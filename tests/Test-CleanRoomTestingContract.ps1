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
$reset = Read 'tools/Reset-BiologyIteration.ps1'
$legacyReset = Read 'tools/Reset-RealPassIteration.ps1'
$publishSnapshot = Read 'tools/Publish-LocalGameReferenceSnapshot.ps1'
$package = Read 'tools/Build-BiologyPackage.ps1'
$legacyPackage = Read 'tools/Build-CleanRoomTestPackage.ps1'
$deploy = Read 'tools/Deploy-BiologyRedmod.ps1'
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
Require $doc 'biology/build-manifest\.json' 'Biology iteration cleanup must be tied to the installed owner manifest.'
Require $doc 'Build-BiologyPackage\.ps1' 'Clean-room doc must name the canonical integrated Biology builder.'
Require $doc 'Reset-BiologyIteration\.ps1' 'Clean-room doc must name the Biology manifest reset path.'
Require $doc 'Deploy-BiologyRedmod\.ps1' 'Clean-room doc must name deterministic REDmod deployment.'
Require $doc 'Build-CleanRoomTestPackage\.ps1.*PKG-06|PKG-06.*Build-CleanRoomTestPackage\.ps1' 'Legacy clean-room builder must be demoted to a PKG-06 fallback rather than silently deleted.'
Require $doc 'If any of those checks fail, the correct response is a milestone reset' 'Cleanup must fail closed rather than broaden deletion.'
Require $doc 'MILESTONE CLEAN-ROOM' 'Structural REDmod-first integration must require milestone clean-room acceptance.'

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
Require $capture 'HASH \[\{0\}\].*files.*GiB.*elapsed' 'Long vanilla baseline hashing must emit durable host-independent progress.'
Require $capture '-c "user\.name=\$commitAuthorName"' 'Vanilla baseline publishing must not depend on machine-global Git author configuration.'
Require $capture '-c "user\.email=\$commitAuthorEmail"' 'Vanilla baseline publishing must scope an email identity to the generated commit.'

Require $publishSnapshot 'Refresh-LocalGameReference\.ps1' 'Current-state publisher must refresh the GitHub-safe snapshot first.'
Require $publishSnapshot 'local-game-snapshot-' 'Current-state publisher must use a dedicated snapshot branch.'
Require $publishSnapshot 'git -C \$project add -- ''reference/cyberpunk''' 'Current-state publisher must scope commits to reference metadata.'

Require $compare 'Get-FileHash' 'Baseline comparison must verify file hashes, not path names alone.'
Require $compare "Status='EXTRA'" 'Baseline comparison must detect extra files.'
Require $compare "Status='MISSING'" 'Baseline comparison must detect missing files.'
Require $compare "Status='HASH'" 'Baseline comparison must detect changed same-sized files.'

Require $reset 'biology\\build-manifest\.json' 'Biology reset must require the installed Biology owner manifest.'
Require $reset 'baselineByPath\.ContainsKey' 'Biology reset must protect paths that existed in vanilla.'
Require $reset 'Installed package file changed since installation' 'Biology reset must refuse changed package-owned files.'
Require $reset 'approved-dependency-owned' 'Biology reset must understand exact dependency-file ownership without owning shared roots.'
Require $reset 'Compare-GameToVanillaBaseline\.ps1' 'Biology reset must finish with a strict whole-game baseline comparison.'
Require $reset 'MILESTONE CLEAN-ROOM' 'Biology reset must fail closed to milestone mode.'
Require $legacyReset 'realpass\\build-manifest\.json' 'Legacy reset must remain available for the prior package during PKG-06 transition.'

Require $package 'mods/Biology/info\.json' 'Integrated package must include official Biology REDmod identity.'
Require $package 'r6/scripts/CyberpunkRealism|runtimeManifest\.files' 'Integrated package must consume the compiled Biology runtime destinations.'
Require $package 'Compress-Archive' 'Integrated Biology builder must emit a player-shaped ZIP.'
Require $package 'BIOLOGY-VERSION\.txt' 'Integrated package must emit Biology release metadata at archive root.'
Require $package 'Nothing was deployed or launched' 'Integrated builder must remain non-deploying.'
Require $package 'Build-OwnedRuntimeProfile\.ps1' 'Integrated builder must exact-compile the complete runtime profile before artifact emission.'
Require $package 'biology/build-manifest\.json' 'Integrated package must emit exact Biology ownership metadata.'
Require $package 'approved-dependency-owned' 'Integrated package must account for supplemental framework files individually.'
Require $package 'sourceModsRequired = @\(\)' 'Integrated package must require no source gameplay/presentation mod runtime.'
Require $legacyPackage 'Build-OwnedRuntimeProfile\.ps1' 'Known-working old route must remain present until PKG-06 direct replacement proof.'

Require $deploy 'redMod\.exe' 'Deterministic deploy helper must call official REDmod.'
Require $deploy '''deploy''' 'Deterministic deploy helper must call the deploy module.'
Require $deploy '-root=\$game' 'Deterministic deploy helper must pass explicit game root.'
Require $deploy '2\.3\.1\.0' 'Deploy helper must guard directly evidenced REDmod file version.'
Require $deploy '2\.31' 'Deploy helper must guard directly evidenced REDmod product version.'

Require $compile 'redscript-cli\.exe' 'Compile profile must use the pinned redscript CLI.'
Require $compile 'https://github\.com/jac3km4/redscript/releases/download/v0\.5\.31/redscript-cli\.exe' 'Fresh-clone compile must acquire the pinned official redscript CLI asset.'
Require $compile 'CDCBED2E0C943322BBCBBAC4A9C62EF29ADC5620E4B0934F0D2A31A8282B5B62' 'Pinned redscript CLI digest changed or disappeared.'
Require $compile 'if\(-not \(Test-Path -LiteralPath \$cli -PathType Leaf\)\)' 'Compile path must bootstrap a missing developer compiler in a fresh clone.'
Require $compile 'Invoke-WebRequest -Uri \$cliUri -OutFile \$partial' 'Compile path does not acquire the missing pinned compiler.'
Require $compile 'Downloaded offline compiler hash mismatch' 'Downloaded compiler must be verified before installation.'
Require $compile '\$logsDir=Join-Path \$project ''logs''' 'Fresh-clone compile must create its log output root.'
Require $compile '\$reportsDir=Join-Path \$project ''reports''' 'Fresh-clone compile must create its report output root.'
Require $compile 'New-Item -ItemType Directory -Force -Path \$dir' 'Fresh-clone compile must materialize ignored output directories before writing.'

Write-Host 'PASS: attended testing now uses the REDmod-first Biology build/deploy/reset route, preserves strict vanilla-baseline cleanup and milestone discipline, and keeps the old package path only as a PKG-06 rollback.'
