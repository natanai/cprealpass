$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\tools\Common.ps1"
$project = Get-ProjectRoot
$script:checks = 0
function Check($condition,[string]$message) { if (-not $condition) { throw $message }; $script:checks++ }

$goals = Get-Content -Raw -LiteralPath (Join-Path $project 'AGREED-GOALS.md')
$biologyDoc = Get-Content -Raw -LiteralPath (Join-Path $project 'docs/BIOLOGY-UI.md')
$provenancePath = Join-Path $project 'src/redscript/CyberpunkRealism/InjuryProvenance.reds'
$presentationPath = Join-Path $project 'src/redscript/CyberpunkRealism/ConditionPresentation.reds'
$biologyPresentationPath = Join-Path $project 'src/redscript/CyberpunkRealism/BiologyPresentation.reds'
$biologyActionsPath = Join-Path $project 'src/redscript/CyberpunkRealism/BiologyActionsNative.reds'
$biologyShellPath = Join-Path $project 'src/redscript/CyberpunkRealism/BiologyCyberwareShell.reds'
$oldBiologyPath = Join-Path $project 'src/redscript/CyberpunkRealism/BiologyNativeUI.reds'
$legacyConditionPath = Join-Path $project 'src/redscript/CyberpunkRealism/ConditionNativeUI.reds'
$professionalPath = Join-Path $project 'src/redscript/CyberpunkRealism/ProfessionalCareModel.reds'
$professionalRuntimePath = Join-Path $project 'src/redscript/CyberpunkRealism/ProfessionalCareRuntime.reds'
$woundsPath = Join-Path $project 'src/redscript/CyberpunkRealism/CombatWoundsNative.reds'
$fieldCarePath = Join-Path $project 'src/redscript/CyberpunkRealism/FieldCareActionRuntime.reds'
foreach ($path in @($provenancePath,$presentationPath,$biologyPresentationPath,$biologyActionsPath,$biologyShellPath,$professionalPath,$professionalRuntimePath,$woundsPath,$fieldCarePath)) {
    Check (Test-Path -LiteralPath $path) "Missing Biology/condition architecture source: $path"
}
Check (-not (Test-Path -LiteralPath $oldBiologyPath)) 'Failed floating Biology hub prototype remains in production source.'
Check (-not (Test-Path -LiteralPath $legacyConditionPath)) 'Superseded Cyberware-mounted ConditionNativeUI remains in production source.'

$provenance = Get-Content -Raw -LiteralPath $provenancePath
$presentation = Get-Content -Raw -LiteralPath $presentationPath
$biologyPresentation = Get-Content -Raw -LiteralPath $biologyPresentationPath
$biologyActions = Get-Content -Raw -LiteralPath $biologyActionsPath
$biologyShell = Get-Content -Raw -LiteralPath $biologyShellPath
$professional = Get-Content -Raw -LiteralPath $professionalPath
$professionalRuntime = Get-Content -Raw -LiteralPath $professionalRuntimePath
$wounds = Get-Content -Raw -LiteralPath $woundsPath
$fieldCare = Get-Content -Raw -LiteralPath $fieldCarePath

foreach ($goal in @('G-043','G-044','G-045','G-046','G-047','G-048','G-049','G-060','G-061','G-062','G-063','G-064','G-065','G-066','G-072')) {
    Check ($goals.Contains($goal)) "Canonical Biology/condition goal missing: $goal"
}

# The superseded Condition instruction packet is intentionally absent; Biology is the
# only active body-interface architecture document in the current tree.
Check (-not (Test-Path -LiteralPath (Join-Path $project 'docs/CONDITION-UI.md'))) 'Superseded Condition instruction packet returned to the active tree.'
Check ($biologyDoc.Contains('Cyberware is installed equipment within the body') -and $biologyDoc.Contains('Biology submode')) 'Biology contract does not establish Cyberware as a Biology submode.'
Check ($biologyDoc.Contains('The Biology screen is **always available**') -and $biologyDoc -match '(?i)supported.*body.*nodes.*remain visible.*selectable') 'Biology contract does not preserve healthy-state inspectability.'
Check ($biologyDoc -match '(?i)actual.*carried items/actions' -and $biologyDoc -match '(?i)never creates a second inventory|never.*manually.*decrement') 'Biology item actions risk becoming a duplicate inventory.'
Check ($biologyDoc -match '(?i)detail/drill-down.*mode switching is unavailable' -and $biologyDoc -match '(?i)Back/Cancel.*overview') 'Biology condition contract lost native detail/back mode-state rules.'

