Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not (Get-Command Resolve-BiologyReleaseChild -ErrorAction SilentlyContinue)) {
    . (Join-Path $PSScriptRoot 'BiologyReleaseInstall.Core.ps1')
}

function Test-BiologyRecoveryPathUnder([string]$RelativePath,[string]$RootRelative) {
    $relative = $RelativePath.Replace('\','/').Trim('/')
    $root = $RootRelative.Replace('\','/').Trim('/')
    return $relative.Equals($root,[StringComparison]::OrdinalIgnoreCase) -or $relative.StartsWith($root + '/',[StringComparison]::OrdinalIgnoreCase)
}

function Get-BiologyRecoveryRelative([string]$GameRoot,[string]$FullPath) {
    return [IO.Path]::GetRelativePath([IO.Path]::GetFullPath($GameRoot),[IO.Path]::GetFullPath($FullPath)).Replace('\','/')
}

function Get-BiologyRecoveryParent([string]$RelativePath) {
    $native = $RelativePath.Replace('/',[IO.Path]::DirectorySeparatorChar).Replace('\',[IO.Path]::DirectorySeparatorChar)
    $parent = [IO.Path]::GetDirectoryName($native)
    if ([string]::IsNullOrWhiteSpace($parent)) { return $null }
    return $parent.Replace('\','/').Trim('/')
}

function New-BiologyFailedInstallRecoveryPlan([string]$PackageRoot,[string]$GameRoot,$Manifest) {
    $PackageRoot = [IO.Path]::GetFullPath($PackageRoot)
    $GameRoot = [IO.Path]::GetFullPath($GameRoot)
    if ($Manifest.schemaVersion -ne 2 -or [string]$Manifest.product -ne 'Biology') {
        throw 'Unexpected Biology release ownership manifest for failed-install recovery.'
    }

    $ownedRoots = @('mods/Biology','r6/scripts/CyberpunkRealism','biology')
    $ownedFiles = @{}
    $sharedFiles = @{}
    $knownOwnedDirectories = @{}
    foreach ($root in $ownedRoots) { $knownOwnedDirectories[$root.ToLowerInvariant()] = $root }

    foreach ($file in @($Manifest.files)) {
        $relative = ([string]$file.path).Replace('\','/').TrimStart('/')
        $source = Resolve-BiologyReleaseChild $PackageRoot $relative
        $expected = ([string]$file.sha256).ToUpperInvariant()
        if ($expected -notmatch '^[A-F0-9]{64}$') { throw "Invalid artifact SHA-256 in failed-install recovery manifest: $relative" }
        if (-not (Test-Path -LiteralPath $source -PathType Leaf) -or (Get-BiologyReleaseSha256 $source) -ne $expected) {
            throw "Failed-install recovery artifact payload does not match its receipt: $relative"
        }

        if ([string]$file.replacePolicy -eq 'biology-owned') {
            $key = $relative.ToLowerInvariant()
            if ($ownedFiles.ContainsKey($key)) { throw "Duplicate Biology-owned recovery path: $relative" }
            $ownedFiles[$key] = [pscustomobject]@{ relativePath=$relative; expectedSha256=$expected; receiptFile=$false }

            $parent = Get-BiologyRecoveryParent $relative
            while ($parent) {
                $isOwnedDirectory = $false
                foreach ($root in $ownedRoots) {
                    if (Test-BiologyRecoveryPathUnder $parent $root) { $isOwnedDirectory = $true; break }
                }
                if (-not $isOwnedDirectory) { break }
                $knownOwnedDirectories[$parent.ToLowerInvariant()] = $parent
                $parent = Get-BiologyRecoveryParent $parent
            }
        } elseif ([string]$file.replacePolicy -eq 'generic-dependency-shared') {
            $key = $relative.ToLowerInvariant()
            if ($sharedFiles.ContainsKey($key)) { throw "Duplicate shared recovery path: $relative" }
            $sharedFiles[$key] = [pscustomobject]@{ relativePath=$relative; expectedSha256=$expected }
        } else {
            throw "Unexpected replacePolicy in failed-install recovery artifact: $relative / $($file.replacePolicy)"
        }
    }

    # The ownership receipt cannot list/hash itself. For this exact failed
    # artifact it is recoverable only when byte-identical to the retained ZIP.
    $receiptRelative = 'biology/build-manifest.json'
    $receiptSource = Resolve-BiologyReleaseChild $PackageRoot $receiptRelative
    if (-not (Test-Path -LiteralPath $receiptSource -PathType Leaf)) { throw 'Failed-install recovery artifact ownership receipt is missing.' }
    $receiptHash = Get-BiologyReleaseSha256 $receiptSource
    $ownedFiles[$receiptRelative.ToLowerInvariant()] = [pscustomobject]@{ relativePath=$receiptRelative; expectedSha256=$receiptHash; receiptFile=$true }
    $knownOwnedDirectories['biology'] = 'biology'

    # Inspect the complete Biology-owned roots before allowing any deletion. Any
    # unrecognized file/directory is ambiguous foreign state and stops recovery.
    foreach ($rootRelative in $ownedRoots) {
        $rootFull = Resolve-BiologyReleaseChild $GameRoot $rootRelative
        if (-not (Test-Path -LiteralPath $rootFull)) { continue }
        $rootItem = Get-Item -Force -LiteralPath $rootFull
        if ($rootItem.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "Recovery refuses Biology-owned reparse point: $rootRelative" }
        if (-not $rootItem.PSIsContainer) { throw "Recovery expected Biology-owned directory but found a file: $rootRelative" }

        foreach ($entry in @(Get-ChildItem -Force -LiteralPath $rootFull -Recurse)) {
            if ($entry.Attributes -band [IO.FileAttributes]::ReparsePoint) {
                throw "Recovery refuses reparse point inside Biology-owned root: $(Get-BiologyRecoveryRelative $GameRoot $entry.FullName)"
            }
            $relative = Get-BiologyRecoveryRelative $GameRoot $entry.FullName
            $key = $relative.ToLowerInvariant()
            if ($entry.PSIsContainer) {
                if (-not $knownOwnedDirectories.ContainsKey($key)) {
                    throw "Recovery found an unrecognized directory inside Biology-owned state: $relative"
                }
            } elseif (-not $ownedFiles.ContainsKey($key)) {
                throw "Recovery found foreign/unrecognized content inside Biology-owned state: $relative"
            }
        }
    }

    $filePlan = [Collections.Generic.List[object]]::new()
    foreach ($owned in @($ownedFiles.Values | Sort-Object relativePath)) {
        $destination = Resolve-BiologyReleaseChild $GameRoot ([string]$owned.relativePath)
        $current = Get-BiologyReleaseExistingHash $destination
        if ($null -eq $current) {
            $action = 'absent'
        } elseif ($current -eq [string]$owned.expectedSha256) {
            $action = 'remove-exact'
        } else {
            throw "Recovery refuses changed/ambiguous Biology-owned content: $($owned.relativePath)"
        }
        $filePlan.Add([pscustomobject]@{
            relativePath = [string]$owned.relativePath
            destination = $destination
            expectedSha256 = [string]$owned.expectedSha256
            observedSha256 = $current
            action = $action
            receiptFile = [bool]$owned.receiptFile
        })
    }

    $sharedPlan = [Collections.Generic.List[object]]::new()
    foreach ($shared in @($sharedFiles.Values | Sort-Object relativePath)) {
        $destination = Resolve-BiologyReleaseChild $GameRoot ([string]$shared.relativePath)
        $current = Get-BiologyReleaseExistingHash $destination
        $sharedPlan.Add([pscustomobject]@{
            relativePath = [string]$shared.relativePath
            destination = $destination
            packageSha256 = [string]$shared.expectedSha256
            observedSha256 = $current
            action = 'preserve-shared'
        })
    }

    $directoryPlan = [Collections.Generic.List[object]]::new()
    foreach ($relative in @($knownOwnedDirectories.Values | Sort-Object { ($_ -split '/').Count } -Descending)) {
        $destination = Resolve-BiologyReleaseChild $GameRoot $relative
        if (Test-Path -LiteralPath $destination) {
            $directoryPlan.Add([pscustomobject]@{ relativePath=$relative; destination=$destination; action='remove-if-empty' })
        }
    }

    return [pscustomobject]@{
        gameRoot = $GameRoot
        files = @($filePlan)
        shared = @($sharedPlan)
        directories = @($directoryPlan)
        ownedRoots = $ownedRoots
    }
}

function Invoke-BiologyFailedInstallRecoveryPlan($Plan) {
    # All ambiguity checks happened while creating the complete plan. Recheck
    # exact file identities again immediately before each deletion.
    foreach ($item in @($Plan.files)) {
        if ([string]$item.action -eq 'absent') {
            if (Test-Path -LiteralPath ([string]$item.destination)) {
                throw "Recovery destination appeared after plan: $($item.relativePath)"
            }
            continue
        }
        if ([string]$item.action -ne 'remove-exact') { throw "Unexpected failed-install recovery action: $($item.action)" }
        $current = Get-BiologyReleaseExistingHash ([string]$item.destination)
        if ($current -ne [string]$item.expectedSha256) {
            throw "Recovery destination changed after plan: $($item.relativePath)"
        }
        Remove-Item -LiteralPath ([string]$item.destination) -Force
        if (Test-Path -LiteralPath ([string]$item.destination)) { throw "Recovery could not remove exact Biology-owned file: $($item.relativePath)" }
    }

    # Never mutate generic/shared redscript or cybercmd payload. Verify afterward
    # that recovery itself did not change their observed state.
    foreach ($item in @($Plan.shared)) {
        if ([string]$item.action -ne 'preserve-shared') { throw "Unexpected shared recovery action: $($item.relativePath)" }
        $current = Get-BiologyReleaseExistingHash ([string]$item.destination)
        if ($current -ne $item.observedSha256) {
            throw "Shared dependency changed while failed-install recovery ran: $($item.relativePath)"
        }
    }

    foreach ($directory in @($Plan.directories)) {
        $path = [string]$directory.destination
        if (-not (Test-Path -LiteralPath $path -PathType Container)) { continue }
        $item = Get-Item -Force -LiteralPath $path
        if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "Recovery refuses directory reparse point during cleanup: $($directory.relativePath)" }
        if (@(Get-ChildItem -Force -LiteralPath $path).Count -eq 0) {
            Remove-Item -LiteralPath $path -Force
        }
    }

    foreach ($file in @($Plan.files)) {
        if (Test-Path -LiteralPath ([string]$file.destination)) {
            throw "Biology-owned failed-install residue remains after recovery: $($file.relativePath)"
        }
    }
    foreach ($rootRelative in @($Plan.ownedRoots)) {
        $rootPath = Resolve-BiologyReleaseChild ([string]$Plan.gameRoot) ([string]$rootRelative)
        if (Test-Path -LiteralPath $rootPath) {
            throw "Biology-owned directory remains after failed-install recovery: $rootRelative"
        }
    }
}
