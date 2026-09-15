// Biology-owned E3-inspired NPC nameplate treatment.
//
// Native identity/visibility rules remain authoritative. NameplatesNative.reds may
// supply an otherwise-missing scanned civilian display name; this file only adds a
// thin Biology-owned red frame to a nameplate that the native controller is already
// rendering. It never reads health values or owns scanner/quickhack UI.
module CyberpunkRealism.Presentation

import CyberpunkRealism.Settings.*

@addField(NameplateVisualsLogicController)
private let crBiologyE3NameplateFrame: ref<inkCanvas>;

@addMethod(NameplateVisualsLogicController)
private final func CRBiologyE3NameplateRect(name: CName, x: Float, y: Float, width: Float, height: Float, opacity: Float) -> ref<inkRectangle> {
  let widget: ref<inkRectangle> = new inkRectangle();
  widget.SetName(name);
  widget.SetSize(Vector2(width, height));
  widget.SetTranslation(x, y);
  widget.SetTintColor(new HDRColor(1.1761, 0.1400, 0.1200, 1.0));
  widget.SetOpacity(opacity);
  widget.Reparent(this.crBiologyE3NameplateFrame, -1);
  return widget;
}

@addMethod(NameplateVisualsLogicController)
private final func CRCreateBiologyE3Nameplate() -> Void {
  if IsDefined(this.crBiologyE3NameplateFrame) {
    return;
  }

  let root: ref<inkCompoundWidget> = this.GetRootCompoundWidget();
  if !IsDefined(root) {
    return;
  }

  this.crBiologyE3NameplateFrame = new inkCanvas();
  this.crBiologyE3NameplateFrame.SetName(n"CRBiologyE3NameplateFrame");
  this.crBiologyE3NameplateFrame.SetAnchor(inkEAnchor.Centered);
  this.crBiologyE3NameplateFrame.SetHAlign(inkEHorizontalAlign.Center);
  this.crBiologyE3NameplateFrame.SetVAlign(inkEVerticalAlign.Center);
  this.crBiologyE3NameplateFrame.SetSize(Vector2(360.0, 58.0));
  this.crBiologyE3NameplateFrame.Reparent(root, -1);

  // Open, asymmetric rails preserve the stock text and native state colors while
  // making the optional Biology presentation visibly different from vanilla.
  this.CRBiologyE3NameplateRect(n"CRBiologyE3NameplateTop", 0.0, 0.0, 252.0, 2.0, 0.94);
  this.CRBiologyE3NameplateRect(n"CRBiologyE3NameplateLeft", 0.0, 0.0, 2.0, 42.0, 0.94);
  this.CRBiologyE3NameplateRect(n"CRBiologyE3NameplateBottom", 22.0, 42.0, 148.0, 2.0, 0.78);
  this.CRBiologyE3NameplateRect(n"CRBiologyE3NameplateAccent", 265.0, 0.0, 20.0, 5.0, 1.00);
  this.CRBiologyE3NameplateRect(n"CRBiologyE3NameplateTick", 294.0, 0.0, 9.0, 2.0, 0.58);

  let label: ref<inkText> = new inkText();
  label.SetName(n"CRBiologyE3NameplateLabel");
  label.SetText("BIO // ID");
  label.SetFontFamily("base\\gameplay\\gui\\fonts\\raj\\raj.inkfontfamily");
  label.SetFontStyle(n"Regular");
  label.SetFontSize(12);
  label.SetFitToContent(true);
  label.SetTranslation(266.0, 9.0);
  label.SetTintColor(new HDRColor(1.1761, 0.1400, 0.1200, 1.0));
  label.SetOpacity(0.72);
  label.Reparent(this.crBiologyE3NameplateFrame, -1);
}

@addMethod(NameplateVisualsLogicController)
private final func CRRefreshBiologyE3Nameplate(puppet: ref<GameObject>) -> Void {
  this.CRCreateBiologyE3Nameplate();
  if !IsDefined(this.crBiologyE3NameplateFrame) {
    return;
  }

  let visible: Bool = IsDefined(puppet) && CRRealpassSettings.UseE3FirstPersonHudVisuals(puppet.GetGame());
  this.crBiologyE3NameplateFrame.SetVisible(visible);
}

@wrapMethod(NameplateVisualsLogicController)
public final func SetVisualData(puppet: ref<GameObject>, const incomingData: script_ref<NPCNextToTheCrosshair>, opt isNewNpc: Bool) -> Void {
  wrappedMethod(puppet, incomingData, isNewNpc);
  this.CRRefreshBiologyE3Nameplate(puppet);
}
