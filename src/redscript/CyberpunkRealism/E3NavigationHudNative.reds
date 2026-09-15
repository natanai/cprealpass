// Biology-owned red/minimal framing on Cyberpunk 2.31's current native minimap host.
// Direct installed-game evidence on 2026-09-15 confirmed MinimapContainerController
// in cyberpunk/UI/widgets/minimap/minimap.script. Native minimap/mappin/navigation
// data remains authoritative; scanner/quickhack and weapon ironsight ownership stay untouched.
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
  this.crBiologyE3MinimapFrame.SetSize(Vector2(520.0, 286.0));
  this.crBiologyE3MinimapFrame.SetTranslation(-28.0, 28.0);
  this.crBiologyE3MinimapFrame.Reparent(root, -1);

  CRBiologyE3Primitives.AddRect(this.crBiologyE3MinimapFrame, n"CRBiologyE3MinimapTop", 74.0, 0.0, 420.0, 3.0, 0.92);
  CRBiologyE3Primitives.AddRect(this.crBiologyE3MinimapFrame, n"CRBiologyE3MinimapRight", 491.0, 0.0, 3.0, 180.0, 0.92);
  CRBiologyE3Primitives.AddRect(this.crBiologyE3MinimapFrame, n"CRBiologyE3MinimapBottom", 278.0, 180.0, 216.0, 3.0, 0.72);
  CRBiologyE3Primitives.AddRect(this.crBiologyE3MinimapFrame, n"CRBiologyE3MinimapAccent", 46.0, 0.0, 19.0, 7.0, 1.00);
  CRBiologyE3Primitives.AddRect(this.crBiologyE3MinimapFrame, n"CRBiologyE3MinimapTickA", 18.0, 0.0, 18.0, 3.0, 0.62);
}

@addMethod(MinimapContainerController)
private final func CRRefreshBiologyE3MinimapFrame() -> Void {
  let enabled: Bool = CRRealpassSettings.UseE3FirstPersonHudVisuals(GetGameInstance());
  this.CRCreateBiologyE3MinimapFrame();
  CRBiologyE3Primitives.TintNeutralHudRoot(this.GetRootWidget(), enabled);
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
