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

# realpass currently uses only REDscript language/runtime plumbing. No owned source
# imports RED4ext/ArchiveXL/TweakXL/Codeware/Mod Settings/Input Loader APIs, so the
# live-test profile deliberately does not carry those historical framework layers.
$genericIds = @('redscript')
& "$PSScriptRoot\Acquire-Components.ps1" -ComponentIds $genericIds
if ($LASTEXITCODE -ne 0) { throw 'REDscript acquisition/verification failed.' }
& "$PSScriptRoot\Stage-Components.ps1" -Profile 'm1-base'
if ($LASTEXITCODE -ne 0) { throw 'REDscript staging failed.' }
$genericManifestPath = Resolve-SafeChildPath $project 'manifest/m1-base.deployment.json'
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
    throw 'Owned source candidate and REDscript runtime base disagree on ownership or game version.'
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

foreach ($forbidden in @('darkfuture','dark future','project e3','project-e3','red4ext','archivexl','tweakxl','codeware','mod-settings','input-loader')) {
    $hit = @($files | Where-Object { ([string]$_.component).ToLowerInvariant().Contains($forbidden) -or ([string]$_.destination).ToLowerInvariant().Contains($forbidden) })
    if ($hit.Count -gt 0) { throw "Forbidden or unnecessary runtime content leaked into owned profile: $($hit[0].destination)" }
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
    coreBuildId = $coreBuildId
    fileCount = $files.Count
    manifestPath = $outputRelative
    scope = 'Deployable development profile containing project-original realpass REDscript plus pinned redscript plumbing only. No source-mod runtime, RED4ext-family framework, settings framework, or input-loader content is required by this candidate. Does not deploy or launch the game.'
}
Write-JsonFile $record $report
Write-Host "PASS: deployable owned runtime profile $BuildId compiled with $($files.Count) files using only project-original realpass source plus redscript. Nothing was deployed or launched."
return $outputRelative