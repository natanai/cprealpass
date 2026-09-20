// Biology-owned E3-inspired ambient NPC nameplate treatment.
//
// W03.3's ambient identity lifecycle is a live KEEP: ordinary-look names appear outside
// scanner context. W20.1 keeps structural composition on authored m_nameTextMain and
// m_nameFrame and never writes Biology fallback identity into native knowledge.
//
// T007 proved the remaining ownership defect: the modern scanner could show its detailed
// native identity (for example BEAT COP) while Biology simultaneously kept a generic
// ambient projected identity (for example NC RESIDENT) visible. W20.3 therefore treats
// NpcNameplateGameController.m_isScanning as an ownership boundary. It does not hook,
// replace, recolor or load any scanner/quickhack controller/resource.
//
// Biology's ambient text/frame styling is reversible on every lifecycle pass. Native
// SetVisualData is re-run with the last unchanged native data whenever scanner/preference
// ownership changes so OFF/scanner entry cannot leave Biology text or style behind.
module CyberpunkRealism.Presentation

import CyberpunkRealism.Settings.*

@addField(NameplateVisualsLogicController)
public let crBiologyE3ScannerActive: Bool;

@addField(NameplateVisualsLogicController)
private let crBiologyE3PreferenceActive: Bool;

@addField(NameplateVisualsLogicController)
private let crBiologyE3LastPuppet: wref<GameObject>;

@addField(NameplateVisualsLogicController)
private let crBiologyE3LastData: NPCNextToTheCrosshair;

@addField(NameplateVisualsLogicController)
private let crBiologyE3NativeNameTint: HDRColor;

@addField(NameplateVisualsLogicController)
private let crBiologyE3NativeFrameTint: HDRColor;

@addField(NameplateVisualsLogicController)
private let crBiologyE3NativeFrameOpacity: Float;

@addField(NameplateVisualsLogicController)
private let crBiologyE3NativeFrameVisible: Bool;

@addField(NameplateVisualsLogicController)
private let crBiologyE3HasNativeNameTint: Bool;

@addField(NameplateVisualsLogicController)
private let crBiologyE3HasNativeFrameStyle: Bool;

@addField(NameplateVisualsLogicController)
private let crBiologyE3LoggedVisualData: Bool;

@addField(NpcNameplateGameController)
private let crBiologyE3LoggedProjection: Bool;

@addMethod(NameplateVisualsLogicController)
private final func CRBiologyE3ShouldShowAmbientName(puppet: wref<GameObject>, data: NPCNextToTheCrosshair) -> Bool {
  return IsDefined(puppet)
    && !this.crBiologyE3ScannerActive
    && CRRealpassSettings.UseE3FirstPersonHudVisuals(puppet.GetGame())
    && this.CRPublicAmbientNameAllowed(puppet)
    && IsStringValid(this.CRResolveBiologyAmbientName(puppet, data));
}

@addMethod(NameplateVisualsLogicController)
private final func CRRestoreBiologyE3NameplateStyle() -> Void {
  let nativeNameText: ref<inkText> = inkWidgetRef.Get(this.m_nameTextMain) as inkText;
  let nativeNameFrame: ref<inkWidget> = inkWidgetRef.Get(this.m_nameFrame);

  if IsDefined(nativeNameText) && this.crBiologyE3HasNativeNameTint {
    nativeNameText.SetTintColor(this.crBiologyE3NativeNameTint);
  }

  if IsDefined(nativeNameFrame) && this.crBiologyE3HasNativeFrameStyle {
    nativeNameFrame.SetTintColor(this.crBiologyE3NativeFrameTint);
    nativeNameFrame.SetOpacity(this.crBiologyE3NativeFrameOpacity);
    nativeNameFrame.SetVisible(this.crBiologyE3NativeFrameVisible);
  }

  this.crBiologyE3HasNativeNameTint = false;
  this.crBiologyE3HasNativeFrameStyle = false;
}

