// Biology-owned E3-inspired ordinary interaction-prompt treatment.
//
// Native InteractionChoiceHubData, timing, option spawning, input and visibility remain
// authoritative. W03.3 makes the owned treatment root-sized so it follows the actual
// prompt layout instead of relying on a large translated child canvas.
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
  CRBiologyE3Primitives.AddFillWash(this.crBiologyE3InteractionFrame, n"CRBiologyE3InteractionWash", 0.075);
  CRBiologyE3Primitives.AddRect(this.crBiologyE3InteractionFrame, n"CRBiologyE3InteractionTop", 0.0, 0.0, 210.0, 4.0, 0.96);
  CRBiologyE3Primitives.AddRect(this.crBiologyE3InteractionFrame, n"CRBiologyE3InteractionLeft", 0.0, 0.0, 4.0, 58.0, 0.88);
  CRBiologyE3Primitives.AddRect(this.crBiologyE3InteractionFrame, n"CRBiologyE3InteractionAccent", 0.0, 0.0, 24.0, 9.0, 1.00);
  CRBiologyE3Primitives.AddLabel(this.crBiologyE3InteractionFrame, n"CRBiologyE3InteractionLabel", "INTERACTION // ACTION", 32.0, 8.0, 13, 0.84);
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
