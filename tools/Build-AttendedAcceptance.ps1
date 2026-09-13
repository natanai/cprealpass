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

# A broad combat-feel session is useful only when the whole causal chain is in the
# candidate. Fail early with an actionable list rather than silently testing body +
# one bridge while armor, injury consequences, blood loss or field care are absent.
$requiredDestinations = @(
    'r6/scripts/CyberpunkRealism/BodyRuntime.reds',
    'r6/scripts/CyberpunkRealism/BodyInteractionRuntime.reds',
    'r6/scripts/CyberpunkRealism/CombatNativeBridge.reds',
    'r6/scripts/CyberpunkRealism/CombatProfilesNative.reds',
    'r6/scripts/CyberpunkRealism/CombatWoundsNative.reds',
    'r6/scripts/CyberpunkRealism/ArmorWearNative.reds',
    'r6/scripts/CyberpunkRealism/InjuryEffectsNative.reds',
    'r6/scripts/CyberpunkRealism/BloodLossNative.reds',
    'r6/scripts/CyberpunkRealism/FieldCareRuntime.reds',
    'r6/scripts/CyberpunkRealism/FieldCareActionRuntime.reds',
    'r6/scripts/CyberpunkRealism/FieldCareItemUse.reds',
    'r6/scripts/CyberpunkRealism/FieldCareUI.reds'
)
$missing = @($requiredDestinations | Where-Object { -not $destinations.ContainsKey($_) })
if ($missing.Count -gt 0) {
    throw "Source manifest is not a broad realpass acceptance profile. Missing:`n - $($missing -join "`n - ")"
}
if (@($manifest.files | Where-Object component -eq 'mod-settings').Count -eq 0) {
    throw 'Broad attended settings surface requires the pinned Mod Settings component in the source profile.'
}

$stageRelative = 'staging/attended-' + [guid]::NewGuid().ToString('N')
$stage = Resolve-SafeChildPath $project $stageRelative
New-Item -ItemType Directory -Force -Path $stage | Out-Null
$changes = [Collections.Generic.List[object]]::new()

function Set-PolicyOnce([string]$text,[string]$className,[string]$methodName,[bool]$desired,[string]$requiredCurrent='') {
    $pattern = '(public class ' + [regex]::Escape($className) + ' extends IScriptable \{\s+public static func ' + [regex]::Escape($methodName) + '\(\) -> Bool \{\s+)return (?<value>true|false);'
    $matches = [regex]::Matches($text,$pattern)
    if ($matches.Count -ne 1) { throw "Expected one policy gate: $className.$methodName" }
    $current = $matches[0].Groups['value'].Value
    if ($requiredCurrent -in @('true','false') -and $current -ne $requiredCurrent) {
        throw "Unexpected current policy for $className.$methodName: $current; required $requiredCurrent"
    }
    $desiredText = $desired.ToString().ToLowerInvariant()
    if ($current -eq $desiredText) { return $text }
    return [regex]::Replace($text,$pattern,('${1}return ' + $desiredText + ';'))
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

function Sync-ProjectSource([string]$sourceRelative,[string]$destination,[string]$component,[string]$label) {
    $source = Resolve-SafeChildPath $project $sourceRelative
    $hash = Get-Sha256 $source
    if ($destinations.ContainsKey($destination)) {
        $existing = $destinations[$destination]
        $owner = [string]$existing.component
        if (-not [string]::IsNullOrWhiteSpace($owner) -and $owner -notlike 'realpass*' -and $owner -ne 'cyberpunk-realism-body') {
            throw "$destination is owned by a non-realpass component: $owner"
        }
        $before = $existing.sha256
        $existing.source = $sourceRelative
        $existing.sha256 = $hash
        if ([string]::IsNullOrWhiteSpace($owner)) { $existing.component = $component }
        $changes.Add([ordered]@{destination=$destination;purpose=$label;beforeSha256=$before;afterSha256=$hash})
    } else {
        $entry = [pscustomobject][ordered]@{source=$sourceRelative;destination=$destination;sha256=$hash;component=$component}
        $manifest.files += $entry
        $destinations[$destination] = $entry
        $changes.Add([ordered]@{destination=$destination;purpose=$label;beforeSha256=$null;afterSha256=$hash})
    }
}

# The current known-good deployment may already be a body-enabled quiet profile.
# Accept either canonical-disabled or already-body-enabled input, but make the
# generated result unambiguously body-enabled. Diagnostics must arrive closed so a
# prior diagnostic build cannot silently leak into an ordinary feel test.
$bodyDestination = 'r6/scripts/CyberpunkRealism/BodyRuntime.reds'
$bodyEntry = $destinations[$bodyDestination]
$bodySource = Resolve-SafeChildPath $project $bodyEntry.source
$bodyText = [IO.File]::ReadAllText($bodySource).Replace("`r`n","`n")
$bodyText = Set-PolicyOnce $bodyText 'CRBodyRuntimePolicy' 'Enabled' $true
$bodyText = Set-PolicyOnce $bodyText 'CRBodyTestPolicy' 'Diagnostics' ([bool]$Diagnostics) 'false'
Stage-Replacement $bodyDestination $bodyText ('body enabled; diagnostics=' + [bool]$Diagnostics)

# Combat is deliberately opened only in this generated profile. Require the base
# to still have combat closed; otherwise we would be accepting an unknown already-
# active combat build as the source of truth without an attended acceptance record.
$combatDestination = 'r6/scripts/CyberpunkRealism/CombatNativeBridge.reds'
$combatEntry = $destinations[$combatDestination]
$combatSource = Resolve-SafeChildPath $project $combatEntry.source
$combatText = [IO.File]::ReadAllText($combatSource).Replace("`r`n","`n")
$combatText = Set-PolicyOnce $combatText 'CRCombatRuntimePolicy' 'Enabled' $true 'false'
Stage-Replacement $combatDestination $combatText 'combat native bridge enabled for attended acceptance'

# Always compile the current project-owned policy model + settings surface into the
# attended candidate. Settings translate player intent into policy flags, but their
# acceptance booleans remain false; this source cannot open gameplay gates itself.
# Refresh here so an older known-good deployed base can test the new settings UI
# without requiring the player to rebuild that base by hand first.
$policyDestination = 'r6/scripts/CyberpunkRealism/RuntimePolicyModel.reds'
$settingsDestination = 'r6/scripts/CyberpunkRealism/RealpassSettings.reds'
Sync-ProjectSource 'src/redscript/CyberpunkRealism/RuntimePolicyModel.reds' $policyDestination 'realpass-core' 'refresh engine-independent accepted-and-intent policy model'
Sync-ProjectSource 'src/redscript/CyberpunkRealism/RealpassSettings.reds' $settingsDestination 'realpass-settings' 'refresh passive realpass-owned Mod Settings surface'

# Add the project-original no-healthbar presentation to the test candidate by
# default. It hides HP UI only; it does not change the damage/stat-pool simulation.
$healthbarDestination = 'r6/scripts/CyberpunkRealism/NoHealthbars.reds'
if (-not $ShowTraditionalHealthBars) {
    Sync-ProjectSource 'src/redscript/CyberpunkRealism/NoHealthbars.reds' $healthbarDestination 'realpass-presentation' 'traditional player/NPC/boss/companion actor health bars hidden'
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
    runtimePolicyModel = $policyDestination
    settingsSurface = $settingsDestination
    requiredRuntimeDestinations = @($requiredDestinations)
    changes = @($changes.ToArray())
    manifestPath = $outputRelative
    scope = 'Attended compile candidate only. Build does not deploy or launch Cyberpunk. Native combat feel, settings rendering, UI rendering, saves, quests, bosses and Phantom Liberty still require player-attended acceptance.'
}
Write-JsonFile $record $report
Write-Host "Staged and compiled attended candidate $BuildId: body=on, combat=on, healthBars=$([bool]$ShowTraditionalHealthBars), diagnostics=$([bool]$Diagnostics), settings=passive. No live deployment performed."
