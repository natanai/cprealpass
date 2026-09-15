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
if ($distribution.schemaVersion -ne 1) { throw 'Unexpected distribution contract.' }

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

# Provenance is authoritative for finalized artifact component declarations. Support
# both the transitional realpass metadata and the REDmod-first Biology metadata while
# PKG-06 keeps the old route available as a rollback path.
$provenanceCandidates = @(
    'biology/provenance.json',
    'biology/provenance/components.json',
    'realpass/provenance.json',
    'realpass/provenance/components.json',
    'provenance.json',
    'provenance/components.json'
)
$disallowed = @($distribution.components | Where-Object { $_.status -in @('blocked','not-required') } | ForEach-Object id)
foreach ($candidate in $provenanceCandidates) {
    $full = Join-Path $rootFull $candidate
    if (-not (Test-Path -LiteralPath $full -PathType Leaf)) { continue }
    try { $data = Get-Content -Raw -LiteralPath $full | ConvertFrom-Json } catch { throw "Invalid artifact provenance JSON: $candidate" }

    $declaredIds = [Collections.Generic.List[string]]::new()
    if ($null -ne $data.components) {
        foreach ($entry in @($data.components)) {
            $id = if ($entry -is [string]) { [string]$entry } else { [string]$entry.id }
            if (-not [string]::IsNullOrWhiteSpace($id)) { $declaredIds.Add($id) }
        }
    }
    if ($null -ne $data.retainedDependencies) {
        foreach ($entry in @($data.retainedDependencies)) {
            $id = if ($entry -is [string]) { [string]$entry } else { [string]$entry.id }
            if (-not [string]::IsNullOrWhiteSpace($id)) { $declaredIds.Add($id) }
        }
    }
    if ($null -ne $data.removedDependencies) {
        foreach ($id in @($data.removedDependencies)) {
            # Removed dependencies are expected to be disallowed or absent; never
            # interpret this documentation list as a runtime declaration.
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
