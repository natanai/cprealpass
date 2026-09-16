$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'Test-RedmodFoundation.ps1 requires PowerShell 7 or newer.' }
. "$PSScriptRoot\..\tools\Common.ps1"

$project = Get-ProjectRoot
function ReadJson([string]$relative) {
    $path = Join-Path $project $relative
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Missing REDmod contract: $relative" }
    Get-Content -Raw -LiteralPath $path | ConvertFrom-Json
}
function ReadText([string]$relative) {
    $path = Join-Path $project $relative
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Missing REDmod evidence/doc: $relative" }
    Get-Content -Raw -LiteralPath $path
}

$package = ReadJson 'manifest/redmod-package.json'
$dependencies = ReadJson 'manifest/dependency-graph.json'
$classifications = ReadJson 'manifest/redmod-classification.json'
$install = ReadJson 'manifest/redmod-install-contract.json'
$info = ReadJson 'mods/Biology/info.json'
$toolProbe = ReadText 'docs/evidence/REDMOD-2.31-PROBE-2026-09-15.md'
$deployEvidence = ReadText 'docs/test-runs/2026-09-15-8cf04566-redmod-deploy-preflight.md'
$assembly = ReadText 'docs/REDMOD-INTEGRATED-ASSEMBLY.md'
$deployHelper = ReadText 'tools/Deploy-BiologyRedmod.ps1'

if ($package.schemaVersion -ne 2 -or $package.product -ne 'Biology' -or $package.packageId -ne 'Biology') { throw 'Unexpected Biology REDmod package contract.' }
if ($package.supportedGameVersion -ne '2.31' -or $package.status -ne 'playable-integrated-candidate') { throw 'Integrated candidate/game support status drifted.' }
if ($package.canonicalBuilder -ne 'tools/Build-BiologyPackage.ps1' -or $package.exactCompileRequiredBeforeArtifact -ne $true) { throw 'Canonical build/exact-compile gate drifted.' }
if ($package.redmod.packageRoot -ne 'mods/Biology' -or $package.redmod.metadata -ne 'mods/Biology/info.json') { throw 'Biology REDmod identity drifted.' }
if ($package.redmod.deployHelper -ne 'tools/Deploy-BiologyRedmod.ps1') { throw 'Package contract bypasses the fail-closed deploy helper.' }
if ($package.redmod.observedSupportedInstall.fileVersion -ne '2.3.1.0' -or $package.redmod.observedSupportedInstall.productVersion -ne '2.31') { throw 'Supported REDmod tool evidence drifted.' }
if ($package.redmod.observedSupportedInstall.biologyRecognitionProven -ne $true -or $package.redmod.observedSupportedInstall.biologyFiveStageDeploymentProven -ne $true) { throw 'Already-accepted Biology recognition/deployment was regressed to an open gate.' }
if ($info.name -ne 'Biology') { throw 'mods/Biology/info.json lost Biology identity.' }

if ($toolProbe -notmatch '2\.3\.1\.0' -or $toolProbe -notmatch '2\.31') { throw 'Direct REDmod tool probe no longer supports the recorded package contract.' }
if ($deployEvidence -notmatch '(?i)Found mod\s+"Biology"' -or $deployEvidence -notmatch '(?i)\[DEPLOY\].*5/5|Stage 5/5|all five' -or $deployEvidence -notmatch '(?i)Commandlet deploy has succeeded') {
    throw 'Attended deployment record no longer contains Biology discovery, five-stage deploy, and successful completion evidence.'
}

foreach ($required in @('ProcessStartInfo','ArgumentList','No root specified','No mods found','Commandlet deploy has succeeded')) {
    if ($deployHelper -notmatch [regex]::Escape($required)) { throw "Fail-closed deploy helper lost required behavior/evidence check: $required" }
}

