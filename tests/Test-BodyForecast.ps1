. "$PSScriptRoot\..\tools\Common.ps1"
. "$PSScriptRoot\CoreHarness.ps1"
$project=Get-ProjectRoot
$paths=@('InjuryModel','BodyModel','SleepModel','BodyInputs','ServingModel','BodyPresentation','BodyForecast')|ForEach-Object{Join-Path $project "src/redscript/CyberpunkRealism/$_.reds"}
Add-Type -TypeDefinition (Convert-RedscriptCore $paths)
$script:checks=0
function Check($condition,$message){if(-not $condition){throw $message};$script:checks++}
$options=[System.Text.Json.JsonSerializerOptions]::new();$options.IncludeFields=$true
function Body-Json($body){[System.Text.Json.JsonSerializer]::Serialize($body,[CRBodyState],$options)}
function Queue-Json($queue){[System.Text.Json.JsonSerializer]::Serialize($queue,[CRBodyInputQueue],$options)}
$c=[CRBodyConfig]::new();$m=[CRBodyMeterConfig]::new()
$s=[CRBodyPresentation]::Migrate($c,$m,60,70,50);$q=[CRBodyInputQueue]::new()
[CRBodyModel]::Ingest($s,300,400,35)|Out-Null
[CRBodyModel]::Advance($s,$c,0.5/60,0.5,$false)|Out-Null
$s.injuries.leftArm.cyberwareDamage=0.4
$copy=[CRBodyForecast]::CopyBody($s)
Check ((Body-Json $s) -eq (Body-Json $copy)) 'Forecast copy omitted a scalar or nested injury field'
Check (-not [Object]::ReferenceEquals($s.injuries,$copy.injuries)) 'Forecast aliases the live injury object'
foreach($region in @('head','torso','leftArm','rightArm','leftLeg','rightLeg')){
 if([Object]::ReferenceEquals($s.injuries.$region,$copy.injuries.$region)){throw 'Forecast aliases a live regional injury'}
}
$copy.injuries.leftArm.cyberwareDamage=0.8
Check ($s.injuries.leftArm.cyberwareDamage -eq [float]0.4) 'Forecast mutation changed a live injury'
Check (-not [Object]::ReferenceEquals($s,$copy)) 'Forecast aliases the live body'
$bodyBefore=Body-Json $s;$queueBefore=Queue-Json $q
$f=[CRBodyForecast]::Create($s,$q,$c,$m)
Check $f.ready 'Ordinary body forecast unavailable'
$serving=[CRServingModel]::Resolve($true,$false,3)
Check ([CRBodyForecast]::AddServing($f,$serving)) 'Known serving rejected'
$result=[CRBodyForecast]::Step($f,1,$false)
Check $result.valid 'One-hour serving projection invalid'
Check ((Body-Json $s) -eq $bodyBefore -and (Queue-Json $q) -eq $queueBefore) 'Hover forecast modified body or queued inputs'
# Forecast and actual intake must follow exactly the same time/absorption path.
$real=[CRBodyForecast]::CopyBody($s);$realQueue=[CRBodyInputQueue]::new()
[CRBodyInputs]::Intake($realQueue,$serving.waterMl,$serving.energyKcal,$serving.residueGrams)|Out-Null
[CRBodyInputs]::Time($realQueue,1,0,$false)|Out-Null
while($realQueue.count -gt 0){[CRBodyInputs]::Drain($realQueue,$real,$c)|Out-Null}
$actual=[CRBodyPresentation]::Read($real,$c,$m)
Check ([Math]::Abs($result.hydration-$actual.hydration) -lt 0.001 -and [Math]::Abs($result.nutrition-$actual.nutrition) -lt 0.001 -and [Math]::Abs($result.energy-$actual.energy) -lt 0.001) 'Inventory forecast differs from actual intake plus one hour at rest'
foreach($sleeping in @($false,$true)){
 foreach($hours in @(1,8,24)){
  $f=[CRBodyForecast]::Create($s,$q,$c,$m)
  for($i=0;$i -lt $hours*12;$i++){ $preview=[CRBodyForecast]::Step($f,1.0/12,$sleeping) }
  $real=[CRBodyForecast]::CopyBody($s)
  [CRBodyModel]::Advance($real,$c,$hours,0,$sleeping)|Out-Null
  $actual=[CRBodyPresentation]::Read($real,$c,$m)
  Check ($preview.valid -and [Math]::Abs($preview.hydration-$actual.hydration) -lt 0.05 -and [Math]::Abs($preview.nutrition-$actual.nutrition) -lt 0.05 -and [Math]::Abs($preview.energy-$actual.energy) -lt 0.05) "Menu iterations and actual skip disagree: sleep=$sleeping hours=$hours preview=$($preview.hydration),$($preview.nutrition),$($preview.energy) actual=$($actual.hydration),$($actual.nutrition),$($actual.energy) elapsed=$($f.body.elapsedHours),$($real.elapsedHours) pending=$($f.body.pendingHours),$($real.pendingHours)"
 }
}
Check ((Body-Json $s) -eq $bodyBefore) 'Repeated sleep previews changed current body state'
# A bounded pending queue is included, on a deep copy, before future time starts.
$q=[CRBodyInputQueue]::new()
[CRBodyInputs]::Time($q,1,0,$false)|Out-Null
[CRBodyInputs]::Intake($q,500,0,0)|Out-Null
$queueBefore=Queue-Json $q
$f=[CRBodyForecast]::Create($s,$q,$c,$m)
Check ($f.ready -and $f.body.gutWaterMl -eq 500) 'Forecast ignored pending earlier intake/time'
Check ((Queue-Json $q) -eq $queueBefore -and (Body-Json $s) -eq $bodyBefore) 'Forecast drained the real queue'
$q=[CRBodyInputQueue]::new()
[CRBodyInputs]::Time($q,180,0,$false)|Out-Null
[CRBodyInputs]::Intake($q,500,0,0)|Out-Null
$queueBefore=Queue-Json $q
$f=[CRBodyForecast]::Create($s,$q,$c,$m)
Check (-not $f.ready -and (Queue-Json $q) -eq $queueBefore) 'Oversized backlog silently omitted or processed unboundedly'
$q.faulted=$true
Check (-not [CRBodyForecast]::Create($s,$q,$c,$m).ready) 'Faulted input queue produced a usable forecast'
$q=[CRBodyInputQueue]::new();$q.count=1;$q.first=[CRBodyInput]::new();$q.first.next=$q.first
Check (-not [CRBodyForecast]::Create($s,$q,$c,$m).ready) 'Cyclic queue was followed without a bound'
$q=[CRBodyInputQueue]::new()
$f=[CRBodyForecast]::Create($s,$q,$c,$m)
Check (-not [CRBodyForecast]::Step($f,[float]::NaN,$false).valid -and -not $f.ready) 'Invalid forecast duration accepted'
$f=[CRBodyForecast]::Create($s,$q,$c,$m)
Check (-not [CRBodyForecast]::AddServing($f,[CRServing]::new())) 'Unknown item invented a serving'
Write-JsonFile ([ordered]@{testedAtUtc=[DateTime]::UtcNow.ToString('o');passed=$true;assertions=$script:checks;copiedBodyFields=[CRBodyState].GetFields().Count;sources=@($paths|ForEach-Object{[ordered]@{path=$_;sha256=(Get-Sha256 $_)}});scope='Actual original forecast sources translated to C# float32. Deep-copy isolation, pending input inclusion, bounded malformed/backlog handling and prediction-vs-transition equality. UI layout and native menu hooks are not exercised.'}) (Join-Path $project 'reports/body-forecast-tests.json')
Write-Host "PASS: $script:checks body forecast checks."
