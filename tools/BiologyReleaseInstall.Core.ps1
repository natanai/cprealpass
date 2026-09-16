Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Resolve-BiologyReleaseChild([string]$Root,[string]$RelativePath) {
    if ([string]::IsNullOrWhiteSpace($RelativePath) -or [IO.Path]::IsPathRooted($RelativePath) -or $RelativePath.Contains(':')) {
        throw "Expected ordinary relative package path: $RelativePath"
    }
    $parts = $RelativePath -split '[\\/]'
    foreach ($part in $parts) {
        if ($part -in @('','..','.') -or $part -match '[<>"|?*]' -or $part -match '[ .]$' -or $part -match '^(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])(\.|$)') {
            throw "Unsafe package path segment: $RelativePath"
        }
    }
    $rootFull = [IO.Path]::GetFullPath($Root).TrimEnd('\','/')
    $candidate = [IO.Path]::GetFullPath((Join-Path $rootFull $RelativePath))
    if (-not $candidate.StartsWith($rootFull + [IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)) {
        throw "Package path escapes root: $RelativePath"
    }
    $probe = $candidate
    while ($probe) {
        if (Test-Path -LiteralPath $probe) {
            if ((Get-Item -Force -LiteralPath $probe).Attributes -band [IO.FileAttributes]::ReparsePoint) {
                throw "Reparse points are not supported in Biology release install paths: $probe"
            }
        }
        $next = Split-Path -Parent $probe
        if ($next -eq $probe) { break }
        $probe = $next
    }
    return $candidate
}

function Get-BiologyReleaseSha256([string]$Path) {
    return (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToUpperInvariant()
}

function Get-BiologyReleaseExistingHash([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) { return $null }
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "Expected ordinary file at install destination: $Path" }
    return Get-BiologyReleaseSha256 $Path
}

function Copy-BiologyReleaseVerified([string]$Source,[string]$Destination,[string]$ExpectedHash) {
    if ((Get-BiologyReleaseSha256 $Source) -ne $ExpectedHash) { throw "Package source changed before copy: $Source" }
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Destination) | Out-Null
    $temporary = $Destination + '.biology-install-' + [guid]::NewGuid().ToString('N') + '.tmp'
    try {
        Copy-Item -LiteralPath $Source -Destination $temporary
        if ((Get-BiologyReleaseSha256 $temporary) -ne $ExpectedHash) { throw "Temporary install copy failed SHA-256 verification: $Destination" }
        [IO.File]::Replace($temporary,$Destination,$null,$true)
    } catch [IO.FileNotFoundException] {
        if (Test-Path -LiteralPath $Destination) { throw }
        Move-Item -LiteralPath $temporary -Destination $Destination
    } finally {
        if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary -Force }
    }
}

function New-BiologyReleaseInstallPlan([string]$PackageRoot,[string]$GameRoot,$Manifest) {
    $PackageRoot = [IO.Path]::GetFullPath($PackageRoot)
    $GameRoot = [IO.Path]::GetFullPath($GameRoot)
    if ($Manifest.schemaVersion -ne 2 -or [string]$Manifest.product -ne 'Biology') { throw 'Unexpected Biology release ownership manifest.' }

    $protectedStandaloneLoaderPaths = @{
        'bin/x64/global.ini' = $true
        'bin/x64/version.dll' = $true
    }
    $replaceableStandalonePath = 'bin/x64/plugins/cybercmd.asi'
    $seen = @{}
    $plan = [Collections.Generic.List[object]]::new()

    foreach ($file in @($Manifest.files)) {
        $relative = ([string]$file.path).Replace('\','/').TrimStart('/')
        $source = Resolve-BiologyReleaseChild $PackageRoot $relative
        $destination = Resolve-BiologyReleaseChild $GameRoot $relative
        if ($seen.ContainsKey($destination)) { throw "Duplicate release destination: $relative" }
        $seen[$destination] = $true
        $expected = ([string]$file.sha256).ToUpperInvariant()
        if ($expected -notmatch '^[A-F0-9]{64}$') { throw "Invalid release SHA-256 in ownership manifest: $relative" }
        if (-not (Test-Path -LiteralPath $source -PathType Leaf) -or (Get-BiologyReleaseSha256 $source) -ne $expected) {
            throw "Release payload hash mismatch before install: $relative"
        }

        $prior = Get-BiologyReleaseExistingHash $destination
        $action = if ($prior -eq $expected) { 'preserve' } elseif ($null -ne $prior) { 'replace' } else { 'create' }
        $isProtectedLoader = $protectedStandaloneLoaderPaths.ContainsKey($relative.ToLowerInvariant())
        $isCybercmdAsi = $relative.Equals($replaceableStandalonePath,[StringComparison]::OrdinalIgnoreCase)

        if ($isProtectedLoader -and $action -eq 'replace') {
            throw "Shared standalone cybercmd loader/config collision at '$relative'. Biology will not overwrite an existing non-identical file. Preserve the existing compatible loader/config or reconcile it manually before install. No game files were changed."
        }
        if ([string]$file.component -eq 'cybercmd' -and $action -eq 'replace' -and -not $isCybercmdAsi) {
            throw "Standalone cybercmd collision is not replaceable by Biology: $relative. Only bin/x64/plugins/cybercmd.asi may be replaced. No game files were changed."
        }

        $plan.Add([pscustomobject]@{
            relativePath = $relative
            source = $source
            destination = $destination
            component = [string]$file.component
            replacePolicy = [string]$file.replacePolicy
            priorSha256 = $prior
            deployedSha256 = $expected
            action = $action
            protectedSharedLoader = $isProtectedLoader
            cybercmdReplaceable = $isCybercmdAsi
        })
    }
    return @($plan)
}

function Invoke-BiologyReleaseInstallPlan([object[]]$Plan) {
    foreach ($item in @($Plan)) {
        $current = Get-BiologyReleaseExistingHash ([string]$item.destination)
        if ($current -ne $item.priorSha256) {
            throw "Install destination changed after preflight: $($item.relativePath)"
        }
        if ([string]$item.action -eq 'preserve') { continue }
        if ([bool]$item.protectedSharedLoader -and [string]$item.action -eq 'replace') {
            throw "Protected shared loader/config reached an impossible replace action: $($item.relativePath)"
        }
        if ([string]$item.component -eq 'cybercmd' -and [string]$item.action -eq 'replace' -and -not [bool]$item.cybercmdReplaceable) {
            throw "Only cybercmd.asi may be replaced by the standalone cybercmd install path: $($item.relativePath)"
        }
        Copy-BiologyReleaseVerified ([string]$item.source) ([string]$item.destination) ([string]$item.deployedSha256)
        if ((Get-BiologyReleaseExistingHash ([string]$item.destination)) -ne [string]$item.deployedSha256) {
            throw "Post-install SHA-256 verification failed: $($item.relativePath)"
        }
    }
}