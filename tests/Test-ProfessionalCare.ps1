. "$PSScriptRoot\..\tools\Common.ps1"
. "$PSScriptRoot\CoreHarness.ps1"
$project = Get-ProjectRoot
$paths = @('InjuryModel','BodyModel','SleepModel','BodyInputs','ProfessionalCareModel') | ForEach-Object { Join-Path $project "src/redscript/CyberpunkRealism/$_.reds" }
$code = Convert-RedscriptCore $paths
Add-Type -TypeDefinition $code
$script:checks = 0
function Check($condition,[string]$message) { if (-not $condition) { throw $message }; $script:checks++ }
function Wounded {
    $s = [CRInjuryModel]::Create()
    [CRInjuryModel]::Wound($s,5,0.4,0.5,0.6,100,40) | Out-Null
    return $s
}

$s = Wounded
Check ([CRProfessionalCareModel]::ClinicalCanHelp($s,5)) 'Clinical care did not recognize biological/bleeding injury.'
Check ([CRProfessionalCareModel]::MechanicalCanHelp($s,5)) 'Mechanical care did not recognize cyberware damage.'
foreach ($region in @(0,7)) {
    Check (-not [CRProfessionalCareModel]::ClinicalCanHelp($s,$region)) 'Clinical care accepted an invalid region.'
    Check (-not [CRProfessionalCareModel]::MechanicalCanHelp($s,$region)) 'Mechanical care accepted an invalid region.'
}
foreach ($kind in @(0,1,2,3,6)) {
    Check (-not [CRProfessionalCareModel]::CanHelp($s,5,$kind)) "Professional-care model accepted nonprofessional kind $kind."
}

# Clinical intervention stabilizes active biological problems and establishes
# aftercare. It must not directly heal tissue/bone, repair chrome or replace blood.
$s.bloodLostMl = 300
$s.bloodDeficitMl = 300
$beforeTissue = $s.leftLeg.tissueDamage
$beforeBone = $s.leftLeg.boneDamage
$beforeChrome = $s.leftLeg.cyberwareDamage
Check ([CRInjuryModel]::Treat($s,5,4,1)) 'Clinical treatment commit failed.'
Check ($s.leftLeg.externalBleedMlPerHour -eq 0 -and $s.leftLeg.internalBleedMlPerHour -eq 0) 'Clinical care failed to control bleeding.'
Check ($s.leftLeg.tissueDamage -eq $beforeTissue -and $s.leftLeg.boneDamage -eq $beforeBone) 'Clinical care instantly healed tissue/bone.'
Check ($s.leftLeg.cyberwareDamage -eq $beforeChrome) 'Clinical care repaired cyberware.'
Check ($s.leftLeg.clinicalCare -eq 1) 'Clinical care did not establish professional aftercare.'
Check ($s.bloodLostMl -eq 300 -and $s.bloodDeficitMl -eq 300 -and $s.bloodRecoveredMl -eq 0) 'Clinical care magically replaced lost blood.'
Check (-not [CRProfessionalCareModel]::ClinicalCanHelp($s,5)) 'Fully stabilized/aftercare biological injury still advertises duplicate clinical service.'
Check ([CRProfessionalCareModel]::MechanicalCanHelp($s,5)) 'Clinical care hid unresolved mechanical damage.'

# Mechanical service is strictly chrome repair and must not touch biological state.
Check ([CRInjuryModel]::Treat($s,5,5,1)) 'Mechanical repair commit failed.'
Check ($s.leftLeg.cyberwareDamage -eq 0) 'Mechanical service did not repair chrome.'
Check ($s.leftLeg.tissueDamage -eq $beforeTissue -and $s.leftLeg.boneDamage -eq $beforeBone -and $s.leftLeg.clinicalCare -eq 1) 'Mechanical service altered biological injury/aftercare.'
Check ($s.bloodLostMl -eq 300 -and $s.bloodDeficitMl -eq 300) 'Mechanical service altered whole-body blood loss.'
Check (-not [CRProfessionalCareModel]::MechanicalCanHelp($s,5)) 'Repaired chrome still advertises duplicate mechanical service.'

# The native UI commits professional service through CRBodyRuntime.CompleteTreatment,
# which queues the same ordered CRBodyInputs path used by every other body mutation.
$cQueue = [CRBodyConfig]::new()
$body = [CRBodyModel]::Create($cQueue)
$body.injuries = Wounded
$queue = [CRBodyInputQueue]::new()
Check ([CRBodyInputs]::Treatment($queue,5,4,1) -and $queue.count -eq 1) 'Clinical service could not enter shared ordered body inputs.'
Check ([CRBodyInputs]::Drain($queue,$body,$cQueue) -eq 1 -and $queue.appliedTreatments -eq 1) 'Clinical service did not commit through shared body inputs.'
Check ($body.injuries.leftLeg.externalBleedMlPerHour -eq 0 -and $body.injuries.leftLeg.internalBleedMlPerHour -eq 0 -and $body.injuries.leftLeg.tissueDamage -eq [float]0.4 -and $body.injuries.leftLeg.boneDamage -eq [float]0.5 -and $body.injuries.leftLeg.cyberwareDamage -eq [float]0.6) 'Shared clinical commit crossed biological/mechanical boundaries.'
Check ([CRBodyInputs]::Treatment($queue,5,5,1) -and [CRBodyInputs]::Drain($queue,$body,$cQueue) -eq 1 -and $queue.appliedTreatments -eq 2) 'Mechanical service did not commit through shared body inputs.'
Check ($body.injuries.leftLeg.cyberwareDamage -eq 0 -and $body.injuries.leftLeg.tissueDamage -eq [float]0.4 -and $body.injuries.leftLeg.boneDamage -eq [float]0.5) 'Shared mechanical commit altered biological injury.'

