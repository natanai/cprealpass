// Project-original player-facing projection for restrained realpass biology presentation.
// Exact simulation values stay inside the body model/diagnostics; normal UI describes
// what V could reasonably notice or know about their body in terse status language.
module CyberpunkRealism.Presentation

import CyberpunkRealism.Integration.*
import CyberpunkRealism.Physiology.*

public class CRBodyStatusPresentation extends IScriptable {
  public static func Owns() -> Bool {
    return CRBodyRuntimePolicy.Enabled() && CRBodyRuntime.Get().OwnsNeeds();
  }

  private static func RegionStatus(state: ref<CRInjuryState>, region: Int32) -> String {
    let r: ref<CRRegionalInjury> = CRInjuryModel.Region(state, region);
    if !CRInjuryModel.ValidRegion(r) {
      return "UNKNOWN";
    }
    if r.externalBleedMlPerHour + r.internalBleedMlPerHour > 0.0 {
      return "BLEEDING";
    }
    if r.cyberwareDamage > 0.0 {
      return "CHROME DAMAGE";
    }
    if CRInjuryModel.Function(state, region) < 0.5 {
      return "IMPAIRED";
    }
    if r.tissueDamage + r.boneDamage > 0.0 {
      return "INJURED";
    }
    return "OK";
  }

  private static func AddRegionStatus(text: String, state: ref<CRInjuryState>, region: Int32, label: String) -> String {
    let status: String = CRBodyStatusPresentation.RegionStatus(state, region);
    if Equals(status, "OK") || Equals(status, "UNKNOWN") {
      return text;
    }
    if !Equals(text, "") {
      text += "  |  ";
    }
    return text + label + " " + status;
  }

  public static func InjuryStatus(state: ref<CRInjuryState>) -> String {
    if !IsDefined(state) || !CRInjuryModel.ValidState(state) {
      return "INJURY UNAVAILABLE";
    }
    if !CRBodyRuntime.Get().OwnsLocalizedInjuries() {
      return "";
    }
    let result: String = "";
    result = CRBodyStatusPresentation.AddRegionStatus(result, state, 1, "HEAD");
    result = CRBodyStatusPresentation.AddRegionStatus(result, state, 2, "TORSO");
    result = CRBodyStatusPresentation.AddRegionStatus(result, state, 3, "L ARM");
    result = CRBodyStatusPresentation.AddRegionStatus(result, state, 4, "R ARM");
    result = CRBodyStatusPresentation.AddRegionStatus(result, state, 5, "L LEG");
    result = CRBodyStatusPresentation.AddRegionStatus(result, state, 6, "R LEG");
    if state.bloodDeficitMl > 1.0 {
      if !Equals(result, "") {
        result += "  |  ";
      }
      result += "BLOOD LOW";
    }
    return result;
  }

  private static func AddNeed(text: String, need: String) -> String {
    if Equals(need, "") {
      return text;
    }
    if !Equals(text, "") {
      text += "  |  ";
    }
    return text + need;
  }

  private static func HydrationNeed(value: Float) -> String {
    if value < 25.0 {
      return "THIRST CRITICAL";
    }
    if value < 50.0 {
      return "THIRST HIGH";
    }
    if value < 75.0 {
      return "THIRST";
    }
    return "";
  }

  private static func FoodNeed(value: Float, body: ref<CRBodyState>) -> String {
    if value < 20.0 {
      return "HUNGER CRITICAL";
    }
    if value < 45.0 {
      return "HUNGER HIGH";
    }
    if value < 70.0 {
      return "HUNGER";
    }
    if body.gutEnergyKcal > 150.0 {
      return "DIGESTING";
    }
    return "";
  }

  private static func RestNeed(value: Float) -> String {
    if value < 20.0 {
      return "FATIGUE CRITICAL";
    }
    if value < 40.0 {
      return "FATIGUE HIGH";
    }
    if value < 65.0 {
      return "FATIGUE";
    }
    return "";
  }

  private static func EliminationNeed(body: ref<CRBodyState>) -> String {
    let result: String = "";
    if body.bladderMl >= 550.0 {
      result = CRBodyStatusPresentation.AddNeed(result, "BLADDER URGENT");
    } else {
      if body.bladderMl >= 400.0 {
        result = CRBodyStatusPresentation.AddNeed(result, "BLADDER HIGH");
      } else {
        if body.bladderMl >= 250.0 {
          result = CRBodyStatusPresentation.AddNeed(result, "BLADDER RISING");
        }
      }
    }
    if body.bowelGrams >= 450.0 {
      result = CRBodyStatusPresentation.AddNeed(result, "BOWEL URGENT");
    } else {
      if body.bowelGrams >= 300.0 {
        result = CRBodyStatusPresentation.AddNeed(result, "BOWEL HIGH");
      }
    }
    return result;
  }

  private static func HygieneNeed(body: ref<CRBodyState>) -> String {
    if body.hygieneLoad >= 25.0 {
      return "HYGIENE POOR";
    }
    if body.hygieneLoad >= 10.0 {
      return "HYGIENE LOW";
    }
    return "";
  }

  public static func BodyStatus(body: ref<CRBodyState>) -> String {
    if !IsDefined(body) || !body.initialized {
      return "BODY UNAVAILABLE";
    }
    let meters: ref<CRBodyMeters> = CRBodyRuntime.Get().GetMeters();
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

  public static func CurrentStatus() -> String {
    if !CRBodyStatusPresentation.Owns() {
      return "";
    }
    let body: ref<CRBodyState> = CRBodyRuntime.Get().GetBodySnapshot();
    if !IsDefined(body) {
      return "BODY UNAVAILABLE";
    }
    let text: String = CRBodyStatusPresentation.BodyStatus(body);
    let injury: String = CRBodyStatusPresentation.InjuryStatus(body.injuries);
    if !Equals(injury, "") {
      text += "\n" + injury;
    }
    return text;
  }

  // Normal presentation describes likely bodily effect, not hidden fluid/calorie
  // quantities. Exact serving data remains available to model tests/diagnostics.
  public static func ServingForecast(item: wref<Item_Record>) -> String {
    if !CRBodyStatusPresentation.Owns() || !IsDefined(item) {
      return "";
    }
    let serving: ref<CRServing> = CRItemServing.Resolve(item);
    if !serving.recognized {
      return "UNMODELED";
    }
    let before: ref<CRBodyMeters> = CRBodyRuntime.Get().GetMeters();
    let forecast: ref<CRBodyForecastState> = CRBodyRuntime.Get().BeginForecast();
    if !IsDefined(before) || !before.valid || !CRBodyForecast.AddServing(forecast, serving) {
      return "FORECAST UNAVAILABLE";
    }
    let after: ref<CRBodyMeters> = CRBodyForecast.Step(forecast, 1.0, false);
    if !after.valid {
      return "FORECAST UNAVAILABLE";
    }
    if after.hydration > before.hydration + 1.0 && after.nutrition > before.nutrition + 1.0 {
      return "THIRST + HUNGER";
    }
    if after.hydration > before.hydration + 1.0 {
      return "THIRST";
    }
    if after.nutrition > before.nutrition + 1.0 {
      return "HUNGER";
    }
    return "ABSORBING";
  }
}
