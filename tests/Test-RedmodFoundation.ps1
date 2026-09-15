$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'Test-RedmodFoundation.ps1 requires PowerShell 7 or newer.' }
. "$PSScriptRoot\..\tools\Common.ps1"

$project = Get-ProjectRoot
$packagePath = Join-Path $project 'manifest/redmod-package.json'
$dependencyPath = Join-Path $project 'manifest/dependency-graph.json'
$classificationPath = Join-Path $project 'manifest/redmod-classification.json'
$installPath = Join-Path $project 'manifest/redmod-install-contract.json'
$infoPath = Join-Path $project 'mods/Biology/info.json'
$probeEvidencePath = Join-Path $project 'docs/evidence/REDMOD-2.31-PROBE-2026-09-15.md'
$deployEvidencePath = Join-Path $project 'docs/test-runs/2026-09-15-8cf04566-redmod-deploy-preflight.md'
$assemblyDocPath = Join-Path $project 'docs/REDMOD-INTEGRATED-ASSEMBLY.md'

foreach ($required in @($packagePath,$dependencyPath,$classificationPath,$installPath,$infoPath,$probeEvidencePath,$deployEvidencePath,$assemblyDocPath)) {
    if (-not (Test-Path -LiteralPath $required -PathType Leaf)) { throw "Missing REDmod contract/evidence file: $required" }
}

$package = Get-Content -Raw -LiteralPath $packagePath | ConvertFrom-Json
$dependencies = Get-Content -Raw -LiteralPath $dependencyPath | ConvertFrom-Json
$classifications = Get-Content -Raw -LiteralPath $classificationPath | ConvertFrom-Json
$install = Get-Content -Raw -LiteralPath $installPath | ConvertFrom-Json
$info = Get-Content -Raw -LiteralPath $infoPath | ConvertFrom-Json
$probeEvidence = Get-Content -Raw -LiteralPath $probeEvidencePath
$deployEvidence = Get-Content -Raw -LiteralPath $deployEvidencePath
$assemblyDoc = Get-Content -Raw -LiteralPath $assemblyDocPath

if ($package.schemaVersion -ne 2 -or $package.product -ne 'Biology' -or $package.packageId -ne 'Biology') { throw 'Unexpected integrated REDmod package contract.' }
if ($package.supportedGameVersion -ne '2.31' -or $package.redmod.packageRoot -ne 'mods/Biology' -or $package.redmod.metadata -ne 'mods/Biology/info.json') { throw 'Biology REDmod identity/path drifted.' }
if ($package.status -ne 'playable-integrated-candidate') { throw 'REDmod package contract lost integrated playable-candidate state.' }
if ($package.canonicalBuilder -ne 'tools/Build-BiologyPackage.ps1' -or $package.exactCompileRequiredBeforeArtifact -ne $true) { throw 'Canonical integrated builder/exact-compile gate drifted.' }
if ($package.redmod.deployHelper -ne 'tools/Deploy-BiologyRedmod.ps1' -or $package.redmod.deployCommandPolicy -notmatch '(?i)exit code 0') { throw 'REDmod deploy contract no longer records the fail-closed helper policy.' }
if ($package.redmod.observedSupportedInstall.fileVersion -ne '2.3.1.0' -or $package.redmod.observedSupportedInstall.productVersion -ne '2.31') { throw 'Direct REDmod version evidence drifted.' }
if ($package.redmod.observedSupportedInstall.biologyRecognitionProven -ne $true -or $package.redmod.observedSupportedInstall.biologyFiveStageDeploymentProven -ne $true) { throw 'Package contract forgot accepted Biology REDmod deployment evidence.' }
if ($probeEvidence -notmatch 'File version: `2\.3\.1\.0`' -or $probeEvidence -notmatch 'Product version: `2\.31`') { throw 'Human-readable REDmod tool probe evidence is incomplete.' }
if ($deployEvidence -notmatch '(?i)Found mod.*Biology' -or $deployEvidence -notmatch '(?i)Stage 5/5|five-stage' -or $deployEvidence -notmatch '(?i)deploy.*PASS|PASS.*deploy') { throw 'Accepted Biology deployment evidence is incomplete.' }
if ($info.name -ne 'Biology' -or $info.version -notmatch '^\d+\.\d+\.\d+(?:[-+][A-Za-z0-9.-]+)?$') { throw 'Invalid Biology info.json identity/version.' }

