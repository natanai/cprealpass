$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\tools\Common.ps1"
$project = Get-ProjectRoot

function Read([string]$relative) {
    $path = Join-Path $project $relative
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Missing local-operator contract file: $relative" }
    Get-Content -Raw -LiteralPath $path
}
function Require([string]$text,[string]$pattern,[string]$message) {
    if ($text -notmatch $pattern) { throw $message }
}
function Reject([string]$text,[string]$pattern,[string]$message) {
    if ($text -match $pattern) { throw $message }
}
function Require-FailureDurableChildBootstrap([string]$relative,[string]$text) {
    Require $text 'ProcessStartInfo' "$relative must invoke evidence-bearing child processes through ProcessStartInfo."
    Require $text 'RedirectStandardOutput\s*=\s*\$true' "$relative must redirect child stdout."
    Require $text 'RedirectStandardError\s*=\s*\$true' "$relative must redirect child stderr."
    Require $text 'ArgumentList\.Add' "$relative must preserve child argument boundaries with ArgumentList."
    Require $text 'StdOut|stdout' "$relative must retain child stdout."
    Require $text 'StdErr|stderr' "$relative must retain child stderr."
    Require $text 'ExitCode|exit code' "$relative must retain child exit code."
    Require $text 'ATTACH THIS FILE TO CHATGPT:' "$relative must expose one obvious attachment handoff."
}
function Require-ZeroRepoExactMainBootstrap([string]$relative,[string]$text) {
    Require $text "'rev-parse','--show-toplevel'" "$relative must validate discovered local repositories through Git."
    Require $text "'remote','get-url','origin'" "$relative must validate natanai/cprealpass origin."
    Require $text "'clone','--no-checkout'" "$relative must support zero-local-repo seed acquisition."
    Require $text "'fetch','origin'" "$relative must fetch exact canonical source before use."
    Require $text "'cat-file','-e'" "$relative must prove exact cached commit availability before offline fallback."
    Require $text 'cprealpass-repo-' "$relative must use uniquely signed disposable seed state when needed."
    Reject $text [regex]::Escape('.git\config') "$relative must not require a physical .git/config for worktree discovery."
    Reject $text 'C:\\Games\\CyberpunkRealism' "$relative reintroduced the retired fixed checkout path."
    Reject $text '(?i)Start-Process[^\r\n]*Cyberpunk' "$relative must never launch Cyberpunk."
}

$agents = Read 'AGENTS.md'
$catalog = Read 'docs/LOCAL-OPERATOR-COMMANDS.md'
$operatorEvidenceReadme = Read 'docs/operator-evidence/README.md'
$cleanRoom = Read 'docs/CLEAN-ROOM-TESTING.md'
$prepare = Read 'tools/Prepare-BiologyMilestoneTest.ps1'
$sanity = Read 'tools/Test-VanillaGameSanity.ps1'
$compare = Read 'tools/Compare-GameToVanillaBaseline.ps1'
$deploy = Read 'tools/Deploy-BiologyRedmod.ps1'
$audit = Read 'tools/Audit-GameContracts.ps1'
$presentationBootstrap = Read 'tools/Bootstrap-PresentationAudit.ps1'
$activationBootstrap = Read 'tools/Bootstrap-RedmodActivationSentinelProbe.ps1'
$transitionProbeBootstrap = Read 'tools/Bootstrap-LegacyFrameworkTransitionProbe.ps1'
$transitionProbe = Read 'tools/Probe-LegacyFrameworkTransition.ps1'
$transitionCleanupBootstrap = Read 'tools/Bootstrap-LegacyFrameworkTransitionCleanup.ps1'
$legacyCandidateBootstrap = Read 'tools/Bootstrap-BiologyPostTransitionCandidate.ps1'
$managedCandidate = Read 'tools/Bootstrap-BiologyManagedPostTransitionCandidate.ps1'
$managedRecovery = Read 'tools/Bootstrap-BiologyManagedFailedInstallRecovery.ps1'
$managedCleanup = Read 'tools/Bootstrap-BiologyOperatorEvidenceCleanup.ps1'
$operatorCore = Read 'tools/BiologyOperatorEvidence.Core.ps1'
$removalVerifier = Read 'tools/Verify-BiologyRemoval.ps1'

Require $agents 'LOCAL OPERATOR COMMAND GATE' 'AGENTS.md must make the local operator catalog mandatory.'
Require $agents 'docs/LOCAL-OPERATOR-COMMANDS\.md' 'AGENTS.md must direct agents to the canonical operator catalog.'
Require $agents 'do not invent|must not invent|rather than invent' 'AGENTS.md must prohibit ad-hoc replacements for catalogued operations.'

