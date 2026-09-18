// Biology-owned E3-inspired transient activity-log treatment.
//
// Native activity queue, typing timing and disappearance animation remain authoritative.
// Biology only changes the current entry text color while the E3 presentation preference
// is on, restoring the captured native tint when it is off.
module CyberpunkRealism.Presentation

import CyberpunkRealism.Settings.*

@addField(activityLogEntryLogicController)
private let crBiologyE3NativeActivityTint: HDRColor;

@addField(activityLogEntryLogicController)
private let crBiologyE3HasNativeActivityTint: Bool;

@addMethod(activityLogEntryLogicController)
private final func CRRefreshBiologyE3Activity() -> Void {
  let root: ref<inkText> = this.GetRootWidget() as inkText;
  if !IsDefined(root) {
    return;
  }

  if CRRealpassSettings.UseE3FirstPersonHudVisuals(GetGameInstance()) {
    root.SetLetterCase(textLetterCase.UpperCase);
    root.SetTintColor(CRBiologyE3Primitives.Red());
  } else {
    if this.crBiologyE3HasNativeActivityTint {
      root.SetTintColor(this.crBiologyE3NativeActivityTint);
    }
  }
}

@wrapMethod(activityLogEntryLogicController)
protected cb func OnInitialize() -> Bool {
  let result: Bool = wrappedMethod();
  let root: ref<inkText> = this.GetRootWidget() as inkText;

  if IsDefined(root) {
    this.crBiologyE3NativeActivityTint = root.GetTintColor();
    this.crBiologyE3HasNativeActivityTint = true;
  }

  CRBiologyE3Primitives.Trace("activityLogEntryLogicController.OnInitialize");
  this.CRRefreshBiologyE3Activity();
  return result;
}

@wrapMethod(activityLogEntryLogicController)
public final func SetText(const displayText: script_ref<String>) -> Void {
  wrappedMethod(displayText);
  this.CRRefreshBiologyE3Activity();
}
