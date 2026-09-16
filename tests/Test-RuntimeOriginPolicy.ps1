$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\tools\Common.ps1"
$project = Get-ProjectRoot
$policyPath = Join-Path $project 'manifest/runtime-origin-policy.json'
if (-not (Test-Path -LiteralPath $policyPath)) { throw 'Missing runtime-origin policy.' }
$policy = Get-Content -Raw -LiteralPath $policyPath | ConvertFrom-Json
$script:checks = 0
function Check($condition,[string]$message) { if (-not $condition) { throw $message }; $script:checks++ }

Check ($policy.schemaVersion -eq 2) 'Unexpected runtime-origin schema.'
Check ($policy.product -eq 'realpass') 'Runtime-origin policy must retain internal realpass compatibility identity.'
Check ($policy.releaseExperience.mode -eq 'locked-authored-experience') 'Release is not a locked authored experience.'
Check ($policy.releaseExperience.allOrNothing -eq $true) 'Release must be all-or-nothing.'
Check ($policy.releaseExperience.publicGameplayToggles -eq $false) 'Public gameplay toggles are forbidden for release.'
Check ($policy.releaseExperience.publicBalanceSliders -eq $false) 'Public balance sliders are forbidden for release.'
Check ($policy.releaseExperience.traditionalActorHealthBars -eq $false) 'Traditional actor health bars must remain absent in the authored release.'
Check ($policy.releaseExperience.wholeModActivation -match '(?i)REDlauncher|REDmod') 'Whole-mod activation authority is not the official launcher/REDmod boundary.'
Check (@($policy.releaseExperience.publicPreferences).Count -eq 1 -and $policy.releaseExperience.publicPreferences[0] -eq 'presentation.e3-first-person-hud-visuals') 'Runtime-origin policy does not constrain the public surface to one E3 presentation preference.'
Check ($policy.releaseExperience.note -match '(?i)save-persistent' -and $policy.releaseExperience.note -match '(?i)E3-inspired') 'Release note does not identify the save-backed single E3 presentation preference.'
Check ($policy.runtimeOwnership.gameplayAndPresentationRequiredOrigin -eq 'project-original') 'Gameplay/presentation runtime is not constrained to project-original code.'
Check ($policy.runtimeOwnership.allowedInfrastructureClass -eq 'generic-framework') 'Generic framework infrastructure class is no longer explicit.'
Check ($policy.runtimeOwnership.referenceRule -match '(?i)E3 visual target' -and $policy.runtimeOwnership.referenceRule -match '(?i)Biology-owned') 'Runtime ownership no longer requires a Biology-owned E3-inspired recreation.'
Check ($policy.vanillaFirst.preserveUsefulIdentity -eq $true -and $policy.vanillaFirst.preserveUsefulNativeShells -eq $true -and $policy.vanillaFirst.preferSemanticNativeHooks -eq $true) 'Vanilla-first stability policy is not active.'
$medicalExamples = @($policy.vanillaFirst.medicalIdentityExamples) -join ' '
Check ($medicalExamples -match 'MaxDoc' -and $medicalExamples -match 'FirstAidWhiff' -and $medicalExamples -match 'Bounce Back' -and $medicalExamples -match 'Health Booster') 'Vanilla medical identities are not explicit in runtime policy.'
foreach ($component in @('darkfuture','project-e3-hud','mod-settings','archivexl','red4ext')) {
    Check (@($policy.forbiddenRuntimeComponents) -contains $component) "Forbidden runtime component missing: $component"
}
foreach ($needle in @('module DarkFuture.','import DarkFuture.')) {
    Check (@($policy.forbiddenProductionSourceNamespaces) -contains $needle) "Forbidden source namespace rule missing: $needle"
}
foreach ($needle in @('Trauma Kit','UseTraumaKit')) {
    Check (@($policy.vanillaFirst.forbiddenOwnedSourceIdentityPatterns) -contains $needle) "Forbidden source-mod identity rule missing: $needle"
}

