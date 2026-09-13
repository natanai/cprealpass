$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\tools\Common.ps1"
$project = Get-ProjectRoot
$script:checks = 0
function Check($condition,[string]$message) { if (-not $condition) { throw $message }; $script:checks++ }

$goals = Get-Content -Raw -LiteralPath (Join-Path $project 'AGREED-GOALS.md')
$conditionDoc = Get-Content -Raw -LiteralPath (Join-Path $project 'docs/CONDITION-UI.md')
$provenancePath = Join-Path $project 'src/redscript/CyberpunkRealism/InjuryProvenance.reds'
$presentationPath = Join-Path $project 'src/redscript/CyberpunkRealism/ConditionPresentation.reds'
$nativeUiPath = Join-Path $project 'src/redscript/CyberpunkRealism/ConditionNativeUI.reds'
$professionalPath = Join-Path $project 'src/redscript/CyberpunkRealism/ProfessionalCareModel.reds'
$professionalRuntimePath = Join-Path $project 'src/redscript/CyberpunkRealism/ProfessionalCareRuntime.reds'
$woundsPath = Join-Path $project 'src/redscript/CyberpunkRealism/CombatWoundsNative.reds'
$fieldCarePath = Join-Path $project 'src/redscript/CyberpunkRealism/FieldCareActionRuntime.reds'
foreach ($path in @($provenancePath,$presentationPath,$nativeUiPath,$professionalPath,$professionalRuntimePath,$woundsPath,$fieldCarePath)) {
    Check (Test-Path -LiteralPath $path) "Missing Condition architecture source: $path"
}
$provenance = Get-Content -Raw -LiteralPath $provenancePath
$presentation = Get-Content -Raw -LiteralPath $presentationPath
$nativeUi = Get-Content -Raw -LiteralPath $nativeUiPath
$professional = Get-Content -Raw -LiteralPath $professionalPath
$professionalRuntime = Get-Content -Raw -LiteralPath $professionalRuntimePath
$wounds = Get-Content -Raw -LiteralPath $woundsPath
$fieldCare = Get-Content -Raw -LiteralPath $fieldCarePath

foreach ($goal in @('G-043','G-044','G-045','G-046','G-047','G-048','G-049','G-050','G-051','G-052','G-053')) {
    Check ($goals.Contains($goal)) "Canonical Condition/treatment goal missing: $goal"
}
Check ($conditionDoc.Contains('CYBERWARE | CONDITION')) 'Condition UI contract does not preserve the agreed mode concept.'
Check ($conditionDoc.Contains('obsolete backpack `FIELD CARE` popup has been retired from production source')) 'Backpack prototype retirement is not documented as production-source removal.'
Check ($conditionDoc.Contains('paper-doll zoom')) 'Native zoom reuse is not part of the Condition UI contract.'
Check ($conditionDoc.Contains('bounded provenance')) 'Condition UI contract does not require bounded provenance.'

Check ($provenance.Contains('private persistent let recent: array<ref<CRInjuryProvenance>>')) 'Provenance is not persistent/bounded runtime state.'
Check ($provenance.Contains('while ArraySize(this.recent) > 16')) 'Provenance history has no hard bound.'
Check ($provenance.Contains('ArrayErase(this.recent, i)') -and $provenance.Contains('ArrayErase(this.recent, 0)')) 'Provenance pruning is not using REDscript array helpers.'
Check (-not $provenance.Contains('this.recent.Erase(')) 'Provenance reintroduced unsupported array member Erase calls.'
Check ($provenance.Contains('sample.targetIsPlayer')) 'Player provenance is not gated to accepted player wounds.'
Check (-not $provenance.Contains('CRInjuryModel.Wound(')) 'Provenance must not become a second injury authority.'
Check (-not $provenance.Contains('CRInjuryModel.Treat(')) 'Provenance must not mutate treatment state.'

$commitIndex = $wounds.IndexOf('plan.committed = CRBodyRuntime.Get().RecordInjury')
$recordIndex = $wounds.IndexOf('CRInjuryProvenanceRuntime.Get().Record(sample, wound)')
Check ($commitIndex -ge 0 -and $recordIndex -gt $commitIndex) 'Provenance is not recorded after authoritative player wound commit.'
Check ($wounds.Contains('if plan.committed')) 'Provenance is not conditioned on successful physical wound commit.'

Check ($professional.Contains('kind != 4 && kind != 5')) 'Professional care accepts field/wound kinds.'
Check ($professional.Contains('ClinicalCanHelp') -and $professional.Contains('MechanicalCanHelp')) 'Professional biological/mechanical eligibility is not separated.'
Check ($professional.Contains('r.cyberwareDamage > 0.0')) 'Mechanical care does not key off chrome damage.'
Check (-not $professional.Contains('CRInjuryModel.Treat(')) 'Professional-care eligibility mutates authoritative injury state.'
foreach ($forbiddenEconomyAuthority in @('GameInstance.GetTransactionSystem','GetMoney(','RemoveMoney(','AddMoney(','PriceService(','PurchaseService(')) {
    Check (-not $professional.Contains($forbiddenEconomyAuthority)) "Professional-care eligibility introduced economy authority: $forbiddenEconomyAuthority"
}
Check ($professionalRuntime.Contains('public class CRProfessionalCareRuntime') -and $professionalRuntime.Contains('CRBodyRuntime.Get()')) 'Professional care has no explicit realpass runtime boundary.'
Check (-not $professionalRuntime.Contains('@addMethod(CRBodyRuntime)')) 'Professional care reintroduced an unresolved custom-class @addMethod target.'
Check ($professionalRuntime.Contains('CRProfessionalCareModel.CanHelp')) 'Professional runtime does not revalidate current condition before commit.'
Check ($professionalRuntime.Contains('.CompleteTreatment(region, kind, 1.0)')) 'Professional runtime does not enter the shared ordered treatment authority.'
Check (-not $professionalRuntime.Contains('CRInjuryModel.Treat(')) 'Professional runtime bypasses the shared body treatment authority.'

