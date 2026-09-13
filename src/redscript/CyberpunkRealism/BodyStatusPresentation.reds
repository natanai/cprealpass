// Project-original text/status projection for restrained realpass presentation.
// It reads realpass state only and has no dependency on another mod's UI model.
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

  public static func InjuryStatus(state: ref<CRInjuryState>) -> String {
    if !IsDefined(state) || !CRInjuryModel.ValidState(state) {
      return "INJURY STATUS UNAVAILABLE";
    }
    if !CRBodyRuntime.Get().OwnsLocalizedInjuries() {
      return "";
    }
    let result: String = "Head: " + CRBodyStatusPresentation.RegionStatus(state, 1)
      + "  |  Torso: " + CRBodyStatusPresentation.RegionStatus(state, 2)
      + "  |  L arm: " + CRBodyStatusPresentation.RegionStatus(state, 3)
      + "  |  R arm: " + CRBodyStatusPresentation.RegionStatus(state, 4)
      + "  |  L leg: " + CRBodyStatusPresentation.RegionStatus(state, 5)
      + "  |  R leg: " + CRBodyStatusPresentation.RegionStatus(state, 6);
    if state.bloodDeficitMl > 1.0 {
      result += "  |  blood volume recovering";
    }
    return result;
  }

  public static func BodyStatus(body: ref<CRBodyState>) -> String {
    if !IsDefined(body) || !body.initialized {
      return "BODY STATUS UNAVAILABLE";
    }
    let hygiene: String = "clean";
    if body.hygieneLoad >= 25.0 {
      hygiene = "needs washing";
    } else {
      if body.hygieneLoad >= 10.0 {
        hygiene = "could use a wash";
      }
    }
    return "Digesting " + ToString(Cast<Int32>(body.gutEnergyKcal)) + " kcal"
      + "  |  Bladder " + ToString(Cast<Int32>(body.bladderMl)) + " ml"
      + "  |  Sleep pressure " + ToString(Cast<Int32>(body.sleepPressureHours)) + " h"
      + "  |  Hygiene: " + hygiene;
  }

  public static func CurrentStatus() -> String {
    if !CRBodyStatusPresentation.Owns() {
      return "";
    }
    let body: ref<CRBodyState> = CRBodyRuntime.Get().GetBodySnapshot();
    if !IsDefined(body) {
      return "realpass  |  BODY STATUS UNAVAILABLE";
    }
    let text: String = "realpass  |  " + CRBodyStatusPresentation.BodyStatus(body);
    let injury: String = CRBodyStatusPresentation.InjuryStatus(body.injuries);
    if !Equals(injury, "") {
      text += "\n" + injury;
    }
    let diagnostic: String = CRBodyRuntime.Get().TestStatus();
    if !Equals(diagnostic, "") {
      text += "\n" + diagnostic;
    }
    return text;
  }

  // Forecast text is intentionally qualitative in normal presentation. Exact
  // internal model values remain available to development tests, not permanent HUD.
  public static func ServingForecast(item: wref<Item_Record>) -> String {
    if !CRBodyStatusPresentation.Owns() || !IsDefined(item) {
      return "";
    }
    let serving: ref<CRServing> = CRItemServing.Resolve(item);
    if !serving.recognized {
      return "No realpass food/fluid serving data for this item.";
    }
    let forecast: ref<CRBodyForecastState> = CRBodyRuntime.Get().BeginForecast();
    if !CRBodyForecast.AddServing(forecast, serving) {
      return "Body forecast unavailable while earlier body events are settling.";
    }
    let result: ref<CRBodyMeters> = CRBodyForecast.Step(forecast, 1.0, false);
    if !result.valid {
      return "Body forecast unavailable.";
    }
    return "Absorption is gradual; this serving is modeled as " + ToString(Cast<Int32>(serving.waterMl)) + " ml fluid and " + ToString(Cast<Int32>(serving.energyKcal)) + " kcal.";
  }
}
