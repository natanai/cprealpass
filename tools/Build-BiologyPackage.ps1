param(
    [string]$GameRoot = 'C:\Games\Steam\steamapps\common\Cyberpunk 2077',
    [string]$OutputRoot,
    [switch]$Diagnostics
)
$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'Build-BiologyPackage.ps1 requires PowerShell 7 or newer.' }
. "$PSScriptRoot\Common.ps1"

$project = Get-ProjectRoot
$game = Assert-GameRoot $GameRoot
Assert-GameStopped

$gameVersion = (Get-Item -LiteralPath (Join-Path $game 'bin\x64\Cyberpunk2077.exe')).VersionInfo.ProductVersion
if ($gameVersion -ne '2.31') { throw "Biology integrated packaging currently supports Cyberpunk 2077 2.31; installed game reports $gameVersion." }

if (-not $OutputRoot) { $OutputRoot = Join-Path $project 'staging\biology-packages' }
$OutputRoot = [IO.Path]::GetFullPath($OutputRoot)
New-Item -ItemType Directory -Force -Path $OutputRoot | Out-Null

$revision = 'source-archive'
$shortRevision = 'archive'
if (Test-Path -LiteralPath (Join-Path $project '.git')) {
    $dirty = @(& git -C $project status --porcelain=v1 --untracked-files=no)
    if ($LASTEXITCODE -ne 0) { throw 'Unable to inspect repository state.' }
    if ($dirty.Count -gt 0) {
        throw "Biology package build requires no modified tracked files. Commit/push the candidate or use a fresh clone/download first.`n$($dirty -join "`n")"
    }
    $revision = (& git -C $project rev-parse HEAD).Trim()
    if ($LASTEXITCODE -ne 0 -or $revision -notmatch '^[A-Fa-f0-9]{40}$') { throw 'Unable to resolve repository revision.' }
    $shortRevision = $revision.Substring(0,12).ToLowerInvariant()
}

$packageContract = Get-Content -Raw -LiteralPath (Join-Path $project 'manifest\redmod-package.json') | ConvertFrom-Json
$dependencyGraph = Get-Content -Raw -LiteralPath (Join-Path $project 'manifest\dependency-graph.json') | ConvertFrom-Json
$info = Get-Content -Raw -LiteralPath (Join-Path $project 'mods\Biology\info.json') | ConvertFrom-Json
if ($packageContract.product -ne 'Biology' -or $packageContract.packageId -ne 'Biology') { throw 'Unexpected Biology REDmod package contract.' }
if ($packageContract.redmod.packageRoot -ne 'mods/Biology') { throw 'Biology REDmod package root drifted.' }
if ($info.name -ne 'Biology') { throw 'mods/Biology/info.json does not declare Biology.' }

$stamp = [DateTime]::UtcNow.ToString('yyyyMMdd-HHmmss')
$buildId = "biology-integrated-$stamp-$shortRevision"
$runtimeBuildId = $buildId + '-runtime'
$packageRoot = Join-Path $OutputRoot ($buildId + '-root')
$zipPath = Join-Path $OutputRoot ($buildId + '.zip')
if ((Test-Path -LiteralPath $packageRoot) -or (Test-Path -LiteralPath $zipPath)) { throw "Biology package output already exists for build ID: $buildId" }
New-Item -ItemType Directory -Force -Path $packageRoot | Out-Null

# This is the hard build gate: the complete merged project-owned REDscript tree plus
# every retained generic runtime component is exact-compiled against the installed
# Cyberpunk 2077 2.31 final.redscripts before any playable package is emitted.
$profileArgs = @{ BuildId = $runtimeBuildId; GameRoot = $game }
if ($Diagnostics) { $profileArgs.Diagnostics = $true }
$runtimeManifestRelative = & "$PSScriptRoot\Build-OwnedRuntimeProfile.ps1" @profileArgs
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace([string]$runtimeManifestRelative)) { throw 'Integrated Biology runtime profile build/exact compile failed.' }
$runtimeManifestPath = Resolve-SafeChildPath $project ([string]$runtimeManifestRelative)
$runtimeManifest = Get-Content -Raw -LiteralPath $runtimeManifestPath | ConvertFrom-Json
if ($runtimeManifest.schemaVersion -ne 1 -or -not $runtimeManifest.ownedRuntime -or $runtimeManifest.gameVersion -ne $gameVersion) { throw 'Unexpected integrated Biology runtime manifest.' }
$compileReportPath = Join-Path $project ('reports\compile-' + $runtimeBuildId + '.json')
if (-not (Test-Path -LiteralPath $compileReportPath -PathType Leaf)) { throw 'Integrated exact-compile report is missing.' }
$compileReport = Get-Content -Raw -LiteralPath $compileReportPath | ConvertFrom-Json
if ($compileReport.passed -ne $true -or $compileReport.exitCode -ne 0 -or $compileReport.outputPresent -ne $true) { throw 'Integrated exact compile did not pass.' }

$files = [Collections.Generic.List[object]]::new()
$dependencyComponents = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
function Add-FileRecord([string]$RelativePath,[string]$Owner,[string]$Component,[string]$Route,[string]$ReplacePolicy) {
    $normalized = $RelativePath.Replace('\','/').TrimStart('/')
    $target = Resolve-SafeChildPath $packageRoot $normalized
    if (-not (Test-Path -LiteralPath $target -PathType Leaf)) { throw "Cannot record missing package file: $normalized" }
    $files.Add([ordered]@{
        path = $normalized
        sha256 = Get-Sha256 $target
        owner = $Owner
        component = $Component
        route = $Route
        replacePolicy = $ReplacePolicy
    })
}
function Copy-IntoPackage([string]$Source,[string]$RelativePath,[string]$ExpectedSha256,[string]$Owner,[string]$Component,[string]$Route,[string]$ReplacePolicy) {
    $destination = Resolve-SafeChildPath $packageRoot $RelativePath
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $destination) | Out-Null
    Copy-VerifiedPayload $Source $destination $ExpectedSha256
    Add-FileRecord $RelativePath $Owner $Component $Route $ReplacePolicy
}

# Official first-party REDmod identity.
$infoSource = Join-Path $project 'mods\Biology\info.json'
Copy-IntoPackage $infoSource 'mods/Biology/info.json' (Get-Sha256 $infoSource) 'Biology' 'biology-redmod-identity' 'REDMOD-NATIVE' 'biology-owned'

# Supplemental runtime. Project-original sources remain Biology-owned; retained generic
# framework files are individually owned and never turn their shared parent directory
# into a Biology-owned root.
$routeByComponent = @{
    'redscript' = 'REDSCRIPT-BETTER'
    'red4ext' = 'REMOVE/RETHINK'
    'archivexl' = 'REMOVE/RETHINK'
    'mod-settings' = 'REMOVE/RETHINK'
}
foreach ($entry in @($runtimeManifest.files)) {
    $source = Resolve-SafeChildPath $project ([string]$entry.source)
    if ((Get-Sha256 $source) -ne [string]$entry.sha256) { throw "Runtime source hash mismatch: $($entry.source)" }
    $destination = ([string]$entry.destination).Replace('\','/')
    $origin = if ($entry.PSObject.Properties.Name -contains 'origin') { [string]$entry.origin } else { 'pinned-generic-framework' }
    if ($origin -eq 'project-original') {
        Copy-IntoPackage $source $destination ([string]$entry.sha256) 'Biology' ([string]$entry.component) 'REDSCRIPT-BETTER' 'biology-owned'
    } else {
        $component = [string]$entry.component
        if (-not $routeByComponent.ContainsKey($component)) { throw "Unexpected retained generic component in Biology runtime: $component" }
        [void]$dependencyComponents.Add($component)
        Copy-IntoPackage $source $destination ([string]$entry.sha256) ('upstream:' + $component) $component $routeByComponent[$component] 'approved-dependency-owned'
    }
}

$expectedRetained = @('redscript','red4ext','archivexl','mod-settings')
foreach ($id in $expectedRetained) {
    if (-not $dependencyComponents.Contains($id)) { throw "Playable Biology candidate is missing retained dependency payload: $id" }
}
foreach ($id in @($dependencyComponents)) {
    if ($id -notin $expectedRetained) { throw "Unexpected dependency entered playable Biology package: $id" }
}

# Tracked license snapshots are part of the package metadata, not runtime authority.
$licenseRoot = Join-Path $packageRoot 'LICENSES'
New-Item -ItemType Directory -Force -Path $licenseRoot | Out-Null
foreach ($component in @($dependencyComponents | Sort-Object)) {
    $matches = @(Get-ChildItem -LiteralPath (Join-Path $project 'LICENSES') -File -Filter ($component + '-v*.txt'))
    if ($matches.Count -ne 1) { throw "Expected exactly one tracked license snapshot for retained component '$component', found $($matches.Count)." }
    $relative = 'LICENSES/' + $component + '.txt'
    $destination = Resolve-SafeChildPath $packageRoot $relative
    Copy-Item -LiteralPath $matches[0].FullName -Destination $destination
    Add-FileRecord $relative 'Biology' ('license-notice:' + $component) 'REDMOD-NATIVE' 'biology-owned'
}

$installText = @'
Biology integrated REDmod-first candidate

SUPPORTED GAME
Cyberpunk 2077 2.31

PACKAGE IDENTITY
The first-party package identity is mods\Biology. The current playable candidate also contains individually accounted supplemental redscript/runtime framework files because Biology still uses narrow REDscript wrappers and the current accessible preference provider remains Mod Settings.

INSTALL / ATTENDED TEST
1. Follow the repository's canonical ITERATION or MILESTONE CLEAN-ROOM operator flow appropriate to the change being tested.
2. Close Cyberpunk 2077.
3. Extract/copy the CONTENTS of this package into the Cyberpunk 2077 game root.
4. Verify mods\Biology\info.json is present.
5. For deterministic developer/probe deployment, use the repository-owned tools\Deploy-BiologyRedmod.ps1 helper with the explicit game root. Do not reconstruct raw REDmod quoting from old chat/docs.
6. Normal players use the supported REDlauncher/Steam mod-enable path.
7. Launch normally through Steam.

Official REDmod recognition of Biology and real five-stage deployment on Cyberpunk 2077 2.31 have already been directly proven. Build/CI still does not prove launcher-off behavior, hard-uninstall safety, body/runtime/UI/presentation behavior, or broader gameplay acceptance.
'@
[IO.File]::WriteAllText((Join-Path $packageRoot 'INSTALL.txt'),$installText.TrimStart() + "`n",[Text.UTF8Encoding]::new($false))
Add-FileRecord 'INSTALL.txt' 'Biology' 'biology-package-metadata' 'REDMOD-NATIVE' 'biology-owned'

$uninstallText = @'
Biology integrated REDmod-first candidate

UNINSTALL / RESET PRINCIPLE
Use biology\build-manifest.json as the exact ownership record. Remove only files recorded there and then only empty Biology-owned directories. Never recursively delete shared roots such as r6, engine, red4ext, archive, mods, or bin.

The player-release target is a self-contained Uninstall Biology.exe that applies these rules, preserves saves/settings by default, and refuses changed/ambiguous file deletion. Until that implementation is integrated and accepted, development iteration cleanup uses the canonical repository reset/operator flow; a full Steam reinstall is reserved for structural clean-room/recovery cases, not normal Biology removal.

Disabling/uninstalling Biology is not permission to delete save data or player settings outside explicitly owned package paths.
'@
[IO.File]::WriteAllText((Join-Path $packageRoot 'UNINSTALL.txt'),$uninstallText.TrimStart() + "`n",[Text.UTF8Encoding]::new($false))
Add-FileRecord 'UNINSTALL.txt' 'Biology' 'biology-package-metadata' 'REDMOD-NATIVE' 'biology-owned'

$version = [string]$info.version + '-candidate.' + $stamp + '.' + $shortRevision
$versionText = @(
    'Biology ' + $version,
    'Cyberpunk 2077 ' + $gameVersion,
    'source ' + $revision,
    'REDmod package mods/Biology'
) -join "`n"
[IO.File]::WriteAllText((Join-Path $packageRoot 'BIOLOGY-VERSION.txt'),$versionText + "`n",[Text.UTF8Encoding]::new($false))
Add-FileRecord 'BIOLOGY-VERSION.txt' 'Biology' 'biology-package-metadata' 'REDMOD-NATIVE' 'biology-owned'

$biologyDir = Join-Path $packageRoot 'biology'
New-Item -ItemType Directory -Force -Path $biologyDir | Out-Null
$provenance = [ordered]@{
    schemaVersion = 1
    product = 'Biology'
    buildId = $buildId
    version = $version
    sourceRevision = $revision
    gameVersion = $gameVersion
    redmodFirst = $true
    officialPackageRoot = 'mods/Biology'
    playableRuntimeIncluded = $true
    exactCompile = [ordered]@{
        required = $true
        passed = $true
        buildId = $runtimeBuildId
        sourceCount = [int]$compileReport.sourceCount
        baseBundleSha256 = [string]$compileReport.baseBundleSha256
        scope = [string]$compileReport.scope
    }
    retainedDependencies = @(
        [ordered]@{ id='redscript'; reason='Required by accepted Biology-owned additive/wrapper REDscript runtime and native seams.' },
        [ordered]@{ id='mod-settings'; reason='Temporary current UI/persistence adapter for the provider-neutral Biology preference surface; #44 owns launcher-off activation interactions and #40 owns attended E3 presentation behavior.' },
        [ordered]@{ id='archivexl'; reason='Retained only as a transitive dependency of the current Mod Settings adapter.' },
        [ordered]@{ id='red4ext'; reason='Retained only as transitive runtime plumbing for ArchiveXL/Mod Settings; Biology has no project-owned RED4ext plugin.' }
    )
    removedDependencies = @('tweakxl','codeware','input-loader','darkfuture','project-e3-hud')
    sourceModsRequired = @()
    directGameGatesRemaining = @('launcher enable/disable and Biology-inactive OFF behavior','normal relaunch persistence','self-contained hard uninstall and residue verification','safe REDmod overlap/precedence fixture','attended body/runtime/UI/presentation/gameplay acceptance')
}
Write-JsonFile $provenance (Join-Path $biologyDir 'provenance.json')
Add-FileRecord 'biology/provenance.json' 'Biology' 'biology-package-metadata' 'REDMOD-NATIVE' 'biology-owned'

$manifest = [ordered]@{
    schemaVersion = 1
    product = 'Biology'
    buildId = $buildId
    version = $version
    gameVersion = $gameVersion
    sourceRevision = $revision
    playableRuntimeIncluded = $true
    officialPackageRoot = 'mods/Biology'
    files = @($files.ToArray() | Sort-Object path)
    metadataHashRule = 'SHA256SUMS.txt covers biology/build-manifest.json and every final artifact file except SHA256SUMS.txt itself; the owner manifest cannot recursively hash itself.'
}
Write-JsonFile $manifest (Join-Path $biologyDir 'build-manifest.json')

$sumLines = [Collections.Generic.List[string]]::new()
foreach ($file in @(Get-ChildItem -LiteralPath $packageRoot -Recurse -File -Force | Sort-Object FullName)) {
    $relative = [IO.Path]::GetRelativePath($packageRoot,$file.FullName).Replace('\','/')
    if ($relative -eq 'SHA256SUMS.txt') { continue }
    $sumLines.Add(((Get-Sha256 $file.FullName).ToLowerInvariant() + '  ' + $relative))
}
[IO.File]::WriteAllText((Join-Path $packageRoot 'SHA256SUMS.txt'),($sumLines -join "`n") + "`n",[Text.UTF8Encoding]::new($false))

# Final fail-closed checks.
foreach ($entry in @($manifest.files)) {
    $target = Resolve-SafeChildPath $packageRoot ([string]$entry.path)
    if ((Get-Sha256 $target) -ne [string]$entry.sha256) { throw "Final Biology artifact hash mismatch: $($entry.path)" }
}
foreach ($blocked in @('darkfuture','project e3','project-e3','input-loader','tweakxl','codeware')) {
    $hit = @(Get-ChildItem -LiteralPath $packageRoot -Recurse -File | Where-Object { $_.FullName.ToLowerInvariant().Contains($blocked) })
    if ($hit.Count -gt 0) { throw "Blocked runtime/dependency content leaked into Biology package: $($hit[0].FullName)" }
}
& "$PSScriptRoot\Test-ArtifactPolicy.ps1" -Root $packageRoot
if ($LASTEXITCODE -ne 0) { throw 'Artifact policy rejected integrated Biology package.' }

Compress-Archive -Path (Join-Path $packageRoot '*') -DestinationPath $zipPath -CompressionLevel Optimal
if (-not (Test-Path -LiteralPath $zipPath -PathType Leaf) -or (Get-Item -LiteralPath $zipPath).Length -le 0) { throw 'Integrated Biology package ZIP was not created.' }

Write-Host ''
Write-Host 'PASS: playable integrated Biology REDmod-first package built and exact-compiled. Nothing was deployed or launched.' -ForegroundColor Green
Write-Host "Package root: $packageRoot"
Write-Host "ZIP:          $zipPath"
Write-Host "Game version: $gameVersion"
Write-Host "Revision:     $revision"
Write-Host "REDmod ID:    mods/Biology"
Write-Host ''
Write-Host 'The parent integration thread owns install/deploy and attended acceptance under the canonical operator/test-mode policy.'
return $zipPath
