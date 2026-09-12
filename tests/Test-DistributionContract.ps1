$ErrorActionPreference = 'Stop'
$project = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$path = Join-Path $project 'manifest/distribution.json'
if (-not (Test-Path -LiteralPath $path)) { throw 'Missing manifest/distribution.json' }

$distribution = Get-Content -Raw -LiteralPath $path | ConvertFrom-Json
if ($distribution.schemaVersion -ne 1 -or $distribution.product -ne 'realpass') { throw 'Unexpected distribution contract.' }
if ($distribution.target.experience -ne 'one-download-normal-launch') { throw 'Release UX target drifted.' }
if ($distribution.target.specialLauncherRequiredAfterInstall -ne $false) { throw 'realpass must not require a permanent special launcher.' }
if ($distribution.releaseGate.publicPlayableArtifactReady -ne $false) { throw 'Public playable artifact must remain gated until explicit release acceptance.' }

$components = @{}
foreach ($component in @($distribution.components)) {
    if ([string]::IsNullOrWhiteSpace($component.id)) { throw 'Distribution component without id.' }
    if ($components.ContainsKey($component.id)) { throw "Duplicate distribution component: $($component.id)" }
    $components[$component.id] = $component
    if ([string]::IsNullOrWhiteSpace($component.artifactPolicy) -or [string]::IsNullOrWhiteSpace($component.status)) {
        throw "Incomplete distribution policy: $($component.id)"
    }
}

foreach ($required in @('realpass-project-original','red4ext','redscript','darkfuture','project-e3-hud','cyberpunk-game-files')) {
    if (-not $components.ContainsKey($required)) { throw "Distribution component missing: $required" }
}
if ($components['realpass-project-original'].status -ne 'allowed') { throw 'Project-original runtime must remain bundleable.' }
if ($components['project-e3-hud'].status -ne 'blocked') { throw 'Project E3 HUD must remain blocked under current recorded terms.' }
if ($components['project-e3-hud'].artifactPolicy -match '^bundle$') { throw 'Project E3 HUD cannot be directly bundled under current recorded terms.' }
if ($components['cyberpunk-game-files'].status -ne 'blocked' -or $components['cyberpunk-game-files'].artifactPolicy -ne 'never-bundle') {
    throw 'Game files must never enter a realpass artifact.'
}

$forbidden = @($distribution.forbiddenArtifactPatterns)
foreach ($pattern in @('Cyberpunk2077.exe','final.redscripts','UserSettings.json','*.sav','vendor/**','ReferenceMods/**')) {
    if ($forbidden -notcontains $pattern) { throw "Forbidden artifact pattern missing: $pattern" }
}

$mustPass = @($distribution.releaseGate.mustPass)
foreach ($gate in @('dependency-license-and-transitive-notice-audit','no-blocked-assets-in-artifact','native-body-acceptance','native-combat-injury-acceptance','artifact-hash-and-content-verification')) {
    if ($mustPass -notcontains $gate) { throw "Release gate missing: $gate" }
}

Write-Host "PASS: realpass distribution contract ($($components.Count) component policies, $($forbidden.Count) forbidden patterns)."
