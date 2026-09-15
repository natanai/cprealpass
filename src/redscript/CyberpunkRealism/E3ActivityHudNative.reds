// Biology-owned E3-inspired activity-log accent.
// Entry content/lifetime remains native; the old Project E3 replacement animation is
// not copied. New native entries simply receive the shared red/minimal visual language.
module CyberpunkRealism.Presentation

import CyberpunkRealism.Settings.*

@addField(activityLogEntryLogicController)
private let crBiologyE3ActivityFrame: ref<inkCanvas>;

@addMethod(activityLogEntryLogicController)
private final func CRCreateBiologyE3ActivityFrame() -> Void {
  if IsDefined(this.crBiologyE3ActivityFrame) {
    return;
  }
  let root: ref<inkCompoundWidget> = this.GetRootWidget() as inkCompoundWidget;
  if !IsDefined(root) {
    return;
  }

  this.crBiologyE3ActivityFrame = new inkCanvas();
  this.crBiologyE3ActivityFrame.SetName(n"CRBiologyE3ActivityFrame");
  this.crBiologyE3ActivityFrame.SetAnchor(inkEAnchor.CenterLeft);
  this.crBiologyE3ActivityFrame.SetHAlign(inkEHorizontalAlign.Left);
  this.crBiologyE3ActivityFrame.SetVAlign(inkEVerticalAlign.Center);
  this.crBiologyE3ActivityFrame.SetSize(Vector2(470.0, 64.0));
  this.crBiologyE3ActivityFrame.SetTranslation(-10.0, 0.0);
  this.crBiologyE3ActivityFrame.SetAffectsLayoutWhenHidden(false);
  this.crBiologyE3ActivityFrame.Reparent(root, -1);

  CRBiologyE3Primitives.AddRect(this.crBiologyE3ActivityFrame, n"CRBiologyE3ActivityLeft", 0.0, 7.0, 3.0, 42.0, 0.88);
  CRBiologyE3Primitives.AddRect(this.crBiologyE3ActivityFrame, n"CRBiologyE3ActivityTop", 0.0, 7.0, 118.0, 3.0, 0.82);
  CRBiologyE3Primitives.AddRect(this.crBiologyE3ActivityFrame, n"CRBiologyE3ActivityTick", 128.0, 7.0, 18.0, 3.0, 0.56);
  CRBiologyE3Primitives.AddLabel(this.crBiologyE3ActivityFrame, n"CRBiologyE3ActivityLabel", "LOG", 12.0, 15.0, 11, 0.64);
}

@addMethod(activityLogEntryLogicController)
private final func CRRefreshBiologyE3ActivityFrame() -> Void {
  this.CRCreateBiologyE3ActivityFrame();
  if IsDefined(this.crBiologyE3ActivityFrame) {
    this.crBiologyE3ActivityFrame.SetVisible(CRRealpassSettings.UseE3FirstPersonHudVisuals(GetGameInstance()));
  }
}

@wrapMethod(activityLogEntryLogicController)
protected cb func OnInitialize() -> Bool {
  let result: Bool = wrappedMethod();
  this.CRRefreshBiologyE3ActivityFrame();
  return result;
}
