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

# This builder starts from the repository's realpass source tree, never from the
# currently deployed mod stack. That distinction is the owned-runtime boundary.
$sourceRoot = Resolve-SafeChildPath $project 'src/redscript/CyberpunkRealism'
$sourceFiles = @(Get-ChildItem -LiteralPath $sourceRoot -File -Filter '*.reds' | Sort-Object Name)
if ($sourceFiles.Count -lt 20) { throw 'Unexpectedly small realpass source tree; refusing to construct an incomplete owned candidate.' }

# The old Codeware-backed backpack field-care popup is retained as prototype/source
# evidence while Condition mode is implemented, but it is not part of the owned
# acceptance runtime. Treatment models/action runtime are still included.
$excluded = @('FieldCareUI.reds')
$candidateFiles = @($sourceFiles | Where-Object { $_.Name -notin $excluded })

# Fail closed on source-mod/runtime-host imports. Generic frameworks may eventually
# be allowed by an explicit dependency contract, but the first owned acceptance
# candidate intentionally requires only the normal redscript loader at runtime.
$forbiddenRuntimePatterns = @(
    '(?m)^\s*(?:module|import)\s+DarkFuture(?:\.|\b)',
    '(?im)Project\s*E3',
    '(?m)^\s*import\s+Codeware(?:\.|\b)',
    '(?im)ModSettings|Mod Settings'
)
foreach ($file in $candidateFiles) {
    $text = Get-Content -Raw -LiteralPath $file.FullName
    foreach ($pattern in $forbiddenRuntimePatterns) {
        if ($text -match $pattern) { throw "Owned candidate source has forbidden runtime dependency: $($file.Name) / $pattern" }
    }
}

# Keep the repository source fail-closed. Open body/combat only in immutable staged
# copies that are compiled as this exact candidate.
$stageRelative = 'staging/owned-' + [guid]::NewGuid().ToString('N')
$stage = Resolve-SafeChildPath $project $stageRelative
New-Item -ItemType Directory -Force -Path $stage | Out-Null

function Set-PolicyOnce([string]$text,[string]$className,[string]$methodName,[bool]$desired,[string]$requiredCurrent='false') {
    $pattern = '(?s)(public class ' + [regex]::Escape($className) + ' extends IScriptable\s*\{.*?public static func ' + [regex]::Escape($methodName) + '\(\) -> Bool\s*\{\s*)return (?<value>true|false);'
    $matches = [regex]::Matches($text,$pattern)
    if ($matches.Count -ne 1) { throw "Expected exactly one policy gate: $className.$methodName" }
    $current = $matches[0].Groups['value'].Value
    if ($requiredCurrent -in @('true','false') -and $current -ne $requiredCurrent) {
        throw "Unexpected canonical policy for $className.$methodName: $current; required $requiredCurrent"
    }
    $desiredText = $desired.ToString().ToLowerInvariant()
    return [regex]::Replace($text,$pattern,('${1}return ' + $desiredText + ';'),1)
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
        $text = Set-PolicyOnce $text 'CRCombatRuntimePolicy' 'Enabled' $true 'false'
        $changed = $true
        $stagedGates.Add([ordered]@{policy='CRCombatRuntimePolicy.Enabled';value=$true})
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
if (@($entries | Where-Object destination -eq 'r6/scripts/CyberpunkRealism/FieldCareUI.reds').Count -gt 0) {
    throw 'Backpack field-care prototype leaked into owned candidate.'
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
    excludedPrototypeSources = @($excluded)
    genericRuntimeRequirement = 'redscript loader/toolchain already installed for development; final bundling/licensing remains a release task'
    stagedGates = @($stagedGates.ToArray())
    manifestPath = $outputRelative
    traditionalActorHealthBars = $false
    sourceModsRequired = @()
    scope = 'Owned attended compile candidate only. Contains project-original realpass REDscript, excludes Dark Future/Project E3 and the backpack Field Care prototype, does not deploy or launch Cyberpunk. Native UI/gameplay/save/quest acceptance is still required.'
}
Write-JsonFile $record $report
Write-Host "PASS: owned realpass candidate $BuildId compiled from $($entries.Count) project-original sources. No Dark Future/Project E3 runtime was inherited. Nothing was deployed or launched."
return $outputRelative
