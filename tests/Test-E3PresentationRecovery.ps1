$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\tools\Common.ps1"
$project = Get-ProjectRoot
$sourceRoot = Join-Path $project 'src\redscript\CyberpunkRealism'
$script:checks = 0
function Check($condition,[string]$message) { if (-not $condition) { throw $message }; $script:checks++ }
function Text([string]$name) { return Get-Content -Raw -LiteralPath (Join-Path $sourceRoot $name) }

$settings = Text 'RealpassSettings.reds'
$preference = Text 'BiologyPreferencesNative.reds'
$lowerLeft = Text 'E3FirstPersonHud.reds'
$hotkey = Text 'E3HotkeyHudNative.reds'
$navigation = Text 'E3NavigationHudNative.reds'
$interaction = Text 'E3InteractionHudNative.reds'
$activity = Text 'E3ActivityHudNative.reds'
$crosshair = Text 'E3CrosshairHudNative.reds'
$quest = Text 'E3QuestHudNative.reds'
$weapon = Text 'E3WeaponHudNative.reds'
$nameplate = Text 'E3NameplatesNative.reds'
$identity = Text 'NameplatesNative.reds'
$primitives = Text 'E3PresentationPrimitives.reds'

# ---------------------------------------------------------------------------
# W20.3 root-cause guard: never recreate the rejected autonomous activation trap.
# Pre-autonomous startup treated missing early save authority as the default-ON value.
# The rejected release made that false AND lazy-created frames only while true, so an
# early HUD-controller init could permanently miss its Biology presentation tree.
# ---------------------------------------------------------------------------
Check ($settings -match '!\s*IsDefined\(settings\)\s*\|\|\s*settings\.e3FirstPersonHudVisuals') 'Early missing settings no longer preserve the canonical default-ON startup contract.'
Check (-not ($settings -match 'IsDefined\(settings\)\s*&&\s*settings\.e3FirstPersonHudVisuals')) 'Rejected autonomous fail-closed E3 startup gate returned.'
Check ($settings.Contains('public class CRBiologyE3PreferenceChangedEvent extends Event {}')) 'Stateless E3 presentation refresh event is missing.'
Check ($settings.Contains('private func OnAttach() -> Void') -and $settings.Contains('private func OnRestored(saveVersion: Int32, gameVersion: Int32) -> Void')) 'Saved preference lifecycle does not reconcile live HUD controllers.'
Check ($settings.Contains('ui.QueueEvent(new CRBiologyE3PreferenceChangedEvent());')) 'Saved preference changes do not fan out through the native UI event system.'
Check ($settings.Contains('return Equals(settings.e3FirstPersonHudVisuals, enabled);')) 'OFF writes are still confused with failed writes.'

$frameSources = @($lowerLeft,$hotkey,$navigation,$interaction,$quest,$weapon)
foreach ($entry in $frameSources) {
    Check (-not ($entry -match 'if\s+enabled\s*\{\s*this\.CRCreateBiologyE3')) 'Rejected lazy E3 frame creation returned.'
}

# Native UI event naming convention: FooEvent is delivered to OnFoo, not OnFooEvent.
foreach ($entry in @($lowerLeft,$hotkey,$navigation,$interaction,$activity,$crosshair,$quest,$weapon,$nameplate)) {
    Check ($entry.Contains('OnCRBiologyE3PreferenceChanged(evt: ref<CRBiologyE3PreferenceChangedEvent>)')) 'A live E3 controller is not wired to the native preference-change event callback name.'
    Check (-not $entry.Contains('OnCRBiologyE3PreferenceChangedEvent(')) 'Rejected Event-suffixed callback name returned and would not match native UI event dispatch.'
    $handlerStart = $entry.IndexOf('protected cb func OnCRBiologyE3PreferenceChanged(')
    $handlerTail = $entry.Substring($handlerStart)
    Check ($handlerTail.Contains('return false;')) 'Stateless E3 refresh notification consumes UI-event propagation instead of remaining broadcast-safe.'
}

