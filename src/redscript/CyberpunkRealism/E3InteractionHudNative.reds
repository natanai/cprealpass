// Biology-owned E3-inspired ordinary interaction treatment.
//
// Native choices, timers, spawn lifecycle and input remain authoritative. W03.4 removes
// the full-root wash and keeps only compact chrome, so prompts participate in the same
// visual language without becoming another large opaque red panel.
module CyberpunkRealism.Presentation

import CyberpunkRealism.Settings.*

@addField(interactionWidgetGameController)
private let crBiologyE3InteractionFrame: ref<inkCanvas>;

@addMethod(interactionWidgetGameController)
private final func CRCreateBiologyE3InteractionFrame() -> Void {
  if IsDefined(this.crBiologyE3InteractionFrame) {
    return;
  }
  let root: ref<inkCompoundWidget> = this.GetRootCompoundWidget();
  if !IsDefined(root) {
    return;
  }

  this.crBiologyE3InteractionFrame = CRBiologyE3Primitives.CreateFillShell(root, n"CRBiologyE3InteractionFrame");
  CRBiologyE3Primitives.AddPanelChrome(this.crBiologyE3InteractionFrame, "INTERACTION", 168.0);
}

@addMethod(interactionWidgetGameController)
private final func CRRefreshBiologyE3InteractionFrame() -> Void {
  let enabled: Bool = CRRealpassSettings.UseE3FirstPersonHudVisuals(GetGameInstance());
  this.CRCreateBiologyE3InteractionFrame();
  if IsDefined(this.crBiologyE3InteractionFrame) {
    this.crBiologyE3InteractionFrame.SetVisible(enabled);
  }
}

@wrapMethod(interactionWidgetGameController)
protected cb func OnInitialize() -> Bool {
  let result: Bool = wrappedMethod();
  CRBiologyE3Primitives.Trace("interactionWidgetGameController.OnInitialize");
  this.CRRefreshBiologyE3InteractionFrame();
  return result;
}

@wrapMethod(interactionWidgetGameController)
protected cb func OnUpdateInteraction(argValue: Variant) -> Bool {
  let result: Bool = wrappedMethod(argValue);
  this.CRRefreshBiologyE3InteractionFrame();
  return result;
}

@addMethod(interactionWidgetGameController)
protected cb func OnCRBiologyE3PreferenceChangedEvent(evt: ref<CRBiologyE3PreferenceChangedEvent>) -> Bool {
  this.CRRefreshBiologyE3InteractionFrame();
  return true;
}
