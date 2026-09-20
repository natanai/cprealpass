. "$PSScriptRoot\..\tools\Common.ps1"
$project = Get-ProjectRoot
$path = Join-Path $project 'src/redscript/CyberpunkRealism/BodyModel.reds'
. "$PSScriptRoot\CoreHarness.ps1"
$sleepPath = Join-Path $project 'src/redscript/CyberpunkRealism/SleepModel.reds'
$injuryPath = Join-Path $project 'src/redscript/CyberpunkRealism/InjuryModel.reds'
$code = Convert-RedscriptCore @($path,$sleepPath,$injuryPath)
$work=Join-Path $project ('staging\body-model-tests-'+[guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $work|Out-Null
Set-Content (Join-Path $work 'BodyModel.cs') $code -Encoding utf8
Add-Type -TypeDefinition $code
$script:checks=0
function Check($Condition,$Message){if(-not $Condition){throw $Message};$script:checks++}
$c=[CRBodyConfig]::new()
$s=[CRBodyModel]::Create($c)
Check ([CRBodyModel]::Ingest($s,500,600,80)) 'Valid intake rejected'
Check ($s.bodyWaterMl -eq 42000 -and $s.bladderMl -eq 0 -and $s.energyBalanceKcal -eq 0 -and $s.bowelGrams -eq 0) 'Intake bypasses digestion'
[CRBodyModel]::Advance($s,$c,1.0/60,0,$false)|Out-Null
Check ($s.bodyWaterMl -gt 42000 -and $s.gutWaterMl -gt 0) 'Absorption missing or instant'
Check ($s.bowelGrams -eq 0 -and $s.colonResidueGrams -gt 0) 'New meal immediately entered bowel'
[CRBodyModel]::Advance($s,$c,23.983333,0,$false)|Out-Null
$totalWater=$s.bodyWaterMl+$s.gutWaterMl+$s.bladderMl+$s.waterLostMl+$s.waterVoidedMl
Check ([Math]::Abs($totalWater-42500) -lt 10) "Water not conserved: $totalWater"
$totalResidue=$s.upperGutResidueGrams+$s.colonResidueGrams+$s.bowelGrams+$s.residueVoidedGrams
Check ([Math]::Abs($totalResidue-80) -lt 0.05) 'Residue not conserved'
Check ([Math]::Abs(($s.gutEnergyKcal+$s.energyBalanceKcal+$s.energyUsedKcal)-600) -lt 1) 'Energy not conserved'
Check ($s.bowelGrams -gt 0 -and $s.bowelGrams -lt 80) 'Gut transit absent or instantaneous'
$rest=[CRBodyModel]::Create($c);$run=[CRBodyModel]::Create($c)
[CRBodyModel]::Advance($rest,$c,2,0,$false)|Out-Null
[CRBodyModel]::Advance($run,$c,2,1,$false)|Out-Null
Check ($run.waterLostMl -gt $rest.waterLostMl -and $run.energyUsedKcal -gt $rest.energyUsedKcal) 'Exertion has no resource cost'
Check ($run.hygieneLoad -gt $rest.hygieneLoad -and $run.exertionFatigueHours -gt $rest.exertionFatigueHours) 'Exertion not connected to other body state'
$good=[CRBodyModel]::Create($c);$short=[CRBodyModel]::Create($c)
for($day=0;$day -lt 3;$day++){
 [CRBodyModel]::Advance($good,$c,16,0,$false)|Out-Null
 [CRBodyModel]::Advance($good,$c,8,0,$true)|Out-Null
 [CRBodyModel]::Advance($short,$c,20,0,$false)|Out-Null
 [CRBodyModel]::Advance($short,$c,4,0,$true)|Out-Null
}
Check ($good.sleepDebtHours -lt 0.01 -and $short.sleepDebtHours -gt 5) 'Sleep debt does not accumulate across short nights'
$bladder=$s.bladderMl;$bowel=$s.bowelGrams
$waterBefore=$s.bodyWaterMl
[CRBodyModel]::EmptyBladder($s)|Out-Null;[CRBodyModel]::EmptyBowel($s)|Out-Null
Check ($s.bladderMl -eq 0 -and $s.waterVoidedMl -eq $bladder -and $s.bodyWaterMl -eq $waterBefore) 'Void changed hydration or lost accounting'
Check ($s.bowelGrams -eq 0 -and $s.residueVoidedGrams -eq $bowel) 'Bowel interaction lost accounting'
[CRBodyModel]::Wash($run,1)
Check ($run.hygieneLoad -eq 0) 'Washing did not clear hygiene load'
$before=$s.gutWaterMl
Check (-not [CRBodyModel]::Ingest($s,-1,0,0)) 'Negative intake accepted'
Check (-not [CRBodyModel]::Ingest($s,[float]::NaN,0,0)) 'NaN intake accepted'
Check ($s.gutWaterMl -eq $before) 'Invalid intake changed state'
$one=[CRBodyModel]::Create($c);$many=[CRBodyModel]::Create($c)
[CRBodyModel]::Advance($one,$c,24,0,$false)|Out-Null
for($i=0;$i -lt 1440;$i++){[CRBodyModel]::Advance($many,$c,1.0/60,0,$false)|Out-Null}
Check ([Math]::Abs($one.bodyWaterMl-$many.bodyWaterMl) -lt 1) 'Day skip and minute updates diverge'
Check ([Math]::Abs($one.elapsedHours-24) -lt 0.005) 'Simulation clock drift exceeds tolerance'
# Exact hour durations must not lose a tick through repeated float subtraction.
for($hours=1;$hours -le 72;$hours++){
 $hourState=[CRBodyModel]::Create($c)
 $ticks=[CRBodyModel]::Advance($hourState,$c,$hours,0,$false)
 if($ticks -ne 60*$hours -or $hourState.pendingHours -gt 0.00001){throw "Whole-hour batch lost ticks at $hours hours: $ticks"}
}
Check $true 'Whole-hour tick parity failed'
$long=[CRBodyModel]::Create($c)
$count=[CRBodyModel]::Advance($long,$c,100,0,$false)
Check ($count -eq 4320 -and $long.pendingHours -gt 27) 'Long skip discarded or processing unbounded'
$queuedBefore=$long.pendingHours
[CRBodyModel]::Advance($long,$c,8,0,$true)|Out-Null
Check (-not $long.lastAdvanceAccepted -and $long.pendingHours -eq $queuedBefore) 'Backlog was reinterpreted as sleep'
# A zero-duration drain must use the stored context, even if the caller supplies sleep.
$pressureBefore=$long.sleepPressureHours
[CRBodyModel]::Advance($long,$c,0,0,$true)|Out-Null
Check ($long.lastAdvanceAccepted -and $long.sleepPressureHours -gt $pressureBefore) 'Backlog drain used the wrong activity'
Check ([Math]::Abs(($long.elapsedHours+$long.pendingHours)-100) -lt 0.01) 'Queued elapsed time was lost'
Write-JsonFile ([ordered]@{testedAtUtc=[DateTime]::UtcNow.ToString('o');passed=$true;assertions=$script:checks;sourceSha256=(Get-Sha256 $path);sleepSourceSha256=(Get-Sha256 $sleepPath);injurySourceSha256=(Get-Sha256 $injuryPath);fixture=$work;scope='Original redscript core translated to C# float32 for arithmetic and conservation tests; no runtime hooks exercised.'}) (Join-Path $project 'reports/body-model-tests.json')
Write-Host "PASS: $script:checks body-model invariant checks."
