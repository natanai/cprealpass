// Keep contextual action/node interactivity synchronized with the shared
// Biology/Cyberware mode controls without giving this layer simulation authority.
module CyberpunkRealism.Presentation

import CyberpunkRealism.Settings.*

@addField(CyberwareInventoryMiniGrid)
private let crBiologyStockLabelCallbacksSuspended: Bool;

@addMethod(CyberwareInventoryMiniGrid)
public final func CRSetBiologyLabelInteractive(active: Bool) -> Void {
  if !CRRealpassSettings.IsEnabled(GetGameInstance()) {
    active = false;
  }
  inkTextRef.SetInteractive(this.m_label, active);
  // The stock label callback opens cyberware-category tooltips. While this same label
  // is serving as a Biology body node, suspend only those two callbacks; restore them
  // exactly once when Cyberware mode returns.
  if active && !this.crBiologyStockLabelCallbacksSuspended {
    inkTextRef.UnregisterFromCallback(this.m_label, n"OnHoverOver", this, n"OnHoverOverCategoryLabel");
    inkTextRef.UnregisterFromCallback(this.m_label, n"OnHoverOut", this, n"OnHoverOutCategoryLabel");
    this.crBiologyStockLabelCallbacksSuspended = true;
  } else {
    if !active && this.crBiologyStockLabelCallbacksSuspended {
      inkTextRef.RegisterToCallback(this.m_label, n"OnHoverOver", this, n"OnHoverOverCategoryLabel");
      inkTextRef.RegisterToCallback(this.m_label, n"OnHoverOut", this, n"OnHoverOutCategoryLabel");
      this.crBiologyStockLabelCallbacksSuspended = false;
    }
  }
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
private final func CRSyncSpawnedBiologyNode(widget: ref<inkWidget>) -> Void {
  if !CRRealpassSettings.IsEnabled(GetGameInstance()) || !IsDefined(widget) {
    return;
  }
  let minigrid: ref<CyberwareInventoryMiniGrid> = widget.GetController() as CyberwareInventoryMiniGrid;
  if !IsDefined(minigrid) {
    return;
  }

  // Stock SpawnMinigrids is asynchronous. OnInitialize can therefore enter Biology
  // before m_equipmentMinigrids contains these controllers. Apply the already chosen
  // shell mode at the actual native creation boundary so healthy modeled nodes do
  // not disappear merely because they arrived one frame later.
  minigrid.CRSetBiologyMode(this.crBiologyShellMode);
  minigrid.CRSetBiologyLabelInteractive(this.crBiologyShellMode && CRBiologyDetailPresentation.Supported(minigrid.CRBiologyArea()));
}

@wrapMethod(RipperDocGameController)
protected cb func OnMinigridSpawned(widget: ref<inkWidget>, userData: ref<IScriptable>) -> Bool {
  let result: Bool = wrappedMethod(widget, userData);
  this.CRSyncSpawnedBiologyNode(widget);
  return result;
}

@addMethod(RipperDocGameController)
protected cb func OnCRBioModeActionSync(evt: ref<inkPointerEvent>) -> Bool {
  if !CRRealpassSettings.IsEnabled(GetGameInstance()) || !IsDefined(evt) || !evt.IsAction(n"click") {
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
  if !CRRealpassSettings.IsEnabled(GetGameInstance()) {
    return result;
  }

  // The attended build placed this shell control at y=92, directly in the stock top
  // navigation band. Keep it within the shared body screen but below that native
  // navigation layer; final pixel acceptance remains an attended resolution/UI-scale
  // check rather than a claim made from static source.
  if IsDefined(this.crBiologyModeBar) {
    this.crBiologyModeBar.SetMargin(inkMargin(0.0, 154.0, 0.0, 0.0));
  }
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
