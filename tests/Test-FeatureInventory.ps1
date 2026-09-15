$ErrorActionPreference = 'Stop'
$project = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$modulePath = Join-Path $project 'manifest/runtime-modules.json'
$inventoryPath = Join-Path $project 'manifest/feature-inventory.json'
if (-not (Test-Path -LiteralPath $modulePath) -or -not (Test-Path -LiteralPath $inventoryPath)) {
    throw 'Missing runtime module or feature inventory contract.'
}

$modules = Get-Content -Raw -LiteralPath $modulePath | ConvertFrom-Json
$inventory = Get-Content -Raw -LiteralPath $inventoryPath | ConvertFrom-Json
if ($inventory.schemaVersion -ne 2 -or $inventory.product -ne 'Biology') { throw 'Unexpected current Biology feature inventory schema/product.' }
if ($inventory.idCompatibilityNote -notmatch '(?i)historical realpass prefix.*internal compatibility') { throw 'Feature inventory does not explain retained legacy realpass ids.' }
if ($inventory.purpose -match '(?i)owned realpass target|realpass starts') { throw 'Feature inventory purpose still advertises RealPass as the product.' }

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
        if ([string]::IsNullOrWhiteSpace($feature.owner) -and $feature.id -notin @('darkfuture-item-renames')) {
            throw "Retained/replaced feature lacks a Biology owner or explicit removal-only rationale: $($feature.id)"
        }
        if (-not [string]::IsNullOrWhiteSpace($feature.owner) -and $moduleIds -notcontains $feature.owner) {
            throw "Feature owner is not a declared Biology runtime module: $($feature.id) / $($feature.owner)"
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
    'realpass-physical-outfit-loadouts',
    'e3-npc-nameplates',
    'e3-hud-aesthetic',
    'e3-scanner-overrides',
    'realpass-settings-presence',
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

foreach ($id in @('realpass-physical-outfit-loadouts','realpass-settings-presence','realpass-body-model','realpass-ballistics-wounds','realpass-regional-injury-care','realpass-pain-maxdoc','realpass-physical-protection')) {
    if ($ids[$id].disposition -ne 'retain' -or $ids[$id].source -ne 'project-original') { throw "Project-original Biology feature is not retained as project-original: $id" }
}
if ($ids['e3-npc-nameplates'].disposition -ne 'replace' -or $ids['e3-hud-aesthetic'].disposition -ne 'replace') {
    throw 'E3 reference presentation must be replaced by Biology-owned behavior before standalone release.'
}
if ($ids['e3-npc-nameplates'].currentState -notmatch '(?i)random civilian' -or $ids['e3-npc-nameplates'].currentState -notmatch 'PR #46') {
    throw 'Nameplate inventory does not record the current attended failure and #40/PR #46 follow-up.'
}
if ($ids['e3-hud-aesthetic'].currentState -notmatch '(?i)modern retail HUD' -or $ids['e3-hud-aesthetic'].targetState -notmatch '(?i)modern scanner') {
    throw 'E3 HUD inventory does not record the current attended failure/modern-scanner preserve rule.'
}
if ($ids['development-diagnostics'].disposition -ne 'development-only' -or $ids['development-diagnostics'].owner -ne 'diagnostics') {
    throw 'Diagnostics must remain development-only.'
}
if ($allowed -contains 'adapt') { throw 'Feature inventory still permits source-mod adaptation as a final runtime disposition.' }
if ($ids['realpass-pain-maxdoc'].targetState -notmatch 'MaxDoc/FirstAidWhiff' -or $ids['darkfuture-item-renames'].targetState -notmatch 'preserve vanilla') {
    throw 'Vanilla medical-item identity is not explicit in feature inventory.'
}

$outfit = $ids['realpass-physical-outfit-loadouts']
if ($outfit.owner -ne 'armor' -or $outfit.targetState -notmatch '(?i)actual carried items' -or $outfit.targetState -notmatch '(?i)stash' -or $outfit.targetState -notmatch '(?i)transmog') {
    throw 'Physical Outfit feature does not preserve actual carried-equipment/protection identity without stash/transmog authority.'
}
if ($ids['source-mod-outfit-transmog-layer'].disposition -ne 'remove') {
    throw 'Parallel source-mod transmog authority must remain removed even though vanilla Outfit UX is retained as physical loadouts.'
}
$settings = $ids['realpass-settings-presence']
if ($settings.owner -ne 'presentation' -or $settings.currentState -notmatch 'Enable Biology' -or $settings.currentState -notmatch 'E3-inspired HUD \+ nameplates' -or $settings.currentState -notmatch '(?i)no subsystem ledger' -or $settings.targetState -notmatch '(?i)provider choice may change') {
    throw 'Legacy-stable settings feature id no longer describes the current minimal provider-neutral Biology surface.'
}

$inventoryText = Get-Content -Raw -LiteralPath $inventoryPath
if ($inventoryText -match '(?i)managed feature ledger|broad HUD replacement is not required|stock modern UI plus realpass-owned') {
    throw 'Feature inventory still contains superseded settings or E3 presentation conclusions.'
}

Write-Host "PASS: Biology vanilla-first feature consolidation inventory ($($features.Count) tracked features), including current attended E3 findings, owned physical Outfit loadouts, and minimal provider-neutral settings."
