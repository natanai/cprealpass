// Project-original thin adapters from stock Cyberpunk events into realpass body
// state. Keep native coupling here so the physiology model remains patch-resilient.
module CyberpunkRealism.Integration

@wrapMethod(PlayerPuppet)
protected cb func OnGameAttached() -> Bool {
  let result: Bool = wrappedMethod();
  if !this.IsReplacer() && CRBodyRuntimePolicy.Enabled() {
    CRBodyRuntime.Get().Activate();
  }
  return result;
}

// Capture an actual completed stock consumable action rather than depending on a
// broad gameplay mod's dispatch/tags. The record is captured before vanilla may
// remove the item from inventory; realpass processes it only for the local player.
@wrapMethod(ConsumeAction)
public func CompleteAction(gameInstance: GameInstance) -> Void {
  let executor: ref<GameObject> = this.GetExecutor();
  let itemID: ItemID = this.GetItemData().GetID();
  let record: wref<Item_Record> = TweakDBInterface.GetItemRecord(ItemID.GetTDBID(itemID));
  wrappedMethod(gameInstance);

  if !CRBodyRuntimePolicy.Enabled() || !IsDefined(executor) || !executor.IsPlayer() || !IsDefined(record) {
    return;
  }
  let local: ref<PlayerPuppet> = GameInstance.GetPlayerSystem(gameInstance).GetLocalPlayerMainGameObject() as PlayerPuppet;
  if IsDefined(local) && Equals(local.GetEntityID(), executor.GetEntityID()) {
    CRBodyRuntime.Get().Consume(record);
  }
}

// The pause/hub button is an explicit "wait/skip time" path. Bed interactions use
// the same stock time-skip popup without this marker, so the body runtime can treat
// that committed interval as sleep without importing another mod's sleep system.
@wrapMethod(HubTimeSkipController)
protected cb func OnTimeSkipButtonPressed(e: ref<inkPointerEvent>) -> Bool {
  if CRBodyRuntimePolicy.Enabled() && e.IsAction(n"click") {
    CRBodyRuntime.Get().MarkNextTimeSkipAsWait();
  }
  return wrappedMethod(e);
}

@addField(TimeskipGameController)
private let crRealpassSleeping: Bool;

@wrapMethod(TimeskipGameController)
protected cb func OnInitialize() -> Bool {
  if CRBodyRuntimePolicy.Enabled() {
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
  if CRBodyRuntimePolicy.Enabled() && hours > 0 {
    CRBodyRuntime.Get().BeginSkip();
  }
  wrappedMethod();
  if CRBodyRuntimePolicy.Enabled() && hours > 0 {
    CRBodyRuntime.Get().FinishSkipHours(Cast<Float>(hours), this.crRealpassSleeping);
  }
}
