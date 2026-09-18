$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\tools\Common.ps1"
$project = Get-ProjectRoot
$path = Join-Path $project 'tools/Audit-GameContracts.ps1'
$presentationPath = Join-Path $project 'tools/Audit-PresentationContracts.ps1'
$probePath = Join-Path $project 'tools/Probe-PresentationNativeContracts.ps1'
$localReferencePath = Join-Path $project 'docs/LOCAL-GAME-REFERENCE.md'
$migrationPath = Join-Path $project 'docs/BIOLOGY-REDMOD-MIGRATION.md'
foreach ($required in @($path,$presentationPath,$probePath,$localReferencePath,$migrationPath)) {
    if (-not (Test-Path -LiteralPath $required -PathType Leaf)) { throw "Missing proactive local game contract audit file: $required" }
}
$source = Get-Content -Raw -LiteralPath $path
$presentation = Get-Content -Raw -LiteralPath $presentationPath
$probe = Get-Content -Raw -LiteralPath $probePath
$localReference = Get-Content -Raw -LiteralPath $localReferencePath
$migration = Get-Content -Raw -LiteralPath $migrationPath
$script:checks = 0
function Check($condition,[string]$message) { if (-not $condition) { throw $message }; $script:checks++ }

foreach ($needle in @(
    'Refresh-LocalGameReference.ps1',
    'manifest\native-seams.json',
    'r6\cache\final.redscripts',
    'r6\cache\tweakdb.bin',
    'wrapMethod|replaceMethod|addMethod|addField',
    'Acquire-Components.ps1',
    "-ComponentIds @('redscript')",
    'Test-NativeSeamPolicy.ps1',
    'Build-OwnedAcceptance.ps1',
    'reference\cyberpunk',
    'native-contracts.json',
    'compatibility-audit.json',
    'baseScriptBundleSha256',
    'hookFingerprintSha256',
    'readOnlyGameAudit = $true',
    'local-game-contract-audit-',
    'Start-Transcript',
    'Stop-Transcript',
    'LOCAL EVIDENCE REPORT:',
    'textEvidenceReport'
)) {
    Check ($source.Contains($needle)) "Game-contract audit lost required behavior/evidence: $needle"
}

Check ($source.Contains('Split-Path -Parent $PSScriptRoot')) 'Game-contract audit does not derive its default repo root from its own checkout.'
Check (-not $source.Contains("[string]`$RepoRoot = 'C:\Games\CyberpunkRealism'")) 'Game-contract audit reintroduced the retired fixed local repo path.'

foreach ($forbidden in @(
    'Copy-Item -Destination $GamePath',
    'Copy-Item -Destination $gamePath',
    'Move-Item -Destination $GamePath',
    'Remove-Item -LiteralPath $GamePath',
    'Set-Content -Path $GamePath',
    'Start-Process',
    'Register-ScheduledTask',
    'New-Service',
    'Prepare-OwnedSession.ps1 -Deploy',
    'Upgrade.ps1'
)) {
    Check (-not $source.Contains($forbidden)) "Read-only game audit gained a forbidden game/runtime side effect: $forbidden"
    Check (-not $probe.Contains($forbidden)) "Read-only presentation probe gained a forbidden game/runtime side effect: $forbidden"
}

Check ($source.Contains("scope = 'Static/native contract compatibility audit.")) 'Audit report does not state its limited evidence scope.'
Check ($source.Contains('Runtime semantics, UI rendering, save behavior, quest behavior and gameplay feel still require attended testing.')) 'Audit overclaims what static/exact-compile evidence establishes.'
Check ($source.Contains('previousSnapshotPresent')) 'Audit does not compare against the previous tracked compatibility snapshot.'
Check ($source.Contains('baseScriptBundleChanged')) 'Audit does not report official base-script changes.'
Check ($source.Contains('hookFingerprintChanged')) 'Audit does not report changes in the Biology native-hook surface.'
Check ($source.Contains('FAIL: Biology native-contract audit did not complete.')) 'Audit text evidence does not clearly preserve failure outcome.'
Check ($source.Contains('PASS: Biology native-contract audit completed.')) 'Audit text evidence does not clearly preserve success outcome.'
Check ($source.Contains('Return that .txt file')) 'Audit does not instruct the operator to return the text evidence file.'

