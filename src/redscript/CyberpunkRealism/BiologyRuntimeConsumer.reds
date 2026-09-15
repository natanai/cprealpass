// Narrow attended consumer seam for Biology menu reads.
//
// The visual shell remains owned by the Biology UI lane. This file changes only
// how its existing overview/detail refresh methods obtain authoritative body data:
// the RipperDoc controller supplies its player-owned GameInstance all the way to
// CRBodyRuntime and subordinate projections. No body state lives in this UI layer.
module CyberpunkRealism.Presentation

import CyberpunkRealism.Integration.*
import CyberpunkRealism.Physiology.*

@addMethod(CRBodyStatusPresentation)
public static func Owns(game: GameInstance) -> Bool {
  return CRBiologyRuntimeAvailability.EnsureActive(game);
}

@addMethod(CRBodyStatusPresentation)
public static func BodyStatus(game: GameInstance, body: ref<CRBodyState>) -> String {
  if !IsDefined(body) || !body.initialized {
    return "BODY UNAVAILABLE";
  }
  let runtime: ref<CRBodyRuntime> = CRBodyRuntime.Get(game);
  if !IsDefined(runtime) {
    return "BODY UNAVAILABLE";
  }
  let meters: ref<CRBodyMeters> = runtime.GetMeters();
  if !IsDefined(meters) || !meters.valid {
    return "BODY UNAVAILABLE";
  }
  let result: String = "";
  result = CRBodyStatusPresentation.AddNeed(result, CRBodyStatusPresentation.HydrationNeed(meters.hydration));
  result = CRBodyStatusPresentation.AddNeed(result, CRBodyStatusPresentation.FoodNeed(meters.nutrition, body));
  result = CRBodyStatusPresentation.AddNeed(result, CRBodyStatusPresentation.RestNeed(meters.energy));
  result = CRBodyStatusPresentation.AddNeed(result, CRBodyStatusPresentation.EliminationNeed(body));
  result = CRBodyStatusPresentation.AddNeed(result, CRBodyStatusPresentation.HygieneNeed(body));
  if Equals(result, "") {
    return "STABLE";
  }
  return result;
}

@addMethod(CRConditionPresentation)
public static func Current(game: GameInstance, region: Int32) -> ref<CRConditionDescriptor> {
  let runtime: ref<CRBodyRuntime> = CRBodyRuntime.Get(game);
  let result: ref<CRConditionDescriptor>;
  let provenanceRuntime: ref<CRInjuryProvenanceRuntime>;
  let painRuntime: ref<CRPainRuntime>;
  let provenance: ref<CRInjuryProvenance>;
  if !IsDefined(runtime) {
    return new CRConditionDescriptor();
  }
  let body: ref<CRBodyState> = runtime.GetBodySnapshot();
  if !IsDefined(body) {
    return new CRConditionDescriptor();
  }
  provenanceRuntime = CRInjuryProvenanceRuntime.Get(game);
  if IsDefined(provenanceRuntime) {
    provenance = provenanceRuntime.LatestForRegion(region);
  }
  result = CRConditionPresentation.Describe(body.injuries, region, provenance);
  if IsDefined(result) && result.valid && result.hasCondition {
    painRuntime = CRPainRuntime.Get(game);
    if IsDefined(painRuntime) {
      result.painText = CRConditionPresentation.PainText(painRuntime.Read());
    } else {
      result.painText = "Pain response unavailable.";
    }
  }
  return result;
}

@addMethod(CRBiologyPresentation)
private static func Effects(game: GameInstance) -> String {
  let painRuntime: ref<CRPainRuntime> = CRPainRuntime.Get(game);
  if !IsDefined(painRuntime) {
    return "";
  }
  let pain: ref<CRPainProjection> = painRuntime.Read();
  if !IsDefined(pain) || !pain.valid {
    return "";
  }
  let result: String = "";
  if pain.perceivedPain >= 0.75 {
    result = CRBiologyPresentation.AddToken(result, "PAIN CRITICAL");
  } else {
    if pain.perceivedPain >= 0.45 {
      result = CRBiologyPresentation.AddToken(result, "PAIN HIGH");
    } else {
      if pain.perceivedPain >= 0.15 {
        result = CRBiologyPresentation.AddToken(result, "PAIN");
      }
    }
  }
  if pain.analgesia > 0.0 && pain.physicalPain > 0.0 {
    result = CRBiologyPresentation.AddToken(result, "ANALGESIA");
  }
  if pain.intoxication >= 0.66 {
    result = CRBiologyPresentation.AddToken(result, "DISORIENTATION HIGH");
  } else {
    if pain.intoxication > 0.0 {
      result = CRBiologyPresentation.AddToken(result, "DISORIENTATION");
    }
  }
  return result;
}

