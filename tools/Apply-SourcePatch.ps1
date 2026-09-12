param(
    [Parameter(Mandatory=$true)][string]$ManifestPath,
    [Parameter(Mandatory=$true)][string]$PatchPath
)
. "$PSScriptRoot\Common.ps1"
$project = Get-ProjectRoot
$manifestFull = Resolve-SafeChildPath $project $ManifestPath
$manifest = Get-Content -Raw -LiteralPath $manifestFull | ConvertFrom-Json
$patch = Get-Content -Raw -LiteralPath (Resolve-SafeChildPath $project $PatchPath) | ConvertFrom-Json
if ($patch.schemaVersion -ne 1 -or $patch.id -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]*$') { throw 'Invalid patch schema or ID.' }
$workRelative = 'staging\patch-' + $patch.id + '-' + [guid]::NewGuid().ToString('N')
$work = Resolve-SafeChildPath $project $workRelative
$seen = @{}
$prepared = @(foreach ($change in $patch.patches) {
    $destination = Resolve-SafeChildPath $work $change.destination
    if ($seen.ContainsKey($destination)) { throw 'Duplicate patch destination.' }
    $seen[$destination] = $true
    $matches = @($manifest.files | Where-Object destination -eq $change.destination)
    if ($matches.Count -ne 1 -or $matches[0].component -ne $patch.component) { throw 'Patch target must match exactly one component-owned file.' }
    $file = $matches[0]
    $source = Resolve-SafeChildPath $project $file.source
    if ($change.expectedSha256 -notmatch '^[A-Fa-f0-9]{64}$' -or $file.sha256 -ne $change.expectedSha256 -or (Get-Sha256 $source) -ne $change.expectedSha256) { throw 'Patch requires the exact pinned source bytes.' }
    $edits = if ($change.PSObject.Properties.Name -contains 'edits') { @($change.edits) } else { @($change) }
    if ($edits.Count -eq 0) { throw 'Patch must contain an edit.' }
    $content = [IO.File]::ReadAllText($source)
    foreach ($edit in $edits) {
        if ([string]::IsNullOrEmpty($edit.find) -or $edit.expectedOccurrences -lt 1) { throw 'Invalid patch match.' }
        if ([regex]::Matches($content,[regex]::Escape($edit.find)).Count -ne $edit.expectedOccurrences) { throw 'Patch match count differs from expectation.' }
        $content = $content.Replace($edit.find,$edit.replace)
    }
    $notice = "// Local adaptation: Cyberpunk Realism $($patch.id). $($patch.description)`n// Original: DarkFortuneTeller/DarkFuture, $($patch.sourceVersion), $($patch.license).`n// $($patch.sourceUrl)`n"
    [pscustomobject]@{file=$file;source=$source;destination=$destination;relative=($workRelative+'\'+$change.destination);before=$change.expectedSha256;content=($notice+$content)}
})
# Copy-on-write keeps every previously staged or deployed build reproducible.
$results = @(foreach ($item in $prepared) {
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $item.destination) | Out-Null
    [IO.File]::WriteAllText($item.destination,$item.content,[Text.UTF8Encoding]::new($false))
    $item.file.source = $item.relative
    $item.file.sha256 = Get-Sha256 $item.destination
    [ordered]@{destination=$item.file.destination;originalSource=$item.source;sourceSha256=$item.before;patchedSource=$item.relative;patchedSha256=$item.file.sha256}
})
Write-JsonFile $manifest $manifestFull
Write-JsonFile ([ordered]@{patchId=$patch.id;buildId=$manifest.buildId;appliedAtUtc=[DateTime]::UtcNow.ToString('o');license=$patch.license;sourceUrl=$patch.sourceUrl;changes=$results}) (Join-Path $project ('reports\patch-'+$manifest.buildId+'-'+$patch.id+'.json'))
Write-Host "Applied $($results.Count) source patch(es) into isolated staging. Live files were not changed."
