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
    'fixed retired repo path C:\Games\CyberpunkRealism' = 'C:\\Games\\CyberpunkRealism'
    'retired RealPass iteration reset as active instruction' = 'Reset-RealPassIteration\.ps1'
    'merged REDmod foundation branch presented in active guidance' = 'agent/redmod-foundation'
    'merged Biology UI/runtime branch presented in active guidance' = 'agent/biology-ui-runtime'
    'merged presentation branch presented in active guidance' = 'agent/presentation-hud-nameplates'
}

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

Write-Host 'PASS: active guidance contains no retired fixed checkout, legacy reset command, or merged worker-lane instructions; historical evidence remains separate.'
