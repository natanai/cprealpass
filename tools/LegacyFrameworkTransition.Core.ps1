Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function ConvertTo-LegacyRelativePath([string]$Root, [string]$Path) {
    ([IO.Path]::GetRelativePath([IO.Path]::GetFullPath($Root), [IO.Path]::GetFullPath($Path))).Replace('\\','/')
}

function Assert-LegacyRelativePath([string]$RelativePath) {
    $relative = $RelativePath.Replace('\\','/').TrimStart('/')
    if ([string]::IsNullOrWhiteSpace($relative) -or [IO.Path]::IsPathRooted($relative) -or $relative.Contains(':')) {
        throw "Expected ordinary relative path: $RelativePath"
    }
    foreach ($part in @($relative -split '/')) {
        if ($part -in @('','..','.') -or $part -match '[<>"|?*]' -or $part -match '[ .]$') {
            throw "Unsafe path segment: $RelativePath"
        }
    }
    return $relative
}

function Resolve-LegacySafeChildPath([string]$Root, [string]$RelativePath) {
    $relative = Assert-LegacyRelativePath $RelativePath
    $rootFull = [IO.Path]::GetFullPath($Root).TrimEnd([IO.Path]::DirectorySeparatorChar,[IO.Path]::AltDirectorySeparatorChar)
    $candidate = [IO.Path]::GetFullPath((Join-Path $rootFull $relative.Replace('/',[IO.Path]::DirectorySeparatorChar)))
    $prefix = $rootFull + [IO.Path]::DirectorySeparatorChar
    if (-not $candidate.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)) { throw "Path escapes root: $RelativePath" }
    $probe = $candidate
    while (-not [string]::IsNullOrWhiteSpace($probe)) {
        if (Test-Path -LiteralPath $probe) {
            $item = Get-Item -Force -LiteralPath $probe
            if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "Reparse points are not supported in transition ownership paths: $probe" }
        }
        $parent = Split-Path -Parent $probe
        if ($parent -eq $probe) { break }
        $probe = $parent
    }
    return $candidate
}

