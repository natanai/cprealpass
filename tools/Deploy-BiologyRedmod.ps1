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

Write-Host "Deploying installed REDmods with explicit root: $game"
& $redmod 'deploy' ("-root=$game")
$code = $LASTEXITCODE
if ($code -ne 0) { throw "REDmod deploy failed with exit code $code." }
Write-Host 'PASS: REDmod deploy command completed. This is deployment evidence only; it does not prove launcher enablement, relaunch persistence, or attended in-game behavior.' -ForegroundColor Green
