$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\tools\Common.ps1"
$project = Get-ProjectRoot
$bodyPath = Join-Path $project 'src/redscript/CyberpunkRealism/BodyRuntime.reds'
$combatPath = Join-Path $project 'src/redscript/CyberpunkRealism/CombatNativeBridge.reds'
$bodyAttendedPath = Join-Path $project 'tools/Build-BodyAttended.ps1'
$broadAttendedPath = Join-Path $project 'tools/Build-AttendedAcceptance.ps1'
$retiredSessionPath = Join-Path $project 'tools/Prepare-AttendedSession.ps1'
$acceptancePath = Join-Path $project 'manifest/acceptance.json'
$settingsPath = Join-Path $project 'manifest/settings.json'
$surfacePath = Join-Path $project 'src/redscript/CyberpunkRealism/RealpassSettings.reds'

$body = Get-Content -Raw -LiteralPath $bodyPath
$combat = Get-Content -Raw -LiteralPath $combatPath
$bodyAttended = Get-Content -Raw -LiteralPath $bodyAttendedPath
$broadAttended = Get-Content -Raw -LiteralPath $broadAttendedPath
$acceptance = Get-Content -Raw -LiteralPath $acceptancePath | ConvertFrom-Json
$settings = Get-Content -Raw -LiteralPath $settingsPath | ConvertFrom-Json
$surface = Get-Content -Raw -LiteralPath $surfacePath

function RequireDisabledPolicy([string]$source,[string]$class,[string]$method) {
    $pattern = '(?s)public class ' + [regex]::Escape($class) + ' extends IScriptable\s*\{.*?public static func ' + [regex]::Escape($method) + '\(\) -> Bool\s*\{\s*return false;'
    if ([regex]::Matches($source,$pattern).Count -ne 1) { throw "Expected exactly one disabled source policy: $class.$method" }
}

RequireDisabledPolicy $body 'CRBodyRuntimePolicy' 'Enabled'
RequireDisabledPolicy $body 'CRBodyTestPolicy' 'Diagnostics'
RequireDisabledPolicy $combat 'CRCombatRuntimePolicy' 'BuildEnabled'
if (-not $combat.Contains('CRCombatRuntimePolicy.BuildEnabled() && CRRealpassSettings.IsEnabled(GetGameInstance())')) {
    throw 'Combat runtime enable path does not combine the staged build gate with the Biology launcher boundary.'
}
if ($surface -notmatch 'public static func IsEnabled\(game: GameInstance\) -> Bool\s*\{\s*return CRRealpassSettings\.IsLauncherActivated\(\);') {
    throw 'Biology whole-mod activation is not solely authorized by the REDmod-owned launcher marker.'
}
if ($surface -match '(?m)public\s+(?:persistent\s+)?let\s+enabled\s*:\s*Bool') {
    throw 'A redundant persisted in-game Biology master switch has re-entered production.'
}

$combatGate = @($acceptance.gates | Where-Object id -eq 'combat-native-activation')
if ($combatGate.Count -ne 1 -or $combatGate[0].status -eq 'passed') { throw 'Combat source is gated but acceptance ledger does not identify pending native activation.' }
if ($settings.schemaVersion -ne 5 -or $settings.surface.publicGameplaySettings -ne $false -or $settings.surface.publicBalanceSettings -ne $false -or $settings.surface.publicMasterEnable -ne $false) {
    throw 'Current settings contract does not preserve launcher-owned whole-mod activation and non-gameplay preference boundaries.'
}
if ($settings.surface.activationOwner -ne 'redlauncher-redmod-sentinel' -or $settings.surface.persistenceOwner -ne 'cyberpunk-save-scriptable-system') {
    throw 'Settings contract lost launcher activation or Biology save-backed persistence ownership.'
}
foreach ($authority in @('body','injury','combat','armor','cyberwarePhysiology','presentation')) {
    if ($settings.releaseProfile.$authority -ne $true) { throw "Authored Biology-on release profile is not locked on: $authority" }
}
if ($settings.releaseProfile.diagnostics -ne $false) { throw 'Authored release profile does not lock diagnostics off.' }
$controls = @($settings.publicControls)
if ($controls.Count -ne 1) { throw 'Expected exactly one in-game public preference: E3 presentation.' }
$control = $controls[0]
if ([string]$control.type -ne 'bool' -or [string]$control.id -ne 'presentation.e3-first-person-hud-visuals' -or [string]$control.authority -ne 'presentation-only') {
    throw 'The sole public preference is not the binary presentation-only E3 control.'
}
if (@($settings.forbiddenPublicSettings) -notcontains 'biology.enabled' -or @($settings.forbiddenPublicSettings) -notcontains 'realpass.enabled') {
    throw 'Settings contract no longer explicitly forbids an in-game whole-mod master preference.'
}

foreach ($needle in @('Parameter(Mandatory=$true)','Build ID already exists','Missing disabled policy','Combat build gate must remain disabled','body enabled, combat build gate disabled')) {
    if ($bodyAttended -notmatch [regex]::Escape($needle)) { throw "Attended body builder lost safety invariant: $needle" }
}
if ($bodyAttended -match '(?i)(Start-Process|Cyberpunk2077\.exe|scheduled task|Register-ScheduledTask)') {
    throw 'Attended body builder must not launch the game or install background automation.'
}

foreach ($needle in @(
    "Set-PolicyOnce `$bodyText 'CRBodyRuntimePolicy' 'Enabled' `$true",
    "Set-PolicyOnce `$combatText 'CRCombatRuntimePolicy' 'BuildEnabled' `$true 'false'",
    "Set-PolicyOnce `$bodyText 'CRBodyTestPolicy' 'Diagnostics' ([bool]`$Diagnostics) 'false'",
    'Build ID already exists; attended acceptance profiles are immutable',
    'Compile-Profile.ps1',
    'No live deployment performed.'
)) {
    if (-not $broadAttended.Contains($needle)) { throw "Broad attended builder lost safety invariant: $needle" }
}
if ($broadAttended -match '(?i)(Deploy\.ps1|Upgrade\.ps1|Start-Process|Register-ScheduledTask|New-Service)') {
    throw 'Broad attended builder must stage/compile only; it cannot deploy or launch.'
}

if (Test-Path -LiteralPath $retiredSessionPath) {
    throw 'Retired Prepare-AttendedSession.ps1 unexpectedly reappeared; attended testing must use the clean-room package path.'
}

Write-Host 'PASS: canonical body/combat/diagnostic gates remain build-controlled; REDlauncher/REDmod is the sole Biology whole-mod boundary; all release authorities stay locked together and E3 presentation is the only in-game preference.'
