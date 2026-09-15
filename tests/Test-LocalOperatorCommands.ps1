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

$agents = Read 'AGENTS.md'
$catalog = Read 'docs/LOCAL-OPERATOR-COMMANDS.md'
$cleanRoom = Read 'docs/CLEAN-ROOM-TESTING.md'
$prepare = Read 'tools/Prepare-BiologyMilestoneTest.ps1'
$sanity = Read 'tools/Test-VanillaGameSanity.ps1'
$compare = Read 'tools/Compare-GameToVanillaBaseline.ps1'
$deploy = Read 'tools/Deploy-BiologyRedmod.ps1'
$officialProbe = Read 'tools/Probe-OfficialRedmod.ps1'

Require $agents 'LOCAL OPERATOR COMMAND GATE' 'AGENTS.md must make the local operator command catalog mandatory.'
Require $agents 'docs/LOCAL-OPERATOR-COMMANDS\.md' 'Agents must be directed to the canonical local operator command catalog.'
Require $agents 'do not invent|must not invent|rather than invent' 'AGENTS.md must prohibit ad-hoc replacement of catalogued commands.'
Require $agents 'disposable.*Biology-Test|Biology-Test-<YYYY-MM-DD>-<short-main-sha>' 'AGENTS.md must describe disposable milestone workspaces rather than a permanent checkout.'

Require $catalog 'canonical user-run command surface' 'Local command catalog must declare itself canonical.'
Require $catalog 'Command 0 — bootstrap a disposable milestone workspace' 'Catalog must provide the no-local-repo bootstrap path.'
Require $catalog 'Prepare-BiologyMilestoneTest\.ps1' 'Catalog must route milestone preparation through the repository-owned orchestrator.'
Require $catalog 'exhaustive.*defaults to \*\*No\*\*' 'Catalog must make the expensive fresh-reinstall hash scan optional and default it off.'
Require $catalog 'Test-VanillaGameSanity\.ps1' 'Catalog must expose the fast post-reinstall sanity check.'
Require $catalog 'Compare-GameToVanillaBaseline\.ps1' 'Catalog must retain the strict full hash comparison for uncertain/reused installs.'
Require $catalog 'VERIFY \[' 'Catalog must document visible durable comparison progress.'
Require $catalog 'Capture-VanillaGameBaseline\.ps1' 'Catalog must document deliberate baseline refresh/publish rather than silently deleting that capability.'
Require $catalog 'Reset-BiologyIteration\.ps1' 'Catalog must document iteration reset.'
Require $catalog 'Audit-GameContracts\.ps1' 'Catalog must document direct compatibility audit.'
Require $catalog 'Command 9 — ask the installed official REDmod tool what it can do' 'Catalog must expose direct official REDmod capability probing.'
Require $catalog 'Probe-OfficialRedmod\.ps1' 'Catalog must route official REDmod capability questions through the repository-owned probe.'
Require $catalog 'community.*fallback|modder.*fallback|community/modder route is necessary' 'Catalog must not treat community practice as proof that an official route is unavailable.'
Require $catalog 'No mods found.*failure|failure.*No mods found' 'Catalog must explain that an empty REDmod set is a deployment failure for installed Biology.'

Require $prepare 'Read-Host.*exhaustive vanilla hash verification' 'Milestone orchestrator must ask the user whether to run the expensive full baseline comparison.'
Require $prepare '\$runExhaustive = \$answer -in' 'Milestone exhaustive verification must default to off unless explicitly accepted.'
Require $prepare 'fully uninstalled in Steam.*residual install directory removed.*reinstalled' 'Skipping the full comparison must require fresh reinstall confirmation.'
Require $prepare 'Test-VanillaGameSanity\.ps1' 'Skipped exhaustive comparison must still run the canonical fast sanity probe.'
Require $prepare 'exhaustive-hash-check-skipped' 'Skipped exhaustive comparison must be explicit in evidence.'
Require $prepare 'git clone' 'Milestone orchestrator must create a fresh candidate clone.'
Require $prepare 'Build-BiologyPackage\.ps1' 'Milestone orchestrator must use the canonical package builder.'
Require $prepare 'Deploy-BiologyRedmod\.ps1' 'Milestone orchestrator must use the canonical REDmod deploy helper.'
Require $prepare 'milestone-prep\.json' 'Milestone orchestrator must persist concise handoff evidence.'
Require $prepare 'STOP_BEFORE_GAME_LAUNCH=YES' 'Milestone preparation must stop before attended launch so the parent can issue the checklist.'

