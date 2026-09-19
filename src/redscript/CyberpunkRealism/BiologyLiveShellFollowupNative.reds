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

@addField(RipperdocInventoryController)
private let crBiologyContentHostVisibilityCaptured: Bool;

@addField(RipperdocInventoryController)
private let crBiologyContentHostWasVisible: Bool;

@addField(RipperdocInventoryController)
private let crBiologyCyberwareContentHost: wref<inkWidget>;

@addField(RipperdocInventoryController)
private let crBiologyDetailMountStatus: String;

@addField(RipperdocInventoryController)
private let crBiologyDetailNativeParent: wref<inkCompoundWidget>;

@addField(RipperdocInventoryController)
private let crBiologyDetailNativeRegion: wref<inkWidget>;

// Current CP2077 2.31 resource archaeology proves the stock inventory subtree is:
//
// Inventory (RipperdocInventoryController root)
// -> cyberwareContainer
// -> GridAndSlider -> grid -> scrollRect -> virtualGridContainer
//
// Biology must not live inside that scrolling item-grid subtree. Keep Inventory as the
// native selected-detail lifecycle/opacity authority, but hide the authored
// cyberwareContainer as one stock content unit while Biology occupies a sibling panel
// under the same Inventory root. Restore the container's exact prior visibility on exit.
@addMethod(RipperdocInventoryController)
public final func CRSetBiologyDetailSurface(active: Bool) -> Void {
  this.crBiologyDetailSurfaceActive = active;

  let inventoryRoot: ref<inkCompoundWidget> = this.GetRootWidget() as inkCompoundWidget;
  let contentHost: ref<inkWidget> = this.crBiologyCyberwareContentHost;
  if !IsDefined(contentHost) && IsDefined(inventoryRoot) {
    contentHost = this.CRFindBiologyAuthoredContentHost(inventoryRoot);
    if IsDefined(contentHost) {
      this.crBiologyCyberwareContentHost = contentHost;
    }
  }

  if !IsDefined(contentHost) || !IsDefined(contentHost as inkVerticalPanel) {
    return;
  }

  if active {
    if !this.crBiologyContentHostVisibilityCaptured {
      this.crBiologyContentHostWasVisible = contentHost.IsVisible();
      this.crBiologyContentHostVisibilityCaptured = true;
    }
    contentHost.SetVisible(false);
  } else {
    if this.crBiologyContentHostVisibilityCaptured {
      contentHost.SetVisible(this.crBiologyContentHostWasVisible);
      this.crBiologyContentHostVisibilityCaptured = false;
    }
  }
}

@addMethod(RipperdocInventoryController)
public final func CRBiologyDetailSurfaceActive() -> Bool {
  return this.crBiologyDetailSurfaceActive;
}

// P02's current-2.31 serialized INK evidence closes the old W02.4/W02.6 host
// uncertainty. cyberwareContainer is the direct authored child of the Inventory root,
// while GridAndSlider -> grid -> scrollRect -> virtualGridContainer is only its internal
// Cyberware item-list implementation. Resolve that exact direct child by authored name;
// fail closed if a future game patch changes the contract rather than falling back to
// screen coordinates or a convenient descendant.
@addMethod(RipperdocInventoryController)
private final func CRFindBiologyAuthoredContentHost(inventoryRoot: ref<inkCompoundWidget>) -> ref<inkWidget> {
  if !IsDefined(inventoryRoot) {
    return null;
  }

  let i: Int32 = 0;
  while i < inventoryRoot.GetNumChildren() {
    let child: wref<inkWidget> = inventoryRoot.GetWidgetByIndex(i);
    if IsDefined(child) && Equals(child.GetName(), n"cyberwareContainer") {
      return child;
    }
    i += 1;
  }
  return null;
}

