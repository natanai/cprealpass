. "$PSScriptRoot\..\tools\Common.ps1"
. "$PSScriptRoot\CoreHarness.ps1"
$project=Get-ProjectRoot
$paths=@('InjuryModel','BodyModel','SleepModel','BodyPresentation')|ForEach-Object{Join-Path $project "src/redscript/CyberpunkRealism/$_.reds"}
Add-Type -TypeDefinition (Convert-RedscriptCore $paths)
$script:checks=0
function Check($condition,$message){if(-not $condition){throw $message};$script:checks++}
$c=[CRBodyConfig]::new();$m=[CRBodyMeterConfig]::new()
$maxError=0.0
foreach($h in @(0,1,10,25,50,75,99,100)){
 foreach($n in @(0,10,50,100)){
  foreach($e in @(0,5,50,100)){
   $s=[CRBodyPresentation]::Migrate($c,$m,$h,$n,$e)
   $view=[CRBodyPresentation]::Read($s,$c,$m)
   if(-not $view.valid){throw 'Valid migration did not produce a readable body'}
   $maxError=[Math]::Max($maxError,[Math]::Max([Math]::Abs($view.hydration-$h),[Math]::Max([Math]::Abs($view.nutrition-$n),[Math]::Abs($view.energy-$e))))
  }
 }
}
Check ($maxError -lt 0.001) 'Migration silently changed current needs percentages'
$s=[CRBodyPresentation]::Migrate($c,$m,75,50,25)
Check ($s.gutWaterMl -eq 0 -and $s.gutEnergyKcal -eq 0 -and $s.bladderMl -eq 0 -and $s.bowelGrams -eq 0 -and $s.sleepDebtHours -eq 0) 'Migration fabricated digestive or sleep history'
Check ($null -eq [CRBodyPresentation]::Migrate($c,$m,-1,50,50)) 'Unready upstream sentinel migrated'
Check ($null -eq [CRBodyPresentation]::Migrate($c,$m,101,50,50)) 'Out-of-range upstream value clamped silently'
Check ($null -eq [CRBodyPresentation]::Migrate($c,$m,50,[float]::NaN,50)) 'NaN upstream value migrated'
Check ($null -eq [CRBodyPresentation]::Migrate($c,$m,50,50,[float]::PositiveInfinity)) 'Infinite upstream value migrated'
$before=[CRBodyPresentation]::Read($s,$c,$m)
[CRBodyModel]::Ingest($s,500,650,35)|Out-Null
$after=[CRBodyPresentation]::Read($s,$c,$m)
Check ($before.hydration -eq $after.hydration -and $before.nutrition -eq $after.nutrition -and $before.energy -eq $after.energy) 'Intake instantly refilled projected needs'
[CRBodyModel]::Advance($s,$c,0.5,0,$false)|Out-Null
$after=[CRBodyPresentation]::Read($s,$c,$m)
Check ($after.hydration -gt $before.hydration -and $after.nutrition -gt $before.nutrition) 'Absorption did not feed displayed needs'
Check ($after.energy -lt $before.energy) 'Calories refilled sleep energy'
$awake=[CRBodyPresentation]::Migrate($c,$m,100,100,50)
$sleep=[CRBodyPresentation]::Migrate($c,$m,100,100,50)
[CRBodyModel]::Advance($awake,$c,8,0,$false)|Out-Null
[CRBodyModel]::Advance($sleep,$c,8,0,$true)|Out-Null
$awakeView=[CRBodyPresentation]::Read($awake,$c,$m);$sleepView=[CRBodyPresentation]::Read($sleep,$c,$m)
Check ($sleepView.energy -gt $awakeView.energy) 'Sleep recovery is not reflected in the meter'
$sleep.sleepDebtHours=12
$debtView=[CRBodyPresentation]::Read($sleep,$c,$m)
Check ($debtView.energy -lt $sleepView.energy) 'Existing sleep debt is hidden by the display'
$sleep.bodyWaterMl=50000;$sleep.energyBalanceKcal=9000
$surplus=[CRBodyPresentation]::Read($sleep,$c,$m)
Check ($surplus.hydration -eq 100 -and $surplus.nutrition -eq 100 -and $sleep.bodyWaterMl -eq 50000 -and $sleep.energyBalanceKcal -eq 9000) 'Meter caps destroyed physical surplus'
$delta=[CRBodyPresentation]::ResolveDelta($true,40,60,41)
Check ($delta -eq 1) 'Legacy positive change can override shared state'
Check ([CRBodyPresentation]::ResolveDelta($true,40,-30,41) -eq 1) 'Legacy depletion double-charged shared state'
Check ([CRBodyPresentation]::ResolveDelta($false,40,20,41) -eq 20) 'Unmanaged need lost legacy behavior'
Check ([CRBodyPresentation]::ResolveDelta($true,40,100,[float]::NaN) -eq 0) 'Invalid projection contaminated cached needs'
Check ([CRBodyPresentation]::ResolveDelta($true,41,100,41) -eq 0) 'Repeated legacy change replayed a refill'
$sleep.bodyWaterMl=[float]::NaN
Check (-not [CRBodyPresentation]::Read($sleep,$c,$m).valid) 'Invalid body read was marked usable'
Check (-not [CRBodyPresentation]::Read($null,$c,$m).valid) 'Missing body read was marked usable'
$m.waterDeficitAtZeroMl=0
Check ($null -eq [CRBodyPresentation]::Migrate($c,$m,50,50,50)) 'Zero meter range migrated'
Write-JsonFile ([ordered]@{testedAtUtc=[DateTime]::UtcNow.ToString('o');passed=$true;assertions=$script:checks;migrationCombinations=128;maximumRoundTripError=$maxError;sources=@($paths|ForEach-Object{[ordered]@{path=$_;sha256=(Get-Sha256 $_)}});scope='Actual pure presentation/migration source translated to C# float32. Meter preservation, absorption, sleep, surplus, invalid values and managed/unmanaged delta policy. Native hooks, UI effects and engine save migration remain untested.'}) (Join-Path $project 'reports/body-presentation-tests.json')
Write-Host "PASS: $script:checks body presentation/migration checks across 128 migration combinations."
