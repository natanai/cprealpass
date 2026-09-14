// Project-original player-facing projection for restrained realpass biology presentation.
// Exact simulation values stay inside the body model/diagnostics; normal UI describes
// what V could reasonably notice or know about their body.
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
      return "unknown";
    }
    if r.externalBleedMlPerHour + r.internalBleedMlPerHour > 0.0 {
      return "bleeding";
    }
    if r.cyberwareDamage > 0.0 {
      return "chrome damaged";
    }
    if CRInjuryModel.Function(state, region) < 0.5 {
      return "impaired";
    }
    if r.tissueDamage + r.boneDamage > 0.0 {
      return "injured";
    }
    return "ok";
  }

  private static func AddRegionStatus(text: String, state: ref<CRInjuryState>, region: Int32, label: String) -> String {
    let status: String = CRBodyStatusPresentation.RegionStatus(state, region);
    if Equals(status, "ok") || Equals(status, "unknown") {
      return text;
    }
    if !Equals(text, "") {
      text += "  |  ";
    }
    return text + label + ": " + status;
  }

  public static func InjuryStatus(state: ref<CRInjuryState>) -> String {
    if !IsDefined(state) || !CRInjuryModel.ValidState(state) {
      return "INJURY STATUS UNAVAILABLE";
    }
    if !CRBodyRuntime.Get().OwnsLocalizedInjuries() {
      return "";
    }
    let result: String = "";
    result = CRBodyStatusPresentation.AddRegionStatus(result, state, 1, "Head");
    result = CRBodyStatusPresentation.AddRegionStatus(result, state, 2, "Torso");
    result = CRBodyStatusPresentation.AddRegionStatus(result, state, 3, "L arm");
    result = CRBodyStatusPresentation.AddRegionStatus(result, state, 4, "R arm");
    result = CRBodyStatusPresentation.AddRegionStatus(result, state, 5, "L leg");
    result = CRBodyStatusPresentation.AddRegionStatus(result, state, 6, "R leg");
    if state.bloodDeficitMl > 1.0 {
      if !Equals(result, "") {
        result += "  |  ";
      }
      result += "blood volume recovering";
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
      return "intensely thirsty";
    }
    if value < 50.0 {
      return "very thirsty";
    }
    if value < 75.0 {
      return "thirsty";
    }
    return "";
  }

  private static func FoodNeed(value: Float, body: ref<CRBodyState>) -> String {
    if value < 20.0 {
      return "weak with hunger";
    }
    if value < 45.0 {
      return "very hungry";
    }
    if value < 70.0 {
      return "hungry";
    }
    if body.gutEnergyKcal > 150.0 {
      return "digesting a meal";
    }
    return "";
  }

  private static func RestNeed(value: Float) -> String {
    if value < 20.0 {
      return "exhausted";
    }
    if value < 40.0 {
      return "very tired";
    }
    if value < 65.0 {
      return "tired";
    }
    return "";
  }

  private static func EliminationNeed(body: ref<CRBodyState>) -> String {
    let result: String = "";
    if body.bladderMl >= 550.0 {
      result = CRBodyStatusPresentation.AddNeed(result, "urgent need to urinate");
    } else {
      if body.bladderMl >= 400.0 {
        result = CRBodyStatusPresentation.AddNeed(result, "need to urinate");
      } else {
        if body.bladderMl >= 250.0 {
          result = CRBodyStatusPresentation.AddNeed(result, "bladder becoming noticeable");
        }
      }
    }
    if body.bowelGrams >= 450.0 {
      result = CRBodyStatusPresentation.AddNeed(result, "urgent bowel pressure");
    } else {
      if body.bowelGrams >= 300.0 {
        result = CRBodyStatusPresentation.AddNeed(result, "need to use the bathroom");
      }
    }
    return result;
  }

  private static func HygieneNeed(body: ref<CRBodyState>) -> String {
    if body.hygieneLoad >= 25.0 {
      return "feel noticeably dirty";
    }
    if body.hygieneLoad >= 10.0 {
      return "could use a wash";
    }
    return "";
  }

  public static func BodyStatus(body: ref<CRBodyState>) -> String {
    if !IsDefined(body) || !body.initialized {
      return "BODY STATUS UNAVAILABLE";
    }
    let meters: ref<CRBodyMeters> = CRBodyRuntime.Get().GetMeters();
    if !IsDefined(meters) || !meters.valid {
      return "BODY STATUS UNAVAILABLE";
    }
    let result: String = "";
    result = CRBodyStatusPresentation.AddNeed(result, CRBodyStatusPresentation.HydrationNeed(meters.hydration));
    result = CRBodyStatusPresentation.AddNeed(result, CRBodyStatusPresentation.FoodNeed(meters.nutrition, body));
    result = CRBodyStatusPresentation.AddNeed(result, CRBodyStatusPresentation.RestNeed(meters.energy));
    result = CRBodyStatusPresentation.AddNeed(result, CRBodyStatusPresentation.EliminationNeed(body));
    result = CRBodyStatusPresentation.AddNeed(result, CRBodyStatusPresentation.HygieneNeed(body));
    if Equals(result, "") {
      return "No strong bodily need is demanding attention.";
    }
    return result;
  }

  public static func CurrentStatus() -> String {
    if !CRBodyStatusPresentation.Owns() {
      return "";
    }
    let body: ref<CRBodyState> = CRBodyRuntime.Get().GetBodySnapshot();
    if !IsDefined(body) {
      return "BODY STATUS UNAVAILABLE";
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
      return "No realpass serving model is available for this item.";
    }
    let before: ref<CRBodyMeters> = CRBodyRuntime.Get().GetMeters();
    let forecast: ref<CRBodyForecastState> = CRBodyRuntime.Get().BeginForecast();
    if !IsDefined(before) || !before.valid || !CRBodyForecast.AddServing(forecast, serving) {
      return "The body's response cannot be estimated right now.";
    }
    let after: ref<CRBodyMeters> = CRBodyForecast.Step(forecast, 1.0, false);
    if !after.valid {
      return "The body's response cannot be estimated right now.";
    }
    let result: String = "Effects arrive gradually as the serving is absorbed.";
    if after.hydration > before.hydration + 1.0 && after.nutrition > before.nutrition + 1.0 {
      return result + " It should help with both thirst and hunger.";
    }
    if after.hydration > before.hydration + 1.0 {
      return result + " It should help with thirst.";
    }
    if after.nutrition > before.nutrition + 1.0 {
      return result + " It should help with hunger.";
    }
    return result;
  }
}
