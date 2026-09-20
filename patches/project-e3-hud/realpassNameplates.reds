// realpass scanned civilian nameplates. Local integration with Project E3 - HUD by Virtuoso75.
// https://www.nexusmods.com/cyberpunk2077/mods/8800 ; this patch requires the original mod.

@addMethod(NameplateVisualsLogicController)
public func RealpassScannedCrowdAllowed(puppet: wref<GameObject>) -> Bool {
    let npc: wref<NPCPuppet> = puppet as NPCPuppet;
    let character: wref<Character_Record>;
    let nameplate: wref<UINameplate_Record>;
    let preset: wref<ScannerModuleVisibilityPreset_Record>;
    let ps: ref<ScriptedPuppetPS>;
    if !IsDefined(npc) || !npc.IsAttached() || !npc.IsScanned() || !npc.IsCharacterCivilian() || this.m_isQuestTarget {
        return false;
    }
    // Generic crowd presentation is opt-in after scan; authored hidden identities are not.
    if npc.GetBoolFromCharacterTweak("hide_nametag") || !IsDefined(npc.GetBlackboard()) {
        return false;
    }
    if npc.GetBlackboard().GetBool(GetAllBlackboardDefs().Puppet.HideNameplate) {
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

@addMethod(NameplateVisualsLogicController)
public func RealpassScannedCrowdName(puppet: wref<GameObject>) -> String {
    if !this.RealpassScannedCrowdAllowed(puppet) {
        return "";
    }
    // This is the entity's public display name, also used by the native civilian scanner.
    // Do not resolve FullDisplayName, archetypes, affiliations or hidden alternative identities.
    return puppet.GetDisplayName();
}

@addMethod(NameplateVisualsLogicController)
public func RealpassSetNameVisible(visible: Bool) -> Void {
    let showName: Bool = visible && this.m_npcNamesEnabled && !this.m_forceHide && !this.m_npcDefeated
        && IsDefined(this.m_cachedIncomingData.npc) && !this.m_cachedIncomingData.npc.IsTurret()
        && IsStringValid(inkTextRef.GetText(this.m_nameTextMain));
    let elite: Bool = (this.m_isBoss || this.m_isElite) && !Equals(this.m_cachedIncomingData.attitude, EAIAttitude.AIA_Friendly);
    inkTextRef.SetVisible(this.m_nameTextMain, showName);
    // E3 draws these separately from the native m_displayName reference.
    inkWidgetRef.SetVisible(this.m_nameFrame, showName && !elite);
    if IsDefined(this.m_nameBG) {
        this.m_nameBG.SetVisible(showName && elite);
    }
}

@addMethod(NameplateVisualsLogicController)
public func RealpassPrepareName() -> Void {
    let data: NPCNextToTheCrosshair = this.m_cachedIncomingData;
    inkTextRef.SetText(this.m_nameTextMain, this.GetCustomNPCName(data.npc as gamePuppetBase, data));
    // Prepare before the native IsAnyElementVisible check so a completed scan can recover
    // from the preceding hidden frame, even without another focus-data notification.
    this.RealpassSetNameVisible(true);
}

@wrapMethod(NpcNameplateGameController)
protected cb func OnScreenProjectionUpdate(projections: ref<gameuiScreenProjectionsData>) -> Bool {
    let showName: Bool;
    let result: Bool;
    if IsDefined(this.m_visualController) {
        this.m_visualController.RealpassPrepareName();
    }
    result = wrappedMethod(projections);
    if !IsDefined(this.m_visualController) {
        return result;
    }
    showName = this.GetNameplateVisible() && inkWidgetRef.IsVisible(this.m_displayName);
    // Keep native distance, mounting, dialog, scene, projection and HideNameplate decisions.
    // Only the generic crowd name policy may be extended, after a permitted completed scan.
    if this.GetNameplateVisible() && !showName && this.m_visualController.RealpassScannedCrowdAllowed(this.m_bufferedGameObject) {
        showName = true;
        inkWidgetRef.SetVisible(this.m_displayName, true);
    }
    this.m_visualController.RealpassSetNameVisible(showName);
    return result;
}
