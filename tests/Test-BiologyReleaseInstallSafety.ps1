$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$root = Split-Path -Parent $PSScriptRoot
. (Join-Path $root 'tools\BiologyReleaseInstall.Core.ps1')
. (Join-Path $root 'tools\BiologyFailedInstallRecovery.Core.ps1')

function Assert-True([bool]$Value,[string]$Message) {
    if (-not $Value) { throw $Message }
}
function Write-TestFile([string]$Base,[string]$Relative,[string]$Text) {
    $path = Resolve-BiologyReleaseChild $Base $Relative
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $path) | Out-Null
    [IO.File]::WriteAllText($path,$Text,[Text.UTF8Encoding]::new($false))
    return [pscustomobject]@{ path=$path; sha256=(Get-BiologyReleaseSha256 $path) }
}
function New-TestManifest([object[]]$Entries) {
    return [pscustomobject]@{ schemaVersion=2; product='Biology'; gameVersion='2.31'; sourceRevision=('1' * 40); files=$Entries }
}
function New-Entry([string]$Relative,[string]$Hash,[string]$Component='cybercmd',[string]$Policy='generic-dependency-shared') {
    return [pscustomobject]@{ path=$Relative; sha256=$Hash; component=$Component; replacePolicy=$Policy }
}
function Assert-NoInstallTemps([string]$Base,[string]$Message) {
    $temps = @(Get-ChildItem -LiteralPath $Base -Recurse -Force -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '\.biology-install(?:-backup)?-[0-9a-f]+\.tmp$' })
    Assert-True ($temps.Count -eq 0) ($Message + ': ' + (($temps | ForEach-Object FullName) -join ', '))
}
function Write-RecoveryReceipt([string]$PackageRoot,$Manifest) {
    $path = Resolve-BiologyReleaseChild $PackageRoot 'biology/build-manifest.json'
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $path) | Out-Null
    $Manifest | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $path -Encoding utf8
    return [pscustomobject]@{ path=$path; sha256=(Get-BiologyReleaseSha256 $path) }
}

