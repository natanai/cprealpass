$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'Test-RedmodFoundation.ps1 requires PowerShell 7 or newer.' }
. "$PSScriptRoot\..\tools\Common.ps1"

$project = Get-ProjectRoot
$packagePath = Join-Path $project 'manifest/redmod-package.json'
$dependencyPath = Join-Path $project 'manifest/dependency-graph.json'
$classificationPath = Join-Path $project 'manifest/redmod-classification.json'
$installPath = Join-Path $project 'manifest/redmod-install-contract.json'
$infoPath = Join-Path $project 'mods/Biology/info.json'
$activationPath = Join-Path $project 'mods/Biology/tweaks/base/gameplay/static_data/database/items/weapons/parts/biology_activation.tweak'
$probeEvidencePath = Join-Path $project 'docs/evidence/REDMOD-2.31-PROBE-2026-09-15.md'
$assemblyDocPath = Join-Path $project 'docs/REDMOD-INTEGRATED-ASSEMBLY.md'

foreach ($required in @($packagePath,$dependencyPath,$classificationPath,$installPath,$infoPath,$activationPath,$probeEvidencePath,$assemblyDocPath)) {
    if (-not (Test-Path -LiteralPath $required -PathType Leaf)) { throw "Missing REDmod contract/evidence file: $required" }
}

$package = Get-Content -Raw -LiteralPath $packagePath | ConvertFrom-Json
$dependencies = Get-Content -Raw -LiteralPath $dependencyPath | ConvertFrom-Json
$classifications = Get-Content -Raw -LiteralPath $classificationPath | ConvertFrom-Json
$install = Get-Content -Raw -LiteralPath $installPath | ConvertFrom-Json
$info = Get-Content -Raw -LiteralPath $infoPath | ConvertFrom-Json
$activation = Get-Content -Raw -LiteralPath $activationPath
$probeEvidence = Get-Content -Raw -LiteralPath $probeEvidencePath
$assemblyDoc = Get-Content -Raw -LiteralPath $assemblyDocPath

if ($package.schemaVersion -ne 2 -or $package.product -ne 'Biology' -or $package.packageId -ne 'Biology') { throw 'Unexpected integrated REDmod package contract.' }
if ($package.foundationBaseRevision -ne '6fab5ba706e2a10387bb8629cccdb0868533bb97') { throw 'Foundation provenance revision drifted.' }
if ($package.integratedBaseRevision -ne 'bfd6f7469139c64f0b9185724619a37e4ced5eca') { throw 'Integrated assembly did not start from the parent-supplied canonical main.' }
if ($package.supportedGameVersion -ne '2.31' -or $package.redmod.packageRoot -ne 'mods/Biology' -or $package.redmod.metadata -ne 'mods/Biology/info.json') {
    throw 'Biology REDmod identity/path drifted.'
}
if ($package.status -ne 'playable-integrated-candidate') { throw 'REDmod package contract did not advance to the integrated playable candidate.' }
if ($package.canonicalBuilder -ne 'tools/Build-BiologyPackage.ps1' -or $package.canonicalBuildCommand -ne 'pwsh ./tools/Build-BiologyPackage.ps1') {
    throw 'Integrated candidate does not have one canonical Biology build route.'
}
if ($package.exactCompileRequiredBeforeArtifact -ne $true) { throw 'Integrated candidate may emit without exact compile.' }
if ($package.redmod.deployCommand -notmatch 'deploy -root=<Cyberpunk 2077>') { throw 'REDmod deploy contract lost explicit root.' }
if ($package.redmod.launcherActivationMarker -ne 'Items.BiologyLauncherActivationMarker.stackable') { throw 'REDmod package contract lost launcher activation marker.' }
if ($activation -notmatch 'Items\.BiologyLauncherActivationMarker' -or $activation -notmatch 'stackable\s*=\s*true') { throw 'Launcher activation tweak source drifted.' }
if ($package.redmod.observedSupportedInstall.fileVersion -ne '2.3.1.0' -or $package.redmod.observedSupportedInstall.productVersion -ne '2.31') {
    throw 'Direct REDmod 2.31 executable evidence is missing or drifted.'
}
if ($package.redmod.observedSupportedInstall.deployModulePresent -ne $true -or $package.redmod.observedSupportedInstall.explicitRootRequiredByBiologyTooling -ne $true) {
    throw 'Deterministic REDmod deploy invocation contract is missing.'
}
if (@($package.redmod.observedSupportedInstall.modsDirectoryBaseline) -notcontains '.stub') { throw 'Direct clean mods-directory baseline was not recorded.' }
if ($probeEvidence -notmatch 'File version: `2\.3\.1\.0`' -or $probeEvidence -notmatch 'Product version: `2\.31`' -or $probeEvidence -notmatch 'deploy') {
    throw 'Human-readable direct REDmod probe evidence is incomplete.'
}
if ($info.name -ne 'Biology' -or $info.version -notmatch '^\d+\.\d+\.\d+(?:[-+][A-Za-z0-9.-]+)?$') { throw 'Invalid Biology info.json identity/version.' }

