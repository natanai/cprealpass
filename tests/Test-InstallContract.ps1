$ErrorActionPreference = 'Stop'
$project = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$path = Join-Path $project 'manifest/install-contract.json'
$contract = Get-Content -Raw -LiteralPath $path | ConvertFrom-Json

if ($contract.schemaVersion -ne 3 -or $contract.product -ne 'Biology') { throw 'Unexpected Biology install contract.' }
if ($contract.installModel -ne 'game-root-shaped-redmod-first') { throw 'Install model must remain REDmod-first and game-root shaped.' }
if ($contract.playerFlow.normalLaunch -ne 'Steam' -or $contract.playerFlow.permanentLauncher -ne $false) { throw 'Normal play must use Steam without a permanent Biology launcher.' }
if ($contract.playerFlow.vanillaPlay -notmatch '(?i)Enable mods OFF') { throw 'Install contract lost launcher-off vanilla-play target.' }
if ($contract.playerFlow.uninstall -notmatch 'Uninstall Biology\.exe') { throw 'Install contract lost self-contained hard uninstall.' }
if ($contract.playerFlow.firstInstall -notmatch '(?i)Install Biology\.ps1' -or $contract.playerFlow.update -notmatch '(?i)global\.ini.*version\.dll.*fail') { throw 'Player install/update flow does not route through the collision-safe standalone-cybercmd installer.' }

if ($contract.ownerManifest.path -ne 'biology/build-manifest.json' -or $contract.ownerManifest.biologyOwnerValue -ne 'Biology') { throw 'Biology owner manifest identity drifted.' }
if ($contract.ownerManifest.approvedDependencyOwnerPrefix -ne 'upstream:') { throw 'Approved dependency ownership convention drifted.' }
$requiredRoot = @($contract.releaseRootFiles)
foreach ($required in @('Install Biology.ps1','BiologyReleaseInstall.Core.ps1','INSTALL.txt','UNINSTALL.txt','BIOLOGY-VERSION.txt','SHA256SUMS.txt','biology/build-manifest.json','biology/provenance.json','mods/Biology/info.json')) { if ($requiredRoot -notcontains $required) { throw "Required release file missing: $required" } }

$ownerProps = @($contract.ownerManifest.requiredFileProperties)
foreach ($property in @('path','sha256','owner','component','route','replacePolicy')) { if ($ownerProps -notcontains $property) { throw "Owner manifest property missing: $property" } }
foreach ($policy in @('biology-owned','generic-dependency-shared')) { if (@($contract.ownerManifest.allowedReplacePolicies) -notcontains $policy) { throw "Allowed replace policy missing: $policy" } }

$installer = $contract.installer
if ($installer.entryScript -ne 'Install Biology.ps1' -or $installer.coreScript -ne 'BiologyReleaseInstall.Core.ps1') { throw 'Collision-safe Biology player installer identity drifted.' }
if ($installer.packageMustBeStagedOutsideGameRoot -ne $true -or $installer.preflightAllInventoriedHashesBeforeMutation -ne $true -or $installer.directZipMergeSupported -ne $false) { throw 'Player installer staging/preflight/direct-merge safety contract drifted.' }
if ($installer.sharedStandaloneCybercmdPolicy.'bin/x64/global.ini' -notmatch 'preserve-if-byte-identical.*fail-closed-before-mutation' -or $installer.sharedStandaloneCybercmdPolicy.'bin/x64/version.dll' -notmatch 'preserve-if-byte-identical.*fail-closed-before-mutation') { throw 'Shared standalone cybercmd loader/config collision policy drifted.' }
if ($installer.sharedStandaloneCybercmdPolicy.'bin/x64/plugins/cybercmd.asi' -ne 'create-preserve-or-replace') { throw 'cybercmd.asi must remain the only replaceable standalone-cybercmd path.' }

