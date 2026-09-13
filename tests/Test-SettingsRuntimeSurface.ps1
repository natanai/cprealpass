$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\tools\Common.ps1"
$project = Get-ProjectRoot
$sourcePath = Join-Path $project 'src/redscript/CyberpunkRealism/RealpassSettings.reds'
$contractPath = Join-Path $project 'manifest/settings.json'
$policyPath = Join-Path $project 'src/redscript/CyberpunkRealism/RuntimePolicyModel.reds'
$source = Get-Content -Raw -LiteralPath $sourcePath
$contract = Get-Content -Raw -LiteralPath $contractPath | ConvertFrom-Json
$policy = Get-Content -Raw -LiteralPath $policyPath
$script:checks = 0
function Check($condition,[string]$message) { if (-not $condition) { throw $message }; $script:checks++ }
function Has-Property($object,[string]$name) { return $null -ne $object.PSObject.Properties[$name] }

Check ($source.Contains('public class CRRealpassSettings extends ScriptableSystem')) 'realpass settings are not owned by one ScriptableSystem.'
Check ($source.Contains('ModSettings.RegisterListenerToClass(this);')) 'Settings system does not register for Mod Settings value updates.'
Check ($source.Contains('ModSettings.UnregisterListenerToClass(this);')) 'Settings system does not unregister cleanly.'
Check (-not $source.Contains('RegisterListenerToModifications')) 'Passive settings surface should not dispatch runtime effects yet.'
Check ($source.Contains('public static func Get() -> ref<CRRealpassSettings>')) 'Settings system lacks a stable accessor.'
Check ($source.Contains('public func IntentSnapshot() -> ref<CRRuntimeFeatureFlags>')) 'Settings system does not map player intent into the central policy model.'

# Player intent must remain passive until a separately accepted runtime-policy
# facade is introduced. Merely opening the settings menu may not activate systems.
foreach ($forbidden in @(
    'CRBodyRuntimePolicy',
    'CRCombatRuntimePolicy',
    'CRBodyRuntime.Get()',
    'CRInjuryEffectsRuntime.Get()',
    'CRFieldCareActionRuntime.Get()',
    'ApplyDamage',
    'SetStatPoolValue',
    'QueueHitEvent',
    'Start-Process',
    'Register-ScheduledTask'
)) {
    Check (-not $source.Contains($forbidden)) "Passive settings surface gained side-effect authority: $forbidden"
}
foreach ($acceptedField in @('bodyAccepted','injuryAccepted','combatAccepted','armorAccepted','cyberwarePhysiologyAccepted','presentationAccepted','diagnosticsAccepted')) {
    Check (-not $source.Contains('flags.' + $acceptedField + ' =')) "Player settings can assign an acceptance gate: $acceptedField"
    Check ($policy -match ('public let ' + $acceptedField + ': Bool = false;')) "Central policy acceptance default is no longer closed: $acceptedField"
}

$fieldMap = [ordered]@{
    'body.enabled' = 'bodyEnabled'
    'body.nutrition' = 'bodyNutrition'
    'body.hydration' = 'bodyHydration'
    'body.sleep' = 'bodySleep'
    'body.exertion' = 'bodyExertion'
    'body.elimination' = 'bodyElimination'
    'body.hygiene' = 'bodyHygiene'
    'injury.enabled' = 'injuryEnabled'
    'injury.bloodLoss' = 'injuryBloodLoss'
    'injury.impairment' = 'injuryImpairment'
    'injury.fieldCare' = 'injuryFieldCare'
    'injury.recovery' = 'injuryRecovery'
    'combat.enabled' = 'combatEnabled'
    'armor.enabled' = 'armorEnabled'
    'armor.wear' = 'armorWear'
    'cyberwarePhysiology.enabled' = 'cyberwarePhysiologyEnabled'
    'presentation.enabled' = 'presentationEnabled'
    'presentation.nameplates' = 'presentationNameplates'
    'presentation.statusCues' = 'presentationStatusCues'
    'presentation.traditionalHealthBars' = 'presentationTraditionalHealthBars'
    'diagnostics.enabled' = 'diagnosticsEnabled'
}
$flagMap = [ordered]@{
    'body.enabled' = 'bodyEnabled'
    'body.nutrition' = 'nutritionEnabled'
    'body.hydration' = 'hydrationEnabled'
    'body.sleep' = 'sleepEnabled'
    'body.exertion' = 'exertionEnabled'
    'body.elimination' = 'eliminationEnabled'
    'body.hygiene' = 'hygieneEnabled'
    'injury.enabled' = 'injuryEnabled'
    'injury.bloodLoss' = 'bloodLossEnabled'
    'injury.impairment' = 'impairmentEnabled'
    'injury.fieldCare' = 'fieldCareEnabled'
    'injury.recovery' = 'injuryRecoveryEnabled'
    'combat.enabled' = 'combatEnabled'
    'armor.enabled' = 'armorEnabled'
    'armor.wear' = 'armorWearEnabled'
    'cyberwarePhysiology.enabled' = 'cyberwarePhysiologyEnabled'
    'presentation.enabled' = 'presentationEnabled'
    'presentation.nameplates' = 'nameplatesEnabled'
    'presentation.statusCues' = 'statusCuesEnabled'
    'presentation.traditionalHealthBars' = 'traditionalHealthBarsEnabled'
    'diagnostics.enabled' = 'diagnosticsEnabled'
}

