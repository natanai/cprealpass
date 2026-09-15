$ErrorActionPreference = 'Stop'
$project = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))

function Read-Tracked([string]$relative) {
    $path = Join-Path $project $relative
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Missing hygiene target: $relative" }
    Get-Content -Raw -LiteralPath $path
}

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
    $text = Read-Tracked $relative
    foreach ($entry in $forbidden.GetEnumerator()) {
        if ($text -match $entry.Value) {
            $violations.Add("$relative contains $($entry.Key)")
        }
    }

    # A current document may name the old checkout only as an explicit anti-example.
    foreach ($match in [regex]::Matches($text, '(?im)^.*' + $retiredRepoPathPattern + '.*$')) {
        $line = $match.Value
        if ($line -notmatch '(?i)do not|retired|legacy|obsolete|historical') {
            $violations.Add("$relative presents the retired fixed repo path without an explicit warning")
        }
    }
}

# Local-reference tools derive the active checkout rather than defaulting to a retired
# permanent repo path. The broader operator catalog has its own dedicated regression test.
foreach ($relative in @(
    'tools/Refresh-LocalGameReference.ps1',
    'tools/Publish-LocalGameReferenceSnapshot.ps1'
)) {
    $text = Read-Tracked $relative
    if ($text -match $retiredRepoPathPattern) {
        $violations.Add("$relative still hard-codes the retired repository checkout")
    }
}

# Merged worker handoffs and superseded player/build entrypoints are preserved by Git
# history, not left in the working tree where an agent can mistake them for current.
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
    if (Test-Path -LiteralPath (Join-Path $project $retired)) {
        $violations.Add("Retired active-looking file still exists: $retired")
    }
}

# Compatibility pointers may remain at historically linked paths, but they must be
# explicit tombstones rather than stale parallel sources of truth.
$spec = Read-Tracked 'REALISM-SPEC.md'
if ($spec -notmatch '(?i)retired from active guidance' -or $spec -match '(?im)^realpass is one coherent') {
    $violations.Add('REALISM-SPEC.md is not an explicit retired pointer.')
}
$foundation = Read-Tracked 'docs/REDMOD-PACKAGE-FOUNDATION.md'
if ($foundation -notmatch '(?i)historical phase complete|archived phase pointer' -or $foundation -match '(?i)Lane C|Biology REDmod recognition/deployment;') {
    $violations.Add('REDMOD-PACKAGE-FOUNDATION.md still behaves like current phase guidance.')
}

$worklog = Read-Tracked 'docs/WORKLOG.md'
if ($worklog -notmatch '^# Biology current worklog' -or $worklog -match '(?i)Enable RealPass|agent/instruction-cleanup-native-audit') {
    $violations.Add('WORKLOG.md still carries superseded RealPass/current-branch instructions.')
}

$thirdParty = Read-Tracked 'THIRD_PARTY.md'
if ($thirdParty -notmatch '^# Biology third-party provenance' -or $thirdParty -match '(?i)managed.feature.ledger|host for RealPass presence') {
    $violations.Add('THIRD_PARTY.md still describes the superseded RealPass settings/dependency surface.')
}

$packageReadme = Read-Tracked 'package/README.md'
$packageRecipe = Get-Content -Raw -LiteralPath (Join-Path $project 'manifest/package.json') | ConvertFrom-Json
if ($packageReadme -notmatch '^# Biology development/source artifact' -or $packageReadme -match '(?i)managed.feature.ledger|m1-owned-settings|Enable RealPass') {
    $violations.Add('Development source package README carries stale RealPass/current-runtime claims.')
}
if ($packageRecipe.id -ne 'biology-source' -or $packageRecipe.name -notmatch 'Biology') {
    $violations.Add('Development source package recipe still uses stale RealPass product identity.')
}

$workflow = Read-Tracked '.github/workflows/ci.yml'
if (-not $workflow.StartsWith('name: Biology CI') -or $workflow -match '(?i)realpass-development-source|realpass-offline-reports|Run cloud-safe realpass checks') {
    $violations.Add('Active GitHub Actions surfaces still advertise stale RealPass CI/artifact identity.')
}

$playerBuilder = Read-Tracked 'tools/Build-BiologyPackage.ps1'
if ($playerBuilder -match '(?i)Lane C|Biology REDmod recognition/deployment.*directGameGatesRemaining|Recognition, enable/disable, relaunch persistence, clean uninstall/reset') {
    $violations.Add('Canonical Biology package builder still emits superseded lane/deployment-gate text.')
}
if ($playerBuilder -notmatch 'Deploy-BiologyRedmod\.ps1' -or $playerBuilder -notmatch 'Uninstall Biology\.exe') {
    $violations.Add('Canonical Biology package output lost current deploy/uninstall guidance.')
}

# Dated evidence is intentionally excluded from stale-string scanning. Historical
# records must preserve what actually happened, including old paths/branch names.
$baseline = Join-Path $project 'docs\PRE-REDMOD-LIVE-BASELINE-2026-09-15.md'
if (-not (Test-Path -LiteralPath $baseline -PathType Leaf)) {
    $violations.Add('Historical pre-REDmod attended baseline was removed instead of preserved as evidence.')
}

if ($violations.Count -gt 0) {
    throw "Active guidance hygiene failed:`n - $($violations -join "`n - ")"
}

Write-Host 'PASS: current guidance, package surfaces, CI identity and operator tooling are separated from retired RealPass paths/phases while dated evidence remains intact.'
