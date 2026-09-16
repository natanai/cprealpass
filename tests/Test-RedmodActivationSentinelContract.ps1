$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'Test-RedmodActivationSentinelContract.ps1 requires PowerShell 7 or newer.' }
. "$PSScriptRoot\..\tools\Common.ps1"
$project = Get-ProjectRoot

function ReadText([string]$relative) {
    $path = Join-Path $project $relative
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Missing activation-sentinel contract asset: $relative" }
    Get-Content -Raw -LiteralPath $path
}

$marker = ReadText 'mods/Biology/tweaks/base/gameplay/static_data/database/items/weapons/parts/biology_activation.tweak'
$settings = ReadText 'src/redscript/CyberpunkRealism/RealpassSettings.reds'
$builder = ReadText 'tools/Build-BiologyPackage.ps1'
$evidence = ReadText 'docs/evidence/REDMOD-2.31-ACTIVATION-SENTINEL-2026-09-15.md'
$install = ReadText 'manifest/redmod-install-contract.json' | ConvertFrom-Json
$package = ReadText 'manifest/redmod-package.json' | ConvertFrom-Json

$packageMatch = [regex]::Match($marker,'(?m)^\s*package\s+Items\s*$')
$recordMatch = [regex]::Match($marker,'(?m)^\s*BiologyLauncherActivationMarker\s*:\s*IconicWeaponModAbilityBase\s*$')
if (-not $packageMatch.Success) { throw 'Activation sentinel must enter the native Items package before declaring the marker.' }
if (-not $recordMatch.Success) { throw 'Activation sentinel must declare the marker/base unqualified inside package Items.' }
if ($packageMatch.Index -gt $recordMatch.Index) { throw 'Items package declaration must precede the activation record declaration.' }
if ($marker -match '(?m)^\s*using\s+Items\s*$') { throw 'Activation sentinel regressed to the attended-rejected standalone using Items form.' }
if ($marker -match '(?m)^\s*Items\.BiologyLauncherActivationMarker\s*:') { throw 'Activation sentinel must not invent a qualified declaration inside package Items.' }
if ($marker -notmatch '(?m)^\s*stackable\s*=\s*true\s*;\s*$') { throw 'Activation sentinel no longer sets the inherited native stackable Boolean true.' }
if ($marker -match '(?ms)^\s*BiologyLauncherActivationMarker\s*\{.*?\bbool\b') { throw 'Activation sentinel regressed to an unevidenced unbased custom-Boolean group.' }
if ($marker -match '(?i)TweakXL|ArchiveXL|Codeware') { throw 'Activation authority must remain official REDmod/TweakDB owned.' }

if ($settings -notmatch 'TweakDBInterface\.GetBool\(t"Items\.BiologyLauncherActivationMarker\.stackable",\s*false\)') {
    throw 'REDscript launcher accessor no longer reads the exact marker with a false missing-value default.'
}
if ($settings -notmatch 'public static func IsEnabled\(game: GameInstance\) -> Bool\s*\{\s*return CRRealpassSettings\.IsLauncherActivated\(\);') {
    throw 'REDlauncher/REDmod is no longer the sole Biology whole-mod activation authority.'
}
if ($settings -match '(?m)public\s+(?:persistent\s+)?let\s+enabled\s*:\s*Bool') {
    throw 'A saved in-game master preference has re-entered the activation boundary.'
}
if ($settings -notmatch 'UseE3FirstPersonHudVisuals[\s\S]*CRRealpassSettings\.IsEnabled\(game\)[\s\S]*e3FirstPersonHudVisuals') {
    throw 'The save-backed E3 presentation preference is no longer subordinate to launcher activation.'
}

$signal = 'Items.BiologyLauncherActivationMarker.stackable'
if ($install.launcherActivation.signal -ne $signal) { throw 'Install contract and activation sentinel read path disagree.' }
if ($install.launcherActivation.publicMasterPreference -ne $false) { throw 'Install contract reintroduced an in-game whole-mod preference.' }
if ($package.redmod.launcherActivationMarker -ne $signal) { throw 'Package contract and activation sentinel read path disagree.' }
if ($builder -notmatch [regex]::Escape('mods/Biology/tweaks/base/gameplay/static_data/database/items/weapons/parts/biology_activation.tweak')) {
    throw 'Canonical player builder stopped packaging the REDmod activation source.'
}
foreach ($requiredBuilderText in @('activationPackage','activationRecord','package\s+Items','BiologyLauncherActivationMarker','IconicWeaponModAbilityBase','using\s+Items','stackable')) {
    if (-not $builder.Contains($requiredBuilderText)) { throw "Canonical player builder lost standalone-tweak structural validation token: $requiredBuilderText" }
}

foreach ($required in @('2684','mods_abilities.tweak','package Items','first package/import directive','Items.IconicWeaponModAbilityBase','GetBool(path, defaultValue)','parent P01.1')) {
    if ($evidence -notmatch [regex]::Escape($required)) { throw "Activation-sentinel evidence record lost required finding/boundary: $required" }
}
if ($evidence -notmatch '(?i)does not.*prove|cannot.*emulate|pending.*parent|still.*parent') {
    throw 'Activation-sentinel evidence must not overclaim native REDmod compile/deploy acceptance.'
}

Write-Host 'PASS: activation sentinel mirrors shipped Items package grammar, remains the sole whole-mod activation authority, keeps the E3 preference subordinate, and leaves official REDmod live acceptance parent-owned.'
