$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\tools\Common.ps1"
$project = Get-ProjectRoot
$script:checks = 0

function Check($condition,[string]$message) {
    if (-not $condition) { throw $message }
    $script:checks++
}
function Read-Project([string]$relative) {
    $path = Join-Path $project $relative
    Check (Test-Path -LiteralPath $path -PathType Leaf) "Missing W04.2 persistence source: $relative"
    return Get-Content -Raw -LiteralPath $path
}

$runtime = Read-Project 'src/redscript/CyberpunkRealism/BodyRuntime.reds'
$authority = Read-Project 'src/redscript/CyberpunkRealism/BodyRuntimeAuthority.reds'
$availability = Read-Project 'src/redscript/CyberpunkRealism/BiologyRuntimeAvailability.reds'
$sessionPresentation = Read-Project 'src/redscript/CyberpunkRealism/BiologySessionPresentation.reds'
$legacyDetail = Read-Project 'src/redscript/CyberpunkRealism/BiologyDetailPresentation.reds'
$shell = Read-Project 'src/redscript/CyberpunkRealism/BiologyCyberwareShell.reds'
$hooks = Read-Project 'src/redscript/CyberpunkRealism/BodyNativeHooks.reds'
$attendedBootstrap = Read-Project 'tools/Bootstrap-BiologyPostTransitionCandidate.ps1'
$packageBuilder = Read-Project 'tools/Build-BiologyPackage.ps1'

# Authority provenance: deliberate Biology detail must be a projection of the one
# persistent CRBodyRuntime, not a menu-owned or static substitute.
Check ($runtime -match 'public class CRBodyRuntime extends ScriptableSystem') 'CRBodyRuntime is no longer the body ScriptableSystem authority.'
Check ($runtime -match 'private persistent let body: ref<CRBodyState>') 'Authoritative body state is not persistent on CRBodyRuntime.'
Check ($runtime -match 'private persistent let inputs: ref<CRBodyInputQueue>') 'Authoritative body input queue is not persistent on CRBodyRuntime.'
Check ($runtime -match 'private persistent let bodySchemaVersion: Int32') 'Authoritative body schema version is not persistent on CRBodyRuntime.'
Check ($authority -match 'public static func Body\(game: GameInstance\) -> ref<CRBodyRuntime>') 'Explicit session authority no longer resolves CRBodyRuntime.'
Check ($authority -match 'container\.Get\(n"CyberpunkRealism\.Integration\.CRBodyRuntime"\) as CRBodyRuntime') 'Explicit session authority no longer resolves the registered body system.'
Check (-not ($authority -match 'persistent let|new CRBodyState')) 'Session authority introduced a second persistent/substitute body.'

$runtimeLookups = [regex]::Matches($sessionPresentation,'let runtime: ref<CRBodyRuntime> = CRBiologySessionAuthority\.Body\(game\);').Count
$snapshotReads = [regex]::Matches($sessionPresentation,'let body: ref<CRBodyState> = runtime\.GetBodySnapshot\(\);').Count
Check ($runtimeLookups -ge 2) 'Overview/detail projection no longer resolves the authoritative body runtime for each read.'
Check ($snapshotReads -ge 2) 'Overview/detail projection no longer snapshots the authoritative body for each read.'
Check (-not $sessionPresentation.Contains('new CRBodyState')) 'Biology session presentation manufactured substitute body state.'
Check ($shell.Contains('CRBiologySessionPresentation.Detail(player.GetGame(), this.crBiologySelectedArea)')) 'Biology detail does not use the menu player-owned GameInstance.'

