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
$patterns = Read 'docs/AGENT-OPERATING-PATTERNS.md'
$migration = Read 'docs/BIOLOGY-REDMOD-MIGRATION.md'
$parallel = Read 'docs/PARALLEL-AGENT-WORKFLOW.md'
$handoffIndex = Read 'docs/handoffs/README.md'

Require $root 'CURRENT ROADMAP' 'Root ROADMAP.md must remain the obvious active-work entry point.'
Require $root 'docs/THREAD-LEDGER\.md' 'Root roadmap must defer live conversation/assignment state to THREAD-LEDGER.md.'
Require $root 'current GitHub issues/PRs|current open GitHub issues/PRs' 'Root roadmap must defer live implementation state to GitHub.'
Require $root 'W11\.1' 'Root roadmap must preserve completed W11 transition provenance.'
Require $root '#64' 'Root roadmap must preserve the historical W11 issue identity.'
Require $root 'PR #65' 'Root roadmap must preserve the merged W11 pull request identity.'
Require $root 'SAFE-TO-APPLY' 'Root roadmap must preserve the attended W11 transition decision.'
Require $root 'docs/operator-evidence' 'Root roadmap must point to durable operator evidence.'
Require $root '04d4c1584df4b0823e093422b98cf4c5575c7b19' 'Root roadmap must preserve exact failed-install source provenance.'
Require $root '#39' 'Root roadmap must preserve Biology UI attended acceptance.'
Require $root '#40' 'Root roadmap must preserve presentation attended acceptance.'
Require $root '#41' 'Root roadmap must preserve body-runtime attended acceptance.'
Require $root '#44' 'Root roadmap must preserve player disable/uninstall attended acceptance.'
Require $root '8cf045664b5e4d8b4b014edfc98bf2f8eb270ba5' 'Root roadmap must preserve provenance for the first integrated attended findings.'
Require $root '7e61724071b8c95ba5c334ab9e8d11c43381c94e|pre-W10 transition provenance' 'Root roadmap must preserve pre-W10 transition provenance.'
Reject $root 'There is currently \*\*no active worker implementation lane\*\*' 'Root roadmap must not freeze an obsolete no-worker state.'

Require $roadmap 'docs/THREAD-LEDGER\.md' 'Active follow-up roadmap must defer live conversation/assignment state to THREAD-LEDGER.md.'
Require $roadmap 'current GitHub issues/PRs|GitHub.*authoritative for implementation state' 'Active follow-up roadmap must defer live implementation state to GitHub.'
Require $roadmap 'W11 / PR #65|W11.*PR #65' 'Active follow-up roadmap must preserve completed W11 transition provenance.'
Require $roadmap '#64' 'Active follow-up roadmap must preserve issue #64 as historical provenance.'
Require $roadmap 'SAFE-TO-APPLY' 'Active follow-up roadmap must preserve the successful W11 read-only decision.'
Require $roadmap 'Mod Settings.*ArchiveXL.*RED4ext|Mod Settings / ArchiveXL / RED4ext' 'Active follow-up roadmap must describe the retired pre-W10 dependency footprint.'
Require $roadmap 'redscript.*preserv|redscript.*remain|redscript must remain' 'Active follow-up roadmap must protect retained redscript.'
Require $roadmap 'repo-backed|repository evidence|docs/operator-evidence' 'Active follow-up roadmap must describe durable operator evidence.'
Require $roadmap 'empty.*Biology-owned roots|empty-owned-roots' 'Active follow-up roadmap must preserve the bounded missing-ZIP recovery boundary.'
Require $roadmap 'shared redscript/cybercmd.*preserve|redscript/cybercmd remains preserve' 'Active follow-up roadmap must preserve shared runtime dependencies.'
Require $roadmap 'BODY RUNTIME SYSTEM MISSING' 'Active follow-up roadmap must retain the observed body-runtime acceptance target.'
Require $roadmap 'overview.*detail.*Back|Back.*overview' 'Active follow-up roadmap must retain Biology drill-down back-navigation acceptance.'
Require $roadmap 'civilian' 'Active follow-up roadmap must retain civilian ambient-nameplate acceptance.'
Require $roadmap 'modern scanner/quickhack' 'Active follow-up roadmap must retain the scanner preserve requirement.'
Require $roadmap 'hard uninstall' 'Active follow-up roadmap must retain the player hard-uninstall target.'
Reject $roadmap 'There is currently \*\*no active worker implementation lane\*\*' 'Active follow-up roadmap must not freeze an obsolete no-worker state.'

# The ledger may legitimately change which worker is ACTIVE from one PR to the next.
# This test checks durable numbering/routing semantics, not today's transient worker.
Require $ledger 'canonical active conversation/lane registry' 'Thread ledger must remain the canonical conversation registry.'
Require $patterns 'W15\.1\s*->\s*issue #72[\s\S]*W15\.2\s*->\s*issue #74' 'Operating patterns must preserve same-conversation sequential assignment semantics with distinct Git ownership.'
Require $patterns 'W16\.1' 'Operating patterns must define newly opened worker conversation numbering.'
Reject $patterns 'W06\.1\s*->\s*W06\.2' 'Operating patterns must not use worker .2 as replacement-chat numbering.'

# Historical attended evidence remains immutable evidence even though it is not current guidance.
Require $baseline 'ec8ba06451c3cbacabfad24f1479e1537147d0c9' 'Pre-REDmod baseline must stay tied to the exact historical tested revision.'
Require $baseline 'Body state is unavailable' 'Historical baseline must retain the body-state observation that actually occurred.'
Require $baseline 'E3-inspired first-person HUD recreation is not visibly present' 'Historical baseline must retain the original presentation failure.'

# Merged worker branches must not be resurrected as current assignments by
# roadmap/policy surfaces. Historical ledger rows are intentionally excluded.
$activeGuidance = @($root,$roadmap,$migration,$parallel,$handoffIndex) -join "`n"
foreach ($oldBranch in @(
    'agent/redmod-foundation',
    'agent/biology-ui-runtime',
    'agent/presentation-hud-nameplates',
    'agent/biology-ui-attended-followup',
    'agent/presentation-attended-followup',
    'agent/body-runtime-attended-followup',
    'agent/player-uninstall-vanilla-toggle',
    'agent/pre-w10-framework-transition-cleanup'
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
Require $parallel 'does \*\*not\*\* hard-code current worker branch names|does not.*hard-code current worker branch names' 'Parallel policy must remain branch-agnostic for live implementation state.'
Require $parallel 'THREAD-LEDGER\.md' 'Parallel policy must expose the canonical conversation registry.'
Require $handoffIndex 'issue-specific and temporary' 'Handoff index must explain that merged worker packets are retired rather than canonical forever.'

Write-Host 'PASS: active guidance preserves durable historical/product invariants, defers live worker state to THREAD-LEDGER/GitHub, and does not freeze transient worker assignments into roadmap CI.'
