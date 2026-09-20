[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$GameRoot,
    [string]$PackageRoot = $PSScriptRoot,
    [switch]$WhatIf
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'BiologyReleaseInstall.Core.ps1')

function Assert-BiologyGameStopped {
    if (Get-Process -Name 'Cyberpunk2077' -ErrorAction SilentlyContinue) {
        throw 'Cyberpunk 2077 is running. Close the game before installing Biology.'
    }
}

$PackageRoot = [IO.Path]::GetFullPath($PackageRoot).TrimEnd('\','/')
$GameRoot = [IO.Path]::GetFullPath($GameRoot).TrimEnd('\','/')
if (-not (Test-Path -LiteralPath $PackageRoot -PathType Container)) { throw "Biology package root does not exist: $PackageRoot" }
if (-not (Test-Path -LiteralPath $GameRoot -PathType Container)) { throw "Cyberpunk game root does not exist: $GameRoot" }
if ($PackageRoot.Equals($GameRoot,[StringComparison]::OrdinalIgnoreCase) -or $PackageRoot.StartsWith($GameRoot + [IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)) {
    throw 'Biology release installation must run from a staging/extracted package directory outside the Cyberpunk game root. Do not merge the ZIP directly into the game directory.'
}

$gameExe = Resolve-BiologyReleaseChild $GameRoot 'bin/x64/Cyberpunk2077.exe'
if (-not (Test-Path -LiteralPath $gameExe -PathType Leaf)) { throw "Not a Cyberpunk 2077 game root: $GameRoot" }
$gameVersion = (Get-Item -LiteralPath $gameExe).VersionInfo.ProductVersion
if ($gameVersion -ne '2.31') { throw "Biology currently supports Cyberpunk 2077 2.31; installed game reports '$gameVersion'." }
Assert-BiologyGameStopped

$manifestPath = Resolve-BiologyReleaseChild $PackageRoot 'biology/build-manifest.json'
if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) { throw 'Biology package ownership receipt is missing.' }
$manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
if ($manifest.schemaVersion -ne 2 -or [string]$manifest.product -ne 'Biology' -or [string]$manifest.gameVersion -ne '2.31') {
    throw 'Biology package ownership receipt is not a supported release manifest.'
}

# The complete payload is hashed and collision-planned before any game file is written.
# Standalone cybercmd's shared global.ini/version.dll are accepted only when absent
# or byte-identical to the package. A non-identical pre-existing file fails closed.
# cybercmd.asi is the only standalone cybercmd path allowed to be replaced.
$plan = @(New-BiologyReleaseInstallPlan -PackageRoot $PackageRoot -GameRoot $GameRoot -Manifest $manifest)
if ($plan.Count -eq 0) { throw 'Biology release ownership receipt contains no installable files.' }

$manifestDestination = Resolve-BiologyReleaseChild $GameRoot 'biology/build-manifest.json'
$manifestSourceHash = Get-BiologyReleaseSha256 $manifestPath
$manifestPriorHash = Get-BiologyReleaseExistingHash $manifestDestination
$manifestAction = if ($manifestPriorHash -eq $manifestSourceHash) { 'preserve' } elseif ($null -eq $manifestPriorHash) { 'create' } else { 'replace' }

if ($WhatIf) {
    $plan | Select-Object relativePath,component,action,protectedSharedLoader,cybercmdReplaceable
    [pscustomobject]@{
        relativePath = 'biology/build-manifest.json'
        component = 'biology-package-metadata'
        action = $manifestAction
        protectedSharedLoader = $false
        cybercmdReplaceable = $false
    }
    return
}

Assert-BiologyGameStopped
Invoke-BiologyReleaseInstallPlan -Plan $plan

# Publish the receipt last, after all inventoried payload hashes verify. This file
# cannot hash itself, so it is validated structurally above and copied atomically.
if ((Get-BiologyReleaseExistingHash $manifestDestination) -ne $manifestPriorHash) {
    throw 'Installed Biology ownership receipt changed after preflight.'
}
if ($manifestAction -ne 'preserve') {
    Copy-BiologyReleaseVerified -Source $manifestPath -Destination $manifestDestination -ExpectedHash $manifestSourceHash -Action $manifestAction -ExpectedPriorHash $manifestPriorHash
}
if ((Get-BiologyReleaseExistingHash $manifestDestination) -ne $manifestSourceHash) {
    throw 'Installed Biology ownership receipt failed post-copy verification.'
}

$preservedShared = @($plan | Where-Object { $_.protectedSharedLoader -and $_.action -eq 'preserve' }).Count
$createdShared = @($plan | Where-Object { $_.protectedSharedLoader -and $_.action -eq 'create' }).Count
$replacedCybercmd = @($plan | Where-Object { $_.cybercmdReplaceable -and $_.action -eq 'replace' }).Count
Write-Host ("PASS: Biology release install verified: {0} inventoried files; protected shared loader/config preserved={1}, created={2}; cybercmd.asi replacements={3}." -f $plan.Count,$preservedShared,$createdShared,$replacedCybercmd) -ForegroundColor Green
Write-Host 'Standalone cybercmd collision rule: global.ini/version.dll are never overwritten; only cybercmd.asi may be replaced.'
