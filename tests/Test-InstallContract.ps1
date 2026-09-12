$ErrorActionPreference = 'Stop'
$project = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$path = Join-Path $project 'manifest/install-contract.json'
$contract = Get-Content -Raw -LiteralPath $path | ConvertFrom-Json
if ($contract.schemaVersion -ne 1 -or $contract.product -ne 'realpass') { throw 'Unexpected install contract.' }
if ($contract.installModel -ne 'game-root-relative') { throw 'Install model must remain game-root-relative.' }
if ($contract.playerFlow.normalLaunch -ne 'Steam' -or $contract.playerFlow.permanentLauncher -ne $false) { throw 'Normal play must use Steam without a permanent realpass launcher.' }
if ($contract.ownerManifest.path -ne 'realpass/build-manifest.json' -or $contract.ownerManifest.ownerValue -ne 'realpass') { throw 'Owner manifest identity drifted.' }

$requiredRoot = @($contract.releaseRootFiles)
foreach ($required in @('INSTALL.txt','UNINSTALL.txt','REALPASS-VERSION.txt','SHA256SUMS.txt','realpass/build-manifest.json','realpass/provenance.json')) {
    if ($requiredRoot -notcontains $required) { throw "Required release metadata file missing: $required" }
}
$ownerProps = @($contract.ownerManifest.requiredFileProperties)
foreach ($property in @('path','sha256','owner','component','replacePolicy')) {
    if ($ownerProps -notcontains $property) { throw "Owner manifest file property missing: $property" }
}
if ($contract.stateAndSaves.saveDataIsNeverInArtifact -ne $true -or $contract.stateAndSaves.fileRollbackIsNotSaveRollback -ne $true) {
    throw 'Save/file rollback safety rule drifted.'
}
if ($contract.stateAndSaves.destructiveStateResetByToggle -ne $false) { throw 'Feature toggle must not destructively reset saved simulation state.' }

$preflight = @($contract.preflight)
foreach ($required in @('game-must-be-closed-for-installer-assisted-writes','supported-game-version-must-match-release-metadata','artifact-sha256-and-file-manifest-must-verify','unknown-collision-must-fail-closed-for-installer-assisted-updates','blocked-component-must-not-be-present')) {
    if ($preflight -notcontains $required) { throw "Install preflight safety gate missing: $required" }
}

$roots = @($contract.runtimeRoots)
foreach ($forbidden in @('saves','staging','vendor','ReferenceMods','reports','snapshots')) {
    if ($roots -contains $forbidden) { throw "Development/private root exposed as runtime root: $forbidden" }
}

Write-Host "PASS: game-root install contract with $($requiredRoot.Count) release metadata files, $($roots.Count) allowed runtime roots, and per-file uninstall ownership."
