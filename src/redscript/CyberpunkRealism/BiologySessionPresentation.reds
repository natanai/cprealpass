// Explicit-session Biology projections for native menu controllers.
//
// This project-owned helper is read-only. It carries the controller/player-owned
// GameInstance to the single persistent CRBodyRuntime and subordinate systems,
// without patching Biology-authored classes or creating a second body authority.
module CyberpunkRealism.Presentation

import CyberpunkRealism.Integration.*
import CyberpunkRealism.Physiology.*

public class CRBiologySessionPresentation extends IScriptable {
  public static func ConditionForSession(game: GameInstance, region: Int32) -> ref<CRConditionDescriptor> {
    let runtime: ref<CRBodyRuntime> = CRBiologySessionAuthority.Body(game);
    if !IsDefined(runtime) || !runtime.OwnsNeeds() {
      return new CRConditionDescriptor();
    }
    return CRBiologySessionPresentation.Condition(game, runtime.GetBodySnapshot(), region);
  }

  private static func AddToken(text: String, token: String) -> String {
    if Equals(token, "") {
      return text;
    }
    if !Equals(text, "") {
      text += "  |  ";
    }
    return text + token;
  }

  private static func BodyStatus(runtime: ref<CRBodyRuntime>, body: ref<CRBodyState>) -> String {
    if !IsDefined(runtime) || !IsDefined(body) || !body.initialized {
      return "BODY UNAVAILABLE";
    }
    let meters: ref<CRBodyMeters> = runtime.GetMeters();
    if !IsDefined(meters) || !meters.valid {
      return "BODY UNAVAILABLE";
    }

    let result: String = "";
    if meters.hydration < 25.0 {
      result = CRBiologySessionPresentation.AddToken(result, "THIRST CRITICAL");
    } else {
      if meters.hydration < 50.0 {
        result = CRBiologySessionPresentation.AddToken(result, "THIRST HIGH");
      } else {
        if meters.hydration < 75.0 {
          result = CRBiologySessionPresentation.AddToken(result, "THIRST");
        }
      }
    }

    if meters.nutrition < 20.0 {
      result = CRBiologySessionPresentation.AddToken(result, "HUNGER CRITICAL");
    } else {
      if meters.nutrition < 45.0 {
        result = CRBiologySessionPresentation.AddToken(result, "HUNGER HIGH");
      } else {
        if meters.nutrition < 70.0 {
          result = CRBiologySessionPresentation.AddToken(result, "HUNGER");
        } else {
          if body.gutEnergyKcal > 150.0 {
            result = CRBiologySessionPresentation.AddToken(result, "DIGESTING");
          }
        }
      }
    }

    if meters.energy < 20.0 {
      result = CRBiologySessionPresentation.AddToken(result, "FATIGUE CRITICAL");
    } else {
      if meters.energy < 40.0 {
        result = CRBiologySessionPresentation.AddToken(result, "FATIGUE HIGH");
      } else {
        if meters.energy < 65.0 {
          result = CRBiologySessionPresentation.AddToken(result, "FATIGUE");
        }
      }
    }

    if body.bladderMl >= 550.0 {
      result = CRBiologySessionPresentation.AddToken(result, "BLADDER URGENT");
    } else {
      if body.bladderMl >= 400.0 {
        result = CRBiologySessionPresentation.AddToken(result, "BLADDER HIGH");
      } else {
        if body.bladderMl >= 250.0 {
          result = CRBiologySessionPresentation.AddToken(result, "BLADDER RISING");
        }
      }
    }
    if body.bowelGrams >= 450.0 {
      result = CRBiologySessionPresentation.AddToken(result, "BOWEL URGENT");
    } else {
      if body.bowelGrams >= 300.0 {
        result = CRBiologySessionPresentation.AddToken(result, "BOWEL HIGH");
      }
    }
    if body.hygieneLoad >= 25.0 {
      result = CRBiologySessionPresentation.AddToken(result, "HYGIENE POOR");
    } else {
      if body.hygieneLoad >= 10.0 {
        result = CRBiologySessionPresentation.AddToken(result, "HYGIENE LOW");
      }
    }

    if Equals(result, "") {
      return "STABLE";
    }
    return result;
  }

