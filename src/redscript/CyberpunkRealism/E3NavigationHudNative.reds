// Biology-owned framing on Cyberpunk 2.31's current native minimap host.
// Mappins/navigation stay native. W03.4 removes the attended root wash and uses compact
// chrome so the map remains readable rather than becoming one large red rectangle.
module CyberpunkRealism.Presentation

import CyberpunkRealism.Settings.*

@addField(MinimapContainerController)
private let crBiologyE3MinimapFrame: ref<inkCanvas>;

@addMethod(MinimapContainerController)
private final func CRCreateBiologyE3MinimapFrame() -> Void {
  if IsDefined(this.crBiologyE3MinimapFrame) {
    return;
  }
  let root: ref<inkCompoundWidget> = this.GetRootCompoundWidget();
  if !IsDefined(root) {
    return;
  }

  this.crBiologyE3MinimapFrame = CRBiologyE3Primitives.CreateFillShell(root, n"CRBiologyE3MinimapFrame");
  CRBiologyE3Primitives.AddPanelChrome(this.crBiologyE3MinimapFrame, "NAV // ROUTE", 172.0);
}

@addMethod(MinimapContainerController)
private final func CRRefreshBiologyE3MinimapFrame() -> Void {
  let enabled: Bool = CRRealpassSettings.UseE3FirstPersonHudVisuals(GetGameInstance());
  this.CRCreateBiologyE3MinimapFrame();
  if IsDefined(this.crBiologyE3MinimapFrame) {
    this.crBiologyE3MinimapFrame.SetVisible(enabled);
  }
}

@wrapMethod(MinimapContainerController)
protected cb func OnInitialize() -> Bool {
  let result: Bool = wrappedMethod();
  CRBiologyE3Primitives.Trace("MinimapContainerController.OnInitialize");
  this.CRRefreshBiologyE3MinimapFrame();
  return result;
}
