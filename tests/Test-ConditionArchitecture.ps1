$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\tools\Common.ps1"
$project = Get-ProjectRoot
$script:checks = 0
function Check($condition,[string]$message) { if (-not $condition) { throw $message }; $script:checks++ }

$goals = Get-Content -Raw -LiteralPath (Join-Path $project 'AGREED-GOALS.md')
$conditionDoc = Get-Content -Raw -LiteralPath (Join-Path $project 'docs/CONDITION-UI.md')
$provenancePath = Join-Path $project 'src/redscript/CyberpunkRealism/InjuryProvenance.reds'
$presentationPath = Join-Path $project 'src/redscript/CyberpunkRealism/ConditionPresentation.reds'
$woundsPath = Join-Path $project 'src/redscript/CyberpunkRealism/CombatWoundsNative.reds'
$fieldCarePath = Join-Path $project 'src/redscript/CyberpunkRealism/FieldCareActionRuntime.reds'
foreach ($path in @($provenancePath,$presentationPath,$woundsPath,$fieldCarePath)) {
    Check (Test-Path -LiteralPath $path) "Missing Condition architecture source: $path"
}
$provenance = Get-Content -Raw -LiteralPath $provenancePath
$presentation = Get-Content -Raw -LiteralPath $presentationPath
$wounds = Get-Content -Raw -LiteralPath $woundsPath
$fieldCare = Get-Content -Raw -LiteralPath $fieldCarePath

foreach ($goal in @('G-043','G-044','G-045','G-046','G-047','G-048','G-049')) {
    Check ($goals.Contains($goal)) "Canonical Condition goal missing: $goal"
}
Check ($conditionDoc.Contains('CYBERWARE | CONDITION')) 'Condition UI contract does not preserve the agreed mode concept.'
Check ($conditionDoc.Contains('The current backpack `FIELD CARE` popup is a development prototype')) 'Backpack prototype retirement is not documented.'
Check ($conditionDoc.Contains('paper-doll zoom')) 'Native zoom reuse is not part of the Condition UI contract.'
Check ($conditionDoc.Contains('bounded provenance')) 'Condition UI contract does not require bounded provenance.'

Check ($provenance.Contains('private persistent let recent: array<ref<CRInjuryProvenance>>')) 'Provenance is not persistent/bounded runtime state.'
Check ($provenance.Contains('while ArraySize(this.recent) > 16')) 'Provenance history has no hard bound.'
Check ($provenance.Contains('sample.targetIsPlayer')) 'Player provenance is not gated to accepted player wounds.'
Check (-not $provenance.Contains('CRInjuryModel.Wound(')) 'Provenance must not become a second injury authority.'
Check (-not $provenance.Contains('CRInjuryModel.Treat(')) 'Provenance must not mutate treatment state.'

$commitIndex = $wounds.IndexOf('plan.committed = CRBodyRuntime.Get().RecordInjury')
$recordIndex = $wounds.IndexOf('CRInjuryProvenanceRuntime.Get().Record(sample, wound)')
Check ($commitIndex -ge 0 -and $recordIndex -gt $commitIndex) 'Provenance is not recorded after authoritative player wound commit.'
Check ($wounds.Contains('if plan.committed')) 'Provenance is not conditioned on successful physical wound commit.'

Check ($presentation.Contains('public class CRConditionDescriptor')) 'Condition presentation descriptor is missing.'
Check ($presentation.Contains('CRInjuryModel.Function')) 'Condition presentation does not project authoritative regional function.'
Check ($presentation.Contains('CRFieldCareModel.CanHelp')) 'Condition presentation does not derive field-care applicability from the treatment model.'
Check ($presentation.Contains('Internal bleeding suspected')) 'Internal bleeding is not distinguished in Condition text.'
Check ($presentation.Contains('Cyberware structural damage')) 'Cyberware injury is not distinguished in Condition text.'
Check (-not $presentation.Contains('gamedataStatType.Health')) 'Condition presentation must not derive state from native HP.'

Check (-not $fieldCare.Contains('DarkFuture.')) 'Field-care action runtime still depends on Dark Future.'
Check ($fieldCare.Contains('GetAllBlackboardDefs().UI_System.IsInMenu')) 'Field-care menu boundary is not using the native realpass-owned path.'

Write-Host "PASS: $script:checks Condition/provenance architecture checks."
