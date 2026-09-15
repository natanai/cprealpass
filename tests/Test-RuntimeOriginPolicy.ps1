$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\tools\Common.ps1"
$project = Get-ProjectRoot
$policyPath = Join-Path $project 'manifest/runtime-origin-policy.json'
if (-not (Test-Path -LiteralPath $policyPath)) { throw 'Missing runtime-origin policy.' }
$policy = Get-Content -Raw -LiteralPath $policyPath | ConvertFrom-Json
$script:checks = 0
function Check($condition,[string]$message) { if (-not $condition) { throw $message }; $script:checks++ }

Check ($policy.schemaVersion -eq 1) 'Unexpected runtime-origin schema.'
Check ($policy.product -eq 'realpass') 'Runtime-origin policy must identify realpass.'
Check ($policy.releaseExperience.mode -eq 'locked-authored-experience') 'Release is not a locked authored experience.'
Check ($policy.releaseExperience.allOrNothing -eq $true) 'Release must be all-or-nothing.'
Check ($policy.releaseExperience.publicGameplayToggles -eq $false) 'Public gameplay toggles are forbidden for release.'
Check ($policy.releaseExperience.publicBalanceSliders -eq $false) 'Public balance sliders are forbidden for release.'
Check ($policy.releaseExperience.traditionalActorHealthBars -eq $false) 'Traditional actor health bars must remain absent in the authored release.'
Check ($policy.releaseExperience.note -match '(?i)Mod Settings' -and $policy.releaseExperience.note -match '(?i)E3-inspired') 'Release note does not identify the single E3-inspired presentation preference.'
Check ($policy.runtimeOwnership.gameplayAndPresentationRequiredOrigin -eq 'project-original') 'Gameplay/presentation runtime is not constrained to project-original code.'
Check ($policy.runtimeOwnership.allowedInfrastructureClass -eq 'generic-framework') 'Generic framework infrastructure class is no longer explicit.'
Check ($policy.runtimeOwnership.referenceRule -match '(?i)E3 visual target' -and $policy.runtimeOwnership.referenceRule -match '(?i)RealPass-owned') 'Runtime ownership no longer requires an owned E3-inspired recreation.'
Check ($policy.vanillaFirst.preserveUsefulIdentity -eq $true -and $policy.vanillaFirst.preserveUsefulNativeShells -eq $true -and $policy.vanillaFirst.preferSemanticNativeHooks -eq $true) 'Vanilla-first stability policy is not active.'
$medicalExamples = @($policy.vanillaFirst.medicalIdentityExamples) -join ' '
Check ($medicalExamples -match 'MaxDoc' -and $medicalExamples -match 'FirstAidWhiff' -and $medicalExamples -match 'Bounce Back' -and $medicalExamples -match 'Health Booster') 'Vanilla medical identities are not explicit in runtime policy.'
foreach ($component in @('darkfuture','project-e3-hud')) {
    Check (@($policy.forbiddenRuntimeComponents) -contains $component) "Forbidden runtime component missing: $component"
}
foreach ($needle in @('module DarkFuture.','import DarkFuture.')) {
    Check (@($policy.forbiddenProductionSourceNamespaces) -contains $needle) "Forbidden source namespace rule missing: $needle"
}
foreach ($needle in @('Trauma Kit','UseTraumaKit')) {
    Check (@($policy.vanillaFirst.forbiddenOwnedSourceIdentityPatterns) -contains $needle) "Forbidden source-mod identity rule missing: $needle"
}

$requiredInfrastructure = @($policy.genericInfrastructure.requiredForCurrentOwnedCandidate)
foreach ($component in @('redscript','red4ext','archivexl','mod-settings')) {
    Check ($requiredInfrastructure -contains $component) "Required generic infrastructure missing from runtime-origin policy: $component"
}
$notRequiredInfrastructure = @($policy.genericInfrastructure.currentlyNotRequired)
foreach ($component in @('tweakxl','codeware','input-loader')) {
    Check ($notRequiredInfrastructure -contains $component) "Unneeded generic infrastructure is not explicitly excluded: $component"
}
Check ($policy.genericInfrastructure.modSettingsBoundary -match '(?i)exactly one' -and $policy.genericInfrastructure.modSettingsBoundary -match '(?i)E3-inspired') 'Mod Settings boundary lost the single E3 HUD/nameplate toggle.'
Check ($policy.genericInfrastructure.modSettingsBoundary -match '(?i)not a body, injury, combat, armor, progression or balance authority') 'Mod Settings boundary no longer forbids simulation ownership.'

# The redistribution-safe package is a model/source handoff inventory rather than the
# live candidate. Every file in that package must still be project-original and must
# not smuggle source-mod runtime material back into production.
$package = Get-Content -Raw -LiteralPath (Join-Path $project 'manifest/package.json') | ConvertFrom-Json
foreach ($file in @($package.files)) {
    Check ($file.origin -eq 'project-original') "Package includes non-original source: $($file.source)"
    $normalized = ([string]$file.source).Replace('\\','/')
    foreach ($fragment in @($policy.forbiddenRuntimePathFragments)) {
        Check (-not $normalized.Contains($fragment.Trim('/'))) "Package source path references forbidden runtime material: $normalized"
    }
}

# Superseded source-mod-integrated/prototype files are removed from production, not
# merely hidden from the owned builder. Git history is sufficient as reference.
$sourceRoot = Join-Path $project 'src/redscript/CyberpunkRealism'
foreach ($retired in @('FieldCareUI.reds','RealpassLocalization.reds','FieldCareItemUse.reds')) {
    Check (-not (Test-Path -LiteralPath (Join-Path $sourceRoot $retired))) "Retired production source reappeared: $retired"
}

# Every remaining production REDscript must obey the same source-mod namespace and
# vanilla-identity rules; there are no grandfathered runtime exceptions.
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

Write-Host "PASS: $script:checks owned-runtime policy checks; release is locked, vanilla-first, the single E3-inspired presentation preference is constrained, and no source-mod runtime ownership leaks into production."
