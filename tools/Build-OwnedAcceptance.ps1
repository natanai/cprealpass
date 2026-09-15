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
$report = Resolve-SafeChildPath $project ('reports/owned-acceptance-' + $BuildId + '.json')
if ((Test-Path -LiteralPath $output) -or (Test-Path -LiteralPath $report)) {
    throw 'Build ID already exists; owned acceptance profiles are immutable. Use a new BuildId.'
}

$actualVersion = (Get-Item -LiteralPath (Join-Path $game 'bin\x64\Cyberpunk2077.exe')).VersionInfo.ProductVersion
if ($actualVersion -ne '2.31') {
    throw "This owned candidate is calibrated/declared for Cyberpunk 2077 2.31; installed game reports $actualVersion. Update native acceptance before building."
}

# This builder starts from the repository's RealPass source tree, never from the
# currently deployed mod stack. That distinction is the owned-runtime boundary.
$sourceRoot = Resolve-SafeChildPath $project 'src/redscript/CyberpunkRealism'
$sourceFiles = @(Get-ChildItem -LiteralPath $sourceRoot -File -Filter '*.reds' | Sort-Object Name)
if ($sourceFiles.Count -lt 20) { throw 'Unexpectedly small RealPass source tree; refusing to construct an incomplete owned candidate.' }

# These files belonged to superseded source-mod-integrated/prototype paths. They are
# intentionally retired from production source rather than silently excluded at build
# time. Git history remains the reference if their old behavior needs to be studied.
$retiredProductionSources = @('FieldCareUI.reds','RealpassLocalization.reds','FieldCareItemUse.reds')
$presentRetired = @($sourceFiles | Where-Object { $_.Name -in $retiredProductionSources })
if ($presentRetired.Count -gt 0) {
    throw "Retired legacy/prototype production source reappeared: $(@($presentRetired.Name) -join ', ')"
}
$candidateFiles = @($sourceFiles)

# Fail closed on source-mod/runtime-host imports and source-mod nomenclature that
# would silently rebrand vanilla gameplay items. Mod Settings metadata plus guarded
# RegisterListenerToClass/UnregisterListenerToClass lifecycle calls are allowed as
# generic UI/persistence plumbing. RealPass may not query or drive Mod Settings as a
# gameplay/simulation policy owner beyond reading the global RealPass master state.
$forbiddenOwnedPatterns = @(
    '(?m)^\s*(?:module|import)\s+DarkFuture(?:\.|\b)',
    '(?im)Project\s*E3',
    '(?m)^\s*import\s+Codeware(?:\.|\b)',
    '(?m)^\s*import\s+ModSettings(?:\.|\b)',
    '(?m)(?<!["''])\bModSettings\.(?:GetInstance|GetMods|GetCategories|GetVars|AcceptChanges|RejectChanges|RestoreDefaults)\b',
    '(?i)\bTrauma\s+Kit\b|UseTraumaKit'
)
foreach ($file in $candidateFiles) {
    $text = Get-Content -Raw -LiteralPath $file.FullName
    foreach ($pattern in $forbiddenOwnedPatterns) {
        if ($text -match $pattern) { throw "Owned candidate source has forbidden dependency or source-mod identity: $($file.Name) / $pattern" }
    }
}

# Keep the repository source fail-closed. Open body/combat only in immutable staged
# copies that are compiled as this exact candidate.
$stageRelative = 'staging/owned-' + [guid]::NewGuid().ToString('N')
$stage = Resolve-SafeChildPath $project $stageRelative
New-Item -ItemType Directory -Force -Path $stage | Out-Null

function Set-PolicyOnce([string]$text,[string]$className,[string]$methodName,[bool]$desired,[string]$requiredCurrent='false') {
    $pattern = '(?s)(public class ' + [regex]::Escape($className) + ' extends IScriptable\s*\{.*?public static func ' + [regex]::Escape($methodName) + '\(\) -> Bool\s*\{\s*)return (?<value>true|false);'
    $regex = [regex]::new($pattern)
    $matches = $regex.Matches($text)
    if ($matches.Count -ne 1) { throw "Expected exactly one policy gate: $className.$methodName" }
    $current = $matches[0].Groups['value'].Value
    if ($requiredCurrent -in @('true','false') -and $current -ne $requiredCurrent) {
        throw "Unexpected canonical policy for $className.$($methodName): $current; required $requiredCurrent"
    }
    $desiredText = $desired.ToString().ToLowerInvariant()
    return $regex.Replace($text,('${1}return ' + $desiredText + ';'),1)
}

