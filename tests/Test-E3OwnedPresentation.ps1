$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\tools\Common.ps1"
$project = Get-ProjectRoot
$sourceRoot = Join-Path $project 'src/redscript/CyberpunkRealism'
$paths = [ordered]@{
    lowerLeft = Join-Path $sourceRoot 'E3FirstPersonHud.reds'
    quest = Join-Path $sourceRoot 'E3QuestHudNative.reds'
    navigation = Join-Path $sourceRoot 'E3NavigationHudNative.reds'
    weapon = Join-Path $sourceRoot 'E3WeaponHudNative.reds'
    crosshair = Join-Path $sourceRoot 'E3CrosshairHudNative.reds'
    hotkey = Join-Path $sourceRoot 'E3HotkeyHudNative.reds'
    interaction = Join-Path $sourceRoot 'E3InteractionHudNative.reds'
    activity = Join-Path $sourceRoot 'E3ActivityHudNative.reds'
    nameplate = Join-Path $sourceRoot 'E3NameplatesNative.reds'
    identity = Join-Path $sourceRoot 'NameplatesNative.reds'
    health = Join-Path $sourceRoot 'NoHealthbars.reds'
    settings = Join-Path $sourceRoot 'RealpassSettings.reds'
    preferenceUi = Join-Path $sourceRoot 'BiologyPreferencesNative.reds'
    primitives = Join-Path $sourceRoot 'E3PresentationPrimitives.reds'
}
$mappingPath = Join-Path $project 'docs/E3-COMPONENT-MAPPING.md'
$presentationPath = Join-Path $project 'docs/E3-PRESENTATION.md'
$seams = Get-Content -Raw -LiteralPath (Join-Path $project 'manifest/native-seams.json') | ConvertFrom-Json
$contract = Get-Content -Raw -LiteralPath (Join-Path $project 'manifest/settings.json') | ConvertFrom-Json
$script:checks = 0
function Check($condition,[string]$message) { if (-not $condition) { throw $message }; $script:checks++ }

foreach ($path in @($paths.Values) + @($mappingPath,$presentationPath)) {
    Check (Test-Path -LiteralPath $path -PathType Leaf) "Missing W03.2 E3 presentation contract/source: $path"
}

$source = @{}
foreach ($key in $paths.Keys) { $source[$key] = Get-Content -Raw -LiteralPath $paths[$key] }
$mapping = Get-Content -Raw -LiteralPath $mappingPath
$presentation = Get-Content -Raw -LiteralPath $presentationPath

# W03.2 must materially affect ordinary first-person presentation through owned,
# reversible widgets rather than merely tinting native roots.
foreach ($key in @('quest','navigation','weapon','crosshair','hotkey','interaction')) {
    Check ($source[$key].Contains('CRRealpassSettings.UseE3FirstPersonHudVisuals(GetGameInstance())')) "$key presentation seam is not gated by the single E3 preference."
    Check (-not $source[$key].Contains('TintNeutralHudRoot')) "$key still mutates a native HUD root tint instead of yielding cleanly on E3 OFF."
}
Check (-not $source.primitives.Contains('TintNeutralHudRoot')) 'Shared E3 primitives still expose the native-root tint mutation path.'
Check ($source.primitives.Contains('AddPlate') -and $source.primitives.Contains('AddLabel')) 'Shared E3 primitives do not support the stronger owned visual language.'

Check ($source.quest.Contains('@wrapMethod(QuestTrackerGameController)') -and $source.quest.Contains('OBJECTIVES') -and $source.quest.Contains('CRBiologyE3QuestWash')) 'Quest tracker does not receive the materially visible W03.2 E3 shell.'
Check ($source.navigation.Contains('@wrapMethod(MinimapContainerController)') -and $source.navigation.Contains('NAV // ROUTE') -and $source.navigation.Contains('CRBiologyE3MinimapWash')) 'Current minimap host does not receive the W03.2 E3 navigation shell.'
Check (-not $source.navigation.Contains('@wrapMethod(IronsightGameController)')) 'Navigation styling regressed to the historical Project E3 ironsight host.'
Check ($source.weapon.Contains('@wrapMethod(WeaponRosterGameController)') -and $source.weapon.Contains('WEAPON // AMMO') -and $source.weapon.Contains('CRBiologyE3WeaponWash')) 'Weapon/ammo roster does not receive the W03.2 E3 shell.'
Check ($source.hotkey.Contains('@wrapMethod(HotkeysWidgetController)') -and $source.hotkey.Contains('QUICK // INPUT')) 'Hotkey/D-pad surface does not receive the W03.2 E3 shell.'

