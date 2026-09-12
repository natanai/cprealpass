// Original persistent regional armor condition. Values are normalized wear,
// driven by absorbed projectile energy rather than actor health damage.
module CyberpunkRealism.Combat
public class CRArmorCondition extends IScriptable {
  public persistent let head: Float = 0.0;
  public persistent let torso: Float = 0.0;
  public persistent let leftArm: Float = 0.0;
  public persistent let rightArm: Float = 0.0;
  public persistent let leftLeg: Float = 0.0;
  public persistent let rightLeg: Float = 0.0;
}
public class CRArmorWearModel extends IScriptable {
  public static func Valid(s: ref<CRArmorCondition>) -> Bool {
    return IsDefined(s) && CRImpactModel.InRange(s.head, 0.0, 1.0) && CRImpactModel.InRange(s.torso, 0.0, 1.0) && CRImpactModel.InRange(s.leftArm, 0.0, 1.0) && CRImpactModel.InRange(s.rightArm, 0.0, 1.0) && CRImpactModel.InRange(s.leftLeg, 0.0, 1.0) && CRImpactModel.InRange(s.rightLeg, 0.0, 1.0);
  }
  public static func Integrity(s: ref<CRArmorCondition>, region: Int32) -> Float {
    if !CRArmorWearModel.Valid(s) {
      return -1.0;
    }
    if region == 1 {
      return 1.0 - s.head;
    }
    if region == 2 {
      return 1.0 - s.torso;
    }
    if region == 3 {
      return 1.0 - s.leftArm;
    }
    if region == 4 {
      return 1.0 - s.rightArm;
    }
    if region == 5 {
      return 1.0 - s.leftLeg;
    }
    if region == 6 {
      return 1.0 - s.rightLeg;
    }
    return -1.0;
  }
  public static func Dose(absorbedJ: Float, durabilityJ: Float) -> Float {
    if !CRImpactModel.InRange(absorbedJ, 0.0, 125000000.0) || !CRImpactModel.InRange(durabilityJ, 0.001, 1000000000.0) {
      return -1.0;
    }
    return MinF(1.0, absorbedJ / durabilityJ);
  }
  public static func Apply(s: ref<CRArmorCondition>, region: Int32, dose: Float) -> Bool {
    let integrity: Float = CRArmorWearModel.Integrity(s, region);
    if integrity < 0.0 || !CRImpactModel.InRange(dose, 0.0, 1.0) {
      return false;
    }
    if dose == 0.0 {
      return true;
    }
    let wear: Float = MinF(1.0, 1.0 - integrity + dose);
    if region == 1 {
      s.head = wear;
    }
    if region == 2 {
      s.torso = wear;
    }
    if region == 3 {
      s.leftArm = wear;
    }
    if region == 4 {
      s.rightArm = wear;
    }
    if region == 5 {
      s.leftLeg = wear;
    }
    if region == 6 {
      s.rightLeg = wear;
    }
    return true;
  }
  public static func Accepted(proposed: Float, finalPhysical: Float, actualPhysical: Float, healthEvaluated: Bool, nativeProtection: Bool) -> Bool {
    if !CRImpactModel.InRange(proposed, 0.0, 1000000000.0) || !CRImpactModel.InRange(finalPhysical, 0.0, 1000000000.0) || !CRImpactModel.InRange(actualPhysical, 0.0, 1000000000.0) {
      return false;
    }
    if actualPhysical > 0.0 && proposed > 0.0 && finalPhysical > 0.0 {
      return true;
    }
    // Our own complete stop can wear armor without a wound. An explicit zero
    // physical Health entry confirms evaluation; native protection shapes are
    // excluded because their veto is not proof of a physical armor contact.
    return proposed == 0.0 && finalPhysical == 0.0 && actualPhysical == 0.0 && healthEvaluated && !nativeProtection;
  }
}