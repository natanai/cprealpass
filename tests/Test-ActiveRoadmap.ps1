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
$migration = Read 'docs/BIOLOGY-REDMOD-MIGRATION.md'
$parallel = Read 'docs/PARALLEL-AGENT-WORKFLOW.md'
$handoffIndex = Read 'docs/handoffs/README.md'

Require $root 'CURRENT ROADMAP' 'Root ROADMAP.md must remain the obvious active-work entry point.'
Require $root '#39' 'Root roadmap must expose the attended Biology UI follow-up.'
Require $root 'agent/biology-ui-attended-followup' 'Root roadmap must name the active Biology UI follow-up branch.'
Require $root '#40' 'Root roadmap must expose the attended presentation follow-up.'
Require $root 'agent/presentation-attended-followup' 'Root roadmap must name the active presentation follow-up branch.'
Require $root '#41' 'Root roadmap must expose the attended body-runtime follow-up.'
Require $root 'agent/body-runtime-attended-followup' 'Root roadmap must name the active body-runtime follow-up branch.'
Require $root '#44' 'Root roadmap must expose the player disable/uninstall lane.'
Require $root 'agent/player-uninstall-vanilla-toggle' 'Root roadmap must name the player disable/uninstall branch.'
Require $root '8cf045664b5e4d8b4b014edfc98bf2f8eb270ba5' 'Root roadmap must tie current attended findings to the exact integrated artifact source revision.'

Require $roadmap 'BODY RUNTIME SYSTEM MISSING' 'Active follow-up ledger must retain the observed body-runtime failure.'
Require $roadmap 'overview.*detail.*Back|Back/Cancel' 'Active follow-up ledger must retain Biology drill-down back-navigation acceptance.'
Require $roadmap 'random civilian' 'Active follow-up ledger must retain the civilian ambient-nameplate failure.'
Require $roadmap 'modern scanner/quickhack' 'Active follow-up ledger must retain the scanner preserve requirement.'
Require $roadmap 'Uninstall Biology\.exe' 'Active follow-up ledger must include the self-contained player-uninstall target.'

# Historical attended evidence remains immutable evidence even though it is not current guidance.
Require $baseline 'ec8ba06451c3cbacabfad24f1479e1537147d0c9' 'Pre-REDmod baseline must stay tied to the exact historical tested revision.'
Require $baseline 'Body state is unavailable' 'Historical baseline must retain the body-state observation that actually occurred.'
Require $baseline 'E3-inspired first-person HUD recreation is not visibly present' 'Historical baseline must retain the original presentation failure.'

# Merged original worker lanes must not be resurrected by active docs/tests.
$activeGuidance = @($root,$roadmap,$migration,$parallel,$handoffIndex) -join "`n"
foreach ($oldBranch in @(
    'agent/redmod-foundation',
    'agent/biology-ui-runtime',
    'agent/presentation-hud-nameplates'
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

Write-Host 'PASS: active guidance points at current attended follow-ups while dated historical evidence remains preserved.'
