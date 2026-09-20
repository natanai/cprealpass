// Deliberate Biology drill-down projection.
// Exact values are exposed only after the player selects a system/region; the
// ordinary Biology overview remains qualitative. These are read-only views over
// the authoritative body/injury/pain state, never a second simulation authority.
module CyberpunkRealism.Presentation

import CyberpunkRealism.Integration.*
import CyberpunkRealism.Physiology.*

public class CRBiologyMetric extends IScriptable {
  public let label: String;
  public let percent: Float;
  public let valueText: String;
}

public class CRBiologyDetailViewModel extends IScriptable {
  public let valid: Bool = false;
  public let title: String;
  public let summary: String;
  public let metrics: array<ref<CRBiologyMetric>>;
}

public class CRBiologyDetailPresentation extends IScriptable {
  private static func Metric(label: String, percent: Float, valueText: String) -> ref<CRBiologyMetric> {
    let metric: ref<CRBiologyMetric> = new CRBiologyMetric();
    metric.label = label;
    metric.percent = ClampF(percent, 0.0, 100.0);
    metric.valueText = valueText;
    return metric;
  }

  private static func PercentText(value: Float) -> String {
    return ToString(Cast<Float>(RoundF(ClampF(value, 0.0, 100.0) * 10.0)) / 10.0) + "%";
  }

  private static func IntegrityText(damage: Float) -> String {
    return CRBiologyDetailPresentation.PercentText((1.0 - ClampF(damage, 0.0, 1.0)) * 100.0);
  }

  private static func RegionSummary(region: Int32) -> String {
    let descriptor: ref<CRConditionDescriptor> = CRConditionPresentation.Current(region);
    if !IsDefined(descriptor) || !descriptor.valid || !descriptor.hasCondition {
      return "NO CONDITION";
    }
    return descriptor.title + " / " + descriptor.severity;
  }

  private static func AddRegionMetrics(result: ref<CRBiologyDetailViewModel>, injury: ref<CRInjuryState>, region: Int32) -> Void {
    let regional: ref<CRRegionalInjury> = CRInjuryModel.Region(injury, region);
    if !IsDefined(regional) {
      return;
    }
    let function: Float = CRInjuryModel.Function(injury, region) * 100.0;
    ArrayPush(result.metrics, CRBiologyDetailPresentation.Metric("FUNCTION", function, CRBiologyDetailPresentation.PercentText(function)));
    ArrayPush(result.metrics, CRBiologyDetailPresentation.Metric("TISSUE INTEGRITY", (1.0 - regional.tissueDamage) * 100.0, CRBiologyDetailPresentation.IntegrityText(regional.tissueDamage)));
    ArrayPush(result.metrics, CRBiologyDetailPresentation.Metric("BONE INTEGRITY", (1.0 - regional.boneDamage) * 100.0, CRBiologyDetailPresentation.IntegrityText(regional.boneDamage)));
    ArrayPush(result.metrics, CRBiologyDetailPresentation.Metric("CYBERWARE INTEGRITY", (1.0 - regional.cyberwareDamage) * 100.0, CRBiologyDetailPresentation.IntegrityText(regional.cyberwareDamage)));
    if regional.externalBleedMlPerHour > 0.0 || regional.internalBleedMlPerHour > 0.0 {
      result.summary += "  |  BLEED " + ToString(RoundF(regional.externalBleedMlPerHour)) + "/" + ToString(RoundF(regional.internalBleedMlPerHour)) + " ml/h";
    }
  }

  private static func WorstTissue(injury: ref<CRInjuryState>) -> Float {
    let worst: Float = 0.0;
    let i: Int32 = 1;
    while i <= 6 {
      worst = MaxF(worst, CRInjuryModel.Region(injury, i).tissueDamage);
      i += 1;
    }
    return worst;
  }

