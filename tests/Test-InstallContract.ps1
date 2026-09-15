$ErrorActionPreference = 'Stop'
$project = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$path = Join-Path $project 'manifest/install-contract.json'
$contract = Get-Content -Raw -LiteralPath $path | ConvertFrom-Json

if ($contract.schemaVersion -ne 2 -or $contract.product -ne 'Biology') { throw 'Unexpected Biology install contract.' }
if ($contract.installModel -ne 'game-root-shaped-redmod-first') { throw 'Install model must remain REDmod-first and game-root shaped.' }
if ($contract.playerFlow.normalLaunch -ne 'Steam' -or $contract.playerFlow.permanentLauncher -ne $false) { throw 'Normal play must use Steam without a permanent Biology launcher.' }
if ($contract.playerFlow.vanillaPlay -notmatch '(?i)Enable mods OFF') { throw 'Install contract lost launcher-off vanilla-play target.' }
if ($contract.playerFlow.uninstall -notmatch 'Uninstall Biology\.exe') { throw 'Install contract lost self-contained player hard uninstall.' }

if ($contract.ownerManifest.path -ne 'biology/build-manifest.json' -or $contract.ownerManifest.biologyOwnerValue -ne 'Biology') { throw 'Biology owner manifest identity drifted.' }
if ($contract.ownerManifest.approvedDependencyOwnerPrefix -ne 'upstream:') { throw 'Approved dependency ownership convention drifted.' }
$requiredRoot = @($contract.releaseRootFiles)
foreach ($required in @('INSTALL.txt','UNINSTALL.txt','BIOLOGY-VERSION.txt','SHA256SUMS.txt','biology/build-manifest.json','biology/provenance.json','mods/Biology/info.json')) {
    if ($requiredRoot -notcontains $required) { throw "Required release metadata/identity file missing: $required" }
}

$ownerProps = @($contract.ownerManifest.requiredFileProperties)
foreach ($property in @('path','sha256','owner','component','route','replacePolicy')) {
    if ($ownerProps -notcontains $property) { throw "Owner manifest file property missing: $property" }
}
foreach ($policy in @('biology-owned','approved-dependency-owned')) {
    if (@($contract.ownerManifest.allowedReplacePolicies) -notcontains $policy) { throw "Allowed replace policy missing: $policy" }
}

$uninstaller = $contract.uninstaller
if ($uninstaller.targetExecutable -ne 'Uninstall Biology.exe' -or $uninstaller.selfContained -ne $true) { throw 'Self-contained Biology uninstaller target drifted.' }
if ($uninstaller.requiresPowerShell -ne $false -or $uninstaller.requiresRepositoryCheckout -ne $false) { throw 'Player uninstaller may not depend on PowerShell or repository checkout.' }
if ($uninstaller.gameMustBeClosed -ne $true) { throw 'Uninstaller must require Cyberpunk to be closed.' }
if ($uninstaller.deleteChangedFileByDefault -ne $false) { throw 'Uninstaller must not automatically delete changed/ambiguous files.' }
if ($uninstaller.preserveSaves -ne $true -or $uninstaller.preserveSettingsByDefault -ne $true) { throw 'Uninstaller must preserve saves and preserve settings by default.' }
if ($uninstaller.removeOnlyEmptyOwnedDirectories -ne $true -or $uninstaller.refreshRedmodStateAfterRemoval -ne $true) { throw 'Uninstaller cleanup/REDmod refresh contract drifted.' }

if ($contract.stateAndSaves.saveDataIsNeverInArtifact -ne $true -or $contract.stateAndSaves.saveDataIsNeverDeletedByUninstaller -ne $true) { throw 'Save safety rule drifted.' }
if ($contract.stateAndSaves.destructiveStateResetByToggle -ne $false) { throw 'Activation toggle must not destructively reset saved simulation state.' }

$preflight = @($contract.preflight)
foreach ($required in @('game-must-be-closed-for-installer-or-uninstaller-writes','supported-game-version-must-match-release-metadata','artifact-sha256-and-file-manifest-must-verify','unknown-collision-must-fail-closed-for-assisted-updates','changed-owned-file-must-not-be-auto-deleted','blocked-component-must-not-be-present')) {
    if ($preflight -notcontains $required) { throw "Install/uninstall preflight safety gate missing: $required" }
}

$roots = @($contract.runtimeRoots)
if ($roots -notcontains 'mods/Biology') { throw 'Official Biology REDmod root missing from runtime roots.' }
foreach ($forbidden in @('saves','staging','vendor','ReferenceMods','reports','snapshots')) {
    if ($roots -contains $forbidden) { throw "Development/private root exposed as runtime root: $forbidden" }
}
foreach ($shared in @('archive','bin','engine','mods','r6','red4ext')) {
    if (@($contract.sharedRootsNeverRecursivelyOwned) -notcontains $shared) { throw "Shared-root delete protection missing: $shared" }
}

if (($contract.notes -join ' ') -notmatch '(?i)reinstall.*exceptional|exceptional.*reinstall') { throw 'Install contract must reject full Steam reinstall as ordinary Biology uninstall.' }

Write-Host "PASS: Biology REDmod-first install contract, manifest-safe self-contained uninstaller target, save/settings preservation, and shared-root protections are explicit."