$depById = @{}
foreach ($dep in @($dependencies.dependencies)) {
    if ([string]::IsNullOrWhiteSpace([string]$dep.id) -or $depById.ContainsKey([string]$dep.id)) { throw "Invalid/duplicate dependency id: $($dep.id)" }
    $depById[[string]$dep.id] = $dep
}
foreach ($id in @('redmod','redscript','tweakxl','codeware','input-loader','darkfuture','project-e3-hud','cyberpunk-game-files')) {
    if (-not $depById.ContainsKey($id)) { throw "Dependency graph missing: $id" }
}
foreach ($retired in @('mod-settings','archivexl','red4ext')) {
    if ($depById.ContainsKey($retired)) { throw "Retired settings dependency remains active in dependency graph: $retired" }
}
$removedById = @{}
foreach ($dep in @($dependencies.removedDependencies)) { $removedById[[string]$dep.id] = $dep }
foreach ($retired in @('mod-settings','archivexl','red4ext')) {
    if (-not $removedById.ContainsKey($retired) -or $removedById[$retired].removedByIssue -ne 61) { throw "Dependency removal is not recorded for issue #61: $retired" }
}
if ($depById['redmod'].status -ne 'required-platform' -or $depById['redmod'].bundledByBiology -ne $false) { throw 'Official REDmod platform authority drifted.' }
if ($depById['redscript'].status -ne 'required-current-runtime' -or $depById['redscript'].route -ne 'REDSCRIPT-BETTER' -or $depById['redscript'].bundledByBiology -ne $true) { throw 'redscript direct runtime rationale drifted.' }
if ((@($depById['redscript'].consumerFeatures) -join ' ') -notmatch '(?i)ScriptableSystem|preference') { throw 'redscript dependency inventory lost its self-contained settings consumer.' }
foreach ($id in @('tweakxl','codeware','input-loader')) {
    if ($depById[$id].status -ne 'not-required' -or $depById[$id].bundledByBiology -ne $false) { throw "Unneeded framework appears required: $id" }
}
foreach ($id in @('darkfuture','project-e3-hud')) {
    if ($depById[$id].status -ne 'blocked-runtime' -or $depById[$id].bundledByBiology -ne $false) { throw "Reference mod became executable/bundleable: $id" }
}

if ($classifications.schemaVersion -ne 3) { throw 'REDmod classification schema is not current after settings migration.' }
$allowed = @($classifications.allowedClassifications)
foreach ($required in @('REDMOD-NATIVE','REDMOD-POSSIBLE-BUT-BRITTLE','REDSCRIPT-BETTER','REQUIRES-NATIVE-EXTENSION','REMOVE/RETHINK','UNKNOWN — NEEDS DIRECT GAME PROBE')) {
    if ($allowed -notcontains $required) { throw "Required routing classification missing: $required" }
}
$classById = @{}
foreach ($entry in @($classifications.entries)) { $classById[[string]$entry.id] = $entry }
foreach ($id in @('integrated-biology-player-package','current-native-hook-seams','biology-owned-settings-persistence-ui','settings-provider-accessibility-blocker','mod-settings-framework','archivexl-framework','red4ext-framework','official-redmod-cli-on-supported-2.31-install','biology-redmod-recognition-on-supported-2.31-install','redmod-conflict-precedence-on-supported-2.31-install')) {
    if (-not $classById.ContainsKey($id)) { throw "Classification coverage missing: $id" }
}
if ($classById['integrated-biology-player-package'].classification -ne 'REDMOD-NATIVE') { throw 'Integrated package lost REDmod-first classification.' }
if ($classById['current-native-hook-seams'].classification -ne 'REDSCRIPT-BETTER') { throw 'Narrow current hook seams lost their routing rationale.' }
if ($classById['biology-owned-settings-persistence-ui'].classification -ne 'REDSCRIPT-BETTER' -or $classById['biology-owned-settings-persistence-ui'].reason -notmatch '(?i)save-backed') { throw 'Self-contained settings route is not classified as the narrow Biology-owned redscript seam.' }
foreach ($retired in @('mod-settings-framework','archivexl-framework','red4ext-framework')) {
    if ($classById[$retired].classification -ne 'REMOVE/RETHINK' -or $classById[$retired].reason -notmatch '(?i)Removed from production') { throw "Retired framework classification is stale: $retired" }
}
if ($classById['biology-redmod-recognition-on-supported-2.31-install'].classification -ne 'REDMOD-NATIVE' -or $classById['biology-redmod-recognition-on-supported-2.31-install'].evidence -notmatch 'docs/test-runs/') { throw 'Accepted Biology recognition/deployment is not tied to attended evidence.' }
if ($classById['redmod-conflict-precedence-on-supported-2.31-install'].classification -ne 'UNKNOWN — NEEDS DIRECT GAME PROBE') { throw 'Overlap precedence was claimed without accepted fixture evidence.' }