Check ($presentation.Contains('public class CRConditionDescriptor')) 'Condition presentation descriptor is missing.'
Check ($presentation.Contains('CRInjuryModel.Function')) 'Condition presentation does not project authoritative regional function.'
Check ($presentation.Contains('CRFieldCareModel.CanHelp')) 'Condition presentation does not derive field-care applicability from the treatment model.'
Check ($presentation.Contains('CRProfessionalCareModel.ClinicalCanHelp') -and $presentation.Contains('CRProfessionalCareModel.MechanicalCanHelp')) 'Condition presentation does not derive professional-care applicability from its model.'
Check ($presentation.Contains('Internal bleeding suspected')) 'Internal bleeding is not distinguished in Condition text.'
Check ($presentation.Contains('Cyberware structural damage')) 'Cyberware injury is not distinguished in Condition text.'
Check ($presentation.Contains('Biological recovery still') -or $presentation.Contains('recovery still takes body time')) 'Condition text no longer communicates delayed biological recovery.'
Check (-not $presentation.Contains('gamedataStatType.Health')) 'Condition presentation must not derive state from native HP.'

# The native UI slice must live on the stock Cyberware/ripperdoc controller, stay
# qualitative, reuse stock paper-doll selection, and dispatch only through body/
# timed-care authorities. Exact native compilation/rendering is still local-only.
Check ($nativeUi.Contains('@wrapMethod(RipperDocGameController)')) 'Condition UI is not mounted on the stock Cyberware/ripperdoc controller.'
Check ($nativeUi.Contains('CRConditionCyberwareTab') -and $nativeUi.Contains('CRConditionConditionTab')) 'CYBERWARE/CONDITION mode controls are missing.'
Check ($nativeUi.Contains('CRConditionPresentation.Current')) 'Native Condition UI does not read the qualitative projection.'
Check ($nativeUi.Contains('this.DollHover(area)') -and $nativeUi.Contains('this.DollSelect(true)')) 'Native Condition UI does not reuse stock anatomical paper-doll selection.'
Check ($nativeUi.Contains('SetWrappingAtPosition(width)') -and -not $nativeUi.Contains('.SetWrapping(true')) 'Condition text wrapping is not using the stock inkText API.'
Check ($nativeUi.Contains('ArrayClear(this.crConditionRegionWidgets)') -and -not $nativeUi.Contains('crConditionRegionWidgets.Clear()')) 'Condition region arrays are not using REDscript array helpers.'
Check ($nativeUi.Contains('descriptor.canDress') -and $nativeUi.Contains('descriptor.canSupport')) 'Condition UI does not gate field actions through model-derived applicability.'
Check ($nativeUi.Contains('CRBodyRuntime.Get().UseFieldCare')) 'Condition UI does not dispatch field treatment through the authoritative timed-care runtime.'
Check ($nativeUi.Contains('descriptor.canClinical') -and $nativeUi.Contains('descriptor.canMechanical')) 'Condition UI does not gate distinct professional actions through model-derived applicability.'
Check ($nativeUi.Contains('CRConditionClinical') -and $nativeUi.Contains('CRConditionMechanical')) 'Condition UI is missing separate clinical/mechanical controls.'
Check ($nativeUi.Contains('CRProfessionalCareRuntime.Complete')) 'Professional Condition actions do not use the revalidating runtime boundary.'
Check ($nativeUi.Contains('Equals(this.m_screen, CyberwareScreenType.Ripperdoc)')) 'Condition UI does not distinguish ordinary field-care context from ripperdoc context.'
Check ($nativeUi.Contains('Biological recovery still takes time')) 'Professional UI implies clinical care is an instant biological heal.'
Check (-not $nativeUi.Contains('SetStatPoolValue') -and -not $nativeUi.Contains('ApplyDamage') -and -not $nativeUi.Contains('CRInjuryModel.Treat(')) 'Condition UI became a simulation/damage authority.'
Check (-not $nativeUi.Contains('DarkFuture') -and -not $nativeUi.Contains('Project E3')) 'Condition UI depends on a source mod runtime.'
Check (-not $nativeUi.Contains('gamedataStatType.Health')) 'Condition UI exposes/derives native HP.'

Check (-not $fieldCare.Contains('DarkFuture.')) 'Field-care action runtime still depends on Dark Future.'
Check ($fieldCare.Contains('GetAllBlackboardDefs().UI_System.IsInMenu')) 'Field-care menu boundary is not using the native realpass-owned path.'

Write-Host "PASS: $script:checks Condition/provenance/field-professional-care/native-UI architecture checks."
