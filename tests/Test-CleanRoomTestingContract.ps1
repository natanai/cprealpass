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
$compile = Read 'tools/Compile-Profile.ps1'

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
Require $capture 'relativeToMods -eq ''\.stub'' -and \$file\.Length -eq 0' 'Vanilla capture must permit only the exact zero-byte REDmod .stub marker.'
Require $capture 'mods/\$relativeToMods' 'Vanilla capture must still reject any other file under mods.'
Require $capture 'HASH \[\{0\}\].*files.*GiB.*elapsed' 'Long vanilla baseline hashing must emit durable host-independent progress, not rely only on Write-Progress.'
Require $capture '-c "user\.name=\$commitAuthorName"' 'Vanilla baseline publishing must not depend on machine-global Git author configuration.'
Require $capture '-c "user\.email=\$commitAuthorEmail"' 'Vanilla baseline publishing must scope an email identity to the generated commit.'

Require $publishSnapshot 'Refresh-LocalGameReference\.ps1' 'Current-state publisher must refresh the GitHub-safe snapshot first.'
Require $publishSnapshot 'local-game-snapshot-' 'Current-state publisher must use a dedicated snapshot branch.'
Require $publishSnapshot 'git -C \$project add -- ''reference/cyberpunk''' 'Current-state publisher must scope commits to reference metadata.'
Require $publishSnapshot '-c "user\.name=\$commitAuthorName"' 'Current-state snapshot publishing must not depend on machine-global Git author configuration.'
Require $publishSnapshot '-c "user\.email=\$commitAuthorEmail"' 'Current-state snapshot publishing must scope an email identity to the generated commit.'

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

# A fresh clone must be able to exact-compile without carrying developer binaries in
# Git. The pinned official redscript CLI is a local build dependency only and must
# be downloaded on demand with its exact upstream digest before execution.
Require $compile 'redscript-cli\.exe' 'Compile profile must use the pinned redscript CLI.'
Require $compile 'https://github\.com/jac3km4/redscript/releases/download/v0\.5\.31/redscript-cli\.exe' 'Fresh-clone compile must acquire the pinned official redscript CLI asset.'
Require $compile 'CDCBED2E0C943322BBCBBAC4A9C62EF29ADC5620E4B0934F0D2A31A8282B5B62' 'Pinned redscript CLI digest changed or disappeared.'
Require $compile 'if\(-not \(Test-Path -LiteralPath \$cli -PathType Leaf\)\)' 'Compile path must bootstrap a missing developer compiler in a fresh clone.'
Require $compile 'Invoke-WebRequest -Uri \$cliUri -OutFile \$partial' 'Compile path does not acquire the missing pinned compiler.'
Require $compile 'Downloaded offline compiler hash mismatch' 'Downloaded compiler must be verified before installation.'

Write-Host 'PASS: attended testing distinguishes fresh-source iteration from milestone clean-room, archives GitHub-safe game snapshots, enforces fail-closed vanilla-baseline evidence, and bootstraps the pinned offline compiler in fresh clones.'
