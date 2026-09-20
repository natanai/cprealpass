// Biology-owned E3-inspired ambient NPC nameplate treatment.
//
// W03.3's ambient identity lifecycle is a live KEEP: ordinary-look names now appear.
// W03.4 preserves that lifecycle and upgrades presentation from plain red text to a
// compact Project-E3-informed identity frame. No actor HP bar/health number is added.
//
// T002 also proves the reticle bracket was not nameplate-owned; it exactly matches the
// deleted CRBiologyE3FocusFrame in E3CrosshairHudNative.reds. Nameplate chrome therefore
// stays scoped to the native projected nameplate root.
module CyberpunkRealism.Presentation

import CyberpunkRealism.Settings.*

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
private let crBiologyE3IdentityChrome: ref<inkCanvas>;

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
private final func CRCreateBiologyE3IdentityChrome() -> Void {
  let root: ref<inkCompoundWidget>;
  if IsDefined(this.crBiologyE3IdentityChrome) {
    return;
  }

  root = this.GetRootWidget() as inkCompoundWidget;
  if !IsDefined(root) {
    return;
  }

  this.crBiologyE3IdentityChrome = new inkCanvas();
  this.crBiologyE3IdentityChrome.SetName(n"CRBiologyE3IdentityChrome");
  this.crBiologyE3IdentityChrome.SetAnchor(inkEAnchor.Centered);
  this.crBiologyE3IdentityChrome.SetAnchorPoint(Vector2(0.5, 0.5));
  this.crBiologyE3IdentityChrome.SetHAlign(inkEHorizontalAlign.Center);
  this.crBiologyE3IdentityChrome.SetVAlign(inkEVerticalAlign.Center);
  this.crBiologyE3IdentityChrome.SetSize(Vector2(340.0, 46.0));
  this.crBiologyE3IdentityChrome.Reparent(root, 0);

  CRBiologyE3Primitives.AddRect(this.crBiologyE3IdentityChrome, n"CRBiologyE3NameTLH", 0.0, 0.0, 88.0, 2.0, 0.92);
  CRBiologyE3Primitives.AddRect(this.crBiologyE3IdentityChrome, n"CRBiologyE3NameTLV", 0.0, 0.0, 2.0, 14.0, 0.88);
  CRBiologyE3Primitives.AddRect(this.crBiologyE3IdentityChrome, n"CRBiologyE3NameTRH", 252.0, 0.0, 88.0, 2.0, 0.92);
  CRBiologyE3Primitives.AddRect(this.crBiologyE3IdentityChrome, n"CRBiologyE3NameTRV", 338.0, 0.0, 2.0, 14.0, 0.88);
  CRBiologyE3Primitives.AddRect(this.crBiologyE3IdentityChrome, n"CRBiologyE3NameBLH", 0.0, 44.0, 42.0, 2.0, 0.62);
  CRBiologyE3Primitives.AddRect(this.crBiologyE3IdentityChrome, n"CRBiologyE3NameBRH", 298.0, 44.0, 42.0, 2.0, 0.62);
  CRBiologyE3Primitives.AddRect(this.crBiologyE3IdentityChrome, n"CRBiologyE3NameAccent", 9.0, 18.0, 7.0, 10.0, 1.00);
  CRBiologyE3Primitives.AddRect(this.crBiologyE3IdentityChrome, n"CRBiologyE3NameBand", 20.0, 10.0, 300.0, 27.0, 0.08);
}

@addMethod(NameplateVisualsLogicController)
private final func CRRefreshBiologyE3Nameplate(puppet: wref<GameObject>, data: NPCNextToTheCrosshair) -> Void {
  let e3Enabled: Bool = IsDefined(puppet) && CRRealpassSettings.UseE3FirstPersonHudVisuals(puppet.GetGame());
  let name: String = this.CRResolveBiologyAmbientName(puppet, data);
  let showName: Bool = e3Enabled && IsStringValid(name);
  let nativeNameText: ref<inkText> = inkWidgetRef.Get(this.m_nameTextMain) as inkText;
  let nativeNameFrame: ref<inkWidget> = inkWidgetRef.Get(this.m_nameFrame);

  this.CRCaptureBiologyE3NativeNameplateStyle();
  this.CRCreateBiologyE3IdentityChrome();

  if IsDefined(this.crBiologyE3IdentityChrome) {
    this.crBiologyE3IdentityChrome.SetVisible(showName);
  }

  if !e3Enabled {
    if IsDefined(nativeNameText) && this.crBiologyE3HasNativeNameTint {
      nativeNameText.SetTintColor(this.crBiologyE3NativeNameTint);
    }
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
    nativeNameFrame.SetOpacity(0.72);
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
