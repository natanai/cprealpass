$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'Test-IntegratedBiologyPackage.ps1 requires PowerShell 7 or newer.' }
. "$PSScriptRoot\..\tools\Common.ps1"

$project = Get-ProjectRoot
$package = Get-Content -Raw -LiteralPath (Join-Path $project 'manifest/redmod-package.json') | ConvertFrom-Json
$deps = Get-Content -Raw -LiteralPath (Join-Path $project 'manifest/dependency-graph.json') | ConvertFrom-Json
$install = Get-Content -Raw -LiteralPath (Join-Path $project 'manifest/redmod-install-contract.json') | ConvertFrom-Json
$settings = Get-Content -Raw -LiteralPath (Join-Path $project 'src/redscript/CyberpunkRealism/RealpassSettings.reds')
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
Check ($package.redmod.deployHelper -eq 'tools/Deploy-BiologyRedmod.ps1') 'Package contract does not use the fail-closed deploy helper.'
Check ($package.redmod.deployCommandPolicy -match '(?i)false positives|exit code 0') 'Package contract forgot the attended REDmod false-positive lesson.'
Check ($package.redmod.observedSupportedInstall.biologyRecognitionProven -eq $true) 'Accepted Biology REDmod recognition is not represented.'
Check ($package.redmod.observedSupportedInstall.biologyFiveStageDeploymentProven -eq $true) 'Accepted five-stage REDmod deployment is not represented.'
Check ($package.redmod.launcherActivationMarker -eq 'Items.BiologyLauncherActivationMarker.stackable') 'Package contract lost the REDmod-owned launcher activation marker.'
Check ($package.generatedMetadata.playerUninstaller -eq 'Uninstall Biology.exe') 'Package contract lost player-uninstaller metadata.'
$runtimeEntry = @($package.firstPartyFiles | Where-Object { $_.component -eq 'biology-owned-runtime' })
Check ($runtimeEntry.Count -eq 1 -and $runtimeEntry[0].destinationRoot -eq 'r6/scripts/CyberpunkRealism' -and $runtimeEntry[0].route -eq 'REDSCRIPT-BETTER') 'Package contract lost Biology-owned supplemental REDscript destination/route.'
$activationEntry = @($package.firstPartyFiles | Where-Object { $_.component -eq 'biology-launcher-activation' })
Check ($activationEntry.Count -eq 1 -and $activationEntry[0].destination -match 'mods/Biology/tweaks/.+biology_activation\.tweak') 'Package contract lost Biology launcher activation tweak payload.'

Check ($builder.Contains('Build-OwnedRuntimeProfile.ps1')) 'Integrated builder bypasses exact-compiled owned runtime profile.'
Check ($builder -match 'reports[\\/]compile-') 'Integrated builder does not consume exact compile report.'
Check ($builder.Contains('$compileReport.passed -ne $true')) 'Integrated builder does not fail closed on compile result.'
Check ($builder.Contains('$compileReport.exitCode -ne 0')) 'Integrated builder does not require compiler exit code zero.'
Check ($builder.Contains('$compileReport.outputPresent -ne $true')) 'Integrated builder does not require compiler output.'
Check ($builder -match '\$gameVersion\s+-ne\s+''2\.31''') 'Integrated builder does not pin the supported game version.'
Check ($builder.Contains("'mods/Biology/info.json'")) 'Integrated builder does not include official Biology REDmod metadata.'
Check ($builder.Contains('mods/Biology/tweaks/base/gameplay/static_data/database/items/weapons/parts/biology_activation.tweak')) 'Integrated builder does not package the launcher activation marker.'
Check ($builder -match '\$expectedRetained\s*=\s*@\(''redscript'',''red4ext'',''archivexl'',''mod-settings''\)') 'Integrated builder retained dependency set is not exact/fail-closed.'
foreach ($blocked in @('tweakxl','codeware','input-loader','darkfuture','project-e3')) {
    Check ($builder.ToLowerInvariant().Contains($blocked)) "Integrated builder does not explicitly reject/exclude $blocked."
}
Check ($builder.Contains('biology/build-manifest.json')) 'Integrated owner manifest is not generated.'
Check ($builder.Contains('biology/provenance.json')) 'Integrated provenance is not generated.'
Check ($builder.Contains('BIOLOGY-VERSION.txt')) 'Integrated Biology version marker is missing.'
Check ($builder.Contains('SHA256SUMS.txt')) 'Integrated checksums are missing.'
Check ($builder.Contains('playableRuntimeIncluded = $true')) 'Integrated artifact does not declare playable runtime inclusion.'
Check ($builder.Contains('sourceModsRequired = @()')) 'Integrated artifact does not reject source-mod runtime requirements.'
Check ($builder.Contains('Build-BiologyUninstaller.ps1') -and $builder.Contains('Uninstall Biology.exe')) 'Integrated package does not build/embed the player uninstaller.'
Check ($builder.Contains('generic-dependency-shared')) 'Integrated package does not distinguish shared generic dependencies at uninstall time.'
Check (-not $builder.Contains('Build-RedmodFoundation.ps1')) 'Playable builder delegates to non-playable foundation skeleton.'

