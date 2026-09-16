Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not (Get-Command Resolve-BiologyReleaseChild -ErrorAction SilentlyContinue)) {
    . (Join-Path $PSScriptRoot 'BiologyReleaseInstall.Core.ps1')
}
if (-not (Get-Command Invoke-BiologyFailedInstallRecoveryPlan -ErrorAction SilentlyContinue)) {
    . (Join-Path $PSScriptRoot 'BiologyFailedInstallRecovery.Core.ps1')
}

function Get-BiologyOperatorSha256([string]$Path) {
    return (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToUpperInvariant()
}

function Get-BiologyOperatorTextSha256([string]$Path) {
    $text = [IO.File]::ReadAllText($Path)
    $normalized = $text.Replace("`r`n","`n").Replace("`r","`n")
    $bytes = [Text.UTF8Encoding]::new($false).GetBytes($normalized)
    $sha = [Security.Cryptography.SHA256]::Create()
    try { return ([Convert]::ToHexString($sha.ComputeHash($bytes))).ToUpperInvariant() }
    finally { $sha.Dispose() }
}

function Assert-BiologyOperatorEvidenceId([string]$EvidenceId) {
    if ([string]::IsNullOrWhiteSpace($EvidenceId) -or $EvidenceId -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]{0,119}$') {
        throw "Unsafe Biology operator evidence id: $EvidenceId"
    }
    return $EvidenceId
}

function Get-BiologyOperatorEvidenceRoot([string]$RepoRoot,[string]$EvidenceId) {
    $id = Assert-BiologyOperatorEvidenceId $EvidenceId
    return Resolve-BiologyReleaseChild $RepoRoot ("docs/operator-evidence/$id")
}

