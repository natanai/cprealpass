[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [ValidatePattern('^[A-Fa-f0-9]{40}$')]
    [string]$MainSha,
    [string]$GameRoot = 'C:\Games\Steam\steamapps\common\Cyberpunk 2077',
    [string]$WorkspaceRoot
)

$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'Prepare-BiologyMilestoneTest.ps1 requires PowerShell 7 or newer.' }
. "$PSScriptRoot\Common.ps1"

$operatorRepo = Get-ProjectRoot
$game = Assert-GameRoot $GameRoot
Assert-GameStopped
$MainSha = $MainSha.ToLowerInvariant()

$operatorHead = (& git -C $operatorRepo rev-parse HEAD).Trim().ToLowerInvariant()
if ($LASTEXITCODE -ne 0 -or $operatorHead -ne $MainSha) {
    throw "Operator checkout is not the requested canonical main SHA. Expected $MainSha; found $operatorHead."
}

if (-not $WorkspaceRoot) { $WorkspaceRoot = Split-Path -Parent $operatorRepo }
$WorkspaceRoot = [IO.Path]::GetFullPath($WorkspaceRoot)
$candidateRepo = Join-Path $WorkspaceRoot 'candidate'
if (Test-Path -LiteralPath $candidateRepo) {
    throw "Candidate directory already exists: $candidateRepo. Milestone candidate source must be a fresh clone."
}

$remote = (& git -C $operatorRepo remote get-url origin).Trim()
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($remote)) { throw 'Could not resolve the repository origin URL.' }

Write-Host ''
Write-Host '=== BIOLOGY MILESTONE CLEAN-ROOM PREPARATION ===' -ForegroundColor Cyan
Write-Host "Canonical main : $MainSha"
Write-Host "Game root      : $game"
Write-Host "Workspace      : $WorkspaceRoot"

$answer = (Read-Host 'Run exhaustive vanilla hash verification against the tracked baseline? [y/N]').Trim().ToLowerInvariant()
$runExhaustive = $answer -in @('y','yes')
$gameStateEvidence = $null

if ($runExhaustive) {
    Write-Host ''
    Write-Host '=== EXHAUSTIVE VANILLA HASH VERIFICATION ===' -ForegroundColor Cyan
    & "$PSScriptRoot\Compare-GameToVanillaBaseline.ps1" -GameRoot $game
    if ($LASTEXITCODE -ne 0) { throw 'Exhaustive vanilla baseline verification failed.' }
    $gameStateEvidence = 'verified-against-recorded-vanilla-baseline'
} else {
    Write-Host ''
    Write-Host 'The exhaustive baseline scan was skipped by operator choice.' -ForegroundColor Yellow
    $fresh = (Read-Host 'Confirm this game was just fully uninstalled in Steam, residual install directory removed, and reinstalled before this milestone [y/N]').Trim().ToLowerInvariant()
    if ($fresh -notin @('y','yes')) {
        throw 'Without a fresh reinstall confirmation, the milestone requires exhaustive vanilla hash verification. Re-run and answer Y to the exhaustive check.'
    }
    Write-Host ''
    Write-Host '=== FAST VANILLA SANITY CHECK ===' -ForegroundColor Cyan
    & "$PSScriptRoot\Test-VanillaGameSanity.ps1" -GameRoot $game
    if ($LASTEXITCODE -ne 0) { throw 'Fast vanilla sanity check failed.' }
    $gameStateEvidence = 'fresh-steam-reinstall-user-confirmed;fast-sanity-pass;exhaustive-hash-check-skipped'
}