@addMethod(NameplateVisualsLogicController)
private final func CRCaptureBiologyE3NativeNameplateStyle() -> Void {
  let nativeNameText: ref<inkText> = inkWidgetRef.Get(this.m_nameTextMain) as inkText;
  let nativeNameFrame: ref<inkWidget> = inkWidgetRef.Get(this.m_nameFrame);

  if IsDefined(nativeNameText) && !this.crBiologyE3HasNativeNameTint {
    this.crBiologyE3NativeNameTint = nativeNameText.GetTintColor();
    this.crBiologyE3HasNativeNameTint = true;
  }

  if IsDefined(nativeNameFrame) && !this.crBiologyE3HasNativeFrameStyle {
    this.crBiologyE3NativeFrameTint = nativeNameFrame.GetTintColor();
    this.crBiologyE3NativeFrameOpacity = nativeNameFrame.GetOpacity();
    this.crBiologyE3NativeFrameVisible = nativeNameFrame.IsVisible();
    this.crBiologyE3HasNativeFrameStyle = true;
  }
}

@addMethod(NameplateVisualsLogicController)
private final func CRRefreshBiologyE3Nameplate(puppet: wref<GameObject>, data: NPCNextToTheCrosshair) -> Void {
  let showName: Bool = this.CRBiologyE3ShouldShowAmbientName(puppet, data);
  let nativeNameText: ref<inkText> = inkWidgetRef.Get(this.m_nameTextMain) as inkText;
  let nativeNameFrame: ref<inkWidget> = inkWidgetRef.Get(this.m_nameFrame);
  let name: String;

  if !showName {
    return;
  }

  name = this.CRResolveBiologyAmbientName(puppet, data);
  this.CRCaptureBiologyE3NativeNameplateStyle();

  if IsDefined(nativeNameText) {
    // Text content may use the public ambient fallback, but font family/case/style stay
    // native so OFF/scanner restoration never depends on unavailable style getters.
    nativeNameText.SetText(name);
    nativeNameText.SetTintColor(CRBiologyE3Primitives.Red());
    nativeNameText.SetVisible(true);
  }

  if IsDefined(nativeNameFrame) {
    nativeNameFrame.SetTintColor(CRBiologyE3Primitives.Red());
    nativeNameFrame.SetOpacity(0.72);
    nativeNameFrame.SetVisible(true);
  }
}

@addMethod(NameplateVisualsLogicController)
public final func CRSyncBiologyE3IdentityOwner(scanning: Bool, enabled: Bool) -> Void {
  if Equals(scanning, this.crBiologyE3ScannerActive)
    && Equals(enabled, this.crBiologyE3PreferenceActive) {
    return;
  }

  this.crBiologyE3ScannerActive = scanning;
  this.crBiologyE3PreferenceActive = enabled;

  if IsDefined(this.crBiologyE3LastPuppet) {
    // Restore captured style first, then let native rebuild text/visibility from the
    // unchanged last NPCNextToTheCrosshair payload. No Biology fallback is written into
    // that payload, so scanner/native knowledge remains one-way authoritative.
    this.CRRestoreBiologyE3NameplateStyle();
    this.SetVisualData(this.crBiologyE3LastPuppet, this.crBiologyE3LastData);
  }
}

@wrapMethod(NameplateVisualsLogicController)
public final func SetVisualData(puppet: ref<GameObject>, const incomingData: script_ref<NPCNextToTheCrosshair>, opt isNewNpc: Bool) -> Void {
  let data: NPCNextToTheCrosshair = Deref(incomingData);

  this.crBiologyE3LastPuppet = puppet;
  this.crBiologyE3LastData = data;
  this.CRRestoreBiologyE3NameplateStyle();

  if !this.crBiologyE3LoggedVisualData {
    CRBiologyE3Primitives.Trace("NameplateVisualsLogicController.SetVisualData");
    this.crBiologyE3LoggedVisualData = true;
  }

  // Preserve W20.1's already exact-compiled native wrapper call shape and pass native
  // values through unchanged. Ambient fallback is resolved only after native handling.
  wrappedMethod(puppet, data, isNewNpc);
}

