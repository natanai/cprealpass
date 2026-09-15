// RealPass-owned Mod Settings surface.
//
// RealPass has one authored physical simulation. The public settings surface has a
// global master switch plus one presentation-only preference for the red E3-inspired
// first-person HUD/nameplate layer. No individual simulation authority or balance
// value is player-tunable.
module CyberpunkRealism.Settings

public class CRRealpassSettings extends ScriptableSystem {
  @runtimeProperty("ModSettings.mod", "RealPass")
  @runtimeProperty("ModSettings.category", "General")
  @runtimeProperty("ModSettings.category.order", "0")
  @runtimeProperty("ModSettings.displayName", "Enable RealPass")
  @runtimeProperty("ModSettings.description", "Enable or disable the complete RealPass overhaul. When off, RealPass gameplay and presentation adapters yield to Cyberpunk's native behavior. Reload the current save after changing this setting so every runtime adapter starts from the same state.")
  @runtimeProperty("ModSettings.order", "0")
  public let enabled: Bool = true;

  @runtimeProperty("ModSettings.mod", "RealPass")
  @runtimeProperty("ModSettings.category", "Presentation")
  @runtimeProperty("ModSettings.category.order", "10")
  @runtimeProperty("ModSettings.displayName", "E3 first-person HUD visuals")
  @runtimeProperty("ModSettings.description", "Use the red E3-inspired first-person HUD and NPC-nameplate presentation. This changes presentation only; the RealPass simulation and modern scanner remain unchanged.")
  @runtimeProperty("ModSettings.order", "10")
  public let e3FirstPersonHudVisuals: Bool = true;

  public static func Get(game: GameInstance) -> ref<CRRealpassSettings> {
    return GameInstance.GetScriptableSystemsContainer(game).Get(n"CyberpunkRealism.Settings.CRRealpassSettings") as CRRealpassSettings;
  }

  public static func IsEnabled(game: GameInstance) -> Bool {
    let settings: ref<CRRealpassSettings> = CRRealpassSettings.Get(game);
    // Fail toward the authored/default RealPass state during startup. A missing
    // settings singleton must never silently disable the overhaul.
    return !IsDefined(settings) || settings.enabled;
  }

  // Listener registration keeps the ScriptableSystem singleton synchronized with
  // changes accepted in Mod Settings. The master switch is intentionally global;
  // individual body/combat/armor/etc. authorities remain non-configurable.
  @if(ModuleExists("ModSettingsModule"))
  private func OnAttach() -> Void {
    ModSettings.RegisterListenerToClass(this);
  }

  @if(!ModuleExists("ModSettingsModule"))
  private func OnAttach() -> Void {}

  @if(ModuleExists("ModSettingsModule"))
  private func OnDetach() -> Void {
    ModSettings.UnregisterListenerToClass(this);
  }

  @if(!ModuleExists("ModSettingsModule"))
  private func OnDetach() -> Void {}

  public static func UseE3FirstPersonHudVisuals(game: GameInstance) -> Bool {
    let settings: ref<CRRealpassSettings> = CRRealpassSettings.Get(game);
    return CRRealpassSettings.IsEnabled(game) && (!IsDefined(settings) || settings.e3FirstPersonHudVisuals);
  }
}
