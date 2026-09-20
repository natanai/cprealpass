function Convert-RedscriptCore([string[]]$Paths) {
    $code=($Paths | ForEach-Object { Get-Content -Raw -LiteralPath $_ }) -join "`n"
    $code=[regex]::Replace($code,'(?m)^module .+$','')
    $code=[regex]::Replace($code,'(?m)//[^\r\n]*','')
    $code=$code.Replace('extends IScriptable',': CRMath')
    $code=[regex]::Replace($code,'ref<(\w+)>','$1')
    $code=[regex]::Replace($code,'public (?:persistent )?let (\w+): (\w+)','public $2 $1')
    $code=[regex]::Replace($code,'let (\w+): (\w+)','$2 $1')
    $code=[regex]::Replace($code,'Cast<(\w+)>\(([^()]*)\)','(($1)($2))')
    $code=[regex]::Replace($code,'(public|private) static func (\w+)\(([^)]*)\) -> (\w+)',[Text.RegularExpressions.MatchEvaluator]{param($m) $parameters=[regex]::Replace($m.Groups[3].Value,'(\w+): (\w+)','$2 $1');$m.Groups[1].Value+' static '+$m.Groups[4].Value+' '+$m.Groups[2].Value+'('+$parameters+')'})
    $code=[regex]::Replace($code,'(?m)^(\s*)(if|while) (.+) \{','$1$2 ($3) {')
    foreach($type in @(@('Float','float'),@('Bool','bool'),@('Int32','int'),@('Void','void'))) { $code=[regex]::Replace($code,'\b'+$type[0]+'\b',$type[1]) }
    $code=[regex]::Replace($code,'\b(\d+\.\d+)\b(?!f)','${1}f')
    'public class CRMath { protected static bool IsDefined(object value){return value != null;} protected static float MaxF(float a,float b){return System.Math.Max(a,b);} protected static float MinF(float a,float b){return System.Math.Min(a,b);} protected static float ClampF(float x,float a,float b){return System.Math.Clamp(x,a,b);} }'+$code
}
