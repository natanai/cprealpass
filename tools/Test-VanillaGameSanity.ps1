[CmdletBinding()]
param(
    [string]$GameRoot = 'C:\Games\Steam\steamapps\common\Cyberpunk 2077'
)

$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'Test-VanillaGameSanity.ps1 requires PowerShell 7 or newer.' }
. "$PSScriptRoot\Common.ps1"

$game = Assert-GameRoot $GameRoot
Assert-GameStopped

$exe = Get-Item -LiteralPath (Join-Path $game 'bin\x64\Cyberpunk2077.exe')
if ($exe.VersionInfo.ProductVersion -ne '2.31') {
    throw "Biology currently supports Cyberpunk 2077 2.31; installed game reports $($exe.VersionInfo.ProductVersion)."
}

$redmod = Join-Path $game 'tools\redmod\bin\redMod.exe'
if (-not (Test-Path -LiteralPath $redmod -PathType Leaf)) {
    throw "Official REDmod executable is missing: $redmod"
}
$redmodVersion = (Get-Item -LiteralPath $redmod).VersionInfo
if ($redmodVersion.FileVersion -ne '2.3.1.0' -or $redmodVersion.ProductVersion -ne '2.31') {
    throw "Expected REDmod file 2.3.1.0 / product 2.31; installed tool reports $($redmodVersion.FileVersion) / $($redmodVersion.ProductVersion)."
}

$forbiddenRoots = @(
    'archive\pc\mod',
    'red4ext',
    'bin\x64\plugins\cyber_engine_tweaks',
    'r6\scripts'
)
$findings = [Collections.Generic.List[string]]::new()
foreach ($relative in $forbiddenRoots) {
    $path = Join-Path $game $relative
    if (Test-Path -LiteralPath $path) {
        $files = @(Get-ChildItem -LiteralPath $path -File -Recurse -Force -ErrorAction SilentlyContinue)
        if ($files.Count -gt 0) { $findings.Add("$relative ($($files.Count) file(s))") }
    }
}

$modsRoot = Join-Path $game 'mods'
if (Test-Path -LiteralPath $modsRoot) {
    foreach ($file in @(Get-ChildItem -LiteralPath $modsRoot -File -Recurse -Force -ErrorAction SilentlyContinue)) {
        $relativeToMods = [IO.Path]::GetRelativePath($modsRoot,$file.FullName).Replace('\','/')
        $isVanillaStub = $relativeToMods -eq '.stub' -and $file.Length -eq 0
        if (-not $isVanillaStub) { $findings.Add("mods/$relativeToMods ($($file.Length) byte(s))") }
    }
}

if ($findings.Count -gt 0) {
    throw "Fast vanilla sanity check found mod-shaped payload:`n$($findings -join "`n")"
}

Write-Host ''
Write-Host 'PASS: fast vanilla sanity check.' -ForegroundColor Green
Write-Host "Game version : $($exe.VersionInfo.ProductVersion)"
Write-Host "REDmod       : $($redmodVersion.FileVersion) / $($redmodVersion.ProductVersion)"
Write-Host 'Mod surfaces : no payload found in known loose-mod roots; mods contains only the vanilla .stub if present.'
Write-Host 'NOTE: this is deliberately not a full-file/hash proof against the tracked vanilla baseline.' -ForegroundColor Yellow
return $true
