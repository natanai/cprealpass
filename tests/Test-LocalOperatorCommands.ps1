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
    Require $text 'StdOut|stdout' "$relative must retain child stdout for the attachable report."
    Require $text 'StdErr|stderr' "$relative must retain child stderr for the attachable report."
    Require $text 'ExitCode|exit code' "$relative must retain the child exit code."
    Require $text 'Exception type:' "$relative must preserve the outer exception type in failure evidence."
    Require $text 'Error:' "$relative must preserve the outer exception/error message in failure evidence."
    Require $text 'finally\s*\{' "$relative must expose its attachment handoff from a finally-equivalent path."
    Require $text 'ATTACH THIS FILE TO CHATGPT:' "$relative must always print the attachment handoff."
}
function Require-WorktreeAwareExactHeadBootstrap([string]$relative,[string]$text) {
    Require $text "'rev-parse','--show-toplevel'" "$relative must validate local checkout usability through Git."
    Require $text "'remote','get-url','origin'" "$relative must validate cprealpass identity through Git origin."
    Reject $text [regex]::Escape('.git\config') "$relative must not gate repository discovery on a physical .git/config file."
    Require $text 'cached remote branch' "$relative must inspect cached origin/<branch> when fetch fails."
    Require $text "'cat-file','-e'" "$relative must prove the expected commit object exists before offline fallback."
    Require $text 'Offline exact-head fallback: ACCEPTED' "$relative must record accepted exact-head offline fallback."
}

$agents = Read 'AGENTS.md'
$catalog = Read 'docs/LOCAL-OPERATOR-COMMANDS.md'
$cleanRoom = Read 'docs/CLEAN-ROOM-TESTING.md'
$prepare = Read 'tools/Prepare-BiologyMilestoneTest.ps1'
$sanity = Read 'tools/Test-VanillaGameSanity.ps1'
$compare = Read 'tools/Compare-GameToVanillaBaseline.ps1'
$deploy = Read 'tools/Deploy-BiologyRedmod.ps1'
$officialProbe = Read 'tools/Probe-OfficialRedmod.ps1'
$audit = Read 'tools/Audit-GameContracts.ps1'
$presentationBootstrap = Read 'tools/Bootstrap-PresentationAudit.ps1'
$activationBootstrap = Read 'tools/Bootstrap-RedmodActivationSentinelProbe.ps1'
$transitionProbeBootstrap = Read 'tools/Bootstrap-LegacyFrameworkTransitionProbe.ps1'
$transitionCleanupBootstrap = Read 'tools/Bootstrap-LegacyFrameworkTransitionCleanup.ps1'
$candidateBootstrap = Read 'tools/Bootstrap-BiologyPostTransitionCandidate.ps1'
$removalVerifier = Read 'tools/Verify-BiologyRemoval.ps1'

Require $agents 'LOCAL OPERATOR COMMAND GATE' 'AGENTS.md must make the local operator command catalog mandatory.'
Require $agents 'docs/LOCAL-OPERATOR-COMMANDS\.md' 'Agents must be directed to the canonical local operator command catalog.'
Require $agents 'do not invent|must not invent|rather than invent' 'AGENTS.md must prohibit ad-hoc replacement of catalogued commands.'
Require $agents 'disposable.*Biology-Test|Biology-Test-<YYYY-MM-DD>-<short-main-sha>' 'AGENTS.md must describe disposable milestone workspaces rather than a permanent checkout.'

Require $catalog 'canonical user-run command surface' 'Local command catalog must declare itself canonical.'
Require $catalog 'Mandatory repository discovery/bootstrap rule' 'Catalog must define repository discovery/bootstrap before repo-dependent local commands.'
Require $catalog 'rev-parse --show-toplevel|rev-parse.*show-toplevel' 'Catalog must describe Git-validated clone/worktree discovery.'
Require $catalog 'remote get-url origin|remote.*get-url.*origin' 'Catalog must identify existing local repos by cprealpass origin rather than a fixed folder name.'
Reject $catalog 'discovery.*\.git\\config|\.git\\config.*admission|physical `?\.git\\config`?.*required' 'Catalog must not prescribe .git/config-only repository admission.'
Require $catalog 'cached.*origin.*exact|exact-head.*cached-origin|cached-origin.*exact-head' 'Catalog must document exact-head cached-origin fallback after network failure.'
Require $catalog 'cprealpass-repo-\$Signature|cprealpass-repo-' 'Catalog must describe uniquely signed clone creation when no usable local checkout exists.'
Require $catalog 'timestamp and random suffix|random suffix.*timestamp' 'Catalog must require collision-resistant unique local workspace signatures.'
Require $catalog 'must not be assumed or recreated|must not.*recreated' 'Catalog must explicitly retire the fixed CyberpunkRealism checkout convention.'
Require $catalog 'never assume any prior local cprealpass clone/worktree.*exists|zero local repo|zero-local-repo' 'Catalog must treat zero prior repository state as a normal supported condition.'
Require $catalog 'bootstrap-loader boundary|loader boundary' 'Catalog must document that acquiring the repo-owned bootstrap is itself part of the operator path.'

