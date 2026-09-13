. "$PSScriptRoot\..\tools\Common.ps1"
. "$PSScriptRoot\CoreHarness.ps1"
$project=Get-ProjectRoot
$nativePath=Join-Path $project 'src/redscript/CyberpunkRealism/InjuryEffectsNative.reds'
$native=(Get-Content -Raw $nativePath)+"`n"+(Get-Content -Raw (Join-Path $project 'src/redscript/CyberpunkRealism/CombatWoundsNative.reds'))
$classes=foreach($name in @('CRNPCInjuryBridge','CRInjuryModifierSlot','CRInjuryModifierSet','CRInjuryEffectsBridge','CRInjuryEffectsRuntime')){
 $match=[regex]::Match($native,'(?m)^public class '+$name+' extends (IScriptable|ScriptableSystem)')
 if(-not $match.Success){throw "Missing native class $name"}
 $start=$native.IndexOf('{',$match.Index);$depth=1;$end=$start+1
 while($depth -gt 0 -and $end -lt $native.Length){if($native[$end] -eq '{'){$depth++};if($native[$end] -eq '}'){$depth--};$end++}
 if($depth -ne 0){throw 'Unbalanced source class'}
 $s=$native.Substring($match.Index,$end-$match.Index).Replace('extends ScriptableSystem','extends IScriptable').Replace('private let','public let').Replace('wref<','ref<')
 # The pure injury-effects harness deliberately excludes the PlayerPuppet-only pain
 # presentation call. Pain ownership/refresh is covered by Test-PainArchitecture and
 # exact local REDscript compilation; keeping it here would require fake engine/UI
 # types in a model harness and would weaken rather than improve the isolation test.
 # Use line regexes so this stays deterministic under both LF and Windows CRLF checkout.
 $s=[regex]::Replace($s,'(?m)^\s*let localPlayer: ref<PlayerPuppet> = player as PlayerPuppet;\r?\n','')
 $s=[regex]::Replace($s,'(?m)^\s*CRPainNativeEffects\.Refresh\(localPlayer, IsDefined\(body\) && enabled && CRInjuryEffectsBridge\.Allowed\(localPlayer, true\)\);\r?\n','')
 $s=[regex]::Replace($s,'(public|private) func (\w+)\(','$1 static func CRInstance_$2(')
 $s=[regex]::Replace($s,'return GameInstance.GetScriptableSystemsContainer\(GetGameInstance\(\)\).+?;', 'return CREffectsFixture.runtime;')
 $s=$s.Replace('GetGameInstance()','CREffectsFixture.game').Replace('array<ref<CRInjuryModifierSlot>>','CRModifierSlots = new CRModifierSlots()').Replace('array<ref<NPCPuppet>>','CRNpcList = new CRNpcList()')
 $s
}
$generated=Join-Path $project ('staging/injury-effects-test-'+[guid]::NewGuid().ToString('N')+'.reds')
[IO.File]::WriteAllText($generated,($classes -join "`n"))
$paths=@('ClockModel','ImpactModel','WoundModel','NPCBodyModel','InjuryModel','BodyModel','SleepModel','InjuryEffectsModel')|ForEach-Object{Join-Path $project "src/redscript/CyberpunkRealism/$_.reds"}
$code=Convert-RedscriptCore ($paths+@($generated))
$code=[regex]::Replace($code,'(public|private) static (\w+) CRInstance_(\w+)\(','$1 $2 $3(')
$code=$code.Replace('Cast<StatsObjectID>','').Replace('ArraySize(','CREffectsFixture.Size(').Replace('ArrayPush(','CREffectsFixture.Push(').Replace('ArrayErase(','CREffectsFixture.Erase(').Replace('AbsF(','System.Math.Abs(').Replace('NotEquals(','CREffectsFixture.NotEquals(')
$code=[regex]::Replace($code,'\bStatsObjectID\b','string')
Add-Type -TypeDefinition ($code+(Get-Content -Raw "$PSScriptRoot/fixtures/InjuryEffects.cs"))
