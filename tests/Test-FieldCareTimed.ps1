. "$PSScriptRoot\..\tools\Common.ps1"
. "$PSScriptRoot\CoreHarness.ps1"
$project=Get-ProjectRoot
function Extract([string]$source,[string]$pattern){
 $match=[regex]::Match($source,$pattern)
 if(-not $match.Success){throw "Missing source: $pattern"}
 $start=$source.IndexOf('{',$match.Index);$depth=1;$end=$start+1
 while($depth -gt 0 -and $end -lt $source.Length){if($source[$end] -eq '{'){$depth++};if($source[$end] -eq '}'){$depth--};$end++}
 if($depth -ne 0){throw 'Unbalanced source'}
 return $source.Substring($match.Index,$end-$match.Index)
}
$nativePath=Join-Path $project 'src/redscript/CyberpunkRealism/FieldCareActionRuntime.reds'
$runtime=Get-Content $nativePath -Raw
$parts=@(Extract $runtime '(?m)^public class CRFieldCareActionCallback');$parts+=Extract $runtime '(?m)^public class CRFieldCareActionRuntime'
$bodyPath=Join-Path $project 'src/redscript/CyberpunkRealism/BodyRuntime.reds'
$body=Get-Content $bodyPath -Raw
$methods=@(Extract $body 'public func CanUseFieldCare\(');$methods+=Extract $body 'public func CanContinueFieldCare\(';$methods+=Extract $body 'public func CommitFieldCare\('
$parts+='public class CRBodyRuntime extends IScriptable {'+"`n"+($methods -join "`n")+"`n}"
$s=($parts -join "`n").Replace('extends DelayCallback','extends IScriptable').Replace('extends ScriptableSystem','extends IScriptable').Replace('wref<','ref<').Replace('private let','public let')
$s=[regex]::Replace($s,'(?:public|private) func (\w+)\(','public static func CRInstance_$1(')
$s=[regex]::Replace($s,'return GameInstance.GetScriptableSystemsContainer\(GetGameInstance\(\)\).+?;', 'return CareTimedFixture.runtime;')
$s=$s.Replace('GetGameInstance()','CareTimedFixture.game').Replace('GetAllBlackboardDefs()','CareTimedFixture.defs').Replace('ToVariant(warning)','warning').Replace('GetInvalidDelayID()','0')
$generated=Join-Path $project ('staging/field-care-timed-'+[guid]::NewGuid().ToString('N')+'.reds');[IO.File]::WriteAllText($generated,$s)
$paths=@('InjuryModel','BodyModel','SleepModel','BodyInputs','FieldCareModel','FieldCareRuntime','FieldCareActionModel')|ForEach-Object{Join-Path $project "src/redscript/CyberpunkRealism/$_.reds"}
$code=Convert-RedscriptCore ($paths+@($generated))
$code=[regex]::Replace($code,'(?m)^import .+$','')
$code=[regex]::Replace($code,'public static (\w+) CRInstance_(\w+)\(','public $1 $2(')
$code=[regex]::Replace($code,'\bDelayID\b','int')
$code=[regex]::Replace($code,'\bString\b','string')
$code=$code.Replace('public class CRBodyRuntime :','public partial class CRBodyRuntime :').Replace('t"','"')
$code=$code.Replace('IntEnum<gamePSMRangedWeaponStates>','(gamePSMRangedWeaponStates)').Replace('IntEnum<gamePSMUpperBodyStates>','(gamePSMUpperBodyStates)')
$code=$code.Replace('Cast<int>','(int)').Replace('ToString(','System.Convert.ToString(')
Add-Type -TypeDefinition ($code+(Get-Content -Raw "$PSScriptRoot/fixtures/FieldCareInventory.cs")+(Get-Content -Raw "$PSScriptRoot/fixtures/FieldCareTimed.cs"))
$script:checks=0
function Check($condition,$message){if(-not $condition){throw $message};$script:checks++}
function Reset {[CareTimedFixture]::Reset()}
function Begin($kind=2){return [CareTimedFixture]::runtime.Begin(5,$kind)}
function StartCare {[DFGameStateService]::inMenu=$false;[CareTimedFixture]::Sample()}
function Finish($samples=32){foreach($i in 1..$samples){[CareTimedFixture]::Sample()}}
Reset;$r=[CareTimedFixture]::runtime;$inv=[CareTimedFixture]::game.inventory
Check ((Begin) -eq 8 -and $inv.removeCalls -eq 0 -and [CareTimedFixture]::delays.callbacks.Count -eq 1) 'Queuing care consumed a kit or scheduled duplicate callbacks'
foreach($i in 1..20){[CareTimedFixture]::Sample()}
Check ($r.action.elapsed -eq 0 -and $r.action.stage -eq 1 -and $inv.count -eq 3) 'Inventory time completed paid care'
Check ((Begin) -eq 0 -and [CareTimedFixture]::delays.callbacks.Count -eq 1) 'Second request stacked an action'
StartCare
Finish 31
Check ($inv.removeCalls -eq 0 -and [CareTimedFixture]::body.body.injuries.leftLeg.externalBleedMlPerHour -eq 100) 'Treatment applied before its duration'
[CareTimedFixture]::Sample()
Check (-not $r.Active() -and $inv.count -eq 2 -and [CareTimedFixture]::body.inputs.appliedTreatments -eq 1 -and [CareTimedFixture]::body.body.injuries.leftLeg.externalBleedMlPerHour -eq 0 -and [CareTimedFixture]::delays.callbacks.Count -eq 0) 'Completed care failed exact-once debit/treatment/cleanup'
Check ([CareTimedFixture]::messages.Count -eq 2) 'Gameplay feedback missing or emitted on every sample'
Reset;Begin 3|Out-Null;StartCare;Finish 32
Check ([CareTimedFixture]::game.inventory.removeCalls -eq 0) 'Limb support incorrectly used dressing duration'
Finish 16
Check ([CareTimedFixture]::body.body.injuries.leftLeg.support -eq 1 -and [CareTimedFixture]::body.body.injuries.leftLeg.boneDamage -eq 0.5) 'Timed support healed bone or failed to apply support'
foreach($case in @('move','teleport','menu','combat','dead','mounted','scene','invalid-game','skip-gap','backward-clock','detached','restored','manual','menu-boundary','weapon','consumable','aim')){
 Reset;Begin|Out-Null;StartCare;$r=[CareTimedFixture]::runtime
 switch($case){
  'weapon'{[CareTimedFixture]::player.board.values['weapon']=9}
  'consumable'{[CareTimedFixture]::player.board.values['consumable']=1}
  'aim'{[CareTimedFixture]::player.board.values['upper']=1}
  'move'{[CareTimedFixture]::player.velocity=[Vector4]@{X=1}}
  'teleport'{[CareTimedFixture]::player.position=[Vector4]@{X=2}}
  'menu'{[DFGameStateService]::inMenu=$true}
  'combat'{[CareTimedFixture]::player.combat=$true}
  'dead'{[CareTimedFixture]::player.dead=$true}
  'mounted'{[CareTimedFixture]::player.mounted=$true}
  'scene'{[CareTimedFixture]::player.scene=$true}
  'invalid-game'{[DFGameStateService]::valid=$false}
  'skip-gap'{[CareTimedFixture]::sim+=10}
  'backward-clock'{[CareTimedFixture]::sim=-1}
  'detached'{$r.OnDetach()}
  'restored'{$r.OnRestored(1,1)}
  'manual'{$r.Cancel($true)}
  'menu-boundary'{[DFGameStateService]::inMenu=$true;$r.OnMenuBoundary()}
 }
 if($r.Active()){[CareTimedFixture]::Sample()}
 Check (-not $r.Active() -and [CareTimedFixture]::delays.callbacks.Count -eq 0 -and [CareTimedFixture]::game.inventory.removeCalls -eq 0 -and [CareTimedFixture]::body.body.injuries.leftLeg.externalBleedMlPerHour -eq 100) "Interrupted care mutated inventory/wounds or left a timer: $case"
}
# One callback identity/sample ticket cannot fork a chain or affect a replacement.
Reset;Begin|Out-Null;$old=[CareTimedFixture]::delays.Fire();$scheduled=[CareTimedFixture]::delays.scheduled
$old.Call()
Check ([CareTimedFixture]::delays.scheduled -eq $scheduled -and [CareTimedFixture]::delays.callbacks.Count -eq 1) 'Duplicate callback forked a timer chain'
[CareTimedFixture]::runtime.Cancel($false);Begin|Out-Null;$current=[CareTimedFixture]::runtime.action;$old.Call()
Check ([CareTimedFixture]::runtime.action -eq $current -and [CareTimedFixture]::delays.callbacks.Count -eq 1) 'Stale callback cancelled or advanced new action'
[CareTimedFixture]::runtime.Cancel($false)
Reset;Begin|Out-Null
foreach($i in 1..241){[CareTimedFixture]::Sample(0)}
Check (-not [CareTimedFixture]::runtime.Active() -and [CareTimedFixture]::delays.callbacks.Count -eq 0) 'Queued/paused action scheduled forever'
# Prepare fresh after ordinary body progression, then enforce inventory callbacks.
Reset;Begin|Out-Null;StartCare;[CareTimedFixture]::body.pendingHours=0.005
Finish
Check ([CareTimedFixture]::game.inventory.count -eq 2 -and [CareTimedFixture]::body.body.injuries.bloodLostMl -gt 0 -and [CareTimedFixture]::body.body.injuries.leftLeg.externalBleedMlPerHour -eq 0) 'Natural progression invalidated all care or historical bleeding was erased'
Reset;Begin|Out-Null;StartCare;[CareTimedFixture]::game.inventory.count=0;Finish
Check ([CareTimedFixture]::body.inputs.appliedTreatments -eq 0 -and [CareTimedFixture]::game.inventory.removeCalls -eq 0) 'Supplies missing at completion still gave treatment'
Reset;Begin|Out-Null;StartCare;[CareTimedFixture]::game.inventory.onRemove={ [CareTimedFixture]::runtime.Cancel($false) };Finish
Check ([CareTimedFixture]::game.inventory.count -eq 3 -and [CareTimedFixture]::game.inventory.giveCalls -eq 1 -and [CareTimedFixture]::body.inputs.appliedTreatments -eq 0 -and [CareTimedFixture]::delays.callbacks.Count -eq 0) 'Cancellation during debit still applied care or lost the kit'
Reset;Begin|Out-Null;StartCare;[CareTimedFixture]::game.inventory.giveFails=$true;[CareTimedFixture]::game.inventory.onRemove={ [CareTimedFixture]::runtime.Cancel($false) };Finish
Check ([CareTimedFixture]::runtime.status.Contains('could not be returned') -and [CareTimedFixture]::body.inputs.appliedTreatments -eq 0) 'Refund failure was concealed'
Reset;$fake=[CRFieldCareActionModel]::Create(5,2);$fake.stage=3
Check ([CareTimedFixture]::body.CommitFieldCare($fake) -eq 0 -and [CareTimedFixture]::game.inventory.removeCalls -eq 0) 'Forged completion bypassed action identity'
Reset;Begin|Out-Null;StartCare;[CareTimedFixture]::game.inventory.onRemove={ [CareTimedFixture]::player.combat=$true };Finish
Check ([CareTimedFixture]::game.inventory.count -eq 3 -and [CareTimedFixture]::body.inputs.appliedTreatments -eq 0) 'State changed during debit without a cancel event but treatment still applied'
Reset;[CareTimedFixture]::delays.failSchedule=$true
Check ((Begin) -eq 0 -and -not [CareTimedFixture]::runtime.Active() -and [CareTimedFixture]::delays.callbacks.Count -eq 0) 'Rejected callback scheduling left a queued action stuck'
Write-JsonFile ([ordered]@{testedAtUtc=[DateTime]::UtcNow.ToString('o');passed=$true;assertions=$script:checks;runtimeSha256=Get-Sha256 $nativePath;bodyRuntimeSha256=Get-Sha256 $bodyPath;sources=@($paths|ForEach-Object{[ordered]@{path=$_;sha256=Get-Sha256 $_}});scope='Actual action model/runtime, eligibility, completion and inventory methods translated with native scheduling/player/notification fixtures. Duration, menu queueing, interruption, bounded scheduling, stale tickets, completion-only debit and callback cancellation/refund tested. Engine scheduling, native UI, save lifecycle and animation remain unverified.'}) (Join-Path $project 'reports/field-care-timed-tests.json')
Write-Host "PASS: $script:checks timed field-care/runtime checks."