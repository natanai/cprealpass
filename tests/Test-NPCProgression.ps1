. "$PSScriptRoot\InjuryEffectsHarness.ps1"
$script:checks=0
function Check($condition,$message){if(-not $condition){throw $message};$script:checks++}
function Reset { [CREffectsFixture]::Reset() }
function StepClock($clock,$world,$sim,$allowed) {
 $hours=[CRClockModel]::Observe($clock,$world,$sim,$allowed)
 [CREffectsFixture]::runtime.Advance($hours,[CREffectsFixture]::config,$false)
 return $hours
}
Reset;$c=[CREffectsFixture]::config;$npc=[CREffectsFixture]::NPC();$old=$npc.crLocalizedInjuries
$old.leftLeg.boneDamage=0.8;$old.leftLeg.support=0.5;$old.leftArm.cyberwareDamage=0.4;$old.torso.internalBleedMlPerHour=200;$old.bloodLostMl=400;$old.bloodDeficitMl=350;$old.bloodRecoveredMl=50
Check ([CRNPCInjuryBridge]::EnsureBody($npc,$c) -and $npc.crInjurySchemaVersion -eq 2 -and $null -eq $npc.crLocalizedInjuries) 'Migration retained two persistent injury owners'
$state=[CRNPCInjuryBridge]::State($npc)
Check ($state -ne $old -and $state.leftLeg -ne $old.leftLeg -and $state.bloodDeficitMl -eq 350 -and $state.bloodRecoveredMl -eq 50 -and $state.torso.internalBleedMlPerHour -eq 200) 'Migration aliased or erased existing wounds/blood accounting'
$body=$npc.crInjuryBody;$body.bodyWaterMl=37000
Check ([CRNPCInjuryBridge]::EnsureBody($npc,$c) -and $npc.crInjuryBody -eq $body -and $body.bodyWaterMl -eq 37000) 'Repeated migration refilled body water or replaced state'
foreach($case in @('future','missing','ambiguous','bad-blood','bad-body','bad-pending')){
 $n=[CREffectsFixture]::NPC()
 switch($case){
  'future'{$n.crInjurySchemaVersion=3}
  'missing'{$n.crLocalizedInjuries=$null}
  'ambiguous'{$n.crInjuryBody=[CRBodyModel]::Create($c)}
  'bad-blood'{$n.crLocalizedInjuries.bloodDeficitMl=100}
  'bad-body'{[CRNPCInjuryBridge]::EnsureBody($n,$c)|Out-Null;$n.crInjuryBody.bodyWaterMl=[float]::NaN}
  'bad-pending'{[CRNPCInjuryBridge]::EnsureBody($n,$c)|Out-Null;$n.crInjuryBody.pendingHours=[float]::NaN}
 }
 $prior=$n.crInjurySchemaVersion
 Check (-not [CRNPCInjuryBridge]::EnsureBody($n,$c) -and $n.crInjurySchemaVersion -eq $prior) "Invalid NPC state reset: $case"
}
# NPC and V execute the same minute equations with identical resources/context.
Reset;$c=[CREffectsFixture]::config;$npc=[CREffectsFixture]::NPC();$npc.crLocalizedInjuries.leftLeg.externalBleedMlPerHour=600;$npc.crLocalizedInjuries.rightArm.internalBleedMlPerHour=100
$player=[CRNPCBodyModel]::Create($npc.crLocalizedInjuries,$c)
Check ([CRNPCInjuryBridge]::Advance($npc,$c,2,0.7)) 'NPC could not advance accepted time'
[CRBodyModel]::Advance($player,$c,2,0.7,$false)|Out-Null
foreach($field in @('bodyWaterMl','bloodWaterLostMl','energyBalanceKcal','sleepPressureHours','elapsedHours','bladderMl')){
 Check ($npc.crInjuryBody.$field -eq $player.$field) "NPC uses a different body equation: $field"
}
Check ($npc.crInjuryBody.injuries.bloodDeficitMl -eq $player.injuries.bloodDeficitMl -and $npc.crInjuryBody.injuries.leftLeg.externalBleedMlPerHour -lt 600) 'NPC blood/clotting diverged from player body solver'
Check ([Math]::Abs($npc.crInjuryBody.bodyWaterMl+$npc.crInjuryBody.bladderMl+$npc.crInjuryBody.waterLostMl-$c.targetBodyWaterMl) -lt 2) 'Bleeding/renal losses did not conserve NPC water'
Check ($npc.crInjuryBody.bloodWaterLostMl -gt 0 -and $npc.crInjuryBody.energyUsedKcal -gt 0) 'NPC bleeding/healing used no tracked body resources'
# New wounds cannot bleed through fractional time before they were received.
Reset;$c=[CREffectsFixture]::config;$c.injuryExternalClotPerHourSquared=0;$c.injuryBloodRecoveryMlPerHour=0
$npc=[CREffectsFixture]::NPC();$npc.crLocalizedInjuries.leftLeg.externalBleedMlPerHour=100
[CRNPCInjuryBridge]::Advance($npc,$c,(10/3600),0)|Out-Null
$w=[CRImpactWound]::new();$w.valid=$true;$w.region=3;$w.tissueDamage=0.1;$w.externalBleedMlPerHour=500
Check ([CRNPCInjuryBridge]::Commit($npc,$w)) 'Accepted later wound rejected'
Check ([Math]::Abs($npc.crInjuryBody.injuries.bloodLostMl-(100*10/3600)) -lt 0.00001 -and $npc.crInjuryBody.pendingHours -eq 0) 'New wound was applied before earlier fractional time'
[CRNPCInjuryBridge]::Advance($npc,$c,(10/3600),0)|Out-Null
[CRNPCBodyModel]::BeforeEvent($npc.crInjuryBody,$c)|Out-Null
Check ([Math]::Abs($npc.crInjuryBody.injuries.bloodLostMl-(700*10/3600)) -lt 0.00001) 'Subsequent time omitted the new bleed source'
# Registration observes existing actors before the newcomer joins the interval.
Reset;$c=[CREffectsFixture]::config;$r=[CREffectsFixture]::runtime;$first=[CREffectsFixture]::NPC();$r.Register($first)|Out-Null
[CRBodyRuntime]::pendingHours=1
$new=[CREffectsFixture]::NPC();$r.Register($new)|Out-Null
Check ($first.crInjuryBody.elapsedHours -eq 1 -and $null -eq $new.crInjuryBody) 'New registration received time from before it existed'
# Shared clock boundaries: menu, reload/rebase, skips and repeated completion.
$clock=[CRClockState]::new()
StepClock $clock 100 1 $true|Out-Null
StepClock $clock 160 8.5 $true|Out-Null
$elapsed=$first.crInjuryBody.elapsedHours
Check ($elapsed -gt 1) 'Ordinary accepted clock time did not reach NPCs'
StepClock $clock 220 16 $false|Out-Null
StepClock $clock 400 38 $false|Out-Null
StepClock $clock 460 46 $true|Out-Null
Check ($first.crInjuryBody.elapsedHours -eq $elapsed) 'Menu/boundary time advanced NPCs'
[CRClockModel]::Reset($clock,10000,1,$true)
Check ((StepClock $clock 10000 1 $true) -eq 0 -and $first.crInjuryBody.elapsedHours -eq $elapsed) 'Restored observation replayed offline time'
[CRClockModel]::BeginSkip($clock,10000,1)
StepClock $clock 13600 2 $true|Out-Null
Check ($first.crInjuryBody.elapsedHours -eq $elapsed) 'Pending skip was counted as ordinary time'
$hours=[CRClockModel]::FinishSkip($clock,13600,2,1);$r.Advance($hours,$c,$true)
Check ([Math]::Abs($first.crInjuryBody.elapsedHours-$elapsed-1) -lt 0.00001 -and $first.crInjuryBody.sleepWindowSleepSeconds -eq 0) 'Confirmed skip omitted NPC time or pretended the NPC slept'
$before=$first.crInjuryBody.elapsedHours;$r.Advance([CRClockModel]::FinishSkip($clock,13600,2,1),$c,$true)
Check ($first.crInjuryBody.elapsedHours -eq $before) 'Repeated skip completion advanced NPCs twice'
# Per-actor protected scenes suppress intervals without catch-up on exit.
[CREffectsFixture]::game.scene.script.actors.Add($first.id)|Out-Null
$r.Advance(1,$c,$false)
Check ($first.crInjuryBody.elapsedHours -eq $before -and $new.crInjuryBody.elapsedHours -gt 1) 'Scene protection failed or froze unrelated actors'
[CREffectsFixture]::game.scene.script.actors.Remove($first.id)|Out-Null
$r.Advance(1,$c,$false)
Check ($first.crInjuryBody.elapsedHours -eq $before) 'Scene exit retroactively simulated the protected interval'
$r.Advance(1,$c,$false)
Check ($first.crInjuryBody.elapsedHours -eq $before+1) 'NPC did not resume after the scene boundary'
# Own velocity, mounted motion exclusion, and no sprint extrapolation through skips.
Reset;$c=[CREffectsFixture]::config;$r=[CREffectsFixture]::runtime;$walking=[CREffectsFixture]::NPC();$mounted=[CREffectsFixture]::NPC()
$walking.velocity=7;$mounted.velocity=7;$mounted.mounted=$true;$r.Register($walking)|Out-Null;$r.Register($mounted)|Out-Null
$r.Advance(1,$c,$false)
Check ($walking.crInjuryBody.energyUsedKcal -gt $mounted.crInjuryBody.energyUsedKcal -and $walking.crInjuryBody.waterLostMl -gt $mounted.crInjuryBody.waterLostMl) 'NPC exertion used vehicle speed or ignored walking speed'
$e1=$walking.crInjuryBody.energyUsedKcal;$e2=$mounted.crInjuryBody.energyUsedKcal
$r.Advance(1,$c,$true)
Check ([Math]::Abs(($walking.crInjuryBody.energyUsedKcal-$e1)-($mounted.crInjuryBody.energyUsedKcal-$e2)) -lt 0.1) 'Time skip extrapolated prior sprinting through unobserved hours'
# Save-like reconstruction retains pending context and body/injury identity.
$body=$walking.crInjuryBody
[CRNPCBodyModel]::Advance($body,$c,0.005,0.4)|Out-Null
$copy=[CREffectsFixture]::Reconstruct($body)
Check ($copy -ne $body -and $copy.injuries -ne $body.injuries -and $copy.pendingHours -eq $body.pendingHours) 'Graph reconstruction lost fractional time or retained aliases'
[CRNPCBodyModel]::Advance($body,$c,0.125,0.6)|Out-Null;[CRNPCBodyModel]::Advance($copy,$c,0.125,0.6)|Out-Null
Check ($copy.bodyWaterMl -eq $body.bodyWaterMl -and $copy.energyBalanceKcal -eq $body.energyBalanceKcal -and $copy.injuries.leftLeg.tissueDamage -eq $body.injuries.leftLeg.tissueDamage) 'Reconstructed NPC diverged from uninterrupted progression'
# Long skips and context boundaries retain the last minute rather than dropping it.
$long=[CRNPCBodyModel]::Create([CREffectsFixture]::Injured(),$c)
[CRNPCBodyModel]::Advance($long,$c,0.005,0)|Out-Null
Check ([CRNPCBodyModel]::Advance($long,$c,72,0) -and [CRNPCBodyModel]::Advance($long,$c,0.005,1) -and [CRNPCBodyModel]::BeforeEvent($long,$c)) 'Long bounded skip could not drain into a new context'
Check ([Math]::Abs($long.elapsedHours-72.01) -lt 0.0001) 'Long skip lost retained fractional time'
$before=$long.elapsedHours
Check (-not [CRNPCBodyModel]::Advance($long,$c,[float]::NaN,0) -and -not [CRNPCBodyModel]::Advance($long,$c,73,0) -and $long.elapsedHours -eq $before) 'Invalid interval modified NPC state'
# Bridge failures are inspectable and do not erase malformed saved state.
$walking.crInjuryBody.pendingHours=[float]::NaN;$r.Advance(0.1,$c,$false)
Check ($r.lastProgressFailures -eq 1 -and [float]::IsNaN($walking.crInjuryBody.pendingHours)) 'Malformed progression was hidden or reset'
Write-JsonFile ([ordered]@{testedAtUtc=[DateTime]::UtcNow.ToString('o');passed=$true;assertions=$script:checks;scope='Actual shared clock, NPC body model, NPC migration/commit and registry advancement methods with native actor fixtures. Conservation, V parity, event order, migration, graph reconstruction, scene/menu/skip boundaries and own exertion tested. Actual callbacks, native save serialization, AI self-care and performance remain unverified.';sources=@('NPCBodyModel','BodyRuntime','CombatWoundsNative','InjuryEffectsNative','ClockModel'|ForEach-Object{[ordered]@{path=$_;sha256=Get-Sha256 (Join-Path $project "src/redscript/CyberpunkRealism/$_.reds")}})}) (Join-Path $project 'reports/npc-progression-tests.json')
Write-Host "PASS: $script:checks NPC migration/shared-clock/body-progression checks."