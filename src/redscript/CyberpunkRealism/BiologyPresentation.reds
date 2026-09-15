// Project-original Biology view-model projection.
// This layer deliberately exposes qualitative, player-knowable state while the
// underlying body model retains exact quantities for simulation and diagnostics.
module CyberpunkRealism.Presentation

import CyberpunkRealism.Integration.*
import CyberpunkRealism.Physiology.*

public class CRBiologyViewModel extends IScriptable {
  public let valid: Bool = false;
  public let needs: String;
  public let effects: String;
  public let conditions: String;
  public let hasNeeds: Bool = false;
  public let hasEffects: Bool = false;
  public let hasConditions: Bool = false;
  public let showEat: Bool = false;
  public let showDrink: Bool = false;
}

public class CRBiologyPresentation extends IScriptable {
  private static func AddToken(text: String, token: String) -> String {
    if Equals(token, "") {
      return text;
    }
    if !Equals(text, "") {
      text += "  |  ";
    }
    return text + token;
  }

  private static func AddCondition(text: String, descriptor: ref<CRConditionDescriptor>) -> String {
    if !IsDefined(descriptor) || !descriptor.valid || !descriptor.hasCondition {
      return text;
    }
    if !Equals(text, "") {
      text += "\n";
    }
    return text + descriptor.regionName + " — " + descriptor.title + " / " + descriptor.severity;
  }

  private static func Effects() -> String {
    let pain: ref<CRPainProjection> = CRPainRuntime.Get().Read();
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

  public static func Current() -> ref<CRBiologyViewModel> {
    let result: ref<CRBiologyViewModel> = new CRBiologyViewModel();
    if !CRBodyStatusPresentation.Owns() {
      return result;
    }
    let body: ref<CRBodyState> = CRBodyRuntime.Get().GetBodySnapshot();
    let meters: ref<CRBodyMeters> = CRBodyRuntime.Get().GetMeters();
    if !IsDefined(body) || !body.initialized || !IsDefined(meters) || !meters.valid {
      return result;
    }

    result.needs = CRBodyStatusPresentation.BodyStatus(body);
    result.hasNeeds = !Equals(result.needs, "") && !Equals(result.needs, "STABLE");
    // These are presentation thresholds only. The UI never reads or displays the
    // underlying percentages; it only decides whether a contextual action is useful.
    result.showDrink = meters.hydration < 75.0;
    result.showEat = meters.nutrition < 70.0;

    result.effects = CRBiologyPresentation.Effects();
    result.hasEffects = !Equals(result.effects, "");

    let conditions: String = "";
    let region: Int32 = 1;
    while region <= 6 {
      conditions = CRBiologyPresentation.AddCondition(conditions, CRConditionPresentation.Current(region));
      region += 1;
    }
    result.conditions = conditions;
    result.hasConditions = !Equals(conditions, "");
    result.valid = true;
    return result;
  }
}
