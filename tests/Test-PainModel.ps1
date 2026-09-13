. "$PSScriptRoot\..\tools\Common.ps1"
. "$PSScriptRoot\CoreHarness.ps1"
$project = Get-ProjectRoot
$paths = @('InjuryModel','BodyModel','SleepModel','PainModel') | ForEach-Object { Join-Path $project "src/redscript/CyberpunkRealism/$_.reds" }
$code = Convert-RedscriptCore $paths
Add-Type -TypeDefinition $code
$script:checks = 0
function Check($condition,[string]$message) { if (-not $condition) { throw $message }; $script:checks++ }
function Close([float]$a,[float]$b,[float]$epsilon=0.0001) { return [Math]::Abs($a-$b) -le $epsilon }

$state = [CRPainModel]::Create()
$injury = [CRInjuryModel]::Create()
Check ([CRPainModel]::Valid($state)) 'Fresh pain state invalid.'
$p = [CRPainModel]::Read($injury,$state)
Check ($p.valid -and (Close $p.physicalPain 0) -and (Close $p.perceivedPain 0) -and (Close $p.intoxication 0)) 'Healthy body produced pain/intoxication.'

# Biological trauma creates pain; chrome-only structural damage does not pretend to
# be nociceptive pain without surrounding tissue/bone injury.
[CRInjuryModel]::Wound($injury,3,0.6,0.0,0.0,0.0,0.0) | Out-Null
$p = [CRPainModel]::Read($injury,$state)
Check ($p.physicalPain -gt 0.35 -and $p.perceivedPain -eq $p.physicalPain) 'Arm tissue trauma did not create unsuppressed pain.'
$chrome = [CRInjuryModel]::Create(); [CRInjuryModel]::Wound($chrome,3,0.0,0.0,0.8,0.0,0.0) | Out-Null
Check ((Close ([CRPainModel]::PhysicalPain($chrome)) 0)) 'Chrome-only damage was treated as biological pain.'
$bone = [CRInjuryModel]::Create(); [CRInjuryModel]::Wound($bone,5,0.2,0.8,0.0,0.0,0.0) | Out-Null
Check ([CRPainModel]::PhysicalPain($bone) -gt [CRPainModel]::PhysicalPain($injury)) 'Severe bone trauma was not pain-heavy.'

# Trauma Kit analgesia only changes the pain state. It must not modify the injury.
$before = [CRInjuryModel]::Copy($injury)
Check ([CRPainModel]::UseTraumaKit($state)) 'First Trauma Kit dose rejected.'
$p1 = [CRPainModel]::Read($injury,$state)
Check ($p1.analgesia -gt 0 -and $p1.perceivedPain -lt $p1.physicalPain) 'Trauma Kit did not reduce perceived pain.'
Check ([CRInjuryModel]::ValidState($injury) -and $injury.leftArm.tissueDamage -eq $before.leftArm.tissueDamage) 'Analgesia altered underlying injury.'
Check ($injury.leftArm.externalBleedMlPerHour -eq $before.leftArm.externalBleedMlPerHour -and $injury.leftArm.cyberwareDamage -eq $before.leftArm.cyberwareDamage) 'Analgesia changed bleeding/chrome.'

# Each overlapping dose adds less pain relief than the previous one.
$gain1 = $p1.analgesia
Check ([CRPainModel]::UseTraumaKit($state)) 'Second Trauma Kit dose rejected.'
$p2 = [CRPainModel]::Read($injury,$state)
$gain2 = $p2.analgesia - $p1.analgesia
Check ([CRPainModel]::UseTraumaKit($state)) 'Third Trauma Kit dose rejected.'
$p3 = [CRPainModel]::Read($injury,$state)
$gain3 = $p3.analgesia - $p2.analgesia
Check ($gain1 -gt $gain2 -and $gain2 -gt $gain3 -and $gain3 -gt 0) 'Analgesia does not have diminishing returns.'
Check ($p3.perceivedPain -gt 0) 'Stacked Trauma Kits erased pain entirely.'
Check ($p2.intoxication -eq 0 -and $p3.intoxication -gt 0) 'Overlapping third dose did not enter intoxication envelope at the intended threshold.'
Check ($p3.intoxication -lt 1) 'Third dose jumped directly to maximum intoxication.'

Check ([CRPainModel]::UseTraumaKit($state)) 'Fourth Trauma Kit dose rejected.'
$p4 = [CRPainModel]::Read($injury,$state)
Check ((Close $p4.intoxication 1)) 'Fourth overlapping dose did not reach the authored maximum intoxication envelope.'
Check ($p4.analgesia -le 0.85) 'Analgesia exceeded the hard relief ceiling.'
Check ($state.dosesTaken -eq 4) 'Dose history counter did not record accepted uses.'

# Load decays through body time; intoxication clears before the lifetime dose count.
Check ([CRPainModel]::Advance($state,2.0)) 'Pain state rejected valid time advancement.'
$pAfter2h = [CRPainModel]::Read($injury,$state)
Check ((Close $state.analgesicLoad 3.0) -and $state.dosesTaken -eq 4) 'Analgesic load/history decayed incorrectly.'
Check ($pAfter2h.intoxication -gt 0 -and $pAfter2h.intoxication -lt 1) 'Intoxication did not decay with concurrent load.'
Check ([CRPainModel]::Advance($state,6.0)) 'Pain state rejected later time advancement.'
$pCleared = [CRPainModel]::Read($injury,$state)
Check ((Close $state.analgesicLoad 0) -and (Close $pCleared.analgesia 0) -and (Close $pCleared.intoxication 0)) 'Analgesia/intoxication failed to clear with time.'
Check ((Close $pCleared.perceivedPain $pCleared.physicalPain)) 'Pain did not return when analgesia cleared while injury remained.'

# Reject malformed state/time rather than silently normalizing impossible values.
$bad = [CRPainModel]::Create(); $bad.analgesicLoad = [float]::NaN
Check (-not [CRPainModel]::Valid($bad)) 'NaN analgesic load accepted.'
Check (-not [CRPainModel]::Advance($state,-1.0) -and -not [CRPainModel]::Advance($state,73.0)) 'Pain model accepted impossible time interval.'

Write-JsonFile ([ordered]@{
    testedAtUtc = [DateTime]::UtcNow.ToString('o')
    passed = $true
    assertions = $script:checks
    sources = @($paths | ForEach-Object { [ordered]@{path=$_;sha256=(Get-Sha256 $_)} })
    scope = 'Pure realpass pain/analgesia model. Covers biological versus chrome pain, Trauma Kit pain-only semantics, diminishing returns, intoxication envelope and deterministic load decay. Native item interception, drunk/SFX presentation, V vocalizations and live aiming behavior remain unverified.'
}) (Join-Path $project 'reports/pain-model-tests.json')
Write-Host "PASS: $script:checks pain/analgesia checks."