# W03.1 only touched Tech-Hex. W03.2 must cover the normal crosshair container while
# preserving each weapon controller's aiming/spread/charge semantics.
Check ($source.crosshair.Contains('@wrapMethod(gameuiCrosshairContainerController)')) 'General current crosshair container is not part of W03.2 ordinary focus presentation.'
Check ($source.crosshair.Contains('@wrapMethod(CrosshairGameController_Tech_Hex)')) 'Tech-Hex specialization unexpectedly disappeared.'
Check ($source.crosshair.Contains('CRBiologyE3FocusFrame')) 'General crosshair/focus frame is missing.'
foreach ($forbidden in @('@replaceMethod(gameuiCrosshairContainerController)','OnPSMVisionStateChanged','GetActiveCrosshairGameController')) {
    Check (-not $source.crosshair.Contains($forbidden)) "Crosshair styling took over native crosshair/vision behavior: $forbidden"
}

# Materially recurring prompt/activity surfaces are now audited and narrowly styled.
Check ($source.interaction.Contains('@wrapMethod(interactionWidgetGameController)')) 'Ordinary interaction prompt surface is not covered.'
Check ($source.interaction.Contains('protected cb func OnUpdateInteraction(argValue: Variant) -> Bool')) 'Interaction adapter lost the evidenced current update seam.'
Check ($source.interaction.Contains('INTERACTION')) 'Interaction adapter lacks visible E3 identity.'
Check (-not $source.interaction.Contains('@replaceMethod')) 'W03.2 interaction presentation replaced native interaction behavior.'
Check (-not $source.interaction.Contains('FromVariant<InteractionChoiceHubData>')) 'W03.2 interaction presentation started reimplementing choice-hub logic.'
Check (-not $source.interaction.Contains('AsyncSpawnFromLocal')) 'W03.2 interaction presentation started owning option spawning.'
Check ($source.activity.Contains('@wrapMethod(activityLogEntryLogicController)')) 'Transient activity presentation is not covered.'
Check ($source.activity.Contains('textLetterCase.UpperCase') -and $source.activity.Contains('CRBiologyE3Primitives.Red()')) 'Activity entries do not use the shared E3 text language.'
Check (-not $source.activity.Contains('@replaceMethod') -and -not $source.activity.Contains('inkAnimController')) 'W03.2 activity styling took over native queue/animation behavior.'

# Existing lower-left slice remains presentation-only, never a replacement health meter.
Check ($source.lowerLeft.Contains('CRBiologyE3HudFrame')) 'Lower-left E3 HUD root is missing.'
Check ($source.lowerLeft.Contains('CRRealpassSettings.UseE3FirstPersonHudVisuals(GetGameInstance())')) 'Lower-left E3 HUD is not preference gated.'
foreach ($forbidden in @('StatPoolType.Health','GetStatPoolValue','SetStatPoolValue','ApplyDamage','ProcessLocalizedDamage')) {
    Check (-not $source.lowerLeft.Contains($forbidden)) "Lower-left E3 HUD incorrectly became a health-state surface: $forbidden"
}

# Ambient nameplates: native incoming identity wins; civilian fallback is ordinary-look
# public display identity, not scanner completion or Project E3's derived identity DB.
Check ($source.identity.Contains('CRResolveBiologyAmbientName')) 'Owned ambient identity resolver is missing.'
Check ($source.identity.Contains('if IsStringValid(data.name)')) 'Native focus/nameplate identity does not explicitly win.'
Check (-not $source.identity.Contains('npc.IsScanned()')) 'Ambient civilian identity is still structurally scanner-only.'
Check (-not $source.identity.Contains('ScannerModulePreset')) 'Baseline ambient identity is still coupled to scanner-module records.'
Check (-not $source.identity.Contains('UINameplate.CrowdSettings')) 'Civilian fallback is still restricted to one assumed crowd nameplate record ID.'
Check ($source.identity.Contains('ps.HasAlternativeName()')) 'Ambient fallback can reveal an authored alternative identity.'
Check ($source.identity.Contains('hide_nametag') -and $source.identity.Contains('Puppet.HideNameplate')) 'Ambient fallback lost native hidden-name gates.'
Check ($source.identity.Contains('GetDisplayName()')) 'Ambient fallback lost the native public display-name source.'
foreach ($forbidden in @('FullDisplayName','ArchetypeData','Affiliation().LocalizedName')) {
    Check (-not $source.identity.Contains($forbidden)) "Ambient fallback started deriving non-public identity records: $forbidden"
}

