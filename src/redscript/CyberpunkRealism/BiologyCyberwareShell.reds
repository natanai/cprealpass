// Shared Biology/Cyberware body shell.
//
// The stock cyberware_equip fullscreen remains the technical screen. Biology reuses
// its body silhouette, category controllers, selection/zoom state, selector strip,
// back stack and content anchor instead of maintaining a parallel drill-down state.
module CyberpunkRealism.Presentation

import CyberpunkRealism.Integration.*
import CyberpunkRealism.Physiology.*
import CyberpunkRealism.Settings.*

public class CRBiologyAreaSelectEvent extends Event {
  public let area: gamedataEquipmentArea;
}

public class CRBiologyAreaHoverEvent extends Event {
  public let area: gamedataEquipmentArea;
}

public class CRBiologyAreaHoverOutEvent extends Event {}

// Keep the exact native Cyberware menu identifier/fullscreen route. Only its visible
// hub label changes while Biology is enabled; master-off restores stock Cyberware.
@wrapMethod(MenuHubLogicController)
public final func SetMenusData(menuData: ref<MenuDataBuilder>, perkPoints: Int32, attrPoints: Int32) -> Void {
  wrappedMethod(menuData, perkPoints, attrPoints);
  if !CRRealpassSettings.IsEnabled(GetGameInstance()) {
    return;
  }
  let biologyData: MenuData = menuData.GetData(EnumInt(HubMenuItems.Cyberware));
  biologyData.label = "BIOLOGY";
  HubMenuUtils.SetMenuData(this.m_btnCyberware, biologyData);
}

// -----------------------------------------------------------------------------
// Native Cyberware category controllers become Biology overview nodes. Their stock
// equipment grids are hidden in Biology mode, but the controllers/anchors themselves
// remain the interaction surface and are restored unchanged for Cyberware mode.
// -----------------------------------------------------------------------------

@addField(CyberwareInventoryMiniGrid)
private let crBiologyMode: Bool;

@addField(CyberwareInventoryMiniGrid)
private let crBiologyCallbacksInstalled: Bool;

@addMethod(CyberwareInventoryMiniGrid)
public final func CRBiologyArea() -> gamedataEquipmentArea {
  return this.m_equipArea;
}

@addMethod(CyberwareInventoryMiniGrid)
private final func CRInstallBiologyCallbacks() -> Void {
  if !CRRealpassSettings.IsEnabled(GetGameInstance()) || this.crBiologyCallbacksInstalled {
    return;
  }
  inkTextRef.RegisterToCallback(this.m_label, n"OnRelease", this, n"OnCRBiologyRelease");
  inkTextRef.RegisterToCallback(this.m_label, n"OnHoverOver", this, n"OnCRBiologyHoverOver");
  inkTextRef.RegisterToCallback(this.m_label, n"OnHoverOut", this, n"OnCRBiologyHoverOut");
  this.crBiologyCallbacksInstalled = true;
}

@addMethod(CyberwareInventoryMiniGrid)
public final func CRSetBiologyMode(active: Bool) -> Void {
  if !CRRealpassSettings.IsEnabled(GetGameInstance()) {
    this.crBiologyMode = false;
    this.GetRootWidget().SetVisible(true);
    inkWidgetRef.SetVisible(this.m_gridContainer, true);
    inkWidgetRef.SetVisible(this.m_isNew, true);
    this.UpdateTitle(this.GetAreaHeader(this.m_equipArea));
    return;
  }

  this.CRInstallBiologyCallbacks();
  let area: gamedataEquipmentArea = this.m_equipArea;
  let supported: Bool = CRBiologyDetailPresentation.Supported(area);
  this.crBiologyMode = active && supported;

  if active {
    this.GetRootWidget().SetVisible(supported);
    if supported {
      inkWidgetRef.SetVisible(this.m_gridContainer, false);
      inkWidgetRef.SetVisible(this.m_isNew, false);
      inkTextRef.SetText(this.m_label, CRBiologyDetailPresentation.Label(area));
    }
  } else {
    this.GetRootWidget().SetVisible(true);
    inkWidgetRef.SetVisible(this.m_gridContainer, true);
    inkWidgetRef.SetVisible(this.m_isNew, true);
    this.UpdateTitle(this.GetAreaHeader(area));
  }
}

@addMethod(CyberwareInventoryMiniGrid)
public final func CRSetBiologyOverviewNodeVisible(visible: Bool) -> Void {
  if !this.crBiologyMode {
    return;
  }
  this.GetRootWidget().SetVisible(visible && CRBiologyDetailPresentation.Supported(this.m_equipArea));
}

@addMethod(CyberwareInventoryMiniGrid)
protected cb func OnCRBiologyRelease(evt: ref<inkPointerEvent>) -> Bool {
  if !this.crBiologyMode || !IsDefined(evt) || !evt.IsAction(n"click") || evt.IsHandled() {
    return false;
  }
  let request: ref<CRBiologyAreaSelectEvent> = new CRBiologyAreaSelectEvent();
  request.area = this.m_equipArea;
  this.QueueEvent(request);
  evt.Handle();
  return true;
}

