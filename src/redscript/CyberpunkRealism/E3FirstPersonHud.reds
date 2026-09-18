// Biology-owned lower-left E3-inspired presentation.
//
// The player health controller root remains alive under Biology; NoHealthbars hides only
// health-specific children. W03.3 therefore mounts a root-sized owned shell rather than
// a guessed 520x112 child canvas that could be clipped by the native local layout.
module CyberpunkRealism.Presentation

import CyberpunkRealism.Settings.*

@addField(healthbarWidgetGameController)
private let crBiologyE3HudFrame: ref<inkCanvas>;

@addMethod(healthbarWidgetGameController)
private final func CRCreateBiologyE3Hud() -> Void {
  if IsDefined(this.crBiologyE3HudFrame) {
    return;
  }

  let root: ref<inkCompoundWidget> = this.GetRootCompoundWidget();
  if !IsDefined(root) {
    return;
  }

  this.crBiologyE3HudFrame = CRBiologyE3Primitives.CreateFillShell(root, n"CRBiologyE3HudFrame");
  CRBiologyE3Primitives.AddFillWash(this.crBiologyE3HudFrame, n"CRBiologyE3HudWash", 0.025);
  CRBiologyE3Primitives.AddRect(this.crBiologyE3HudFrame, n"CRBiologyE3HudTopRail", 0.0, 0.0, 190.0, 3.0, 0.94);
  CRBiologyE3Primitives.AddRect(this.crBiologyE3HudFrame, n"CRBiologyE3HudLeftRail", 0.0, 0.0, 3.0, 46.0, 0.94);
  CRBiologyE3Primitives.AddRect(this.crBiologyE3HudFrame, n"CRBiologyE3HudAccent", 0.0, 0.0, 22.0, 7.0, 1.00);
  CRBiologyE3Primitives.AddLabel(this.crBiologyE3HudFrame, n"CRBiologyE3HudLabel", "BIOLOGY // STATUS", 30.0, 7.0, 13, 0.84);
}

@addMethod(healthbarWidgetGameController)
private final func CRRefreshBiologyE3Hud() -> Void {
  this.CRCreateBiologyE3Hud();
  if IsDefined(this.crBiologyE3HudFrame) {
    this.crBiologyE3HudFrame.SetVisible(CRRealpassSettings.UseE3FirstPersonHudVisuals(GetGameInstance()));
  }
}

@wrapMethod(healthbarWidgetGameController)
protected cb func OnInitialize() -> Bool {
  let result: Bool = wrappedMethod();
  CRBiologyE3Primitives.Trace("healthbarWidgetGameController.OnInitialize");
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
