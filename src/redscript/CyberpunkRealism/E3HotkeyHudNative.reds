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
  this.crBiologyE3HotkeyFrame.SetSize(Vector2(286.0, 112.0));
  this.crBiologyE3HotkeyFrame.SetTranslation(0.0, -8.0);
  this.crBiologyE3HotkeyFrame.Reparent(root, -1);

  CRBiologyE3Primitives.AddRect(this.crBiologyE3HotkeyFrame, n"CRBiologyE3HotkeyLeft", 0.0, 18.0, 3.0, 70.0, 0.76);
  CRBiologyE3Primitives.AddRect(this.crBiologyE3HotkeyFrame, n"CRBiologyE3HotkeyTop", 0.0, 18.0, 158.0, 3.0, 0.76);
  CRBiologyE3Primitives.AddRect(this.crBiologyE3HotkeyFrame, n"CRBiologyE3HotkeyTick", 169.0, 18.0, 22.0, 3.0, 0.52);
}

@addMethod(HotkeysWidgetController)
private final func CRRefreshBiologyE3HotkeyFrame() -> Void {
  let enabled: Bool = CRRealpassSettings.UseE3FirstPersonHudVisuals(GetGameInstance());
  this.CRCreateBiologyE3HotkeyFrame();
  CRBiologyE3Primitives.TintNeutralHudRoot(this.GetRootWidget(), enabled);
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
