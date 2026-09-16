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
    nameplate = Join-Path $sourceRoot 'E3NameplatesNative.reds'
    identity = Join-Path $sourceRoot 'NameplatesNative.reds'
    health = Join-Path $sourceRoot 'NoHealthbars.reds'
    settings = Join-Path $sourceRoot 'RealpassSettings.reds'
    preferenceUi = Join-Path $sourceRoot 'BiologyPreferencesNative.reds'
    primitives = Join-Path $sourceRoot 'E3PresentationPrimitives.reds'
}
$mappingPath = Join-Path $project 'docs/E3-COMPONENT-MAPPING.md'
$seams = Get-Content -Raw -LiteralPath (Join-Path $project 'manifest/native-seams.json') | ConvertFrom-Json
$contract = Get-Content -Raw -LiteralPath (Join-Path $project 'manifest/settings.json') | ConvertFrom-Json
$script:checks = 0
function Check($condition,[string]$message) { if (-not $condition) { throw $message }; $script:checks++ }

foreach ($path in @($paths.Values) + @($mappingPath)) {
    Check (Test-Path -LiteralPath $path -PathType Leaf) "Missing E3 presentation contract/source: $path"
}

$source = @{}
foreach ($key in $paths.Keys) { $source[$key] = Get-Content -Raw -LiteralPath $paths[$key] }
$mapping = Get-Content -Raw -LiteralPath $mappingPath

# Clarified scope: persistent neutral first-person HUD plus NPC nameplates only.
foreach ($key in @('quest','navigation','weapon','crosshair','hotkey')) {
    Check ($source[$key].Contains('CRRealpassSettings.UseE3FirstPersonHudVisuals(GetGameInstance())')) "$key neutral-HUD seam is not gated by the single E3 presentation preference."
    Check ($source[$key].Contains('TintNeutralHudRoot')) "$key neutral-HUD seam does not visibly restyle the native root in the red/minimal language."
}
Check ($source.quest.Contains('@wrapMethod(QuestTrackerGameController)')) 'Persistent quest/objective tracker is not part of the neutral E3 HUD implementation.'
Check ($source.navigation.Contains('@wrapMethod(MinimapContainerController)')) 'Persistent minimap/navigation host is not part of the neutral E3 HUD implementation.'
Check ($source.navigation.Contains('protected cb func OnInitialize() -> Bool')) 'Current minimap adapter lost the directly established 2.31 initialization seam.'
Check (-not $source.navigation.Contains('@wrapMethod(IronsightGameController)')) 'Navigation styling still relies on the weapon/ironsight controller instead of the current minimap host.'
Check ($source.weapon.Contains('@wrapMethod(WeaponRosterGameController)')) 'Persistent weapon/ammo roster is not part of the neutral E3 HUD implementation.'
Check ($source.crosshair.Contains('@wrapMethod(CrosshairGameController_Tech_Hex)')) 'Ordinary applicable crosshair presentation is not part of the neutral E3 HUD implementation.'
Check ($source.hotkey.Contains('@wrapMethod(HotkeysWidgetController)')) 'Persistent quick-slot/D-pad presentation is not part of the neutral E3 HUD implementation.'
Check ($mapping.Contains('neutral first-person HUD') -and $mapping.Contains('quest/objective tracker') -and $mapping.Contains('Context-specific systems')) 'Durable E3 archaeology mapping does not record the clarified neutral-HUD-only scope.'
Check (-not (Test-Path -LiteralPath (Join-Path $sourceRoot 'E3InteractionHudNative.reds'))) 'Contextual interaction/dialogue E3 implementation leaked into the clarified neutral-HUD scope.'
Check (-not (Test-Path -LiteralPath (Join-Path $sourceRoot 'E3ActivityHudNative.reds'))) 'Contextual activity-log E3 implementation leaked into the clarified neutral-HUD scope.'

# Existing lower-left slice remains presentation-only, never a replacement health meter.
Check ($source.lowerLeft.Contains('CRBiologyE3HudFrame')) 'Lower-left E3 HUD root is missing.'
Check ($source.lowerLeft.Contains('CRRealpassSettings.UseE3FirstPersonHudVisuals(GetGameInstance())')) 'Lower-left E3 HUD is not presentation-preference gated.'
foreach ($forbidden in @('StatPoolType.Health','GetStatPoolValue','SetStatPoolValue','ApplyDamage','ProcessLocalizedDamage')) {
    Check (-not $source.lowerLeft.Contains($forbidden)) "Lower-left E3 HUD incorrectly became a health-state surface: $forbidden"
}