Write-Host ''
Write-Host '=== FRESH CANDIDATE CLONE ===' -ForegroundColor Cyan
& git clone $remote $candidateRepo
if ($LASTEXITCODE -ne 0) { throw 'Candidate clone failed.' }
& git -C $candidateRepo checkout --detach $MainSha
if ($LASTEXITCODE -ne 0) { throw 'Could not check out exact canonical main in candidate clone.' }
$candidateHead = (& git -C $candidateRepo rev-parse HEAD).Trim().ToLowerInvariant()
if ($candidateHead -ne $MainSha) { throw "Candidate checkout is on the wrong revision: $candidateHead" }
$dirty = @(& git -C $candidateRepo status --porcelain)
if ($LASTEXITCODE -ne 0) { throw 'Could not inspect candidate checkout state.' }
if ($dirty.Count -ne 0) { throw "Fresh candidate checkout is unexpectedly dirty:`n$($dirty -join "`n")" }

Write-Host ''
Write-Host '=== BUILD RELEASE-SHAPED BIOLOGY PACKAGE ===' -ForegroundColor Cyan
$buildScript = Join-Path $candidateRepo 'tools\Build-BiologyPackage.ps1'
$buildOutput = @(& pwsh $buildScript -GameRoot $game)
$buildCode = $LASTEXITCODE
$buildOutput | ForEach-Object { Write-Host $_ }
if ($buildCode -ne 0) { throw "Biology integrated package build failed with exit code $buildCode." }
$zip = $buildOutput | Where-Object { [string]$_ -match '\.zip$' } | Select-Object -Last 1
if ([string]::IsNullOrWhiteSpace([string]$zip) -or -not (Test-Path -LiteralPath $zip -PathType Leaf)) {
    throw 'Build completed but the generated Biology ZIP could not be identified.'
}
$zip = (Resolve-Path -LiteralPath $zip).Path
$zipHash = (Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash.ToUpperInvariant()
$zipBytes = (Get-Item -LiteralPath $zip).Length
$packageRoot = Join-Path (Split-Path -Parent $zip) (([IO.Path]::GetFileNameWithoutExtension($zip)) + '-root')
if (-not (Test-Path -LiteralPath $packageRoot -PathType Container)) { throw 'Build completed but the release-shaped package root could not be identified.' }

Write-Host ''
Write-Host '=== COLLISION-SAFE INSTALL PREFLIGHT ===' -ForegroundColor Cyan
$installScript = Join-Path $candidateRepo 'tools\Install-BiologyRelease.ps1'
$preflightOutput = @(& pwsh $installScript -PackageRoot $packageRoot -GameRoot $game -WhatIf)
$preflightCode = $LASTEXITCODE
$preflightOutput | ForEach-Object { Write-Host $_ }
if ($preflightCode -ne 0) { throw 'Biology release install preflight failed before mutation. Existing non-identical shared global.ini/version.dll are never overwritten.' }

Write-Host ''
Write-Host '=== INSTALL EXACT GENERATED PACKAGE ===' -ForegroundColor Cyan
$installOutput = @(& pwsh $installScript -PackageRoot $packageRoot -GameRoot $game)
$installCode = $LASTEXITCODE
$installOutput | ForEach-Object { Write-Host $_ }
if ($installCode -ne 0 -or ($installOutput -join "`n") -notmatch 'PASS: Biology release install verified') { throw 'Collision-safe Biology release installer failed or did not return its positive verification marker.' }
if (-not (Test-Path -LiteralPath (Join-Path $game 'mods\Biology\info.json') -PathType Leaf)) { throw 'Biology REDmod identity is missing after package install.' }
if (-not (Test-Path -LiteralPath (Join-Path $game 'biology\build-manifest.json') -PathType Leaf)) { throw 'Biology build manifest is missing after package install.' }
if (-not (Test-Path -LiteralPath (Join-Path $game 'BIOLOGY-VERSION.txt') -PathType Leaf)) { throw 'Biology version metadata is missing after package install.' }

Write-Host ''
Write-Host '=== OFFICIAL REDMOD DEPLOY ===' -ForegroundColor Cyan
$deployScript = Join-Path $candidateRepo 'tools\Deploy-BiologyRedmod.ps1'
& pwsh $deployScript -GameRoot $game
if ($LASTEXITCODE -ne 0) { throw 'Official REDmod deployment failed.' }

$evidence = [ordered]@{
    schemaVersion = 1
    testMode = 'MILESTONE CLEAN-ROOM'
    preparedUtc = [DateTime]::UtcNow.ToString('o')
    sourceRevision = $candidateHead
    operatorRevision = $operatorHead
    gameRoot = $game
    gameStateEvidence = $gameStateEvidence
    exhaustiveVanillaHashCheck = $runExhaustive
    candidateRepo = $candidateRepo
    artifact = $zip
    artifactSha256 = $zipHash
    artifactBytes = $zipBytes
    collisionSafeInstall = 'PASS'
    sharedCybercmdLoaderPolicy = 'global.ini/version.dll preserve-if-identical-or-fail-before-mutation; only cybercmd.asi replaceable'
    redmodDeploy = 'PASS'
    readyToLaunch = $false
    note = 'Return this evidence to the parent integration thread before launching the attended test.'
}
$evidencePath = Join-Path $WorkspaceRoot 'milestone-prep.json'
$evidence | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $evidencePath -Encoding utf8

Write-Host ''
Write-Host '============================================' -ForegroundColor Green
Write-Host 'READY FOR PARENT ATTENDED-TEST HANDOFF' -ForegroundColor Green
Write-Host '============================================' -ForegroundColor Green
Write-Host 'TEST_MODE=MILESTONE CLEAN-ROOM'
Write-Host "MAIN_SHA=$candidateHead"
Write-Host "GAME_STATE_EVIDENCE=$gameStateEvidence"
Write-Host "EXHAUSTIVE_BASELINE=$runExhaustive"
Write-Host "WORKSPACE=$WorkspaceRoot"
Write-Host "CANDIDATE_REPO=$candidateRepo"
Write-Host "ZIP=$zip"
Write-Host "ZIP_SHA256=$zipHash"
Write-Host "ZIP_BYTES=$zipBytes"
Write-Host 'COLLISION_SAFE_INSTALL=PASS'
Write-Host 'SHARED_CYBERCMD_LOADER_POLICY=global.ini/version.dll preserve-if-identical-or-fail-before-mutation; only cybercmd.asi replaceable'
Write-Host 'REDMOD_DEPLOY=PASS'
Write-Host "EVIDENCE_FILE=$evidencePath"
Write-Host 'STOP_BEFORE_GAME_LAUNCH=YES' -ForegroundColor Yellow
Write-Host '============================================' -ForegroundColor Green
return $evidencePath
