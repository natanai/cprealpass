// Original injury bookkeeping for the shared body clock. Provisional game
// parameters: no clinical diagnosis, native HP changes, effects or timers.
module CyberpunkRealism.Physiology

public class CRRegionalInjury extends IScriptable {
  public persistent let tissueDamage: Float;
  public persistent let boneDamage: Float;
  public persistent let cyberwareDamage: Float;
  public persistent let externalBleedMlPerHour: Float;
  public persistent let internalBleedMlPerHour: Float;
  public persistent let support: Float;
  public persistent let clinicalCare: Float;
}

public class CRInjuryState extends IScriptable {
  public persistent let head: ref<CRRegionalInjury>;
  public persistent let torso: ref<CRRegionalInjury>;
  public persistent let leftArm: ref<CRRegionalInjury>;
  public persistent let rightArm: ref<CRRegionalInjury>;
  public persistent let leftLeg: ref<CRRegionalInjury>;
  public persistent let rightLeg: ref<CRRegionalInjury>;
  public persistent let bloodDeficitMl: Float;
  public persistent let bloodLostMl: Float;
  public persistent let bloodRecoveredMl: Float;
  // Cumulative authored health-fraction demand; never a native damage receipt.
  public persistent let bloodLossExposure: Float;
}

public class CRInjuryModel extends IScriptable {
  private static func Range(value: Float, low: Float, high: Float) -> Bool {
    return value >= low && value <= high;
  }

  public static func Create() -> ref<CRInjuryState> {
    let s: ref<CRInjuryState> = new CRInjuryState();
    s.head = new CRRegionalInjury();
    s.torso = new CRRegionalInjury();
    s.leftArm = new CRRegionalInjury();
    s.rightArm = new CRRegionalInjury();
    s.leftLeg = new CRRegionalInjury();
    s.rightLeg = new CRRegionalInjury();
    return s;
  }

  public static func Region(s: ref<CRInjuryState>, region: Int32) -> ref<CRRegionalInjury> {
    if !IsDefined(s) {
      return null;
    }
    if region == 1 {
      return s.head;
    }
    if region == 2 {
      return s.torso;
    }
    if region == 3 {
      return s.leftArm;
    }
    if region == 4 {
      return s.rightArm;
    }
    if region == 5 {
      return s.leftLeg;
    }
    if region == 6 {
      return s.rightLeg;
    }
    return null;
  }

  public static func ValidRegion(r: ref<CRRegionalInjury>) -> Bool {
    if !IsDefined(r) {
      return false;
    }
    return CRInjuryModel.Range(r.tissueDamage, 0.0, 1.0) && CRInjuryModel.Range(r.boneDamage, 0.0, 1.0) && CRInjuryModel.Range(r.cyberwareDamage, 0.0, 1.0) && CRInjuryModel.Range(r.externalBleedMlPerHour, 0.0, 1000000.0) && CRInjuryModel.Range(r.internalBleedMlPerHour, 0.0, 1000000.0) && CRInjuryModel.Range(r.support, 0.0, 1.0) && CRInjuryModel.Range(r.clinicalCare, 0.0, 1.0);
  }

  // A missing added field denotes an old uninjured prototype state. Once an
  // injury object exists, all regions and accounting must validate completely.
  public static func ValidState(s: ref<CRInjuryState>) -> Bool {
    let i: Int32 = 1;
    let j: Int32;
    let sum: Float;
    let tolerance: Float;
    if !IsDefined(s) {
      return true;
    }
    while i <= 6 {
      if !CRInjuryModel.ValidRegion(CRInjuryModel.Region(s, i)) {
        return false;
      }
      j = i + 1;
      while j <= 6 {
        if CRInjuryModel.Region(s, i) == CRInjuryModel.Region(s, j) {
          return false;
        }
        j += 1;
      }
      i += 1;
    }
    if !CRInjuryModel.Range(s.bloodLossExposure, 0.0, 1000000.0) || !CRInjuryModel.Range(s.bloodDeficitMl, 0.0, 100000.0) || !CRInjuryModel.Range(s.bloodLostMl, 0.0, 1000000000.0) || !CRInjuryModel.Range(s.bloodRecoveredMl, 0.0, s.bloodLostMl) {
      return false;
    }
    sum = s.bloodDeficitMl + s.bloodRecoveredMl;
    tolerance = MaxF(0.01, s.bloodLostMl * 0.00001);
    return sum >= s.bloodLostMl - tolerance && sum <= s.bloodLostMl + tolerance;
  }

