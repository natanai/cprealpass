. "$PSScriptRoot\InjuryEffectsHarness.ps1"
$script:checks=0
function Check($condition,$message){if(-not $condition){throw $message};$script:checks++}
function Reset { [CREffectsFixture]::Reset() }
function Value($object,$stat) { [CREffectsFixture]::game.stats.Value($object.id,$stat) }
Reset
$c=[CRBodyConfig]::new();$healthy=[CRInjuryModel]::Create()
$e=[CRInjuryEffectsModel]::Read($healthy,$c)
Check ($e.valid -and $e.speed -eq 1 -and $e.stamina -eq 1 -and $e.reload -eq 1 -and $e.recoil -eq 1 -and $e.spread -eq 1) 'Healthy state is not neutral'
$leg=[CRInjuryModel]::Create();$leg.leftLeg.boneDamage=0.8
$before=[CRInjuryEffectsModel]::Read($leg,$c)
Check ($before.speed -lt 1 -and $before.reload -eq 1 -and $before.spread -eq 1) 'Leg injury altered weapon handling'
[CRInjuryModel]::Treat($leg,5,3,1)|Out-Null
$after=[CRInjuryEffectsModel]::Read($leg,$c)
Check ($after.speed -gt $before.speed -and $after.speed -lt 1 -and [Math]::Abs($leg.leftLeg.boneDamage-0.8) -lt 0.00001) 'Support failed to improve function or instantly healed bone'
$arm=[CRInjuryModel]::Create();$arm.rightArm.cyberwareDamage=0.8
$e=[CRInjuryEffectsModel]::Read($arm,$c)
Check ($e.speed -eq 1 -and $e.reload -gt 1 -and $e.spread -gt 1 -and $arm.rightArm.externalBleedMlPerHour -eq 0) 'Mechanical arm impairment caused leg damage or bleeding'
[CRInjuryModel]::Treat($arm,4,3,1)|Out-Null
Check ([CRInjuryEffectsModel]::Read($arm,$c).reload -eq $e.reload) 'Bone support repaired damaged cyberware'
foreach($region in 1..6){
 $s=[CRInjuryModel]::Create();$prev=[CRInjuryEffectsModel]::Read($s,$c)
 foreach($percent in 1..100){
  [CRInjuryModel]::Region($s,$region).tissueDamage=$percent/100
  $e=[CRInjuryEffectsModel]::Read($s,$c)
  Check ($e.valid -and $e.speed -le $prev.speed -and $e.stamina -le $prev.stamina -and $e.reload -ge $prev.reload -and $e.recoil -ge $prev.recoil -and $e.spread -ge $prev.spread) 'Increasing regional injury improved ability'
  Check ($e.speed -ge 0.2 -and $e.stamina -ge 0.15 -and $e.staminaRegen -ge 0.15 -and $e.reload -le 3 -and $e.recoil -le 3 -and $e.spread -le 4) 'Regional impairment exceeded bounded gameplay response'
  $prev=$e
 }
}
$s=[CRInjuryModel]::Create();$prev=[CRInjuryEffectsModel]::Read($s,$c)
foreach($loss in 0..50){
 $s.bloodLostMl=$loss*100;$s.bloodDeficitMl=$s.bloodLostMl
 $e=[CRInjuryEffectsModel]::Read($s,$c)
 Check ($e.valid -and $e.speed -le $prev.speed -and $e.stamina -le $prev.stamina -and $e.reload -ge $prev.reload) 'Progressive blood loss improved function or became invalid'
 $prev=$e
}
$s.bloodRecoveredMl=$s.bloodLostMl;$s.bloodDeficitMl=0
Check ([CRInjuryEffectsModel]::Read($s,$c).speed -eq 1) 'Recovered blood did not restore function'
$s.head.tissueDamage=[float]::NaN
Check (-not [CRInjuryEffectsModel]::Read($s,$c).valid) 'Invalid injury produced native effects'
Check (-not [CRInjuryEffectsModel]::Read($null,$c).valid -and -not [CRInjuryEffectsModel]::Read($healthy,$null).valid) 'Missing state/config accepted'
# Exact ownership: ordinary perks/modifiers must survive every cleanup.
Reset;$actor=[CREffectsFixture]::game.playerSystem.player;$stats=[CREffectsFixture]::game.stats
$foreign=[RPGManager]::CreateStatModifier('MaxSpeed','Multiplier',1.2);$stats.AddModifier($actor.id,$foreign)|Out-Null
$slot=[CRInjuryModifierSlot]::new()
Check ($slot.Sync($actor,'MaxSpeed',0.5) -and $stats.Count($actor.id) -eq 2) 'Owned modifier was not added alongside foreign modifier'
$adds=$stats.addAttempts
foreach($i in 1..20){Check ($slot.Sync($actor,'MaxSpeed',0.5)) 'Unchanged sync failed'}
Check ($stats.addAttempts -eq $adds -and [Math]::Abs((Value $actor 'MaxSpeed')-0.6) -lt 0.00001) 'Repeated refresh stacked impairment'
Check ($slot.Sync($actor,'MaxSpeed',0.75) -and $stats.Count($actor.id) -eq 2 -and [Math]::Abs((Value $actor 'MaxSpeed')-0.9) -lt 0.00001) 'Changing severity stacked instead of replacing'
$stats.failRemove=$true;$adds=$stats.addAttempts
Check (-not $slot.Sync($actor,'MaxSpeed',0.25) -and $stats.addAttempts -eq $adds -and $stats.Count($actor.id) -eq 2) 'Failed removal added a replacement'
Check (-not $slot.Clear()) 'Failed removal dropped its retained handle'
$stats.failRemove=$false
Check ($slot.Clear() -and $stats.Count($actor.id) -eq 1 -and $stats.active[$actor.id].Contains($foreign)) 'Retry failed or removed another mod'
$stats.failAdd=$true
Check (-not $slot.Sync($actor,'MaxSpeed',0.5) -and $slot.Clear() -and $stats.Count($actor.id) -eq 1) 'Failed add retained a nonexistent modifier'
$stats.failAdd=$false
$slot.Sync($actor,'MaxSpeed',0.5)|Out-Null
Check ($slot.Sync($actor,'MaxSpeed',[float]::NaN) -and $stats.Count($actor.id) -eq 1) 'Invalid factor kept or installed a modifier'
# Whole actor/weapon bundle, swaps and recovery.
Reset;$actor=[CREffectsFixture]::game.playerSystem.player;$stats=[CREffectsFixture]::game.stats;$injury=[CREffectsFixture]::Injured()
Check ([CRInjuryEffectsBridge]::Apply($actor,$injury,$c,$true) -and $stats.Count($actor.id) -eq 3 -and $stats.Count($actor.weapon.id) -eq 8) 'Actor/weapon bundle incomplete'
Check ((Value $actor.weapon 'SpreadAdsDefaultX') -gt 1 -and (Value $actor.weapon 'RecoilKickMax') -gt 1) 'Aimed spread or kick omitted'
$old=$actor.weapon;$actor.weapon=[WeaponObject]::new()
Check ([CRInjuryEffectsBridge]::Apply($actor,$injury,$c,$true) -and $stats.Count($old.id) -eq 0 -and $stats.Count($actor.weapon.id) -eq 8) 'Weapon swap left penalties on prior weapon'
$old=$actor.weapon;$actor.weapon=$null
Check ([CRInjuryEffectsBridge]::Apply($actor,$injury,$c,$true) -and $stats.Count($old.id) -eq 0 -and $stats.Count($actor.id) -eq 3) 'Unequipping erased actor penalties or retained weapon penalties'
Check ([CRInjuryEffectsBridge]::Apply($actor,$healthy,$c,$true) -and $stats.Count($actor.id) -eq 0) 'Recovery failed to remove actor impairment'
foreach($case in @('disabled','scene','dead','defeated','detached','replacer','invalid')){
 Reset;$actor=[CREffectsFixture]::game.playerSystem.player;$stats=[CREffectsFixture]::game.stats;$injury=[CREffectsFixture]::Injured();$enabled=$true
 [CRInjuryEffectsBridge]::Apply($actor,$injury,$c,$true)|Out-Null
 switch($case){
  'disabled'{$enabled=$false}
  'scene'{[CREffectsFixture]::game.scene.script.actors.Add($actor.id)|Out-Null}
  'dead'{$actor.dead=$true}
  'defeated'{$actor.defeated=$true}
  'detached'{$actor.attached=$false}
  'replacer'{$actor.replacer=$true}
  'invalid'{$injury.head.tissueDamage=[float]::NaN}
 }
 Check ([CRInjuryEffectsBridge]::Apply($actor,$injury,$c,$enabled) -and $stats.Count($actor.id) -eq 0 -and $stats.Count($actor.weapon.id) -eq 0) "Protected/disabled context retained impairment: $case"
}
# Registry lifecycle is bounded; cleanup failure stays retryable and counted.
Reset;$r=[CREffectsFixture]::runtime;$stats=[CREffectsFixture]::game.stats;$npc=[CREffectsFixture]::NPC();$body=[CRBodyModel]::Create($c);$body.injuries=[CREffectsFixture]::Injured()
Check ($r.Register($npc) -and $r.Register($npc) -and $r.npcs.Count -eq 1) 'NPC registered twice'
$r.Refresh($body,$c,$true)
Check ($stats.Count($npc.id) -eq 3 -and $r.lastRefreshFailures -eq 0) 'Registered NPC did not receive impairment'
$npc.dead=$true;$stats.failRemove=$true
$r.Refresh($body,$c,$true)
Check ($r.npcs.Count -eq 1 -and $r.lastRefreshFailures -eq 1) 'Failed dead-actor cleanup was forgotten or hidden'
$stats.failRemove=$false;$r.Refresh($body,$c,$true)
Check ($r.npcs.Count -eq 0 -and $stats.Count($npc.id) -eq 0 -and $stats.Count($npc.weapon.id) -eq 0) 'Dead actor occupied registry after successful cleanup'
$npc=[CREffectsFixture]::NPC();$r.Register($npc)|Out-Null;$r.Refresh($body,$c,$true);$r.Suspend()
Check ($r.npcs.Count -eq 1 -and $stats.Count($npc.id) -eq 0 -and $stats.Count([CREffectsFixture]::game.playerSystem.player.id) -eq 0) 'Suspend forgot live NPCs or retained penalties'
$r.Refresh($body,$c,$true)
Check ($stats.Count($npc.id) -eq 3) 'Resume failed to reconstruct impairment'
$npc.crInjurySchemaVersion=3;$r.Refresh($body,$c,$true)
Check ($stats.Count($npc.id) -eq 0) 'Unknown NPC save schema retained impairment'
Reset;$r=[CREffectsFixture]::runtime
foreach($i in 1..128){Check ($r.Register([CREffectsFixture]::NPC())) 'Registry reached capacity too early'}
Check (-not $r.Register([CREffectsFixture]::NPC()) -and $r.rejectedRegistrations -eq 1 -and $r.npcs.Count -eq 128) 'Registry capacity was unbounded or silent'
$r.npcs[0].attached=$false;$r.npcs[1]=$null
Check ($r.Register([CREffectsFixture]::NPC()) -and $r.npcs.Count -eq 127) 'Released weak/detached entries were not reclaimed'
[CRCombatRuntimePolicy]::enabled=$false
Check (-not $r.Register([CREffectsFixture]::NPC())) 'Disabled combat registered an actor'
Write-JsonFile ([ordered]@{testedAtUtc=[DateTime]::UtcNow.ToString('o');passed=$true;assertions=$script:checks;nativeSourceSha256=Get-Sha256 $nativePath;modelSources=@($paths|ForEach-Object{[ordered]@{path=$_;sha256=Get-Sha256 $_}});scope='Actual model and native modifier/bridge/registry methods translated with typed stat, actor, weapon and scene fixtures. Ownership, retry, cleanup, bounded registry and regional response tested. Engine timing, NPC stat consumers, weak-reference expiration and save serialization remain unverified.'}) (Join-Path $project 'reports/injury-effects-tests.json')
Write-Host "PASS: $script:checks injury-effect model/ownership/lifecycle checks."