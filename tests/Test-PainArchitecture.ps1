$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\tools\Common.ps1"
$project = Get-ProjectRoot
$script:checks = 0
function Check($condition,[string]$message) { if (-not $condition) { throw $message }; $script:checks++ }

$goals = Get-Content -Raw -LiteralPath (Join-Path $project 'AGREED-GOALS.md')
$painModel = Get-Content -Raw -LiteralPath (Join-Path $project 'src/redscript/CyberpunkRealism/PainModel.reds')
$painRuntime = Get-Content -Raw -LiteralPath (Join-Path $project 'src/redscript/CyberpunkRealism/PainRuntime.reds')
$painNative = Get-Content -Raw -LiteralPath (Join-Path $project 'src/redscript/CyberpunkRealism/PainNativeEffects.reds')
$injuryEffectsNative = Get-Content -Raw -LiteralPath (Join-Path $project 'src/redscript/CyberpunkRealism/InjuryEffectsNative.reds')
$bodyHooks = Get-Content -Raw -LiteralPath (Join-Path $project 'src/redscript/CyberpunkRealism/BodyNativeHooks.reds')
$fieldCare = Get-Content -Raw -LiteralPath (Join-Path $project 'src/redscript/CyberpunkRealism/FieldCareRuntime.reds')
$conditionPresentation = Get-Content -Raw -LiteralPath (Join-Path $project 'src/redscript/CyberpunkRealism/ConditionPresentation.reds')
$biologyOverview = Get-Content -Raw -LiteralPath (Join-Path $project 'src/redscript/CyberpunkRealism/BiologyPresentation.reds')
$biologyDetail = Get-Content -Raw -LiteralPath (Join-Path $project 'src/redscript/CyberpunkRealism/BiologyDetailPresentation.reds')
$biologyActions = Get-Content -Raw -LiteralPath (Join-Path $project 'src/redscript/CyberpunkRealism/BiologyActionsNative.reds')

foreach ($goal in @('G-004','G-054','G-055','G-056','G-057','G-066')) {
    Check ($goals.Contains($goal)) "Canonical vanilla-first/pain goal missing: $goal"
}

# Pain remains an interpretation of authoritative physical injury plus its own
# bounded analgesic state; it cannot heal or become an HP authority.
Check ($painModel.Contains('CRPainModel.PhysicalPain')) 'Pain model has no physical-injury projection.'
Check ($painModel.Contains('AnalgesiaForLoad') -and $painModel.Contains('IntoxicationForLoad')) 'Analgesia/intoxication model is missing.'
Check ($painModel.Contains('WeaponSwayMultiplier') -and $painModel.Contains('SpreadMultiplier') -and $painModel.Contains('RecoilMultiplier')) 'Pain has no authored weapon-handling projection.'
Check (-not $painModel.Contains('CRInjuryModel.Treat(') -and -not $painModel.Contains('gamedataStatPoolType.Health')) 'Pain model can heal/modify HP.'
Check ($painModel.Contains('UseMaxDoc') -and -not $painModel.Contains('UseTraumaKit')) 'Pain model does not preserve vanilla MaxDoc identity.'

# Analgesia decays against shared body time; no second timer/source-mod state.
Check ($painRuntime.Contains('body.elapsedHours') -and $painRuntime.Contains('CRPainModel.Advance')) 'Analgesia is not synchronized to shared body clock.'
Check ($painRuntime.Contains('bodyClockAnchored') -and $painRuntime.Contains('lastBodyHours: Float = 0.0')) 'Pain clock does not use explicit REDscript-compatible anchor state.'
Check (-not ($painRuntime -match 'persistent\s+let\s+lastBodyHours\s*:\s*Float\s*=\s*-')) 'Pain runtime reintroduced invalid negative persistent sentinel.'
Check (-not $painRuntime.Contains('DelayCallback') -and -not $painRuntime.Contains('DelaySystem')) 'Pain runtime created an independent progression timer.'
Check (-not $painRuntime.Contains('DarkFuture') -and -not $painRuntime.Contains('Project E3')) 'Pain runtime depends on a source mod.'
Check ($painRuntime.Contains('CRPainModel.UseMaxDoc(this.state)')) 'MaxDoc does not enter owned analgesia model.'

