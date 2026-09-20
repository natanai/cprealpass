Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'BiologyReleaseInstall.Core.ps1')
. (Join-Path $PSScriptRoot 'BiologyFailedInstallRecovery.Core.ps1')

function Test-BiologyPriorAllowedOwnedPath([string]$RelativePath) {
    $rootFiles = @(
        'Install Biology.ps1',
        'BiologyReleaseInstall.Core.ps1',
        'INSTALL.txt',
        'UNINSTALL.txt',
        'BIOLOGY-VERSION.txt',
        'SHA256SUMS.txt',
        'Uninstall Biology.exe'
    )
    foreach ($name in $rootFiles) {
        if ($RelativePath.Equals($name,[StringComparison]::OrdinalIgnoreCase)) { return $true }
    }
    foreach ($root in @('mods/Biology','r6/scripts/CyberpunkRealism','biology')) {
        if ($RelativePath.StartsWith($root + '/',[StringComparison]::OrdinalIgnoreCase)) { return $true }
    }
    return $false
}

function Assert-BiologyPriorManifestContract($Manifest) {
    if ($null -eq $Manifest -or [int]$Manifest.schemaVersion -ne 2 -or [string]$Manifest.product -cne 'Biology') {
        throw 'Unsupported or non-Biology ownership receipt; replacement refused.'
    }
    if (-not [bool]$Manifest.playableRuntimeIncluded -or [string]$Manifest.officialPackageRoot -cne 'mods/Biology') {
        throw 'Ownership receipt is not the supported playable Biology package shape.'
    }
    if (@($Manifest.files).Count -lt 1) { throw 'Biology ownership receipt has no file inventory.' }
    if ($null -eq $Manifest.uninstall -or [int]$Manifest.uninstall.schemaVersion -ne 2) {
        throw 'Biology ownership receipt does not contain the supported uninstall contract.'
    }
    if (
        [string]$Manifest.uninstall.playerBinary -cne 'Uninstall Biology.exe' -or
        [string]$Manifest.uninstall.biologyOwnedPolicy -cne 'biology-owned' -or
        [string]$Manifest.uninstall.genericDependencyPolicy -cne 'preserve' -or
        [string]$Manifest.uninstall.savePolicy -cne 'never-target' -or
        [string]$Manifest.uninstall.preferencePolicy -cne 'stored-in-save-never-target' -or
        [string]$Manifest.uninstall.redmodRefresh -cne 'official-redmod-deploy-explicit-root'
    ) {
        throw 'Biology ownership receipt uninstall policy is unexpected; replacement refused.'
    }
}

