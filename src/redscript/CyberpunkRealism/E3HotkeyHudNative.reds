// Biology-owned E3-inspired D-pad/quick-slot presentation.
// Input semantics and slot authority remain native.
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

  this.crBiologyE3HotkeyFrame = CRBiologyE3Primitives.CreateFillShell(root, n"CRBiologyE3HotkeyFrame");
  CRBiologyE3Primitives.AddFillWash(this.crBiologyE3HotkeyFrame, n"CRBiologyE3HotkeyWash", 0.060);
  CRBiologyE3Primitives.AddRect(this.crBiologyE3HotkeyFrame, n"CRBiologyE3HotkeyTop", 0.0, 0.0, 160.0, 3.0, 0.92);
  CRBiologyE3Primitives.AddRect(this.crBiologyE3HotkeyFrame, n"CRBiologyE3HotkeyLeft", 0.0, 0.0, 3.0, 44.0, 0.84);
  CRBiologyE3Primitives.AddRect(this.crBiologyE3HotkeyFrame, n"CRBiologyE3HotkeyAccent", 0.0, 0.0, 20.0, 7.0, 1.00);
  CRBiologyE3Primitives.AddLabel(this.crBiologyE3HotkeyFrame, n"CRBiologyE3HotkeyLabel", "QUICK // INPUT", 28.0, 7.0, 12, 0.80);
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
  CRBiologyE3Primitives.Trace("HotkeysWidgetController.OnInitialize");
  this.CRRefreshBiologyE3HotkeyFrame();
  return result;
}