  public static func ValidConfig(c: ref<CRBodyConfig>) -> Bool {
    if !IsDefined(c) {
      return false;
    }
    return CRInjuryModel.Range(c.injuryBloodCapacityMl, 1.0, 100000.0) && CRInjuryModel.Range(c.injuryBloodWaterFraction, 0.01, 1.0) && CRInjuryModel.Range(c.injuryTissueRecoveryPerHour, 0.0, 1.0) && CRInjuryModel.Range(c.injuryBoneRecoveryPerHour, 0.0, 1.0) && CRInjuryModel.Range(c.injuryClinicalRecoveryMultiplier, 1.0, 10.0) && CRInjuryModel.Range(c.injuryExternalClotPerHourSquared, 0.0, 1000000.0) && CRInjuryModel.Range(c.injuryBloodRecoveryMlPerHour, 0.0, 1000.0) && CRInjuryModel.Range(c.injuryMetabolicKcalPerHour, 0.0, 100.0) && CRInjuryModel.Range(c.injuryExertionBleedMultiplier, 0.0, 10.0);
  }

  public static func CanAdvance(s: ref<CRInjuryState>, c: ref<CRBodyConfig>) -> Bool {
    if !CRInjuryModel.ValidState(s) || !CRInjuryModel.ValidConfig(c) {
      return false;
    }
    return !IsDefined(s) || s.bloodDeficitMl <= c.injuryBloodCapacityMl;
  }
  public static func ValidWound(tissue: Float, bone: Float, cyberware: Float, externalBleed: Float, internalBleed: Float) -> Bool {
    return CRInjuryModel.Range(tissue, 0.0, 1.0) && CRInjuryModel.Range(bone, 0.0, 1.0) && CRInjuryModel.Range(cyberware, 0.0, 1.0) && CRInjuryModel.Range(externalBleed, 0.0, 100000.0) && CRInjuryModel.Range(internalBleed, 0.0, 100000.0) && (tissue + bone + cyberware + externalBleed + internalBleed > 0.0);
  }

  public static func Wound(s: ref<CRInjuryState>, region: Int32, tissue: Float, bone: Float, cyberware: Float, externalBleed: Float, internalBleed: Float) -> Bool {
    let r: ref<CRRegionalInjury>;
    if !IsDefined(s) || !CRInjuryModel.ValidState(s) || !CRInjuryModel.ValidWound(tissue, bone, cyberware, externalBleed, internalBleed) {
      return false;
    }
    r = CRInjuryModel.Region(s, region);
    if !IsDefined(r) || r.externalBleedMlPerHour + externalBleed > 1000000.0 || r.internalBleedMlPerHour + internalBleed > 1000000.0 {
      return false;
    }
    r.tissueDamage = MinF(1.0, r.tissueDamage + tissue);
    r.boneDamage = MinF(1.0, r.boneDamage + bone);
    r.cyberwareDamage = MinF(1.0, r.cyberwareDamage + cyberware);
    r.externalBleedMlPerHour += externalBleed;
    r.internalBleedMlPerHour += internalBleed;
    if tissue + bone + externalBleed + internalBleed > 0.0 {
      r.clinicalCare = 0.0;
    }
    if bone > 0.0 {
      r.support = 0.0;
    }
    return true;
  }

