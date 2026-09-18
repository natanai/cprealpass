// Biology-owned E3-inspired weapon/ammo presentation.
// Native WeaponRosterGameController remains the sole weapon/ammo authority. W03.4
// replaces the attended full-root red slab with the same compact chrome used elsewhere.
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
  CRBiologyE3Primitives.AddPanelChrome(this.crBiologyE3WeaponFrame, "WEAPON // AMMO", 178.0);
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
