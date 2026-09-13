// Project-original first native slice of CYBERWARE | CONDITION.
//
// This deliberately reuses the stock RipperDoc/Cyberware controller and its paper-
// doll selection animation. It adds only realpass-owned ink widgets and reads the
// qualitative Condition projection; the UI never becomes an injury authority.
module CyberpunkRealism.Presentation

import CyberpunkRealism.Integration.*

@addField(RipperDocGameController)
private let crConditionTabs: wref<inkHorizontalPanel>;

@addField(RipperDocGameController)
private let crConditionPanel: wref<inkVerticalPanel>;

@addField(RipperDocGameController)
private let crConditionList: wref<inkVerticalPanel>;

@addField(RipperDocGameController)
private let crConditionCyberwareTab: wref<inkText>;

@addField(RipperDocGameController)
private let crConditionTab: wref<inkText>;

@addField(RipperDocGameController)
private let crConditionRegionWidgets: array<wref<inkText>>;

@addField(RipperDocGameController)
private let crConditionTitle: wref<inkText>;

@addField(RipperDocGameController)
private let crConditionState: wref<inkText>;

@addField(RipperDocGameController)
private let crConditionCause: wref<inkText>;

@addField(RipperDocGameController)
private let crConditionFunction: wref<inkText>;

@addField(RipperDocGameController)
private let crConditionPain: wref<inkText>;

@addField(RipperDocGameController)
private let crConditionCare: wref<inkText>;

@addField(RipperDocGameController)
private let crConditionProfessional: wref<inkText>;

@addField(RipperDocGameController)
private let crConditionDress: wref<inkText>;

@addField(RipperDocGameController)
private let crConditionSupport: wref<inkText>;

@addField(RipperDocGameController)
private let crConditionClinical: wref<inkText>;

@addField(RipperDocGameController)
private let crConditionMechanical: wref<inkText>;

@addField(RipperDocGameController)
private let crConditionStatus: wref<inkText>;

@addField(RipperDocGameController)
private let crConditionMode: Bool;

@addField(RipperDocGameController)
private let crConditionSelectedRegion: Int32;

