// Project-original native Biology presentation.
//
// Biology is an embodied-state surface, not a second inventory and not a simulation
// authority. Ordinary Biology lives on the stock hub and invokes stock item actions
// for carried food/drink. Ripperdoc context exposes the same condition language for
// professional care without replacing the vanilla Cyberware screen.
module CyberpunkRealism.Presentation

import CyberpunkRealism.Integration.*
import CyberpunkRealism.Physiology.*

// -----------------------------------------------------------------------------
// Hub Biology surface
// -----------------------------------------------------------------------------

@addField(MenuHubLogicController)
private let crBiologyButton: ref<inkText>;

@addField(MenuHubLogicController)
private let crBiologyPanel: ref<inkVerticalPanel>;

@addField(MenuHubLogicController)
private let crBiologyNeeds: ref<inkText>;

@addField(MenuHubLogicController)
private let crBiologyEffects: ref<inkText>;

@addField(MenuHubLogicController)
private let crBiologyConditionsHeading: ref<inkText>;

@addField(MenuHubLogicController)
private let crBiologyConditionRows: array<ref<inkText>>;

@addField(MenuHubLogicController)
private let crBiologyDetailTitle: ref<inkText>;

@addField(MenuHubLogicController)
private let crBiologyDetailState: ref<inkText>;

@addField(MenuHubLogicController)
private let crBiologyDetailFunction: ref<inkText>;

@addField(MenuHubLogicController)
private let crBiologyDetailPain: ref<inkText>;

@addField(MenuHubLogicController)
private let crBiologyDetailCause: ref<inkText>;

@addField(MenuHubLogicController)
private let crBiologyDetailCare: ref<inkText>;

@addField(MenuHubLogicController)
private let crBiologyEat: ref<inkText>;

@addField(MenuHubLogicController)
private let crBiologyDrink: ref<inkText>;

@addField(MenuHubLogicController)
private let crBiologyDress: ref<inkText>;

@addField(MenuHubLogicController)
private let crBiologySupport: ref<inkText>;

@addField(MenuHubLogicController)
private let crBiologyClose: ref<inkText>;

@addField(MenuHubLogicController)
private let crBiologyItemRows: array<ref<inkText>>;

@addField(MenuHubLogicController)
private let crBiologyItemIDs: array<ItemID>;

@addField(MenuHubLogicController)
private let crBiologySelectedRegion: Int32;

@addField(MenuHubLogicController)
private let crBiologyPickerMode: Int32;

@addField(MenuHubLogicController)
private let crBiologyStatus: ref<inkText>;

@addMethod(MenuHubLogicController)
private func CRBiologyText(text: String, name: CName, size: Int32) -> ref<inkText> {
  let widget: ref<inkText> = new inkText();
  widget.SetName(name);
  widget.SetText(text);
  widget.SetFontFamily("base\\gameplay\\gui\\fonts\\raj\\raj.inkfontfamily");
  widget.SetFontStyle(n"Medium");
  widget.SetFontSize(size);
  widget.SetFitToContent(true);
  return widget;
}

@addMethod(MenuHubLogicController)
private func CRBiologyWrappedText(text: String, name: CName, size: Int32, width: Float) -> ref<inkText> {
  let widget: ref<inkText> = this.CRBiologyText(text, name, size);
  widget.SetWrappingAtPosition(width);
  widget.SetSize(Vector2(width, 0.0));
  return widget;
}

@addMethod(MenuHubLogicController)
private func CRBiologyAction(text: String, name: CName) -> ref<inkText> {
  let widget: ref<inkText> = this.CRBiologyText(text, name, 21);
  widget.SetInteractive(true);
  widget.SetOpacity(0.90);
  return widget;
}