@addMethod(CyberwareInventoryMiniGrid)
protected cb func OnCRBiologyHoverOver(evt: ref<inkPointerEvent>) -> Bool {
  if !this.crBiologyMode || !IsDefined(evt) {
    return false;
  }
  let request: ref<CRBiologyAreaHoverEvent> = new CRBiologyAreaHoverEvent();
  request.area = this.m_equipArea;
  this.QueueEvent(request);
  return true;
}

@addMethod(CyberwareInventoryMiniGrid)
protected cb func OnCRBiologyHoverOut(evt: ref<inkPointerEvent>) -> Bool {
  if !this.crBiologyMode || !IsDefined(evt) {
    return false;
  }
  this.QueueEvent(new CRBiologyAreaHoverOutEvent());
  return true;
}

// -----------------------------------------------------------------------------
// Shared stock body/anatomy fullscreen.
// -----------------------------------------------------------------------------

@addField(RipperDocGameController)
private let crBiologyShellMode: Bool;

@addField(RipperDocGameController)
private let crBiologyModeBar: ref<inkHorizontalPanel>;

@addField(RipperDocGameController)
private let crBiologyModeButton: ref<inkText>;

@addField(RipperDocGameController)
private let crCyberwareModeButton: ref<inkText>;

@addField(RipperDocGameController)
private let crBiologyOverview: ref<inkVerticalPanel>;

@addField(RipperDocGameController)
private let crBiologyOverviewText: ref<inkText>;

// Biology detail stays under the stock RipperdocInventoryController lifecycle root,
// but current-2.31 archaeology no longer mounts it inside the Cyberware scroll/grid.
// It becomes a sibling of the authored cyberwareContainer and derives placement from
// that same-type native vertical panel.
@addField(RipperDocGameController)
private let crBiologyNativeContent: ref<inkVerticalPanel>;

@addField(RipperDocGameController)
private let crBiologyDetailTitle: ref<inkText>;

@addField(RipperDocGameController)
private let crBiologyDetailSummary: ref<inkText>;

@addField(RipperDocGameController)
private let crBiologyDetailContentStatus: String;

@addField(RipperDocGameController)
private let crBiologyMetricRows: array<ref<inkCanvas>>;

@addField(RipperDocGameController)
private let crBiologyMetricLabels: array<ref<inkText>>;

@addField(RipperDocGameController)
private let crBiologyMetricBackgrounds: array<ref<inkRectangle>>;

@addField(RipperDocGameController)
private let crBiologyMetricFills: array<ref<inkRectangle>>;

@addField(RipperDocGameController)
private let crBiologyMetricValues: array<ref<inkText>>;

@addField(RipperDocGameController)
private let crBiologySelectedArea: gamedataEquipmentArea;

@addMethod(RipperDocGameController)
private final func CRShellText(text: String, name: CName, size: Int32) -> ref<inkText> {
  let widget: ref<inkText> = new inkText();
  widget.SetName(name);
  widget.SetText(text);
  widget.SetFontFamily("base\\gameplay\\gui\\fonts\\raj\\raj.inkfontfamily");
  widget.SetFontStyle(n"Medium");
  widget.SetFontSize(size);
  widget.SetFitToContent(true);
  return widget;
}

@addMethod(RipperDocGameController)
private final func CRShellWrappedText(text: String, name: CName, size: Int32, width: Float) -> ref<inkText> {
  let widget: ref<inkText> = this.CRShellText(text, name, size);
  widget.SetWrappingAtPosition(width);
  widget.SetSize(Vector2(width, 0.0));
  return widget;
}

@addMethod(RipperDocGameController)
private final func CRShellModeAction(text: String, name: CName) -> ref<inkText> {
  let widget: ref<inkText> = this.CRShellText(text, name, 28);
  widget.SetInteractive(true);
  widget.SetOpacity(0.96);
  return widget;
}

@addMethod(RipperDocGameController)
private final func CRCreateMetricRow(index: Int32) -> Void {
  let row: ref<inkCanvas> = new inkCanvas();
  row.SetName(StringToName("CRBiologyMetricRow" + ToString(index + 1)));
  row.SetSize(Vector2(680.0, 40.0));

  let label: ref<inkText> = this.CRShellText("", StringToName("CRBiologyMetricLabel" + ToString(index + 1)), 18);
  label.SetFitToContent(false);
  label.SetSize(Vector2(240.0, 30.0));
  label.SetTranslation(0.0, 0.0);
  label.Reparent(row, -1);

  let background: ref<inkRectangle> = new inkRectangle();
  background.SetName(StringToName("CRBiologyMetricBG" + ToString(index + 1)));
  background.SetSize(Vector2(300.0, 10.0));
  background.SetTranslation(250.0, 10.0);
  background.SetOpacity(0.28);
  background.Reparent(row, -1);

  let fill: ref<inkRectangle> = new inkRectangle();
  fill.SetName(StringToName("CRBiologyMetricFill" + ToString(index + 1)));
  fill.SetSize(Vector2(0.0, 10.0));
  fill.SetTranslation(250.0, 10.0);
  fill.SetOpacity(0.90);
  fill.Reparent(row, -1);

  let value: ref<inkText> = this.CRShellText("", StringToName("CRBiologyMetricValue" + ToString(index + 1)), 18);
  value.SetTranslation(565.0, 0.0);
  value.Reparent(row, -1);

  row.Reparent(this.crBiologyNativeContent, -1);
  ArrayPush(this.crBiologyMetricRows, row);
  ArrayPush(this.crBiologyMetricLabels, label);
  ArrayPush(this.crBiologyMetricBackgrounds, background);
  ArrayPush(this.crBiologyMetricFills, fill);
  ArrayPush(this.crBiologyMetricValues, value);
}

