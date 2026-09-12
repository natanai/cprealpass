// Original provisional gameplay projection of regional injury and blood loss.
module CyberpunkRealism.Physiology
public class CRInjuryEffects extends IScriptable {
  public let valid: Bool = false;
  public let speed: Float = 1.0;
  public let stamina: Float = 1.0;
  public let staminaRegen: Float = 1.0;
  public let reload: Float = 1.0;
  public let recoil: Float = 1.0;
  public let spread: Float = 1.0;
}
public class CRInjuryEffectsModel extends IScriptable {
  public static func Read(s: ref<CRInjuryState>, c: ref<CRBodyConfig>) -> ref<CRInjuryEffects> {
    let result: ref<CRInjuryEffects> = new CRInjuryEffects();
    let head: Float;
    let torso: Float;
    let arms: Float;
    let legs: Float;
    let blood: Float;
    if !IsDefined(s) || !CRInjuryModel.CanAdvance(s, c) {
      return result;
    }
    head = 1.0 - CRInjuryModel.Function(s, 1);
    torso = 1.0 - CRInjuryModel.Function(s, 2);
    arms = 1.0 - 0.5 * (CRInjuryModel.Function(s, 3) + CRInjuryModel.Function(s, 4));
    legs = 1.0 - MinF(CRInjuryModel.Function(s, 5), CRInjuryModel.Function(s, 6));
    // This response curve is authored gameplay tuning, not clinical calibration.
    blood = ClampF((s.bloodDeficitMl / c.injuryBloodCapacityMl - 0.1) / 0.4, 0.0, 1.0);
    result.speed = MaxF(0.2, 1.0 - 0.75 * legs - 0.25 * blood);
    result.stamina = MaxF(0.15, 1.0 - 0.45 * torso - 0.7 * blood);
    result.staminaRegen = MaxF(0.15, 1.0 - 0.3 * torso - 0.8 * blood);
    result.reload = 1.0 + 1.1 * arms + 0.3 * blood;
    result.recoil = 1.0 + 0.8 * arms + 0.35 * head + 0.5 * blood;
    result.spread = 1.0 + 0.9 * arms + 0.8 * head + 0.5 * blood;
    result.valid = true;
    return result;
  }
}