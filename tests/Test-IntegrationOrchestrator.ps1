$ErrorActionPreference = 'Stop'
$project = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))

function Read([string]$relative) {
    $path = Join-Path $project $relative
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Missing integration-orchestrator file: $relative" }
    Get-Content -Raw -LiteralPath $path
}
function Require([string]$text,[string]$pattern,[string]$message) {
    if ($text -notmatch $pattern) { throw $message }
}

$agents = Read 'AGENTS.md'
$roadmap = Read 'ROADMAP.md'
$ledger = Read 'docs/THREAD-LEDGER.md'
$orchestrator = Read 'docs/INTEGRATION-ORCHESTRATOR.md'
$parallel = Read 'docs/PARALLEL-AGENT-WORKFLOW.md'
$template = Read 'docs/test-runs/README.md'
$handoff = Read 'docs/handoffs/PARENT-INTEGRATION.md'

Require $agents 'PARENT INTEGRATION GATE' 'AGENTS.md must make parent integration responsibility explicit.'
Require $agents 'docs/INTEGRATION-ORCHESTRATOR\.md' 'AGENTS.md must direct parent/integration agents to the canonical orchestration policy.'
Require $roadmap 'Parent integration/orchestration thread' 'Root roadmap must expose the parent integration thread.'
Require $roadmap 'docs/test-runs/' 'Root roadmap must preserve durable attended-test records.'
Require $roadmap 'docs/handoffs/PARENT-INTEGRATION\.md' 'Root roadmap must expose the copy/paste parent-thread handoff.'

foreach ($required in @(
    'Thread/lane continuity',
    'Merge orchestration',
    'Local-test orchestration',
    'Evidence capture',
    'Finding triage',
    'Redistribution',
    'Route A — return to the original worker lane/thread',
    'Route C — cross-lane integration issue',
    'Route D — parent handles a tiny integration-only fix',
    'docs/test-runs/',
    'exact canonical `main` SHA',
    'THREAD-LEDGER.md'
)) {
    Require $orchestrator ([regex]::Escape($required)) "Integration orchestrator policy lost required contract: $required"
}

Require $orchestrator 'Route B — new follow-up branch/thread for the same subsystem|Route B — new follow-up branch for the same subsystem' 'Parent policy must retain a new-follow-up route.'
Require $orchestrator 'not.*fourth broad implementation lane|not primarily a feature-development lane' 'Parent thread must remain coordination-focused rather than silently becoming another feature lane.'
Require $orchestrator 'short-lived integration branch' 'Parent policy must support temporary combined integration branches when risk is high.'
Require $orchestrator 'original agent' 'Parent policy must explicitly support returning attended findings to the original implementation agent when appropriate.'
Require $orchestrator 'new agent/thread' 'Parent policy must explicitly support creating a fresh follow-up lane when the original context is no longer appropriate.'
Require $orchestrator 'MILESTONE CLEAN-ROOM' 'Parent policy must preserve clean-room escalation.'
Require $orchestrator 'ITERATION' 'Parent policy must preserve iteration-test reuse when baseline proof is available.'

Require $ledger 'canonical active conversation/lane registry' 'Canonical thread ledger is missing or no longer authoritative.'
Require $ledger 'TOO-LONG' 'Thread ledger must support explicit too-long handoff state.'
Require $parallel 'MANDATORY THREAD REGISTRY' 'Worker workflow must require the thread ledger.'

Require $template 'Canonical main SHA:' 'Attended test template must bind evidence to exact main.'
Require $template 'Artifact/package:' 'Attended test template must bind evidence to an exact artifact.'
Require $template 'Owner / route' 'Attended test template must route findings to an owner.'
Require $template 'Accepted \| Partially accepted \| Rejected' 'Attended test template must record milestone disposition.'

Require $handoff 'PARENT / INTEGRATION ORCHESTRATOR' 'Parent handoff must explicitly establish the role.'
Require $handoff 'original worker thread' 'Parent handoff must support routing findings back to the original agent when appropriate.'
Require $handoff 'new follow-up agent/branch/thread|new follow-up agent/branch' 'Parent handoff must support starting a new worker when appropriate.'
Require $handoff 'one combined build|ONE release-shaped local test' 'Parent handoff must coordinate integrated testing instead of branch-by-branch local contamination.'
Require $handoff 'official parent-thread ID' 'Parent handoff must preserve explicit parent conversation continuity.'

Write-Host 'PASS: parent integration thread owns thread continuity plus merge/test/evidence/routing orchestration without becoming a fourth broad feature lane.'
