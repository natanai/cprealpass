$ErrorActionPreference = 'Stop'
$project = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))

function Read-Tracked([string]$relative) {
    $path = Join-Path $project $relative
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Missing hygiene target: $relative" }
    Get-Content -Raw -LiteralPath $path
}

# These are current policy/guidance surfaces. Dated test-runs and historical
# handoffs are intentionally excluded from stale-string scanning.
$activeFiles = @(
    'README.md',
    'ROADMAP.md',
    'docs/ACTIVE-REDMOD-ROADMAP.md',
    'docs/AGENT-OPERATING-PATTERNS.md',
    'docs/THREAD-LEDGER.md',
    'docs/BIOLOGY-REDMOD-MIGRATION.md',
    'docs/BIOLOGY-UI.md',
    'docs/DEPENDENCY-AUDIT.md',
    'docs/E3-PRESENTATION.md',
    'docs/RELEASE-ARCHITECTURE.md',
    'docs/REDMOD-INTEGRATED-ASSEMBLY.md',
    'docs/SETTINGS-ARCHITECTURE.md',
    'docs/PATCH-RESILIENCE.md',
    'docs/LOCAL-GAME-REFERENCE.md',
    'docs/LOCAL-OPERATOR-COMMANDS.md',
    'docs/PARALLEL-AGENT-WORKFLOW.md',
    'docs/INTEGRATION-ORCHESTRATOR.md',
    'docs/operator-evidence/README.md',
    'docs/handoffs/README.md',
    'docs/handoffs/PARENT-INTEGRATION.md',
    'tests/README.md'
)

$violations = [Collections.Generic.List[string]]::new()
$retiredRepoPathPattern = 'C:\\Games\\CyberpunkRealism'

foreach ($relative in $activeFiles) {
    $text = Read-Tracked $relative

    if ($text -match 'Reset-RealPassIteration\.ps1') {
        $violations.Add("$relative reintroduces the retired RealPass iteration reset as active-looking guidance")
    }

    # A current document may name the old checkout only as an explicit anti-example.
    foreach ($match in [regex]::Matches($text, '(?im)^.*' + $retiredRepoPathPattern + '.*$')) {
        $line = $match.Value
        if ($line -notmatch '(?i)do not|retired|legacy|obsolete|historical') {
            $violations.Add("$relative presents the retired fixed repo path without an explicit warning")
        }
    }

    # The old literal retention phrase may appear only while describing legacy or
    # historical compatibility. It must never be presented as the current human
    # workflow contract.
    foreach ($match in [regex]::Matches($text, '(?im)^.*KEEP UNTIL.*$')) {
        $line = $match.Value
        if ($line -notmatch '(?i)legacy|historical|compatibility|old|pre-W15|superseded|do not use|not.*contract') {
            $violations.Add("$relative presents KEEP UNTIL as current human-managed operator state: $($line.Trim())")
        }
    }
}

# Current branch/issue names may legitimately live in THREAD-LEDGER and roadmaps,
# but branch-agnostic architecture/policy files must not resurrect merged workers.
$branchAgnosticFiles = @(
    'docs/BIOLOGY-REDMOD-MIGRATION.md',
    'docs/PARALLEL-AGENT-WORKFLOW.md',
    'docs/INTEGRATION-ORCHESTRATOR.md',
    'docs/handoffs/README.md'
)
foreach ($relative in $branchAgnosticFiles) {
    $text = Read-Tracked $relative
    foreach ($oldBranch in @('agent/redmod-foundation','agent/biology-ui-runtime','agent/presentation-hud-nameplates')) {
        if ($text -match [regex]::Escape($oldBranch)) {
            $violations.Add("$relative presents merged branch as current policy: $oldBranch")
        }
    }
}

# Canonical worker numbering/reuse must not drift back to the old replacement-chat
# interpretation. W15.1 -> W15.2 is sequential work in the same conversation;
# a newly opened worker conversation starts at the next base W##.1.
$patterns = Read-Tracked 'docs/AGENT-OPERATING-PATTERNS.md'
$ledger = Read-Tracked 'docs/THREAD-LEDGER.md'
$parallel = Read-Tracked 'docs/PARALLEL-AGENT-WORKFLOW.md'
$orchestrator = Read-Tracked 'docs/INTEGRATION-ORCHESTRATOR.md'
$parentHandoff = Read-Tracked 'docs/handoffs/PARENT-INTEGRATION.md'
foreach ($pair in @(
    @{Name='AGENT-OPERATING-PATTERNS';Text=$patterns},
    @{Name='THREAD-LEDGER';Text=$ledger},
    @{Name='PARALLEL-AGENT-WORKFLOW';Text=$parallel},
    @{Name='INTEGRATION-ORCHESTRATOR';Text=$orchestrator},
    @{Name='PARENT-INTEGRATION handoff';Text=$parentHandoff}
)) {
    if ($pair.Text -notmatch 'W15\.1[\s\S]*W15\.2') { $violations.Add("$($pair.Name) lost the canonical W15.1 -> W15.2 same-conversation example") }
    if ($pair.Text -notmatch 'W16\.1|next unused base.*\.1|next base worker.*\.1') { $violations.Add("$($pair.Name) does not encode new worker conversation -> next base W##.1") }
    if ($pair.Text -match 'W06\.1\s*->\s*W06\.2') { $violations.Add("$($pair.Name) reintroduces worker .2 as replacement-chat numbering") }
    if ($pair.Text -match '(?i)clear new goal.*new W##|new goal.*new worker lane/thread') { $violations.Add("$($pair.Name) reintroduces the superseded new-goal=>new-conversation default") }
}

