// RealPass-owned Mod Settings surface.
//
// RealPass has one authored physical simulation. Mod Settings exposes exactly one
// editable preference: whether the RealPass-owned E3-inspired first-person HUD /
// nameplate presentation is used. This preference is presentation-only; it does not
// alter body, injury, combat, armor, pain, treatment, recovery or scanner authority.
module CyberpunkRealism.Settings

public class CRRealpassSettings extends ScriptableSystem {
  @runtimeProperty("ModSettings.mod", "RealPass")
  @runtimeProperty("ModSettings.category", "Presentation")
  @runtimeProperty("ModSettings.category.order", "10")
  @runtimeProperty("ModSettings.displayName", "E3 first-person HUD visuals")
  @runtimeProperty("ModSettings.description", "Use RealPass' red E3-inspired first-person HUD and NPC-nameplate presentation. This changes presentation only; the RealPass simulation and the modern scanner remain unchanged.")
  @runtimeProperty("ModSettings.order", "10")
  public let e3FirstPersonHudVisuals: Bool = true;

  public static func Get(game: GameInstance) -> ref<CRRealpassSettings> {
    return GameInstance.GetScriptableSystemsContainer(game).Get(n"CyberpunkRealism.Settings.CRRealpassSettings") as CRRealpassSettings;
  }

  // Listener registration keeps the ScriptableSystem singleton synchronized with
  // changes accepted in Mod Settings. Mod Settings is persistence/UI plumbing only;
  // RealPass source remains the owner of what this preference means.
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
    // Fail toward the authored/default presentation if the system is temporarily
    // unavailable during startup; this never changes simulation state.
    return !IsDefined(settings) || settings.e3FirstPersonHudVisuals;
  }
}
