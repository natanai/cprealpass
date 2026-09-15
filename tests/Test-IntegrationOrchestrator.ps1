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
$orchestrator = Read 'docs/INTEGRATION-ORCHESTRATOR.md'
$template = Read 'docs/test-runs/README.md'

Require $agents 'PARENT INTEGRATION GATE' 'AGENTS.md must make parent integration responsibility explicit.'
Require $agents 'docs/INTEGRATION-ORCHESTRATOR\.md' 'AGENTS.md must direct parent/integration agents to the canonical orchestration policy.'
Require $roadmap 'Parent integration/orchestration thread' 'Root roadmap must expose the parent integration thread.'
Require $roadmap 'docs/test-runs/' 'Root roadmap must preserve durable attended-test records.'

foreach ($required in @(
    'Merge orchestration',
    'Local-test orchestration',
    'Evidence capture',
    'Finding triage',
    'Redistribution',
    'Route A — return to the original worker lane/thread',
    'Route B — new follow-up branch for the same subsystem',
    'Route C — cross-lane integration issue',
    'Route D — parent handles a tiny integration-only fix',
    'docs/test-runs/',
    'exact canonical `main` SHA'
)) {
    Require $orchestrator ([regex]::Escape($required)) "Integration orchestrator policy lost required contract: $required"
}

Require $orchestrator 'not.*fourth broad implementation lane|not primarily a feature-development lane' 'Parent thread must remain coordination-focused rather than silently becoming another feature lane.'
Require $orchestrator 'short-lived integration branch' 'Parent policy must support temporary combined integration branches when risk is high.'
Require $orchestrator 'original agent' 'Parent policy must explicitly support returning attended findings to the original implementation agent when appropriate.'
Require $orchestrator 'new agent/thread' 'Parent policy must explicitly support creating a fresh follow-up lane when the original context is no longer appropriate.'
Require $orchestrator 'MILESTONE CLEAN-ROOM' 'Parent policy must preserve clean-room escalation.'
Require $orchestrator 'ITERATION' 'Parent policy must preserve iteration-test reuse when baseline proof is available.'

Require $template 'Canonical main SHA:' 'Attended test template must bind evidence to exact main.'
Require $template 'Artifact/package:' 'Attended test template must bind evidence to an exact artifact.'
Require $template 'Owner / route' 'Attended test template must route findings to an owner.'
Require $template 'Accepted \| Partially accepted \| Rejected' 'Attended test template must record milestone disposition.'

Write-Host 'PASS: parent integration thread owns merge/test/evidence/routing orchestration without becoming a fourth broad feature lane.'
