$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\tools\Common.ps1"
$project = Get-ProjectRoot
$builderPath = Join-Path $project 'tools/Build-OwnedRuntimeProfile.ps1'
$sessionPath = Join-Path $project 'tools/Prepare-OwnedSession.ps1'
$acquirePath = Join-Path $project 'tools/Acquire-Components.ps1'
$builder = Get-Content -Raw -LiteralPath $builderPath
$session = Get-Content -Raw -LiteralPath $sessionPath
$acquire = Get-Content -Raw -LiteralPath $acquirePath
$script:checks = 0
function Check($condition,[string]$message) { if (-not $condition) { throw $message }; $script:checks++ }

# Selective acquisition is required so the owned path never downloads reference
# gameplay mods merely because they remain documented in the historical catalog.
Check ($acquire.Contains('[string[]]$ComponentIds')) 'Component acquisition has no selective owned-runtime path.'
Check ($acquire.Contains('Add-ComponentWithDependencies')) 'Selective acquisition does not close dependency requirements.'
Check ($acquire.Contains('$selected.ContainsKey')) 'Selective acquisition does not deduplicate dependency traversal.'

foreach ($needle in @(
    "`$genericIds = @('red4ext','redscript')",
    'Acquire-Components.ps1',
    'Stage-Components.ps1',
    "-Profile 'm1-base'",
    'Build-OwnedAcceptance.ps1',
    "profile = 'owned-runtime-development'",
    'Compile-Profile.ps1',
    'sourceModsRequired = @()'
)) {
    Check ($builder.Contains($needle)) "Owned deployable-profile invariant missing: $needle"
}
Check ($builder.Contains("component = [string]`$entry.component")) 'Owned profile does not preserve per-file component ownership.'
Check ($builder.Contains("origin = `$(if (`$entry.PSObject.Properties.Name -contains 'origin')")) 'Owned profile does not preserve file provenance.'
foreach ($forbidden in @('darkfuture','project e3','mod-settings','input-loader')) {
    Check ($builder.Contains($forbidden)) "Owned deployable profile lost forbidden payload guard: $forbidden"
}
foreach ($danger in @('Deploy.ps1','Upgrade.ps1','Start-Process','Register-ScheduledTask','New-Service')) {
    Check (-not $builder.Contains($danger)) "Owned profile builder gained live/unattended side effect: $danger"
}

Check ($session.Contains('tests\Run-CI.ps1')) 'Owned session does not establish cloud-safe/offline source coherence before local build.'
Check ($session.Contains('Owned-path offline checks failed; candidate build/deployment aborted.')) 'Owned session does not fail closed when offline checks fail.'
Check ($session.Contains('offlineChecksPassed = $true')) 'Owned session report does not record the offline-check gate.'
Check ($session.Contains('Build-OwnedRuntimeProfile.ps1')) 'Owned session does not build the explicit owned profile.'
Check ($session.Contains('Upgrade.ps1') -and $session.Contains('-WhatIf')) 'Owned upgrade path does not use the real transaction planner as preflight.'
Check ($session.Contains('Deploy.ps1') -and $session.Contains('-WhatIf')) 'Owned initial-deploy path does not use the real transaction planner as preflight.'
Check ($session.Contains('Backup-Saves.ps1')) 'Live owned deployment does not require a verified save backup.'
Check ($session.Contains('Verify-Deployment.ps1')) 'Live owned deployment does not hash-verify its receipt.'
Check ($session.Contains('Get-ForbiddenOwnedAcceptanceResidue')) 'Owned session does not verify source-mod runtime isolation.'
Check ($session.Contains('r6/scripts/Dark Future') -and $session.Contains('r6/scripts/Project E3 - HUD')) 'Owned session does not check known source-mod script residue.'
Check ($session.Contains('Rollback.ps1')) 'Owned session cannot recover automatically after post-deploy isolation failure.'
Check ($session.Contains('source-mod-residue-free')) 'Owned session success message does not state the ownership boundary it verified.'
foreach ($danger in @('Start-Process','Cyberpunk2077.exe','Register-ScheduledTask','New-Service')) {
    Check (-not $session.Contains($danger)) "Owned session contains unattended launch/background behavior: $danger"
}

Write-Host "PASS: $script:checks owned runtime build/session orchestration checks."
