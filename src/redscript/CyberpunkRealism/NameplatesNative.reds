// Project-original scanned-civilian name fallback.
// Extends only the stock name data handed to the stock nameplate renderer. It does
// not ship or depend on Project E3 assets/controllers and does not reveal authored
// hidden identities, alternative names, quest targets or globally disabled names.
module CyberpunkRealism.Presentation

@addMethod(NameplateVisualsLogicController)
private final func CRScannedCrowdNameAllowed(puppet: wref<GameObject>) -> Bool {
  let npc: wref<NPCPuppet> = puppet as NPCPuppet;
  let character: wref<Character_Record>;
  let nameplate: wref<UINameplate_Record>;
  let preset: wref<ScannerModuleVisibilityPreset_Record>;
  let ps: ref<ScriptedPuppetPS>;
  if !IsDefined(npc) || !npc.IsAttached() || !npc.IsScanned() || !npc.IsCharacterCivilian() || this.m_isQuestTarget {
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
  if !IsDefined(nameplate) || !nameplate.Enabled() || nameplate.GetID() != t"UINameplate.CrowdSettings" {
    return false;
  }
  ps = npc.GetPS();
  if !IsDefined(ps) || ps.HasAlternativeName() {
    return false;
  }
  preset = character.ScannerModulePreset();
  if TDBID.IsValid(ps.GetForcedScannerPreset()) {
    preset = TweakDBInterface.GetScannerModuleVisibilityPresetRecord(ps.GetForcedScannerPreset());
  }
  return IsDefined(preset) && preset.ShoulShowName();
}

@wrapMethod(NameplateVisualsLogicController)
public final func SetVisualData(puppet: ref<GameObject>, incomingData: NPCNextToTheCrosshair, opt isNewNpc: Bool) -> Void {
  // Native focus data always wins. Only recover an empty public crowd name after a
  // permitted completed scan; the stock renderer retains every visibility decision.
  if !IsStringValid(incomingData.name) && this.CRScannedCrowdNameAllowed(puppet) {
    incomingData.name = puppet.GetDisplayName();
  }
  wrappedMethod(puppet, incomingData, isNewNpc);
}
