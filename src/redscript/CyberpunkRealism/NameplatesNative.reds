// RealPass-owned NPC name fallback used by the E3-inspired first-person HUD layer.
// Extends only the stock name data handed to the stock renderer. It has no external
// presentation-mod runtime dependency and does not reveal authored hidden identities,
// alternative names, quest targets or globally disabled names.
module CyberpunkRealism.Presentation

import CyberpunkRealism.Settings.*

@addMethod(NameplateVisualsLogicController)
private final func CRScannedCrowdNameAllowed(puppet: wref<GameObject>) -> Bool {
  let npc: wref<NPCPuppet> = puppet as NPCPuppet;
  let character: wref<Character_Record>;
  let nameplate: wref<UINameplate_Record>;
  let preset: wref<ScannerModuleVisibilityPreset_Record>;
  let ps: ref<ScriptedPuppetPS>;
  if !CRRealpassSettings.UseE3FirstPersonHudVisuals() {
    return false;
  }
  if !IsDefined(npc) || !npc.IsAttached() || !npc.IsScanned() || !npc.IsCharacterCivilian() || this.IsQuestTarget() {
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
  // Match the stock NPC scanner's own visibility source rather than inventing a
  // second scanner-preset override path.
  preset = character.ScannerModulePreset();
  return IsDefined(preset) && preset.ShoulShowName();
}

@wrapMethod(NameplateVisualsLogicController)
public final func SetVisualData(puppet: ref<GameObject>, const incomingData: script_ref<NPCNextToTheCrosshair>, opt isNewNpc: Bool) -> Void {
  // 2.31 passes this imported struct by script_ref. Work on a local copy so the
  // wrapper matches the native signature while the caller's blackboard payload is
  // never mutated in place.
  let resolved: NPCNextToTheCrosshair = Deref(incomingData);
  // Native focus data always wins. Only recover an empty public crowd name after a
  // permitted completed scan while the E3-inspired presentation is enabled; the
  // stock renderer retains every visibility decision.
  if !IsStringValid(resolved.name) && this.CRScannedCrowdNameAllowed(puppet) {
    resolved.name = puppet.GetDisplayName();
  }
  wrappedMethod(puppet, resolved, isNewNpc);
}