foreach ($needle in @('Audit-GameContracts.ps1','Probe-PresentationNativeContracts.ps1','presentation-local-audit-','LOCAL EVIDENCE REPORT:','Attach that .txt file','PRESENTATION LOCAL AUDIT RESULT')) {
    Check ($presentation.Contains($needle)) "Presentation local audit wrapper lost required behavior: $needle"
}
Check ($presentation.Contains('-ReportPath $ReportPath')) 'Presentation wrapper does not consolidate exact-compile output into its single text evidence report.'
Check ($probe.Contains('tools\redmod\scripts')) 'Presentation native probe is not grounded in the installed official REDmod decompiled scripts.'
Check ($probe.Contains('Primary evidence is the installed official REDmod decompiled script tree.')) 'Presentation probe no longer declares installed REDmod scripts as primary native evidence.'
Check (-not $probe.Contains('Get-ChildItem -LiteralPath $scriptRoot -Recurse')) 'Presentation native probe regressed to a noisy full-tree symbol sweep instead of narrow W03.4 source contracts.'
foreach ($needle in @('MinimapContainerController','IronsightGameController','QuestTrackerGameController','WeaponRosterGameController','HotkeysWidgetController','gameuiCrosshairContainerController','gameuiCrosshairBaseGameController','OnCrosshairStateChange','OnState_Scanning','interactionWidgetGameController','activityLogEntryLogicController','NpcNameplateGameController','NameplateVisualsLogicController','OnInitialize','OnScreenProjectionUpdate','SetElementVisibility','IsAnyElementVisible','OnUpdateInteraction','SetText','c_DisplayRangeNotAggressive','c_MaxDisplayRangeNotAggressive')) {
    Check ($probe.Contains($needle)) "Presentation native probe no longer checks required current-game symbol: $needle"
}
Check ($probe.Contains("path = 'cyberpunk/UI/widgets/minimap/minimap.script'")) 'Presentation probe no longer pins current minimap evidence to the installed native minimap script.'
Check ($probe.Contains("'\bfunction\s+SetElementVisibility\s*\('") -and $probe.Contains("'\bfunction\s+IsAnyElementVisible\s*\('")) 'Presentation probe no longer verifies the exact nameplate visibility lifecycle W03.4 preserves.'
Check ($probe.Contains("'\bevent\s+OnUpdateInteraction\s*\('") -and $probe.Contains("'\bfunction\s+SetText\s*\('")) 'Presentation probe no longer verifies interaction/activity W03.3 update seams.'
Check ($probe.Contains('Read-only targeted symbol/signature evidence only')) 'Presentation probe does not state its read-only narrow-evidence boundary.'

Check ($localReference.Contains('Prefer the installed official REDmod script tree for script contracts')) 'Local-game reference no longer prioritizes installed REDmod script archaeology.'
Check ($localReference.Contains('tools\redmod\scripts')) 'Local-game reference does not identify the official installed REDmod script tree.'
Check ($localReference.Contains('web/community script dumps')) 'Local-game reference does not explicitly demote web/community script mirrors below direct installed-game evidence.'
Check ($localReference.Contains('Do not assume or recreate `C:\Games\CyberpunkRealism`')) 'Local-game reference does not explicitly retire the fixed repository layout.'

# Preserve the scrubbed/current migration language while still enforcing the worker's
# official-path-first requirement. The exact heading/wording is allowed to evolve.
Check ($migration.Contains('Official-source-first investigation gate')) 'REDmod migration no longer declares the official-source-first investigation gate.'
Check ($migration.Contains('tools\redmod\bin\redMod.exe')) 'REDmod migration no longer requires direct consideration of the installed official executable.'
Check ($migration -match '(?is)community/modder solution|modding ecosystem.{0,80}solved') 'REDmod migration no longer warns against inheriting community architecture by popularity.'
Check ($migration.Contains('After directly checking the official/native option')) 'REDSCRIPT-BETTER/native fallback decisions are no longer conditioned on direct official-route investigation.'
Check ($migration.Contains('official Cyberpunk/REDmod capabilities are directly investigated')) 'Migration acceptance no longer requires direct official capability investigation.'

Write-Host "PASS: $script:checks proactive game-contract audit policy checks, including checkout-relative repo discovery, exact compile text evidence, installed-2.31 REDmod-first native script probing, and official-source-first architecture policy."
