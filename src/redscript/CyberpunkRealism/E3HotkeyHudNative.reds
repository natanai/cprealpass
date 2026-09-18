// Biology-owned E3-inspired D-pad/quick-slot presentation.
// Input semantics and slot authority remain native. W03.4 removes the full-root wash
// that made the bottom-left HUD read as an opaque red block in T002.
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
  CRBiologyE3Primitives.AddPanelChrome(this.crBiologyE3HotkeyFrame, "QUICK // INPUT", 154.0);
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