@addMethod(RipperDocGameController)
private func CRConditionText(text: String, name: CName, size: Int32) -> ref<inkText> {
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
private func CRConditionWrappedText(text: String, name: CName, size: Int32, width: Float) -> ref<inkText> {
  let widget: ref<inkText> = this.CRConditionText(text, name, size);
  widget.SetWrappingAtPosition(width);
  widget.SetSize(Vector2(width, 0.0));
  return widget;
}

@addMethod(RipperDocGameController)
private func CRConditionCreateUI() -> Void {
  let root: ref<inkCompoundWidget>;
  let region: ref<inkText>;
  if IsDefined(this.crConditionTabs) || IsDefined(this.crConditionPanel) {
    return;
  }
  root = this.GetRootCompoundWidget();
  if !IsDefined(root) {
    return;
  }

  this.crConditionTabs = new inkHorizontalPanel();
  this.crConditionTabs.SetName(n"CRConditionTabs");
  this.crConditionTabs.SetAnchor(inkEAnchor.TopRight);
  this.crConditionTabs.SetHAlign(inkEHorizontalAlign.Right);
  this.crConditionTabs.SetVAlign(inkEVerticalAlign.Top);
  this.crConditionTabs.SetMargin(inkMargin(0.0, 92.0, 72.0, 0.0));
  this.crConditionTabs.SetChildMargin(inkMargin(14.0, 0.0, 14.0, 0.0));
  this.crConditionTabs.Reparent(root, -1);

  this.crConditionCyberwareTab = this.CRConditionText("CYBERWARE", n"CRConditionCyberwareTab", 28);
  this.crConditionCyberwareTab.SetInteractive(true);
  this.crConditionCyberwareTab.RegisterToCallback(n"OnRelease", this, n"OnCRConditionTabReleased");
  this.crConditionCyberwareTab.Reparent(this.crConditionTabs, -1);

  let divider: ref<inkText> = this.CRConditionText("|", n"CRConditionDivider", 28);
  divider.SetOpacity(0.45);
  divider.Reparent(this.crConditionTabs, -1);

  this.crConditionTab = this.CRConditionText("CONDITION", n"CRConditionConditionTab", 28);
  this.crConditionTab.SetInteractive(true);
  this.crConditionTab.RegisterToCallback(n"OnRelease", this, n"OnCRConditionTabReleased");
  this.crConditionTab.Reparent(this.crConditionTabs, -1);

  this.crConditionPanel = new inkVerticalPanel();
  this.crConditionPanel.SetName(n"CRConditionPanel");
  this.crConditionPanel.SetAnchor(inkEAnchor.TopRight);
  this.crConditionPanel.SetHAlign(inkEHorizontalAlign.Right);
  this.crConditionPanel.SetVAlign(inkEVerticalAlign.Top);
  this.crConditionPanel.SetMargin(inkMargin(0.0, 142.0, 72.0, 0.0));
  this.crConditionPanel.SetChildMargin(inkMargin(0.0, 5.0, 0.0, 5.0));
  this.crConditionPanel.SetVisible(false);
  this.crConditionPanel.Reparent(root, -1);

  let heading: ref<inkText> = this.CRConditionText("ACTIVE CONDITIONS", n"CRConditionHeading", 22);
  heading.SetOpacity(0.70);
  heading.Reparent(this.crConditionPanel, -1);

  this.crConditionList = new inkVerticalPanel();
  this.crConditionList.SetName(n"CRConditionList");
  this.crConditionList.SetChildMargin(inkMargin(0.0, 3.0, 0.0, 3.0));
  this.crConditionList.Reparent(this.crConditionPanel, -1);

  ArrayClear(this.crConditionRegionWidgets);
  region = this.CRConditionText("", n"CRConditionRegion1", 24); ArrayPush(this.crConditionRegionWidgets, region); region.Reparent(this.crConditionList, -1);
  region = this.CRConditionText("", n"CRConditionRegion2", 24); ArrayPush(this.crConditionRegionWidgets, region); region.Reparent(this.crConditionList, -1);
  region = this.CRConditionText("", n"CRConditionRegion3", 24); ArrayPush(this.crConditionRegionWidgets, region); region.Reparent(this.crConditionList, -1);
  region = this.CRConditionText("", n"CRConditionRegion4", 24); ArrayPush(this.crConditionRegionWidgets, region); region.Reparent(this.crConditionList, -1);
  region = this.CRConditionText("", n"CRConditionRegion5", 24); ArrayPush(this.crConditionRegionWidgets, region); region.Reparent(this.crConditionList, -1);
  region = this.CRConditionText("", n"CRConditionRegion6", 24); ArrayPush(this.crConditionRegionWidgets, region); region.Reparent(this.crConditionList, -1);

  let i: Int32 = 0;
  while i < ArraySize(this.crConditionRegionWidgets) {
    this.crConditionRegionWidgets[i].SetInteractive(true);
    this.crConditionRegionWidgets[i].RegisterToCallback(n"OnRelease", this, n"OnCRConditionRegionReleased");
    i += 1;
  }

  this.crConditionTitle = this.CRConditionWrappedText("", n"CRConditionTitle", 28, 570.0);
  this.crConditionTitle.SetMargin(inkMargin(0.0, 16.0, 0.0, 0.0));
  this.crConditionTitle.Reparent(this.crConditionPanel, -1);
  this.crConditionState = this.CRConditionWrappedText("", n"CRConditionState", 20, 570.0); this.crConditionState.Reparent(this.crConditionPanel, -1);
  this.crConditionFunction = this.CRConditionWrappedText("", n"CRConditionFunction", 20, 570.0); this.crConditionFunction.Reparent(this.crConditionPanel, -1);
  this.crConditionPain = this.CRConditionWrappedText("", n"CRConditionPain", 18, 570.0); this.crConditionPain.SetOpacity(0.90); this.crConditionPain.Reparent(this.crConditionPanel, -1);
  this.crConditionCause = this.CRConditionWrappedText("", n"CRConditionCause", 18, 570.0); this.crConditionCause.SetOpacity(0.78); this.crConditionCause.Reparent(this.crConditionPanel, -1);
  this.crConditionCare = this.CRConditionWrappedText("", n"CRConditionCare", 18, 570.0); this.crConditionCare.Reparent(this.crConditionPanel, -1);
  this.crConditionProfessional = this.CRConditionWrappedText("", n"CRConditionProfessional", 18, 570.0); this.crConditionProfessional.Reparent(this.crConditionPanel, -1);

  this.crConditionDress = this.CRConditionText("[ APPLY DRESSING ]", n"CRConditionDress", 20);
  this.crConditionDress.SetInteractive(true);
  this.crConditionDress.RegisterToCallback(n"OnRelease", this, n"OnCRConditionCareReleased");
  this.crConditionDress.Reparent(this.crConditionPanel, -1);

  this.crConditionSupport = this.CRConditionText("[ SUPPORT LIMB ]", n"CRConditionSupport", 20);
  this.crConditionSupport.SetInteractive(true);
  this.crConditionSupport.RegisterToCallback(n"OnRelease", this, n"OnCRConditionCareReleased");
  this.crConditionSupport.Reparent(this.crConditionPanel, -1);

  this.crConditionClinical = this.CRConditionText("[ CLINICAL CARE ]", n"CRConditionClinical", 20);
  this.crConditionClinical.SetInteractive(true);
  this.crConditionClinical.RegisterToCallback(n"OnRelease", this, n"OnCRConditionProfessionalReleased");
  this.crConditionClinical.Reparent(this.crConditionPanel, -1);

  this.crConditionMechanical = this.CRConditionText("[ REPAIR CYBERWARE ]", n"CRConditionMechanical", 20);
  this.crConditionMechanical.SetInteractive(true);
  this.crConditionMechanical.RegisterToCallback(n"OnRelease", this, n"OnCRConditionProfessionalReleased");
  this.crConditionMechanical.Reparent(this.crConditionPanel, -1);

  this.crConditionStatus = this.CRConditionWrappedText("", n"CRConditionStatus", 18, 570.0);
  this.crConditionStatus.SetOpacity(0.82);
  this.crConditionStatus.Reparent(this.crConditionPanel, -1);
  this.CRConditionRefresh();
}

@addMethod(RipperDocGameController)
private func CRConditionArea(region: Int32) -> gamedataEquipmentArea {
  switch region {
    case 1: return gamedataEquipmentArea.FrontalCortexCW;
    case 2: return gamedataEquipmentArea.IntegumentarySystemCW;
    case 3: return gamedataEquipmentArea.ArmsCW;
    case 4: return gamedataEquipmentArea.ArmsCW;
    case 5: return gamedataEquipmentArea.LegsCW;
    case 6: return gamedataEquipmentArea.LegsCW;
  }
  return gamedataEquipmentArea.Invalid;
}

@addMethod(RipperDocGameController)
private func CRConditionFocusRegion(region: Int32) -> Void {
  let area: gamedataEquipmentArea = this.CRConditionArea(region);
  if Equals(area, gamedataEquipmentArea.Invalid) {
    return;
  }
  this.m_filterArea = area;
  this.m_filteringByArea = true;
  this.DollHover(area);
  this.DollSelect(true);
}

@addMethod(RipperDocGameController)
private func CRConditionFirstActive() -> Int32 {
  let region: Int32 = 1;
  let descriptor: ref<CRConditionDescriptor>;
  while region <= 6 {
    descriptor = CRConditionPresentation.Current(region);
    if IsDefined(descriptor) && descriptor.valid && descriptor.hasCondition {
      return region;
    }
    region += 1;
  }
  return 0;
}

@addMethod(RipperDocGameController)
private func CRConditionRefresh() -> Void {
  let i: Int32 = 0;
  let descriptor: ref<CRConditionDescriptor>;
  let active: Bool;
  let atRipperdoc: Bool = Equals(this.m_screen, CyberwareScreenType.Ripperdoc);
  if !IsDefined(this.crConditionPanel) {
    return;
  }
  while i < ArraySize(this.crConditionRegionWidgets) {
    descriptor = CRConditionPresentation.Current(i + 1);
    active = IsDefined(descriptor) && descriptor.valid && descriptor.hasCondition;
    this.crConditionRegionWidgets[i].SetVisible(active);
    if active {
      this.crConditionRegionWidgets[i].SetText(descriptor.regionName + "  |  " + descriptor.title + "  |  " + descriptor.severity);
      this.crConditionRegionWidgets[i].SetOpacity(i + 1 == this.crConditionSelectedRegion ? 1.0 : 0.68);
    }
    i += 1;
  }

  if this.crConditionSelectedRegion < 1 || this.crConditionSelectedRegion > 6 {
    this.crConditionSelectedRegion = this.CRConditionFirstActive();
  }
  descriptor = CRConditionPresentation.Current(this.crConditionSelectedRegion);
  if !IsDefined(descriptor) || !descriptor.valid || !descriptor.hasCondition {
    this.crConditionSelectedRegion = this.CRConditionFirstActive();
    descriptor = CRConditionPresentation.Current(this.crConditionSelectedRegion);
  }
  if !IsDefined(descriptor) || !descriptor.valid || !descriptor.hasCondition {
    this.crConditionTitle.SetText("NO ACTIVE CONDITIONS");
    this.crConditionState.SetText("No regional injury currently requires attention.");
    this.crConditionFunction.SetText("");
    this.crConditionPain.SetText("");
    this.crConditionCause.SetText("");
    this.crConditionCare.SetText("");
    this.crConditionProfessional.SetText("");
    this.crConditionDress.SetVisible(false);
    this.crConditionSupport.SetVisible(false);
    this.crConditionClinical.SetVisible(false);
    this.crConditionMechanical.SetVisible(false);
    return;
  }

  this.crConditionTitle.SetText(descriptor.regionName + " — " + descriptor.title + " / " + descriptor.severity);
  this.crConditionState.SetText(descriptor.currentState);
  this.crConditionFunction.SetText(descriptor.functionText);
  this.crConditionPain.SetText(descriptor.painText);
  this.crConditionCause.SetText(descriptor.likelyCause);
  this.crConditionCare.SetText("FIELD CARE: " + descriptor.fieldCare);
  this.crConditionProfessional.SetText("PROFESSIONAL CARE: " + descriptor.professionalCare);
  this.crConditionDress.SetVisible(descriptor.canDress && !atRipperdoc);
  this.crConditionSupport.SetVisible(descriptor.canSupport && !atRipperdoc);
  this.crConditionClinical.SetVisible(descriptor.canClinical && atRipperdoc);
  this.crConditionMechanical.SetVisible(descriptor.canMechanical && atRipperdoc);
}

@addMethod(RipperDocGameController)
private func CRConditionSetMode(enabled: Bool) -> Void {
  if !IsDefined(this.crConditionPanel) {
    return;
  }
  this.crConditionMode = enabled;
  this.crConditionPanel.SetVisible(enabled);
  this.crConditionCyberwareTab.SetOpacity(enabled ? 0.45 : 1.0);
  this.crConditionTab.SetOpacity(enabled ? 1.0 : 0.45);
  if enabled {
    this.crConditionStatus.SetText("");
    this.crConditionSelectedRegion = this.CRConditionFirstActive();
    this.CRConditionRefresh();
    if this.crConditionSelectedRegion > 0 {
      this.CRConditionFocusRegion(this.crConditionSelectedRegion);
    }
  } else {
    if this.m_dollSelected {
      this.DollSelect(false);
    }
    this.m_filteringByArea = false;
  }
}

@addMethod(RipperDocGameController)
protected cb func OnCRConditionTabReleased(evt: ref<inkPointerEvent>) -> Bool {
  if !IsDefined(evt) || !evt.IsAction(n"click") || evt.IsHandled() {
    return false;
  }
  if Equals(evt.GetCurrentTarget(), this.crConditionTab) {
    this.CRConditionSetMode(true);
  } else {
    if Equals(evt.GetCurrentTarget(), this.crConditionCyberwareTab) {
      this.CRConditionSetMode(false);
    } else {
      return false;
    }
  }
  evt.Handle();
  return true;
}

@addMethod(RipperDocGameController)
protected cb func OnCRConditionRegionReleased(evt: ref<inkPointerEvent>) -> Bool {
  let i: Int32 = 0;
  if !this.crConditionMode || !IsDefined(evt) || !evt.IsAction(n"click") || evt.IsHandled() {
    return false;
  }
  while i < ArraySize(this.crConditionRegionWidgets) {
    if Equals(evt.GetCurrentTarget(), this.crConditionRegionWidgets[i]) {
      this.crConditionSelectedRegion = i + 1;
      this.crConditionStatus.SetText("");
      this.CRConditionFocusRegion(this.crConditionSelectedRegion);
      this.CRConditionRefresh();
      evt.Handle();
      return true;
    }
    i += 1;
  }
  return false;
}

@addMethod(RipperDocGameController)
private func CRConditionCareFeedback(result: Int32) -> String {
  switch result {
    case 8: return CRFieldCareActionRuntime.Get().Status();
    case 2: return "Required field-care supplies are unavailable. No treatment started.";
    case 6: return "That field treatment no longer helps this condition.";
  }
  return "Field care is unavailable here. Nothing was consumed.";
}

@addMethod(RipperDocGameController)
protected cb func OnCRConditionCareReleased(evt: ref<inkPointerEvent>) -> Bool {
  let kind: Int32;
  let result: Int32;
  if !this.crConditionMode || !IsDefined(evt) || !evt.IsAction(n"click") || evt.IsHandled() || this.crConditionSelectedRegion < 1 || Equals(this.m_screen, CyberwareScreenType.Ripperdoc) {
    return false;
  }
  if Equals(evt.GetCurrentTarget(), this.crConditionDress) {
    kind = 2;
  } else {
    if Equals(evt.GetCurrentTarget(), this.crConditionSupport) {
      kind = 3;
    } else {
      return false;
    }
  }
  result = CRBodyRuntime.Get().UseFieldCare(this.crConditionSelectedRegion, kind);
  this.crConditionStatus.SetText(this.CRConditionCareFeedback(result));
  this.CRConditionRefresh();
  evt.Handle();
  return true;
}

@addMethod(RipperDocGameController)
protected cb func OnCRConditionProfessionalReleased(evt: ref<inkPointerEvent>) -> Bool {
  let descriptor: ref<CRConditionDescriptor>;
  let kind: Int32;
  let accepted: Bool;
  if !this.crConditionMode || !IsDefined(evt) || !evt.IsAction(n"click") || evt.IsHandled() || this.crConditionSelectedRegion < 1 || !Equals(this.m_screen, CyberwareScreenType.Ripperdoc) {
    return false;
  }
  descriptor = CRConditionPresentation.Current(this.crConditionSelectedRegion);
  if !IsDefined(descriptor) || !descriptor.valid || !descriptor.hasCondition {
    return false;
  }
  if Equals(evt.GetCurrentTarget(), this.crConditionClinical) && descriptor.canClinical {
    kind = 4;
  } else {
    if Equals(evt.GetCurrentTarget(), this.crConditionMechanical) && descriptor.canMechanical {
      kind = 5;
    } else {
      return false;
    }
  }

  // These are completed professional-service interactions, not portable kit care.
  // The runtime re-checks service eligibility immediately before the shared body
  // treatment commit. Biological recovery still takes body time; mechanical repair
  // affects chrome only.
  accepted = CRProfessionalCareRuntime.Complete(this.crConditionSelectedRegion, kind);
  if accepted {
    if kind == 4 {
      this.crConditionStatus.SetText("Clinical care completed. Biological recovery still takes time.");
    } else {
      this.crConditionStatus.SetText("Cyberware repair completed for this region.");
    }
  } else {
    this.crConditionStatus.SetText("Professional care could not be completed. No injury state was changed.");
  }
  this.CRConditionRefresh();
  evt.Handle();
  return true;
}

@wrapMethod(RipperDocGameController)
protected cb func OnInitialize() -> Bool {
  let result: Bool = wrappedMethod();
  this.crConditionMode = false;
  this.crConditionSelectedRegion = 0;
  this.CRConditionCreateUI();
  this.CRConditionSetMode(false);
  return result;
}

@wrapMethod(RipperDocGameController)
protected cb func OnUninitialize() -> Bool {
  this.crConditionMode = false;
  this.crConditionSelectedRegion = 0;
  ArrayClear(this.crConditionRegionWidgets);
  this.crConditionTabs = null;
  this.crConditionPanel = null;
  this.crConditionList = null;
  this.crConditionCyberwareTab = null;
  this.crConditionTab = null;
  this.crConditionTitle = null;
  this.crConditionState = null;
  this.crConditionCause = null;
  this.crConditionFunction = null;
  this.crConditionPain = null;
  this.crConditionCare = null;
  this.crConditionProfessional = null;
  this.crConditionDress = null;
  this.crConditionSupport = null;
  this.crConditionClinical = null;
  this.crConditionMechanical = null;
  this.crConditionStatus = null;
  return wrappedMethod();
}
