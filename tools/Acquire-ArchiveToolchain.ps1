#requires -Version 7.0
param(
    [string]$ConfigPath = 'config/archive-toolchain.json',
    [string]$CacheRoot = '',
    [switch]$Offline
)
. "$PSScriptRoot/Common.ps1"
$project = Get-ProjectRoot
$configPathFull = Resolve-SafeChildPath $project $ConfigPath
$cacheRootFull = $null
if (-not [string]::IsNullOrWhiteSpace($CacheRoot)) {
    if (-not [IO.Path]::IsPathRooted($CacheRoot)) { throw 'CacheRoot must be an absolute path when provided.' }
    $cacheRootFull = [IO.Path]::GetFullPath($CacheRoot).TrimEnd('\','/')
    New-Item -ItemType Directory -Force -Path $cacheRootFull | Out-Null
    if ((Get-Item -Force -LiteralPath $cacheRootFull).Attributes -band [IO.FileAttributes]::ReparsePoint) {
        throw 'Tool cache root may not be a reparse point.'
    }
}
$configHash = Get-Sha256 $configPathFull
$config = Get-Content -Raw -LiteralPath $configPathFull | ConvertFrom-Json
if ($config.schemaVersion -ne 1 -or $config.id -ne 'realpass-portable-archive-tools-v1' -or $config.platform -ne 'win-x64' -or @($config.tools).Count -ne 2) {
    throw 'Unsupported portable archive-toolchain configuration.'
}
if (-not $IsWindows -or [Runtime.InteropServices.RuntimeInformation]::OSArchitecture -ne [Runtime.InteropServices.Architecture]::X64) {
    throw 'This pinned portable toolchain requires Windows x64.'
}

function Get-ArchiveStreamHash([IO.Stream]$Stream, [string]$Algorithm) {
    $hasher = switch ($Algorithm) {
        'SHA256' { [Security.Cryptography.SHA256]::Create() }
        'SHA512' { [Security.Cryptography.SHA512]::Create() }
        default { throw 'Unsupported archive hash algorithm.' }
    }
    try { [Convert]::ToHexString($hasher.ComputeHash($Stream)) } finally { $hasher.Dispose() }
}

function Get-ValidatedArchiveInventory($Zip, [string]$ExtractRoot, $Pin) {
    $seenEntries = @{}
    $fileNames = @{}
    $directories = @{}
    $files = [Collections.Generic.List[object]]::new()
    [long]$uncompressedBytes = 0
    if ($Zip.Entries.Count -gt 10000) { throw 'Unexpected archive entry count.' }
    foreach ($entry in $Zip.Entries) {
        $name = $entry.FullName.Replace('\','/')
        if ($name -match '[\x00-\x1F\x7F]') { throw 'Control characters in archive paths are unsupported.' }
        $isDirectory = $name.EndsWith('/')
        if ($isDirectory) { $name = $name.TrimEnd('/') }
        $resolved = Resolve-SafeChildPath $ExtractRoot $name
        if ($seenEntries.ContainsKey($name)) { throw "Duplicate archive entry: $name" }
        $seenEntries[$name] = $true
        $unixType = ([long]$entry.ExternalAttributes -shr 16) -band 61440
        if ($unixType -notin @(0,16384,32768) -or ([long]$entry.ExternalAttributes -band 1024)) {
            throw "Archive links/special files are unsupported: $name"
        }
        if (($unixType -eq 16384 -and -not $isDirectory) -or ($unixType -eq 32768 -and $isDirectory)) {
            throw "Inconsistent archive entry type: $name"
        }
        $parts = $name.Split('/')
        for ($part = 1; $part -lt $parts.Length; $part++) {
            $parent = ($parts[0..($part-1)] -join '/')
            if ($fileNames.ContainsKey($parent)) { throw "Archive file is also a parent directory: $parent" }
            $directories[$parent] = $true
        }
        if ($isDirectory) {
            if ($entry.Length -ne 0 -or $fileNames.ContainsKey($name)) { throw "Invalid archive directory: $name" }
            $directories[$name] = $true
            continue
        }
        if ($directories.ContainsKey($name) -or $entry.Length -lt 0) { throw "Archive file/directory collision: $name" }
        $fileNames[$name] = $true
        $uncompressedBytes += $entry.Length
        if ($uncompressedBytes -gt [long]$Pin.uncompressedBytes) { throw 'Archive exceeds pinned uncompressed size.' }
        $stream = $entry.Open()
        try { $hash = Get-ArchiveStreamHash $stream 'SHA256' } finally { $stream.Dispose() }
        $files.Add([pscustomobject]@{path=$name;archiveEntry=$entry.FullName;length=$entry.Length;sha256=$hash})
    }
    if ($files.Count -ne [int]$Pin.fileCount -or $uncompressedBytes -ne [long]$Pin.uncompressedBytes) {
        throw 'Archive file count or uncompressed size differs from the pin.'
    }
    $entryPoints = @($files | Where-Object path -eq $Pin.entryPoint)
    if ($entryPoints.Count -ne 1 -or $entryPoints[0].sha256 -ne $Pin.entryPointSha256) {
        throw 'Archive entry point differs from the pinned executable or DLL.'
    }
    [pscustomobject]@{files=$files.ToArray();directories=$directories;uncompressedBytes=$uncompressedBytes}
}

function Assert-ArchiveTree([string]$Root, $Inventory) {
    if (-not (Test-Path -LiteralPath $Root -PathType Container)) { throw "Expected extracted tool directory: $Root" }
    $expectedFiles = @{}
    foreach ($file in $Inventory.files) { $expectedFiles[$file.path] = $file }
    $pending = [Collections.Generic.Stack[string]]::new()
    $pending.Push($Root)
    $actualFiles = 0
    while ($pending.Count -gt 0) {
        $directory = $pending.Pop()
        foreach ($item in Get-ChildItem -LiteralPath $directory -Force) {
            $relative = [IO.Path]::GetRelativePath($Root,$item.FullName).Replace('\','/')
            $safePath = Resolve-SafeChildPath $Root $relative
            if ($item.PSIsContainer) {
                if (-not $Inventory.directories.ContainsKey($relative)) { throw "Unindexed directory in tool cache: $relative" }
                $pending.Push($safePath)
            } else {
                if (-not $expectedFiles.ContainsKey($relative)) { throw "Unindexed file in tool cache: $relative" }
                $file = $expectedFiles[$relative]
                if ($item.Length -ne $file.length -or (Get-Sha256 $safePath) -ne $file.sha256) {
                    throw "Extracted tool cache differs from its verified ZIP: $relative"
                }
                $actualFiles++
            }
        }
    }
    if ($actualFiles -ne $expectedFiles.Count) { throw 'Extracted tool cache is incomplete; do not run it.' }
}

$validatedPins = @()
$ids = @{}
$roots = @{}
foreach ($pin in $config.tools) {
    if ($pin.id -notin @('wolvenkit-cli','dotnet-runtime') -or $ids.ContainsKey($pin.id) -or $pin.version -notmatch '^\d+\.\d+\.\d+$') { throw 'Unexpected or duplicate archive tool pin.' }
    $ids[$pin.id] = $true
    $uri = [uri]$pin.assetUrl
    $expectedHost = if ($pin.id -eq 'wolvenkit-cli') { 'github.com' } else { 'builds.dotnet.microsoft.com' }
    if ($uri.Scheme -ne 'https' -or $uri.Host -ne $expectedHost -or $uri.UserInfo -or $uri.Query -or $uri.Fragment) { throw 'Tool downloads require a pinned official HTTPS release asset.' }
    if ($pin.hashAlgorithm -notin @('SHA256','SHA512')) { throw 'Invalid archive checksum algorithm.' }
    $hashLength = if ($pin.hashAlgorithm -eq 'SHA512') { 128 } else { 64 }
    if ($pin.archiveHash -notmatch ('^[A-Fa-f0-9]{'+$hashLength+'}$') -or $pin.entryPointSha256 -notmatch '^[A-Fa-f0-9]{64}$') { throw 'Invalid pinned checksum.' }
    if ($pin.archivePath -notmatch '^vendor[\\/]' -or $pin.extractRoot -notmatch '^vendor[\\/]' -or [IO.Path]::GetExtension($pin.archivePath) -ne '.zip') { throw 'Portable archive tools must remain inside the workspace vendor directory.' }
    if ($cacheRootFull) {
        $archiveRelative = ($pin.archivePath -replace '^[Vv][Ee][Nn][Dd][Oo][Rr][\\/]+','')
        $extractRelative = ($pin.extractRoot -replace '^[Vv][Ee][Nn][Dd][Oo][Rr][\\/]+','')
        if ($archiveRelative -eq $pin.archivePath -or $extractRelative -eq $pin.extractRoot) { throw 'Pinned tool paths must remain vendor-relative before cache remapping.' }
        $archivePath = Resolve-SafeChildPath $cacheRootFull $archiveRelative
        $extractRoot = Resolve-SafeChildPath $cacheRootFull $extractRelative
    } else {
        $archivePath = Resolve-SafeChildPath $project $pin.archivePath
        $extractRoot = Resolve-SafeChildPath $project $pin.extractRoot
    }
    $entryPoint = Resolve-SafeChildPath $extractRoot $pin.entryPoint
    if ($archivePath.StartsWith($extractRoot+'\',[StringComparison]::OrdinalIgnoreCase)) { throw 'Tool ZIP must be outside its extracted tree.' }
    if ($roots.ContainsKey($extractRoot) -or $roots.ContainsKey($archivePath)) { throw 'Colliding portable-tool paths.' }
    $roots[$extractRoot] = $true
    $roots[$archivePath] = $true
    if ([long]$pin.archiveBytes -le 0 -or [long]$pin.archiveBytes -gt 1073741824 -or [int]$pin.fileCount -le 0 -or [int]$pin.fileCount -gt 10000 -or [long]$pin.uncompressedBytes -le 0 -or [long]$pin.uncompressedBytes -gt 2147483648) { throw 'Invalid archive size/count pin.' }
    $validatedPins += [pscustomobject]@{pin=$pin;uri=$uri;archivePath=$archivePath;extractRoot=$extractRoot;entryPoint=$entryPoint}
}
# Reject overlapping trees before acquiring or publishing any artifacts.
for ($a=0;$a -lt $validatedPins.Count;$a++) {
    for ($b=0;$b -lt $validatedPins.Count;$b++) {
        if ($a -eq $b) { continue }
        if ($validatedPins[$a].extractRoot.StartsWith($validatedPins[$b].extractRoot+'\',[StringComparison]::OrdinalIgnoreCase) -or $validatedPins[$a].archivePath.StartsWith($validatedPins[$b].extractRoot+'\',[StringComparison]::OrdinalIgnoreCase)) {
            throw 'Portable tool roots and ZIP paths must not overlap.'
        }
    }
}
$verified = @()
foreach ($tool in $validatedPins) {
    $pin = $tool.pin
    $archivePath = $tool.archivePath
    $extractRoot = $tool.extractRoot
    $downloaded = $false
    $extracted = $false
    if (-not (Test-Path -LiteralPath $archivePath)) {
        if ($Offline) { throw "Pinned ZIP missing in offline mode: $($pin.archivePath)" }
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $archivePath) | Out-Null
        $temporary = $archivePath+'.'+[guid]::NewGuid().ToString('N')+'.partial'
        try {
            Write-Host "Downloading portable $($pin.id) $($pin.version)..."
            Invoke-WebRequest -Uri $tool.uri -OutFile $temporary -TimeoutSec 120 -MaximumRedirection 5
            if ((Get-Item -LiteralPath $temporary).Length -ne [long]$pin.archiveBytes -or (Get-FileHash -LiteralPath $temporary -Algorithm $pin.hashAlgorithm).Hash -ne $pin.archiveHash) { throw 'Downloaded tool ZIP failed its pinned checksum/length.' }
            [IO.File]::Move($temporary,$archivePath,$false)
            $downloaded = $true
        } finally { if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary } }
    }
    # Hold a read-only handle throughout checksum, inventory and extraction; a second writer
    # cannot replace the verified archive between those operations.
    $archiveStream = [IO.File]::Open($archivePath,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::Read)
    $zip = $null
    try {
        if ($archiveStream.Length -ne [long]$pin.archiveBytes -or (Get-ArchiveStreamHash $archiveStream $pin.hashAlgorithm) -ne $pin.archiveHash) { throw "Cached tool ZIP checksum/length differs: $($pin.id)" }
        $archiveStream.Position = 0
        $zip = [IO.Compression.ZipArchive]::new($archiveStream,[IO.Compression.ZipArchiveMode]::Read,$true)
        $inventory = Get-ValidatedArchiveInventory $zip $extractRoot $pin
        if (-not (Test-Path -LiteralPath $extractRoot)) {
            $stageBase = if ($cacheRootFull) { $cacheRootFull } else { $project }
            $stageRelative = if ($cacheRootFull) {
                $extractRelative+'.extract-'+[guid]::NewGuid().ToString('N')
            } else {
                $pin.extractRoot+'.extract-'+[guid]::NewGuid().ToString('N')
            }
            $stage = Resolve-SafeChildPath $stageBase $stageRelative
            New-Item -ItemType Directory -Path $stage | Out-Null
            try {
                foreach ($directory in $inventory.directories.Keys) {
                    New-Item -ItemType Directory -Force -Path (Resolve-SafeChildPath $stage $directory) | Out-Null
                }
                foreach ($file in $inventory.files) {
                    $target = Resolve-SafeChildPath $stage $file.path
                    $inputStream = $zip.GetEntry($file.archiveEntry).Open()
                    try {
                        $outputStream = [IO.File]::Open($target,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
                        try { $inputStream.CopyTo($outputStream); $outputStream.Flush($true) } finally { $outputStream.Dispose() }
                    } finally { $inputStream.Dispose() }
                }
                Assert-ArchiveTree $stage $inventory
                $checkedStage = Resolve-SafeChildPath $stageBase $stageRelative
                $checkedTarget = $extractRoot
                [IO.Directory]::Move($checkedStage,$checkedTarget)
                $extracted = $true
            } finally {
                if (Test-Path -LiteralPath $stage) {
                    # This unique private staging tree was created by this invocation.
                    $checkedStage = Resolve-SafeChildPath $stageBase $stageRelative
                    if ($checkedStage -ne $stage -or $stageRelative -notmatch '\.extract-[a-f0-9]{32}$') { throw 'Refusing unsafe staging cleanup.' }
                    Remove-Item -LiteralPath $checkedStage -Recurse
                }
            }
        }
        Assert-ArchiveTree $extractRoot $inventory
        $verified += [pscustomobject]@{id=$pin.id;version=$pin.version;archivePath=$archivePath;archiveHashAlgorithm=$pin.hashAlgorithm;archiveHash=$pin.archiveHash;extractRoot=$extractRoot;entryPoint=$tool.entryPoint;entryPointSha256=$pin.entryPointSha256;fileCount=$inventory.files.Count;uncompressedBytes=$inventory.uncompressedBytes;downloaded=$downloaded;extracted=$extracted;files=$inventory.files}
        Write-Host "Verified portable $($pin.id) $($pin.version): $($inventory.files.Count) files match the pinned ZIP."
    } finally {
        if ($null -ne $zip) { $zip.Dispose() }
        $archiveStream.Dispose()
    }
}
if ((Get-Sha256 $configPathFull) -ne $configHash) { throw 'Toolchain configuration changed during acquisition.' }
$reportPath = Resolve-SafeChildPath $project 'reports/archive-toolchain.json'
Write-JsonFile ([ordered]@{
    schemaVersion=1
    verifiedAtUtc=[DateTime]::UtcNow.ToString('o')
    configuration=$ConfigPath
    configurationSha256=$configHash
    verified=$true
    offline=[bool]$Offline
    runtimeExecuted=$false
    machineEnvironmentChanged=$false
    cacheRoot=$cacheRootFull
    cacheMode=$(if($cacheRootFull){'persistent-external'}else{'workspace-vendor'})
    tools=$verified
}) $reportPath
$dotnet = @($verified | Where-Object id -eq 'dotnet-runtime')[0]
$cli = @($verified | Where-Object id -eq 'wolvenkit-cli')[0]
[pscustomobject]@{dotnetExe=$dotnet.entryPoint;cliDll=$cli.entryPoint;reportPath=$reportPath;dotnetExeSha256=$dotnet.entryPointSha256;cliDllSha256=$cli.entryPointSha256}
