param(
    [Parameter(Mandatory=$true)][ValidatePattern('^[a-zA-Z0-9][a-zA-Z0-9._-]*$')][string]$BuildId,
    [Parameter(Mandatory=$true)][string]$ManifestPath,
    [string]$GameRoot = 'C:\Games\Steam\steamapps\common\Cyberpunk 2077',
    [switch]$Diagnostics,
    [switch]$ShowTraditionalHealthBars
)
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\Common.ps1"
$project = Get-ProjectRoot
$sourceManifest = Resolve-SafeChildPath $project $ManifestPath
$outputRelative = 'manifest/' + $BuildId + '.deployment.json'
$output = Resolve-SafeChildPath $project $outputRelative
$report = Resolve-SafeChildPath $project ('reports/attended-' + $BuildId + '.json')
if ((Test-Path -LiteralPath $output) -or (Test-Path -LiteralPath $report)) {
    throw 'Build ID already exists; attended acceptance profiles are immutable. Use a new BuildId.'
}
$manifest = Get-Content -Raw -LiteralPath $sourceManifest | ConvertFrom-Json
if ($manifest.schemaVersion -ne 1 -or [string]::IsNullOrWhiteSpace($manifest.buildId) -or [string]::IsNullOrWhiteSpace($manifest.gameVersion)) {
    throw 'Unexpected deployment manifest contract.'
}

