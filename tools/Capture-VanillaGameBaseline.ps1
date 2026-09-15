[CmdletBinding()]
param(
    [string]$GameRoot = 'C:\Games\Steam\steamapps\common\Cyberpunk 2077',
    [switch]$Publish
)

$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'Capture-VanillaGameBaseline.ps1 requires PowerShell 7 or newer.' }
. "$PSScriptRoot\Common.ps1"

$project = Get-ProjectRoot
$game = Assert-GameRoot $GameRoot
Assert-GameStopped

$baselineRoot = Join-Path $project 'reference\cyberpunk\vanilla-baseline'
$baselineFiles = Join-Path $baselineRoot 'files.csv'
$baselineEnvironment = Join-Path $baselineRoot 'environment.json'

# A vanilla baseline must not knowingly contain the standard loose-mod surfaces.
$forbiddenRoots = @(
    'archive\pc\mod',
    'red4ext',
    'bin\x64\plugins\cyber_engine_tweaks',
    'r6\scripts',
    'mods'
)
$forbidden = [Collections.Generic.List[string]]::new()
foreach ($relative in $forbiddenRoots) {
    $path = Join-Path $game $relative
    if (Test-Path -LiteralPath $path) {
        $files = @(Get-ChildItem -LiteralPath $path -File -Recurse -Force -ErrorAction SilentlyContinue)
        if ($files.Count -gt 0) { $forbidden.Add("$relative ($($files.Count) file(s))") }
    }
}
if ($forbidden.Count -gt 0) {
    throw "Refusing to capture a vanilla baseline because mod-shaped payload locations are not empty:`n$($forbidden -join "`n")"
}

Write-Host ''
Write-Host 'Refreshing the ordinary GitHub-safe current-game snapshot...' -ForegroundColor Cyan
& "$PSScriptRoot\Refresh-LocalGameReference.ps1" -RepoRoot $project -GamePath $game
if ($LASTEXITCODE -ne 0) { throw 'Refresh-LocalGameReference.ps1 failed.' }

Write-Host ''
Write-Host 'Capturing strict vanilla file baseline (full SHA-256 scan)...' -ForegroundColor Cyan
Write-Host 'This reads the full game installation and may take several minutes. The game is not modified.' -ForegroundColor DarkGray

New-Item -ItemType Directory -Force -Path $baselineRoot | Out-Null
$rows = [Collections.Generic.List[object]]::new()
$totalBytes = [int64]0
$files = @(Get-ChildItem -LiteralPath $game -File -Recurse -Force -ErrorAction Stop | Sort-Object FullName)
$index = 0
foreach ($file in $files) {
    $index++
    if (($index % 250) -eq 0 -or $index -eq $files.Count) {
        Write-Progress -Activity 'Hashing vanilla Cyberpunk files' -Status "$index / $($files.Count)" -PercentComplete (($index / [Math]::Max(1,$files.Count)) * 100)
    }
    $relative = [IO.Path]::GetRelativePath($game,$file.FullName).Replace('\','/')
    $hash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToUpperInvariant()
    $rows.Add([pscustomobject]@{
        Path = $relative
        SizeBytes = [int64]$file.Length
        Sha256 = $hash
    })
    $totalBytes += [int64]$file.Length
}
Write-Progress -Activity 'Hashing vanilla Cyberpunk files' -Completed

$rows | Export-Csv -LiteralPath $baselineFiles -NoTypeInformation -Encoding utf8
$exe = Get-Item -LiteralPath (Join-Path $game 'bin\x64\Cyberpunk2077.exe')
$environment = [ordered]@{
    schemaVersion = 1
    capturedUtc = (Get-Date).ToUniversalTime().ToString('o')
    game = [ordered]@{
        name = 'Cyberpunk 2077'
        version = $exe.VersionInfo.ProductVersion
        executableVersion = $exe.VersionInfo.FileVersion
    }
    files = $rows.Count
    totalBytes = $totalBytes
    hashAlgorithm = 'SHA256'
    purpose = 'Known-clean vanilla baseline for RealPass attended-test residue detection.'
    contentPolicy = 'Derived metadata only; no Cyberpunk-owned file content is stored.'
}
Write-JsonFile $environment $baselineEnvironment

Write-Host ''
Write-Host 'PASS: vanilla baseline captured.' -ForegroundColor Green
Write-Host "Files hashed : $($rows.Count)"
Write-Host "Game version : $($exe.VersionInfo.ProductVersion)"
Write-Host "Baseline     : $baselineRoot"
Write-Host 'No game files were modified.' -ForegroundColor Green

if (-not $Publish) {
    Write-Host ''
    Write-Host 'The metadata is currently only in this checkout. Use -Publish to push it on a dedicated branch for a remote agent.' -ForegroundColor Yellow
    return $baselineRoot
}

$dirtyOutsideReference = @(& git -C $project status --porcelain=v1 --untracked-files=no -- . ':(exclude)reference/cyberpunk')
if ($LASTEXITCODE -ne 0) { throw 'Unable to inspect repository state before publishing baseline.' }
if ($dirtyOutsideReference.Count -gt 0) {
    throw "Refusing to publish baseline from a checkout with other tracked changes:`n$($dirtyOutsideReference -join "`n")"
}

$stamp = [DateTime]::UtcNow.ToString('yyyyMMdd-HHmmss')
$branch = "local-vanilla-baseline-$stamp"
$current = (& git -C $project branch --show-current).Trim()
if ([string]::IsNullOrWhiteSpace($current)) { throw 'Baseline publishing requires a named current Git branch.' }

& git -C $project switch -c $branch
if ($LASTEXITCODE -ne 0) { throw "Could not create baseline branch: $branch" }
& git -C $project add -- 'reference/cyberpunk'
if ($LASTEXITCODE -ne 0) { throw 'Could not stage GitHub-safe Cyberpunk reference metadata.' }
& git -C $project commit -m "Capture clean Cyberpunk vanilla baseline $stamp"
if ($LASTEXITCODE -ne 0) { throw 'Could not commit vanilla baseline metadata.' }
& git -C $project push -u origin $branch
if ($LASTEXITCODE -ne 0) { throw 'Could not push vanilla baseline branch.' }

Write-Host ''
Write-Host 'PUBLISHED: GitHub-safe vanilla baseline branch created.' -ForegroundColor Green
Write-Host "Branch: $branch" -ForegroundColor Cyan
Write-Host "Previous branch: $current"
Write-Host 'Only reference/cyberpunk metadata was committed; no game files were uploaded.' -ForegroundColor Green
Write-Host 'Give the branch name to a remote agent for review/merge.' -ForegroundColor Cyan
return $branch
