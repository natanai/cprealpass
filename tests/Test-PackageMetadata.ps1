$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\tools\Common.ps1"
$project = Get-ProjectRoot
$manifestPath = Join-Path $project 'manifest/package.json'
$readmePath = Join-Path $project 'package/README.md'
$distributionPath = Join-Path $project 'manifest/distribution.json'

$manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
$readme = Get-Content -Raw -LiteralPath $readmePath
$distribution = Get-Content -Raw -LiteralPath $distributionPath | ConvertFrom-Json

if ($manifest.schemaVersion -ne 1 -or $manifest.id -ne 'realpass') { throw 'Unexpected development package manifest.' }
if ([string]::IsNullOrWhiteSpace($manifest.version)) { throw 'Development package version missing.' }
if ($readme -notmatch [regex]::Escape($manifest.version)) { throw "Package README does not identify manifest version $($manifest.version)." }
if ($readme -notmatch '(?i)development/source artifact') { throw 'Package README must clearly label the artifact as development/source.' }
if ($readme -notmatch '(?i)does not activate gameplay') { throw 'Package README must state that the development artifact does not activate gameplay.' }
if ($distribution.releaseGate.publicPlayableArtifactReady -ne $false) { throw 'Development package test assumes public playable release remains gated.' }

$destinations = @{}
$modules = @{}
foreach ($file in @($manifest.files)) {
    if ($file.origin -ne 'project-original') { throw "Development source package contains non-project origin: $($file.source)" }
    $source = Resolve-SafeChildPath $project $file.source
    if (-not (Test-Path -LiteralPath $source -PathType Leaf)) { throw "Package source missing: $($file.source)" }
    $destination = $file.destination.Replace('\','/')
    if ($destination.StartsWith('/') -or $destination -match '(^|/)\.\.(/|$)') { throw "Unsafe package destination: $destination" }
    if ($destinations.ContainsKey($destination)) { throw "Duplicate package destination: $destination" }
    $destinations[$destination] = $true
    $modules[$file.module] = $true
    if ($destination -match '(?i)(Cyberpunk2077\.exe$|final\.redscripts$|UserSettings\.json$|\.sav$)') {
        throw "Game/user file entered development package manifest: $destination"
    }
}

if (@($manifest.files).Count -lt 10) { throw 'Development package unexpectedly lost most original modules.' }
if (-not $modules.ContainsKey('body-core') -or -not $modules.ContainsKey('combat-core') -or -not $modules.ContainsKey('injury-body')) {
    throw 'Development package no longer covers the expected original model families.'
}

Write-Host "PASS: development package metadata matches $($manifest.version), $(@($manifest.files).Count) project-original files, and remains non-playable by contract."
