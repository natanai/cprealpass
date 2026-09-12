param([string]$ManifestPath='manifest/m3-body-runtime-prototype.deployment.json')
. "$PSScriptRoot/../tools/Common.ps1"
. "$PSScriptRoot/CoreHarness.ps1"
$project=Get-ProjectRoot
$runtimePath=Join-Path $project 'src/redscript/CyberpunkRealism/BodyInteractionRuntime.reds'
$localePath=Join-Path $project 'src/redscript/CyberpunkRealism/RealpassLocalization.reds'
$tweakPath=Join-Path $project 'src/tweaks/realpass-interactions.yaml'
$builderPath=Join-Path $project 'tools/Build-BodyRuntime.ps1'
function ExtractClass([string]$source,[string]$name) {
 $match=[regex]::Match($source,'public class '+[regex]::Escape($name)+'\b')
 if(!$match.Success){throw "Missing actual class $name"}
 $start=$source.IndexOf('{',$match.Index);$depth=1;$end=$start+1
 while($depth -gt 0 -and $end -lt $source.Length){
  if($source[$end] -eq '{'){$depth++}
  if($source[$end] -eq '}'){$depth--}
  $end++
 }
 if($depth -ne 0){throw "Unbalanced class $name"}
 $source.Substring($match.Index,$end-$match.Index)
}
# Translate the actual action class, excluding unrelated native device callbacks.
$converted=Convert-RedscriptCore @($runtimePath)
$code=(ExtractClass $converted 'CRMath')+(ExtractClass $converted 'CRUseToilet')
$code=$code.Replace('extends ActionBool',': ActionBool')
$code=[regex]::Replace($code,'public func (\w+)\(\) -> (\w+)','public $2 $1()')
$code=[regex]::Replace($code,'\b(String|CName|TweakDBID)\b','string')
$code=[regex]::Replace($code,'\b[nt]"','"')
$fixture=@"
public class BoolProperty {
 public string name,trueKey,falseKey; public bool value;
}
public class DeviceActionPropertyFunctions {
 public static BoolProperty SetUpProperty_Bool(string name,bool value,string trueKey,string falseKey){
  return new(){name=name,value=value,trueKey=trueKey,falseKey=falseKey};
 }
}
public class ChoiceRecord {
 public string id,name,caption,icon,input;
 public ChoiceRecord Copy(){return (ChoiceRecord)MemberwiseClone();}
}
public class InteractionChoiceData {
 public string caption,localizedName;
 public System.Collections.Generic.List<string> captionParts=new();
}
public class InteractionChoiceCaption {
 public static void Clear(System.Collections.Generic.List<string> parts){parts.Clear();}
 public static void AddTextPart(System.Collections.Generic.List<string> parts,string text){parts.Add(text);}
}
public class ActionBool:CRMath {
 public string actionName; public BoolProperty prop; public InteractionChoiceData interactionChoice=new();
 protected static string GetLocalizedTextByKey(string key){return ToiletFixture.Text(key);}
}
public class ToiletFixture {
 public static System.Collections.Generic.Dictionary<string,string> locale=new();
 public static System.Collections.Generic.Dictionary<string,ChoiceRecord> records=new();
 public static string Text(string key){return locale[key];}
 public static void Reset(){
  locale.Clear();records.Clear();locale["VanillaFlushCaption"]="Flush";
  records["Interactions.Flush"]=new(){id="Interactions.Flush",name="Flush",caption="VanillaFlushCaption",icon="vanilla_toilet_icon",input="vanilla_device_input"};
 }
 public static void Clone(string id,string basis,string name,string caption){
  var record=records[basis].Copy();record.id=id;record.name=name;record.caption=caption;records.Add(id,record);
 }
 // Controlled native boundary: the engine resolves this record to localizedName.
 // This deliberately does not claim to execute TweakXL or E3's native widget rendering.
 public static InteractionChoiceData ResolveChoice(CRUseToilet action){
  var record=records[action.GetTweakDBChoiceID()];
  return new(){localizedName=Text(record.caption),caption=Text(record.caption)};
 }
}
"@
Add-Type -TypeDefinition ($code+$fixture)
$script:checks=0
function Check($condition,[string]$message){if(!$condition){throw $message};$script:checks++}
# Read the tiny declarative record without accepting unrelated YAML records or fields.
$yaml=[IO.File]::ReadAllText($tweakPath)
$meaningful=@($yaml -split '\r?\n'|Where-Object {$_ -notmatch '^\s*(#.*)?$'})
Check ($meaningful.Count -eq 4) 'Interaction tweak unexpectedly has additional records or fields'
$recordMatch=[regex]::Match($meaningful[0],'^(Interactions\.[A-Za-z0-9_]+):$')
Check $recordMatch.Success 'Interaction record header invalid'
$recordID=$recordMatch.Groups[1].Value
$fields=@{}
foreach($line in $meaningful[1..3]){
 $fieldMatch=[regex]::Match($line,'^  (\$base|name|caption): ([A-Za-z0-9_.]+)$')
 Check $fieldMatch.Success 'Unsupported interaction record field'
 $key=$fieldMatch.Groups[1].Value
 Check (!$fields.ContainsKey($key)) 'Duplicate interaction record field'
 $fields[$key]=$fieldMatch.Groups[2].Value
}
Check ($recordID -eq 'Interactions.RealpassUseToilet' -and $recordID -ne $fields['$base']) 'Custom choice overwrites its source record'
Check ($fields['$base'] -eq 'Interactions.Flush') 'Custom choice does not inherit the native toilet input and icon'
$locale=[IO.File]::ReadAllText($localePath)
$localeEntries=[regex]::Matches($locale,'this\.Text\(("(?:\\.|[^"\\])*"), ("(?:\\.|[^"\\])*")\);')
$found=@($localeEntries|Where-Object {(ConvertFrom-Json $_.Groups[1].Value) -eq $fields['caption']})
Check ($found.Count -eq 1) 'Interaction caption locale key absent or ambiguous'
$caption=ConvertFrom-Json $found[0].Groups[2].Value
Check ($caption -ceq 'Use toilet') 'Player-facing action caption is not Use toilet'
[ToiletFixture]::Reset()
[ToiletFixture]::locale[$fields['caption']]=$caption
[ToiletFixture]::Clone($recordID,$fields['$base'],$fields['name'],$fields['caption'])
$action=[CRUseToilet]::new()
$action.SetProperties()
Check ($action.actionName -eq 'CRUseToilet' -and $action.prop.name -eq 'CRUseToilet' -and $action.prop.value) 'Custom device action identity/property changed'
Check ($action.prop.trueKey -eq $fields['caption'] -and $action.prop.falseKey -eq $fields['caption']) 'Action properties do not use the cloned record caption key'
Check ($action.GetTweakDBChoiceRecord() -eq $fields['name']) 'Action record name does not resolve the custom metadata'
Check ($action.GetTweakDBChoiceID() -eq $recordID) 'Action record ID still points at Flush or unrelated metadata'
$choice=[ToiletFixture]::ResolveChoice($action)
$action.interactionChoice=$choice
$choice.captionParts.Add('Flush')
$choice.captionParts.Add('stale custom caption')
$action.SetBodyCaption()
Check ($choice.caption -ceq $caption -and $choice.localizedName -ceq $caption) 'Caption and E3 record-derived localizedName disagree'
Check ($choice.captionParts.Count -eq 1 -and $choice.captionParts[0] -ceq $choice.localizedName) 'Caption parts retain Flush or disagree with the visible metadata caption'
$action.SetBodyCaption()
Check ($choice.captionParts.Count -eq 1) 'Repeated caption refresh duplicates text parts'
Check (!$action.completedByDevice -and !$action.bodyApplied) 'Creating or relabeling the action marks it completed'
$vanilla=[ToiletFixture]::records['Interactions.Flush']
$custom=[ToiletFixture]::records[$recordID]
Check ($vanilla.name -ceq 'Flush' -and [ToiletFixture]::Text($vanilla.caption) -ceq 'Flush') 'Cloning/relabeling changed vanilla Flush'
Check ($custom.icon -eq $vanilla.icon -and $custom.input -eq $vanilla.input) 'Cloned choice lost inherited native icon/input defaults'

