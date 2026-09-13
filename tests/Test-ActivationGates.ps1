$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\tools\Common.ps1"
$project = Get-ProjectRoot
$bodyPath = Join-Path $project 'src/redscript/CyberpunkRealism/BodyRuntime.reds'
$combatPath = Join-Path $project 'src/redscript/CyberpunkRealism/CombatNativeBridge.reds'
$bodyAttendedPath = Join-Path $project 'tools/Build-BodyAttended.ps1'
$broadAttendedPath = Join-Path $project 'tools/Build-AttendedAcceptance.ps1'
$sessionPath = Join-Path $project 'tools/Prepare-AttendedSession.ps1'
$acceptancePath = Join-Path $project 'manifest/acceptance.json'
$settingsPath = Join-Path $project 'manifest/settings.json'

$body = Get-Content -Raw -LiteralPath $bodyPath
$combat = Get-Content -Raw -LiteralPath $combatPath
$bodyAttended = Get-Content -Raw -LiteralPath $bodyAttendedPath
$broadAttended = Get-Content -Raw -LiteralPath $broadAttendedPath
$session = Get-Content -Raw -LiteralPath $sessionPath
$acceptance = Get-Content -Raw -LiteralPath $acceptancePath | ConvertFrom-Json
$settings = Get-Content -Raw -LiteralPath $settingsPath | ConvertFrom-Json

function RequireDisabledPolicy([string]$source,[string]$class,[string]$method) {
    # Comments are allowed between a class brace and its policy method. Match the
    # class body narrowly rather than assuming undocumented source formatting.
    $pattern = '(?s)public class ' + [regex]::Escape($class) + ' extends IScriptable\s*\{.*?public static func ' + [regex]::Escape($method) + '\(\) -> Bool\s*\{\s*return false;'
    if ([regex]::Matches($source,$pattern).Count -ne 1) { throw "Expected exactly one disabled source policy: $class.$method" }
}

RequireDisabledPolicy $body 'CRBodyRuntimePolicy' 'Enabled'
RequireDisabledPolicy $body 'CRBodyTestPolicy' 'Diagnostics'
RequireDisabledPolicy $combat 'CRCombatRuntimePolicy' 'Enabled'

$combatGate = @($acceptance.gates | Where-Object id -eq 'combat-native-activation')
if ($combatGate.Count -ne 1 -or $combatGate[0].status -eq 'passed') { throw 'Combat source is gated but acceptance ledger does not identify pending native activation.' }
if ($settings.schemaVersion -ne 2 -or $settings.surface.publicGameplaySettings -ne $false) { throw 'Locked release settings contract unexpectedly restored player activation controls.' }
foreach ($authority in @('body','injury','combat','armor','cyberwarePhysiology','presentation')) {
    if ($settings.releaseProfile.$authority -ne $true) { throw "Authored release profile is not locked on: $authority" }
}
if ($settings.releaseProfile.diagnostics -ne $false) { throw 'Authored release profile does not lock diagnostics off.' }

# Legacy body-only builder may open only the body gate in generated staging and
# must reject combat. It remains useful for isolated body acceptance.
foreach ($needle in @('Parameter(Mandatory=$true)','Build ID already exists','Missing disabled policy','Combat must remain disabled','body enabled, combat disabled')) {
    if ($bodyAttended -notmatch [regex]::Escape($needle)) { throw "Attended body builder lost safety invariant: $needle" }
}
if ($bodyAttended -match '(?i)(Start-Process|Cyberpunk2077\.exe|scheduled task|Register-ScheduledTask)') {
    throw 'Attended body builder must not launch the game or install background automation.'
}

# The historical broad builder can open BOTH body and combat only in a new
# immutable generated manifest that is compiled before use. It is NOT the new
# owned-runtime release/test path; ownership policy separately prevents calling its
# inherited source-mod profile an owned candidate.
foreach ($needle in @(
    "Set-PolicyOnce `$bodyText 'CRBodyRuntimePolicy' 'Enabled' `$true",
    "Set-PolicyOnce `$combatText 'CRCombatRuntimePolicy' 'Enabled' `$true 'false'",
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

# The session orchestrator may use Upgrade only after an exact -WhatIf preflight.
# The live write path must remain explicit and must establish a verified save backup.
foreach ($needle in @('Upgrade.ps1','-WhatIf','if (-not $Deploy)','Backup-Saves.ps1','Verify-Deployment.ps1')) {
    if (-not $session.Contains($needle)) { throw "Attended session deployment safety invariant missing: $needle" }
}
if ($session -match '(?i)(Start-Process|Register-ScheduledTask|New-Service)') {
    throw 'Attended session tool must not launch the game or install background automation.'
}

Write-Host 'PASS: canonical body/combat/diagnostic gates remain closed; release intent is fixed rather than player-toggleable, and live installation remains explicit + backed up.'
