// Biology-owned ambient NPC identity resolver for the E3-inspired nameplate layer.
//
// Native focus/nameplate identity always wins. For an otherwise-empty ordinary public
// civilian identity, Biology may use the entity's existing public display name before
// scanner mode. Hidden, alternative and quest-specific identities are not derived.
// Scanning can still enrich the result because native NPCNextToTheCrosshair.name wins.
module CyberpunkRealism.Presentation

import CyberpunkRealism.Settings.*

@addMethod(NameplateVisualsLogicController)
public final func CRPublicCrowdNameAllowed(puppet: wref<GameObject>) -> Bool {
  let npc: wref<NPCPuppet> = puppet as NPCPuppet;
  let character: wref<Character_Record>;
  let nameplate: wref<UINameplate_Record>;
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

  // A defined disabled native nameplate record is an explicit no. Do not require one
  // particular CrowdSettings record ID: that W03.1 assumption proved too restrictive
  // for ordinary public civilians in live play.
  nameplate = character.UiNameplate();
  if IsDefined(nameplate) && !nameplate.Enabled() {
    return false;
  }

  ps = npc.GetPS() as ScriptedPuppetPS;
  if !IsDefined(ps) || ps.HasAlternativeName() {
    return false;
  }

  // GetDisplayName is the already-public entity label. We deliberately do not derive
  // FullDisplayName/archetype/affiliation records and do not require scanner state or
  // ScannerModulePreset permission for this baseline ordinary-look label.
  return IsStringValid(puppet.GetDisplayName());
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
  // fills an otherwise-empty permitted public civilian identity.
  if !IsStringValid(resolved.name) && IsStringValid(ambientName) {
    resolved.name = ambientName;
  }

  wrappedMethod(puppet, resolved, isNewNpc);
}
