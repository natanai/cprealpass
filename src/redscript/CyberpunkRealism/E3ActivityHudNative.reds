// Biology-owned E3-inspired transient activity-log treatment.
//
// The native activity-log queue and animation lifecycle remain authoritative. Biology
// only gives each newly initialized ordinary activity entry the shared red/uppercase
// presentation while E3 presentation is enabled.
module CyberpunkRealism.Presentation

import CyberpunkRealism.Settings.*

@wrapMethod(activityLogEntryLogicController)
protected cb func OnInitialize() -> Bool {
  let result: Bool = wrappedMethod();
  let root: ref<inkText> = this.GetRootWidget() as inkText;

  if CRRealpassSettings.UseE3FirstPersonHudVisuals(GetGameInstance()) && IsDefined(root) {
    root.SetLetterCase(textLetterCase.UpperCase);
    root.SetFontStyle(n"Medium");
    root.SetTintColor(CRBiologyE3Primitives.Red());
  }

  return result;
}
