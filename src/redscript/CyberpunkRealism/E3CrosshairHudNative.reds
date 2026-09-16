// Biology-owned E3-inspired crosshair/focus treatment.
//
// The generic current crosshair container gives ordinary weapon crosshairs one shared
// presentation seam. Native crosshair controllers still own spread, charge, ADS,
// weapon selection and visibility. In particular, the native container hides itself
// outside default vision, so Biology does not need a scanner/quickhack hook.
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
  this.crBiologyE3FocusFrame.SetSize(Vector2(164.0, 164.0));
  this.crBiologyE3FocusFrame.Reparent(root, -1);

  CRBiologyE3Primitives.AddRect(this.crBiologyE3FocusFrame, n"CRBiologyE3FocusTLH", 8.0, 8.0, 34.0, 3.0, 0.76);
  CRBiologyE3Primitives.AddRect(this.crBiologyE3FocusFrame, n"CRBiologyE3FocusTLV", 8.0, 8.0, 3.0, 34.0, 0.76);
  CRBiologyE3Primitives.AddRect(this.crBiologyE3FocusFrame, n"CRBiologyE3FocusTRH", 122.0, 8.0, 34.0, 3.0, 0.56);
  CRBiologyE3Primitives.AddRect(this.crBiologyE3FocusFrame, n"CRBiologyE3FocusBRH", 122.0, 153.0, 34.0, 3.0, 0.76);
  CRBiologyE3Primitives.AddRect(this.crBiologyE3FocusFrame, n"CRBiologyE3FocusBRV", 153.0, 122.0, 3.0, 34.0, 0.76);
  CRBiologyE3Primitives.AddRect(this.crBiologyE3FocusFrame, n"CRBiologyE3FocusBLH", 8.0, 153.0, 22.0, 3.0, 0.48);
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
  this.CRRefreshBiologyE3FocusFrame();
  return result;
}

// Tech-Hex keeps a restrained inner treatment from W03.1. It remains presentation
// only; the broader container above is what makes the E3 focus language apply across
// ordinary weapon types rather than one tech-weapon crosshair.
@addField(CrosshairGameController_Tech_Hex)
private let crBiologyE3CrosshairFrame: ref<inkCanvas>;

@addMethod(CrosshairGameController_Tech_Hex)
private final func CRCreateBiologyE3CrosshairFrame() -> Void {
  if IsDefined(this.crBiologyE3CrosshairFrame) {
    return;
  }
  let root: ref<inkCompoundWidget> = this.GetRootCompoundWidget();
  if !IsDefined(root) {
    return;
  }

  this.crBiologyE3CrosshairFrame = new inkCanvas();
  this.crBiologyE3CrosshairFrame.SetName(n"CRBiologyE3CrosshairFrame");
  this.crBiologyE3CrosshairFrame.SetAnchor(inkEAnchor.Centered);
  this.crBiologyE3CrosshairFrame.SetHAlign(inkEHorizontalAlign.Center);
  this.crBiologyE3CrosshairFrame.SetVAlign(inkEVerticalAlign.Center);
  this.crBiologyE3CrosshairFrame.SetSize(Vector2(108.0, 108.0));
  this.crBiologyE3CrosshairFrame.Reparent(root, -1);

  CRBiologyE3Primitives.AddRect(this.crBiologyE3CrosshairFrame, n"CRBiologyE3CrosshairTLH", 8.0, 8.0, 22.0, 2.0, 0.68);
  CRBiologyE3Primitives.AddRect(this.crBiologyE3CrosshairFrame, n"CRBiologyE3CrosshairTLV", 8.0, 8.0, 2.0, 22.0, 0.68);
  CRBiologyE3Primitives.AddRect(this.crBiologyE3CrosshairFrame, n"CRBiologyE3CrosshairBRH", 78.0, 98.0, 22.0, 2.0, 0.68);
  CRBiologyE3Primitives.AddRect(this.crBiologyE3CrosshairFrame, n"CRBiologyE3CrosshairBRV", 98.0, 78.0, 2.0, 22.0, 0.68);
}

@addMethod(CrosshairGameController_Tech_Hex)
private final func CRRefreshBiologyE3CrosshairFrame() -> Void {
  let enabled: Bool = CRRealpassSettings.UseE3FirstPersonHudVisuals(GetGameInstance());
  this.CRCreateBiologyE3CrosshairFrame();
  if IsDefined(this.crBiologyE3CrosshairFrame) {
    this.crBiologyE3CrosshairFrame.SetVisible(enabled);
  }
}

@wrapMethod(CrosshairGameController_Tech_Hex)
protected cb func OnInitialize() -> Bool {
  let result: Bool = wrappedMethod();
  this.CRRefreshBiologyE3CrosshairFrame();
  return result;
}

@wrapMethod(CrosshairGameController_Tech_Hex)
protected func OnState_Aim() -> Void {
  wrappedMethod();
  this.CRRefreshBiologyE3CrosshairFrame();
}

@wrapMethod(CrosshairGameController_Tech_Hex)
protected func OnState_HipFire() -> Void {
  wrappedMethod();
  this.CRRefreshBiologyE3CrosshairFrame();
}
