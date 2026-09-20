$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\tools\Common.ps1"
$project = Get-ProjectRoot
$script:checks = 0
function Check($condition,[string]$message) { if (-not $condition) { throw $message }; $script:checks++ }
function Read-Project([string]$relative) {
    $path = Join-Path $project $relative
    Check (Test-Path -LiteralPath $path -PathType Leaf) "Missing required file: $relative"
    return Get-Content -Raw -LiteralPath $path
}

$ledger = Read-Project 'docs/THREAD-LEDGER.md'
$patterns = Read-Project 'docs/AGENT-OPERATING-PATTERNS.md'
$agents = Read-Project 'AGENTS.md'
$parent = Read-Project 'docs/INTEGRATION-ORCHESTRATOR.md'
$parallel = Read-Project 'docs/PARALLEL-AGENT-WORKFLOW.md'
$handoff = Read-Project 'docs/handoffs/PARENT-INTEGRATION.md'

foreach ($token in @(
    'canonical active conversation/lane registry',
    'Thread-state vocabulary',
    '`ACTIVE`',
    '`USABLE`',
    '`TOO-LONG`',
    '`RETIRED`',
    'Lane-work-state vocabulary',
    '`READY-PARENT`',
    '`MERGED`',
    '`CLOSED`'
)) {
    Check ($ledger.Contains($token)) "Thread ledger contract missing: $token"
}

# W## is a worker conversation lineage and the decimal suffix is the sequential
# assignment number inside that same conversation. A newly opened worker
# conversation receives the next base W## and starts at .1.
foreach ($text in @($ledger,$patterns,$agents,$parallel,$parent,$handoff)) {
    Check ($text -match 'W15\.1[\s\S]*W15\.2') 'Canonical workflow lost the W15.1 -> W15.2 same-conversation example.'
    Check ($text -match 'W16\.1|next unused base.*\.1|next base worker.*\.1') 'Canonical workflow must encode new worker conversation -> next base W##.1.'
    Check ($text -notmatch 'W06\.1\s*->\s*W06\.2') 'Canonical workflow reintroduced worker .2 as replacement-chat numbering.'
}
Check ($patterns -match 'W15\.1\s*->\s*issue #72[\s\S]*W15\.2\s*->\s*issue #74') 'Operating patterns must separate W15 conversation continuity from issue/branch identity.'
Check ($ledger -match 'W15\.1\s*->\s*issue #72[\s\S]*W15\.2\s*->\s*issue #74') 'Thread ledger must preserve the canonical W15.1/W15.2 issue-separation example.'
Check ($parallel -match 'new issue/branch[\s\S]*does not require a new conversation|new issue/branch.*same useful sequential context') 'Parallel workflow must allow clean new Git ownership inside a reused worker conversation.'
Check ($ledger -match '\.2.*does.*not.*replacement|\.2.*not.*replacement') 'Ledger must reject the old .2=replacement-chat interpretation.'
Check ($parallel -match 'replacement conversation.*does \*\*not\*\* inherit|replacement conversation.*next unused base|newly opened worker conversation.*next') 'Parallel workflow must route overgrown worker conversations to the next base W##.1.'

# Known historical assignments remain registered for continuity, but this test
# does not freeze whichever worker happens to be ACTIVE today.
Check ($ledger.Contains('**P01.1**')) 'Predecessor parent thread ID is not registered.'
Check ($ledger.Contains('`PARENT 1`')) 'Predecessor parent visible alias is not registered.'
Check ($ledger.Contains('**P01.2**')) 'Current parent lineage is not registered.'
Check ($ledger.Contains('**W06.1**')) 'Exact-compile repair assignment is not registered.'
Check ($ledger.Contains('Lane - INTEGRATION EXACT-COMPILE REPAIR')) 'Exact-compile repair visible alias is not registered.'
Check ($ledger.Contains('Issue #50')) 'Exact-compile repair issue is not registered.'
Check ($ledger.Contains('agent/integration-exact-compile-repair')) 'Exact-compile repair branch is not registered.'
Check ($ledger.Contains('**W15.1**')) 'Canonical W15.1 example row is missing.'
Check ($ledger.Contains('**W15.2**')) 'Canonical W15.2 example row is missing.'
Check ($ledger.Contains('Issue #72')) 'W15.1 issue example is not registered.'
Check ($ledger.Contains('Issue #74')) 'W15.2 issue example is not registered.'
Check ($ledger.Contains('agent/failed-install-recovery-zip-validation')) 'W15.1 branch example is not registered.'
Check ($ledger.Contains('agent/operator-evidence-lifecycle')) 'W15.2 branch example is not registered.'

$w06Row = [regex]::Match($ledger, '(?m)^\| \*\*W06\.1\*\*.*$').Value
Check (-not [string]::IsNullOrWhiteSpace($w06Row)) 'W06.1 ledger row is missing.'
Check ($w06Row -match '\*\*(ACTIVE|USABLE|TOO-LONG|RETIRED)\*\*') 'W06.1 conversation state is not explicit.'
Check ($w06Row -match '\*\*(IN-PROGRESS|WAITING|READY-PARENT|BLOCKED|MERGED|SUPERSEDED|CLOSED)\*\*') 'W06.1 assignment state is not explicit.'

$activeParentRows = [regex]::Matches($ledger, '(?m)^\| \*\*P\d{2}\.\d+\*\*.*\| \*\*ACTIVE\*\* \|')
Check ($activeParentRows.Count -eq 1) "Expected exactly one ACTIVE parent row, found $($activeParentRows.Count)."

foreach ($pair in @(
    @{ Name = 'parent orchestrator'; Text = $parent },
    @{ Name = 'parallel worker workflow'; Text = $parallel },
    @{ Name = 'parent startup handoff'; Text = $handoff }
)) {
    Check ($pair.Text.Contains('THREAD-LEDGER.md')) "$($pair.Name) does not reference THREAD-LEDGER.md."
}
Check ($parent -match 'MANDATORY CURRENT-THREAD LOOKUP') 'Parent policy does not make the thread lookup mandatory.'
Check ($parallel -match 'MANDATORY THREAD REGISTRY') 'Worker workflow does not make the thread lookup mandatory.'
Check ($parallel -match 'old conversation merely exists[\s\S]*never a reason to reuse|old conversation merely exists.*never a reason to reuse') 'Worker workflow lost the deliberate-reuse guard.'
Check ($handoff -match 'official parent-thread ID') 'Replacement parent handoff does not carry the official parent-thread ID.'

Write-Host "PASS: $script:checks durable parent/worker conversation-lineage and sequential-assignment checks without freezing today's active worker state."
