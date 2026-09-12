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
$recipe=Get-Content -Raw (Join-Path $project 'config/patches/realpass-e3-nameplates.json')|ConvertFrom-Json
$supportPath=Join-Path $project $recipe.supportSource
$support=Get-Content -Raw $supportPath
$methods=@('RealpassScannedCrowdAllowed','RealpassScannedCrowdName','RealpassSetNameVisible','RealpassPrepareName')|ForEach-Object{Extract $support "public func $_\("}
$projection=Extract $support 'protected cb func OnScreenProjectionUpdate\('
# The replacement body is the actual build recipe, not a copy of the resolver.
$resolver='public func GetCustomNPCName(puppet: wref<gamePuppetBase>, data: NPCNextToTheCrosshair) -> String {'+[Environment]::NewLine+$recipe.patches[0].edits[0].replace+[Environment]::NewLine+'}'
$source='public class NameplateVisualsLogicController extends IScriptable {'+$resolver+($methods -join [Environment]::NewLine)+'} public class NpcNameplateGameController extends IScriptable {'+$projection+'}'
$source=$source.Replace('wref<','ref<').Replace('protected cb func','public func')
$source=[regex]::Replace($source,'public func (\w+)\(','public static func CRInstance_$1(')
$generated=Join-Path $project ('staging/nameplate-tests-'+[guid]::NewGuid().ToString('N')+'.reds')
[IO.File]::WriteAllText($generated,$source)
$code=Convert-RedscriptCore @($generated)
$code=[regex]::Replace($code,'public static (\w+) CRInstance_(\w+)\(','public $1 $2(')
$code=[regex]::Replace($code,'\b[nt]"','"')
$code=[regex]::Replace($code,'\bString\b','string')
$code=$code.Replace('public class NameplateVisualsLogicController :','public partial class NameplateVisualsLogicController :').Replace('public class NpcNameplateGameController :','public partial class NpcNameplateGameController :')
$code=$code.Replace('public class CRMath {','public class CRMath { protected static bool IsStringValid(string s){return !string.IsNullOrEmpty(s);} protected static Defs GetAllBlackboardDefs(){return new Defs();} ')
$fixture=@"
public class Defs {public PuppetDefs Puppet=new();} public class PuppetDefs {public bool HideNameplate;}
public class Blackboard {public bool hidden;public bool GetBool(bool key){return hidden;}}
public class GameObject { public bool attached=true,scanned=true,civilian=true,hidden,turret;public string displayName="ALEX RIVERA";public int displayReads;public Blackboard blackboard=new();public ScriptedPuppetPS ps=new();public bool IsAttached(){return attached;}public bool IsScanned(){return scanned;}public bool IsCharacterCivilian(){return civilian;}public bool GetBoolFromCharacterTweak(string key){return hidden;}public Blackboard GetBlackboard(){return blackboard;}public string GetRecordID(){return "Character.Crowd";}public ScriptedPuppetPS GetPS(){return ps;}public bool IsTurret(){return turret;}public string GetDisplayName(){displayReads++;return displayName;}}
public class gamePuppetBase:GameObject{} public class NPCPuppet:gamePuppetBase{}
public class ScriptedPuppetPS {public bool alternative;public string forced;public bool HasAlternativeName(){return alternative;}public string GetForcedScannerPreset(){return forced;}}
public class Character_Record {public UINameplate_Record nameplate=new();public ScannerModuleVisibilityPreset_Record preset=new();public UINameplate_Record UiNameplate(){return nameplate;}public ScannerModuleVisibilityPreset_Record ScannerModulePreset(){return preset;}}
public class UINameplate_Record {public bool enabled=true;public string id="UINameplate.CrowdSettings";public bool Enabled(){return enabled;}public string GetID(){return id;}}
public class ScannerModuleVisibilityPreset_Record {public bool show=true;public bool ShoulShowName(){return show;}}
public class TweakDBInterface {public static Character_Record character=new();public static ScannerModuleVisibilityPreset_Record forced=new();public static Character_Record GetCharacterRecord(string id){return character;}public static ScannerModuleVisibilityPreset_Record GetScannerModuleVisibilityPresetRecord(string id){return forced;}}
public class TDBID {public static bool IsValid(string id){return !string.IsNullOrEmpty(id);}}
public enum EAIAttitude {AIA_Neutral,AIA_Friendly,AIA_Hostile}
public struct NPCNextToTheCrosshair {public GameObject npc;public string name;public EAIAttitude attitude;}
public class Widget {public bool visible;public string text="";public void SetVisible(bool value){visible=value;}}
public class inkTextRef {public static string GetText(Widget w){return w.text;}public static void SetText(Widget w,string text){w.text=text;}public static void SetVisible(Widget w,bool visible){w.visible=visible;}}
public class inkWidgetRef {public static bool IsVisible(Widget w){return w.visible;}public static void SetVisible(Widget w,bool visible){w.visible=visible;}}
public class gameuiScreenProjectionsData {}
public partial class NameplateVisualsLogicController {public bool m_isQuestTarget,m_forceHide,m_npcDefeated,m_isBoss,m_isElite;public bool m_npcNamesEnabled=true;public NPCNextToTheCrosshair m_cachedIncomingData;public Widget m_nameTextMain=new(),m_nameFrame=new(),m_nameBG=new();}
public partial class NpcNameplateGameController {
 public NameplateVisualsLogicController m_visualController=new();public GameObject m_bufferedGameObject;public Widget m_displayName=new();public bool outerAllowed=true,nativeNameAllowed;public bool visible;public int nativeCalls;
 public bool GetNameplateVisible(){return visible;}
 public bool wrappedMethod(gameuiScreenProjectionsData projections){nativeCalls++;visible=outerAllowed&&m_visualController!=null&&m_visualController.m_nameTextMain.visible;m_displayName.visible=nativeNameAllowed;return true;}
}
public static class NameplateFixture {public static NpcNameplateGameController controller;public static NPCPuppet npc;public static void Reset(bool shared){controller=new();npc=new();controller.m_bufferedGameObject=npc;controller.m_visualController.m_cachedIncomingData=new(){npc=npc,name="",attitude=EAIAttitude.AIA_Neutral};if(shared){controller.m_displayName=controller.m_visualController.m_nameTextMain;}TweakDBInterface.character=new();TweakDBInterface.forced=new();}public static void Run(){controller.OnScreenProjectionUpdate(new());}}
"@
Add-Type -TypeDefinition ($code+$fixture)
$script:checks=0
function Check($condition,$message){if(!$condition){throw $message};$script:checks++}
function Reset($shared=$false){[NameplateFixture]::Reset($shared)}
function Run{[NameplateFixture]::Run()}
function Visual{return [NameplateFixture]::controller.m_visualController}
function SetData([string]$name){$d=(Visual).m_cachedIncomingData;$d.name=$name;(Visual).m_cachedIncomingData=$d}
foreach($shared in @($false,$true)){
 Reset $shared
 Run
 Check ((Visual).m_nameTextMain.text -eq 'ALEX RIVERA' -and (Visual).m_nameTextMain.visible -and (Visual).m_nameFrame.visible -and !(Visual).m_nameBG.visible) 'Scanned civilian did not get readable name and frame'
 Check ([NameplateFixture]::controller.nativeCalls -eq 1 -and [NameplateFixture]::controller.m_displayName.visible) 'Native projection was bypassed or generic crowd name stayed hidden'
 [NameplateFixture]::npc.scanned=$false
 Run
 Check (!(Visual).m_nameTextMain.visible -and !(Visual).m_nameFrame.visible -and !(Visual).m_nameBG.visible) 'Unscanned civilian leaked text or empty frame'
 [NameplateFixture]::npc.scanned=$true
 Run
 Check ((Visual).m_nameTextMain.visible -and (Visual).m_nameFrame.visible) 'Completed scan could not recover from preceding hidden frame'
 SetData 'NATIVE NAME'
 Run
 Check ((Visual).m_nameTextMain.text -eq 'NATIVE NAME') 'Native focus name was not preferred'
 SetData ''
 [NameplateFixture]::npc.displayName=''
 Run
 Check (!(Visual).m_nameTextMain.visible -and !(Visual).m_nameFrame.visible) 'Empty entity name left an empty rectangle'
 Reset $shared
 [NameplateFixture]::controller.outerAllowed=$false
 Run
 Check (!(Visual).m_nameTextMain.visible -and !(Visual).m_nameFrame.visible -and !(Visual).m_nameBG.visible) 'Native scene/distance/mount/projection rejection was overridden'
 Reset $shared
 [NameplateFixture]::controller.nativeNameAllowed=$true
 [TweakDBInterface]::character.nameplate.id='UINameplate.QuestSettings'
 (Visual).m_isQuestTarget=$true
 SetData 'AUTHORED QUEST NAME'
 Run
 Check ((Visual).m_nameTextMain.text -eq 'AUTHORED QUEST NAME' -and (Visual).m_nameTextMain.visible) 'Legitimate native quest name was lost'
 Check ([NameplateFixture]::npc.displayReads -eq 0) 'Quest name caused an entity-name fallback'
 Reset $shared
 (Visual).m_isBoss=$true
 Run
 Check ((Visual).m_nameBG.visible -and !(Visual).m_nameFrame.visible) 'Elite name did not synchronize the E3 fill instead of border'
}
foreach($gate in @('unscanned','not-civilian','quest','detached','hide-nametag','hide-blackboard','missing-blackboard','missing-character','missing-nameplate','disabled','quest-record','custom-record','missing-ps','alternative-name','missing-preset','scanner-hidden','forced-hidden','forced-missing')){
 Reset
 switch($gate){
  'unscanned'{[NameplateFixture]::npc.scanned=$false}
  'not-civilian'{[NameplateFixture]::npc.civilian=$false}
  'quest'{(Visual).m_isQuestTarget=$true}
  'detached'{[NameplateFixture]::npc.attached=$false}
  'hide-nametag'{[NameplateFixture]::npc.hidden=$true}
  'hide-blackboard'{[NameplateFixture]::npc.blackboard.hidden=$true}
  'missing-blackboard'{[NameplateFixture]::npc.blackboard=$null}
  'missing-character'{[TweakDBInterface]::character=$null}
  'missing-nameplate'{[TweakDBInterface]::character.nameplate=$null}
  'disabled'{[TweakDBInterface]::character.nameplate.enabled=$false}
  'quest-record'{[TweakDBInterface]::character.nameplate.id='UINameplate.QuestSettings'}
  'custom-record'{[TweakDBInterface]::character.nameplate.id='UINameplate.HiddenStoryCharacter'}
  'missing-ps'{[NameplateFixture]::npc.ps=$null}
  'alternative-name'{[NameplateFixture]::npc.ps.alternative=$true}
  'missing-preset'{[TweakDBInterface]::character.preset=$null}
  'scanner-hidden'{[TweakDBInterface]::character.preset.show=$false}
  'forced-hidden'{[NameplateFixture]::npc.ps.forced='Forced';[TweakDBInterface]::forced.show=$false}
  'forced-missing'{[NameplateFixture]::npc.ps.forced='Forced';[TweakDBInterface]::forced=$null}
 }
 Run
 Check (!(Visual).m_nameTextMain.visible -and !(Visual).m_nameFrame.visible) ("Denied fallback left name decorations: "+$gate)
 Check ([NameplateFixture]::npc.displayReads -eq 0) ("Denied fallback read entity name: "+$gate)
}
foreach($gate in @('names-disabled','force-hide','defeated','turret')){
 Reset
 SetData 'KNOWN NAME'
 [NameplateFixture]::controller.nativeNameAllowed=$true
 switch($gate){'names-disabled'{(Visual).m_npcNamesEnabled=$false};'force-hide'{(Visual).m_forceHide=$true};'defeated'{(Visual).m_npcDefeated=$true};'turret'{[NameplateFixture]::npc.turret=$true}}
 Run
 Check (!(Visual).m_nameTextMain.visible -and !(Visual).m_nameFrame.visible -and !(Visual).m_nameBG.visible) ("Name UI ignored gate: "+$gate)
}
Reset
[TweakDBInterface]::character.preset.show=$false
[NameplateFixture]::npc.ps.forced='Forced'
Run
Check ((Visual).m_nameTextMain.visible) 'Permitted forced scanner preset did not supersede the ordinary preset'
Reset
[NameplateFixture]::controller.m_visualController=$null
Run
Check ([NameplateFixture]::controller.nativeCalls -eq 1) 'Missing visual controller bypassed native projection'
Reset
$d=(Visual).m_cachedIncomingData;$d.npc=$null;(Visual).m_cachedIncomingData=$d
[NameplateFixture]::controller.m_bufferedGameObject=$null
Run
Check (!(Visual).m_nameTextMain.visible -and !(Visual).m_nameFrame.visible) 'Detached focus retained a stale name frame'
Write-JsonFile ([ordered]@{passed=$true;checks=$script:checks;supportSha256=(Get-Sha256 $supportPath);recipeSha256=(Get-Sha256 (Join-Path $project 'config/patches/realpass-e3-nameplates.json'));scope='Actual name resolution, visibility helpers and projection wrapper executed with controlled native API fixtures, testing distinct and aliased native text widget references. Native archive widget bindings/font rendering and actual crowd records require game verification.'}) (Join-Path $project 'reports/realpass-nameplates-tests.json')
Write-Host "realpass nameplate behavior checks passed: $script:checks"
