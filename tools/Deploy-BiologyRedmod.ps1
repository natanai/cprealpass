param(
    [string]$GameRoot = 'C:\Games\Steam\steamapps\common\Cyberpunk 2077'
)
$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'Deploy-BiologyRedmod.ps1 requires PowerShell 7 or newer.' }
. "$PSScriptRoot\Common.ps1"

$game = Assert-GameRoot $GameRoot
Assert-GameStopped
$info = Join-Path $game 'mods\Biology\info.json'
if (-not (Test-Path -LiteralPath $info -PathType Leaf)) { throw "Biology REDmod identity is not installed at $info" }
$redmod = Join-Path $game 'tools\redmod\bin\redMod.exe'
if (-not (Test-Path -LiteralPath $redmod -PathType Leaf)) { throw "Official REDmod executable not found: $redmod" }
$version = (Get-Item -LiteralPath $redmod).VersionInfo
if ($version.FileVersion -ne '2.3.1.0' -or $version.ProductVersion -ne '2.31') {
    throw "This deployment contract is evidenced for REDmod file 2.3.1.0 / product 2.31; installed tool reports $($version.FileVersion) / $($version.ProductVersion)."
}

function Invoke-Redmod([string[]]$Arguments) {
    $psi = [Diagnostics.ProcessStartInfo]::new()
    $psi.FileName = $redmod
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.CreateNoWindow = $true
    $psi.WorkingDirectory = Split-Path -Parent $redmod
    foreach ($arg in $Arguments) { [void]$psi.ArgumentList.Add($arg) }

    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $psi
    if (-not $process.Start()) { throw 'Could not start official REDmod executable.' }
    $stdout = $process.StandardOutput.ReadToEnd()
    $stderr = $process.StandardError.ReadToEnd()
    $process.WaitForExit()
    $combined = (($stdout,$stderr | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }) -join "`n").Trim()
    [pscustomobject]@{ ExitCode=$process.ExitCode; Output=$combined; Args=$Arguments }
}

function Write-Attempt($attempt,[string]$label) {
    Write-Host ''
    Write-Host $label -ForegroundColor Cyan
    if (-not [string]::IsNullOrWhiteSpace($attempt.Output)) { Write-Host $attempt.Output }
}

function Has-BadRootSignal([string]$text) {
    $text -match '(?im)No root specified|Invalid root path found'
}

Write-Host "Deploying installed REDmods with explicit root: $game"

# Attended W09 evidence on REDmod 2.31 proved that, after a successful no-mod
# refresh followed by reinstall, r6/cache may still exist while the shared
# r6/cache/modded output root is absent. REDmod then reaches TweakDB compilation
# but fails to move tweakdb_ep1.bin into that missing parent (Win32 0x3).
#
# Prepare only the official shared output directory immediately at the deploy
# boundary. This is intentionally idempotent: existing contents from Biology or
# any other REDmods are preserved, and no generated cache file or mods.json is
# created, copied, replaced, or deleted here.
$moddedRoot = Resolve-SafeChildPath $game 'r6\cache\modded'
if (Test-Path -LiteralPath $moddedRoot -PathType Leaf) {
    throw "REDmod output root is blocked by a file: $moddedRoot"
}
if (-not (Test-Path -LiteralPath $moddedRoot -PathType Container)) {
    New-Item -ItemType Directory -Path $moddedRoot -Force | Out-Null
    Write-Host "Prepared missing REDmod output directory: $moddedRoot" -ForegroundColor DarkGray
}
if (-not (Test-Path -LiteralPath $moddedRoot -PathType Container)) {
    throw "Could not prepare REDmod output directory: $moddedRoot"
}

# Current 2.31 accepts the conventional split form used by current community
# tooling. ProcessStartInfo.ArgumentList guarantees the game path remains one
# argument even though it contains spaces.
$attempt = Invoke-Redmod @('deploy','-root',$game)
Write-Attempt $attempt 'REDmod deploy attempt: deploy -root <game>'

# Older official documentation shows -root=<path>. Retry only when REDmod itself
# proves the first form was not parsed as a root argument. A failed parsing
# attempt cannot have deployed Biology because REDmod did not resolve the game.
if (Has-BadRootSignal $attempt.Output) {
    Write-Host 'REDmod did not consume the split root form; retrying documented -root=<path> form...' -ForegroundColor Yellow
    $attempt = Invoke-Redmod @('deploy',("-root=$game"))
    Write-Attempt $attempt 'REDmod deploy attempt: deploy -root=<game>'
}

if ($attempt.ExitCode -ne 0) { throw "REDmod deploy failed with exit code $($attempt.ExitCode)." }
if (Has-BadRootSignal $attempt.Output) {
    throw 'REDmod returned exit 0 but did not consume the explicit game root. Deployment is NOT accepted.'
}
if ($attempt.Output -match '(?im)No mods found, no deployment is needed') {
    throw 'REDmod returned exit 0 but reported no mods found. Biology is installed at mods\Biology\info.json but was not recognized as a deployable REDmod; route this as a package-recognition failure.'
}
if ($attempt.Output -notmatch '(?im)\[DEPLOY\]' -or $attempt.Output -notmatch '(?im)Commandlet deploy has succeeded') {
    throw 'REDmod returned exit 0 without the expected deploy-stage/success evidence. Deployment is NOT accepted.'
}

Write-Host ''
Write-Host 'PASS: REDmod consumed the explicit game root and completed a real deployment without reporting an empty mod set.' -ForegroundColor Green
Write-Host 'This proves only direct REDmod deployment. It does not prove launcher enablement, relaunch persistence, or attended in-game behavior.' -ForegroundColor DarkGray
