. "$PSScriptRoot\..\tools\Common.ps1"
. "$PSScriptRoot\CoreHarness.ps1"
$project=Get-ProjectRoot
$native=Get-Content -Raw (Join-Path $project 'src/redscript/CyberpunkRealism/BloodLossNative.reds')
$start=$native.IndexOf('public class CRBloodLossNative');$end=$native.IndexOf('@wrapMethod(DamageSystem)',$start)
$s=$native.Substring($start,$end-$start)
$s=$s.Replace('return GameInstance.GetSimTime(GetGameInstance()).ToFloat();','return CRBloodFixture.sim;').Replace('const lost: script_ref<[SDamageDealt]>','lost: CRLosses').Replace('Deref(lost)','lost').Replace('array<Float>','CRValues').Replace('let context: AttackInitContext;','let context: AttackInitContext = new AttackInitContext();')
$bossWrapper=$native.Substring($native.IndexOf('@wrapMethod(StatPoolsManager)'))
$bossWrapper=$bossWrapper.Substring($bossWrapper.IndexOf('public final static func'))
$bossWrapper=$bossWrapper.Replace('public final static func','public static func').Replace('out valuesLost: [SDamageDealt]','valuesLost: CRBossLosses').Replace('array<Float>','CRValues')
$s += 'public class StatPoolsManager extends IScriptable {'+$bossWrapper+'}'
$generated=Join-Path $project ('staging/blood-loss-test-'+[guid]::NewGuid().ToString('N')+'.reds')
[IO.File]::WriteAllText($generated,$s)
$paths=@('BloodLossModel','InjuryModel','BodyModel','SleepModel','NPCBodyModel','FieldCareModel')|ForEach-Object{Join-Path $project "src/redscript/CyberpunkRealism/$_.reds"}
$code=Convert-RedscriptCore ($paths+@($generated))
$code=$code.Replace('CRBiologySessionAuthority.Body(actor.GetGame())','CRBodyRuntime.Get()')
$code=$code.Replace('CRLosses','SDamageDealt[]').Replace('CRValues','float[]').Replace('Cast<StatsObjectID>','').Replace('NotEquals(','CRBloodFixture.NotEquals(').Replace('ArraySize(','CRBloodFixture.Size(')
$code=[regex]::Replace($code,'\b[nt]"','"')
$code=$code.Replace('CRBossLosses','System.Collections.Generic.List<SDamageDealt>').Replace('ArrayClear(','CRBossFixture.Clear(').Replace('public class StatPoolsManager :','public partial class StatPoolsManager :')
$bossFixture=@"
public static class CRBossFixture {
 public static int nativeCalls,stockCalls;public static float lastDamage;
 public static void Clear<T>(System.Collections.Generic.List<T> list){list.Clear();}
 public static void Reset(){nativeCalls=stockCalls=0;lastDamage=0;TweakDBInterface.dotProportion=1;}
}
public partial class StatPoolsManager {
 public static void wrappedMethod(gameHitEvent hit,bool real,System.Collections.Generic.List<SDamageDealt> lost){CRBossFixture.stockCalls++;}
 public static void ApplyDamageSingle(gameHitEvent hit,gamedataDamageType type,float damage,bool real,System.Collections.Generic.List<SDamageDealt> lost){
  CRBossFixture.nativeCalls++;CRBossFixture.lastDamage=damage;
  lost.Add(new SDamageDealt{affectedStatPool=gamedataStatPoolType.Health,value=damage});
 }
}
"@
Add-Type -TypeDefinition ($code+(Get-Content -Raw "$PSScriptRoot/fixtures/BloodLoss.cs")+$bossFixture)
$script:checks=0
function Check($condition,$message){if(-not $condition){throw $message};$script:checks++}
function Reset {[CRBloodFixture]::Reset()}
function Injury($deficit=2500){$s=[CRInjuryModel]::Create();$s.bloodDeficitMl=$deficit;$s.bloodLostMl=$deficit;return $s}
function Refresh($actor,$injury,$enabled=$true){[CRBloodLossNative]::Refresh($actor,$injury,$enabled)}
function Dose($actor,$injury,$amount=0.02){$injury.bloodLossExposure+=$amount;Refresh $actor $injury;return [CRBloodFixture]::Last()}
# Shared physiology, minute integration, snapshot independence and migration.
$c=[CRBodyConfig]::new();$c.injuryBloodRecoveryMlPerHour=0
foreach($deficit in @(0,1000,1500)){$s=Injury $deficit;[CRInjuryModel]::Advance($s,$c,1,0,0,42000)|Out-Null;Check ($s.bloodLossExposure -eq 0) 'Subthreshold loss generated shock damage'}
$s=Injury 2000;[CRInjuryModel]::Advance($s,$c,0.5,0,0,42000)|Out-Null
Check ([Math]::Abs($s.bloodLossExposure-0.5) -lt 0.00001) 'Intermediate dose rate or game-hour units wrong'
$s=Injury;[CRInjuryModel]::Advance($s,$c,1,0,0,42000)|Out-Null
Check ([Math]::Abs($s.bloodLossExposure-2) -lt 0.00001 -and $s.bloodLostMl -eq 2500) 'Shock accounting mutated blood or used wrong upper rate'
$copy=[CRInjuryModel]::Copy($s);Check ([Math]::Abs($copy.bloodLossExposure-2) -lt 0.00001 -and $copy -ne $s) 'Exposure missing from independent injury snapshots'
$copy.bloodLossExposure=3;Check (-not [CRFieldCareModel]::Same($s,$copy)) 'Field-care transaction accepted changed exposure'
foreach($invalid in @([float]::NaN,[float]::PositiveInfinity,-1,1000001)){$s=Injury;$s.bloodLossExposure=$invalid;Check (-not [CRInjuryModel]::ValidState($s)) 'Malformed exposure accepted'}
$a=[CRBodyModel]::Create($c);$a.injuries=Injury;$b=[CRNPCBodyModel]::Create($a.injuries,$c)
[CRBodyModel]::Advance($a,$c,1,0,$false)|Out-Null
for($i=0;$i -lt 60;$i++){[CRNPCBodyModel]::Advance($b,$c,(1/60),0)|Out-Null}
Check ([Math]::Abs($a.injuries.bloodLossExposure-$b.injuries.bloodLossExposure) -lt 0.00001) 'V/NPC segmented shared-clock demand diverged'
$cross=[CRBodyModel]::Create($c);$cross.injuries=Injury 1499;$cross.injuries.torso.internalBleedMlPerHour=6000
[CRBodyModel]::Advance($cross,$c,(1/60),0,$false)|Out-Null
Check ($cross.injuries.bloodLossExposure -eq 0) 'New threshold charged time before crossing'
[CRBodyModel]::Advance($cross,$c,(1/60),0,$false)|Out-Null
Check ($cross.injuries.bloodLossExposure -gt 0) 'Continued severe loss omitted exposure'
# Native delivery is initialized once; old exposure is never replayed.
Reset;$p=[ScriptedPuppet]::new();$s=Injury;$s.bloodLossExposure=100
Refresh $p $s;Check ([CRBloodFixture]::hits.Count -eq 0) 'Existing save exposure replayed on first observation'
$h=Dose $p $s;Check ([CRBloodFixture]::hits.Count -eq 1 -and $h.crBloodLossDelivery.phase -eq 1) 'New eligible demand not queued'
Check ($h.attackData.instigator -eq $p -and $h.attackData.source -eq $p -and $h.attackData.flags.Count -eq 4 -and $h.attackData.HasFlag([hitFlag]::DamageOverTime)) 'Unexpected self-DOT identity or flags'
Check ([CRBloodLossNative]::Admit($h) -and -not [CRBloodLossNative]::Admit($h)) 'Native event admission can repeat'
[CRBloodLossNative]::Prepare($h)
Check ($h.crBloodLossDelivery.phase -eq 2 -and [Math]::Abs($h.attackComputed.values[0]-2) -lt 0.001 -and $h.attackComputed.values[1] -eq 0) 'Post-RPG physiological proposal retained source/elemental damage'
[CRBloodLossNative]::Acknowledge($h,[CRBloodFixture]::Losses(1,50))
[CRBloodLossNative]::Acknowledge($h,[CRBloodFixture]::Losses(10,50))
Check ($h.crBloodLossDelivery.phase -eq 3 -and $h.crBloodLossDelivery.reportedHealthDamage -eq 1) 'Acknowledgement repeated or counted armor loss'
Refresh $p $s;Check ([CRBloodFixture]::hits.Count -eq 1) 'Repeated publication repeated damage'
# Sub-one-point doses accumulate without native minimum-damage amplification.
Reset;$p=[ScriptedPuppet]::new();$s=Injury;Refresh $p $s
Dose $p $s 0.003|Out-Null;Dose $p $s 0.003|Out-Null
Check ([CRBloodFixture]::hits.Count -eq 0) 'Tiny dose was amplified by native one-point minimum'
$h=Dose $p $s 0.005;Check ($h.crBloodLossDelivery.proposedDamage -gt 1 -and $h.crBloodLossDelivery.proposedDamage -lt 1.2) 'Fractional demand lost'
# Large accepted skips are capped and discarded, not paid as later bursts.
Reset;$p=[ScriptedPuppet]::new();$s=Injury;Refresh $p $s;$h=Dose $p $s 20
Check ($h.crBloodLossDelivery.proposedDamage -eq 10 -and $p.crBloodLossCursor.droppedFraction -gt 19) 'Unbounded catch-up health burst'
[CRBloodFixture]::sim=3;Refresh $p $s
Check ($h.crBloodLossDelivery.phase -eq 0 -and [CRBloodFixture]::hits.Count -eq 1 -and -not [CRBloodLossNative]::Admit($h)) 'Unacknowledged dose was retried or late event accepted'
$next=Dose $p $s;Check ([CRBloodFixture]::hits.Count -eq 2 -and $next -ne $h) 'Fresh demand could not resume after a lost response'
# Explicit lifecycle, scene, actor and malformed-health rejection.
foreach($case in @('disabled','scene','detached','dead','replacer','fast-finisher','drone','invalid-health')){
 Reset;$p=[NPCPuppet]::new();$s=Injury;Refresh $p $s;$h=Dose $p $s
 switch($case){'disabled'{[CRCombatRuntimePolicy]::enabled=$false};'scene'{$p.scene=$true};'detached'{$p.attached=$false};'dead'{$p.dead=$true};'replacer'{$p.replacer=$true};'fast-finisher'{$p.fastFinisher=$true};'drone'{$p.type=[gamedataNPCType]::Drone};'invalid-health'{$p.maximumHealth=[float]::NaN}}
 $s.bloodLossExposure+=1;Refresh $p $s
 Check (-not [CRBloodLossNative]::Admit($h) -and [CRBloodFixture]::hits.Count -eq 1) "Unsafe actor/lifecycle accepted: $case"
}
Reset;$p=[ScriptedPuppet]::new();$s=Injury;Refresh $p $s;$h=Dose $p $s
[CRBloodLossNative]::Clear($p);$s.bloodLossExposure=10;Refresh $p $s
Check ([CRBloodFixture]::hits.Count -eq 1 -and -not [CRBloodLossNative]::Admit($h)) 'Suspension replayed exposure or retained queued event'
$new=[CRInjuryModel]::Copy($s);$new.bloodLossExposure=20;Refresh $p $new
Check ([CRBloodFixture]::hits.Count -eq 1) 'Body replacement replayed old exposure'
# Native immunity/limit flags must remain authoritative after admission.
foreach($flag in @('DealNoDamage','DamageNullified','ImmortalTarget','CannotModifyDamage','DeterministicDamage')){
 Reset;$p=[ScriptedPuppet]::new();$s=Injury;Refresh $p $s;$h=Dose $p $s
 [CRBloodLossNative]::Admit($h)|Out-Null;$h.attackData.AddFlag([hitFlag]::$flag,'fixture');[CRBloodLossNative]::Prepare($h)
 Check ($h.attackComputed.values[0] -eq 0 -and $h.attackComputed.values[1] -eq 0 -and $h.crBloodLossDelivery.phase -eq 0) "Native protection overwritten: $flag"
}
foreach($flag in @('IgnoreImmortalityModes','IgnoreStatPoolCustomLimit','Kill','Nonlethal')){
 Reset;$p=[ScriptedPuppet]::new();$s=Injury;Refresh $p $s;$h=Dose $p $s;$h.attackData.AddFlag([hitFlag]::$flag,'fixture')
 Check (-not [CRBloodLossNative]::Admit($h)) "Unexpected special native flag accepted: $flag"
}
foreach($case in @('projection','wrong-target','wrong-source','expired','body-suspended')){
 Reset;$p=[ScriptedPuppet]::new();$s=Injury;Refresh $p $s;$h=Dose $p $s
 switch($case){'projection'{$h.projectionPipeline=$true};'wrong-target'{$h.target=[ScriptedPuppet]::new()};'wrong-source'{$h.attackData.source=[ScriptedPuppet]::new()};'expired'{[CRBloodFixture]::sim=3};'body-suspended'{[CRBloodFixture]::allowed=$false}}
 Check (-not [CRBloodLossNative]::Admit($h)) "Invalid event identity/context accepted: $case"
}
foreach($case in @('failRecord','failAttack')){
 Reset;$p=[ScriptedPuppet]::new();$s=Injury;Refresh $p $s
 if($case -eq 'failRecord'){[CRBloodFixture]::failRecord=$true}else{[CRBloodFixture]::failAttack=$true}
 Dose $p $s|Out-Null
 Check ([CRBloodFixture]::hits.Count -eq 0 -and $null -eq $p.crBloodLossCursor.pending) 'Failed native initialization retained a live plan'
}
Reset;$p=[ScriptedPuppet]::new();$s=Injury;Refresh $p $s;$h=Dose $p $s;[CRBloodLossNative]::Admit($h)|Out-Null;[CRBloodLossNative]::Prepare($h);$p.dead=$true
[CRBloodLossNative]::Acknowledge($h,[CRBloodFixture]::Losses(1,0))
Check ($h.crBloodLossDelivery.phase -eq 3) 'Terminal native response was discarded merely because actor died'
# A queued hit must also respect the current maximum health at delivery.
foreach($health in @(50,1,[float]::NaN)){
 Reset;$p=[ScriptedPuppet]::new();$s=Injury;Refresh $p $s;$h=Dose $p $s 0.1
 [CRBloodLossNative]::Admit($h)|Out-Null;$p.maximumHealth=$health;[CRBloodLossNative]::Prepare($h)
 if($health -eq 50){Check ($h.attackComputed.values[0] -eq 5) 'Queued dose ignored a reduced maximum health'}else{Check ($h.attackComputed.values[0] -eq 0 -and $h.crBloodLossDelivery.phase -eq 0) 'Invalid/tiny current health accepted queued damage'}
}
# New publication while an event is in flight keeps one bounded pending dose.
Reset;$p=[ScriptedPuppet]::new();$s=Injury;Refresh $p $s;$h=Dose $p $s
for($i=0;$i -lt 10;$i++){Dose $p $s 0.001|Out-Null}
Check ([CRBloodFixture]::hits.Count -eq 1 -and $p.crBloodLossCursor.carry -le 0.1) 'Concurrent publication started multiple event chains'
[CRBloodLossNative]::Admit($h)|Out-Null;$p.scene=$true;[CRBloodLossNative]::Prepare($h)
Check ($h.attackComputed.values[0] -eq 0 -and $h.attackData.HasFlag([hitFlag]::DealNoDamage)) 'Scene entry after preflight still dealt damage'
Reset;$p=[ScriptedPuppet]::new();$s=Injury;Refresh $p $s;$h=Dose $p $s;[CRBloodLossNative]::Admit($h)|Out-Null
$h.attackComputed.values[0]=[float]::NaN;$h.attackData.AddFlag([hitFlag]::ImmortalTarget,'fixture');[CRBloodLossNative]::Prepare($h)
Check ($h.attackComputed.values[0] -eq 0) 'Protected event retained a non-finite native source value'
# Check routing contracts; native engine delivery is still an attended test gate.
$wounds=Get-Content -Raw (Join-Path $project 'src/redscript/CyberpunkRealism/CombatWoundsNative.reds')
$contact=Get-Content -Raw (Join-Path $project 'src/redscript/CyberpunkRealism/CombatNativeBridge.reds')
Check ($wounds -match '(?s)if IsDefined\(hitEvent\) && IsDefined\(hitEvent.crBloodLossDelivery\).*?CRBloodLossNative.Prepare\(hitEvent\);\s*} else {\s*CRNativeWoundBridge.Prepare') 'Shock events share physical wound preparation'
Check ($contact -match '(?s)CRBloodLossNative.Acknowledge\(hitEvent, resourcesLost\);\s*return;') 'Shock acknowledgement falls through to new wound/armor routing'
Check ($native -match 'if !CRBloodLossNative.Admit\(hitEvent\)' -and $native -notmatch 'Request(?:Setting|Changing)StatPoolValue|IgnoreStatPoolCustomLimit,|IgnoreImmortalityModes,|hitFlag.Kill,') 'Native preflight missing or health protections bypassed'
# Execute the actual resource wrapper for weaponless boss/MaxTac doses.
function BossDose($maxtac=$false){
 Reset;[CRBossFixture]::Reset()
 $script:boss=[NPCPuppet]::new();$boss.maximumHealth=1000;$boss.maxPercentDamage=2
 if($maxtac){$boss.rarity=[gamedataNPCRarity]::MaxTac}else{$boss.boss=$true}
 $injury=Injury;Refresh $boss $injury
 $script:bossHit=Dose $boss $injury 0.1
 Check ([CRBloodLossNative]::Admit($bossHit)) 'Human boss/MaxTac dose rejected'
 [CRBloodLossNative]::Prepare($bossHit)
 $script:bossLost=[System.Collections.Generic.List[SDamageDealt]]::new()
}
foreach($maxtac in @($false,$true)){
 BossDose $maxtac
 [TweakDBInterface]::dotProportion=0.25
 [StatPoolsManager]::ApplyDamage($bossHit,$true,$bossLost)
 Check ([CRBossFixture]::nativeCalls -eq 1 -and [CRBossFixture]::stockCalls -eq 0 -and [Math]::Abs([CRBossFixture]::lastDamage-5) -lt 0.001) 'Boss DOT/per-hit cap or native boundary wrong'
 Check ($bossHit.attackComputed.values[1] -eq 0 -and $bossHit.crBloodLossDelivery.resourcesSubmitted) 'Boss branch retained elemental values or lacked single-submit marker'
 $reported=$bossLost.ToArray()
 [StatPoolsManager]::ApplyDamage($bossHit,$true,$bossLost)
 Check ([CRBossFixture]::nativeCalls -eq 1) 'Boss resource submission repeated'
 [CRBloodLossNative]::Acknowledge($bossHit,$reported)
 Check ($bossHit.crBloodLossDelivery.phase -eq 3 -and $bossHit.crBloodLossDelivery.reportedHealthDamage -eq 5) 'Boss native response not acknowledged'
}
BossDose
[StatPoolsManager]::ApplyDamage($bossHit,$false,$bossLost)
Check ([CRBossFixture]::nativeCalls -eq 0 -and !$bossHit.crBloodLossDelivery.resourcesSubmitted) 'Preview spent/consumed boss delivery'
[StatPoolsManager]::ApplyDamage($bossHit,$true,$bossLost)
Check ([CRBossFixture]::nativeCalls -eq 1) 'Preview prevented actual delivery'
foreach($case in @('scene','dead','weapon','not-dot','expired','wrong-phase','null-computed','invalid-cap','invalid-proposal','fast-finisher','invalid-proportion','invalid-health','zero-proportion')){
 BossDose
 switch($case){
  'scene'{$boss.scene=$true};'dead'{$boss.dead=$true};'weapon'{$bossHit.attackData.weapon=[object]::new()}
  'not-dot'{$bossHit.attackData.flags.Remove([hitFlag]::DamageOverTime)|Out-Null}
  'expired'{[CRBloodFixture]::sim=3};'wrong-phase'{$bossHit.crBloodLossDelivery.phase=1};'null-computed'{$bossHit.attackComputed=$null}
  'invalid-proposal'{$bossHit.crBloodLossDelivery.proposedDamage=[float]::NaN};'fast-finisher'{$boss.fastFinisher=$true};'invalid-cap'{$boss.maxPercentDamage=[float]::NaN};'invalid-proportion'{[TweakDBInterface]::dotProportion=[float]::PositiveInfinity}
  'invalid-health'{$boss.maximumHealth=[float]::NaN};'zero-proportion'{[TweakDBInterface]::dotProportion=0}
 }
 [StatPoolsManager]::ApplyDamage($bossHit,$true,$bossLost)
 Check ([CRBossFixture]::nativeCalls -eq 0 -and [CRBossFixture]::stockCalls -eq 0 -and $bossLost.Count -eq 0) "Invalid boss event reached native spending: $case"
}
foreach($flag in @('DealNoDamage','DamageNullified','ImmortalTarget','CannotModifyDamage','DeterministicDamage','IgnoreImmortalityModes','IgnoreStatPoolCustomLimit','Kill','Nonlethal')){
 BossDose;$bossHit.attackData.AddFlag([hitFlag]::$flag,'fixture')
 [StatPoolsManager]::ApplyDamage($bossHit,$true,$bossLost)
 Check ([CRBossFixture]::nativeCalls -eq 0) "Late native protection bypassed: $flag"
}
BossDose;$boss.maxPercentDamage=0
[StatPoolsManager]::ApplyDamage($bossHit,$true,$bossLost)
Check ([CRBossFixture]::lastDamage -eq 100) 'No-cap boss lost original bounded proposal'
BossDose;$boss.maxPercentDamage=0.01
[StatPoolsManager]::ApplyDamage($bossHit,$true,$bossLost)
Check ([CRBossFixture]::lastDamage -eq 1) 'Native positive-damage quantum not preserved'
BossDose;$bossHit.crBloodLossDelivery=$null
[StatPoolsManager]::ApplyDamage($bossHit,$true,$bossLost)
Check ([CRBossFixture]::stockCalls -eq 1 -and [CRBossFixture]::nativeCalls -eq 0) 'Unmarked boss attack diverted from stock path'
Write-JsonFile ([pscustomobject]@{passed=$true;checks=$script:checks;sourceSha256=Get-Sha256 (Join-Path $project 'src/redscript/CyberpunkRealism/BloodLossNative.reds');scope='Actual injury/delivery models, adapter and marked-boss resource wrapper with controlled queue/actor/damage fixtures; native resource drain internals, engine delivery, death, saves and boss/quest encounters unverified'}) (Join-Path $project 'reports/blood-loss-tests.json')
Write-Host "Blood-loss model and adapter: $script:checks checks passed."
