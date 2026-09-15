// Biology-owned restrained E3-inspired crosshair accent.
// The native tech-weapon crosshair remains responsible for spread, charge, ADS and
// aiming behavior. Biology does not reproduce Project E3's ADS hiding/layout logic.
module CyberpunkRealism.Presentation

import CyberpunkRealism.Settings.*

@addField(CrosshairGameController_Tech_Hex)
private let crBiologyE3CrosshairFrame: ref<inkCanvas>;

@addMethod(CrosshairGameController_Tech_Hex)
private final func CRCreateBiologyE3CrosshairFrame() -> Void {
  if IsDefined(this.crBiologyE3CrosshairFrame) {
    return;
  }
  let root: ref<inkCompoundWidget> = this.GetRootWidget() as inkCompoundWidget;
  if !IsDefined(root) {
    return;
  }

  this.crBiologyE3CrosshairFrame = new inkCanvas();
  this.crBiologyE3CrosshairFrame.SetName(n"CRBiologyE3CrosshairFrame");
  this.crBiologyE3CrosshairFrame.SetAnchor(inkEAnchor.Centered);
  this.crBiologyE3CrosshairFrame.SetHAlign(inkEHorizontalAlign.Center);
  this.crBiologyE3CrosshairFrame.SetVAlign(inkEVerticalAlign.Center);
  this.crBiologyE3CrosshairFrame.SetSize(Vector2(108.0, 108.0));
  this.crBiologyE3CrosshairFrame.SetAffectsLayoutWhenHidden(false);
  this.crBiologyE3CrosshairFrame.Reparent(root, -1);

  CRBiologyE3Primitives.AddRect(this.crBiologyE3CrosshairFrame, n"CRBiologyE3CrosshairTLH", 8.0, 8.0, 22.0, 2.0, 0.72);
  CRBiologyE3Primitives.AddRect(this.crBiologyE3CrosshairFrame, n"CRBiologyE3CrosshairTLV", 8.0, 8.0, 2.0, 22.0, 0.72);
  CRBiologyE3Primitives.AddRect(this.crBiologyE3CrosshairFrame, n"CRBiologyE3CrosshairBRH", 78.0, 98.0, 22.0, 2.0, 0.72);
  CRBiologyE3Primitives.AddRect(this.crBiologyE3CrosshairFrame, n"CRBiologyE3CrosshairBRV", 98.0, 78.0, 2.0, 22.0, 0.72);
}

@addMethod(CrosshairGameController_Tech_Hex)
private final func CRRefreshBiologyE3CrosshairFrame() -> Void {
  this.CRCreateBiologyE3CrosshairFrame();
  if IsDefined(this.crBiologyE3CrosshairFrame) {
    this.crBiologyE3CrosshairFrame.SetVisible(CRRealpassSettings.UseE3FirstPersonHudVisuals(GetGameInstance()));
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
