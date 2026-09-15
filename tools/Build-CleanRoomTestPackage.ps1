param(
    [string]$GameRoot = 'C:\Games\Steam\steamapps\common\Cyberpunk 2077',
    [string]$OutputRoot,
    [switch]$Diagnostics
)
$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'Build-CleanRoomTestPackage.ps1 requires PowerShell 7 or newer.' }
. "$PSScriptRoot\Common.ps1"

$project = Get-ProjectRoot
$game = Assert-GameRoot $GameRoot
Assert-GameStopped

if (-not $OutputRoot) { $OutputRoot = Join-Path $project 'staging\clean-room-packages' }
$OutputRoot = [IO.Path]::GetFullPath($OutputRoot)
New-Item -ItemType Directory -Force -Path $OutputRoot | Out-Null

# Broad clean-room acceptance should originate from an ordinary received repository
# state, not from uncommitted source edits. A source ZIP has no .git directory, so
# this check is intentionally conditional.
$revision = 'source-archive'
$shortRevision = 'archive'
$gitDir = Join-Path $project '.git'
if (Test-Path -LiteralPath $gitDir) {
    $dirty = @(& git -C $project status --porcelain=v1 --untracked-files=no)
    if ($LASTEXITCODE -ne 0) { throw 'Unable to inspect repository state.' }
    if ($dirty.Count -gt 0) {
        throw "Clean-room package build requires no modified tracked files. Commit/push the candidate or use a fresh clone/download first.`n$($dirty -join "`n")"
    }
    $revision = (& git -C $project rev-parse HEAD).Trim()
    if ($LASTEXITCODE -ne 0 -or $revision -notmatch '^[A-Fa-f0-9]{40}$') { throw 'Unable to resolve repository revision.' }
    $shortRevision = $revision.Substring(0,12).ToLowerInvariant()
}

$stamp = [DateTime]::UtcNow.ToString('yyyyMMdd-HHmmss')
$buildId = "realpass-cleanroom-$stamp-$shortRevision"
$packageRoot = Join-Path $OutputRoot ($buildId + '-root')
$zipPath = Join-Path $OutputRoot ($buildId + '.zip')
if ((Test-Path -LiteralPath $packageRoot) -or (Test-Path -LiteralPath $zipPath)) {
    throw "Clean-room package output already exists for build ID: $buildId"
}
New-Item -ItemType Directory -Force -Path $packageRoot | Out-Null

# Build and exact-compile the same complete owned runtime profile that is intended to
# ship. This writes only repository build outputs; it does not deploy to GameRoot.
$profileArgs = @{ BuildId = $buildId; GameRoot = $game }
if ($Diagnostics) { $profileArgs.Diagnostics = $true }
$manifestRelative = & "$PSScriptRoot\Build-OwnedRuntimeProfile.ps1" @profileArgs
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($manifestRelative)) {
    throw 'Owned runtime profile build failed.'
}
$manifestPath = Resolve-SafeChildPath $project ([string]$manifestRelative)
$manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
$actualGameVersion = (Get-Item -LiteralPath (Join-Path $game 'bin\x64\Cyberpunk2077.exe')).VersionInfo.ProductVersion
if ($manifest.schemaVersion -ne 1 -or -not $manifest.ownedRuntime -or $manifest.gameVersion -ne $actualGameVersion) {
    throw 'Unexpected owned runtime manifest.'
}

$planFiles = [Collections.Generic.List[object]]::new()
$components = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)

function Add-PlanFile([string]$RelativePath, [string]$Owner, [string]$Component, [string]$ReplacePolicy) {
    $normalized = $RelativePath.Replace('\','/').TrimStart('/')
    $planFiles.Add([ordered]@{
        path = $normalized
        owner = $Owner
        component = $Component
        replacePolicy = $ReplacePolicy
    })
}

# Materialize the runtime manifest into a game-root-shaped package directory.
foreach ($entry in @($manifest.files)) {
    $source = Resolve-SafeChildPath $project ([string]$entry.source)
    if ((Get-Sha256 $source) -ne [string]$entry.sha256) { throw "Runtime source hash mismatch: $source" }
    $relative = ([string]$entry.destination).Replace('\','/')
    $destination = Resolve-SafeChildPath $packageRoot $relative
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $destination) | Out-Null
    Copy-VerifiedPayload $source $destination ([string]$entry.sha256)
    $component = [string]$entry.component
    [void]$components.Add($component)
    $policy = if ($component -eq 'realpass') { 'realpass-owned' } else { 'approved-dependency-owned' }
    $owner = if ($component -eq 'realpass') { 'realpass' } else { 'upstream:' + $component }
    Add-PlanFile $relative $owner $component $policy
}

# Include the repository's audited notice snapshots for each bundled generic
# dependency. The package copies them under stable names rather than exposing vendor
# or staging directories.
$licenseRoot = Join-Path $packageRoot 'LICENSES'
New-Item -ItemType Directory -Force -Path $licenseRoot | Out-Null
foreach ($component in @($components | Sort-Object)) {
    if ($component -eq 'realpass') { continue }
    $matches = @(Get-ChildItem -LiteralPath (Join-Path $project 'LICENSES') -File -Filter ($component + '-v*.txt'))
    if ($matches.Count -ne 1) { throw "Expected exactly one tracked license snapshot for bundled component '$component', found $($matches.Count)." }
    $destination = Join-Path $licenseRoot ($component + '.txt')
    Copy-Item -LiteralPath $matches[0].FullName -Destination $destination
    Add-PlanFile ('LICENSES/' + $component + '.txt') 'realpass' 'realpass-project-original' 'realpass-owned'
}

$installText = @'
RealPass clean-room test package

SUPPORTED GAME
Cyberpunk 2077 2.31

INSTALL / TEST
1. Start from a vanilla Cyberpunk 2077 installation.
2. Close Cyberpunk 2077.
3. Extract/copy the CONTENTS of this package into the Cyberpunk 2077 game root (the folder containing bin, archive, engine and r6).
4. Merge folders when Windows asks.
5. Launch Cyberpunk 2077 normally through Steam.

This package is deliberately game-root-shaped so attended testing exercises the same drag-and-drop installation model intended for players.
'@
[IO.File]::WriteAllText((Join-Path $packageRoot 'INSTALL.txt'),$installText.TrimStart() + "`n",[Text.UTF8Encoding]::new($false))
Add-PlanFile 'INSTALL.txt' 'realpass' 'realpass-project-original' 'realpass-owned'

$uninstallText = @'
RealPass clean-room test package

For clean-room development acceptance, do not rely on this package to restore a modded game to vanilla.
Before the next broad candidate, uninstall Cyberpunk 2077 in Steam, delete any residual Cyberpunk 2077 game directory, and reinstall through Steam.

Save data is outside the game install directory and is not part of this package.
'@
[IO.File]::WriteAllText((Join-Path $packageRoot 'UNINSTALL.txt'),$uninstallText.TrimStart() + "`n",[Text.UTF8Encoding]::new($false))
Add-PlanFile 'UNINSTALL.txt' 'realpass' 'realpass-project-original' 'realpass-owned'

$realpassDir = Join-Path $packageRoot 'realpass'
New-Item -ItemType Directory -Force -Path $realpassDir | Out-Null
$provenanceComponents = @($components | ForEach-Object { if ($_ -eq 'realpass') { 'realpass-project-original' } else { $_ } } | Sort-Object -Unique)
$provenance = [ordered]@{
    schemaVersion = 1
    product = 'realpass'
    buildId = $buildId
    sourceRevision = $revision
    gameVersion = [string]$manifest.gameVersion
    cleanRoomTestPackage = $true
    components = $provenanceComponents
    sourceModsRequired = @()
}
Write-JsonFile $provenance (Join-Path $realpassDir 'provenance.json')
Add-PlanFile 'realpass/provenance.json' 'realpass' 'realpass-project-original' 'realpass-owned'

$plan = [ordered]@{
    schemaVersion = 1
    product = 'realpass'
    files = @($planFiles.ToArray())
}
$planRelative = 'manifest/' + $buildId + '.player-package-plan.json'
$planPath = Resolve-SafeChildPath $project $planRelative
Write-JsonFile $plan $planPath

$version = 'test-' + $stamp + '-' + $shortRevision
$sourceForMetadata = if ($revision -match '^[A-Fa-f0-9]{7,64}$') { $revision } else { '0000000' }
& "$PSScriptRoot\Finalize-PlayerPackage.ps1" -Root $packageRoot -PlanPath $planRelative -Version $version -GameVersion ([string]$manifest.gameVersion) -SourceRevision $sourceForMetadata | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'Player-package finalization failed.' }

# Build an archive whose contents are already game-root-shaped. The user extracts the
# ZIP and copies/merges those contents into the vanilla game root.
Compress-Archive -Path (Join-Path $packageRoot '*') -DestinationPath $zipPath -CompressionLevel Optimal
if (-not (Test-Path -LiteralPath $zipPath -PathType Leaf) -or (Get-Item -LiteralPath $zipPath).Length -le 0) {
    throw 'Clean-room package ZIP was not created.'
}

Write-Host ''
Write-Host 'PASS: clean-room RealPass package built. Nothing was deployed to Cyberpunk.' -ForegroundColor Green
Write-Host "Package root: $packageRoot"
Write-Host "ZIP:          $zipPath"
Write-Host "Game version: $($manifest.gameVersion)"
Write-Host "Revision:     $revision"
Write-Host ''
Write-Host 'For attended testing, apply this ZIP to a freshly restored vanilla game directory by ordinary folder merge, then launch through Steam.'
return $zipPath
