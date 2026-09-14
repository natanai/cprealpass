// Keep contextual action visibility synchronized with the shared Biology/Cyberware
// mode controls without giving the action layer any simulation authority.
module CyberpunkRealism.Presentation

@addMethod(RipperDocGameController)
protected cb func OnCRBioModeActionSync(evt: ref<inkPointerEvent>) -> Bool {
  if !IsDefined(evt) || !evt.IsAction(n"click") {
    return false;
  }
  let target: wref<inkWidget> = evt.GetCurrentTarget();
  if target == this.crBiologyModeButton {
    this.CRApplyBiologyShellMode(true);
    this.CRRefreshBiologyActions();
    return true;
  }
  if target == this.crCyberwareModeButton {
    this.CRApplyBiologyShellMode(false);
    this.CRRefreshBiologyActions();
    return true;
  }
  return false;
}

@wrapMethod(RipperDocGameController)
protected cb func OnInitialize() -> Bool {
  let result: Bool = wrappedMethod();
  if IsDefined(this.crBiologyModeButton) {
    this.crBiologyModeButton.RegisterToCallback(n"OnRelease", this, n"OnCRBioModeActionSync");
  }
  if IsDefined(this.crCyberwareModeButton) {
    this.crCyberwareModeButton.RegisterToCallback(n"OnRelease", this, n"OnCRBioModeActionSync");
  }
  this.CRRefreshBiologyActions();
  return result;
}