# The exact LEGS values observed attended are calculated from the authoritative
# injury state. Guard specifically against replacing these with healthy literals.
Check ($sessionPresentation.Contains('CRInjuryModel.Function(body.injuries, 5) * 100.0')) 'Left-leg function is not derived from authoritative injuries.'
Check ($sessionPresentation.Contains('CRInjuryModel.Function(body.injuries, 6) * 100.0')) 'Right-leg function is not derived from authoritative injuries.'
Check ($sessionPresentation.Contains('(1.0 - body.injuries.leftLeg.boneDamage) * 100.0')) 'Left-leg bone integrity is not derived from authoritative injuries.'
Check ($sessionPresentation.Contains('(1.0 - body.injuries.rightLeg.boneDamage) * 100.0')) 'Right-leg bone integrity is not derived from authoritative injuries.'
Check (-not $sessionPresentation.Contains('Metric("LEFT LEG FUNCTION", 100.0')) 'Left-leg function regressed to a static healthy placeholder.'
Check (-not $sessionPresentation.Contains('Metric("RIGHT LEG FUNCTION", 100.0')) 'Right-leg function regressed to a static healthy placeholder.'
Check (-not $sessionPresentation.Contains('Metric("LEFT BONE INTEGRITY", 100.0')) 'Left bone integrity regressed to a static healthy placeholder.'
Check (-not $sessionPresentation.Contains('Metric("RIGHT BONE INTEGRITY", 100.0')) 'Right bone integrity regressed to a static healthy placeholder.'

# T006 could only prove that the rendered surface looked inert. Whole-percent
# formatting can conceal real early metabolism, so deliberate detail preserves one
# decimal while retaining the exact authoritative Float underneath.
Check ($sessionPresentation.Contains('RoundF(ClampF(value, 0.0, 100.0) * 10.0) / 10.0')) 'Session detail still rounds authoritative percentages to whole integers.'
Check ($legacyDetail.Contains('RoundF(ClampF(value, 0.0, 100.0) * 10.0) / 10.0')) 'Legacy detail projection disagrees with session detail precision.'

# T007 observability stays Biology-owned, transient, bounded and attended-only.
# It must diagnose the existing authority, never become save state or external telemetry.
foreach ($field in @('testTickCount','testProgressCount','testLastObservedHours','testLastNativeAllowed','testCombatEventCount','testLastCombat','testPresentationCount','testLastPresentation')) {
    Check ($runtime -match ('private let ' + $field + ':')) "T007 diagnostic field is not transient: $field"
    Check (-not ($runtime -match ('private persistent let ' + $field + ':'))) "T007 diagnostic field became save-persistent: $field"
}
Check ($runtime.Contains('public func TestCombatStage(')) 'Combat boundary diagnostic surface is missing.'
Check ($runtime.Contains('public func TestPresentationRead(')) 'Presentation readback diagnostic surface is missing.'
Check ($runtime.Contains('if !CRBodyTestPolicy.Diagnostics()')) 'Attended diagnostic surface is not policy-gated.'
Check ($runtime.Contains('this.testCombatEventCount < 10000')) 'Combat diagnostics are not bounded.'
Check ($runtime.Contains('this.testPresentationCount < 10000')) 'Presentation diagnostics are not bounded.'
Check ($sessionPresentation.Contains('runtime.TestPresentationRead("overview");')) 'Overview does not mark authoritative presentation readback.'
Check ($sessionPresentation.Contains('runtime.TestPresentationRead("detail-" + result.title);')) 'Detail does not mark authoritative presentation readback.'
Check ($sessionPresentation.Contains('let testStatus: String = runtime.TestStatus();')) 'Attended projection cannot surface bounded authority status.'
Check ($attendedBootstrap -match "Build-BiologyPackage\.ps1'.*'-Diagnostics'") 'Managed attended candidate does not enable bounded Biology diagnostics.'
Check ($packageBuilder -match '\[switch\]\$Diagnostics') 'Package builder lost explicit diagnostics switch.'
Check ($packageBuilder.Contains('if ($Diagnostics) { $profileArgs.Diagnostics = $true }')) 'Package builder no longer keeps diagnostics opt-in.'
Check (-not ($packageBuilder -match '\[switch\]\$Diagnostics\s*=\s*\$true')) 'Ordinary Biology package builds default diagnostics on.'