@wrapMethod(NameplateVisualsLogicController)
private func SetElementVisibility(const incomingData: script_ref<NPCNextToTheCrosshair>) -> Void {
  this.crBiologyE3LastData = Deref(incomingData);
  this.CRRestoreBiologyE3NameplateStyle();
  wrappedMethod(incomingData);
  this.CRRefreshBiologyE3Nameplate(this.crBiologyE3LastPuppet, this.crBiologyE3LastData);
}

@wrapMethod(NameplateVisualsLogicController)
public final func IsAnyElementVisible() -> Bool {
  if wrappedMethod() {
    return true;
  }
  return this.CRBiologyE3ShouldShowAmbientName(this.crBiologyE3LastPuppet, this.crBiologyE3LastData);
}

@addMethod(NpcNameplateGameController)
private final func CRRefreshBiologyE3NameplateRange() -> Void {
  if CRRealpassSettings.UseE3FirstPersonHudVisuals(GetGameInstance()) {
    this.c_DisplayRangeNotAggressive = 10.0;
    this.c_MaxDisplayRangeNotAggressive = 20.0;
  } else {
    this.c_DisplayRangeNotAggressive = SNameplateRangesData.GetDisplayRangeNotAggressive();
    this.c_MaxDisplayRangeNotAggressive = SNameplateRangesData.GetMaxDisplayRangeNotAggressive();
  }
}

@addMethod(NpcNameplateGameController)
private final func CRSyncBiologyE3NameplateOwner() -> Void {
  let enabled: Bool = CRRealpassSettings.UseE3FirstPersonHudVisuals(GetGameInstance());

  this.CRRefreshBiologyE3NameplateRange();
  if IsDefined(this.m_visualController) {
    this.m_visualController.CRSyncBiologyE3IdentityOwner(this.m_isScanning, enabled);
  }

  // The current/native scanner owns detailed identity while scanning. Suppress only
  // Biology's ordinary projected display-name surface; scanner/quickhack UI is untouched.
  if this.m_isScanning && enabled {
    inkWidgetRef.SetVisible(this.m_displayName, false);
  }
}

@wrapMethod(NpcNameplateGameController)
protected cb func OnInitialize() -> Bool {
  let result: Bool = wrappedMethod();
  CRBiologyE3Primitives.Trace("NpcNameplateGameController.OnInitialize");
  this.CRSyncBiologyE3NameplateOwner();
  return result;
}

@wrapMethod(NpcNameplateGameController)
protected cb func OnScreenProjectionUpdate(projections: ref<gameuiScreenProjectionsData>) -> Void {
  let enabled: Bool = CRRealpassSettings.UseE3FirstPersonHudVisuals(GetGameInstance());

  if IsDefined(this.m_visualController) {
    this.m_visualController.CRSyncBiologyE3IdentityOwner(this.m_isScanning, enabled);
  }
  this.CRRefreshBiologyE3NameplateRange();
  wrappedMethod(projections);

  if !this.crBiologyE3LoggedProjection {
    CRBiologyE3Primitives.Trace("NpcNameplateGameController.OnScreenProjectionUpdate");
    this.crBiologyE3LoggedProjection = true;
  }

  if this.m_isScanning {
    if enabled {
      // T007: prevent simultaneous generic ambient identity beside native detailed
      // scanner identity. This hides only the projected nameplate displayName.
      inkWidgetRef.SetVisible(this.m_displayName, false);
    }
    return;
  }

  if !enabled {
    return;
  }

  if this.GetNameplateVisible() {
    if !IsDefined(this.m_bufferedCharacterNamePlateRecord) || this.m_bufferedCharacterNamePlateRecord.Enabled() {
      inkWidgetRef.SetVisible(this.m_displayName, true);
    }
  }
}

@wrapMethod(NpcNameplateGameController)
protected cb func OnIsEnabledChange(val: Int32) -> Bool {
  let result: Bool = wrappedMethod(val);
  this.CRSyncBiologyE3NameplateOwner();
  return result;
}

@addMethod(NpcNameplateGameController)
protected cb func OnCRBiologyE3PreferenceChanged(evt: ref<CRBiologyE3PreferenceChangedEvent>) -> Bool {
  this.CRSyncBiologyE3NameplateOwner();
  // Notification events are broadcast invalidations; do not consume propagation.
  return false;
}
