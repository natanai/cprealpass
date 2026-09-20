$ErrorActionPreference = 'Stop'
$project = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$path = Join-Path $project 'manifest/acceptance.json'
$ledger = Get-Content -Raw -LiteralPath $path | ConvertFrom-Json
if ($ledger.schemaVersion -ne 2 -or $ledger.product -ne 'Biology') { throw 'Unexpected current Biology acceptance ledger.' }
if ($ledger.evidenceRule -notmatch '(?i)Source/CI/compile.*never.*live-game|attended evidence') { throw 'Acceptance ledger lost the evidence-tier rule.' }

$allowed = @($ledger.statusValues)
$gates = @($ledger.gates)
$ids = @{}
foreach ($gate in $gates) {
    if ([string]::IsNullOrWhiteSpace([string]$gate.id) -or $ids.ContainsKey([string]$gate.id)) { throw "Missing/duplicate acceptance gate: $($gate.id)" }
    $ids[[string]$gate.id] = $gate
    if ($allowed -notcontains $gate.status) { throw "Invalid acceptance status: $($gate.id) -> $($gate.status)" }
    if (@($gate.evidence).Count -eq 0) { throw "Acceptance gate has no evidence pointer: $($gate.id)" }
    if ([string]::IsNullOrWhiteSpace([string]$gate.remaining)) { throw "Acceptance gate has no remaining-work statement: $($gate.id)" }
}

foreach ($required in @(
    'scope-and-product-architecture',
    'official-source-first-investigation-policy',
    'redmod-package-recognition-and-deployment',
    'owned-runtime-isolation',
    'unified-settings-contract',
    'biology-native-shell-and-drilldown',
    'body-runtime-authority',
    'body-native-integration',
    'combat-impact-and-ballistics-model',
    'combat-native-activation',
    'pain-and-maxdoc-model',
    'physical-outfit-loadouts',
    'no-traditional-healthbars',
    'modern-scanner-native-acceptance',
    'owned-nameplate-presentation',
    'e3-independent-standalone-presentation',
    'dependency-redistribution-audit',
    'one-download-playable-package',
    'launcher-off-vanilla-play',
    'self-contained-hard-uninstall',
    'save-reload-upgrade-uninstall',
    'phantom-liberty-quest-compatibility',
    'performance-and-script-latency'
)) {
    if (-not $ids.ContainsKey($required)) { throw "Acceptance ledger missing required current gate: $required" }
}

if ($ids['scope-and-product-architecture'].status -ne 'passed') { throw 'Canonical Biology product architecture should be resolved.' }
if ($ids['official-source-first-investigation-policy'].status -ne 'passed') { throw 'Official-source-first investigation policy should be locked.' }
if ($ids['redmod-package-recognition-and-deployment'].status -ne 'passed') { throw 'Already-observed Biology REDmod recognition/deployment was regressed to an open gate.' }
if (($ids['redmod-package-recognition-and-deployment'].evidence -join ' ') -notmatch '8cf04566-redmod-deploy-preflight') { throw 'Accepted REDmod gate is not tied to attended deployment evidence.' }

# Native observations remain separate from repaired source/local release gates.
foreach ($id in @('biology-native-shell-and-drilldown','body-runtime-authority','owned-nameplate-presentation','e3-independent-standalone-presentation')) {
    if ($ids[$id].status -eq 'passed') { throw "$id cannot pass before a new integrated attended build accepts it." }
}
foreach ($id in @('biology-native-shell-and-drilldown','body-runtime-authority','owned-nameplate-presentation','e3-independent-standalone-presentation')) {
    if ($ids[$id].remaining -notmatch 'LIVE-ONLY' -or ($ids[$id].evidence -join ' ') -notmatch 'AUTONOMOUS-COMPLETION') { throw "$id lost the current repair/evidence boundary." }
}
if ($ids['body-runtime-authority'].remaining -notmatch 'BODY RUNTIME SYSTEM MISSING' -or $ids['body-runtime-authority'].remaining -notmatch 'source repairs') { throw 'Body authority must distinguish its historical failure from current repaired source.' }
if ($ids['owned-nameplate-presentation'].remaining -notmatch '(?i)civilian|scanner' -or $ids['e3-independent-standalone-presentation'].remaining -notmatch 'E3 ON/OFF') { throw 'Native presentation observations lost their scope.' }