# Menu close/reopen is a presentation lifecycle only. Teardown may clear widgets but
# must not suspend, replace, or reset the body authority.
$uninit = [regex]::Match($shell,'(?s)@wrapMethod\(RipperDocGameController\)\s*protected cb func OnUninitialize\(\) -> Bool \{(?<body>.*?)return wrappedMethod\(\);\s*\}')
Check $uninit.Success 'Could not locate Biology shell OnUninitialize lifecycle.'
$uninitBody = $uninit.Groups['body'].Value
foreach ($forbidden in @('CRBodyRuntime','CRBiologySessionAuthority','CRBiologyRuntimeAvailability','Suspend(','Activate(','ResetTransientState','new CRBodyState')) {
    Check (-not $uninitBody.Contains($forbidden)) "Menu teardown mutates body authority through: $forbidden"
}
Check ($shell.Contains('protected cb func OnInitialize() -> Bool')) 'Biology menu initialization hook is missing.'
Check ($shell.Contains('this.CRCreateBiologyShell();')) 'Biology menu reopen no longer rebuilds presentation shell.'
Check ($shell.Contains('this.CRRefreshBiologyOverview();')) 'Biology menu reopen path no longer re-reads runtime-backed overview state.'

# Save/load keeps physiology persistent and rebuilds only transient runtime machinery.
Check ($runtime -match '(?s)private func OnRestored\(saveVersion: Int32, gameVersion: Int32\) -> Void \{\s*this\.ResetTransientState\(\);\s*\}') 'Save restore no longer rebuilds only transient runtime state.'
$resetStart = $runtime.IndexOf('private func ResetTransientState() -> Void {')
$activateStart = $runtime.IndexOf('public func Activate() -> Void {')
Check ($resetStart -ge 0 -and $activateStart -gt $resetStart) 'Could not isolate ResetTransientState for persistence audit.'
$resetBody = $runtime.Substring($resetStart,$activateStart - $resetStart)
foreach ($persistentMutation in @('this.body =','this.inputs =','this.bodySchemaVersion =')) {
    Check (-not $resetBody.Contains($persistentMutation)) "Restore reset mutates persisted physiology: $persistentMutation"
}
Check ($runtime.Contains('if this.bodySchemaVersion == 0 {')) 'Clean-save initialization guard disappeared.'
Check ($runtime -match '(?s)if this\.bodySchemaVersion == 0 \{\s*if IsDefined\(this\.body\) \{\s*return;\s*\}\s*this\.body = CRBodyModel\.Create\(this\.config\);') 'Activate can no longer distinguish clean initialization from restored persisted physiology.'
Check ($availability -match '(?s)public static func EnsureActive\(game: GameInstance\) -> Bool.*?let runtime: ref<CRBodyRuntime> = CRBiologySessionAuthority\.Body\(game\);.*?if !runtime\.IsRunning\(\) \|\| !runtime\.OwnsNeeds\(\) \{\s*runtime\.Activate\(\);') 'Restored session readiness does not reactivate the same authoritative runtime.'

