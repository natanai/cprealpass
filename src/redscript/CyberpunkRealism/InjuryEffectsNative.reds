// Original transient impairment adapters. Uses existing body callbacks only.
import CyberpunkRealism.Physiology.*
import CyberpunkRealism.Integration.*

public class CRInjuryModifierSlot extends IScriptable {
  private let stats: ref<StatsSystem>;
  private let owner: StatsObjectID;
  private let modifier: ref<gameStatModifierData>;
  private let stat: gamedataStatType;
  private let value: Float;
  public func Clear() -> Bool {
    if !IsDefined(this.modifier) {
      return true;
    }
    if !IsDefined(this.stats) || !this.stats.RemoveAndUncacheModifier(this.owner, this.modifier) {
      // Retain the exact handle on failure; never stack a replacement over it.
      return false;
    }
    this.modifier = null;
    this.stats = null;
    return true;
  }
  public func Sync(target: ref<GameObject>, stat: gamedataStatType, factor: Float) -> Bool {
    let id: StatsObjectID;
    let stats: ref<StatsSystem>;
    let modifier: ref<gameStatModifierData>;
    if !IsDefined(target) || factor == 1.0 || !(factor >= 0.05 && factor <= 10.0) {
      return this.Clear();
    }
    id = Cast<StatsObjectID>(target.GetEntityID());
    if IsDefined(this.modifier) && Equals(this.owner, id) && Equals(this.stat, stat) && AbsF(this.value - factor) < 0.0001 {
      return true;
    }
    if !this.Clear() {
      return false;
    }
    stats = GameInstance.GetStatsSystem(target.GetGame());
    modifier = RPGManager.CreateStatModifier(stat, gameStatModifierType.Multiplier, factor);
    if !IsDefined(stats) || !IsDefined(modifier) || !stats.AddModifier(id, modifier) {
      return false;
    }
    this.stats = stats;
    this.owner = id;
    this.modifier = modifier;
    this.stat = stat;
    this.value = factor;
    return true;
  }
}
public class CRInjuryModifierSet extends IScriptable {
  private let slots: array<ref<CRInjuryModifierSlot>>;
  public func Clear() -> Bool {
    let i: Int32 = 0;
    let cleared: Bool = true;
    while i < ArraySize(this.slots) {
      if !this.slots[i].Clear() {
        cleared = false;
      }
      i += 1;
    }
    return cleared;
  }
  public func Sync(actor: ref<ScriptedPuppet>, effects: ref<CRInjuryEffects>) -> Bool {
    let weapon: ref<WeaponObject>;
    let ok: Bool = true;
    if !IsDefined(actor) || !IsDefined(effects) || !effects.valid {
      return this.Clear();
    }
    while ArraySize(this.slots) < 11 {
      ArrayPush(this.slots, new CRInjuryModifierSlot());
    }
    weapon = GameObject.GetActiveWeapon(actor);
    if !this.slots[0].Sync(actor, gamedataStatType.MaxSpeed, effects.speed) { ok = false; }
    if !this.slots[1].Sync(actor, gamedataStatType.Stamina, effects.stamina) { ok = false; }
    if !this.slots[2].Sync(actor, gamedataStatType.StaminaRegenRate, effects.staminaRegen) { ok = false; }
    if !this.slots[3].Sync(weapon, gamedataStatType.ReloadTime, effects.reload) { ok = false; }
    if !this.slots[4].Sync(weapon, gamedataStatType.RecoilAngle, effects.recoil) { ok = false; }
    if !this.slots[5].Sync(weapon, gamedataStatType.SpreadDefaultX, effects.spread) { ok = false; }
    if !this.slots[6].Sync(weapon, gamedataStatType.SpreadDefaultY, effects.spread) { ok = false; }
    if !this.slots[7].Sync(weapon, gamedataStatType.RecoilKickMin, effects.recoil) { ok = false; }
    if !this.slots[8].Sync(weapon, gamedataStatType.RecoilKickMax, effects.recoil) { ok = false; }
    if !this.slots[9].Sync(weapon, gamedataStatType.SpreadAdsDefaultX, effects.spread) { ok = false; }
    if !this.slots[10].Sync(weapon, gamedataStatType.SpreadAdsDefaultY, effects.spread) { ok = false; }
    return ok;
  }
}

