. "$PSScriptRoot\..\tools\Common.ps1"
. "$PSScriptRoot\CoreHarness.ps1"
$project=Get-ProjectRoot
$paths=@('InjuryModel','BodyModel','SleepModel','BodyInputs','ServingModel','BodyPresentation','BodyForecast')|ForEach-Object{Join-Path $project "src/redscript/CyberpunkRealism/$_.reds"}
Add-Type -TypeDefinition (Convert-RedscriptCore $paths)
$script:checks=0
function Check($condition,$message){if(-not $condition){throw $message};$script:checks++}
$c=[CRBodyConfig]::new();$m=[CRBodyMeterConfig]::new()
$normal=[CRBodyModel]::Create($c);$short=[CRBodyModel]::Create($c)
for($day=0;$day -lt 7;$day++){
 [CRBodyModel]::Advance($normal,$c,16,0,$false)|Out-Null
 if($day -eq 0){Check ($normal.sleepDebtHours -eq 0 -and $normal.sleepPressureHours -gt 15) 'Normal awake time mislabeled as historical sleep debt'}
 [CRBodyModel]::Advance($normal,$c,8,0,$true)|Out-Null
 [CRBodyModel]::Advance($short,$c,18,0,$false)|Out-Null
 [CRBodyModel]::Advance($short,$c,6,0,$true)|Out-Null
}
Check ($normal.sleepDebtHours -lt 0.001 -and $normal.sleepPressureHours -lt 0.001) 'Full nights accumulated debt or residual sleep pressure'
Check ([Math]::Abs($short.sleepDebtHours-14) -lt 0.01) 'Six-hour nights did not accumulate the two-hour daily shortfall'
[CRBodyModel]::Advance($short,$c,14,0,$false)|Out-Null
[CRBodyModel]::Advance($short,$c,10,0,$true)|Out-Null
Check ([Math]::Abs($short.sleepDebtHours-12) -lt 0.01) 'Additional sleep did not repay the recorded shortfall'
$nap=[CRBodyModel]::Create($c)
[CRBodyModel]::Advance($nap,$c,12,0,$false)|Out-Null
[CRBodyModel]::Advance($nap,$c,2,0,$true)|Out-Null
[CRBodyModel]::Advance($nap,$c,4,0,$false)|Out-Null
[CRBodyModel]::Advance($nap,$c,6,0,$true)|Out-Null
Check ($nap.sleepDebtHours -lt 0.001) 'Naps were omitted from daily sleep accounting'
$deprived=[CRBodyModel]::Create($c)
[CRBodyModel]::Advance($deprived,$c,48,0,$false)|Out-Null
Check ([Math]::Abs($deprived.sleepDebtHours-16) -lt 0.001) 'Missed nights did not accumulate configured sleep need'
# Retained daily windows behave identically across arbitrary save-like copying.
$split=[CRBodyModel]::Create($c)
[CRBodyModel]::Advance($split,$c,18,0,$false)|Out-Null
[CRBodyModel]::Advance($split,$c,3,0,$true)|Out-Null
$copy=[CRBodyForecast]::CopyBody($split)
[CRBodyModel]::Advance($copy,$c,3,0,$true)|Out-Null
Check ([Math]::Abs($copy.sleepDebtHours-2) -lt 0.001) 'Window state lost sleep across reconstruction'
$invalid=[CRBodyModel]::Create($c);$invalid.sleepWindowSeconds=86401
Check ([CRBodyModel]::Advance($invalid,$c,1,0,$false) -eq 0 -and -not $invalid.lastAdvanceAccepted) 'Invalid window admitted a non-terminating/negative segment'
$invalid.pendingHours=0.005
Check (-not [CRBodyModel]::CloseInterval($invalid,$c)) 'Fractional interaction path bypassed invalid sleep-window rejection'
# Interactions occur after prior time and do not reset unrelated physiology.
$s=[CRBodyModel]::Create($c);$q=[CRBodyInputQueue]::new()
[CRBodyInputs]::Time($q,8,0,$false)|Out-Null
[CRBodyInputs]::Interact($q,4,1)|Out-Null
[CRBodyInputs]::Time($q,1,0,$false)|Out-Null
while($q.count -gt 0 -and -not $q.faulted){[CRBodyInputs]::Drain($q,$s,$c)|Out-Null}
Check ($q.appliedInteractions -eq 1 -and $s.waterVoidedMl -gt 0 -and $s.bladderMl -gt 0) 'Toilet use ignored order or stopped subsequent bladder filling'
Check ([Math]::Abs($s.bodyWaterMl+$s.bladderMl+$s.waterLostMl+$s.waterVoidedMl-42000) -lt 2) 'Toilet interaction lost water accounting'
$water=$s.bodyWaterMl;$energy=$s.energyBalanceKcal;$s.hygieneLoad=40;$s.bowelGrams=70
[CRBodyInputs]::Interact($q,1,0.5)|Out-Null
[CRBodyInputs]::Drain($q,$s,$c)|Out-Null
Check ($s.hygieneLoad -eq 20 -and $s.bowelGrams -eq 70 -and $s.bodyWaterMl -eq $water -and $s.energyBalanceKcal -eq $energy) 'Washing altered unrelated body state'
[CRBodyInputs]::Interact($q,4,1)|Out-Null
[CRBodyInputs]::Drain($q,$s,$c)|Out-Null
Check ($s.bowelGrams -eq 0 -and $s.residueVoidedGrams -eq 70 -and $s.hygieneLoad -eq 20) 'Toilet use lost residue or silently washed the player'
$voided=$s.waterVoidedMl
[CRBodyInputs]::Drain($q,$s,$c)|Out-Null
Check ($s.waterVoidedMl -eq $voided -and $q.appliedInteractions -eq 3) 'Empty queue replayed an interaction'
Check (-not [CRBodyInputs]::Interact($q,5,1)) 'Unknown interaction accepted'
Check (-not [CRBodyInputs]::Interact($q,1,[float]::NaN)) 'NaN washing accepted'
# Queued bathroom work must be represented by copied forecasts, without touching reality.
$s.hygieneLoad=30;$s.bladderMl=250
[CRBodyInputs]::Interact($q,4,1)|Out-Null
[CRBodyInputs]::Interact($q,1,1)|Out-Null
$f=[CRBodyForecast]::Create($s,$q,$c,$m)
Check ($f.ready -and $f.body.bladderMl -eq 0 -and $f.body.hygieneLoad -eq 0) 'Forecast omitted queued body interactions'
Check ($s.bladderMl -eq 250 -and $s.hygieneLoad -eq 30 -and $q.count -eq 2) 'Forecast performed real bathroom operations'
$q.first.interactionKind=7
Check ([CRBodyInputs]::Drain($q,$s,$c) -eq 0 -and $q.faulted -and $s.bladderMl -eq 250) 'Invalid retained interaction mutated body state'
Write-JsonFile ([ordered]@{testedAtUtc=[DateTime]::UtcNow.ToString('o');passed=$true;assertions=$script:checks;sources=@($paths|ForEach-Object{[ordered]@{path=$_;sha256=(Get-Sha256 $_)}});scope='Actual original sleep/interaction sources translated to C# float32. Daily sleep balance, naps, reconstruction, validation, ordered wash/void operations, conservation and forecast isolation. Native device actions and shower events remain untested.'}) (Join-Path $project 'reports/body-interaction-tests.json')
Write-Host "PASS: $script:checks sleep and body-interaction checks."