function New-BiologyPriorInstallTransitionPlan([string]$GameRoot,[string]$ManifestPath) {
    $GameRoot = [IO.Path]::GetFullPath($GameRoot)
    $ManifestPath = [IO.Path]::GetFullPath($ManifestPath)
    $expectedReceipt = Resolve-BiologyReleaseChild $GameRoot 'biology/build-manifest.json'
    if (-not $ManifestPath.Equals($expectedReceipt,[StringComparison]::OrdinalIgnoreCase)) {
        throw 'The ownership receipt is not at biology/build-manifest.json under this game root.'
    }
    if (-not (Test-Path -LiteralPath $ManifestPath -PathType Leaf)) {
        throw 'Biology ownership receipt is missing; replacement cannot prove ownership.'
    }

    try { $manifest = Get-Content -Raw -LiteralPath $ManifestPath | ConvertFrom-Json -ErrorAction Stop }
    catch { throw "Biology ownership receipt is not valid JSON: $($_.Exception.Message)" }
    Assert-BiologyPriorManifestContract $manifest

    $ownedRoots = @('mods/Biology','r6/scripts/CyberpunkRealism','biology')
    $knownDirectories = @{}
    foreach ($root in $ownedRoots) { $knownDirectories[$root.ToLowerInvariant()] = $root }
    $inventoried = @{}
    $ownedFiles = @{}
    $sharedFiles = @{}

    foreach ($file in @($manifest.files)) {
        $relative = ([string]$file.path).Replace('\','/').Trim()
        if ([string]::IsNullOrWhiteSpace($relative)) { throw 'Ownership receipt contains an empty path.' }
        [void](Resolve-BiologyReleaseChild $GameRoot $relative)
        $key = $relative.ToLowerInvariant()
        if ($inventoried.ContainsKey($key)) { throw "Duplicate path in Biology ownership receipt: $relative" }
        if (
            [string]::IsNullOrWhiteSpace([string]$file.owner) -or
            [string]::IsNullOrWhiteSpace([string]$file.component) -or
            [string]::IsNullOrWhiteSpace([string]$file.route)
        ) { throw "Ownership receipt contains incomplete metadata for: $relative" }

        $hash = ([string]$file.sha256).ToUpperInvariant()
        if ($hash -notmatch '^[A-F0-9]{64}$') { throw "Ownership receipt contains an invalid SHA-256 for: $relative" }

        if ([string]$file.replacePolicy -ceq 'biology-owned') {
            if ([string]$file.owner -cne 'Biology' -or -not (Test-BiologyPriorAllowedOwnedPath $relative)) {
                throw "Biology-owned deletion is not allowed at this path: $relative"
            }
            $inventoried[$key] = 'biology-owned'
            $ownedFiles[$key] = [pscustomobject]@{ relativePath=$relative; expectedSha256=$hash; receiptFile=$false }

            $parent = Get-BiologyRecoveryParent $relative
            while ($parent) {
                $inside = $false
                foreach ($root in $ownedRoots) {
                    if (Test-BiologyRecoveryPathUnder $parent $root) { $inside = $true; break }
                }
                if (-not $inside) { break }
                $knownDirectories[$parent.ToLowerInvariant()] = $parent
                $parent = Get-BiologyRecoveryParent $parent
            }
        } elseif ([string]$file.replacePolicy -ceq 'generic-dependency-shared') {
            if (-not ([string]$file.owner).StartsWith('upstream:',[StringComparison]::OrdinalIgnoreCase)) {
                throw "Generic dependency ownership is not attributed to upstream at: $relative"
            }
            $inventoried[$key] = 'generic-dependency-shared'
            $sharedFiles[$key] = [pscustomobject]@{ relativePath=$relative; expectedSha256=$hash }
        } else {
            throw "Unsupported replacement/uninstall policy for: $relative"
        }
    }

    $receiptRelative = 'biology/build-manifest.json'
    $receiptKey = $receiptRelative.ToLowerInvariant()
    if ($inventoried.ContainsKey($receiptKey)) { throw 'Ownership receipt must not inventory itself.' }
    $receiptHash = Get-BiologyReleaseSha256 $ManifestPath
    $inventoried[$receiptKey] = 'receipt'
    $ownedFiles[$receiptKey] = [pscustomobject]@{
        relativePath=$receiptRelative
        expectedSha256=$receiptHash
        receiptFile=$true
    }
    $knownDirectories['biology'] = 'biology'

    foreach ($rootRelative in $ownedRoots) {
        $rootFull = Resolve-BiologyReleaseChild $GameRoot $rootRelative
        if (-not (Test-Path -LiteralPath $rootFull)) { continue }
        $rootItem = Get-Item -Force -LiteralPath $rootFull
        if ($rootItem.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "Replacement refuses Biology-owned reparse point: $rootRelative" }
        if (-not $rootItem.PSIsContainer) { throw "Replacement expected Biology-owned directory but found a file: $rootRelative" }

        foreach ($entry in @(Get-ChildItem -Force -LiteralPath $rootFull -Recurse)) {
            if ($entry.Attributes -band [IO.FileAttributes]::ReparsePoint) {
                throw "Replacement refuses reparse point inside Biology-owned root: $(Get-BiologyRecoveryRelative $GameRoot $entry.FullName)"
            }
            $relative = Get-BiologyRecoveryRelative $GameRoot $entry.FullName
            $key = $relative.ToLowerInvariant()
            if ($entry.PSIsContainer) {
                if (-not $knownDirectories.ContainsKey($key)) {
                    throw "Replacement found an untracked directory inside Biology-owned state: $relative"
                }
            } elseif (-not $inventoried.ContainsKey($key)) {
                throw "Replacement found untracked content inside Biology-owned state: $relative"
            } elseif ([string]$inventoried[$key] -eq 'generic-dependency-shared') {
                throw "Replacement refuses preserve-only shared content inside a Biology-owned namespace: $relative"
            }
        }
    }

    $filePlan = [Collections.Generic.List[object]]::new()
    foreach ($owned in @($ownedFiles.Values | Sort-Object relativePath)) {
        $destination = Resolve-BiologyReleaseChild $GameRoot ([string]$owned.relativePath)
        $current = Get-BiologyReleaseExistingHash $destination
        if ($null -eq $current) {
            if ([bool]$owned.receiptFile) { throw 'Installed Biology ownership receipt disappeared during planning.' }
            $action = 'absent'
        } elseif ($current -eq [string]$owned.expectedSha256) {
            $action = 'remove-exact'
        } else {
            throw "Replacement refuses changed Biology-owned content: $($owned.relativePath)"
        }
        $filePlan.Add([pscustomobject]@{
            relativePath=[string]$owned.relativePath
            destination=$destination
            expectedSha256=[string]$owned.expectedSha256
            observedSha256=$current
            action=$action
            receiptFile=[bool]$owned.receiptFile
        })
    }

    $sharedPlan = [Collections.Generic.List[object]]::new()
    foreach ($shared in @($sharedFiles.Values | Sort-Object relativePath)) {
        $destination = Resolve-BiologyReleaseChild $GameRoot ([string]$shared.relativePath)
        $sharedPlan.Add([pscustomobject]@{
            relativePath=[string]$shared.relativePath
            destination=$destination
            packageSha256=[string]$shared.expectedSha256
            observedSha256=(Get-BiologyReleaseExistingHash $destination)
            action='preserve-shared'
        })
    }

    $directoryPlan = [Collections.Generic.List[object]]::new()
    foreach ($relative in @($knownDirectories.Values | Sort-Object { ($_ -split '/').Count } -Descending)) {
        $destination = Resolve-BiologyReleaseChild $GameRoot $relative
        if (Test-Path -LiteralPath $destination) {
            $directoryPlan.Add([pscustomobject]@{ relativePath=$relative; destination=$destination; action='remove-if-empty' })
        }
    }

    return [pscustomobject]@{
        gameRoot=$GameRoot
        files=@($filePlan)
        shared=@($sharedPlan)
        directories=@($directoryPlan)
        ownedRoots=$ownedRoots
        manifest=$manifest
        manifestSha256=$receiptHash
        inventoried=$inventoried
        knownDirectories=$knownDirectories
    }
}

function Assert-BiologyPriorOwnedNamespace($Plan) {
    foreach ($rootRelative in @($Plan.ownedRoots)) {
        $rootFull = Resolve-BiologyReleaseChild ([string]$Plan.gameRoot) ([string]$rootRelative)
        if (-not (Test-Path -LiteralPath $rootFull)) { continue }
        $rootItem = Get-Item -Force -LiteralPath $rootFull
        if ($rootItem.Attributes -band [IO.FileAttributes]::ReparsePoint) {
            throw "Replacement refuses Biology-owned reparse point: $rootRelative"
        }
        if (-not $rootItem.PSIsContainer) {
            throw "Replacement expected Biology-owned directory but found a file: $rootRelative"
        }
        foreach ($entry in @(Get-ChildItem -Force -LiteralPath $rootFull -Recurse)) {
            if ($entry.Attributes -band [IO.FileAttributes]::ReparsePoint) {
                throw "Replacement refuses reparse point inside Biology-owned root: $(Get-BiologyRecoveryRelative ([string]$Plan.gameRoot) $entry.FullName)"
            }
            $relative = Get-BiologyRecoveryRelative ([string]$Plan.gameRoot) $entry.FullName
            $key = $relative.ToLowerInvariant()
            if ($entry.PSIsContainer) {
                if (-not $Plan.knownDirectories.ContainsKey($key)) {
                    throw "Replacement found an untracked directory inside Biology-owned state: $relative"
                }
            } elseif (-not $Plan.inventoried.ContainsKey($key)) {
                throw "Replacement found untracked content inside Biology-owned state: $relative"
            } elseif ([string]$Plan.inventoried[$key] -eq 'generic-dependency-shared') {
                throw "Replacement refuses preserve-only shared content inside a Biology-owned namespace: $relative"
            }
        }
    }
}

function Assert-BiologyPriorInstallTransitionPlan($Plan) {
    $receipt = Resolve-BiologyReleaseChild ([string]$Plan.gameRoot) 'biology/build-manifest.json'
    if (-not (Test-Path -LiteralPath $receipt -PathType Leaf) -or
        (Get-BiologyReleaseSha256 $receipt) -ne [string]$Plan.manifestSha256) {
        throw 'Prior Biology ownership receipt changed after planning; replacement refused before mutation.'
    }

    foreach ($item in @($Plan.files)) {
        $current = Get-BiologyReleaseExistingHash ([string]$item.destination)
        if ([string]$item.action -eq 'absent') {
            if ($null -ne $current) { throw "A previously missing Biology-owned path appeared after planning: $($item.relativePath)" }
        } elseif ([string]$item.action -eq 'remove-exact') {
            if ($current -ne [string]$item.expectedSha256) {
                throw "Biology-owned content changed after planning; replacement refused before mutation: $($item.relativePath)"
            }
        } else {
            throw "Unexpected replacement action: $($item.action)"
        }
    }

    Assert-BiologyPriorOwnedNamespace $Plan
}
