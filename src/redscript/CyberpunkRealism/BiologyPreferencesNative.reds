// Minimal Biology-owned preference UI.
//
// Biology deliberately does not register a pause-menu/settings-provider row. The
// shared Biology/Cyberware body screen already belongs to Biology and gives the one
// remaining public preference a stable, self-contained editing surface.
module CyberpunkRealism.Presentation

import CyberpunkRealism.Settings.*

@addField(RipperDocGameController)
private let crBiologyE3Preference: ref<inkText>;

@addMethod(RipperDocGameController)
private final func CRRefreshBiologyE3Preference() -> Void {
  if !IsDefined(this.crBiologyE3Preference) {
    return;
  }
  let enabled: Bool = CRRealpassSettings.UseE3FirstPersonHudVisuals(GetGameInstance());
  this.crBiologyE3Preference.SetText(enabled ? "E3 HUD + NAMEPLATES  ON" : "E3 HUD + NAMEPLATES  OFF");
  this.crBiologyE3Preference.SetOpacity(enabled ? 0.96 : 0.52);
}

@addMethod(RipperDocGameController)
private final func CRMountBiologyE3Preference() -> Void {
  if !CRRealpassSettings.IsEnabled(GetGameInstance()) || IsDefined(this.crBiologyE3Preference) {
    return;
  }

  let root: ref<inkCompoundWidget> = this.GetRootCompoundWidget();
  if !IsDefined(root) {
    return;
  }

  let toggle: ref<inkText> = new inkText();
  toggle.SetName(n"CRBiologyE3Preference");
  toggle.SetText("E3 HUD + NAMEPLATES  ON");
  toggle.SetFontFamily("base\\gameplay\\gui\\fonts\\raj\\raj.inkfontfamily");
  toggle.SetFontStyle(n"Medium");
  toggle.SetFontSize(18);
  toggle.SetFitToContent(true);
  toggle.SetInteractive(true);
  toggle.SetAnchor(inkEAnchor.TopRight);
  toggle.SetHAlign(inkEHorizontalAlign.Right);
  toggle.SetVAlign(inkEVerticalAlign.Top);
  toggle.SetMargin(inkMargin(0.0, 158.0, 48.0, 0.0));
  toggle.RegisterToCallback(n"OnRelease", this, n"OnCRBiologyE3PreferenceToggle");
  toggle.Reparent(root, -1);
  this.crBiologyE3Preference = toggle;
  this.CRRefreshBiologyE3Preference();
}

@addMethod(RipperDocGameController)
protected cb func OnCRBiologyE3PreferenceToggle(evt: ref<inkPointerEvent>) -> Bool {
  if !CRRealpassSettings.IsEnabled(GetGameInstance())
    || !IsDefined(evt)
    || !evt.IsAction(n"click")
    || evt.IsHandled() {
    return false;
  }

  CRRealpassSettings.ToggleE3FirstPersonHudVisuals(GetGameInstance());
  this.CRRefreshBiologyE3Preference();
  evt.Handle();
  return true;
}

@wrapMethod(RipperDocGameController)
protected cb func OnInitialize() -> Bool {
  let result: Bool = wrappedMethod();
  this.CRMountBiologyE3Preference();
  return result;
}