  private static func Condition(game: GameInstance, body: ref<CRBodyState>, region: Int32) -> ref<CRConditionDescriptor> {
    let provenanceRuntime: ref<CRInjuryProvenanceRuntime> = CRBiologySessionAuthority.Provenance(game);
    let provenance: ref<CRInjuryProvenance>;
    if !IsDefined(body) || !body.initialized || !IsDefined(body.injuries) {
      return new CRConditionDescriptor();
    }
    if IsDefined(provenanceRuntime) {
      provenance = provenanceRuntime.LatestForRegion(region);
    }
    return CRConditionPresentation.Describe(body.injuries, region, provenance);
  }

  private static func Effects(game: GameInstance) -> String {
    let painRuntime: ref<CRPainRuntime> = CRBiologySessionAuthority.Pain(game);
    if !IsDefined(painRuntime) {
      return "";
    }
    let pain: ref<CRPainProjection> = painRuntime.Read();
    if !IsDefined(pain) || !pain.valid {
      return "";
    }
    let result: String = "";
    if pain.perceivedPain >= 0.75 {
      result = CRBiologySessionPresentation.AddToken(result, "PAIN CRITICAL");
    } else {
      if pain.perceivedPain >= 0.45 {
        result = CRBiologySessionPresentation.AddToken(result, "PAIN HIGH");
      } else {
        if pain.perceivedPain >= 0.15 {
          result = CRBiologySessionPresentation.AddToken(result, "PAIN");
        }
      }
    }
    if pain.analgesia > 0.0 && pain.physicalPain > 0.0 {
      result = CRBiologySessionPresentation.AddToken(result, "ANALGESIA");
    }
    if pain.intoxication >= 0.66 {
      result = CRBiologySessionPresentation.AddToken(result, "DISORIENTATION HIGH");
    } else {
      if pain.intoxication > 0.0 {
        result = CRBiologySessionPresentation.AddToken(result, "DISORIENTATION");
      }
    }
    return result;
  }

  private static func Diagnostic(reason: String) -> ref<CRBiologyViewModel> {
    let result: ref<CRBiologyViewModel> = new CRBiologyViewModel();
    result.valid = true;
    result.diagnosticFailure = true;
    result.needs = "[ BIOLOGY ERROR ] " + (Equals(reason, "") ? "BODY STATE UNAVAILABLE" : reason);
    return result;
  }

  public static func Current(game: GameInstance) -> ref<CRBiologyViewModel> {
    if !CRBiologyRuntimeAvailability.EnsureActive(game) {
      return CRBiologySessionPresentation.Diagnostic(CRBiologyRuntimeAvailability.FailureReason(game));
    }
    let runtime: ref<CRBodyRuntime> = CRBiologySessionAuthority.Body(game);
    if !IsDefined(runtime) {
      return CRBiologySessionPresentation.Diagnostic(CRBiologyRuntimeAvailability.FailureReason(game));
    }
    let body: ref<CRBodyState> = runtime.GetBodySnapshot();
    let meters: ref<CRBodyMeters> = runtime.GetMeters();
    if !IsDefined(body) || !body.initialized || !IsDefined(meters) || !meters.valid {
      return CRBiologySessionPresentation.Diagnostic("BODY STATE INVALID");
    }

    let result: ref<CRBiologyViewModel> = new CRBiologyViewModel();
    result.needs = CRBiologySessionPresentation.BodyStatus(runtime, body);
    result.hasNeeds = !Equals(result.needs, "") && !Equals(result.needs, "STABLE");
    result.showDrink = meters.hydration < 75.0;
    result.showEat = meters.nutrition < 70.0;
    result.effects = CRBiologySessionPresentation.Effects(game);
    result.hasEffects = !Equals(result.effects, "");
    runtime.TestPresentationRead("overview");
    let testStatus: String = runtime.TestStatus();
    if !Equals(testStatus, "") {
      result.effects = CRBiologySessionPresentation.AddToken(result.effects, testStatus);
      result.hasEffects = true;
    }

    let conditions: String = "";
    let region: Int32 = 1;
    while region <= 6 {
      let descriptor: ref<CRConditionDescriptor> = CRBiologySessionPresentation.Condition(game, body, region);
      if IsDefined(descriptor) && descriptor.valid && descriptor.hasCondition {
        if !Equals(conditions, "") {
          conditions += "\n";
        }
        conditions += descriptor.regionName + " — " + descriptor.title + " / " + descriptor.severity;
      }
      region += 1;
    }
    result.conditions = conditions;
    result.hasConditions = !Equals(conditions, "");
    result.valid = true;
    return result;
  }