# Normal time, wait, and sleep all feed the same persistent body/input authority.
Check ($runtime.Contains('CRBodyInputs.Time(this.inputs, hours, exertion, sleeping);')) 'Elapsed/sleep time no longer enters the authoritative body input queue.'
Check ($runtime.Contains('CRBodyInputs.Drain(this.inputs, this.body, this.config);')) 'Time progression no longer drains into the persistent body.'
Check ($runtime.Contains('CRClockModel.Observe(this.clock, this.WorldSeconds(), this.SimSeconds(), this.NativeStateAllowed(false))')) 'Normal play-time observation path disappeared.'
Check ($runtime.Contains('CRClockModel.FinishSkip(this.clock, this.WorldSeconds(), this.SimSeconds(), hoursRequested)')) 'Committed wait/sleep clock path disappeared.'
Check ($hooks.Contains('runtime = CRBiologySessionAuthority.Body(player.GetGame());')) 'Wait/sleep UI no longer resolves the player-session body authority.'
Check ($hooks.Contains('runtime.MarkNextTimeSkipAsWait();')) 'Wait classification no longer reaches the body authority.'
Check ($hooks.Contains('this.crRealpassSleeping = runtime.ConsumeNextTimeSkipSleeping();')) 'Sleep/wait classification is no longer consumed by the same body authority.'
Check ($hooks.Contains('runtime.BeginSkip();')) 'Time-skip boundary no longer brackets the authoritative body clock.'
Check ($hooks.Contains('runtime.FinishSkipHours(Cast<Float>(hours), this.crRealpassSleeping);')) 'Committed wait/sleep hours no longer advance the authoritative body.'

# Failure is explicit. STABLE/detail values are unreachable until runtime/body validity
# has been established; a failed detail projection remains invalid for the shell.
foreach ($reason in @(
    'BODY RUNTIME SESSION CONTEXT UNAVAILABLE',
    'BODY RUNTIME SYSTEM NOT REGISTERED',
    'BODY RUNTIME SYSTEM MISSING',
    'BODY RUNTIME PLAYER UNAVAILABLE',
    'BODY SAVE VERSION UNSUPPORTED',
    'BODY RUNTIME NOT INITIALIZED',
    'BODY RUNTIME NOT RUNNING'
)) {
    Check ($availability.Contains($reason)) "Missing fail-closed authority reason: $reason"
}
Check ($sessionPresentation -match 'if !CRBiologyRuntimeAvailability\.EnsureActive\(game\) \{\s*return CRBiologySessionPresentation\.Diagnostic') 'Overview no longer fails visibly when authority is unavailable.'
Check ($sessionPresentation -match '(?s)public static func Detail\(game: GameInstance, area: gamedataEquipmentArea\).*?if !CRBiologyDetailPresentation\.Supported\(area\) \|\| !CRBiologyRuntimeAvailability\.EnsureActive\(game\) \{\s*return result;') 'Detail no longer fails closed before rendering metrics.'
Check ($shell.Contains('[ BIOLOGY ERROR ] BODY DETAIL UNAVAILABLE')) 'Invalid detail authority no longer produces visible Biology failure.'
Check ($shell.Contains('[ BIOLOGY ERROR ] BODY STATE UNAVAILABLE')) 'Invalid overview authority no longer produces visible Biology failure.'

$stableGuard = $sessionPresentation.IndexOf('if !IsDefined(runtime) || !IsDefined(body) || !body.initialized')
$metersGuard = $sessionPresentation.IndexOf('if !IsDefined(meters) || !meters.valid')
$stableReturn = $sessionPresentation.IndexOf('return "STABLE";')
Check ($stableGuard -ge 0 -and $metersGuard -gt $stableGuard -and $stableReturn -gt $metersGuard) 'STABLE can be emitted before runtime/body/meter validity is established.'

# Existing bounded developer snapshots cover activation and skip boundaries without
# adding release telemetry, another timer, or another persistence authority.
Check ($runtime.Contains('if !CRBodyTestPolicy.Diagnostics()')) 'Body diagnostic snapshots are no longer development-gated.'
foreach ($event in @('activate','skip-start','skip-finish','tick')) {
    Check ($runtime.Contains(('this.TestSnapshot("' + $event + '");'))) "Missing bounded runtime diagnostic event: $event"
}
Check (-not ($runtime -match 'persistent let testLastSnapshot|persistent let testSnapshotCount')) 'Development diagnostics became save-persistent state.'

Write-Host "PASS: $script:checks W04.2 body authority/persistence checks; detail provenance, menu reopen, restore, time progression and fail-closed contracts are source-proven. Live save/reload and wait/sleep continuity remain attended CP2077 2.31 acceptance."
