// Project-original thin adapters from stock Cyberpunk events into realpass body
// state. Keep native coupling here so the physiology model remains patch-resilient.
module CyberpunkRealism.Integration

import CyberpunkRealism.Settings.*

public class CRBodyRuntimeMasterPolicy extends IScriptable {
  public static func Enabled() -> Bool {
    return CRBodyRuntimePolicy.Enabled() && CRRealpassSettings.IsEnabled(GetGameInstance());
  }

  public static func Ready() -> Bool {
    return CRBiologyRuntimeAvailability.EnsureActive();
  }
}

@wrapMethod(PlayerPuppet)
protected cb func OnGameAttached() -> Bool {
  let result: Bool = wrappedMethod();
  if !this.IsReplacer() && CRBodyRuntimeMasterPolicy.Enabled() {
    // Normal session startup path. EnsureActive is intentionally safe to call again
    // from presentation/native action boundaries if save/system ordering caused this
    // edge to run before the ScriptableSystem was ready.
    CRBodyRuntimeMasterPolicy.Ready();
  }
  return result;
}

// Capture an actual completed stock consumable action rather than depending on a
// broad gameplay mod's dispatch/tags. The record is captured before vanilla may
// remove the item from inventory; realpass processes it only for the local player.
// Medical healing-item actions (MaxDoc/Bounce Back) use UseHealChargeAction and are
// handled separately below so ordinary food/drink consumption keeps its stock path.
@wrapMethod(ConsumeAction)
public func CompleteAction(gameInstance: GameInstance) -> Void {
  let executor: ref<GameObject> = this.GetExecutor();
  let itemID: ItemID = this.GetItemData().GetID();
  let tdbid: TweakDBID = ItemID.GetTDBID(itemID);
  let record: wref<Item_Record> = TweakDBInterface.GetItemRecord(tdbid);
  wrappedMethod(gameInstance);

  if !CRBodyRuntimeMasterPolicy.Ready() || !IsDefined(executor) || !executor.IsPlayer() || !IsDefined(record) {
    return;
  }
  let local: ref<PlayerPuppet> = GameInstance.GetPlayerSystem(gameInstance).GetLocalPlayerMainGameObject() as PlayerPuppet;
  if !IsDefined(local) || !Equals(local.GetEntityID(), executor.GetEntityID()) {
    return;
  }

  CRBodyRuntime.Get().Consume(record);
}

// Vanilla MaxDoc is the inhaler family (ConsumableBaseName.FirstAidWhiff). realpass
// preserves that native item identity, name, animation, quick-slot action and charge
// handling, but swaps the *effect*: MaxDoc becomes analgesia only. We intercept the
// status-effect application itself rather than applying vanilla healing and trying
// to undo HP afterward. Bounce Back and every other healing-item family stay on the
// vanilla path until realpass gives them an explicitly authored replacement role.
@wrapMethod(UseHealChargeAction)
protected func ProcessStatusEffects(const actionEffects: script_ref<array<wref<ObjectActionEffect_Record>>>, gameInstance: GameInstance) -> Void {
  let executor: wref<GameObject> = this.GetExecutor();
  let itemData: wref<gameItemData> = this.GetItemData();
  let tdbid: TweakDBID;
  let consumable: wref<ConsumableItem_Record>;
  let local: ref<PlayerPuppet>;

  // If the Biology runtime cannot establish authoritative state, yield this action
  // completely to vanilla instead of suppressing healing while our body is offline.
  if !CRBodyRuntimeMasterPolicy.Ready() || !IsDefined(executor) || !executor.IsPlayer() || !IsDefined(itemData) {
    wrappedMethod(actionEffects, gameInstance);
    return;
  }

  tdbid = ItemID.GetTDBID(itemData.GetID());
  consumable = TweakDBInterface.GetConsumableItemRecord(tdbid);
  if !IsDefined(consumable) || !Equals(consumable.ConsumableBaseName().Type(), gamedataConsumableBaseName.FirstAidWhiff) {
    wrappedMethod(actionEffects, gameInstance);
    return;
  }

  local = GameInstance.GetPlayerSystem(gameInstance).GetLocalPlayerMainGameObject() as PlayerPuppet;
  if !IsDefined(local) || !Equals(local.GetEntityID(), executor.GetEntityID()) {
    wrappedMethod(actionEffects, gameInstance);
    return;
  }

  // Intentionally do NOT call wrappedMethod for MaxDoc: that is the point at which
  // vanilla FirstAidWhiff health-regeneration effects would be applied. Charge use,
  // animation and hotkey refresh remain native in UseHealChargeAction.CompleteAction.
  if CRPainRuntime.Get().UseMaxDoc() {
    // Consumable use is an explicit state boundary. Reconstruct transient weapon/
    // intoxication feedback now rather than waiting for a later injury/body refresh;
    // no independent pain polling timer is introduced.
    CRPainNativeEffects.Refresh(local, true);
  }
}

// The pause/hub button is an explicit "wait/skip time" path. Bed interactions use
// the same stock time-skip popup without this marker, so the body runtime can treat
// that committed interval as sleep without importing another mod's sleep system.
@wrapMethod(HubTimeSkipController)
protected cb func OnTimeSkipButtonPressed(e: ref<inkPointerEvent>) -> Bool {
  if CRBodyRuntimeMasterPolicy.Ready() && e.IsAction(n"click") {
    CRBodyRuntime.Get().MarkNextTimeSkipAsWait();
  }
  return wrappedMethod(e);
}

@addField(TimeskipGameController)
private let crRealpassSleeping: Bool;

@wrapMethod(TimeskipGameController)
protected cb func OnInitialize() -> Bool {
  if CRBodyRuntimeMasterPolicy.Ready() {
    this.crRealpassSleeping = CRBodyRuntime.Get().ConsumeNextTimeSkipSleeping();
  }
  return wrappedMethod();
}

// Vanilla commits the world-time change synchronously in Apply(). realpass brackets
// that exact operation so CRClockModel does not mistake the jump for normal awake
// play. The UI animation may continue afterward, but the physical interval is
// already committed by the game at this point.
@wrapMethod(TimeskipGameController)
private func Apply() -> Void {
  let hours: Int32 = this.m_hoursToSkip;
  let ready: Bool = hours > 0 && CRBodyRuntimeMasterPolicy.Ready();
  if ready {
    CRBodyRuntime.Get().BeginSkip();
  }
  wrappedMethod();
  if ready {
    CRBodyRuntime.Get().FinishSkipHours(Cast<Float>(hours), this.crRealpassSleeping);
  }
}