$depById = @{}
foreach ($dep in @($dependencies.dependencies)) {
    if ([string]::IsNullOrWhiteSpace($dep.id) -or $depById.ContainsKey($dep.id)) { throw "Invalid/duplicate dependency id: $($dep.id)" }
    $depById[$dep.id] = $dep
}
foreach ($id in @('redmod','redscript','mod-settings','archivexl','red4ext','tweakxl','codeware','input-loader','darkfuture','project-e3-hud','cyberpunk-game-files')) {
    if (-not $depById.ContainsKey($id)) { throw "Dependency graph missing: $id" }
}
if ($depById['redmod'].status -ne 'required-platform' -or $depById['redmod'].bundledByBiology -ne $false) { throw 'REDmod platform authority contract drifted.' }
if ($depById['redscript'].status -ne 'required-current-runtime' -or $depById['redscript'].bundledByBiology -ne $true) { throw 'redscript direct runtime requirement is not recorded.' }
if ($depById['mod-settings'].status -ne 'temporary-retained-blocker' -or $depById['mod-settings'].plannedAction -match '(?i)Lane C') { throw 'Mod Settings dependency still uses stale lane ownership or lost temporary status.' }
if ($depById['mod-settings'].currentOwnerIssue -notmatch '#44|#40') { throw 'Current settings/activation ownership is not routed to live issues.' }
foreach ($id in @('archivexl','red4ext')) {
    if ($depById[$id].status -ne 'temporary-transitive' -or $depById[$id].bundledByBiology -ne $true) { throw "Temporary transitive dependency is not explicit: $id" }
}
foreach ($id in @('tweakxl','codeware','input-loader')) {
    if ($depById[$id].status -ne 'not-required' -or $depById[$id].bundledByBiology -ne $false) { throw "Unconsumed framework entered integrated runtime: $id" }
}
foreach ($id in @('darkfuture','project-e3-hud')) {
    if ($depById[$id].status -ne 'blocked-runtime' -or $depById[$id].bundledByBiology -ne $false) { throw "Reference runtime became bundleable: $id" }
}

$allowed = @($classifications.allowedClassifications)
foreach ($required in @('REDMOD-NATIVE','REDMOD-POSSIBLE-BUT-BRITTLE','REDSCRIPT-BETTER','REQUIRES-NATIVE-EXTENSION','REMOVE/RETHINK','UNKNOWN — NEEDS DIRECT GAME PROBE')) {
    if ($allowed -notcontains $required) { throw "Required classification missing: $required" }
}
$classById = @{}
foreach ($entry in @($classifications.entries)) { $classById[$entry.id] = $entry }
foreach ($id in @('integrated-biology-player-package','current-native-hook-seams','transitional-mod-settings-provider','settings-provider-accessibility-blocker','official-redmod-cli-on-supported-2.31-install','biology-redmod-recognition-on-supported-2.31-install','redmod-conflict-precedence-on-supported-2.31-install')) {
    if (-not $classById.ContainsKey($id)) { throw "Classification coverage missing: $id" }
}
if ($classById['integrated-biology-player-package'].classification -ne 'REDMOD-NATIVE') { throw 'Integrated package is not REDmod-first.' }
if ($classById['biology-redmod-recognition-on-supported-2.31-install'].classification -ne 'REDMOD-NATIVE') { throw 'Accepted Biology recognition/deployment was regressed to an unknown gate.' }
if ($classById['biology-redmod-recognition-on-supported-2.31-install'].evidence -notmatch 'docs/test-runs/') { throw 'Recognition/deploy classification lacks attended evidence path.' }
if ($classById['redmod-conflict-precedence-on-supported-2.31-install'].classification -ne 'UNKNOWN — NEEDS DIRECT GAME PROBE') { throw 'Overlap precedence was claimed without accepted direct fixture evidence.' }

if ($install.schemaVersion -ne 2 -or $install.product -ne 'Biology' -or $install.candidateStatus -ne 'playable-integrated-candidate') { throw 'Unexpected integrated install contract.' }
if ($install.officialPackageRoot -ne 'mods/Biology' -or $install.playerFlow.permanentBiologyLauncher -ne $false) { throw 'Install contract lost REDmod-first normal-launch target.' }
if ($install.redmodCli.biologyRecognitionProven -ne $true -or $install.redmodCli.fiveStageDeploymentProven -ne $true) { throw 'Install contract forgot accepted direct deployment evidence.' }
if ($install.playerFlow.disable -notmatch '(?i)Enable mods OFF' -or $install.playerFlow.uninstall -notmatch 'Uninstall Biology\.exe') { throw 'Install contract lost current vanilla-play/hard-uninstall targets.' }
foreach ($root in @('bin','archive','engine','mods','r6','red4ext')) {
    if (@($install.neverRecursivelyOwnedRoots) -notcontains $root) { throw "Shared root lost recursive-deletion protection: $root" }
}
if ($install.cleanRoom.firstIntegratedRedmodMilestoneCompleted -ne $true -or $install.cleanRoom.fullSteamReinstallIsNormalUninstall -ne $false) { throw 'Clean-room contract still treats the first migration as pending or reinstall as normal uninstall.' }

if ($assemblyDoc -notmatch 'DEPLOYMENT FOUNDATION ACCEPTED' -or $assemblyDoc -notmatch 'Found mod' -or $assemblyDoc -match '(?i)remaining direct-game gates\s*.*actual Biology REDmod recognition/deployment') {
    throw 'Integrated assembly documentation still describes accepted REDmod recognition/deployment as pending.'
}
if ($assemblyDoc -notmatch 'Uninstall Biology\.exe' -or $assemblyDoc -notmatch 'Deploy-BiologyRedmod\.ps1') { throw 'Integrated assembly documentation lost current uninstall/deploy-helper direction.' }

Write-Host 'PASS: REDmod foundation contracts preserve the accepted Biology deployment evidence, current dependency ownership, current player disable/uninstall direction, and only genuinely open direct-game gates.'
