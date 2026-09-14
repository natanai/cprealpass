// Shared Biology/Cyberware body shell.
// The stock cyberware_equip fullscreen remains the technical screen; RealPass
// changes the player-facing hierarchy and reads body state without duplicating it.
module CyberpunkRealism.Presentation

import CyberpunkRealism.Integration.*
import CyberpunkRealism.Physiology.*

public class CRBiologyAreaSelectEvent extends Event {
  public let area: gamedataEquipmentArea;
}

public class CRBiologyAreaHoverEvent extends Event {
  public let area: gamedataEquipmentArea;
}

public class CRBiologyAreaHoverOutEvent extends Event {}

// Keep the exact native Cyberware menu identifier/fullscreen route. Only its visible
// hub label changes, so every stock transition still opens cyberware_equip.
@wrapMethod(MenuHubLogicController)
public final func SetMenusData(menuData: ref<MenuDataBuilder>, perkPoints: Int32, attrPoints: Int32) -> Void {
  wrappedMethod(menuData, perkPoints, attrPoints);
  let biologyData: MenuData = menuData.GetData(EnumInt(HubMenuItems.Cyberware));
  biologyData.label = "BIOLOGY";
  HubMenuUtils.SetMenuData(this.m_btnCyberware, biologyData);
}

// -----------------------------------------------------------------------------
// Stock Cyberware category anchors become Biology body-system nodes while Biology
// mode is active. Their slot grids are hidden, not destroyed or re-authored.
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
  if this.crBiologyCallbacksInstalled {
    return;
  }
  inkTextRef.RegisterToCallback(this.m_label, n"OnRelease", this, n"OnCRBiologyRelease");
  inkTextRef.RegisterToCallback(this.m_label, n"OnHoverOver", this, n"OnCRBiologyHoverOver");
  inkTextRef.RegisterToCallback(this.m_label, n"OnHoverOut", this, n"OnCRBiologyHoverOut");
  this.crBiologyCallbacksInstalled = true;
}

