[CmdletBinding()]
param(
    [string]$GameRoot = 'C:\Games\Steam\steamapps\common\Cyberpunk 2077'
)

$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'Reset-RealPassIteration.ps1 requires PowerShell 7 or newer.' }
. "$PSScriptRoot\Common.ps1"

$project = Get-ProjectRoot
$game = Assert-GameRoot $GameRoot
Assert-GameStopped
$baselinePath = Join-Path $project 'reference\cyberpunk\vanilla-baseline\files.csv'
if (-not (Test-Path -LiteralPath $baselinePath -PathType Leaf)) {
    throw 'No recorded vanilla baseline is available. Use milestone clean-room mode and capture one before relying on iteration cleanup.'
}

$manifestPath = Join-Path $game 'realpass\build-manifest.json'
if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
    throw 'Installed RealPass build manifest is missing. The prior package cannot be proven/removed safely; use milestone clean-room mode.'
}

$baseline = @(Import-Csv -LiteralPath $baselinePath)
$baselineByPath = @{}
foreach ($row in $baseline) {
    $key = ([string]$row.Path).Replace('\','/')
    $baselineByPath[$key] = $row
}

$manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
if ($manifest.schemaVersion -ne 1 -or $manifest.product -ne 'realpass' -or -not $manifest.files) {
    throw 'Installed RealPass build manifest is malformed or unsupported. Use milestone clean-room mode.'
}

$owned = [Collections.Generic.List[object]]::new()
$seen = @{}
foreach ($entry in @($manifest.files)) {
    $relative = ([string]$entry.path).Replace('\','/').TrimStart('/')
    if ([string]::IsNullOrWhiteSpace($relative) -or $relative -match '(^|/)\.\.(/|$)' -or [IO.Path]::IsPathRooted($relative)) {
        throw "Unsafe path in installed RealPass manifest: $relative"
    }
    if ($seen.ContainsKey($relative)) { throw "Duplicate path in installed RealPass manifest: $relative" }
    $seen[$relative] = $true
    if ($baselineByPath.ContainsKey($relative)) {
        throw "Iteration cleanup refuses to remove a package path that existed in vanilla baseline: $relative. Use milestone clean-room mode."
    }
    $expected = ([string]$entry.sha256).ToUpperInvariant()
    if ($expected -notmatch '^[A-F0-9]{64}$') { throw "Invalid installed package hash: $relative" }
    $full = Resolve-SafeChildPath $game $relative
    if (-not (Test-Path -LiteralPath $full -PathType Leaf)) {
        throw "Installed package file is already missing: $relative. State is not provably the prior package; use milestone clean-room mode."
    }
    $actual = Get-Sha256 $full
    if ($actual -ne $expected) {
        throw "Installed package file changed since installation: $relative. Refusing cleanup; use milestone clean-room mode or investigate."
    }
    $owned.Add([pscustomobject]@{ Path=$relative; FullPath=$full })
}

# Finalizer-generated metadata is package-owned but intentionally not part of the
# build-manifest file list. They must also be absent from vanilla before we remove them.
$generated = @(
    'realpass/build-manifest.json',
    'REALPASS-VERSION.txt',
    'SHA256SUMS.txt'
)
foreach ($relative in $generated) {
    if ($baselineByPath.ContainsKey($relative)) {
        throw "Iteration cleanup refuses generated package metadata that overlaps vanilla baseline: $relative"
    }
}

Write-Host ''
Write-Host "Validated $($owned.Count) installed RealPass payload files against their package hashes." -ForegroundColor Cyan
Write-Host 'Removing only package-owned files that were absent from the vanilla baseline...' -ForegroundColor Cyan

$parentCandidates = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach ($entry in $owned) {
    Remove-Item -LiteralPath $entry.FullPath -Force
    [void]$parentCandidates.Add((Split-Path -Parent $entry.FullPath))
}
foreach ($relative in $generated) {
    $full = Resolve-SafeChildPath $game $relative
    if (Test-Path -LiteralPath $full -PathType Leaf) {
        Remove-Item -LiteralPath $full -Force
        [void]$parentCandidates.Add((Split-Path -Parent $full))
    }
}

# Remove only now-empty parent directories created by the package. Stop at game root.
foreach ($start in @($parentCandidates | Sort-Object Length -Descending)) {
    $dir = $start
    while ($dir -and -not $dir.Equals($game,[StringComparison]::OrdinalIgnoreCase)) {
        if (-not (Test-Path -LiteralPath $dir -PathType Container)) { break }
        $children = @(Get-ChildItem -LiteralPath $dir -Force -ErrorAction Stop)
        if ($children.Count -ne 0) { break }
        Remove-Item -LiteralPath $dir -Force
        $dir = Split-Path -Parent $dir
    }
}

Write-Host ''
Write-Host 'Package-owned files removed. Verifying the entire game against the recorded vanilla baseline...' -ForegroundColor Cyan
& "$PSScriptRoot\Compare-GameToVanillaBaseline.ps1" -GameRoot $game
if ($LASTEXITCODE -ne 0) { throw 'Vanilla baseline comparison failed after iteration cleanup.' }

Write-Host ''
Write-Host 'READY FOR ITERATION PACKAGE: previous RealPass payload is gone and the game matches the recorded vanilla baseline.' -ForegroundColor Green
return $true
