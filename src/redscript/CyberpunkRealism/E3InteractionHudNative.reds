// Biology-owned E3-inspired interaction/dialogue presentation.
// Native interaction and dialogue systems continue to create choices, timers, tags and
// actions; Biology contributes only a red/minimal visual shell on their current 2.31
// controllers. Scanner/quickhack surfaces are intentionally absent from this file.
module CyberpunkRealism.Presentation

import CyberpunkRealism.Settings.*

@addField(interactionWidgetGameController)
private let crBiologyE3InteractionFrame: ref<inkCanvas>;

@addMethod(interactionWidgetGameController)
private final func CRCreateBiologyE3InteractionFrame() -> Void {
  if IsDefined(this.crBiologyE3InteractionFrame) {
    return;
  }
  let root: ref<inkCompoundWidget> = this.GetRootWidget() as inkCompoundWidget;
  if !IsDefined(root) {
    return;
  }

  this.crBiologyE3InteractionFrame = new inkCanvas();
  this.crBiologyE3InteractionFrame.SetName(n"CRBiologyE3InteractionFrame");
  this.crBiologyE3InteractionFrame.SetAnchor(inkEAnchor.Centered);
  this.crBiologyE3InteractionFrame.SetHAlign(inkEHorizontalAlign.Center);
  this.crBiologyE3InteractionFrame.SetVAlign(inkEVerticalAlign.Center);
  this.crBiologyE3InteractionFrame.SetSize(Vector2(620.0, 178.0));
  this.crBiologyE3InteractionFrame.SetAffectsLayoutWhenHidden(false);
  this.crBiologyE3InteractionFrame.Reparent(root, -1);

  CRBiologyE3Primitives.AddRect(this.crBiologyE3InteractionFrame, n"CRBiologyE3InteractionLeft", 0.0, 18.0, 3.0, 122.0, 0.92);
  CRBiologyE3Primitives.AddRect(this.crBiologyE3InteractionFrame, n"CRBiologyE3InteractionTop", 0.0, 18.0, 274.0, 3.0, 0.92);
  CRBiologyE3Primitives.AddRect(this.crBiologyE3InteractionFrame, n"CRBiologyE3InteractionBottom", 0.0, 140.0, 164.0, 3.0, 0.68);
  CRBiologyE3Primitives.AddRect(this.crBiologyE3InteractionFrame, n"CRBiologyE3InteractionAccent", 287.0, 18.0, 22.0, 6.0, 1.00);
  CRBiologyE3Primitives.AddLabel(this.crBiologyE3InteractionFrame, n"CRBiologyE3InteractionLabel", "ACTION // INPUT", 18.0, 29.0, 12, 0.72);
}

@addMethod(interactionWidgetGameController)
private final func CRRefreshBiologyE3InteractionFrame() -> Void {
  this.CRCreateBiologyE3InteractionFrame();
  if IsDefined(this.crBiologyE3InteractionFrame) {
    this.crBiologyE3InteractionFrame.SetVisible(CRRealpassSettings.UseE3FirstPersonHudVisuals(GetGameInstance()));
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

@addField(DialogChoiceLogicController)
private let crBiologyE3DialogRail: ref<inkCanvas>;

@addMethod(DialogChoiceLogicController)
private final func CRCreateBiologyE3DialogRail() -> Void {
  if IsDefined(this.crBiologyE3DialogRail) {
    return;
  }
  let root: ref<inkCompoundWidget> = this.GetRootWidget() as inkCompoundWidget;
  if !IsDefined(root) {
    return;
  }

  this.crBiologyE3DialogRail = new inkCanvas();
  this.crBiologyE3DialogRail.SetName(n"CRBiologyE3DialogRail");
  this.crBiologyE3DialogRail.SetAnchor(inkEAnchor.CenterLeft);
  this.crBiologyE3DialogRail.SetHAlign(inkEHorizontalAlign.Left);
  this.crBiologyE3DialogRail.SetVAlign(inkEVerticalAlign.Center);
  this.crBiologyE3DialogRail.SetSize(Vector2(38.0, 70.0));
  this.crBiologyE3DialogRail.SetTranslation(-18.0, 0.0);
  this.crBiologyE3DialogRail.SetAffectsLayoutWhenHidden(false);
  this.crBiologyE3DialogRail.Reparent(root, -1);

  CRBiologyE3Primitives.AddRect(this.crBiologyE3DialogRail, n"CRBiologyE3DialogLeft", 0.0, 8.0, 3.0, 54.0, 0.92);
  CRBiologyE3Primitives.AddRect(this.crBiologyE3DialogRail, n"CRBiologyE3DialogTop", 0.0, 8.0, 28.0, 3.0, 0.92);
  CRBiologyE3Primitives.AddRect(this.crBiologyE3DialogRail, n"CRBiologyE3DialogTick", 12.0, 55.0, 16.0, 3.0, 0.64);
}

@addMethod(DialogChoiceLogicController)
private final func CRRefreshBiologyE3DialogRail() -> Void {
  this.CRCreateBiologyE3DialogRail();
  if IsDefined(this.crBiologyE3DialogRail) {
    this.crBiologyE3DialogRail.SetVisible(CRRealpassSettings.UseE3FirstPersonHudVisuals(GetGameInstance()));
  }
}

@wrapMethod(DialogChoiceLogicController)
protected cb func OnInitialize() -> Bool {
  let result: Bool = wrappedMethod();
  this.CRRefreshBiologyE3DialogRail();
  return result;
}

@wrapMethod(DialogChoiceLogicController)
private func UpdateColors() -> Void {
  wrappedMethod();
  this.CRRefreshBiologyE3DialogRail();
}