function Assert-BiologyOperatorRelativePath([string]$RelativePath) {
    if ([string]::IsNullOrWhiteSpace($RelativePath) -or [IO.Path]::IsPathRooted($RelativePath) -or $RelativePath.Contains(':')) {
        throw "Unsafe Biology operator evidence path: $RelativePath"
    }
    $normalized = $RelativePath.Replace('\','/').TrimStart('/')
    foreach ($part in @($normalized -split '/')) {
        if ($part -in @('','..','.') -or $part -match '[<>"|?*]' -or $part -match '[ .]$' -or $part -match '(?i)^(?:CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])(?:\..*)?$') {
            throw "Unsafe Biology operator evidence path segment: $RelativePath"
        }
    }
    return $normalized
}

function Assert-BiologyOperatorEvidenceRecord($Evidence) {
    if ($null -eq $Evidence) { throw 'Biology operator evidence record is null.' }
    if ([int]$Evidence.schemaVersion -ne 1 -or [string]$Evidence.product -ne 'Biology') {
        throw 'Unexpected Biology operator evidence schema/product.'
    }
    $id = Assert-BiologyOperatorEvidenceId ([string]$Evidence.evidenceId)
    if ([string]::IsNullOrWhiteSpace([string]$Evidence.operation)) { throw 'Biology operator evidence operation is missing.' }
    $source = ([string]$Evidence.sourceRevision).ToLowerInvariant()
    if ($source -notmatch '^[a-f0-9]{40}$') { throw 'Biology operator evidence sourceRevision is invalid.' }
    if ([string]$Evidence.result -notin @('PASS','FAIL-CLOSED','PARTIAL')) { throw 'Biology operator evidence result is invalid.' }

    if ($Evidence.PSObject.Properties.Name -contains 'artifact' -and $null -ne $Evidence.artifact) {
        $artifactHash = ([string]$Evidence.artifact.sha256).ToUpperInvariant()
        if (-not [string]::IsNullOrWhiteSpace($artifactHash) -and $artifactHash -notmatch '^[A-F0-9]{64}$') { throw 'Biology operator evidence artifact SHA-256 is invalid.' }
        if ($Evidence.artifact.PSObject.Properties.Name -contains 'bytes' -and $null -ne $Evidence.artifact.bytes -and [long]$Evidence.artifact.bytes -lt 0) { throw 'Biology operator evidence artifact byte count is invalid.' }
    }

    if ($Evidence.PSObject.Properties.Name -contains 'handoff' -and $null -ne $Evidence.handoff) {
        $reportHash = ([string]$Evidence.handoff.reportSha256).ToUpperInvariant()
        if ($reportHash -notmatch '^[A-F0-9]{64}$') { throw 'Biology operator evidence report SHA-256 is invalid.' }
        if ([string]::IsNullOrWhiteSpace([string]$Evidence.handoff.bundleName) -or [string]$Evidence.handoff.bundleName -match '[\\/]') { throw 'Biology operator evidence bundleName is invalid.' }
    }

    if (-not ($Evidence.PSObject.Properties.Name -contains 'recovery') -or $null -eq $Evidence.recovery) {
        throw 'Biology operator evidence recovery contract is missing.'
    }
    $mode = [string]$Evidence.recovery.mode
    if ($mode -notin @('none','exact-payload-manifest','empty-owned-roots-only')) { throw "Unsupported Biology operator recovery mode: $mode" }

    if ($mode -eq 'exact-payload-manifest') {
        if (-not ($Evidence.PSObject.Properties.Name -contains 'payloadManifest') -or $null -eq $Evidence.payloadManifest) {
            throw 'Exact-payload Biology operator evidence is missing payloadManifest.'
        }
        $manifest = $Evidence.payloadManifest
        if ([int]$manifest.schemaVersion -ne 2 -or [string]$manifest.product -ne 'Biology') { throw 'Operator evidence payload manifest is not Biology schema 2.' }
        if (([string]$manifest.sourceRevision).ToLowerInvariant() -ne $source) { throw 'Operator evidence payload sourceRevision does not match evidence sourceRevision.' }
        $receiptHash = ([string]$Evidence.recovery.receiptSha256).ToUpperInvariant()
        if ($receiptHash -notmatch '^[A-F0-9]{64}$') { throw 'Exact-payload operator evidence receipt SHA-256 is invalid.' }
        $seen = @{}
        foreach ($file in @($manifest.files)) {
            $relative = Assert-BiologyOperatorRelativePath ([string]$file.path)
            $key = $relative.ToLowerInvariant()
            if ($seen.ContainsKey($key)) { throw "Duplicate payload path in operator evidence: $relative" }
            $seen[$key] = $true
            $hash = ([string]$file.sha256).ToUpperInvariant()
            if ($hash -notmatch '^[A-F0-9]{64}$') { throw "Invalid payload hash in operator evidence: $relative" }
            if ([string]$file.replacePolicy -notin @('biology-owned','generic-dependency-shared')) { throw "Unexpected replacePolicy in operator evidence: $relative" }
        }
    }

    if ($mode -eq 'empty-owned-roots-only') {
        $ownedRoots = @($Evidence.recovery.ownedRoots)
        if ($ownedRoots.Count -lt 1) { throw 'Legacy empty-root evidence has no ownedRoots.' }
        foreach ($root in $ownedRoots) { [void](Assert-BiologyOperatorRelativePath ([string]$root)) }
        foreach ($file in @($Evidence.recovery.mustBeAbsentFiles)) { [void](Assert-BiologyOperatorRelativePath ([string]$file)) }
    }

    if ($Evidence.PSObject.Properties.Name -contains 'cleanup' -and $null -ne $Evidence.cleanup) {
        $artifactRootName = [string]$Evidence.cleanup.artifactRootName
        if (-not [string]::IsNullOrWhiteSpace($artifactRootName)) {
            if ($artifactRootName -match '[\\/]' -or -not $artifactRootName.StartsWith('Biology-Candidate-Artifacts-',[StringComparison]::Ordinal)) {
                throw 'Operator evidence cleanup artifactRootName is unsafe.'
            }
        }
    }
    return $id
}

function Get-BiologyEvidenceRecoveryOwnedState($Evidence) {
    [void](Assert-BiologyOperatorEvidenceRecord $Evidence)
    $manifest = $Evidence.payloadManifest
    $ownedRoots = @('mods/Biology','r6/scripts/CyberpunkRealism','biology')
    $ownedFiles = @{}
    $sharedFiles = @{}
    $knownOwnedDirectories = @{}
    foreach ($root in $ownedRoots) { $knownOwnedDirectories[$root.ToLowerInvariant()] = $root }

    foreach ($file in @($manifest.files)) {
        $relative = Assert-BiologyOperatorRelativePath ([string]$file.path)
        $expected = ([string]$file.sha256).ToUpperInvariant()
        if ([string]$file.replacePolicy -eq 'biology-owned') {
            $ownedFiles[$relative.ToLowerInvariant()] = [pscustomobject]@{ relativePath=$relative; expectedSha256=$expected; receiptFile=$false }
            $parent = Get-BiologyRecoveryParent $relative
            while ($parent) {
                $under = $false
                foreach ($root in $ownedRoots) { if (Test-BiologyRecoveryPathUnder $parent $root) { $under = $true; break } }
                if (-not $under) { break }
                $knownOwnedDirectories[$parent.ToLowerInvariant()] = $parent
                $parent = Get-BiologyRecoveryParent $parent
            }
        } else {
            $sharedFiles[$relative.ToLowerInvariant()] = [pscustomobject]@{ relativePath=$relative; expectedSha256=$expected }
        }
    }

    $receiptRelative = 'biology/build-manifest.json'
    $ownedFiles[$receiptRelative.ToLowerInvariant()] = [pscustomobject]@{ relativePath=$receiptRelative; expectedSha256=([string]$Evidence.recovery.receiptSha256).ToUpperInvariant(); receiptFile=$true }
    $knownOwnedDirectories['biology'] = 'biology'

    return [pscustomobject]@{ ownedRoots=$ownedRoots; ownedFiles=$ownedFiles; sharedFiles=$sharedFiles; knownOwnedDirectories=$knownOwnedDirectories }
}

function New-BiologyEvidenceBackedFailedInstallRecoveryPlan([string]$GameRoot,$Evidence) {
    [void](Assert-BiologyOperatorEvidenceRecord $Evidence)
    if ([string]$Evidence.recovery.mode -ne 'exact-payload-manifest' -or -not [bool]$Evidence.recovery.eligible) {
        throw 'Operator evidence is not eligible for exact-payload failed-install recovery.'
    }
    $GameRoot = [IO.Path]::GetFullPath($GameRoot)
    $state = Get-BiologyEvidenceRecoveryOwnedState $Evidence

    foreach ($rootRelative in @($state.ownedRoots)) {
        $rootFull = Resolve-BiologyReleaseChild $GameRoot $rootRelative
        if (-not (Test-Path -LiteralPath $rootFull)) { continue }
        $rootItem = Get-Item -Force -LiteralPath $rootFull
        if ($rootItem.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "Recovery refuses Biology-owned reparse point: $rootRelative" }
        if (-not $rootItem.PSIsContainer) { throw "Recovery expected Biology-owned directory but found a file: $rootRelative" }
        foreach ($entry in @(Get-ChildItem -Force -LiteralPath $rootFull -Recurse)) {
            if ($entry.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "Recovery refuses reparse point inside Biology-owned root: $(Get-BiologyRecoveryRelative $GameRoot $entry.FullName)" }
            $relative = Get-BiologyRecoveryRelative $GameRoot $entry.FullName
            $key = $relative.ToLowerInvariant()
            if ($entry.PSIsContainer) {
                if (-not $state.knownOwnedDirectories.ContainsKey($key)) { throw "Recovery found an unrecognized directory inside Biology-owned state: $relative" }
            } elseif (-not $state.ownedFiles.ContainsKey($key)) {
                throw "Recovery found foreign/unrecognized content inside Biology-owned state: $relative"
            }
        }
    }

    $filePlan = [Collections.Generic.List[object]]::new()
    foreach ($owned in @($state.ownedFiles.Values | Sort-Object relativePath)) {
        $destination = Resolve-BiologyReleaseChild $GameRoot ([string]$owned.relativePath)
        $current = Get-BiologyReleaseExistingHash $destination
        if ($null -eq $current) { $action = 'absent' }
        elseif ($current -eq [string]$owned.expectedSha256) { $action = 'remove-exact' }
        else { throw "Recovery refuses changed/ambiguous Biology-owned content: $($owned.relativePath)" }
        $filePlan.Add([pscustomobject]@{ relativePath=[string]$owned.relativePath; destination=$destination; expectedSha256=[string]$owned.expectedSha256; observedSha256=$current; action=$action; receiptFile=[bool]$owned.receiptFile })
    }

    $sharedPlan = [Collections.Generic.List[object]]::new()
    foreach ($shared in @($state.sharedFiles.Values | Sort-Object relativePath)) {
        $destination = Resolve-BiologyReleaseChild $GameRoot ([string]$shared.relativePath)
        $sharedPlan.Add([pscustomobject]@{ relativePath=[string]$shared.relativePath; destination=$destination; packageSha256=[string]$shared.expectedSha256; observedSha256=(Get-BiologyReleaseExistingHash $destination); action='preserve-shared' })
    }

    $directoryPlan = [Collections.Generic.List[object]]::new()
    foreach ($relative in @($state.knownOwnedDirectories.Values | Sort-Object { ($_ -split '/').Count } -Descending)) {
        $destination = Resolve-BiologyReleaseChild $GameRoot $relative
        if (Test-Path -LiteralPath $destination) { $directoryPlan.Add([pscustomobject]@{ relativePath=$relative; destination=$destination; action='remove-if-empty' }) }
    }
    return [pscustomobject]@{ gameRoot=$GameRoot; files=@($filePlan); shared=@($sharedPlan); directories=@($directoryPlan); ownedRoots=@($state.ownedRoots) }
}

function New-BiologyLegacyEmptyFailedInstallRecoveryPlan([string]$GameRoot,$Evidence) {
    [void](Assert-BiologyOperatorEvidenceRecord $Evidence)
    if ([string]$Evidence.recovery.mode -ne 'empty-owned-roots-only' -or -not [bool]$Evidence.recovery.eligible) {
        throw 'Operator evidence is not eligible for legacy empty-owned-root recovery.'
    }
    $GameRoot = [IO.Path]::GetFullPath($GameRoot)
    foreach ($relative in @($Evidence.recovery.mustBeAbsentFiles)) {
        $path = Resolve-BiologyReleaseChild $GameRoot (Assert-BiologyOperatorRelativePath ([string]$relative))
        if (Test-Path -LiteralPath $path) { throw "Legacy recovery found ambiguous Biology-owned file and refuses deletion: $relative" }
    }

    $directories = [Collections.Generic.List[object]]::new()
    foreach ($relative in @($Evidence.recovery.ownedRoots)) {
        $normalized = Assert-BiologyOperatorRelativePath ([string]$relative)
        $path = Resolve-BiologyReleaseChild $GameRoot $normalized
        if (-not (Test-Path -LiteralPath $path)) { continue }
        $item = Get-Item -Force -LiteralPath $path
        if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "Legacy recovery refuses Biology-owned reparse point: $normalized" }
        if (-not $item.PSIsContainer) { throw "Legacy recovery expected Biology-owned directory but found a file: $normalized" }
        if (@(Get-ChildItem -Force -LiteralPath $path).Count -ne 0) {
            throw "Legacy recovery refuses non-empty Biology-owned root without exact payload evidence: $normalized"
        }
        $directories.Add([pscustomobject]@{ relativePath=$normalized; destination=$path; action='remove-if-empty' })
    }
    return [pscustomobject]@{ gameRoot=$GameRoot; files=@(); shared=@(); directories=@($directories); ownedRoots=@($Evidence.recovery.ownedRoots) }
}

