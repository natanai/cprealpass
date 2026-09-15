// Keep every native hub doorway consistent: the existing Cyberware route remains
// technically intact, but Biology is the player-facing parent label while RealPass
// is enabled. The global master switch restores the stock Cyberware label.
module CyberpunkRealism.Presentation

import CyberpunkRealism.Settings.*

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
