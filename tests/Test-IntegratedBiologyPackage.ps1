$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'Test-IntegratedBiologyPackage.ps1 requires PowerShell 7 or newer.' }
. "$PSScriptRoot\..\tools\Common.ps1"

$project = Get-ProjectRoot
$package = Get-Content -Raw -LiteralPath (Join-Path $project 'manifest/redmod-package.json') | ConvertFrom-Json
$deps = Get-Content -Raw -LiteralPath (Join-Path $project 'manifest/dependency-graph.json') | ConvertFrom-Json
$install = Get-Content -Raw -LiteralPath (Join-Path $project 'manifest/redmod-install-contract.json') | ConvertFrom-Json
$settings = Get-Content -Raw -LiteralPath (Join-Path $project 'src/redscript/CyberpunkRealism/RealpassSettings.reds')
$preferenceUi = Get-Content -Raw -LiteralPath (Join-Path $project 'src/redscript/CyberpunkRealism/BiologyPreferencesNative.reds')
$builderPath = Join-Path $project 'tools/Build-BiologyPackage.ps1'
$deployPath = Join-Path $project 'tools/Deploy-BiologyRedmod.ps1'
$docPath = Join-Path $project 'docs/REDMOD-INTEGRATED-ASSEMBLY.md'
foreach ($path in @($builderPath,$deployPath,$docPath)) { if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Missing integrated package asset: $path" } }
$builder = Get-Content -Raw -LiteralPath $builderPath
$deploy = Get-Content -Raw -LiteralPath $deployPath
$doc = Get-Content -Raw -LiteralPath $docPath

$script:checks = 0
function Check($condition,[string]$message) { if (-not $condition) { throw $message }; $script:checks++ }

Check ($package.schemaVersion -eq 2) 'Integrated REDmod package schema drifted.'
Check ($package.status -eq 'playable-integrated-candidate') 'Package lost playable integrated candidate status.'
Check ($package.canonicalBuilder -eq 'tools/Build-BiologyPackage.ps1') 'Canonical builder is not Build-BiologyPackage.ps1.'
Check ($package.exactCompileRequiredBeforeArtifact -eq $true) 'Exact compilation is not a package-emission requirement.'
Check ($package.redmod.packageRoot -eq 'mods/Biology') 'Official REDmod identity is not mods/Biology.'
Check ($package.redmod.deployHelper -eq 'tools/Deploy-BiologyRedmod.ps1') 'Package contract does not use fail-closed deploy helper.'
Check ($package.redmod.observedSupportedInstall.biologyRecognitionProven -eq $true -and $package.redmod.observedSupportedInstall.biologyFiveStageDeploymentProven -eq $true) 'Accepted REDmod recognition/deployment evidence is missing.'
Check ($package.redmod.launcherActivationMarker -eq 'Items.BiologyLauncherActivationMarker.stackable') 'Package contract lost launcher activation marker.'
Check ($package.generatedMetadata.playerUninstaller -eq 'Uninstall Biology.exe') 'Package contract lost player-uninstaller metadata.'
$runtimeEntry = @($package.firstPartyFiles | Where-Object { $_.component -eq 'biology-owned-runtime' })
Check ($runtimeEntry.Count -eq 1 -and $runtimeEntry[0].destinationRoot -eq 'r6/scripts/CyberpunkRealism' -and $runtimeEntry[0].route -eq 'REDSCRIPT-BETTER') 'Package contract lost Biology-owned REDscript route.'

Check ($builder.Contains('Build-OwnedRuntimeProfile.ps1')) 'Integrated builder bypasses exact-compiled owned runtime profile.'
Check ($builder -match 'reports[\\/]compile-') 'Integrated builder does not consume exact compile report.'
Check ($builder.Contains('$compileReport.passed -ne $true') -and $builder.Contains('$compileReport.exitCode -ne 0') -and $builder.Contains('$compileReport.outputPresent -ne $true')) 'Integrated builder does not fail closed on exact compile.'
Check ($builder -match '\$gameVersion\s+-ne\s+''2\.31''') 'Integrated builder does not pin supported game version.'
Check ($builder.Contains("'mods/Biology/info.json'")) 'Integrated builder does not include official Biology REDmod metadata.'
Check ($builder.Contains('mods/Biology/tweaks/base/gameplay/static_data/database/items/weapons/parts/biology_activation.tweak')) 'Integrated builder does not package launcher activation marker.'
Check ($builder -match '\$expectedRetained\s*=\s*@\(''redscript''\)') 'Integrated builder retained dependency set is not exactly redscript.'
foreach ($retired in @('mod-settings','mod_settings','archivexl','red4ext')) { Check ($builder.ToLowerInvariant().Contains($retired)) "Integrated builder does not explicitly fail closed against retired component: $retired" }
foreach ($blocked in @('tweakxl','codeware','input-loader','darkfuture','project-e3')) { Check ($builder.ToLowerInvariant().Contains($blocked)) "Integrated builder does not explicitly reject/exclude $blocked." }
Check ($builder.Contains('biology/build-manifest.json') -and $builder.Contains('biology/provenance.json') -and $builder.Contains('BIOLOGY-VERSION.txt') -and $builder.Contains('SHA256SUMS.txt')) 'Integrated ownership/provenance metadata is incomplete.'
Check ($builder.Contains('Build-BiologyUninstaller.ps1') -and $builder.Contains('Uninstall Biology.exe')) 'Integrated package does not build/embed player uninstaller.'
Check ($builder.Contains("preferencePolicy = 'stored-in-save-never-target'")) 'Package ownership receipt does not preserve save-backed preference state.'
Check ($builder.Contains("removedDependencies = @('mod-settings','archivexl','red4ext'")) 'Package provenance does not record settings-stack removal.'
Check (-not $builder.Contains("$expectedRetained = @('redscript','red4ext'")) 'Retired dependency set remains expected by the playable builder.'

Check ($deploy -match 'tools\\redmod\\bin\\redMod\.exe') 'Deploy helper does not use official REDmod executable.'
Check ($deploy -match 'ProcessStartInfo|ArgumentList') 'Deploy helper does not control native argument boundaries.'
Check ($deploy -match 'No root specified' -and $deploy -match 'No mods found' -and $deploy -match 'Commandlet deploy has succeeded') 'Deploy helper lost fail-closed evidence checks.'

$dep = @{}
foreach ($entry in @($deps.dependencies)) { $dep[$entry.id] = $entry }
Check ($dep['redscript'].status -eq 'required-current-runtime' -and $dep['redscript'].bundledByBiology -eq $true) 'redscript is not recorded as direct retained runtime dependency.'
foreach ($retired in @('mod-settings','archivexl','red4ext')) { Check (-not $dep.ContainsKey($retired)) "$retired remains an active dependency." }
$removed = @($deps.removedDependencies | ForEach-Object { $_.id })
foreach ($retired in @('mod-settings','archivexl','red4ext')) { Check ($removed -contains $retired) "$retired removal is not documented in dependency graph." }
foreach ($id in @('tweakxl','codeware','input-loader')) { Check ($dep[$id].status -eq 'not-required' -and $dep[$id].bundledByBiology -eq $false) "$id unexpectedly survives integrated candidate." }
foreach ($id in @('darkfuture','project-e3-hud')) { Check ($dep[$id].status -eq 'blocked-runtime' -and $dep[$id].bundledByBiology -eq $false) "$id reference runtime became packageable." }

Check ($settings.Contains('public static func IsEnabled(game: GameInstance)')) 'Biology activation semantics lost shared accessor.'
Check ($settings.Contains('return CRRealpassSettings.IsLauncherActivated();')) 'Whole-mod activation is not solely REDlauncher-authorized.'
Check ($settings.Contains('public persistent let e3FirstPersonHudVisuals: Bool = true;')) 'E3 preference is not save-persistent.'
Check (-not ($settings -match '(?i)ModSettings|mod_settings|runtimeProperty|ModuleExists')) 'Production settings source still contains provider registration.'
Check ($preferenceUi.Contains('RipperDocGameController') -and $preferenceUi.Contains('ToggleE3FirstPersonHudVisuals')) 'Biology-owned E3 editor is missing.'

Check ($install.schemaVersion -eq 3) 'REDmod install contract is not current self-contained settings schema.'
Check (@($install.supplementalRuntime.retainedGenericComponents).Count -eq 1 -and $install.supplementalRuntime.retainedGenericComponents[0] -eq 'redscript') 'Install contract retained generic set is not exactly redscript.'
foreach ($retired in @('mod-settings','archivexl','red4ext')) { Check (@($install.supplementalRuntime.removedGenericComponents) -contains $retired) "Install contract does not record removed component: $retired" }
Check ($install.preferences.externalSettingsProvider -eq $false -and $install.preferences.pauseMenuRegistration -eq $false) 'Install contract still permits provider/pause-menu registration.'
Check (@($install.preferences.publicControls).Count -eq 1 -and $install.preferences.publicControls[0] -eq 'presentation.e3-first-person-hud-visuals') 'Install contract public preference count drifted.'
Check ($install.launcherActivation.publicMasterPreference -eq $false) 'Install contract still exposes redundant in-game master preference.'
Check ($install.ownerManifest.path -eq 'biology/build-manifest.json' -and $install.ownerManifest.schemaVersion -eq 2) 'Install contract lost exact owner manifest.'
Check ($install.playerUninstaller.binary -eq 'Uninstall Biology.exe') 'Install contract lost player uninstaller.'
Check ($install.launcherActivation.signal -eq 'Items.BiologyLauncherActivationMarker.stackable') 'Install contract lost launcher activation signal.'

Check ($doc -match 'Current generic dependencies') 'Integrated documentation no longer records current dependency disposition.'

Write-Host "PASS: $script:checks integrated Biology package checks; release runtime is redscript-only, settings are Biology-owned/save-backed, and retired provider DLLs are fail-closed from the artifact."
