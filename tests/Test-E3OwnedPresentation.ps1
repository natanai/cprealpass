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
    Check (Test-Path -LiteralPath $path -PathType Leaf) "Missing W03.3 E3 presentation contract/source: $path"
}

$source = @{}
foreach ($key in $paths.Keys) { $source[$key] = Get-Content -Raw -LiteralPath $paths[$key] }
$mapping = Get-Content -Raw -LiteralPath $mappingPath
$presentation = Get-Content -Raw -LiteralPath $presentationPath

Check ($source.primitives.Contains('CreateFillShell') -and $source.primitives.Contains('SetAnchor(inkEAnchor.Fill)')) 'Shared primitives do not provide root-fitted E3 shells.'
Check ($source.primitives.Contains('AddFillWash')) 'Shared primitives do not provide a root-fitted E3 wash.'
Check (-not $source.primitives.Contains('TintNeutralHudRoot')) 'Native-root tint mutation path returned.'
foreach ($key in @('lowerLeft','quest','navigation','weapon','hotkey','interaction')) {
    Check ($source[$key].Contains('CreateFillShell')) "$key still relies on a guessed fixed-size HUD shell instead of the actual native root."
    Check ($source[$key].Contains('UseE3FirstPersonHudVisuals(GetGameInstance())')) "$key presentation seam is not gated by the single E3 preference."
}
foreach ($key in @('quest','navigation','weapon','hotkey','interaction')) {
    Check ($source[$key].Contains('AddFillWash')) "$key lacks the materially visible root-fitted E3 treatment."
}

Check ($source.quest.Contains('@wrapMethod(QuestTrackerGameController)') -and $source.quest.Contains('OBJECTIVES // ACTIVE')) 'Quest/objective tracker lost the coherent E3 shell.'
Check ($source.navigation.Contains('@wrapMethod(MinimapContainerController)') -and $source.navigation.Contains('NAV // ROUTE')) 'Current minimap host lost the coherent E3 shell.'
Check (-not $source.navigation.Contains('@wrapMethod(IronsightGameController)')) 'Navigation styling regressed to the historical Project E3 ironsight host.'
Check ($source.weapon.Contains('@wrapMethod(WeaponRosterGameController)') -and $source.weapon.Contains('WEAPON // AMMO')) 'Weapon/ammo roster lost the coherent E3 shell.'
Check ($source.hotkey.Contains('@wrapMethod(HotkeysWidgetController)') -and $source.hotkey.Contains('QUICK // INPUT')) 'Quick-slot/D-pad surface lost the coherent E3 shell.'
Check ($source.interaction.Contains('@wrapMethod(interactionWidgetGameController)') -and $source.interaction.Contains('INTERACTION // ACTION')) 'Ordinary interaction prompt lost the coherent E3 shell.'
Check ($source.interaction.Contains('protected cb func OnUpdateInteraction(argValue: Variant) -> Bool')) 'Interaction adapter lost the established current update seam.'
Check (-not $source.interaction.Contains('@replaceMethod') -and -not $source.interaction.Contains('FromVariant<InteractionChoiceHubData>') -and -not $source.interaction.Contains('AsyncSpawnFromLocal')) 'Interaction presentation took over native choice/input behavior.'

Check ($source.crosshair.Contains('@wrapMethod(gameuiCrosshairContainerController)')) 'General current crosshair container is not covered.'
Check ($source.crosshair.Contains('CRBiologyE3FocusFrame')) 'General crosshair/focus frame is missing.'
Check (-not $source.crosshair.Contains('CrosshairGameController_Tech_Hex')) 'Tech-Hex duplicate crosshair treatment survived W03.3 artifact cleanup.'
foreach ($forbidden in @('@replaceMethod(gameuiCrosshairContainerController)','protected cb func OnPSMVisionStateChanged','GetActiveCrosshairGameController()')) {
    Check (-not $source.crosshair.Contains($forbidden)) "Crosshair styling took over native crosshair/vision behavior: $forbidden"
}

