// Biology-owned ordinary crosshair/focus treatment.
//
// W03.3 keeps one generic current crosshair-container seam. The W03.2 Tech-Hex child
// frame is intentionally removed: it could remain visible independently near scanner
// focus and is one plausible source of the attended post-scan red rectangle. Native
// crosshair controllers still own spread, charge, ADS, weapon selection and visibility.
module CyberpunkRealism.Presentation

import CyberpunkRealism.Settings.*

@addField(gameuiCrosshairContainerController)
private let crBiologyE3FocusFrame: ref<inkCanvas>;

@addMethod(gameuiCrosshairContainerController)
private final func CRCreateBiologyE3FocusFrame() -> Void {
  if IsDefined(this.crBiologyE3FocusFrame) {
    return;
  }
  let root: ref<inkCompoundWidget> = this.GetRootCompoundWidget();
  if !IsDefined(root) {
    return;
  }

  this.crBiologyE3FocusFrame = new inkCanvas();
  this.crBiologyE3FocusFrame.SetName(n"CRBiologyE3FocusFrame");
  this.crBiologyE3FocusFrame.SetAnchor(inkEAnchor.Centered);
  this.crBiologyE3FocusFrame.SetHAlign(inkEHorizontalAlign.Center);
  this.crBiologyE3FocusFrame.SetVAlign(inkEVerticalAlign.Center);
  this.crBiologyE3FocusFrame.SetSize(Vector2(112.0, 112.0));
  this.crBiologyE3FocusFrame.Reparent(root, -1);

  CRBiologyE3Primitives.AddRect(this.crBiologyE3FocusFrame, n"CRBiologyE3FocusTLH", 4.0, 4.0, 22.0, 2.0, 0.72);
  CRBiologyE3Primitives.AddRect(this.crBiologyE3FocusFrame, n"CRBiologyE3FocusTLV", 4.0, 4.0, 2.0, 22.0, 0.72);
  CRBiologyE3Primitives.AddRect(this.crBiologyE3FocusFrame, n"CRBiologyE3FocusBRH", 86.0, 106.0, 22.0, 2.0, 0.72);
  CRBiologyE3Primitives.AddRect(this.crBiologyE3FocusFrame, n"CRBiologyE3FocusBRV", 106.0, 86.0, 2.0, 22.0, 0.72);
}

@addMethod(gameuiCrosshairContainerController)
private final func CRRefreshBiologyE3FocusFrame() -> Void {
  let enabled: Bool = CRRealpassSettings.UseE3FirstPersonHudVisuals(GetGameInstance());
  this.CRCreateBiologyE3FocusFrame();
  if IsDefined(this.crBiologyE3FocusFrame) {
    this.crBiologyE3FocusFrame.SetVisible(enabled);
  }
}

@wrapMethod(gameuiCrosshairContainerController)
protected cb func OnInitialize() -> Bool {
  let result: Bool = wrappedMethod();
  CRBiologyE3Primitives.Trace("gameuiCrosshairContainerController.OnInitialize");
  this.CRRefreshBiologyE3FocusFrame();
  return result;
}
