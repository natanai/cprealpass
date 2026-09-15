$ErrorActionPreference = 'Stop'
$project = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))

function Read([string]$relative) {
    $path = Join-Path $project $relative
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Missing Biology direction file: $relative" }
    Get-Content -Raw -LiteralPath $path
}
function Require([string]$text,[string]$pattern,[string]$message) {
    if ($text -notmatch $pattern) { throw $message }
}

$agents = Read 'AGENTS.md'
$goals = Read 'AGREED-GOALS.md'
$migration = Read 'docs/BIOLOGY-REDMOD-MIGRATION.md'
$parallel = Read 'docs/PARALLEL-AGENT-WORKFLOW.md'
$release = Read 'docs/RELEASE-ARCHITECTURE.md'
$settings = Read 'docs/SETTINGS-ARCHITECTURE.md'
$history = Read 'docs/DECISION-HISTORY.md'

Require $agents '^# Biology agent instructions' 'AGENTS.md must identify Biology as the current product.'
Require $agents 'PARALLEL WORK GATE' 'AGENTS.md must make parallel work a prominent gate.'
Require $agents '2–3 agents concurrently|2-3 agents concurrently' 'AGENTS.md must acknowledge the owner can use 2–3 concurrent agents.'
Require $agents 'copy/paste-ready handoff' 'Agents must proactively provide handoffs for safe parallel work.'
Require $agents 'own branch' 'Parallel lanes must use separate branches.'
Require $agents 'official REDmod' 'AGENTS.md must make official REDmod the preferred route where robust.'
Require $agents 'mods/Biology' 'AGENTS.md must expose the preferred self-contained package identity.'

Require $goals '^# Biology — agreed goals ledger' 'Canonical goals must use Biology product identity.'
Require $goals 'G-005 — “Biology” is the organizing product concept' 'Goals must define Biology as the whole-overhaul concept.'
Require $goals 'G-013 — Official REDmod is the preferred final packaging/runtime route' 'Goals must lock REDmod-first direction.'
Require $goals 'G-014 — Minimize dependency depth' 'Goals must lock dependency minimization.'
Require $goals 'G-015 — Biology is authoritative where it intentionally overlaps' 'Goals must describe bounded authoritative overlap.'
Require $goals 'G-016 — Final package identity should be self-contained and obvious' 'Goals must require self-contained package identity.'
Require $goals 'G-093 — Parallel agents are a normal project resource' 'Goals must lock parallel branch workflow for large separable work.'

foreach ($classification in @('REDMOD-NATIVE','REDMOD-POSSIBLE-BUT-BRITTLE','REDSCRIPT-BETTER','REQUIRES-NATIVE-EXTENSION','REMOVE/RETHINK','UNKNOWN — NEEDS DIRECT GAME PROBE')) {
    Require $migration ([regex]::Escape($classification)) "Missing REDmod migration classification: $classification"
}
Require $migration 'REDmod-first does not mean REDmod-only' 'Migration plan must explicitly reject ideological REDmod-only routing.'
Require $migration 'Do not preserve a framework stack merely to host two booleans' 'Migration plan must scrutinize settings-only dependencies.'
Require $migration 'Lane A — REDmod/package/dependency audit' 'Migration plan must expose an initial parallel lane split.'

Require $parallel 'Core rule' 'Parallel workflow must define the proactive split rule.'
Require $parallel 'When not to split' 'Parallel workflow must also define unsafe parallelism.'
Require $parallel 'Required handoff packet for a new agent/thread' 'Parallel workflow must define handoff contents.'
Require $parallel 'one attended combined test|one combined release-shaped candidate' 'Parallel branches must converge before broad attended testing.'
Require $parallel 'Lane A — official REDmod/package/dependency architecture' 'Parallel workflow must define the REDmod packaging lane.'
Require $parallel 'Lane B — runtime seam classification/migration' 'Parallel workflow must define the runtime seam lane.'
Require $parallel 'Lane C — Biology product/UI/settings identity' 'Parallel workflow must define the product/UI lane.'

Require $release '^# Biology release and installation architecture' 'Release architecture must use Biology identity.'
Require $release 'mods/Biology' 'Release target must prefer one Biology REDmod package.'
Require $release 'REDmod-first does not mean REDmod-only' 'Release architecture must preserve the narrow-wrapper exception.'
Require $release 'Current clean-room builder is transitional' 'Old root-package builder must not be mistaken for final architecture.'

Require $settings '^# Biology configuration architecture' 'Settings architecture must use Biology identity.'
Require $settings 'provider is no longer locked to Mod Settings|Provider is not product architecture' 'Settings provider must be migration-neutral.'
Require $settings 'Do not preserve a framework stack merely to host two booleans' 'Settings architecture must not justify dependency depth by convenience.'

Require $history 'the product is named Biology' 'Decision history must record the product rename.'
Require $history 'multi-agent parallel branches are the normal workflow' 'Decision history must record the parallel-development decision.'
Require $history 'official REDmod should be the default route' 'Decision history must record the REDmod-first correction.'

Write-Host 'PASS: Biology identity, REDmod-first/self-contained migration, bounded overlap, dependency minimization, and proactive parallel-agent branch workflow are canonical and cross-documented.'
