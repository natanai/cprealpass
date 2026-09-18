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

// T002 plus the attended 2.31 INK probe proved the inventory controller root is only
// a zero-margin Fill lifecycle container. m_virtualGridContainer is nested below an
// additional native parent. Its layout values are therefore LOCAL to that parent.
// Copying those values onto a widget mounted directly under the controller root loses
// the authored ancestor transform and reproduces the extreme top-left failure.
//
// Vanilla redscript does not expose inkWidget.GetParentWidget(). Walk DOWN from the
// known inventory root instead, find the compound that directly owns the native virtual
// grid, and mount Biology beside it. Only then is copying the native child's local
// geometry valid.
@addMethod(RipperdocInventoryController)
private final func CRFindBiologyDetailRegionParent(parent: ref<inkCompoundWidget>, nativeRegion: ref<inkWidget>) -> ref<inkCompoundWidget> {
  if !IsDefined(parent) || !IsDefined(nativeRegion) {
    return null;
  }

  let i: Int32 = 0;
  while i < parent.GetNumChildren() {
    let child: wref<inkWidget> = parent.GetWidgetByIndex(i);
    if IsDefined(child) {
      if child == nativeRegion {
        return parent;
      }

      let childCompound: ref<inkCompoundWidget> = child as inkCompoundWidget;
      if IsDefined(childCompound) {
        let found: ref<inkCompoundWidget> = this.CRFindBiologyDetailRegionParent(childCompound, nativeRegion);
        if IsDefined(found) {
          return found;
        }
      }
    }
    i += 1;
  }
  return null;
}

@addMethod(RipperdocInventoryController)
public final func CRMountBiologyDetailInNativeRegion(target: ref<inkWidget>) -> Bool {
  if !IsDefined(target) {
    return false;
  }

  let nativeRegion: ref<inkWidget> = inkVirtualCompoundRef.Get(this.m_virtualGridContainer);
  let inventoryRoot: ref<inkCompoundWidget> = this.GetRootWidget() as inkCompoundWidget;
  if !IsDefined(nativeRegion) || !IsDefined(inventoryRoot) {
    return false;
  }

  let nativeParent: ref<inkCompoundWidget> = this.CRFindBiologyDetailRegionParent(inventoryRoot, nativeRegion);
  if !IsDefined(nativeParent) {
    return false;
  }

  target.Reparent(nativeParent, -1);
  target.SetAnchor(nativeRegion.GetAnchor());
  target.SetAnchorPoint(nativeRegion.GetAnchorPoint());
  target.SetHAlign(nativeRegion.GetHAlign());
  target.SetVAlign(nativeRegion.GetVAlign());
  target.SetMargin(nativeRegion.GetMargin());
  target.SetPadding(nativeRegion.GetPadding());
  target.SetSizeRule(nativeRegion.GetSizeRule());
  target.SetSizeCoefficient(nativeRegion.GetSizeCoefficient());
  target.SetSize(nativeRegion.GetSize());
  target.SetTranslation(nativeRegion.GetTranslation());
  return true;
}

@addMethod(RipperDocGameController)
private final func CRBiologyNativeDetailReady() -> Bool {
  // SpawnMinigrids is asynchronous. Stock Cyberware does not finish its native
  // category layout until all ten minigrids exist and InitializeEquipmentMinigrids
  // has run from the tenth OnMinigridSpawned callback.
  return ArraySize(this.m_equipmentMinigrids) >= 10
    && IsDefined(this.m_animationController)
    && IsDefined(this.m_inventoryView)
    && IsDefined(this.m_selector);
}

// DollHover is a native Cyberware seam already used by the existing Biology path.
// When Biology has just committed a selected area, force the native hover/animation
// markers back to an overview baseline before stock DollHover evaluates its early-
// return conditions. This makes the chosen crBiologySelectedArea the focus target on
// the first Biology session as well as after repeated Back/reopen cycles.
//
// Biology Back clears crBiologySelectedArea and then calls DollHover(Invalid). Detect
// that existing native boundary to close the reused content surface; no second Back
// stack or Biology-only navigation convention is introduced.
@wrapMethod(RipperDocGameController)
private func DollHover(area: gamedataEquipmentArea) -> Void {
  let inventoryView: wref<RipperdocInventoryController> = this.m_inventoryView;
  let enteringBiologyDetail: Bool = this.crBiologyShellMode
    && NotEquals(this.crBiologySelectedArea, gamedataEquipmentArea.Invalid)
    && Equals(area, this.crBiologySelectedArea)
    && Equals(this.m_filterMode, RipperdocModes.Item)
    && (!IsDefined(inventoryView) || !inventoryView.CRBiologyDetailSurfaceActive());
  let closingBiologyDetail: Bool = this.crBiologyShellMode
    && Equals(area, gamedataEquipmentArea.Invalid)
    && Equals(this.crBiologySelectedArea, gamedataEquipmentArea.Invalid)
    && IsDefined(inventoryView)
    && inventoryView.CRBiologyDetailSurfaceActive();

  if enteringBiologyDetail {
    this.m_hoverArea = gamedataEquipmentArea.Invalid;
    this.m_dollHoverArea = gamedataEquipmentArea.Invalid;
    this.m_dollSelected = false;
    if IsDefined(this.m_animationController) {
      this.m_animationController.SetOutside();
    }
  }

  wrappedMethod(area);

  if closingBiologyDetail {
    inventoryView.CRSetBiologyDetailSurface(false);
    this.DisplayInventory(false);
    this.CRSyncBiologyNodeInteractivity(this.crBiologyShellMode && this.CRBiologyNativeDetailReady());
    this.CRSyncBiologyContentVisibility();
  }
}

// Stock Cyberware opens its content/detail controller through DisplayInventory(true)
// immediately after DollSelect(true). Biology previously copied only the native depth
// booleans, which left RipperdocInventoryController hidden. Reuse the same transition
// here after the stock selection animation accepts Biology's already-committed area,
// then suppress only Cyberware's item-list chrome. The existing Biology method that
// called DollSelect continues immediately afterward and performs the selected-system
// detail/action binding against crBiologySelectedArea.
@wrapMethod(RipperDocGameController)
private func DollSelect(select: Bool) -> Void {
  wrappedMethod(select);

  if !select
    || !this.crBiologyShellMode
    || Equals(this.crBiologySelectedArea, gamedataEquipmentArea.Invalid)
    || !Equals(this.m_filterMode, RipperdocModes.Item) {
    return;
  }

  this.DisplayInventory(true);
  if IsDefined(this.m_inventoryView) {
    this.m_inventoryView.CRSetBiologyDetailSurface(true);
  }
  this.AnimateMinigrids();
}

// Keep first-open Biology labels non-actionable until stock Cyberware has completed
// its asynchronous minigrid initialization. Native OnMinigridSpawned remains the
// lifecycle authority; this wrapper only synchronizes Biology label interactivity.
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
