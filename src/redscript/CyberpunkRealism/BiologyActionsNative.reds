// Contextual actions inside the shared Biology/Cyberware body shell.
// Inventory and treatment authority remain elsewhere: this file only exposes
// relevant gateways and submits work to existing native/item/care runtimes.
module CyberpunkRealism.Presentation

import CyberpunkRealism.Integration.*
import CyberpunkRealism.Physiology.*

@addField(RipperDocGameController)
private let crBioActionsPanel: ref<inkVerticalPanel>;

@addField(RipperDocGameController)
private let crBioEat: ref<inkText>;

@addField(RipperDocGameController)
private let crBioDrink: ref<inkText>;

@addField(RipperDocGameController)
private let crBioItemRows: array<ref<inkText>>;

@addField(RipperDocGameController)
private let crBioItemIDs: array<ItemID>;

@addField(RipperDocGameController)
private let crBioPickerMode: Int32;

@addField(RipperDocGameController)
private let crBioConditionsHeading: ref<inkText>;

@addField(RipperDocGameController)
private let crBioConditionRows: array<ref<inkText>>;

@addField(RipperDocGameController)
private let crBioSelectedRegion: Int32;

@addField(RipperDocGameController)
private let crBioDress: ref<inkText>;

@addField(RipperDocGameController)
private let crBioSupport: ref<inkText>;

@addField(RipperDocGameController)
private let crBioClinical: ref<inkText>;

@addField(RipperDocGameController)
private let crBioMechanical: ref<inkText>;

@addField(RipperDocGameController)
private let crBioActionStatus: ref<inkText>;

