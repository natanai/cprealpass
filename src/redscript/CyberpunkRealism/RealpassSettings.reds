// realpass-owned player preference surface.
//
// This system intentionally records player intent only. It does not open any
// development/native acceptance gate and does not apply gameplay effects. Runtime
// activation remains: accepted build gate AND player intent AND safe lifecycle.
module CyberpunkRealism.Settings
import CyberpunkRealism.Core.*

public class CRRealpassSettings extends ScriptableSystem {
  // BODY
  @runtimeProperty("ModSettings.mod", "realpass")
  @runtimeProperty("ModSettings.category", "Body")
  @runtimeProperty("ModSettings.category.order", "10")
  @runtimeProperty("ModSettings.displayName", "Body simulation")
  public let bodyEnabled: Bool = true;

  @runtimeProperty("ModSettings.mod", "realpass")
  @runtimeProperty("ModSettings.category", "Body")
  @runtimeProperty("ModSettings.category.order", "10")
  @runtimeProperty("ModSettings.displayName", "Nutrition")
  @runtimeProperty("ModSettings.dependency", "bodyEnabled")
  public let bodyNutrition: Bool = true;

  @runtimeProperty("ModSettings.mod", "realpass")
  @runtimeProperty("ModSettings.category", "Body")
  @runtimeProperty("ModSettings.category.order", "10")
  @runtimeProperty("ModSettings.displayName", "Hydration")
  @runtimeProperty("ModSettings.dependency", "bodyEnabled")
  public let bodyHydration: Bool = true;

  @runtimeProperty("ModSettings.mod", "realpass")
  @runtimeProperty("ModSettings.category", "Body")
  @runtimeProperty("ModSettings.category.order", "10")
  @runtimeProperty("ModSettings.displayName", "Sleep and fatigue")
  @runtimeProperty("ModSettings.dependency", "bodyEnabled")
  public let bodySleep: Bool = true;

  @runtimeProperty("ModSettings.mod", "realpass")
  @runtimeProperty("ModSettings.category", "Body")
  @runtimeProperty("ModSettings.category.order", "10")
  @runtimeProperty("ModSettings.displayName", "Exertion")
  @runtimeProperty("ModSettings.dependency", "bodyEnabled")
  public let bodyExertion: Bool = true;

  @runtimeProperty("ModSettings.mod", "realpass")
  @runtimeProperty("ModSettings.category", "Body")
  @runtimeProperty("ModSettings.category.order", "10")
  @runtimeProperty("ModSettings.displayName", "Bathroom needs")
  @runtimeProperty("ModSettings.dependency", "bodyEnabled")
  public let bodyElimination: Bool = true;

  @runtimeProperty("ModSettings.mod", "realpass")
  @runtimeProperty("ModSettings.category", "Body")
  @runtimeProperty("ModSettings.category.order", "10")
  @runtimeProperty("ModSettings.displayName", "Hygiene")
  @runtimeProperty("ModSettings.dependency", "bodyEnabled")
  public let bodyHygiene: Bool = true;

  // INJURY AND TREATMENT
  @runtimeProperty("ModSettings.mod", "realpass")
  @runtimeProperty("ModSettings.category", "Injury and treatment")
  @runtimeProperty("ModSettings.category.order", "20")
  @runtimeProperty("ModSettings.displayName", "Localized injuries")
  public let injuryEnabled: Bool = true;

  @runtimeProperty("ModSettings.mod", "realpass")
  @runtimeProperty("ModSettings.category", "Injury and treatment")
  @runtimeProperty("ModSettings.category.order", "20")
  @runtimeProperty("ModSettings.displayName", "Blood loss")
  @runtimeProperty("ModSettings.dependency", "injuryEnabled")
  public let injuryBloodLoss: Bool = true;

  @runtimeProperty("ModSettings.mod", "realpass")
  @runtimeProperty("ModSettings.category", "Injury and treatment")
  @runtimeProperty("ModSettings.category.order", "20")
  @runtimeProperty("ModSettings.displayName", "Regional impairment")
  @runtimeProperty("ModSettings.dependency", "injuryEnabled")
  public let injuryImpairment: Bool = true;

  @runtimeProperty("ModSettings.mod", "realpass")
  @runtimeProperty("ModSettings.category", "Injury and treatment")
  @runtimeProperty("ModSettings.category.order", "20")
  @runtimeProperty("ModSettings.displayName", "Field treatment")
  @runtimeProperty("ModSettings.dependency", "injuryEnabled")
  public let injuryFieldCare: Bool = true;

  @runtimeProperty("ModSettings.mod", "realpass")
  @runtimeProperty("ModSettings.category", "Injury and treatment")
  @runtimeProperty("ModSettings.category.order", "20")
  @runtimeProperty("ModSettings.displayName", "Injury recovery")
  @runtimeProperty("ModSettings.dependency", "injuryEnabled")
  public let injuryRecovery: Bool = true;

  // COMBAT
  @runtimeProperty("ModSettings.mod", "realpass")
  @runtimeProperty("ModSettings.category", "Combat")
  @runtimeProperty("ModSettings.category.order", "30")
  @runtimeProperty("ModSettings.displayName", "Physical ballistics and damage")
  public let combatEnabled: Bool = true;

