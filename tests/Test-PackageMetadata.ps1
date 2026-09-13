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
foreach ($requiredModule in @('runtime-policy-model','settings-surface','body-core','combat-core','injury-body')) {
    if (-not $modules.ContainsKey($requiredModule)) { throw "Development package lost required original module family: $requiredModule" }
}
if (-not $destinations.ContainsKey('r6/scripts/CyberpunkRealism/RuntimePolicyModel.reds')) {
    throw 'Development package does not contain the code-level runtime policy model.'
}
if (-not $destinations.ContainsKey('r6/scripts/CyberpunkRealism/RealpassSettings.reds')) {
    throw 'Development package does not contain the realpass-owned settings surface.'
}
$requirements = @($manifest.requiredExternalComponents)
if (-not ($requirements -contains 'redscript 0.5.31')) { throw 'Development source package lost pinned redscript prerequisite.' }
if (@($requirements | Where-Object { $_ -match '^Mod Settings 0\.2\.21' }).Count -ne 1) { throw 'Settings source package does not declare its pinned Mod Settings prerequisite.' }

$settingsSource = Get-Content -Raw -LiteralPath (Join-Path $project 'src/redscript/CyberpunkRealism/RealpassSettings.reds')
if ($settingsSource.Contains('CRBodyRuntimePolicy') -or $settingsSource.Contains('CRCombatRuntimePolicy')) {
    throw 'Development settings source can directly open staged runtime gates.'
}

Write-Host "PASS: development package metadata matches $($manifest.version), $(@($manifest.files).Count) project-original files, includes passive settings source, and remains non-playable by contract."
