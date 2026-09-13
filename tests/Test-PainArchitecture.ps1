$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\tools\Common.ps1"
$project = Get-ProjectRoot
$script:checks = 0
function Check($condition,[string]$message) { if (-not $condition) { throw $message }; $script:checks++ }

$goals = Get-Content -Raw -LiteralPath (Join-Path $project 'AGREED-GOALS.md')
$painModel = Get-Content -Raw -LiteralPath (Join-Path $project 'src/redscript/CyberpunkRealism/PainModel.reds')
$painRuntime = Get-Content -Raw -LiteralPath (Join-Path $project 'src/redscript/CyberpunkRealism/PainRuntime.reds')
$painNative = Get-Content -Raw -LiteralPath (Join-Path $project 'src/redscript/CyberpunkRealism/PainNativeEffects.reds')
$bodyHooks = Get-Content -Raw -LiteralPath (Join-Path $project 'src/redscript/CyberpunkRealism/BodyNativeHooks.reds')
$fieldCare = Get-Content -Raw -LiteralPath (Join-Path $project 'src/redscript/CyberpunkRealism/FieldCareRuntime.reds')
$conditionPresentation = Get-Content -Raw -LiteralPath (Join-Path $project 'src/redscript/CyberpunkRealism/ConditionPresentation.reds')
$conditionUI = Get-Content -Raw -LiteralPath (Join-Path $project 'src/redscript/CyberpunkRealism/ConditionNativeUI.reds')

foreach ($goal in @('G-054','G-055','G-056','G-057')) {
    Check ($goals.Contains($goal)) "Canonical pain/Trauma Kit goal missing: $goal"
}

# Pain remains an interpretation of authoritative physical injury plus its own
# bounded analgesic state; it cannot heal or become an HP authority.
Check ($painModel.Contains('CRPainModel.PhysicalPain')) 'Pain model has no physical-injury projection.'
Check ($painModel.Contains('AnalgesiaForLoad') -and $painModel.Contains('IntoxicationForLoad')) 'Analgesia/intoxication model is missing.'
Check ($painModel.Contains('WeaponSwayMultiplier') -and $painModel.Contains('SpreadMultiplier') -and $painModel.Contains('RecoilMultiplier')) 'Pain has no authored weapon-handling projection.'
Check (-not $painModel.Contains('CRInjuryModel.Treat(') -and -not $painModel.Contains('gamedataStatPoolType.Health')) 'Pain model can heal/modify HP.'

# Analgesia decays against CRBodyRuntime elapsed body time; no second timer or
# Dark Future state may own the effect.
Check ($painRuntime.Contains('body.elapsedHours') -and $painRuntime.Contains('CRPainModel.Advance')) 'Analgesia is not synchronized to the shared body clock.'
Check (-not $painRuntime.Contains('DelayCallback') -and -not $painRuntime.Contains('DelaySystem')) 'Pain runtime created an independent progression timer.'
Check (-not $painRuntime.Contains('DarkFuture') -and -not $painRuntime.Contains('Project E3')) 'Pain runtime depends on a source mod.'
Check ($painRuntime.Contains('CRPainModel.UseTraumaKit(this.state)')) 'Trauma Kit does not enter the owned analgesia model.'

# The stock Health Booster family is intercepted after native consumption, its
# vanilla health buff is removed, and it is not forwarded as food/body intake.
Check ($bodyHooks.Contains('gamedataConsumableBaseName.HealthBooster')) 'Native Trauma Kit/Health Booster family is not recognized.'
Check ($bodyHooks.Contains('StatusEffectHelper.RemoveStatusEffect(local, T"BaseStatusEffect.HealthBooster")')) 'Vanilla Health Booster effect is not removed.'
Check ($bodyHooks.Contains('StatusEffectHelper.RemoveStatusEffect(local, T"BaseStatusEffect.Blackmarket_HealthBooster")')) 'Blackmarket Health Booster variant is not removed.'
Check ($bodyHooks.Contains('CRPainRuntime.Get().UseTraumaKit()')) 'Native Trauma Kit use does not route to pain runtime.'
Check ($bodyHooks.Contains('CRPainNativeEffects.Refresh(local, true)')) 'Accepted Trauma Kit use does not reconstruct pain/intoxication feedback immediately.'

# Field wound treatment uses separate supplies. This assertion is deliberately
# cross-layer so a future refactor cannot silently turn Trauma Kits into bandages.
Check (-not $fieldCare.Contains('Items.HealthBooster')) 'Field care still spends Trauma Kits.'
Check ($fieldCare.Contains('Items.GenericJunkItem4') -and $fieldCare.Contains('Items.CommonMaterial1')) 'Dressing/support do not have distinct field supplies.'
Check (-not $conditionUI.Contains('No trauma kit available')) 'Condition field-care feedback still describes wound supplies as Trauma Kits.'

# Native pain effects use weapon sway and CDPR's existing fullscreen drunk loops,
# but do not apply BaseStatusEffect.Drunk and inherit alcohol gameplay packages.
Check ($painNative.Contains('gamedataStatType.SwaySideMaximumAngleDistance') -and $painNative.Contains('gamedataStatType.SwaySideMinimumAngleDistance')) 'Pain does not drive native weapon sway.'
foreach ($level in 1..3) {
    Check ($painNative.Contains("status_drunk_level_$level")) "Native intoxication presentation is missing drunk visual level $level."
}
Check ($painNative.Contains('vfx_fullscreen_drunk_level')) 'Native intoxication audio/fullscreen parameter is not synchronized.'
Check (-not $painNative.Contains('ApplyStatusEffect') -and -not $painNative.Contains('BaseStatusEffect.Drunk')) 'Pain overuse inherited the stock alcohol status/gameplay package.'
Check (-not $painNative.Contains('gamedataStatPoolType.Health') -and -not $painNative.Contains('CRInjuryModel.Treat(')) 'Native pain presentation became a healing/HP authority.'

# Condition mode must expose the qualitative projection rather than calculating a
# second pain value or presenting a numeric pain meter.
Check ($conditionPresentation.Contains('public let painText: String') -and $conditionPresentation.Contains('CRPainRuntime.Get().Read()')) 'Condition descriptor is not sourced from the owned pain projection.'
Check ($conditionUI.Contains('crConditionPain') -and $conditionUI.Contains('this.crConditionPain.SetText(descriptor.painText)')) 'Condition UI does not render qualitative pain state.'
Check (-not $conditionUI.Contains('PAIN: ') -and -not $conditionUI.Contains('pain.perceivedPain')) 'Condition UI computes or exposes a raw pain meter instead of rendering the projection.'

Write-Host "PASS: $script:checks pain/Trauma-Kit ownership, immediate feedback, and Condition rendering architecture checks."
