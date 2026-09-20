// Biology-owned ambient identity resolver for the E3-inspired nameplate layer.
//
// Native NPCNextToTheCrosshair.name always wins. When it is empty, Biology may render
// the entity's already-public GetDisplayName() for ordinary attached NPCs, including
// civilians, police and ordinary combatants. That fallback is presentation-only: it
// must never be written back into NPCNextToTheCrosshair or scanner/native knowledge.
// Hidden, alternative, disabled-nameplate and quest-target policy remains
// native-authoritative. Scanner state is not required.
module CyberpunkRealism.Presentation

import CyberpunkRealism.Settings.*

@addMethod(NameplateVisualsLogicController)
public final func CRPublicAmbientNameAllowed(puppet: wref<GameObject>) -> Bool {
  let npc: wref<NPCPuppet> = puppet as NPCPuppet;
  let character: wref<Character_Record>;
  let nameplate: wref<UINameplate_Record>;
  let ps: ref<ScriptedPuppetPS>;

  if !IsDefined(puppet) || !CRRealpassSettings.UseE3FirstPersonHudVisuals(puppet.GetGame()) {
    return false;
  }
  if !IsDefined(npc) || !npc.IsAttached() || this.IsQuestTarget()
    || this.m_forceHide || !this.m_npcNamesEnabled || this.crBiologyE3ScannerActive {
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
  if IsDefined(nameplate) && !nameplate.Enabled() {
    return false;
  }

  ps = npc.GetPS() as ScriptedPuppetPS;
  if !IsDefined(ps) || ps.HasAlternativeName() {
    return false;
  }

  return IsStringValid(puppet.GetDisplayName());
}

@addMethod(NameplateVisualsLogicController)
public final func CRResolveBiologyAmbientName(puppet: wref<GameObject>, data: NPCNextToTheCrosshair) -> String {
  if IsStringValid(data.name) {
    return data.name;
  }
  if this.CRPublicAmbientNameAllowed(puppet) {
    return puppet.GetDisplayName();
  }
  return "";
}
