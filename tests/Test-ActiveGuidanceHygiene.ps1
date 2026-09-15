$ErrorActionPreference = 'Stop'
$project = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))

$activeFiles = @(
    'README.md',
    'ROADMAP.md',
    'docs/ACTIVE-REDMOD-ROADMAP.md',
    'docs/BIOLOGY-REDMOD-MIGRATION.md',
    'docs/RELEASE-ARCHITECTURE.md',
    'docs/LOCAL-GAME-REFERENCE.md',
    'docs/PARALLEL-AGENT-WORKFLOW.md',
    'docs/INTEGRATION-ORCHESTRATOR.md',
    'docs/handoffs/README.md',
    'docs/handoffs/PARENT-INTEGRATION.md'
)

$forbidden = [ordered]@{
    'retired RealPass iteration reset as active instruction' = 'Reset-RealPassIteration\.ps1'
    'merged REDmod foundation branch presented in active guidance' = 'agent/redmod-foundation'
    'merged Biology UI/runtime branch presented in active guidance' = 'agent/biology-ui-runtime'
    'merged presentation branch presented in active guidance' = 'agent/presentation-hud-nameplates'
}
$retiredRepoPathPattern = 'C:\\Games\\CyberpunkRealism'

$violations = [Collections.Generic.List[string]]::new()
foreach ($relative in $activeFiles) {
    $path = Join-Path $project $relative
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        $violations.Add("Missing active guidance file: $relative")
        continue
    }
    $text = Get-Content -Raw -LiteralPath $path
    foreach ($entry in $forbidden.GetEnumerator()) {
        if ($text -match $entry.Value) {
            $violations.Add("$relative contains $($entry.Key)")
        }
    }

    # It is useful for a current document to identify the retired checkout as an
    # explicit anti-example. Reject the path only when it appears as an instruction
    # or unexplained current assumption rather than in a same-line warning.
    foreach ($match in [regex]::Matches($text, '(?im)^.*' + $retiredRepoPathPattern + '.*$')) {
        $line = $match.Value
        if ($line -notmatch '(?i)do not|retired|legacy|obsolete|historical') {
            $violations.Add("$relative presents the retired fixed repo path without an explicit warning")
        }
    }
}

# Local-reference tools owned by this cleanup must derive the active checkout rather
# than defaulting back to the retired permanent repository path. Audit-GameContracts
# and the broader operator catalog are intentionally owned by the active presentation
# follow-up PR and have their own regression coverage there.
foreach ($relative in @(
    'tools/Refresh-LocalGameReference.ps1',
    'tools/Publish-LocalGameReferenceSnapshot.ps1'
)) {
    $path = Join-Path $project $relative
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        $violations.Add("Missing local-reference tool: $relative")
        continue
    }
    $text = Get-Content -Raw -LiteralPath $path
    if ($text -match $retiredRepoPathPattern) {
        $violations.Add("$relative still hard-codes the retired repository checkout")
    }
}

foreach ($retired in @(
    'docs/handoffs/REDMOD-FOUNDATION.md',
    'docs/handoffs/BIOLOGY-UI-RUNTIME.md',
    'docs/handoffs/PRESENTATION-HUD-NAMEPLATES.md'
)) {
    if (Test-Path -LiteralPath (Join-Path $project $retired)) {
        $violations.Add("Retired merged worker handoff still exists: $retired")
    }
}

# Dated evidence is intentionally excluded from the stale-string scan. Historical
# records must preserve what actually happened, including old paths/branch names.
$baseline = Join-Path $project 'docs\PRE-REDMOD-LIVE-BASELINE-2026-09-15.md'
if (-not (Test-Path -LiteralPath $baseline -PathType Leaf)) {
    $violations.Add('Historical pre-REDmod attended baseline was removed instead of preserved as evidence.')
}

if ($violations.Count -gt 0) {
    throw "Active guidance hygiene failed:`n - $($violations -join "`n - ")"
}

Write-Host 'PASS: active guidance does not instruct retired checkouts/resets/merged lanes, local reference tools derive the active checkout, and historical evidence remains separate.'
