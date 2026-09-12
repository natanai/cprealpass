// Original staged native blood-loss delivery. No helper process or timer.
import CyberpunkRealism.Physiology.*
import CyberpunkRealism.Integration.*

@addField(ScriptedPuppet)
public let crBloodLossCursor: ref<CRBloodLossCursor>;
@addField(gameHitEvent)
public let crBloodLossDelivery: ref<CRBloodLossDelivery>;

public class CRBloodLossNative extends IScriptable {
  public static func SimSeconds() -> Float {
    return GameInstance.GetSimTime(GetGameInstance()).ToFloat();
  }
  public static func Allowed(actor: ref<ScriptedPuppet>, enabled: Bool) -> Bool {
    let npc: ref<NPCPuppet> = actor as NPCPuppet;
    if !CRCombatRuntimePolicy.Enabled() || !CRInjuryEffectsBridge.Allowed(actor, enabled) {
      return false;
    }
    if actor.GetIsInFastFinisher() { return false; }
    if !actor.IsPlayer() {
      // Flesh-bearing human NPCs include bosses and MaxTac. Their weaponless
      // resource cap is handled below without fabricating a projectile weapon.
      return IsDefined(npc) && Equals(npc.GetNPCType(), gamedataNPCType.Human);
    }
    return true;
  }
  public static func Clear(actor: ref<ScriptedPuppet>) -> Void {
    if IsDefined(actor) {
      CRBloodLossModel.Invalidate(actor.crBloodLossCursor);
    }
  }
  public static func Refresh(actor: ref<ScriptedPuppet>, injury: ref<CRInjuryState>, enabled: Bool) -> Void {
    let maximumHealth: Float;
    let delivery: ref<CRBloodLossDelivery>;
    let context: AttackInitContext;
    let attack: ref<IAttack>;
    let hit: ref<gameHitEvent>;
    if !IsDefined(actor) {
      return;
    }
    if !IsDefined(actor.crBloodLossCursor) {
      actor.crBloodLossCursor = new CRBloodLossCursor();
    }
    maximumHealth = GameInstance.GetStatsSystem(actor.GetGame()).GetStatValue(Cast<StatsObjectID>(actor.GetEntityID()), gamedataStatType.Health);
    delivery = CRBloodLossModel.Sample(actor.crBloodLossCursor, injury, CRBloodLossNative.Allowed(actor, enabled), maximumHealth, CRBloodLossNative.SimSeconds());
    if !IsDefined(delivery) {
      return;
    }
    // Use the stock generic effect definition only to initialize native attack
    // data. Do not copy its Nonlethal flag or apply the vanilla Bleeding effect.
    context.record = TweakDBInterface.GetAttackRecord(t"Attacks.BaseDOTTick");
    context.instigator = actor;
    context.source = actor;
    if !IsDefined(context.record) {
      CRBloodLossNative.Clear(actor);
      return;
    }
    attack = IAttack.Create(context);
    if !IsDefined(attack) {
      CRBloodLossNative.Clear(actor);
      return;
    }
    hit = new gameHitEvent();
    hit.target = actor;
    hit.crBloodLossDelivery = delivery;
    hit.attackData = new AttackData();
    hit.attackData.SetAttackDefinition(attack);
    hit.attackData.SetInstigator(actor);
    hit.attackData.SetSource(actor);
    hit.attackData.SetAttackType(gamedataAttackType.Effect);
    hit.attackData.SetAttackTime(CRBloodLossNative.SimSeconds());
    hit.attackData.SetAttackPosition(actor.GetWorldPosition());
    hit.hitPosition = actor.GetWorldPosition();
    hit.attackData.AddFlag(hitFlag.CanDamageSelf, n"CRBloodLoss");
    hit.attackData.AddFlag(hitFlag.FriendlyFire, n"CRBloodLoss");
    hit.attackData.AddFlag(hitFlag.DamageOverTime, n"CRBloodLoss");
    hit.attackData.AddFlag(hitFlag.DisableNPCHitReaction, n"CRBloodLoss");
    hit.attackData.PreAttack();
    GameInstance.GetDamageSystem(actor.GetGame()).QueueHitEvent(hit, actor);
  }
  public static func Current(hit: ref<gameHitEvent>) -> Bool {
    let actor: ref<ScriptedPuppet>;
    if !IsDefined(hit) || !IsDefined(hit.crBloodLossDelivery) || !IsDefined(hit.attackData) || hit.projectionPipeline {
      return false;
    }
    actor = hit.target as ScriptedPuppet;
    if !CRBloodLossNative.Allowed(actor, CRBodyRuntime.Get().CanAcceptCombatInjury()) || !CRBloodLossModel.Current(actor.crBloodLossCursor, hit.crBloodLossDelivery, CRBloodLossNative.SimSeconds()) {
      return false;
    }
    return hit.attackData.GetInstigator() == actor && hit.attackData.GetSource() == actor && !IsDefined(hit.attackData.GetWeapon()) && hit.attackData.HasFlag(hitFlag.DamageOverTime) && !hit.attackData.HasFlag(hitFlag.IgnoreImmortalityModes) && !hit.attackData.HasFlag(hitFlag.IgnoreStatPoolCustomLimit) && !hit.attackData.HasFlag(hitFlag.Kill) && !hit.attackData.HasFlag(hitFlag.Nonlethal);
  }
  public static func Admit(hit: ref<gameHitEvent>) -> Bool {
    if !CRBloodLossNative.Current(hit) || hit.crBloodLossDelivery.phase != 1 {
      return false;
    }
    hit.crBloodLossDelivery.phase = 5;
    return true;
  }
  public static func Prepare(hit: ref<gameHitEvent>) -> Void {
    let values: array<Float>;
    let i: Int32 = 0;
    let maximumHealth: Float;
    let proposal: Float;
    values = hit.attackComputed.GetAttackValues();
    while i < ArraySize(values) {
      values[i] = 0.0;
      i += 1;
    }
    hit.attackComputed.SetAttackValues(values);
    if !CRBloodLossNative.Current(hit) || hit.crBloodLossDelivery.phase != 5 {
      hit.attackData.AddFlag(hitFlag.DealNoDamage, n"CRBloodLossRejected");
      return;
    }
    if hit.attackData.HasFlag(hitFlag.DealNoDamage) || hit.attackData.HasFlag(hitFlag.DamageNullified) || hit.attackData.HasFlag(hitFlag.ImmortalTarget) || hit.attackData.HasFlag(hitFlag.CannotModifyDamage) || hit.attackData.HasFlag(hitFlag.DeterministicDamage) {
      hit.attackData.AddFlag(hitFlag.DealNoDamage, n"CRBloodLossProtected");
      hit.crBloodLossDelivery.phase = 0;
      return;
    }
    maximumHealth = GameInstance.GetStatsSystem(hit.target.GetGame()).GetStatValue(Cast<StatsObjectID>(hit.target.GetEntityID()), gamedataStatType.Health);
    proposal = MinF(hit.crBloodLossDelivery.proposedDamage, maximumHealth * 0.1);
    if !(maximumHealth >= 1.0 && maximumHealth <= 1000000000.0) || !(proposal >= 1.0 && proposal <= 100000000.0) {
      hit.attackData.AddFlag(hitFlag.DealNoDamage, n"CRBloodLossInvalidHealth");
      hit.crBloodLossDelivery.phase = 0;
      return;
    }

    hit.attackComputed.SetAttackValue(proposal, gamedataDamageType.Physical);
    hit.crBloodLossDelivery.phase = 2;
  }
  public static func IsBossDelivery(hit: ref<gameHitEvent>) -> Bool {
    if !IsDefined(hit) || !IsDefined(hit.crBloodLossDelivery) { return false; }
    let npc: ref<NPCPuppet> = hit.target as NPCPuppet;
    return IsDefined(npc) && (npc.IsBoss() || Equals(npc.GetNPCRarity(), gamedataNPCRarity.MaxTac));
  }

