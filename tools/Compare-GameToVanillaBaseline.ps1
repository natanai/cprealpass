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
$expectedBytes = [int64]0
foreach ($row in $baseline) {
    $path = [string]$row.Path
    if ([string]::IsNullOrWhiteSpace($path) -or $baselineByPath.ContainsKey($path)) { throw "Invalid or duplicate baseline path: $path" }
    if ([string]$row.Sha256 -notmatch '^[A-Fa-f0-9]{64}$') { throw "Invalid baseline hash: $path" }
    $size = [int64]$row.SizeBytes
    if ($size -lt 0) { throw "Invalid baseline size: $path" }
    $baselineByPath[$path] = $row
    $expectedBytes += $size
}

Write-Host ''
Write-Host 'Comparing current Cyberpunk installation to recorded vanilla baseline...' -ForegroundColor Cyan
Write-Host 'This is a strict full-file comparison and may take several minutes.' -ForegroundColor DarkGray
Write-Host 'Durable VERIFY progress is printed every ~5% so progress remains visible even when Write-Progress is hidden.' -ForegroundColor DarkGray

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
$processedBytes = [int64]0
$startedAt = Get-Date
$lastReportedBucket = -1
$baselinePaths = @($baselineByPath.Keys | Sort-Object)
foreach ($path in $baselinePaths) {
    $index++
    $row = $baselineByPath[$path]
    $rowBytes = [int64]$row.SizeBytes

    if (-not $currentByPath.ContainsKey($path)) {
        $issues.Add([pscustomobject]@{ Status='MISSING'; Path=$path; Detail='Present in vanilla baseline, absent now' })
    } else {
        $file = $currentByPath[$path]
        if ([int64]$file.Length -ne $rowBytes) {
            $issues.Add([pscustomobject]@{ Status='SIZE'; Path=$path; Detail="baseline=$($row.SizeBytes) current=$($file.Length)" })
        } else {
            $hash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToUpperInvariant()
            if ($hash -ne ([string]$row.Sha256).ToUpperInvariant()) {
                $issues.Add([pscustomobject]@{ Status='HASH'; Path=$path; Detail='SHA-256 differs from vanilla baseline' })
            }
        }
    }

    $processedBytes += $rowBytes
    $percent = if ($expectedBytes -gt 0) {
        [int][Math]::Floor(($processedBytes / [double]$expectedBytes) * 100.0)
    } else {
        [int][Math]::Floor(($index / [double][Math]::Max(1,$baselinePaths.Count)) * 100.0)
    }
    $percent = [Math]::Min(100,[Math]::Max(0,$percent))

    if (($index % 250) -eq 0 -or $index -eq $baselinePaths.Count) {
        Write-Progress -Activity 'Verifying vanilla baseline' -Status "$index / $($baselinePaths.Count) files; $percent%" -PercentComplete $percent
    }

    $bucket = [int][Math]::Floor($percent / 5)
    if ($bucket -gt $lastReportedBucket -or $index -eq $baselinePaths.Count) {
        $lastReportedBucket = $bucket
        $barWidth = 20
        $filled = [Math]::Min($barWidth,[int][Math]::Floor(($percent / 100.0) * $barWidth))
        $bar = ('#' * $filled) + ('-' * ($barWidth - $filled))
        $processedGiB = $processedBytes / 1GB
        $expectedGiB = $expectedBytes / 1GB
        $elapsed = ((Get-Date) - $startedAt).ToString('hh\:mm\:ss')
        Write-Host ("VERIFY [{0}] {1,3}% | {2}/{3} files | {4:N1}/{5:N1} GiB | elapsed {6}" -f $bar,$percent,$index,$baselinePaths.Count,$processedGiB,$expectedGiB,$elapsed) -ForegroundColor Cyan
    }
}
Write-Progress -Activity 'Verifying vanilla baseline' -Completed

if ($issues.Count -gt 0) {
    Write-Host ''
    Write-Host "FAIL: game differs from vanilla baseline in $($issues.Count) file(s)." -ForegroundColor Red
    $issues | Sort-Object Status, Path | Format-Table -AutoSize
    throw 'Game directory is not proven clean. Do not layer another attended Biology candidate over it; use a milestone clean-room reset or investigate the differences.'
}

Write-Host ''
Write-Host "PASS: game exactly matches recorded vanilla baseline ($($baselineByPath.Count) files)." -ForegroundColor Green
return $true
