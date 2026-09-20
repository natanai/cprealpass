// Original staged physical-damage/wound adapter. All activation remains behind
// the combat policy and the shared body's valid gameplay lifecycle.
import CyberpunkRealism.Combat.*
import CyberpunkRealism.Physiology.*
import CyberpunkRealism.Integration.*

public class CRNativeWoundPlan extends IScriptable {
  public let targetID: EntityID;
  public let region: Int32;
  public let material: Int32;
  public let wound: ref<CRImpactWound>;
  public let proposedPhysical: Float;
  // Bounded per-hit evidence for the conservative unknown-player-protection path.
  public let nativePhysicalBeforePrepare: Float;
  public let nativePhysicalCap: Bool;
  public let consumed: Bool = false;
  public let committed: Bool = false;
  public let armorCommitted: Bool = false;
  public let armorWear: ref<CRArmorWearPlan>;
}

@addField(gameHitEvent)
public let crWoundPrepared: Bool;

@addField(gameHitEvent)
public let crPreparedHit: ref<CRNativeHitSample>;

@addField(gameHitEvent)
public let crWoundPlan: ref<CRNativeWoundPlan>;

@addField(NPCPuppet)
public persistent let crLocalizedInjuries: ref<CRInjuryState>;

@addField(NPCPuppet)
public persistent let crInjurySchemaVersion: Int32;

@addField(NPCPuppet)
public persistent let crInjuryBody: ref<CRBodyState>;

public class CRNPCInjuryBridge extends IScriptable {
  public static func State(npc: ref<NPCPuppet>) -> ref<CRInjuryState> {
    if !IsDefined(npc) {
      return null;
    }
    if npc.crInjurySchemaVersion == 2 && IsDefined(npc.crInjuryBody) && !IsDefined(npc.crLocalizedInjuries) {
      return npc.crInjuryBody.injuries;
    }
    if npc.crInjurySchemaVersion == 1 && !IsDefined(npc.crInjuryBody) {
      return npc.crLocalizedInjuries;
    }
    return null;
  }
  public static func EnsureBody(npc: ref<NPCPuppet>, config: ref<CRBodyConfig>) -> Bool {
    let body: ref<CRBodyState>;
    if !CRNPCInjuryBridge.CanAccept(npc) {
      return false;
    }
    if npc.crInjurySchemaVersion == 2 {
      return CRNPCBodyModel.Valid(npc.crInjuryBody, config);
    }
    body = CRNPCBodyModel.Create(CRNPCInjuryBridge.State(npc), config);
    if !CRNPCBodyModel.Valid(body, config) {
      return false;
    }
    npc.crInjuryBody = body;
    npc.crLocalizedInjuries = null;
    npc.crInjurySchemaVersion = 2;
    return true;
  }
  public static func Advance(npc: ref<NPCPuppet>, config: ref<CRBodyConfig>, hours: Float, activity: Float) -> Bool {
    if !CRNPCInjuryBridge.EnsureBody(npc, config) {
      return false;
    }
    return CRNPCBodyModel.Advance(npc.crInjuryBody, config, hours, activity);
  }
  public static func CanAccept(npc: ref<NPCPuppet>) -> Bool {
    if !IsDefined(npc) || npc.IsReplacer() || NotEquals(npc.GetNPCType(), gamedataNPCType.Human) {
      return false;
    }
    if npc.crInjurySchemaVersion == 0 {
      return !IsDefined(npc.crLocalizedInjuries) && !IsDefined(npc.crInjuryBody);
    }
    if npc.crInjurySchemaVersion == 2 {
      return !IsDefined(npc.crLocalizedInjuries) && CRNPCBodyModel.Valid(npc.crInjuryBody, CRBodyRuntime.Get().GetBodyConfig());
    }
    return npc.crInjurySchemaVersion == 1 && !IsDefined(npc.crInjuryBody) && IsDefined(npc.crLocalizedInjuries) && CRInjuryModel.ValidState(npc.crLocalizedInjuries);
  }

  public static func Commit(npc: ref<NPCPuppet>, wound: ref<CRImpactWound>) -> Bool {
    let injuries: ref<CRInjuryState>;
    if !CRNPCInjuryBridge.CanAccept(npc) || !CRWoundModel.HasInjury(wound) {
      return false;
    }
    // Settle the accepted shared interval before adding a newly received wound.
    CRBodyRuntime.Get().Observe();
    if !CRNPCInjuryBridge.EnsureBody(npc, CRBodyRuntime.Get().GetBodyConfig()) || !CRNPCBodyModel.BeforeEvent(npc.crInjuryBody, CRBodyRuntime.Get().GetBodyConfig()) {
      return false;
    }
    injuries = npc.crInjuryBody.injuries;
    if !CRInjuryModel.Wound(injuries, wound.region, wound.tissueDamage, wound.boneDamage, wound.cyberwareDamage, wound.externalBleedMlPerHour, wound.internalBleedMlPerHour) {
      return false;
    }

    if CRInjuryEffectsRuntime.Get().Register(npc) {
      CRBodyRuntime.Get().RefreshInjuryEffects();
    }
    return true;
  }
}