function Test-BiologyOperatorEvidenceBundleAgainstRepository([string]$BundlePath,[string]$RepositoryEvidenceRoot) {
    if (-not (Test-Path -LiteralPath $BundlePath -PathType Leaf)) { throw 'Operator evidence handoff bundle does not exist.' }
    $repoEvidence = Join-Path $RepositoryEvidenceRoot 'evidence.json'
    $repoReport = Join-Path $RepositoryEvidenceRoot 'report.txt'
    foreach ($required in @($repoEvidence,$repoReport)) { if (-not (Test-Path -LiteralPath $required -PathType Leaf)) { throw "Durable repository evidence is incomplete: $required" } }

    $temp = Join-Path ([IO.Path]::GetTempPath()) ('biology-evidence-bundle-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Force -Path $temp | Out-Null
    try {
        Expand-Archive -LiteralPath $BundlePath -DestinationPath $temp
        $files = @(Get-ChildItem -LiteralPath $temp -Recurse -File -Force)
        if ($files.Count -ne 2) { throw "Operator evidence bundle must contain exactly evidence.json and report.txt; found $($files.Count) files." }
        $localEvidence = Join-Path $temp 'evidence.json'
        $localReport = Join-Path $temp 'report.txt'
        foreach ($required in @($localEvidence,$localReport)) { if (-not (Test-Path -LiteralPath $required -PathType Leaf)) { throw 'Operator evidence bundle has an unexpected layout.' } }
        if ((Get-BiologyOperatorTextSha256 $localEvidence) -ne (Get-BiologyOperatorTextSha256 $repoEvidence)) { throw 'Local evidence.json does not exactly match durable repository evidence after newline normalization.' }
        if ((Get-BiologyOperatorTextSha256 $localReport) -ne (Get-BiologyOperatorTextSha256 $repoReport)) { throw 'Local report.txt does not exactly match durable repository evidence after newline normalization.' }
        $record = Get-Content -Raw -LiteralPath $localEvidence | ConvertFrom-Json
        [void](Assert-BiologyOperatorEvidenceRecord $record)
        if ((Get-BiologyOperatorTextSha256 $localReport) -ne ([string]$record.handoff.reportSha256).ToUpperInvariant()) { throw 'Local operator report hash does not match its evidence record.' }
        return $record
    } finally {
        if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Recurse -Force }
    }
}