  // 2 dressing, 3 support, 4 completed clinical care, 5 mechanical repair.
  // These represent committed game interactions; native costs/items are separate.
  public static func Treat(s: ref<CRInjuryState>, region: Int32, kind: Int32, effectiveness: Float) -> Bool {
    let r: ref<CRRegionalInjury>;
    if !IsDefined(s) || !CRInjuryModel.ValidState(s) || kind < 2 || kind > 5 || !CRInjuryModel.Range(effectiveness, 0.0, 1.0) {
      return false;
    }
    r = CRInjuryModel.Region(s, region);
    if !IsDefined(r) {
      return false;
    }
    if kind == 2 {
      r.externalBleedMlPerHour *= 1.0 - effectiveness;
    }
    if kind == 3 {
      r.support = MaxF(r.support, effectiveness);
    }
    if kind == 4 {
      r.externalBleedMlPerHour *= 1.0 - effectiveness;
      r.internalBleedMlPerHour *= 1.0 - effectiveness;
      if effectiveness > 0.0 {
        r.clinicalCare = MaxF(r.clinicalCare, effectiveness);
      }
    }
    if kind == 5 {
      r.cyberwareDamage *= 1.0 - effectiveness;
    }
    return true;
  }

  public static func Function(s: ref<CRInjuryState>, region: Int32) -> Float {
    let r: ref<CRRegionalInjury>;
    if region < 1 || region > 6 || !CRInjuryModel.ValidState(s) {
      return -1.0;
    }
    if !IsDefined(s) {
      return 1.0;
    }
    r = CRInjuryModel.Region(s, region);
    return 1.0 - MaxF(r.tissueDamage, MaxF(r.boneDamage * (1.0 - 0.4 * r.support), r.cyberwareDamage));
  }

  public static func TissueBurden(s: ref<CRInjuryState>) -> Float {
    let total: Float = 0.0;
    let i: Int32 = 1;
    if !IsDefined(s) {
      return total;
    }
    while i <= 6 {
      total += CRInjuryModel.Region(s, i).tissueDamage;
      i += 1;
    }
    return total;
  }

  // Called only from the body's existing minute/fractional step. Return value
  // is blood lost during this interval; the caller removes its water fraction
  // from the one shared body-water pool. Recovery redistributes existing body
  // resources; it never creates water, restores HP or repairs chrome.
  public static func Advance(s: ref<CRInjuryState>, c: ref<CRBodyConfig>, hours: Float, activity: Float, recoveryFactor: Float, availableWaterMl: Float) -> Float {
    let i: Int32 = 1;
    let r: ref<CRRegionalInjury>;
    let activeHours: Float;
    let externalEnd: Float;
    let demand: Float = 0.0;
    let lost: Float;
    let restored: Float;
    let repair: Float;
    let startDeficit: Float;
    if !IsDefined(s) {
      return 0.0;
    }
    if !CRInjuryModel.ValidState(s) || !CRInjuryModel.ValidConfig(c) || !CRInjuryModel.Range(hours, 0.0, 72.0) || !CRInjuryModel.Range(activity, 0.0, 1.0) || !CRInjuryModel.Range(recoveryFactor, 0.0, 2.0) || !CRInjuryModel.Range(availableWaterMl, 0.0, 1000000.0) || s.bloodDeficitMl > c.injuryBloodCapacityMl {
      return -1.0;
    }
    startDeficit = s.bloodDeficitMl;
    while i <= 6 {
      r = CRInjuryModel.Region(s, i);
      activeHours = hours;
      if c.injuryExternalClotPerHourSquared > 0.0 {
        activeHours = MinF(hours, r.externalBleedMlPerHour / c.injuryExternalClotPerHourSquared);
      }
      externalEnd = MaxF(0.0, r.externalBleedMlPerHour - c.injuryExternalClotPerHourSquared * hours);
      demand += 0.5 * (r.externalBleedMlPerHour + externalEnd) * activeHours + r.internalBleedMlPerHour * hours;
      r.externalBleedMlPerHour = externalEnd;
      repair = hours * recoveryFactor;
      if r.clinicalCare > 0.0 {
        repair *= 1.0 + (c.injuryClinicalRecoveryMultiplier - 1.0) * r.clinicalCare;
      }
      r.tissueDamage = MaxF(0.0, r.tissueDamage - c.injuryTissueRecoveryPerHour * repair);
      if r.clinicalCare > 0.0 || r.support > 0.0 {
        r.boneDamage = MaxF(0.0, r.boneDamage - c.injuryBoneRecoveryPerHour * repair * MaxF(r.clinicalCare, r.support));
      }
      i += 1;
    }
    demand *= 1.0 + activity * c.injuryExertionBleedMultiplier;
    lost = MinF(demand, MinF(c.injuryBloodCapacityMl - s.bloodDeficitMl, availableWaterMl / c.injuryBloodWaterFraction));
    s.bloodDeficitMl += lost;
    s.bloodLostMl += lost;
    restored = MinF(s.bloodDeficitMl, c.injuryBloodRecoveryMlPerHour * recoveryFactor * hours);
    s.bloodDeficitMl -= restored;
    s.bloodRecoveredMl += restored;
    // Left endpoint: a newly crossed threshold cannot charge the whole prior
    // minute. Minute/fraction boundaries are shared by V, NPCs and forecasts.
    s.bloodLossExposure = MinF(1000000.0, s.bloodLossExposure + CRInjuryModel.BloodLossRate(startDeficit, c.injuryBloodCapacityMl) * hours);
    return lost;
  }