public class CRNativeWoundBridge extends IScriptable {
  public static func Prepare(hit: ref<gameHitEvent>) -> Void {
    let sample: ref<CRNativeHitSample>;
    let emptyLosses: array<SDamageDealt>;
    let wound: ref<CRImpactWound>;
    let plan: ref<CRNativeWoundPlan>;
    let runtime: ref<CRBodyRuntime>;
    let maximumHealth: Float;
    let proposal: Float;
    let appliedPhysical: Float;
    let nativePhysical: Float;
    let npc: ref<NPCPuppet>;
    let playerTarget: Bool = false;
    if !CRCombatRuntimePolicy.Enabled() || !IsDefined(hit) || hit.projectionPipeline || hit.crWoundPrepared {
      return;
    }
    runtime = CRBodyRuntime.Get();
    if !IsDefined(runtime) {
      return;
    }
    if !runtime.CanAcceptCombatInjury() {
      if IsDefined(hit.target) && hit.target.IsPlayer() {
        runtime.TestCombatStage("prepare-body-gate", 0, 0, 0, 0.0);
      }
      return;
    }
    hit.crWoundPrepared = true;
    if !IsDefined(hit.attackData) || !IsDefined(hit.target) {
      return;
    }
    playerTarget = hit.target.IsPlayer();
    if playerTarget {
      runtime.TestCombatStage("prepare-enter", 0, 0, 0, 0.0);
    }
    nativePhysical = hit.attackComputed.GetAttackValue(gamedataDamageType.Physical);
    if !(nativePhysical > 0.0) {
      if playerTarget {
        runtime.TestCombatStage("prepare-no-physical", 0, 0, 0, nativePhysical);
      }
      return;
    }
    sample = CRNativeHitAdapter.Read(hit, emptyLosses);
    hit.crPreparedHit = sample;
    if !IsDefined(sample) || !IsDefined(sample.contact) {
      if playerTarget {
        runtime.TestCombatStage("prepare-contact-missing", 0, 0, 0, nativePhysical);
      }
      return;
    }
    if !CRHitModel.CanProcess(sample.contact, sample.eligibility) {
      if playerTarget {
        runtime.TestCombatStage("prepare-contact-rejected", sample.contact.region, sample.contact.material, sample.contact.shapeCount, nativePhysical);
      }
      return;
    }
    if !IsDefined(sample.profiles) || !sample.profiles.referenceReady {
      if playerTarget {
        runtime.TestCombatStage("prepare-profile-rejected", sample.contact.region, sample.contact.material, sample.contact.shapeCount, nativePhysical);
      }
      return;
    }
    npc = hit.target as NPCPuppet;
    if !sample.targetIsPlayer && !CRNPCInjuryBridge.CanAccept(npc) {
      return;
    }
    wound = CRWoundModel.Resolve(sample.profiles.referenceImpact, CRWoundModel.Anatomy(sample.contact.region, sample.contact.material));
    maximumHealth = GameInstance.GetStatsSystem(hit.target.GetGame()).GetStatValue(Cast<StatsObjectID>(hit.target.GetEntityID()), gamedataStatType.Health);
    proposal = CRWoundModel.NativeDamage(wound, maximumHealth);
    if proposal < 0.0 {
      if playerTarget {
        runtime.TestCombatStage("prepare-anatomy-rejected", sample.contact.region, sample.contact.material, sample.contact.shapeCount, proposal);
      }
      return;
    }
    plan = new CRNativeWoundPlan();
    plan.targetID = sample.targetID;
    plan.region = sample.contact.region;
    plan.material = sample.contact.material;
    plan.wound = wound;
    plan.proposedPhysical = proposal;
    plan.nativePhysicalBeforePrepare = nativePhysical;
    plan.nativePhysicalCap = sample.profiles.nativePhysicalCap;
    plan.armorWear = sample.profiles.armorWear;
    hit.crWoundPlan = plan;
    // Only the physical channel changes. This executes after RPG/source/armor
    // modifiers but BEFORE one-shot protection, boss caps and resource handling.
    // When player equipment includes unmapped protection, never increase the
    // already-computed native physical channel: the final/proposed ratio will
    // conservatively scale the accepted wound after actual Health loss.
    appliedPhysical = proposal;
    if plan.nativePhysicalCap {
      appliedPhysical = MinF(proposal, nativePhysical);
    }
    hit.attackComputed.SetAttackValue(appliedPhysical, gamedataDamageType.Physical);
    if playerTarget {
      runtime.TestCombatStage("prepare-ready", sample.contact.region, sample.contact.material, sample.contact.shapeCount, appliedPhysical);
    }
  }

