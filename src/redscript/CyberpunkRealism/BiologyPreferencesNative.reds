// Biology-owned presentation preference inside the authored Biology detail region.
//
// T006 proved that a free-floating TopRight text control attached to the fullscreen
// RipperDocGameController root is clipped and effectively unusable. Keep the one
// legitimate save-backed preference, but make it a normal Biology detail subsection:
// it is a child of CRBiologyNativeContent, which W17.1 mounts under the native
// RipperdocInventoryController lifecycle as a sibling of authored cyberwareContainer.
//
// The row owns a 680x48 local hit target. It never reconstructs screen-space position,
// never registers a second settings provider, and never becomes an authority separate
// from CRRealpassSettings.
module CyberpunkRealism.Presentation

import CyberpunkRealism.Settings.*

@addField(RipperDocGameController)
private let crBiologyE3PreferencePanel: ref<inkVerticalPanel>;

@addField(RipperDocGameController)
private let crBiologyE3PreferenceRow: ref<inkCanvas>;

@addField(RipperDocGameController)
private let crBiologyE3PreferenceBackground: ref<inkRectangle>;

@addField(RipperDocGameController)
private let crBiologyE3PreferenceValue: ref<inkText>;

@addMethod(RipperDocGameController)
private final func CRBiologyE3PreferenceText(text: String, name: CName, size: Int32) -> ref<inkText> {
  let widget: ref<inkText> = new inkText();
  widget.SetName(name);
  widget.SetText(text);
  widget.SetFontFamily("base\\gameplay\\gui\\fonts\\raj\\raj.inkfontfamily");
  widget.SetFontStyle(n"Medium");
  widget.SetFontSize(size);
  widget.SetFitToContent(true);
  widget.SetInteractive(false);
  return widget;
}

@addMethod(RipperDocGameController)
public final func CRRefreshBiologyE3Preference() -> Void {
  if !IsDefined(this.crBiologyE3PreferenceValue) || !IsDefined(this.crBiologyE3PreferenceBackground) {
    return;
  }

  let player: wref<GameObject> = this.GetPlayerControlledObject();
  if !IsDefined(player) || !IsDefined(CRRealpassSettings.Get(player.GetGame())) {
    this.crBiologyE3PreferenceValue.SetText("UNAVAILABLE");
    this.crBiologyE3PreferenceValue.SetOpacity(0.68);
    return;
  }
  let enabled: Bool = CRRealpassSettings.UseE3FirstPersonHudVisuals(player.GetGame());
  this.crBiologyE3PreferenceValue.SetText(enabled ? "ON" : "OFF");
  this.crBiologyE3PreferenceValue.SetOpacity(enabled ? 1.0 : 0.68);
  this.crBiologyE3PreferenceBackground.SetOpacity(0.10);
}

@addMethod(RipperDocGameController)
public final func CRMountBiologyE3PreferenceInNativeContent(host: ref<inkVerticalPanel>) -> Void {
  let player: wref<GameObject> = this.GetPlayerControlledObject();
  if !IsDefined(player) || !CRRealpassSettings.IsEnabled(player.GetGame()) || !IsDefined(host) {
    return;
  }

  if !IsDefined(this.crBiologyE3PreferencePanel) {
    let panel: ref<inkVerticalPanel> = new inkVerticalPanel();
    panel.SetName(n"CRBiologyE3PreferencePanel");
    panel.SetChildMargin(inkMargin(0.0, 3.0, 0.0, 3.0));
    panel.SetMargin(inkMargin(0.0, 18.0, 0.0, 0.0));
    panel.SetFitToContent(true);

    let heading: ref<inkText> = this.CRBiologyE3PreferenceText("PRESENTATION", n"CRBiologyE3PreferenceHeading", 17);
    heading.SetOpacity(0.62);
    heading.Reparent(panel, -1);

    let row: ref<inkCanvas> = new inkCanvas();
    row.SetName(n"CRBiologyE3PreferenceRow");
    row.SetSize(Vector2(680.0, 48.0));
    row.SetInteractive(true);
    row.RegisterToCallback(n"OnRelease", this, n"OnCRBiologyE3PreferenceToggle");
    row.RegisterToCallback(n"OnHoverOver", this, n"OnCRBiologyE3PreferenceHoverOver");
    row.RegisterToCallback(n"OnHoverOut", this, n"OnCRBiologyE3PreferenceHoverOut");
    row.Reparent(panel, -1);

    let background: ref<inkRectangle> = new inkRectangle();
    background.SetName(n"CRBiologyE3PreferenceBackground");
    background.SetSize(Vector2(680.0, 44.0));
    background.SetTranslation(0.0, 2.0);
    background.SetOpacity(0.10);
    background.SetInteractive(false);
    background.Reparent(row, -1);

    let label: ref<inkText> = this.CRBiologyE3PreferenceText("E3 HUD + NAMEPLATES", n"CRBiologyE3PreferenceLabel", 18);
    label.SetTranslation(16.0, 10.0);
    label.SetOpacity(0.86);
    label.Reparent(row, -1);

    this.crBiologyE3PreferenceValue = this.CRBiologyE3PreferenceText("ON", n"CRBiologyE3PreferenceValue", 18);
    this.crBiologyE3PreferenceValue.SetTranslation(602.0, 10.0);
    this.crBiologyE3PreferenceValue.Reparent(row, -1);

    this.crBiologyE3PreferencePanel = panel;
    this.crBiologyE3PreferenceRow = row;
    this.crBiologyE3PreferenceBackground = background;
    panel.Reparent(host, -1);
  }

  this.CRRefreshBiologyE3Preference();
}

@addMethod(RipperDocGameController)
public final func CRResetBiologyE3Preference() -> Void {
  this.crBiologyE3PreferencePanel = null;
  this.crBiologyE3PreferenceRow = null;
  this.crBiologyE3PreferenceBackground = null;
  this.crBiologyE3PreferenceValue = null;
}

@addMethod(RipperDocGameController)
protected cb func OnCRBiologyE3PreferenceToggle(evt: ref<inkPointerEvent>) -> Bool {
  let player: wref<GameObject> = this.GetPlayerControlledObject();
  if !IsDefined(player) || !CRRealpassSettings.IsEnabled(player.GetGame())
    || !this.CRBiologyInDetail()
    || !IsDefined(evt)
    || !evt.IsAction(n"click")
    || evt.IsHandled() {
    return false;
  }

  // This callback is registered only on the row. Decorative children cannot take
  // pointer ownership; do not discard a bubbled event based on its current target.
  let written: Bool = CRRealpassSettings.ToggleE3FirstPersonHudVisuals(player.GetGame());
  this.CRRefreshBiologyE3Preference();
  if !written {
    return false;
  }
  evt.Handle();
  return true;
}

@addMethod(RipperDocGameController)
protected cb func OnCRBiologyE3PreferenceHoverOver(evt: ref<inkPointerEvent>) -> Bool {
  if !IsDefined(evt)
    || !IsDefined(this.crBiologyE3PreferenceBackground) {
    return false;
  }
  this.crBiologyE3PreferenceBackground.SetOpacity(0.18);
  return true;
}

@addMethod(RipperDocGameController)
protected cb func OnCRBiologyE3PreferenceHoverOut(evt: ref<inkPointerEvent>) -> Bool {
  if !IsDefined(evt)
    || !IsDefined(this.crBiologyE3PreferenceBackground) {
    return false;
  }
  this.crBiologyE3PreferenceBackground.SetOpacity(0.10);
  return true;
}
