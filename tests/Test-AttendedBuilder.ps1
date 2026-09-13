$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\tools\Common.ps1"
$project = Get-ProjectRoot
$builderPath = Join-Path $project 'tools/Build-AttendedAcceptance.ps1'
$builder = Get-Content -Raw -LiteralPath $builderPath
$bodyPath = Join-Path $project 'src/redscript/CyberpunkRealism/BodyRuntime.reds'
$combatPath = Join-Path $project 'src/redscript/CyberpunkRealism/CombatNativeBridge.reds'
$healthPath = Join-Path $project 'src/redscript/CyberpunkRealism/NoHealthbars.reds'
$settingsPath = Join-Path $project 'src/redscript/CyberpunkRealism/RealpassSettings.reds'
$body = Get-Content -Raw -LiteralPath $bodyPath
$combat = Get-Content -Raw -LiteralPath $combatPath
$health = Get-Content -Raw -LiteralPath $healthPath
$settings = Get-Content -Raw -LiteralPath $settingsPath
$script:checks = 0
function Check($condition,[string]$message) { if (-not $condition) { throw $message }; $script:checks++ }

# Canonical source must remain fail-closed. Only a generated immutable attended
# profile is allowed to open these development gates.
Check ($body -match 'public class CRBodyRuntimePolicy extends IScriptable \{\s+public static func Enabled\(\) -> Bool \{\s+return false;') 'Canonical body gate is not closed.'
Check ($body -match 'public class CRBodyTestPolicy extends IScriptable \{\s+public static func Diagnostics\(\) -> Bool \{\s+return false;') 'Canonical diagnostics gate is not closed.'
Check ($combat -match 'public class CRCombatRuntimePolicy extends IScriptable \{\s+public static func Enabled\(\) -> Bool \{\s+return false;') 'Canonical combat gate is not closed.'

Check ($builder.Contains("Stage-Replacement `$bodyDestination")) 'Builder does not stage the body source independently.'
Check ($builder.Contains("Stage-Replacement `$combatDestination")) 'Builder does not stage the combat source independently.'
Check ($builder.Contains("Set-PolicyOnce `$bodyText 'CRBodyRuntimePolicy' 'Enabled' `$true")) 'Builder does not make staged body active.'
Check ($builder.Contains("Set-PolicyOnce `$combatText 'CRCombatRuntimePolicy' 'Enabled' `$true 'false'")) 'Builder does not require closed combat before opening staged combat.'
Check ($builder.Contains("Set-PolicyOnce `$bodyText 'CRBodyTestPolicy' 'Diagnostics' ([bool]`$Diagnostics) 'false'")) 'Builder does not require diagnostics closed before applying explicit attended choice.'
Check ($builder.Contains('[switch]$Diagnostics')) 'Diagnostics cannot be explicitly opted into for attended debugging.'
Check ($builder.Contains('current known-good deployment may already be a body-enabled quiet profile')) 'Builder no longer documents body-enabled current-build compatibility.'

# A broad acceptance candidate must contain the causal chain the player is being
# asked to judge. Missing consequences should fail preflight rather than masquerade
# as a balance result.
foreach ($destination in @(
    'BodyRuntime.reds',
    'BodyInteractionRuntime.reds',
    'CombatNativeBridge.reds',
    'CombatProfilesNative.reds',
    'CombatWoundsNative.reds',
    'ArmorWearNative.reds',
    'InjuryEffectsNative.reds',
    'BloodLossNative.reds',
    'FieldCareRuntime.reds',
    'FieldCareActionRuntime.reds',
    'FieldCareItemUse.reds',
    'FieldCareUI.reds'
)) {
    Check ($builder.Contains('/' + $destination + "'")) "Broad attended prerequisite missing from builder: $destination"
}
Check ($builder.Contains('Source manifest is not a broad realpass acceptance profile')) 'Missing broad-profile files do not fail with an actionable preflight error.'

# The broad candidate also compiles the realpass-owned player preference surface.
# It remains passive: settings cannot launder an unaccepted gameplay gate open.
Check ($builder.Contains("`$settingsDestination = 'r6/scripts/CyberpunkRealism/RealpassSettings.reds'")) 'Attended candidate does not include the realpass settings surface.'
Check ($builder.Contains("Sync-ProjectSource 'src/redscript/CyberpunkRealism/RealpassSettings.reds'")) 'Builder does not refresh settings source from the current project revision.'
Check ($builder.Contains("Where-Object component -eq 'mod-settings'")) 'Builder does not require its pinned Mod Settings runtime dependency.'
Check ($builder.Contains('settings=passive')) 'Builder output does not state the settings activation boundary.'
Check (-not $settings.Contains('CRBodyRuntimePolicy') -and -not $settings.Contains('CRCombatRuntimePolicy')) 'Settings source directly controls development activation gates.'

# The broad acceptance profile requested for combat defaults to information-sparse
# play: no traditional HP bars, while source offers an explicit comparison switch.
Check ($builder.Contains("`$healthbarDestination = 'r6/scripts/CyberpunkRealism/NoHealthbars.reds'")) 'No-healthbar presentation is not part of the attended candidate.'
Check ($builder.Contains('if (-not $ShowTraditionalHealthBars)')) 'Traditional health bars are not hidden by default.'
Check ($builder.Contains('[switch]$ShowTraditionalHealthBars')) 'No explicit comparison path exists for healthbars-on debugging.'
Check ($health.Contains('return false;')) 'No-healthbar source default changed.'
Check ($builder.Contains("owner -notlike 'realpass*'")) 'Project-source refresh could overwrite an unrelated component.'

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
Check ($builder.Contains('requiredRuntimeDestinations')) 'Attended report does not preserve the required runtime inventory.'
Check ($builder.Contains('settingsSurface = $settingsDestination')) 'Attended report does not record the compiled settings surface.'

Write-Host "PASS: $script:checks attended-builder safety checks; current body-enabled builds are valid bases, settings remain passive, canonical combat stays closed, and generated broad combat testing defaults to no health bars."