# Vanilla MaxDoc identity/integration. The native action carries its real GameInstance
# into the project-owned session resolver; no project-class redscript patch overload
# is required to retrieve the pain authority.
Check ($bodyHooks.Contains('@wrapMethod(UseHealChargeAction)')) 'MaxDoc is not intercepted at native healing-item action boundary.'
Check ($bodyHooks.Contains('gamedataConsumableBaseName.FirstAidWhiff')) 'Vanilla MaxDoc/FirstAidWhiff family is not recognized.'
Check ($bodyHooks.Contains('painRuntime = CRBiologySessionAuthority.Pain(gameInstance);')) 'Native MaxDoc use does not resolve pain authority from the action-owned session.'
Check (-not $bodyHooks.Contains('painRuntime = CRPainRuntime.Get(gameInstance);')) 'Native MaxDoc regressed to a project-class overload that exact compilation cannot own.'
Check ($bodyHooks -match 'if !IsDefined\(painRuntime\) \|\| !painRuntime.UseMaxDoc\(\) \{\s*wrappedMethod\(actionEffects, gameInstance\);\s*return;') 'Unavailable/rejected Biology analgesia must preserve native medicine behavior.'
Check ($bodyHooks.Contains('CRPainNativeEffects.Refresh(local, true)')) 'Accepted MaxDoc use does not reconstruct pain/intoxication feedback immediately.'
Check (-not $bodyHooks.Contains('gamedataConsumableBaseName.HealthBooster')) 'Health Booster is still repurposed as MaxDoc analgesia.'
Check (-not $bodyHooks.Contains('UseTraumaKit')) 'Source-mod medical naming leaked into native pain adapter.'

# Field wound treatment remains separate from MaxDoc.
Check (-not $fieldCare.Contains('Items.HealthBooster')) 'Field care still spends Health Boosters as wound supplies.'
Check ($fieldCare.Contains('Items.GenericJunkItem4') -and $fieldCare.Contains('Items.CommonMaterial1')) 'Dressing/support do not have distinct field supplies.'
Check (-not $biologyActions.Contains('No trauma kit available')) 'Biology field-care copy uses source-mod Trauma Kit language.'

# Native pain effects reuse weapon sway / CDPR fullscreen drunk loops without applying
# the stock alcohol status package.
Check ($painNative.Contains('gamedataStatType.SwaySideMaximumAngleDistance') -and $painNative.Contains('gamedataStatType.SwaySideMinimumAngleDistance')) 'Pain does not drive native weapon sway.'
foreach ($level in 1..3) {
    Check ($painNative.Contains("status_drunk_level_$level")) "Native intoxication presentation is missing drunk visual level $level."
}
Check ($painNative.Contains('vfx_fullscreen_drunk_level')) 'Native intoxication audio/fullscreen parameter is not synchronized.'
Check (-not $painNative.Contains('ApplyStatusEffect') -and -not $painNative.Contains('BaseStatusEffect.Drunk')) 'Pain overuse inherited stock alcohol gameplay package.'
Check (-not $painNative.Contains('gamedataStatPoolType.Health') -and -not $painNative.Contains('CRInjuryModel.Treat(')) 'Native pain presentation became healing/HP authority.'
Check ($injuryEffectsNative.Contains('CRPainNativeEffects.Refresh(localPlayer')) 'Pain is not refreshed from owned transient-injury reconstruction boundary.'

# Overview is qualitative/terse; exact pain/analgesia values are allowed only in
# deliberate Biology drill-down, per G-041/G-045/G-066. Status words such as
# ANALGESIA and DISORIENTATION are permitted on the overview; numeric metrics are not.
Check ($conditionPresentation.Contains('public let painText: String') -and $conditionPresentation.Contains('CRPainRuntime.Get().Read()')) 'Condition descriptor is not sourced from owned pain projection.'
Check ($conditionPresentation.Contains('MaxDoc analgesia') -and -not $conditionPresentation.Contains('Trauma Kit analgesia')) 'Condition copy does not preserve vanilla MaxDoc terminology.'
Check ($biologyOverview.Contains('CRBiologyPresentation.Effects()')) 'Biology overview lost qualitative pain/effect language.'
Check ($biologyOverview.Contains('"PAIN HIGH"') -and $biologyOverview.Contains('"ANALGESIA"') -and $biologyOverview.Contains('"DISORIENTATION"')) 'Biology overview lost terse pain/analgesia telemetry.'
Check (-not $biologyOverview.Contains('"PERCEIVED PAIN"') -and -not $biologyOverview.Contains('PercentText(') -and -not $biologyOverview.Contains('ToString(RoundF(')) 'Biology overview exposes exact/numeric pain metrics.'
Check ($biologyDetail.Contains('CRPainRuntime.Get().Read()')) 'Deliberate Biology detail does not inspect authoritative pain projection.'
Check ($biologyDetail.Contains('"PERCEIVED PAIN"') -and $biologyDetail.Contains('"ANALGESIA"') -and $biologyDetail.Contains('"DISORIENTATION"')) 'Deliberate nervous-system drill-down lacks exact pain/analgesia/overuse metrics.'
Check (-not $biologyDetail.Contains('CRPainModel.UseMaxDoc') -and -not $biologyDetail.Contains('CRInjuryModel.Treat(')) 'Pain drill-down mutates pain/injury state.'

Write-Host "PASS: $script:checks vanilla-MaxDoc analgesia ownership, embodied feedback, terse qualitative overview and deliberate Biology pain drill-down checks."
