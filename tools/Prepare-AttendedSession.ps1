param(
    [Parameter(Mandatory=$true)][ValidatePattern('^[a-zA-Z0-9][a-zA-Z0-9._-]*$')][string]$BuildId,
    [string]$SourceManifestPath,
    [string]$GameRoot = 'C:\Games\Steam\steamapps\common\Cyberpunk 2077',
    [string]$SaveRoot,
    [string]$StateRoot,
    [switch]$Diagnostics,
    [switch]$ShowTraditionalHealthBars,
    [switch]$Deploy
)
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\Common.ps1"
$project = Get-ProjectRoot
$GameRoot = Assert-GameRoot $GameRoot
Assert-GameStopped

if (-not $StateRoot) { $StateRoot = Join-Path $project 'snapshots\deployment-state' }
$StateRoot = [IO.Path]::GetFullPath($StateRoot)

# Default to the exact manifest behind the currently deployed build so the player
# does not have to know internal manifest names. This keeps the current accepted
# presentation/dependency payload and layers the attended gates on top of it.
if ([string]::IsNullOrWhiteSpace($SourceManifestPath)) {
    $currentPath = Join-Path $StateRoot 'current.json'
    if (-not (Test-Path -LiteralPath $currentPath -PathType Leaf)) {
        throw 'No current deployment state was found. Supply -SourceManifestPath explicitly.'
    }
    $current = Get-Content -Raw -LiteralPath $currentPath | ConvertFrom-Json
    if ($current.status -ne 'deployed' -or $current.buildId -notmatch '^[a-zA-Z0-9][a-zA-Z0-9._-]*$') {
        throw 'Current deployment is not in a clean deployed state. Recover it before preparing an attended session.'
    }
    $SourceManifestPath = 'manifest/' + $current.buildId + '.deployment.json'
    $sourceFull = Resolve-SafeChildPath $project $SourceManifestPath
    if (-not (Test-Path -LiteralPath $sourceFull -PathType Leaf)) {
        throw "Current deployed build is $($current.buildId), but its local source manifest is unavailable: $SourceManifestPath"
    }
    Write-Host "Using current deployed build as attended base: $($current.buildId)"
}

# Build-AttendedAcceptance verifies every inherited source hash and compiles the
# exact generated profile against the installed game before this script considers
# live deployment. The canonical source gates remain closed.
$builderArgs = @{
    BuildId = $BuildId
    ManifestPath = $SourceManifestPath
    GameRoot = $GameRoot
}
if ($Diagnostics) { $builderArgs.Diagnostics = $true }
if ($ShowTraditionalHealthBars) { $builderArgs.ShowTraditionalHealthBars = $true }
& "$PSScriptRoot\Build-AttendedAcceptance.ps1" @builderArgs

$manifest = Resolve-SafeChildPath $project ('manifest/' + $BuildId + '.deployment.json')
if (-not (Test-Path -LiteralPath $manifest -PathType Leaf)) { throw 'Attended builder did not emit the expected manifest.' }

$upgradeArgs = @{ GameRoot = $GameRoot; ManifestPath = $manifest; StateRoot = $StateRoot }
# Use the real upgrade planner as preflight. This verifies the current receipt
# chain, owned-file hashes, collisions, rollback backups and exact candidate plan
# without writing to the game.
$plan = @(& "$PSScriptRoot\Upgrade.ps1" @upgradeArgs -WhatIf)
if ($plan.Count -eq 0) { throw 'Attended candidate produced an empty upgrade plan.' }

$preflight = [ordered]@{
    schemaVersion = 1
    buildId = $BuildId
    preparedAtUtc = [DateTime]::UtcNow.ToString('o')
    sourceManifest = $SourceManifestPath
    candidateManifest = $manifest
    gameRoot = $GameRoot
    stateRoot = $StateRoot
    diagnosticsEnabled = [bool]$Diagnostics
    traditionalHealthBars = [bool]$ShowTraditionalHealthBars
    deployRequested = [bool]$Deploy
    plannedFiles = $plan.Count
    actions = @($plan | Group-Object action | Sort-Object Name | ForEach-Object { [ordered]@{action=$_.Name;count=$_.Count} })
    saveBackup = $null
    deploymentReceipt = $null
    status = 'preflight-passed'
}
$reportPath = Resolve-SafeChildPath $project ('reports/attended-session-' + $BuildId + '.json')

if (-not $Deploy) {
    Write-JsonFile $preflight $reportPath
    Write-Host "PASS: attended candidate $BuildId compiled and upgrade preflight passed for $($plan.Count) paths. Nothing was deployed."
    Write-Host 'When the player is present and ready, rerun the same command with -Deploy. The script still will not launch Cyberpunk.'
    return $reportPath
}

# A live attended install requires a verified save snapshot first. Backup-Saves
# asserts the game is stopped both before and after copying and hashes every file.
$backupArgs = @{}
if ($SaveRoot) { $backupArgs.SaveRoot = $SaveRoot }
$backup = & "$PSScriptRoot\Backup-Saves.ps1" @backupArgs
if ([string]::IsNullOrWhiteSpace([string]$backup)) { throw 'Verified save backup was not established; deployment aborted.' }
$preflight.saveBackup = [string]$backup
Assert-GameStopped

$receipt = & "$PSScriptRoot\Upgrade.ps1" @upgradeArgs
if ([string]::IsNullOrWhiteSpace([string]$receipt)) { throw 'Upgrade returned no deployment receipt.' }
& "$PSScriptRoot\Verify-Deployment.ps1" -ReceiptPath $receipt
$preflight.deploymentReceipt = [string]$receipt
$preflight.status = 'deployed-and-verified'
Write-JsonFile $preflight $reportPath

Write-Host "READY: $BuildId is deployed and hash-verified with a verified save backup."
Write-Host 'This tool does not start Cyberpunk, create background services, or enable diagnostics unless explicitly requested.'
Write-Host "Rollback receipt: $receipt"
return $reportPath
