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
if ($components['realpass-project-original'].status -ne 'allowed') { throw 'Project-original runtime must remain bundleable.' }
if ($components['redscript'].status -ne 'allowed') { throw 'Pinned redscript is the required generic runtime and must be bundleable.' }
foreach ($id in @('red4ext','archivexl','tweakxl','codeware','mod-settings','input-loader')) {
    if ($components[$id].status -ne 'not-required') { throw "Historical framework still appears required by the owned runtime: $id" }
}
foreach ($id in @('darkfuture','project-e3-hud','cyberpunk-game-files')) {
    if ($components[$id].status -ne 'blocked') { throw "Forbidden runtime component is not blocked: $id" }
}
if ($components['cyberpunk-game-files'].artifactPolicy -ne 'never-bundle') { throw 'Game files must never enter a realpass artifact.' }

$forbidden = @($distribution.forbiddenArtifactPatterns)
foreach ($pattern in @('Cyberpunk2077.exe','final.redscripts','UserSettings.json','*.sav','vendor/**','ReferenceMods/**')) {
    if ($forbidden -notcontains $pattern) { throw "Forbidden artifact pattern missing: $pattern" }
}

$mustPass = @($distribution.releaseGate.mustPass)
foreach ($gate in @('dependency-license-and-notice-audit','no-blocked-or-unrequired-runtime-in-artifact','native-body-acceptance','native-combat-injury-acceptance','native-presentation-acceptance','artifact-hash-and-content-verification')) {
    if ($mustPass -notcontains $gate) { throw "Release gate missing: $gate" }
}
if (($distribution.artifactRequirements -join ' ') -notmatch 'project-original realpass payload plus the pinned redscript runtime') {
    throw 'Distribution artifact requirements do not lock the minimal runtime set.'
}

Write-Host "PASS: realpass standalone distribution contract ($($components.Count) component policies, $($forbidden.Count) forbidden patterns); only realpass + redscript are allowed runtime components."