@addMethod(RipperDocGameController)
private final func CRCreateBiologyShell() -> Void {
  if !CRRealpassSettings.IsEnabled(GetGameInstance()) || IsDefined(this.crBiologyModeBar) {
    return;
  }

  let root: ref<inkCompoundWidget> = this.GetRootCompoundWidget();
  if !IsDefined(root) {
    return;
  }

  // Overview-only internal mode control. It intentionally sits below the top hub and
  // is substantially more legible than the attended 20 px prototype.
  this.crBiologyModeBar = new inkHorizontalPanel();
  this.crBiologyModeBar.SetName(n"CRBiologyModeBar");
  this.crBiologyModeBar.SetAnchor(inkEAnchor.TopCenter);
  this.crBiologyModeBar.SetHAlign(inkEHorizontalAlign.Center);
  this.crBiologyModeBar.SetVAlign(inkEVerticalAlign.Top);
  this.crBiologyModeBar.SetMargin(inkMargin(0.0, 154.0, 0.0, 0.0));
  this.crBiologyModeBar.SetChildMargin(inkMargin(18.0, 0.0, 18.0, 0.0));
  this.crBiologyModeBar.Reparent(root, -1);

  this.crBiologyModeButton = this.CRShellModeAction("BIOLOGY", n"CRBiologyModeBiology");
  this.crBiologyModeButton.RegisterToCallback(n"OnRelease", this, n"OnCRBiologyModeToggle");
  this.crBiologyModeButton.Reparent(this.crBiologyModeBar, -1);

  let separator: ref<inkText> = this.CRShellText("|", n"CRBiologyModeSeparator", 25);
  separator.SetOpacity(0.52);
  separator.Reparent(this.crBiologyModeBar, -1);

  this.crCyberwareModeButton = this.CRShellModeAction("CYBERWARE", n"CRBiologyModeCyberware");
  this.crCyberwareModeButton.RegisterToCallback(n"OnRelease", this, n"OnCRBiologyModeToggle");
  this.crCyberwareModeButton.Reparent(this.crBiologyModeBar, -1);

  // The only overview-specific custom content is terse status telemetry. Anatomy
  // labels/selection remain the stock category controllers around the stock body.
  this.crBiologyOverview = new inkVerticalPanel();
  this.crBiologyOverview.SetName(n"CRBiologyOverview");
  this.crBiologyOverview.SetAnchor(inkEAnchor.BottomCenter);
  this.crBiologyOverview.SetHAlign(inkEHorizontalAlign.Center);
  this.crBiologyOverview.SetVAlign(inkEVerticalAlign.Bottom);
  this.crBiologyOverview.SetMargin(inkMargin(0.0, 0.0, 0.0, 62.0));
  this.crBiologyOverview.SetSize(Vector2(760.0, 0.0));
  this.crBiologyOverview.Reparent(root, -1);

  let overviewHeading: ref<inkText> = this.CRShellText("BODY", n"CRBiologyOverviewHeading", 21);
  overviewHeading.SetOpacity(0.72);
  overviewHeading.Reparent(this.crBiologyOverview, -1);
  this.crBiologyOverviewText = this.CRShellWrappedText("", n"CRBiologyOverviewText", 18, 760.0);
  this.crBiologyOverviewText.Reparent(this.crBiologyOverview, -1);

  // Create the Biology detail subtree independently of the first native mount attempt.
  // W02.4 discarded this panel when initialization-time native-region resolution failed;
  // detail-time fail-closed logic then had no panel left to retry. Retain the panel and
  // all runtime-bound children while hidden, and let every detail transition re-resolve
  // the current native host before making it visible.
  this.crBiologyNativeContent = new inkVerticalPanel();
  this.crBiologyNativeContent.SetName(n"CRBiologyNativeContent");
  this.crBiologyNativeContent.SetChildMargin(inkMargin(0.0, 4.0, 0.0, 4.0));
  this.crBiologyNativeContent.SetFitToContent(true);
  this.crBiologyNativeContent.SetVisible(false);
  this.crBiologyNativeContent.SetAffectsLayoutWhenHidden(true);

  // Best-effort early mount only. Failure here is not terminal; the panel remains
  // retained and CRSyncBiologyNativeContentLayout retries against the live native tree.
  if IsDefined(this.m_inventoryView) {
    this.m_inventoryView.CRMountBiologyDetailInAuthoredContentHost(this.crBiologyNativeContent);
  }

  if IsDefined(this.crBiologyNativeContent) {
    this.crBiologyDetailTitle = this.CRShellText("", n"CRBiologyDetailHeading", 30);
    this.crBiologyDetailTitle.SetMargin(inkMargin(0.0, 0.0, 0.0, 2.0));
    this.crBiologyDetailTitle.Reparent(this.crBiologyNativeContent, -1);
    this.crBiologyDetailSummary = this.CRShellWrappedText("", n"CRBiologyDetailSummary", 18, 680.0);
    this.crBiologyDetailSummary.SetMargin(inkMargin(0.0, 0.0, 0.0, 14.0));
    this.crBiologyDetailSummary.SetOpacity(0.80);
    this.crBiologyDetailSummary.Reparent(this.crBiologyNativeContent, -1);

    ArrayClear(this.crBiologyMetricRows);
    ArrayClear(this.crBiologyMetricLabels);
    ArrayClear(this.crBiologyMetricBackgrounds);
    ArrayClear(this.crBiologyMetricFills);
    ArrayClear(this.crBiologyMetricValues);
    let i: Int32 = 0;
    while i < 4 {
      this.CRCreateMetricRow(i);
      i += 1;
    }
  }
}

