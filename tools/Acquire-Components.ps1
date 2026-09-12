param([string]$ManifestPath)
. "$PSScriptRoot\Common.ps1"
$project = Get-ProjectRoot
if (-not $ManifestPath) { $ManifestPath = Join-Path $project 'manifest\components.json' }
$catalog = Get-Content -Raw -LiteralPath $ManifestPath | ConvertFrom-Json
foreach ($component in $catalog.components) {
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