# ---------------------------------------------------------------------------
# Meaningful E3 ON paths must still exist. The public setting is not allowed to become
# a state-only control disconnected from presentation.
# ---------------------------------------------------------------------------
Check ($lowerLeft.Contains('CRBiologyE3HudFrame') -and $lowerLeft.Contains('AddPanelChrome') -and $lowerLeft.Contains('"BIOLOGY"')) 'Lower-left E3 presentation path is missing.'
Check ($hotkey.Contains('this.m_dpadHintsPanel') -and $hotkey.Contains('AddSegmentedRegionChrome')) 'D-pad/quick-slot E3 presentation path is missing.'
Check ($quest.Contains('this.m_questTrackerContainer') -and $quest.Contains('this.m_QuestTitle') -and $quest.Contains('QuestTrackerObjectiveLogicController') -and $quest.Contains('this.m_objectiveTitle')) 'Quest/objective E3 presentation path is incomplete.'
Check ($weapon.Contains('this.m_onFootContainer') -and $weapon.Contains('this.m_weaponName') -and $weapon.Contains('this.m_weaponCurrentAmmo') -and $weapon.Contains('this.m_weaponTotalAmmo')) 'Weapon/ammo E3 presentation path is incomplete.'
Check ($nameplate.Contains('this.m_nameTextMain') -and $nameplate.Contains('this.m_nameFrame') -and $nameplate.Contains('CRPublicAmbientNameAllowed')) 'Ambient authored nameplate E3 presentation path is incomplete.'
Check ($crosshair.Contains('this.GetRootWidget()') -and $crosshair.Contains('CRBiologyE3Primitives.Red()')) 'Native ordinary crosshair E3 tint path is missing.'
Check (-not $crosshair.Contains('new inkCanvas()') -and -not $crosshair.Contains('CRBiologyE3FocusFrame')) 'Old custom reticle geometry returned.'

# ---------------------------------------------------------------------------
# OFF must restore native/current state, not merely hide the preference value.
# ---------------------------------------------------------------------------
Check ($quest.Contains('CRRestoreBiologyE3QuestStyle') -and $quest.Contains('this.crBiologyE3HasObjectiveStyle = false;') -and $quest.Contains('this.crBiologyE3HasNativeQuestTitleTint = false;')) 'Quest OFF path cannot recapture/restore current native styling per lifecycle.'
Check ($weapon.Contains('CRRestoreBiologyE3WeaponTints') -and $weapon.Contains('this.crBiologyE3HasNativeWeaponTints = false;')) 'Weapon OFF path can retain stale native tint capture.'
Check ($crosshair.Contains('CRRestoreBiologyE3CrosshairTint') -and $crosshair.Contains('this.crBiologyE3HasNativeCrosshairTint = false;')) 'Crosshair OFF path can retain stale native tint capture.'
Check ($activity.Contains('CRRestoreBiologyE3Activity') -and $activity.Contains('this.crBiologyE3HasNativeActivityTint = false;')) 'Activity OFF path can retain stale native tint capture.'
Check (-not $activity.Contains('SetLetterCase(')) 'Activity log still mutates letter case without a native restoration authority.'
Check ($nameplate.Contains('CRRestoreBiologyE3NameplateStyle') -and $nameplate.Contains('this.crBiologyE3HasNativeNameTint = false;') -and $nameplate.Contains('this.crBiologyE3HasNativeFrameStyle = false;')) 'Nameplate OFF path can retain stale style capture.'
Check (-not $nameplate.Contains('SetLetterCase(') -and -not $nameplate.Contains('SetFontStyle(')) 'Nameplate still mutates uncaptured text style across OFF.'
Check ($nameplate.Contains('SNameplateRangesData.GetDisplayRangeNotAggressive()') -and $nameplate.Contains('SNameplateRangesData.GetMaxDisplayRangeNotAggressive()')) 'Nameplate OFF path cannot restore native range.'
foreach ($entry in @($lowerLeft,$hotkey,$navigation,$interaction,$quest,$weapon)) {
    Check ($entry -match 'SetVisible\(enabled\)|SetVisible\(CRRealpassSettings\.UseE3FirstPersonHudVisuals') 'Custom E3 chrome lacks an explicit OFF visibility path.'
}

