$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\tools\Common.ps1"
$project = Get-ProjectRoot
$script:checks = 0
function Check($condition,[string]$message) { if (-not $condition) { throw $message }; $script:checks++ }

$goals = Get-Content -Raw -LiteralPath (Join-Path $project 'AGREED-GOALS.md')
$conditionDoc = Get-Content -Raw -LiteralPath (Join-Path $project 'docs/CONDITION-UI.md')
$biologyDoc = Get-Content -Raw -LiteralPath (Join-Path $project 'docs/BIOLOGY-UI.md')
$provenancePath = Join-Path $project 'src/redscript/CyberpunkRealism/InjuryProvenance.reds'
$presentationPath = Join-Path $project 'src/redscript/CyberpunkRealism/ConditionPresentation.reds'
$biologyPresentationPath = Join-Path $project 'src/redscript/CyberpunkRealism/BiologyPresentation.reds'
$nativeUiPath = Join-Path $project 'src/redscript/CyberpunkRealism/ConditionNativeUI.reds'
$professionalPath = Join-Path $project 'src/redscript/CyberpunkRealism/ProfessionalCareModel.reds'
$professionalRuntimePath = Join-Path $project 'src/redscript/CyberpunkRealism/ProfessionalCareRuntime.reds'
$woundsPath = Join-Path $project 'src/redscript/CyberpunkRealism/CombatWoundsNative.reds'
$fieldCarePath = Join-Path $project 'src/redscript/CyberpunkRealism/FieldCareActionRuntime.reds'
foreach ($path in @($provenancePath,$presentationPath,$biologyPresentationPath,$nativeUiPath,$professionalPath,$professionalRuntimePath,$woundsPath,$fieldCarePath)) {
    Check (Test-Path -LiteralPath $path) "Missing Biology/condition architecture source: $path"
}

$provenance = Get-Content -Raw -LiteralPath $provenancePath
$presentation = Get-Content -Raw -LiteralPath $presentationPath
$biologyPresentation = Get-Content -Raw -LiteralPath $biologyPresentationPath
$nativeUi = Get-Content -Raw -LiteralPath $nativeUiPath
$professional = Get-Content -Raw -LiteralPath $professionalPath
$professionalRuntime = Get-Content -Raw -LiteralPath $professionalRuntimePath
$wounds = Get-Content -Raw -LiteralPath $woundsPath
$fieldCare = Get-Content -Raw -LiteralPath $fieldCarePath

foreach ($goal in @('G-043','G-044','G-045','G-046','G-047','G-048','G-049','G-060','G-061','G-062','G-063','G-064','G-065','G-072')) {
    Check ($goals.Contains($goal)) "Canonical Biology/condition goal missing: $goal"
}

# The old Cyberware-mounted Condition concept is now explicitly historical. Biology
# owns player-facing body state; Backpack owns possessions; Condition remains a
# subsection/projection rather than a second injury authority.
Check ($conditionDoc.Contains('superseded by `BIOLOGY-UI.md`')) 'Superseded Condition document does not point to Biology.'
Check ($conditionDoc.Contains('Conditions remain a subsection of Biology')) 'Condition migration does not preserve conditions under Biology.'
Check ($biologyDoc.Contains('Backpack = possessions.')) 'Biology contract does not preserve the inventory boundary.'
Check ($biologyDoc.Contains('Biology = embodied state.')) 'Biology contract does not establish Biology as the body-state owner.'
Check ($biologyDoc.Contains('Conditions remain an important Biology subsection')) 'Biology contract does not retain active conditions.'
Check ($biologyDoc.Contains('not permanent meters')) 'Biology contract regressed to permanent needs meters.'
Check ($biologyDoc.Contains('filtered views into actual carried items')) 'Biology item actions risk becoming a duplicate inventory.'
Check ($biologyDoc.Contains('legacy migration code, not canonical architecture')) 'Old Cyberware Condition prototype is not marked legacy.'
Check ($biologyDoc.Contains('Still pending native implementation/acceptance')) 'Biology documentation incorrectly implies the native shell is already complete.'

# Biology view-model must remain qualitative and compose the existing body/condition
# projections rather than reading native HP or hidden simulation values directly.
Check ($biologyPresentation.Contains('public class CRBiologyViewModel')) 'Biology qualitative view-model is missing.'
Check ($biologyPresentation.Contains('CRBodyStatusPresentation.BodyStatus(body)')) 'Biology does not consume the qualitative body-status projection.'
Check ($biologyPresentation.Contains('CRConditionPresentation.Current(region)')) 'Biology does not compose active regional conditions.'
Check ($biologyPresentation.Contains('descriptor.hasCondition')) 'Biology does not suppress healthy condition rows.'
Check (-not $biologyPresentation.Contains('gamedataStatType.Health')) 'Biology derives presentation from native HP.'
Check (-not $biologyPresentation.Contains('hydrationMl') -and -not $biologyPresentation.Contains('calories') -and -not $biologyPresentation.Contains('bladderMl')) 'Biology view-model exposes hidden body quantities directly.'

