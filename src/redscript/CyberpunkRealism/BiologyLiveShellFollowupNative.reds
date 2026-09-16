// W02.2 live follow-up for first-open Biology detail state.
//
// This adapter does not create a second body/detail state machine. It closes the
// remaining lifecycle gap between Biology's selected-system identity and the stock
// Ripperdoc shell that already owns category initialization, doll focus, content
// visibility, and overview/detail depth.
module CyberpunkRealism.Presentation

import CyberpunkRealism.Settings.*

@addField(RipperdocInventoryController)
private let crBiologyDetailSurfaceActive: Bool;

// Biology reuses the native Ripperdoc inventory/detail surface, but its detail view
// must not expose the Cyberware item grid underneath Biology telemetry/actions.
// Keep the stock controller/root authoritative and suppress only its item-list chrome
// while Biology detail is active. Returning to overview restores the stock surface so
// Cyberware can use it unchanged.
@addMethod(RipperdocInventoryController)
public final func CRSetBiologyDetailSurface(active: Bool) -> Void {
  this.crBiologyDetailSurfaceActive = active;
  let virtualGrid: ref<inkWidget> = inkVirtualCompoundRef.Get(this.m_virtualGridContainer);
  if IsDefined(virtualGrid) {
    virtualGrid.SetVisible(!active);
  }
  inkWidgetRef.SetVisible(this.m_scrollBarContainer, !active);
  inkTextRef.SetVisible(this.m_labelPrefix, !active);
  inkTextRef.SetVisible(this.m_labelSuffix, !active);
}

@addMethod(RipperdocInventoryController)
public final func CRBiologyDetailSurfaceActive() -> Bool {
  return this.crBiologyDetailSurfaceActive;
}

@addMethod(RipperDocGameController)
private final func CRBiologyNativeDetailReady() -> Bool {
  // SpawnMinigrids is asynchronous. Stock Cyberware does not finish its native
  // category layout until all ten minigrids exist and InitializeEquipmentMinigrids
  // has run from the tenth OnMinigridSpawned callback. Entering Biology detail before
  // that boundary is what allowed a first-open click to inherit an uninitialized /
  // stale anatomy target.
  return ArraySize(this.m_equipmentMinigrids) >= 10
    && IsDefined(this.m_animationController)
    && IsDefined(this.m_inventoryView)
    && IsDefined(this.m_selector);
}

@addMethod(RipperDocGameController)
private final func CRNormalizeBiologyNativeSelectionForEntry() -> Void {
  // Treat every Biology overview -> detail transition as a fresh native selection.
  // The selected Biology area remains crBiologySelectedArea; these are only stock
  // Cyberware shell markers that can otherwise survive a first-instance/previous
  // animation state and cause DollHover/DollSelect to reuse the wrong focus target.
  this.m_hoverArea = gamedataEquipmentArea.Invalid;
  this.m_dollHoverArea = gamedataEquipmentArea.Invalid;
  this.m_dollSelected = false;
  if IsDefined(this.m_animationController) {
    this.m_animationController.SetOutside();
  }
}

// Gate the existing Biology select event on the same asynchronous native-shell
// readiness that stock Cyberware receives before its complete category layout exists.
// The wrapped handler remains the single selected-system propagation path.
@wrapMethod(RipperDocGameController)
protected cb func OnCRBiologyAreaSelectEvent(evt: ref<CRBiologyAreaSelectEvent>) -> Bool {
  if this.crBiologyShellMode && !this.CRBiologyNativeDetailReady() {
    return false;
  }

  if this.crBiologyShellMode && !this.CRBodyShellInDetail() {
    this.CRNormalizeBiologyNativeSelectionForEntry();
  }

  let result: Bool = wrappedMethod(evt);
  if !result || !this.CRBiologyInDetail() {
    return result;
  }

  // Native Cyberware uses DisplayInventory(true) as part of the actual detail-depth
  // transition. Biology previously copied only its booleans, leaving the native
  // content controller opacity at the overview/hidden state. Reuse the transition,
  // then suppress only Cyberware's item-list chrome.
  this.DisplayInventory(true);
  if IsDefined(this.m_inventoryView) {
    this.m_inventoryView.CRSetBiologyDetailSurface(true);
  }
  this.AnimateMinigrids();

  // The selected-system identity was already committed by the wrapped Biology path.
  // Refresh after the native surface is open so supplied authoritative metrics/actions
  // bind into a visible native content region on the very first Biology session.
  this.CRRefreshBiologyDetail();
  this.CRRefreshBiologyActions();
  this.CRSyncBiologyContentVisibility();
  return true;
}

// Biology Back already resets its own selected-system state and then calls the native
// DollHover(Invalid) zoom-out path. Detect that exact native boundary while the
// Biology detail surface is active and complete the content-depth inverse there. This
// avoids a second Back stack and is independent of wrapper ordering around OnBack.
@wrapMethod(RipperDocGameController)
private func DollHover(area: gamedataEquipmentArea) -> Void {
  let closeBiologyDetail: Bool = this.crBiologyShellMode
    && Equals(area, gamedataEquipmentArea.Invalid)
    && IsDefined(this.m_inventoryView)
    && this.m_inventoryView.CRBiologyDetailSurfaceActive();

  wrappedMethod(area);

  if closeBiologyDetail {
    this.m_inventoryView.CRSetBiologyDetailSurface(false);
    this.DisplayInventory(false);
    this.CRSyncBiologyNodeInteractivity(this.crBiologyShellMode && this.CRBiologyNativeDetailReady());
    this.CRSyncBiologyContentVisibility();
  }
}

// Keep the first-open Biology labels non-actionable until stock Cyberware has really
// completed its asynchronous minigrid initialization. The select-event guard above
// remains authoritative even if wrapper ordering briefly exposes an early label.
@wrapMethod(RipperDocGameController)
protected cb func OnMinigridSpawned(widget: ref<inkWidget>, userData: ref<IScriptable>) -> Bool {
  let result: Bool = wrappedMethod(widget, userData);
  if CRRealpassSettings.IsEnabled(GetGameInstance()) && this.crBiologyShellMode {
    this.CRSyncBiologyNodeInteractivity(this.CRBiologyNativeDetailReady());
  }
  return result;
}

@wrapMethod(RipperDocGameController)
protected cb func OnInitialize() -> Bool {
  let result: Bool = wrappedMethod();
  if CRRealpassSettings.IsEnabled(GetGameInstance()) && this.crBiologyShellMode {
    this.CRSyncBiologyNodeInteractivity(this.CRBiologyNativeDetailReady());
  }
  return result;
}