$operatorEvidence = Read-Tracked 'docs/operator-evidence/README.md'
if ($operatorEvidence -notmatch 'canonical repository-backed home') { $violations.Add('Operator evidence README no longer declares the durable evidence home.') }
if ($operatorEvidence -notmatch 'not a human `KEEP` list') { $violations.Add('Operator evidence README no longer rejects human KEEP lists.') }
if ($operatorEvidence -notmatch 'local operator PC does \*\*not\*\* push') { $violations.Add('Operator evidence README no longer keeps GitHub writes off the local PC.') }

# Local-reference tools derive the active checkout rather than defaulting to a retired path.
foreach ($relative in @('tools/Refresh-LocalGameReference.ps1','tools/Publish-LocalGameReferenceSnapshot.ps1')) {
    $text = Read-Tracked $relative
    if ($text -match $retiredRepoPathPattern) { $violations.Add("$relative still hard-codes the retired repository checkout") }
}

# Merged worker handoffs and superseded player/build entrypoints remain in Git history,
# not as active-looking files in the working tree.
foreach ($retired in @(
    'docs/handoffs/REDMOD-FOUNDATION.md',
    'docs/handoffs/BIOLOGY-UI-RUNTIME.md',
    'docs/handoffs/PRESENTATION-HUD-NAMEPLATES.md',
    'tools/Build-CleanRoomTestPackage.ps1',
    'tools/Finalize-PlayerPackage.ps1',
    'tools/Reset-RealPassIteration.ps1',
    'tools/Build-RedmodFoundation.ps1',
    'package/PLAYER-INSTALL.template.txt',
    'package/PLAYER-UNINSTALL.template.txt'
)) {
    if (Test-Path -LiteralPath (Join-Path $project $retired)) { $violations.Add("Retired active-looking file still exists: $retired") }
}

$spec = Read-Tracked 'REALISM-SPEC.md'
if ($spec -notmatch '(?i)retired from active guidance' -or $spec -match '(?im)^realpass is one coherent') { $violations.Add('REALISM-SPEC.md is not an explicit retired pointer.') }
$foundation = Read-Tracked 'docs/REDMOD-PACKAGE-FOUNDATION.md'
if ($foundation -notmatch '(?i)historical phase complete|archived phase pointer' -or $foundation -match '(?i)Lane C|Biology REDmod recognition/deployment;') { $violations.Add('REDMOD-PACKAGE-FOUNDATION.md still behaves like current phase guidance.') }

$worklog = Read-Tracked 'docs/WORKLOG.md'
if ($worklog -notmatch '^# Biology current worklog' -or $worklog -match '(?i)Enable RealPass|agent/instruction-cleanup-native-audit') { $violations.Add('WORKLOG.md still carries superseded RealPass/current-branch instructions.') }
$thirdParty = Read-Tracked 'THIRD_PARTY.md'
if ($thirdParty -notmatch '^# Biology third-party provenance' -or $thirdParty -match '(?i)managed.feature.ledger|host for RealPass presence') { $violations.Add('THIRD_PARTY.md still describes the superseded RealPass settings/dependency surface.') }

$packageReadme = Read-Tracked 'package/README.md'
$packageRecipe = Get-Content -Raw -LiteralPath (Join-Path $project 'manifest/package.json') | ConvertFrom-Json
if ($packageReadme -notmatch '^# Biology development/source artifact' -or $packageReadme -match '(?i)managed.feature.ledger|m1-owned-settings|Enable RealPass') { $violations.Add('Development source package README carries stale RealPass/current-runtime claims.') }
if ($packageRecipe.id -ne 'biology-source' -or $packageRecipe.name -notmatch 'Biology') { $violations.Add('Development source package recipe still uses stale RealPass product identity.') }

$workflow = Read-Tracked '.github/workflows/ci.yml'
if (-not $workflow.StartsWith('name: Biology CI') -or $workflow -match '(?i)realpass-development-source|realpass-offline-reports|Run cloud-safe realpass checks') { $violations.Add('Active GitHub Actions surfaces still advertise stale RealPass CI/artifact identity.') }

$playerBuilder = Read-Tracked 'tools/Build-BiologyPackage.ps1'
if ($playerBuilder -match '(?i)Lane C|Biology REDmod recognition/deployment.*directGameGatesRemaining|Recognition, enable/disable, relaunch persistence, clean uninstall/reset') { $violations.Add('Canonical Biology package builder still emits superseded lane/deployment-gate text.') }
if ($playerBuilder -notmatch '(?i)Enable mods ON|Deploy-BiologyRedmod\.ps1' -or $playerBuilder -notmatch 'Uninstall Biology\.exe') { $violations.Add('Canonical Biology package output lost current deploy/activation or uninstall guidance.') }

$baseline = Join-Path $project 'docs\PRE-REDMOD-LIVE-BASELINE-2026-09-15.md'
if (-not (Test-Path -LiteralPath $baseline -PathType Leaf)) { $violations.Add('Historical pre-REDmod attended baseline was removed instead of preserved as evidence.') }

if ($violations.Count -gt 0) { throw "Active guidance hygiene failed:`n - $($violations -join "`n - ")" }

Write-Host 'PASS: active guidance includes worker-numbering and repo-backed evidence policy, rejects current human KEEP/replacement-chat contracts, and keeps dated historical evidence separate from live mutable state.'