Require $catalog 'Mandatory evidence-report rule' 'Catalog must define the text evidence-file handoff rule.'
Require $catalog 'plain-text.*\.txt|\.txt.*evidence report' 'Catalog must require user-returned local evidence as a text file.'
Require $catalog 'attach.*file.*ChatGPT|attach.*\.txt' 'Catalog must tell agents to request the report file rather than pasted console output.'
Require $catalog 'failure.*success|PASS.*FAIL|FAIL.*PASS' 'Evidence report policy must cover failures as well as successful runs.'
Require $catalog 'Canonical failure-durable probe/bootstrap contract' 'Catalog must generalize the failure-durable child-process evidence rule.'
Require $catalog 'not complete unless its useful evidence survives failure' 'Catalog must state that evidence durability is part of probe completeness.'
Require $catalog 'exact 40-character expected head' 'Canonical probe contract must require exact branch/head pinning when branch-specific.'
Require $catalog 'uniquely signed detached/disposable checkout|uniquely signed.*worktree' 'Canonical probe contract must require isolated disposable revision workspaces.'
Require $catalog 'read-only unless mutation is explicitly the purpose' 'Canonical probe contract must default installed game/tool trees to read-only.'
Require $catalog 'Fingerprint the authority being inspected' 'Canonical probe contract must fingerprint the exact game/native/tool authority.'
Require $catalog 'Collect bounded evidence' 'Canonical probe contract must reject indiscriminate tree/console dumping.'
Require $catalog 'source/symbol/schema evidence.*exact compilation|exact compilation.*source/symbol/schema evidence' 'Canonical probe contract must distinguish source evidence from exact compile/deploy/runtime proof.'
Require $catalog 'stdout, stderr, exit code, and actual exception/error text' 'Canonical probe contract must preserve all useful child failure diagnostics.'
Require $catalog 'requested branch/head.*fetched head.*disposable checkout/worktree path' 'Canonical probe report must record revision and checkout context.'
Require $catalog 'nonzero child exit code.*not enough|nonzero exit.*incomplete probe' 'Catalog must explicitly reject opaque nonzero-exit-only reports.'
Require $catalog 'ATTACH THIS FILE TO CHATGPT:' 'Canonical probe contract must expose the one obvious attachment handoff.'
Require $catalog 'ProcessStartInfo' 'Canonical probe contract must recommend explicit native child process capture.'
Require $catalog 'RedirectStandardOutput = true' 'Canonical probe contract must require redirected child stdout.'
Require $catalog 'RedirectStandardError = true' 'Canonical probe contract must require redirected child stderr.'
Require $catalog 'ArgumentList' 'Canonical probe contract must require safe child argument boundaries.'
Require $catalog 'outer `catch` must add the exception type and message' 'Canonical probe contract must preserve actual outer exception evidence.'

