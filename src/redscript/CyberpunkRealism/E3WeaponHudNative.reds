// Biology-owned E3-inspired weapon/ammo presentation.
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

  this.crBiologyE3WeaponFrame = CRBiologyE3Primitives.CreateFillShell(root, n"CRBiologyE3WeaponFrame");
  CRBiologyE3Primitives.AddFillWash(this.crBiologyE3WeaponFrame, n"CRBiologyE3WeaponWash", 0.080);
  CRBiologyE3Primitives.AddRect(this.crBiologyE3WeaponFrame, n"CRBiologyE3WeaponTop", 0.0, 0.0, 200.0, 4.0, 0.98);
  CRBiologyE3Primitives.AddRect(this.crBiologyE3WeaponFrame, n"CRBiologyE3WeaponLeft", 0.0, 0.0, 4.0, 54.0, 0.88);
  CRBiologyE3Primitives.AddRect(this.crBiologyE3WeaponFrame, n"CRBiologyE3WeaponAccent", 0.0, 0.0, 24.0, 9.0, 1.00);
  CRBiologyE3Primitives.AddLabel(this.crBiologyE3WeaponFrame, n"CRBiologyE3WeaponLabel", "WEAPON // AMMO", 32.0, 8.0, 13, 0.86);
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
  CRBiologyE3Primitives.Trace("WeaponRosterGameController.OnInitialize");
  this.CRRefreshBiologyE3WeaponFrame();
  return result;
}

@wrapMethod(WeaponRosterGameController)
private func SetRosterSlotData() -> Void {
  wrappedMethod();
  this.CRRefreshBiologyE3WeaponFrame();
}