function Get-LegacySha256([string]$Path) {
    (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToUpperInvariant()
}

function Test-LegacyWildcard([string]$RelativePath,[string[]]$Patterns) {
    $relative = $RelativePath.Replace('\\','/')
    foreach ($pattern in @($Patterns)) {
        if ($relative -like $pattern.Replace('**','*')) { return $true }
    }
    return $false
}

function Get-LegacyIniSections([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return @() }
    $sections = [Collections.Generic.List[string]]::new()
    foreach ($line in @(Get-Content -LiteralPath $Path -ErrorAction Stop)) {
        $match = [regex]::Match([string]$line,'^\s*\[(?<name>[^\]]+)\]\s*$')
        if ($match.Success) { $sections.Add($match.Groups['name'].Value.Trim()) }
    }
    @($sections.ToArray() | Sort-Object -Unique)
}

function Get-LegacyFrameworkTransitionPlan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$GameRoot,
        [Parameter(Mandatory=$true)][string]$BaselinePath,
        [Parameter(Mandatory=$true)][string]$ManifestPath,
        [Parameter(Mandatory=$true)][string]$TransitionContractPath,
        [Parameter(Mandatory=$true)][string]$DistributionPath,
        [Parameter(Mandatory=$true)][string]$ProfilesPath
    )

    $game = [IO.Path]::GetFullPath($GameRoot)
    foreach ($required in @($BaselinePath,$ManifestPath,$TransitionContractPath,$DistributionPath,$ProfilesPath)) {
        if (-not (Test-Path -LiteralPath $required -PathType Leaf)) { throw "Required transition evidence file is missing: $required" }
    }

    $contract = Get-Content -Raw -LiteralPath $TransitionContractPath | ConvertFrom-Json
    $manifest = Get-Content -Raw -LiteralPath $ManifestPath | ConvertFrom-Json
    $distribution = Get-Content -Raw -LiteralPath $DistributionPath | ConvertFrom-Json
    $profiles = Get-Content -Raw -LiteralPath $ProfilesPath | ConvertFrom-Json
    $baseline = @(Import-Csv -LiteralPath $BaselinePath)

    $blockers = [Collections.Generic.List[string]]::new()
    $warnings = [Collections.Generic.List[string]]::new()
    $retiredFiles = [Collections.Generic.List[object]]::new()
    $redscriptFiles = [Collections.Generic.List[object]]::new()
    $consumerEvidence = [Collections.Generic.List[string]]::new()

    if ($contract.schemaVersion -ne 1 -or [string]::IsNullOrWhiteSpace([string]$contract.transitionId)) { throw 'Unsupported legacy-framework transition contract.' }
    if ($manifest.schemaVersion -ne 2 -or $manifest.product -ne 'Biology' -or $manifest.playableRuntimeIncluded -ne $true) {
        $blockers.Add('Installed biology/build-manifest.json is not a supported playable schema-2 Biology receipt.')
    }
    if ([string]$manifest.sourceRevision -ne [string]$contract.installedSourceRevision) {
        $blockers.Add("Installed Biology source revision is '$($manifest.sourceRevision)', expected exact pre-W10 source '$($contract.installedSourceRevision)'.")
    }
    if ([string]$manifest.gameVersion -ne [string]$contract.targetGameVersion) {
        $blockers.Add("Installed Biology receipt targets game version '$($manifest.gameVersion)', expected '$($contract.targetGameVersion)'.")
    }
    if ([string]$manifest.uninstall.biologyOwnedPolicy -ne 'biology-owned' -or [string]$manifest.uninstall.genericDependencyPolicy -ne 'preserve') {
        $blockers.Add('Installed Biology receipt does not carry the expected fail-closed player-uninstall policy.')
    }

    $retiredIds = @($contract.retiredComponents | ForEach-Object { ([string]$_).ToLowerInvariant() })
    $retainedIds = @($contract.retainedComponents | ForEach-Object { ([string]$_).ToLowerInvariant() })
    foreach ($id in @($contract.expectedInstalledRetainedDependencies)) {
        $owner = 'upstream:' + ([string]$id).ToLowerInvariant()
        $owned = @($manifest.files | Where-Object { ([string]$_.owner).ToLowerInvariant() -eq $owner })
        if ($owned.Count -eq 0) { $blockers.Add("Installed receipt is missing exact file ownership for expected pre-W10 dependency '$id'.") }
    }

    $removed = @($distribution.removedDependencies | ForEach-Object { ([string]$_).ToLowerInvariant() })
    foreach ($id in $retiredIds) {
        if ($id -notin $removed) { $blockers.Add("Current production distribution does not mark retired component '$id' as removed.") }
    }
    $runtimeProfileName = [string]$contract.currentRuntimeProfile
    $runtimeProfileProperty = $profiles.profiles.PSObject.Properties[$runtimeProfileName]
    if ($null -eq $runtimeProfileProperty) {
        $blockers.Add("Current production runtime profile '$runtimeProfileName' is missing.")
    } else {
        $runtimeIds = @($runtimeProfileProperty.Value | ForEach-Object { ([string]$_).ToLowerInvariant() })
        if ($runtimeIds.Count -ne 1 -or $runtimeIds[0] -ne 'redscript') { $blockers.Add("Current production runtime profile '$runtimeProfileName' is not redscript-only.") }
    }

    $baselineByPath = @{}
    foreach ($row in $baseline) {
        $key = ([string]$row.Path).Replace('\\','/').TrimStart('/').ToLowerInvariant()
        if (-not [string]::IsNullOrWhiteSpace($key)) { $baselineByPath[$key] = $row }
    }

    $receiptByPath = @{}
    foreach ($entry in @($manifest.files)) {
        try { $relative = Assert-LegacyRelativePath ([string]$entry.path) } catch { $blockers.Add($_.Exception.Message); continue }
        $key = $relative.ToLowerInvariant()
        if ($receiptByPath.ContainsKey($key)) { $blockers.Add("Duplicate path in installed Biology receipt: $relative"); continue }
        $receiptByPath[$key] = $entry
        if ([string]$entry.sha256 -notmatch '^[A-Fa-f0-9]{64}$') { $blockers.Add("Invalid receipt SHA-256: $relative") }
    }

    foreach ($id in $retiredIds) {
        $entries = @($manifest.files | Where-Object {
            ([string]$_.owner).ToLowerInvariant() -eq ('upstream:' + $id) -and
            (([string]$_.component).ToLowerInvariant() -eq $id -or ([string]$_.component).ToLowerInvariant() -eq ('license-notice:' + $id))
        })
        if ($entries.Count -eq 0) { $blockers.Add("Installed receipt contains no exact file ownership for retired component '$id'.") }
        foreach ($entry in $entries) {
            $relative = Assert-LegacyRelativePath ([string]$entry.path)
            $expected = ([string]$entry.sha256).ToUpperInvariant()
            $state = 'Unknown'
            $actual = $null
            if ([string]$entry.replacePolicy -ne 'generic-dependency-shared') { $blockers.Add("Retired dependency receipt entry has unexpected policy: $relative / $($entry.replacePolicy)") }
            if ($baselineByPath.ContainsKey($relative.ToLowerInvariant())) { $blockers.Add("Tracked vanilla baseline contains retired dependency path; automatic deletion is forbidden: $relative") }
            try {
                $full = Resolve-LegacySafeChildPath $game $relative
                if (Test-Path -LiteralPath $full -PathType Container) {
                    $state = 'WrongPathType'
                    $blockers.Add("Expected retired dependency file is a directory: $relative")
                } elseif (-not (Test-Path -LiteralPath $full -PathType Leaf)) {
                    $state = 'AlreadyAbsent'
                } else {
                    $actual = Get-LegacySha256 $full
                    if ($actual -eq $expected) { $state = 'ExactMatch' }
                    else {
                        $state = 'Changed'
                        $blockers.Add("Retired dependency file changed from the installed receipt: $relative")
                    }
                }
            } catch {
                $state = 'UnsafePath'
                $blockers.Add($_.Exception.Message)
            }
            $retiredFiles.Add([pscustomobject][ordered]@{ path=$relative; component=$id; expectedSha256=$expected; actualSha256=$actual; state=$state })
        }
    }

    foreach ($id in $retainedIds) {
        $entries = @($manifest.files | Where-Object { ([string]$_.owner).ToLowerInvariant() -eq ('upstream:' + $id) })
        if ($entries.Count -eq 0) { $blockers.Add("Installed receipt contains no retained '$id' payload to protect.") }
        foreach ($entry in $entries) {
            $relative = Assert-LegacyRelativePath ([string]$entry.path)
            $full = Resolve-LegacySafeChildPath $game $relative
            $state = if (Test-Path -LiteralPath $full -PathType Leaf) { 'Present' } elseif (Test-Path -LiteralPath $full) { 'WrongPathType' } else { 'Absent' }
            if ($state -eq 'WrongPathType') { $blockers.Add("Protected retained dependency path has wrong path type: $relative") }
            $redscriptFiles.Add([pscustomobject][ordered]@{ path=$relative; component=$id; state=$state })
        }
    }

    $preferencePath = [string]$manifest.uninstall.preferencePath
    $preferenceSection = [string]$manifest.uninstall.preferenceSection
    if (-not [string]::IsNullOrWhiteSpace($preferencePath)) {
        try {
            $preferenceRelative = Assert-LegacyRelativePath $preferencePath
            $preferenceFull = Resolve-LegacySafeChildPath $game $preferenceRelative
            if (Test-Path -LiteralPath $preferenceFull -PathType Leaf) {
                $sections = @(Get-LegacyIniSections $preferenceFull)
                $foreignSections = @($sections | Where-Object { $_ -ne $preferenceSection })
                if ($foreignSections.Count -gt 0) { $consumerEvidence.Add("Legacy Mod Settings preference file contains non-Biology section(s): $($foreignSections -join ', ')") }
                else { $warnings.Add("Legacy Mod Settings preference file is present and will be preserved: $preferenceRelative") }
            }
        } catch { $blockers.Add($_.Exception.Message) }
    }

    foreach ($rootRelative in @($contract.consumerScanRoots)) {
        $rootNormalized = Assert-LegacyRelativePath ([string]$rootRelative)
        $rootFull = Resolve-LegacySafeChildPath $game $rootNormalized
        if (-not (Test-Path -LiteralPath $rootFull -PathType Container)) { continue }
        foreach ($file in @(Get-ChildItem -LiteralPath $rootFull -Recurse -File -Force -ErrorAction Stop)) {
            $relative = ConvertTo-LegacyRelativePath $game $file.FullName
            $key = $relative.ToLowerInvariant()
            if ($baselineByPath.ContainsKey($key) -or $receiptByPath.ContainsKey($key)) { continue }
            if (-not [string]::IsNullOrWhiteSpace($preferencePath) -and $key -eq $preferencePath.Replace('\\','/').TrimStart('/').ToLowerInvariant()) { continue }
            if (Test-LegacyWildcard $relative @($contract.ignoredUnreceiptedPatterns)) {
                $warnings.Add("Ignoring known generated/non-consumer framework residue while preserving it: $relative")
                continue
            }
            $consumerEvidence.Add($relative)
        }
    }
    foreach ($evidence in @($consumerEvidence | Sort-Object -Unique)) { $blockers.Add("Unreceipted non-vanilla mod/framework payload may indicate another consumer: $evidence") }

    $deletionCandidates = @($retiredFiles.ToArray() | Where-Object state -eq 'ExactMatch' | Sort-Object path)
    $alreadyAbsent = @($retiredFiles.ToArray() | Where-Object state -eq 'AlreadyAbsent' | Sort-Object path)
    [pscustomobject][ordered]@{
        schemaVersion = 1
        transitionId = [string]$contract.transitionId
        generatedUtc = [DateTime]::UtcNow.ToString('o')
        gameRoot = $game
        installedSourceRevision = [string]$manifest.sourceRevision
        targetGameVersion = [string]$contract.targetGameVersion
        receiptSha256 = Get-LegacySha256 $ManifestPath
        baselineSha256 = Get-LegacySha256 $BaselinePath
        transitionContractSha256 = Get-LegacySha256 $TransitionContractPath
        currentDistributionSha256 = Get-LegacySha256 $DistributionPath
        currentProfilesSha256 = Get-LegacySha256 $ProfilesPath
        safeToApply = ($blockers.Count -eq 0)
        blockers = @($blockers.ToArray() | Sort-Object -Unique)
        warnings = @($warnings.ToArray() | Sort-Object -Unique)
        retiredFiles = @($retiredFiles.ToArray() | Sort-Object path)
        deletionCandidates = $deletionCandidates
        alreadyAbsent = $alreadyAbsent
        preservedRedscript = @($redscriptFiles.ToArray() | Sort-Object path)
        consumerEvidence = @($consumerEvidence.ToArray() | Sort-Object -Unique)
        preferencePath = $preferencePath
        preferenceSection = $preferenceSection
    }
}