Require $catalog 'Command 0 — bootstrap a disposable milestone workspace' 'Catalog must provide the ordinary no-local-repo milestone bootstrap path.'
Require $catalog 'Prepare-BiologyMilestoneTest\.ps1' 'Catalog must route ordinary clean-room milestone preparation through the repository-owned orchestrator.'
Require $catalog 'exhaustive.*defaults to \*\*No\*\*' 'Catalog must make the expensive fresh-reinstall hash scan optional and default it off.'
Require $catalog 'Test-VanillaGameSanity\.ps1' 'Catalog must expose the fast post-reinstall sanity check.'
Require $catalog 'Compare-GameToVanillaBaseline\.ps1' 'Catalog must retain the strict full hash comparison for uncertain/reused installs.'
Require $catalog 'VERIFY \[' 'Catalog must document visible durable comparison progress.'
Require $catalog 'Capture-VanillaGameBaseline\.ps1' 'Catalog must document deliberate baseline refresh/publish.'
Require $catalog 'Reset-BiologyIteration\.ps1' 'Catalog must document iteration reset.'
Require $catalog 'Verify-BiologyRemoval\.ps1' 'Catalog must expose Biology-specific post-uninstall residue verification.'
Require $catalog 'double-click.*Uninstall Biology\.exe' 'Catalog must identify the player-facing hard-uninstall action.'
Require $catalog 'Audit-GameContracts\.ps1' 'Catalog must document direct compatibility audit.'
Require $catalog 'LOCAL EVIDENCE REPORT:' 'Catalog must document the text-report handoff line.'
Require $catalog 'Command 9 — ask the installed official REDmod tool what it can do' 'Catalog must expose direct official REDmod capability probing.'
Require $catalog 'Probe-OfficialRedmod\.ps1' 'Catalog must route official REDmod capability questions through the repository-owned probe.'
Require $catalog 'community.*fallback|modder.*fallback|Community/modder.*fallback' 'Catalog must not treat community practice as proof that an official route is unavailable.'
Require $catalog 'No mods found.*failure|failure.*No mods found' 'Catalog must explain that an empty REDmod set is a deployment failure for installed Biology.'
Require $catalog 'Command 13 — post-W11 transition canonical candidate preparation' 'Catalog must provide the P01.2 W11-transition candidate path.'
Require $catalog 'Bootstrap-BiologyPostTransitionCandidate\.ps1' 'Catalog must route the transition candidate through the repository-owned W12 bootstrap.'
Require $catalog 'TransitionCleanupReportPath' 'Catalog must require the reviewed W11 cleanup evidence path.'
Require $catalog 'ExpectedTransitionCleanupReportSha256' 'Catalog must pin the reviewed W11 cleanup evidence hash.'
Require $catalog 'NOT.*vanilla-baseline|not.*vanilla baseline' 'Catalog must not misclassify the W11 transition state as vanilla baseline proof.'
Require $catalog 'Biology-Post-Transition-Candidate-Prep-' 'Catalog must document the W12 report filename contract.'
Require $catalog 'Biology-Candidate-Artifacts-' 'Catalog must document retained candidate artifact location outside disposable source.'
Require $catalog 'STOP_BEFORE_GAME_LAUNCH=YES' 'Catalog must state that W12 candidate preparation stops before launch.'

foreach ($pair in @(
    @{Name='tools/Bootstrap-PresentationAudit.ps1';Text=$presentationBootstrap},
    @{Name='tools/Bootstrap-RedmodActivationSentinelProbe.ps1';Text=$activationBootstrap},
    @{Name='tools/Bootstrap-LegacyFrameworkTransitionProbe.ps1';Text=$transitionProbeBootstrap},
    @{Name='tools/Bootstrap-LegacyFrameworkTransitionCleanup.ps1';Text=$transitionCleanupBootstrap},
    @{Name='tools/Bootstrap-BiologyPostTransitionCandidate.ps1';Text=$candidateBootstrap}
)) {
    Require-WorktreeAwareExactHeadBootstrap -relative $pair.Name -text $pair.Text
}

Require $presentationBootstrap '\[Parameter\(Mandatory=\$true\)\]\[string\]\$Branch' 'Presentation bootstrap must require the exact branch explicitly.'
Require $presentationBootstrap '\[ValidatePattern\(''\^\[0-9a-fA-F\]\{40\}\$''\)\].*\$ExpectedHead' 'Presentation bootstrap must require an exact 40-character head SHA.'
Require $presentationBootstrap 'Biology-Presentation-Audit-' 'Presentation bootstrap must create a uniquely named text evidence report.'
Require $presentationBootstrap 'No usable cprealpass seed checkout found\. Cloning seed' 'Presentation bootstrap must explicitly support zero-local-repository acquisition.'
Require $presentationBootstrap 'cprealpass-presentation-audit-' 'Presentation bootstrap must use a uniquely signed disposable audit checkout.'
Require $presentationBootstrap 'Audit-PresentationContracts\.ps1' 'Presentation bootstrap must invoke the repository-owned presentation audit.'
Require $presentationBootstrap 'INNER PRESENTATION AUDIT PROCESS OUTPUT' 'Presentation bootstrap must persist child process output.'
Require $presentationBootstrap 'Cyberpunk product version:' 'Presentation bootstrap must fingerprint inspected game version.'
Require $presentationBootstrap 'Cyberpunk executable SHA-256:' 'Presentation bootstrap must fingerprint inspected game executable.'
Reject $presentationBootstrap 'C:\\Games\\CyberpunkRealism' 'Presentation bootstrap reintroduced the retired fixed repo path.'

