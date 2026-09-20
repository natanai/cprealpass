// Biology-owned ordinary crosshair/focus treatment.
//
// T002 conclusively identified the previous CRBiologyE3FocusFrame as the reticle artifact:
// its 112x112 centered canvas drew exactly the top-left and bottom-right red corners seen
// beside the live reticle. W03.4 deletes that geometry entirely.
//
// Ordinary crosshair treatment now uses the native crosshair root itself. The native
// gameuiCrosshairBaseGameController already hides that root in Scanning state, so this
// tint does not create Biology geometry in the modern scanner/quickhack presentation.
module CyberpunkRealism.Presentation

import CyberpunkRealism.Settings.*

@addField(gameuiCrosshairBaseGameController)
private let crBiologyE3NativeCrosshairTint: HDRColor;

@addField(gameuiCrosshairBaseGameController)
private let crBiologyE3HasNativeCrosshairTint: Bool;

@addMethod(gameuiCrosshairBaseGameController)
private final func CRCaptureBiologyE3CrosshairTint() -> Void {
  let root: ref<inkWidget> = this.GetRootWidget();
  if IsDefined(root) && !this.crBiologyE3HasNativeCrosshairTint {
    this.crBiologyE3NativeCrosshairTint = root.GetTintColor();
    this.crBiologyE3HasNativeCrosshairTint = true;
  }
}

@addMethod(gameuiCrosshairBaseGameController)
private final func CRRestoreBiologyE3CrosshairTint() -> Void {
  let root: ref<inkWidget> = this.GetRootWidget();
  if IsDefined(root) && this.crBiologyE3HasNativeCrosshairTint {
    root.SetTintColor(this.crBiologyE3NativeCrosshairTint);
  }
  this.crBiologyE3HasNativeCrosshairTint = false;
}

@addMethod(gameuiCrosshairBaseGameController)
private final func CRRefreshBiologyE3CrosshairTint() -> Void {
  let root: ref<inkWidget> = this.GetRootWidget();
  if !IsDefined(root) {
    return;
  }

  this.CRRestoreBiologyE3CrosshairTint();
  if CRRealpassSettings.UseE3FirstPersonHudVisuals(GetGameInstance()) {
    this.CRCaptureBiologyE3CrosshairTint();
    root.SetTintColor(CRBiologyE3Primitives.Red());
  }
}

@wrapMethod(gameuiCrosshairBaseGameController)
protected cb func OnInitialize() -> Bool {
  let result: Bool = wrappedMethod();
  CRBiologyE3Primitives.Trace("gameuiCrosshairBaseGameController.OnInitialize");
  this.CRRefreshBiologyE3CrosshairTint();
  return result;
}

@wrapMethod(gameuiCrosshairBaseGameController)
protected func OnCrosshairStateChange(oldState: gamePSMCrosshairStates, newState: gamePSMCrosshairStates) -> Void {
  this.CRRestoreBiologyE3CrosshairTint();
  wrappedMethod(oldState, newState);
  this.CRRefreshBiologyE3CrosshairTint();
}

@addMethod(gameuiCrosshairBaseGameController)
protected cb func OnCRBiologyE3PreferenceChangedEvent(evt: ref<CRBiologyE3PreferenceChangedEvent>) -> Bool {
  this.CRRefreshBiologyE3CrosshairTint();
  return true;
}