@addMethod(CyberwareInventoryMiniGrid)
public final func CRSetBiologyMode(active: Bool) -> Void {
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

@addField(RipperDocGameController)
private let crBiologyDetailPanel: ref<inkVerticalPanel>;

@addField(RipperDocGameController)
private let crBiologyDetailTitle: ref<inkText>;

@addField(RipperDocGameController)
private let crBiologyDetailSummary: ref<inkText>;

@addField(RipperDocGameController)
private let crBiologyDetailBack: ref<inkText>;

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
private final func CRShellAction(text: String, name: CName) -> ref<inkText> {
  let widget: ref<inkText> = this.CRShellText(text, name, 20);
  widget.SetInteractive(true);
  widget.SetOpacity(0.90);
  return widget;
}

@addMethod(RipperDocGameController)
private final func CRCreateMetricRow(index: Int32) -> Void {
  let row: ref<inkCanvas> = new inkCanvas();
  row.SetName(StringToName("CRBiologyMetricRow" + ToString(index + 1)));
  row.SetSize(Vector2(620.0, 34.0));

  let label: ref<inkText> = this.CRShellText("", StringToName("CRBiologyMetricLabel" + ToString(index + 1)), 17);
  label.SetFitToContent(false);
  label.SetSize(Vector2(205.0, 28.0));
  label.SetTranslation(0.0, 0.0);
  label.Reparent(row, -1);

  let background: ref<inkRectangle> = new inkRectangle();
  background.SetName(StringToName("CRBiologyMetricBG" + ToString(index + 1)));
  background.SetSize(Vector2(270.0, 9.0));
  background.SetTranslation(215.0, 8.0);
  background.SetOpacity(0.28);
  background.Reparent(row, -1);

  let fill: ref<inkRectangle> = new inkRectangle();
  fill.SetName(StringToName("CRBiologyMetricFill" + ToString(index + 1)));
  fill.SetSize(Vector2(0.0, 9.0));
  fill.SetTranslation(215.0, 8.0);
  fill.SetOpacity(0.90);
  fill.Reparent(row, -1);

  let value: ref<inkText> = this.CRShellText("", StringToName("CRBiologyMetricValue" + ToString(index + 1)), 17);
  value.SetTranslation(500.0, 0.0);
  value.Reparent(row, -1);

  row.Reparent(this.crBiologyDetailPanel, -1);
  ArrayPush(this.crBiologyMetricRows, row);
  ArrayPush(this.crBiologyMetricLabels, label);
  ArrayPush(this.crBiologyMetricBackgrounds, background);
  ArrayPush(this.crBiologyMetricFills, fill);
  ArrayPush(this.crBiologyMetricValues, value);
}

@addMethod(RipperDocGameController)
private final func CRCreateBiologyShell() -> Void {
  if IsDefined(this.crBiologyModeBar) {
    return;
  }
  let root: ref<inkCompoundWidget> = this.GetRootCompoundWidget();
  if !IsDefined(root) {
    return;
  }

  this.crBiologyModeBar = new inkHorizontalPanel();
  this.crBiologyModeBar.SetName(n"CRBiologyModeBar");
  this.crBiologyModeBar.SetAnchor(inkEAnchor.TopCenter);
  this.crBiologyModeBar.SetHAlign(inkEHorizontalAlign.Center);
  this.crBiologyModeBar.SetVAlign(inkEVerticalAlign.Top);
  this.crBiologyModeBar.SetMargin(inkMargin(0.0, 92.0, 0.0, 0.0));
  this.crBiologyModeBar.SetChildMargin(inkMargin(14.0, 0.0, 14.0, 0.0));
  this.crBiologyModeBar.Reparent(root, -1);

  this.crBiologyModeButton = this.CRShellAction("BIOLOGY", n"CRBiologyModeBiology");
  this.crBiologyModeButton.RegisterToCallback(n"OnRelease", this, n"OnCRBiologyModeToggle");
  this.crBiologyModeButton.Reparent(this.crBiologyModeBar, -1);
  this.crCyberwareModeButton = this.CRShellAction("CYBERWARE", n"CRBiologyModeCyberware");
  this.crCyberwareModeButton.RegisterToCallback(n"OnRelease", this, n"OnCRBiologyModeToggle");
  this.crCyberwareModeButton.Reparent(this.crBiologyModeBar, -1);

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

  this.crBiologyDetailPanel = new inkVerticalPanel();
  this.crBiologyDetailPanel.SetName(n"CRBiologyDetailPanel");
  this.crBiologyDetailPanel.SetAnchor(inkEAnchor.BottomCenter);
  this.crBiologyDetailPanel.SetHAlign(inkEHorizontalAlign.Center);
  this.crBiologyDetailPanel.SetVAlign(inkEVerticalAlign.Bottom);
  this.crBiologyDetailPanel.SetMargin(inkMargin(0.0, 0.0, 0.0, 48.0));
  this.crBiologyDetailPanel.SetChildMargin(inkMargin(0.0, 3.0, 0.0, 3.0));
  this.crBiologyDetailPanel.SetVisible(false);
  this.crBiologyDetailPanel.Reparent(root, -1);
  this.crBiologyDetailTitle = this.CRShellText("", n"CRBiologyDetailHeading", 25);
  this.crBiologyDetailTitle.Reparent(this.crBiologyDetailPanel, -1);
  this.crBiologyDetailSummary = this.CRShellWrappedText("", n"CRBiologyDetailSummary", 17, 620.0);
  this.crBiologyDetailSummary.SetOpacity(0.80);
  this.crBiologyDetailSummary.Reparent(this.crBiologyDetailPanel, -1);

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

  this.crBiologyDetailBack = this.CRShellAction("[ OVERVIEW ]", n"CRBiologyDetailBack");
  this.crBiologyDetailBack.SetMargin(inkMargin(0.0, 8.0, 0.0, 0.0));
  this.crBiologyDetailBack.RegisterToCallback(n"OnRelease", this, n"OnCRBiologyDetailBack");
  this.crBiologyDetailBack.Reparent(this.crBiologyDetailPanel, -1);
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
public final func CRRefreshBiologyOverview() -> Void {
  if !IsDefined(this.crBiologyOverviewText) {
    return;
  }
  let view: ref<CRBiologyViewModel> = CRBiologyPresentation.Current();
  if !IsDefined(view) || !view.valid {
    this.crBiologyOverviewText.SetText("Body state is unavailable.");
    return;
  }
  let text: String = view.needs;
  if view.hasEffects {
    if !Equals(text, "") { text += "  "; }
    text += view.effects;
  }
  if view.hasConditions {
    if !Equals(text, "") { text += "  "; }
    text += "Active condition present — select the relevant body system for detail.";
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
  if !this.crBiologyShellMode || !IsDefined(this.crBiologyDetailPanel) {
    return;
  }
  let detail: ref<CRBiologyDetailViewModel> = CRBiologyDetailPresentation.Current(this.crBiologySelectedArea);
  this.CRHideMetricRows();
  if !IsDefined(detail) || !detail.valid {
    this.crBiologyDetailTitle.SetText("BODY");
    this.crBiologyDetailSummary.SetText("No detailed model is available for this node yet.");
    return;
  }
  this.crBiologyDetailTitle.SetText(detail.title);
  this.crBiologyDetailSummary.SetText(detail.summary);
  let i: Int32 = 0;
  while i < ArraySize(detail.metrics) && i < ArraySize(this.crBiologyMetricRows) {
    this.crBiologyMetricLabels[i].SetText(detail.metrics[i].label);
    this.crBiologyMetricFills[i].SetSize(Vector2(270.0 * ClampF(detail.metrics[i].percent / 100.0, 0.0, 1.0), 9.0));
    this.crBiologyMetricValues[i].SetText(detail.metrics[i].valueText);
    this.crBiologyMetricRows[i].SetVisible(true);
    i += 1;
  }
}

@addMethod(RipperDocGameController)
private final func CRCloseBiologyDetail() -> Void {
  this.crBiologySelectedArea = gamedataEquipmentArea.Invalid;
  if IsDefined(this.m_animationController) {
    this.m_animationController.SetOutside();
    this.m_animationController.StopSelect();
    this.m_animationController.StopHover();
  }
  if IsDefined(this.crBiologyDetailPanel) {
    this.crBiologyDetailPanel.SetVisible(false);
  }
  if IsDefined(this.crBiologyOverview) {
    this.crBiologyOverview.SetVisible(this.crBiologyShellMode);
  }
}

@addMethod(RipperDocGameController)
public final func CRApplyBiologyShellMode(biology: Bool) -> Void {
  if biology && this.m_isInventoryOpen {
    return;
  }
  if this.crBiologyShellMode && !biology {
    this.CRCloseBiologyDetail();
  }
  this.crBiologyShellMode = biology;
  this.CRSetCategoryMode(biology);
  this.CRSetStockMetersVisible(!biology);
  if IsDefined(this.crBiologyOverview) {
    this.crBiologyOverview.SetVisible(biology);
  }
  if IsDefined(this.crBiologyDetailPanel) && !biology {
    this.crBiologyDetailPanel.SetVisible(false);
  }
  if IsDefined(this.crBiologyModeButton) {
    this.crBiologyModeButton.SetOpacity(biology ? 1.0 : 0.45);
  }
  if IsDefined(this.crCyberwareModeButton) {
    this.crCyberwareModeButton.SetOpacity(biology ? 0.45 : 1.0);
  }
  if biology {
    this.CRRefreshBiologyOverview();
  }
}

@addMethod(RipperDocGameController)
protected cb func OnCRBiologyModeToggle(evt: ref<inkPointerEvent>) -> Bool {
  if !IsDefined(evt) || !evt.IsAction(n"click") || evt.IsHandled() {
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
  if !this.crBiologyShellMode || !IsDefined(evt) || !CRBiologyDetailPresentation.Supported(evt.area) {
    return false;
  }
  if IsDefined(this.m_animationController) {
    this.m_animationController.StartHover(evt.area);
  }
  return true;
}

@addMethod(RipperDocGameController)
protected cb func OnCRBiologyAreaHoverOutEvent(evt: ref<CRBiologyAreaHoverOutEvent>) -> Bool {
  if !this.crBiologyShellMode || !IsDefined(evt) || !IsDefined(this.m_animationController) {
    return false;
  }
  if Equals(this.crBiologySelectedArea, gamedataEquipmentArea.Invalid) {
    this.m_animationController.StopHover();
  }
  return true;
}

@addMethod(RipperDocGameController)
protected cb func OnCRBiologyAreaSelectEvent(evt: ref<CRBiologyAreaSelectEvent>) -> Bool {
  if !this.crBiologyShellMode || !IsDefined(evt) || !CRBiologyDetailPresentation.Supported(evt.area) {
    return false;
  }
  this.crBiologySelectedArea = evt.area;
  if IsDefined(this.m_animationController) {
    this.m_animationController.StartHover(evt.area);
    this.m_animationController.StartSelect();
  }
  this.crBiologyOverview.SetVisible(false);
  this.crBiologyDetailPanel.SetVisible(true);
  this.CRRefreshBiologyDetail();
  return true;
}

@addMethod(RipperDocGameController)
protected cb func OnCRBiologyDetailBack(evt: ref<inkPointerEvent>) -> Bool {
  if !IsDefined(evt) || !evt.IsAction(n"click") || evt.IsHandled() || !this.crBiologyShellMode {
    return false;
  }
  this.CRCloseBiologyDetail();
  this.CRRefreshBiologyOverview();
  evt.Handle();
  return true;
}

@wrapMethod(RipperDocGameController)
protected cb func OnInitialize() -> Bool {
  let result: Bool = wrappedMethod();
  this.crBiologySelectedArea = gamedataEquipmentArea.Invalid;
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
  this.crBiologyDetailPanel = null;
  this.crBiologyDetailTitle = null;
  this.crBiologyDetailSummary = null;
  this.crBiologyDetailBack = null;
  this.crBiologySelectedArea = gamedataEquipmentArea.Invalid;
  this.crBiologyShellMode = false;
  return wrappedMethod();
}