  public static func Commit(hit: ref<gameHitEvent>, sample: ref<CRNativeHitSample>) -> Bool {
    let wound: ref<CRImpactWound>;
    let plan: ref<CRNativeWoundPlan>;
    let runtime: ref<CRBodyRuntime>;
    if !CRCombatRuntimePolicy.Enabled() || !IsDefined(hit) || hit.projectionPipeline || !IsDefined(sample) {
      return false;
    }
    runtime = CRBodyRuntime.Get();
    if !IsDefined(runtime) {
      return false;
    }
    if !runtime.CanAcceptCombatInjury() {
      if sample.targetIsPlayer {
        runtime.TestCombatStage("commit-body-gate", sample.contact.region, sample.contact.material, sample.contact.shapeCount, sample.eligibility.actualHealthDamage);
      }
      return false;
    }
    plan = hit.crWoundPlan;
    if !IsDefined(plan) || plan.consumed {
      if sample.targetIsPlayer {
        runtime.TestCombatStage("commit-no-plan", sample.contact.region, sample.contact.material, sample.contact.shapeCount, sample.eligibility.actualHealthDamage);
      }
      return false;
    }
    plan.consumed = true;
    if !CRHitModel.CanProcess(sample.contact, sample.eligibility) || NotEquals(plan.targetID, sample.targetID) || plan.region != sample.contact.region || plan.material != sample.contact.material {
      if sample.targetIsPlayer {
        runtime.TestCombatStage("commit-mismatch", sample.contact.region, sample.contact.material, sample.contact.shapeCount, sample.eligibility.actualHealthDamage);
      }
      return false;
    }
    if CRArmorWearModel.Accepted(plan.proposedPhysical, hit.attackComputed.GetAttackValue(gamedataDamageType.Physical), sample.nativePhysicalHealthDamage, sample.physicalHealthEvaluated, sample.contact.hasProtectionLayer) {
      plan.armorCommitted = CRArmorWearBridge.Commit(plan.armorWear);
    }
    if !CRHitModel.CanRoute(sample.contact, sample.eligibility) {
      if sample.targetIsPlayer {
        runtime.TestCombatStage("commit-no-health-loss", sample.contact.region, sample.contact.material, sample.contact.shapeCount, sample.eligibility.actualHealthDamage);
      }
      return false;
    }
    wound = CRWoundModel.Accepted(plan.wound, plan.proposedPhysical, hit.attackComputed.GetAttackValue(gamedataDamageType.Physical), sample.nativePhysicalHealthDamage);
    if !CRWoundModel.HasInjury(wound) {
      if sample.targetIsPlayer {
        runtime.TestCombatStage("commit-no-injury", sample.contact.region, sample.contact.material, sample.contact.shapeCount, sample.nativePhysicalHealthDamage);
      }
      return false;
    }
    if sample.targetIsPlayer {
      runtime.TestCombatStage("commit-ready", sample.contact.region, sample.contact.material, sample.contact.shapeCount, sample.nativePhysicalHealthDamage);
      plan.committed = runtime.RecordInjury(wound.region, wound.tissueDamage, wound.boneDamage, wound.cyberwareDamage, wound.externalBleedMlPerHour, wound.internalBleedMlPerHour);
      if plan.committed {
        // Provenance is explanatory metadata only. A metadata failure must never
        // roll back or veto an already accepted physical wound.
        CRInjuryProvenanceRuntime.Get().Record(sample, wound);
      }
    } else {
      plan.committed = CRNPCInjuryBridge.Commit(hit.target as NPCPuppet, wound);
    }
    return plan.committed;
  }
}

@wrapMethod(DamageSystem)
private final func ProcessOneShotProtection(hitEvent: ref<gameHitEvent>) -> Void {
  if IsDefined(hitEvent) && IsDefined(hitEvent.crBloodLossDelivery) {
    CRBloodLossNative.Prepare(hitEvent);
  } else {
    CRNativeWoundBridge.Prepare(hitEvent);
  }
  wrappedMethod(hitEvent);
}
