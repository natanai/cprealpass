param(
    [string]$GameRoot = 'C:\Games\Steam\steamapps\common\Cyberpunk 2077',
    [string]$SteamRoot = 'C:\Games\Steam',
    [Parameter(Mandatory=$true)][ValidatePattern('^[0-9]+$')][string]$SteamUserDataId,
    [string]$SaveRoot = (Join-Path $env:USERPROFILE 'Saved Games\CD Projekt Red\Cyberpunk 2077'),
    [string]$OutputPath
)

. "$PSScriptRoot\Common.ps1"
$GameRoot = Assert-GameRoot $GameRoot
$project = Get-ProjectRoot
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
if (-not $OutputPath) { $OutputPath = Join-Path $project 'manifest\baseline.json' }
if (Test-Path -LiteralPath $OutputPath) { throw 'Baseline already exists. Use -OutputPath for a separate snapshot; preserve the original baseline.' }
$exe = Join-Path $GameRoot 'bin\x64\Cyberpunk2077.exe'
$redmodExe = Join-Path $GameRoot 'tools\redmod\bin\redMod.exe'
$appManifest = Join-Path $SteamRoot 'steamapps\appmanifest_1091500.acf'
$localConfig = Join-Path $SteamRoot "userdata\$SteamUserDataId\config\localconfig.vdf"

$appText = if (Test-Path -LiteralPath $appManifest) { Get-Content -Raw -LiteralPath $appManifest } else { '' }
$buildId = if ($appText -match '"buildid"\s+"([^"]+)"') { $Matches[1] } else { $null }
$plInstalled = $appText -match '"2138330"'
$launchOptionsPresent = if (Test-Path -LiteralPath $localConfig) {
    [bool](Select-String -LiteralPath $localConfig -SimpleMatch -Pattern 'LaunchOptions' -Quiet)
} else { $null }

$surfaces = foreach ($rel in @('archive\pc\mod','bin\x64\plugins','r6\scripts','r6\tweaks','red4ext','mods')) {
    $path = Join-Path $GameRoot $rel
    $exists = Test-Path -LiteralPath $path
    [ordered]@{
        path = $rel
        exists = $exists
        files = @(if ($exists) { Get-ChildItem -File -Force -Recurse -LiteralPath $path | ForEach-Object { $_.FullName.Substring($GameRoot.Length + 1) } })
    }
}

$saveInventory = if (Test-Path -LiteralPath $SaveRoot) {
    @(Get-ChildItem -Force -LiteralPath $SaveRoot | ForEach-Object {
        [ordered]@{ name = $_.Name; isDirectory = $_.PSIsContainer; lastWriteTimeUtc = $_.LastWriteTimeUtc.ToString('o'); length = if ($_.PSIsContainer) { $null } else { $_.Length } }
    })
} else { @() }

$critical = @($exe, $redmodExe, (Join-Path $GameRoot 'launcher-configuration.json')) | Where-Object { Test-Path -LiteralPath $_ } | ForEach-Object {
    [ordered]@{ path = $_.Substring($GameRoot.Length + 1); length = (Get-Item -LiteralPath $_).Length; sha256 = Get-Sha256 $_ }
}

$cpuName = try { (Get-ItemProperty -LiteralPath 'HKLM:\HARDWARE\DESCRIPTION\System\CentralProcessor\0').ProcessorNameString.Trim() } catch { $null }
$gpuInfo = try {
    $nvidiaSmi = Get-Command nvidia-smi.exe -ErrorAction Stop
    (& $nvidiaSmi.Source --query-gpu=name,memory.total,driver_version --format=csv,noheader 2>$null) -join '; '
} catch { $null }

$baseline = [ordered]@{
    schemaVersion = 1
    capturedAtUtc = (Get-Date).ToUniversalTime().ToString('o')
    gameRoot = $GameRoot
    steamRoot = (Resolve-Path -LiteralPath $SteamRoot).Path
    gameVersion = (Get-Item -LiteralPath $exe).VersionInfo.ProductVersion
    fileVersion = (Get-Item -LiteralPath $exe).VersionInfo.FileVersion
    steamBuildId = $buildId
    phantomLibertyDepot2138330Installed = $plInstalled
    redmodPresent = (Test-Path -LiteralPath $redmodExe)
    redmodVersion = if (Test-Path -LiteralPath $redmodExe) { (Get-Item -LiteralPath $redmodExe).VersionInfo.ProductVersion } else { $null }
    steamLaunchOptionsPresent = $launchOptionsPresent
    host = [ordered]@{ cpu = $cpuName; gpu = $gpuInfo }
    modSurfaces = @($surfaces)
    criticalFiles = @($critical)
    saves = [ordered]@{ root = $SaveRoot; topLevelEntryCount = @($saveInventory).Count; entries = @($saveInventory) }
}

`$baselinePath = $OutputPath
Write-JsonFile $baseline $baselinePath

$fileInventory = Get-ChildItem -File -Force -Recurse -LiteralPath $GameRoot | ForEach-Object {
    [ordered]@{ path = $_.FullName.Substring($GameRoot.Length + 1); length = $_.Length; lastWriteTimeUtc = $_.LastWriteTimeUtc.ToString('o') }
}
$inventoryPath = Join-Path $project "reports\game-files-$stamp.json"
Write-JsonFile ([ordered]@{ capturedAtUtc = $baseline.capturedAtUtc; gameRoot = $GameRoot; files = @($fileInventory) }) $inventoryPath

Write-Host "Baseline: $baselinePath"
Write-Host "File inventory: $inventoryPath"
