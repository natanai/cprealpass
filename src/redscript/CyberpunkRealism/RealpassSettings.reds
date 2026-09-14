// RealPass-owned Mod Settings surface.
//
// This is deliberately NOT a gameplay tuning surface. The core physical simulation
// remains authored/fixed for a RealPass version. Mod Settings is used to prove the
// runtime is present, summarize the authorities RealPass owns, and expose only
// binary presentation/accessibility preferences that do not change hidden physics.
//
// The one-value CRRealpassManagedState enum makes ledger rows informational in
// practice: there is no alternate value for the player to select. We intentionally
// avoid Int32/Float settings here so numeric balance controls cannot creep in.
module CyberpunkRealism.Settings

public enum CRRealpassManagedState {
  Active = 0
}

public class CRRealpassSettings extends IScriptable {
  // STATUS / FEATURE LEDGER
  @runtimeProperty("ModSettings.mod", "RealPass")
  @runtimeProperty("ModSettings.category", "Status")
  @runtimeProperty("ModSettings.category.order", "10")
  @runtimeProperty("ModSettings.displayName", "RealPass")
  @runtimeProperty("ModSettings.description", "RealPass is installed and its owned runtime is active. This page summarizes major RealPass authorities; it is not a patch-note or diagnostics screen.")
  @runtimeProperty("ModSettings.order", "10")
  @runtimeProperty("ModSettings.displayValues.Active", "Active")
  public let runtimeActive: CRRealpassManagedState = CRRealpassManagedState.Active;

  @runtimeProperty("ModSettings.mod", "RealPass")
  @runtimeProperty("ModSettings.category", "Managed systems")
  @runtimeProperty("ModSettings.category.order", "20")
  @runtimeProperty("ModSettings.displayName", "Body and physiology")
  @runtimeProperty("ModSettings.description", "Hydration, energy, sleep, exertion, elimination and recovery share one RealPass physiological body state.")
  @runtimeProperty("ModSettings.order", "10")
  @runtimeProperty("ModSettings.displayValues.Active", "Managed by RealPass")
  public let bodyPhysiology: CRRealpassManagedState = CRRealpassManagedState.Active;

  @runtimeProperty("ModSettings.mod", "RealPass")
  @runtimeProperty("ModSettings.category", "Managed systems")
  @runtimeProperty("ModSettings.category.order", "20")
  @runtimeProperty("ModSettings.displayName", "Injury, bleeding and recovery")
  @runtimeProperty("ModSettings.description", "Regional injury, blood loss, impairment, treatment and recovery are handled by the RealPass physical-body model.")
  @runtimeProperty("ModSettings.order", "20")
  @runtimeProperty("ModSettings.displayValues.Active", "Managed by RealPass")
  public let injuryRecovery: CRRealpassManagedState = CRRealpassManagedState.Active;

  @runtimeProperty("ModSettings.mod", "RealPass")
  @runtimeProperty("ModSettings.category", "Managed systems")
  @runtimeProperty("ModSettings.category.order", "20")
  @runtimeProperty("ModSettings.displayName", "Pain and MaxDoc analgesia")
  @runtimeProperty("ModSettings.description", "Physical pain and MaxDoc analgesia are RealPass physiology; MaxDoc does not erase physical wounds.")
  @runtimeProperty("ModSettings.order", "30")
  @runtimeProperty("ModSettings.displayValues.Active", "Managed by RealPass")
  public let painAnalgesia: CRRealpassManagedState = CRRealpassManagedState.Active;

  @runtimeProperty("ModSettings.mod", "RealPass")
  @runtimeProperty("ModSettings.category", "Managed systems")
  @runtimeProperty("ModSettings.category.order", "20")
  @runtimeProperty("ModSettings.displayName", "Combat and ballistics")
  @runtimeProperty("ModSettings.description", "Projectile, impact-region and wound consequences use RealPass physical combat logic rather than player-adjustable damage scaling.")
  @runtimeProperty("ModSettings.order", "40")
  @runtimeProperty("ModSettings.displayValues.Active", "Managed by RealPass")
  public let combatBallistics: CRRealpassManagedState = CRRealpassManagedState.Active;

  @runtimeProperty("ModSettings.mod", "RealPass")
  @runtimeProperty("ModSettings.category", "Managed systems")
  @runtimeProperty("ModSettings.category.order", "20")
  @runtimeProperty("ModSettings.displayName", "Physical armor and protection")
  @runtimeProperty("ModSettings.description", "Protection follows the physical equipment actually covering the body, including coverage and wear where modeled.")
  @runtimeProperty("ModSettings.order", "50")
  @runtimeProperty("ModSettings.displayValues.Active", "Managed by RealPass")
  public let armorProtection: CRRealpassManagedState = CRRealpassManagedState.Active;

  @runtimeProperty("ModSettings.mod", "RealPass")
  @runtimeProperty("ModSettings.category", "Managed systems")
  @runtimeProperty("ModSettings.category.order", "20")
  @runtimeProperty("ModSettings.displayName", "Presentation and feedback")
  @runtimeProperty("ModSettings.description", "RealPass presentation translates hidden physical state into restrained player-facing feedback. Temporary vanilla fallback indicators may remain during development until replacements are accepted.")
  @runtimeProperty("ModSettings.order", "60")
  @runtimeProperty("ModSettings.displayValues.Active", "Managed by RealPass")
  public let presentationFeedback: CRRealpassManagedState = CRRealpassManagedState.Active;

  // BINARY PRESENTATION / ACCESSIBILITY PREFERENCES ONLY.
  // This preference gates only the fullscreen/audio disorientation loop used to
  // communicate excessive overlapping analgesia. The pain model, analgesic load,
  // injury state, weapon-handling consequences and overdose state are unchanged.
  @runtimeProperty("ModSettings.mod", "RealPass")
  @runtimeProperty("ModSettings.category", "Presentation preferences")
  @runtimeProperty("ModSettings.category.order", "30")
  @runtimeProperty("ModSettings.displayName", "Fullscreen disorientation effects")
  @runtimeProperty("ModSettings.description", "Show RealPass fullscreen/audio disorientation feedback for excessive analgesic load. Turning this off changes presentation only; it does not change pain, MaxDoc dose, injury, damage, weapon handling, bleeding or recovery.")
  @runtimeProperty("ModSettings.order", "10")
  public let fullscreenDisorientationEffects: Bool = true;

  // Mod Settings updates script-class defaults when a change is accepted. Creating
  // a fresh lightweight settings object therefore reads the current persisted
  // defaults without importing or calling the ModSettings API from project source.
  public static func Current() -> ref<CRRealpassSettings> {
    return new CRRealpassSettings();
  }

  public static func ShowFullscreenDisorientationEffects() -> Bool {
    return CRRealpassSettings.Current().fullscreenDisorientationEffects;
  }
}
