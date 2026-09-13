param(
    [string]$GameRoot = 'C:\Games\Steam\steamapps\common\Cyberpunk 2077',
    [Parameter(Mandatory=$true)][string]$ManifestPath,
    [string]$StateRoot,
    [switch]$WhatIf
)
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\Common.ps1"
$project = Get-ProjectRoot
$GameRoot = Assert-GameRoot $GameRoot
Assert-GameStopped
if (-not $StateRoot) { $StateRoot = Join-Path $project 'snapshots\deployment-state' }
$StateRoot = [IO.Path]::GetFullPath($StateRoot)
$manifest = Get-Content -Raw -LiteralPath $ManifestPath | ConvertFrom-Json
if ($manifest.schemaVersion -ne 1 -or -not $manifest.ownedRuntime -or $manifest.buildId -notmatch '^[a-zA-Z0-9][a-zA-Z0-9._-]*$') {
    throw 'Invalid owned-runtime deployment manifest.'
}
$actualVersion = (Get-Item -LiteralPath (Join-Path $GameRoot 'bin\x64\Cyberpunk2077.exe')).VersionInfo.ProductVersion
if ($manifest.gameVersion -ne $actualVersion) { throw "Game version mismatch: expected $($manifest.gameVersion), actual $actualVersion" }

function Remove-KnownRetiredRuntime([string]$root) {
    foreach ($relative in @(
        'r6/scripts/CyberpunkRealism',
        'r6/tweaks/CyberpunkRealism',
        'r6/scripts/Dark Future',
        'r6/tweaks/Dark Future',
        'r6/scripts/Project E3 - HUD',
        'r6/tweaks/Project E3 - HUD'
    )) {
        $path = Resolve-SafeChildPath $root $relative
        if (Test-Path -LiteralPath $path) { Remove-Item -LiteralPath $path -Recurse -Force }
    }
    foreach ($relative in @(
        'r6/input/Dark Future.xml',
        'archive/pc/mod/basegame_3e_demo_hud.archive'
    )) {
        $path = Resolve-SafeChildPath $root $relative
        if (Test-Path -LiteralPath $path -PathType Leaf) { Remove-Item -LiteralPath $path -Force }
    }
    $archiveRoot = Resolve-SafeChildPath $root 'archive/pc/mod'
    if (Test-Path -LiteralPath $archiveRoot -PathType Container) {
        foreach ($file in @(Get-ChildItem -LiteralPath $archiveRoot -File)) {
            if ($file.Name -match '(?i)^Dark Future.*\.archive$|^darkfuture.*\.(archive|xl)$|Project.?E3') {
                Remove-Item -LiteralPath $file.FullName -Force
            }
        }
    }
}

$files = @($manifest.files)
if ($files.Count -eq 0) { throw 'Owned-runtime deployment manifest has no files.' }
$seen = @{}
$plan = [Collections.Generic.List[object]]::new()
for ($i = 0; $i -lt $files.Count; $i++) {
    $file = $files[$i]
    $percent = [int](100.0 * ($i + 1) / $files.Count)
    Write-Progress -Activity 'Planning fast owned-runtime install' -Status "$($i + 1)/$($files.Count): $($file.destination)" -PercentComplete $percent
    $source = Resolve-SafeChildPath $project ([string]$file.source)
    $destination = Resolve-SafeChildPath $GameRoot ([string]$file.destination)
    if ($seen.ContainsKey($destination)) { throw "Duplicate destination: $destination" }
    $seen[$destination] = $true
    if ($file.sha256 -notmatch '^[A-Fa-f0-9]{64}$' -or (Get-Sha256 $source) -ne $file.sha256) {
        throw "Invalid staged hash: $source"
    }
    $existing = Get-ExistingHash $destination
    $action = if ($existing -eq $file.sha256) { 'preserve' } elseif ($existing) { 'replace' } else { 'create' }
    $plan.Add([ordered]@{
        source = $source
        destination = [string]$file.destination
        component = [string]$file.component
        priorSha256 = $existing
        deployedSha256 = [string]$file.sha256
        action = $action
    })
}
Write-Progress -Activity 'Planning fast owned-runtime install' -Completed
if ($WhatIf) {
    $plan | ForEach-Object { [pscustomobject]$_ } | Select-Object destination,component,action
    return
}

$lock = Open-StateLock $StateRoot
try {
    Assert-GameStopped
    Write-Host 'Fast install: clearing only realpass-owned script namespaces and retired Dark Future/Project E3 runtime residue...'
    Remove-KnownRetiredRuntime $GameRoot

    for ($i = 0; $i -lt $plan.Count; $i++) {
        $item = $plan[$i]
        $percent = [int](100.0 * ($i + 1) / $plan.Count)
        Write-Progress -Activity 'Installing owned realpass runtime' -Status "$($i + 1)/$($plan.Count): $($item.destination)" -PercentComplete $percent
        Assert-GameStopped
        $destination = Resolve-SafeChildPath $GameRoot $item.destination
        if ((Get-Sha256 $item.source) -ne $item.deployedSha256) { throw "Source changed after compile: $($item.source)" }
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $destination) | Out-Null
        Copy-VerifiedPayload $item.source $destination $item.deployedSha256
        if ((Get-ExistingHash $destination) -ne $item.deployedSha256) { throw "Post-copy hash failed: $destination" }
    }
    Write-Progress -Activity 'Installing owned realpass runtime' -Completed

    $state = [ordered]@{
        schemaVersion = 1
        mode = 'flat-owned-development-install'
        buildId = [string]$manifest.buildId
        gameVersion = [string]$manifest.gameVersion
        gameRoot = $GameRoot
        installedAtUtc = [DateTime]::UtcNow.ToString('o')
        files = @($plan | ForEach-Object { [ordered]@{ destination=$_.destination; component=$_.component; sha256=$_.deployedSha256 } })
        recovery = 'Remove-OwnedRuntime.ps1 removes the recorded owned payload. Steam Verify Files or reinstall is the authoritative stock-game repair path if needed.'
    }
    $statePath = Join-Path $StateRoot 'owned-current.json'
    Write-JsonFile $state $statePath
    Write-Host "Fast owned-runtime install verified: $($plan.Count) files. State: $statePath"
    return $statePath
} finally {
    Write-Progress -Activity 'Installing owned realpass runtime' -Completed -ErrorAction SilentlyContinue
    $lock.Dispose()
}
