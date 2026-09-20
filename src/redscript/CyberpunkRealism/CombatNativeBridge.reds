// Cyberpunk Realism original native adapter. Disabled development hook; no
// logs, timers or synthetic damage events. Physical damage/wound routing lives in CombatWoundsNative.
import CyberpunkRealism.Combat.*
import CyberpunkRealism.Physiology.*
import CyberpunkRealism.Settings.*

public class CRCombatRuntimePolicy extends IScriptable {
  // BuildEnabled is the compile-time/acceptance gate rewritten only in staged
  // candidates. Enabled adds the player's one global RealPass master decision.
  public static func BuildEnabled() -> Bool {
    return false;
  }

  public static func Enabled() -> Bool {
    return CRCombatRuntimePolicy.BuildEnabled() && CRRealpassSettings.IsEnabled(GetGameInstance());
  }
}

public class CRNativeHitSample extends IScriptable {
  public let contact: ref<CRHitContact>;
  public let eligibility: ref<CRHitEligibility>;
  public let weaponRecord: TweakDBID;
  public let targetID: EntityID;
  public let targetIsPlayer: Bool;
  public let targetIsBoss: Bool;
  public let nativePhysicalHealthDamage: Float;
  public let physicalHealthEvaluated: Bool;
  public let canRoute: Bool;
  public let profiles: ref<CRCombatProfileSample>;
}

public class CRNativeHitAdapter extends IScriptable {
  public static func Region(data: ref<HitShapeUserDataBase>) -> Int32 {
    if !IsDefined(data) {
      return 0;
    }
    if HitShapeUserDataBase.IsHitReactionZoneHead(data) {
      return 1;
    }
    if HitShapeUserDataBase.IsHitReactionZoneTorso(data) {
      return 2;
    }
    if HitShapeUserDataBase.IsHitReactionZoneLeftArm(data) {
      return 3;
    }
    if HitShapeUserDataBase.IsHitReactionZoneRightArm(data) {
      return 4;
    }
    if HitShapeUserDataBase.IsHitReactionZoneLeftLeg(data) {
      return 5;
    }
    if HitShapeUserDataBase.IsHitReactionZoneRightLeg(data) {
      return 6;
    }
    return 0;
  }

  public static func Material(data: ref<HitShapeUserDataBase>) -> Int32 {
    if !IsDefined(data) {
      return 0;
    }
    switch data.m_hitShapeType {
      case EHitShapeType.Flesh: return 1;
      case EHitShapeType.Armor: return 2;
      case EHitShapeType.Cyberware: return 3;
      case EHitShapeType.Metal: return 4;
    }
    return 0;
  }

