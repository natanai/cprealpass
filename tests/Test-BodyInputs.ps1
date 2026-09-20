. "$PSScriptRoot\..\tools\Common.ps1"
. "$PSScriptRoot\CoreHarness.ps1"
$project=Get-ProjectRoot
$paths=@('InjuryModel','BodyModel','SleepModel','BodyInputs','ServingModel')|ForEach-Object{Join-Path $project "src/redscript/CyberpunkRealism/$_.reds"}
Add-Type -TypeDefinition (Convert-RedscriptCore $paths)
$script:checks=0
function Check($condition,$message){if(-not $condition){throw $message};$script:checks++}
function Drain-All($queue,$state,$config){
  $pumps=0
  while($queue.count -gt 0 -and -not $queue.faulted -and $pumps -lt 100){[CRBodyInputs]::Drain($queue,$state,$config)|Out-Null;$pumps++}
  Check ($queue.count -eq 0 -and -not $queue.faulted) 'Ordered input queue did not finish'
}
$c=[CRBodyConfig]::new();$s=[CRBodyModel]::Create($c);$q=[CRBodyInputQueue]::new()
Check ([CRBodyInputs]::Time($q,180,0,$false)) 'Long elapsed event rejected'
Check ([CRBodyInputs]::Intake($q,500,650,35)) 'Meal rejected'
Check ([CRBodyInputs]::Time($q,8,0,$true)) 'Sleep event rejected'
[CRBodyInputs]::Drain($q,$s,$c)|Out-Null
Check ($s.elapsedHours -lt 72.1 -and $s.pendingHours -gt 107 -and $q.count -eq 3) 'First pump exceeded time bound or dropped input'
Check ($s.gutWaterMl -eq 0 -and $q.appliedIntakes -eq 0 -and $q.first.submitted) 'Meal applied before older time'
# Serialize submitted queue and body through a separate test serializer. This checks
# retained data/ordering, NOT redscript engine save serialization (still a runtime gate).
$options=[System.Text.Json.JsonSerializerOptions]::new();$options.IncludeFields=$true
$queueJson=[System.Text.Json.JsonSerializer]::Serialize($q,[CRBodyInputQueue],$options)
$bodyJson=[System.Text.Json.JsonSerializer]::Serialize($s,[CRBodyState],$options)
$q=[System.Text.Json.JsonSerializer]::Deserialize($queueJson,[CRBodyInputQueue],$options)
$s=[System.Text.Json.JsonSerializer]::Deserialize($bodyJson,[CRBodyState],$options)
[CRBodyInputs]::Drain($q,$s,$c)|Out-Null
Check ($s.elapsedHours -gt 143.8 -and $s.elapsedHours -lt 144.2 -and $q.appliedIntakes -eq 0) 'Submitted time replayed after reconstruction or meal applied too early'
[CRBodyInputs]::Drain($q,$s,$c)|Out-Null
Check ($q.appliedIntakes -eq 1 -and $s.gutWaterMl -eq 500 -and $s.gutEnergyKcal -eq 650) 'Meal not applied once after backlog'
Drain-All $q $s $c
Check ([Math]::Abs($s.elapsedHours+$s.pendingHours-188) -lt 0.2) 'Elapsed time lost during activity transition'
Check ($q.acceptedIntakes -eq 1 -and $q.appliedIntakes -eq 1 -and $null -eq $q.first) 'Queue replayed meal or retained detached references'
$energy=$s.energyBalanceKcal
[CRBodyInputs]::Drain($q,$s,$c)|Out-Null
Check ($s.energyBalanceKcal -eq $energy -and $q.appliedIntakes -eq 1) 'Empty queue changed state'
# An intake boundary must settle even sub-minute time before depositing a meal.
$s=[CRBodyModel]::Create($c);$q=[CRBodyInputQueue]::new()
[CRBodyInputs]::Time($q,0.5/60,0,$false)|Out-Null
[CRBodyInputs]::Intake($q,330,125,8)|Out-Null
Drain-All $q $s $c
Check ($s.gutWaterMl -eq 330 -and $s.gutEnergyKcal -eq 125 -and $s.colonResidueGrams -eq 0) 'New meal absorbed retroactively in fractional interval'
Check ($s.energyUsedKcal -gt 0 -and $s.pendingHours -eq 0) 'Time before meal was discarded'
# Two rapid legitimate uses of the same item must both count; no time-based debounce.
[CRBodyInputs]::Intake($q,330,125,8)|Out-Null
[CRBodyInputs]::Intake($q,330,125,8)|Out-Null
Drain-All $q $s $c
Check ($q.appliedIntakes -eq 3 -and $s.gutWaterMl -eq 990) 'Rapid legitimate consumption was deduplicated'
Check (-not [CRBodyInputs]::Intake($q,[float]::NaN,0,0)) 'NaN intake accepted'
Check (-not [CRBodyInputs]::Time($q,8,[float]::NaN,$false)) 'NaN exertion accepted'
Check (-not [CRBodyInputs]::Time($q,-1,0,$false)) 'Negative elapsed time accepted'
Check ($q.count -eq 0 -and $q.acceptedIntakes -eq 3) 'Rejected event mutated queue'
# Old backlog predating the queue cannot cause a new context to be dropped.
$s=[CRBodyModel]::Create($c);$q=[CRBodyInputQueue]::new()
[CRBodyModel]::Advance($s,$c,240,1,$false)|Out-Null
[CRBodyInputs]::Time($q,8,0,$true)|Out-Null
Drain-All $q $s $c
Check ([Math]::Abs($s.elapsedHours+$s.pendingHours-248) -lt 0.3) 'Pre-existing long backlog lost new sleep event'
# Short bursts are bounded separately from the expensive time integration.
$s=[CRBodyModel]::Create($c);$q=[CRBodyInputQueue]::new()
for($i=0;$i -lt 40;$i++){[CRBodyInputs]::Intake($q,1,0,0)|Out-Null}
$count=[CRBodyInputs]::Drain($q,$s,$c)
Check ($count -eq 32 -and $q.count -eq 8 -and $s.gutWaterMl -eq 32) 'Event pump is unbounded or loses burst events'
Drain-All $q $s $c
Check ($s.gutWaterMl -eq 40 -and $q.appliedIntakes -eq 40) 'Burst remainder lost'
# New events appended to a reconstructed pending chain must remain reachable.
$s=[CRBodyModel]::Create($c);$q=[CRBodyInputQueue]::new()
[CRBodyInputs]::Time($q,180,0,$false)|Out-Null
[CRBodyInputs]::Intake($q,100,0,0)|Out-Null
[CRBodyInputs]::Drain($q,$s,$c)|Out-Null
$queueJson=[System.Text.Json.JsonSerializer]::Serialize($q,[CRBodyInputQueue],$options)
$q=[System.Text.Json.JsonSerializer]::Deserialize($queueJson,[CRBodyInputQueue],$options)
[CRBodyInputs]::Intake($q,200,0,0)|Out-Null
Drain-All $q $s $c
Check ($q.appliedIntakes -eq 2 -and $s.gutWaterMl -eq 300) 'Appending after reconstruction disconnected new intake'
$water=[CRServingModel]::Resolve($true,$true,0)
$drink=[CRServingModel]::Resolve($true,$false,0)
$meal=[CRServingModel]::Resolve($false,$false,3)
$unknown=[CRServingModel]::Resolve($false,$false,0)
Check ($water.recognized -and $water.waterMl -eq 500 -and $water.energyKcal -eq 0) 'Water mapping wrong'
Check ($drink.waterMl -eq 330 -and $drink.residueGrams -eq 0) 'Drink serving wrong'
Check ($meal.energyKcal -eq 650 -and $meal.waterMl -gt 0 -and $meal.residueGrams -gt 0) 'Meal lacks connected physical inputs'
Check (-not $unknown.recognized -and $unknown.waterMl -eq 0 -and $unknown.energyKcal -eq 0) 'Unknown item manufactured nourishment'
Write-JsonFile ([ordered]@{testedAtUtc=[DateTime]::UtcNow.ToString('o');passed=$true;assertions=$script:checks;sources=@($paths|ForEach-Object{[ordered]@{path=$_;sha256=(Get-Sha256 $_)}});scope='Actual original sources translated to C# float32. Ordered long skips/intake, fractional boundaries, event replay, bounded pumping and data reconstruction. Engine callbacks, TweakDB mapping and game saves remain untested.'}) (Join-Path $project 'reports/body-input-tests.json')
Write-Host "PASS: $script:checks ordered body-input checks."