  // Authored gameplay response, not clinical calibration: demand starts above
  // 30% missing blood and reaches two maximum-health fractions per game hour
  // at 50%. The native delivery adapter retains all engine health protections.
  public static func BloodLossRate(deficit: Float, capacity: Float) -> Float {
    if !(capacity >= 1.0 && capacity <= 100000.0) || !(deficit >= 0.0 && deficit <= capacity) {
      return 0.0;
    }
    return 2.0 * ClampF((deficit / capacity - 0.3) / 0.2, 0.0, 1.0);
  }
  private static func CopyRegion(r: ref<CRRegionalInjury>) -> ref<CRRegionalInjury> {
    let copy: ref<CRRegionalInjury> = new CRRegionalInjury();
    copy.tissueDamage = r.tissueDamage;
    copy.boneDamage = r.boneDamage;
    copy.cyberwareDamage = r.cyberwareDamage;
    copy.externalBleedMlPerHour = r.externalBleedMlPerHour;
    copy.internalBleedMlPerHour = r.internalBleedMlPerHour;
    copy.support = r.support;
    copy.clinicalCare = r.clinicalCare;
    return copy;
  }

  public static func Copy(s: ref<CRInjuryState>) -> ref<CRInjuryState> {
    let copy: ref<CRInjuryState>;
    if !IsDefined(s) || !CRInjuryModel.ValidState(s) {
      return null;
    }
    copy = new CRInjuryState();
    copy.head = CRInjuryModel.CopyRegion(s.head);
    copy.torso = CRInjuryModel.CopyRegion(s.torso);
    copy.leftArm = CRInjuryModel.CopyRegion(s.leftArm);
    copy.rightArm = CRInjuryModel.CopyRegion(s.rightArm);
    copy.leftLeg = CRInjuryModel.CopyRegion(s.leftLeg);
    copy.rightLeg = CRInjuryModel.CopyRegion(s.rightLeg);
    copy.bloodDeficitMl = s.bloodDeficitMl;
    copy.bloodLostMl = s.bloodLostMl;
    copy.bloodRecoveredMl = s.bloodRecoveredMl;
    copy.bloodLossExposure = s.bloodLossExposure;
    return copy;
  }
}
