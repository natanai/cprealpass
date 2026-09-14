$ErrorActionPreference = 'Stop'
$project = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$path = Join-Path $project 'manifest/distribution.json'
if (-not (Test-Path -LiteralPath $path)) { throw 'Missing manifest/distribution.json' }

$distribution = Get-Content -Raw -LiteralPath $path | ConvertFrom-Json
if ($distribution.schemaVersion -ne 1 -or $distribution.product -ne 'realpass') { throw 'Unexpected distribution contract.' }
if ($distribution.target.experience -ne 'one-download-normal-launch') { throw 'Release UX target drifted.' }
if ($distribution.target.specialLauncherRequiredAfterInstall -ne $false) { throw 'realpass must not require a permanent special launcher.' }
if ($distribution.releaseGate.publicPlayableArtifactReady -ne $false) { throw 'Public playable artifact must remain gated until explicit live/release acceptance.' }

$components = @{}
foreach ($component in @($distribution.components)) {
    if ([string]::IsNullOrWhiteSpace($component.id)) { throw 'Distribution component without id.' }
    if ($components.ContainsKey($component.id)) { throw "Duplicate distribution component: $($component.id)" }
    $components[$component.id] = $component
    if ([string]::IsNullOrWhiteSpace($component.artifactPolicy) -or [string]::IsNullOrWhiteSpace($component.status)) {
        throw "Incomplete distribution policy: $($component.id)"
    }
}

foreach ($required in @('realpass-project-original','redscript','red4ext','archivexl','tweakxl','codeware','mod-settings','input-loader','darkfuture','project-e3-hud','cyberpunk-game-files')) {
    if (-not $components.ContainsKey($required)) { throw "Distribution component missing: $required" }
}

foreach ($id in @('realpass-project-original','redscript','red4ext','archivexl','mod-settings')) {
    if ($components[$id].status -ne 'allowed') { throw "Required owned/settings runtime component is not bundleable: $id" }
}
foreach ($id in @('tweakxl','codeware','input-loader')) {
    if ($components[$id].status -ne 'not-required') { throw "Unneeded framework appears required by the owned runtime: $id" }
}
foreach ($id in @('darkfuture','project-e3-hud','cyberpunk-game-files')) {
    if ($components[$id].status -ne 'blocked') { throw "Forbidden runtime component is not blocked: $id" }
}
if ($components['cyberpunk-game-files'].artifactPolicy -ne 'never-bundle') { throw 'Game files must never enter a realpass artifact.' }
if ($components['mod-settings'].notes -notmatch '(?i)(presence|ledger)' -or $components['mod-settings'].notes -notmatch '(?i)presentation') {
    throw 'Mod Settings distribution purpose drifted away from the constrained status/presentation surface.'
}

$forbidden = @($distribution.forbiddenArtifactPatterns)
foreach ($pattern in @('Cyberpunk2077.exe','final.redscripts','UserSettings.json','*.sav','vendor/**','ReferenceMods/**')) {
    if ($forbidden -notcontains $pattern) { throw "Forbidden artifact pattern missing: $pattern" }
}

$mustPass = @($distribution.releaseGate.mustPass)
foreach ($gate in @('dependency-license-and-notice-audit','no-blocked-or-unrequired-runtime-in-artifact','native-body-acceptance','native-combat-injury-acceptance','native-presentation-acceptance','artifact-hash-and-content-verification')) {
    if ($mustPass -notcontains $gate) { throw "Release gate missing: $gate" }
}
$requirements = $distribution.artifactRequirements -join ' '
foreach ($requiredText in @('project-original RealPass payload','redscript','RED4ext','ArchiveXL','Mod Settings')) {
    if ($requirements -notmatch [regex]::Escape($requiredText)) { throw "Distribution artifact requirements lost required runtime component: $requiredText" }
}
if ($requirements -notmatch '(?i)licenses.*third-party notices') { throw 'Bundled generic dependencies do not require license/notice inclusion.' }

Write-Host "PASS: RealPass standalone distribution contract ($($components.Count) component policies, $($forbidden.Count) forbidden patterns); owned source plus the constrained redscript/RED4ext/ArchiveXL/Mod Settings plumbing are bundleable while source mods and unneeded frameworks remain excluded."
