param(
    [Parameter(Mandatory=$true)][ValidatePattern('^[a-zA-Z0-9][a-zA-Z0-9._-]*$')][string]$BuildId,
    [string]$GameRoot = 'C:\Games\Steam\steamapps\common\Cyberpunk 2077',
    [switch]$Diagnostics
)
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\Common.ps1"
$project = Get-ProjectRoot
$game = Assert-GameRoot $GameRoot
Assert-GameStopped

$outputRelative = 'manifest/' + $BuildId + '.deployment.json'
$output = Resolve-SafeChildPath $project $outputRelative
$report = Resolve-SafeChildPath $project ('reports/owned-runtime-' + $BuildId + '.json')
if ((Test-Path -LiteralPath $output) -or (Test-Path -LiteralPath $report)) {
    throw 'Build ID already exists; owned runtime profiles are immutable. Use a new BuildId.'
}

# redscript is the only retained generic runtime component. Biology's remaining
# player preference is save-backed by its own ScriptableSystem and edited from its
# own body shell, so Mod Settings/ArchiveXL/RED4ext are neither acquired nor staged.
$genericIds = @('redscript')
& "$PSScriptRoot\Acquire-Components.ps1" -ComponentIds $genericIds
if ($LASTEXITCODE -ne 0) { throw 'Retained generic framework acquisition/verification failed.' }
& "$PSScriptRoot\Stage-Components.ps1" -Profile 'biology-runtime'
if ($LASTEXITCODE -ne 0) { throw 'Retained generic framework staging failed.' }
$genericManifestPath = Resolve-SafeChildPath $project 'manifest/biology-runtime.deployment.json'
$genericManifest = Get-Content -Raw -LiteralPath $genericManifestPath | ConvertFrom-Json

$unexpected = @($genericManifest.files | Where-Object { [string]$_.component -notin $genericIds })
if ($unexpected.Count -gt 0) {
    throw "Owned runtime base contains an unexpected component: $($unexpected[0].component)"
}

# Build-OwnedAcceptance starts from repository-owned REDscript, opens canonical
# body/combat gates only in immutable staged copies, rejects source-mod namespaces,
# and exact-compiles the source-only candidate before it can be merged with plumbing.
$coreBuildId = $BuildId + '-core'
$ownedArgs = @{ BuildId = $coreBuildId; GameRoot = $game }
if ($Diagnostics) { $ownedArgs.Diagnostics = $true }
& "$PSScriptRoot\Build-OwnedAcceptance.ps1" @ownedArgs | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'Owned source candidate failed exact compilation.' }
$coreManifestPath = Resolve-SafeChildPath $project ('manifest/' + $coreBuildId + '.deployment.json')
$coreManifest = Get-Content -Raw -LiteralPath $coreManifestPath | ConvertFrom-Json
if (-not $coreManifest.ownedRuntime -or $coreManifest.gameVersion -ne $genericManifest.gameVersion) {
    throw 'Owned source candidate and generic runtime base disagree on ownership or game version.'
}

$files = [Collections.Generic.List[object]]::new()
$destinations = @{}
foreach ($entry in @($genericManifest.files) + @($coreManifest.files)) {
    $destination = ([string]$entry.destination).Replace('\','/')
    if ($destinations.ContainsKey($destination)) {
        throw "Owned runtime profile has overlapping destination: $destination"
    }
    $source = Resolve-SafeChildPath $project ([string]$entry.source)
    if ($entry.sha256 -notmatch '^[A-Fa-f0-9]{64}$' -or (Get-Sha256 $source) -ne $entry.sha256) {
        throw "Owned runtime profile source hash mismatch: $destination"
    }
    $destinations[$destination] = $true
    $files.Add([pscustomobject][ordered]@{
        source = [string]$entry.source
        destination = $destination
        sha256 = [string]$entry.sha256
        component = [string]$entry.component
        origin = $(if ($entry.PSObject.Properties.Name -contains 'origin') { [string]$entry.origin } else { 'pinned-generic-framework' })
    })
}

# Source/reference gameplay or presentation hosts and the retired settings stack are
# forbidden from the deployable profile. This fail-closed check makes accidental
# reintroduction visible even if a future staging profile drifts.
foreach ($forbidden in @('darkfuture','dark future','project e3','project-e3','input-loader','mod-settings','mod_settings','archivexl','archive xl','red4ext')) {
    $hit = @($files | Where-Object { ([string]$_.component).ToLowerInvariant().Contains($forbidden) -or ([string]$_.destination).ToLowerInvariant().Contains($forbidden) })
    if ($hit.Count -gt 0) { throw "Forbidden runtime content leaked into owned profile: $($hit[0].destination)" }
}

$manifest = [ordered]@{
    schemaVersion = 1
    buildId = $BuildId
    gameVersion = [string]$coreManifest.gameVersion
    ownedRuntime = $true
    profile = 'owned-runtime-development'
    files = @($files.ToArray())
}
Write-JsonFile $manifest $output

# Compile the exact final deployable manifest, not merely the source-only precursor.
& "$PSScriptRoot\Compile-Profile.ps1" -ManifestPath $outputRelative -GameRoot $game
if ($LASTEXITCODE -ne 0) { throw 'Final owned runtime profile failed exact compilation.' }

$record = [ordered]@{
    schemaVersion = 2
    buildId = $BuildId
    generatedAtUtc = [DateTime]::UtcNow.ToString('o')
    gameVersion = $manifest.gameVersion
    ownedRuntime = $true
    diagnosticsEnabled = [bool]$Diagnostics
    genericComponents = $genericIds
    sourceModsRequired = @()
    settingsProvider = 'biology-owned-save-state'
    publicPreferences = @('presentation.e3-first-person-hud-visuals')
    activationAuthority = 'REDmod launcher sentinel'
    coreBuildId = $coreBuildId
    fileCount = $files.Count
    manifestPath = $outputRelative
    scope = 'Deployable Biology runtime containing project-original REDscript plus pinned redscript only. The E3 presentation preference is persisted by Biology save state and edited in Biology-owned UI. No Mod Settings, ArchiveXL, RED4ext, Dark Future, Project E3 or Input Loader runtime content. Does not deploy or launch the game.'
}
Write-JsonFile $record $report
Write-Host "PASS: deployable owned runtime profile $BuildId compiled with $($files.Count) files. Nothing was deployed or launched."
return $outputRelative
