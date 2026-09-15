$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\tools\Common.ps1"
$project = Get-ProjectRoot
$path = Join-Path $project 'tools/Audit-GameContracts.ps1'
if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw 'Missing proactive local game contract audit tool.' }
$source = Get-Content -Raw -LiteralPath $path
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

# Repository path is contextual: derive it from the tool checkout unless explicitly
# supplied. The retired fixed C:\Games\CyberpunkRealism checkout must never return.
Check ($source.Contains('Split-Path -Parent $PSScriptRoot')) 'Game-contract audit does not derive its default repo root from its own checkout.'
Check (-not $source.Contains("[string]`$RepoRoot = 'C:\Games\CyberpunkRealism'")) 'Game-contract audit reintroduced the retired fixed local repo path.'

# The audit may read the installed game and write repository-side derived metadata,
# but it must never deploy, mutate, launch, monitor, or repair Cyberpunk itself.
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
}

Check ($source.Contains("scope = 'Static/native contract compatibility audit.")) 'Audit report does not state its limited evidence scope.'
Check ($source.Contains('Runtime semantics, UI rendering, save behavior, quest behavior and gameplay feel still require attended testing.')) 'Audit overclaims what static/exact-compile evidence establishes.'
Check ($source.Contains('previousSnapshotPresent')) 'Audit does not compare against the previous tracked compatibility snapshot.'
Check ($source.Contains('baseScriptBundleChanged')) 'Audit does not report official base-script changes.'
Check ($source.Contains('hookFingerprintChanged')) 'Audit does not report changes in the Biology native-hook surface.'
Check ($source.Contains('FAIL: Biology native-contract audit did not complete.')) 'Audit text evidence does not clearly preserve failure outcome.'
Check ($source.Contains('PASS: Biology native-contract audit completed.')) 'Audit text evidence does not clearly preserve success outcome.'
Check ($source.Contains('Return that .txt file')) 'Audit does not instruct the operator to return the text evidence file.'

Write-Host "PASS: $script:checks proactive game-contract audit policy checks, including checkout-relative repo discovery and user-returned text evidence."