@addMethod(RipperDocGameController)
public final func CRBiologyInDetail() -> Bool {
  return this.crBiologyShellMode && NotEquals(this.crBiologySelectedArea, gamedataEquipmentArea.Invalid);
}

@addMethod(RipperDocGameController)
public final func CRBodyShellInDetail() -> Bool {
  return Equals(this.m_filterMode, RipperdocModes.Item)
    || this.m_isInventoryOpen
    || NotEquals(this.crBiologySelectedArea, gamedataEquipmentArea.Invalid);
}

@addMethod(RipperDocGameController)
private final func CRSetStockMetersVisible(visible: Bool) -> Void {
  let capacity: ref<RipperdocMetersCapacity> = this.GetControllerByType(n"RipperdocMetersCapacity") as RipperdocMetersCapacity;
  let armor: ref<RipperdocMetersArmor> = this.GetControllerByType(n"RipperdocMetersArmor") as RipperdocMetersArmor;
  if IsDefined(capacity) {
    capacity.GetRootWidget().SetVisible(visible);
  }
  if IsDefined(armor) {
    armor.GetRootWidget().SetVisible(visible);
  }
}

@addMethod(RipperDocGameController)
private final func CRSetCategoryMode(biology: Bool) -> Void {
  let i: Int32 = 0;
  while i < ArraySize(this.m_equipmentMinigrids) {
    if IsDefined(this.m_equipmentMinigrids[i]) {
      this.m_equipmentMinigrids[i].CRSetBiologyMode(biology);
    }
    i += 1;
  }
}

@addMethod(RipperDocGameController)
private final func CRSetBiologyOverviewNodesVisible(visible: Bool) -> Void {
  let i: Int32 = 0;
  while i < ArraySize(this.m_equipmentMinigrids) {
    if IsDefined(this.m_equipmentMinigrids[i]) {
      this.m_equipmentMinigrids[i].CRSetBiologyOverviewNodeVisible(visible);
    }
    i += 1;
  }
}

@addMethod(RipperDocGameController)
public final func CRMountBiologyActionsInNativeContent() -> Void {
  if !IsDefined(this.crBiologyNativeContent) || !IsDefined(this.crBioActionsPanel) {
    return;
  }
  this.crBioActionsPanel.SetAnchor(inkEAnchor.TopLeft);
  this.crBioActionsPanel.SetHAlign(inkEHorizontalAlign.Left);
  this.crBioActionsPanel.SetVAlign(inkEVerticalAlign.Top);
  this.crBioActionsPanel.SetMargin(inkMargin(0.0, 18.0, 0.0, 0.0));
  this.crBioActionsPanel.SetSize(Vector2(680.0, 0.0));
  this.crBioActionsPanel.Reparent(this.crBiologyNativeContent, -1);
}

@addMethod(RipperDocGameController)
private final func CRSelectBiologyConditionForArea(area: gamedataEquipmentArea) -> Void {
  if Equals(area, gamedataEquipmentArea.FrontalCortexCW) {
    this.crBioSelectedRegion = 1;
    return;
  }
  if Equals(area, gamedataEquipmentArea.ArmsCW) {
    let left: ref<CRConditionDescriptor> = CRConditionPresentation.Current(3);
    this.crBioSelectedRegion = IsDefined(left) && left.valid && left.hasCondition ? 3 : 4;
    return;
  }
  if Equals(area, gamedataEquipmentArea.LegsCW) {
    let left: ref<CRConditionDescriptor> = CRConditionPresentation.Current(5);
    this.crBioSelectedRegion = IsDefined(left) && left.valid && left.hasCondition ? 5 : 6;
    return;
  }
  if Equals(area, gamedataEquipmentArea.MusculoskeletalSystemCW) || Equals(area, gamedataEquipmentArea.IntegumentarySystemCW) {
    this.crBioSelectedRegion = this.CRBioFirstCondition();
    return;
  }
  this.crBioSelectedRegion = 0;
}