$requiredInfrastructure = @($policy.genericInfrastructure.requiredForCurrentOwnedCandidate)
Check ($requiredInfrastructure.Count -eq 2 -and $requiredInfrastructure -contains 'redscript' -and $requiredInfrastructure -contains 'cybercmd') 'Current owned candidate generic infrastructure must be exactly redscript plus cybercmd.'
Check ($policy.genericInfrastructure.redscriptStartupBoundary -match '(?i)InvokeScc' -and $policy.genericInfrastructure.redscriptStartupBoundary -match 'final\.redscripts' -and $policy.genericInfrastructure.redscriptStartupBoundary -match '(?i)never activation') 'Runtime-origin policy does not constrain cybercmd to the REDscript startup compilation boundary.'
$removedInfrastructure = @($policy.genericInfrastructure.removedBySelfContainedSettings)
foreach ($component in @('mod-settings','archivexl','red4ext')) {
    Check ($removedInfrastructure -contains $component) "Settings-stack removal missing from runtime-origin policy: $component"
    Check ($requiredInfrastructure -notcontains $component) "Retired settings dependency remains required: $component"
}
$notRequiredInfrastructure = @($policy.genericInfrastructure.currentlyNotRequired)
foreach ($component in @('tweakxl','codeware','input-loader')) {
    Check ($notRequiredInfrastructure -contains $component) "Unneeded generic infrastructure is not explicitly excluded: $component"
}
Check ($policy.genericInfrastructure.settingsBoundary -match '(?i)ScriptableSystem' -and $policy.genericInfrastructure.settingsBoundary -match '(?i)body-shell') 'Self-contained E3 settings boundary is not documented.'
Check ($policy.genericInfrastructure.settingsBoundary -match '(?i)sole whole-mod activation boundary') 'Self-contained settings boundary does not preserve launcher authority.'
Check ($policy.genericInfrastructure.settingsBoundary -match '(?i)No external settings provider') 'External settings provider is not explicitly excluded.'

$package = Get-Content -Raw -LiteralPath (Join-Path $project 'manifest/package.json') | ConvertFrom-Json
foreach ($file in @($package.files)) {
    Check ($file.origin -eq 'project-original') "Package includes non-original source: $($file.source)"
    $normalized = ([string]$file.source).Replace('\\','/')
    foreach ($fragment in @($policy.forbiddenRuntimePathFragments)) {
        Check (-not $normalized.Contains($fragment.Trim('/'))) "Package source path references forbidden runtime material: $normalized"
    }
}

$sourceRoot = Join-Path $project 'src/redscript/CyberpunkRealism'
foreach ($retired in @('FieldCareUI.reds','RealpassLocalization.reds','FieldCareItemUse.reds')) {
    Check (-not (Test-Path -LiteralPath (Join-Path $sourceRoot $retired))) "Retired production source reappeared: $retired"
}

$violations = [Collections.Generic.List[string]]::new()
Get-ChildItem -LiteralPath $sourceRoot -Filter '*.reds' -File | ForEach-Object {
    $text = Get-Content -Raw -LiteralPath $_.FullName
    foreach ($needle in @($policy.forbiddenProductionSourceNamespaces)) {
        if ($text.Contains([string]$needle)) { $violations.Add($_.Name + ' -> ' + $needle) }
    }
    foreach ($needle in @($policy.vanillaFirst.forbiddenOwnedSourceIdentityPatterns)) {
        if ($text.Contains([string]$needle)) { $violations.Add($_.Name + ' -> forbidden identity ' + $needle) }
    }
}
if ($violations.Count -gt 0) {
    throw "Production candidate source violates owned-runtime policy:`n - $($violations -join "`n - ")"
}

Write-Host "PASS: $script:checks owned-runtime policy checks; release is locked, vanilla-first, the save-backed E3 preference is Biology-owned, and generic runtime is limited to redscript plus cybercmd startup plumbing."