@addField(ScriptedPuppet)
public let crInjuryModifiers: ref<CRInjuryModifierSet>;

@addField(NPCPuppet)
public let crProgressAllowed: Bool;

public class CRInjuryEffectsBridge extends IScriptable {
  public static func Allowed(actor: ref<ScriptedPuppet>, enabled: Bool) -> Bool {
    let scene: ref<SceneSystemInterface>;
    if !enabled || !IsDefined(actor) || actor.IsReplacer() || actor.IsDead() || ScriptedPuppet.IsDefeated(actor) || !actor.IsAttached() {
      return false;
    }
    scene = GameInstance.GetSceneSystem(actor.GetGame()).GetScriptInterface();
    return !IsDefined(scene) || !scene.IsEntityInScene(actor.GetEntityID());
  }
  public static func Clear(actor: ref<ScriptedPuppet>) -> Bool {
    CRBloodLossNative.Clear(actor);
    if IsDefined(actor) && IsDefined(actor.crInjuryModifiers) {
      return actor.crInjuryModifiers.Clear();
    }
    return true;
  }
  public static func Apply(actor: ref<ScriptedPuppet>, injury: ref<CRInjuryState>, config: ref<CRBodyConfig>, enabled: Bool) -> Bool {
    let effects: ref<CRInjuryEffects>;
    if !IsDefined(actor) {
      return true;
    }
    if !CRInjuryEffectsBridge.Allowed(actor, enabled) {
      return CRInjuryEffectsBridge.Clear(actor);
    }
    effects = CRInjuryEffectsModel.Read(injury, config);
    if !effects.valid {
      return CRInjuryEffectsBridge.Clear(actor);
    }
    CRBloodLossNative.Refresh(actor, injury, enabled);
    if !IsDefined(actor.crInjuryModifiers) {
      actor.crInjuryModifiers = new CRInjuryModifierSet();
    }
    return actor.crInjuryModifiers.Sync(actor, effects);
  }
}

public class CRInjuryEffectsRuntime extends ScriptableSystem {
  private let npcs: array<wref<NPCPuppet>>;
  // Transient diagnostic counters only; no output, polling or persistent effects.
  public let lastRefreshFailures: Int32;
  public let rejectedRegistrations: Int32;
  public let lastProgressFailures: Int32;

  public static func Get() -> ref<CRInjuryEffectsRuntime> {
    return GameInstance.GetScriptableSystemsContainer(GetGameInstance()).Get(NameOf<CRInjuryEffectsRuntime>()) as CRInjuryEffectsRuntime;
  }

  private func Prune() -> Void {
    let i: Int32 = 0;
    while i < ArraySize(this.npcs) {
      if !IsDefined(this.npcs[i]) {
        ArrayErase(this.npcs, i);
      } else {
        if (this.npcs[i].IsDead() || ScriptedPuppet.IsDefeated(this.npcs[i]) || !this.npcs[i].IsAttached()) && CRInjuryEffectsBridge.Clear(this.npcs[i]) {
          ArrayErase(this.npcs, i);
        } else {
          i += 1;
        }
      }
    }
  }

