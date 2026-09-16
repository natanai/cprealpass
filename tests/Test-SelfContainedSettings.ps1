$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\tools\Common.ps1"
$project = Get-ProjectRoot

$settingsPath = Join-Path $project 'src\redscript\CyberpunkRealism\RealpassSettings.reds'
$uiPath = Join-Path $project 'src\redscript\CyberpunkRealism\BiologyPreferencesNative.reds'
$builderPath = Join-Path $project 'tools\Build-BiologyPackage.ps1'
$runtimeBuilderPath = Join-Path $project 'tools\Build-OwnedRuntimeProfile.ps1'
$corePath = Join-Path $project 'src\uninstaller\BiologyUninstallCore.cs'
$programPath = Join-Path $project 'src\uninstaller\BiologyUninstallerProgram.cs'
foreach ($path in @($settingsPath,$uiPath,$builderPath,$runtimeBuilderPath,$corePath,$programPath)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Missing self-contained settings asset: $path" }
}

$settingsSource = Get-Content -Raw -LiteralPath $settingsPath
$uiSource = Get-Content -Raw -LiteralPath $uiPath
$builder = Get-Content -Raw -LiteralPath $builderPath
$runtimeBuilder = Get-Content -Raw -LiteralPath $runtimeBuilderPath
$core = Get-Content -Raw -LiteralPath $corePath
$program = Get-Content -Raw -LiteralPath $programPath
$contract = Get-Content -Raw -LiteralPath (Join-Path $project 'manifest\settings.json') | ConvertFrom-Json
$distribution = Get-Content -Raw -LiteralPath (Join-Path $project 'manifest\distribution.json') | ConvertFrom-Json
$deps = Get-Content -Raw -LiteralPath (Join-Path $project 'manifest\dependency-graph.json') | ConvertFrom-Json
$profiles = Get-Content -Raw -LiteralPath (Join-Path $project 'manifest\profiles.json') | ConvertFrom-Json
$install = Get-Content -Raw -LiteralPath (Join-Path $project 'manifest\redmod-install-contract.json') | ConvertFrom-Json

$productionProviderText = $settingsSource + "`n" + $uiSource + "`n" + $core + "`n" + $program
foreach ($needle in @('ModSettings','mod_settings','red4ext/plugins/mod_settings/user.ini','BiologyPreferenceCleaner','runtimeProperty("ModSettings.')) {
    if ($productionProviderText -match [regex]::Escape($needle)) { throw "Production provider residue remains: $needle" }
}
if ($settingsSource -notmatch 'public\s+persistent\s+let\s+e3FirstPersonHudVisuals\s*:\s*Bool\s*=\s*true') { throw 'E3 preference is not read from Biology save-backed persistence authority.' }
if ($settingsSource -notmatch 'return\s+CRRealpassSettings\.IsLauncherActivated\(\);') { throw 'REDlauncher activation boundary is not separate from E3 persistence.' }
if ($uiSource -notmatch 'RipperDocGameController' -or $uiSource -notmatch 'ToggleE3FirstPersonHudVisuals') { throw 'Biology-owned UI cannot edit E3 preference.' }

$controls = @($contract.publicControls)
if ($controls.Count -gt 2 -or $controls.Count -ne 1 -or $controls[0].id -ne 'presentation.e3-first-person-hud-visuals') { throw 'Public preference count exceeds or differs from the canonical one-control surface.' }
if ($contract.surface.publicMasterEnable -ne $false) { throw 'Redundant in-game Biology master switch returned.' }
if ($contract.numericPublicBalanceControlsAllowed -ne $false) { throw 'Public numeric/balance settings returned.' }

$activeDeps = @($deps.dependencies | ForEach-Object { $_.id })
$removedDeps = @($deps.removedDependencies | ForEach-Object { $_.id })
$distributionIds = @($distribution.components | ForEach-Object { $_.id })
foreach ($retired in @('mod-settings','archivexl','red4ext')) {
    if ($activeDeps -contains $retired) { throw "Retired dependency remains active: $retired" }
    if ($distributionIds -contains $retired) { throw "Retired dependency remains distributable: $retired" }
    if ($removedDeps -notcontains $retired) { throw "Retired dependency is not recorded as removed: $retired" }
    if (@($install.supplementalRuntime.retainedGenericComponents) -contains $retired) { throw "Retired dependency remains in install contract: $retired" }
}
if (@($install.supplementalRuntime.retainedGenericComponents).Count -ne 1 -or $install.supplementalRuntime.retainedGenericComponents[0] -ne 'redscript') { throw 'Surviving generic dependency inventory is not exactly redscript.' }
if (@($profiles.profiles.'biology-runtime').Count -ne 1 -or $profiles.profiles.'biology-runtime'[0] -ne 'redscript') { throw 'Production staging profile is not exactly redscript.' }
if ($runtimeBuilder -notmatch '\$genericIds\s*=\s*@\(''redscript''\)') { throw 'Production dependency acquisition is not constrained to redscript.' }
if ($builder -notmatch '\$expectedRetained\s*=\s*@\(''redscript''\)') { throw 'Package builder is not constrained to redscript.' }
foreach ($retired in @('mod-settings','mod_settings','archivexl','red4ext')) {
    if ($builder.ToLowerInvariant() -notmatch [regex]::Escape($retired)) { throw "Package builder does not fail closed against retired dependency: $retired" }
}

if ($install.preferences.externalSettingsProvider -ne $false -or $install.preferences.pauseMenuRegistration -ne $false) { throw 'Stale external settings provider/menu registration is still permitted.' }
if ($settingsSource -match '(?i)Project E3|Dark Future' -or $uiSource -match '(?i)Project E3|Dark Future') { throw 'Reference-mod runtime returned through settings implementation.' }

Write-Host 'PASS: Biology settings are self-contained, one-control, save-backed, launcher-separated, provider-row-free, and the release dependency set is redscript-only.'