function Remove-BiologyManagedArtifactRoot([string]$GamesRoot,$Evidence) {
    [void](Assert-BiologyOperatorEvidenceRecord $Evidence)
    $rootName = [string]$Evidence.cleanup.artifactRootName
    if ([string]::IsNullOrWhiteSpace($rootName)) { return $false }
    $GamesRoot = [IO.Path]::GetFullPath($GamesRoot).TrimEnd('\','/')
    $artifactRoot = [IO.Path]::GetFullPath((Join-Path $GamesRoot $rootName))
    if (-not $artifactRoot.StartsWith($GamesRoot + [IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)) { throw 'Managed artifact root escapes GamesRoot.' }
    if (-not (Test-Path -LiteralPath $artifactRoot)) { return $false }
    $rootItem = Get-Item -Force -LiteralPath $artifactRoot
    if ($rootItem.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Managed artifact root is a reparse point.' }
    if (-not $rootItem.PSIsContainer) { throw 'Managed artifact root is not a directory.' }

    if ([string]$Evidence.recovery.mode -ne 'exact-payload-manifest') { throw 'Managed artifact cleanup requires exact payload manifest evidence.' }
    $expectedFiles = @{}
    $expectedRelativePaths = @{}
    $zipName = [string]$Evidence.cleanup.artifactZipName
    $packageRootName = [string]$Evidence.cleanup.packageRootName
    if ([string]::IsNullOrWhiteSpace($zipName) -or $zipName -match '[\\/]' -or [string]::IsNullOrWhiteSpace($packageRootName) -or $packageRootName -match '[\\/]') { throw 'Managed artifact cleanup metadata is incomplete.' }
    $zipKey = $zipName.ToLowerInvariant()
    $expectedFiles[$zipKey] = ([string]$Evidence.artifact.sha256).ToUpperInvariant()
    $expectedRelativePaths[$zipKey] = $zipName
    foreach ($file in @($Evidence.payloadManifest.files)) {
        $relative = Assert-BiologyOperatorRelativePath ([string]$file.path)
        $artifactRelative = $packageRootName + '/' + $relative
        $key = $artifactRelative.ToLowerInvariant()
        $expectedFiles[$key] = ([string]$file.sha256).ToUpperInvariant()
        $expectedRelativePaths[$key] = $artifactRelative
    }
    $receiptRelative = $packageRootName + '/biology/build-manifest.json'
    $receiptKey = $receiptRelative.ToLowerInvariant()
    $expectedFiles[$receiptKey] = ([string]$Evidence.recovery.receiptSha256).ToUpperInvariant()
    $expectedRelativePaths[$receiptKey] = $receiptRelative

    $allowedDirectories = @{}
    foreach ($relative in @($expectedRelativePaths.Values)) {
        $parent = Get-BiologyRecoveryParent $relative
        while ($parent) { $allowedDirectories[$parent.ToLowerInvariant()] = $true; $parent = Get-BiologyRecoveryParent $parent }
    }
    foreach ($entry in @(Get-ChildItem -Force -LiteralPath $artifactRoot -Recurse)) {
        if ($entry.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "Managed artifact cleanup refuses reparse point: $($entry.FullName)" }
        $relative = [IO.Path]::GetRelativePath($artifactRoot,$entry.FullName).Replace('\','/')
        $key = $relative.ToLowerInvariant()
        if ($entry.PSIsContainer) {
            if (-not $allowedDirectories.ContainsKey($key)) { throw "Managed artifact cleanup found foreign directory: $relative" }
        } else {
            if (-not $expectedFiles.ContainsKey($key)) { throw "Managed artifact cleanup found foreign file: $relative" }
            if ((Get-BiologyOperatorSha256 $entry.FullName) -ne $expectedFiles[$key]) { throw "Managed artifact cleanup found changed file: $relative" }
        }
    }
    foreach ($key in @($expectedFiles.Keys)) {
        $relative = [string]$expectedRelativePaths[$key]
        $expectedPath = Resolve-BiologyReleaseChild $artifactRoot $relative
        if (-not (Test-Path -LiteralPath $expectedPath -PathType Leaf)) {
            throw "Managed artifact cleanup is missing expected file: $relative"
        }
    }
    Remove-Item -LiteralPath $artifactRoot -Recurse -Force
    if (Test-Path -LiteralPath $artifactRoot) { throw 'Managed artifact root remained after cleanup.' }
    return $true
}
