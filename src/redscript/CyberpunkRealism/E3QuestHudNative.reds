// Biology-owned E3-inspired quest/objective presentation.
// Native Journal/tracker logic remains authoritative. W03.3 fits the owned shell to
// the actual tracker root so the treatment cannot disappear outside a clipped local
// canvas as the attended 205578b1... candidate did.
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

  this.crBiologyE3QuestFrame = CRBiologyE3Primitives.CreateFillShell(root, n"CRBiologyE3QuestFrame");
  CRBiologyE3Primitives.AddFillWash(this.crBiologyE3QuestFrame, n"CRBiologyE3QuestWash", 0.080);
  CRBiologyE3Primitives.AddRect(this.crBiologyE3QuestFrame, n"CRBiologyE3QuestTop", 0.0, 0.0, 220.0, 4.0, 0.98);
  CRBiologyE3Primitives.AddRect(this.crBiologyE3QuestFrame, n"CRBiologyE3QuestLeft", 0.0, 0.0, 4.0, 64.0, 0.90);
  CRBiologyE3Primitives.AddRect(this.crBiologyE3QuestFrame, n"CRBiologyE3QuestAccent", 0.0, 0.0, 24.0, 9.0, 1.00);
  CRBiologyE3Primitives.AddLabel(this.crBiologyE3QuestFrame, n"CRBiologyE3QuestLabel", "OBJECTIVES // ACTIVE", 32.0, 8.0, 13, 0.86);
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
  CRBiologyE3Primitives.Trace("QuestTrackerGameController.OnInitialize");
  this.CRRefreshBiologyE3QuestFrame();
  return result;
}

@wrapMethod(QuestTrackerGameController)
private func UpdateTrackerData() -> Void {
  wrappedMethod();
  this.CRRefreshBiologyE3QuestFrame();
}
