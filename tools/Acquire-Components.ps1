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

$selected = @{}
function Add-ComponentWithDependencies([string]$id) {
    if ($selected.ContainsKey($id)) { return }
    if (-not $byId.ContainsKey($id)) { throw "Unknown component id: $id" }
    $component = $byId[$id]
    foreach ($dependency in @($component.dependencies)) { Add-ComponentWithDependencies ([string]$dependency) }
    $selected[$id] = $component
}

if (@($ComponentIds).Count -gt 0) {
    foreach ($id in @($ComponentIds)) {
        if ([string]::IsNullOrWhiteSpace($id)) { throw 'ComponentIds cannot contain an empty id.' }
        Add-ComponentWithDependencies $id
    }
    $components = @($all | Where-Object { $selected.ContainsKey([string]$_.id) })
} else {
    $components = $all
}

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
            if ((Get-Sha256 $partial) -ne $component.archiveSha256) { throw "Download digest mismatch: $($component.id)" }
            Move-Item -LiteralPath $partial -Destination $archive
        } finally { if (Test-Path -LiteralPath $partial) { Remove-Item -LiteralPath $partial } }
    }
    if ((Get-Sha256 $archive) -ne $component.archiveSha256) { throw "Cached archive changed: $archive" }
    Write-Host "Verified $($component.id) $($component.pinnedVersion)"
}

Write-Host "Verified $($components.Count) selected component(s)."