  private static func Metric(label: String, percent: Float, valueText: String) -> ref<CRBiologyMetric> {
    let metric: ref<CRBiologyMetric> = new CRBiologyMetric();
    metric.label = label;
    metric.percent = ClampF(percent, 0.0, 100.0);
    metric.valueText = valueText;
    return metric;
  }

  private static func PercentText(value: Float) -> String {
    // Whole-percent rounding made genuine early body progression look exactly
    // healthy. Preserve one decimal without changing the authoritative value.
    return ToString(Cast<Float>(RoundF(ClampF(value, 0.0, 100.0) * 10.0)) / 10.0) + "%";
  }

  private static func IntegrityText(damage: Float) -> String {
    return CRBiologySessionPresentation.PercentText((1.0 - ClampF(damage, 0.0, 1.0)) * 100.0);
  }

  private static func RegionSummary(game: GameInstance, body: ref<CRBodyState>, region: Int32) -> String {
    let descriptor: ref<CRConditionDescriptor> = CRBiologySessionPresentation.Condition(game, body, region);
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
    ArrayPush(result.metrics, CRBiologySessionPresentation.Metric("FUNCTION", function, CRBiologySessionPresentation.PercentText(function)));
    ArrayPush(result.metrics, CRBiologySessionPresentation.Metric("TISSUE INTEGRITY", (1.0 - regional.tissueDamage) * 100.0, CRBiologySessionPresentation.IntegrityText(regional.tissueDamage)));
    ArrayPush(result.metrics, CRBiologySessionPresentation.Metric("BONE INTEGRITY", (1.0 - regional.boneDamage) * 100.0, CRBiologySessionPresentation.IntegrityText(regional.boneDamage)));
    ArrayPush(result.metrics, CRBiologySessionPresentation.Metric("CYBERWARE INTEGRITY", (1.0 - regional.cyberwareDamage) * 100.0, CRBiologySessionPresentation.IntegrityText(regional.cyberwareDamage)));
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

  public static func Detail(game: GameInstance, area: gamedataEquipmentArea) -> ref<CRBiologyDetailViewModel> {
    let result: ref<CRBiologyDetailViewModel> = new CRBiologyDetailViewModel();
    if !CRBiologyDetailPresentation.Supported(area) || !CRBiologyRuntimeAvailability.EnsureActive(game) {
      return result;
    }
    let runtime: ref<CRBodyRuntime> = CRBiologySessionAuthority.Body(game);
    if !IsDefined(runtime) {
      return result;
    }
    let body: ref<CRBodyState> = runtime.GetBodySnapshot();
    let meters: ref<CRBodyMeters> = runtime.GetMeters();
    let config: ref<CRBodyConfig> = runtime.GetBodyConfig();
    if !IsDefined(body) || !body.initialized || !IsDefined(body.injuries) || !IsDefined(meters) || !meters.valid || !IsDefined(config) {
      return result;
    }

    result.title = CRBiologyDetailPresentation.Label(area);
    if Equals(area, gamedataEquipmentArea.SystemReplacementCW) {
      result.summary = CRBiologySessionPresentation.BodyStatus(runtime, body);
      ArrayPush(result.metrics, CRBiologySessionPresentation.Metric("HYDRATION", meters.hydration, CRBiologySessionPresentation.PercentText(meters.hydration)));
      ArrayPush(result.metrics, CRBiologySessionPresentation.Metric("NUTRITION", meters.nutrition, CRBiologySessionPresentation.PercentText(meters.nutrition)));
      ArrayPush(result.metrics, CRBiologySessionPresentation.Metric("ENERGY", meters.energy, CRBiologySessionPresentation.PercentText(meters.energy)));
      ArrayPush(result.metrics, CRBiologySessionPresentation.Metric("BLADDER", 100.0 * body.bladderMl / 550.0, ToString(RoundF(body.bladderMl)) + " ml"));
      result.summary += "  |  BOWEL " + ToString(RoundF(body.bowelGrams)) + " g";
    } else {
      if Equals(area, gamedataEquipmentArea.CardiovascularSystemCW) {
        let available: Float = 100.0 * (1.0 - body.injuries.bloodDeficitMl / config.injuryBloodCapacityMl);
        result.summary = "DEFICIT " + ToString(RoundF(body.injuries.bloodDeficitMl)) + " ml  |  BLEED EXT " + ToString(RoundF(CRBiologySessionPresentation.TotalExternalBleed(body.injuries))) + "  |  BLEED INT " + ToString(RoundF(CRBiologySessionPresentation.TotalInternalBleed(body.injuries)));
        ArrayPush(result.metrics, CRBiologySessionPresentation.Metric("CIRCULATING VOLUME", available, CRBiologySessionPresentation.PercentText(available)));
      } else {
        if Equals(area, gamedataEquipmentArea.NervousSystemCW) {
          let painRuntime: ref<CRPainRuntime> = CRBiologySessionAuthority.Pain(game);
          let pain: ref<CRPainProjection>;
          result.summary = "PAIN / ANALGESIA";
          if IsDefined(painRuntime) {
            pain = painRuntime.Read();
          }
          if IsDefined(pain) && pain.valid {
            ArrayPush(result.metrics, CRBiologySessionPresentation.Metric("PERCEIVED PAIN", pain.perceivedPain * 100.0, CRBiologySessionPresentation.PercentText(pain.perceivedPain * 100.0)));
            ArrayPush(result.metrics, CRBiologySessionPresentation.Metric("ANALGESIA", pain.analgesia * 100.0, CRBiologySessionPresentation.PercentText(pain.analgesia * 100.0)));
            ArrayPush(result.metrics, CRBiologySessionPresentation.Metric("DISORIENTATION", pain.intoxication * 100.0, CRBiologySessionPresentation.PercentText(pain.intoxication * 100.0)));
          }
        } else {
          if Equals(area, gamedataEquipmentArea.FrontalCortexCW) {
            result.summary = CRBiologySessionPresentation.RegionSummary(game, body, 1);
            CRBiologySessionPresentation.AddRegionMetrics(result, body.injuries, 1);
          } else {
            if Equals(area, gamedataEquipmentArea.ArmsCW) {
              let leftFunction: Float = CRInjuryModel.Function(body.injuries, 3) * 100.0;
              let rightFunction: Float = CRInjuryModel.Function(body.injuries, 4) * 100.0;
              result.summary = "L " + CRBiologySessionPresentation.RegionSummary(game, body, 3) + "  |  R " + CRBiologySessionPresentation.RegionSummary(game, body, 4);
              ArrayPush(result.metrics, CRBiologySessionPresentation.Metric("LEFT ARM FUNCTION", leftFunction, CRBiologySessionPresentation.PercentText(leftFunction)));
              ArrayPush(result.metrics, CRBiologySessionPresentation.Metric("RIGHT ARM FUNCTION", rightFunction, CRBiologySessionPresentation.PercentText(rightFunction)));
              ArrayPush(result.metrics, CRBiologySessionPresentation.Metric("LEFT BONE INTEGRITY", (1.0 - body.injuries.leftArm.boneDamage) * 100.0, CRBiologySessionPresentation.IntegrityText(body.injuries.leftArm.boneDamage)));
              ArrayPush(result.metrics, CRBiologySessionPresentation.Metric("RIGHT BONE INTEGRITY", (1.0 - body.injuries.rightArm.boneDamage) * 100.0, CRBiologySessionPresentation.IntegrityText(body.injuries.rightArm.boneDamage)));
            } else {
              if Equals(area, gamedataEquipmentArea.LegsCW) {
                let leftFunction: Float = CRInjuryModel.Function(body.injuries, 5) * 100.0;
                let rightFunction: Float = CRInjuryModel.Function(body.injuries, 6) * 100.0;
                result.summary = "L " + CRBiologySessionPresentation.RegionSummary(game, body, 5) + "  |  R " + CRBiologySessionPresentation.RegionSummary(game, body, 6);
                ArrayPush(result.metrics, CRBiologySessionPresentation.Metric("LEFT LEG FUNCTION", leftFunction, CRBiologySessionPresentation.PercentText(leftFunction)));
                ArrayPush(result.metrics, CRBiologySessionPresentation.Metric("RIGHT LEG FUNCTION", rightFunction, CRBiologySessionPresentation.PercentText(rightFunction)));
                ArrayPush(result.metrics, CRBiologySessionPresentation.Metric("LEFT BONE INTEGRITY", (1.0 - body.injuries.leftLeg.boneDamage) * 100.0, CRBiologySessionPresentation.IntegrityText(body.injuries.leftLeg.boneDamage)));
                ArrayPush(result.metrics, CRBiologySessionPresentation.Metric("RIGHT BONE INTEGRITY", (1.0 - body.injuries.rightLeg.boneDamage) * 100.0, CRBiologySessionPresentation.IntegrityText(body.injuries.rightLeg.boneDamage)));
              } else {
                if Equals(area, gamedataEquipmentArea.MusculoskeletalSystemCW) {
                  let worstBone: Float = CRBiologySessionPresentation.WorstBone(body.injuries);
                  let worstFunction: Float = 1.0;
                  let i: Int32 = 1;
                  while i <= 6 {
                    worstFunction = MinF(worstFunction, CRInjuryModel.Function(body.injuries, i));
                    i += 1;
                  }
                  result.summary = "GLOBAL LOAD";
                  ArrayPush(result.metrics, CRBiologySessionPresentation.Metric("LOWEST FUNCTION", worstFunction * 100.0, CRBiologySessionPresentation.PercentText(worstFunction * 100.0)));
                  ArrayPush(result.metrics, CRBiologySessionPresentation.Metric("WORST BONE INTEGRITY", (1.0 - worstBone) * 100.0, CRBiologySessionPresentation.IntegrityText(worstBone)));
                  ArrayPush(result.metrics, CRBiologySessionPresentation.Metric("EXERTION RESERVE", 100.0 * (1.0 - ClampF(body.exertionFatigueHours / MaxF(0.01, config.exertionFatigueMaximumHours), 0.0, 1.0)), ToString(RoundF(body.exertionFatigueHours * 60.0)) + " min"));
                } else {
                  if Equals(area, gamedataEquipmentArea.IntegumentarySystemCW) {
                    let worstTissue: Float = CRBiologySessionPresentation.WorstTissue(body.injuries);
                    result.summary = "BLEED " + ToString(RoundF(CRBiologySessionPresentation.TotalExternalBleed(body.injuries))) + " ml/h  |  HYGIENE " + ToString(RoundF(body.hygieneLoad));
                    ArrayPush(result.metrics, CRBiologySessionPresentation.Metric("WORST TISSUE INTEGRITY", (1.0 - worstTissue) * 100.0, CRBiologySessionPresentation.IntegrityText(worstTissue)));
                    ArrayPush(result.metrics, CRBiologySessionPresentation.Metric("CLEANLINESS", 100.0 * (1.0 - ClampF(body.hygieneLoad / 25.0, 0.0, 1.0)), ToString(RoundF(body.hygieneLoad))));
                  }
                }
              }
            }
          }
        }
      }
    }

    runtime.TestPresentationRead("detail-" + result.title);
    let testStatus: String = runtime.TestStatus();
    if !Equals(testStatus, "") {
      if !Equals(result.summary, "") {
        result.summary += "\n";
      }
      result.summary += testStatus;
    }
    result.valid = true;
    return result;
  }
}