# Overview remains qualitative/terse and composes body/condition/pain projections.
Check ($biologyPresentation.Contains('public class CRBiologyViewModel')) 'Biology qualitative view-model is missing.'
Check ($biologyPresentation.Contains('CRBodyStatusPresentation.BodyStatus(body)')) 'Biology does not consume the qualitative body-status projection.'
Check ($biologyPresentation.Contains('CRConditionPresentation.Current(region)')) 'Biology does not compose active regional conditions.'
Check ($biologyPresentation.Contains('descriptor.hasCondition')) 'Biology does not suppress healthy condition rows.'
Check ($biologyPresentation.Contains('showEat') -and $biologyPresentation.Contains('showDrink')) 'Biology has no contextual intake-action projection.'
Check ($biologyPresentation.Contains('CRPainRuntime.Get().Read()')) 'Biology does not project meaningful current pain/analgesia effects.'
Check (-not $biologyPresentation.Contains('gamedataStatType.Health')) 'Biology derives presentation from native HP.'
Check (-not $biologyPresentation.Contains('bladderMl') -and -not $biologyPresentation.Contains('bloodDeficitMl')) 'Biology overview exposes hidden exact body quantities.'

# Contextual actions use actual carried inventory/native actions and shared treatment runtimes.
Check ($biologyActions.Contains('GetItemList(player, items)')) 'Biology does not enumerate the actual carried inventory.'
Check ($biologyActions.Contains('GetItemQuantity(player, itemID)')) 'Biology item picker does not show quantity from authoritative stack.'
Check ($biologyActions.Contains('CRItemServing.Resolve(record)')) 'Biology inventory picker does not use shared serving classification.'
Check ($biologyActions.Contains('ItemActionsHelper.GetEatAction') -and $biologyActions.Contains('ItemActionsHelper.EatItem')) 'Biology food path does not preserve stock Eat actions.'
Check ($biologyActions.Contains('ItemActionsHelper.GetDrinkAction') -and $biologyActions.Contains('ItemActionsHelper.DrinkItem')) 'Biology drink path does not preserve stock Drink actions.'
Check ($biologyActions.Contains('ItemActionsHelper.GetConsumeAction') -and $biologyActions.Contains('ItemActionsHelper.ConsumeItem')) 'Biology lost stock generic Consume fallback.'
Check ($biologyActions.Contains('GetLocalizedItemNameByCName(record.DisplayName())')) 'Biology item picker does not use stock item-name localization.'
Check (-not $biologyActions.Contains('RemoveItem(') -and -not $biologyActions.Contains('CRBodyRuntime.Get().Consume(')) 'Biology bypasses native item transaction/consumption adapter.'
Check ($biologyActions.Contains('CRBodyRuntime.Get().UseFieldCare')) 'Biology does not initiate shared field-care runtime actions.'
Check ($biologyActions.Contains('CRProfessionalCareRuntime.Complete')) 'Biology has no professional-care completion path.'
Check ($biologyActions.Contains('CyberwareScreenType.Ripperdoc')) 'Professional Biology care is not constrained to ripperdoc context.'
Check (-not $biologyActions.Contains('SetStatPoolValue') -and -not $biologyActions.Contains('ApplyDamage') -and -not $biologyActions.Contains('CRInjuryModel.Treat(')) 'Biology action UI became a simulation/damage authority.'
Check (-not $biologyActions.Contains('DarkFuture') -and -not $biologyActions.Contains('Project E3')) 'Biology actions depend on a source-mod runtime.'

