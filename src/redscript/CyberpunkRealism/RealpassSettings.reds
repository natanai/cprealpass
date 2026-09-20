// Biology-owned activation and presentation preference authority.
//
// REDlauncher/REDmod is the whole-product activation boundary. Biology therefore
// does not keep a second persisted master switch merely to mirror launcher state.
// The one remaining public preference is presentation-only and is persisted by the
// native save lifecycle of a ScriptableSystem rather than an external settings mod.
module CyberpunkRealism.Settings

public class CRRealpassSettings extends ScriptableSystem {
  // CRRealpassSettings remains a compatibility identifier during the product rename.
  // ScriptableSystem persistent fields are serialized with the current game save.
  public persistent let e3FirstPersonHudVisuals: Bool = true;

  public static func Get(game: GameInstance) -> ref<CRRealpassSettings> {
    return GameInstance.GetScriptableSystemsContainer(game).Get(n"CyberpunkRealism.Settings.CRRealpassSettings") as CRRealpassSettings;
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
      && (!IsDefined(settings) || settings.e3FirstPersonHudVisuals);
  }

  public static func SetE3FirstPersonHudVisuals(game: GameInstance, enabled: Bool) -> Bool {
    let settings: ref<CRRealpassSettings> = CRRealpassSettings.Get(game);
    if !IsDefined(settings) {
      return true;
    }
    settings.e3FirstPersonHudVisuals = enabled;
    return settings.e3FirstPersonHudVisuals;
  }

  public static func ToggleE3FirstPersonHudVisuals(game: GameInstance) -> Bool {
    let next: Bool = !CRRealpassSettings.UseE3FirstPersonHudVisuals(game);
    return CRRealpassSettings.SetE3FirstPersonHudVisuals(game, next);
  }
}
