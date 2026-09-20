param([string]$ReportPath='reports/sleep-drift-after.json')
. "$PSScriptRoot/../tests/CoreHarness.ps1"
. "$PSScriptRoot/Common.ps1"
$project=Get-ProjectRoot
$paths=@('InjuryModel','BodyModel','SleepModel','BodyPresentation')|ForEach-Object{Join-Path $project "src/redscript/CyberpunkRealism/$_.reds"}
Add-Type -TypeDefinition (Convert-RedscriptCore $paths)
$c=[CRBodyConfig]::new();$meters=[CRBodyMeterConfig]::new();$rows=@()
foreach($activity in @(0,0.4,1)){
 $s=[CRBodyModel]::Create($c)
 for($day=1;$day -le 30;$day++){
  [CRBodyModel]::Ingest($s,2000,2400,180)|Out-Null
  [CRBodyModel]::Advance($s,$c,6,0,$false)|Out-Null
  [CRBodyModel]::Advance($s,$c,2,$activity,$false)|Out-Null
  [CRBodyModel]::Advance($s,$c,8,0,$false)|Out-Null
  [CRBodyModel]::Advance($s,$c,8,0,$true)|Out-Null
  if($day -in @(1,7,14,30)){
   $rows += [pscustomobject]@{day=$day;activeHours=2;activity=$activity;wakePressure=$s.sleepPressureHours;debt=$s.sleepDebtHours;exertionFatigue=$s.exertionFatigueHours;morningEnergy=[CRBodyPresentation]::Read($s,$c,$meters).energy}
  }
 }
}
Write-JsonFile $rows (Join-Path $project $ReportPath)
$rows|Format-Table -AutoSize