param(
    [Parameter(Mandatory=$true)][string]$Root,
    [string]$DistributionPath = 'manifest/distribution.json'
)
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/Common.ps1"
$project = Get-ProjectRoot
$rootFull = [IO.Path]::GetFullPath($Root)
if (-not (Test-Path -LiteralPath $rootFull -PathType Container)) { throw "Artifact root not found: $rootFull" }
$distributionFull = Resolve-SafeChildPath $project $DistributionPath
$distribution = Get-Content -Raw -LiteralPath $distributionFull | ConvertFrom-Json
if ($distribution.schemaVersion -notin @(1,2,3)) { throw 'Unexpected distribution contract.' }

function Normalize-Relative([string]$full) {
    $relative = [IO.Path]::GetRelativePath($rootFull, $full).Replace('\','/')
    if ($relative -eq '.' -or $relative.StartsWith('../') -or [IO.Path]::IsPathRooted($relative)) {
        throw "Unsafe artifact path: $full"
    }
    return $relative
}

function Matches-PolicyPattern([string]$relative, [string]$pattern) {
    $candidate = $relative.Replace('\','/').TrimStart('/').ToLowerInvariant()
    $rule = $pattern.Replace('\','/').TrimStart('/').ToLowerInvariant()
    if (-not $rule.Contains('/')) {
        return [IO.Path]::GetFileName($candidate) -like $rule
    }
    return $candidate -like $rule
}

$files = @(Get-ChildItem -LiteralPath $rootFull -Recurse -File -Force)
$violations = [Collections.Generic.List[string]]::new()
foreach ($file in $files) {
    $relative = Normalize-Relative $file.FullName
    foreach ($pattern in @($distribution.forbiddenArtifactPatterns)) {
        if (Matches-PolicyPattern $relative $pattern) {
            $violations.Add("forbidden-path:$relative matches $pattern")
        }
    }
    if ($relative -match '(?i)(^|/)(\.env(?:\..*)?|.*\.(pem|key))$') {
        $violations.Add("secret-like-file:$relative")
    }
}

# Biology provenance is authoritative for finalized player artifacts. Generic
# provenance.json locations remain accepted for isolated policy fixtures, but retired
# RealPass player-package metadata paths are no longer treated as current artifact forms.
$provenanceCandidates = @(
    'biology/provenance.json',
    'biology/provenance/components.json',
    'provenance.json',
    'provenance/components.json'
)
$disallowed = @($distribution.components | Where-Object { $_.status -in @('blocked','not-required') } | ForEach-Object id)
foreach ($candidate in $provenanceCandidates) {
    $full = Join-Path $rootFull $candidate
    if (-not (Test-Path -LiteralPath $full -PathType Leaf)) { continue }
    try { $data = Get-Content -Raw -LiteralPath $full | ConvertFrom-Json } catch { throw "Invalid artifact provenance JSON: $candidate" }

    $declaredIds = [Collections.Generic.List[string]]::new()
    $propertyNames = @($data.PSObject.Properties.Name)
    if ($propertyNames -contains 'components' -and $null -ne $data.components) {
        foreach ($entry in @($data.components)) {
            $id = if ($entry -is [string]) { [string]$entry } else { [string]$entry.id }
            if (-not [string]::IsNullOrWhiteSpace($id)) { $declaredIds.Add($id) }
        }
    }
    if ($propertyNames -contains 'retainedDependencies' -and $null -ne $data.retainedDependencies) {
        foreach ($entry in @($data.retainedDependencies)) {
            $id = if ($entry -is [string]) { [string]$entry } else { [string]$entry.id }
            if (-not [string]::IsNullOrWhiteSpace($id)) { $declaredIds.Add($id) }
        }
    }
    if ($propertyNames -contains 'removedDependencies' -and $null -ne $data.removedDependencies) {
        foreach ($id in @($data.removedDependencies)) {
            if ([string]::IsNullOrWhiteSpace([string]$id)) { throw "Empty removed dependency id in $candidate" }
        }
    }

    foreach ($id in @($declaredIds | Sort-Object -Unique)) {
        if ($disallowed -contains $id) {
            $violations.Add("disallowed-component:$id declared as retained runtime by $candidate")
        }
    }
}

if ($violations.Count -gt 0) {
    throw "Artifact policy rejected $($violations.Count) item(s):`n - $($violations -join "`n - ")"
}

Write-Host "PASS: artifact policy accepted $($files.Count) files under $rootFull."