$temp = Join-Path ([IO.Path]::GetTempPath()) ('biology-install-safety-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $temp | Out-Null
try {
    # W14 create executor: an ordinary absent Biology-owned payload must use the
    # explicit create primitive and arrive with the exact planned hash.
    $createPackage = Join-Path $temp 'create-package'
    $createGame = Join-Path $temp 'create-game'
    New-Item -ItemType Directory -Force -Path $createPackage,$createGame | Out-Null
    $createSource = Write-TestFile $createPackage 'mods/Biology/create-fixture.txt' 'create-fixture'
    $createManifest = New-TestManifest @(
        (New-Entry 'mods/Biology/create-fixture.txt' $createSource.sha256 'biology-redmod-identity' 'biology-owned')
    )
    $createPlan = @(New-BiologyReleaseInstallPlan -PackageRoot $createPackage -GameRoot $createGame -Manifest $createManifest)
    Assert-True ($createPlan.Count -eq 1 -and $createPlan[0].action -eq 'create') 'Absent ordinary file was not planned as create.'
    Invoke-BiologyReleaseInstallPlan -Plan $createPlan
    $createdPath = Resolve-BiologyReleaseChild $createGame 'mods/Biology/create-fixture.txt'
    Assert-True ((Get-BiologyReleaseExistingHash $createdPath) -eq $createSource.sha256) 'Create executor did not install the absent ordinary file with the exact hash.'
    Assert-NoInstallTemps $createGame 'Create executor left temporary install residue'

    # Protected standalone loader/config paths are safe creates when absent, then
    # become preserves when byte-identical on a repeated plan.
    $protectedPackage = Join-Path $temp 'protected-package'
    $protectedGame = Join-Path $temp 'protected-game'
    New-Item -ItemType Directory -Force -Path $protectedPackage,$protectedGame | Out-Null
    $packageGlobal = Write-TestFile $protectedPackage 'bin/x64/global.ini' "biology-global`n"
    $packageVersion = Write-TestFile $protectedPackage 'bin/x64/version.dll' 'biology-loader'
    $protectedManifest = New-TestManifest @(
        (New-Entry 'bin/x64/global.ini' $packageGlobal.sha256),
        (New-Entry 'bin/x64/version.dll' $packageVersion.sha256)
    )
    $protectedCreatePlan = @(New-BiologyReleaseInstallPlan -PackageRoot $protectedPackage -GameRoot $protectedGame -Manifest $protectedManifest)
    Assert-True (@($protectedCreatePlan | Where-Object { $_.action -eq 'create' -and $_.protectedSharedLoader }).Count -eq 2) 'Absent protected global.ini/version.dll were not both planned as safe creates.'
    Invoke-BiologyReleaseInstallPlan -Plan $protectedCreatePlan
    Assert-True ((Get-BiologyReleaseExistingHash (Resolve-BiologyReleaseChild $protectedGame 'bin/x64/global.ini')) -eq $packageGlobal.sha256) 'Protected global.ini create did not verify.'
    Assert-True ((Get-BiologyReleaseExistingHash (Resolve-BiologyReleaseChild $protectedGame 'bin/x64/version.dll')) -eq $packageVersion.sha256) 'Protected version.dll create did not verify.'
    $protectedPreservePlan = @(New-BiologyReleaseInstallPlan -PackageRoot $protectedPackage -GameRoot $protectedGame -Manifest $protectedManifest)
    Assert-True (@($protectedPreservePlan | Where-Object { $_.action -eq 'preserve' -and $_.protectedSharedLoader }).Count -eq 2) 'Matching protected global.ini/version.dll were not both preserved.'
    Invoke-BiologyReleaseInstallPlan -Plan $protectedPreservePlan
    Assert-NoInstallTemps $protectedGame 'Protected create/preserve path left temporary install residue'

    # A non-identical pre-existing shared loader/config must stop the complete plan
    # before any install write can begin.
    $collisionPackage = Join-Path $temp 'collision-package'
    $collisionGame = Join-Path $temp 'collision-game'
    New-Item -ItemType Directory -Force -Path $collisionPackage,$collisionGame | Out-Null
    $collisionGlobal = Write-TestFile $collisionPackage 'bin/x64/global.ini' "biology-global`n"
    $collisionVersion = Write-TestFile $collisionPackage 'bin/x64/version.dll' 'biology-loader'
    $collisionCybercmd = Write-TestFile $collisionPackage 'bin/x64/plugins/cybercmd.asi' 'biology-cybercmd'
    $collisionOwned = Write-TestFile $collisionPackage 'mods/Biology/info.json' '{"name":"Biology"}'
    $collisionManifest = New-TestManifest @(
        (New-Entry 'bin/x64/global.ini' $collisionGlobal.sha256),
        (New-Entry 'bin/x64/version.dll' $collisionVersion.sha256),
        (New-Entry 'bin/x64/plugins/cybercmd.asi' $collisionCybercmd.sha256),
        (New-Entry 'mods/Biology/info.json' $collisionOwned.sha256 'biology-redmod-identity' 'biology-owned')
    )

    $foreignGlobal = Write-TestFile $collisionGame 'bin/x64/global.ini' "foreign-global`n"
    $ownedBefore = Write-TestFile $collisionGame 'mods/Biology/info.json' 'preexisting-owned'
    $threw = $false
    try { New-BiologyReleaseInstallPlan -PackageRoot $collisionPackage -GameRoot $collisionGame -Manifest $collisionManifest | Out-Null } catch {
        $threw = $true
        Assert-True ($_.Exception.Message -match 'will not overwrite') 'global.ini collision did not fail with the protected shared-loader contract.'
    }
    Assert-True $threw 'Non-identical pre-existing global.ini did not fail closed.'
    Assert-True ((Get-BiologyReleaseSha256 $foreignGlobal.path) -eq $foreignGlobal.sha256) 'global.ini changed despite preflight failure.'
    Assert-True ((Get-BiologyReleaseSha256 $ownedBefore.path) -eq $ownedBefore.sha256) 'Another payload file changed despite shared-loader preflight failure.'

    Remove-Item -LiteralPath $foreignGlobal.path -Force
    $matchingGlobal = Write-TestFile $collisionGame 'bin/x64/global.ini' "biology-global`n"
    $foreignVersion = Write-TestFile $collisionGame 'bin/x64/version.dll' 'foreign-loader'
    $threw = $false
    try { New-BiologyReleaseInstallPlan -PackageRoot $collisionPackage -GameRoot $collisionGame -Manifest $collisionManifest | Out-Null } catch {
        $threw = $true
        Assert-True ($_.Exception.Message -match 'will not overwrite') 'version.dll collision did not fail with the protected shared-loader contract.'
    }
    Assert-True $threw 'Non-identical pre-existing version.dll did not fail closed.'
    Assert-True ((Get-BiologyReleaseSha256 $matchingGlobal.path) -eq $matchingGlobal.sha256) 'Matching shared global.ini was changed during failed planning.'
    Assert-True ((Get-BiologyReleaseSha256 $foreignVersion.path) -eq $foreignVersion.sha256) 'version.dll changed despite preflight failure.'

    # Matching shared loader/config is preserved while cybercmd.asi is the only
    # standalone cybercmd path permitted to execute a replace.
    Remove-Item -LiteralPath $foreignVersion.path -Force
    $matchingVersion = Write-TestFile $collisionGame 'bin/x64/version.dll' 'biology-loader'
    $foreignCybercmd = Write-TestFile $collisionGame 'bin/x64/plugins/cybercmd.asi' 'old-cybercmd'
    $plan = @(New-BiologyReleaseInstallPlan -PackageRoot $collisionPackage -GameRoot $collisionGame -Manifest $collisionManifest)
    $globalPlan = @($plan | Where-Object relativePath -eq 'bin/x64/global.ini')
    $versionPlan = @($plan | Where-Object relativePath -eq 'bin/x64/version.dll')
    $cybercmdPlan = @($plan | Where-Object relativePath -eq 'bin/x64/plugins/cybercmd.asi')
    Assert-True ($globalPlan.Count -eq 1 -and $globalPlan[0].action -eq 'preserve' -and $globalPlan[0].protectedSharedLoader) 'Matching global.ini was not preserved.'
    Assert-True ($versionPlan.Count -eq 1 -and $versionPlan[0].action -eq 'preserve' -and $versionPlan[0].protectedSharedLoader) 'Matching version.dll was not preserved.'
    Assert-True ($cybercmdPlan.Count -eq 1 -and $cybercmdPlan[0].action -eq 'replace' -and $cybercmdPlan[0].cybercmdReplaceable) 'cybercmd.asi was not the explicitly replaceable standalone path.'
    Invoke-BiologyReleaseInstallPlan -Plan $plan
    Assert-True ((Get-BiologyReleaseExistingHash $foreignCybercmd.path) -eq $collisionCybercmd.sha256) 'cybercmd.asi explicit replace did not install the exact package hash.'
    Assert-True ((Get-BiologyReleaseExistingHash $matchingGlobal.path) -eq $collisionGlobal.sha256) 'Preserved global.ini changed during cybercmd.asi replacement.'
    Assert-True ((Get-BiologyReleaseExistingHash $matchingVersion.path) -eq $collisionVersion.sha256) 'Preserved version.dll changed during cybercmd.asi replacement.'
    Assert-NoInstallTemps $collisionGame 'Replace executor left install or backup temporary residue'

    # Destination identity changes after planning must fail before an overwrite.
    $racePackage = Join-Path $temp 'race-package'
    $raceGame = Join-Path $temp 'race-game'
    New-Item -ItemType Directory -Force -Path $racePackage,$raceGame | Out-Null
    $raceSource = Write-TestFile $racePackage 'mods/Biology/race.txt' 'planned-payload'
    $raceManifest = New-TestManifest @((New-Entry 'mods/Biology/race.txt' $raceSource.sha256 'biology-redmod-identity' 'biology-owned'))
    $racePlan = @(New-BiologyReleaseInstallPlan -PackageRoot $racePackage -GameRoot $raceGame -Manifest $raceManifest)
    $racedDestination = Write-TestFile $raceGame 'mods/Biology/race.txt' 'appeared-after-plan'
    $threw = $false
    try { Invoke-BiologyReleaseInstallPlan -Plan $racePlan } catch {
        $threw = $true
        Assert-True ($_.Exception.Message -match 'changed after preflight') 'Destination-change execution failure did not identify preflight identity change.'
    }
    Assert-True $threw 'Destination appearing after a create plan did not fail closed.'
    Assert-True ((Get-BiologyReleaseSha256 $racedDestination.path) -eq $racedDestination.sha256) 'Destination appearing after plan was overwritten.'
    Assert-NoInstallTemps $raceGame 'Destination-change failure left install temporary residue'

    # Failed-install recovery is exact-artifact-bound: exact Biology-owned residue
    # is removable, shared dependencies are preserved even when non-identical,
    # and Biology-owned directories are removed only once empty.
    $recoveryPackage = Join-Path $temp 'recovery-package'
    $recoveryGame = Join-Path $temp 'recovery-game'
    New-Item -ItemType Directory -Force -Path $recoveryPackage,$recoveryGame | Out-Null
    $recoveryOwned = Write-TestFile $recoveryPackage 'mods/Biology/info.json' '{"name":"Biology"}'
    $recoveryProvenance = Write-TestFile $recoveryPackage 'biology/provenance.json' '{"product":"Biology"}'
    $recoveryShared = Write-TestFile $recoveryPackage 'bin/x64/global.ini' 'artifact-shared'
    $recoveryManifest = New-TestManifest @(
        (New-Entry 'mods/Biology/info.json' $recoveryOwned.sha256 'biology-redmod-identity' 'biology-owned'),
        (New-Entry 'biology/provenance.json' $recoveryProvenance.sha256 'biology-package-metadata' 'biology-owned'),
        (New-Entry 'bin/x64/global.ini' $recoveryShared.sha256 'cybercmd' 'generic-dependency-shared')
    )
    $recoveryReceipt = Write-RecoveryReceipt $recoveryPackage $recoveryManifest
    Write-TestFile $recoveryGame 'mods/Biology/info.json' '{"name":"Biology"}' | Out-Null
    Write-TestFile $recoveryGame 'biology/provenance.json' '{"product":"Biology"}' | Out-Null
    Copy-Item -LiteralPath $recoveryReceipt.path -Destination (Resolve-BiologyReleaseChild $recoveryGame 'biology/build-manifest.json')
    $foreignShared = Write-TestFile $recoveryGame 'bin/x64/global.ini' 'pre-existing-shared-different-from-artifact'
    $recoveryPlan = New-BiologyFailedInstallRecoveryPlan -PackageRoot $recoveryPackage -GameRoot $recoveryGame -Manifest $recoveryManifest
    Assert-True (@($recoveryPlan.files | Where-Object action -eq 'remove-exact').Count -eq 3) 'Recovery did not plan exact Biology-owned payload plus receipt for removal.'
    Assert-True (@($recoveryPlan.shared | Where-Object action -eq 'preserve-shared').Count -eq 1) 'Recovery did not explicitly preserve shared payload.'
    Invoke-BiologyFailedInstallRecoveryPlan -Plan $recoveryPlan
    Assert-True (-not (Test-Path -LiteralPath (Resolve-BiologyReleaseChild $recoveryGame 'mods/Biology'))) 'Recovery left the Biology REDmod-owned directory.'
    Assert-True (-not (Test-Path -LiteralPath (Resolve-BiologyReleaseChild $recoveryGame 'biology'))) 'Recovery left the Biology metadata-owned directory.'
    Assert-True ((Get-BiologyReleaseSha256 $foreignShared.path) -eq $foreignShared.sha256) 'Recovery changed or removed a shared dependency.'

    # Changed Biology-owned content and foreign files inside Biology-owned roots
    # are ambiguity: planning must fail before deleting any exact file.
    $changedGame = Join-Path $temp 'changed-recovery-game'
    New-Item -ItemType Directory -Force -Path $changedGame | Out-Null
    $changedOwned = Write-TestFile $changedGame 'mods/Biology/info.json' 'changed-by-someone'
    $threw = $false
    try { New-BiologyFailedInstallRecoveryPlan -PackageRoot $recoveryPackage -GameRoot $changedGame -Manifest $recoveryManifest | Out-Null } catch {
        $threw = $true
        Assert-True ($_.Exception.Message -match 'changed/ambiguous') 'Changed Biology-owned recovery content did not fail with ambiguity wording.'
    }
    Assert-True $threw 'Changed Biology-owned content did not fail recovery planning.'
    Assert-True ((Get-BiologyReleaseSha256 $changedOwned.path) -eq $changedOwned.sha256) 'Changed Biology-owned content was mutated despite plan failure.'

    $foreignGame = Join-Path $temp 'foreign-recovery-game'
    New-Item -ItemType Directory -Force -Path $foreignGame | Out-Null
    $exactOwned = Write-TestFile $foreignGame 'mods/Biology/info.json' '{"name":"Biology"}'
    $foreignInside = Write-TestFile $foreignGame 'mods/Biology/foreign.txt' 'not-in-receipt'
    $threw = $false
    try { New-BiologyFailedInstallRecoveryPlan -PackageRoot $recoveryPackage -GameRoot $foreignGame -Manifest $recoveryManifest | Out-Null } catch {
        $threw = $true
        Assert-True ($_.Exception.Message -match 'foreign/unrecognized') 'Foreign content inside Biology-owned root did not fail closed.'
    }
    Assert-True $threw 'Foreign content inside Biology-owned root did not stop recovery planning.'
    Assert-True ((Get-BiologyReleaseSha256 $exactOwned.path) -eq $exactOwned.sha256) 'Exact Biology-owned content was removed despite foreign-content plan failure.'
    Assert-True ((Get-BiologyReleaseSha256 $foreignInside.path) -eq $foreignInside.sha256) 'Foreign content was mutated despite recovery plan failure.'

    # Recovery also rechecks identity immediately before each deletion.
    $changeAfterPlanGame = Join-Path $temp 'change-after-recovery-plan-game'
    New-Item -ItemType Directory -Force -Path $changeAfterPlanGame | Out-Null
    Write-TestFile $changeAfterPlanGame 'mods/Biology/info.json' '{"name":"Biology"}' | Out-Null
    $changeAfterPlan = New-BiologyFailedInstallRecoveryPlan -PackageRoot $recoveryPackage -GameRoot $changeAfterPlanGame -Manifest $recoveryManifest
    $changedAfterPlan = Write-TestFile $changeAfterPlanGame 'mods/Biology/info.json' 'changed-after-plan'
    $threw = $false
    try { Invoke-BiologyFailedInstallRecoveryPlan -Plan $changeAfterPlan } catch {
        $threw = $true
        Assert-True ($_.Exception.Message -match 'changed after plan') 'Recovery destination-change failure did not identify post-plan change.'
    }
    Assert-True $threw 'Recovery did not fail when an exact destination changed after planning.'
    Assert-True ((Get-BiologyReleaseSha256 $changedAfterPlan.path) -eq $changedAfterPlan.sha256) 'Recovery deleted content that changed after planning.'

    # Parent release-shaped candidate tooling must call the guarded installer and
    # must no longer force-expand a release ZIP directly into the game root.
    foreach ($relativeTool in @('tools/Bootstrap-BiologyPostTransitionCandidate.ps1','tools/Prepare-BiologyMilestoneTest.ps1')) {
        $text = Get-Content -Raw -LiteralPath (Join-Path $root $relativeTool)
        Assert-True ($text -match 'Install-BiologyRelease\.ps1') "$relativeTool does not use the collision-safe release installer."
        Assert-True ($text -notmatch 'Expand-Archive\s+-LiteralPath\s+\$(artifactZip|zip)\s+-DestinationPath\s+\$(GameRoot|game)\s+-Force') "$relativeTool still force-expands the release ZIP into the game root."
    }

    $installer = Get-Content -Raw -LiteralPath (Join-Path $root 'tools\Install-BiologyRelease.ps1')
    $payloadInvoke = $installer.IndexOf('Invoke-BiologyReleaseInstallPlan -Plan $plan',[StringComparison]::Ordinal)
    $receiptPublish = $installer.IndexOf('Copy-BiologyReleaseVerified -Source $manifestPath',[StringComparison]::Ordinal)
    Assert-True ($payloadInvoke -ge 0 -and $receiptPublish -gt $payloadInvoke) 'Ownership receipt is not published strictly after payload execution.'
    Assert-True ($installer -match '-Action \$manifestAction -ExpectedPriorHash \$manifestPriorHash') 'Ownership receipt does not use explicit create/replace action semantics.'

    $recoveryBootstrap = Get-Content -Raw -LiteralPath (Join-Path $root 'tools\Bootstrap-BiologyFailedInstallRecovery.ps1')
    foreach ($required in @('ExpectedFailedCandidateReportSha256','ExpectedArtifactSha256','ProcessStartInfo','ArgumentList.Add','PLAN STATUS: SAFE-TO-APPLY','preserve-shared','ATTACH THIS FILE TO CHATGPT:','rev-parse'',''--show-toplevel','remote'',''get-url'',''origin','cat-file'',''-e','Offline exact-head fallback: ACCEPTED')) {
        Assert-True ($recoveryBootstrap -match [regex]::Escape($required)) "Failed-install recovery bootstrap is missing required bounded-evidence/bootstrap contract text: $required"
    }
    Assert-True ($recoveryBootstrap -notmatch 'Deploy-BiologyRedmod\.ps1') 'Failed-install recovery must not redeploy REDmod.'
    Assert-True ($recoveryBootstrap -notmatch '(?i)Start-Process[^\r\n]*Cyberpunk') 'Failed-install recovery must never launch Cyberpunk.'

    $builder = Get-Content -Raw -LiteralPath (Join-Path $root 'tools\Build-BiologyPackage.ps1')
    Assert-True ($builder -match "'Install Biology\.ps1'") 'Player package does not include the collision-safe installer entry point.'
    Assert-True ($builder -match "'BiologyReleaseInstall\.Core\.ps1'") 'Player package does not include the collision-safe installer core.'
    Assert-True ($builder -match 'DO NOT extract/copy the package directly into the Cyberpunk 2077 game root') 'Player install instructions do not reject blind game-root merge.'

    Write-Host 'PASS: W14 release install uses explicit verified create/preserve/replace execution, blocks destination races and protected collisions, cleans temp/backup files, publishes the receipt last, and provides exact-artifact failed-install recovery that removes only exact Biology-owned residue while preserving shared dependencies.'
} finally {
    if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Recurse -Force }
}