Check ($source.activity.Contains('@wrapMethod(activityLogEntryLogicController)')) 'Transient activity presentation is not covered.'
Check ($source.activity.Contains('textLetterCase.UpperCase') -and $source.activity.Contains('CRBiologyE3Primitives.Red()')) 'Activity entries do not use the shared E3 text language.'
Check ($source.activity.Contains('crBiologyE3NativeActivityTint') -and $source.activity.Contains('public final func SetText(const displayText: script_ref<String>) -> Void')) 'Activity presentation cannot restore native tint when E3 is off for reused entries.'
Check (-not $source.activity.Contains('@replaceMethod') -and -not $source.activity.Contains('new inkAnimController')) 'Activity styling took over native queue/animation behavior.'

Check ($source.identity.Contains('CRPublicAmbientNameAllowed')) 'W03.3 ambient identity helper is missing.'
Check (-not $source.identity.Contains('@wrapMethod')) 'Identity helper still adds a second SetVisualData wrapper.'
Check (-not $source.identity.Contains('npc.IsCharacterCivilian()')) 'Police/combatants remain excluded from the ambient public-name path.'
Check ($source.nameplate.Contains('public final func IsAnyElementVisible() -> Bool')) 'Nameplate adapter does not correct the native IsAnyElementVisible root-hide bottleneck.'
Check ($source.nameplate.Contains('CRBiologyE3ShouldShowAmbientName')) 'Nameplate root visibility is not connected to legitimate ambient identity.'
Check ($source.nameplate.Contains('private func SetElementVisibility(const incomingData: script_ref<NPCNextToTheCrosshair>) -> Void')) 'Nameplate adapter does not refresh after native visibility evaluation.'
Check ($source.nameplate.Contains('wrappedMethod(incomingData)')) 'Nameplate visibility lifecycle was replaced rather than wrapped.'
Check ($source.nameplate.Contains('this.m_nameTextMain') -and $source.nameplate.Contains('this.m_nameFrame')) 'W03.3 no longer uses native projected identity text/frame.'
Check (-not $source.nameplate.Contains('CRBiologyE3NameplateFrame') -and -not $source.nameplate.Contains('CRBiologyE3NameText')) 'Oversized custom projected nameplate box survived the attended artifact repair.'
Check ($source.nameplate.Contains('@wrapMethod(NpcNameplateGameController)')) 'Ambient nameplate no longer reuses native screen projection.'
Check ($source.nameplate.Contains('this.GetNameplateVisible()')) 'Projection adapter lost native root visibility authority.'
Check ($source.nameplate.Contains('inkWidgetRef.SetVisible(this.m_displayName, true)')) 'Projection adapter does not expose the native display-name surface when the native root is visible.'
Check ($source.nameplate.Contains('this.c_DisplayRangeNotAggressive = 10.0') -and $source.nameplate.Contains('this.c_MaxDisplayRangeNotAggressive = 20.0')) 'E3 ambient non-aggressive projection range is not restored to the intended ordinary-look envelope.'
Check ($source.nameplate.Contains('SNameplateRangesData.GetDisplayRangeNotAggressive()') -and $source.nameplate.Contains('SNameplateRangesData.GetMaxDisplayRangeNotAggressive()')) 'E3 OFF cannot restore native non-aggressive nameplate range.'
Check ($source.nameplate.Contains('crBiologyE3NativeFrameVisible') -and $source.nameplate.Contains('crBiologyE3NativeFrameOpacity')) 'E3 OFF does not preserve/restore native name-frame visibility and opacity after W03.3 styling.'
foreach ($forbidden in @('m_healthbarWidget','m_damagePreviewWidget','currentHealth','maximumHealth','StatPoolType.Health')) {
    Check (-not $source.nameplate.Contains($forbidden)) "E3 nameplate absorbed health-meter ownership: $forbidden"
}