@addMethod(RipperDocGameController)
public final func CRConstrainBiologyActionsToSelectedArea() -> Void {
  if !IsDefined(this.crBioActionsPanel) {
    return;
  }
  if !this.CRBiologyInDetail() {
    this.crBioActionsPanel.SetVisible(false);
    return;
  }

  let area: gamedataEquipmentArea = this.crBiologySelectedArea;
  let metabolism: Bool = Equals(area, gamedataEquipmentArea.SystemReplacementCW);
  let careArea: Bool = Equals(area, gamedataEquipmentArea.FrontalCortexCW)
    || Equals(area, gamedataEquipmentArea.ArmsCW)
    || Equals(area, gamedataEquipmentArea.LegsCW)
    || Equals(area, gamedataEquipmentArea.MusculoskeletalSystemCW)
    || Equals(area, gamedataEquipmentArea.IntegumentarySystemCW);

  this.crBioActionsPanel.SetVisible(metabolism || careArea);
  if !metabolism {
    this.crBioEat.SetVisible(false);
    this.crBioDrink.SetVisible(false);
    this.CRBioHideItemRows();
  }
  if !careArea {
    this.crBioConditionsHeading.SetVisible(false);
    let j: Int32 = 0;
    while j < ArraySize(this.crBioConditionRows) {
      this.crBioConditionRows[j].SetVisible(false);
      j += 1;
    }
    this.crBioDress.SetVisible(false);
    this.crBioSupport.SetVisible(false);
    this.crBioClinical.SetVisible(false);
    this.crBioMechanical.SetVisible(false);
    return;
  }

  // Regional nodes show only conditions belonging to the selected anatomy. Global
  // skin/wounds and musculoskeletal nodes may legitimately summarize several regions.
  if Equals(area, gamedataEquipmentArea.FrontalCortexCW) {
    let i: Int32 = 1;
    while i < ArraySize(this.crBioConditionRows) {
      this.crBioConditionRows[i].SetVisible(false);
      i += 1;
    }
  } else {
    if Equals(area, gamedataEquipmentArea.ArmsCW) {
      this.crBioConditionRows[0].SetVisible(false);
      this.crBioConditionRows[1].SetVisible(false);
      this.crBioConditionRows[4].SetVisible(false);
      this.crBioConditionRows[5].SetVisible(false);
    } else {
      if Equals(area, gamedataEquipmentArea.LegsCW) {
        this.crBioConditionRows[0].SetVisible(false);
        this.crBioConditionRows[1].SetVisible(false);
        this.crBioConditionRows[2].SetVisible(false);
        this.crBioConditionRows[3].SetVisible(false);
      }
    }
  }
}

@addMethod(RipperDocGameController)
public final func CRSyncBiologyModeSwitcher() -> Void {
  if !IsDefined(this.crBiologyModeBar) {
    return;
  }
  // Match native Cyberware: the parent/submode switch exists at overview depth only.
  // Any native or Biology detail state must be backed out before changing modes.
  this.crBiologyModeBar.SetVisible(!this.CRBodyShellInDetail());
}

@addMethod(RipperDocGameController)
private final func CRSyncBiologyNativeContentLayout() -> Bool {
  // Re-resolve the authored Inventory -> cyberwareContainer seam at detail depth.
  // This deliberately fails closed if a future game patch changes that native contract.
  return IsDefined(this.m_inventoryView)
    && IsDefined(this.crBiologyNativeContent)
    && this.m_inventoryView.CRMountBiologyDetailInAuthoredContentHost(this.crBiologyNativeContent);
}

@addMethod(RipperDocGameController)
private final func CRBiologyDetailPostMountStatus(layoutReady: Bool) -> String {
  if !layoutReady {
    if IsDefined(this.m_inventoryView) {
      return this.m_inventoryView.CRBiologyDetailMountStatus() + " " + this.crBiologyDetailContentStatus;
    }
    return "INVENTORY_MISSING " + this.crBiologyDetailContentStatus;
  }

  let result: String;
  if IsDefined(this.m_inventoryView) && IsDefined(this.crBiologyNativeContent) {
    result = this.m_inventoryView.CRBiologyDetailPostMountStatus(this.crBiologyNativeContent);
  } else {
    result = "POST_MOUNT_MISSING";
  }
  result += " " + this.crBiologyDetailContentStatus;

  if IsDefined(this.crBiologyDetailTitle) {
    let headingDesired: Vector2 = this.crBiologyDetailTitle.GetDesiredSize();
    if this.crBiologyDetailTitle.IsVisible() {
      result += " H1/";
    } else {
      result += " H0/";
    }
    result += FloatToStringPrec(this.crBiologyDetailTitle.GetOpacity(), 1);
    result += ":" + FloatToStringPrec(headingDesired.X, 0) + "x" + FloatToStringPrec(headingDesired.Y, 0);
  } else {
    result += " H?";
  }

  if ArraySize(this.crBiologyMetricRows) > 0 && IsDefined(this.crBiologyMetricRows[0]) {
    let rowDesired: Vector2 = this.crBiologyMetricRows[0].GetDesiredSize();
    if this.crBiologyMetricRows[0].IsVisible() {
      result += " M1:";
    } else {
      result += " M0:";
    }
    result += FloatToStringPrec(rowDesired.X, 0) + "x" + FloatToStringPrec(rowDesired.Y, 0);
  } else {
    result += " M?";
  }
  return result;
}

