$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\tools\Common.ps1"
$project = Get-ProjectRoot
$path = Join-Path $project 'manifest/distribution.json'
$distribution = Get-Content -Raw -LiteralPath $path | ConvertFrom-Json
if ($distribution.schemaVersion -ne 2 -or $distribution.product -ne 'Biology') { throw 'Unexpected Biology distribution contract.' }
if ($distribution.target.experience -ne 'one-download-normal-launch') { throw 'Release UX target drifted.' }
if ($distribution.target.preferredInstall -ne 'game-root-shaped-redmod-first-zip') { throw 'Distribution is not REDmod-first.' }
if ($distribution.target.officialPackageIdentity -ne 'mods/Biology') { throw 'Official Biology REDmod package identity drifted.' }
if ($distribution.target.canonicalBuilder -ne 'tools/Build-BiologyPackage.ps1') { throw 'Distribution has no canonical integrated builder.' }
if ($distribution.target.specialLauncherRequiredAfterInstall -ne $false) { throw 'Biology must not require a permanent special launcher.' }
if ($distribution.target.playerUninstaller -ne 'Uninstall Biology.exe') { throw 'Distribution lost the self-contained player uninstaller.' }
if ($distribution.target.launcherDisableExperience -notmatch '(?i)launcher.*off.*Biology-inactive') { throw 'Distribution does not define launcher-off vanilla-play behavior.' }
if ($distribution.releaseGate.publicPlayableArtifactReady -ne $false) { throw 'Public playable artifact must remain gated until direct live/release acceptance.' }
if ($distribution.releaseGate.candidatePlayableAfterExactCompile -ne $true) { throw 'Integrated exact-compiled candidate is not distinguished from public release acceptance.' }

$components = @{}
foreach ($component in @($distribution.components)) {
    if ([string]::IsNullOrWhiteSpace($component.id)) { throw 'Distribution component without id.' }
    if ($components.ContainsKey($component.id)) { throw "Duplicate distribution component: $($component.id)" }
    $components[$component.id] = $component
    if ([string]::IsNullOrWhiteSpace($component.artifactPolicy) -or [string]::IsNullOrWhiteSpace($component.status)) { throw "Incomplete distribution policy: $($component.id)" }
}
foreach ($required in @('biology-project-original','redscript','red4ext','archivexl','mod-settings','tweakxl','codeware','input-loader','darkfuture','project-e3-hud','cyberpunk-game-files')) {
    if (-not $components.ContainsKey($required)) { throw "Distribution component missing: $required" }
}
foreach ($id in @('biology-project-original','redscript')) { if ($components[$id].status -ne 'allowed') { throw "Direct Biology/runtime component is not allowed: $id" } }
foreach ($id in @('red4ext','archivexl','mod-settings')) { if ($components[$id].status -ne 'temporary' -or $components[$id].artifactPolicy -notmatch 'temporarily') { throw "Settings-chain component is not explicitly temporary: $id" } }
if ($components['redscript'].notes -notmatch '(?i)additive|wrapper') { throw 'redscript retention lost its seam-specific rationale.' }
if ($components['redscript'].notes -notmatch '(?i)preserves|preserve') { throw 'Distribution no longer records conservative redscript player-uninstall policy.' }
if ($components['mod-settings'].notes -notmatch '(?i)provider-neutral' -or $components['mod-settings'].notes -notmatch '(?i)Lane C') { throw 'Mod Settings temporary removal blocker is not accurately described.' }
foreach ($id in @('tweakxl','codeware','input-loader')) { if ($components[$id].status -ne 'not-required') { throw "Unneeded framework appears required by Biology: $id" } }
foreach ($id in @('darkfuture','project-e3-hud','cyberpunk-game-files')) { if ($components[$id].status -ne 'blocked') { throw "Forbidden runtime component is not blocked: $id" } }
if ($components['cyberpunk-game-files'].artifactPolicy -ne 'never-bundle') { throw 'Game files must never enter a Biology artifact.' }

$forbidden = @($distribution.forbiddenArtifactPatterns)
foreach ($pattern in @('Cyberpunk2077.exe','final.redscripts','UserSettings.json','*.sav','vendor/**','ReferenceMods/**')) { if ($forbidden -notcontains $pattern) { throw "Forbidden artifact pattern missing: $pattern" } }
$mustPass = @($distribution.releaseGate.mustPass)
foreach ($gate in @('integrated-exact-redscript-compile-2.31','redmod-recognition-and-deploy','redmod-enable-disable-relaunch-persistence','clean-uninstall-reset','redmod-overlap-precedence-probe','native-body-acceptance','native-presentation-acceptance','artifact-hash-and-content-verification','player-uninstaller-safety-tests')) { if ($mustPass -notcontains $gate) { throw "Release gate missing: $gate" } }
$requirements = $distribution.artifactRequirements -join ' '
foreach ($requiredText in @('mods/Biology','project-original','redscript','RED4ext','ArchiveXL','Mod Settings','SHA-256','Uninstall Biology.exe')) { if ($requirements -notmatch [regex]::Escape($requiredText)) { throw "Distribution artifact requirements lost required current contract text: $requiredText" } }
if ($requirements -notmatch '(?i)licenses.*third-party notices') { throw 'Bundled generic dependencies do not require license/notice inclusion.' }
if ($requirements -notmatch '(?i)preserves generic/shared dependencies') { throw 'Distribution does not require conservative shared dependency uninstall behavior.' }
if ($requirements -notmatch '(?i)not live acceptance') { throw 'Distribution contract conflates source/build success with live acceptance.' }

Write-Host "PASS: Biology REDmod-first distribution contract ($($components.Count) component policies, $($forbidden.Count) forbidden patterns); launcher OFF is fail-closed, player uninstall is bundled, redscript is directly retained, the settings chain is temporary, and source mods/unneeded frameworks remain excluded."