Require $catalog 'canonical user-run command surface' 'Local command catalog must declare itself canonical.'
Require $catalog 'Mandatory repository discovery/bootstrap rule' 'Catalog must define repository discovery/bootstrap.'
Require $catalog 'rev-parse --show-toplevel|rev-parse.*show-toplevel' 'Catalog must describe Git-validated clone/worktree discovery.'
Require $catalog 'remote get-url origin|remote.*get-url.*origin' 'Catalog must validate repository identity by origin.'
Require $catalog 'zero local repo|zero-local-repo' 'Catalog must treat zero local repo as supported.'
Require $catalog 'exact-head cached-origin|cached-origin.*exact-head|cached.*origin.*exact' 'Catalog must preserve exact offline fallback.'
Require $catalog 'timestamp and random suffix|random suffix.*timestamp' 'Catalog must require collision-resistant workspace signatures.'
Require $catalog 'must not be assumed or recreated|must not.*recreated' 'Catalog must retire the fixed CyberpunkRealism checkout convention.'
Require $catalog 'bootstrap-loader boundary|loader boundary' 'Catalog must include exact-revision loader policy.'

Require $catalog 'Mandatory evidence-report rule' 'Catalog must define evidence handoff policy.'
Require $catalog 'one managed handoff bundle|one obvious attachable handoff|one `Biology-Operator-Evidence-' 'Catalog must converge managed operations on one obvious handoff surface.'
Require $catalog 'docs/operator-evidence/<evidence-id>/' 'Catalog must make repo-backed operator evidence durable.'
Require $catalog 'local PC does not need GitHub write credentials|local PC never pushes evidence|local PC.*does not.*push' 'Catalog must keep GitHub writes out of the local operator PC.'
Require $catalog 'not.*human `KEEP`|no open-ended human `KEEP`|Do not use that wording as a new human-memory contract' 'Catalog must reject human-maintained KEEP state as the steady-state contract.'
Require $catalog 'Parent evidence ingestion rule' 'Catalog must define parent/assistant evidence ingestion.'

# Command 13 is retained only as the inner compatibility implementation. Its old
# retention strings may remain in historical output, but they are not active policy.
Require $catalog 'Command 13 — legacy post-W11 candidate preparation compatibility entrypoint' 'Command 13 must be explicitly legacy compatibility.'
Require $catalog 'historical report may contain `KEEP UNTIL ATTENDED TEST`' 'Catalog must identify old KEEP wording as historical evidence.'
Require $catalog 'Do not use that wording as a new human-memory contract' 'Catalog must reject Command 13 KEEP wording as a new operator contract.'
Require $catalog 'Bootstrap-BiologyPostTransitionCandidate\.ps1' 'Catalog must retain the W12 compatibility entrypoint.'
Require $legacyCandidateBootstrap 'STOP_BEFORE_GAME_LAUNCH=YES' 'Legacy candidate bootstrap must still stop before launch.'
Require $legacyCandidateBootstrap 'RESULT: FAIL-CLOSED' 'Legacy candidate bootstrap must preserve failure evidence.'
Require-FailureDurableChildBootstrap 'tools/Bootstrap-BiologyPostTransitionCandidate.ps1' $legacyCandidateBootstrap

# Commands 14-16 are the steady-state managed lifecycle.
Require $catalog 'Command 14 — managed post-W11 candidate preparation' 'Catalog must expose managed candidate preparation.'
Require $catalog 'Bootstrap-BiologyManagedPostTransitionCandidate\.ps1' 'Catalog must name the managed candidate bootstrap.'
Require $catalog 'Command 15 — repository-evidence-backed failed-install recovery' 'Catalog must expose managed failed-install recovery.'
Require $catalog 'Bootstrap-BiologyManagedFailedInstallRecovery\.ps1' 'Catalog must name managed recovery.'
Require $catalog 'Command 16 — repo-confirmed local operator evidence cleanup' 'Catalog must expose repo-confirmed cleanup.'
Require $catalog 'Bootstrap-BiologyOperatorEvidenceCleanup\.ps1' 'Catalog must name managed cleanup.'
Require $catalog 'any missing expected artifact file' 'Catalog must state that incomplete managed artifact roots fail closed.'

foreach ($pair in @(
    @{Name='tools/Bootstrap-BiologyManagedPostTransitionCandidate.ps1';Text=$managedCandidate},
    @{Name='tools/Bootstrap-BiologyManagedFailedInstallRecovery.ps1';Text=$managedRecovery},
    @{Name='tools/Bootstrap-BiologyOperatorEvidenceCleanup.ps1';Text=$managedCleanup}
)) {
    Require-ZeroRepoExactMainBootstrap $pair.Name $pair.Text
}