  public static func BossDamage(hit: ref<gameHitEvent>) -> Float {
    if !CRBloodLossNative.IsBossDelivery(hit) || !CRBloodLossNative.Current(hit) || hit.crBloodLossDelivery.phase != 2 || hit.crBloodLossDelivery.resourcesSubmitted || !IsDefined(hit.attackComputed) {
      return 0.0;
    }
    if hit.attackData.HasFlag(hitFlag.DealNoDamage) || hit.attackData.HasFlag(hitFlag.DamageNullified) || hit.attackData.HasFlag(hitFlag.ImmortalTarget) || hit.attackData.HasFlag(hitFlag.CannotModifyDamage) || hit.attackData.HasFlag(hitFlag.DeterministicDamage) {
      return 0.0;
    }
    let stats: ref<StatsSystem> = GameInstance.GetStatsSystem(hit.target.GetGame());
    let maximum: Float = stats.GetStatValue(Cast<StatsObjectID>(hit.target.GetEntityID()), gamedataStatType.Health);
    let percent: Float = stats.GetStatValue(Cast<StatsObjectID>(hit.target.GetEntityID()), gamedataStatType.MaxPercentDamageTakenPerHit);
    let proportion: Float = TweakDBInterface.GetFloat(t"Constants.DamageSystem.maxDamageDoTProportion", 1.0);
    let damage: Float = hit.attackComputed.GetAttackValue(gamedataDamageType.Physical);
    if !(maximum >= 1.0 && maximum <= 1000000000.0) || !(percent >= 0.0 && percent <= 1000000.0) || !(proportion >= 0.0 && proportion <= 1000000.0) || !(damage >= 0.0 && damage <= 100000000.0) || !(hit.crBloodLossDelivery.proposedDamage >= 1.0 && hit.crBloodLossDelivery.proposedDamage <= 100000000.0) {
      return 0.0;
    }
    damage = MinF(damage, MinF(hit.crBloodLossDelivery.proposedDamage, maximum * 0.1));
    if percent > 0.0 {
      // Same native per-hit and DOT proportion limits, for one physiological
      // event. There is no projectile count to divide by and no weapon lookup.
      damage = MinF(damage, percent * proportion / 100.0 * maximum);
    }
    // Preserve the native resource path's minimum positive damage quantum.
    if damage > 0.0 && damage < 1.0 { damage = 1.0; }
    return damage;
  }

