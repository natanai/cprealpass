$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\tools\Common.ps1"
$project = Get-ProjectRoot
$builderPath = Join-Path $project 'tools/Build-AttendedAcceptance.ps1'
$builder = Get-Content -Raw -LiteralPath $builderPath
$bodyPath = Join-Path $project 'src/redscript/CyberpunkRealism/BodyRuntime.reds'
$combatPath = Join-Path $project 'src/redscript/CyberpunkRealism/CombatNativeBridge.reds'
$healthPath = Join-Path $project 'src/redscript/CyberpunkRealism/NoHealthbars.reds'
$body = Get-Content -Raw -LiteralPath $bodyPath
$combat = Get-Content -Raw -LiteralPath $combatPath
$health = Get-Content -Raw -LiteralPath $healthPath
$script:checks = 0
function Check($condition,[string]$message) { if (-not $condition) { throw $message }; $script:checks++ }

# Canonical source must remain fail-closed. Only a generated immutable attended
# profile is allowed to open these development gates.
Check ($body -match 'public class CRBodyRuntimePolicy extends IScriptable \{\s+public static func Enabled\(\) -> Bool \{\s+return false;') 'Canonical body gate is not closed.'
Check ($body -match 'public class CRBodyTestPolicy extends IScriptable \{\s+public static func Diagnostics\(\) -> Bool \{\s+return false;') 'Canonical diagnostics gate is not closed.'
Check ($combat -match 'public class CRCombatRuntimePolicy extends IScriptable \{\s+public static func Enabled\(\) -> Bool \{\s+return false;') 'Canonical combat gate is not closed.'

Check ($builder.Contains("Stage-Replacement `$bodyDestination")) 'Builder does not stage the body source independently.'
Check ($builder.Contains("Stage-Replacement `$combatDestination")) 'Builder does not stage the combat source independently.'
Check ($builder.Contains("Replace-PolicyOnce `$bodyText 'CRBodyRuntimePolicy' 'Enabled' `$true")) 'Builder does not explicitly open body only in staged content.'
Check ($builder.Contains("Replace-PolicyOnce `$combatText 'CRCombatRuntimePolicy' 'Enabled' `$true")) 'Builder does not explicitly open combat only in staged content.'
Check ($builder.Contains("Replace-PolicyOnce `$bodyText 'CRBodyTestPolicy' 'Diagnostics' `$false")) 'Default attended build does not explicitly preserve diagnostics-off.'
Check ($builder.Contains('[switch]$Diagnostics')) 'Diagnostics cannot be explicitly opted into for attended debugging.'

# The broad acceptance profile requested for combat defaults to information-sparse
# play: no traditional HP bars, while source offers an explicit comparison switch.
Check ($builder.Contains("`$healthbarDestination = 'r6/scripts/CyberpunkRealism/NoHealthbars.reds'")) 'No-healthbar presentation is not part of the attended candidate.'
Check ($builder.Contains('if (-not $ShowTraditionalHealthBars)')) 'Traditional health bars are not hidden by default.'
Check ($builder.Contains('[switch]$ShowTraditionalHealthBars')) 'No explicit comparison path exists for healthbars-on debugging.'
Check ($health.Contains('return false;')) 'No-healthbar source default changed.'

# Builder must verify every inherited payload hash, compile exact output, and stop.
Check ($builder.Contains('Source profile hash mismatch')) 'Inherited source profile is not hash-validated.'
Check ($builder.Contains('Compile-Profile.ps1')) 'Generated attended profile is not compilation-gated.'
Check ($builder.Contains('No live deployment performed.')) 'Builder contract does not clearly stop before deployment.'
foreach ($danger in @('Deploy.ps1','Upgrade.ps1','Start-Process','Cyberpunk2077.exe"','Invoke-WebRequest','scheduled task','Register-ScheduledTask')) {
    Check (-not $builder.Contains($danger)) "Attended builder contains unattended/live side effect: $danger"
}

# Generated output is immutable-by-id and local deployment manifests remain ignored.
Check ($builder.Contains('Build ID already exists; attended acceptance profiles are immutable')) 'Attended profile IDs can overwrite evidence.'
Check ($builder.Contains("'manifest/' + `$BuildId + '.deployment.json'")) 'Builder does not use the established deployment-manifest format.'

Write-Host "PASS: $script:checks attended-builder safety checks; canonical gates stay closed and generated combat testing defaults to no health bars."
