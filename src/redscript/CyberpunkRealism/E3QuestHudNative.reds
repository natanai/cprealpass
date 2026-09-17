// Biology-owned E3-inspired quest/objective presentation.
// Native Journal and quest-tracker data remain authoritative; Biology adds a
// materially visible, reversible red/minimal shell around the current tracker.
module CyberpunkRealism.Presentation

import CyberpunkRealism.Settings.*

@addField(QuestTrackerGameController)
private let crBiologyE3QuestFrame: ref<inkCanvas>;

@addMethod(QuestTrackerGameController)
private final func CRCreateBiologyE3QuestFrame() -> Void {
  if IsDefined(this.crBiologyE3QuestFrame) {
    return;
  }
  let root: ref<inkCompoundWidget> = this.GetRootCompoundWidget();
  if !IsDefined(root) {
    return;
  }

  this.crBiologyE3QuestFrame = new inkCanvas();
  this.crBiologyE3QuestFrame.SetName(n"CRBiologyE3QuestFrame");
  this.crBiologyE3QuestFrame.SetAnchor(inkEAnchor.TopRight);
  this.crBiologyE3QuestFrame.SetHAlign(inkEHorizontalAlign.Right);
  this.crBiologyE3QuestFrame.SetVAlign(inkEVerticalAlign.Top);
  this.crBiologyE3QuestFrame.SetSize(Vector2(530.0, 286.0));
  this.crBiologyE3QuestFrame.SetTranslation(-8.0, 0.0);
  this.crBiologyE3QuestFrame.Reparent(root, -1);

  CRBiologyE3Primitives.AddPlate(this.crBiologyE3QuestFrame, n"CRBiologyE3QuestWash", 36.0, 0.0, 470.0, 250.0, 0.055);
  CRBiologyE3Primitives.AddRect(this.crBiologyE3QuestFrame, n"CRBiologyE3QuestTop", 74.0, 0.0, 432.0, 4.0, 0.98);
  CRBiologyE3Primitives.AddRect(this.crBiologyE3QuestFrame, n"CRBiologyE3QuestRight", 502.0, 0.0, 4.0, 224.0, 0.98);
  CRBiologyE3Primitives.AddRect(this.crBiologyE3QuestFrame, n"CRBiologyE3QuestBottom", 286.0, 224.0, 220.0, 4.0, 0.78);
  CRBiologyE3Primitives.AddRect(this.crBiologyE3QuestFrame, n"CRBiologyE3QuestAccent", 42.0, 0.0, 22.0, 9.0, 1.00);
  CRBiologyE3Primitives.AddRect(this.crBiologyE3QuestFrame, n"CRBiologyE3QuestTick", 14.0, 0.0, 18.0, 4.0, 0.58);
  CRBiologyE3Primitives.AddLabel(this.crBiologyE3QuestFrame, n"CRBiologyE3QuestLabel", "OBJECTIVES", 74.0, 8.0, 14, 0.82);
}

@addMethod(QuestTrackerGameController)
private final func CRRefreshBiologyE3QuestFrame() -> Void {
  let enabled: Bool = CRRealpassSettings.UseE3FirstPersonHudVisuals(GetGameInstance());
  this.CRCreateBiologyE3QuestFrame();
  if IsDefined(this.crBiologyE3QuestFrame) {
    this.crBiologyE3QuestFrame.SetVisible(enabled);
  }
}

@wrapMethod(QuestTrackerGameController)
protected cb func OnInitialize() -> Bool {
  let result: Bool = wrappedMethod();
  this.CRRefreshBiologyE3QuestFrame();
  return result;
}

@wrapMethod(QuestTrackerGameController)
private func UpdateTrackerData() -> Void {
  wrappedMethod();
  this.CRRefreshBiologyE3QuestFrame();
}
