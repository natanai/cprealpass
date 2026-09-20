param(
    [string]$BuildId,
    [string]$GameRoot = 'C:\Games\Steam\steamapps\common\Cyberpunk 2077',
    [string]$StateRoot,
    [switch]$Diagnostics,
    [switch]$Deploy
)
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\Common.ps1"
$project = Get-ProjectRoot
$GameRoot = Assert-GameRoot $GameRoot
Assert-GameStopped

if ([string]::IsNullOrWhiteSpace($BuildId)) {
    $mode = if ($Deploy) { 'deploy' } else { 'preflight' }
    $BuildId = 'realpass-owned-' + $mode + '-' + [DateTime]::UtcNow.ToString('yyyyMMdd-HHmmss') + '-' + [guid]::NewGuid().ToString('N').Substring(0,8)
}
if ($BuildId -notmatch '^[a-zA-Z0-9][a-zA-Z0-9._-]*$') { throw 'Invalid BuildId.' }
if (-not $StateRoot) { $StateRoot = Join-Path $project 'snapshots\deployment-state' }
$StateRoot = [IO.Path]::GetFullPath($StateRoot)

function Get-ForbiddenOwnedAcceptanceResidue([string]$root) {
    $hits = [Collections.Generic.List[string]]::new()
    foreach ($relative in @(
        'r6/scripts/realpass',
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

Write-Host '[1/5] Validating repository and offline contracts...'
& (Join-Path $project 'tests\Run-CI.ps1')
if ($LASTEXITCODE -ne 0) { throw 'Owned-path offline checks failed; candidate build/deployment aborted.' }

Write-Host '[2/5] Building and exact-compiling the owned Cyberpunk 2.31 runtime...'
Write-Host "Owned attended build ID: $BuildId"
$builderArgs = @{ BuildId = $BuildId; GameRoot = $GameRoot }
if ($Diagnostics) { $builderArgs.Diagnostics = $true }
$manifestRelative = & "$PSScriptRoot\Build-OwnedRuntimeProfile.ps1" @builderArgs
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace([string]$manifestRelative)) { throw 'Owned runtime build/compile did not complete.' }
$manifest = Resolve-SafeChildPath $project ([string]$manifestRelative)

Write-Host '[3/5] Planning the flat owned-runtime install...'
$plan = @(& "$PSScriptRoot\Install-OwnedRuntime.ps1" -GameRoot $GameRoot -ManifestPath $manifest -StateRoot $StateRoot -WhatIf)
if ($plan.Count -eq 0) { throw 'Owned runtime candidate produced an empty install plan.' }
Write-Host "Fast install plan ready: $($plan.Count) paths. No rollback-chain traversal or local save copy is required."

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
    deployRequested = [bool]$Deploy
    plannedFiles = $plan.Count
    actions = @($plan | Group-Object action | Sort-Object Name | ForEach-Object { [ordered]@{action=$_.Name;count=$_.Count} })
    preexistingForbiddenResidue = @(Get-ForbiddenOwnedAcceptanceResidue $GameRoot)
    installMode = 'flat-owned-development-install'
    recoveryMode = 'Remove-OwnedRuntime.ps1 plus Steam Verify Files/reinstall if stock-game repair is needed'
    installState = $null
    status = 'compiled-and-preflight-passed'
}
$reportPath = Resolve-SafeChildPath $project ('reports/owned-session-' + $BuildId + '.json')

if (-not $Deploy) {
    Write-JsonFile $preflight $reportPath
    Write-Host "PASS: owned candidate $BuildId passed offline checks, exact compilation, and fast install preflight for $($plan.Count) paths. Nothing was deployed."
    return $reportPath
}

Write-Host '[4/5] Installing the owned runtime directly...'
$installState = & "$PSScriptRoot\Install-OwnedRuntime.ps1" -GameRoot $GameRoot -ManifestPath $manifest -StateRoot $StateRoot
if ([string]::IsNullOrWhiteSpace([string]$installState)) { throw 'Fast owned-runtime installer returned no state path.' }
$preflight.installState = [string]$installState

Write-Host '[5/5] Checking source-mod and retired-presentation isolation...'
$residue = @(Get-ForbiddenOwnedAcceptanceResidue $GameRoot)
if ($residue.Count -gt 0) {
    throw "Owned acceptance isolation failed; retired/source-mod runtime residue remains: $($residue -join ', '). Run Remove-OwnedRuntime.ps1 if cleanup is needed; Steam Verify Files/reinstall remains the stock-game repair path."
}
$state = Get-Content -Raw -LiteralPath ([string]$installState) | ConvertFrom-Json
if ($state.status -ne 'installed' -or $state.buildId -ne $BuildId) { throw 'Flat owned-runtime install state did not finalize correctly.' }

$preflight.status = 'owned-runtime-installed-and-verified'
$preflight.postDeployForbiddenResidue = @()
Write-JsonFile $preflight $reportPath
Write-Host "READY: owned runtime $BuildId exact-compiled and fast-installed $($plan.Count) files; retired/source-mod runtime residue is absent."
Write-Host 'Recovery is intentionally simple: Remove-OwnedRuntime.ps1 removes recorded realpass files; use Steam Verify Files or reinstall Cyberpunk if stock-game repair is ever needed.'
Write-Host 'This tool does not launch Cyberpunk, create background services, or enable diagnostics unless explicitly requested.'
return $reportPath