@addMethod(RipperdocInventoryController)
private final func CRBiologyDirectParentOwnsWidget(parent: ref<inkCompoundWidget>, target: ref<inkWidget>) -> Bool {
  if !IsDefined(parent) || !IsDefined(target) {
    return false;
  }

  let i: Int32 = 0;
  while i < parent.GetNumChildren() {
    let child: wref<inkWidget> = parent.GetWidgetByIndex(i);
    if IsDefined(child) && child == target {
      return true;
    }
    i += 1;
  }
  return false;
}

@addMethod(RipperdocInventoryController)
public final func CRBiologyDetailMountStatus() -> String {
  return this.crBiologyDetailMountStatus;
}

@addMethod(RipperdocInventoryController)
private final func CRBiologyChildIndex(parent: ref<inkCompoundWidget>, target: ref<inkWidget>) -> Int32 {
  if !IsDefined(parent) || !IsDefined(target) {
    return -1;
  }

  let i: Int32 = 0;
  while i < parent.GetNumChildren() {
    let child: wref<inkWidget> = parent.GetWidgetByIndex(i);
    if IsDefined(child) && child == target {
      return i;
    }
    i += 1;
  }
  return -1;
}

@addMethod(RipperdocInventoryController)
public final func CRBiologyDetailPostMountStatus(target: ref<inkWidget>) -> String {
  if !IsDefined(target) {
    return this.crBiologyDetailMountStatus + " T?";
  }

  let inventoryRoot: ref<inkWidget> = this.GetRootWidget();
  let nativeRegion: ref<inkWidget> = this.crBiologyDetailNativeRegion;
  let nativeParent: ref<inkCompoundWidget> = this.crBiologyDetailNativeParent;
  if !IsDefined(nativeParent) {
    nativeParent = inventoryRoot as inkCompoundWidget;
  }
  if !IsDefined(nativeRegion) && IsDefined(nativeParent) {
    nativeRegion = this.CRFindBiologyAuthoredContentHost(nativeParent);
  }

  let result: String = this.crBiologyDetailMountStatus;
  if IsDefined(inventoryRoot) {
    result += " R" + FloatToStringPrec(inventoryRoot.GetOpacity(), 1);
  } else {
    result += " R?";
  }

  if target.IsVisible() {
    result += " T1/";
  } else {
    result += " T0/";
  }
  result += FloatToStringPrec(target.GetOpacity(), 1);

  let stored: Vector2 = target.GetSize();
  let desired: Vector2 = target.GetDesiredSize();
  result += " S" + FloatToStringPrec(stored.X, 0) + "x" + FloatToStringPrec(stored.Y, 0);
  result += " D" + FloatToStringPrec(desired.X, 0) + "x" + FloatToStringPrec(desired.Y, 0);
  result += " K" + FloatToStringPrec(target.GetSizeCoefficient(), 1);
  if Equals(target.GetSizeRule(), inkESizeRule.Stretch) {
    result += " QS";
  } else {
    result += " QF";
  }

  let targetCompound: ref<inkCompoundWidget> = target as inkCompoundWidget;
  if IsDefined(targetCompound) {
    result += " N" + IntToString(targetCompound.GetNumChildren());
  } else {
    result += " N?";
  }

  if IsDefined(nativeParent) && IsDefined(nativeRegion) {
    let childSize: Vector2 = nativeParent.GetChildSize(target);
    let childPosition: Vector2 = nativeParent.GetChildPosition(target);
    let parentDesired: Vector2 = nativeParent.GetDesiredSize();
    let targetIndex: Int32 = this.CRBiologyChildIndex(nativeParent, target);
    let nativeIndex: Int32 = this.CRBiologyChildIndex(nativeParent, nativeRegion);

    result += " C" + FloatToStringPrec(childSize.X, 0) + "x" + FloatToStringPrec(childSize.Y, 0);
    result += " P" + FloatToStringPrec(parentDesired.X, 0) + "x" + FloatToStringPrec(parentDesired.Y, 0);
    result += " X" + FloatToStringPrec(childPosition.X, 0) + "," + FloatToStringPrec(childPosition.Y, 0);
    result += " I" + IntToString(targetIndex) + "/" + IntToString(nativeIndex);
    if Equals(nativeParent.GetChildOrder(), inkEChildOrder.Backward) {
      result += "B";
    } else {
      result += "F";
    }

    let targetMargin: inkMargin = target.GetMargin();
    let nativeMargin: inkMargin = nativeRegion.GetMargin();
    let targetAnchorPoint: Vector2 = target.GetAnchorPoint();
    let nativeAnchorPoint: Vector2 = nativeRegion.GetAnchorPoint();
    let targetTranslation: Vector2 = target.GetTranslation();
    let nativeTranslation: Vector2 = nativeRegion.GetTranslation();
    let layoutMatch: Bool = Equals(target.GetAnchor(), nativeRegion.GetAnchor())
      && targetAnchorPoint.X == nativeAnchorPoint.X
      && targetAnchorPoint.Y == nativeAnchorPoint.Y
      && Equals(target.GetHAlign(), nativeRegion.GetHAlign())
      && Equals(target.GetVAlign(), nativeRegion.GetVAlign())
      && targetMargin.left == nativeMargin.left
      && targetMargin.top == nativeMargin.top
      && targetMargin.right == nativeMargin.right
      && targetMargin.bottom == nativeMargin.bottom
      && targetTranslation.X == nativeTranslation.X
      && targetTranslation.Y == nativeTranslation.Y;
    if layoutMatch {
      result += " L1";
    } else {
      result += " L0";
    }
  } else {
    result += " P?";
  }
  return result;
}

