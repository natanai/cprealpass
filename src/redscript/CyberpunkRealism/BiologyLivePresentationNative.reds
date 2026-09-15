// Live-validated native lifecycle repairs for the shared Biology/Cyberware shell.
//
// RipperDocGameController builds its ten CyberwareInventoryMiniGrid controllers
// asynchronously. OnInitialize therefore fires too early to transform those grids
// into Biology nodes. Apply the already-selected Biology/Cyberware mode again at the
// stock InitializeEquipmentMinigrids completion boundary, then promote RealPass's
// dynamic overlays to the same visible root layer used by proven Ripperdoc UI mods.
module CyberpunkRealism.Presentation

@addMethod(RipperDocGameController)
private final func CRPromoteBiologyOverlay() -> Void {
  let root: ref<inkCompoundWidget> = this.GetRootCompoundWidget();
  if !IsDefined(root) {
    return;
  }

  if IsDefined(this.crBiologyModeBar) {
    this.crBiologyModeBar.SetAnchor(inkEAnchor.TopCenter);
    this.crBiologyModeBar.SetAnchorPoint(Vector2(0.5, 0.0));
    this.crBiologyModeBar.SetHAlign(inkEHorizontalAlign.Center);
    this.crBiologyModeBar.SetVAlign(inkEVerticalAlign.Top);
    this.crBiologyModeBar.SetSize(Vector2(460.0, 54.0));
    this.crBiologyModeBar.SetInteractive(true);
    this.crBiologyModeBar.Reparent(root, 5);
  }

  if IsDefined(this.crBiologyOverview) {
    this.crBiologyOverview.SetAnchor(inkEAnchor.BottomCenter);
    this.crBiologyOverview.SetAnchorPoint(Vector2(0.5, 1.0));
    this.crBiologyOverview.SetHAlign(inkEHorizontalAlign.Center);
    this.crBiologyOverview.SetVAlign(inkEVerticalAlign.Bottom);
    this.crBiologyOverview.Reparent(root, 5);
  }

  if IsDefined(this.crBiologyDetailPanel) {
    this.crBiologyDetailPanel.SetAnchor(inkEAnchor.BottomCenter);
    this.crBiologyDetailPanel.SetAnchorPoint(Vector2(0.5, 1.0));
    this.crBiologyDetailPanel.SetHAlign(inkEHorizontalAlign.Center);
    this.crBiologyDetailPanel.SetVAlign(inkEVerticalAlign.Bottom);
    this.crBiologyDetailPanel.Reparent(root, 5);
  }

  if IsDefined(this.crBioActionsPanel) {
    this.crBioActionsPanel.SetAnchor(inkEAnchor.CenterRight);
    this.crBioActionsPanel.SetAnchorPoint(Vector2(1.0, 0.5));
    this.crBioActionsPanel.SetHAlign(inkEHorizontalAlign.Right);
    this.crBioActionsPanel.SetVAlign(inkEVerticalAlign.Center);
    this.crBioActionsPanel.Reparent(root, 5);
  }
}

@wrapMethod(RipperDocGameController)
private final func InitializeEquipmentMinigrids() -> Void {
  wrappedMethod();

  // At this point all ten stock category controllers exist. Reapply the mode that
  // OnInitialize selected: normal hub access starts in Biology, an actual ripperdoc
  // starts in Cyberware. This is presentation-only and does not alter item authority.
  this.CRPromoteBiologyOverlay();
  this.CRApplyBiologyShellMode(this.crBiologyShellMode);
  this.CRSyncBiologyNodeInteractivity(this.crBiologyShellMode);
  this.CRRefreshBiologyActions();
}
