// Biology-owned E3-inspired D-pad/quick-slot presentation for the neutral HUD.
// Input semantics and consumable/phone slots remain native.
module CyberpunkRealism.Presentation

import CyberpunkRealism.Settings.*

@addField(HotkeysWidgetController)
private let crBiologyE3HotkeyFrame: ref<inkCanvas>;

@addMethod(HotkeysWidgetController)
private final func CRCreateBiologyE3HotkeyFrame() -> Void {
  if IsDefined(this.crBiologyE3HotkeyFrame) {
    return;
  }
  let root: ref<inkCompoundWidget> = this.GetRootCompoundWidget();
  if !IsDefined(root) {
    return;
  }

  this.crBiologyE3HotkeyFrame = new inkCanvas();
  this.crBiologyE3HotkeyFrame.SetName(n"CRBiologyE3HotkeyFrame");
  this.crBiologyE3HotkeyFrame.SetAnchor(inkEAnchor.BottomLeft);
  this.crBiologyE3HotkeyFrame.SetHAlign(inkEHorizontalAlign.Left);
  this.crBiologyE3HotkeyFrame.SetVAlign(inkEVerticalAlign.Bottom);
  this.crBiologyE3HotkeyFrame.SetSize(Vector2(324.0, 132.0));
  this.crBiologyE3HotkeyFrame.SetTranslation(0.0, -4.0);
  this.crBiologyE3HotkeyFrame.Reparent(root, -1);

  CRBiologyE3Primitives.AddPlate(this.crBiologyE3HotkeyFrame, n"CRBiologyE3HotkeyWash", 0.0, 14.0, 286.0, 96.0, 0.045);
  CRBiologyE3Primitives.AddRect(this.crBiologyE3HotkeyFrame, n"CRBiologyE3HotkeyLeft", 0.0, 14.0, 4.0, 86.0, 0.92);
  CRBiologyE3Primitives.AddRect(this.crBiologyE3HotkeyFrame, n"CRBiologyE3HotkeyTop", 0.0, 14.0, 222.0, 4.0, 0.92);
  CRBiologyE3Primitives.AddRect(this.crBiologyE3HotkeyFrame, n"CRBiologyE3HotkeyBottom", 0.0, 96.0, 146.0, 4.0, 0.68);
  CRBiologyE3Primitives.AddRect(this.crBiologyE3HotkeyFrame, n"CRBiologyE3HotkeyTick", 234.0, 14.0, 26.0, 4.0, 0.58);
  CRBiologyE3Primitives.AddLabel(this.crBiologyE3HotkeyFrame, n"CRBiologyE3HotkeyLabel", "QUICK // INPUT", 12.0, 22.0, 13, 0.78);
}

@addMethod(HotkeysWidgetController)
private final func CRRefreshBiologyE3HotkeyFrame() -> Void {
  let enabled: Bool = CRRealpassSettings.UseE3FirstPersonHudVisuals(GetGameInstance());
  this.CRCreateBiologyE3HotkeyFrame();
  if IsDefined(this.crBiologyE3HotkeyFrame) {
    this.crBiologyE3HotkeyFrame.SetVisible(enabled);
  }
}

@wrapMethod(HotkeysWidgetController)
protected cb func OnInitialize() -> Bool {
  let result: Bool = wrappedMethod();
  this.CRRefreshBiologyE3HotkeyFrame();
  return result;
}
