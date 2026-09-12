. "$PSScriptRoot\..\tools\Common.ps1"
. "$PSScriptRoot\CoreHarness.ps1"
$project=Get-ProjectRoot
$paths=@('InjuryModel','BodyModel','SleepModel','BodyInputs','ServingModel','BodyPresentation','BodyForecast')|ForEach-Object{Join-Path $project "src/redscript/CyberpunkRealism/$_.reds"}
Add-Type -TypeDefinition (Convert-RedscriptCore $paths)
$script:checks=0
function Check($condition,$message){if(-not $condition){throw $message};$script:checks++}
function Drain($q,$s,$c){$n=0;while($q.count -gt 0 -and -not $q.faulted -and $n -lt 50){[CRBodyInputs]::Drain($q,$s,$c)|Out-Null;$n++};if($q.faulted -or $q.count -ne 0){throw 'Queue did not drain'}}
$c=[CRBodyConfig]::new();$meters=[CRBodyMeterConfig]::new()
$c.restingWaterLossMlPerHour=0;$c.baselineUrineMlPerHour=0;$c.minimumUrineMlPerHour=0;$c.restingEnergyKcalPerHour=0;$c.injuryMetabolicKcalPerHour=0
$c.injuryExternalClotPerHourSquared=0;$c.injuryBloodRecoveryMlPerHour=0
$s=[CRBodyModel]::Create($c);$q=[CRBodyInputQueue]::new()
[CRBodyInputs]::Time($q,2,0,$false)|Out-Null
[CRBodyInputs]::Injury($q,5,0.4,0.5,0.6,100,50)|Out-Null
[CRBodyInputs]::Time($q,1,0,$false)|Out-Null
[CRBodyInputs]::Treatment($q,5,2,1)|Out-Null
[CRBodyInputs]::Time($q,1,0,$false)|Out-Null
Drain $q $s $c
Check ($q.appliedWounds -eq 1 -and $q.appliedTreatments -eq 1) 'Wound/treatment applied more than once or lost'
Check ([Math]::Abs($s.injuries.bloodLostMl-200) -lt 0.01) 'Bleeding started before the hit or dressing stopped internal bleeding'
Check ([Math]::Abs($s.bloodWaterLostMl-160) -lt 0.01 -and [Math]::Abs($s.waterLostMl-160) -lt 0.01) 'Bleeding water omitted or counted twice'
Check ([Math]::Abs($s.bodyWaterMl+$s.waterLostMl-42000) -lt 1) 'Shared body-water conservation failed'
Check ($s.injuries.leftLeg.externalBleedMlPerHour -eq 0 -and $s.injuries.leftLeg.internalBleedMlPerHour -eq 50) 'Dressing treated the wrong bleeding channel'
Check ($s.injuries.leftLeg.boneDamage -eq 0.5 -and $s.injuries.leftLeg.cyberwareDamage -eq [float]0.6) 'Dressing healed bone/chrome'
Check ($s.injuries.rightLeg.tissueDamage -eq 0 -and $s.injuries.head.tissueDamage -eq 0) 'Localized injury damaged other regions'
$beforeBlood=$s.injuries.bloodLostMl
[CRBodyInputs]::Drain($q,$s,$c)|Out-Null
Check ($s.injuries.bloodLostMl -eq $beforeBlood -and $q.appliedWounds -eq 1) 'Empty queue replayed a wound or interval'
$tissue=$s.injuries.leftLeg.tissueDamage;$bone=$s.injuries.leftLeg.boneDamage;$deficit=$s.injuries.bloodDeficitMl
[CRBodyInputs]::Treatment($q,5,4,1)|Out-Null;Drain $q $s $c
Check ($s.injuries.leftLeg.internalBleedMlPerHour -eq 0 -and $s.injuries.leftLeg.tissueDamage -eq $tissue -and $s.injuries.leftLeg.boneDamage -eq $bone -and $s.injuries.bloodDeficitMl -eq $deficit) 'Clinical care instantly regenerated tissue/bone/blood'
[CRBodyInputs]::Treatment($q,5,5,1)|Out-Null;Drain $q $s $c
Check ($s.injuries.leftLeg.cyberwareDamage -eq 0 -and $s.injuries.leftLeg.tissueDamage -eq $tissue) 'Cyberware service healed biology'
$beforeFunction=[CRInjuryModel]::Function($s.injuries,5)
[CRBodyInputs]::Treatment($q,5,3,1)|Out-Null;Drain $q $s $c
Check ([CRInjuryModel]::Function($s.injuries,5) -gt $beforeFunction -and $s.injuries.leftLeg.boneDamage -eq $bone) 'Support did not help function independently from healing'
[CRInjuryModel]::Wound($s.injuries,5,0,0,0.4,60,0)|Out-Null
Check ($s.injuries.leftLeg.externalBleedMlPerHour -eq 60) 'Old dressing automatically treated a new wound'
[CRInjuryModel]::Treat($s.injuries,5,4,1)|Out-Null
[CRBodyModel]::Advance($s,$c,8,0,$true)|Out-Null
Check ($s.injuries.leftLeg.cyberwareDamage -eq [float]0.4 -and $s.injuries.leftLeg.boneDamage -lt $bone -and $s.injuries.leftLeg.tissueDamage -lt $tissue) 'Sleep repaired chrome or did not progress supported biological recovery'
Check ($s.injuries.leftLeg.boneDamage -gt 0 -and $s.injuries.leftLeg.tissueDamage -gt 0) 'Sleep instantly cleared serious injury'
# Long skips cannot create historical bleeding before a queued hit.
$long=[CRBodyModel]::Create($c);$queue=[CRBodyInputQueue]::new()
[CRBodyInputs]::Time($queue,100,0,$false)|Out-Null
[CRBodyInputs]::Injury($queue,2,0.1,0,0,100,0)|Out-Null
[CRBodyInputs]::Time($queue,1,0,$false)|Out-Null
Drain $queue $long $c
Check ([Math]::Abs($long.injuries.bloodLostMl-100) -lt 0.01 -and $queue.appliedWounds -eq 1) 'Backlog assigned pre-injury hours to bleeding'
# Exact clotting integral across a split interval, with recovery disabled.
$clotConfig=[CRBodyConfig]::new();$clotConfig.injuryBloodRecoveryMlPerHour=0
$a=[CRInjuryModel]::Create();[CRInjuryModel]::Wound($a,3,0.2,0,0,100,0)|Out-Null;$b=[CRInjuryModel]::Copy($a)
$loss=[CRInjuryModel]::Advance($a,$clotConfig,1,0,1,42000)
for($n=0;$n -lt 60;$n++){[CRInjuryModel]::Advance($b,$clotConfig,(1.0/60),0,1,42000)|Out-Null}
Check ([Math]::Abs($loss-50) -lt 0.001 -and [Math]::Abs($a.bloodLostMl-$b.bloodLostMl) -lt 0.01) 'Clotting created partition-dependent blood loss'
# Body available-water and circulating-volume bounds both constrain loss.
$dry=[CRBodyModel]::Create($c);$dry.bodyWaterMl=80
[CRInjuryModel]::Wound($dry.injuries,2,0.1,0,0,0,100000)|Out-Null
[CRBodyModel]::Advance($dry,$c,1,0,$false)|Out-Null
Check ($dry.bodyWaterMl -eq 0 -and [Math]::Abs($dry.injuries.bloodLostMl-100) -lt 0.01) 'Bleeding created negative body water'
$limited=[CRInjuryModel]::Create();[CRInjuryModel]::Wound($limited,2,0.1,0,0,0,100000)|Out-Null
$loss=[CRInjuryModel]::Advance($limited,$c,1,0,0,42000)
Check ($loss -eq 5000 -and $limited.bloodDeficitMl -eq 5000) 'Bleeding exceeded configured blood capacity'
[CRInjuryModel]::Treat($limited,2,4,1)|Out-Null;$recover=[CRBodyConfig]::new()
[CRInjuryModel]::Advance($limited,$recover,3,0,1,42000)|Out-Null
Check ($limited.bloodDeficitMl -eq 4970 -and $limited.bloodRecoveredMl -eq 30 -and [CRInjuryModel]::ValidState($limited)) 'Blood-recovery ledger lost its conservation relation'
# Forecast copied queued injury, then evolves independently from the live body.
$real=[CRBodyModel]::Create($c);$pending=[CRBodyInputQueue]::new()
[CRBodyInputs]::Injury($pending,4,0.3,0.2,0.1,90,30)|Out-Null
$f=[CRBodyForecast]::Create($real,$pending,$c,$meters)
Check ($f.ready -and $f.body.injuries.rightArm.tissueDamage -eq [float]0.3 -and $real.injuries.rightArm.tissueDamage -eq 0 -and $pending.count -eq 1) 'Forecast ignored or committed queued injury'
[CRBodyForecast]::Step($f,1,$false)|Out-Null
Drain $pending $real $c;[CRBodyModel]::Advance($real,$c,1,0,$false)|Out-Null
Check ([Math]::Abs($f.body.injuries.bloodLostMl-$real.injuries.bloodLostMl) -lt 0.001 -and [Math]::Abs($f.body.bodyWaterMl-$real.bodyWaterMl) -lt 0.001) 'Forecast injury progression differs from actual body transitions'
[CRBodyInputs]::Treatment($pending,4,2,1)|Out-Null
$f=[CRBodyForecast]::Create($real,$pending,$c,$meters)
Check ($f.ready -and $f.body.injuries.rightArm.externalBleedMlPerHour -eq 0 -and $real.injuries.rightArm.externalBleedMlPerHour -eq 90) 'Forecast treatment leaked into real wounds'
# Reconstruction preserves separate regions, bleeding, treatment and ledgers.
$options=[System.Text.Json.JsonSerializerOptions]::new();$options.IncludeFields=$true
$json=[System.Text.Json.JsonSerializer]::Serialize($real,[CRBodyState],$options)
$restored=[System.Text.Json.JsonSerializer]::Deserialize($json,[CRBodyState],$options)
Check ([CRInjuryModel]::ValidState($restored.injuries) -and $restored.injuries.rightArm.internalBleedMlPerHour -eq 30) 'Reconstructed state lost injury data'
[CRBodyModel]::Advance($restored,$c,1,0,$false)|Out-Null
[CRBodyModel]::Advance($real,$c,1,0,$false)|Out-Null
Check ([Math]::Abs($restored.injuries.bloodLostMl-$real.injuries.bloodLostMl) -lt 0.001) 'Restored injuries stopped or replayed time'
# Malformed retained nodes/state must fail before advancing queued fractions.
$invalid=[CRBodyModel]::Create($c);[CRBodyModel]::Advance($invalid,$c,0.005,0,$false)|Out-Null
$badQueue=[CRBodyInputQueue]::new();[CRBodyInputs]::Treatment($badQueue,2,2,1)|Out-Null;$badQueue.first.externalBleed=[float]::NaN
[CRBodyInputs]::Drain($badQueue,$invalid,$c)|Out-Null
Check ($badQueue.faulted -and $invalid.elapsedHours -eq 0 -and $invalid.pendingHours -gt 0) 'Malformed medical payload advanced or mutated the body'
$invalid.injuries.head.tissueDamage=[float]::NaN;$water=$invalid.bodyWaterMl
[CRBodyModel]::Advance($invalid,$c,1,0,$false)|Out-Null
Check (-not $invalid.lastAdvanceAccepted -and $invalid.bodyWaterMl -eq $water -and [CRBodyForecast]::CopyBody($invalid) -eq $null) 'Invalid injury state advanced or forecast as healthy'
$alias=[CRInjuryModel]::Create();$alias.torso=$alias.head
Check (-not [CRInjuryModel]::ValidState($alias)) 'Aliased body regions could advance the same wound repeatedly'
Check ([CRInjuryModel]::Function($alias,2) -lt 0 -and [CRInjuryModel]::Function($null,0) -lt 0) 'Invalid injury metadata presented as normal function'
foreach($bad in @(-1,[float]::NaN,[float]::PositiveInfinity)){
 Check (-not [CRBodyInputs]::Injury([CRBodyInputQueue]::new(),2,$bad,0,0,100,0)) 'Invalid wound accepted'
 Check (-not [CRBodyInputs]::Treatment([CRBodyInputQueue]::new(),2,2,$bad)) 'Invalid treatment strength accepted'
}
Check (-not [CRBodyInputs]::Injury([CRBodyInputQueue]::new(),0,0.2,0,0,0,0)) 'Unknown injury region became torso'
Check (-not [CRBodyInputs]::Treatment([CRBodyInputQueue]::new(),2,6,1)) 'Unknown treatment accepted'
# Injured repair has body resource demand; no second depletion clock.
$normalConfig=[CRBodyConfig]::new();$healthy=[CRBodyModel]::Create($normalConfig);$hurt=[CRBodyModel]::Create($normalConfig)
[CRInjuryModel]::Wound($hurt.injuries,3,0.5,0,0,0,0)|Out-Null
[CRBodyModel]::Advance($healthy,$normalConfig,1,0,$false)|Out-Null
[CRBodyModel]::Advance($hurt,$normalConfig,1,0,$false)|Out-Null
Check ($hurt.energyUsedKcal -gt $healthy.energyUsedKcal -and $hurt.elapsedHours -eq $healthy.elapsedHours) 'Tissue recovery disconnected from shared resource use/time'
# Schema migration preserves old needs and existing injuries, exactly once.
$old=[CRBodyModel]::Create($c);$old.injuries=$null;$old.energyBalanceKcal=-123
Check ([CRBodyPresentation]::UpgradeSchema(1,$old,$c,$meters) -eq 2 -and $null -ne $old.injuries -and $old.energyBalanceKcal -eq -123) 'Old body schema migration lost needs or omitted injury state'
[CRInjuryModel]::Wound($old.injuries,1,0.3,0,0,20,10)|Out-Null
Check ([CRBodyPresentation]::UpgradeSchema(2,$old,$c,$meters) -eq 2 -and $old.injuries.head.tissueDamage -eq [float]0.3) 'Repeated migration healed an existing wound'
$missing=[CRBodyModel]::Create($c);$missing.injuries=$null
Check ([CRBodyPresentation]::UpgradeSchema(2,$missing,$c,$meters) -eq -1 -and $null -eq $missing.injuries) 'Missing retained version-2 injury state was recreated as healthy'
Check ([CRBodyPresentation]::UpgradeSchema(3,$old,$c,$meters) -eq -1 -and $old.injuries.head.tissueDamage -eq [float]0.3) 'Unsupported future schema was modified'
$corrupt=[CRBodyModel]::Create($c);$corrupt.bodyWaterMl=[float]::NaN;$corrupt.injuries=$null
Check ([CRBodyPresentation]::UpgradeSchema(1,$corrupt,$c,$meters) -eq -1 -and $null -eq $corrupt.injuries) 'Invalid old state was partially migrated'
[CRBodyModel]::Advance($corrupt,$c,1,0,$false)|Out-Null
Check (-not $corrupt.lastAdvanceAccepted -and $corrupt.elapsedHours -eq 0) 'Invalid water state advanced part of an injury interval'
Write-JsonFile ([ordered]@{testedAtUtc=[DateTime]::UtcNow.ToString('o');passed=$true;assertions=$script:checks;sources=@($paths|ForEach-Object{[ordered]@{path=$_;sha256=(Get-Sha256 $_)}});scope='Actual original injury/body/input/forecast code translated to float32 C#. Localization, treatment separation, chronology, long backlogs, fluid/blood accounting, resource coupling, independent forecasts, reconstruction and invalid data. Native hits, saves, effects, medical interactions and clinical/gameplay calibration remain unverified.'}) (Join-Path $project 'reports/injury-body-tests.json')
Write-Host "PASS: $script:checks injury/body integration checks."