Require $activationBootstrap 'No usable cprealpass seed checkout found\. Cloning seed' 'Activation bootstrap must support zero-local-repository acquisition.'
Require $activationBootstrap 'cprealpass-redmod-activation-probe-' 'Activation bootstrap must use a uniquely signed disposable audit checkout.'
Require $activationBootstrap 'Probe-RedmodActivationSentinel\.ps1' 'Activation bootstrap must invoke the repository-owned activation sentinel probe.'

Require-FailureDurableChildBootstrap -relative 'tools/Bootstrap-PresentationAudit.ps1' -text $presentationBootstrap
Require-FailureDurableChildBootstrap -relative 'tools/Bootstrap-RedmodActivationSentinelProbe.ps1' -text $activationBootstrap
Require-FailureDurableChildBootstrap -relative 'tools/Bootstrap-BiologyPostTransitionCandidate.ps1' -text $candidateBootstrap

Require $candidateBootstrap 'Transition-state classification:' 'W12 bootstrap must record the exact transition-state classification.'
Require $candidateBootstrap 'Build-BiologyPackage\.ps1' 'W12 bootstrap must use release-shaped builder.'
Require $candidateBootstrap 'Deploy-BiologyRedmod\.ps1' 'W12 bootstrap must use canonical deployment helper.'
Require $candidateBootstrap 'Retained artifact SHA-256:' 'W12 bootstrap must report artifact checksum.'
Require $candidateBootstrap 'Installed receipt sourceRevision:' 'W12 bootstrap must verify installed source revision.'
Require $candidateBootstrap 'worktree.*remove.*--force|''worktree'',''remove'',''--force''' 'W12 bootstrap must clean its disposable worktree.'
Require $candidateBootstrap 'KEEP UNTIL ATTENDED TEST' 'W12 bootstrap must label retained evidence/artifact state.'
Require $candidateBootstrap 'STOP_BEFORE_GAME_LAUNCH=YES' 'W12 bootstrap must stop before game launch.'
Reject $candidateBootstrap '(?i)Start-Process[^\r\n]*Cyberpunk' 'W12 bootstrap must not launch the game.'

Require $prepare 'Read-Host.*exhaustive vanilla hash verification' 'Milestone orchestrator must ask whether to run expensive full baseline comparison.'
Require $prepare '\$runExhaustive = \$answer -in' 'Milestone exhaustive verification must default off unless explicitly accepted.'
Require $prepare 'fully uninstalled in Steam.*residual install directory removed.*reinstalled' 'Skipping full comparison must require fresh reinstall confirmation.'
Require $prepare 'Test-VanillaGameSanity\.ps1' 'Skipped exhaustive comparison must still run canonical fast sanity probe.'
Require $prepare 'exhaustive-hash-check-skipped' 'Skipped exhaustive comparison must be explicit in evidence.'
Require $prepare 'git clone' 'Milestone orchestrator must create a fresh candidate clone.'
Require $prepare 'Build-BiologyPackage\.ps1' 'Milestone orchestrator must use canonical package builder.'
Require $prepare 'Deploy-BiologyRedmod\.ps1' 'Milestone orchestrator must use canonical REDmod deploy helper.'
Require $prepare 'milestone-prep\.json' 'Milestone orchestrator must persist concise handoff evidence.'
Require $prepare 'STOP_BEFORE_GAME_LAUNCH=YES' 'Milestone preparation must stop before attended launch.'

Require $sanity 'archive\\pc\\mod' 'Fast sanity check must reject loose archive mod payload.'
Require $sanity 'r6\\scripts' 'Fast sanity check must reject loose REDscript payload.'
Require $sanity 'red4ext' 'Fast sanity check must reject RED4ext payload on a claimed fresh vanilla install.'
Require $sanity "relativeToMods -eq '\.stub'.*Length -eq 0" 'Fast sanity check must permit only stock zero-byte REDmod .stub under mods.'
Require $sanity 'not a full-file/hash proof' 'Fast sanity check must not overclaim baseline verification.'

Require $compare 'VERIFY \[\{0\}\].*files.*GiB.*elapsed' 'Full baseline comparison must emit host-independent durable progress.'
Require $compare 'Write-Progress' 'Full baseline comparison should retain native Write-Progress in addition to durable console output.'

