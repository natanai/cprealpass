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
function Reject([string]$text,[string]$pattern,[string]$message) {
    if ($text -match $pattern) { throw $message }
}

$agents = Read 'AGENTS.md'
$roadmap = Read 'ROADMAP.md'
$ledger = Read 'docs/THREAD-LEDGER.md'
$patterns = Read 'docs/AGENT-OPERATING-PATTERNS.md'
$orchestrator = Read 'docs/INTEGRATION-ORCHESTRATOR.md'
$parallel = Read 'docs/PARALLEL-AGENT-WORKFLOW.md'
$template = Read 'docs/test-runs/README.md'
$operatorEvidence = Read 'docs/operator-evidence/README.md'
$handoff = Read 'docs/handoffs/PARENT-INTEGRATION.md'

Require $agents 'PARENT INTEGRATION GATE' 'AGENTS.md must make parent integration responsibility explicit.'
Require $agents 'docs/INTEGRATION-ORCHESTRATOR\.md' 'AGENTS.md must direct parent/integration agents to the canonical orchestration policy.'
Require $roadmap 'Parent integration/orchestration thread' 'Root roadmap must expose the parent integration thread.'
Require $roadmap 'docs/test-runs/' 'Root roadmap must preserve durable attended-test records.'
Require $roadmap 'docs/operator-evidence/' 'Root roadmap must expose durable managed operator evidence.'
Require $roadmap 'docs/handoffs/PARENT-INTEGRATION\.md' 'Root roadmap must expose the copy/paste parent-thread handoff.'

foreach ($required in @(
    'Merge orchestration',
    'Local-test orchestration',
    'Evidence capture',
    'Finding triage',
    'Redistribution',
    'Route A — deliberately reuse a recent useful worker conversation',
    'Route B — open a new worker conversation',
    'Route C — cross-assignment integration issue',
    'Route D — parent handles a tiny integration-only fix',
    'docs/test-runs/',
    'THREAD-LEDGER.md'
)) {
    Require $orchestrator ([regex]::Escape($required)) "Integration orchestrator policy lost required contract: $required"
}

Require $orchestrator 'W15\.1\s*->\s*issue #72[\s\S]*W15\.2\s*->\s*issue #74' 'Parent policy must encode same-conversation sequential assignment reuse with distinct Git ownership.'
Require $orchestrator 'new issue/branch/PR[\s\S]*does not require a new|new issue/branch/PR.*conversation reuse' 'Parent policy must separate Git assignment identity from worker conversation identity.'
Require $orchestrator 'too long.*stale.*unrelated.*parallel|too long/unwieldy.*stale.*unrelated.*parallel' 'Parent policy must define the reasons to open a new worker conversation.'
Require $orchestrator 'next unused base `W##`.*\.1|next unused base worker ID at `\.1`' 'Parent policy must start a newly opened worker conversation at the next base W##.1.'
Require $orchestrator 'Do \*\*not\*\* use `\.2` to mean a replacement conversation|\.2.*not.*replacement' 'Parent policy must reject the old .2=replacement-chat interpretation.'
Reject $orchestrator 'clear new goal should normally receive a new worker lane/thread' 'Parent policy must not retain the superseded new-goal=>new-conversation default.'
Reject $orchestrator 'same lane may continue in the next thread generation.*W06\.1 -> W06\.2' 'Parent policy must not use worker decimal suffixes as replacement-conversation generations.'

Require $orchestrator 'not.*fourth broad implementation lane|not primarily a feature-development lane' 'Parent conversation must remain coordination-focused rather than silently becoming another feature lane.'
Require $orchestrator 'short-lived integration branch' 'Parent policy must support temporary combined integration branches when risk is high.'
Require $orchestrator 'MILESTONE CLEAN-ROOM' 'Parent policy must preserve clean-room escalation.'
Require $orchestrator 'ITERATION' 'Parent policy must preserve iteration-test reuse when baseline proof is available.'
Require $orchestrator 'docs/operator-evidence|operator-evidence' 'Parent policy must include durable managed operator evidence ingestion.'
Require $orchestrator 'human-maintained open-ended KEEP/delete lists are not the steady-state contract|KEEP/delete lists.*not.*steady-state' 'Parent policy must reject human-managed KEEP/delete state as the steady-state evidence model.'

Require $ledger 'canonical active conversation/lane registry' 'Canonical thread ledger is missing or no longer authoritative.'
Require $ledger 'W15\.2' 'Thread ledger must expose the W15.2 sequential assignment.'
Require $patterns 'W15\.1\s*->\s*issue #72[\s\S]*W15\.2\s*->\s*issue #74' 'Operating patterns must preserve W15 same-conversation reuse.'
Require $parallel 'MANDATORY THREAD REGISTRY' 'Worker workflow must require the thread ledger.'

Require $template 'Canonical main SHA:' 'Attended test template must bind evidence to exact main.'
Require $template 'Artifact/package:' 'Attended test template must bind evidence to an exact artifact.'
Require $template 'Owner / route' 'Attended test template must route findings to an owner.'
Require $template 'Accepted \| Partially accepted \| Rejected' 'Attended test template must record milestone disposition.'

Require $operatorEvidence 'canonical repository-backed home' 'Managed operator evidence must have one canonical repository-backed home.'
Require $operatorEvidence 'local operator PC does \*\*not\*\* push' 'Local PC must not need GitHub write credentials for evidence ingestion.'
Require $operatorEvidence 'not a human `KEEP` list' 'Managed operator evidence must reject human KEEP lists as durable state.'

Require $handoff 'PARENT / INTEGRATION ORCHESTRATOR' 'Parent handoff must explicitly establish the role.'
Require $handoff 'deliberately reuse a recent useful ACTIVE/USABLE worker conversation' 'Parent handoff must prefer useful recent worker reuse for sequential work.'
Require $handoff 'W15\.1 -> issue #72.*W15\.2 -> issue #74|W15\.1.*issue #72[\s\S]*W15\.2.*issue #74' 'Parent handoff must include the canonical W15 same-conversation example.'
Require $handoff 'next base worker conversation at \.1|next base worker.*\.1' 'Parent handoff must define when to open the next worker conversation.'
Require $handoff 'one combined build|ONE release-shaped local test' 'Parent handoff must coordinate integrated testing instead of branch-by-branch local contamination.'
Require $handoff 'official parent-thread ID' 'Parent handoff must preserve explicit parent conversation continuity.'
Reject $handoff 'clear new goal normally gets a new W## lane' 'Parent handoff must not retain the superseded new-goal=>new-conversation rule.'
Reject $handoff 'W06\.1 -> W06\.2' 'Parent handoff must not use worker decimal suffixes as replacement-chat generations.'

Write-Host 'PASS: parent integration owns merge/test/evidence/routing orchestration, deliberately reuses recent useful worker conversations for sequential assignments, and opens a new worker conversation only for length/staleness/unrelated scope/parallelism.'
