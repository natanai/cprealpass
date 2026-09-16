// Biology-owned E3-inspired weapon/ammo presentation for the neutral first-person HUD.
// Native WeaponRosterGameController remains the sole weapon/ammo data authority.
module CyberpunkRealism.Presentation

import CyberpunkRealism.Settings.*

@addField(WeaponRosterGameController)
private let crBiologyE3WeaponFrame: ref<inkCanvas>;

@addMethod(WeaponRosterGameController)
private final func CRCreateBiologyE3WeaponFrame() -> Void {
  if IsDefined(this.crBiologyE3WeaponFrame) {
    return;
  }
  let root: ref<inkCompoundWidget> = this.GetRootCompoundWidget();
  if !IsDefined(root) {
    return;
  }

  this.crBiologyE3WeaponFrame = new inkCanvas();
  this.crBiologyE3WeaponFrame.SetName(n"CRBiologyE3WeaponFrame");
  this.crBiologyE3WeaponFrame.SetAnchor(inkEAnchor.BottomRight);
  this.crBiologyE3WeaponFrame.SetHAlign(inkEHorizontalAlign.Right);
  this.crBiologyE3WeaponFrame.SetVAlign(inkEVerticalAlign.Bottom);
  this.crBiologyE3WeaponFrame.SetSize(Vector2(484.0, 176.0));
  this.crBiologyE3WeaponFrame.SetTranslation(-10.0, -8.0);
  this.crBiologyE3WeaponFrame.Reparent(root, -1);

  CRBiologyE3Primitives.AddPlate(this.crBiologyE3WeaponFrame, n"CRBiologyE3WeaponWash", 30.0, 0.0, 430.0, 132.0, 0.050);
  CRBiologyE3Primitives.AddRect(this.crBiologyE3WeaponFrame, n"CRBiologyE3WeaponTop", 68.0, 0.0, 392.0, 4.0, 0.98);
  CRBiologyE3Primitives.AddRect(this.crBiologyE3WeaponFrame, n"CRBiologyE3WeaponRight", 456.0, 0.0, 4.0, 126.0, 0.98);
  CRBiologyE3Primitives.AddRect(this.crBiologyE3WeaponFrame, n"CRBiologyE3WeaponBottom", 270.0, 126.0, 190.0, 4.0, 0.78);
  CRBiologyE3Primitives.AddRect(this.crBiologyE3WeaponFrame, n"CRBiologyE3WeaponAccent", 38.0, 0.0, 21.0, 9.0, 1.00);
  CRBiologyE3Primitives.AddLabel(this.crBiologyE3WeaponFrame, n"CRBiologyE3WeaponLabel", "WEAPON // AMMO", 68.0, 8.0, 14, 0.82);
}

@addMethod(WeaponRosterGameController)
private final func CRRefreshBiologyE3WeaponFrame() -> Void {
  let enabled: Bool = CRRealpassSettings.UseE3FirstPersonHudVisuals(GetGameInstance());
  this.CRCreateBiologyE3WeaponFrame();
  if IsDefined(this.crBiologyE3WeaponFrame) {
    this.crBiologyE3WeaponFrame.SetVisible(enabled);
  }
}

@wrapMethod(WeaponRosterGameController)
protected cb func OnInitialize() -> Bool {
  let result: Bool = wrappedMethod();
  this.CRRefreshBiologyE3WeaponFrame();
  return result;
}

@wrapMethod(WeaponRosterGameController)
private func SetRosterSlotData() -> Void {
  wrappedMethod();
  this.CRRefreshBiologyE3WeaponFrame();
}