  // ARMOR
  @runtimeProperty("ModSettings.mod", "realpass")
  @runtimeProperty("ModSettings.category", "Armor")
  @runtimeProperty("ModSettings.category.order", "40")
  @runtimeProperty("ModSettings.displayName", "Physical armor coverage")
  public let armorEnabled: Bool = true;

  @runtimeProperty("ModSettings.mod", "realpass")
  @runtimeProperty("ModSettings.category", "Armor")
  @runtimeProperty("ModSettings.category.order", "40")
  @runtimeProperty("ModSettings.displayName", "Armor wear")
  @runtimeProperty("ModSettings.dependency", "armorEnabled")
  public let armorWear: Bool = true;

  // CYBERWARE PHYSIOLOGY
  @runtimeProperty("ModSettings.mod", "realpass")
  @runtimeProperty("ModSettings.category", "Cyberware physiology")
  @runtimeProperty("ModSettings.category.order", "50")
  @runtimeProperty("ModSettings.displayName", "Physical cyberware consequences")
  public let cyberwarePhysiologyEnabled: Bool = true;

  // PRESENTATION
  @runtimeProperty("ModSettings.mod", "realpass")
  @runtimeProperty("ModSettings.category", "Presentation")
  @runtimeProperty("ModSettings.category.order", "60")
  @runtimeProperty("ModSettings.displayName", "realpass presentation")
  public let presentationEnabled: Bool = true;

  @runtimeProperty("ModSettings.mod", "realpass")
  @runtimeProperty("ModSettings.category", "Presentation")
  @runtimeProperty("ModSettings.category.order", "60")
  @runtimeProperty("ModSettings.displayName", "NPC nameplates")
  @runtimeProperty("ModSettings.dependency", "presentationEnabled")
  public let presentationNameplates: Bool = true;

  @runtimeProperty("ModSettings.mod", "realpass")
  @runtimeProperty("ModSettings.category", "Presentation")
  @runtimeProperty("ModSettings.category.order", "60")
  @runtimeProperty("ModSettings.displayName", "Contextual body and injury cues")
  @runtimeProperty("ModSettings.dependency", "presentationEnabled")
  public let presentationStatusCues: Bool = true;

  @runtimeProperty("ModSettings.mod", "realpass")
  @runtimeProperty("ModSettings.category", "Presentation")
  @runtimeProperty("ModSettings.category.order", "60")
  @runtimeProperty("ModSettings.displayName", "Traditional health bars")
  @runtimeProperty("ModSettings.description", "Show continuous actor HP/overshield bars instead of relying on physical injury feedback. Does not change damage or health simulation.")
  @runtimeProperty("ModSettings.dependency", "presentationEnabled")
  public let presentationTraditionalHealthBars: Bool = false;

  // Diagnostics is contract-owned but deliberately not a public Mod Settings field.
  // Attended diagnostic activation remains an explicit build/session choice.
  public let diagnosticsEnabled: Bool = false;

  public static func Get() -> ref<CRRealpassSettings> {
    return GameInstance.GetScriptableSystemsContainer(GetGameInstance()).Get(NameOf<CRRealpassSettings>()) as CRRealpassSettings;
  }

  // Translate UI/persisted player preferences into the engine-independent policy
  // model. Acceptance flags intentionally remain their false defaults here; only a
  // future build-acceptance adapter may supply those.
  public func IntentSnapshot() -> ref<CRRuntimeFeatureFlags> {
    let flags = new CRRuntimeFeatureFlags();
    flags.bodyEnabled = this.bodyEnabled;
    flags.nutritionEnabled = this.bodyNutrition;
    flags.hydrationEnabled = this.bodyHydration;
    flags.sleepEnabled = this.bodySleep;
    flags.exertionEnabled = this.bodyExertion;
    flags.eliminationEnabled = this.bodyElimination;
    flags.hygieneEnabled = this.bodyHygiene;

    flags.injuryEnabled = this.injuryEnabled;
    flags.bloodLossEnabled = this.injuryBloodLoss;
    flags.impairmentEnabled = this.injuryImpairment;
    flags.fieldCareEnabled = this.injuryFieldCare;
    flags.injuryRecoveryEnabled = this.injuryRecovery;

    flags.combatEnabled = this.combatEnabled;
    flags.armorEnabled = this.armorEnabled;
    flags.armorWearEnabled = this.armorWear;
    flags.cyberwarePhysiologyEnabled = this.cyberwarePhysiologyEnabled;

    flags.presentationEnabled = this.presentationEnabled;
    flags.nameplatesEnabled = this.presentationNameplates;
    flags.statusCuesEnabled = this.presentationStatusCues;
    flags.traditionalHealthBarsEnabled = this.presentationTraditionalHealthBars;
    flags.diagnosticsEnabled = this.diagnosticsEnabled;
    return flags;
  }

  private func OnAttach() -> Void {
    ModSettings.RegisterListenerToClass(this);
  }

  private func OnDetach() -> Void {
    ModSettings.UnregisterListenerToClass(this);
  }
}
