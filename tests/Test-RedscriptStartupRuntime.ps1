$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'Test-RedscriptStartupRuntime.ps1 requires PowerShell 7 or newer.' }
. "$PSScriptRoot\..\tools\Common.ps1"
$project = Get-ProjectRoot

$components = Get-Content -Raw -LiteralPath (Join-Path $project 'manifest/components.json') | ConvertFrom-Json
$profiles = Get-Content -Raw -LiteralPath (Join-Path $project 'manifest/profiles.json') | ConvertFrom-Json
$deps = Get-Content -Raw -LiteralPath (Join-Path $project 'manifest/dependency-graph.json') | ConvertFrom-Json
$install = Get-Content -Raw -LiteralPath (Join-Path $project 'manifest/redmod-install-contract.json') | ConvertFrom-Json
$distribution = Get-Content -Raw -LiteralPath (Join-Path $project 'manifest/distribution.json') | ConvertFrom-Json
$runtimeOrigin = Get-Content -Raw -LiteralPath (Join-Path $project 'manifest/runtime-origin-policy.json') | ConvertFrom-Json
$acquire = Get-Content -Raw -LiteralPath (Join-Path $project 'tools/Acquire-Components.ps1')
$runtimeBuilder = Get-Content -Raw -LiteralPath (Join-Path $project 'tools/Build-OwnedRuntimeProfile.ps1')
$packageBuilder = Get-Content -Raw -LiteralPath (Join-Path $project 'tools/Build-BiologyPackage.ps1')
$licensePath = Join-Path $project 'LICENSES/cybercmd-v0.0.13.txt'

function Require($condition,[string]$message) { if (-not $condition) { throw $message } }

$cybercmd = @($components.components | Where-Object id -eq 'cybercmd')
Require ($cybercmd.Count -eq 1) 'W13 must pin exactly one cybercmd component.'
$cybercmd = $cybercmd[0]
Require ($cybercmd.pinnedVersion -eq '0.0.13') 'W13 cybercmd version pin drifted.'
Require ($cybercmd.assetUrl -eq 'https://github.com/jac3km4/cybercmd/releases/download/v0.0.13/cybercmd-standalone.zip') 'W13 cybercmd asset is not the official standalone release.'
Require ($cybercmd.archiveSha256 -eq '87E235026D0693D7974A908E65F8C93F6503652FB781F0647B115572BBDD6103') 'W13 cybercmd archive fingerprint drifted.'
$deployment = @($cybercmd.deployment)
foreach ($path in @('bin/x64/global.ini','bin/x64/plugins/cybercmd.asi','bin/x64/version.dll')) { Require ($deployment -contains $path) "W13 cybercmd deployment is missing $path" }
Require ($deployment.Count -eq 3) 'W13 cybercmd component gained an unexpected deployment file.'
Require (Test-Path -LiteralPath $licensePath -PathType Leaf) 'W13 cybercmd MIT license snapshot is missing.'

foreach ($profileName in @('m1-base','biology-runtime')) {
    $profile = @($profiles.profiles.$profileName)
    Require ($profile.Count -eq 2 -and $profile -contains 'redscript' -and $profile -contains 'cybercmd') "Runtime profile $profileName is not exactly redscript + cybercmd."
    foreach ($retired in @('red4ext','archivexl','mod-settings')) { Require ($profile -notcontains $retired) "Runtime profile $profileName restored retired component $retired." }
}

$depById = @{}
foreach ($entry in @($deps.dependencies)) { $depById[[string]$entry.id] = $entry }
Require ($depById.ContainsKey('redscript')) 'Dependency graph lost redscript.'
Require ($depById.ContainsKey('cybercmd')) 'Dependency graph lost cybercmd startup runner.'
Require ($depById['cybercmd'].route -eq 'REDSCRIPT-STARTUP') 'cybercmd route is not REDSCRIPT-STARTUP.'
Require ($depById['cybercmd'].bundledByBiology -eq $true) 'cybercmd is not bundled by Biology.'
Require ((@($depById['cybercmd'].consumerFeatures) -join ' ') -match '(?i)InvokeScc') 'cybercmd consumer is not the scc.toml InvokeScc task.'
Require ((@($depById['cybercmd'].consumerFeatures) -join ' ') -match 'r6/cache/modded/final\.redscripts') 'cybercmd consumer does not name the configured compiled blob.'
foreach ($retired in @('red4ext','archivexl','mod-settings')) { Require (-not $depById.ContainsKey($retired)) "W13 restored retired active dependency $retired." }

Require ($acquire.Contains("if (@(`$ComponentIds).Count -eq 0) { `$ComponentIds = @('redscript','cybercmd') }")) 'Default component acquisition does not fetch the complete startup pair.'
Require ($runtimeBuilder.Contains("`$genericIds = @('redscript','cybercmd')")) 'Owned runtime builder does not require the complete startup pair.'
Require ($packageBuilder.Contains("`$expectedRetained = @('redscript','cybercmd')")) 'Player package builder does not require the complete startup pair.'
Require ($packageBuilder.Contains("'cybercmd' = 'REDSCRIPT-STARTUP'")) 'Player package builder does not isolate cybercmd to startup compilation.'
foreach ($path in @('bin/x64/global.ini','bin/x64/plugins/cybercmd.asi','bin/x64/version.dll')) { Require ($packageBuilder.Contains($path)) "Player package builder does not enforce cybercmd payload path $path" }
Require ($packageBuilder.Contains("'generic-dependency-shared'")) 'Player package builder does not preserve generic dependency ownership policy.'

$retainedInstall = @($install.supplementalRuntime.retainedGenericComponents)
Require ($retainedInstall.Count -eq 2 -and $retainedInstall -contains 'redscript' -and $retainedInstall -contains 'cybercmd') 'Install contract does not retain exactly redscript + cybercmd.'
Require ($install.supplementalRuntime.startupCompileContract -match '(?i)InvokeScc' -and $install.supplementalRuntime.startupCompileContract -match 'r6/cache/modded/final\.redscripts') 'Install contract lost the W13 configured-output startup boundary.'
Require ($install.launcherActivation.signal -eq 'Items.BiologyLauncherActivationMarker.stackable') 'W13 must not replace REDmod launcher activation authority.'

$distributionCybercmd = @($distribution.components | Where-Object id -eq 'cybercmd')
Require ($distributionCybercmd.Count -eq 1 -and $distributionCybercmd[0].status -eq 'allowed') 'Distribution does not permit the pinned cybercmd startup runner.'
Require (@($distribution.releaseGate.mustPass) -contains 'redscript-startup-output-regeneration') 'Distribution does not retain live compiled-output regeneration as an acceptance gate.'
Require (@($distribution.forbiddenArtifactPatterns) -contains 'final.redscripts') 'W13 must never bundle a generated/game compiled final.redscripts blob.'

$infra = @($runtimeOrigin.genericInfrastructure.requiredForCurrentOwnedCandidate)
Require ($infra.Count -eq 2 -and $infra -contains 'redscript' -and $infra -contains 'cybercmd') 'Runtime-origin policy does not constrain generic infrastructure to redscript + cybercmd.'
Require ($runtimeOrigin.genericInfrastructure.redscriptStartupBoundary -match '(?i)never activation') 'Runtime-origin policy allows cybercmd to become activation authority.'

Write-Host 'PASS: W13 pins and packages standalone cybercmd solely as the missing REDscript scc.toml startup executor, keeps generated final.redscripts out of the artifact, and preserves REDmod as Biology activation authority.'
