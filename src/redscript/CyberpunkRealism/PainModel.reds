// Project-original pain/analgesia model. Authored gameplay response, not clinical
// calibration. Underlying regional injury remains authoritative; analgesia changes
// perceived pain only and never repairs tissue, bone, blood loss or cyberware.
module CyberpunkRealism.Physiology

public class CRPainState extends IScriptable {
  // Concurrent authored analgesic load. One Trauma Kit contributes one unit; load
  // decays through game time. This is not a pharmaceutical dose measurement.
  public persistent let analgesicLoad: Float = 0.0;
  public persistent let dosesTaken: Int32 = 0;
}

public class CRPainProjection extends IScriptable {
  public let valid: Bool = false;
  public let physicalPain: Float = 0.0;
  public let analgesia: Float = 0.0;
  public let perceivedPain: Float = 0.0;
  public let intoxication: Float = 0.0;
  public let nextDoseGain: Float = 0.0;
  public let weaponSway: Float = 1.0;
  public let painSpread: Float = 1.0;
  public let painRecoil: Float = 1.0;
}

public class CRPainModel extends IScriptable {
  public static func Create() -> ref<CRPainState> {
    return new CRPainState();
  }

  public static func Valid(state: ref<CRPainState>) -> Bool {
    return IsDefined(state) && state.analgesicLoad >= 0.0 && state.analgesicLoad <= 16.0 && state.dosesTaken >= 0;
  }

  private static func RegionBurden(region: ref<CRRegionalInjury>, weight: Float) -> Float {
    if !CRInjuryModel.ValidRegion(region) {
      return 0.0;
    }
    // Bone trauma is deliberately more pain-heavy than soft-tissue trauma. Chrome
    // damage is not treated as nociceptive pain by itself; biological tissue around
    // an implant can still hurt through tissue/bone injury.
    let biological: Float = MaxF(region.tissueDamage, MinF(1.0, region.boneDamage * 1.15));
    return ClampF(biological * weight, 0.0, 1.0);
  }

  public static func PhysicalPain(injury: ref<CRInjuryState>) -> Float {
    if !IsDefined(injury) || !CRInjuryModel.ValidState(injury) {
      return 0.0;
    }
    let head: Float = CRPainModel.RegionBurden(injury.head, 1.0);
    let torso: Float = CRPainModel.RegionBurden(injury.torso, 0.95);
    let leftArm: Float = CRPainModel.RegionBurden(injury.leftArm, 0.8);
    let rightArm: Float = CRPainModel.RegionBurden(injury.rightArm, 0.8);
    let leftLeg: Float = CRPainModel.RegionBurden(injury.leftLeg, 0.9);
    let rightLeg: Float = CRPainModel.RegionBurden(injury.rightLeg, 0.9);
    let peak: Float = MaxF(head, MaxF(torso, MaxF(leftArm, MaxF(rightArm, MaxF(leftLeg, rightLeg)))));
    let mean: Float = (head + torso + leftArm + rightArm + leftLeg + rightLeg) / 6.0;
    return ClampF(0.75 * peak + 0.5 * mean, 0.0, 1.0);
  }

  // Saturating response gives diminishing returns by construction. The first kit
  // can meaningfully blunt pain; stacking more can never erase all perceived pain.
  public static func AnalgesiaForLoad(load: Float) -> Float {
    if load <= 0.0 {
      return 0.0;
    }
    return ClampF(0.85 * load / (0.75 + load), 0.0, 0.85);
  }

  // Overuse is intentionally nonlethal in this first authored model. Three or more
  // overlapping kit-equivalents enter the intoxication envelope; exact calibration
  // remains a playtest value. Native presentation may reuse CDPR's drunk/SFX path.
  public static func IntoxicationForLoad(load: Float) -> Float {
    return ClampF((load - 2.0) / 2.0, 0.0, 1.0);
  }

  // Pain handling is separate from structural limb impairment. Analgesia can reduce
  // these factors because they depend on perceived pain, while a damaged arm's
  // mechanical reload/recoil penalties continue to come from CRInjuryEffectsModel.
  public static func WeaponSwayMultiplier(perceivedPain: Float) -> Float {
    return 1.0 + 1.25 * ClampF(perceivedPain, 0.0, 1.0);
  }

  public static func SpreadMultiplier(perceivedPain: Float) -> Float {
    return 1.0 + 0.35 * ClampF(perceivedPain, 0.0, 1.0);
  }

  public static func RecoilMultiplier(perceivedPain: Float) -> Float {
    return 1.0 + 0.20 * ClampF(perceivedPain, 0.0, 1.0);
  }

  public static func Read(injury: ref<CRInjuryState>, state: ref<CRPainState>) -> ref<CRPainProjection> {
    let result: ref<CRPainProjection> = new CRPainProjection();
    if !CRPainModel.Valid(state) || !CRInjuryModel.ValidState(injury) {
      return result;
    }
    result.physicalPain = CRPainModel.PhysicalPain(injury);
    result.analgesia = CRPainModel.AnalgesiaForLoad(state.analgesicLoad);
    result.perceivedPain = result.physicalPain * (1.0 - result.analgesia);
    result.intoxication = CRPainModel.IntoxicationForLoad(state.analgesicLoad);
    result.nextDoseGain = CRPainModel.AnalgesiaForLoad(MinF(16.0, state.analgesicLoad + 1.0)) - result.analgesia;
    result.weaponSway = CRPainModel.WeaponSwayMultiplier(result.perceivedPain);
    result.painSpread = CRPainModel.SpreadMultiplier(result.perceivedPain);
    result.painRecoil = CRPainModel.RecoilMultiplier(result.perceivedPain);
    result.valid = true;
    return result;
  }

  public static func UseTraumaKit(state: ref<CRPainState>) -> Bool {
    if !CRPainModel.Valid(state) || state.analgesicLoad + 1.0 > 16.0 {
      return false;
    }
    state.analgesicLoad += 1.0;
    state.dosesTaken += 1;
    return true;
  }

  public static func Advance(state: ref<CRPainState>, hours: Float) -> Bool {
    if !CRPainModel.Valid(state) || hours < 0.0 || hours > 72.0 {
      return false;
    }
    // Provisional authored decay: one load unit clears over two game-hours. This
    // will be calibrated in play; it is deliberately linear and deterministic.
    state.analgesicLoad = MaxF(0.0, state.analgesicLoad - 0.5 * hours);
    return true;
  }
}