  public static func Acknowledge(hit: ref<gameHitEvent>, const lost: script_ref<[SDamageDealt]>) -> Void {
    let i: Int32 = 0;
    let actor: ref<ScriptedPuppet> = hit.target as ScriptedPuppet;
    if !IsDefined(actor) || !CRBloodLossModel.Current(actor.crBloodLossCursor, hit.crBloodLossDelivery, CRBloodLossNative.SimSeconds()) || hit.crBloodLossDelivery.phase != 2 {
      return;
    }
    hit.crBloodLossDelivery.phase = 3;
    while i < ArraySize(Deref(lost)) {
      if Equals(Deref(lost)[i].affectedStatPool, gamedataStatPoolType.Health) && Deref(lost)[i].value > 0.0 {
        hit.crBloodLossDelivery.reportedHealthDamage += Deref(lost)[i].value;
      }
      i += 1;
    }
    // These are native reported resource losses, not a post-pool HP measurement.
    // Native custom limits/immortality can further constrain actual health.
  }
}
@wrapMethod(DamageSystem)
private final func PreProcess(hitEvent: ref<gameHitEvent>, cache: ref<CacheData>) -> Bool {
  if IsDefined(hitEvent) && IsDefined(hitEvent.crBloodLossDelivery) {
    if !CRBloodLossNative.Admit(hitEvent) {
      return false;
    }
  }
  return wrappedMethod(hitEvent, cache);
}
// Only this project's marked boss blood-loss events use the weaponless cap.
// All other attacks retain the complete stock ApplyDamage path.
@wrapMethod(StatPoolsManager)
public final static func ApplyDamage(hitEvent: ref<gameHitEvent>, forReal: Bool, out valuesLost: [SDamageDealt]) -> Void {
  if !CRBloodLossNative.IsBossDelivery(hitEvent) {
    wrappedMethod(hitEvent, forReal, valuesLost);
    return;
  }
  ArrayClear(valuesLost);
  if !forReal || hitEvent.crBloodLossDelivery.resourcesSubmitted { return; }
  if !IsDefined(hitEvent.attackComputed) { hitEvent.crBloodLossDelivery.resourcesSubmitted = true; return; }
  let damage: Float = CRBloodLossNative.BossDamage(hitEvent);
  hitEvent.crBloodLossDelivery.resourcesSubmitted = true;
  let values: array<Float> = hitEvent.attackComputed.GetAttackValues();
  let i: Int32 = 0;
  while i < ArraySize(values) { values[i] = 0.0; i += 1; }
  hitEvent.attackComputed.SetAttackValues(values);
  hitEvent.attackComputed.SetAttackValue(damage, gamedataDamageType.Physical);
  if damage > 0.0 {
    // Retain native overshield/armor, finisher grace and DrainStatPool handling.
    // DrainStatPool preserves minimum health, immortality and custom pool limits.
    StatPoolsManager.ApplyDamageSingle(hitEvent, gamedataDamageType.Physical, damage, forReal, valuesLost);
  }
}