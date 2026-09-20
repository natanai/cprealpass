// Keep every native menu doorway consistent: Cyberpunk's existing cyberware_equip
// route remains intact, but Biology is the player-facing parent destination while
// Biology is enabled. CYBERWARE is reserved for the internal equipment submode.
module CyberpunkRealism.Presentation

import CyberpunkRealism.Settings.*

@addMethod(MenuDataBuilder)
public final func CRRelabelBiologyDestination() -> Void {
  let i: Int32 = 0;
  while i < ArraySize(this.m_data) {
    if this.m_data[i].identifier == EnumInt(HubMenuItems.Cyberware) {
      this.m_data[i].label = "BIOLOGY";
    }
    i += 1;
  }
}

// Relabel the canonical menu data at its source so every standard navigation strip
// consuming HubMenuUtility data sees BIOLOGY, rather than repairing only one rendered
// hub button after the builder has already propagated the stock CYBERWARE label.
@wrapMethod(HubMenuUtility)
public static func CreateMenuData(player: wref<PlayerPuppet>) -> ref<MenuDataBuilder> {
  let data: ref<MenuDataBuilder> = wrappedMethod(player);
  if IsDefined(data) && CRRealpassSettings.IsEnabled(GetGameInstance()) {
    data.CRRelabelBiologyDestination();
  }
  return data;
}

// Inventory builds its adjacent navigation hyperlink directly instead of consuming
// the shared MenuDataBuilder label. Reinitialize only that existing native button;
// the identifier/fullscreen route stays Cyberpunk's stock cyberware_equip path.
@wrapMethod(gameuiInventoryGameController)
protected cb func OnSetUserData(userData: ref<IScriptable>) -> Bool {
  let result: Bool = wrappedMethod(userData);
  if !CRRealpassSettings.IsEnabled(GetGameInstance()) {
    return result;
  }

  let controller: ref<MenuItemController> = inkWidgetRef.GetController(this.m_btnCyberware) as MenuItemController;
  if IsDefined(controller) {
    let data: MenuData;
    data.label = "BIOLOGY";
    data.icon = n"ico_deck_hub";
    data.fullscreenName = n"cyberware_equip";
    data.identifier = EnumInt(HubMenuItems.Cyberware);
    data.parentIdentifier = EnumInt(HubMenuItems.Inventory);
    controller.Init(data);
    controller.SetHyperlink(true);
  }
  return result;
}

@wrapMethod(RadialMenuHubLogicController)
public final func SetMenusData(menuData: ref<MenuDataBuilder>, tarotIsBlocked: Bool, mapIsBlocked: Bool, perkPoints: Int32, attrPoints: Int32) -> Void {
  wrappedMethod(menuData, tarotIsBlocked, mapIsBlocked, perkPoints, attrPoints);
  if !CRRealpassSettings.IsEnabled(GetGameInstance()) {
    return;
  }
  let biologyData: MenuData = menuData.GetData(EnumInt(HubMenuItems.Cyberware));
  biologyData.label = "BIOLOGY";
  HubMenuUtils.SetRadialMenuData(this.m_btnCyberware, biologyData);
}
