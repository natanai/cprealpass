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

# Generic plumbing only. Mod Settings is intentionally present again because the
# accepted product surface uses it for runtime presence, a concise read-only-ish
# feature ledger and binary presentation/accessibility preferences. ArchiveXL is a
# declared dependency of the pinned Mod Settings release. None of these components
# owns RealPass simulation policy.
$genericIds = @('red4ext','redscript','archivexl','mod-settings')
& "$PSScriptRoot\Acquire-Components.ps1" -ComponentIds $genericIds
if ($LASTEXITCODE -ne 0) { throw 'Generic framework acquisition/verification failed.' }
& "$PSScriptRoot\Stage-Components.ps1" -Profile 'm1-owned-settings'
if ($LASTEXITCODE -ne 0) { throw 'Generic framework staging failed.' }
$genericManifestPath = Resolve-SafeChildPath $project 'manifest/m1-owned-settings.deployment.json'
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

# Source/reference gameplay or presentation hosts remain forbidden. Mod Settings is
# no longer forbidden because it is now an explicitly accepted generic UI/persistence
# provider; it must still never own RealPass gameplay policy.
foreach ($forbidden in @('darkfuture','dark future','project e3','project-e3','input-loader')) {
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
    schemaVersion = 1
    buildId = $BuildId
    generatedAtUtc = [DateTime]::UtcNow.ToString('o')
    gameVersion = $manifest.gameVersion
    ownedRuntime = $true
    diagnosticsEnabled = [bool]$Diagnostics
    genericComponents = $genericIds
    sourceModsRequired = @()
    settingsProvider = 'mod-settings'
    coreBuildId = $coreBuildId
    fileCount = $files.Count
    manifestPath = $outputRelative
    scope = 'Deployable development profile containing project-original RealPass runtime plus pinned RED4ext/redscript/ArchiveXL/Mod Settings plumbing. Mod Settings provides status/ledger and binary presentation preferences only. No Dark Future, Project E3 or Input Loader runtime content. Does not deploy or launch the game.'
}
Write-JsonFile $record $report
Write-Host "PASS: deployable owned runtime profile $BuildId compiled with $($files.Count) files. Nothing was deployed or launched."
return $outputRelative
