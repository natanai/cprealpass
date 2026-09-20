// Original provisional terminal-impact mapping. Parameters are authored game
// abstractions awaiting material/anatomy calibration, not clinical predictions.
module CyberpunkRealism.Combat

public class CRAnatomyProfile extends IScriptable {
  public let valid: Bool = false;
  public let region: Int32;
  public let material: Int32;
  public let depositFraction: Float;
  public let boneFraction: Float;
  public let mechanicalFraction: Float;
  public let tissueCapacityJ: Float;
  public let boneCapacityJ: Float;
  public let mechanicalCapacityJ: Float;
  public let externalBleedAtFullMlPerHour: Float;
  public let internalBleedAtFullMlPerHour: Float;
  public let internalBleedThreshold: Float;
  public let nativeHealthFractionAtFull: Float;
}

public class CRImpactWound extends IScriptable {
  public let valid: Bool = false;
  public let region: Int32;
  public let penetratingDepositJ: Float;
  public let exitingJ: Float;
  public let bluntJ: Float;
  public let tissueDamage: Float;
  public let boneDamage: Float;
  public let cyberwareDamage: Float;
  public let externalBleedMlPerHour: Float;
  public let internalBleedMlPerHour: Float;
  public let nativeHealthFraction: Float;
}

public class CRWoundModel extends IScriptable {
  // Hit-shape material is only the struck structure. It does not infer that
  // clothing is unarmored, or that an entire NPC is biological/cybernetic.
  public static func Anatomy(region: Int32, material: Int32) -> ref<CRAnatomyProfile> {
    let p: ref<CRAnatomyProfile> = new CRAnatomyProfile();
    p.region = region;
    p.material = material;
    if region < 1 || region > 6 || (material != 1 && material != 3 && material != 4) {
      return p;
    }
    p.depositFraction = 0.4;
    p.boneFraction = 0.2;
    p.mechanicalFraction = 0.0;
    p.tissueCapacityJ = 350.0;
    p.boneCapacityJ = 300.0;
    p.mechanicalCapacityJ = 900.0;
    p.externalBleedAtFullMlPerHour = 6000.0;
    p.internalBleedAtFullMlPerHour = 1000.0;
    p.internalBleedThreshold = 0.6;
    p.nativeHealthFractionAtFull = 0.25;
    if region == 1 {
      p.depositFraction = 0.7;
      p.boneFraction = 0.35;
      p.tissueCapacityJ = 160.0;
      p.boneCapacityJ = 150.0;
      p.externalBleedAtFullMlPerHour = 4000.0;
      p.internalBleedAtFullMlPerHour = 3000.0;
      p.internalBleedThreshold = 0.5;
      p.nativeHealthFractionAtFull = 1.5;
    }
    if region == 2 {
      p.depositFraction = 0.65;
      p.boneFraction = 0.1;
      p.tissueCapacityJ = 900.0;
      p.boneCapacityJ = 600.0;
      p.externalBleedAtFullMlPerHour = 1500.0;
      p.internalBleedAtFullMlPerHour = 12000.0;
      p.internalBleedThreshold = 0.45;
      p.nativeHealthFractionAtFull = 1.2;
    }
    if material == 3 || material == 4 {
      p.mechanicalFraction = 1.0;
      p.boneFraction = 0.0;
      p.externalBleedAtFullMlPerHour = 0.0;
      p.internalBleedAtFullMlPerHour = 0.0;
    }
    p.valid = true;
    return p;
  }

  public static func ValidProfile(p: ref<CRAnatomyProfile>) -> Bool {
    if !IsDefined(p) || !p.valid {
      return false;
    }
    return p.region >= 1 && p.region <= 6 && (p.material == 1 || p.material == 3 || p.material == 4) && CRImpactModel.InRange(p.depositFraction, 0.0, 1.0) && CRImpactModel.InRange(p.boneFraction, 0.0, 1.0) && CRImpactModel.InRange(p.mechanicalFraction, 0.0, 1.0) && p.boneFraction + p.mechanicalFraction <= 1.0 && CRImpactModel.InRange(p.tissueCapacityJ, 1.0, 1000000.0) && CRImpactModel.InRange(p.boneCapacityJ, 1.0, 1000000.0) && CRImpactModel.InRange(p.mechanicalCapacityJ, 1.0, 1000000.0) && CRImpactModel.InRange(p.externalBleedAtFullMlPerHour, 0.0, 100000.0) && CRImpactModel.InRange(p.internalBleedAtFullMlPerHour, 0.0, 100000.0) && CRImpactModel.InRange(p.internalBleedThreshold, 0.0, 0.99) && CRImpactModel.InRange(p.nativeHealthFractionAtFull, 0.0, 4.0);
  }

