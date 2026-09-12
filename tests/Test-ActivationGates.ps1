$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\tools\Common.ps1"
$project = Get-ProjectRoot
$bodyPath = Join-Path $project 'src/redscript/CyberpunkRealism/BodyRuntime.reds'
$combatPath = Join-Path $project 'src/redscript/CyberpunkRealism/CombatNativeBridge.reds'
$attendedPath = Join-Path $project 'tools/Build-BodyAttended.ps1'
$acceptancePath = Join-Path $project 'manifest/acceptance.json'
$settingsPath = Join-Path $project 'manifest/settings.json'

$body = Get-Content -Raw -LiteralPath $bodyPath
$combat = Get-Content -Raw -LiteralPath $combatPath
$attended = Get-Content -Raw -LiteralPath $attendedPath
$acceptance = Get-Content -Raw -LiteralPath $acceptancePath | ConvertFrom-Json
$settings = Get-Content -Raw -LiteralPath $settingsPath | ConvertFrom-Json

function RequireDisabledPolicy([string]$source,[string]$class,[string]$method) {
    $pattern = 'public class ' + [regex]::Escape($class) + ' extends IScriptable\s*\{\s*public static func ' + [regex]::Escape($method) + '\(\) -> Bool\s*\{\s*return false;'
    if ([regex]::Matches($source,$pattern).Count -ne 1) { throw "Expected exactly one disabled source policy: $class.$method" }
}

RequireDisabledPolicy $body 'CRBodyRuntimePolicy' 'Enabled'
RequireDisabledPolicy $body 'CRBodyTestPolicy' 'Diagnostics'
RequireDisabledPolicy $combat 'CRCombatRuntimePolicy' 'Enabled'

$combatGate = @($acceptance.gates | Where-Object id -eq 'combat-native-activation')
if ($combatGate.Count -ne 1 -or $combatGate[0].status -eq 'passed') { throw 'Combat source is gated but acceptance ledger does not identify pending native activation.' }
if (@($settings.safety.currentAcceptedForAutomaticActivation).Count -ne 0) { throw 'Settings contract claims automatic native acceptance while source policies remain gated.' }

# The only existing helper allowed to open a source gate is the attended body builder.
# It must work in staging, require a unique BuildId, and explicitly reject enabled combat.
foreach ($needle in @('Parameter(Mandatory=$true)','Build ID already exists','Missing disabled policy','Combat must remain disabled','body enabled, combat disabled')) {
    if ($attended -notmatch [regex]::Escape($needle)) { throw "Attended body builder lost safety invariant: $needle" }
}
if ($attended -match '(?i)(Start-Process|Cyberpunk2077\.exe|scheduled task|Register-ScheduledTask)') {
    throw 'Attended build helper must not launch the game or install background automation.'
}

Write-Host 'PASS: source body/combat/diagnostic gates remain closed; only the explicit staged body builder may open body for attended testing.'