if ($install.schemaVersion -ne 3 -or $install.product -ne 'Biology' -or $install.officialPackageRoot -ne 'mods/Biology') { throw 'Unexpected current REDmod install contract.' }
if ($install.redmodCli.biologyRecognitionProven -ne $true -or $install.redmodCli.fiveStageDeploymentProven -ne $true) { throw 'Install contract forgot accepted deploy evidence.' }
if ($install.playerFlow.disable -notmatch '(?i)Enable mods OFF' -or $install.playerFlow.uninstall -notmatch 'Uninstall Biology\.exe') { throw 'Current launcher-off/hard-uninstall targets are missing.' }
if ($install.launcherActivation.publicMasterPreference -ne $false) { throw 'Install contract reintroduced redundant in-game whole-mod activation.' }
if ($install.preferences.externalSettingsProvider -ne $false -or $install.preferences.pauseMenuRegistration -ne $false) { throw 'Install contract still permits the retired settings provider/menu row.' }
if (@($install.supplementalRuntime.retainedGenericComponents).Count -ne 1 -or $install.supplementalRuntime.retainedGenericComponents[0] -ne 'redscript') { throw 'Install contract generic runtime is not redscript-only.' }
foreach ($retired in @('mod-settings','archivexl','red4ext')) {
    if (@($install.supplementalRuntime.removedGenericComponents) -notcontains $retired) { throw "Install contract does not record retired component: $retired" }
}
foreach ($root in @('bin','archive','engine','mods','r6','red4ext')) {
    if (@($install.neverRecursivelyOwnedRoots) -notcontains $root) { throw "Shared-root deletion protection missing: $root" }
}
if ($install.cleanRoom.firstIntegratedRedmodMilestoneCompleted -ne $true -or $install.cleanRoom.fullSteamReinstallIsNormalUninstall -ne $false) { throw 'Clean-room state is stale.' }
if (@($install.remainingDirectGameGates) -contains 'Biology REDmod recognition/deployment') { throw 'Already-accepted recognition/deployment remains listed as open.' }

if ($assembly -notmatch 'DEPLOYMENT FOUNDATION ACCEPTED' -or $assembly -notmatch 'Uninstall Biology\.exe' -or $assembly -notmatch '(?i)redscript.*only retained generic') { throw 'Integrated assembly doc does not reflect current deployment/uninstall/dependency state.' }
if ($assembly -match '(?i)original three migration lanes.*current|Lane C.*blocker') { throw 'Integrated assembly doc revived merged-lane ownership.' }

foreach ($retired in @('tools/Build-CleanRoomTestPackage.ps1','tools/Finalize-PlayerPackage.ps1','tools/Reset-RealPassIteration.ps1')) {
    if (Test-Path -LiteralPath (Join-Path $project $retired)) { throw "Superseded RealPass attended tooling still exists: $retired" }
}

Write-Host 'PASS: Biology REDmod foundation reflects proven recognition/deployment, self-contained settings, redscript-only generic runtime, current disable/uninstall targets, and only genuinely open direct-game gates.'
