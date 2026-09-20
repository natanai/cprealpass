// Biology-owned activation and presentation preference authority.
//
// REDlauncher/REDmod is the whole-product activation boundary. Biology therefore
// does not keep a second persisted master switch merely to mirror launcher state.
// The one remaining public preference is presentation-only and is persisted by the
// native save lifecycle of a ScriptableSystem rather than an external settings mod.
module CyberpunkRealism.Settings

public class CRBiologyE3PreferenceChangedEvent extends Event {}

public class CRRealpassSettings extends ScriptableSystem {
  // CRRealpassSettings remains a compatibility identifier during the product rename.
  // ScriptableSystem persistent fields are serialized with the current game save.
  public persistent let e3FirstPersonHudVisuals: Bool = true;

  public static func Get(game: GameInstance) -> ref<CRRealpassSettings> {
    let container: ref<ScriptableSystemsContainer> = GameInstance.GetScriptableSystemsContainer(game);
    if !IsDefined(container) {
      return null;
    }
    return container.Get(n"CyberpunkRealism.Settings.CRRealpassSettings") as CRRealpassSettings;
  }

  // REDlauncher activation authority is deliberately outside persistent settings.
  // The sentinel exists only in Biology's official REDmod tweak payload and is
  // absent from the active vanilla TweakDB path when REDmods are disabled.
  public static func IsLauncherActivated() -> Bool {
    return TweakDBInterface.GetBool(t"Items.BiologyLauncherActivationMarker.stackable", false);
  }

  public static func IsEnabled(game: GameInstance) -> Bool {
    // REDlauncher is the sole whole-mod public activation boundary. Keeping this
    // provider-neutral accessor preserves one fail-closed gate for every Biology
    // runtime consumer without inventing a second saved master preference.
    return CRRealpassSettings.IsLauncherActivated();
  }

  public static func UseE3FirstPersonHudVisuals(game: GameInstance) -> Bool {
    let settings: ref<CRRealpassSettings> = CRRealpassSettings.Get(game);
    return CRRealpassSettings.IsEnabled(game)
      && IsDefined(settings) && settings.e3FirstPersonHudVisuals;
  }

  public static func SetE3FirstPersonHudVisuals(game: GameInstance, enabled: Bool) -> Bool {
    let settings: ref<CRRealpassSettings> = CRRealpassSettings.Get(game);
    if !CRRealpassSettings.IsEnabled(game) || !IsDefined(settings) {
      return false;
    }
    if !Equals(settings.e3FirstPersonHudVisuals, enabled) {
      settings.e3FirstPersonHudVisuals = enabled;
      // Native UI event delivery refreshes existing HUD controllers even when their
      // quest/weapon/hotkey data has not changed. The event carries no second state.
      GameInstance.GetUISystem(game).QueueEvent(new CRBiologyE3PreferenceChangedEvent());
    }
    // Return write success, not the value: a successful OFF write is also success.
    return Equals(settings.e3FirstPersonHudVisuals, enabled);
  }

  public static func ToggleE3FirstPersonHudVisuals(game: GameInstance) -> Bool {
    let settings: ref<CRRealpassSettings> = CRRealpassSettings.Get(game);
    if !IsDefined(settings) {
      return false;
    }
    return CRRealpassSettings.SetE3FirstPersonHudVisuals(game, !settings.e3FirstPersonHudVisuals);
  }
}