@addMethod(CRBiologyPresentation)
public static func Current(game: GameInstance) -> ref<CRBiologyViewModel> {
  let result: ref<CRBiologyViewModel> = new CRBiologyViewModel();
  if !CRBiologyRuntimeAvailability.EnsureActive(game) {
    return CRBiologyPresentation.Diagnostic(result, CRBiologyRuntimeAvailability.FailureReason(game));
  }
  let runtime: ref<CRBodyRuntime> = CRBodyRuntime.Get(game);
  if !IsDefined(runtime) {
    return CRBiologyPresentation.Diagnostic(result, CRBiologyRuntimeAvailability.FailureReason(game));
  }
  let body: ref<CRBodyState> = runtime.GetBodySnapshot();
  let meters: ref<CRBodyMeters> = runtime.GetMeters();
  if !IsDefined(body) || !body.initialized || !IsDefined(meters) || !meters.valid {
    return CRBiologyPresentation.Diagnostic(result, "BODY STATE INVALID");
  }

  result.needs = CRBodyStatusPresentation.BodyStatus(game, body);
  result.hasNeeds = !Equals(result.needs, "") && !Equals(result.needs, "STABLE");
  result.showDrink = meters.hydration < 75.0;
  result.showEat = meters.nutrition < 70.0;

  result.effects = CRBiologyPresentation.Effects(game);
  result.hasEffects = !Equals(result.effects, "");

  let conditions: String = "";
  let region: Int32 = 1;
  while region <= 6 {
    conditions = CRBiologyPresentation.AddCondition(conditions, CRConditionPresentation.Current(game, region));
    region += 1;
  }
  result.conditions = conditions;
  result.hasConditions = !Equals(conditions, "");
  result.valid = true;
  return result;
}

@addMethod(CRBiologyDetailPresentation)
private static func RegionSummary(game: GameInstance, region: Int32) -> String {
  let descriptor: ref<CRConditionDescriptor> = CRConditionPresentation.Current(game, region);
  if !IsDefined(descriptor) || !descriptor.valid || !descriptor.hasCondition {
    return "NO CONDITION";
  }
  return descriptor.title + " / " + descriptor.severity;
}