# ---------------------------------------------------------------------------
# W20.2 local preference layout remains, but T007 click ownership is repaired.
# ---------------------------------------------------------------------------
Check ($preference.Contains('CRMountBiologyE3PreferenceInNativeContent(host: ref<inkVerticalPanel>)')) 'W20.2 local Biology preference host was lost.'
Check (-not $preference.Contains('GetRootCompoundWidget') -and -not $preference.Contains('inkEAnchor.TopRight')) 'Preference regressed to a floating fullscreen control.'
Check ($preference.Contains('row.SetSize(Vector2(680.0, 48.0));') -and $preference.Contains('row.SetInteractive(true);')) 'Preference row lost its usable local hit target.'
Check ($preference.Contains('widget.SetInteractive(false);') -and $preference.Contains('background.SetInteractive(false);')) 'Decorative preference children can still own pointer input.'
Check (-not $preference.Contains('GetCurrentTarget() != this.crBiologyE3PreferenceRow')) 'T007 current-target click rejection returned.'
Check ($preference.Contains('CRRealpassSettings.ToggleE3FirstPersonHudVisuals(player.GetGame())')) 'Preference does not write the single player-session saved authority.'
Check ($preference.Contains('this.CRRefreshBiologyE3Preference();')) 'Preference does not update visible ON/OFF state immediately.'

# ---------------------------------------------------------------------------
# T007 scanner identity authority: scanner detailed identity wins. Biology only gates
# its projected ambient nameplate through existing native nameplate scanner state.
# ---------------------------------------------------------------------------
Check ($nameplate.Contains('public let crBiologyE3ScannerActive: Bool;')) 'Ambient nameplate has no scanner ownership state.'
Check ($nameplate.Contains('this.m_isScanning') -and $nameplate.Contains('CRSyncBiologyE3IdentityOwner')) 'Native nameplate scanner state does not drive Biology ambient ownership.'
Check ($nameplate.Contains('inkWidgetRef.SetVisible(this.m_displayName, false);')) 'Conflicting ambient projected identity is not suppressed during scanner ownership.'
Check ($identity.Contains('this.crBiologyE3ScannerActive')) 'Ambient fallback remains available during scanner ownership.'
Check ($identity.Contains('this.m_forceHide') -and $identity.Contains('this.m_npcNamesEnabled')) 'Ambient fallback ignores native nameplate visibility policy.'
Check ($identity.Contains('return data.name;')) 'Native discovered identity no longer wins.'
Check (-not $nameplate.Contains('data.name =')) 'Biology presentation fallback is written into native scanner/nameplate knowledge.'
Check ($nameplate.Contains('this.SetVisualData(this.crBiologyE3LastPuppet, this.crBiologyE3LastData);')) 'Ownership changes do not restore native identity from unchanged native data.'

# Modern scanner/quickhack remains a hard exclusion: m_isScanning on the nameplate
# controller is allowed; scanner controller/resources are not.
$combined = @($settings,$preference,$lowerLeft,$hotkey,$navigation,$interaction,$activity,$crosshair,$quest,$weapon,$nameplate,$identity,$primitives) -join [Environment]::NewLine
foreach ($forbidden in @(
    'ScannerGameController','scannerGameController','ScannerDetailsGameController',
    'ScannerNPCHeaderGameController','quickhackWidgetGameController','QuickHackGameController',
    'scanner.inkwidget','scanner_details.inkwidget','scanner_hud.inkwidget',
    'base\gameplay\gui\widgets\scanner'
)) {
    Check (-not $combined.Contains($forbidden)) "W20.3 crossed the native scanner/quickhack boundary: $forbidden"
}

foreach ($forbidden in @(
    'module ProjectE3','import ProjectE3','basegame_3e_demo_hud.archive',
    'patches/project-e3-hud','DarkFuture.','import DarkFuture',
    'ModSettings','mod_settings','ArchiveXL','RED4ext'
)) {
    Check (-not $combined.Contains($forbidden)) "W20.3 introduced a forbidden E3/settings runtime dependency: $forbidden"
}

Write-Host "PASS: $script:checks W20.3 E3 recovery checks; meaningful native-hosted ON paths, immediate single-authority refresh, reversible OFF state, T007 preference click repair and scanner-over-ambient identity ownership are all source-enforced."