@addMethod(RipperDocGameController)
private final func CRBioActionText(text: String, name: CName, size: Int32) -> ref<inkText> {
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
private final func CRBioActionButton(text: String, name: CName) -> ref<inkText> {
  let widget: ref<inkText> = this.CRBioActionText(text, name, 18);
  widget.SetInteractive(true);
  widget.SetOpacity(0.88);
  return widget;
}

@addMethod(RipperDocGameController)
private final func CRBioCreateActions() -> Void {
  if IsDefined(this.crBioActionsPanel) {
    return;
  }

  // Create safely on the fullscreen root; the outer native-shell wrapper reparents
  // this panel into m_inventoryViewAnchor once all chained OnInitialize hooks finish.
  let root: ref<inkCompoundWidget> = this.GetRootCompoundWidget();
  if !IsDefined(root) {
    return;
  }

  this.crBioActionsPanel = new inkVerticalPanel();
  this.crBioActionsPanel.SetName(n"CRBiologyActions");
  this.crBioActionsPanel.SetChildMargin(inkMargin(0.0, 3.0, 0.0, 3.0));
  this.crBioActionsPanel.SetVisible(false);
  this.crBioActionsPanel.Reparent(root, -1);

  let intakeHeading: ref<inkText> = this.CRBioActionText("CONTEXT", n"CRBioContextHeading", 17);
  intakeHeading.SetOpacity(0.62);
  intakeHeading.Reparent(this.crBioActionsPanel, -1);

  this.crBioEat = this.CRBioActionButton("[ EAT… ]", n"CRBioEat");
  this.crBioEat.RegisterToCallback(n"OnRelease", this, n"OnCRBioPicker");
  this.crBioEat.Reparent(this.crBioActionsPanel, -1);
  this.crBioDrink = this.CRBioActionButton("[ DRINK… ]", n"CRBioDrink");
  this.crBioDrink.RegisterToCallback(n"OnRelease", this, n"OnCRBioPicker");
  this.crBioDrink.Reparent(this.crBioActionsPanel, -1);

  ArrayClear(this.crBioItemRows);
  let i: Int32 = 0;
  while i < 8 {
    let row: ref<inkText> = this.CRBioActionButton("", StringToName("CRBioItem" + ToString(i + 1)));
    row.SetVisible(false);
    row.RegisterToCallback(n"OnRelease", this, n"OnCRBioItem");
    row.Reparent(this.crBioActionsPanel, -1);
    ArrayPush(this.crBioItemRows, row);
    i += 1;
  }

  this.crBioConditionsHeading = this.CRBioActionText("ACTIVE CONDITIONS", n"CRBioConditionsHeading", 17);
  this.crBioConditionsHeading.SetMargin(inkMargin(0.0, 10.0, 0.0, 0.0));
  this.crBioConditionsHeading.SetOpacity(0.62);
  this.crBioConditionsHeading.Reparent(this.crBioActionsPanel, -1);

  ArrayClear(this.crBioConditionRows);
  let region: Int32 = 1;
  while region <= 6 {
    let condition: ref<inkText> = this.CRBioActionButton("", StringToName("CRBioCondition" + ToString(region)));
    condition.SetVisible(false);
    condition.RegisterToCallback(n"OnRelease", this, n"OnCRBioCondition");
    condition.Reparent(this.crBioActionsPanel, -1);
    ArrayPush(this.crBioConditionRows, condition);
    region += 1;
  }

  this.crBioDress = this.CRBioActionButton("[ APPLY DRESSING ]", n"CRBioDress");
  this.crBioDress.RegisterToCallback(n"OnRelease", this, n"OnCRBioCare");
  this.crBioDress.Reparent(this.crBioActionsPanel, -1);
  this.crBioSupport = this.CRBioActionButton("[ SUPPORT LIMB ]", n"CRBioSupport");
  this.crBioSupport.RegisterToCallback(n"OnRelease", this, n"OnCRBioCare");
  this.crBioSupport.Reparent(this.crBioActionsPanel, -1);
  this.crBioClinical = this.CRBioActionButton("[ CLINICAL CARE ]", n"CRBioClinical");
  this.crBioClinical.RegisterToCallback(n"OnRelease", this, n"OnCRBioProfessional");
  this.crBioClinical.Reparent(this.crBioActionsPanel, -1);
  this.crBioMechanical = this.CRBioActionButton("[ REPAIR CYBERWARE ]", n"CRBioMechanical");
  this.crBioMechanical.RegisterToCallback(n"OnRelease", this, n"OnCRBioProfessional");
  this.crBioMechanical.Reparent(this.crBioActionsPanel, -1);

  this.crBioActionStatus = this.CRBioActionText("", n"CRBioActionStatus", 16);
  this.crBioActionStatus.SetWrappingAtPosition(420.0);
  this.crBioActionStatus.SetSize(Vector2(420.0, 0.0));
  this.crBioActionStatus.SetOpacity(0.72);
  this.crBioActionStatus.Reparent(this.crBioActionsPanel, -1);
}

@addMethod(RipperDocGameController)
private final func CRBioAreaAllowsIntake() -> Bool {
  return this.CRBiologyInDetail() && Equals(this.crBiologySelectedArea, gamedataEquipmentArea.SystemReplacementCW);
}

@addMethod(RipperDocGameController)
private final func CRBioRegionAllowedForSelectedArea(region: Int32) -> Bool {
  if !this.CRBiologyInDetail() || region < 1 || region > 6 {
    return false;
  }
  let area: gamedataEquipmentArea = this.crBiologySelectedArea;
  if Equals(area, gamedataEquipmentArea.FrontalCortexCW) {
    return region == 1;
  }
  if Equals(area, gamedataEquipmentArea.ArmsCW) {
    return region == 3 || region == 4;
  }
  if Equals(area, gamedataEquipmentArea.LegsCW) {
    return region == 5 || region == 6;
  }
  return Equals(area, gamedataEquipmentArea.MusculoskeletalSystemCW)
    || Equals(area, gamedataEquipmentArea.IntegumentarySystemCW);
}

@addMethod(RipperDocGameController)
private final func CRBioFirstCondition() -> Int32 {
  let region: Int32 = 1;
  while region <= 6 {
    let descriptor: ref<CRConditionDescriptor> = CRConditionPresentation.Current(region);
    if this.CRBioRegionAllowedForSelectedArea(region) && IsDefined(descriptor) && descriptor.valid && descriptor.hasCondition {
      return region;
    }
    region += 1;
  }
  return 0;
}

@addMethod(RipperDocGameController)
private final func CRBioHideItemRows() -> Void {
  let i: Int32 = 0;
  while i < ArraySize(this.crBioItemRows) {
    this.crBioItemRows[i].SetVisible(false);
    i += 1;
  }
  ArrayClear(this.crBioItemIDs);
}

@addMethod(RipperDocGameController)
private final func CRBioItemHasNativeAction(itemID: ItemID) -> Bool {
  if this.crBioPickerMode == 1 {
    return IsDefined(ItemActionsHelper.GetEatAction(itemID)) || IsDefined(ItemActionsHelper.GetConsumeAction(itemID));
  }
  if this.crBioPickerMode == 2 {
    return IsDefined(ItemActionsHelper.GetDrinkAction(itemID)) || IsDefined(ItemActionsHelper.GetConsumeAction(itemID));
  }
  return false;
}

@addMethod(RipperDocGameController)
private final func CRBioUseNativeItemAction(player: wref<GameObject>, itemID: ItemID) -> Bool {
  if !IsDefined(player) || !this.CRBioAreaAllowsIntake() {
    return false;
  }
  if this.crBioPickerMode == 1 {
    if IsDefined(ItemActionsHelper.GetEatAction(itemID)) {
      ItemActionsHelper.EatItem(player, itemID, true);
      return true;
    }
    if IsDefined(ItemActionsHelper.GetConsumeAction(itemID)) {
      ItemActionsHelper.ConsumeItem(player, itemID, true);
      return true;
    }
  }
  if this.crBioPickerMode == 2 {
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

@addMethod(RipperDocGameController)
private final func CRBioRefreshItems() -> Void {
  this.CRBioHideItemRows();
  if this.crBioPickerMode == 0 || !this.CRBioAreaAllowsIntake() {
    return;
  }

  let player: ref<PlayerPuppet> = GameInstance.GetPlayerSystem(GetGameInstance()).GetLocalPlayerMainGameObject() as PlayerPuppet;
  if !IsDefined(player) {
    this.crBioActionStatus.SetText("Inventory is unavailable.");
    return;
  }

  // Enumerate actual carried stacks from Cyberpunk's transaction system. The action
  // is only surfaced if the same ItemID also has a real native eat/drink/consume path.
  let items: array<wref<gameItemData>>;
  GameInstance.GetTransactionSystem(GetGameInstance()).GetItemList(player, items);
  let i: Int32 = 0;
  let shown: Int32 = 0;
  while i < ArraySize(items) && shown < ArraySize(this.crBioItemRows) {
    if IsDefined(items[i]) {
      let itemID: ItemID = items[i].GetID();
      let record: wref<Item_Record> = TweakDBInterface.GetItemRecord(ItemID.GetTDBID(itemID));
      if IsDefined(record) {
        let serving: ref<CRServing> = CRItemServing.Resolve(record);
        let matches: Bool = false;
        if IsDefined(serving) && serving.recognized {
          if this.crBioPickerMode == 1 {
            matches = record.TagsContains(n"Food");
          } else {
            matches = record.TagsContains(n"Drink") || record.TagsContains(n"Alcohol");
          }
        }
        matches = matches && this.CRBioItemHasNativeAction(itemID);
        if matches {
          let quantity: Int32 = GameInstance.GetTransactionSystem(GetGameInstance()).GetItemQuantity(player, itemID);
          this.crBioItemRows[shown].SetText("[ " + GetLocalizedItemNameByCName(record.DisplayName()) + "  x" + ToString(quantity) + " ]");
          this.crBioItemRows[shown].SetVisible(true);
          ArrayPush(this.crBioItemIDs, itemID);
          shown += 1;
        }
      }
    }
    i += 1;
  }

  if shown == 0 {
    this.crBioActionStatus.SetText(this.crBioPickerMode == 1 ? "No modeled food is currently carried." : "No modeled drink is currently carried.");
  }
}

@addMethod(RipperDocGameController)
public final func CRRefreshBiologyActions() -> Void {
  if !IsDefined(this.crBioActionsPanel) {
    return;
  }

  this.crBioEat.SetVisible(false);
  this.crBioDrink.SetVisible(false);
  this.CRBioHideItemRows();
  this.crBioConditionsHeading.SetVisible(false);
  this.crBioDress.SetVisible(false);
  this.crBioSupport.SetVisible(false);
  this.crBioClinical.SetVisible(false);
  this.crBioMechanical.SetVisible(false);
  let clearIndex: Int32 = 0;
  while clearIndex < ArraySize(this.crBioConditionRows) {
    this.crBioConditionRows[clearIndex].SetVisible(false);
    clearIndex += 1;
  }

  // Overview is inspection-only. Contextual actions occupy the native content area
  // only after the player has deliberately entered a Biology body-system detail.
  if !this.crBiologyShellMode || !this.CRBiologyInDetail() {
    this.crBioPickerMode = 0;
    this.crBioActionsPanel.SetVisible(false);
    return;
  }

  let view: ref<CRBiologyViewModel> = CRBiologyPresentation.Current();
  let intake: Bool = this.CRBioAreaAllowsIntake();
  let showEat: Bool = intake && IsDefined(view) && view.valid && view.showEat;
  let showDrink: Bool = intake && IsDefined(view) && view.valid && view.showDrink;
  this.crBioEat.SetVisible(showEat);
  this.crBioDrink.SetVisible(showDrink);

  let anyCondition: Bool = false;
  let i: Int32 = 0;
  let descriptor: ref<CRConditionDescriptor>;
  while i < ArraySize(this.crBioConditionRows) {
    descriptor = CRConditionPresentation.Current(i + 1);
    let active: Bool = this.CRBioRegionAllowedForSelectedArea(i + 1)
      && IsDefined(descriptor)
      && descriptor.valid
      && descriptor.hasCondition;
    this.crBioConditionRows[i].SetVisible(active);
    if active {
      anyCondition = true;
      this.crBioConditionRows[i].SetText("[ " + descriptor.regionName + " — " + descriptor.title + " / " + descriptor.severity + " ]");
      this.crBioConditionRows[i].SetOpacity(i + 1 == this.crBioSelectedRegion ? 1.0 : 0.62);
    }
    i += 1;
  }

  if this.crBioSelectedRegion < 1 || !this.CRBioRegionAllowedForSelectedArea(this.crBioSelectedRegion) {
    this.crBioSelectedRegion = this.CRBioFirstCondition();
  }
  descriptor = CRConditionPresentation.Current(this.crBioSelectedRegion);
  if !IsDefined(descriptor) || !descriptor.valid || !descriptor.hasCondition {
    this.crBioSelectedRegion = this.CRBioFirstCondition();
    descriptor = CRConditionPresentation.Current(this.crBioSelectedRegion);
  }

  let hasCondition: Bool = IsDefined(descriptor) && descriptor.valid && descriptor.hasCondition;
  this.crBioConditionsHeading.SetVisible(anyCondition);
  this.crBioDress.SetVisible(hasCondition && descriptor.canDress);
  this.crBioSupport.SetVisible(hasCondition && descriptor.canSupport);
  let professional: Bool = Equals(this.m_screen, CyberwareScreenType.Ripperdoc);
  this.crBioClinical.SetVisible(professional && hasCondition && descriptor.canClinical);
  this.crBioMechanical.SetVisible(professional && hasCondition && descriptor.canMechanical);

  this.crBioActionsPanel.SetVisible(showEat || showDrink || anyCondition);
  this.CRBioRefreshItems();
}

@addMethod(RipperDocGameController)
protected cb func OnCRBioPicker(evt: ref<inkPointerEvent>) -> Bool {
  if !this.CRBioAreaAllowsIntake() || !IsDefined(evt) || !evt.IsAction(n"click") || evt.IsHandled() {
    return false;
  }
  let target: wref<inkWidget> = evt.GetCurrentTarget();
  if target == this.crBioEat {
    this.crBioPickerMode = this.crBioPickerMode == 1 ? 0 : 1;
  } else {
    if target == this.crBioDrink {
      this.crBioPickerMode = this.crBioPickerMode == 2 ? 0 : 2;
    } else {
      return false;
    }
  }
  this.crBioActionStatus.SetText("");
  this.CRBioRefreshItems();
  evt.Handle();
  return true;
}

@addMethod(RipperDocGameController)
protected cb func OnCRBioItem(evt: ref<inkPointerEvent>) -> Bool {
  if !this.CRBioAreaAllowsIntake() || !IsDefined(evt) || !evt.IsAction(n"click") || evt.IsHandled() {
    return false;
  }
  let target: wref<inkWidget> = evt.GetCurrentTarget();
  let i: Int32 = 0;
  while i < ArraySize(this.crBioItemRows) && i < ArraySize(this.crBioItemIDs) {
    if target == this.crBioItemRows[i] {
      let player: ref<PlayerPuppet> = GameInstance.GetPlayerSystem(GetGameInstance()).GetLocalPlayerMainGameObject() as PlayerPuppet;
      if this.CRBioUseNativeItemAction(player, this.crBioItemIDs[i]) {
        this.crBioActionStatus.SetText("Used the selected carried item through its normal Cyberpunk item action.");
      } else {
        this.crBioActionStatus.SetText("That carried item cannot be eaten or drunk right now.");
      }
      this.crBioPickerMode = 0;
      this.CRRefreshBiologyActions();
      this.CRRefreshBiologyDetail();
      this.CRRefreshBiologyOverview();
      evt.Handle();
      return true;
    }
    i += 1;
  }
  return false;
}

@addMethod(RipperDocGameController)
protected cb func OnCRBioCondition(evt: ref<inkPointerEvent>) -> Bool {
  if !this.CRBiologyInDetail() || !IsDefined(evt) || !evt.IsAction(n"click") || evt.IsHandled() {
    return false;
  }
  let target: wref<inkWidget> = evt.GetCurrentTarget();
  let i: Int32 = 0;
  while i < ArraySize(this.crBioConditionRows) {
    if target == this.crBioConditionRows[i] && this.CRBioRegionAllowedForSelectedArea(i + 1) {
      this.crBioSelectedRegion = i + 1;
      this.crBioActionStatus.SetText("");
      this.CRRefreshBiologyActions();
      evt.Handle();
      return true;
    }
    i += 1;
  }
  return false;
}

@addMethod(RipperDocGameController)
private final func CRBioCareFeedback(result: Int32) -> String {
  switch result {
    case 8: return CRFieldCareActionRuntime.Get().Status();
    case 2: return "Required field-care supplies are unavailable. Nothing was consumed.";
    case 6: return "That field treatment no longer helps this condition.";
  }
  return "Field care cannot be started in the current state. Nothing was consumed.";
}

@addMethod(RipperDocGameController)
protected cb func OnCRBioCare(evt: ref<inkPointerEvent>) -> Bool {
  if !this.CRBiologyInDetail() || !this.CRBioRegionAllowedForSelectedArea(this.crBioSelectedRegion)
    || !IsDefined(evt) || !evt.IsAction(n"click") || evt.IsHandled() {
    return false;
  }
  let target: wref<inkWidget> = evt.GetCurrentTarget();
  let kind: Int32;
  if target == this.crBioDress {
    kind = 2;
  } else {
    if target == this.crBioSupport {
      kind = 3;
    } else {
      return false;
    }
  }

  // Field-care runtime owns inventory checks, timed action state and consumption.
  let result: Int32 = CRBodyRuntime.Get().UseFieldCare(this.crBioSelectedRegion, kind);
  this.crBioActionStatus.SetText(this.CRBioCareFeedback(result));
  this.CRRefreshBiologyActions();
  this.CRRefreshBiologyDetail();
  this.CRRefreshBiologyOverview();
  evt.Handle();
  return true;
}

@addMethod(RipperDocGameController)
protected cb func OnCRBioProfessional(evt: ref<inkPointerEvent>) -> Bool {
  if !this.CRBiologyInDetail() || !Equals(this.m_screen, CyberwareScreenType.Ripperdoc)
    || !this.CRBioRegionAllowedForSelectedArea(this.crBioSelectedRegion)
    || !IsDefined(evt) || !evt.IsAction(n"click") || evt.IsHandled() {
    return false;
  }
  let target: wref<inkWidget> = evt.GetCurrentTarget();
  let kind: Int32;
  if target == this.crBioClinical {
    kind = 4;
  } else {
    if target == this.crBioMechanical {
      kind = 5;
    } else {
      return false;
    }
  }

  if CRProfessionalCareRuntime.Complete(this.crBioSelectedRegion, kind) {
    this.crBioActionStatus.SetText(kind == 4 ? "Clinical care completed. Biological recovery still takes body time." : "Cyberware repair completed for this region.");
  } else {
    this.crBioActionStatus.SetText("Professional care could not be completed. No injury state changed.");
  }
  this.CRRefreshBiologyActions();
  this.CRRefreshBiologyDetail();
  this.CRRefreshBiologyOverview();
  evt.Handle();
  return true;
}

@wrapMethod(RipperDocGameController)
protected cb func OnInitialize() -> Bool {
  let result: Bool = wrappedMethod();
  this.crBioPickerMode = 0;
  this.crBioSelectedRegion = 0;
  this.CRBioCreateActions();
  this.CRMountBiologyActionsInNativeContent();
  this.CRRefreshBiologyActions();
  return result;
}

@wrapMethod(RipperDocGameController)
protected cb func OnUninitialize() -> Bool {
  ArrayClear(this.crBioItemRows);
  ArrayClear(this.crBioItemIDs);
  ArrayClear(this.crBioConditionRows);
  this.crBioActionsPanel = null;
  this.crBioEat = null;
  this.crBioDrink = null;
  this.crBioConditionsHeading = null;
  this.crBioDress = null;
  this.crBioSupport = null;
  this.crBioClinical = null;
  this.crBioMechanical = null;
  this.crBioActionStatus = null;
  this.crBioPickerMode = 0;
  this.crBioSelectedRegion = 0;
  return wrappedMethod();
}
