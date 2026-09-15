$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'Test-RedmodFoundation.ps1 requires PowerShell 7 or newer.' }
. "$PSScriptRoot\..\tools\Common.ps1"

$project = Get-ProjectRoot
$packagePath = Join-Path $project 'manifest/redmod-package.json'
$dependencyPath = Join-Path $project 'manifest/dependency-graph.json'
$classificationPath = Join-Path $project 'manifest/redmod-classification.json'
$installPath = Join-Path $project 'manifest/redmod-install-contract.json'
$infoPath = Join-Path $project 'mods/Biology/info.json'

foreach ($required in @($packagePath,$dependencyPath,$classificationPath,$installPath,$infoPath)) {
    if (-not (Test-Path -LiteralPath $required -PathType Leaf)) { throw "Missing REDmod foundation file: $required" }
}

$package = Get-Content -Raw -LiteralPath $packagePath | ConvertFrom-Json
$dependencies = Get-Content -Raw -LiteralPath $dependencyPath | ConvertFrom-Json
$classifications = Get-Content -Raw -LiteralPath $classificationPath | ConvertFrom-Json
$install = Get-Content -Raw -LiteralPath $installPath | ConvertFrom-Json
$info = Get-Content -Raw -LiteralPath $infoPath | ConvertFrom-Json

if ($package.schemaVersion -ne 1 -or $package.product -ne 'Biology' -or $package.packageId -ne 'Biology') { throw 'Unexpected REDmod package contract.' }
if ($package.foundationBaseRevision -ne '6fab5ba706e2a10387bb8629cccdb0868533bb97') { throw 'REDmod foundation lost its canonical start revision.' }
if ($package.supportedGameVersion -ne '2.31' -or $package.redmod.packageRoot -ne 'mods/Biology' -or $package.redmod.metadata -ne 'mods/Biology/info.json') {
    throw 'Biology REDmod identity/path drifted.'
}
if ($package.status -ne 'foundation-skeleton-not-yet-playable') { throw 'Foundation skeleton must not claim to be a playable release.' }
if ($info.name -ne 'Biology' -or $info.version -notmatch '^\d+\.\d+\.\d+(?:[-+][A-Za-z0-9.-]+)?$') { throw 'Invalid Biology info.json identity/version.' }
if ($null -eq $info.customSounds) { throw 'Biology info.json must declare customSounds.' }

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
if ($depById['redmod'].status -ne 'required-platform' -or $depById['redmod'].route -ne 'REDMOD-NATIVE') { throw 'REDmod is not the package authority.' }
if ($depById['redscript'].status -ne 'retention-candidate' -or $depById['redscript'].route -ne 'REDSCRIPT-BETTER') { throw 'redscript retention must be explicitly seam-based.' }
foreach ($id in @('mod-settings','archivexl','red4ext')) {
    if ($depById[$id].status -ne 'removal-candidate' -or $depById[$id].route -ne 'REMOVE/RETHINK') { throw "Transitional dependency is not a removal candidate: $id" }
}
foreach ($id in @('tweakxl','codeware','input-loader')) {
    if ($depById[$id].status -ne 'not-required') { throw "Unconsumed framework became required: $id" }
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
foreach ($id in @('biology-redmod-package-identity','current-native-hook-seams','redmod-whole-file-script-replacement-for-current-hooks','transitional-mod-settings-provider','official-redmod-cli-on-supported-2.31-install','redmod-conflict-precedence-on-supported-2.31-install')) {
    if (-not $classById.ContainsKey($id)) { throw "Classification coverage missing: $id" }
}
if ($classById['official-redmod-cli-on-supported-2.31-install'].classification -ne 'UNKNOWN — NEEDS DIRECT GAME PROBE') { throw 'Local REDmod CLI was guessed instead of probed.' }
if ($classById['redmod-conflict-precedence-on-supported-2.31-install'].classification -ne 'UNKNOWN — NEEDS DIRECT GAME PROBE') { throw 'PKG-05 local precedence evidence was guessed instead of probed.' }

if ($install.schemaVersion -ne 1 -or $install.product -ne 'Biology' -or $install.installModel -ne 'redmod-first-game-root-relative') { throw 'Unexpected REDmod install contract.' }
if ($install.officialPackageRoot -ne 'mods/Biology' -or $install.playerFlow.permanentBiologyLauncher -ne $false) { throw 'Install contract lost REDmod-first normal-launch target.' }
if ($install.ownerManifest.path -ne 'biology/build-manifest.json' -or $install.ownerManifest.ownerValue -ne 'Biology') { throw 'Biology ownership manifest drifted.' }
if (@($install.neverOwnedRoots) -notcontains 'r6' -or @($install.neverOwnedRoots) -notcontains 'red4ext') { throw 'Shared roots are not protected from broad uninstall ownership.' }
if ($install.cleanRoom.currentFoundationChangeRequiresMilestoneBeforeBroadAcceptance -ne $true) { throw 'Structural REDmod migration lost milestone clean-room gate.' }

$temp = Join-Path ([IO.Path]::GetTempPath()) ('biology-redmod-test-' + [guid]::NewGuid().ToString('N'))
try {
    New-Item -ItemType Directory -Force -Path $temp | Out-Null
    $zip = & (Join-Path $project 'tools/Build-RedmodFoundation.ps1') -OutputRoot $temp
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace([string]$zip) -or -not (Test-Path -LiteralPath $zip -PathType Leaf)) {
        throw 'REDmod foundation builder did not produce an archive.'
    }
    $expanded = Join-Path $temp 'expanded'
    Expand-Archive -LiteralPath $zip -DestinationPath $expanded
    foreach ($required in @('mods/Biology/info.json','INSTALL.txt','UNINSTALL.txt','BIOLOGY-VERSION.txt','SHA256SUMS.txt','biology/build-manifest.json','biology/provenance.json')) {
        if (-not (Test-Path -LiteralPath (Join-Path $expanded $required) -PathType Leaf)) { throw "Foundation archive missing: $required" }
    }
    foreach ($forbidden in @('r6/scripts','red4ext','archive/pc/mod','ReferenceMods','vendor','reports','staging')) {
        if (Test-Path -LiteralPath (Join-Path $expanded $forbidden)) { throw "Foundation archive leaked unrelated/transitional payload: $forbidden" }
    }
    $builtManifest = Get-Content -Raw -LiteralPath (Join-Path $expanded 'biology/build-manifest.json') | ConvertFrom-Json
    if ($builtManifest.product -ne 'Biology' -or $builtManifest.playableRuntimeIncluded -ne $false) { throw 'Built manifest overclaims foundation runtime.' }
    foreach ($file in @($builtManifest.files)) {
        $target = Resolve-SafeChildPath $expanded ([string]$file.path)
        if (-not (Test-Path -LiteralPath $target -PathType Leaf)) { throw "Owned file missing from archive: $($file.path)" }
        if ((Get-Sha256 $target) -ne $file.sha256) { throw "Owned file hash mismatch: $($file.path)" }
        if ($file.owner -ne 'Biology' -or $file.replacePolicy -ne 'biology-owned') { throw "Foundation ownership drifted: $($file.path)" }
    }
    $checksums = Get-Content -LiteralPath (Join-Path $expanded 'SHA256SUMS.txt')
    if (-not ($checksums -match '  biology/build-manifest\.json$')) { throw 'Final owner manifest is not covered by SHA256SUMS.' }
} finally {
    if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Recurse -Force }
}

Write-Host "PASS: Biology REDmod foundation has official package identity, release-shaped offline construction, explicit uninstall ownership, dependency-removal rationale, route classification, and fail-closed direct-game evidence gates."
