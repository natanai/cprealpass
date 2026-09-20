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
# The stock/empty REDmod directory is a special case: CDPR's documented empty
# state contains only mods\.stub. Permit that exact zero-byte marker and nothing
# else under mods.
$forbiddenRoots = @(
    'archive\pc\mod',
    'red4ext',
    'bin\x64\plugins\cyber_engine_tweaks',
    'r6\scripts'
)
$forbidden = [Collections.Generic.List[string]]::new()
foreach ($relative in $forbiddenRoots) {
    $path = Join-Path $game $relative
    if (Test-Path -LiteralPath $path) {
        $files = @(Get-ChildItem -LiteralPath $path -File -Recurse -Force -ErrorAction SilentlyContinue)
        if ($files.Count -gt 0) { $forbidden.Add("$relative ($($files.Count) file(s))") }
    }
}

$modsRoot = Join-Path $game 'mods'
if (Test-Path -LiteralPath $modsRoot) {
    $modFiles = @(Get-ChildItem -LiteralPath $modsRoot -File -Recurse -Force -ErrorAction SilentlyContinue)
    foreach ($file in $modFiles) {
        $relativeToMods = [IO.Path]::GetRelativePath($modsRoot, $file.FullName).Replace('\','/')
        $isVanillaStub = $relativeToMods -eq '.stub' -and $file.Length -eq 0
        if (-not $isVanillaStub) {
            $forbidden.Add("mods/$relativeToMods ($($file.Length) byte(s))")
        }
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
$expectedBytes = [int64](($files | Measure-Object -Property Length -Sum).Sum)
$index = 0
$startedAt = Get-Date
$lastReportedBucket = -1

foreach ($file in $files) {
    $index++
    $relative = [IO.Path]::GetRelativePath($game,$file.FullName).Replace('\','/')
    $hash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToUpperInvariant()
    $rows.Add([pscustomobject]@{
        Path = $relative
        SizeBytes = [int64]$file.Length
        Sha256 = $hash
    })
    $totalBytes += [int64]$file.Length

    $percent = if ($expectedBytes -gt 0) {
        [int][Math]::Floor(($totalBytes / [double]$expectedBytes) * 100.0)
    } else {
        [int][Math]::Floor(($index / [double][Math]::Max(1,$files.Count)) * 100.0)
    }
    $percent = [Math]::Min(100,[Math]::Max(0,$percent))

    if (($index % 100) -eq 0 -or $index -eq $files.Count) {
        Write-Progress -Activity 'Hashing vanilla Cyberpunk files' -Status "$index / $($files.Count) files; $percent%" -PercentComplete $percent
    }

    # Write-Progress can be hidden when pwsh is launched from another PowerShell
    # host. Emit a durable console bar every 5 percentage points so the user can
    # always see that a long whole-game hash is advancing.
    $bucket = [int][Math]::Floor($percent / 5)
    if ($bucket -gt $lastReportedBucket -or $index -eq $files.Count) {
        $lastReportedBucket = $bucket
        $barWidth = 20
        $filled = [Math]::Min($barWidth,[int][Math]::Floor(($percent / 100.0) * $barWidth))
        $bar = ('#' * $filled) + ('-' * ($barWidth - $filled))
        $hashedGiB = $totalBytes / 1GB
        $expectedGiB = $expectedBytes / 1GB
        $elapsed = ((Get-Date) - $startedAt).ToString('hh\:mm\:ss')
        Write-Host ("HASH [{0}] {1,3}% | {2}/{3} files | {4:N1}/{5:N1} GiB | elapsed {6}" -f $bar,$percent,$index,$files.Count,$hashedGiB,$expectedGiB,$elapsed) -ForegroundColor Cyan
    }
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

# Fresh disposable test clones are not required to have a user-level Git author
# configured. Scope a neutral identity to this one generated metadata commit only.
$commitAuthorName = 'RealPass Snapshot'
$commitAuthorEmail = 'realpass-snapshot@users.noreply.github.com'
& git -C $project -c "user.name=$commitAuthorName" -c "user.email=$commitAuthorEmail" commit -m "Capture clean Cyberpunk vanilla baseline $stamp"
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