@addMethod(RipperdocInventoryController)
public final func CRMountBiologyDetailInAuthoredContentHost(target: ref<inkWidget>) -> Bool {
  if !IsDefined(target) {
    this.crBiologyDetailMountStatus = "TARGET_MISSING";
    return false;
  }

  let inventoryRoot: ref<inkCompoundWidget> = this.GetRootWidget() as inkCompoundWidget;
  if !IsDefined(inventoryRoot) {
    this.crBiologyDetailMountStatus = "ROOT_MISSING";
    return false;
  }

  let contentHost: ref<inkWidget> = this.CRFindBiologyAuthoredContentHost(inventoryRoot);
  if !IsDefined(contentHost) {
    this.crBiologyDetailMountStatus = "CONTENT_HOST_MISSING";
    return false;
  }

  // The serialized 2.31 resource identifies cyberwareContainer as an
  // inkVerticalPanelWidget. Biology is intentionally the same layout family so we can
  // borrow the authored selected-content placement without inheriting scroll/grid
  // virtualization semantics.
  let contentPanel: ref<inkVerticalPanel> = contentHost as inkVerticalPanel;
  if !IsDefined(contentPanel) {
    this.crBiologyDetailMountStatus = "CONTENT_HOST_TYPE_MISMATCH";
    return false;
  }

  target.Reparent(inventoryRoot, -1);
  if !this.CRBiologyDirectParentOwnsWidget(inventoryRoot, target) {
    this.crBiologyDetailMountStatus = "REPARENT_UNCONFIRMED";
    return false;
  }

  this.crBiologyCyberwareContentHost = contentHost;
  this.crBiologyDetailNativeParent = inventoryRoot;
  this.crBiologyDetailNativeRegion = contentHost;

  // Copy only the authored container's placement contract. Biology owns the extent of
  // its actual title/summary/metrics/actions, so content sizing remains fit-to-content.
  // No screen-space offsets are reconstructed here.
  target.SetAnchor(contentHost.GetAnchor());
  target.SetAnchorPoint(contentHost.GetAnchorPoint());
  target.SetHAlign(contentHost.GetHAlign());
  target.SetVAlign(contentHost.GetVAlign());
  target.SetMargin(contentHost.GetMargin());
  target.SetPadding(contentHost.GetPadding());
  target.SetTranslation(contentHost.GetTranslation());
  target.SetFitToContent(true);
  target.SetOpacity(1.0);
  target.SetAffectsLayoutWhenHidden(true);
  this.crBiologyDetailMountStatus = "CONTENT_HOST_MOUNTED";
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
