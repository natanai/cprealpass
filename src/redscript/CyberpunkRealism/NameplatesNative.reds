// Biology-owned ambient NPC identity resolver for the E3-inspired nameplate layer.
//
// Native focus/nameplate identity always wins. For an ordinary public crowd identity
// whose native nameplate/scanner records permit a name, Biology may use the entity's
// public display name even before scanner mode so the neutral E3 HUD can show an
// ambient nameplate. Scanning can still enrich the result because any richer native
// NPCNextToTheCrosshair.name always takes precedence. Hidden/alternative/quest
// identities are never derived from records by this fallback.
module CyberpunkRealism.Presentation

import CyberpunkRealism.Settings.*

@addMethod(NameplateVisualsLogicController)
public final func CRPublicCrowdNameAllowed(puppet: wref<GameObject>) -> Bool {
  let npc: wref<NPCPuppet> = puppet as NPCPuppet;
  let character: wref<Character_Record>;
  let nameplate: wref<UINameplate_Record>;
  let preset: wref<ScannerModuleVisibilityPreset_Record>;
  let ps: ref<ScriptedPuppetPS>;

  if !IsDefined(puppet) || !CRRealpassSettings.UseE3FirstPersonHudVisuals(puppet.GetGame()) {
    return false;
  }
  if !IsDefined(npc) || !npc.IsAttached() || !npc.IsCharacterCivilian() || this.IsQuestTarget() {
    return false;
  }
  if npc.GetBoolFromCharacterTweak("hide_nametag") || !IsDefined(npc.GetBlackboard()) || npc.GetBlackboard().GetBool(GetAllBlackboardDefs().Puppet.HideNameplate) {
    return false;
  }

  character = TweakDBInterface.GetCharacterRecord(npc.GetRecordID());
  if !IsDefined(character) {
    return false;
  }

  nameplate = character.UiNameplate();
  if !IsDefined(nameplate) || !nameplate.Enabled() || NotEquals(nameplate.GetID(), t"UINameplate.CrowdSettings") {
    return false;
  }

  ps = npc.GetPS() as ScriptedPuppetPS;
  if !IsDefined(ps) || ps.HasAlternativeName() {
    return false;
  }

  // Use the same native visibility authority that governs whether this public name is
  // legitimate scanner/nameplate information. This is a permission check, not a
  // requirement that the player has already entered scanner mode.
  preset = character.ScannerModulePreset();
  if TDBID.IsValid(ps.GetForcedScannerPreset()) {
    preset = TweakDBInterface.GetScannerModuleVisibilityPresetRecord(ps.GetForcedScannerPreset());
  }
  return IsDefined(preset) && preset.ShoulShowName();
}

@addMethod(NameplateVisualsLogicController)
public final func CRResolveBiologyAmbientName(puppet: wref<GameObject>, data: NPCNextToTheCrosshair) -> String {
  if IsStringValid(data.name) {
    return data.name;
  }
  if this.CRPublicCrowdNameAllowed(puppet) {
    return puppet.GetDisplayName();
  }
  return "";
}

@wrapMethod(NameplateVisualsLogicController)
public final func SetVisualData(puppet: ref<GameObject>, const incomingData: script_ref<NPCNextToTheCrosshair>, opt isNewNpc: Bool) -> Void {
  let resolved: NPCNextToTheCrosshair = Deref(incomingData);
  let ambientName: String = this.CRResolveBiologyAmbientName(puppet, resolved);

  // Work on a local copy so the caller's focus blackboard payload is never mutated.
  // Native identity already present in incomingData always wins; the fallback only
  // fills an otherwise-empty permitted public crowd identity.
  if !IsStringValid(resolved.name) && IsStringValid(ambientName) {
    resolved.name = ambientName;
  }

  wrappedMethod(puppet, resolved, isNewNpc);
}