# A changed translation must drive all visible paths through the same key, not a hard-coded string.
[ToiletFixture]::locale[$fields['caption']]='Translated toilet action'
$action.interactionChoice=[ToiletFixture]::ResolveChoice($action)
$action.SetBodyCaption()
Check ($action.interactionChoice.caption -ceq 'Translated toilet action' -and $action.interactionChoice.captionParts[0] -ceq $action.interactionChoice.localizedName) 'Localized metadata and explicit caption diverge after translation'
Check ([ToiletFixture]::Text($vanilla.caption) -ceq 'Flush') 'Changing the custom translation changes vanilla Flush'
# Check the actual build output includes the new metadata, not just the source declaration.
$builder=[IO.File]::ReadAllText($builderPath)
Check ($builder.Contains('src/tweaks/realpass-interactions.yaml') -and $builder.Contains("destination='r6/tweaks/realpass/realpass-interactions.yaml'")) 'Body builder omits the required native choice record'
$manifest=Get-Content -Raw (Resolve-SafeChildPath $project $ManifestPath)|ConvertFrom-Json
$dependencies=@(
 [pscustomobject]@{destination='r6/tweaks/realpass/realpass-interactions.yaml';source=$tweakPath}
 [pscustomobject]@{destination='r6/scripts/CyberpunkRealism/BodyInteractionRuntime.reds';source=$runtimePath}
 [pscustomobject]@{destination='r6/scripts/CyberpunkRealism/RealpassLocalization.reds';source=$localePath}
)
foreach($dependency in $dependencies){
 $files=@($manifest.files|Where-Object destination -eq $dependency.destination)
 Check ($files.Count -eq 1) "Staged choice dependency missing or duplicated: $($dependency.destination)"
 $file=$files[0]
 Check ($file.sha256 -eq (Get-Sha256 $dependency.source) -and (Get-Sha256 (Resolve-SafeChildPath $project $file.source)) -eq $file.sha256) "Staged choice dependency stale: $($dependency.destination)"
}
$report=[ordered]@{
 testedAtUtc=[DateTime]::UtcNow.ToString('o')
 passed=$true
 checks=$script:checks
 buildId=$manifest.buildId
 manifestPath=$ManifestPath
 sources=@(@($runtimePath,$localePath,$tweakPath,$builderPath)|ForEach-Object{[ordered]@{path=$_;sha256=Get-Sha256 $_}})
 scope='Actual CRUseToilet property/record/caption methods translated through CoreHarness with controlled native metadata/localization boundaries. Checks cloned-record routing, shared caption key and parts, stale caption clearing, repeat refresh, unchanged Flush and matching staged dependencies. Native TweakXL record creation, engine localizedName delivery, device callbacks and E3 rendering remain unverified.'
}
Write-JsonFile $report (Join-Path $project 'reports/realpass-interaction-tests.json')
Write-Host "PASS: $script:checks realpass toilet choice checks."