  private static func WorstBone(injury: ref<CRInjuryState>) -> Float {
    let worst: Float = 0.0;
    let i: Int32 = 1;
    while i <= 6 {
      worst = MaxF(worst, CRInjuryModel.Region(injury, i).boneDamage);
      i += 1;
    }
    return worst;
  }

  private static func TotalExternalBleed(injury: ref<CRInjuryState>) -> Float {
    let total: Float = 0.0;
    let i: Int32 = 1;
    while i <= 6 {
      total += CRInjuryModel.Region(injury, i).externalBleedMlPerHour;
      i += 1;
    }
    return total;
  }

  private static func TotalInternalBleed(injury: ref<CRInjuryState>) -> Float {
    let total: Float = 0.0;
    let i: Int32 = 1;
    while i <= 6 {
      total += CRInjuryModel.Region(injury, i).internalBleedMlPerHour;
      i += 1;
    }
    return total;
  }

  public static func Supported(area: gamedataEquipmentArea) -> Bool {
    return Equals(area, gamedataEquipmentArea.FrontalCortexCW)
      || Equals(area, gamedataEquipmentArea.CardiovascularSystemCW)
      || Equals(area, gamedataEquipmentArea.NervousSystemCW)
      || Equals(area, gamedataEquipmentArea.SystemReplacementCW)
      || Equals(area, gamedataEquipmentArea.MusculoskeletalSystemCW)
      || Equals(area, gamedataEquipmentArea.IntegumentarySystemCW)
      || Equals(area, gamedataEquipmentArea.ArmsCW)
      || Equals(area, gamedataEquipmentArea.LegsCW);
  }

  public static func Label(area: gamedataEquipmentArea) -> String {
    if Equals(area, gamedataEquipmentArea.FrontalCortexCW) { return "HEAD / BRAIN"; }
    if Equals(area, gamedataEquipmentArea.CardiovascularSystemCW) { return "CIRCULATION"; }
    if Equals(area, gamedataEquipmentArea.NervousSystemCW) { return "NERVOUS"; }
    if Equals(area, gamedataEquipmentArea.SystemReplacementCW) { return "METABOLISM"; }
    if Equals(area, gamedataEquipmentArea.MusculoskeletalSystemCW) { return "MUSCULOSKELETAL"; }
    if Equals(area, gamedataEquipmentArea.IntegumentarySystemCW) { return "SKIN / WOUNDS"; }
    if Equals(area, gamedataEquipmentArea.ArmsCW) { return "ARMS"; }
    if Equals(area, gamedataEquipmentArea.LegsCW) { return "LEGS"; }
    return "";
  }

