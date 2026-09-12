param(
    [Parameter(Mandatory=$true)][ValidatePattern('^[a-zA-Z0-9][a-zA-Z0-9._-]*$')][string]$BuildId,
    [Parameter(Mandatory=$true)][string]$ManifestPath,
    [string]$ConfigPath = 'config/realpass-e3.json'
)
. "$PSScriptRoot/Common.ps1"
$project = Get-ProjectRoot
$outputRelative = 'manifest/' + $BuildId + '.deployment.json'
$output = Resolve-SafeChildPath $project $outputRelative
$reportRelative = 'reports/presentation-' + $BuildId + '.json'
$reportPath = Resolve-SafeChildPath $project $reportRelative
if ((Test-Path -LiteralPath $output) -or (Test-Path -LiteralPath $reportPath)) { throw 'Build ID already exists; use a new immutable ID.' }
$basePath = Resolve-SafeChildPath $project $ManifestPath
$configFull = Resolve-SafeChildPath $project $ConfigPath
$baseHash = Get-Sha256 $basePath
$configHash = Get-Sha256 $configFull
$manifest = Get-Content -Raw -LiteralPath $basePath | ConvertFrom-Json
$config = Get-Content -Raw -LiteralPath $configFull | ConvertFrom-Json
if ($manifest.schemaVersion -ne 1 -or $config.schemaVersion -ne 1 -or $config.id -ne 'realpass-e3-minimal-v1') { throw 'Unsupported manifest or E3 preset schema.' }
if ($config.distribution -ne 'local-integration-only' -or @($config.files).Count -ne 36) { throw 'Expected the pinned local-only E3 reference payload.' }
$reference = Resolve-SafeChildPath $project $config.referenceRoot
$destinations = @{}
foreach ($file in $manifest.files) {
    $resolvedDestination = Resolve-SafeChildPath $project $file.destination
    if ($destinations.ContainsKey($resolvedDestination)) { throw 'Duplicate base destination.' }
    $destinations[$resolvedDestination] = $true
    $source = Resolve-SafeChildPath $project $file.source
    if ($file.sha256 -notmatch '^[A-Fa-f0-9]{64}$' -or (Get-Sha256 $source) -ne $file.sha256) { throw "Base payload hash mismatch: $($file.destination)" }
}
$expected = @{}
foreach ($file in $config.files) {
    $source = Resolve-SafeChildPath $reference $file.path
    $destination = Resolve-SafeChildPath $project $file.path
    if ($expected.ContainsKey($source) -or $destinations.ContainsKey($destination)) { throw 'Duplicate or colliding E3 payload path.' }
    if ([IO.Path]::GetExtension($source) -notin @('.reds','.yaml','.archive')) { throw 'Unexpected E3 payload type.' }
    $expected[$source] = $true
    $destinations[$destination] = $true
    if ($file.sha256 -notmatch '^[A-Fa-f0-9]{64}$' -or (Get-Sha256 $source) -ne $file.sha256 -or (Get-Item -Force -LiteralPath $source).Length -ne $file.bytes) { throw "E3 reference hash/length mismatch: $($file.path)" }
}
$exclusions = @{}
foreach ($path in $config.excludedPaths) {
    if ([IO.Path]::GetFileName($path) -ne 'desktop.ini') { throw 'Only desktop.ini metadata may be excluded.' }
    $exclusions[(Resolve-SafeChildPath $reference $path)] = $true
}
foreach ($file in Get-ChildItem -LiteralPath $reference -Recurse -File -Force) {
    $relative = [IO.Path]::GetRelativePath($reference,$file.FullName)
    $safe = Resolve-SafeChildPath $reference $relative
    if (-not $expected.ContainsKey($safe) -and -not $exclusions.ContainsKey($safe)) { throw "Unindexed E3 reference file: $relative" }
}
function Replace-Exact([string]$Content,[string]$Find,[string]$Replacement,[int]$Count=1) {
    if ([regex]::Matches($Content,[regex]::Escape($Find)).Count -ne $Count) { throw "E3 adaptation match differs: $Find" }
    return $Content.Replace($Find,$Replacement)
}
function Replace-OnePattern([string]$Content,[string]$Pattern,[string]$Replacement) {
    $regex = [regex]::new($Pattern)
    if ($regex.Matches($Content).Count -ne 1) { throw "E3 adaptation pattern differs: $Pattern" }
    return $regex.Replace($Content,[System.Text.RegularExpressions.MatchEvaluator]{param($match) $Replacement})
}
$nl = [string][char]10
$stage = 'staging/realpass-presentation-' + [guid]::NewGuid().ToString('N')
$notice = '// realpass local presentation adaptation. Original Project E3 - HUD by Virtuoso75.' + $nl + '// https://www.nexusmods.com/cyberpunk2077/mods/8800 ; published changes require the original mod.' + $nl
$prepared = @()
$settingsPath = 'r6/scripts/Project E3 - HUD/core/ModSettings.reds'
$nameplatePath = 'r6/scripts/Project E3 - HUD/cyberpunk/widgets/healthbar/npcNamePlate.reds'
$visualPath = 'r6/scripts/Project E3 - HUD/cyberpunk/widgets/healthbar/nameplateVisuals.reds'
foreach ($file in $config.files) {
    $source = Resolve-SafeChildPath $reference $file.path
    $content = $null
    $reason = 'Original E3 reference bytes; local dependency only.'
    if ($file.path -eq $settingsPath) {
        $content = [IO.File]::ReadAllText($source).Replace([string][char]13,'')
        $content = Replace-Exact $content '"ModSettings.mod", "Project E3: HUD"' '"ModSettings.mod", "realpass (E3 HUD)"' 16
        foreach ($setting in $config.settings.PSObject.Properties) {
            $pattern = '(?m)(?<prefix>^\s*let ' + [regex]::Escape($setting.Name) + ': (?:Bool|Float|Int32) = )[^;]+;'
            $value = if ($setting.Value -is [bool]) { $setting.Value.ToString().ToLowerInvariant() } else { ([IFormattable]$setting.Value).ToString($null,[Globalization.CultureInfo]::InvariantCulture) }
            if ($setting.Name -in @('NameplateDisplayRange','NameplateDisplayRangeNotAggressive')) { $value = ([double]$setting.Value).ToString('0.0',[Globalization.CultureInfo]::InvariantCulture) }
            $regex = [regex]::new($pattern)
            if ($regex.Matches($content).Count -ne 1) { throw "Missing E3 setting: $($setting.Name)" }
            $replacementValue = $value
            $content = $regex.Replace($content,[System.Text.RegularExpressions.MatchEvaluator]{param($match) $match.Groups['prefix'].Value + $replacementValue + ';'})
        }
        $reason = 'realpass settings group and minimalist defaults; internal class/property names retained.'
    } elseif ($file.path -in @('r6/tweaks/Project E3 - HUD/ui/npc/schema.yaml','r6/tweaks/Project E3 - HUD/ui/npc/nameplate.yaml')) {
        $content = '# realpass: preserve native authored UINameplate records, Disabled/Never/AfterScan policies and positions.' + $nl + '# Original E3 reference by Virtuoso75; blanket Always/Enabled overrides intentionally omitted.' + $nl
        $reason = 'Preserve native nameplate records and authored scan/disabled policies.'
    } elseif ($file.path -eq $nameplatePath) {
        $content = [IO.File]::ReadAllText($source).Replace([string][char]13,'')
        $content = Replace-OnePattern $content '(?s)\n@wrapMethod\(NpcNameplateGameController\).*\z' ($nl + '// Native projection visibility retains disabled, after-scan, scene and HideNameplate gates.' + $nl)
        $reason = 'Retain E3 range configuration; remove force-visible name override.'
    } elseif ($file.path -eq $visualPath) {
        $content = [IO.File]::ReadAllText($source).Replace([string][char]13,'')
        $pattern = '(?s)public func GetCustomNPCName\(puppet: wref<gamePuppetBase>, data: NPCNextToTheCrosshair\) -> String \{.*?\n\}\n\n@replaceMethod'
        $replacement = 'public func GetCustomNPCName(puppet: wref<gamePuppetBase>, data: NPCNextToTheCrosshair) -> String {' + $nl + '    // Use the name supplied by native focus data; do not discover hidden names from records.' + $nl + '    return data.name;' + $nl + '}' + $nl + $nl + '@replaceMethod'
        $content = Replace-OnePattern $content $pattern $replacement
        $reason = 'Keep E3 visual treatment but use only native-provided names.'
    }
    if ($null -ne $content -and $file.path.EndsWith('.reds')) { $content = $notice + $content }
    $prepared += [pscustomobject]@{destination=$file.path;source=$source;before=$file.sha256;content=$content;component='project-e3-hud-local';reason=$reason;entry=$null}
}
# E3 compatibility is a property of this complete profile, independent of a previously saved false toggle.
$dfDestination = 'r6/scripts/Dark Future/Settings/DFSettings.reds'
$dfMatches = @($manifest.files | Where-Object destination -eq $dfDestination)
if ($dfMatches.Count -ne 1 -or $dfMatches[0].component -ne 'darkfuture') { throw 'Expected one Dark Future settings source in the base profile.' }
$df = $dfMatches[0]
$dfSource = Resolve-SafeChildPath $project $df.source
$dfText = [IO.File]::ReadAllText($dfSource).Replace([string][char]13,'')
$dfText = Replace-Exact $dfText 'public let compatibilityProjectE3HUD: Bool = false;' 'public let compatibilityProjectE3HUD: Bool = true;'
$policy = 'this.compatibilityProjectE3HUD = true;' + $nl + '        this.compatibilityProjectE3UI = false;'
$dfText = Replace-Exact $dfText 'public final func ReconcileSettings() -> Void {' ('public final func ReconcileSettings() -> Void {' + $nl + '        ' + $policy)
$dfText = Replace-Exact $dfText 'RegisterDFSettingsListener(this);' ('RegisterDFSettingsListener(this);' + $nl + '        ' + $policy)
$dfText = Replace-Exact $dfText 'return instance;' ('if IsDefined(instance) {' + $nl + '            instance.compatibilityProjectE3HUD = true;' + $nl + '            instance.compatibilityProjectE3UI = false;' + $nl + '        }' + $nl + '        return instance;')
$dfNotice = '// realpass E3-containing profile: derive compatibility from installed components at access/init/reconcile.' + $nl + '// Original DarkFortuneTeller/DarkFuture 2.0-release, CC BY-SA 4.0; existing notices retained.' + $nl
$prepared += [pscustomobject]@{destination=$dfDestination;source=$dfSource;before=$df.sha256;content=($dfNotice+$dfText);component='darkfuture';reason='E3 HUD compatibility on, separate E3 UI off; source/runtime only, no persisted settings edits.';entry=$df}
# Guard the optional humanity caption against the E3 widget hierarchy.
$dialogueRecipeRelative = 'config/patches/darkfuture-e3-dialogue.json'
$dialogueRecipePath = Resolve-SafeChildPath $project $dialogueRecipeRelative
$dialogueRecipeHash = Get-Sha256 $dialogueRecipePath
$dialogueRecipe = Get-Content -Raw $dialogueRecipePath | ConvertFrom-Json
if ($dialogueRecipe.schemaVersion -ne 1 -or $dialogueRecipe.component -ne 'darkfuture' -or @($dialogueRecipe.patches).Count -ne 1) { throw 'Unexpected E3 dialogue adaptation recipe.' }
$dialogueChange = $dialogueRecipe.patches[0]
$dialogueMatches = @($manifest.files | Where-Object destination -eq $dialogueChange.destination)
if ($dialogueMatches.Count -ne 1 -or $dialogueMatches[0].component -ne 'darkfuture' -or $dialogueMatches[0].sha256 -ne $dialogueChange.expectedSha256) { throw 'E3 dialogue adaptation requires the pinned Dark Future source.' }
$dialogueEntry = $dialogueMatches[0]
$dialogueSource = Resolve-SafeChildPath $project $dialogueEntry.source
$dialogueText = [IO.File]::ReadAllText($dialogueSource)
foreach ($edit in $dialogueChange.edits) {
    $dialogueText = Replace-Exact $dialogueText $edit.find $edit.replace $edit.expectedOccurrences
}
$dialogueNotice = '// realpass: guard optional humanity caption widgets for the E3 hierarchy.' + $nl + '// Original DarkFortuneTeller/DarkFuture 2.0-release, CC BY-SA 4.0; existing notices retained.' + $nl
$prepared += [pscustomobject]@{destination=$dialogueEntry.destination;source=$dialogueSource;before=$dialogueEntry.sha256;content=($dialogueNotice+$dialogueText);component='darkfuture';reason='Guard optional caption insertion/cleanup and ancestor layout checks; preserve choice and humanity behavior.';entry=$dialogueEntry}
$changes = @()
foreach ($item in $prepared) {
    $relative = $stage + '/' + $item.destination
    $target = Resolve-SafeChildPath $project $relative
    if ((Get-Sha256 $item.source) -ne $item.before) { throw 'Reference changed during preparation.' }
    if ($null -eq $item.content) { Copy-VerifiedPayload $item.source $target $item.before } else {
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $target) | Out-Null
        [IO.File]::WriteAllText($target,$item.content,[Text.UTF8Encoding]::new($false))
    }
    $hash = Get-Sha256 $target
    if ($null -eq $item.entry) { $manifest.files += [pscustomobject]@{source=$relative;destination=$item.destination;component=$item.component;sha256=$hash} } else { $item.entry.source=$relative; $item.entry.sha256=$hash }
    $changes += [ordered]@{destination=$item.destination;originalSha256=$item.before;stagedSha256=$hash;changed=($hash -ne $item.before);reason=$item.reason}
}
if ((Get-Sha256 $basePath) -ne $baseHash -or (Get-Sha256 $configFull) -ne $configHash) { throw 'Build inputs changed during staging.' }
$manifest.buildId = $BuildId
$manifest | Add-Member -Force NoteProperty realpassE3 ([ordered]@{preset=$config.id;distribution='local-integration-only';includesRestrictedThirdPartyAssets=$true;originalDependency=$config.sourceUrl;author=$config.author;provenance=$reportRelative})
$report = [ordered]@{buildId=$BuildId;builtAtUtc=[DateTime]::UtcNow.ToString('o');baseManifest=$ManifestPath;baseManifestSha256=$baseHash;preset=$ConfigPath;presetSha256=$configHash;dialogueRecipe=$dialogueRecipeRelative;dialogueRecipeSha256=$dialogueRecipeHash;sourceVersion=$config.sourceVersion;sourceUrl=$config.sourceUrl;author=$config.author;permission=$config.permission;distribution='local-integration-only';referenceRoot=$config.referenceRoot;referenceFiles=36;scriptFilesAdded=22;files=$changes;compiled=$false;installed=$false;nativeVisibilityVerified=$false;persistedSettingsFilesChanged=$false}
Write-JsonFile $report $reportPath
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $output) | Out-Null
$bytes = [Text.UTF8Encoding]::new($false).GetBytes(($manifest | ConvertTo-Json -Depth 20) + $nl)
$stream = [IO.File]::Open($output,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
try { $stream.Write($bytes,0,$bytes.Length) } finally { $stream.Dispose() }
Write-Host "Staged $BuildId with 36 local-only E3 files, source-derived compatibility and guarded dialogue captions. No compilation or live deployment performed."