  public static func Read(hit: ref<gameHitEvent>, const lost: script_ref<[SDamageDealt]>, opt skipProfiles: Bool) -> ref<CRNativeHitSample> {
    let sample: ref<CRNativeHitSample> = new CRNativeHitSample();
    let gate: ref<CRHitEligibility> = new CRHitEligibility();
    let contact: ref<CRHitContact> = new CRHitContact();
    let puppet: ref<ScriptedPuppet>;
    let npc: ref<NPCPuppet>;
    let instigator: ref<GameObject>;
    let weapon: ref<WeaponObject>;
    let shape: ref<HitShapeUserDataBase>;
    let legacyShape: ref<HitData_Base>;
    let shapes: array<HitShapeData>;
    let i: Int32 = 0;
    sample.contact = contact;
    sample.eligibility = gate;
    if !IsDefined(hit) || !IsDefined(hit.target) || !IsDefined(hit.attackData) {
      return sample;
    }
    puppet = hit.target as ScriptedPuppet;
    npc = hit.target as NPCPuppet;
    instigator = hit.attackData.GetInstigator();
    sample.targetID = hit.target.GetEntityID();
    sample.targetIsPlayer = hit.target.IsPlayer();
    if IsDefined(npc) {
      sample.targetIsBoss = npc.IsBoss() || Equals(npc.GetNPCRarity(), gamedataNPCRarity.MaxTac);
    }
    gate.targetSupported = IsDefined(puppet) && (sample.targetIsPlayer || IsDefined(npc) && Equals(npc.GetNPCType(), gamedataNPCType.Human));
    gate.projection = hit.projectionPipeline;
    gate.ranged = AttackData.IsRangedOnly(hit.attackData.GetAttackType());
    gate.damageOverTime = AttackData.IsDoT(hit.attackData);
    gate.protectedHit = hit.attackData.HasFlag(hitFlag.DealNoDamage) || hit.attackData.HasFlag(hitFlag.DamageNullified) || hit.attackData.HasFlag(hitFlag.ImmortalTarget) || hit.attackData.HasFlag(hitFlag.CannotModifyDamage) || hit.attackData.HasFlag(hitFlag.DeterministicDamage) || hit.attackData.HasFlag(hitFlag.Kill) || hit.attackData.HasFlag(hitFlag.Nonlethal) || hit.attackData.HasFlag(hitFlag.TargetWasAlreadyDeadNoStatPool) || hit.attackData.HasFlag(hitFlag.FinisherTriggered);
    if IsDefined(puppet) && puppet.IsReplacer() || IsDefined(instigator) && instigator.IsReplacer() {
      gate.protectedHit = true;
    }
    weapon = hit.attackData.GetWeapon();
    if IsDefined(weapon) {
      sample.weaponRecord = ItemID.GetTDBID(weapon.GetItemID());
    }
    while i < ArraySize(Deref(lost)) {
      if Equals(Deref(lost)[i].affectedStatPool, gamedataStatPoolType.Health) {
        // Do not count damage to an armor/limb resource as blood/tissue damage.
        gate.actualHealthDamage += Deref(lost)[i].value;
        if Equals(Deref(lost)[i].type, gamedataDamageType.Physical) {
          sample.nativePhysicalHealthDamage += Deref(lost)[i].value;
          sample.physicalHealthEvaluated = sample.physicalHealthEvaluated || Deref(lost)[i].value >= 0.0;
        }
      }
      i += 1;
    }
    shapes = hit.hitRepresentationResult.hitShapes;
    if ArraySize(shapes) > 32 {
      contact.unknownShape = true;
      return sample;
    }
    i = 0;
    while i < ArraySize(shapes) {
      shape = shapes[i].userData as HitShapeUserDataBase;
      legacyShape = shapes[i].userData as HitData_Base;
      if IsDefined(shape) {
        CRHitModel.AddShape(contact, CRNativeHitAdapter.Region(shape), CRNativeHitAdapter.Material(shape), shape.m_isProtectionLayer, shape.m_isInternalWeakspot);
      } else {
        if IsDefined(legacyShape) {
          CRHitModel.AddShape(contact, 0, 0, Equals(legacyShape.m_hitShapeType, HitShape_Type.ProtectionLayer), legacyShape.IsWeakspot());
        } else {
          CRHitModel.AddShape(contact, 0, 0, false, false);
        }
      }
      i += 1;
    }
    sample.canRoute = CRHitModel.CanRoute(contact, gate);
    if !skipProfiles && CRHitModel.CanProcess(contact, gate) {
      sample.profiles = CRCombatProfilesNative.Read(hit, contact);
    }
    return sample;
  }
}

@addField(gameHitEvent)
public let crContactRead: Bool;

@addField(ScriptedPuppet)
public let crLastNativeHit: ref<CRNativeHitSample>;

// This stage receives the actual resource losses after native damage, including
// native boss caps/protection handling. Computed attack damage is not proof of
// health loss. Retain one bounded transient sample, never a global hit history.
@wrapMethod(DamageSystem)
private final func SendDamageEvents(hitEvent: ref<gameHitEvent>, const resourcesLost: script_ref<[SDamageDealt]>) -> Void {
  let target: ref<ScriptedPuppet>;
  wrappedMethod(hitEvent, resourcesLost);
  if IsDefined(hitEvent) && IsDefined(hitEvent.crBloodLossDelivery) {
    CRBloodLossNative.Acknowledge(hitEvent, resourcesLost);
    return;
  }
  if !CRCombatRuntimePolicy.Enabled() || !IsDefined(hitEvent) || hitEvent.projectionPipeline || hitEvent.crContactRead {
    return;
  }
  hitEvent.crContactRead = true;
  target = hitEvent.target as ScriptedPuppet;
  if IsDefined(target) {
    target.crLastNativeHit = CRNativeHitAdapter.Read(hitEvent, resourcesLost, IsDefined(hitEvent.crPreparedHit));
    if IsDefined(hitEvent.crPreparedHit) {
      target.crLastNativeHit.profiles = hitEvent.crPreparedHit.profiles;
    }
    CRNativeWoundBridge.Commit(hitEvent, target.crLastNativeHit);
  }
}