  public static func Resolve(impact: ref<CRImpactState>, p: ref<CRAnatomyProfile>) -> ref<CRImpactWound> {
    let w: ref<CRImpactWound> = new CRImpactWound();
    let tissueFraction: Float;
    let penetratingTissue: Float;
    let biologicalBlunt: Float;
    if !CRImpactModel.ValidState(impact) || !CRWoundModel.ValidProfile(p) {
      return w;
    }
    w.region = p.region;
    w.penetratingDepositJ = impact.remainingJ * p.depositFraction;
    w.exitingJ = impact.remainingJ - w.penetratingDepositJ;
    w.bluntJ = impact.bluntJ;
    tissueFraction = 1.0 - p.boneFraction - p.mechanicalFraction;
    penetratingTissue = ClampF(w.penetratingDepositJ * tissueFraction / p.tissueCapacityJ, 0.0, 1.0);
    biologicalBlunt = w.bluntJ * (1.0 - p.mechanicalFraction);
    w.tissueDamage = ClampF(penetratingTissue + biologicalBlunt * (1.0 - p.boneFraction) / p.tissueCapacityJ, 0.0, 1.0);
    w.boneDamage = ClampF((w.penetratingDepositJ + biologicalBlunt) * p.boneFraction / p.boneCapacityJ, 0.0, 1.0);
    w.cyberwareDamage = ClampF((w.penetratingDepositJ + w.bluntJ) * p.mechanicalFraction / p.mechanicalCapacityJ, 0.0, 1.0);
    // A stopped projectile may bruise/break a structure through blunt load,
    // but it cannot manufacture an open bleeding tract.
    w.externalBleedMlPerHour = penetratingTissue * p.externalBleedAtFullMlPerHour;
    // Minor bruising must not become an indefinitely bleeding internal wound.
    // This regional threshold is provisional; vascular/anatomy bindings remain open.
    w.internalBleedMlPerHour = MaxF(0.0, w.tissueDamage - p.internalBleedThreshold) / (1.0 - p.internalBleedThreshold) * p.internalBleedAtFullMlPerHour;
    w.nativeHealthFraction = MaxF(0.75 * w.tissueDamage + 0.25 * w.boneDamage, w.cyberwareDamage) * p.nativeHealthFractionAtFull;
    w.valid = true;
    return w;
  }

  public static func ValidWound(w: ref<CRImpactWound>) -> Bool {
    if !IsDefined(w) || !w.valid {
      return false;
    }
    return w.region >= 1 && w.region <= 6 && CRImpactModel.InRange(w.penetratingDepositJ, 0.0, 125000000.0) && CRImpactModel.InRange(w.exitingJ, 0.0, 125000000.0) && CRImpactModel.InRange(w.bluntJ, 0.0, 125000000.0) && CRImpactModel.InRange(w.tissueDamage, 0.0, 1.0) && CRImpactModel.InRange(w.boneDamage, 0.0, 1.0) && CRImpactModel.InRange(w.cyberwareDamage, 0.0, 1.0) && CRImpactModel.InRange(w.externalBleedMlPerHour, 0.0, 100000.0) && CRImpactModel.InRange(w.internalBleedMlPerHour, 0.0, 100000.0) && CRImpactModel.InRange(w.nativeHealthFraction, 0.0, 4.0);
  }

  // Native HP is an output adapter. Normalizing to max HP removes level/HP-pool
  // inflation from this physical channel; it is not an input to wound severity.
  public static func NativeDamage(w: ref<CRImpactWound>, maximumHealth: Float) -> Float {
    if !CRWoundModel.ValidWound(w) || !CRImpactModel.InRange(maximumHealth, 1.0, 100000000.0) {
      return -1.0;
    }
    return w.nativeHealthFraction * maximumHealth;
  }

  public static func HasInjury(w: ref<CRImpactWound>) -> Bool {
    if !CRWoundModel.ValidWound(w) {
      return false;
    }
    return w.tissueDamage + w.boneDamage + w.cyberwareDamage + w.externalBleedMlPerHour + w.internalBleedMlPerHour > 0.0;
  }

  // Reconcile one-shot/boss/protection reductions using the final native attack
  // value. Actual HP loss only proves acceptance: low remaining HP must not
  // weaken an otherwise fatal wound, and non-physical losses do not qualify.
  public static func Accepted(w: ref<CRImpactWound>, proposedPhysical: Float, finalPhysical: Float, actualPhysicalHealthLoss: Float) -> ref<CRImpactWound> {
    let scale: Float;
    let result: ref<CRImpactWound>;
    if !CRWoundModel.HasInjury(w) || !CRImpactModel.InRange(proposedPhysical, 0.000001, 1000000000.0) || !CRImpactModel.InRange(finalPhysical, 0.000001, 1000000000.0) || !CRImpactModel.InRange(actualPhysicalHealthLoss, 0.000001, 1000000000.0) {
      return null;
    }
    scale = MinF(1.0, finalPhysical / proposedPhysical);
    result = new CRImpactWound();
    result.valid = true;
    result.region = w.region;
    result.penetratingDepositJ = w.penetratingDepositJ * scale;
    result.exitingJ = w.exitingJ;
    result.bluntJ = w.bluntJ * scale;
    result.tissueDamage = w.tissueDamage * scale;
    result.boneDamage = w.boneDamage * scale;
    result.cyberwareDamage = w.cyberwareDamage * scale;
    result.externalBleedMlPerHour = w.externalBleedMlPerHour * scale;
    result.internalBleedMlPerHour = w.internalBleedMlPerHour * scale;
    result.nativeHealthFraction = w.nativeHealthFraction * scale;
    return result;
  }
}
