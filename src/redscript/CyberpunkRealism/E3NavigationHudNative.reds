// Biology-owned red/minimal framing on Cyberpunk 2.31's current native minimap host.
// Native minimap/mappin/navigation data remains authoritative. Biology does not restore
// Project E3's historical compass system or touch scanner/quickhack ownership.
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

  this.crBiologyE3MinimapFrame = new inkCanvas();
  this.crBiologyE3MinimapFrame.SetName(n"CRBiologyE3MinimapFrame");
  this.crBiologyE3MinimapFrame.SetAnchor(inkEAnchor.TopRight);
  this.crBiologyE3MinimapFrame.SetHAlign(inkEHorizontalAlign.Right);
  this.crBiologyE3MinimapFrame.SetVAlign(inkEVerticalAlign.Top);
  this.crBiologyE3MinimapFrame.SetSize(Vector2(552.0, 312.0));
  this.crBiologyE3MinimapFrame.SetTranslation(-20.0, 20.0);
  this.crBiologyE3MinimapFrame.Reparent(root, -1);

  CRBiologyE3Primitives.AddPlate(this.crBiologyE3MinimapFrame, n"CRBiologyE3MinimapWash", 34.0, 0.0, 492.0, 212.0, 0.048);
  CRBiologyE3Primitives.AddRect(this.crBiologyE3MinimapFrame, n"CRBiologyE3MinimapTop", 68.0, 0.0, 458.0, 4.0, 0.98);
  CRBiologyE3Primitives.AddRect(this.crBiologyE3MinimapFrame, n"CRBiologyE3MinimapRight", 522.0, 0.0, 4.0, 196.0, 0.98);
  CRBiologyE3Primitives.AddRect(this.crBiologyE3MinimapFrame, n"CRBiologyE3MinimapBottom", 304.0, 196.0, 222.0, 4.0, 0.78);
  CRBiologyE3Primitives.AddRect(this.crBiologyE3MinimapFrame, n"CRBiologyE3MinimapAccent", 38.0, 0.0, 21.0, 9.0, 1.00);
  CRBiologyE3Primitives.AddRect(this.crBiologyE3MinimapFrame, n"CRBiologyE3MinimapTickA", 10.0, 0.0, 18.0, 4.0, 0.58);
  CRBiologyE3Primitives.AddLabel(this.crBiologyE3MinimapFrame, n"CRBiologyE3MinimapLabel", "NAV // ROUTE", 68.0, 8.0, 14, 0.82);
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
  this.CRRefreshBiologyE3MinimapFrame();
  return result;
}
