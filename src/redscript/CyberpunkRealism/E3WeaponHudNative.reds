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
  this.crBiologyE3WeaponFrame.SetSize(Vector2(456.0, 154.0));
  this.crBiologyE3WeaponFrame.SetTranslation(-14.0, -12.0);
  this.crBiologyE3WeaponFrame.Reparent(root, -1);

  CRBiologyE3Primitives.AddRect(this.crBiologyE3WeaponFrame, n"CRBiologyE3WeaponTop", 74.0, 0.0, 356.0, 3.0, 0.92);
  CRBiologyE3Primitives.AddRect(this.crBiologyE3WeaponFrame, n"CRBiologyE3WeaponRight", 427.0, 0.0, 3.0, 116.0, 0.92);
  CRBiologyE3Primitives.AddRect(this.crBiologyE3WeaponFrame, n"CRBiologyE3WeaponBottom", 252.0, 116.0, 178.0, 3.0, 0.72);
  CRBiologyE3Primitives.AddRect(this.crBiologyE3WeaponFrame, n"CRBiologyE3WeaponAccent", 45.0, 0.0, 20.0, 7.0, 1.00);
}

@addMethod(WeaponRosterGameController)
private final func CRRefreshBiologyE3WeaponFrame() -> Void {
  let enabled: Bool = CRRealpassSettings.UseE3FirstPersonHudVisuals(GetGameInstance());
  this.CRCreateBiologyE3WeaponFrame();
  CRBiologyE3Primitives.TintNeutralHudRoot(this.GetRootWidget(), enabled);
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
