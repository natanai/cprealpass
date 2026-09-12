. "$PSScriptRoot/../tools/Common.ps1"
. "$PSScriptRoot/CoreHarness.ps1"
$project=Get-ProjectRoot
function Extract([string]$source,[string]$pattern){
 $match=[regex]::Match($source,$pattern);if(!$match.Success){throw "Missing source $pattern"}
 $start=$source.IndexOf('{',$match.Index);$depth=1;$end=$start+1
 while($depth -gt 0 -and $end -lt $source.Length){if($source[$end] -eq '{'){$depth++};if($source[$end] -eq '}'){$depth--};$end++}
 if($depth -ne 0){throw 'Unbalanced source'}
 $source.Substring($match.Index,$end-$match.Index)
}
$path=Join-Path $project 'src/redscript/CyberpunkRealism/FieldCareItemUse.reds'
$use=Extract (Get-Content -Raw $path) 'public static func Intercept\('
$menuSource=Get-Content -Raw (Join-Path $project 'src/redscript/CyberpunkRealism/FieldCareUI.reds')
$menuSource=$menuSource.Substring($menuSource.IndexOf('public class CRFieldCareMenuSession'))
$methods=@('Register','Clear','RequestOpen')|ForEach-Object{Extract $menuSource "public func $_\("}
$m=Get-Content -Raw (Join-Path $project 'manifest/m3-body-runtime-prototype.deployment.json')|ConvertFrom-Json
$f=@($m.files|Where-Object destination -eq 'r6/scripts/Dark Future/Needs/DFNeedConsumables.reds')[0]
$patched=Get-Content -Raw (Join-Path $project $f.source)
$five=Extract $patched 'public final static func ProcessItemAction\([^)]*fromInventory: Bool\)'
$six=Extract $patched 'public final static func ProcessItemAction\([^)]*quantity: Int32\)'
$source='public class CRFieldCareItemUse extends IScriptable {'+$use+'} public class CRFieldCareMenuSession extends IScriptable {'+($methods -join [Environment]::NewLine)+'} public class ItemActionsHelper extends IScriptable {'+$five+$six+'}'
$source=$source.Replace('wref<','ref<').Replace('public final static func','public static func')
$source=[regex]::Replace($source,'public func (\w+)\(','public static func CRInstance_$1(')
$generated=Join-Path $project ('staging/field-care-consume-'+[guid]::NewGuid().ToString('N')+'.reds')
[IO.File]::WriteAllText($generated,$source)
$code=Convert-RedscriptCore @($generated)
$code=[regex]::Replace($code,'public static (\w+) CRInstance_(\w+)\(','public $1 $2(')
$code=[regex]::Replace($code,'\b[nt]"','"')
$code=$code.Replace('TweakDBID','string').Replace('CName','string').Replace('String','string')
$code=[regex]::Replace($code,'\b(if|while) (?!\()([^{\r\n]+) \{','$1 ($2) {')
$code=$code.Replace('public class CRFieldCareItemUse :','public partial class CRFieldCareItemUse :').Replace('public class CRFieldCareMenuSession :','public partial class CRFieldCareMenuSession :').Replace('public class ItemActionsHelper :','public partial class ItemActionsHelper :')
$code=$code.Replace('public class CRMath {','public class CRMath { protected static GameInstance GetGameInstance(){return CareUseFixture.game;} ')
$fixture=@"
public class GameObject {} public class PlayerPuppet:GameObject {}
public class GameInstance { public static PlayerSystem GetPlayerSystem(GameInstance game){return CareUseFixture.players;} }
public class PlayerSystem { public PlayerPuppet player=new(); public GameObject GetLocalPlayerMainGameObject(){return player;} }
public class ItemID { public string id; public static string GetTDBID(ItemID item){return item.id;} public string GetTDBID(){return id;} }
public class gameItemData { public ItemID id=new(){id="Items.HealthBooster"}; public ItemID GetID(){return id;} }
public class ObjectAction_Record { public string name; public string ActionName(){return name;} }
public class TweakDBInterface {
 public static ObjectAction_Record GetObjectActionRecord(string id){return id=="missing"?null:new(){name=id};}
 public static object GetItemRecord(string id){return id;}
}
public class CRBodyRuntimePolicy {public static bool enabled=true;public static bool Enabled(){return enabled;}}
public class CRCombatRuntimePolicy {public static bool enabled=true;public static bool Enabled(){return enabled;}}
public class CRBodyRuntime { public static CRBodyRuntime instance=new();public bool owns=true,allowed=true;public static CRBodyRuntime Get(){return instance;}public bool OwnsLocalizedInjuries(){return owns;}public bool CanUseFieldCare(){return allowed;} }
public class DFGameStateService {public static DFGameStateService instance=new();public bool menu=true;public static DFGameStateService Get(){return instance;}public bool IsInAnyMenu(){return menu;}}
public partial class CRFieldCareItemUse { public static void Notify(string message){CareUseFixture.notices++;} }
public partial class CRFieldCareMenuSession {public CRFieldCareUI current;public static CRFieldCareMenuSession instance=new();public static CRFieldCareMenuSession Get(){return instance;} }
public class CRFieldCareUI {
 public bool alive=true,available=true;public int opens,teardowns;
 public bool IsAlive(){return alive;}public bool Open(){opens++;return available;}
 public void Teardown(){alive=false;teardowns++;CRFieldCareMenuSession.Get().Clear(this);}
}
public class DFMainSystem {public static DFMainSystem instance=new();public static DFMainSystem Get(){return instance;}public void DispatchItemConsumedEvent(object item,bool animate){CareUseFixture.events++;}}
public partial class ItemActionsHelper {
 public static bool wrappedMethod(GameInstance gi,GameObject executor,gameItemData data,string action,bool inventory){return wrappedMethod(gi,executor,data,action,inventory,1);}
 public static bool wrappedMethod(GameInstance gi,GameObject executor,gameItemData data,string action,bool inventory,int quantity){
  CareUseFixture.nativeCalls++;CareUseFixture.quantity=quantity;if(action=="Consume"){CareUseFixture.spent+=quantity;}return true;
 }
}
public class CareUseFixture {
 public static GameInstance game=new(); public static PlayerSystem players=new();public static int nativeCalls,spent,events,notices,quantity;
 public static void Reset(){nativeCalls=spent=events=notices=quantity=0;players=new();CRBodyRuntimePolicy.enabled=CRCombatRuntimePolicy.enabled=true;CRBodyRuntime.instance=new();DFGameStateService.instance=new();CRFieldCareMenuSession.instance=new();CRFieldCareMenuSession.Get().Register(new CRFieldCareUI());}
}
"@
Add-Type -TypeDefinition ($code+$fixture)
$script:checks=0
function Check($condition,$message){if(!$condition){throw $message};$script:checks++}
function Reset{[CareUseFixture]::Reset()}
function Run($quantity=0,$fromInventory=$true){
 $item=[gameItemData]::new()
 if($quantity -eq 0){return [ItemActionsHelper]::ProcessItemAction([CareUseFixture]::game,[CareUseFixture]::players.player,$item,'Consume',$fromInventory)}
 return [ItemActionsHelper]::ProcessItemAction([CareUseFixture]::game,[CareUseFixture]::players.player,$item,'Consume',$fromInventory,$quantity)
}
foreach($quantity in @(0,1,3)){
 foreach($fromInventory in @($true,$false)){
  Reset
  Check (!(Run $quantity $fromInventory)) 'Intercepted kit reported itself consumed'
  Check ([CareUseFixture]::nativeCalls -eq 0 -and [CareUseFixture]::spent -eq 0 -and [CareUseFixture]::events -eq 0) 'Kit reached native spending or legacy consumed dispatch'
  Check ([CRFieldCareMenuSession]::Get().current.opens -eq 1) 'Kit did not request regional care'
 }
}
foreach($gate in @('body-disabled','combat-disabled','legacy-owner')){
 Reset
 switch($gate){'body-disabled'{[CRBodyRuntimePolicy]::enabled=$false};'combat-disabled'{[CRCombatRuntimePolicy]::enabled=$false};'legacy-owner'{[CRBodyRuntime]::Get().owns=$false}}
 Check ((Run) -and [CareUseFixture]::nativeCalls -eq 1 -and [CareUseFixture]::events -eq 1) 'Unowned kit lost original consume behavior'
}
foreach($gate in @('unsafe','no-menu','no-owner','closed-menu','open-refused')){
 Reset
 switch($gate){'unsafe'{[CRBodyRuntime]::Get().allowed=$false};'no-menu'{[DFGameStateService]::Get().menu=$false};'no-owner'{[CRFieldCareMenuSession]::Get().current=$null};'closed-menu'{[CRFieldCareMenuSession]::Get().current.alive=$false};'open-refused'{[CRFieldCareMenuSession]::Get().current.available=$false}}
 Check (!(Run) -and [CareUseFixture]::spent -eq 0 -and [CareUseFixture]::events -eq 0 -and [CareUseFixture]::notices -eq 1) "Unavailable regional care spent kit or failed feedback: $gate"
}
foreach($case in @('other-item','npc','other-player','missing-item','missing-action','drop','equip')){
 Reset;$item=[gameItemData]::new();$executor=[CareUseFixture]::players.player;$action='Consume'
 switch($case){'other-item'{$item.id.id='Items.Water'};'npc'{$executor=[GameObject]::new()};'other-player'{$executor=[PlayerPuppet]::new()};'missing-item'{$item=$null};'missing-action'{$action='missing'};'drop'{$action='Drop'};'equip'{$action='EquipItem'}}
 Check (![CRFieldCareItemUse]::Intercept($executor,$item,$action)) "Intercept captured unrelated request: $case"
 Check ([CRFieldCareMenuSession]::Get().current.opens -eq 0 -and [CareUseFixture]::notices -eq 0) 'Unrelated request opened care or notified'
}
Reset
$session=[CRFieldCareMenuSession]::Get();$old=$session.current;$new=[CRFieldCareUI]::new()
$session.Register($new)
Check (!$old.alive -and $old.teardowns -eq 1 -and [object]::ReferenceEquals($session.current,$new)) 'New menu failed to retire old menu'
$session.Clear($old)
Check ([object]::ReferenceEquals($session.current,$new)) 'Old teardown cleared current registration'
$session.Register($new)
Check ($new.alive -and $new.teardowns -eq 0) 'Repeated registration destroyed current menu'
$new.Teardown()
Check ($null -eq $session.current -and !$session.RequestOpen()) 'Closed menu retained item-use routing'
Write-JsonFile ([ordered]@{passed=$true;checks=$script:checks;sourceSha256=Get-Sha256 $path;patchedDispatchSha256=$f.sha256;scope='Actual pre-consumption router, both patched DF overloads and transient menu registry with native-interface fixtures; excludes game item-use UI, animation, world-transfer and popup delivery'}) (Join-Path $project 'reports/field-care-consume-tests.json')
Write-Host "Field-care consume checks passed: $script:checks"