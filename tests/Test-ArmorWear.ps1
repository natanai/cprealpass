. "$PSScriptRoot\..\tools\Common.ps1"
. "$PSScriptRoot\CoreHarness.ps1"
$project=Get-ProjectRoot
$nativePath=Join-Path $project 'src/redscript/CyberpunkRealism/ArmorWearNative.reds'
$native=Get-Content -Raw $nativePath
$classes=foreach($name in @('CRArmorItemState','CRArmorRegistry','CRArmorWearEntry','CRArmorWearPlan','CRArmorWearBridge')){
 $match=[regex]::Match($native,'(?m)^public class '+$name+' extends (IScriptable|ScriptableSystem)')
 if(-not $match.Success){throw "Missing class $name"}
 $start=$native.IndexOf('{',$match.Index);$depth=1;$end=$start+1
 while($depth -gt 0 -and $end -lt $native.Length){if($native[$end] -eq '{'){$depth++};if($native[$end] -eq '}'){$depth--};$end++}
 if($depth -ne 0){throw 'Unbalanced native class'}
 $s=$native.Substring($match.Index,$end-$match.Index)
 if($name -eq 'CRArmorRegistry'){
  $s=$s.Replace('extends ScriptableSystem','extends IScriptable').Replace('private persistent let','public persistent let')
  $s=[regex]::Replace($s,'public func (\w+)\(','public static func CRInstance_$1(')
  $s=[regex]::Replace($s,'return GameInstance.GetScriptableSystemsContainer\(GetGameInstance\(\)\).+?;', 'return CRArmorFixture.registry;')
 }
 $s
}
$generated=Join-Path $project ('staging/armor-registry-test-'+[guid]::NewGuid().ToString('N')+'.reds')
$s=($classes -join "`n").Replace('wref<','ref<').Replace('array<ref<CRArmorWearEntry>>','CRArmorEntries = new CRArmorEntries()')
[IO.File]::WriteAllText($generated,$s)
$paths=@('ImpactModel','ArmorWearModel')|ForEach-Object{Join-Path $project "src/redscript/CyberpunkRealism/$_.reds"}
$code=Convert-RedscriptCore ($paths+@($generated))
$code=[regex]::Replace($code,'public static (\w+) CRInstance_(\w+)\(','public $1 $2(')
$code=$code.Replace('ArraySize(','CRArmorFixture.Size(').Replace('ArrayPush(','CRArmorFixture.Push(').Replace('NotEquals(','CRArmorFixture.NotEquals(')
Add-Type -TypeDefinition ($code+(Get-Content -Raw "$PSScriptRoot/fixtures/ArmorWear.cs"))
$script:checks=0
function Check($condition,$message){if(-not $condition){throw $message};$script:checks++}
function Reset { [CRArmorFixture]::registry=[CRArmorRegistry]::new() }
Reset
$a=[CRArmorFixture]::Item('vest-instance-a');$b=[CRArmorFixture]::Item('vest-instance-b')
$r=[CRArmorFixture]::registry
Check ($r.Valid() -and $r.Integrity($a,2) -eq 1 -and $r.count -eq 0) 'Reading fresh armor mutated registry'
Check ($r.Apply($a,2,0) -and $r.count -eq 0) 'Zero wear allocated persistent state'
Check ($r.Apply($a,2,0.25) -and $r.Integrity($a,2) -eq 0.75) 'Absorbed dose did not persist'
Check ($r.Integrity($a,1) -eq 1 -and $r.Integrity($b,2) -eq 1) 'Wear leaked to another region or item instance'
Check ($r.Apply($a,2,1) -and $r.Integrity($a,2) -eq 0) 'Destroyed region was not clamped'
Check (-not $r.Apply($a,2,[float]::NaN) -and $r.Integrity($a,2) -eq 0) 'NaN corrupted existing condition'
Check ([CRArmorWearModel]::Dose(500,1000) -eq 0.5 -and [CRArmorWearModel]::Dose(500,0) -eq -1) 'Energy-to-wear dose invalid'
# JSON roundtrip exercises graph reconstruction, not Cyberpunk save serialization.
$json=$r|ConvertTo-Json -Depth 15
$copy=ConvertFrom-Json $json
$r2=[CRArmorRegistry]::new();$r2.schema=$copy.schema;$r2.count=$copy.count;$r2.first=[CRArmorItemState]::new();$r2.first.item=$a;$r2.first.condition=[CRArmorCondition]::new();$r2.first.condition.torso=$copy.first.condition.torso
Check ($r2.Valid() -and $r2.Integrity($a,2) -eq 0) 'Reconstructed worn item became fresh'
$r2.schema=2
Check ($r2.Integrity($a,2) -eq -1) 'Future schema was silently reset'
$r2.schema=1;$r2.first.next=$r2.first
Check (-not $r2.Valid() -and $r2.Integrity($a,2) -eq -1) 'Cyclic saved registry was not bounded/rejected'
Reset;$r=[CRArmorFixture]::registry;$r.Apply($a,2,0.1)|Out-Null;$r.Apply($b,2,0.1)|Out-Null
$r.first.next.item=$b
Check ($r.Integrity($b,2) -eq -1) 'Duplicate item identity accepted ambiguous wear'
$r.first.next.item=$a;$r.first.next.condition=$r.first.condition
Check ($r.Integrity($a,2) -eq -1) 'Aliased condition shared wear between items'
Reset
$plan=[CRArmorFixture]::Plan()
Check ([CRArmorWearBridge]::Capture($plan,$a,2,100,1000) -and [CRArmorFixture]::registry.count -eq 0) 'Preparation mutated armor'
Check (-not [CRArmorWearBridge]::Capture($plan,$a,2,100,1000)) 'Repeated equipment layer accepted twice'
Check ([CRArmorWearBridge]::Commit($plan) -and [Math]::Abs([CRArmorFixture]::registry.Integrity($a,2)-0.9) -lt 0.00001) 'Accepted plan did not persist wear'
Check (-not [CRArmorWearBridge]::Commit($plan)) 'Plan replay wore armor twice'
Reset;$r=[CRArmorFixture]::registry
foreach($i in 1..511){$r.Apply([CRArmorFixture]::Item("worn-$i"),2,0.1)|Out-Null}
$plan=[CRArmorFixture]::Plan();[CRArmorWearBridge]::Capture($plan,$a,2,100,1000)|Out-Null;[CRArmorWearBridge]::Capture($plan,$b,2,100,1000)|Out-Null
Check (-not [CRArmorWearBridge]::Commit($plan) -and $r.count -eq 511 -and $r.Integrity($a,2) -eq 1) 'Capacity exhaustion partially committed multi-item wear'
$plan=[CRArmorFixture]::Plan();[CRArmorWearBridge]::Capture($plan,$a,2,100,1000)|Out-Null
Check ([CRArmorWearBridge]::Commit($plan) -and $r.count -eq 512) 'Last available registry slot unusable'
Check ($r.Integrity($b,2) -eq -1 -and $r.Integrity($a,2) -lt 1) 'Full registry repaired existing wear or accepted untracked armor'
Reset
$plan=[CRArmorFixture]::Plan($false);$npc=$plan.target
[CRArmorWearBridge]::Capture($plan,[ItemID]::new(),2,200,1000)|Out-Null
Check ([CRArmorWearBridge]::Commit($plan) -and $npc.crArmorSchema -eq 1 -and [Math]::Abs($npc.crArmorCondition.torso-0.2) -lt 0.00001) 'NPC condition was not retained per actor'
$other=[NPCPuppet]::new()
Check ([CRArmorWearBridge]::Integrity($other,[ItemID]::new(),2) -eq 1) 'NPC condition leaked to another actor'
$other.crArmorSchema=1
Check ([CRArmorWearBridge]::Integrity($other,[ItemID]::new(),2) -eq -1) 'Missing saved NPC condition reset silently'
Check ([CRArmorWearModel]::Accepted(0,0,0,$true,$false)) 'Acknowledged full armor stop rejected'
Check (-not [CRArmorWearModel]::Accepted(0,0,0,$false,$false)) 'Missing physical evaluation treated as armor stop'
Check (-not [CRArmorWearModel]::Accepted(0,0,0,$true,$true)) 'Native protection veto treated as armor stop'
Check (-not [CRArmorWearModel]::Accepted(20,0,0,$true,$false)) 'Downstream nullification treated as our own armor stop'
Check ([CRArmorWearModel]::Accepted(20,2,2,$true,$false)) 'Accepted boss-capped hit rejected for armor wear'
Check (-not [CRArmorWearModel]::Accepted([float]::NaN,2,2,$true,$false)) 'Invalid proposed damage accepted'
# Repeated impacts progressively lower stopping power while preserving energy.
$s=[CRArmorCondition]::new();$previousRemaining=-1.0
foreach($i in 1..100){
 $projectile=[CRProjectileSpec]::new();$projectile.massGrams=8;$projectile.speedMetersPerSecond=360;$projectile.diameterMm=9
 $impact=[CRImpactModel]::Begin($projectile);$layer=[CRProtectionLayer]::new();$layer.covered=$true;$layer.resistanceJPerMm2=8;$layer.durabilityJ=6000;$layer.bluntTransferFraction=0.22;$layer.integrity=[CRArmorWearModel]::Integrity($s,2)
 Check ([CRImpactModel]::ApplyLayer($impact,$layer) -and [CRImpactModel]::ValidState($impact) -and $impact.remainingJ -ge $previousRemaining) 'Repeated armor impacts gained stopping power or lost energy conservation'
 $dose=[CRArmorWearModel]::Dose($impact.initialJ-$impact.remainingJ,$layer.durabilityJ)
 Check ([CRArmorWearModel]::Apply($s,2,$dose) -and [Math]::Abs([CRArmorWearModel]::Integrity($s,2)-$layer.integrity) -lt 0.00001) 'Persisted wear differs from layer energy calculation'
 $previousRemaining=$impact.remainingJ
}
Reset
$empty=[CRArmorFixture]::Plan()
Check (-not [CRArmorWearBridge]::Commit($empty) -and [CRArmorFixture]::registry.count -eq 0) 'Empty plan claimed armor wear'
$plan=[CRArmorFixture]::Plan();[CRArmorWearBridge]::Capture($plan,$a,2,100,1000)|Out-Null;[CRArmorWearBridge]::Capture($plan,$b,2,100,1000)|Out-Null
$plan.entries[1].dose=[float]::NaN
Check (-not [CRArmorWearBridge]::Commit($plan) -and [CRArmorFixture]::registry.count -eq 0) 'Invalid second dose partially mutated first armor item'
$plan=[CRArmorFixture]::Plan();[CRArmorWearBridge]::Capture($plan,$a,2,100,1000)|Out-Null;$plan.entries.Add($plan.entries[0])
Check (-not [CRArmorWearBridge]::Commit($plan) -and [CRArmorFixture]::registry.count -eq 0) 'Altered duplicate plan partially mutated armor'
Write-JsonFile ([ordered]@{testedAtUtc=[DateTime]::UtcNow.ToString('o');passed=$true;assertions=$script:checks;nativeSourceSha256=Get-Sha256 $nativePath;scope='Actual pure wear and native registry/plan methods translated with typed item/actor fixtures; repeated impacts, item identity, region isolation, replay, reconstruction, malformed state, capacity atomicity and NPC isolation. Engine save identity and callback behavior unverified.'}) (Join-Path $project 'reports/armor-wear-tests.json')
Write-Host "PASS: $script:checks armor wear/registry/commit checks."