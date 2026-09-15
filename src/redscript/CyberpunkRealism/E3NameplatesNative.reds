// Biology-owned E3-inspired ambient NPC nameplate treatment.
//
// Native identity, projection, distance and visibility remain authoritative. Biology
// adds the red/minimal nameplate language and ensures the native display-name surface
// is available during ordinary focus only when the native nameplate is projected and
// its native record permits presentation. Scanner mode is not required for that
// baseline; richer native identity acquired later by scanning always wins.
module CyberpunkRealism.Presentation

import CyberpunkRealism.Settings.*

@addField(NameplateVisualsLogicController)
private let crBiologyE3NameplateFrame: ref<inkCanvas>;

@addMethod(NameplateVisualsLogicController)
private final func CRBiologyE3NameplateRect(name: CName, x: Float, y: Float, width: Float, height: Float, opacity: Float) -> ref<inkRectangle> {
  let widget: ref<inkRectangle> = new inkRectangle();
  widget.SetName(name);
  widget.SetSize(Vector2(width, height));
  widget.SetTranslation(x, y);
  widget.SetTintColor(CRBiologyE3Primitives.Red());
  widget.SetOpacity(opacity);
  widget.Reparent(this.crBiologyE3NameplateFrame, -1);
  return widget;
}

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
  this.crBiologyE3NameplateFrame.SetSize(Vector2(430.0, 72.0));
  this.crBiologyE3NameplateFrame.Reparent(root, -1);

  // A complete open bracket around the native identity text, not a combat-health strip.
  this.CRBiologyE3NameplateRect(n"CRBiologyE3NameplateTop", 0.0, 0.0, 318.0, 2.0, 0.94);
  this.CRBiologyE3NameplateRect(n"CRBiologyE3NameplateLeft", 0.0, 0.0, 2.0, 52.0, 0.94);
  this.CRBiologyE3NameplateRect(n"CRBiologyE3NameplateBottom", 22.0, 52.0, 214.0, 2.0, 0.78);
  this.CRBiologyE3NameplateRect(n"CRBiologyE3NameplateAccent", 330.0, 0.0, 24.0, 6.0, 1.00);
  this.CRBiologyE3NameplateRect(n"CRBiologyE3NameplateTick", 366.0, 0.0, 13.0, 2.0, 0.58);
}

@addMethod(NameplateVisualsLogicController)
public final func CRRefreshBiologyE3Nameplate(puppet: ref<GameObject>, data: NPCNextToTheCrosshair) -> Void {
  let e3Enabled: Bool = IsDefined(puppet) && CRRealpassSettings.UseE3FirstPersonHudVisuals(puppet.GetGame());
  let name: String = this.CRResolveBiologyAmbientName(puppet, data);
  let showName: Bool = e3Enabled && IsStringValid(name);
  let nameText: ref<inkText>;
  let nameFrame: ref<inkBorder>;

  this.CRCreateBiologyE3Nameplate();
  if IsDefined(this.crBiologyE3NameplateFrame) {
    this.crBiologyE3NameplateFrame.SetVisible(showName);
  }

  // These are native 2.31 NameplateVisualsLogicController refs evidenced by the
  // preserved Project E3 2.31.p2 source; no Project E3-added field is required here.
  nameText = inkWidgetRef.Get(this.m_nameTextMain) as inkText;
  if IsDefined(nameText) && showName {
    nameText.SetText(name);
    nameText.SetLetterCase(textLetterCase.UpperCase);
    nameText.SetFontStyle(n"Medium");
    nameText.SetTintColor(CRBiologyE3Primitives.Red());
    nameText.SetVisible(true);
  }

  nameFrame = inkWidgetRef.Get(this.m_nameFrame) as inkBorder;
  if IsDefined(nameFrame) && showName {
    nameFrame.SetTintColor(CRBiologyE3Primitives.Red());
    nameFrame.SetOpacity(0.78);
    nameFrame.SetVisible(true);
  }
}

@wrapMethod(NameplateVisualsLogicController)
public final func SetVisualData(puppet: ref<GameObject>, const incomingData: script_ref<NPCNextToTheCrosshair>, opt isNewNpc: Bool) -> Void {
  let data: NPCNextToTheCrosshair = Deref(incomingData);
  wrappedMethod(puppet, incomingData, isNewNpc);
  this.CRRefreshBiologyE3Nameplate(puppet, data);
}

// Project E3 2.31.p2 used this exact native screen-projection seam and these exact
// native fields. Keep this adapter deliberately no broader than that proven surface.
// Identity permission stays in SetVisualData/CRResolveBiologyAmbientName; this hook
// only makes the already-authorized native display-name container available.
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
