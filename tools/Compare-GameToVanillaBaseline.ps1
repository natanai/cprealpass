[CmdletBinding()]
param(
    [string]$GameRoot = 'C:\Games\Steam\steamapps\common\Cyberpunk 2077'
)

$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'Compare-GameToVanillaBaseline.ps1 requires PowerShell 7 or newer.' }
. "$PSScriptRoot\Common.ps1"

$project = Get-ProjectRoot
$game = Assert-GameRoot $GameRoot
Assert-GameStopped
$baselineRoot = Join-Path $project 'reference\cyberpunk\vanilla-baseline'
$baselineFiles = Join-Path $baselineRoot 'files.csv'
$baselineEnvironment = Join-Path $baselineRoot 'environment.json'
if (-not (Test-Path -LiteralPath $baselineFiles -PathType Leaf) -or -not (Test-Path -LiteralPath $baselineEnvironment -PathType Leaf)) {
    throw 'No tracked vanilla baseline found. Run Capture-VanillaGameBaseline.ps1 from a known-clean install first.'
}

$baseline = @(Import-Csv -LiteralPath $baselineFiles)
$baselineByPath = @{}
foreach ($row in $baseline) {
    $path = [string]$row.Path
    if ([string]::IsNullOrWhiteSpace($path) -or $baselineByPath.ContainsKey($path)) { throw "Invalid or duplicate baseline path: $path" }
    if ([string]$row.Sha256 -notmatch '^[A-Fa-f0-9]{64}$') { throw "Invalid baseline hash: $path" }
    $baselineByPath[$path] = $row
}

Write-Host ''
Write-Host 'Comparing current Cyberpunk installation to recorded vanilla baseline...' -ForegroundColor Cyan
Write-Host 'This is a strict full-file comparison and may take several minutes.' -ForegroundColor DarkGray

$currentFiles = @(Get-ChildItem -LiteralPath $game -File -Recurse -Force -ErrorAction Stop | Sort-Object FullName)
$currentByPath = @{}
foreach ($file in $currentFiles) {
    $relative = [IO.Path]::GetRelativePath($game,$file.FullName).Replace('\','/')
    $currentByPath[$relative] = $file
}

$issues = [Collections.Generic.List[object]]::new()
foreach ($path in @($currentByPath.Keys | Sort-Object)) {
    if (-not $baselineByPath.ContainsKey($path)) {
        $issues.Add([pscustomobject]@{ Status='EXTRA'; Path=$path; Detail='Present now, absent from vanilla baseline' })
    }
}

$index = 0
foreach ($path in @($baselineByPath.Keys | Sort-Object)) {
    $index++
    if (($index % 250) -eq 0 -or $index -eq $baselineByPath.Count) {
        Write-Progress -Activity 'Verifying vanilla baseline' -Status "$index / $($baselineByPath.Count)" -PercentComplete (($index / [Math]::Max(1,$baselineByPath.Count)) * 100)
    }
    if (-not $currentByPath.ContainsKey($path)) {
        $issues.Add([pscustomobject]@{ Status='MISSING'; Path=$path; Detail='Present in vanilla baseline, absent now' })
        continue
    }
    $file = $currentByPath[$path]
    $row = $baselineByPath[$path]
    if ([int64]$file.Length -ne [int64]$row.SizeBytes) {
        $issues.Add([pscustomobject]@{ Status='SIZE'; Path=$path; Detail="baseline=$($row.SizeBytes) current=$($file.Length)" })
        continue
    }
    $hash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToUpperInvariant()
    if ($hash -ne ([string]$row.Sha256).ToUpperInvariant()) {
        $issues.Add([pscustomobject]@{ Status='HASH'; Path=$path; Detail='SHA-256 differs from vanilla baseline' })
    }
}
Write-Progress -Activity 'Verifying vanilla baseline' -Completed

if ($issues.Count -gt 0) {
    Write-Host ''
    Write-Host "FAIL: game differs from vanilla baseline in $($issues.Count) file(s)." -ForegroundColor Red
    $issues | Sort-Object Status, Path | Format-Table -AutoSize
    throw 'Game directory is not proven clean. Do not layer another attended RealPass candidate over it; use a milestone clean-room reset or investigate the differences.'
}

Write-Host ''
Write-Host "PASS: game exactly matches recorded vanilla baseline ($($baselineByPath.Count) files)." -ForegroundColor Green
return $true
