. "$PSScriptRoot/../tools/Common.ps1"
. "$PSScriptRoot/CoreHarness.ps1"
$project=Get-ProjectRoot
$paths=@('InjuryModel','BodyModel','SleepModel','BodyInputs','ServingModel','BodyPresentation','BodyForecast')|ForEach-Object{Join-Path $project "src/redscript/CyberpunkRealism/$_.reds"}
Add-Type -TypeDefinition (Convert-RedscriptCore $paths)
$script:checks=0
function Check($condition,$message){if(!$condition){throw $message};$script:checks++}
function Near($a,$b,$message){Check ([Math]::Abs($a-$b) -lt 0.003) $message}
$c=[CRBodyConfig]::new();$m=[CRBodyMeterConfig]::new()
# Full nights must recover ordinary activity, including activity immediately before bed.
foreach($activity in @(0,0.4,1)){
 foreach($activeHours in @(2,8,16)){
  $s=[CRBodyModel]::Create($c)
  for($day=1;$day -le 30;$day++){
   [CRBodyModel]::Advance($s,$c,(16-$activeHours),0,$false)|Out-Null
   [CRBodyModel]::Advance($s,$c,$activeHours,$activity,$false)|Out-Null
   [CRBodyModel]::Advance($s,$c,8,0,$true)|Out-Null
   Near $s.sleepPressureHours 0 "Residual wake pressure on day $day"
   Near $s.exertionFatigueHours 0 "Residual acute fatigue on day $day activity=$activity hours=$activeHours"
   Near $s.sleepDebtHours 0 "Full night accumulated sleep debt on day $day"
   Near ([CRBodyPresentation]::Read($s,$c,$m).energy) 100 'Morning energy drift'
  }
 }
}
# Exertion still matters during the day; quiet waking rest recovers it without repaying sleep.
$rest=[CRBodyModel]::Create($c);$active=[CRBodyModel]::Create($c)
[CRBodyModel]::Advance($rest,$c,2,0,$false)|Out-Null
[CRBodyModel]::Advance($active,$c,2,1,$false)|Out-Null
Near $active.sleepPressureHours $rest.sleepPressureHours 'Activity changed chronological wake time'
Check ($active.exertionFatigueHours -gt 0) 'Activity produced no acute fatigue'
Check (([CRBodyPresentation]::Read($active,$c,$m).energy) -lt ([CRBodyPresentation]::Read($rest,$c,$m).energy)) 'Energy ignored exertion'
$active.sleepDebtHours=4
[CRBodyModel]::Advance($active,$c,5,0,$false)|Out-Null
Near $active.exertionFatigueHours 0 'Quiet rest failed to recover acute fatigue'
Near $active.sleepDebtHours 4 'Waking rest repaid missed sleep'
Near $active.sleepPressureHours 7 'Waking rest erased time awake'
# Actual short nights retain consequences; one normal night cannot erase historical debt.
$short=[CRBodyModel]::Create($c)
for($day=0;$day -lt 7;$day++){
 [CRBodyModel]::Advance($short,$c,16,0,$false)|Out-Null
 [CRBodyModel]::Advance($short,$c,2,1,$false)|Out-Null
 [CRBodyModel]::Advance($short,$c,6,0,$true)|Out-Null
}
Near $short.sleepDebtHours 14 'Short nights lost sleep debt'
[CRBodyModel]::Advance($short,$c,16,0,$false)|Out-Null
[CRBodyModel]::Advance($short,$c,8,0,$true)|Out-Null
Near $short.sleepDebtHours 14 'Normal night erased historical shortfall'
[CRBodyModel]::Advance($short,$c,14,0,$false)|Out-Null
[CRBodyModel]::Advance($short,$c,10,0,$true)|Out-Null
Near $short.sleepDebtHours 12 'Extra sleep failed to repay shortfall'
# Forecast copies the new field; simulated rest changes only the copy and matches actual recovery.
$s=[CRBodyModel]::Create($c)
[CRBodyModel]::Advance($s,$c,8,1,$false)|Out-Null
$originalFatigue=$s.exertionFatigueHours
$f=[CRBodyForecast]::Create($s,[CRBodyInputQueue]::new(),$c,$m)
Near $f.body.exertionFatigueHours $originalFatigue 'Forecast omitted acute fatigue'
$preview=[CRBodyForecast]::Step($f,2,$true)
Near $s.exertionFatigueHours $originalFatigue 'Forecast mutated live fatigue'
[CRBodyModel]::Advance($s,$c,2,0,$true)|Out-Null
Near $preview.energy ([CRBodyPresentation]::Read($s,$c,$m).energy) 'Forecast and actual sleep differ'
# Additive field defaults preserve older body pressure/debt and percent migration.
$legacy=[CRBodyModel]::Create($c);$legacy.sleepPressureHours=20;$legacy.sleepDebtHours=4
Near ([CRBodyPresentation]::Read($legacy,$c,$m).energy) 37.5 'Default new field refilled legacy energy'
$copy=[CRBodyForecast]::CopyBody($legacy)
Near $copy.sleepPressureHours 20 'Copy changed legacy pressure'
Near $copy.sleepDebtHours 4 'Copy changed legacy debt'
$migrated=[CRBodyPresentation]::Migrate($c,$m,75,60,35)
Near $migrated.exertionFatigueHours 0 'Meter migration invented exertion history'
Near ([CRBodyPresentation]::Read($migrated,$c,$m).energy) 35 'Meter migration changed energy'
# Bad sleep config must reject the whole body step, not silently advance its other systems.
foreach($field in @('sleepNeedHoursPerDay','sleepPressureRecoveryPerHour','exertionFatigueGainPerHour','exertionFatigueRestRecoveryPerHour','exertionFatigueSleepRecoveryPerHour','exertionFatigueMaximumHours')){
 foreach($bad in @([float]::NaN,[float]::PositiveInfinity,-1)){
  $invalid=[CRBodyConfig]::new();$invalid.$field=$bad;$s=[CRBodyModel]::Create($c)
  [CRBodyModel]::Advance($s,$invalid,1,1,$false)|Out-Null
  Check (!$s.lastAdvanceAccepted -and $s.elapsedHours -eq 0 -and $s.bodyWaterMl -eq 42000 -and $s.exertionFatigueHours -eq 0) "Invalid config partially advanced $field"
  Check (![CRBodyPresentation]::Read($s,$invalid,$m).valid) 'Invalid config displayed valid meters'
  Check (![CRBodyModel]::CloseInterval($s,$invalid)) 'Invalid config closed a partial interval'
 }
}
foreach($bad in @([float]::NaN,[float]::PositiveInfinity,-1)){
 $s=[CRBodyModel]::Create($c);$s.exertionFatigueHours=$bad
 [CRBodyModel]::Advance($s,$c,1,0,$false)|Out-Null
 Check (!$s.lastAdvanceAccepted -and $s.elapsedHours -eq 0) 'Invalid persisted fatigue accepted'
 Check (![CRBodyPresentation]::Read($s,$c,$m).valid) 'Invalid persisted fatigue displayed'
}
# The minute loop and hour batches must use identical context boundaries.
$batch=[CRBodyModel]::Create($c);$minute=[CRBodyModel]::Create($c)
foreach($segment in @(@(5,1,$false),@(3,0,$false),@(2,0,$true))){
 [CRBodyModel]::Advance($batch,$c,$segment[0],$segment[1],$segment[2])|Out-Null
 for($i=0;$i -lt $segment[0]*60;$i++){[CRBodyModel]::Advance($minute,$c,(1.0/60),$segment[1],$segment[2])|Out-Null}
}
Near $batch.exertionFatigueHours $minute.exertionFatigueHours 'Batching changed fatigue'
Near $batch.sleepPressureHours $minute.sleepPressureHours 'Batching changed pressure'
Write-JsonFile ([ordered]@{passed=$true;checks=$script:checks;scope='Actual Float32 core: 30-day full nights, exertion/rest, shortfall recovery, forecast and additive defaults, invalid state/config rejection, tick parity';nativeSaveValidation=$false}) (Join-Path $project 'reports/sleep-fatigue-tests.json')
Write-Host "Sleep fatigue checks passed: $script:checks"