@addMethod(RipperDocGameController)
private final func CRSyncBiologyContentVisibility() -> Void {
  let detail: Bool = this.CRBiologyInDetail();
  if IsDefined(this.crBiologyOverview) {
    this.crBiologyOverview.SetVisible(this.crBiologyShellMode && !detail);
  }

  let detailLayoutReady: Bool = true;
  if detail {
    detailLayoutReady = this.CRSyncBiologyNativeContentLayout();
  }
  if IsDefined(this.crBiologyNativeContent) {
    // Re-read the authored content-host geometry at detail depth. The retained panel
    // can recover from an early lifecycle miss, while a changed/missing native host
    // fails closed and remains visible in the existing selector diagnostic.
    this.crBiologyNativeContent.SetVisible(detail && detailLayoutReady);
  }

  if this.crBiologyShellMode {
    inkCompoundRef.SetVisible(this.m_selectorAnchor, detail);
    this.CRSetBiologyOverviewNodesVisible(!detail);
  } else {
    inkCompoundRef.SetVisible(this.m_selectorAnchor, !this.m_isTutorial);
  }

  if detail && IsDefined(this.m_selector) {
    this.m_selector.CRSetBiologyLayoutDiagnostic(this.CRBiologyDetailPostMountStatus(detailLayoutReady));
  }

  this.CRSyncBiologyModeSwitcher();
  this.CRConstrainBiologyActionsToSelectedArea();
}

@addMethod(RipperDocGameController)
public final func CRRefreshBiologyOverview() -> Void {
  if !IsDefined(this.crBiologyOverviewText) {
    return;
  }
  let player: wref<GameObject> = this.GetPlayerControlledObject();
  if !IsDefined(player) {
    this.crBiologyOverviewText.SetText("[ BIOLOGY ERROR ] BODY RUNTIME PLAYER UNAVAILABLE");
    return;
  }
  let view: ref<CRBiologyViewModel> = CRBiologySessionPresentation.Current(player.GetGame());
  if !IsDefined(view) || !view.valid {
    // Runtime failures remain visible; the shell never manufactures STABLE state.
    this.crBiologyOverviewText.SetText("[ BIOLOGY ERROR ] BODY STATE UNAVAILABLE");
    return;
  }
  let text: String = view.needs;
  if view.hasEffects {
    if !Equals(text, "") { text += "  |  "; }
    text += view.effects;
  }
  if view.hasConditions {
    if !Equals(text, "") { text += "  |  "; }
    text += "CONDITION ACTIVE";
  }
  this.crBiologyOverviewText.SetText(text);
}

@addMethod(RipperDocGameController)
private final func CRHideMetricRows() -> Void {
  let i: Int32 = 0;
  while i < ArraySize(this.crBiologyMetricRows) {
    this.crBiologyMetricRows[i].SetVisible(false);
    i += 1;
  }
}

@addMethod(RipperDocGameController)
private final func CRRefreshBiologyDetail() -> Void {
  if !this.CRBiologyInDetail() || !IsDefined(this.crBiologyNativeContent) {
    this.crBiologyDetailContentStatus = "CONTENT_NOT_READY";
    return;
  }

  let player: wref<GameObject> = this.GetPlayerControlledObject();
  this.CRHideMetricRows();
  if !IsDefined(player) {
    this.crBiologyDetailTitle.SetText(CRBiologyDetailPresentation.Label(this.crBiologySelectedArea));
    this.crBiologyDetailSummary.SetText("[ BIOLOGY ERROR ] BODY RUNTIME PLAYER UNAVAILABLE");
    this.crBiologyDetailContentStatus = "PLAYER_ERROR";
    return;
  }
  let detail: ref<CRBiologyDetailViewModel> = CRBiologySessionPresentation.Detail(player.GetGame(), this.crBiologySelectedArea);
  if !IsDefined(detail) || !detail.valid {
    this.crBiologyDetailTitle.SetText(CRBiologyDetailPresentation.Label(this.crBiologySelectedArea));
    this.crBiologyDetailSummary.SetText("[ BIOLOGY ERROR ] BODY DETAIL UNAVAILABLE");
    this.crBiologyDetailContentStatus = "DETAIL_ERROR";
    return;
  }

  this.crBiologyDetailTitle.SetText(detail.title);
  this.crBiologyDetailSummary.SetText(detail.summary);
  let i: Int32 = 0;
  while i < ArraySize(detail.metrics) && i < ArraySize(this.crBiologyMetricRows) {
    this.crBiologyMetricLabels[i].SetText(detail.metrics[i].label);
    this.crBiologyMetricFills[i].SetSize(Vector2(300.0 * ClampF(detail.metrics[i].percent / 100.0, 0.0, 1.0), 10.0));
    this.crBiologyMetricValues[i].SetText(detail.metrics[i].valueText);
    this.crBiologyMetricRows[i].SetVisible(true);
    i += 1;
  }
  this.crBiologyDetailContentStatus = "DATA" + IntToString(i);
}

