// Original provisional game profiles. Values are authored archetypes, not
// claims about the caliber or construction of Cyberpunk's fictional weapons.
module CyberpunkRealism.Combat

public class CRBallisticProfile extends IScriptable {
  public let family: Int32;
  public let massGrams: Float;
  public let muzzleSpeed: Float;
  public let diameterMm: Float;
  public let penetrationFactor: Float = 1.0;
  public let speedHalfDistanceM: Float;
  public let ricochetSpeedRetention: Float = 0.7;
  public let chargeSpeedGain: Float = 0.0;
}

public class CRBallisticProfiles extends IScriptable {
  // 1 handgun, 2 revolver, 3 intermediate rifle, 4 full-size rifle,
  // 5 shotgun pellet, 6 precision/sniper, 7 submachine gun.
  public static func Family(family: Int32) -> ref<CRBallisticProfile> {
    let p: ref<CRBallisticProfile> = new CRBallisticProfile();
    p.family = family;
    if family == 1 || family == 7 {
      p.massGrams = 8.0;
      p.muzzleSpeed = 360.0;
      p.diameterMm = 9.0;
      p.speedHalfDistanceM = 350.0;
      if family == 7 {
        p.muzzleSpeed = 400.0;
      }
    }
    if family == 2 {
      p.massGrams = 15.0;
      p.muzzleSpeed = 420.0;
      p.diameterMm = 11.0;
      p.speedHalfDistanceM = 350.0;
    }
    if family == 3 {
      p.massGrams = 4.0;
      p.muzzleSpeed = 900.0;
      p.diameterMm = 5.6;
      p.speedHalfDistanceM = 900.0;
    }
    if family == 4 || family == 6 {
      p.massGrams = 9.5;
      p.muzzleSpeed = 800.0;
      p.diameterMm = 7.8;
      p.speedHalfDistanceM = 1200.0;
      if family == 6 {
        p.massGrams = 12.0;
        p.muzzleSpeed = 850.0;
      }
    }
    if family == 5 {
      p.massGrams = 3.5;
      p.muzzleSpeed = 380.0;
      p.diameterMm = 8.4;
      p.speedHalfDistanceM = 120.0;
    }
    return p;
  }

  public static func Valid(p: ref<CRBallisticProfile>) -> Bool {
    if !IsDefined(p) {
      return false;
    }
    return p.family >= 1 && p.family <= 7 && CRImpactModel.InRange(p.massGrams, 0.001, 10000.0) && CRImpactModel.InRange(p.muzzleSpeed, 0.0, 5000.0) && CRImpactModel.InRange(p.diameterMm, 0.01, 500.0) && CRImpactModel.InRange(p.penetrationFactor, 0.01, 100.0) && CRImpactModel.InRange(p.speedHalfDistanceM, 1.0, 100000.0) && CRImpactModel.InRange(p.ricochetSpeedRetention, 0.0, 1.0) && CRImpactModel.InRange(p.chargeSpeedGain, 0.0, 4.0);
  }

  public static func Projectile(p: ref<CRBallisticProfile>, distanceM: Float, bounces: Int32, charge: Float) -> ref<CRProjectileSpec> {
    let shot: ref<CRProjectileSpec>;
    let speed: Float;
    let i: Int32 = 0;
    if !CRBallisticProfiles.Valid(p) || !CRImpactModel.InRange(distanceM, 0.0, 100000.0) || bounces < 0 || bounces > 16 || !CRImpactModel.InRange(charge, 0.0, 1.0) {
      return null;
    }
    // Continuous, provisional drag curve. No level, rarity, DPS or HP input.
    speed = p.muzzleSpeed * (1.0 + p.chargeSpeedGain * charge) / (1.0 + distanceM / p.speedHalfDistanceM);
    while i < bounces {
      speed *= p.ricochetSpeedRetention;
      i += 1;
    }
    if !CRImpactModel.InRange(speed, 0.0, 5000.0) {
      return null;
    }
    shot = new CRProjectileSpec();
    shot.massGrams = p.massGrams;
    shot.speedMetersPerSecond = speed;
    shot.diameterMm = p.diameterMm;
    shot.penetrationFactor = p.penetrationFactor;
    return shot;
  }
}

public class CRProtectionProfile extends IScriptable {
  public let mapped: Bool;
  public let head: Bool;
  public let torso: Bool;
  public let leftArm: Bool;
  public let rightArm: Bool;
  public let leftLeg: Bool;
  public let rightLeg: Bool;
  public let resistanceJPerMm2: Float;
  public let durabilityJ: Float;
  public let bluntTransferFraction: Float;
}

public class CRCoverageModel extends IScriptable {
  public static func Covers(p: ref<CRProtectionProfile>, region: Int32) -> Bool {
    if !IsDefined(p) || !p.mapped {
      return false;
    }
    if region == 1 {
      return p.head;
    }
    if region == 2 {
      return p.torso;
    }
    if region == 3 {
      return p.leftArm;
    }
    if region == 4 {
      return p.rightArm;
    }
    if region == 5 {
      return p.leftLeg;
    }
    if region == 6 {
      return p.rightLeg;
    }
    return false;
  }

  // Null means unmapped/invalid, distinct from a known uncovered region.
  public static func Layer(p: ref<CRProtectionProfile>, region: Int32, integrity: Float) -> ref<CRProtectionLayer> {
    let result: ref<CRProtectionLayer>;
    if !IsDefined(p) || !p.mapped || region < 1 || region > 6 {
      return null;
    }
    result = new CRProtectionLayer();
    result.covered = CRCoverageModel.Covers(p, region);
    result.resistanceJPerMm2 = p.resistanceJPerMm2;
    result.durabilityJ = p.durabilityJ;
    result.bluntTransferFraction = p.bluntTransferFraction;
    result.integrity = integrity;
    if !CRImpactModel.ValidLayer(result) {
      return null;
    }
    return result;
  }
}
