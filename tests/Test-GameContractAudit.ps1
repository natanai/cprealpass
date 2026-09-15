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
    'readOnlyGameAudit = $true'
)) {
    Check ($source.Contains($needle)) "Game-contract audit lost required behavior/evidence: $needle"
}

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
Check ($source.Contains('hookFingerprintChanged')) 'Audit does not report changes in the RealPass native-hook surface.'

Write-Host "PASS: $script:checks proactive game-contract audit policy checks."
