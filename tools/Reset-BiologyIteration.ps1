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
    $key = ([string]$row.Path).Replace('\\','/')
    $baselineByPath[$key] = $row
}

$manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
if ($manifest.schemaVersion -ne 2 -or $manifest.product -ne 'Biology' -or $manifest.playableRuntimeIncluded -ne $true -or -not $manifest.files) {
    throw 'Installed Biology build manifest is malformed, non-playable, or unsupported. Use MILESTONE CLEAN-ROOM mode.'
}
if ($manifest.uninstall.biologyOwnedPolicy -ne 'biology-owned' -or $manifest.uninstall.genericDependencyPolicy -ne 'preserve') {
    throw 'Installed Biology manifest has an unsupported uninstall-policy contract. Use MILESTONE CLEAN-ROOM mode.'
}

$removable = [Collections.Generic.List[object]]::new()
$preservedGeneric = [Collections.Generic.List[string]]::new()
$seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach ($entry in @($manifest.files)) {
    $relative = ([string]$entry.path).Replace('\\','/').TrimStart('/')
    if ([string]::IsNullOrWhiteSpace($relative) -or $relative -match '(^|/)\.\.(/|$)' -or $relative -match '(^|/)\.(/|$)' -or $relative.Contains(':') -or [IO.Path]::IsPathRooted($relative)) {
        throw "Unsafe path in installed Biology manifest: $relative"
    }
    if (-not $seen.Add($relative)) { throw "Duplicate path in installed Biology manifest: $relative" }
    if ([string]::IsNullOrWhiteSpace([string]$entry.owner) -or [string]::IsNullOrWhiteSpace([string]$entry.component) -or [string]::IsNullOrWhiteSpace([string]$entry.route)) {
        throw "Installed Biology manifest has incomplete ownership metadata: $relative"
    }
    if ([string]$entry.replacePolicy -notin @('biology-owned','generic-dependency-shared')) {
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

    if ([string]$entry.replacePolicy -eq 'biology-owned') {
        if ($baselineByPath.ContainsKey($relative)) {
            throw "Iteration cleanup refuses to remove a Biology-owned path that existed in the vanilla baseline: $relative. Use MILESTONE CLEAN-ROOM mode."
        }
        $removable.Add([pscustomobject]@{ Path=$relative; FullPath=$full; Policy='biology-owned' })
    } else {
        # Player uninstall always preserves generic dependencies. This stricter
        # developer reset may remove an exact generic file only when the recorded
        # pristine baseline proves Biology introduced it into this installation.
        if ($baselineByPath.ContainsKey($relative)) {
            $preservedGeneric.Add($relative)
        } else {
            $removable.Add([pscustomobject]@{ Path=$relative; FullPath=$full; Policy='generic-dependency-shared' })
        }
    }
}

if ($baselineByPath.ContainsKey('biology/build-manifest.json')) {
    throw 'Iteration cleanup refuses generated Biology ownership metadata that overlaps the vanilla baseline.'
}

Write-Host ''
Write-Host "Validated $($manifest.files.Count) installed Biology receipt entries against hashes and ownership policy." -ForegroundColor Cyan
Write-Host "Removing $($removable.Count) exact files; preserving $($preservedGeneric.Count) generic files that pre-existed in the vanilla baseline." -ForegroundColor Cyan

$parentCandidates = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach ($entry in $removable) {
    # Re-hash immediately before deletion so a file changed after planning is never
    # silently removed.
    $receiptEntry = @($manifest.files | Where-Object { ([string]$_.path).Replace('\\','/') -eq $entry.Path })
    if ($receiptEntry.Count -ne 1 -or (Get-Sha256 $entry.FullPath) -ne ([string]$receiptEntry[0].sha256).ToUpperInvariant()) {
        throw "Installed package file changed during cleanup planning: $($entry.Path). Refusing cleanup."
    }
    Remove-Item -LiteralPath $entry.FullPath -Force
    [void]$parentCandidates.Add((Split-Path -Parent $entry.FullPath))
}

if (Test-Path -LiteralPath $manifestPath -PathType Leaf) {
    Remove-Item -LiteralPath $manifestPath -Force
    [void]$parentCandidates.Add((Split-Path -Parent $manifestPath))
}

# Remove only now-empty directories reached from files this exact package owned.
# Never recursively remove any root, and never climb through protected shared roots.
$protectedTopRoots = @('bin','archive','engine','r6','red4ext','mods','LICENSES')
foreach ($start in @($parentCandidates | Sort-Object Length -Descending)) {
    $dir = $start
    while ($dir -and -not $dir.Equals($game,[StringComparison]::OrdinalIgnoreCase)) {
        $relativeDir = [IO.Path]::GetRelativePath($game,$dir).Replace('\\','/')
        $top = ($relativeDir -split '/')[0]
        if ($relativeDir -in $protectedTopRoots) { break }
        if ($top -in $protectedTopRoots -and $relativeDir -notmatch '^(mods/Biology|r6/scripts/CyberpunkRealism|biology)(/|$)') { break }
        if (-not (Test-Path -LiteralPath $dir -PathType Container)) { break }
        $children = @(Get-ChildItem -LiteralPath $dir -Force -ErrorAction Stop)
        if ($children.Count -ne 0) { break }
        Remove-Item -LiteralPath $dir -Force
        $dir = Split-Path -Parent $dir
    }
}

Write-Host ''
Write-Host 'Biology iteration payload removed. Verifying the entire game against the recorded vanilla baseline...' -ForegroundColor Cyan
& "$PSScriptRoot\Compare-GameToVanillaBaseline.ps1" -GameRoot $game
if ($LASTEXITCODE -ne 0) {
    throw 'Vanilla baseline comparison failed after Biology cleanup. Do not install another candidate over this state; use MILESTONE CLEAN-ROOM mode or investigate the exact residue.'
}

Write-Host ''
Write-Host 'READY FOR ITERATION PACKAGE: previous Biology-owned payload is gone and the game matches the recorded vanilla baseline.' -ForegroundColor Green
return $true
