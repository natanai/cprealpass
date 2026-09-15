// Player-facing Biology label at the actual stock menu-button render boundary.
// Keep Cyberware's identifier, icon and fullscreen route untouched; only its visible
// label changes. Wrapping the button controllers is more reliable than re-running a
// particular hub controller's SetMenusData after the stock layout has already bound
// multiple menu representations.
module CyberpunkRealism.Presentation

@wrapMethod(MenuItemController)
public final func Init(const menuData: script_ref<MenuData>) -> Void {
  wrappedMethod(menuData);
  if Deref(menuData).identifier == EnumInt(HubMenuItems.Cyberware) {
    this.m_menuData.label = "BIOLOGY";
    inkTextRef.SetText(this.m_label, "BIOLOGY");
  }
}

@wrapMethod(RadialMenuItemController)
public final func Init(const menuData: script_ref<MenuData>) -> Void {
  wrappedMethod(menuData);
  if Deref(menuData).identifier == EnumInt(HubMenuItems.Cyberware) {
    this.m_menuData.label = "BIOLOGY";
    inkTextRef.SetText(this.m_label, "BIOLOGY");
  }
}