# The shell owns navigation/presentation, never treatment authority.
Check ($biologyShell.Contains('BIOLOGY') -and $biologyShell.Contains('CYBERWARE')) 'Shared Biology/Cyberware shell is missing.'
Check (-not $biologyShell.Contains('CRInjuryModel.Treat(') -and -not $biologyShell.Contains('RemoveItem(') -and -not $biologyShell.Contains('SetStatPoolValue')) 'Shared shell became a simulation/inventory authority.'

# Provenance remains bounded explanatory metadata recorded only after accepted wounds.
Check ($provenance.Contains('private persistent let recent: array<ref<CRInjuryProvenance>>')) 'Provenance is not persistent/bounded runtime state.'
Check ($provenance.Contains('while ArraySize(this.recent) > 16')) 'Provenance history has no hard bound.'
Check ($provenance.Contains('ArrayErase(this.recent, i)') -and $provenance.Contains('ArrayErase(this.recent, 0)')) 'Provenance pruning is not using REDscript array helpers.'
Check (-not $provenance.Contains('CRInjuryModel.Wound(') -and -not $provenance.Contains('CRInjuryModel.Treat(')) 'Provenance became a second injury/treatment authority.'
$commitIndex = $wounds.IndexOf('plan.committed = CRBodyRuntime.Get().RecordInjury')
$recordIndex = $wounds.IndexOf('CRInjuryProvenanceRuntime.Get().Record(sample, wound)')
Check ($commitIndex -ge 0 -and $recordIndex -gt $commitIndex -and $wounds.Contains('if plan.committed')) 'Provenance is not recorded only after authoritative wound commit.'

# Condition projection remains qualitative and model-derived.
Check ($presentation.Contains('public class CRConditionDescriptor')) 'Condition presentation descriptor is missing.'
Check ($presentation.Contains('CRInjuryModel.Function')) 'Condition presentation does not project authoritative regional function.'
Check ($presentation.Contains('CRFieldCareModel.CanHelp')) 'Condition presentation does not derive field-care applicability from treatment model.'
Check ($presentation.Contains('CRProfessionalCareModel.ClinicalCanHelp') -and $presentation.Contains('CRProfessionalCareModel.MechanicalCanHelp')) 'Condition presentation does not derive professional-care applicability from its model.'
Check ($presentation.Contains('Internal bleeding suspected')) 'Internal bleeding is not distinguished in condition text.'
Check ($presentation.Contains('Cyberware structural damage')) 'Cyberware injury is not distinguished in condition text.'
Check (-not $presentation.Contains('gamedataStatType.Health')) 'Condition projection derives state from native HP.'

# Treatment authority remains separate from presentation.
Check ($professional.Contains('kind != 4 && kind != 5')) 'Professional care accepts field/wound kinds.'
Check ($professional.Contains('ClinicalCanHelp') -and $professional.Contains('MechanicalCanHelp')) 'Professional biological/mechanical eligibility is not separated.'
Check ($professional.Contains('r.cyberwareDamage > 0.0')) 'Mechanical care does not key off chrome damage.'
Check (-not $professional.Contains('CRInjuryModel.Treat(')) 'Professional-care eligibility mutates authoritative injury state.'
Check ($professionalRuntime.Contains('public class CRProfessionalCareRuntime') -and $professionalRuntime.Contains('CRBodyRuntime.Get()')) 'Professional care has no explicit Biology runtime boundary.'
Check ($professionalRuntime.Contains('CRProfessionalCareModel.CanHelp')) 'Professional runtime does not revalidate current condition before commit.'
Check ($professionalRuntime.Contains('.CompleteTreatment(region, kind, 1.0)')) 'Professional runtime does not enter shared ordered treatment authority.'
Check (-not $fieldCare.Contains('DarkFuture.')) 'Field-care runtime still depends on Dark Future.'
Check ($fieldCare.Contains('GetAllBlackboardDefs().UI_System.IsInMenu')) 'Field-care menu boundary is not using native Biology-owned path.'

Write-Host "PASS: $script:checks shared persistent Biology shell, condition/provenance, inventory and treatment architecture checks."
