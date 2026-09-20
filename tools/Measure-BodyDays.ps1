param([string]$ReportPath='reports/body-day-scenarios.json')
. "$PSScriptRoot/../tests/CoreHarness.ps1"
. "$PSScriptRoot/Common.ps1"
$project=Get-ProjectRoot
$paths=@('InjuryModel','BodyModel','SleepModel','BodyPresentation')|ForEach-Object{Join-Path $project "src/redscript/CyberpunkRealism/$_.reds"}
Add-Type -TypeDefinition (Convert-RedscriptCore $paths)
$c=[CRBodyConfig]::new();$m=[CRBodyMeterConfig]::new();$rows=@()
foreach($activity in @(0,0.4,1)){
 $s=[CRBodyModel]::Create($c)
 for($day=1;$day -le 30;$day++){
  $minHydration=100.0;$minNutrition=100.0;$maxBladder=0.0
  # Three meals (2400 kcal total), five 500 ml drinks, three bathroom opportunities,
  # one morning shower, two hours of activity, and an eight-hour night.
  foreach($hour in 0..23){
   if($hour -eq 0){
    [CRBodyModel]::EmptyBowel($s)|Out-Null
    [CRBodyModel]::Wash($s,1)
   }
   if($hour -in @(0,4,10)){[CRBodyModel]::EmptyBladder($s)|Out-Null}
   $food=switch($hour){0{600};4{800};10{1000};default{0}}
   $water=if($hour -in @(0,4,6,10,13)){500}else{0}
   if($food -gt 0 -or $water -gt 0){[CRBodyModel]::Ingest($s,$water,$food,($food*0.075))|Out-Null}
   $effort=if($hour -in @(8,9)){$activity}else{0}
   [CRBodyModel]::Advance($s,$c,1,$effort,($hour -ge 16))|Out-Null
   if(!$s.lastAdvanceAccepted){throw 'Scenario advance rejected'}
   $view=[CRBodyPresentation]::Read($s,$c,$m)
   if(!$view.valid){throw 'Scenario meters invalid'}
   $minHydration=[Math]::Min($minHydration,$view.hydration)
   $minNutrition=[Math]::Min($minNutrition,$view.nutrition)
   $maxBladder=[Math]::Max($maxBladder,$s.bladderMl)
  }
  if($day -in @(1,7,14,30)){
   $rows += [ordered]@{day=$day;activeHours=2;activity=$activity;dailyWaterMl=2500;dailyFoodKcal=2400;lowestHourlyHydration=$minHydration;lowestHourlyNutrition=$minNutrition;morningEnergy=$view.energy;bodyWaterDeficitMl=($c.targetBodyWaterMl-$s.bodyWaterMl);energyBalanceKcal=$s.energyBalanceKcal;maximumHourlyBladderMl=$maxBladder;bowelGrams=$s.bowelGrams;sleepDebtHours=$s.sleepDebtHours;exertionFatigueHours=$s.exertionFatigueHours}
  }
 }
}
Write-JsonFile ([ordered]@{scope='Authored gameplay scenarios using actual Float32 model, not measured game-clock or clinical calibration';sampling='Hourly after body updates; minimum/maximum may miss within-hour extremes';rows=$rows}) (Resolve-SafeChildPath $project $ReportPath)
$rows|ForEach-Object{[pscustomobject]$_}|Format-Table day,activity,lowestHourlyHydration,lowestHourlyNutrition,morningEnergy,bodyWaterDeficitMl,energyBalanceKcal,maximumHourlyBladderMl -AutoSize