$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\tools\Common.ps1"
$project = Get-ProjectRoot

function Read([string]$relative) {
    $path = Join-Path $project $relative
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Missing clean-room contract file: $relative" }
    Get-Content -Raw -LiteralPath $path
}
function Require([string]$text,[string]$pattern,[string]$message) {
    if ($text -notmatch $pattern) { throw $message }
}

$agents = Read 'AGENTS.md'
$doc = Read 'docs/CLEAN-ROOM-TESTING.md'
$referenceDoc = Read 'docs/LOCAL-GAME-REFERENCE.md'
$capture = Read 'tools/Capture-VanillaGameBaseline.ps1'
$compare = Read 'tools/Compare-GameToVanillaBaseline.ps1'
$reset = Read 'tools/Reset-RealPassIteration.ps1'
$publishSnapshot = Read 'tools/Publish-LocalGameReferenceSnapshot.ps1'
$package = Read 'tools/Build-CleanRoomTestPackage.ps1'

Require $agents 'TEST HANDOFF GATE' 'AGENTS.md must put attended-test handoff rules in a prominent gate.'
Require $agents 'ITERATION TEST' 'AGENTS.md must distinguish iteration tests.'
Require $agents 'MILESTONE CLEAN-ROOM TEST' 'AGENTS.md must distinguish milestone clean-room tests.'
Require $agents 'fresh clone/download' 'User-facing tests must require fresh canonical source.'
Require $agents 'exact `main` commit|exact canonical `main` revision' 'Test handoffs must identify the exact main revision.'
Require $agents 'recorded vanilla baseline' 'Agent instructions must require baseline evidence when reusing a game install.'

Require $doc 'A full Cyberpunk reinstall is deliberately \*\*not\*\* required for every small iteration' 'Clean-room doc must not require reinstall for every iteration.'
Require $doc 'Test mode A — iteration test' 'Clean-room doc must define iteration mode.'
Require $doc 'Test mode B — milestone clean-room' 'Clean-room doc must define milestone mode.'
Require $doc 'reference/cyberpunk/vanilla-baseline/' 'Clean-room doc must identify the tracked vanilla baseline.'
Require $doc 'build-manifest\.json' 'Iteration cleanup must be tied to the installed player-package manifest.'
Require $doc 'If any of those checks fail, the correct response is a milestone reset' 'Cleanup must fail closed rather than broaden deletion.'

Require $referenceDoc 'Publish-LocalGameReferenceSnapshot\.ps1' 'Local-game reference docs must expose the running snapshot publish path.'
Require $referenceDoc 'current observed installation|Current observed installation' 'Local-game reference docs must distinguish the current snapshot from vanilla baseline.'

Require $capture 'Get-FileHash' 'Vanilla baseline capture must hash game files.'
Require $capture 'vanilla-baseline' 'Vanilla baseline capture must write the dedicated baseline path.'
Require $capture 'local-vanilla-baseline-' 'Publish mode must use a dedicated snapshot branch.'
Require $capture 'git -C \$project add -- ''reference/cyberpunk''' 'Publish mode must scope its commit to GitHub-safe reference metadata.'
Require $capture 'archive\\pc\\mod' 'Vanilla capture must reject obvious mod payload roots.'
Require $capture 'red4ext' 'Vanilla capture must reject installed RED4ext payload.'

Require $publishSnapshot 'Refresh-LocalGameReference\.ps1' 'Current-state publisher must refresh the GitHub-safe snapshot first.'
Require $publishSnapshot 'local-game-snapshot-' 'Current-state publisher must use a dedicated snapshot branch.'
Require $publishSnapshot 'git -C \$project add -- ''reference/cyberpunk''' 'Current-state publisher must scope commits to reference metadata.'

Require $compare 'Get-FileHash' 'Baseline comparison must verify file hashes, not path names alone.'
Require $compare "Status='EXTRA'" 'Baseline comparison must detect extra files.'
Require $compare "Status='MISSING'" 'Baseline comparison must detect missing files.'
Require $compare "Status='HASH'" 'Baseline comparison must detect changed same-sized files.'

Require $reset 'build-manifest\.json' 'Iteration reset must require the previous player-package manifest.'
Require $reset 'baselineByPath\.ContainsKey' 'Iteration reset must protect paths that existed in vanilla.'
Require $reset 'Installed package file changed since installation' 'Iteration reset must refuse changed package-owned files.'
Require $reset 'Compare-GameToVanillaBaseline\.ps1' 'Iteration reset must finish with a strict whole-game baseline comparison.'

Require $package 'game-root-shaped' 'Attended package builder must remain release-shaped.'
Require $package 'Nothing was deployed to Cyberpunk' 'Package builder must remain non-deploying.'

Write-Host 'PASS: attended testing distinguishes fresh-source iteration from milestone clean-room, archives GitHub-safe game snapshots, and enforces fail-closed vanilla-baseline evidence.'