@addMethod(CRBiologyDetailPresentation)
public static func Current(game: GameInstance, area: gamedataEquipmentArea) -> ref<CRBiologyDetailViewModel> {
  let result: ref<CRBiologyDetailViewModel> = new CRBiologyDetailViewModel();
  if !CRBiologyDetailPresentation.Supported(area) || !CRBiologyRuntimeAvailability.EnsureActive(game) {
    return result;
  }
  let runtime: ref<CRBodyRuntime> = CRBodyRuntime.Get(game);
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
    result.summary = CRBodyStatusPresentation.BodyStatus(game, body);
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
        let painRuntime: ref<CRPainRuntime> = CRPainRuntime.Get(game);
        let pain: ref<CRPainProjection>;
        result.summary = "PAIN / ANALGESIA";
        if IsDefined(painRuntime) {
          pain = painRuntime.Read();
        }
        if IsDefined(pain) && pain.valid {
          ArrayPush(result.metrics, CRBiologyDetailPresentation.Metric("PERCEIVED PAIN", pain.perceivedPain * 100.0, CRBiologyDetailPresentation.PercentText(pain.perceivedPain * 100.0)));
          ArrayPush(result.metrics, CRBiologyDetailPresentation.Metric("ANALGESIA", pain.analgesia * 100.0, CRBiologyDetailPresentation.PercentText(pain.analgesia * 100.0)));
          ArrayPush(result.metrics, CRBiologyDetailPresentation.Metric("DISORIENTATION", pain.intoxication * 100.0, CRBiologyDetailPresentation.PercentText(pain.intoxication * 100.0)));
        }
      } else {
        if Equals(area, gamedataEquipmentArea.FrontalCortexCW) {
          result.summary = CRBiologyDetailPresentation.RegionSummary(game, 1);
          CRBiologyDetailPresentation.AddRegionMetrics(result, body.injuries, 1);
        } else {
          if Equals(area, gamedataEquipmentArea.ArmsCW) {
            let leftFunction: Float = CRInjuryModel.Function(body.injuries, 3) * 100.0;
            let rightFunction: Float = CRInjuryModel.Function(body.injuries, 4) * 100.0;
            result.summary = "L " + CRBiologyDetailPresentation.RegionSummary(game, 3) + "  |  R " + CRBiologyDetailPresentation.RegionSummary(game, 4);
            ArrayPush(result.metrics, CRBiologyDetailPresentation.Metric("LEFT ARM FUNCTION", leftFunction, CRBiologyDetailPresentation.PercentText(leftFunction)));
            ArrayPush(result.metrics, CRBiologyDetailPresentation.Metric("RIGHT ARM FUNCTION", rightFunction, CRBiologyDetailPresentation.PercentText(rightFunction)));
            ArrayPush(result.metrics, CRBiologyDetailPresentation.Metric("LEFT BONE INTEGRITY", (1.0 - body.injuries.leftArm.boneDamage) * 100.0, CRBiologyDetailPresentation.IntegrityText(body.injuries.leftArm.boneDamage)));
            ArrayPush(result.metrics, CRBiologyDetailPresentation.Metric("RIGHT BONE INTEGRITY", (1.0 - body.injuries.rightArm.boneDamage) * 100.0, CRBiologyDetailPresentation.IntegrityText(body.injuries.rightArm.boneDamage)));
          } else {
            if Equals(area, gamedataEquipmentArea.LegsCW) {
              let leftFunction: Float = CRInjuryModel.Function(body.injuries, 5) * 100.0;
              let rightFunction: Float = CRInjuryModel.Function(body.injuries, 6) * 100.0;
              result.summary = "L " + CRBiologyDetailPresentation.RegionSummary(game, 5) + "  |  R " + CRBiologyDetailPresentation.RegionSummary(game, 6);
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

// These two replacements are the only presentation-owned behavior touched by #41.
// They preserve the existing shell formatting and simply supply the controller's
// real player/session context to the new overloads. #39 owns all layout/navigation.
@replaceMethod(RipperDocGameController)
public final func CRRefreshBiologyOverview() -> Void {
  if !IsDefined(this.crBiologyOverviewText) {
    return;
  }
  let player: wref<GameObject> = this.GetPlayerControlledObject();
  if !IsDefined(player) {
    this.crBiologyOverviewText.SetText("[ BIOLOGY ERROR ] BODY RUNTIME PLAYER UNAVAILABLE");
    return;
  }
  let view: ref<CRBiologyViewModel> = CRBiologyPresentation.Current(player.GetGame());
  if !IsDefined(view) || !view.valid {
    this.crBiologyOverviewText.SetText("Body state is unavailable.");
    return;
  }
  let text: String = view.needs;
  if view.hasEffects {
    if !Equals(text, "") { text += "  "; }
    text += view.effects;
  }
  if view.hasConditions {
    if !Equals(text, "") { text += "  "; }
    text += "Active condition present — select the relevant body system for detail.";
  }
  this.crBiologyOverviewText.SetText(text);
}

@replaceMethod(RipperDocGameController)
private final func CRRefreshBiologyDetail() -> Void {
  if !this.crBiologyShellMode || !IsDefined(this.crBiologyDetailPanel) {
    return;
  }
  let player: wref<GameObject> = this.GetPlayerControlledObject();
  this.CRHideMetricRows();
  if !IsDefined(player) {
    this.crBiologyDetailTitle.SetText("BODY");
    this.crBiologyDetailSummary.SetText("[ BIOLOGY ERROR ] BODY RUNTIME PLAYER UNAVAILABLE");
    return;
  }
  let detail: ref<CRBiologyDetailViewModel> = CRBiologyDetailPresentation.Current(player.GetGame(), this.crBiologySelectedArea);
  if !IsDefined(detail) || !detail.valid {
    this.crBiologyDetailTitle.SetText("BODY");
    this.crBiologyDetailSummary.SetText(CRBiologyRuntimeAvailability.FailureReason(player.GetGame()));
    if Equals(this.crBiologyDetailSummary.GetText(), "") {
      this.crBiologyDetailSummary.SetText("No detailed model is available for this node yet.");
    }
    return;
  }
  this.crBiologyDetailTitle.SetText(detail.title);
  this.crBiologyDetailSummary.SetText(detail.summary);
  let i: Int32 = 0;
  while i < ArraySize(detail.metrics) && i < ArraySize(this.crBiologyMetricRows) {
    this.crBiologyMetricLabels[i].SetText(detail.metrics[i].label);
    this.crBiologyMetricFills[i].SetSize(Vector2(270.0 * ClampF(detail.metrics[i].percent / 100.0, 0.0, 1.0), 9.0));
    this.crBiologyMetricValues[i].SetText(detail.metrics[i].valueText);
    this.crBiologyMetricRows[i].SetVisible(true);
    i += 1;
  }
}