Check ($deploy -match 'tools\\redmod\\bin\\redMod\.exe') 'Deploy helper does not use the official REDmod executable.'
Check ($deploy -match 'ProcessStartInfo|ArgumentList') 'Deploy helper does not control native argument boundaries.'
Check ($deploy -match 'No root specified') 'Deploy helper no longer rejects ignored-root false positives.'
Check ($deploy -match 'No mods found') 'Deploy helper no longer rejects empty-mod-set false positives.'
Check ($deploy -match 'Commandlet deploy has succeeded') 'Deploy helper no longer requires positive deploy evidence.'
Check ($deploy.Contains("FileVersion -ne '2.3.1.0'")) 'Deploy helper does not guard REDmod file version.'
Check ($deploy.Contains("ProductVersion -ne '2.31'")) 'Deploy helper does not guard REDmod product version.'

$dep = @{}
foreach ($entry in @($deps.dependencies)) { $dep[$entry.id] = $entry }
Check ($dep['redscript'].status -eq 'required-current-runtime' -and $dep['redscript'].bundledByBiology -eq $true) 'redscript is not recorded as direct retained runtime dependency.'
Check ($dep['mod-settings'].status -eq 'temporary-retained-blocker' -and $dep['mod-settings'].bundledByBiology -eq $true) 'Mod Settings temporary provider is not explicit.'
Check ($dep['mod-settings'].plannedAction -notmatch '(?i)Lane C') 'Settings-provider removal still references merged Lane C ownership.'
Check ($dep['mod-settings'].currentOwnerIssue -match '#44|#40') 'Settings/activation dependency is not routed to current issues.'
foreach ($id in @('archivexl','red4ext')) {
    Check ($dep[$id].status -eq 'temporary-transitive' -and $dep[$id].bundledByBiology -eq $true) "$id is not temporary transitive settings plumbing."
}
foreach ($id in @('tweakxl','codeware','input-loader')) {
    Check ($dep[$id].status -eq 'not-required' -and $dep[$id].bundledByBiology -eq $false) "$id unexpectedly survives the integrated candidate."
}
foreach ($id in @('darkfuture','project-e3-hud')) {
    Check ($dep[$id].status -eq 'blocked-runtime' -and $dep[$id].bundledByBiology -eq $false) "$id reference runtime became packageable."
}

Check ($settings.Contains('public static func IsEnabled(game: GameInstance)')) 'Biology master semantics are not provider-neutral.'
Check ($settings.Contains('public static func IsLauncherActivated()')) 'Biology settings semantics lost launcher activation boundary.'
Check ($settings.Contains('Items.BiologyLauncherActivationMarker.stackable')) 'Settings accessor does not read REDmod-owned activation marker.'
Check ($settings.Contains('public static func UseE3FirstPersonHudVisuals(game: GameInstance)')) 'E3 presentation semantics are not provider-neutral.'
Check ($settings.Contains('@if(ModuleExists("ModSettingsModule"))')) 'Current optional settings adapter is not guarded.'
Check ($doc -match 'Current generic dependencies') 'Integrated documentation no longer records current dependency disposition.'
Check ($doc -match 'Issue #44' -and $doc -match 'Issue #40') 'Integrated documentation is not routed to current follow-up ownership.'
Check ($doc -notmatch '(?i)exact Lane C settings-provider blocker') 'Integrated documentation still frames settings removal through merged lane language.'
Check ($doc -match 'first.*REDmod structural milestone.*already|first integrated REDmod milestone') 'Integrated documentation still acts as though the first structural milestone has not happened.'

Check ($install.ownerManifest.path -eq 'biology/build-manifest.json') 'Install contract lost exact owner manifest.'
Check ($install.ownerManifest.schemaVersion -eq 2) 'Install contract owner receipt is not schema 2.'
Check ($install.playerUninstaller.binary -eq 'Uninstall Biology.exe') 'Install contract lost player uninstaller.'
Check ($install.launcherActivation.signal -eq 'Items.BiologyLauncherActivationMarker.stackable') 'Install contract lost launcher activation signal.'
foreach ($root in @('bin','archive','engine','mods','r6','red4ext')) {
    Check (@($install.neverRecursivelyOwnedRoots) -contains $root) "Install contract permits recursive ownership of shared root $root."
}
Check ($install.redmodCli.biologyRecognitionProven -eq $true -and $install.redmodCli.fiveStageDeploymentProven -eq $true) 'Install contract forgot accepted REDmod deploy evidence.'
Check ($install.remainingDirectGameGates -notcontains 'Biology REDmod recognition/deployment') 'Already accepted recognition/deployment remains listed as an open gate.'
Check (@($install.remainingDirectGameGates).Count -ge 5) 'Genuinely open direct-game gates were collapsed into source/CI assumptions.'

Write-Host "PASS: $script:checks integrated Biology package checks; canonical package/deploy contracts preserve accepted REDmod evidence while adding launcher-fail-closed activation, self-contained uninstall, shared-dependency safety, and current follow-up ownership."
