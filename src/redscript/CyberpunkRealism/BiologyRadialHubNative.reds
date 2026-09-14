// Keep every native hub doorway consistent: the existing Cyberware route remains
// technically intact, but Biology is the player-facing parent label.
module CyberpunkRealism.Presentation

@wrapMethod(RadialMenuHubLogicController)
public final func SetMenusData(menuData: ref<MenuDataBuilder>, tarotIsBlocked: Bool, mapIsBlocked: Bool, perkPoints: Int32, attrPoints: Int32) -> Void {
  wrappedMethod(menuData, tarotIsBlocked, mapIsBlocked, perkPoints, attrPoints);
  let biologyData: MenuData = menuData.GetData(Cast<Int32>(HubMenuItems.Cyberware));
  biologyData.label = "BIOLOGY";
  HubMenuUtils.SetRadialMenuData(this.m_btnCyberware, biologyData);
}