$settings = @{}
foreach ($category in @($contract.categories)) {
    foreach ($setting in @($category.settings)) { $settings[$setting.key] = [pscustomobject]@{category=$category;setting=$setting} }
}
Check ($settings.Count -eq $fieldMap.Count) 'Runtime field map no longer covers every settings-contract key.'
Check ($settings.Count -eq $flagMap.Count) 'Policy flag map no longer covers every settings-contract key.'
foreach ($key in $fieldMap.Keys) {
    Check ($settings.ContainsKey($key)) "Runtime field map references unknown contract key: $key"
    $field = $fieldMap[$key]
    $flag = $flagMap[$key]
    $default = if ($settings[$key].setting.default) { 'true' } else { 'false' }
    Check ($source -match ('public let ' + [regex]::Escape($field) + ': Bool = ' + $default + ';')) "Runtime setting default mismatch: $key -> $field"
    Check ($source.Contains('flags.' + $flag + ' = this.' + $field + ';')) "Player-intent snapshot mapping missing: $key -> $flag"
}

# Optional JSON properties are genuinely optional. Do not let PowerShell strict
# mode turn their absence into a test failure; treat a missing developmentOnly as
# false and a missing dependency as no dependency.
$publicCategories = @($contract.categories | Where-Object { -not (Has-Property $_ 'developmentOnly' -and [bool]$_.developmentOnly) })
$publicContractCount = @($publicCategories | ForEach-Object { @($_.settings) }).Count
$modAnnotations = [regex]::Matches($source,'@runtimeProperty\("ModSettings\.mod", "realpass"\)').Count
Check ($publicContractCount -eq 20) 'Unexpected public setting count in manifest contract.'
Check ($modAnnotations -eq $publicContractCount) 'Mod Settings annotations do not match public contract count.'
Check ($source.Contains('public let diagnosticsEnabled: Bool = false;')) 'Development diagnostics intent field missing or enabled by default.'
$diagIndex = $source.IndexOf('public let diagnosticsEnabled: Bool = false;')
$afterLastAnnotation = $source.LastIndexOf('@runtimeProperty("ModSettings.mod", "realpass")')
Check ($diagIndex -gt $afterLastAnnotation) 'Diagnostics may have entered the ordinary player-facing Mod Settings surface.'

# Mod Settings dependency names refer to source fields, while the manifest uses
# stable dotted product keys. Require an exact per-module mapping for all subtoggles.
foreach ($category in $publicCategories) {
    $master = @($category.settings | Where-Object { $_.key -eq ($category.id + '.enabled') })
    if ($master.Count -eq 1) {
        $masterField = $fieldMap[$master[0].key]
        foreach ($setting in @($category.settings | Where-Object { Has-Property $_ 'dependency' })) {
            $field = $fieldMap[$setting.key]
            $fieldPattern = '(?s)@runtimeProperty\("ModSettings\.dependency", "' + [regex]::Escape($masterField) + '"\)\s+public let ' + [regex]::Escape($field) + ': Bool'
            Check ([regex]::IsMatch($source,$fieldPattern)) "Runtime dependency mismatch: $($setting.key)"
        }
    }
}

Check ($source.Contains('@runtimeProperty("ModSettings.category", "Body")')) 'Body category missing from runtime surface.'
Check ($source.Contains('@runtimeProperty("ModSettings.category", "Injury and treatment")')) 'Injury category missing from runtime surface.'
Check ($source.Contains('@runtimeProperty("ModSettings.category", "Combat")')) 'Combat category missing from runtime surface.'
Check ($source.Contains('@runtimeProperty("ModSettings.category", "Armor")')) 'Armor category missing from runtime surface.'
Check ($source.Contains('@runtimeProperty("ModSettings.category", "Cyberware physiology")')) 'Cyberware category missing from runtime surface.'
Check ($source.Contains('@runtimeProperty("ModSettings.category", "Presentation")')) 'Presentation category missing from runtime surface.'

Write-Host "PASS: $script:checks passive realpass Mod Settings surface checks; 20 public preferences mirror contract defaults and map to closed policy flags without opening acceptance gates."
