$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\tools\Common.ps1"
$project = Get-ProjectRoot
$builderPath = Join-Path $project 'tools/Build-OwnedRuntimeProfile.ps1'
$sessionPath = Join-Path $project 'tools/Prepare-OwnedSession.ps1'
$installerPath = Join-Path $project 'tools/Install-OwnedRuntime.ps1'
$removerPath = Join-Path $project 'tools/Remove-OwnedRuntime.ps1'
$acquirePath = Join-Path $project 'tools/Acquire-Components.ps1'
$builder = Get-Content -Raw -LiteralPath $builderPath
$session = Get-Content -Raw -LiteralPath $sessionPath
$installer = Get-Content -Raw -LiteralPath $installerPath
$remover = Get-Content -Raw -LiteralPath $removerPath
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
Check ($session.Contains('Install-OwnedRuntime.ps1') -and $session.Contains('-WhatIf')) 'Owned session does not use the flat installer for preflight.'
Check ($session.Contains('Install-OwnedRuntime.ps1') -and $session.Contains("'[4/5] Installing the owned runtime directly...'")) 'Owned session does not use the flat installer for live deployment.'
Check (-not $session.Contains('Backup-Saves.ps1')) 'Owned session still performs redundant local save backups.'
Check (-not $session.Contains('Upgrade.ps1')) 'Owned session still traverses legacy upgrade chains.'
Check (-not $session.Contains('Rollback.ps1')) 'Owned session still depends on legacy automatic rollback.'
Check ($session.Contains('Steam Verify Files') -and $session.Contains('Remove-OwnedRuntime.ps1')) 'Owned session does not document the simple external recovery path.'
Check ($session.Contains('Get-ForbiddenOwnedAcceptanceResidue')) 'Owned session does not verify retired/source-mod runtime isolation.'
Check ($session.Contains('r6/scripts/realpass')) 'Owned session does not reject stale legacy realpass presentation scripts.'
Check ($session.Contains('r6/scripts/Dark Future') -and $session.Contains('r6/scripts/Project E3 - HUD')) 'Owned session does not check known source-mod script residue.'
Check ($session.Contains('retired/source-mod runtime residue is absent')) 'Owned session success message does not state the complete runtime-isolation boundary it verified.'

foreach ($needle in @(
    "mode = 'flat-owned-development-install'",
    "status = 'installing'",
    "`$state.status = 'installed'",
    'Copy-VerifiedPayload',
    'Remove-KnownRetiredRuntime',
    'r6/scripts/CyberpunkRealism',
    'r6/scripts/realpass',
    'r6/scripts/Dark Future',
    'r6/scripts/Project E3 - HUD',
    'owned-current.json'
)) {
    Check ($installer.Contains($needle)) "Fast owned installer invariant missing: $needle"
}
Check (-not $installer.Contains('Get-ReceiptChain')) 'Fast owned installer unexpectedly traverses rollback receipts.'
Check (-not $installer.Contains('Backup-Saves.ps1')) 'Fast owned installer unexpectedly backs up saves.'
Check (-not $installer.Contains('Upgrade.ps1')) 'Fast owned installer unexpectedly invokes legacy upgrade tooling.'
Check ($remover.Contains('owned-current.json')) 'Owned cleanup tool does not use the flat install state.'
Check ($remover.Contains('Steam Verify Files')) 'Owned cleanup tool does not document stock-game repair.'

foreach ($text in @($session,$installer,$remover)) {
    foreach ($danger in @('Start-Process','Register-ScheduledTask','New-Service')) {
        Check (-not $text.Contains($danger)) "Owned deployment tooling contains unattended/background behavior: $danger"
    }
}

Write-Host "PASS: $script:checks fast owned runtime build/install orchestration checks."
