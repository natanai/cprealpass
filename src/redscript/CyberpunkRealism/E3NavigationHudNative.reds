// Biology-owned red/minimal navigation framing on Cyberpunk's native navigation host.
// Native route/mappin/navigation information remains authoritative. Biology only
// changes the persistent neutral-HUD visual language; scanner/quickhack is untouched.
module CyberpunkRealism.Presentation

import CyberpunkRealism.Settings.*

@addField(IronsightGameController)
private let crBiologyE3NavFrame: ref<inkCanvas>;

@addMethod(IronsightGameController)
private final func CRCreateBiologyE3NavFrame() -> Void {
  if IsDefined(this.crBiologyE3NavFrame) {
    return;
  }

  let root: ref<inkCompoundWidget> = this.GetRootCompoundWidget();
  if !IsDefined(root) {
    return;
  }

  this.crBiologyE3NavFrame = new inkCanvas();
  this.crBiologyE3NavFrame.SetName(n"CRBiologyE3NavFrame");
  this.crBiologyE3NavFrame.SetAnchor(inkEAnchor.TopRight);
  this.crBiologyE3NavFrame.SetHAlign(inkEHorizontalAlign.Right);
  this.crBiologyE3NavFrame.SetVAlign(inkEVerticalAlign.Top);
  this.crBiologyE3NavFrame.SetSize(Vector2(520.0, 286.0));
  this.crBiologyE3NavFrame.SetTranslation(-28.0, 28.0);
  this.crBiologyE3NavFrame.Reparent(root, -1);

  CRBiologyE3Primitives.AddRect(this.crBiologyE3NavFrame, n"CRBiologyE3NavTop", 74.0, 0.0, 420.0, 3.0, 0.92);
  CRBiologyE3Primitives.AddRect(this.crBiologyE3NavFrame, n"CRBiologyE3NavRight", 491.0, 0.0, 3.0, 180.0, 0.92);
  CRBiologyE3Primitives.AddRect(this.crBiologyE3NavFrame, n"CRBiologyE3NavBottom", 278.0, 180.0, 216.0, 3.0, 0.72);
  CRBiologyE3Primitives.AddRect(this.crBiologyE3NavFrame, n"CRBiologyE3NavAccent", 46.0, 0.0, 19.0, 7.0, 1.00);
  CRBiologyE3Primitives.AddRect(this.crBiologyE3NavFrame, n"CRBiologyE3NavTickA", 18.0, 0.0, 18.0, 3.0, 0.62);
}

@addMethod(IronsightGameController)
private final func CRRefreshBiologyE3NavFrame() -> Void {
  let enabled: Bool = CRRealpassSettings.UseE3FirstPersonHudVisuals(GetGameInstance());
  this.CRCreateBiologyE3NavFrame();
  CRBiologyE3Primitives.TintNeutralHudRoot(this.GetRootWidget(), enabled);
  if IsDefined(this.crBiologyE3NavFrame) {
    this.crBiologyE3NavFrame.SetVisible(enabled);
  }
}

@wrapMethod(IronsightGameController)
protected cb func OnPlayerAttach(playerPuppet: ref<GameObject>) -> Bool {
  let result: Bool = wrappedMethod(playerPuppet);
  this.CRRefreshBiologyE3NavFrame();
  return result;
}

@wrapMethod(IronsightGameController)
protected cb func OnCompassUpdate() -> Bool {
  let result: Bool = wrappedMethod();
  this.CRRefreshBiologyE3NavFrame();
  return result;
}
