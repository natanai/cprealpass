// Biology-owned E3-inspired ambient NPC nameplate treatment.
//
// W03.3 fixes the actual native visibility bottleneck proven by the attended result and
// the 2.31 controller source: NpcNameplateGameController hides the entire projected
// root when NameplateVisualsLogicController.IsAnyElementVisible() is false. W03.2 only
// tried to reveal m_displayName after that decision, so ordinary civilians stayed
// hidden; after scan the native root could become visible and expose the oversized
// Biology child as the observed small red reticle-adjacent rectangle.
//
// This implementation reuses native name text/frame instead of an oversized custom
// projected canvas, counts legitimate Biology ambient identity as a visible element,
// and preserves native projection/dialog/distance/hide-name authority.
module CyberpunkRealism.Presentation

import CyberpunkRealism.Settings.*

@addField(NameplateVisualsLogicController)
private let crBiologyE3LastPuppet: wref<GameObject>;

@addField(NameplateVisualsLogicController)
private let crBiologyE3LastData: NPCNextToTheCrosshair;

@addField(NameplateVisualsLogicController)
private let crBiologyE3NativeFrameTint: HDRColor;

@addField(NameplateVisualsLogicController)
private let crBiologyE3NativeFrameOpacity: Float;

@addField(NameplateVisualsLogicController)
private let crBiologyE3NativeFrameVisible: Bool;

@addField(NameplateVisualsLogicController)
private let crBiologyE3HasNativeFrameStyle: Bool;

@addField(NameplateVisualsLogicController)
private let crBiologyE3LoggedVisualData: Bool;

@addField(NpcNameplateGameController)
private let crBiologyE3LoggedProjection: Bool;

@addMethod(NameplateVisualsLogicController)
private final func CRBiologyE3ShouldShowAmbientName(puppet: wref<GameObject>, data: NPCNextToTheCrosshair) -> Bool {
  return IsDefined(puppet)
    && CRRealpassSettings.UseE3FirstPersonHudVisuals(puppet.GetGame())
    && IsStringValid(this.CRResolveBiologyAmbientName(puppet, data));
}

@addMethod(NameplateVisualsLogicController)
private final func CRCaptureBiologyE3NativeFrameStyle() -> Void {
  let nativeNameFrame: ref<inkWidget> = inkWidgetRef.Get(this.m_nameFrame);

  if IsDefined(nativeNameFrame) && !this.crBiologyE3HasNativeFrameStyle {
    this.crBiologyE3NativeFrameTint = nativeNameFrame.GetTintColor();
    this.crBiologyE3NativeFrameOpacity = nativeNameFrame.GetOpacity();
    this.crBiologyE3NativeFrameVisible = nativeNameFrame.IsVisible();
    this.crBiologyE3HasNativeFrameStyle = true;
  }
}

@addMethod(NameplateVisualsLogicController)
private final func CRRefreshBiologyE3Nameplate(puppet: wref<GameObject>, data: NPCNextToTheCrosshair) -> Void {
  let e3Enabled: Bool = IsDefined(puppet) && CRRealpassSettings.UseE3FirstPersonHudVisuals(puppet.GetGame());
  let name: String = this.CRResolveBiologyAmbientName(puppet, data);
  let showName: Bool = e3Enabled && IsStringValid(name);
  let nativeNameText: ref<inkText> = inkWidgetRef.Get(this.m_nameTextMain) as inkText;
  let nativeNameFrame: ref<inkWidget> = inkWidgetRef.Get(this.m_nameFrame);

  if !e3Enabled {
    if IsDefined(nativeNameFrame) && this.crBiologyE3HasNativeFrameStyle {
      nativeNameFrame.SetTintColor(this.crBiologyE3NativeFrameTint);
      nativeNameFrame.SetOpacity(this.crBiologyE3NativeFrameOpacity);
      nativeNameFrame.SetVisible(this.crBiologyE3NativeFrameVisible);
    }
    return;
  }

  if showName && IsDefined(nativeNameText) {
    nativeNameText.SetText(name);
    nativeNameText.SetLetterCase(textLetterCase.UpperCase);
    nativeNameText.SetFontStyle(n"Medium");
    nativeNameText.SetTintColor(CRBiologyE3Primitives.Red());
    nativeNameText.SetVisible(true);
  }

  if showName && IsDefined(nativeNameFrame) {
    nativeNameFrame.SetTintColor(CRBiologyE3Primitives.Red());
    nativeNameFrame.SetOpacity(0.82);
    nativeNameFrame.SetVisible(true);
  }
}

@wrapMethod(NameplateVisualsLogicController)
public final func SetVisualData(puppet: ref<GameObject>, const incomingData: script_ref<NPCNextToTheCrosshair>, opt isNewNpc: Bool) -> Void {
  let data: NPCNextToTheCrosshair = Deref(incomingData);
  let ambientName: String = this.CRResolveBiologyAmbientName(puppet, data);

  if !IsStringValid(data.name) && IsStringValid(ambientName) {
    data.name = ambientName;
  }

  this.crBiologyE3LastPuppet = puppet;
  this.crBiologyE3LastData = data;

  if !this.crBiologyE3LoggedVisualData {
    CRBiologyE3Primitives.Trace("NameplateVisualsLogicController.SetVisualData");
    this.crBiologyE3LoggedVisualData = true;
  }

  wrappedMethod(puppet, data, isNewNpc);
}

@wrapMethod(NameplateVisualsLogicController)
private func SetElementVisibility(const incomingData: script_ref<NPCNextToTheCrosshair>) -> Void {
  this.crBiologyE3LastData = Deref(incomingData);
  wrappedMethod(incomingData);
  this.CRCaptureBiologyE3NativeFrameStyle();
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

@wrapMethod(NpcNameplateGameController)
protected cb func OnInitialize() -> Bool {
  let result: Bool = wrappedMethod();
  CRBiologyE3Primitives.Trace("NpcNameplateGameController.OnInitialize");
  this.CRRefreshBiologyE3NameplateRange();
  return result;
}

@wrapMethod(NpcNameplateGameController)
protected cb func OnScreenProjectionUpdate(projections: ref<gameuiScreenProjectionsData>) -> Void {
  this.CRRefreshBiologyE3NameplateRange();
  wrappedMethod(projections);

  if !this.crBiologyE3LoggedProjection {
    CRBiologyE3Primitives.Trace("NpcNameplateGameController.OnScreenProjectionUpdate");
    this.crBiologyE3LoggedProjection = true;
  }

  if !CRRealpassSettings.UseE3FirstPersonHudVisuals(GetGameInstance()) {
    return;
  }

  if this.GetNameplateVisible() {
    if !IsDefined(this.m_bufferedCharacterNamePlateRecord) || this.m_bufferedCharacterNamePlateRecord.Enabled() {
      inkWidgetRef.SetVisible(this.m_displayName, true);
    }
  }
}