function Remove-LegacyEmptyParentDirectories {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$GameRoot,
        [Parameter(Mandatory=$true)][string[]]$StartDirectories,
        [Parameter(Mandatory=$true)][string[]]$ProtectedDirectories
    )
    $game = [IO.Path]::GetFullPath($GameRoot).TrimEnd([IO.Path]::DirectorySeparatorChar,[IO.Path]::AltDirectorySeparatorChar)
    $protected = @{}
    foreach ($entry in $ProtectedDirectories) { $protected[(Assert-LegacyRelativePath $entry).ToLowerInvariant()] = $true }
    foreach ($start in @($StartDirectories | Sort-Object Length -Descending -Unique)) {
        $dir = [IO.Path]::GetFullPath($start)
        while ($dir -and -not $dir.Equals($game,[StringComparison]::OrdinalIgnoreCase)) {
            $relative = ConvertTo-LegacyRelativePath $game $dir
            if ($relative.StartsWith('..')) { throw "Directory cleanup path escapes game root: $dir" }
            if ($protected.ContainsKey($relative.ToLowerInvariant())) { break }
            if (-not (Test-Path -LiteralPath $dir -PathType Container)) { break }
            if (@(Get-ChildItem -LiteralPath $dir -Force -ErrorAction Stop).Count -ne 0) { break }
            Remove-Item -LiteralPath $dir -Force
            $parent = Split-Path -Parent $dir
            if ($parent -eq $dir) { break }
            $dir = $parent
        }
    }
}