@addMethod(MenuHubLogicController)
private func CRBiologyFirstCondition() -> Int32 {
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

@addMethod(MenuHubLogicController)
private func CRBiologyCreateUI() -> Void {
  let root: ref<inkCompoundWidget>;
  let row: ref<inkText>;
  if IsDefined(this.crBiologyPanel) {
    return;
  }
  root = this.GetRootCompoundWidget();
  if !IsDefined(root) {
    return;
  }

  this.crBiologyButton = this.CRBiologyAction("BIOLOGY", n"CRBiologyHubButton");
  this.crBiologyButton.SetAnchor(inkEAnchor.TopRight);
  this.crBiologyButton.SetHAlign(inkEHorizontalAlign.Right);
  this.crBiologyButton.SetVAlign(inkEVerticalAlign.Top);
  this.crBiologyButton.SetMargin(inkMargin(0.0, 92.0, 72.0, 0.0));
  this.crBiologyButton.RegisterToCallback(n"OnRelease", this, n"OnCRBiologyOpen");
  this.crBiologyButton.Reparent(root, -1);

  this.crBiologyPanel = new inkVerticalPanel();
  this.crBiologyPanel.SetName(n"CRBiologyPanel");
  this.crBiologyPanel.SetAnchor(inkEAnchor.TopRight);
  this.crBiologyPanel.SetHAlign(inkEHorizontalAlign.Right);
  this.crBiologyPanel.SetVAlign(inkEVerticalAlign.Top);
  this.crBiologyPanel.SetMargin(inkMargin(0.0, 78.0, 72.0, 0.0));
  this.crBiologyPanel.SetChildMargin(inkMargin(0.0, 4.0, 0.0, 4.0));
  this.crBiologyPanel.SetVisible(false);
  this.crBiologyPanel.Reparent(root, -1);

  let heading: ref<inkText> = this.CRBiologyText("BIOLOGY", n"CRBiologyHeading", 34);
  heading.Reparent(this.crBiologyPanel, -1);
  let subtitle: ref<inkText> = this.CRBiologyWrappedText("What your body is making noticeable. Exact simulation values remain hidden.", n"CRBiologySubtitle", 17, 720.0);
  subtitle.SetOpacity(0.65);
  subtitle.Reparent(this.crBiologyPanel, -1);

  let bodyHeading: ref<inkText> = this.CRBiologyText("BODY", n"CRBiologyBodyHeading", 20);
  bodyHeading.SetMargin(inkMargin(0.0, 14.0, 0.0, 0.0));
  bodyHeading.SetOpacity(0.72);
  bodyHeading.Reparent(this.crBiologyPanel, -1);
  this.crBiologyNeeds = this.CRBiologyWrappedText("", n"CRBiologyNeeds", 23, 720.0);
  this.crBiologyNeeds.Reparent(this.crBiologyPanel, -1);

  this.crBiologyEat = this.CRBiologyAction("[ EAT… ]", n"CRBiologyEat");
  this.crBiologyEat.RegisterToCallback(n"OnRelease", this, n"OnCRBiologyPicker");
  this.crBiologyEat.Reparent(this.crBiologyPanel, -1);
  this.crBiologyDrink = this.CRBiologyAction("[ DRINK… ]", n"CRBiologyDrink");
  this.crBiologyDrink.RegisterToCallback(n"OnRelease", this, n"OnCRBiologyPicker");
  this.crBiologyDrink.Reparent(this.crBiologyPanel, -1);

  ArrayClear(this.crBiologyItemRows);
  let itemIndex: Int32 = 0;
  while itemIndex < 8 {
    row = this.CRBiologyAction("", StringToName("CRBiologyItem" + ToString(itemIndex + 1)));
    row.SetVisible(false);
    row.RegisterToCallback(n"OnRelease", this, n"OnCRBiologyItem");
    row.Reparent(this.crBiologyPanel, -1);
    ArrayPush(this.crBiologyItemRows, row);
    itemIndex += 1;
  }

  let effectsHeading: ref<inkText> = this.CRBiologyText("CURRENT EFFECTS", n"CRBiologyEffectsHeading", 20);
  effectsHeading.SetMargin(inkMargin(0.0, 14.0, 0.0, 0.0));
  effectsHeading.SetOpacity(0.72);
  effectsHeading.Reparent(this.crBiologyPanel, -1);
  this.crBiologyEffects = this.CRBiologyWrappedText("", n"CRBiologyEffects", 19, 720.0);
  this.crBiologyEffects.Reparent(this.crBiologyPanel, -1);

  this.crBiologyConditionsHeading = this.CRBiologyText("CONDITIONS", n"CRBiologyConditionsHeading", 20);
  this.crBiologyConditionsHeading.SetMargin(inkMargin(0.0, 14.0, 0.0, 0.0));
  this.crBiologyConditionsHeading.SetOpacity(0.72);
  this.crBiologyConditionsHeading.Reparent(this.crBiologyPanel, -1);

  ArrayClear(this.crBiologyConditionRows);
  let region: Int32 = 1;
  while region <= 6 {
    row = this.CRBiologyAction("", StringToName("CRBiologyCondition" + ToString(region)));
    row.SetVisible(false);
    row.RegisterToCallback(n"OnRelease", this, n"OnCRBiologyCondition");
    row.Reparent(this.crBiologyPanel, -1);
    ArrayPush(this.crBiologyConditionRows, row);
    region += 1;
  }

  this.crBiologyDetailTitle = this.CRBiologyWrappedText("", n"CRBiologyDetailTitle", 25, 720.0);
  this.crBiologyDetailTitle.SetMargin(inkMargin(0.0, 10.0, 0.0, 0.0));
  this.crBiologyDetailTitle.Reparent(this.crBiologyPanel, -1);
  this.crBiologyDetailState = this.CRBiologyWrappedText("", n"CRBiologyDetailState", 18, 720.0); this.crBiologyDetailState.Reparent(this.crBiologyPanel, -1);
  this.crBiologyDetailFunction = this.CRBiologyWrappedText("", n"CRBiologyDetailFunction", 18, 720.0); this.crBiologyDetailFunction.Reparent(this.crBiologyPanel, -1);
  this.crBiologyDetailPain = this.CRBiologyWrappedText("", n"CRBiologyDetailPain", 18, 720.0); this.crBiologyDetailPain.Reparent(this.crBiologyPanel, -1);
  this.crBiologyDetailCause = this.CRBiologyWrappedText("", n"CRBiologyDetailCause", 17, 720.0); this.crBiologyDetailCause.SetOpacity(0.80); this.crBiologyDetailCause.Reparent(this.crBiologyPanel, -1);
  this.crBiologyDetailCare = this.CRBiologyWrappedText("", n"CRBiologyDetailCare", 17, 720.0); this.crBiologyDetailCare.Reparent(this.crBiologyPanel, -1);

  this.crBiologyDress = this.CRBiologyAction("[ APPLY DRESSING ]", n"CRBiologyDress");
  this.crBiologyDress.RegisterToCallback(n"OnRelease", this, n"OnCRBiologyCare");
  this.crBiologyDress.Reparent(this.crBiologyPanel, -1);
  this.crBiologySupport = this.CRBiologyAction("[ SUPPORT LIMB ]", n"CRBiologySupport");
  this.crBiologySupport.RegisterToCallback(n"OnRelease", this, n"OnCRBiologyCare");
  this.crBiologySupport.Reparent(this.crBiologyPanel, -1);

  this.crBiologyStatus = this.CRBiologyWrappedText("", n"CRBiologyStatus", 17, 720.0);
  this.crBiologyStatus.SetOpacity(0.78);
  this.crBiologyStatus.Reparent(this.crBiologyPanel, -1);

  this.crBiologyClose = this.CRBiologyAction("[ CLOSE ]", n"CRBiologyClose");
  this.crBiologyClose.SetMargin(inkMargin(0.0, 14.0, 0.0, 0.0));
  this.crBiologyClose.RegisterToCallback(n"OnRelease", this, n"OnCRBiologyClose");
  this.crBiologyClose.Reparent(this.crBiologyPanel, -1);
  this.CRBiologyRefresh();
}

@addMethod(MenuHubLogicController)
private func CRBiologyHideItemRows() -> Void {
  let i: Int32 = 0;
  while i < ArraySize(this.crBiologyItemRows) {
    this.crBiologyItemRows[i].SetVisible(false);
    i += 1;
  }
  ArrayClear(this.crBiologyItemIDs);
}

@addMethod(MenuHubLogicController)
private func CRBiologyItemHasNativeAction(itemID: ItemID) -> Bool {
  if this.crBiologyPickerMode == 1 {
    return IsDefined(ItemActionsHelper.GetEatAction(itemID)) || IsDefined(ItemActionsHelper.GetConsumeAction(itemID));
  }
  if this.crBiologyPickerMode == 2 {
    return IsDefined(ItemActionsHelper.GetDrinkAction(itemID)) || IsDefined(ItemActionsHelper.GetConsumeAction(itemID));
  }
  return false;
}

@addMethod(MenuHubLogicController)
private func CRBiologyUseNativeItemAction(player: wref<GameObject>, itemID: ItemID) -> Bool {
  if !IsDefined(player) {
    return false;
  }
  if this.crBiologyPickerMode == 1 {
    if IsDefined(ItemActionsHelper.GetEatAction(itemID)) {
      ItemActionsHelper.EatItem(player, itemID, true);
      return true;
    }
    if IsDefined(ItemActionsHelper.GetConsumeAction(itemID)) {
      ItemActionsHelper.ConsumeItem(player, itemID, true);
      return true;
    }
  }
  if this.crBiologyPickerMode == 2 {
    if IsDefined(ItemActionsHelper.GetDrinkAction(itemID)) {
      ItemActionsHelper.DrinkItem(player, itemID, true);
      return true;
    }
    if IsDefined(ItemActionsHelper.GetConsumeAction(itemID)) {
      ItemActionsHelper.ConsumeItem(player, itemID, true);
      return true;
    }
  }
  return false;
}

@addMethod(MenuHubLogicController)
private func CRBiologyRefreshItems() -> Void {
  this.CRBiologyHideItemRows();
  if this.crBiologyPickerMode == 0 {
    return;
  }
  let player: ref<PlayerPuppet> = GameInstance.GetPlayerSystem(GetGameInstance()).GetLocalPlayerMainGameObject() as PlayerPuppet;
  if !IsDefined(player) {
    this.crBiologyStatus.SetText("Inventory is unavailable.");
    return;
  }
  let items: array<wref<gameItemData>>;
  GameInstance.GetTransactionSystem(GetGameInstance()).GetItemList(player, items);
  let i: Int32 = 0;
  let shown: Int32 = 0;
  while i < ArraySize(items) && shown < ArraySize(this.crBiologyItemRows) {
    if IsDefined(items[i]) {
      let itemID: ItemID = items[i].GetID();
      let record: wref<Item_Record> = TweakDBInterface.GetItemRecord(ItemID.GetTDBID(itemID));
      if IsDefined(record) {
        let serving: ref<CRServing> = CRItemServing.Resolve(record);
        let matches: Bool = false;
        if IsDefined(serving) && serving.recognized {
          if this.crBiologyPickerMode == 1 {
            matches = record.TagsContains(n"Food");
          } else {
            matches = record.TagsContains(n"Drink") || record.TagsContains(n"Alcohol");
          }
        }
        matches = matches && this.CRBiologyItemHasNativeAction(itemID);
        if matches {
          let quantity: Int32 = GameInstance.GetTransactionSystem(GetGameInstance()).GetItemQuantity(player, itemID);
          this.crBiologyItemRows[shown].SetText("[ " + GetLocalizedItemNameByCName(record.DisplayName()) + "  x" + ToString(quantity) + " ]");
          this.crBiologyItemRows[shown].SetVisible(true);
          ArrayPush(this.crBiologyItemIDs, itemID);
          shown += 1;
        }
      }
    }
    i += 1;
  }
  if shown == 0 {
    this.crBiologyStatus.SetText(this.crBiologyPickerMode == 1 ? "No modeled food is currently carried." : "No modeled drink is currently carried.");
  }
}

@addMethod(MenuHubLogicController)
private func CRBiologyRefresh() -> Void {
  if !IsDefined(this.crBiologyPanel) {
    return;
  }
  let view: ref<CRBiologyViewModel> = CRBiologyPresentation.Current();
  if !IsDefined(view) || !view.valid {
    this.crBiologyNeeds.SetText("Body state is unavailable.");
    this.crBiologyEffects.SetText("");
    this.crBiologyEat.SetVisible(false);
    this.crBiologyDrink.SetVisible(false);
    this.crBiologyDress.SetVisible(false);
    this.crBiologySupport.SetVisible(false);
    this.CRBiologyHideItemRows();
    return;
  }
  this.crBiologyNeeds.SetText(view.needs);
  this.crBiologyEat.SetVisible(view.showEat);
  this.crBiologyDrink.SetVisible(view.showDrink);
  this.crBiologyEffects.SetText(view.hasEffects ? view.effects : "No additional effect is demanding attention.");

  let i: Int32 = 0;
  let descriptor: ref<CRConditionDescriptor>;
  while i < ArraySize(this.crBiologyConditionRows) {
    descriptor = CRConditionPresentation.Current(i + 1);
    let active: Bool = IsDefined(descriptor) && descriptor.valid && descriptor.hasCondition;
    this.crBiologyConditionRows[i].SetVisible(active);
    if active {
      this.crBiologyConditionRows[i].SetText("[ " + descriptor.regionName + " — " + descriptor.title + " / " + descriptor.severity + " ]");
      this.crBiologyConditionRows[i].SetOpacity(i + 1 == this.crBiologySelectedRegion ? 1.0 : 0.68);
    }
    i += 1;
  }

  if this.crBiologySelectedRegion < 1 || this.crBiologySelectedRegion > 6 {
    this.crBiologySelectedRegion = this.CRBiologyFirstCondition();
  }
  descriptor = CRConditionPresentation.Current(this.crBiologySelectedRegion);
  if !IsDefined(descriptor) || !descriptor.valid || !descriptor.hasCondition {
    this.crBiologySelectedRegion = this.CRBiologyFirstCondition();
    descriptor = CRConditionPresentation.Current(this.crBiologySelectedRegion);
  }
  if !IsDefined(descriptor) || !descriptor.valid || !descriptor.hasCondition {
    this.crBiologyDetailTitle.SetText("No active injury condition");
    this.crBiologyDetailState.SetText("Healthy regions remain visually quiet.");
    this.crBiologyDetailFunction.SetText("");
    this.crBiologyDetailPain.SetText("");
    this.crBiologyDetailCause.SetText("");
    this.crBiologyDetailCare.SetText("");
    this.crBiologyDress.SetVisible(false);
    this.crBiologySupport.SetVisible(false);
  } else {
    this.crBiologyDetailTitle.SetText(descriptor.regionName + " — " + descriptor.title + " / " + descriptor.severity);
    this.crBiologyDetailState.SetText(descriptor.currentState);
    this.crBiologyDetailFunction.SetText(descriptor.functionText);
    this.crBiologyDetailPain.SetText(descriptor.painText);
    this.crBiologyDetailCause.SetText(descriptor.likelyCause);
    this.crBiologyDetailCare.SetText("FIELD CARE: " + descriptor.fieldCare + "\nPROFESSIONAL CARE: " + descriptor.professionalCare);
    this.crBiologyDress.SetVisible(descriptor.canDress);
    this.crBiologySupport.SetVisible(descriptor.canSupport);
  }
  this.CRBiologyRefreshItems();
}

@addMethod(MenuHubLogicController)
protected cb func OnCRBiologyOpen(evt: ref<inkPointerEvent>) -> Bool {
  if !IsDefined(evt) || !evt.IsAction(n"click") || evt.IsHandled() {
    return false;
  }
  this.crBiologySelectedRegion = this.CRBiologyFirstCondition();
  this.crBiologyPickerMode = 0;
  this.crBiologyStatus.SetText("");
  this.crBiologyButton.SetVisible(false);
  this.crBiologyPanel.SetVisible(true);
  this.CRBiologyRefresh();
  evt.Handle();
  return true;
}

@addMethod(MenuHubLogicController)
protected cb func OnCRBiologyClose(evt: ref<inkPointerEvent>) -> Bool {
  if !IsDefined(evt) || !evt.IsAction(n"click") || evt.IsHandled() {
    return false;
  }
  this.crBiologyPickerMode = 0;
  this.CRBiologyHideItemRows();
  this.crBiologyPanel.SetVisible(false);
  this.crBiologyButton.SetVisible(true);
  evt.Handle();
  return true;
}

@addMethod(MenuHubLogicController)
protected cb func OnCRBiologyPicker(evt: ref<inkPointerEvent>) -> Bool {
  if !IsDefined(evt) || !evt.IsAction(n"click") || evt.IsHandled() {
    return false;
  }
  if Equals(evt.GetCurrentTarget(), this.crBiologyEat) {
    this.crBiologyPickerMode = this.crBiologyPickerMode == 1 ? 0 : 1;
  } else {
    if Equals(evt.GetCurrentTarget(), this.crBiologyDrink) {
      this.crBiologyPickerMode = this.crBiologyPickerMode == 2 ? 0 : 2;
    } else {
      return false;
    }
  }
  this.crBiologyStatus.SetText("");
  this.CRBiologyRefreshItems();
  evt.Handle();
  return true;
}

@addMethod(MenuHubLogicController)
protected cb func OnCRBiologyItem(evt: ref<inkPointerEvent>) -> Bool {
  let i: Int32 = 0;
  if !IsDefined(evt) || !evt.IsAction(n"click") || evt.IsHandled() {
    return false;
  }
  while i < ArraySize(this.crBiologyItemRows) && i < ArraySize(this.crBiologyItemIDs) {
    if Equals(evt.GetCurrentTarget(), this.crBiologyItemRows[i]) {
      let player: ref<PlayerPuppet> = GameInstance.GetPlayerSystem(GetGameInstance()).GetLocalPlayerMainGameObject() as PlayerPuppet;
      if !this.CRBiologyUseNativeItemAction(player, this.crBiologyItemIDs[i]) {
        this.crBiologyStatus.SetText("That carried item cannot be eaten or drunk right now.");
      } else {
        this.crBiologyStatus.SetText("Used the selected carried item through Cyberpunk's normal item action.");
      }
      this.crBiologyPickerMode = 0;
      this.CRBiologyRefresh();
      evt.Handle();
      return true;
    }
    i += 1;
  }
  return false;
}

@addMethod(MenuHubLogicController)
protected cb func OnCRBiologyCondition(evt: ref<inkPointerEvent>) -> Bool {
  let i: Int32 = 0;
  if !IsDefined(evt) || !evt.IsAction(n"click") || evt.IsHandled() {
    return false;
  }
  while i < ArraySize(this.crBiologyConditionRows) {
    if Equals(evt.GetCurrentTarget(), this.crBiologyConditionRows[i]) {
      this.crBiologySelectedRegion = i + 1;
      this.crBiologyStatus.SetText("");
      this.CRBiologyRefresh();
      evt.Handle();
      return true;
    }
    i += 1;
  }
  return false;
}

@addMethod(MenuHubLogicController)
private func CRBiologyCareFeedback(result: Int32) -> String {
  switch result {
    case 8: return CRFieldCareActionRuntime.Get().Status();
    case 2: return "Required field-care supplies are unavailable. Nothing was consumed.";
    case 6: return "That field treatment no longer helps this condition.";
  }
  return "Field care cannot be started in the current state. Nothing was consumed.";
}

@addMethod(MenuHubLogicController)
protected cb func OnCRBiologyCare(evt: ref<inkPointerEvent>) -> Bool {
  let kind: Int32;
  if !IsDefined(evt) || !evt.IsAction(n"click") || evt.IsHandled() || this.crBiologySelectedRegion < 1 {
    return false;
  }
  if Equals(evt.GetCurrentTarget(), this.crBiologyDress) {
    kind = 2;
  } else {
    if Equals(evt.GetCurrentTarget(), this.crBiologySupport) {
      kind = 3;
    } else {
      return false;
    }
  }
  let result: Int32 = CRBodyRuntime.Get().UseFieldCare(this.crBiologySelectedRegion, kind);
  this.crBiologyStatus.SetText(this.CRBiologyCareFeedback(result));
  this.CRBiologyRefresh();
  evt.Handle();
  return true;
}

@wrapMethod(MenuHubLogicController)
public final func SetActive(isActive: Bool) -> Void {
  wrappedMethod(isActive);
  if !IsDefined(this.crBiologyPanel) || !IsDefined(this.crBiologyButton) {
    return;
  }
  if !isActive {
    this.crBiologyPickerMode = 0;
    this.CRBiologyHideItemRows();
    this.crBiologyPanel.SetVisible(false);
    this.crBiologyButton.SetVisible(false);
  } else {
    this.crBiologyButton.SetVisible(!this.crBiologyPanel.IsVisible());
  }
}

@wrapMethod(MenuHubLogicController)
protected cb func OnInitialize() -> Bool {
  let result: Bool = wrappedMethod();
  this.crBiologySelectedRegion = 0;
  this.crBiologyPickerMode = 0;
  this.CRBiologyCreateUI();
  return result;
}

@wrapMethod(MenuHubLogicController)
protected cb func OnUninitialize() -> Bool {
  ArrayClear(this.crBiologyConditionRows);
  ArrayClear(this.crBiologyItemRows);
  ArrayClear(this.crBiologyItemIDs);
  this.crBiologyButton = null;
  this.crBiologyPanel = null;
  this.crBiologyNeeds = null;
  this.crBiologyEffects = null;
  this.crBiologyConditionsHeading = null;
  this.crBiologyDetailTitle = null;
  this.crBiologyDetailState = null;
  this.crBiologyDetailFunction = null;
  this.crBiologyDetailPain = null;
  this.crBiologyDetailCause = null;
  this.crBiologyDetailCare = null;
  this.crBiologyEat = null;
  this.crBiologyDrink = null;
  this.crBiologyDress = null;
  this.crBiologySupport = null;
  this.crBiologyClose = null;
  this.crBiologyStatus = null;
  this.crBiologySelectedRegion = 0;
  this.crBiologyPickerMode = 0;
  return wrappedMethod();
}

// -----------------------------------------------------------------------------
// Ripperdoc professional-care Biology surface
// -----------------------------------------------------------------------------

@addField(RipperDocGameController)
private let crBiologyCareButton: ref<inkText>;

@addField(RipperDocGameController)
private let crBiologyCarePanel: ref<inkVerticalPanel>;

@addField(RipperDocGameController)
private let crBiologyCareRows: array<ref<inkText>>;

@addField(RipperDocGameController)
private let crBiologyCareTitle: ref<inkText>;

@addField(RipperDocGameController)
private let crBiologyCareState: ref<inkText>;

@addField(RipperDocGameController)
private let crBiologyCareNeed: ref<inkText>;

@addField(RipperDocGameController)
private let crBiologyClinical: ref<inkText>;

@addField(RipperDocGameController)
private let crBiologyMechanical: ref<inkText>;

@addField(RipperDocGameController)
private let crBiologyCareClose: ref<inkText>;

@addField(RipperDocGameController)
private let crBiologyCareStatus: ref<inkText>;

@addField(RipperDocGameController)
private let crBiologyCareRegion: Int32;

@addMethod(RipperDocGameController)
private func CRBiologyCareText(text: String, name: CName, size: Int32) -> ref<inkText> {
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
private func CRBiologyCareWrapped(text: String, name: CName, size: Int32) -> ref<inkText> {
  let widget: ref<inkText> = this.CRBiologyCareText(text, name, size);
  widget.SetWrappingAtPosition(620.0);
  widget.SetSize(Vector2(620.0, 0.0));
  return widget;
}

@addMethod(RipperDocGameController)
private func CRBiologyCareAction(text: String, name: CName) -> ref<inkText> {
  let widget: ref<inkText> = this.CRBiologyCareText(text, name, 20);
  widget.SetInteractive(true);
  return widget;
}

@addMethod(RipperDocGameController)
private func CRBiologyCareFirst() -> Int32 {
  let region: Int32 = 1;
  while region <= 6 {
    let descriptor: ref<CRConditionDescriptor> = CRConditionPresentation.Current(region);
    if IsDefined(descriptor) && descriptor.valid && descriptor.hasCondition {
      return region;
    }
    region += 1;
  }
  return 0;
}

@addMethod(RipperDocGameController)
private func CRBiologyCreateProfessionalUI() -> Void {
  if IsDefined(this.crBiologyCarePanel) {
    return;
  }
  let root: ref<inkCompoundWidget> = this.GetRootCompoundWidget();
  if !IsDefined(root) {
    return;
  }
  this.crBiologyCareButton = this.CRBiologyCareAction("BIOLOGY", n"CRBiologyRipperdocButton");
  this.crBiologyCareButton.SetAnchor(inkEAnchor.TopRight);
  this.crBiologyCareButton.SetHAlign(inkEHorizontalAlign.Right);
  this.crBiologyCareButton.SetMargin(inkMargin(0.0, 92.0, 72.0, 0.0));
  this.crBiologyCareButton.SetVisible(Equals(this.m_screen, CyberwareScreenType.Ripperdoc));
  this.crBiologyCareButton.RegisterToCallback(n"OnRelease", this, n"OnCRBiologyCareOpen");
  this.crBiologyCareButton.Reparent(root, -1);

  this.crBiologyCarePanel = new inkVerticalPanel();
  this.crBiologyCarePanel.SetName(n"CRBiologyProfessionalPanel");
  this.crBiologyCarePanel.SetAnchor(inkEAnchor.TopRight);
  this.crBiologyCarePanel.SetHAlign(inkEHorizontalAlign.Right);
  this.crBiologyCarePanel.SetMargin(inkMargin(0.0, 142.0, 72.0, 0.0));
  this.crBiologyCarePanel.SetChildMargin(inkMargin(0.0, 4.0, 0.0, 4.0));
  this.crBiologyCarePanel.SetVisible(false);
  this.crBiologyCarePanel.Reparent(root, -1);

  let professionalHeading: ref<inkText> = this.CRBiologyCareText("BIOLOGY / PROFESSIONAL CARE", n"CRBiologyProfessionalHeading", 28);
  professionalHeading.Reparent(this.crBiologyCarePanel, -1);
  ArrayClear(this.crBiologyCareRows);
  let region: Int32 = 1;
  while region <= 6 {
    let row: ref<inkText> = this.CRBiologyCareAction("", StringToName("CRBiologyProfessionalCondition" + ToString(region)));
    row.SetVisible(false);
    row.RegisterToCallback(n"OnRelease", this, n"OnCRBiologyCareCondition");
    row.Reparent(this.crBiologyCarePanel, -1);
    ArrayPush(this.crBiologyCareRows, row);
    region += 1;
  }
  this.crBiologyCareTitle = this.CRBiologyCareWrapped("", n"CRBiologyProfessionalTitle", 24); this.crBiologyCareTitle.Reparent(this.crBiologyCarePanel, -1);
  this.crBiologyCareState = this.CRBiologyCareWrapped("", n"CRBiologyProfessionalState", 18); this.crBiologyCareState.Reparent(this.crBiologyCarePanel, -1);
  this.crBiologyCareNeed = this.CRBiologyCareWrapped("", n"CRBiologyProfessionalNeed", 18); this.crBiologyCareNeed.Reparent(this.crBiologyCarePanel, -1);
  this.crBiologyClinical = this.CRBiologyCareAction("[ CLINICAL CARE ]", n"CRBiologyClinical");
  this.crBiologyClinical.RegisterToCallback(n"OnRelease", this, n"OnCRBiologyProfessional");
  this.crBiologyClinical.Reparent(this.crBiologyCarePanel, -1);
  this.crBiologyMechanical = this.CRBiologyCareAction("[ REPAIR CYBERWARE ]", n"CRBiologyMechanical");
  this.crBiologyMechanical.RegisterToCallback(n"OnRelease", this, n"OnCRBiologyProfessional");
  this.crBiologyMechanical.Reparent(this.crBiologyCarePanel, -1);
  this.crBiologyCareStatus = this.CRBiologyCareWrapped("", n"CRBiologyProfessionalStatus", 17); this.crBiologyCareStatus.Reparent(this.crBiologyCarePanel, -1);
  this.crBiologyCareClose = this.CRBiologyCareAction("[ CLOSE ]", n"CRBiologyProfessionalClose");
  this.crBiologyCareClose.RegisterToCallback(n"OnRelease", this, n"OnCRBiologyCareClose");
  this.crBiologyCareClose.Reparent(this.crBiologyCarePanel, -1);
  this.CRBiologyRefreshProfessionalUI();
}

@addMethod(RipperDocGameController)
private func CRBiologyRefreshProfessionalUI() -> Void {
  if !IsDefined(this.crBiologyCarePanel) {
    return;
  }
  let i: Int32 = 0;
  let descriptor: ref<CRConditionDescriptor>;
  while i < ArraySize(this.crBiologyCareRows) {
    descriptor = CRConditionPresentation.Current(i + 1);
    let active: Bool = IsDefined(descriptor) && descriptor.valid && descriptor.hasCondition;
    this.crBiologyCareRows[i].SetVisible(active);
    if active {
      this.crBiologyCareRows[i].SetText("[ " + descriptor.regionName + " — " + descriptor.title + " / " + descriptor.severity + " ]");
      this.crBiologyCareRows[i].SetOpacity(i + 1 == this.crBiologyCareRegion ? 1.0 : 0.68);
    }
    i += 1;
  }
  if this.crBiologyCareRegion < 1 || this.crBiologyCareRegion > 6 {
    this.crBiologyCareRegion = this.CRBiologyCareFirst();
  }
  descriptor = CRConditionPresentation.Current(this.crBiologyCareRegion);
  if !IsDefined(descriptor) || !descriptor.valid || !descriptor.hasCondition {
    this.crBiologyCareRegion = this.CRBiologyCareFirst();
    descriptor = CRConditionPresentation.Current(this.crBiologyCareRegion);
  }
  if !IsDefined(descriptor) || !descriptor.valid || !descriptor.hasCondition {
    this.crBiologyCareTitle.SetText("No active condition requires professional care.");
    this.crBiologyCareState.SetText("");
    this.crBiologyCareNeed.SetText("");
    this.crBiologyClinical.SetVisible(false);
    this.crBiologyMechanical.SetVisible(false);
    return;
  }
  this.crBiologyCareTitle.SetText(descriptor.regionName + " — " + descriptor.title + " / " + descriptor.severity);
  this.crBiologyCareState.SetText(descriptor.currentState + " " + descriptor.functionText);
  this.crBiologyCareNeed.SetText(descriptor.professionalCare);
  this.crBiologyClinical.SetVisible(descriptor.canClinical);
  this.crBiologyMechanical.SetVisible(descriptor.canMechanical);
}

@addMethod(RipperDocGameController)
protected cb func OnCRBiologyCareOpen(evt: ref<inkPointerEvent>) -> Bool {
  if !IsDefined(evt) || !evt.IsAction(n"click") || evt.IsHandled() || !Equals(this.m_screen, CyberwareScreenType.Ripperdoc) {
    return false;
  }
  this.crBiologyCareRegion = this.CRBiologyCareFirst();
  this.crBiologyCareStatus.SetText("");
  this.crBiologyCarePanel.SetVisible(true);
  this.crBiologyCareButton.SetVisible(false);
  this.CRBiologyRefreshProfessionalUI();
  evt.Handle();
  return true;
}

@addMethod(RipperDocGameController)
protected cb func OnCRBiologyCareClose(evt: ref<inkPointerEvent>) -> Bool {
  if !IsDefined(evt) || !evt.IsAction(n"click") || evt.IsHandled() {
    return false;
  }
  this.crBiologyCarePanel.SetVisible(false);
  this.crBiologyCareButton.SetVisible(Equals(this.m_screen, CyberwareScreenType.Ripperdoc));
  evt.Handle();
  return true;
}

@addMethod(RipperDocGameController)
protected cb func OnCRBiologyCareCondition(evt: ref<inkPointerEvent>) -> Bool {
  let i: Int32 = 0;
  if !IsDefined(evt) || !evt.IsAction(n"click") || evt.IsHandled() {
    return false;
  }
  while i < ArraySize(this.crBiologyCareRows) {
    if Equals(evt.GetCurrentTarget(), this.crBiologyCareRows[i]) {
      this.crBiologyCareRegion = i + 1;
      this.crBiologyCareStatus.SetText("");
      this.CRBiologyRefreshProfessionalUI();
      evt.Handle();
      return true;
    }
    i += 1;
  }
  return false;
}

@addMethod(RipperDocGameController)
protected cb func OnCRBiologyProfessional(evt: ref<inkPointerEvent>) -> Bool {
  let kind: Int32;
  if !IsDefined(evt) || !evt.IsAction(n"click") || evt.IsHandled() || this.crBiologyCareRegion < 1 || !Equals(this.m_screen, CyberwareScreenType.Ripperdoc) {
    return false;
  }
  if Equals(evt.GetCurrentTarget(), this.crBiologyClinical) {
    kind = 4;
  } else {
    if Equals(evt.GetCurrentTarget(), this.crBiologyMechanical) {
      kind = 5;
    } else {
      return false;
    }
  }
  if CRProfessionalCareRuntime.Complete(this.crBiologyCareRegion, kind) {
    this.crBiologyCareStatus.SetText(kind == 4 ? "Clinical care completed. Biological recovery still takes body time." : "Cyberware repair completed for this region.");
  } else {
    this.crBiologyCareStatus.SetText("Professional care could not be completed. No injury state changed.");
  }
  this.CRBiologyRefreshProfessionalUI();
  evt.Handle();
  return true;
}

@wrapMethod(RipperDocGameController)
protected cb func OnInitialize() -> Bool {
  let result: Bool = wrappedMethod();
  this.crBiologyCareRegion = 0;
  this.CRBiologyCreateProfessionalUI();
  return result;
}

@wrapMethod(RipperDocGameController)
protected cb func OnUninitialize() -> Bool {
  ArrayClear(this.crBiologyCareRows);
  this.crBiologyCareButton = null;
  this.crBiologyCarePanel = null;
  this.crBiologyCareTitle = null;
  this.crBiologyCareState = null;
  this.crBiologyCareNeed = null;
  this.crBiologyClinical = null;
  this.crBiologyMechanical = null;
  this.crBiologyCareClose = null;
  this.crBiologyCareStatus = null;
  this.crBiologyCareRegion = 0;
  return wrappedMethod();
}
