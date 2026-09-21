// Biology-owned activation and presentation preference authority.
//
// REDlauncher/REDmod is the whole-product activation boundary. Biology therefore
// does not keep a second persisted master switch merely to mirror launcher state.
// The one remaining public preference is presentation-only and is persisted by the
// native save lifecycle of a ScriptableSystem rather than an external settings mod.
//
// W20.3 keeps the pre-autonomous default-ON startup behavior deliberately. The rejected
// autonomous release made UseE3... fail closed while the ScriptableSystem was not yet
// attached, then made several HUD adapters create their chrome only when that early read
// returned true. Live evidence showed the result: no meaningful E3 presentation even
// after the preference later became available. Missing early settings therefore means
// "default ON until save authority attaches", not "permanently suppress this HUD tree".
module CyberpunkRealism.Settings

public class CRBiologyE3PreferenceChangedEvent extends Event {}

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

  private func CRNotifyE3PresentationChanged() -> Void {
    let game: GameInstance = this.GetGameInstance();
    let ui: ref<UISystem> = GameInstance.GetUISystem(game);
    if CRRealpassSettings.IsEnabled(game) && IsDefined(ui) {
      ui.QueueEvent(new CRBiologyE3PreferenceChangedEvent());
    }
  }

  private func OnAttach() -> Void {
    // A controller that initialized before the saved ScriptableSystem attached used the
    // safe default-ON read above. Reconcile every live HUD adapter once save authority
    // becomes available, including a saved OFF value.
    this.CRNotifyE3PresentationChanged();
  }

  private func OnRestored(saveVersion: Int32, gameVersion: Int32) -> Void {
    // Save/load is also a presentation lifecycle boundary. The event carries no state;
    // every listener re-reads this one persistent Boolean.
    this.CRNotifyE3PresentationChanged();
  }

  public static func SetE3FirstPersonHudVisuals(game: GameInstance, enabled: Bool) -> Bool {
    let settings: ref<CRRealpassSettings> = CRRealpassSettings.Get(game);
    let ui: ref<UISystem> = GameInstance.GetUISystem(game);
    if !CRRealpassSettings.IsEnabled(game) || !IsDefined(settings) {
      return false;
    }

    if !Equals(settings.e3FirstPersonHudVisuals, enabled) {
      settings.e3FirstPersonHudVisuals = enabled;
      if IsDefined(ui) {
        ui.QueueEvent(new CRBiologyE3PreferenceChangedEvent());
      }
    }

    // Return write success rather than the Boolean value itself. OFF is a successful
    // write and must not be mistaken for failure by the Biology preference row.
    return Equals(settings.e3FirstPersonHudVisuals, enabled);
  }

  public static func ToggleE3FirstPersonHudVisuals(game: GameInstance) -> Bool {
    let settings: ref<CRRealpassSettings> = CRRealpassSettings.Get(game);
    if !CRRealpassSettings.IsEnabled(game) || !IsDefined(settings) {
      return false;
    }
    return CRRealpassSettings.SetE3FirstPersonHudVisuals(game, !settings.e3FirstPersonHudVisuals);
  }
}
