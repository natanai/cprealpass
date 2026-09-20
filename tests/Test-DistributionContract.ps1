$ErrorActionPreference = 'Stop'
$project = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$path = Join-Path $project 'manifest/distribution.json'
if (-not (Test-Path -LiteralPath $path)) { throw 'Missing manifest/distribution.json' }

$distribution = Get-Content -Raw -LiteralPath $path | ConvertFrom-Json
if ($distribution.schemaVersion -ne 3 -or $distribution.product -ne 'Biology') { throw 'Unexpected Biology distribution contract.' }
if ($distribution.target.experience -ne 'one-download-normal-launch') { throw 'Release UX target drifted.' }
if ($distribution.target.preferredInstall -ne 'game-root-shaped-redmod-first-zip') { throw 'Distribution is not REDmod-first.' }
if ($distribution.target.officialPackageIdentity -ne 'mods/Biology') { throw 'Official Biology REDmod package identity drifted.' }
if ($distribution.target.canonicalBuilder -ne 'tools/Build-BiologyPackage.ps1') { throw 'Distribution has no canonical integrated builder.' }
if ($distribution.target.specialLauncherRequiredAfterInstall -ne $false) { throw 'Biology must not require a permanent special launcher.' }
if ($distribution.target.vanillaPlayTarget -notmatch '(?i)Enable mods OFF') { throw 'Distribution lost launcher-off vanilla-play target.' }
if ($distribution.target.hardUninstallTarget -notmatch 'Uninstall Biology\.exe') { throw 'Distribution lost self-contained hard-uninstall target.' }
if ($distribution.releaseGate.publicPlayableArtifactReady -ne $false -or $distribution.releaseGate.candidatePlayableAfterExactCompile -ne $true) { throw 'Distribution release gating drifted.' }
if ($distribution.releaseGate.foundationEvidence -notmatch '(?i)REDmod recognition' -or $distribution.releaseGate.foundationEvidence -notmatch '(?i)five-stage' -or $distribution.releaseGate.foundationEvidence -notmatch '(?i)W13') { throw 'Distribution contract forgot proven REDmod foundation/W13 evidence.' }

$components = @{}
foreach ($component in @($distribution.components)) {
    if ([string]::IsNullOrWhiteSpace($component.id)) { throw 'Distribution component without id.' }
    if ($components.ContainsKey($component.id)) { throw "Duplicate distribution component: $($component.id)" }
    $components[$component.id] = $component
}
foreach ($required in @('biology-project-original','redscript','cybercmd','tweakxl','codeware','input-loader','darkfuture','project-e3-hud','cyberpunk-game-files')) {
    if (-not $components.ContainsKey($required)) { throw "Distribution component missing: $required" }
}
foreach ($retired in @('mod-settings','archivexl','red4ext')) {
    if ($components.ContainsKey($retired)) { throw "Retired settings-stack component still appears as an active distribution component: $retired" }
    if (@($distribution.removedDependencies) -notcontains $retired) { throw "Retired dependency is not recorded as removed: $retired" }
}
foreach ($id in @('biology-project-original','redscript','cybercmd')) { if ($components[$id].status -ne 'allowed') { throw "Direct Biology/runtime component is not allowed: $id" } }
if ($components['redscript'].notes -notmatch '(?i)additive|wrapper' -or $components['redscript'].notes -notmatch '(?i)preference|ScriptableSystem') { throw 'redscript retention lost its exact settings/runtime consumer rationale.' }
if ($components['cybercmd'].notes -notmatch '(?i)InvokeScc' -or $components['cybercmd'].notes -notmatch 'final\.redscripts' -or $components['cybercmd'].notes -notmatch '(?i)not Biology activation') { throw 'cybercmd distribution entry lost its narrow startup-only rationale.' }
foreach ($id in @('tweakxl','codeware','input-loader')) { if ($components[$id].status -ne 'not-required') { throw "Unneeded framework appears required: $id" } }
foreach ($id in @('darkfuture','project-e3-hud','cyberpunk-game-files')) { if ($components[$id].status -ne 'blocked') { throw "Forbidden runtime component is not blocked: $id" } }
if ($components['cyberpunk-game-files'].artifactPolicy -ne 'never-bundle') { throw 'Game files must never enter a Biology artifact.' }

$forbidden = @($distribution.forbiddenArtifactPatterns)
foreach ($pattern in @('Cyberpunk2077.exe','final.redscripts','UserSettings.json','*.sav','vendor/**','ReferenceMods/**','red4ext/plugins/mod_settings/**','red4ext/plugins/ArchiveXL/**','red4ext/RED4ext.dll','bin/x64/winmm.dll')) {
    if ($forbidden -notcontains $pattern) { throw "Forbidden artifact pattern missing: $pattern" }
}
$mustPass = @($distribution.releaseGate.mustPass)
foreach ($gate in @('integrated-exact-redscript-compile-2.31','redscript-startup-output-regeneration','redmod-recognition-and-deploy','redmod-enable-disable-relaunch-persistence','launcher-off-biology-inactive','self-contained-e3-preference-persistence','self-contained-hard-uninstall','clean-uninstall-reset','redmod-overlap-precedence-probe','native-body-acceptance','native-presentation-acceptance','artifact-hash-and-content-verification')) {
    if ($mustPass -notcontains $gate) { throw "Release gate missing: $gate" }
}
$requirements = $distribution.artifactRequirements -join ' '
foreach ($requiredText in @('mods/Biology','project-original','redscript','cybercmd','ScriptableSystem','Uninstall Biology.exe','SHA-256')) {
    if ($requirements -notmatch [regex]::Escape($requiredText)) { throw "Distribution artifact requirements lost current contract text: $requiredText" }
}
if ($requirements -notmatch '(?i)Mod Settings.*ArchiveXL.*RED4ext.*not release dependencies') { throw 'Distribution does not state the settings-stack exit.' }
if ($requirements -notmatch '(?i)not live acceptance') { throw 'Distribution contract conflates source/build success with live acceptance.' }

Write-Host 'PASS: Biology distribution is REDmod-first, uses redscript plus cybercmd for generic startup/runtime plumbing, remains self-contained for settings, and excludes the retired Mod Settings/ArchiveXL/RED4ext stack.'
