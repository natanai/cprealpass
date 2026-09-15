[CmdletBinding()]
param(
    [string]$GameRoot = 'C:\Games\Steam\steamapps\common\Cyberpunk 2077'
)

$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'Reset-BiologyIteration.ps1 requires PowerShell 7 or newer.' }
. "$PSScriptRoot\Common.ps1"

$project = Get-ProjectRoot
$game = Assert-GameRoot $GameRoot
Assert-GameStopped
$baselinePath = Join-Path $project 'reference\cyberpunk\vanilla-baseline\files.csv'
if (-not (Test-Path -LiteralPath $baselinePath -PathType Leaf)) {
    throw 'No recorded vanilla baseline is available. Use MILESTONE CLEAN-ROOM mode and capture one before relying on iteration cleanup.'
}

$manifestPath = Join-Path $game 'biology\build-manifest.json'
if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
    throw 'Installed Biology build manifest is missing. The prior package cannot be proven/removed safely; use MILESTONE CLEAN-ROOM mode.'
}

$baseline = @(Import-Csv -LiteralPath $baselinePath)
$baselineByPath = @{}
foreach ($row in $baseline) {
    $key = ([string]$row.Path).Replace('\','/')
    $baselineByPath[$key] = $row
}

$manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
if ($manifest.schemaVersion -ne 1 -or $manifest.product -ne 'Biology' -or $manifest.playableRuntimeIncluded -ne $true -or -not $manifest.files) {
    throw 'Installed Biology build manifest is malformed, non-playable, or unsupported. Use MILESTONE CLEAN-ROOM mode.'
}

$owned = [Collections.Generic.List[object]]::new()
$seen = @{}
foreach ($entry in @($manifest.files)) {
    $relative = ([string]$entry.path).Replace('\','/').TrimStart('/')
    if ([string]::IsNullOrWhiteSpace($relative) -or $relative -match '(^|/)\.\.(/|$)' -or [IO.Path]::IsPathRooted($relative)) {
        throw "Unsafe path in installed Biology manifest: $relative"
    }
    if ($seen.ContainsKey($relative)) { throw "Duplicate path in installed Biology manifest: $relative" }
    $seen[$relative] = $true
    if ($baselineByPath.ContainsKey($relative)) {
        throw "Iteration cleanup refuses to remove a package path that existed in the vanilla baseline: $relative. Use MILESTONE CLEAN-ROOM mode."
    }
    if ([string]::IsNullOrWhiteSpace([string]$entry.owner) -or [string]::IsNullOrWhiteSpace([string]$entry.component) -or [string]::IsNullOrWhiteSpace([string]$entry.route)) {
        throw "Installed Biology manifest has incomplete ownership metadata: $relative"
    }
    if ([string]$entry.replacePolicy -notin @('biology-owned','approved-dependency-owned')) {
        throw "Installed Biology manifest has unsupported replacement policy: $relative / $($entry.replacePolicy)"
    }
    $expected = ([string]$entry.sha256).ToUpperInvariant()
    if ($expected -notmatch '^[A-F0-9]{64}$') { throw "Invalid installed package hash: $relative" }
    $full = Resolve-SafeChildPath $game $relative
    if (-not (Test-Path -LiteralPath $full -PathType Leaf)) {
        throw "Installed package file is already missing: $relative. State is not provably the prior Biology package; use MILESTONE CLEAN-ROOM mode."
    }
    $actual = Get-Sha256 $full
    if ($actual -ne $expected) {
        throw "Installed package file changed since installation: $relative. Refusing cleanup; use MILESTONE CLEAN-ROOM mode or investigate."
    }
    $owned.Add([pscustomobject]@{ Path=$relative; FullPath=$full })
}

# SHA256SUMS and the owner manifest are generated after the ordinary file list is
# finalized. They are package metadata but cannot recursively list/hash themselves.
$generated = @(
    'biology/build-manifest.json',
    'SHA256SUMS.txt'
)
foreach ($relative in $generated) {
    if ($baselineByPath.ContainsKey($relative)) {
        throw "Iteration cleanup refuses generated Biology metadata that overlaps the vanilla baseline: $relative"
    }
}

Write-Host ''
Write-Host "Validated $($owned.Count) installed Biology payload files against their package hashes and ownership records." -ForegroundColor Cyan
Write-Host 'Removing only exact package-owned files that were absent from the vanilla baseline...' -ForegroundColor Cyan

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

# Remove only now-empty directories reached from files this exact package owned.
# Shared roots are never recursively selected for deletion and traversal stops at game root.
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
Write-Host 'Biology package-owned files removed. Verifying the entire game against the recorded vanilla baseline...' -ForegroundColor Cyan
& "$PSScriptRoot\Compare-GameToVanillaBaseline.ps1" -GameRoot $game
if ($LASTEXITCODE -ne 0) {
    throw 'Vanilla baseline comparison failed after Biology cleanup. Do not install another candidate over this state; use MILESTONE CLEAN-ROOM mode or investigate the exact residue.'
}

Write-Host ''
Write-Host 'READY FOR ITERATION PACKAGE: previous Biology-owned payload is gone and the game matches the recorded vanilla baseline.' -ForegroundColor Green
return $true