# Provenance remains bounded explanatory metadata recorded only after accepted wounds.
Check ($provenance.Contains('private persistent let recent: array<ref<CRInjuryProvenance>>')) 'Provenance is not persistent/bounded runtime state.'
Check ($provenance.Contains('while ArraySize(this.recent) > 16')) 'Provenance history has no hard bound.'
Check ($provenance.Contains('ArrayErase(this.recent, i)') -and $provenance.Contains('ArrayErase(this.recent, 0)')) 'Provenance pruning is not using REDscript array helpers.'
Check (-not $provenance.Contains('CRInjuryModel.Wound(') -and -not $provenance.Contains('CRInjuryModel.Treat(')) 'Provenance became a second injury/treatment authority.'
$commitIndex = $wounds.IndexOf('plan.committed = CRBodyRuntime.Get().RecordInjury')
$recordIndex = $wounds.IndexOf('CRInjuryProvenanceRuntime.Get().Record(sample, wound)')
Check ($commitIndex -ge 0 -and $recordIndex -gt $commitIndex -and $wounds.Contains('if plan.committed')) 'Provenance is not recorded only after authoritative wound commit.'

# Condition projection remains qualitative and model-derived so Biology can reuse it.
Check ($presentation.Contains('public class CRConditionDescriptor')) 'Condition presentation descriptor is missing.'
Check ($presentation.Contains('CRInjuryModel.Function')) 'Condition presentation does not project authoritative regional function.'
Check ($presentation.Contains('CRFieldCareModel.CanHelp')) 'Condition presentation does not derive field-care applicability from the treatment model.'
Check ($presentation.Contains('CRProfessionalCareModel.ClinicalCanHelp') -and $presentation.Contains('CRProfessionalCareModel.MechanicalCanHelp')) 'Condition presentation does not derive professional-care applicability from its model.'
Check ($presentation.Contains('Internal bleeding suspected')) 'Internal bleeding is not distinguished in condition text.'
Check ($presentation.Contains('Cyberware structural damage')) 'Cyberware injury is not distinguished in condition text.'
Check (-not $presentation.Contains('gamedataStatType.Health')) 'Condition projection derives state from native HP.'

# Professional/field treatment authority remains separate from presentation.
Check ($professional.Contains('kind != 4 && kind != 5')) 'Professional care accepts field/wound kinds.'
Check ($professional.Contains('ClinicalCanHelp') -and $professional.Contains('MechanicalCanHelp')) 'Professional biological/mechanical eligibility is not separated.'
Check ($professional.Contains('r.cyberwareDamage > 0.0')) 'Mechanical care does not key off chrome damage.'
Check (-not $professional.Contains('CRInjuryModel.Treat(')) 'Professional-care eligibility mutates authoritative injury state.'
Check ($professionalRuntime.Contains('public class CRProfessionalCareRuntime') -and $professionalRuntime.Contains('CRBodyRuntime.Get()')) 'Professional care has no explicit realpass runtime boundary.'
Check ($professionalRuntime.Contains('CRProfessionalCareModel.CanHelp')) 'Professional runtime does not revalidate current condition before commit.'
Check ($professionalRuntime.Contains('.CompleteTreatment(region, kind, 1.0)')) 'Professional runtime does not enter the shared ordered treatment authority.'
Check (-not $fieldCare.Contains('DarkFuture.')) 'Field-care action runtime still depends on Dark Future.'
Check ($fieldCare.Contains('GetAllBlackboardDefs().UI_System.IsInMenu')) 'Field-care menu boundary is not using the native realpass-owned path.'

# Keep the previous Cyberware-mounted UI compiling as migration evidence for now, but
# explicitly reject treating it as the canonical destination. It must remain owned and
# must not mutate simulation state directly.
Check ($nativeUi.Contains('@wrapMethod(RipperDocGameController)')) 'Legacy Condition migration UI no longer has its known native boundary.'
Check ($nativeUi.Contains('CRConditionPresentation.Current')) 'Legacy Condition migration UI lost the qualitative projection used for migration.'
Check (-not $nativeUi.Contains('SetStatPoolValue') -and -not $nativeUi.Contains('ApplyDamage') -and -not $nativeUi.Contains('CRInjuryModel.Treat(')) 'Legacy Condition migration UI became a simulation/damage authority.'
Check (-not $nativeUi.Contains('DarkFuture') -and -not $nativeUi.Contains('Project E3')) 'Legacy Condition migration UI depends on a source-mod runtime.'

Write-Host "PASS: $script:checks Biology/condition/provenance/treatment architecture checks."
