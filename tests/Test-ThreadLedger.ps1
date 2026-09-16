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
# assignment number inside that same conversation. A replacement/new worker
# conversation receives the next base W## and starts at .1.
foreach ($text in @($ledger,$patterns,$agents,$parallel)) {
    Check ($text -match 'W15\.1\s*(?:=|->).*W15|W15\.1[\s\S]*W15\.2') 'Canonical workflow lost the W15.1 -> W15.2 same-conversation example.'
    Check ($text -match 'W15\.2') 'Canonical workflow must explicitly encode W15.2.'
    Check ($text -match 'W16\.1') 'Canonical workflow must explicitly encode new worker conversation -> next base W16.1.'
}
Check ($patterns -match 'W15\.1\s*->\s*issue #72[\s\S]*W15\.2\s*->\s*issue #74') 'Operating patterns must separate W15 conversation continuity from issue/branch identity.'
Check ($ledger -match 'W15\.1\s*->\s*issue #72[\s\S]*W15\.2\s*->\s*issue #74') 'Thread ledger must record W15.1/W15.2 issue separation.'
Check ($parallel -match 'new issue/branch[\s\S]*does not require a new conversation|new issue/branch.*same useful sequential context') 'Parallel workflow must allow clean new Git ownership inside a reused worker conversation.'
Check ($ledger -match '\.2.*does.*not.*replacement|\.2.*not.*replacement') 'Ledger must reject the old .2=replacement-chat interpretation.'
Check ($parallel -match 'replacement conversation.*does \*\*not\*\* inherit|replacement conversation.*next unused base') 'Parallel workflow must route overgrown worker conversations to the next base W##.1.'

# Current parent and known historical worker lanes remain explicitly registered,
# but worker state may legitimately advance independently from conversation reuse.
Check ($ledger.Contains('**P01.1**')) 'Predecessor parent thread ID is not registered.'
Check ($ledger.Contains('`PARENT 1`')) 'Predecessor parent visible alias is not registered.'
Check ($ledger.Contains('**P01.2**')) 'Current parent thread ID is not registered.'
Check ($ledger.Contains('**W06.1**')) 'Exact-compile repair thread ID is not registered.'
Check ($ledger.Contains('Lane - INTEGRATION EXACT-COMPILE REPAIR')) 'Exact-compile repair visible alias is not registered.'
Check ($ledger.Contains('Issue #50')) 'Exact-compile repair issue is not registered.'
Check ($ledger.Contains('agent/integration-exact-compile-repair')) 'Exact-compile repair branch is not registered.'
Check ($ledger.Contains('**W15.1**')) 'W15.1 assignment row is missing.'
Check ($ledger.Contains('**W15.2**')) 'W15.2 assignment row is missing.'
Check ($ledger.Contains('Issue #72')) 'W15.1 issue is not registered.'
Check ($ledger.Contains('Issue #74')) 'W15.2 issue is not registered.'
Check ($ledger.Contains('agent/failed-install-recovery-zip-validation')) 'W15.1 branch is not registered.'
Check ($ledger.Contains('agent/operator-evidence-lifecycle')) 'W15.2 branch is not registered.'

$w06Row = [regex]::Match($ledger, '(?m)^\| \*\*W06\.1\*\*.*$').Value
Check (-not [string]::IsNullOrWhiteSpace($w06Row)) 'W06.1 ledger row is missing.'
Check ($w06Row -match '\*\*(ACTIVE|USABLE|TOO-LONG|RETIRED)\*\*') 'W06.1 thread state is not explicit.'
Check ($w06Row -match '\*\*(IN-PROGRESS|WAITING|READY-PARENT|BLOCKED|MERGED|SUPERSEDED|CLOSED)\*\*') 'W06.1 work state is not explicit.'

$w15_2Row = [regex]::Match($ledger, '(?m)^\| \*\*W15\.2\*\*.*$').Value
Check (-not [string]::IsNullOrWhiteSpace($w15_2Row)) 'W15.2 ledger row is missing.'
Check ($w15_2Row -match '\*\*ACTIVE\*\*') 'W15.2 must be the active worker conversation assignment while this PR is open.'
Check ($w15_2Row -match '\*\*IN-PROGRESS\*\*') 'W15.2 must remain IN-PROGRESS until worker return.'

$activeParentRows = [regex]::Matches($ledger, '(?m)^\| \*\*P\d{2}\.\d+\*\*.*\| \*\*ACTIVE\*\* \|')
Check ($activeParentRows.Count -eq 1) "Expected exactly one ACTIVE parent thread row, found $($activeParentRows.Count)."

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

Write-Host "PASS: $script:checks parent/worker conversation-lineage and sequential-assignment checks."
