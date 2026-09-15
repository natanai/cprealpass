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
    '`CLOSED`',
    'A clear new goal should normally get a new lane/thread'
)) {
    Check ($ledger.Contains($token)) "Thread ledger contract missing: $token"
}

Check ($ledger -match 'P01\.1\s*->\s*P01\.2') 'Parent replacement generation rule is missing.'
Check ($ledger -match 'same ongoing lane[\s\S]*next generation[\s\S]*W\d{2}\.2') 'Worker replacement generation rule is missing.'
Check ($ledger -match 'materially new goal[\s\S]*fresh `W##`|materially new goal[\s\S]*new `W##`') 'New-goal/new-lane rule is missing.'

# Current parent and known worker lanes must remain explicitly registered, but this
# test must not freeze a worker into ACTIVE forever. Lane lifecycle belongs in the
# ledger and can legitimately advance from ACTIVE -> READY-PARENT/CLOSED/MERGED.
Check ($ledger.Contains('**P01.1**')) 'Current parent thread ID is not registered.'
Check ($ledger.Contains('`PARENT 1`')) 'Current parent visible alias is not registered.'
Check ($ledger.Contains('**W06.1**')) 'Exact-compile repair thread ID is not registered.'
Check ($ledger.Contains('Lane - INTEGRATION EXACT-COMPILE REPAIR')) 'Exact-compile repair visible alias is not registered.'
Check ($ledger.Contains('Issue #50')) 'Exact-compile repair issue is not registered.'
Check ($ledger.Contains('agent/integration-exact-compile-repair')) 'Exact-compile repair branch is not registered.'
$w06Row = [regex]::Match($ledger, '(?m)^\| \*\*W06\.1\*\*.*$').Value
Check (-not [string]::IsNullOrWhiteSpace($w06Row)) 'W06.1 ledger row is missing.'
Check ($w06Row -match '\*\*(ACTIVE|USABLE|TOO-LONG|RETIRED)\*\*') 'W06.1 thread state is not explicit.'
Check ($w06Row -match '\*\*(IN-PROGRESS|WAITING|READY-PARENT|BLOCKED|MERGED|SUPERSEDED|CLOSED)\*\*') 'W06.1 lane work state is not explicit.'

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
Check ($parallel -match 'old thread merely exists[\s\S]*never a reason to reuse') 'Worker workflow lost the no-opportunistic-thread-reuse rule.'
Check ($handoff -match 'official parent-thread ID') 'Replacement parent handoff does not carry the official thread ID.'

Write-Host "PASS: $script:checks parent/worker thread-ledger continuity checks."
