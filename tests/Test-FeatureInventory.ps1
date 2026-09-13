$ErrorActionPreference = 'Stop'
$project = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$modulePath = Join-Path $project 'manifest/runtime-modules.json'
$inventoryPath = Join-Path $project 'manifest/feature-inventory.json'
if (-not (Test-Path -LiteralPath $modulePath) -or -not (Test-Path -LiteralPath $inventoryPath)) {
    throw 'Missing runtime module or feature inventory contract.'
}

$modules = Get-Content -Raw -LiteralPath $modulePath | ConvertFrom-Json
$inventory = Get-Content -Raw -LiteralPath $inventoryPath | ConvertFrom-Json
if ($inventory.schemaVersion -ne 1) { throw 'Unexpected feature inventory schema.' }

$moduleIds = @($modules.modules | ForEach-Object id)
$allowed = @($inventory.allowedDispositions)
$features = @($inventory.features)
$ids = @{}
foreach ($feature in $features) {
    if ([string]::IsNullOrWhiteSpace($feature.id)) { throw 'Feature without id.' }
    if ($ids.ContainsKey($feature.id)) { throw "Duplicate feature id: $($feature.id)" }
    $ids[$feature.id] = $feature
    if ($allowed -notcontains $feature.disposition) { throw "Invalid disposition for $($feature.id): $($feature.disposition)" }
    if ($feature.disposition -in @('retain','replace','development-only')) {
        if ($feature.disposition -ne 'remove' -and [string]::IsNullOrWhiteSpace($feature.owner) -and $feature.id -notin @('darkfuture-item-renames')) {
            throw "Retained/replaced feature lacks a realpass owner or explicit removal-only rationale: $($feature.id)"
        }
        if (-not [string]::IsNullOrWhiteSpace($feature.owner) -and $moduleIds -notcontains $feature.owner) {
            throw "Feature owner is not a declared realpass module: $($feature.id) / $($feature.owner)"
        }
    }
    if ([string]::IsNullOrWhiteSpace($feature.targetState)) { throw "Feature missing target state: $($feature.id)" }
}

foreach ($required in @(
    'darkfuture-basic-needs',
    'darkfuture-legacy-injury-condition',
    'darkfuture-item-renames',
    'darkfuture-fast-travel-restrictions',
    'darkfuture-economy-prices',
    'source-mod-outfit-transmog-layer',
    'e3-npc-nameplates',
    'e3-hud-aesthetic',
    'e3-scanner-overrides',
    'realpass-body-model',
    'realpass-ballistics-wounds',
    'realpass-regional-injury-care',
    'realpass-pain-maxdoc',
    'realpass-physical-protection'
)) {
    if (-not $ids.ContainsKey($required)) { throw "Feature inventory missing: $required" }
}

foreach ($id in @(
    'darkfuture-item-renames',
    'darkfuture-reduced-carry-weight',
    'darkfuture-stamina-recovery-penalty',
    'darkfuture-fast-travel-restrictions',
    'darkfuture-fast-travel-marker-hiding',
    'darkfuture-vehicle-summon-limits',
    'darkfuture-sleep-random-encounters',
    'darkfuture-nerve-fatality',
    'darkfuture-humanity-cyberpsychosis',
    'darkfuture-addictions',
    'darkfuture-economy-prices',
    'darkfuture-consumable-weight-rebalance',
    'source-mod-outfit-transmog-layer',
    'e3-scanner-overrides'
)) {
    if ($ids[$id].disposition -ne 'remove') { throw "Out-of-scope/extraneous feature is not marked for removal: $id" }
}

foreach ($id in @('darkfuture-basic-needs','darkfuture-needs-ui','darkfuture-consumable-intake','darkfuture-legacy-injury-condition')) {
    if ($ids[$id].disposition -ne 'replace') { throw "Source-mod runtime behavior must be replaced, not adapted/retained: $id" }
}

foreach ($id in @('realpass-body-model','realpass-ballistics-wounds','realpass-regional-injury-care','realpass-pain-maxdoc','realpass-physical-protection')) {
    if ($ids[$id].disposition -ne 'retain' -or $ids[$id].source -ne 'project-original') { throw "Project-original core feature is not retained as project-original: $id" }
}
if ($ids['e3-npc-nameplates'].disposition -ne 'replace' -or $ids['e3-hud-aesthetic'].disposition -ne 'replace') {
    throw 'E3-dependent presentation must be replaced by realpass-owned behavior before standalone release.'
}
if ($ids['development-diagnostics'].disposition -ne 'development-only' -or $ids['development-diagnostics'].owner -ne 'diagnostics') {
    throw 'Diagnostics must remain development-only.'
}
if ($allowed -contains 'adapt') {
    throw 'Feature inventory still permits source-mod adaptation as a final runtime disposition.'
}
if ($ids['realpass-pain-maxdoc'].targetState -notmatch 'MaxDoc/FirstAidWhiff' -or $ids['darkfuture-item-renames'].targetState -notmatch 'preserve vanilla') {
    throw 'Vanilla medical-item identity is not explicit in feature inventory.'
}

Write-Host "PASS: realpass vanilla-first feature consolidation inventory ($($features.Count) tracked features)."
