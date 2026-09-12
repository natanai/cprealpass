. "$PSScriptRoot/../tools/Common.ps1"
. "$PSScriptRoot/CoreHarness.ps1"
$project=Get-ProjectRoot
function Extract([string]$source,[string]$pattern){
 $match=[regex]::Match($source,$pattern)
 if(!$match.Success){throw "Missing method: $pattern"}
 $start=$source.IndexOf('{',$match.Index);$depth=1;$end=$start+1
 while($depth -gt 0 -and $end -lt $source.Length){if($source[$end] -eq '{'){$depth++};if($source[$end] -eq '}'){$depth--};$end++}
 if($depth -ne 0){throw 'Unbalanced method'}
 return $source.Substring($match.Index,$end-$match.Index)
}
$path=Join-Path $project 'src/redscript/CyberpunkRealism/FieldCareUI.reds'
$s=Get-Content -Raw $path
$ui=$s.Substring(0,$s.IndexOf('public class CRFieldCarePopup'))
$popup=$s.Substring($s.IndexOf('public class CRFieldCarePopup'))
$uiMethods=@('IsAlive','Teardown','PopupClosed','Navigate','Confirm','ControlName','Activate','OnRelease')|ForEach-Object{Extract $ui "(?:public|private) (?:cb )?func $_\("}
$popupMethods=@('SetOwner','UseCursor','CanInteract','OnShown','Close','OnDetach','OnGlobalReleaseInput')|ForEach-Object{Extract $popup "(?:public|protected) (?:cb )?func $_\("}
$nl=[Environment]::NewLine
$source="public class CRFieldCareUI extends IScriptable {"+$nl+($uiMethods -join $nl)+$nl+"}"+$nl+"public class CRFieldCarePopup extends CustomPopup {"+$nl+($popupMethods -join $nl)+$nl+"}"
$source=$source.Replace('wref<','ref<').Replace('super.','base.')
$source=[regex]::Replace($source,'(?:public|private|protected) (?:cb )?func (\w+)\(([^)]*)\)(\s*\{)', 'public static func CRInstance_$1($2) -> Void$3')
$source=[regex]::Replace($source,'(?:public|private|protected) (?:cb )?func (\w+)\(', 'public static func CRInstance_$1(')
$source=$source.Replace('CRInstance_CRInstance_','CRInstance_')
$generated=Join-Path $project ('staging/field-care-ui-'+[guid]::NewGuid().ToString('N')+'.reds')
[IO.File]::WriteAllText($generated,$source)
$code=Convert-RedscriptCore @($generated)
$code=[regex]::Replace($code,'public static (\w+) CRInstance_(\w+)\(','public $1 $2(')
$code=$code.Replace('public class CRFieldCareUI :','public partial class CRFieldCareUI :').Replace('public class CRFieldCarePopup extends CustomPopup','public partial class CRFieldCarePopup : CustomPopup')
$code=[regex]::Replace($code,'\bn"','"')
$code=$code.Replace('CName','string').Replace('String','string')
$code=$code.Replace('public void Close()','public override void Close()').Replace('public void OnShown()','public override void OnShown()').Replace('public void OnDetach()','public override void OnDetach()').Replace('public bool OnGlobalReleaseInput(','public override bool OnGlobalReleaseInput(')
$code=$code.Replace('public class CRMath {','public class CRMath { protected static void ArrayClear<T>(System.Collections.Generic.List<T> values){values.Clear();} protected static int Clamp(int x,int min,int max){return System.Math.Clamp(x,min,max);} ')
$code=[regex]::Replace($code,'\b(if|while|switch) (?!\()([^{\r\n]+) \{','$1 ($2) {')
$code=[regex]::Replace($code,'(default: feedback = [^;]+;)(\s*})','$1 break;$2')
$fixture=@"
public class inkWidget { public string name; public string GetName(){return name;} }
public class inkPointerEvent {
 public string action; public bool handled; public inkWidget target;
 public bool IsHandled(){return handled;} public bool IsAction(string value){return action==value;}
 public inkWidget GetTarget(){return target;} public void Handle(){handled=true;}
}
public class CustomPopup : CRMath {
 public bool initialized=true,top=true; public int closeCalls,detachCalls;
 public bool IsInitialized(){return initialized;} public bool IsTopPopup(){return top;}
 public virtual void Close(){closeCalls++;}
 public virtual void OnShown(){} public virtual void OnDetach(){detachCalls++;}
 public virtual bool OnGlobalReleaseInput(inkPointerEvent evt){
  if(evt.action=="cancel"&&!evt.handled&&top){Close();evt.Handle();return true;} return false;
 }
}
public partial class CRFieldCareUI {
 public bool alive=true; public int region=2,focus=1,opens; public CRFieldCarePopup popup;
 public object message,injurySummary; public string feedback;
 public System.Collections.Generic.List<object> controls=new(),regionButtons=new();
 public void Open(){opens++;} public void Refresh(string text){feedback=text;}
 public string RegionName(int region){return region.ToString();}
}
public partial class CRFieldCarePopup { public CRFieldCareUI owner; public bool closing; }
public class CRFieldCareMenuSession { public static CRFieldCareMenuSession instance=new(); public static CRFieldCareMenuSession Get(){return instance;} public void Clear(CRFieldCareUI ui){} }
public class CRBodyRuntime {
 public static CRBodyRuntime instance=new(); public int region,kind,calls,outcome=8;
 public static CRBodyRuntime Get(){return instance;}
 public int UseFieldCare(int region,int kind){this.region=region;this.kind=kind;calls++;return outcome;}
}
public class CRFieldCareActionRuntime {
 public static CRFieldCareActionRuntime instance=new(); public int cancellations;
 public static CRFieldCareActionRuntime Get(){return instance;}
 public void Cancel(bool ignored){cancellations++;} public string Status(){return "Queued; leave backpack to begin";}
}
"@
Add-Type -TypeDefinition ($code+$fixture)
$script:checks=0
function Check($condition,$message){if(!$condition){throw $message};$script:checks++}
function Setup{
 $script:ui=[CRFieldCareUI]::new();$script:popup=[CRFieldCarePopup]::new()
 $popup.SetOwner($ui);$ui.popup=$popup
 [CRBodyRuntime]::instance=[CRBodyRuntime]::new()
 [CRFieldCareActionRuntime]::instance=[CRFieldCareActionRuntime]::new()
}
function Event($action,$name=''){
 $evt=[inkPointerEvent]::new();$evt.action=$action;$evt.target=[inkWidget]::new();$evt.target.name=$name;return $evt
}
Setup
Check ($popup.CanInteract() -and $popup.UseCursor()) 'Attached top popup unusable'
foreach($pair in @(@('CRCareHead',1),@('CRCareTorso',2),@('CRCareLeftArm',3),@('CRCareRightArm',4),@('CRCareLeftLeg',5),@('CRCareRightLeg',6))){
 Check ($ui.Activate($pair[0]) -and $ui.region -eq $pair[1]) 'Region routing failed'
 $ui.Activate('CRCareDress')|Out-Null
 Check ([CRBodyRuntime]::instance.region -eq $pair[1] -and [CRBodyRuntime]::instance.kind -eq 2) 'Dressing routed to wrong region'
 $ui.Activate('CRCareSupport')|Out-Null
 Check ([CRBodyRuntime]::instance.region -eq $pair[1] -and [CRBodyRuntime]::instance.kind -eq 3) 'Support routed to wrong region'
}
Check ($ui.feedback -like 'Queued*') 'Queue feedback not propagated'
$count=[CRBodyRuntime]::instance.calls
$ui.Activate('CRCareCancel')|Out-Null
Check ([CRFieldCareActionRuntime]::instance.cancellations -eq 1 -and [CRBodyRuntime]::instance.calls -eq $count) 'Cancel dispatched treatment'
Check (!$ui.Activate('unknown')) 'Unknown control treated as action'
foreach($gate in @('background','closing','detached','dead-owner')){
 Setup
 switch($gate){'background'{$popup.top=$false};'closing'{$popup.closing=$true};'detached'{$popup.initialized=$false};'dead-owner'{$ui.alive=$false}}
 Check (!$ui.Activate('CRCareDress') -and [CRBodyRuntime]::instance.calls -eq 0) "Inactive popup accepted paid action: $gate"
}
Setup
$ui.Navigate(-20);Check ($ui.focus -eq 0) 'Navigation underflow'
$ui.Navigate(30);Check ($ui.focus -eq 9) 'Navigation overflow'
$ui.focus=3
$evt=Event 'navigate_down';Check ($popup.OnGlobalReleaseInput($evt) -and $evt.handled -and $ui.focus -eq 6) 'Directional input not handled'
$evt=Event 'proceed';Check ($popup.OnGlobalReleaseInput($evt) -and $evt.handled -and [CRBodyRuntime]::instance.calls -eq 1) 'Confirmation not routed'
$popup.OnGlobalReleaseInput($evt)|Out-Null
Check ([CRBodyRuntime]::instance.calls -eq 1) 'Handled confirmation repeated treatment'
$evt=Event 'click' 'CRCareSupport';Check ($ui.OnRelease($evt) -and $evt.handled -and [CRBodyRuntime]::instance.kind -eq 3) 'Mouse treatment dispatch failed'
$ui.OnRelease($evt)|Out-Null
Check ([CRBodyRuntime]::instance.calls -eq 2) 'Handled mouse release repeated treatment'
$evt=Event 'cancel';Check ($popup.OnGlobalReleaseInput($evt) -and $evt.handled -and $popup.closing -and $popup.closeCalls -eq 1) 'Cancel failed to close through base lifecycle'
$popup.Close();Check ($popup.closeCalls -eq 1) 'Repeated close queued duplicate teardown'
Setup
$ui.Teardown();Check (!$ui.alive -and $popup.closeCalls -eq 1 -and !$popup.CanInteract()) 'Menu teardown left controls active'
$ui.Teardown();Check ($popup.closeCalls -eq 1) 'Repeated menu teardown queued duplicate close'
Setup
$popup.initialized=$false;$ui.Teardown()
Check ($popup.closeCalls -eq 0) 'Unattached popup tried to close before native initialization'
$popup.initialized=$true;$popup.OnShown()
Check ($popup.closeCalls -eq 1 -and !$popup.CanInteract()) 'Popup attached after menu exit remained interactive'
Setup
$ui.controls.Add([object]::new());$ui.regionButtons.Add([object]::new())
$replacement=[CRFieldCarePopup]::new();$ui.popup=$replacement
$popup.OnDetach()
Check ([object]::ReferenceEquals($ui.popup,$replacement) -and $ui.controls.Count -eq 1) 'Stale popup detach cleared newer controls'
$ui.popup=$popup;$popup.OnDetach()
Check ($null -eq $ui.popup -and $ui.controls.Count -eq 0 -and $ui.regionButtons.Count -eq 0) 'Owned popup detach left controls retained'
Write-JsonFile ([ordered]@{passed=$true;checks=$script:checks;sourceSha256=Get-Sha256 $path;scope='Actual control routing, navigation and lifecycle methods with native popup/input fixtures; excludes rendering, native manager delivery, weak-reference GC and engine focus'})(Join-Path $project 'reports/field-care-ui-tests.json')
Write-Host "Field-care UI checks passed: $script:checks"