$entries = [Collections.Generic.List[object]]::new()
$stagedGates = [Collections.Generic.List[object]]::new()
foreach ($file in $candidateFiles) {
    $relative = 'src/redscript/CyberpunkRealism/' + $file.Name
    $sourceRelative = $relative
    $text = Get-Content -Raw -LiteralPath $file.FullName
    $changed = $false

    if ($file.Name -eq 'BodyRuntime.reds') {
        $text = Set-PolicyOnce $text 'CRBodyRuntimePolicy' 'Enabled' $true 'false'
        $text = Set-PolicyOnce $text 'CRBodyTestPolicy' 'Diagnostics' ([bool]$Diagnostics) 'false'
        $changed = $true
        $stagedGates.Add([ordered]@{policy='CRBodyRuntimePolicy.Enabled';value=$true})
        $stagedGates.Add([ordered]@{policy='CRBodyTestPolicy.Diagnostics';value=[bool]$Diagnostics})
    }
    if ($file.Name -eq 'CombatNativeBridge.reds') {
        $text = Set-PolicyOnce $text 'CRCombatRuntimePolicy' 'BuildEnabled' $true 'false'
        $changed = $true
        $stagedGates.Add([ordered]@{policy='CRCombatRuntimePolicy.BuildEnabled';value=$true})
    }

    if ($changed) {
        $sourceRelative = $stageRelative + '/' + $file.Name
        $stagedPath = Resolve-SafeChildPath $project $sourceRelative
        [IO.File]::WriteAllText($stagedPath,$text,[Text.UTF8Encoding]::new($false))
    }
    $sourcePath = Resolve-SafeChildPath $project $sourceRelative
    $entries.Add([pscustomobject][ordered]@{
        source = $sourceRelative
        destination = 'r6/scripts/CyberpunkRealism/' + $file.Name
        sha256 = Get-Sha256 $sourcePath
        component = 'realpass-owned-runtime'
        origin = 'project-original'
    })
}

if (@($entries | Where-Object { $_.destination -match '(?i)(dark[ _-]?future|project[ _-]?e3)' }).Count -gt 0) {
    throw 'Owned candidate generated a forbidden source-mod destination.'
}
if (@($entries | Where-Object { [IO.Path]::GetFileName([string]$_.destination) -in $retiredProductionSources }).Count -gt 0) {
    throw 'Retired legacy/prototype source leaked into the owned candidate.'
}

$manifest = [ordered]@{
    schemaVersion = 1
    buildId = $BuildId
    gameVersion = $actualVersion
    ownedRuntime = $true
    profile = 'owned-attended-acceptance'
    files = @($entries.ToArray())
}
Write-JsonFile $manifest $output

# Re-run the repository-level origin contract immediately before exact compilation.
& (Join-Path $project 'tests\Test-RuntimeOriginPolicy.ps1')
if ($LASTEXITCODE -ne 0) { throw 'Runtime-origin policy failed; owned candidate not compiled.' }

& "$PSScriptRoot\Compile-Profile.ps1" -ManifestPath $outputRelative -GameRoot $game
if ($LASTEXITCODE -ne 0) { throw 'Owned candidate exact compilation failed.' }

$record = [ordered]@{
    schemaVersion = 1
    buildId = $BuildId
    generatedAtUtc = [DateTime]::UtcNow.ToString('o')
    gameVersion = $actualVersion
    ownedRuntime = $true
    sourceCount = $entries.Count
    retiredProductionSources = @($retiredProductionSources)
    genericRuntimeRequirement = 'Generic loader/toolchain/settings requirements are audited separately before deployment; this source candidate inherits no gameplay or presentation mod runtime.'
    stagedGates = @($stagedGates.ToArray())
    manifestPath = $outputRelative
    traditionalActorHealthBarsFinalTarget = $false
    developmentHealthbarFallbackUntilReplacementAccepted = $false
    sourceModsRequired = @()
    vanillaIdentityPolicy = 'Preserve vanilla item/system identity; source-mod renames are forbidden in the owned candidate.'
    scope = 'Owned attended compile candidate only. Contains the complete current project-original RealPass REDscript tree; retired source-mod bridge/prototype files are absent; does not deploy or launch Cyberpunk. Native UI/gameplay/save/quest acceptance is still required.'
}
Write-JsonFile $record $report
Write-Host "PASS: owned RealPass candidate $BuildId compiled from $($entries.Count) project-original sources. No Dark Future/Project E3 runtime, retired prototype source, or source-mod item renames were inherited. Nothing was deployed or launched."
return $outputRelative