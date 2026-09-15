// Biology-owned E3-inspired quest/objective presentation.
// Native Journal and quest-tracker data remain authoritative; this adapter adds a
// coherent red/minimal shell after native tracker updates instead of replacing the
// large quest data/update implementation used by the historical reference mod.
module CyberpunkRealism.Presentation

import CyberpunkRealism.Settings.*

@addField(QuestTrackerGameController)
private let crBiologyE3QuestFrame: ref<inkCanvas>;

@addMethod(QuestTrackerGameController)
private final func CRCreateBiologyE3QuestFrame() -> Void {
  if IsDefined(this.crBiologyE3QuestFrame) {
    return;
  }
  let root: ref<inkCompoundWidget> = this.GetRootWidget() as inkCompoundWidget;
  if !IsDefined(root) {
    return;
  }

  this.crBiologyE3QuestFrame = new inkCanvas();
  this.crBiologyE3QuestFrame.SetName(n"CRBiologyE3QuestFrame");
  this.crBiologyE3QuestFrame.SetAnchor(inkEAnchor.TopRight);
  this.crBiologyE3QuestFrame.SetHAlign(inkEHorizontalAlign.Right);
  this.crBiologyE3QuestFrame.SetVAlign(inkEVerticalAlign.Top);
  this.crBiologyE3QuestFrame.SetSize(Vector2(500.0, 258.0));
  this.crBiologyE3QuestFrame.SetTranslation(-10.0, 0.0);
  this.crBiologyE3QuestFrame.SetAffectsLayoutWhenHidden(false);
  this.crBiologyE3QuestFrame.Reparent(root, -1);

  CRBiologyE3Primitives.AddRect(this.crBiologyE3QuestFrame, n"CRBiologyE3QuestTop", 96.0, 0.0, 378.0, 3.0, 0.90);
  CRBiologyE3Primitives.AddRect(this.crBiologyE3QuestFrame, n"CRBiologyE3QuestRight", 471.0, 0.0, 3.0, 214.0, 0.90);
  CRBiologyE3Primitives.AddRect(this.crBiologyE3QuestFrame, n"CRBiologyE3QuestBottom", 250.0, 214.0, 224.0, 3.0, 0.68);
  CRBiologyE3Primitives.AddRect(this.crBiologyE3QuestFrame, n"CRBiologyE3QuestAccent", 67.0, 0.0, 20.0, 7.0, 1.00);
  CRBiologyE3Primitives.AddLabel(this.crBiologyE3QuestFrame, n"CRBiologyE3QuestLabel", "OBJECTIVE // ACTIVE", 244.0, 9.0, 13, 0.82);
}

@addMethod(QuestTrackerGameController)
private final func CRRefreshBiologyE3QuestFrame() -> Void {
  this.CRCreateBiologyE3QuestFrame();
  if IsDefined(this.crBiologyE3QuestFrame) {
    this.crBiologyE3QuestFrame.SetVisible(CRRealpassSettings.UseE3FirstPersonHudVisuals(GetGameInstance()));
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