if ($ids['modern-scanner-native-acceptance'].status -eq 'pending') { throw 'Attended evidence already demonstrated the modern scanner composition; gate should be partial pending regression confirmation.' }
if ($ids['modern-scanner-native-acceptance'].remaining -notmatch '(?i)reconfirm') { throw 'Scanner gate does not preserve the current positive attended evidence plus regression requirement.' }

$settings = $ids['unified-settings-contract']
if ($settings.status -ne 'passed' -or ($settings.evidence -join ' ') -notmatch 'RealpassSettings\.reds') { throw 'Provider-neutral settings semantics are no longer represented.' }
if ($settings.remaining -notmatch '(?i)no managed feature ledger|no.*per-subsystem') { throw 'Acceptance ledger does not explicitly preserve the rejected feature-ledger/per-subsystem settings boundary.' }
if ($settings.remaining -match '(?i)(expose|retain|provide)\s+(?:a\s+|the\s+)?managed feature ledger|keep\s+(?:a\s+|the\s+)?managed feature ledger') { throw 'Acceptance ledger revived the rejected feature-ledger/settings architecture.' }

$maxdoc = $ids['pain-and-maxdoc-model']
if (($maxdoc.evidence -join ' ') -notmatch 'BodyNativeHooks\.reds' -or $maxdoc.remaining -notmatch 'MaxDoc/FirstAidWhiff') { throw 'MaxDoc gate lost the vanilla item/use integration requirement.' }

$outfits = $ids['physical-outfit-loadouts']
if (($outfits.evidence -join ' ') -notmatch 'PhysicalOutfits\.reds' -or $outfits.remaining -notmatch '(?i)stash' -or $outfits.remaining -notmatch '(?i)quest') { throw 'Physical Outfit gate lost actual-item/no-stash/special-equipment behavior.' }

$dependency = $ids['dependency-redistribution-audit']
foreach ($name in @('redscript','RED4ext','ArchiveXL','Mod Settings')) {
    if ($dependency.remaining -notmatch [regex]::Escape($name)) { throw "Dependency audit gate lost current retained runtime component: $name" }
}
foreach ($name in @('TweakXL','Codeware','Input Loader')) {
    if ($dependency.remaining -notmatch [regex]::Escape($name)) { throw "Dependency audit gate lost explicit exclusion: $name" }
}

if ($ids['one-download-playable-package'].status -notin @('passed','partial','pending','blocked')) { throw 'Invalid local package completion status.' }
if ($ids['one-download-playable-package'].remaining -notmatch '(?i)runtime/UI/presentation/disable/uninstall') { throw 'Player package gate no longer names the actual remaining release blockers.' }

if ($ids['launcher-off-vanilla-play'].status -notin @('partial','pending') -or $ids['launcher-off-vanilla-play'].remaining -notmatch 'Enable mods OFF') { throw 'Launcher-off native gameplay must remain unclaimed without native observation.' }
if ($ids['self-contained-hard-uninstall'].status -ne 'passed' -or $ids['self-contained-hard-uninstall'].remaining -notmatch 'Uninstall Biology\.exe' -or ($ids['self-contained-hard-uninstall'].evidence -join ' ') -notmatch 'AUTONOMOUS-COMPLETION') { throw 'Hard uninstall must be bound to the actual shipped-binary lifecycle evidence.' }
if ($ids['save-reload-upgrade-uninstall'].remaining -notmatch '(?i)Steam reinstall is exceptional') { throw 'Acceptance ledger regressed to routine Steam reinstall as Biology removal.' }

# Retired active-looking evidence paths must not return to the current ledger.
$ledgerText = Get-Content -Raw -LiteralPath $path
foreach ($stale in @('REALISM-SPEC.md','tools/Finalize-PlayerPackage.ps1','docs/NONBIOLOGY-WORKPLAN.md','docs/ATTENDED-ACCEPTANCE.md')) {
    if ($ledgerText -match [regex]::Escape($stale)) { throw "Acceptance ledger contains retired active evidence/reference: $stale" }
}

$distribution = Get-Content -Raw -LiteralPath (Join-Path $project 'manifest/distribution.json') | ConvertFrom-Json
if ($ids['one-download-playable-package'].status -eq 'passed' -and $distribution.releaseGate.localReleaseReady -ne $true) {
    throw 'Acceptance ledger conflicts with the local release gate.'
}

$summary = $gates | Group-Object status | Sort-Object Name | ForEach-Object { "$($_.Name)=$($_.Count)" }
Write-Host "PASS: current Biology acceptance ledger has $($gates.Count) gates ($($summary -join ', ')); accepted REDmod evidence and attended follow-up boundaries remain explicit."