Check ($source.primitives.Contains('[Biology:E3]')) 'W03.3 presentation hook trace prefix is missing.'
foreach ($key in @('lowerLeft','quest','navigation','weapon','hotkey','interaction','activity','crosshair','nameplate')) {
    Check ($source[$key].Contains('CRBiologyE3Primitives.Trace(')) "$key lacks W03.3 live hook-execution trace evidence."
}

$combined = ($source.Keys | ForEach-Object { $source[$_] }) -join [Environment]::NewLine
foreach ($forbidden in @('ScannerGameController','scannerGameController','ScannerDetailsGameController','ScannerNPCHeaderGameController','quickhackWidgetGameController','QuickHackGameController','scanner.inkwidget','scanner_details.inkwidget','scanner_hud.inkwidget','base\gameplay\gui\widgets\scanner')) {
    Check (-not $combined.Contains($forbidden)) "Owned E3 presentation crossed the modern scanner/quickhack boundary: $forbidden"
}
foreach ($forbidden in @('module ProjectE3','import ProjectE3','patches/project-e3-hud','DarkFuture.','import DarkFuture','basegame_3e_demo_hud.archive')) {
    Check (-not $combined.Contains($forbidden)) "Owned E3 runtime gained forbidden source-mod/archive dependency: $forbidden"
}
Check (-not $combined.Contains('ResRef.FromString')) 'Owned E3 presentation depends on external E3 UI resources.'

Check (-not $source.health.Contains('UseE3FirstPersonHudVisuals')) 'Healthbar suppression is incorrectly controlled by the E3 preference.'
Check ($source.health.Contains('CRRealpassSettings.IsEnabled(GetGameInstance())')) 'Healthbar suppression lost its Biology-wide activation gate.'
Check ($contract.releaseProfile.traditionalActorHealthBarsFinalTarget -eq $false) 'Traditional actor health bars were reintroduced.'
Check ($contract.releaseProfile.nativeModernScanner -eq $true) 'Contract no longer protects the modern native scanner.'
$controls = @($contract.publicControls)
Check ($controls.Count -eq 1) 'E3 preference is no longer the sole in-game public preference.'
Check ($controls[0].id -eq 'presentation.e3-first-person-hud-visuals' -and $controls[0].authority -eq 'presentation-only') 'E3 preference no longer has presentation-only authority.'
Check ($source.preferenceUi.Contains('E3 HUD + NAMEPLATES') -and $source.preferenceUi.Contains('ToggleE3FirstPersonHudVisuals')) 'Biology-owned E3 preference editor lost its player-facing control/persistence path.'

foreach ($needle in @('205578b11d818f474dc74a873e6d6ea5a1e1accd','IsAnyElementVisible','root-fitted','red rectangle','W03.3')) {
    Check ($presentation.Contains($needle)) "Canonical W03.3 presentation contract is missing attended diagnosis: $needle"
}
foreach ($needle in @('W03.3','IsAnyElementVisible','3','10','20','Tech-Hex')) {
    Check ($mapping.Contains($needle)) "Component mapping is missing W03.3 corrective evidence: $needle"
}

$allowed = @($seams.allowedHookFiles)
foreach ($file in @('E3FirstPersonHud.reds','E3QuestHudNative.reds','E3NavigationHudNative.reds','E3WeaponHudNative.reds','E3CrosshairHudNative.reds','E3HotkeyHudNative.reds','E3InteractionHudNative.reds','E3ActivityHudNative.reds','E3NameplatesNative.reds','NoHealthbars.reds')) {
    Check ($allowed -contains $file) "W03.3 native presentation seam is not registered in the 2.31 boundary allowlist: $file"
}

Write-Host "PASS: $script:checks W03.3 E3 functional-follow-up checks; native-root-fitted HUD shells, ambient NPC root visibility, artifact cleanup, reversible ON/OFF behavior and modern scanner preservation are explicit."
