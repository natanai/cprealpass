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

# The attended failure escaped earlier CI because the marker declaration looked
# plausible lexically while its native base was invisible from a standalone
# global tweak file. Importing Items is now part of the source contract.
$usingMatch = [regex]::Match($marker,'(?m)^\s*using\s+Items\s*$')
$recordMatch = [regex]::Match($marker,'(?m)^\s*Items\.BiologyLauncherActivationMarker\s*:\s*IconicWeaponModAbilityBase\s*$')
if (-not $usingMatch.Success) { throw 'Activation sentinel must import the native Items package before resolving IconicWeaponModAbilityBase.' }
if (-not $recordMatch.Success) { throw 'Activation sentinel record/base identity drifted.' }
if ($usingMatch.Index -gt $recordMatch.Index) { throw 'Items package import must precede the standalone activation record declaration.' }
if ($marker -notmatch '(?m)^\s*stackable\s*=\s*true\s*;\s*$') { throw 'Activation sentinel no longer sets the inherited native stackable Boolean true.' }

# Do not replace the supported native base with an unevidenced custom unbased
# schema. The direct 2.31 probe found no shipped examples for that shape.
if ($marker -match '(?ms)^\s*Items\.BiologyLauncherActivationMarker\s*\{.*?\bbool\b') {
    throw 'Activation sentinel regressed to an unevidenced unbased custom-Boolean group.'
}
if ($marker -match '(?i)TweakXL|ArchiveXL|Codeware') { throw 'Activation authority must remain official REDmod/TweakDB owned.' }

# REDlauncher OFF must remain fail-closed even though supplemental REDscript can
# still load. Use the shipped GetBool(path, defaultValue) form with false default.
if ($settings -notmatch 'TweakDBInterface\.GetBool\(t"Items\.BiologyLauncherActivationMarker\.stackable",\s*false\)') {
    throw 'REDscript launcher accessor no longer reads the exact marker with a false missing-value default.'
}
if ($settings -notmatch 'if !CRRealpassSettings\.IsLauncherActivated\(\)\s*\{\s*return false;') {
    throw 'Launcher authority is no longer checked before the saved Biology preference.'
}

$signal = 'Items.BiologyLauncherActivationMarker.stackable'
if ($install.launcherActivation.signal -ne $signal) { throw 'Install contract and activation sentinel read path disagree.' }
if ($package.redmod.launcherActivationMarker -ne $signal) { throw 'Package contract and activation sentinel read path disagree.' }
if ($builder -notmatch [regex]::Escape('mods/Biology/tweaks/base/gameplay/static_data/database/items/weapons/parts/biology_activation.tweak')) {
    throw 'Canonical player builder stopped packaging the REDmod activation source.'
}
if ($builder -notmatch 'Items\\\.BiologyLauncherActivationMarker.*IconicWeaponModAbilityBase' -or $builder -notmatch 'stackable.*true') {
    throw 'Canonical player builder stopped validating the activation record/read-path identity.'
}

foreach ($required in @(
    '2684',
    'IconicWeaponModAbilityBase',
    'no shipped examples',
    'GetBool(path, defaultValue)',
    'parent P01.1 attended gate'
)) {
    if ($evidence -notmatch [regex]::Escape($required)) { throw "Activation-sentinel evidence record lost required finding/boundary: $required" }
}
if ($evidence -notmatch '(?i)does not.*prove|cannot.*emulate|still.*parent') {
    throw 'Activation-sentinel evidence must not overclaim native REDmod compile/deploy acceptance.'
}

Write-Host 'PASS: W07.1 activation sentinel imports the native Items package, preserves the inert fail-closed read path, rejects the unsupported bare-global shape, and keeps native compile/deploy parent-owned.'
