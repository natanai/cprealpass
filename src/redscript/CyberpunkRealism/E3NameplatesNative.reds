// Biology-owned E3-inspired ambient NPC nameplate treatment.
//
// Native identity, projection, distance and root visibility remain authoritative.
// Biology renders the resolved identity inside the native nameplate projection root so
// it can use a clean red/minimal treatment without permanently mutating CDPR widget
// tint/state. Scanner mode is not required for the baseline; richer native identity
// acquired later by scanning still wins through NPCNextToTheCrosshair.name.
module CyberpunkRealism.Presentation

import CyberpunkRealism.Settings.*

@addField(NameplateVisualsLogicController)
private let crBiologyE3NameplateFrame: ref<inkCanvas>;

@addField(NameplateVisualsLogicController)
private let crBiologyE3NameText: ref<inkText>;

@addField(NameplateVisualsLogicController)
private let crBiologyE3LastPuppet: wref<GameObject>;

@addMethod(NameplateVisualsLogicController)
private final func CRCreateBiologyE3Nameplate() -> Void {
  if IsDefined(this.crBiologyE3NameplateFrame) {
    return;
  }

  let root: ref<inkCompoundWidget> = this.GetRootCompoundWidget();
  if !IsDefined(root) {
    return;
  }

  this.crBiologyE3NameplateFrame = new inkCanvas();
  this.crBiologyE3NameplateFrame.SetName(n"CRBiologyE3NameplateFrame");
  this.crBiologyE3NameplateFrame.SetAnchor(inkEAnchor.Centered);
  this.crBiologyE3NameplateFrame.SetHAlign(inkEHorizontalAlign.Center);
  this.crBiologyE3NameplateFrame.SetVAlign(inkEVerticalAlign.Center);
  this.crBiologyE3NameplateFrame.SetSize(Vector2(440.0, 82.0));
  this.crBiologyE3NameplateFrame.Reparent(root, -1);

  CRBiologyE3Primitives.AddPlate(this.crBiologyE3NameplateFrame, n"CRBiologyE3NameplateWash", 0.0, 0.0, 392.0, 60.0, 0.065);
  CRBiologyE3Primitives.AddRect(this.crBiologyE3NameplateFrame, n"CRBiologyE3NameplateTop", 0.0, 0.0, 328.0, 3.0, 0.98);
  CRBiologyE3Primitives.AddRect(this.crBiologyE3NameplateFrame, n"CRBiologyE3NameplateLeft", 0.0, 0.0, 3.0, 60.0, 0.98);
  CRBiologyE3Primitives.AddRect(this.crBiologyE3NameplateFrame, n"CRBiologyE3NameplateBottom", 22.0, 57.0, 224.0, 3.0, 0.78);
  CRBiologyE3Primitives.AddRect(this.crBiologyE3NameplateFrame, n"CRBiologyE3NameplateAccent", 340.0, 0.0, 26.0, 8.0, 1.00);
  CRBiologyE3Primitives.AddRect(this.crBiologyE3NameplateFrame, n"CRBiologyE3NameplateTick", 378.0, 0.0, 14.0, 3.0, 0.58);

  this.crBiologyE3NameText = CRBiologyE3Primitives.AddLabel(this.crBiologyE3NameplateFrame, n"CRBiologyE3NameText", "", 18.0, 12.0, 18, 0.98);
  this.crBiologyE3NameText.SetLetterCase(textLetterCase.UpperCase);
}

@addMethod(NameplateVisualsLogicController)
public final func CRRefreshBiologyE3Nameplate(puppet: wref<GameObject>, data: NPCNextToTheCrosshair) -> Void {
  let e3Enabled: Bool = IsDefined(puppet) && CRRealpassSettings.UseE3FirstPersonHudVisuals(puppet.GetGame());
  let name: String = this.CRResolveBiologyAmbientName(puppet, data);
  let showName: Bool = e3Enabled && IsStringValid(name);
  let nativeNameText: ref<inkText>;
  let nativeNameFrame: ref<inkBorder>;

  this.CRCreateBiologyE3Nameplate();
  if IsDefined(this.crBiologyE3NameplateFrame) {
    this.crBiologyE3NameplateFrame.SetVisible(showName);
  }
  if IsDefined(this.crBiologyE3NameText) && showName {
    this.crBiologyE3NameText.SetText(name);
  }

  // While E3 is ON, suppress only the native identity text/frame that would duplicate
  // our Biology-owned treatment. When E3 is OFF we do not touch them; wrapped native
  // visibility/state logic has already run and therefore restores the retail surface.
  if showName {
    nativeNameText = inkWidgetRef.Get(this.m_nameTextMain) as inkText;
    if IsDefined(nativeNameText) {
      nativeNameText.SetVisible(false);
    }
    nativeNameFrame = inkWidgetRef.Get(this.m_nameFrame) as inkBorder;
    if IsDefined(nativeNameFrame) {
      nativeNameFrame.SetVisible(false);
    }
  }
}

@wrapMethod(NameplateVisualsLogicController)
public final func SetVisualData(puppet: ref<GameObject>, const incomingData: script_ref<NPCNextToTheCrosshair>, opt isNewNpc: Bool) -> Void {
  let data: NPCNextToTheCrosshair = Deref(incomingData);
  this.crBiologyE3LastPuppet = puppet;
  wrappedMethod(puppet, incomingData, isNewNpc);
  this.CRRefreshBiologyE3Nameplate(puppet, data);
}

// Native SetVisualData calls SetElementVisibility after it applies text/state. W03.1
// refreshed too early, so native visibility logic could hide the civilian name again.
// Refresh once more after that exact 2.31 lifecycle seam without replacing its logic.
@wrapMethod(NameplateVisualsLogicController)
private func SetElementVisibility(const incomingData: script_ref<NPCNextToTheCrosshair>) -> Void {
  let data: NPCNextToTheCrosshair = Deref(incomingData);
  wrappedMethod(incomingData);
  this.CRRefreshBiologyE3Nameplate(this.crBiologyE3LastPuppet, data);
}

@wrapMethod(NpcNameplateGameController)
protected cb func OnScreenProjectionUpdate(projections: ref<gameuiScreenProjectionsData>) -> Void {
  wrappedMethod(projections);

  if !CRRealpassSettings.UseE3FirstPersonHudVisuals(GetGameInstance()) {
    return;
  }

  if this.GetNameplateVisible() {
    if IsDefined(this.m_bufferedCharacterNamePlateRecord) && this.m_bufferedCharacterNamePlateRecord.Enabled() {
      inkWidgetRef.SetVisible(this.m_displayName, true);
    }
  }
}
