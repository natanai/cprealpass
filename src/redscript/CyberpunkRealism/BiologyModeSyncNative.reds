// Keep contextual action/node interactivity synchronized with the shared
// Biology/Cyberware mode controls without giving this layer simulation authority.
module CyberpunkRealism.Presentation

@addMethod(CyberwareInventoryMiniGrid)
public final func CRSetBiologyLabelInteractive(active: Bool) -> Void {
  inkTextRef.SetInteractive(this.m_label, active);
}

@addMethod(RipperDocGameController)
private final func CRSyncBiologyNodeInteractivity(active: Bool) -> Void {
  let i: Int32 = 0;
  while i < ArraySize(this.m_equipmentMinigrids) {
    if IsDefined(this.m_equipmentMinigrids[i]) {
      this.m_equipmentMinigrids[i].CRSetBiologyLabelInteractive(active && CRBiologyDetailPresentation.Supported(this.m_equipmentMinigrids[i].CRBiologyArea()));
    }
    i += 1;
  }
}

@addMethod(RipperDocGameController)
protected cb func OnCRBioModeActionSync(evt: ref<inkPointerEvent>) -> Bool {
  if !IsDefined(evt) || !evt.IsAction(n"click") {
    return false;
  }
  let target: wref<inkWidget> = evt.GetCurrentTarget();
  if target == this.crBiologyModeButton {
    this.CRApplyBiologyShellMode(true);
    this.CRSyncBiologyNodeInteractivity(true);
    this.CRRefreshBiologyActions();
    return true;
  }
  if target == this.crCyberwareModeButton {
    this.CRApplyBiologyShellMode(false);
    this.CRSyncBiologyNodeInteractivity(false);
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
  this.CRSyncBiologyNodeInteractivity(this.crBiologyShellMode);
  this.CRRefreshBiologyActions();
  return result;
}