Require $managedCandidate 'Biology-Operator-Evidence-' 'Managed candidate preparation must emit the single evidence bundle naming contract.'
Require $managedCandidate 'evidence\.json' 'Managed candidate bundle must include evidence.json.'
Require $managedCandidate 'report\.txt' 'Managed candidate bundle must include report.txt.'
Require $managedCandidate 'payloadManifest' 'Managed candidate evidence must preserve schema-2 payload inventory.'
Require $managedCandidate 'Recovery evidence eligible' 'Managed candidate report must expose recovery eligibility.'
Require $managedCandidate 'Lifecycle: return this one ZIP to P01\.2' 'Managed candidate must direct one-bundle return to the parent.'

Require $managedRecovery 'PLAN STATUS: SAFE-TO-APPLY' 'Managed recovery must complete a read/plan-first gate before mutation.'
Require $managedRecovery 'New-BiologyEvidenceBackedFailedInstallRecoveryPlan' 'Managed recovery must support exact payload evidence.'
Require $managedRecovery 'New-BiologyLegacyEmptyFailedInstallRecoveryPlan' 'Managed recovery must support the bounded legacy current-state path.'
Require $managedRecovery 'Shared redscript/cybercmd deletion count: 0' 'Managed recovery must preserve shared redscript/cybercmd.'
Reject $managedRecovery 'Deploy-BiologyRedmod\.ps1' 'Managed failed-install recovery must not deploy REDmod.'

Require $managedCleanup 'Test-BiologyOperatorEvidenceBundleAgainstRepository' 'Cleanup must authenticate the returned bundle against durable repository evidence.'
Require $managedCleanup 'Remove-BiologyManagedArtifactRoot' 'Cleanup must use the hash/inventory-bounded managed artifact remover.'
Require $managedCleanup 'Remove-Item -LiteralPath \$HandoffBundlePath -Force' 'Cleanup may delete only the exactly matched handoff bundle after durable evidence verification.'
Require $operatorCore 'missing expected file' 'Managed artifact cleanup core must fail closed on incomplete expected inventory.'
Require $operatorCore 'Managed artifact cleanup found foreign file' 'Managed artifact cleanup core must fail closed on foreign content.'
Require $operatorCore 'Managed artifact cleanup found changed file' 'Managed artifact cleanup core must fail closed on changed content.'
Require $operatorCore 'reparse point' 'Managed artifact cleanup core must fail closed on reparse points.'

Require $operatorEvidenceReadme 'canonical repository-backed home' 'Operator evidence README must define canonical durable evidence storage.'
Require $operatorEvidenceReadme 'local operator PC does \*\*not\*\* push' 'Operator evidence README must keep local GitHub writes out of scope.'
Require $operatorEvidenceReadme 'not a human `KEEP` list' 'Operator evidence README must reject human KEEP lists.'
Require $operatorEvidenceReadme 'exact-payload-manifest' 'Operator evidence README must document exact-payload recovery.'
Require $operatorEvidenceReadme 'empty-owned-roots-only' 'Operator evidence README must document the bounded legacy recovery mode.'

# Preserve the broader established operator contracts.
foreach ($pair in @(
    @{Name='tools/Bootstrap-PresentationAudit.ps1';Text=$presentationBootstrap},
    @{Name='tools/Bootstrap-RedmodActivationSentinelProbe.ps1';Text=$activationBootstrap}
)) {
    Require-FailureDurableChildBootstrap $pair.Name $pair.Text
}
Require $transitionProbeBootstrap 'Probe-LegacyFrameworkTransition\.ps1' 'W11 transition bootstrap must invoke the canonical read-only transition probe.'
Require $transitionProbe 'SAFE-TO-APPLY' 'W11 transition probe must retain plan authorization semantics.'
Require $transitionProbe 'PLAN SHA-256' 'W11 transition probe must hash-bind its generated plan.'
Require $transitionCleanupBootstrap 'ExpectedPlanSha256' 'W11 transition cleanup must remain plan/hash bound.'
Require $prepare 'exhaustive-hash-check-skipped' 'Milestone prep must explicitly record skipped exhaustive hashing.'
Require $sanity 'not a full-file/hash proof' 'Fast sanity must not overclaim baseline verification.'
Require $compare 'VERIFY \[' 'Full baseline comparison must emit durable progress.'
Require $deploy 'No mods found, no deployment is needed' 'REDmod deploy helper must reject empty deployment as success.'
Require $deploy 'Commandlet deploy has succeeded' 'REDmod deploy helper must require positive deployment evidence.'
Require $audit 'LOCAL EVIDENCE REPORT:' 'Compatibility audit must expose a file handoff.'
Require $removalVerifier 'read-only|does not delete|No files were modified' 'Removal verifier must remain read-only.'
Require $cleanRoom 'LOCAL-OPERATOR-COMMANDS\.md' 'Clean-room policy must defer routine commands to the catalog.'

Write-Host 'PASS: local operator commands are zero-repo/exact-head/failure-durable; Command 13 retention is compatibility-only; Commands 14-16 enforce repo-backed one-bundle evidence, ZIP-independent recovery, shared-dependency preservation, and exact tool-owned cleanup.'
