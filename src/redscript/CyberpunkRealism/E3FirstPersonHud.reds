// Biology-owned E3-inspired first-person presentation.
//
// This layer is intentionally presentation-only. It decorates the existing lower-left
// biomonitor/HUD host with Biology-owned INK widgets and never restores a health meter,
// reads health values, or touches scanner/quickhack controllers. No Project E3 runtime
// code or assets are required.
module CyberpunkRealism.Presentation

import CyberpunkRealism.Settings.*

@addField(healthbarWidgetGameController)
private let crBiologyE3HudFrame: ref<inkCanvas>;

@addMethod(healthbarWidgetGameController)
private final func CRBiologyE3HudRect(name: CName, x: Float, y: Float, width: Float, height: Float, opacity: Float) -> ref<inkRectangle> {
  let widget: ref<inkRectangle> = new inkRectangle();
  widget.SetName(name);
  widget.SetSize(Vector2(width, height));
  widget.SetTranslation(x, y);
  widget.SetTintColor(new HDRColor(1.1761, 0.1400, 0.1200, 1.0));
  widget.SetOpacity(opacity);
  widget.Reparent(this.crBiologyE3HudFrame, -1);
  return widget;
}

@addMethod(healthbarWidgetGameController)
private final func CRCreateBiologyE3Hud() -> Void {
  if IsDefined(this.crBiologyE3HudFrame) {
    return;
  }

  let root: ref<inkCompoundWidget> = this.GetRootCompoundWidget();
  if !IsDefined(root) {
    return;
  }

  // A deliberately asymmetric red rail/bracket language makes the optional E3 skin
  // obvious in matched ON/OFF screenshots without representing any numeric body state.
  this.crBiologyE3HudFrame = new inkCanvas();
  this.crBiologyE3HudFrame.SetName(n"CRBiologyE3HudFrame");
  this.crBiologyE3HudFrame.SetAnchor(inkEAnchor.BottomLeft);
  this.crBiologyE3HudFrame.SetHAlign(inkEHorizontalAlign.Left);
  this.crBiologyE3HudFrame.SetVAlign(inkEVerticalAlign.Bottom);
  this.crBiologyE3HudFrame.SetSize(Vector2(520.0, 112.0));
  this.crBiologyE3HudFrame.Reparent(root, -1);

  this.CRBiologyE3HudRect(n"CRBiologyE3HudTopRail", 0.0, 0.0, 338.0, 3.0, 0.92);
  this.CRBiologyE3HudRect(n"CRBiologyE3HudLeftRail", 0.0, 0.0, 3.0, 76.0, 0.92);
  this.CRBiologyE3HudRect(n"CRBiologyE3HudLowerRail", 24.0, 76.0, 214.0, 3.0, 0.78);
  this.CRBiologyE3HudRect(n"CRBiologyE3HudAccent", 13.0, 14.0, 18.0, 7.0, 1.00);
  this.CRBiologyE3HudRect(n"CRBiologyE3HudTickA", 350.0, 0.0, 24.0, 3.0, 0.70);
  this.CRBiologyE3HudRect(n"CRBiologyE3HudTickB", 384.0, 0.0, 10.0, 3.0, 0.52);

  let label: ref<inkText> = new inkText();
  label.SetName(n"CRBiologyE3HudLabel");
  label.SetText("BIOLOGY");
  label.SetFontFamily("base\\gameplay\\gui\\fonts\\raj\\raj.inkfontfamily");
  label.SetFontStyle(n"Medium");
  label.SetFontSize(18);
  label.SetFitToContent(true);
  label.SetTranslation(40.0, 5.0);
  label.SetTintColor(new HDRColor(1.1761, 0.1400, 0.1200, 1.0));
  label.SetOpacity(0.96);
  label.Reparent(this.crBiologyE3HudFrame, -1);

  let sublabel: ref<inkText> = new inkText();
  sublabel.SetName(n"CRBiologyE3HudSublabel");
  sublabel.SetText("// PHYSIOLOGY");
  sublabel.SetFontFamily("base\\gameplay\\gui\\fonts\\raj\\raj.inkfontfamily");
  sublabel.SetFontStyle(n"Regular");
  sublabel.SetFontSize(13);
  sublabel.SetFitToContent(true);
  sublabel.SetTranslation(40.0, 29.0);
  sublabel.SetTintColor(new HDRColor(1.1761, 0.1400, 0.1200, 1.0));
  sublabel.SetOpacity(0.70);
  sublabel.Reparent(this.crBiologyE3HudFrame, -1);
}

@addMethod(healthbarWidgetGameController)
private final func CRRefreshBiologyE3Hud() -> Void {
  this.CRCreateBiologyE3Hud();
  if !IsDefined(this.crBiologyE3HudFrame) {
    return;
  }
  this.crBiologyE3HudFrame.SetVisible(CRRealpassSettings.UseE3FirstPersonHudVisuals(GetGameInstance()));
}

// These are already verified 2.31 biomonitor lifecycle seams used by Biology's
// independent barless-health presentation. Multiple wrappers compose; this file
// never calls the health-suppression helpers and the health policy never checks E3.
@wrapMethod(healthbarWidgetGameController)
protected cb func OnInitialize() -> Bool {
  let result: Bool = wrappedMethod();
  this.CRRefreshBiologyE3Hud();
  return result;
}

@wrapMethod(healthbarWidgetGameController)
protected cb func OnUpdateHealthBarVisibility() -> Bool {
  let result: Bool = wrappedMethod();
  this.CRRefreshBiologyE3Hud();
  return result;
}

@wrapMethod(healthbarWidgetGameController)
public final func EvaluateHealthBarVisibility(isInOverclockedState: Bool) -> Void {
  wrappedMethod(isInOverclockedState);
  this.CRRefreshBiologyE3Hud();
}