$depById = @{}
foreach ($dep in @($dependencies.dependencies)) {
    if ([string]::IsNullOrWhiteSpace($dep.id) -or $depById.ContainsKey($dep.id)) { throw "Invalid/duplicate dependency id: $($dep.id)" }
    $depById[$dep.id] = $dep
    if ([string]::IsNullOrWhiteSpace($dep.status) -or [string]::IsNullOrWhiteSpace($dep.route) -or $null -eq $dep.consumerFeatures -or [string]::IsNullOrWhiteSpace($dep.plannedAction)) {
        throw "Incomplete dependency graph entry: $($dep.id)"
    }
}
foreach ($id in @('redmod','redscript','mod-settings','archivexl','red4ext','tweakxl','codeware','input-loader','darkfuture','project-e3-hud','cyberpunk-game-files')) {
    if (-not $depById.ContainsKey($id)) { throw "Dependency graph missing: $id" }
}
if ($depById['redmod'].status -ne 'required-platform' -or $depById['redmod'].route -ne 'REDMOD-NATIVE' -or $depById['redmod'].bundledByBiology -ne $false) { throw 'REDmod package authority contract drifted.' }
if ($depById['redscript'].status -ne 'required-current-runtime' -or $depById['redscript'].route -ne 'REDSCRIPT-BETTER' -or $depById['redscript'].bundledByBiology -ne $true) { throw 'redscript direct runtime requirement is not recorded.' }
if ($depById['mod-settings'].status -ne 'temporary-retained-blocker' -or $depById['mod-settings'].route -ne 'REMOVE/RETHINK' -or $depById['mod-settings'].bundledByBiology -ne $true) { throw 'Mod Settings current-candidate blocker is not explicit.' }
foreach ($id in @('archivexl','red4ext')) {
    if ($depById[$id].status -ne 'temporary-transitive' -or $depById[$id].route -ne 'REMOVE/RETHINK' -or $depById[$id].bundledByBiology -ne $true) { throw "Temporary transitive dependency is not explicit: $id" }
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
foreach ($entry in @($classifications.entries)) {
    if ($classById.ContainsKey($entry.id)) { throw "Duplicate classification entry: $($entry.id)" }
    if ($allowed -notcontains $entry.classification) { throw "Invalid classification '$($entry.classification)' for $($entry.id)" }
    $classById[$entry.id] = $entry
}
foreach ($id in @('integrated-biology-player-package','current-native-hook-seams','transitional-mod-settings-provider','settings-provider-accessibility-blocker','official-redmod-cli-on-supported-2.31-install','biology-redmod-recognition-on-supported-2.31-install','redmod-conflict-precedence-on-supported-2.31-install')) {
    if (-not $classById.ContainsKey($id)) { throw "Classification coverage missing: $id" }
}
if ($classById['integrated-biology-player-package'].classification -ne 'REDMOD-NATIVE') { throw 'Integrated package is not REDmod-first.' }
if ($classById['official-redmod-cli-on-supported-2.31-install'].classification -ne 'REDMOD-NATIVE') { throw 'Direct local REDmod CLI probe is not reflected in classification.' }
if ($classById['biology-redmod-recognition-on-supported-2.31-install'].classification -ne 'UNKNOWN — NEEDS DIRECT GAME PROBE') { throw 'Biology recognition was claimed without direct deployment evidence.' }
if ($classById['redmod-conflict-precedence-on-supported-2.31-install'].classification -ne 'UNKNOWN — NEEDS DIRECT GAME PROBE') { throw 'PKG-05 precedence was claimed without direct fixture evidence.' }

if ($install.schemaVersion -ne 2 -or $install.product -ne 'Biology' -or $install.candidateStatus -ne 'playable-integrated-candidate') { throw 'Unexpected integrated install contract.' }
if ($install.officialPackageRoot -ne 'mods/Biology' -or $install.playerFlow.permanentBiologyLauncher -ne $false) { throw 'Install contract lost REDmod-first normal-launch target.' }
if ($install.canonicalBuilder -ne 'tools/Build-BiologyPackage.ps1') { throw 'Install contract does not point at canonical integrated builder.' }
if ($install.redmodCli.relativeExecutable -ne 'tools/redmod/bin/redMod.exe' -or $install.redmodCli.observedFileVersion -ne '2.3.1.0' -or $install.redmodCli.observedProductVersion -ne '2.31') {
    throw 'Install contract lost directly probed REDmod executable facts.'
}
if ($install.redmodCli.deployModuleObserved -ne $true -or $install.redmodCli.requiredInvocationRule -notmatch '(?i)pass -root') { throw 'Install contract does not require explicit REDmod root.' }
if ($install.ownerManifest.path -ne 'biology/build-manifest.json' -or $install.ownerManifest.ownerValue -ne 'Biology' -or $install.ownerManifest.schemaVersion -ne 2) { throw 'Biology ownership manifest drifted.' }
if ($install.playerUninstaller.binary -ne 'Uninstall Biology.exe' -or $install.playerUninstaller.genericDependencies -ne 'preserve') { throw 'Player uninstaller contract drifted.' }
foreach ($root in @('r6','red4ext','engine','bin','mods')) {
    if (@($install.neverRecursivelyOwnedRoots) -notcontains $root) { throw "Shared root lost recursive-deletion protection: $root" }
}
if ($install.cleanRoom.currentIntegratedAssemblyRequiresMilestoneBeforeBroadAcceptance -ne $true) { throw 'Structural integrated migration lost milestone clean-room gate.' }

if ($assemblyDoc -notmatch 'MILESTONE CLEAN-ROOM' -or $assemblyDoc -notmatch 'PKG-06' -or $assemblyDoc -notmatch 'Lane C' -or $assemblyDoc -notmatch 'Build-BiologyPackage\.ps1') {
    throw 'Integrated assembly documentation is missing canonical build, clean-room, PKG-06, or settings-owner routing.'
}

Write-Host 'PASS: Biology REDmod contracts describe the integrated playable candidate, launcher activation is REDmod-owned/fail-closed, player uninstall is conservative, and direct-game gates remain open.'