Require $sanity 'archive\\pc\\mod' 'Fast sanity check must reject loose archive mod payload.'
Require $sanity 'r6\\scripts' 'Fast sanity check must reject loose REDscript payload.'
Require $sanity 'red4ext' 'Fast sanity check must reject RED4ext payload on a claimed fresh vanilla install.'
Require $sanity "relativeToMods -eq '\.stub'.*Length -eq 0" 'Fast sanity check must permit only the stock zero-byte REDmod .stub under mods.'
Require $sanity 'not a full-file/hash proof' 'Fast sanity check must not overclaim baseline verification.'

Require $compare 'VERIFY \[\{0\}\].*files.*GiB.*elapsed' 'Full baseline comparison must emit host-independent durable progress.'
Require $compare 'Write-Progress' 'Full baseline comparison should retain native Write-Progress in addition to durable console output.'

Require $deploy 'ProcessStartInfo' 'REDmod deploy must control native argument boundaries explicitly.'
Require $deploy 'ArgumentList\.Add' 'REDmod deploy must use native ArgumentList rather than ambiguous shell string reconstruction.'
Require $deploy "Invoke-Redmod @\('deploy','-root'," 'REDmod deploy must try the current split root form.'
Require $deploy '"-root=\$game"' 'REDmod deploy must retain the documented equals-form fallback.'
Require $deploy 'No root specified' 'REDmod deploy must detect ignored explicit-root arguments.'
Require $deploy 'Invalid root path found' 'REDmod deploy must detect invalid-root fallback.'
Require $deploy 'No mods found, no deployment is needed' 'REDmod deploy must detect empty mod discovery even when REDmod exits zero.'
Require $deploy 'Commandlet deploy has succeeded' 'REDmod deploy must require positive deploy completion evidence.'
Require $deploy 'Deployment is NOT accepted|not recognized as a deployable REDmod' 'REDmod deploy must fail closed on deceptive exit-zero output.'

Require $officialProbe 'tools\\redmod\\bin\\redMod\.exe' 'Official REDmod probe must call the game-provided CDPR executable directly.'
Require $officialProbe "Arguments @\('--help'\)|@\('--help'\)" 'Official REDmod probe must query the installed tool help surface.'
Require $officialProbe 'ProcessStartInfo' 'Official REDmod probe must control native invocation boundaries.'
Require $officialProbe 'Get-Sha256' 'Official REDmod probe must fingerprint the executable used as evidence.'
Require $officialProbe 'metadata\.json' 'Official REDmod probe must inventory shipped REDmod metadata/toolset signals.'
Require $officialProbe 'reports' 'Official REDmod probe must write a durable report for remote agents.'
Require $officialProbe 'read-only|No game/package/deploy files were modified' 'Official REDmod probe must be explicitly read-only.'

Require $cleanRoom 'exhaustive.*optional|optional.*exhaustive' 'Clean-room policy must explicitly allow the expensive hash pass to be optional after a fresh reinstall.'
Require $cleanRoom 'fast sanity' 'Clean-room policy must define the lightweight post-reinstall evidence path.'
Require $cleanRoom 'must not.*verified against recorded vanilla baseline|not.*verified against recorded vanilla baseline' 'Clean-room policy must prevent overclaiming when the exhaustive hash check is skipped.'
Require $cleanRoom 'LOCAL-OPERATOR-COMMANDS\.md' 'Clean-room policy must defer routine user commands to the canonical catalog.'

Write-Host 'PASS: local operator commands are standardized, official REDmod capability probing is direct/read-only, milestone prep asks before expensive hashing, and REDmod exit-zero false positives fail closed.'