# W03.2 fixes the post-SetVisualData visibility lifecycle rather than replacing native
# SetElementVisibility wholesale, and renders inside the native projection root.
Check ($source.nameplate.Contains('private func SetElementVisibility(const incomingData: script_ref<NPCNextToTheCrosshair>) -> Void')) 'Nameplate adapter does not refresh after the native visibility lifecycle.'
Check ($source.nameplate.Contains('wrappedMethod(incomingData)')) 'Nameplate visibility adapter replaced rather than wrapped native visibility logic.'
Check ($source.nameplate.Contains('CRBiologyE3NameText')) 'W03.2 nameplate lacks a complete owned identity-text presentation.'
Check ($source.nameplate.Contains('@wrapMethod(NpcNameplateGameController)')) 'Ambient nameplate does not reuse native screen projection.'
Check ($source.nameplate.Contains('this.GetNameplateVisible()') -and $source.nameplate.Contains('this.m_bufferedCharacterNamePlateRecord')) 'Projection adapter lost native visibility/record gates.'
Check ($source.nameplate.Contains('inkWidgetRef.SetVisible(this.m_displayName, true)')) 'Projection adapter no longer exposes the native nameplate container during permitted focus.'
foreach ($forbidden in @('m_healthbarWidget','m_damagePreviewWidget','currentHealth','maximumHealth','StatPoolType.Health')) {
    Check (-not $source.nameplate.Contains($forbidden)) "E3 nameplate incorrectly absorbed health-meter ownership: $forbidden"
}

# Modern scanner/quickhack is a hard exclusion across executing E3 presentation.
$combined = ($source.Keys | ForEach-Object { $source[$_] }) -join "`n"
foreach ($forbidden in @('ScannerGameController','scannerGameController','ScannerDetailsGameController','ScannerNPCHeaderGameController','quickhackWidgetGameController','QuickHackGameController','scanner.inkwidget','scanner_details.inkwidget','scanner_hud.inkwidget','base\\gameplay\\gui\\widgets\\scanner')) {
    Check (-not $combined.Contains($forbidden)) "Owned E3 presentation crossed the modern scanner/quickhack boundary: $forbidden"
}
foreach ($forbidden in @('module ProjectE3','import ProjectE3','patches/project-e3-hud','DarkFuture.','import DarkFuture','basegame_3e_demo_hud.archive')) {
    Check (-not $combined.Contains($forbidden)) "Owned E3 runtime gained forbidden source-mod/archive dependency: $forbidden"
}
Check (-not $combined.Contains('ResRef.FromString')) 'Owned E3 presentation depends on external E3 UI resources instead of Biology-owned INK/native shells.'

# E3 OFF yields presentation only; Biology-wide barless-health and scanner policy stay independent.
Check (-not $source.health.Contains('UseE3FirstPersonHudVisuals')) 'Healthbar suppression is incorrectly controlled by the E3 preference.'
Check ($source.health.Contains('CRRealpassSettings.IsEnabled(GetGameInstance())')) 'Healthbar suppression lost its Biology-wide master gate.'
Check ($contract.releaseProfile.traditionalActorHealthBarsFinalTarget -eq $false) 'Contract reintroduced traditional actor health bars as an E3 toggle behavior.'
Check ($contract.releaseProfile.nativeModernScanner -eq $true) 'Contract no longer protects the modern native scanner.'
$controls = @($contract.publicControls)
Check ($controls.Count -eq 1) 'E3 preference is no longer the sole in-game public preference.'
Check ($controls[0].id -eq 'presentation.e3-first-person-hud-visuals' -and $controls[0].authority -eq 'presentation-only') 'E3 preference no longer has presentation-only authority.'
Check ($source.preferenceUi.Contains('E3 HUD + NAMEPLATES') -and $source.preferenceUi.Contains('ToggleE3FirstPersonHudVisuals')) 'Biology-owned E3 preference editor lost its control/persistence path.'
Check (-not ($source.settings -match '(?i)ModSettings|runtimeProperty|ModuleExists')) 'Provider registration returned to production settings source.'

# Durable archaeology must reflect W03.2 rather than the obsolete “prompts/activity absent” decision.
foreach ($needle in @('interactionWidgetGameController','activityLogEntryLogicController','gameuiCrosshairContainerController','SetElementVisibility','modern scanner','W13')) {
    Check ($mapping.Contains($needle)) "W03.2 component mapping lost required audited responsibility/evidence: $needle"
}
Check ($mapping.Contains('dialogue') -and $mapping.Contains('intentionally not ported')) 'Dialogue audit/decision is not documented rather than silently ignored.'
Check ($presentation.Contains('presentation/hook behavior problem') -and $presentation.Contains('owned overlays')) 'Canonical E3 presentation contract does not record the W13/W03.2 correction.'

$allowed = @($seams.allowedHookFiles)
foreach ($file in @('E3FirstPersonHud.reds','E3QuestHudNative.reds','E3NavigationHudNative.reds','E3WeaponHudNative.reds','E3CrosshairHudNative.reds','E3HotkeyHudNative.reds','E3InteractionHudNative.reds','E3ActivityHudNative.reds','E3NameplatesNative.reds','NameplatesNative.reds')) {
    Check ($allowed -contains $file) "W03.2 native presentation seam is not registered in the 2.31 boundary allowlist: $file"
}

Write-Host "PASS: $script:checks W03.2 E3 live-presentation checks; ordinary HUD responsibilities are materially covered by reversible Biology-owned presentation, ambient names are not scanner-gated, health policy is independent, and modern scanner/quickhack remains native-owned."
