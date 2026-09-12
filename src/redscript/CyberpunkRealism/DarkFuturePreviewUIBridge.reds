// Original UI bridge; uses existing menu layout and game-provided font assets.
module DarkFuture.UI
import CyberpunkRealism.Integration.*
import CyberpunkRealism.Physiology.*

public class CRBodyPreviewUI extends IScriptable {
  public static func Owns() -> Bool {
    return CRBodyRuntimePolicy.Enabled() && CRBodyRuntime.Get().OwnsNeeds();
  }

  public static func Create(parent: ref<inkCompoundWidget>) -> ref<inkText> {
    if !CRBodyPreviewUI.Owns() {
      return null;
    }
    let note: ref<inkText> = new inkText();
    note.SetName(n"CyberpunkRealismBodyStatus");
    note.SetFontFamily("base\\gameplay\\gui\\fonts\\raj\\raj.inkfontfamily", n"Medium");
    note.SetFontSize(26);
    note.SetSize(Vector2(1900.0, 76.0));
    if CRBodyTestPolicy.Diagnostics() {
      note.SetSize(Vector2(1900.0, 100.0));
    }
    note.SetHorizontalAlignment(textHorizontalAlignment.Center);
    note.SetHAlign(inkEHorizontalAlign.Center);
    note.SetStyle(r"base\\gameplay\\gui\\common\\main_colors.inkstyle");
    note.BindProperty(n"tintColor", n"MainColors.Red");
    note.Reparent(parent);
    CRBodyPreviewUI.ShowCurrent(note);
    return note;
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
    let result: String = "INJURY STATUS  |  Head: " + CRBodyPreviewUI.RegionStatus(state, 1) + "  |  Torso: " + CRBodyPreviewUI.RegionStatus(state, 2) + "  |  L arm: " + CRBodyPreviewUI.RegionStatus(state, 3) + "\nR arm: " + CRBodyPreviewUI.RegionStatus(state, 4) + "  |  L leg: " + CRBodyPreviewUI.RegionStatus(state, 5) + "  |  R leg: " + CRBodyPreviewUI.RegionStatus(state, 6);
    if state.bloodDeficitMl > 1.0 {
      result += "  |  Recovering blood loss";
    }
    return result;
  }
  private static func OptionalLine(value: String) -> String {
    if Equals(value, "") {
      return "";
    }
    return "\n" + value;
  }

  public static func ShowCurrent(note: ref<inkText>) -> Void {
    if !IsDefined(note) {
      return;
    }
    note.SetVisible(CRBodyPreviewUI.Owns());
    if !CRBodyPreviewUI.Owns() {
      return;
    }
    let body: ref<CRBodyState> = CRBodyRuntime.Get().GetBodySnapshot();
    if !IsDefined(body) {
      note.SetText("realpass  |  BODY STATUS UNAVAILABLE");
      return;
    }
    let hygiene: String = "clean";
    if body.hygieneLoad >= 25.0 {
      hygiene = "needs washing";
    } else {
      if body.hygieneLoad >= 10.0 {
        hygiene = "could use a wash";
      }
    }
    note.SetText("realpass  |  BODY STATUS  |  Digesting " + ToString(Cast<Int32>(body.gutEnergyKcal)) + " kcal  |  Bladder " + ToString(Cast<Int32>(body.bladderMl)) + " ml  |  Sleep pressure " + ToString(Cast<Int32>(body.sleepPressureHours)) + " h  |  Hygiene: " + hygiene + "\nNEEDS  |  Open the weapon wheel to inspect needs. Food and drink absorb gradually." + CRBodyPreviewUI.OptionalLine(CRBodyRuntime.Get().TestStatus()));
  }

  public static func Preview(note: ref<inkText>, item: wref<Item_Record>, hydration: ref<DFNeedsMenuBar>, nutrition: ref<DFNeedsMenuBar>, energy: ref<DFNeedsMenuBar>) -> Bool {
    if !CRBodyPreviewUI.Owns() {
      return false;
    }
    let runtime: ref<CRBodyRuntime> = CRBodyRuntime.Get();
    let current: ref<CRBodyMeters> = runtime.GetMeters();
    hydration.SetUpdatedValue(current.hydration, 100.0);
    nutrition.SetUpdatedValue(current.nutrition, 100.0);
    energy.SetUpdatedValue(current.energy, 100.0);
    let serving: ref<CRServing> = CRItemServing.Resolve(item);
    if !serving.recognized {
      if IsDefined(item) && Equals(item.GetID(), t"Items.HealthBooster") && runtime.OwnsLocalizedInjuries() {
        if IsDefined(note) { note.SetText("realpass  |  TRAUMA KIT  |  Open FIELD CARE, choose a region, then apply a dressing or support an injured limb."); }
        return true;
      }
      if IsDefined(note) { note.SetText("realpass  |  BODY STATUS  |  No food or fluid serving data for this item"); }
      return true;
    }
    let forecast: ref<CRBodyForecastState> = runtime.BeginForecast();
    if !CRBodyForecast.AddServing(forecast, serving) {
      if IsDefined(note) { note.SetText("realpass  |  BODY FORECAST UNAVAILABLE  |  Earlier body events are still processing"); }
      return true;
    }
    let result: ref<CRBodyMeters> = CRBodyForecast.Step(forecast, 1.0, false);
    if !result.valid {
      if IsDefined(note) { note.SetText("realpass  |  BODY FORECAST UNAVAILABLE"); }
      return true;
    }
    hydration.SetUpdatedValue(result.hydration, 100.0);
    nutrition.SetUpdatedValue(result.nutrition, 100.0);
    energy.SetUpdatedValue(result.energy, 100.0);
    if IsDefined(note) {
      note.SetText("realpass  |  BODY FORECAST: AFTER 1 GAME HOUR AT REST  |  Serving: " + ToString(Cast<Int32>(serving.waterMl)) + " ml, " + ToString(Cast<Int32>(serving.energyKcal)) + " kcal  |  Absorption is gradual");
    }
    return true;
  }
}
