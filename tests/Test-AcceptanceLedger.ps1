$ErrorActionPreference = 'Stop'
$project = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$path = Join-Path $project 'manifest/acceptance.json'
$ledger = Get-Content -Raw -LiteralPath $path | ConvertFrom-Json
if ($ledger.schemaVersion -ne 1 -or $ledger.product -ne 'realpass') { throw 'Unexpected acceptance ledger.' }
$allowed = @($ledger.statusValues)
$gates = @($ledger.gates)
$ids = @{}
foreach ($gate in $gates) {
    if ([string]::IsNullOrWhiteSpace($gate.id) -or $ids.ContainsKey($gate.id)) { throw "Missing/duplicate acceptance gate: $($gate.id)" }
    $ids[$gate.id] = $gate
    if ($allowed -notcontains $gate.status) { throw "Invalid acceptance status: $($gate.id) -> $($gate.status)" }
    if (@($gate.evidence).Count -eq 0) { throw "Acceptance gate has no evidence pointer: $($gate.id)" }
    if ([string]::IsNullOrWhiteSpace($gate.remaining)) { throw "Acceptance gate has no remaining-work statement: $($gate.id)" }
}

foreach ($required in @(
    'owned-runtime-isolation',
    'vanilla-first-native-integration',
    'body-native-integration',
    'combat-impact-and-ballistics-model',
    'combat-native-activation',
    'pain-and-maxdoc-model',
    'condition-ui-and-treatment',
    'owned-nameplate-presentation',
    'no-traditional-healthbars',
    'modern-scanner-native-acceptance',
    'e3-independent-standalone-presentation',
    'one-download-playable-package',
    'save-reload-upgrade-uninstall',
    'phantom-liberty-quest-compatibility'
)) {
    if (-not $ids.ContainsKey($required)) { throw "Acceptance ledger missing required gate: $required" }
}

# Source implementation can be complete while native/runtime acceptance remains open.
foreach ($id in @('owned-runtime-isolation','body-native-integration','combat-native-activation','pain-and-maxdoc-model','condition-ui-and-treatment','owned-nameplate-presentation','no-traditional-healthbars','e3-independent-standalone-presentation')) {
    if ($ids[$id].status -eq 'passed') { throw "$id cannot pass before fresh completion-candidate native acceptance evidence." }
}
if ($ids['one-download-playable-package'].status -eq 'passed') { throw 'Playable one-download package cannot pass while public release remains gated.' }
if ($ids['unified-settings-contract'].status -ne 'passed') { throw 'Locked authored release/settings contract should remain resolved unless product intent changes.' }
if ($ids['e3-independent-standalone-presentation'].status -eq 'blocked') { throw 'Source-mod-independent presentation implementation exists; this gate should now await native acceptance rather than claim an implementation blocker.' }

$maxdoc = $ids['pain-and-maxdoc-model']
if (($maxdoc.evidence -join ' ') -notmatch 'BodyNativeHooks\.reds' -or $maxdoc.remaining -notmatch 'MaxDoc/FirstAidWhiff') {
    throw 'MaxDoc acceptance gate does not explicitly track the vanilla FirstAidWhiff native integration.'
}
$vanilla = $ids['vanilla-first-native-integration']
if (($vanilla.evidence -join ' ') -notmatch 'AGREED-GOALS\.md') {
    throw 'Vanilla-first gate is not tied to canonical product intent.'
}
$biology = $ids['condition-ui-and-treatment']
if (($biology.evidence -join ' ') -notmatch 'BIOLOGY-UI\.md' -or $biology.remaining -notmatch 'Biology') {
    throw 'Condition/treatment gate is not migrated to the canonical Biology architecture.'
}
$nameplates = $ids['owned-nameplate-presentation']
if (($nameplates.evidence -join ' ') -notmatch 'NameplatesNative\.reds') {
    throw 'Owned nameplate gate does not point to the realpass-native implementation.'
}

$distribution = Get-Content -Raw -LiteralPath (Join-Path $project 'manifest/distribution.json') | ConvertFrom-Json
if ($distribution.releaseGate.publicPlayableArtifactReady -eq $false -and $ids['one-download-playable-package'].status -notin @('pending','blocked','partial')) {
    throw 'Acceptance ledger conflicts with distribution release gate.'
}

$summary = $gates | Group-Object status | Sort-Object Name | ForEach-Object { "$($_.Name)=$($_.Count)" }
Write-Host "PASS: acceptance ledger has $($gates.Count) gates ($($summary -join ', '))."