  public static func Current(area: gamedataEquipmentArea) -> ref<CRBiologyDetailViewModel> {
    let result: ref<CRBiologyDetailViewModel> = new CRBiologyDetailViewModel();
    if !CRBiologyDetailPresentation.Supported(area) || !CRBodyStatusPresentation.Owns() {
      return result;
    }
    let body: ref<CRBodyState> = CRBodyRuntime.Get().GetBodySnapshot();
    let meters: ref<CRBodyMeters> = CRBodyRuntime.Get().GetMeters();
    let config: ref<CRBodyConfig> = CRBodyRuntime.Get().GetBodyConfig();
    if !IsDefined(body) || !body.initialized || !IsDefined(body.injuries) || !IsDefined(meters) || !meters.valid || !IsDefined(config) {
      return result;
    }

    result.title = CRBiologyDetailPresentation.Label(area);

    if Equals(area, gamedataEquipmentArea.SystemReplacementCW) {
      result.summary = CRBodyStatusPresentation.BodyStatus(body);
      ArrayPush(result.metrics, CRBiologyDetailPresentation.Metric("HYDRATION", meters.hydration, CRBiologyDetailPresentation.PercentText(meters.hydration)));
      ArrayPush(result.metrics, CRBiologyDetailPresentation.Metric("NUTRITION", meters.nutrition, CRBiologyDetailPresentation.PercentText(meters.nutrition)));
      ArrayPush(result.metrics, CRBiologyDetailPresentation.Metric("ENERGY", meters.energy, CRBiologyDetailPresentation.PercentText(meters.energy)));
      ArrayPush(result.metrics, CRBiologyDetailPresentation.Metric("BLADDER", 100.0 * body.bladderMl / 550.0, ToString(RoundF(body.bladderMl)) + " ml"));
      result.summary += "  |  BOWEL " + ToString(RoundF(body.bowelGrams)) + " g";
    } else {
      if Equals(area, gamedataEquipmentArea.CardiovascularSystemCW) {
        let available: Float = 100.0 * (1.0 - body.injuries.bloodDeficitMl / config.injuryBloodCapacityMl);
        result.summary = "DEFICIT " + ToString(RoundF(body.injuries.bloodDeficitMl)) + " ml  |  BLEED EXT " + ToString(RoundF(CRBiologyDetailPresentation.TotalExternalBleed(body.injuries))) + "  |  BLEED INT " + ToString(RoundF(CRBiologyDetailPresentation.TotalInternalBleed(body.injuries)));
        ArrayPush(result.metrics, CRBiologyDetailPresentation.Metric("CIRCULATING VOLUME", available, CRBiologyDetailPresentation.PercentText(available)));
      } else {
        if Equals(area, gamedataEquipmentArea.NervousSystemCW) {
          let pain: ref<CRPainProjection> = CRPainRuntime.Get().Read();
          result.summary = "PAIN / ANALGESIA";
          if IsDefined(pain) && pain.valid {
            ArrayPush(result.metrics, CRBiologyDetailPresentation.Metric("PERCEIVED PAIN", pain.perceivedPain * 100.0, CRBiologyDetailPresentation.PercentText(pain.perceivedPain * 100.0)));
            ArrayPush(result.metrics, CRBiologyDetailPresentation.Metric("ANALGESIA", pain.analgesia * 100.0, CRBiologyDetailPresentation.PercentText(pain.analgesia * 100.0)));
            ArrayPush(result.metrics, CRBiologyDetailPresentation.Metric("DISORIENTATION", pain.intoxication * 100.0, CRBiologyDetailPresentation.PercentText(pain.intoxication * 100.0)));
          }
        } else {
          if Equals(area, gamedataEquipmentArea.FrontalCortexCW) {
            result.summary = CRBiologyDetailPresentation.RegionSummary(1);
            CRBiologyDetailPresentation.AddRegionMetrics(result, body.injuries, 1);
          } else {
            if Equals(area, gamedataEquipmentArea.ArmsCW) {
              let leftFunction: Float = CRInjuryModel.Function(body.injuries, 3) * 100.0;
              let rightFunction: Float = CRInjuryModel.Function(body.injuries, 4) * 100.0;
              result.summary = "L " + CRBiologyDetailPresentation.RegionSummary(3) + "  |  R " + CRBiologyDetailPresentation.RegionSummary(4);
              ArrayPush(result.metrics, CRBiologyDetailPresentation.Metric("LEFT ARM FUNCTION", leftFunction, CRBiologyDetailPresentation.PercentText(leftFunction)));
              ArrayPush(result.metrics, CRBiologyDetailPresentation.Metric("RIGHT ARM FUNCTION", rightFunction, CRBiologyDetailPresentation.PercentText(rightFunction)));
              ArrayPush(result.metrics, CRBiologyDetailPresentation.Metric("LEFT BONE INTEGRITY", (1.0 - body.injuries.leftArm.boneDamage) * 100.0, CRBiologyDetailPresentation.IntegrityText(body.injuries.leftArm.boneDamage)));
              ArrayPush(result.metrics, CRBiologyDetailPresentation.Metric("RIGHT BONE INTEGRITY", (1.0 - body.injuries.rightArm.boneDamage) * 100.0, CRBiologyDetailPresentation.IntegrityText(body.injuries.rightArm.boneDamage)));
            } else {
              if Equals(area, gamedataEquipmentArea.LegsCW) {
                let leftFunction: Float = CRInjuryModel.Function(body.injuries, 5) * 100.0;
                let rightFunction: Float = CRInjuryModel.Function(body.injuries, 6) * 100.0;
                result.summary = "L " + CRBiologyDetailPresentation.RegionSummary(5) + "  |  R " + CRBiologyDetailPresentation.RegionSummary(6);
                ArrayPush(result.metrics, CRBiologyDetailPresentation.Metric("LEFT LEG FUNCTION", leftFunction, CRBiologyDetailPresentation.PercentText(leftFunction)));
                ArrayPush(result.metrics, CRBiologyDetailPresentation.Metric("RIGHT LEG FUNCTION", rightFunction, CRBiologyDetailPresentation.PercentText(rightFunction)));
                ArrayPush(result.metrics, CRBiologyDetailPresentation.Metric("LEFT BONE INTEGRITY", (1.0 - body.injuries.leftLeg.boneDamage) * 100.0, CRBiologyDetailPresentation.IntegrityText(body.injuries.leftLeg.boneDamage)));
                ArrayPush(result.metrics, CRBiologyDetailPresentation.Metric("RIGHT BONE INTEGRITY", (1.0 - body.injuries.rightLeg.boneDamage) * 100.0, CRBiologyDetailPresentation.IntegrityText(body.injuries.rightLeg.boneDamage)));
              } else {
                if Equals(area, gamedataEquipmentArea.MusculoskeletalSystemCW) {
                  let worstBone: Float = CRBiologyDetailPresentation.WorstBone(body.injuries);
                  let worstFunction: Float = 1.0;
                  let i: Int32 = 1;
                  while i <= 6 {
                    worstFunction = MinF(worstFunction, CRInjuryModel.Function(body.injuries, i));
                    i += 1;
                  }
                  result.summary = "GLOBAL LOAD";
                  ArrayPush(result.metrics, CRBiologyDetailPresentation.Metric("LOWEST FUNCTION", worstFunction * 100.0, CRBiologyDetailPresentation.PercentText(worstFunction * 100.0)));
                  ArrayPush(result.metrics, CRBiologyDetailPresentation.Metric("WORST BONE INTEGRITY", (1.0 - worstBone) * 100.0, CRBiologyDetailPresentation.IntegrityText(worstBone)));
                  ArrayPush(result.metrics, CRBiologyDetailPresentation.Metric("EXERTION RESERVE", 100.0 * (1.0 - ClampF(body.exertionFatigueHours / MaxF(0.01, config.exertionFatigueMaximumHours), 0.0, 1.0)), ToString(RoundF(body.exertionFatigueHours * 60.0)) + " min"));
                } else {
                  if Equals(area, gamedataEquipmentArea.IntegumentarySystemCW) {
                    let worstTissue: Float = CRBiologyDetailPresentation.WorstTissue(body.injuries);
                    result.summary = "BLEED " + ToString(RoundF(CRBiologyDetailPresentation.TotalExternalBleed(body.injuries))) + " ml/h  |  HYGIENE " + ToString(RoundF(body.hygieneLoad));
                    ArrayPush(result.metrics, CRBiologyDetailPresentation.Metric("WORST TISSUE INTEGRITY", (1.0 - worstTissue) * 100.0, CRBiologyDetailPresentation.IntegrityText(worstTissue)));
                    ArrayPush(result.metrics, CRBiologyDetailPresentation.Metric("CLEANLINESS", 100.0 * (1.0 - ClampF(body.hygieneLoad / 25.0, 0.0, 1.0)), ToString(RoundF(body.hygieneLoad))));
                  }
                }
              }
            }
          }
        }
      }
    }

    result.valid = true;
    return result;
  }
}