function Invoke-LegacyRetiredFileRemoval {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$GameRoot,
        [Parameter(Mandatory=$true)][object[]]$DeletionCandidates,
        [Parameter(Mandatory=$true)][string[]]$ProtectedDirectories
    )
    $game = [IO.Path]::GetFullPath($GameRoot)
    $parents = [Collections.Generic.List[string]]::new()
    foreach ($entry in @($DeletionCandidates)) {
        $relative = Assert-LegacyRelativePath ([string]$entry.path)
        $full = Resolve-LegacySafeChildPath $game $relative
        if (-not (Test-Path -LiteralPath $full -PathType Leaf)) { throw "Planned file disappeared before deletion: $relative" }
        $expected = ([string]$entry.expectedSha256).ToUpperInvariant()
        if ($expected -notmatch '^[A-F0-9]{64}$') { throw "Invalid planned SHA-256: $relative" }
        $actual = Get-LegacySha256 $full
        if ($actual -ne $expected) { throw "Planned file changed before deletion: $relative" }
        Remove-Item -LiteralPath $full -Force
        $parents.Add((Split-Path -Parent $full))
    }
    Remove-LegacyEmptyParentDirectories -GameRoot $game -StartDirectories @($parents.ToArray()) -ProtectedDirectories $ProtectedDirectories
}