Require $deploy 'ProcessStartInfo' 'REDmod deploy must control native argument boundaries explicitly.'
Require $deploy 'ArgumentList\.Add' 'REDmod deploy must use native ArgumentList.'
Require $deploy "Invoke-Redmod @\('deploy','-root'," 'REDmod deploy must try current split root form.'
Require $deploy '"-root=\$game"' 'REDmod deploy must retain documented equals-form fallback.'
Require $deploy 'No root specified' 'REDmod deploy must detect ignored explicit-root arguments.'
Require $deploy 'Invalid root path found' 'REDmod deploy must detect invalid-root fallback.'
Require $deploy 'No mods found, no deployment is needed' 'REDmod deploy must detect empty mod discovery even with exit zero.'
Require $deploy 'Commandlet deploy has succeeded' 'REDmod deploy must require positive deploy completion evidence.'
Require $deploy 'Deployment is NOT accepted|not recognized as a deployable REDmod' 'REDmod deploy must fail closed on deceptive exit-zero output.'

Require $audit 'Split-Path -Parent \$PSScriptRoot' 'Compatibility audit must derive repo root from its checkout.'
Require $audit 'local-game-contract-audit-' 'Compatibility audit must create a uniquely named text evidence report.'
Require $audit 'Start-Transcript' 'Compatibility audit must capture diagnostic output into evidence report.'
Require $audit 'Stop-Transcript' 'Compatibility audit must finalize evidence report.'
Require $audit 'LOCAL EVIDENCE REPORT:' 'Compatibility audit must print absolute evidence-file handoff path.'
Require $audit 'Return that \.txt file' 'Compatibility audit must instruct user to return file rather than pasted output.'
Require $audit 'FAIL: Biology native-contract audit did not complete' 'Compatibility audit report must preserve failure outcome.'
Require $audit 'PASS: Biology native-contract audit completed' 'Compatibility audit text evidence must preserve success outcome.'
Require $audit 'textEvidenceReport' 'Compatibility JSON metadata must point to text evidence report.'
Reject $audit "\[string\]\`\$RepoRoot = 'C:\\Games\\CyberpunkRealism'" 'Compatibility audit reintroduced retired fixed repo default.'

Require $removalVerifier 'mods\\Biology|mods/Biology' 'Removal verifier must inspect Biology REDmod namespace.'
Require $removalVerifier 'r6\\scripts\\CyberpunkRealism|r6/scripts/CyberpunkRealism' 'Removal verifier must inspect Biology REDscript namespace.'
Require $removalVerifier 'read-only|does not delete|No files were modified' 'Removal verifier must be read-only.'

Require $officialProbe 'Join-Path \$game .*tools\\redmod' 'Official REDmod probe must resolve game-provided tools\\redmod root.'
Require $officialProbe 'Join-Path \$redmodRoot .*bin\\redMod\.exe' 'Official REDmod probe must call game-provided CDPR executable directly.'
Require $officialProbe 'Arguments @\(''--help''\)|@\(''--help''\)' 'Official REDmod probe must query installed tool help surface.'
Require $officialProbe 'ProcessStartInfo' 'Official REDmod probe must control native invocation boundaries.'
Require $officialProbe 'Get-Sha256' 'Official REDmod probe must fingerprint executable used as evidence.'
Require $officialProbe 'metadata\.json' 'Official REDmod probe must inventory shipped REDmod metadata/toolset signals.'
Require $officialProbe 'reports' 'Official REDmod probe must write durable report for remote agents.'
Require $officialProbe 'read-only|No game/package/deploy files were modified' 'Official REDmod probe must be explicitly read-only.'

Require $cleanRoom 'exhaustive.*optional|optional.*exhaustive' 'Clean-room policy must allow expensive hash pass to be optional after fresh reinstall.'
Require $cleanRoom 'fast sanity' 'Clean-room policy must define lightweight post-reinstall evidence path.'
Require $cleanRoom 'must not.*verified against recorded vanilla baseline|not.*verified against recorded vanilla baseline' 'Clean-room policy must prevent overclaiming when exhaustive hash is skipped.'
Require $cleanRoom 'LOCAL-OPERATOR-COMMANDS\.md' 'Clean-room policy must defer routine user commands to canonical catalog.'

Write-Host 'PASS: local operator commands are worktree-aware, exact-head/offline-safe, zero-repo bootstrappable, failure-durable, transition-state-aware, and preserve the established clean-room/removal/deployment contracts.'
