$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\tools\Common.ps1"
$project = Get-ProjectRoot
$manifestPath = Join-Path $project 'manifest/package.json'
$readmePath = Join-Path $project 'package/README.md'
$distributionPath = Join-Path $project 'manifest/distribution.json'

$manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
$readme = Get-Content -Raw -LiteralPath $readmePath
$distribution = Get-Content -Raw -LiteralPath $distributionPath | ConvertFrom-Json

if ($manifest.schemaVersion -ne 1 -or $manifest.id -ne 'realpass') { throw 'Unexpected legacy development package manifest.' }
if ([string]::IsNullOrWhiteSpace($manifest.version)) { throw 'Development package version missing.' }
if ($readme -notmatch [regex]::Escape($manifest.version)) { throw "Package README does not identify manifest version $($manifest.version)." }
if ($readme -notmatch '(?i)development/source artifact') { throw 'Package README must clearly label the artifact as development/source.' }
if ($readme -notmatch '(?i)does not activate gameplay') { throw 'Package README must state that the development artifact does not activate gameplay.' }
if ($readme -notmatch '(?i)model/source artifact' -or $readme -notmatch 'm1-owned-settings') { throw 'Package README does not distinguish this legacy model-only artifact from the live owned settings profile.' }
if ($distribution.product -ne 'Biology' -or $distribution.releaseGate.publicPlayableArtifactReady -ne $false) { throw 'Development source-package test assumes the current Biology public release remains gated.' }
if ($distribution.target.canonicalBuilder -ne 'tools/Build-BiologyPackage.ps1') { throw 'Legacy development package became ambiguous with the canonical Biology player builder.' }

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
    if ($destination -match '(?i)(Cyberpunk2077\.exe$|final\.redscripts$|UserSettings\.json$|\.sav$)') { throw "Game/user file entered development package manifest: $destination" }
    if ($destination -match '(?i)(Dark Future|Project E3)') { throw "Reference-mod runtime entered source package: $destination" }
}

if (@($manifest.files).Count -lt 10) { throw 'Development package unexpectedly lost most original modules.' }
foreach ($requiredModule in @('runtime-policy-model','body-core','combat-core','injury-body')) {
    if (-not $modules.ContainsKey($requiredModule)) { throw "Development package lost required original module family: $requiredModule" }
}
if (-not $destinations.ContainsKey('r6/scripts/CyberpunkRealism/RuntimePolicyModel.reds')) { throw 'Development package does not contain the code-level runtime policy model.' }
# This historical/model artifact deliberately excludes native adapters. The current
# playable Biology package is built elsewhere by Build-BiologyPackage.ps1.
if ($destinations.ContainsKey('r6/scripts/CyberpunkRealism/RealpassSettings.reds')) { throw 'Native Mod Settings adapter entered the model-only development source artifact.' }
$requirements = @($manifest.requiredExternalComponents)
if (-not ($requirements -contains 'redscript 0.5.31')) { throw 'Development source package lost pinned redscript prerequisite.' }
if (@($requirements | Where-Object { $_ -match '(?i)Mod Settings|ArchiveXL|RED4ext' }).Count -ne 0) { throw 'Model-only development artifact incorrectly inherited live runtime framework prerequisites.' }

$modSettingsPolicy = @($distribution.components | Where-Object id -eq 'mod-settings')
if ($modSettingsPolicy.Count -ne 1 -or $modSettingsPolicy[0].status -ne 'temporary' -or $modSettingsPolicy[0].notes -notmatch '(?i)Lane C') {
    throw 'Current Biology distribution no longer records Mod Settings as the temporary Lane C provider blocker.'
}

Write-Host "PASS: legacy development package metadata remains model/source-only and clearly subordinate to the canonical Biology REDmod-first player builder; current Mod Settings runtime is explicitly temporary."