$uninstaller = $contract.uninstaller
if ($uninstaller.targetExecutable -ne 'Uninstall Biology.exe' -or $uninstaller.selfContained -ne $true) { throw 'Self-contained Biology uninstaller target drifted.' }
if ($uninstaller.requiresPowerShell -ne $false -or $uninstaller.requiresRepositoryCheckout -ne $false) { throw 'Player uninstaller may not depend on PowerShell or repository checkout.' }
if ($uninstaller.gameMustBeClosed -ne $true -or $uninstaller.deleteChangedFileByDefault -ne $false) { throw 'Uninstaller safety gate drifted.' }
if ($uninstaller.preserveSaves -ne $true -or $uninstaller.preferencesLiveInSaves -ne $true) { throw 'Uninstaller must preserve saves and acknowledge save-backed preferences.' }
if ($uninstaller.removeOnlyEmptyOwnedDirectories -ne $true -or $uninstaller.refreshRedmodStateAfterRemoval -ne $true) { throw 'Uninstaller cleanup/REDmod refresh contract drifted.' }
$preserved = @($uninstaller.preserveGenericDependencies)
if ($preserved.Count -ne 2 -or $preserved -notcontains 'redscript' -or $preserved -notcontains 'cybercmd') { throw 'Uninstaller contract does not preserve the exact shared redscript + cybercmd pair.' }

if ($contract.stateAndSaves.saveDataIsNeverInArtifact -ne $true -or $contract.stateAndSaves.saveDataIsNeverDeletedByUninstaller -ne $true) { throw 'Save safety rule drifted.' }
if ($contract.stateAndSaves.destructiveStateResetByToggle -ne $false) { throw 'Activation toggle must not destructively reset saved state.' }
if ($contract.stateAndSaves.e3PreferencePersistence -notmatch '(?i)ScriptableSystem.*save|save.*ScriptableSystem') { throw 'Install contract does not record replacement E3 persistence authority.' }

$preflight = @($contract.preflight)
foreach ($required in @('game-must-be-closed-for-installer-or-uninstaller-writes','supported-game-version-must-match-release-metadata','artifact-sha256-and-file-manifest-must-verify','redscript-startup-task-runner-must-be-present-in-release','standalone-cybercmd-global-ini-and-version-dll-must-never-be-silently-overwritten','only-cybercmd-asi-may-be-replaced-within-standalone-cybercmd-payload','shared-loader-collision-must-fail-before-any-game-file-mutation','unknown-collision-must-fail-closed-for-assisted-updates','changed-owned-file-must-not-be-auto-deleted','blocked-component-must-not-be-present','retired-settings-stack-must-not-be-present')) { if ($preflight -notcontains $required) { throw "Install/uninstall preflight safety gate missing: $required" } }

$roots = @($contract.runtimeRoots)
foreach ($required in @('mods/Biology','r6/scripts','engine/tools','r6/config/cybercmd','bin/x64')) { if ($roots -notcontains $required) { throw "Required runtime root missing: $required" } }
foreach ($forbidden in @('saves','staging','vendor','ReferenceMods','reports','snapshots','red4ext/plugins/mod_settings','red4ext/plugins/ArchiveXL')) { if ($roots -contains $forbidden) { throw "Development/retired root exposed as runtime root: $forbidden" } }
foreach ($shared in @('archive','bin','engine','mods','r6','red4ext')) { if (@($contract.sharedRootsNeverRecursivelyOwned) -notcontains $shared) { throw "Shared-root delete protection missing: $shared" } }

$notes = $contract.notes -join ' '
if ($notes -notmatch '(?i)redscript.*cybercmd.*only retained generic') { throw 'Install contract does not identify redscript plus cybercmd as the complete retained generic dependency set.' }
if ($notes -notmatch '(?i)cybercmd.*startup compilation task') { throw 'Install contract does not constrain cybercmd to REDscript startup execution.' }
if ($notes -notmatch '(?i)global\.ini.*version\.dll.*preserv') { throw 'Install contract does not explain shared standalone-cybercmd loader/config preservation.' }
if ($notes -notmatch '(?i)reinstall.*exceptional|exceptional.*reinstall') { throw 'Install contract must reject full Steam reinstall as ordinary Biology uninstall.' }

Write-Host 'PASS: Biology install contract is REDmod-first, save-safe, collision-safe for standalone cybercmd shared loader/config, settings-self-contained, and retains only redscript plus cybercmd as generic runtime/startup plumbing.'