  public func Register(npc: ref<NPCPuppet>) -> Bool {
    let bodyRuntime: ref<CRBodyRuntime>;
    let i: Int32 = 0;
    if !IsDefined(npc) || !CRCombatRuntimePolicy.Enabled() || npc.IsDead() || ScriptedPuppet.IsDefeated(npc) || !npc.IsAttached() {
      return false;
    }
    this.Prune();
    while i < ArraySize(this.npcs) {
      if Equals(this.npcs[i].GetEntityID(), npc.GetEntityID()) {
        return true;
      }
      i += 1;
    }
    if ArraySize(this.npcs) >= 128 {
      this.rejectedRegistrations += 1;
      return false;
    }
    bodyRuntime = CRBiologySessionAuthority.Body(this.GetGameInstance());
    if !IsDefined(bodyRuntime) {
      return false;
    }
    bodyRuntime.Observe();
    npc.crProgressAllowed = CRInjuryEffectsBridge.Allowed(npc, true);
    ArrayPush(this.npcs, npc);
    return true;
  }

  public func Advance(hours: Float, config: ref<CRBodyConfig>, skipped: Bool) -> Void {
    let i: Int32 = 0;
    let npc: ref<NPCPuppet>;
    let allowed: Bool;
    let activity: Float;
    this.lastProgressFailures = 0;
    if !CRCombatRuntimePolicy.Enabled() || !(hours > 0.0 && hours <= 72.0) {
      return;
    }
    this.Prune();
    while i < ArraySize(this.npcs) {
      npc = this.npcs[i];
      allowed = CRInjuryEffectsBridge.Allowed(npc, true);
      if allowed && npc.crProgressAllowed {
        activity = 0.0;
        if !skipped && !VehicleComponent.IsMountedToVehicle(npc.GetGame(), npc) {
          activity = ClampF(Vector4.Length(npc.GetVelocity()) / 7.0, 0.0, 1.0);
        }
        if !CRNPCInjuryBridge.Advance(npc, config, hours, activity) {
          this.lastProgressFailures += 1;
        }
      }
      npc.crProgressAllowed = allowed;
      i += 1;
    }
  }

  public func Refresh(body: ref<CRBodyState>, config: ref<CRBodyConfig>, enabled: Bool) -> Void {
    let i: Int32 = 0;
    let player: ref<ScriptedPuppet> = GameInstance.GetPlayerSystem(this.GetGameInstance()).GetLocalPlayerMainGameObject() as ScriptedPuppet;
    let localPlayer: ref<PlayerPuppet> = player as PlayerPuppet;
    this.lastRefreshFailures = 0;
    if IsDefined(body) {
      if !CRInjuryEffectsBridge.Apply(player, body.injuries, config, enabled) {
        this.lastRefreshFailures += 1;
      }
    } else {
      if !CRInjuryEffectsBridge.Clear(player) {
        this.lastRefreshFailures += 1;
      }
    }
    this.Prune();
    while i < ArraySize(this.npcs) {
      this.npcs[i].crProgressAllowed = CRInjuryEffectsBridge.Allowed(this.npcs[i], enabled);
      if !CRInjuryEffectsBridge.Apply(this.npcs[i], CRNPCInjuryBridge.State(this.npcs[i]), config, enabled && CRNPCInjuryBridge.CanAccept(this.npcs[i])) {
        this.lastRefreshFailures += 1;
      }
      i += 1;
    }
    CRPainNativeEffects.Refresh(localPlayer, IsDefined(body) && enabled && CRInjuryEffectsBridge.Allowed(localPlayer, true));
  }

  public func Suspend() -> Void {
    this.Refresh(null, null, false);
  }
}

@wrapMethod(ScriptedPuppet)
protected cb func OnGameAttached() -> Bool {
  let result: Bool = wrappedMethod();
  let npc: ref<NPCPuppet> = this as NPCPuppet;
  let runtime: ref<CRInjuryEffectsRuntime>;
  if IsDefined(npc) && IsDefined(CRNPCInjuryBridge.State(npc)) && CRNPCInjuryBridge.CanAccept(npc) {
    runtime = CRBiologySessionAuthority.InjuryEffects(this.GetGame());
    if IsDefined(runtime) {
      runtime.Register(npc);
    }
  }
  return result;
}
