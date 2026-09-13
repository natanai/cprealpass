param(
    [string]$BuildId,
    [string]$GameRoot = 'C:\Games\Steam\steamapps\common\Cyberpunk 2077',
    [string]$SaveRoot,
    [string]$StateRoot,
    [switch]$Diagnostics,
    [switch]$Deploy,
    [switch]$SkipSaveBackup
)
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\Common.ps1"
$project = Get-ProjectRoot
$GameRoot = Assert-GameRoot $GameRoot
Assert-GameStopped

if ($SkipSaveBackup -and -not $Deploy) {
    throw '-SkipSaveBackup is only valid with -Deploy.'
}

if ([string]::IsNullOrWhiteSpace($BuildId)) {
    $mode = if ($Deploy) { 'deploy' } else { 'preflight' }
    $BuildId = 'realpass-owned-' + $mode + '-' + [DateTime]::UtcNow.ToString('yyyyMMdd-HHmmss') + '-' + [guid]::NewGuid().ToString('N').Substring(0,8)
}
if ($BuildId -notmatch '^[a-zA-Z0-9][a-zA-Z0-9._-]*$') { throw 'Invalid BuildId.' }
if (-not $StateRoot) { $StateRoot = Join-Path $project 'snapshots\deployment-state' }
$StateRoot = [IO.Path]::GetFullPath($StateRoot)

# One owned-session command should establish both public-source coherence and the
# installed-game preflight. This remains entirely attended/dev tooling: CI-style
# checks run first, then the exact local candidate is built. Nothing is deployed
# unless -Deploy is explicit.
Write-Host '[1/6] Validating repository and offline contracts...'
Write-Host '=== Running owned-path offline checks ==='
& (Join-Path $project 'tests\Run-CI.ps1')
if ($LASTEXITCODE -ne 0) { throw 'Owned-path offline checks failed; candidate build/deployment aborted.' }

function Get-ForbiddenOwnedAcceptanceResidue([string]$root) {
    $hits = [Collections.Generic.List[string]]::new()
    foreach ($relative in @(
        'r6/scripts/Dark Future',
        'r6/tweaks/Dark Future',
        'r6/scripts/Project E3 - HUD',
        'r6/tweaks/Project E3 - HUD',
        'r6/input/Dark Future.xml',
        'archive/pc/mod/basegame_3e_demo_hud.archive'
    )) {
        $path = Resolve-SafeChildPath $root $relative
        if (Test-Path -LiteralPath $path) { $hits.Add($relative) }
    }
    $archiveRoot = Resolve-SafeChildPath $root 'archive/pc/mod'
    if (Test-Path -LiteralPath $archiveRoot -PathType Container) {
        foreach ($file in @(Get-ChildItem -LiteralPath $archiveRoot -File)) {
            if ($file.Name -match '(?i)^Dark Future.*\.archive$|^darkfuture.*\.(archive|xl)$|Project.?E3') {
                $hits.Add(('archive/pc/mod/' + $file.Name))
            }
        }
    }
    return @($hits | Sort-Object -Unique)
}

Write-Host '[2/6] Building and exact-compiling the owned Cyberpunk 2.31 runtime...'
Write-Host "Owned attended build ID: $BuildId"
$builderArgs = @{ BuildId = $BuildId; GameRoot = $GameRoot }
if ($Diagnostics) { $builderArgs.Diagnostics = $true }
$manifestRelative = & "$PSScriptRoot\Build-OwnedRuntimeProfile.ps1" @builderArgs
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace([string]$manifestRelative)) { throw 'Owned runtime build/compile did not complete.' }
$manifest = Resolve-SafeChildPath $project ([string]$manifestRelative)

Write-Host '[3/6] Planning the reversible deployment transaction...'
$currentPath = Join-Path $StateRoot 'current.json'
$deploymentMode = 'deploy'
$plan = @()
if (Test-Path -LiteralPath $currentPath -PathType Leaf) {
    $current = Get-Content -Raw -LiteralPath $currentPath | ConvertFrom-Json
    if ($current.gameRoot -and [IO.Path]::GetFullPath([string]$current.gameRoot) -ne [IO.Path]::GetFullPath($GameRoot)) {
        throw 'Deployment state belongs to another game root.'
    }
    if ($current.status -eq 'deployed') {
        $deploymentMode = 'upgrade'
        $plan = @(& "$PSScriptRoot\Upgrade.ps1" -GameRoot $GameRoot -ManifestPath $manifest -StateRoot $StateRoot -WhatIf)
    } elseif ($current.status -eq 'rolled-back') {
        $plan = @(& "$PSScriptRoot\Deploy.ps1" -GameRoot $GameRoot -ManifestPath $manifest -StateRoot $StateRoot -WhatIf)
    } else {
        throw "Deployment state is not clean: $($current.status). Recover/rollback before owned acceptance."
    }
} else {
    $plan = @(& "$PSScriptRoot\Deploy.ps1" -GameRoot $GameRoot -ManifestPath $manifest -StateRoot $StateRoot -WhatIf)
}
if ($plan.Count -eq 0) { throw 'Owned runtime candidate produced an empty deployment plan.' }
Write-Host "Deployment plan ready: $($plan.Count) paths; mode=$deploymentMode."

