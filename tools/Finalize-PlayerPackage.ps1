param(
    [Parameter(Mandatory=$true)][string]$Root,
    [Parameter(Mandatory=$true)][string]$PlanPath,
    [Parameter(Mandatory=$true)][string]$Version,
    [Parameter(Mandatory=$true)][string]$GameVersion,
    [Parameter(Mandatory=$true)][string]$SourceRevision
)
$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'Finalize-PlayerPackage.ps1 requires PowerShell 7 or newer.' }
. "$PSScriptRoot/Common.ps1"
$project = Get-ProjectRoot
$rootFull = [IO.Path]::GetFullPath($Root).TrimEnd('\','/')
if (-not (Test-Path -LiteralPath $rootFull -PathType Container)) { throw "Package root not found: $rootFull" }
if ($Version -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]*$') { throw 'Invalid package version.' }
if ($GameVersion -notmatch '^[0-9]+(?:\.[0-9]+){1,3}$') { throw 'Invalid game version.' }
if ($SourceRevision -notmatch '^[A-Fa-f0-9]{7,64}$') { throw 'SourceRevision must be a Git commit-like hexadecimal revision.' }

$planFull = Resolve-SafeChildPath $project $PlanPath
$plan = Get-Content -Raw -LiteralPath $planFull | ConvertFrom-Json
$distribution = Get-Content -Raw -LiteralPath (Join-Path $project 'manifest/distribution.json') | ConvertFrom-Json
$install = Get-Content -Raw -LiteralPath (Join-Path $project 'manifest/install-contract.json') | ConvertFrom-Json
if ($plan.schemaVersion -ne 1 -or $plan.product -ne 'realpass') { throw 'Unexpected player package plan.' }

function Relative([string]$full) {
    $value = [IO.Path]::GetRelativePath($rootFull,$full).Replace('\','/').TrimStart('/')
    if ($value -eq '.' -or $value.StartsWith('../') -or [IO.Path]::IsPathRooted($value)) { throw "Unsafe package path: $full" }
    return $value
}

$generated = @('realpass/build-manifest.json','SHA256SUMS.txt','REALPASS-VERSION.txt')
$allowedPolicies = @($install.ownerManifest.allowedReplacePolicies)
$blocked = @{}
foreach ($component in @($distribution.components | Where-Object status -eq 'blocked')) { $blocked[$component.id] = $true }
$planByPath = @{}
foreach ($entry in @($plan.files)) {
    $path = ([string]$entry.path).Replace('\','/').TrimStart('/')
    if ([string]::IsNullOrWhiteSpace($path) -or $path -match '(^|/)\.\.(/|$)' -or [IO.Path]::IsPathRooted($path)) { throw "Unsafe planned package path: $path" }
    if ($generated -contains $path) { throw "Generated metadata must not appear in package plan: $path" }
    if ($planByPath.ContainsKey($path)) { throw "Duplicate planned package path: $path" }
    if ([string]::IsNullOrWhiteSpace($entry.component)) { throw "Missing component for planned path: $path" }
    if ([string]::IsNullOrWhiteSpace($entry.owner)) { throw "Missing owner for planned path: $path" }
    if ($allowedPolicies -notcontains $entry.replacePolicy) { throw "Invalid replacePolicy for $path: $($entry.replacePolicy)" }
    if ($blocked.ContainsKey($entry.component)) { throw "Blocked component in player package plan: $($entry.component) ($path)" }
    $planByPath[$path] = $entry
}
if ($planByPath.Count -eq 0) { throw 'Player package plan has no files.' }

# Refuse hidden/unplanned payload. Generated metadata from a previous finalization is
# ignored here and replaced deterministically below.
$actualByPath = @{}
foreach ($file in @(Get-ChildItem -LiteralPath $rootFull -Recurse -File -Force)) {
    $relative = Relative $file.FullName
    if ($generated -contains $relative) { continue }
    if ($actualByPath.ContainsKey($relative)) { throw "Duplicate actual package path: $relative" }
    $actualByPath[$relative] = $file.FullName
}
foreach ($path in $planByPath.Keys) {
    if (-not $actualByPath.ContainsKey($path)) { throw "Planned package file missing: $path" }
}
foreach ($path in $actualByPath.Keys) {
    if (-not $planByPath.ContainsKey($path)) { throw "Unplanned package file present: $path" }
}

# The package policy must pass before any metadata is emitted.
& "$PSScriptRoot/Test-ArtifactPolicy.ps1" -Root $rootFull

$manifestFiles = [Collections.Generic.List[object]]::new()
foreach ($path in @($planByPath.Keys | Sort-Object)) {
    $entry = $planByPath[$path]
    $manifestFiles.Add([ordered]@{
        path = $path
        sha256 = Get-Sha256 $actualByPath[$path]
        owner = [string]$entry.owner
        component = [string]$entry.component
        replacePolicy = [string]$entry.replacePolicy
    })
}
$realpassDir = Join-Path $rootFull 'realpass'
New-Item -ItemType Directory -Force -Path $realpassDir | Out-Null
$manifestPath = Join-Path $rootFull 'realpass/build-manifest.json'
$manifest = [ordered]@{
    schemaVersion = 1
    product = 'realpass'
    version = $Version
    gameVersion = $GameVersion
    sourceRevision = $SourceRevision.ToLowerInvariant()
    files = @($manifestFiles.ToArray())
}
Write-JsonFile $manifest $manifestPath

$versionText = @(
    'realpass ' + $Version,
    'Cyberpunk 2077 ' + $GameVersion,
    'source ' + $SourceRevision.ToLowerInvariant()
) -join "`n"
[IO.File]::WriteAllText((Join-Path $rootFull 'REALPASS-VERSION.txt'),$versionText + "`n",[Text.UTF8Encoding]::new($false))

# SHA256SUMS covers every final artifact file except itself, including the owner
# manifest and version marker. Sort paths so rerunning the finalizer is stable.
$sumLines = [Collections.Generic.List[string]]::new()
foreach ($file in @(Get-ChildItem -LiteralPath $rootFull -Recurse -File -Force | Sort-Object FullName)) {
    $relative = Relative $file.FullName
    if ($relative -eq 'SHA256SUMS.txt') { continue }
    $sumLines.Add(((Get-Sha256 $file.FullName).ToLowerInvariant() + '  ' + $relative))
}
[IO.File]::WriteAllText((Join-Path $rootFull 'SHA256SUMS.txt'),($sumLines -join "`n") + "`n",[Text.UTF8Encoding]::new($false))

& "$PSScriptRoot/Test-ArtifactPolicy.ps1" -Root $rootFull
Write-Host "Finalized realpass package metadata: $Version / game $GameVersion / $($manifestFiles.Count) owned payload files."
return $manifestPath
