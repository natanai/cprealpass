// Biology-owned E3-inspired ordinary interaction-prompt treatment.
//
// Project E3 replaced this controller's choice logic. Biology deliberately does not:
// native InteractionChoiceHubData, timing, spawning, input and visibility remain
// authoritative. W03.2 only adds a reversible red/minimal shell around the live prompt.
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

  this.crBiologyE3InteractionFrame = new inkCanvas();
  this.crBiologyE3InteractionFrame.SetName(n"CRBiologyE3InteractionFrame");
  this.crBiologyE3InteractionFrame.SetSize(Vector2(560.0, 210.0));
  this.crBiologyE3InteractionFrame.SetTranslation(-24.0, -16.0);
  this.crBiologyE3InteractionFrame.Reparent(root, -1);

  CRBiologyE3Primitives.AddPlate(this.crBiologyE3InteractionFrame, n"CRBiologyE3InteractionWash", 0.0, 0.0, 530.0, 176.0, 0.045);
  CRBiologyE3Primitives.AddRect(this.crBiologyE3InteractionFrame, n"CRBiologyE3InteractionLeft", 0.0, 0.0, 4.0, 154.0, 0.92);
  CRBiologyE3Primitives.AddRect(this.crBiologyE3InteractionFrame, n"CRBiologyE3InteractionTop", 0.0, 0.0, 388.0, 4.0, 0.92);
  CRBiologyE3Primitives.AddRect(this.crBiologyE3InteractionFrame, n"CRBiologyE3InteractionBottom", 0.0, 150.0, 220.0, 4.0, 0.70);
  CRBiologyE3Primitives.AddRect(this.crBiologyE3InteractionFrame, n"CRBiologyE3InteractionTick", 400.0, 0.0, 28.0, 4.0, 0.58);
  CRBiologyE3Primitives.AddLabel(this.crBiologyE3InteractionFrame, n"CRBiologyE3InteractionLabel", "INTERACTION", 12.0, 10.0, 13, 0.78);
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
  this.CRRefreshBiologyE3InteractionFrame();
  return result;
}

@wrapMethod(interactionWidgetGameController)
protected cb func OnUpdateInteraction(argValue: Variant) -> Bool {
  let result: Bool = wrappedMethod(argValue);
  this.CRRefreshBiologyE3InteractionFrame();
  return result;
}
