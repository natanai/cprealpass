param(
    [string]$ManifestPath,
    [string[]]$ComponentIds
)
. "$PSScriptRoot\Common.ps1"
$project = Get-ProjectRoot
if (-not $ManifestPath) { $ManifestPath = Join-Path $project 'manifest\components.json' }
$catalog = Get-Content -Raw -LiteralPath $ManifestPath | ConvertFrom-Json
$all = @($catalog.components)
$byId = @{}
foreach ($component in $all) {
    if ([string]::IsNullOrWhiteSpace([string]$component.id) -or $byId.ContainsKey([string]$component.id)) { throw 'Component catalog contains a missing or duplicate id.' }
    $byId[[string]$component.id] = $component
}

# The catalog retains historical/pinned evidence for older experiments, but these
# components are no longer legal Biology acquisition targets after issue #61.
# Keeping the retirement gate here prevents an old profile/tool invocation from
# silently downloading the settings DLL stack back into staging.
$retired = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach ($id in @('mod-settings','archivexl','red4ext')) { [void]$retired.Add($id) }

$selected = @{}
function Add-ComponentWithDependencies([string]$id) {
    if ($retired.Contains($id)) { throw "Component '$id' is retired from Biology production acquisition (issue #61)." }
    if ($selected.ContainsKey($id)) { return }
    if (-not $byId.ContainsKey($id)) { throw "Unknown component id: $id" }
    $component = $byId[$id]
    foreach ($dependency in @($component.dependencies)) { Add-ComponentWithDependencies ([string]$dependency) }
    $selected[$id] = $component
}

# No-argument acquisition means the complete current production REDscript runtime:
# redscript supplies SCC/configuration, while standalone cybercmd executes scc.toml's
# InvokeScc task at startup when RED4ext/CET are intentionally absent.
if (@($ComponentIds).Count -eq 0) { $ComponentIds = @('redscript','cybercmd') }
foreach ($id in @($ComponentIds)) {
    if ([string]::IsNullOrWhiteSpace($id)) { throw 'ComponentIds cannot contain an empty id.' }
    Add-ComponentWithDependencies $id
}
$components = @($all | Where-Object { $selected.ContainsKey([string]$_.id) })

foreach ($component in $components) {
    $archive = Resolve-SafeChildPath $project $component.archivePath
    if ($component.archiveSha256 -notmatch '^[A-Fa-f0-9]{64}$') { throw 'An archive hash is required.' }
    if (-not (Test-Path -LiteralPath $archive)) {
        $uri = [uri]$component.assetUrl
        if ($uri.Scheme -ne 'https' -or $uri.Host -ne 'github.com') { throw 'Only pinned official GitHub release assets are supported.' }
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $archive) | Out-Null
        $partial = "$archive.$([guid]::NewGuid().ToString('N')).partial"
        try {
            Invoke-WebRequest -Uri $uri -OutFile $partial
            $actual = Get-Sha256 $partial
            if ($actual -ne $component.archiveSha256) { throw "Download digest mismatch: $($component.id) expected=$($component.archiveSha256) actual=$actual" }
            Move-Item -LiteralPath $partial -Destination $archive
        } finally { if (Test-Path -LiteralPath $partial) { Remove-Item -LiteralPath $partial } }
    }
    $cachedActual = Get-Sha256 $archive
    if ($cachedActual -ne $component.archiveSha256) { throw "Cached archive changed: $archive expected=$($component.archiveSha256) actual=$cachedActual" }
    Write-Host "Verified $($component.id) $($component.pinnedVersion)"
}

Write-Host "Verified $($components.Count) selected component(s)."
