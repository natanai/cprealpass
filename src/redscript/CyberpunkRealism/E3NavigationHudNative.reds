// Biology-owned red/minimal framing on Cyberpunk 2.31's current native minimap host.
// Native minimap/mappin/navigation data remains authoritative; scanner/quickhack and
// historical Project E3 compass ownership remain untouched.
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
  CRBiologyE3Primitives.AddFillWash(this.crBiologyE3MinimapFrame, n"CRBiologyE3MinimapWash", 0.060);
  CRBiologyE3Primitives.AddRect(this.crBiologyE3MinimapFrame, n"CRBiologyE3MinimapTop", 0.0, 0.0, 190.0, 4.0, 0.96);
  CRBiologyE3Primitives.AddRect(this.crBiologyE3MinimapFrame, n"CRBiologyE3MinimapLeft", 0.0, 0.0, 4.0, 56.0, 0.86);
  CRBiologyE3Primitives.AddRect(this.crBiologyE3MinimapFrame, n"CRBiologyE3MinimapAccent", 0.0, 0.0, 22.0, 9.0, 1.00);
  CRBiologyE3Primitives.AddLabel(this.crBiologyE3MinimapFrame, n"CRBiologyE3MinimapLabel", "NAV // ROUTE", 30.0, 8.0, 13, 0.84);
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