$preflight = [ordered]@{
    schemaVersion = 1
    buildId = $BuildId
    preparedAtUtc = [DateTime]::UtcNow.ToString('o')
    ownedRuntime = $true
    offlineChecksPassed = $true
    candidateManifest = $manifest
    gameRoot = $GameRoot
    stateRoot = $StateRoot
    diagnosticsEnabled = [bool]$Diagnostics
    deploymentMode = $deploymentMode
    deployRequested = [bool]$Deploy
    plannedFiles = $plan.Count
    actions = @($plan | Group-Object action | Sort-Object Name | ForEach-Object { [ordered]@{action=$_.Name;count=$_.Count} })
    preexistingForbiddenResidue = @(Get-ForbiddenOwnedAcceptanceResidue $GameRoot)
    saveBackup = $null
    saveBackupSkipped = [bool]$SkipSaveBackup
    deploymentReceipt = $null
    status = 'compiled-and-preflight-passed'
}
$reportPath = Resolve-SafeChildPath $project ('reports/owned-session-' + $BuildId + '.json')

if (-not $Deploy) {
    Write-JsonFile $preflight $reportPath
    Write-Host "PASS: owned candidate $BuildId passed offline checks, exact compilation, and deployment preflight for $($plan.Count) paths. Nothing was deployed."
    if ($preflight.preexistingForbiddenResidue.Count -gt 0) {
        Write-Host 'NOTE: source-mod residue currently exists in the live game, but the deployment plan has not run yet. A live owned session will verify that it is gone after the transaction.'
    }
    return $reportPath
}

if ($SkipSaveBackup) {
    Write-Host '[4/6] Local save backup explicitly skipped by operator; game-file rollback remains enabled.'
} else {
    Write-Host '[4/6] Creating and verifying a save backup before any game files are changed...'
    $backupArgs = @{}
    if ($SaveRoot) { $backupArgs.SaveRoot = $SaveRoot }
    $backup = & "$PSScriptRoot\Backup-Saves.ps1" @backupArgs
    if ([string]::IsNullOrWhiteSpace([string]$backup)) { throw 'Verified save backup was not established; deployment aborted.' }
    $preflight.saveBackup = [string]$backup
}
Assert-GameStopped

Write-Host "[5/6] Applying the $deploymentMode transaction..."
$receipt = $null
try {
    if ($deploymentMode -eq 'upgrade') {
        $receipt = & "$PSScriptRoot\Upgrade.ps1" -GameRoot $GameRoot -ManifestPath $manifest -StateRoot $StateRoot
    } else {
        $receipt = & "$PSScriptRoot\Deploy.ps1" -GameRoot $GameRoot -ManifestPath $manifest -StateRoot $StateRoot
    }
    if ([string]::IsNullOrWhiteSpace([string]$receipt)) { throw 'Deployment returned no receipt.' }
    Write-Host '[6/6] Hash-verifying the installed runtime and checking source-mod isolation...'
    & "$PSScriptRoot\Verify-Deployment.ps1" -ReceiptPath $receipt
    $residue = @(Get-ForbiddenOwnedAcceptanceResidue $GameRoot)
    if ($residue.Count -gt 0) {
        throw "Owned acceptance isolation failed; source-mod runtime residue remains: $($residue -join ', ')"
    }
} catch {
    $failure = $_.Exception.Message
    if (-not [string]::IsNullOrWhiteSpace([string]$receipt) -and (Test-Path -LiteralPath ([string]$receipt))) {
        try {
            Write-Host 'Deployment verification failed; rolling back the candidate...'
            & "$PSScriptRoot\Rollback.ps1" -ReceiptPath ([string]$receipt)
            throw "$failure Candidate deployment was rolled back to the prior verified state."
        } catch {
            if ($_.Exception.Message -like "$failure*") { throw }
            throw "$failure Automatic rollback also failed: $($_.Exception.Message)"
        }
    }
    throw
}

$preflight.deploymentReceipt = [string]$receipt
$preflight.status = 'owned-runtime-deployed-and-verified'
$preflight.postDeployForbiddenResidue = @()
Write-JsonFile $preflight $reportPath
if ($SkipSaveBackup) {
    Write-Host "READY: owned runtime $BuildId passed offline checks and is deployed, hash-verified, source-mod-residue-free, with game-file rollback preserved. Local save backup was skipped by explicit operator request."
} else {
    Write-Host "READY: owned runtime $BuildId passed offline checks and is deployed, hash-verified, source-mod-residue-free, and protected by a verified save backup."
}
Write-Host 'This tool does not launch Cyberpunk, create background services, or enable diagnostics unless explicitly requested.'
Write-Host "Rollback receipt: $receipt"
return $reportPath
