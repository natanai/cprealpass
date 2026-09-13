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
Check ($policy.runtimeOwnership.gameplayAndPresentationRequiredOrigin -eq 'project-original') 'Gameplay/presentation runtime is not constrained to project-original code.'
foreach ($component in @('darkfuture','project-e3-hud')) {
    Check (@($policy.forbiddenRuntimeComponents) -contains $component) "Forbidden runtime component missing: $component"
}
foreach ($needle in @('module DarkFuture.','import DarkFuture.')) {
    Check (@($policy.forbiddenProductionSourceNamespaces) -contains $needle) "Forbidden source namespace rule missing: $needle"
}

# The redistribution-safe package is the first machine-readable production-source
# inventory. It must never list a source-mod runtime payload or a non-original file.
$package = Get-Content -Raw -LiteralPath (Join-Path $project 'manifest/package.json') | ConvertFrom-Json
foreach ($file in @($package.files)) {
    Check ($file.origin -eq 'project-original') "Package includes non-original source: $($file.source)"
    $normalized = ([string]$file.source).Replace('\\','/')
    foreach ($fragment in @($policy.forbiddenRuntimePathFragments)) {
        Check (-not $normalized.Contains($fragment.Trim('/'))) "Package source path references forbidden runtime material: $normalized"
    }
}

# Production code under src/redscript/CyberpunkRealism may not create new source-mod
# namespace dependencies. Transitional bridge files are explicitly detected here so
# CI will remain red until they are removed/replaced; this is intentional under the
# ownership pivot and prevents an old integration profile from being called owned.
$sourceRoot = Join-Path $project 'src/redscript/CyberpunkRealism'
$violations = [Collections.Generic.List[string]]::new()
Get-ChildItem -LiteralPath $sourceRoot -Filter '*.reds' -File | ForEach-Object {
    $text = Get-Content -Raw -LiteralPath $_.FullName
    foreach ($needle in @($policy.forbiddenProductionSourceNamespaces)) {
        if ($text.Contains([string]$needle)) { $violations.Add($_.Name + ' -> ' + $needle) }
    }
}
if ($violations.Count -gt 0) {
    throw "Production source still depends on source-mod namespaces:`n - $($violations -join "`n - ")"
}

Write-Host "PASS: $script:checks owned-runtime policy checks; release is locked and production source contains no Dark Future/E3 runtime ownership."
