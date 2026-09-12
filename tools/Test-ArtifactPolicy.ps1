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
if ($distribution.schemaVersion -ne 1 -or $distribution.product -ne 'realpass') { throw 'Unexpected distribution contract.' }

function Normalize-Relative([string]$full) {
    $relative = [IO.Path]::GetRelativePath($rootFull, $full).Replace('\','/')
    if ($relative -eq '.' -or $relative.StartsWith('../') -or [IO.Path]::IsPathRooted($relative)) {
        throw "Unsafe artifact path: $full"
    }
    return $relative
}

function Matches-PolicyPattern([string]$relative, [string]$pattern) {
    $candidate = $relative.Replace('\','/').TrimStart('/')
    $rule = $pattern.Replace('\','/').TrimStart('/')
    # PowerShell wildcard matching is case-insensitive on Windows; force the same
    # behavior explicitly so CI policy does not depend on runner filesystem rules.
    return $candidate.ToLowerInvariant() -like $rule.ToLowerInvariant()
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
    # Explicit secret/private-key extensions are denied even if a future contract
    # accidentally drops the corresponding wildcard.
    if ($relative -match '(?i)(^|/)(\.env(?:\..*)?|.*\.(pem|key))$') {
        $violations.Add("secret-like-file:$relative")
    }
}

# If an artifact exposes component provenance, reject any component currently
# blocked by the distribution contract. The scanner supports the two intended
# provenance shapes: {components:[{id:...}]} and a bare array of IDs/objects.
$provenanceCandidates = @(
    'realpass/provenance.json',
    'realpass/provenance/components.json',
    'provenance.json',
    'provenance/components.json'
)
$blocked = @($distribution.components | Where-Object status -eq 'blocked' | ForEach-Object id)
foreach ($candidate in $provenanceCandidates) {
    $full = Join-Path $rootFull $candidate
    if (-not (Test-Path -LiteralPath $full -PathType Leaf)) { continue }
    try { $data = Get-Content -Raw -LiteralPath $full | ConvertFrom-Json } catch { throw "Invalid artifact provenance JSON: $candidate" }
    $entries = if ($null -ne $data.components) { @($data.components) } else { @($data) }
    foreach ($entry in $entries) {
        $id = if ($entry -is [string]) { $entry } else { $entry.id }
        if (-not [string]::IsNullOrWhiteSpace($id) -and $blocked -contains $id) {
            $violations.Add("blocked-component:$id declared by $candidate")
        }
    }
}

if ($violations.Count -gt 0) {
    throw "Artifact policy rejected $($violations.Count) item(s):`n - $($violations -join "`n - ")"
}

Write-Host "PASS: artifact policy accepted $($files.Count) files under $rootFull."
