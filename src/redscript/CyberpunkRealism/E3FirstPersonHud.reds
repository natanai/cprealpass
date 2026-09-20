// Biology-owned lower-left E3-inspired presentation.
//
// W03.4 keeps this surface deliberately sparse. The attended W03.3 root wash produced
// a large red slab behind the native hotkey/biomonitor area; compact chrome now carries
// the same presentation language without pretending the whole controller is a panel.
//
// W20.3 deliberately creates the frame independent of the current preference value.
// The rejected autonomous release made creation conditional on an early saved-settings
// read and live testing showed the entire E3 surface could then remain absent.
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
  CRBiologyE3Primitives.AddPanelChrome(this.crBiologyE3HudFrame, "BIOLOGY", 146.0);
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

@addMethod(healthbarWidgetGameController)
protected cb func OnCRBiologyE3PreferenceChangedEvent(evt: ref<CRBiologyE3PreferenceChangedEvent>) -> Bool {
  this.CRRefreshBiologyE3Hud();
  return true;
}
