param(
    [string]$Profile = 'm1-base'
)
. "$PSScriptRoot\Common.ps1"
$project = Get-ProjectRoot
$catalog = Get-Content -Raw (Join-Path $project 'manifest\components.json') | ConvertFrom-Json
$profiles = Get-Content -Raw (Join-Path $project 'manifest\profiles.json') | ConvertFrom-Json
if ($Profile -notin $profiles.profiles.PSObject.Properties.Name) { throw 'Unknown profile.' }
$requested = @($profiles.profiles.$Profile)
$components = @($catalog.components | Where-Object { $_.id -in $requested })
if ($components.Count -ne $requested.Count) { throw 'Profile references missing or duplicate components.' }
$ids = @($components.id)
foreach ($component in $components) {
    foreach ($dependency in $component.dependencies) { if ($dependency -notin $ids) { throw "Missing dependency: $dependency" } }
}
$stageRelative = 'staging\' + $Profile + '-' + [guid]::NewGuid().ToString('N')
$stage = Resolve-SafeChildPath $project $stageRelative
$seen = @{}
$files = @()
foreach ($component in $components) {
    $archive = Resolve-SafeChildPath $project $component.archivePath
    if ((Get-Sha256 $archive) -ne $component.archiveSha256) { throw 'Archive digest mismatch.' }
    $zip = [IO.Compression.ZipFile]::OpenRead($archive)
    try {
        $total = 0L
        $entries = @(foreach ($entry in $zip.Entries) {
            $relative = $entry.FullName.TrimEnd('/','\')
            if (-not $relative) { continue }
            if ($relative -in @(Get-OptionalProperty $component 'excludedArchiveEntries')) { continue }
            $target = Resolve-SafeChildPath $stage $relative
            if (($entry.ExternalAttributes -shr 16 -band 0xF000) -eq 0xA000) { throw 'Archive contains a symbolic link.' }
            $total += $entry.Length
            if ($total -gt 512MB) { throw 'Framework archive exceeds extraction limit.' }
            if (-not $entry.Name) { continue }
            if ($seen.ContainsKey($target)) { throw "Overlapping archive payload: $relative" }
            $seen[$target] = $component.id
            [pscustomobject]@{entry=$entry; target=$target; relative=$relative}
        })
        foreach ($item in $entries) {
            New-Item -ItemType Directory -Force -Path (Split-Path -Parent $item.target) | Out-Null
            [IO.Compression.ZipFileExtensions]::ExtractToFile($item.entry, $item.target, $false)
            $files += [ordered]@{source=($stageRelative + '\' + $item.relative); destination=$item.relative; component=$component.id; sha256=(Get-Sha256 $item.target)}
        }
    } finally { $zip.Dispose() }
}
$manifest = [ordered]@{schemaVersion=1; buildId=$Profile; gameVersion='2.31'; files=$files}
$path = Join-Path $project "manifest\$Profile.deployment.json"
Write-JsonFile $manifest $path
Write-Host "Staged $($components.Count) components / $($files.Count) files: $path"