# Ambient nameplates: baseline civilian presentation is not scanner-gated; richer native
# incoming identity still wins and the native screen-projection lifecycle is reused.
Check ($source.identity.Contains('CRResolveBiologyAmbientName')) 'Owned ambient identity resolver is missing.'
Check ($source.identity.Contains('if IsStringValid(data.name)')) 'Native focus/nameplate identity does not explicitly win.'
Check (-not $source.identity.Contains('npc.IsScanned()')) 'Ambient civilian identity is still structurally scanner-only.'
Check ($source.identity.Contains('t"UINameplate.CrowdSettings"')) 'Ambient public civilian fallback is not constrained to the native public crowd nameplate record.'
Check ($source.identity.Contains('ps.HasAlternativeName()')) 'Ambient fallback can reveal an authored alternative identity.'
Check ($source.identity.Contains('preset.ShoulShowName()')) 'Ambient fallback ignores native identity visibility permission.'
Check ($source.nameplate.Contains('@wrapMethod(NpcNameplateGameController)')) 'Ambient E3 nameplate does not use the native screen-projection lifecycle.'
Check ($source.nameplate.Contains('protected cb func OnScreenProjectionUpdate(projections: ref<gameuiScreenProjectionsData>) -> Void')) 'NpcNameplateGameController projection seam drifted from the inspected Project E3 2.31.p2/native signature.'
Check ($source.nameplate.Contains('CRRealpassSettings.UseE3FirstPersonHudVisuals(GetGameInstance())')) 'Projection-level display-name reveal is not gated by the E3 presentation preference.'
Check ($source.nameplate.Contains('this.m_bufferedCharacterNamePlateRecord') -and $source.nameplate.Contains('this.GetNameplateVisible()')) 'Projection adapter no longer uses the exact native visibility/record gates evidenced by Project E3 2.31.p2.'
Check ($source.nameplate.Contains('inkWidgetRef.SetVisible(this.m_displayName, true)')) 'Ambient nameplate never makes the native display-name surface available during ordinary focus.'
Check (-not $source.nameplate.Contains('m_bufferedGameObject') -and -not $source.nameplate.Contains('m_visualController')) 'Projection adapter widened beyond fields evidenced by the supplied Project E3 2.31.p2 seam.'
Check ($source.nameplate.Contains('this.m_nameTextMain') -and $source.nameplate.Contains('this.m_nameFrame')) 'E3 nameplate does not style the native identity text/frame; a narrow red strip alone is insufficient.'
Check ($source.nameplate.Contains('SetLetterCase(textLetterCase.UpperCase)')) 'E3 nameplate lacks the restrained uppercase identity treatment.'
Check ($source.nameplate.Contains('CRBiologyE3Primitives.Red()')) 'E3 nameplate does not use the shared red/minimal visual language.'
foreach ($forbidden in @('m_healthbarWidget','m_damagePreviewWidget','currentHealth','maximumHealth','StatPoolType.Health')) {
    Check (-not $source.nameplate.Contains($forbidden)) "E3 nameplate incorrectly absorbed health-meter ownership: $forbidden"
}
Check (-not $source.identity.Contains('SetTintColor(')) 'Identity-resolution seam absorbed presentation styling instead of remaining data-only.'

# Modern scanner/quickhack is a hard exclusion across every executing E3 presentation file.
$combined = ($source.Keys | ForEach-Object { $source[$_] }) -join "`n"
foreach ($forbidden in @('ScannerGameController','scannerGameController','ScannerDetailsGameController','ScannerNPCHeaderGameController','quickhackWidgetGameController','QuickHackGameController','scanner.inkwidget','scanner_details.inkwidget','scanner_hud.inkwidget','base\\gameplay\\gui\\widgets\\scanner')) {
    Check (-not $combined.Contains($forbidden)) "Owned E3 presentation crossed the modern scanner/quickhack boundary: $forbidden"
}
foreach ($forbidden in @('module ProjectE3','import ProjectE3','patches/project-e3-hud','DarkFuture.','import DarkFuture','basegame_3e_demo_hud.archive')) {
    Check (-not $combined.Contains($forbidden)) "Owned E3 runtime gained forbidden source-mod/archive dependency: $forbidden"
}
Check (-not $combined.Contains('ResRef.FromString')) 'Owned E3 presentation depends on external E3 UI resources instead of Biology-owned INK/native shells.'

# E3 OFF yields presentation only; Biology-wide barless-health and scanner policy are independent.
Check (-not $source.health.Contains('UseE3FirstPersonHudVisuals')) 'Healthbar suppression is incorrectly controlled by the E3 preference.'
Check ($source.health.Contains('CRRealpassSettings.IsEnabled(GetGameInstance())')) 'Healthbar suppression lost its Biology-wide master gate.'
Check ($contract.releaseProfile.traditionalActorHealthBarsFinalTarget -eq $false) 'Contract reintroduced traditional actor health bars as an E3 toggle behavior.'
Check ($contract.releaseProfile.nativeModernScanner -eq $true) 'Contract no longer protects the modern native scanner.'
$controls = @($contract.publicControls)
Check ($controls.Count -eq 1) 'E3 preference is no longer the sole in-game public preference.'
Check ($controls[0].id -eq 'presentation.e3-first-person-hud-visuals' -and $controls[0].authority -eq 'presentation-only') 'E3 preference no longer has presentation-only authority.'
Check ($controls[0].displayName -eq 'E3-inspired HUD + nameplates') 'Player-facing E3 preference label drifted.'
Check ($contract.surface.provider -eq 'biology-owned-body-shell' -and $contract.surface.publicMasterEnable -eq $false) 'E3 preference contract regressed to an external provider or in-game master control.'
Check ($source.preferenceUi.Contains('E3 HUD + NAMEPLATES') -and $source.preferenceUi.Contains('ToggleE3FirstPersonHudVisuals')) 'Biology-owned E3 preference editor lost its player-facing control or persistence toggle path.'
Check (-not ($source.settings -match '(?i)ModSettings|runtimeProperty|ModuleExists')) 'Provider registration returned to production settings source.'

$allowed = @($seams.allowedHookFiles)
foreach ($file in @('E3FirstPersonHud.reds','E3QuestHudNative.reds','E3NavigationHudNative.reds','E3WeaponHudNative.reds','E3CrosshairHudNative.reds','E3HotkeyHudNative.reds','E3NameplatesNative.reds')) {
    Check ($allowed -contains $file) "Neutral E3 native seam is not registered in the 2.31 boundary allowlist: $file"
}

Write-Host "PASS: $script:checks Biology E3 follow-up checks; persistent neutral HUD and ambient nameplates are gated by the sole save-backed presentation preference, health policy is independent, and scanner/quickhack remains native-owned."
