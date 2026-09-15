$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\tools\Common.ps1"
$project = Get-ProjectRoot

$agents = Get-Content -Raw -LiteralPath (Join-Path $project 'AGENTS.md')
$catalog = Get-Content -Raw -LiteralPath (Join-Path $project 'docs/LOCAL-OPERATOR-COMMANDS.md')
$cleanRoom = Get-Content -Raw -LiteralPath (Join-Path $project 'docs/CLEAN-ROOM-TESTING.md')
$prepare = Get-Content -Raw -LiteralPath (Join-Path $project 'tools/Prepare-BiologyMilestoneTest.ps1')
$sanity = Get-Content -Raw -LiteralPath (Join-Path $project 'tools/Test-VanillaGameSanity.ps1')
$compare = Get-Content -Raw -LiteralPath (Join-Path $project 'tools/Compare-GameToVanillaBaseline.ps1')
$deploy = Get-Content -Raw -LiteralPath (Join-Path $project 'tools/Deploy-BiologyRedmod.ps1')
$verify = Get-Content -Raw -LiteralPath (Join-Path $project 'tools/Verify-BiologyRemoval.ps1')

function Require([string]$text,[string]$pattern,[string]$message) {
    if ($text -notmatch $pattern) { throw $message }
}

Require $agents 'LOCAL OPERATOR COMMAND GATE' 'AGENTS.md must make the local operator command catalog mandatory.'
Require $agents 'docs/LOCAL-OPERATOR-COMMANDS\.md' 'Agents must be directed to the canonical local operator command catalog.'
Require $agents 'do not invent|must not invent|rather than invent' 'AGENTS.md must prohibit ad-hoc replacement of catalogued commands.'
Require $agents 'disposable.*Biology-Test|Biology-Test-<YYYY-MM-DD>-<short-main-sha>' 'AGENTS.md must describe disposable milestone workspaces rather than a permanent CyberpunkRealism checkout.'

Require $catalog 'canonical user-run command surface' 'Local command catalog must declare itself canonical.'
Require $catalog 'Command 0 — bootstrap a disposable milestone workspace' 'Catalog must provide the no-local-repo bootstrap path.'
Require $catalog 'Prepare-BiologyMilestoneTest\.ps1' 'Catalog must route milestone preparation through the repository-owned orchestrator.'
Require $catalog 'exhaustive.*defaults to \*\*No\*\*' 'Catalog must make the expensive fresh-reinstall hash scan optional and default it off.'
Require $catalog 'Test-VanillaGameSanity\.ps1' 'Catalog must expose the fast post-reinstall sanity check.'
Require $catalog 'Compare-GameToVanillaBaseline\.ps1' 'Catalog must retain the strict full hash comparison for uncertain/reused installs.'
Require $catalog 'VERIFY \[' 'Catalog must document visible durable comparison progress.'
Require $catalog 'Capture-VanillaGameBaseline\.ps1' 'Catalog must document deliberate baseline refresh/publish rather than silently deleting that capability.'
Require $catalog 'Reset-BiologyIteration\.ps1' 'Catalog must document iteration reset.'
Require $catalog 'Verify-BiologyRemoval\.ps1' 'Catalog must document the canonical post-player-uninstall residue check.'
Require $catalog 'double-click.*Uninstall Biology\.exe' 'Catalog must keep hard uninstall player-facing rather than PowerShell-driven.'
Require $catalog 'Audit-GameContracts\.ps1' 'Catalog must document direct compatibility audit.'
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

Require $verify 'mods/Biology' 'Removal verifier must inspect the official Biology REDmod package root.'
Require $verify 'r6/scripts/CyberpunkRealism' 'Removal verifier must inspect Biology supplemental script residue.'
Require $verify 'Generic redscript/RED4ext/ArchiveXL/Mod Settings' 'Removal verifier must distinguish preserved shared dependencies from Biology residue.'
if ($verify -match '(?i)Remove-Item|Directory\.Delete|File\.Delete') { throw 'Removal verification must remain read-only.' }

Require $cleanRoom 'exhaustive.*optional|optional.*exhaustive' 'Clean-room policy must explicitly allow the expensive hash pass to be optional after a fresh reinstall.'
Require $cleanRoom 'fast sanity' 'Clean-room policy must define the lightweight post-reinstall evidence path.'
Require $cleanRoom 'must not.*verified against recorded vanilla baseline|not.*verified against recorded vanilla baseline' 'Clean-room policy must prevent overclaiming when the exhaustive hash check is skipped.'
Require $cleanRoom 'LOCAL-OPERATOR-COMMANDS\.md' 'Clean-room policy must defer routine user commands to the canonical catalog.'

Write-Host 'PASS: local operator commands are standardized, player hard-uninstall verification is read-only/reusable, milestone prep asks before expensive hashing, visible full-scan progress is enforced, and REDmod exit-zero false positives fail closed.'
