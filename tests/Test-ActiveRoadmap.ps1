$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\tools\Common.ps1"
$project = Get-ProjectRoot

function Read([string]$relative) {
    $path = Join-Path $project $relative
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Missing active-roadmap file: $relative" }
    Get-Content -Raw -LiteralPath $path
}
function Require([string]$text,[string]$pattern,[string]$message) {
    if ($text -notmatch $pattern) { throw $message }
}
function Reject([string]$text,[string]$pattern,[string]$message) {
    if ($text -match $pattern) { throw $message }
}

$root = Read 'ROADMAP.md'
$baseline = Read 'docs/PRE-REDMOD-LIVE-BASELINE-2026-09-15.md'
$roadmap = Read 'docs/ACTIVE-REDMOD-ROADMAP.md'
$ledger = Read 'docs/THREAD-LEDGER.md'
$migration = Read 'docs/BIOLOGY-REDMOD-MIGRATION.md'
$parallel = Read 'docs/PARALLEL-AGENT-WORKFLOW.md'
$handoffIndex = Read 'docs/handoffs/README.md'

Require $root 'CURRENT ROADMAP' 'Root ROADMAP.md must remain the obvious active-work entry point.'
Require $root 'P01\.2' 'Root roadmap must identify the active parent generation.'
Require $root 'W11\.1' 'Root roadmap must expose the current transition worker lane.'
Require $root '#64' 'Root roadmap must expose the legacy-framework transition issue.'
Require $root 'agent/pre-w10-framework-transition-cleanup' 'Root roadmap must name the current W11 transition branch.'
Require $root '#39' 'Root roadmap must preserve Biology UI attended acceptance.'
Require $root '#40' 'Root roadmap must preserve presentation attended acceptance.'
Require $root '#41' 'Root roadmap must preserve body-runtime attended acceptance.'
Require $root '#44' 'Root roadmap must preserve player disable/uninstall attended acceptance.'
Require $root '#59' 'Root roadmap must preserve W09 REDmod attended acceptance.'
Require $root '8cf045664b5e4d8b4b014edfc98bf2f8eb270ba5' 'Root roadmap must preserve provenance for the first integrated attended findings.'
Require $root '7e61724071b8c95ba5c334ab9e8d11c43381c94e|pre-W10 candidate' 'Root roadmap must preserve the current installed-state transition provenance.'

Require $roadmap 'W11\.1' 'Active follow-up ledger must expose the current W11 transition lane.'
Require $roadmap '#64' 'Active follow-up ledger must expose issue #64.'
Require $roadmap 'Mod Settings.*ArchiveXL.*RED4ext|Mod Settings / ArchiveXL / RED4ext' 'Active follow-up ledger must describe the retired pre-W10 dependency footprint.'
Require $roadmap 'redscript.*remain|redscript must remain' 'Active follow-up ledger must protect the retained redscript dependency.'
Require $roadmap 'BODY RUNTIME SYSTEM MISSING' 'Active follow-up ledger must retain the observed body-runtime failure.'
Require $roadmap 'overview.*detail.*Back|Back/Cancel' 'Active follow-up ledger must retain Biology drill-down back-navigation acceptance.'
Require $roadmap 'civilian' 'Active follow-up ledger must retain the civilian ambient-nameplate acceptance requirement.'
Require $roadmap 'modern scanner/quickhack' 'Active follow-up ledger must retain the scanner preserve requirement.'
Require $roadmap 'hard uninstall|Uninstall Biology\.exe' 'Active follow-up ledger must retain the player hard-uninstall target.'
Require $ledger 'W11\.1' 'Thread ledger must identify W11.1 as the current transition worker.'
Require $ledger 'ACTIVE.*IN-PROGRESS' 'Thread ledger must record an active in-progress worker state.'

# Historical attended evidence remains immutable evidence even though it is not current guidance.
Require $baseline 'ec8ba06451c3cbacabfad24f1479e1537147d0c9' 'Pre-REDmod baseline must stay tied to the exact historical tested revision.'
Require $baseline 'Body state is unavailable' 'Historical baseline must retain the body-state observation that actually occurred.'
Require $baseline 'E3-inspired first-person HUD recreation is not visibly present' 'Historical baseline must retain the original presentation failure.'

# Merged worker branches must not be resurrected by active docs/tests.
$activeGuidance = @($root,$roadmap,$migration,$parallel,$handoffIndex) -join "`n"
foreach ($oldBranch in @(
    'agent/redmod-foundation',
    'agent/biology-ui-runtime',
    'agent/presentation-hud-nameplates',
    'agent/biology-ui-attended-followup',
    'agent/presentation-attended-followup',
    'agent/body-runtime-attended-followup',
    'agent/player-uninstall-vanilla-toggle'
)) {
    Reject $activeGuidance ([regex]::Escape($oldBranch)) "Active guidance still presents merged branch as current: $oldBranch"
}

foreach ($retired in @(
    'docs/handoffs/REDMOD-FOUNDATION.md',
    'docs/handoffs/BIOLOGY-UI-RUNTIME.md',
    'docs/handoffs/PRESENTATION-HUD-NAMEPLATES.md'
)) {
    $path = Join-Path $project $retired
    if (Test-Path -LiteralPath $path) { throw "Merged worker handoff must not remain as active file: $retired" }
}

Require $migration 'does \*\*not\*\* define current worker branch names|does \*\*not\*\* hard-code current worker branch names|does not.*current worker branch names' 'Architecture doc must defer live branch state to roadmap/issues.'
Require $parallel 'Current code work still belongs.*current GitHub issues/PRs|does \*\*not\*\* hard-code current worker branch names|does not.*hard-code current worker branch names' 'Parallel policy must remain branch-agnostic for implementation state while delegating conversation state to THREAD-LEDGER.md.'
Require $parallel 'THREAD-LEDGER\.md' 'Parallel policy must expose the canonical conversation registry.'
Require $handoffIndex 'issue-specific and temporary' 'Handoff index must explain that merged worker packets are retired rather than canonical forever.'

Write-Host 'PASS: active guidance identifies P01.2/W11 transition work, preserves attended acceptance, and does not resurrect merged worker branches.'
