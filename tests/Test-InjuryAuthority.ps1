. "$PSScriptRoot\..\tools\Common.ps1"
. "$PSScriptRoot\CoreHarness.ps1"
$project=Get-ProjectRoot
$manifest=Get-Content -Raw (Join-Path $project 'manifest/m3-body-runtime-prototype.deployment.json')|ConvertFrom-Json
$entry=$manifest.files|Where-Object destination -eq 'r6/scripts/Dark Future/Conditions/DFConditionSystemInjury.reds'
$stagedPath=Resolve-SafeChildPath $project $entry.source
if((Get-Sha256 $stagedPath) -ne $entry.sha256){throw 'Staged injury source hash mismatch'}
$bodyPath=Join-Path $project 'src/redscript/CyberpunkRealism/BodyRuntime.reds'
function ExtractMethod([string]$source,[string]$name){
 $match=[regex]::Match($source,'(?m)^\s*(?:public|private) (?:final )?func '+$name+'\(')
 if(-not $match.Success){throw "Missing method $name"}
 $start=$source.IndexOf('{',$match.Index);$depth=1;$end=$start+1
 while($depth -gt 0 -and $end -lt $source.Length){if($source[$end] -eq '{'){$depth++};if($source[$end] -eq '}'){$depth--};$end++}
 if($depth -ne 0){throw 'Unbalanced method'}
 $source.Substring($match.Index,$end-$match.Index)
}
$bodySource=Get-Content -Raw $bodyPath
$legacySource=Get-Content -Raw $stagedPath
$bodyMethods=@('OwnsLocalizedInjuries','TryInjuryHandover')|ForEach-Object{ExtractMethod $bodySource $_}
$legacyMethods=@('CRIsClearForHandover','GetConditionCureItemTag')|ForEach-Object{ExtractMethod $legacySource $_}
$generated=Join-Path $project ('staging/injury-authority-test-'+[guid]::NewGuid().ToString('N')+'.reds')
[IO.File]::WriteAllText($generated,"public class CRBodyRuntime extends IScriptable {`n"+($bodyMethods -join "`n")+"`n}`npublic class DFInjuryConditionSystem extends IScriptable {`n"+($legacyMethods -join "`n")+"`n}")
$code=Convert-RedscriptCore @($generated)
# Widen private method visibility only to invoke the actual handover in tests.
$code=[regex]::Replace($code,'(?:public|private) (?:final )?func (\w+)\(\) -> (\w+)', 'public $2 $1()')
$code=$code.Replace('public class CRBodyRuntime','public partial class CRBodyRuntime').Replace('public class DFInjuryConditionSystem','public partial class DFInjuryConditionSystem').Replace('CName','string').Replace('n"','"').Replace('0u','0')
Add-Type -TypeDefinition ($code+(Get-Content -Raw "$PSScriptRoot/fixtures/InjuryAuthority.cs"))
$script:checks=0
function Check($condition,$message){if(-not $condition){throw $message};$script:checks++}
function Reset {
 [CRBodyRuntime]::instance=[CRBodyRuntime]::new();[DFInjuryConditionSystem]::instance=[DFInjuryConditionSystem]::new()
 [DFInjuryConditionSystem]::instance.player=[CRFixturePlayer]::new();[CRCombatRuntimePolicy]::enabled=$true
}
Reset
$b=[CRBodyRuntime]::Get();$legacy=[DFInjuryConditionSystem]::Get()
Check ($legacy.CRIsClearForHandover()) 'Clean retained injury state blocked handover'
$b.TryInjuryHandover()
Check ($b.OwnsLocalizedInjuries() -and $b.localizedInjuryHandover) 'Valid handover failed'
Check ($legacy.GetConditionCureItemTag() -eq '') 'Legacy kit cure remained enabled after localized ownership'
$b.running=$false;$b.allowed=$false
Check ($b.OwnsLocalizedInjuries()) 'Suspension returned injury authority to the HP accumulator'
$b.TryInjuryHandover()
Check ($b.localizedInjuryHandover -and $legacy.currentConditionLevel -eq 0 -and $legacy.accumulatedPercentTowardNextLevel -eq 0) 'Repeated handover mutated saved injury values'
foreach($case in @('condition','partial','effect','missing-player','nan','negative-progress','disabled','suspended','invalid-scene','needs-not-owned')){
 Reset;$b=[CRBodyRuntime]::Get();$legacy=[DFInjuryConditionSystem]::Get()
 switch($case){
  'condition'{$legacy.currentConditionLevel=2}
  'partial'{$legacy.accumulatedPercentTowardNextLevel=40}
  'effect'{$legacy.player.legacyEffect=$true}
  'missing-player'{$legacy.player=$null}
  'nan'{$legacy.accumulatedPercentTowardNextLevel=[float]::NaN}
  'negative-progress'{$legacy.accumulatedPercentTowardNextLevel=-1}
  'disabled'{[CRCombatRuntimePolicy]::enabled=$false}
  'suspended'{$b.running=$false}
  'invalid-scene'{$b.allowed=$false}
  'needs-not-owned'{$b.needsOwned=$false}
 }
 $oldLevel=$legacy.currentConditionLevel;$oldProgress=$legacy.accumulatedPercentTowardNextLevel
 $b.TryInjuryHandover()
 Check (-not $b.localizedInjuryHandover -and -not $b.OwnsLocalizedInjuries()) "Unsafe handover accepted: $case"
 Check ($legacy.currentConditionLevel -eq $oldLevel -and ($legacy.accumulatedPercentTowardNextLevel -eq $oldProgress -or [float]::IsNaN($oldProgress))) "Handover erased retained legacy state: $case"
 Check ($legacy.GetConditionCureItemTag() -eq 'DarkFutureInjuryCure') "Legacy recovery disabled while waiting for handover: $case"
}
Reset;$b=[CRBodyRuntime]::Get();$legacy=[DFInjuryConditionSystem]::Get();$legacy.accumulatedPercentTowardNextLevel=40
$b.TryInjuryHandover();$legacy.accumulatedPercentTowardNextLevel=0;$b.TryInjuryHandover()
Check ($b.OwnsLocalizedInjuries()) 'Handover did not become available after existing injury was resolved'
Write-JsonFile ([ordered]@{testedAtUtc=[DateTime]::UtcNow.ToString('o');passed=$true;assertions=$script:checks;bodyRuntimeSha256=(Get-Sha256 $bodyPath);legacyStagedSourceSha256=(Get-Sha256 $stagedPath);patchSha256=(Get-Sha256 (Join-Path $project 'config/patches/darkfuture-injury-authority.json'));fixtureSha256=(Get-Sha256 "$PSScriptRoot/fixtures/InjuryAuthority.cs");scope='Actual ownership/handover methods and staged raw-state/cure-tag methods translated to C# with lifecycle/effect boundaries. Checks retained injury preservation, suspension and delayed handover. Native saves, status-effect callbacks and live legacy event dispatch remain unverified.'}) (Join-Path $project 'reports/injury-authority-tests.json')
Write-Host "PASS: $script:checks injury authority checks."
