// Biology-owned settings semantics with an optional Mod Settings presentation surface.
//
// Biology has one authored physical simulation. The public settings surface has a
// global master switch plus one presentation-only preference for the red E3-inspired
// first-person HUD/nameplate layer. The semantic accessors below are provider-neutral:
// gameplay and presentation code do not depend on Mod Settings implementation APIs.
module CyberpunkRealism.Settings

public class CRRealpassSettings extends ScriptableSystem {
  // CRRealpassSettings and the stored field names remain compatibility identifiers
  // during the product rename. Player-facing product identity is Biology.
  @runtimeProperty("ModSettings.mod", "Biology")
  @runtimeProperty("ModSettings.category", "General")
  @runtimeProperty("ModSettings.category.order", "0")
  @runtimeProperty("ModSettings.displayName", "Enable Biology")
  @runtimeProperty("ModSettings.description", "Enable or disable the complete Biology overhaul. When off, Biology gameplay and presentation adapters yield to Cyberpunk's native behavior. Reload the current save after changing this setting so every runtime adapter starts from the same state.")
  @runtimeProperty("ModSettings.order", "0")
  public let enabled: Bool = true;

  @runtimeProperty("ModSettings.mod", "Biology")
  @runtimeProperty("ModSettings.category", "Presentation")
  @runtimeProperty("ModSettings.category.order", "10")
  @runtimeProperty("ModSettings.displayName", "E3-inspired HUD + nameplates")
  @runtimeProperty("ModSettings.description", "Use Biology's red E3-inspired first-person HUD and NPC-nameplate treatment. Presentation only: Biology simulation, the barless-health policy, and Cyberpunk's modern scanner/quickhack interface remain unchanged.")
  @runtimeProperty("ModSettings.order", "10")
  public let e3FirstPersonHudVisuals: Bool = true;

  public static func Get(game: GameInstance) -> ref<CRRealpassSettings> {
    return GameInstance.GetScriptableSystemsContainer(game).Get(n"CyberpunkRealism.Settings.CRRealpassSettings") as CRRealpassSettings;
  }

  public static func IsEnabled(game: GameInstance) -> Bool {
    let settings: ref<CRRealpassSettings> = CRRealpassSettings.Get(game);
    // Fail toward the authored/default Biology state during startup. A missing
    // settings singleton must never silently disable the overhaul.
    return !IsDefined(settings) || settings.enabled;
  }

  // Listener registration is an optional provider adapter. The rest of Biology
  // consumes only IsEnabled / UseE3FirstPersonHudVisuals and therefore remains
  // independent of whichever persistence/settings UI ultimately hosts the booleans.
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
