$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$root = Split-Path -Parent $PSScriptRoot
. (Join-Path $root 'tools\BiologyReleaseInstall.Core.ps1')

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
    return [pscustomobject]@{ schemaVersion=2; product='Biology'; files=$Entries }
}
function New-Entry([string]$Relative,[string]$Hash,[string]$Component='cybercmd',[string]$Policy='generic-dependency-shared') {
    return [pscustomobject]@{ path=$Relative; sha256=$Hash; component=$Component; replacePolicy=$Policy }
}

$temp = Join-Path ([IO.Path]::GetTempPath()) ('biology-install-safety-' + [guid]::NewGuid().ToString('N'))
$package = Join-Path $temp 'package'
$game = Join-Path $temp 'game'
New-Item -ItemType Directory -Force -Path $package,$game | Out-Null
try {
    $packageGlobal = Write-TestFile $package 'bin/x64/global.ini' "biology-global`n"
    $packageVersion = Write-TestFile $package 'bin/x64/version.dll' 'biology-loader'
    $packageCybercmd = Write-TestFile $package 'bin/x64/plugins/cybercmd.asi' 'biology-cybercmd'
    $packageOwned = Write-TestFile $package 'mods/Biology/info.json' '{"name":"Biology"}'
    $entries = @(
        (New-Entry 'bin/x64/global.ini' $packageGlobal.sha256),
        (New-Entry 'bin/x64/version.dll' $packageVersion.sha256),
        (New-Entry 'bin/x64/plugins/cybercmd.asi' $packageCybercmd.sha256),
        (New-Entry 'mods/Biology/info.json' $packageOwned.sha256 'biology-redmod-identity' 'biology-owned')
    )
    $manifest = New-TestManifest $entries

    # A non-identical pre-existing shared loader/config must stop the complete plan
    # before any install write can begin.
    $foreignGlobal = Write-TestFile $game 'bin/x64/global.ini' "foreign-global`n"
    $ownedBefore = Write-TestFile $game 'mods/Biology/info.json' 'preexisting-owned'
    $threw = $false
    try { New-BiologyReleaseInstallPlan -PackageRoot $package -GameRoot $game -Manifest $manifest | Out-Null } catch {
        $threw = $true
        Assert-True ($_.Exception.Message -match 'will not overwrite') 'global.ini collision did not fail with the protected shared-loader contract.'
    }
    Assert-True $threw 'Non-identical pre-existing global.ini did not fail closed.'
    Assert-True ((Get-BiologyReleaseSha256 $foreignGlobal.path) -eq $foreignGlobal.sha256) 'global.ini changed despite preflight failure.'
    Assert-True ((Get-BiologyReleaseSha256 $ownedBefore.path) -eq $ownedBefore.sha256) 'Another payload file changed despite shared-loader preflight failure.'

    Remove-Item -LiteralPath $foreignGlobal.path -Force
    $matchingGlobal = Write-TestFile $game 'bin/x64/global.ini' "biology-global`n"
    $foreignVersion = Write-TestFile $game 'bin/x64/version.dll' 'foreign-loader'
    $threw = $false
    try { New-BiologyReleaseInstallPlan -PackageRoot $package -GameRoot $game -Manifest $manifest | Out-Null } catch {
        $threw = $true
        Assert-True ($_.Exception.Message -match 'will not overwrite') 'version.dll collision did not fail with the protected shared-loader contract.'
    }
    Assert-True $threw 'Non-identical pre-existing version.dll did not fail closed.'
    Assert-True ((Get-BiologyReleaseSha256 $matchingGlobal.path) -eq $matchingGlobal.sha256) 'Matching shared global.ini was changed during failed planning.'
    Assert-True ((Get-BiologyReleaseSha256 $foreignVersion.path) -eq $foreignVersion.sha256) 'version.dll changed despite preflight failure.'

    # Byte-identical shared loader/config is accepted as compatible/preserved,
    # while cybercmd.asi is the only cybercmd file allowed to be replaced.
    Remove-Item -LiteralPath $foreignVersion.path -Force
    $matchingVersion = Write-TestFile $game 'bin/x64/version.dll' 'biology-loader'
    $foreignCybercmd = Write-TestFile $game 'bin/x64/plugins/cybercmd.asi' 'old-cybercmd'
    $plan = @(New-BiologyReleaseInstallPlan -PackageRoot $package -GameRoot $game -Manifest $manifest)
    $globalPlan = @($plan | Where-Object relativePath -eq 'bin/x64/global.ini')
    $versionPlan = @($plan | Where-Object relativePath -eq 'bin/x64/version.dll')
    $cybercmdPlan = @($plan | Where-Object relativePath -eq 'bin/x64/plugins/cybercmd.asi')
    Assert-True ($globalPlan.Count -eq 1 -and $globalPlan[0].action -eq 'preserve' -and $globalPlan[0].protectedSharedLoader) 'Matching global.ini was not preserved.'
    Assert-True ($versionPlan.Count -eq 1 -and $versionPlan[0].action -eq 'preserve' -and $versionPlan[0].protectedSharedLoader) 'Matching version.dll was not preserved.'
    Assert-True ($cybercmdPlan.Count -eq 1 -and $cybercmdPlan[0].action -eq 'replace' -and $cybercmdPlan[0].cybercmdReplaceable) 'cybercmd.asi was not the explicitly replaceable standalone path.'

    # Parent release-shaped candidate tooling must call the guarded installer and
    # must no longer force-expand a release ZIP directly into the game root.
    foreach ($relativeTool in @('tools/Bootstrap-BiologyPostTransitionCandidate.ps1','tools/Prepare-BiologyMilestoneTest.ps1')) {
        $text = Get-Content -Raw -LiteralPath (Join-Path $root $relativeTool)
        Assert-True ($text -match 'Install-BiologyRelease\.ps1') "$relativeTool does not use the collision-safe release installer."
        Assert-True ($text -notmatch 'Expand-Archive\s+-LiteralPath\s+\$(artifactZip|zip)\s+-DestinationPath\s+\$(GameRoot|game)\s+-Force') "$relativeTool still force-expands the release ZIP into the game root."
    }

    $builder = Get-Content -Raw -LiteralPath (Join-Path $root 'tools\Build-BiologyPackage.ps1')
    Assert-True ($builder -match "'Install Biology\.ps1'") 'Player package does not include the collision-safe installer entry point.'
    Assert-True ($builder -match "'BiologyReleaseInstall\.Core\.ps1'") 'Player package does not include the collision-safe installer core.'
    Assert-True ($builder -match 'DO NOT extract/copy the package directly into the Cyberpunk 2077 game root') 'Player install instructions do not reject blind game-root merge.'

    Write-Host 'PASS: Biology release install planning preserves matching shared global.ini/version.dll, fails closed on non-identical shared loader/config before mutation, allows only cybercmd.asi replacement, and routes parent/player candidate installation through the guarded installer.'
} finally {
    if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Recurse -Force }
}