# Mechanical repair before clinical care leaves bleeding and biology untouched.
$s = Wounded
Check ([CRInjuryModel]::Treat($s,5,5,1)) 'Initial mechanical service failed.'
Check ($s.leftLeg.externalBleedMlPerHour -eq 100 -and $s.leftLeg.internalBleedMlPerHour -eq 40 -and $s.leftLeg.tissueDamage -eq [float]0.4 -and $s.leftLeg.boneDamage -eq [float]0.5) 'Mechanical repair treated biological trauma.'
Check ([CRProfessionalCareModel]::ClinicalCanHelp($s,5)) 'Mechanical repair incorrectly satisfied clinical need.'

# Professional aftercare accelerates later biological recovery but the injury still
# has to progress through body time. A new biological wound invalidates old care.
$c = [CRBodyConfig]::new()
$c.injuryTissueRecoveryPerHour = 0.02
$c.injuryBoneRecoveryPerHour = 0.01
$c.injuryClinicalRecoveryMultiplier = 2
$c.injuryExternalClotPerHourSquared = 0
$c.injuryBloodRecoveryMlPerHour = 0
$c.injuryBloodWaterFraction = 0.5
$c.injuryBloodCapacityMl = 5000
$c.injuryMetabolicKcalPerHour = 0
$c.injuryExertionBleedMultiplier = 0
$uncared = [CRInjuryModel]::Create(); [CRInjuryModel]::Wound($uncared,5,0.4,0.5,0,0,0) | Out-Null
$cared = [CRInjuryModel]::Copy($uncared); [CRInjuryModel]::Treat($cared,5,4,1) | Out-Null
[CRInjuryModel]::Advance($uncared,$c,1,0,1,10000) | Out-Null
[CRInjuryModel]::Advance($cared,$c,1,0,1,10000) | Out-Null
Check ($uncared.leftLeg.tissueDamage -eq [float]0.38) 'Uncared tissue did not follow ordinary body-clock recovery.'
Check ($uncared.leftLeg.boneDamage -eq [float]0.5) 'Unsupported/uncared bone healed on its own.'
Check ($cared.leftLeg.tissueDamage -lt $uncared.leftLeg.tissueDamage -and $cared.leftLeg.boneDamage -lt $uncared.leftLeg.boneDamage) 'Clinical aftercare did not improve later body-clock recovery.'
Check ($cared.leftLeg.tissueDamage -gt 0 -and $cared.leftLeg.boneDamage -gt 0) 'One hour of aftercare instantly erased injury.'
[CRInjuryModel]::Wound($cared,5,0.05,0,0,0,0) | Out-Null
Check ($cared.leftLeg.clinicalCare -eq 0 -and [CRProfessionalCareModel]::ClinicalCanHelp($cared,5)) 'New biological trauma did not invalidate prior clinical aftercare.'

# Chrome-only damage never becomes a clinical problem, while pure tissue/bone
# trauma can receive professional aftercare even when there is no active bleeding.
$chromeOnly = [CRInjuryModel]::Create(); [CRInjuryModel]::Wound($chromeOnly,3,0,0,0.5,0,0) | Out-Null
Check (-not [CRProfessionalCareModel]::ClinicalCanHelp($chromeOnly,3) -and [CRProfessionalCareModel]::MechanicalCanHelp($chromeOnly,3)) 'Chrome-only damage was not kept separate from biological care.'
$bioOnly = [CRInjuryModel]::Create(); [CRInjuryModel]::Wound($bioOnly,3,0.3,0.2,0,0,0) | Out-Null
Check ([CRProfessionalCareModel]::ClinicalCanHelp($bioOnly,3) -and -not [CRProfessionalCareModel]::MechanicalCanHelp($bioOnly,3)) 'Biological trauma was not kept separate from mechanical repair.'

Write-JsonFile ([ordered]@{
    testedAtUtc = [DateTime]::UtcNow.ToString('o')
    passed = $true
    assertions = $script:checks
    sources = @($paths | ForEach-Object { [ordered]@{path=$_;sha256=(Get-Sha256 $_)} })
    scope = 'Professional-care eligibility plus injury-model and ordered-body-input treatment/recovery boundaries. Verifies clinical versus mechanical separation, no instant tissue/bone healing, no blood replacement, and later body-clock recovery. Native ripperdoc context, UI, service cost/time and saves remain unverified.'
}) (Join-Path $project 'reports/professional-care-tests.json')
Write-Host "PASS: $script:checks professional-care checks."
