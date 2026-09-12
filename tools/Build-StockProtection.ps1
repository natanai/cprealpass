param([string]$TweakRoot='C:/Games/Steam/steamapps/common/Cyberpunk 2077/tools/redmod/tweaks')
. "$PSScriptRoot\Common.ps1"
$project=Get-ProjectRoot
$recipePath=Join-Path $project 'config/stock-protection.json'
$recipe=Get-Content -Raw $recipePath|ConvertFrom-Json
if($recipe.schemaVersion -ne 1){throw 'Unknown catalog schema'}
$profiles=@{}
foreach($p in $recipe.profiles){
 if($p.id -le 0 -or $profiles.ContainsKey([int]$p.id) -or $p.resistance -lt 0 -or $p.resistance -gt 100000 -or $p.durability -le 0 -or $p.durability -gt 1e9 -or $p.blunt -lt 0 -or $p.blunt -gt 1 -or @($p.regions|Where-Object{$_ -notin 1..6}).Count -gt 0 -or @($p.regions|Select-Object -Unique).Count -ne @($p.regions).Count){throw 'Invalid authored protection profile'}
 $profiles[[int]$p.id]=$p
}
$entries=[Collections.Generic.List[object]]::new();$excluded=[Collections.Generic.List[object]]::new();$seen=@{}
foreach($rule in $recipe.rules){
 if(-not $profiles.ContainsKey([int]$rule.profile)){throw 'Unknown profile in rule'}
 $path=Resolve-SafeChildPath $TweakRoot $rule.source
 $text=Get-Content -Raw $path
 if($text -notmatch '(?m)^package Items\s*$'){throw 'Expected Items namespace'}
 # Bundled TWEAK format: declarations and their closing braces begin in column 0.
 # Only the explicitly selected record families are parsed; not a general TWEAK interpreter.
 $records=[regex]::Matches($text,'(?ms)^([A-Za-z_]\w*)[ \t]*:[ \t]*([A-Za-z_]\w*)[ \t]*\r?\n\{\r?\n(.*?)^\}')
 $matched=0;$rejected=0
 foreach($r in $records){
  $name=$r.Groups[1].Value
  if($name -notmatch $rule.pattern){continue}
  if($rule.required -and $r.Value -notmatch [regex]::Escape($rule.required)){$rejected++;$excluded.Add([pscustomobject]@{record="Items.$name";source=$rule.source;parent=$r.Groups[2].Value;reason="Expected evidence absent: $($rule.required); remains unresolved"});continue}
  $id='Items.'+$name
  if($seen.ContainsKey($id)){throw "Duplicate stock mapping: $id"}
  $seen[$id]=$true;$matched++
  $entries.Add([pscustomobject]@{record=$id;profile=[int]$rule.profile;source=$rule.source;sourceSha256=Get-Sha256 $path;line=1+[regex]::Matches($text.Substring(0,$r.Index),"`n").Count;parent=$r.Groups[2].Value;reason=$rule.reason})
 }
 $selectedHeaders=@([regex]::Matches($text,'(?m)^([A-Za-z_]\w*)[ \t]*:[ \t]*[A-Za-z_]\w*[ \t]*\r?$')|Where-Object{$_.Groups[1].Value -match $rule.pattern})
 if($selectedHeaders.Count -ne $matched+$rejected){throw "Selected declarations could not all be parsed: $($rule.source)"}
 if($matched -eq 0){throw "Stock rule found no records: $($rule.pattern)"}
}
$lines=[Collections.Generic.List[string]]::new()
$lines.Add('// Generated from original config/stock-protection.json by Build-StockProtection.ps1.')
$lines.Add('// Stock identifiers only; no game assets or upstream source bodies copied.')
$lines.Add('// Provisional coefficients and coarse coverage; combat remains disabled pending validation.')
$lines.Add('import CyberpunkRealism.Combat.*')
$lines.Add('public class CRStockProtectionCatalog extends IScriptable {')
$lines.Add('  public static func Profile(id: Int32) -> ref<CRProtectionProfile> {')
$lines.Add('    let p: ref<CRProtectionProfile> = new CRProtectionProfile();')
$lines.Add('    p.resistanceJPerMm2 = -1.0;')
$lines.Add('    p.durabilityJ = -1.0;')
$lines.Add('    p.bluntTransferFraction = -1.0;')
foreach($p in $recipe.profiles){
 $lines.Add("    if id == $($p.id) {")
 $lines.Add('      p.mapped = true;')
 foreach($region in $p.regions){$field=@('head','torso','leftArm','rightArm','leftLeg','rightLeg')[$region-1];$lines.Add("      p.$field = true;")}
 foreach($pair in @(@('resistanceJPerMm2',$p.resistance),@('durabilityJ',$p.durability),@('bluntTransferFraction',$p.blunt))){$value=([double]$pair[1]).ToString('0.0######',[Globalization.CultureInfo]::InvariantCulture);$lines.Add("      p.$($pair[0]) = $value;")}
 $lines.Add('      return p;');$lines.Add('    }')
}
$lines.Add('    return p;');$lines.Add('  }')
$lines.Add('  public static func Resolve(record: TweakDBID) -> ref<CRProtectionProfile> {')
$lines.Add('    switch record {')
foreach($entry in $entries|Sort-Object record){$lines.Add('      case t"'+$entry.record+'": return CRStockProtectionCatalog.Profile('+ $entry.profile+');')}
$lines.Add('    }');$lines.Add('    return CRStockProtectionCatalog.Profile(0);');$lines.Add('  }');$lines.Add('}')
$output=Join-Path $project 'src/redscript/CyberpunkRealism/StockProtectionCatalog.reds'
[IO.File]::WriteAllText($output,($lines -join "`n")+"`n")
Write-JsonFile ([ordered]@{builtAtUtc=[DateTime]::UtcNow.ToString('o');recipeSha256=Get-Sha256 $recipePath;outputSha256=Get-Sha256 $output;count=$entries.Count;status=$recipe.status;entries=@($entries.ToArray());excluded=@($excluded.ToArray())}) (Join-Path $project 'reports/stock-protection-catalog.json')
Write-Host "Generated $($entries.Count) verified stock identifiers across $($recipe.profiles.Count) original protection profiles."