@addMethod(RipperDocGameController)
private final func CREnterBiologyDetail(area: gamedataEquipmentArea) -> Bool {
  if !this.crBiologyShellMode || this.CRBodyShellInDetail() || !CRBiologyDetailPresentation.Supported(area) {
    return false;
  }

  this.crBiologySelectedArea = area;
  this.m_filterArea = area;
  this.m_lastAreaVisited = area;
  this.m_filteringByArea = true;
  // Reuse the same native depth markers that Cyberware uses. Biology deliberately
  // does not call DisplayInventory(true), because that would populate Cyberware
  // equipment; its own read-only/body actions occupy the existing content anchor.
  this.m_isInventoryOpen = true;
  this.m_filterMode = RipperdocModes.Item;

  this.m_audioSystem.Play(n"ui_gui_cyberware_paperdoll_zoom_in_01");
  this.DollHover(area);
  this.DollSelect(true);

  this.m_selector.CRSetBiologyDetailMode(true);
  this.m_selector.Show(this.EquipmentAreaToIndex(area));
  inkCompoundRef.SetVisible(this.m_selectorAnchor, true);
  this.SetButtonHints(true, false);

  this.CRSelectBiologyConditionForArea(area);
  this.CRSetBiologyOverviewNodesVisible(false);
  this.CRRefreshBiologyDetail();
  this.CRRefreshBiologyActions();
  this.CRSyncBiologyContentVisibility();
  return true;
}

@addMethod(RipperDocGameController)
public final func CRHandleBiologySelectorChange(evt: ref<RipperdocSelectorChangeEvent>) -> Bool {
  if !this.CRBiologyInDetail() || !IsDefined(evt) {
    return false;
  }

  let area: gamedataEquipmentArea = this.IndexToEquipmentArea(evt.Index);
  if !CRBiologyDetailPresentation.Supported(area) {
    return true;
  }

  this.m_audioSystem.Play(n"ui_gui_tab_change");
  this.m_filterArea = area;
  this.m_lastAreaVisited = area;
  this.crBiologySelectedArea = area;
  this.m_selector.Show(evt.Index);

  if IsDefined(this.m_animationController) {
    this.m_animationController.StartSlide(evt.SlidingRight, area);
  }
  this.DollHover(area);
  this.DollSelect(true);

  this.CRSelectBiologyConditionForArea(area);
  this.CRRefreshBiologyDetail();
  this.CRRefreshBiologyActions();
  this.CRSyncBiologyContentVisibility();
  return true;
}

@addMethod(RipperDocGameController)
public final func CRHandleBiologyBack() -> Bool {
  if !this.CRBiologyInDetail() {
    return false;
  }

  this.m_audioSystem.Play(n"ui_gui_cyberware_paperdoll_zoom_out_01");
  this.crBiologySelectedArea = gamedataEquipmentArea.Invalid;
  this.m_lastAreaVisited = gamedataEquipmentArea.Invalid;
  this.m_hoverArea = gamedataEquipmentArea.Invalid;
  this.m_filterArea = gamedataEquipmentArea.Invalid;
  this.m_filteringByArea = false;
  this.m_isInventoryOpen = false;
  this.m_filterMode = RipperdocModes.Default;

  if IsDefined(this.m_animationController) {
    this.m_animationController.SetOutside();
  }
  this.DollHover(gamedataEquipmentArea.Invalid);
  this.ClearMinigridSelection();
  this.ResetMinigridPositions();
  this.AnimateMinigrids();

  this.m_selector.CRSetBiologyDetailMode(false);
  this.m_selector.Hide();
  inkCompoundRef.SetVisible(this.m_selectorAnchor, false);
  this.SetButtonHints(true, true);

  this.CRSetCategoryMode(true);
  this.CRSyncBiologyNodeInteractivity(true);
  this.CRRefreshBiologyOverview();
  this.CRRefreshBiologyActions();
  this.CRSyncBiologyContentVisibility();
  return true;
}