# Validate the complete source profile before changing any gate. This prevents an
# attended builder from laundering a stale/corrupt local manifest into a new one.
$destinations = @{}
foreach ($file in @($manifest.files)) {
    $destination = ([string]$file.destination).Replace('\','/')
    if ($destinations.ContainsKey($destination)) { throw "Duplicate profile destination: $destination" }
    $destinations[$destination] = $file
    $source = Resolve-SafeChildPath $project $file.source
    if ($file.sha256 -notmatch '^[A-Fa-f0-9]{64}$' -or (Get-Sha256 $source) -ne $file.sha256) {
        throw "Source profile hash mismatch: $destination"
    }
}

$stageRelative = 'staging/attended-' + [guid]::NewGuid().ToString('N')
$stage = Resolve-SafeChildPath $project $stageRelative
New-Item -ItemType Directory -Force -Path $stage | Out-Null
$changes = [Collections.Generic.List[object]]::new()

function Replace-PolicyOnce([string]$text,[string]$className,[string]$methodName,[bool]$enable) {
    $pattern = '(public class ' + [regex]::Escape($className) + ' extends IScriptable \{\s+public static func ' + [regex]::Escape($methodName) + '\(\) -> Bool \{\s+)return false;'
    if ([regex]::Matches($text,$pattern).Count -ne 1) { throw "Expected one closed policy gate: $className.$methodName" }
    if (-not $enable) { return $text }
    return [regex]::Replace($text,$pattern,'${1}return true;')
}

function Stage-Replacement([string]$destination,[string]$text,[string]$label) {
    if (-not $destinations.ContainsKey($destination)) { throw "Required profile file missing: $destination" }
    $entry = $destinations[$destination]
    $leaf = [IO.Path]::GetFileName($destination)
    $relative = $stageRelative + '/' + $leaf
    $target = Resolve-SafeChildPath $project $relative
    [IO.File]::WriteAllText($target,$text,[Text.UTF8Encoding]::new($false))
    $before = $entry.sha256
    $entry.source = $relative
    $entry.sha256 = Get-Sha256 $target
    $changes.Add([ordered]@{destination=$destination;purpose=$label;beforeSha256=$before;afterSha256=$entry.sha256})
}

# Body must run for V's localized wound/bleeding/recovery path to be observable.
$bodyDestination = 'r6/scripts/CyberpunkRealism/BodyRuntime.reds'
if (-not $destinations.ContainsKey($bodyDestination)) { throw 'Attended profile requires BodyRuntime.reds.' }
$bodyEntry = $destinations[$bodyDestination]
$bodySource = Resolve-SafeChildPath $project $bodyEntry.source
$bodyText = [IO.File]::ReadAllText($bodySource).Replace("`r`n","`n")
$bodyText = Replace-PolicyOnce $bodyText 'CRBodyRuntimePolicy' 'Enabled' $true
if ($Diagnostics) {
    $bodyText = Replace-PolicyOnce $bodyText 'CRBodyTestPolicy' 'Diagnostics' $true
} else {
    # Fail closed: diagnostics must still exist and remain false in an ordinary
    # attended gameplay build.
    $bodyText = Replace-PolicyOnce $bodyText 'CRBodyTestPolicy' 'Diagnostics' $false
}
Stage-Replacement $bodyDestination $bodyText ('body enabled; diagnostics=' + [bool]$Diagnostics)

# Combat is deliberately opened only in this generated profile; repository source
# remains closed. All existing native injury/armor/blood-loss safety checks still
# decide whether an individual hit is eligible.
$combatDestination = 'r6/scripts/CyberpunkRealism/CombatNativeBridge.reds'
if (-not $destinations.ContainsKey($combatDestination)) { throw 'Attended profile requires CombatNativeBridge.reds.' }
$combatEntry = $destinations[$combatDestination]
$combatSource = Resolve-SafeChildPath $project $combatEntry.source
$combatText = [IO.File]::ReadAllText($combatSource).Replace("`r`n","`n")
$combatText = Replace-PolicyOnce $combatText 'CRCombatRuntimePolicy' 'Enabled' $true
Stage-Replacement $combatDestination $combatText 'combat native bridge enabled for attended acceptance'

# Add project-original no-healthbar presentation to the test candidate by default.
# It hides HP UI only; it does not change the damage/stat-pool simulation.
$healthbarDestination = 'r6/scripts/CyberpunkRealism/NoHealthbars.reds'
$healthbarSourceRelative = 'src/redscript/CyberpunkRealism/NoHealthbars.reds'
$healthbarSource = Resolve-SafeChildPath $project $healthbarSourceRelative
$healthbarHash = Get-Sha256 $healthbarSource
if (-not $ShowTraditionalHealthBars) {
    if ($destinations.ContainsKey($healthbarDestination)) {
        $existing = $destinations[$healthbarDestination]
        if ($existing.sha256 -ne $healthbarHash) { throw 'Profile already owns NoHealthbars.reds with a different hash.' }
    } else {
        $entry = [pscustomobject][ordered]@{
            source = $healthbarSourceRelative
            destination = $healthbarDestination
            sha256 = $healthbarHash
            component = 'realpass-presentation'
        }
        $manifest.files += $entry
        $destinations[$healthbarDestination] = $entry
        $changes.Add([ordered]@{destination=$healthbarDestination;purpose='traditional player/NPC/boss health bars hidden';beforeSha256=$null;afterSha256=$healthbarHash})
    }
}

$sourceBuildId = [string]$manifest.buildId
$manifest.buildId = $BuildId
Write-JsonFile $manifest $output

# Compile the exact generated profile against the user's pinned Cyberpunk 2.31
# bundle/toolchain. This does not copy anything into the live game.
& "$PSScriptRoot\Compile-Profile.ps1" -ManifestPath $outputRelative -GameRoot $GameRoot

$record = [ordered]@{
    schemaVersion = 1
    buildId = $BuildId
    sourceBuildId = $sourceBuildId
    sourceManifest = $ManifestPath
    generatedAtUtc = [DateTime]::UtcNow.ToString('o')
    gameVersion = $manifest.gameVersion
    bodyEnabled = $true
    combatEnabled = $true
    diagnosticsEnabled = [bool]$Diagnostics
    traditionalHealthBars = [bool]$ShowTraditionalHealthBars
    noTraditionalHealthBars = -not [bool]$ShowTraditionalHealthBars
    changes = @($changes.ToArray())
    manifestPath = $outputRelative
    scope = 'Attended compile candidate only. Build does not deploy or launch Cyberpunk. Native combat feel, UI rendering, saves, quests, bosses and Phantom Liberty still require player-attended acceptance.'
}
Write-JsonFile $record $report
Write-Host "Staged and compiled attended candidate $BuildId: body=on, combat=on, healthBars=$([bool]$ShowTraditionalHealthBars), diagnostics=$([bool]$Diagnostics). No live deployment performed."
