// RealPass physicalizes Cyberpunk's vanilla Wardrobe/Outfit convenience.
//
// The stock wardrobe stores visual item identities and normally applies them as a
// parallel appearance override. That breaks RealPass' physical protection model:
// the player can see one jacket while a different item is actually equipped.
//
// RealPass therefore treats "Wear outfit" as a one-shot physical loadout request.
// The saved wardrobe TDBIDs are resolved to matching items the player ACTUALLY
// carries, then ordinary EquipmentSystemPlayerData equip/unequip transactions are
// used. No item is created, no stash is searched, and no visual-only set remains
// active after application. Missing/blocked items fail the request before any slot
// is changed. Quest wardrobe blocking and UnequipBlocked equipment are respected.
module CyberpunkRealism.Equipment

import CyberpunkRealism.Settings.*

public class CRPhysicalOutfitPolicy extends IScriptable {
  public static func Enabled() -> Bool {
    return CRRealpassSettings.IsEnabled(GetGameInstance());
  }

  public static func SupportsArea(area: gamedataEquipmentArea) -> Bool {
    return Equals(area, gamedataEquipmentArea.Head)
      || Equals(area, gamedataEquipmentArea.Face)
      || Equals(area, gamedataEquipmentArea.OuterChest)
      || Equals(area, gamedataEquipmentArea.InnerChest)
      || Equals(area, gamedataEquipmentArea.Legs)
      || Equals(area, gamedataEquipmentArea.Feet);
  }
}

@addMethod(EquipmentSystemPlayerData)
private func CRResolveOwnedPhysicalOutfitItem(storedVisual: ItemID, area: gamedataEquipmentArea) -> ItemID {
  let i: Int32;
  let itemData: wref<gameItemData>;
  let itemID: ItemID;
  let items: array<wref<gameItemData>>;
  let owner: wref<ScriptedPuppet> = this.GetOwner();
  let transactionSystem: ref<TransactionSystem>;

  if !IsDefined(owner) || !ItemID.IsValid(storedVisual) {
    return ItemID.None();
  }
  transactionSystem = GameInstance.GetTransactionSystem(owner.GetGame());
  if !IsDefined(transactionSystem) || !transactionSystem.GetItemList(owner, items) {
    return ItemID.None();
  }

  i = 0;
  while i < ArraySize(items) {
    itemData = items[i];
    if IsDefined(itemData) {
      itemID = itemData.GetID();
      if ItemID.IsValid(itemID)
        && Equals(ItemID.GetTDBID(itemID), ItemID.GetTDBID(storedVisual))
        && Equals(EquipmentSystem.GetEquipAreaType(itemID), area)
        && this.IsEquippable(itemData) {
        return itemID;
      }
    }
    i += 1;
  }
  return ItemID.None();
}

@addMethod(EquipmentSystemPlayerData)
private func CRPhysicalOutfitItemBlocksChange(itemID: ItemID) -> Bool {
  let data: wref<gameItemData>;
  let owner: wref<ScriptedPuppet> = this.GetOwner();
  if !ItemID.IsValid(itemID) || !IsDefined(owner) {
    return false;
  }
  data = GameInstance.GetTransactionSystem(owner.GetGame()).GetItemData(owner, itemID);
  return IsDefined(data) && data.HasTag(n"UnequipBlocked");
}