@addMethod(RipperDocGameController)
public final func CRApplyBiologyShellMode(biology: Bool) -> Void {
  if !CRRealpassSettings.IsEnabled(GetGameInstance()) {
    biology = false;
  }

  // The attended leak was created by allowing a Biology -> Cyberware transition while
  // the body was selected. Native Cyberware already forbids the inverse in practice;
  // make the rule explicit and symmetric: mode changes are overview-only.
  if this.CRBodyShellInDetail() {
    this.CRSyncBiologyModeSwitcher();
    return;
  }

  this.crBiologySelectedArea = gamedataEquipmentArea.Invalid;
  this.crBiologyShellMode = biology;
  this.m_selector.CRSetBiologyDetailMode(false);
  this.CRSetCategoryMode(biology);
  this.CRSetStockMetersVisible(!biology);

  if IsDefined(this.crBiologyNativeContent) {
    this.crBiologyNativeContent.SetVisible(false);
  }
  if IsDefined(this.crBiologyOverview) {
    this.crBiologyOverview.SetVisible(biology);
  }
  if biology {
    inkCompoundRef.SetVisible(this.m_selectorAnchor, false);
  } else {
    inkCompoundRef.SetVisible(this.m_selectorAnchor, !this.m_isTutorial);
  }

  if IsDefined(this.crBiologyModeButton) {
    this.crBiologyModeButton.SetOpacity(biology ? 1.0 : 0.52);
  }
  if IsDefined(this.crCyberwareModeButton) {
    this.crCyberwareModeButton.SetOpacity(biology ? 0.52 : 1.0);
  }

  if biology {
    this.CRRefreshBiologyOverview();
  }
  this.CRSyncBiologyNodeInteractivity(biology);
  this.CRRefreshBiologyActions();
  this.CRSyncBiologyContentVisibility();
}

@addMethod(RipperDocGameController)
protected cb func OnCRBiologyModeToggle(evt: ref<inkPointerEvent>) -> Bool {
  if !IsDefined(evt) || !evt.IsAction(n"click") || evt.IsHandled() || this.CRBodyShellInDetail() {
    return false;
  }

  let target: wref<inkWidget> = evt.GetCurrentTarget();
  if target == this.crBiologyModeButton {
    this.CRApplyBiologyShellMode(true);
    evt.Handle();
    return true;
  }
  if target == this.crCyberwareModeButton {
    this.CRApplyBiologyShellMode(false);
    evt.Handle();
    return true;
  }
  return false;
}

@addMethod(RipperDocGameController)
protected cb func OnCRBiologyAreaHoverEvent(evt: ref<CRBiologyAreaHoverEvent>) -> Bool {
  if !this.crBiologyShellMode || this.CRBodyShellInDetail() || !IsDefined(evt) || !CRBiologyDetailPresentation.Supported(evt.area) {
    return false;
  }
  this.DollHover(evt.area);
  return true;
}

@addMethod(RipperDocGameController)
protected cb func OnCRBiologyAreaHoverOutEvent(evt: ref<CRBiologyAreaHoverOutEvent>) -> Bool {
  if !this.crBiologyShellMode || this.CRBodyShellInDetail() || !IsDefined(evt) {
    return false;
  }
  this.DollHover(gamedataEquipmentArea.Invalid);
  return true;
}

@addMethod(RipperDocGameController)
protected cb func OnCRBiologyAreaSelectEvent(evt: ref<CRBiologyAreaSelectEvent>) -> Bool {
  if !IsDefined(evt) {
    return false;
  }
  return this.CREnterBiologyDetail(evt.area);
}

@wrapMethod(RipperDocGameController)
protected cb func OnInitialize() -> Bool {
  let result: Bool = wrappedMethod();
  this.crBiologySelectedArea = gamedataEquipmentArea.Invalid;
  if !CRRealpassSettings.IsEnabled(GetGameInstance()) {
    this.crBiologyShellMode = false;
    return result;
  }

  this.CRCreateBiologyShell();
  // Ordinary menu access starts in Biology. A direct ripperdoc/vendor visit starts
  // in Cyberware because that is the service context the player intentionally chose.
  this.CRApplyBiologyShellMode(NotEquals(this.m_screen, CyberwareScreenType.Ripperdoc));
  return result;
}

@wrapMethod(RipperDocGameController)
protected cb func OnUninitialize() -> Bool {
  ArrayClear(this.crBiologyMetricRows);
  ArrayClear(this.crBiologyMetricLabels);
  ArrayClear(this.crBiologyMetricBackgrounds);
  ArrayClear(this.crBiologyMetricFills);
  ArrayClear(this.crBiologyMetricValues);
  this.crBiologyModeBar = null;
  this.crBiologyModeButton = null;
  this.crCyberwareModeButton = null;
  this.crBiologyOverview = null;
  this.crBiologyOverviewText = null;
  this.crBiologyNativeContent = null;
  this.crBiologyDetailTitle = null;
  this.crBiologyDetailSummary = null;
  this.crBiologyDetailContentStatus = "";
  this.crBiologySelectedArea = gamedataEquipmentArea.Invalid;
  this.crBiologyShellMode = false;
  return wrappedMethod();
}
