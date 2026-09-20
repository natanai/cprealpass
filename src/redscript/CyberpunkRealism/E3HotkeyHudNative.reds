// Biology-owned E3-inspired D-pad/quick-slot presentation.
//
// T004 disproved HotkeysWidgetController.GetRootCompoundWidget() as the authored
// quickslot coordinate space. Current 2.31 native code spawns consumable, gadget,
// cyberware, leeroy, and time-bank children directly into m_dpadHintsPanel. W03.6
// mounts segmented chrome only in that semantic panel and leaves phone/car/radio
// siblings untouched, eliminating the controller-root overlap seen in the live crop.
module CyberpunkRealism.Presentation

import CyberpunkRealism.Settings.*

@addField(HotkeysWidgetController)
private let crBiologyE3HotkeyFrame: ref<inkCanvas>;

@addField(HotkeysWidgetController)
private let crBiologyE3HotkeyHost: ref<inkCompoundWidget>;

@addField(HotkeysWidgetController)
private let crBiologyE3HotkeyHostName: String;

@addField(HotkeysWidgetController)
private let crBiologyE3HotkeyStateKnown: Bool;

@addField(HotkeysWidgetController)
private let crBiologyE3HotkeyLastEnabled: Bool;

@addMethod(HotkeysWidgetController)
private final func CRResolveBiologyE3HotkeyHost() -> ref<inkCompoundWidget> {
  let host: ref<inkCompoundWidget> = inkCompoundRef.Get(this.m_dpadHintsPanel) as inkCompoundWidget;
  if IsDefined(host) {
    this.crBiologyE3HotkeyHostName = "m_dpadHintsPanel";
    return host;
  }

  this.crBiologyE3HotkeyHostName = "UNRESOLVED";
  return host;
}

@addMethod(HotkeysWidgetController)
private final func CRCreateBiologyE3HotkeyFrame() -> Void {
  if IsDefined(this.crBiologyE3HotkeyFrame) {
    return;
  }

  this.crBiologyE3HotkeyHost = this.CRResolveBiologyE3HotkeyHost();
  if !IsDefined(this.crBiologyE3HotkeyHost) {
    CRBiologyE3Primitives.Trace("Hotkeys content-host unresolved; chrome not mounted");
    return;
  }

  this.crBiologyE3HotkeyFrame = CRBiologyE3Primitives.CreateFillShell(this.crBiologyE3HotkeyHost, n"CRBiologyE3HotkeyFrame");
  CRBiologyE3Primitives.AddSegmentedRegionChrome(this.crBiologyE3HotkeyFrame);
}

@addMethod(HotkeysWidgetController)
private final func CRRefreshBiologyE3HotkeyFrame() -> Void {
  let enabled: Bool = CRRealpassSettings.UseE3FirstPersonHudVisuals(GetGameInstance());

  // Always resolve/create the native-hosted frame when the controller exists. Visibility
  // is the preference. This avoids the rejected autonomous lazy-create startup failure.
  this.CRCreateBiologyE3HotkeyFrame();

  if IsDefined(this.crBiologyE3HotkeyFrame) {
    this.crBiologyE3HotkeyFrame.SetVisible(enabled);
  }

  if !this.crBiologyE3HotkeyStateKnown
    || (this.crBiologyE3HotkeyLastEnabled && !enabled)
    || (!this.crBiologyE3HotkeyLastEnabled && enabled) {
    CRBiologyE3Primitives.TraceMountedRegion(
      "Hotkeys",
      this.crBiologyE3HotkeyHostName,
      this.crBiologyE3HotkeyHost,
      this.crBiologyE3HotkeyFrame,
      enabled
    );
    this.crBiologyE3HotkeyStateKnown = true;
    this.crBiologyE3HotkeyLastEnabled = enabled;
  }
}

@wrapMethod(HotkeysWidgetController)
protected cb func OnInitialize() -> Bool {
  let result: Bool = wrappedMethod();
  CRBiologyE3Primitives.Trace("HotkeysWidgetController.OnInitialize");
  this.CRRefreshBiologyE3HotkeyFrame();
  return result;
}

@addMethod(HotkeysWidgetController)
protected cb func OnCRBiologyE3PreferenceChanged(evt: ref<CRBiologyE3PreferenceChangedEvent>) -> Bool {
  this.CRRefreshBiologyE3HotkeyFrame();
  // Notification events are broadcast invalidations; do not consume propagation.
  return false;
}

@addMethod(HotkeysWidgetController)
protected cb func OnCRBiologyE3PreferenceChangedEvent(evt: ref<CRBiologyE3PreferenceChangedEvent>) -> Bool {
  this.CRRefreshBiologyE3HotkeyFrame();
  // Notification events are broadcast invalidations; do not consume propagation.
  return false;
}
