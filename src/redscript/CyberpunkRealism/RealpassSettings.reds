// RealPass-owned Mod Settings surface.
//
// Keep this class deliberately boring. Live acceptance showed that the earlier
// one-value custom-enum feature ledger caused Mod Settings to show "No mods
// available" even though the provider itself was installed. The player-facing
// settings page now contains only conventional supported preference types.
// Simulation ownership/status remains documented by RealPass manifests and Biology;
// Mod Settings is never simulation authority.
module CyberpunkRealism.Settings

public class CRRealpassSettings extends IScriptable {
  @runtimeProperty("ModSettings.mod", "RealPass")
  @runtimeProperty("ModSettings.category", "Presentation")
  @runtimeProperty("ModSettings.category.order", "10")
  @runtimeProperty("ModSettings.displayName", "Fullscreen disorientation effects")
  @runtimeProperty("ModSettings.description", "Show RealPass fullscreen/audio disorientation feedback for excessive analgesic load. Turning this off changes presentation only; it does not change pain, MaxDoc dose, injury, damage, weapon handling, bleeding or recovery.")
  @runtimeProperty("ModSettings.order", "10")
  public let fullscreenDisorientationEffects: Bool = true;

  public static func Current() -> ref<CRRealpassSettings> {
    return new CRRealpassSettings();
  }

  public static func ShowFullscreenDisorientationEffects() -> Bool {
    return CRRealpassSettings.Current().fullscreenDisorientationEffects;
  }
}