@addMethod(EquipmentSystemPlayerData)
private func CRCanApplyPhysicalOutfit(clothingSet: ref<ClothingSet>) -> Bool {
  let area: gamedataEquipmentArea;
  let current: ItemID;
  let i: Int32;
  let stored: ItemID;

  if !IsDefined(clothingSet) || ArraySize(clothingSet.clothingList) == 0 {
    return false;
  }

  // Respect a quest/special Outfit item before considering normal wardrobe slots.
  current = this.GetActiveItem(gamedataEquipmentArea.Outfit);
  if this.CRPhysicalOutfitItemBlocksChange(current) {
    return false;
  }

  i = 0;
  while i < ArraySize(clothingSet.clothingList) {
    area = clothingSet.clothingList[i].areaType;
    if CRPhysicalOutfitPolicy.SupportsArea(area) {
      current = this.GetActiveItem(area);
      if this.CRPhysicalOutfitItemBlocksChange(current) {
        return false;
      }
      stored = clothingSet.clothingList[i].visualItem;
      // A valid wardrobe visual is only actionable if the matching physical item is
      // in V's carried inventory right now. Wardrobe memory/stash ownership is not
      // enough and RealPass never materializes an item to satisfy a loadout.
      if ItemID.IsValid(stored) && !ItemID.IsValid(this.CRResolveOwnedPhysicalOutfitItem(stored, area)) {
        return false;
      }
    }
    i += 1;
  }
  return true;
}

@addMethod(EquipmentSystemPlayerData)
private func CRApplyPhysicalOutfit(clothingSet: ref<ClothingSet>) -> Void {
  let area: gamedataEquipmentArea;
  let current: ItemID;
  let i: Int32;
  let stored: ItemID;
  let target: ItemID;

  // Remove a normal one-piece Outfit item exactly as vanilla wardrobe application
  // does. CRCanApplyPhysicalOutfit already rejected an UnequipBlocked one.
  current = this.GetActiveItem(gamedataEquipmentArea.Outfit);
  if ItemID.IsValid(current) {
    this.UnequipItem(current);
  }

  i = 0;
  while i < ArraySize(clothingSet.clothingList) {
    area = clothingSet.clothingList[i].areaType;
    if CRPhysicalOutfitPolicy.SupportsArea(area) {
      stored = clothingSet.clothingList[i].visualItem;
      if ItemID.IsValid(stored) {
        target = this.CRResolveOwnedPhysicalOutfitItem(stored, area);
        if ItemID.IsValid(target) {
          this.EquipItem(target, false, false);
        }
      } else {
        // An intentionally empty saved wardrobe slot means an empty physical slot.
        current = this.GetActiveItem(area);
        if ItemID.IsValid(current) {
          this.UnequipItem(current);
        }
      }
      // Belt-and-suspenders: ensure this physical slot is not still carrying a
      // wardrobe appearance override from an earlier visual set.
      this.ClearVisuals(area);
    }
    i += 1;
  }

  // Outfits are now loadouts, not a persistent second appearance layer. Leaving the
  // WardrobeSystem active-set index INVALID ensures GetVisualItemInSlot falls back
  // to the actual equipped item after application.
  this.UpdateUIBBAreaChanged(gamedataEquipmentArea.Outfit, 0);
}

@wrapMethod(EquipmentSystemPlayerData)
public final func EquipWardrobeSet(setID: gameWardrobeClothingSetIndex) -> Void {
  let clothingSet: ref<ClothingSet>;

  if !CRPhysicalOutfitPolicy.Enabled() {
    wrappedMethod(setID);
    return;
  }

  // Preserve stock quest disable semantics. The wrapped method already knows how to
  // no-op safely while wardrobe use is blocked.
  if !this.IsWardrobeEnabled() {
    wrappedMethod(setID);
    return;
  }
  if Equals(setID, gameWardrobeClothingSetIndex.INVALID) {
    wrappedMethod(setID);
    return;
  }

  clothingSet = this.FindWardrobeClothingSetByID(setID);
  if !IsDefined(clothingSet) || ArraySize(clothingSet.clothingList) == 0 {
    wrappedMethod(setID);
    return;
  }

  // Fail atomically before changing physical equipment if even one requested real
  // item is unavailable or a current item is protected from unequip. Also clear any
  // previously active visual set so failure can never leave transmog authoritative.
  if !this.CRCanApplyPhysicalOutfit(clothingSet) {
    this.UnequipWardrobeSet();
    return;
  }

  this.UnequipWardrobeSet();
  this.CRApplyPhysicalOutfit(clothingSet);
}
