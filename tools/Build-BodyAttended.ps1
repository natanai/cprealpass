param([Parameter(Mandatory=$true)][ValidatePattern('^[a-zA-Z0-9][a-zA-Z0-9._-]*$')][string]$BuildId, [switch]$Diagnostics)
. "$PSScriptRoot\Common.ps1"
$project=Get-ProjectRoot
$sourceManifest=Join-Path $project 'manifest/m3-body-runtime-prototype.deployment.json'
$m=Get-Content -Raw $sourceManifest|ConvertFrom-Json
if(Test-Path -LiteralPath (Join-Path $project ('manifest/'+$BuildId+'.deployment.json'))){throw 'Build ID already exists. Use a new ID; historical profiles are immutable.'}
$m.buildId=$BuildId
$entry=@($m.files|Where-Object destination -eq 'r6/scripts/CyberpunkRealism/BodyRuntime.reds')
if($entry.Count -ne 1){throw 'Expected one body runtime source'}
$source=Resolve-SafeChildPath $project $entry[0].source
if((Get-Sha256 $source) -ne $entry[0].sha256){throw 'Runtime source hash mismatch'}
$s=(Get-Content -Raw $source).Replace("`r`n","`n")
foreach($policy in @('CRBodyRuntimePolicy')+$(if($Diagnostics){@('CRBodyTestPolicy')}else{@()})){
  $pattern='(public class '+$policy+' extends IScriptable \{\s+public static func \w+\(\) -> Bool \{\s+)return false;'
  if([regex]::Matches($s,$pattern).Count -ne 1){throw "Missing disabled policy: $policy"}
  $s=[regex]::Replace($s,$pattern,'${1}return true;')
}
$combat=@($m.files|Where-Object destination -eq 'r6/scripts/CyberpunkRealism/CombatNativeBridge.reds')
if($combat.Count -ne 1){throw 'Expected one combat policy'}
$combatPath=Resolve-SafeChildPath $project $combat[0].source
if((Get-Sha256 $combatPath) -ne $combat[0].sha256 -or (Get-Content -Raw $combatPath) -notmatch 'public class CRCombatRuntimePolicy extends IScriptable \{\s+.*?public static func BuildEnabled\(\) -> Bool \{\s+return false;'){throw 'Combat build gate must remain disabled'}
$relative='staging/body-attended-'+[guid]::NewGuid().ToString('N')+'/BodyRuntime.reds'
$target=Resolve-SafeChildPath $project $relative
New-Item -ItemType Directory -Force (Split-Path $target -Parent)|Out-Null
[IO.File]::WriteAllText($target,$s)
$entry[0].source=$relative
$entry[0].sha256=Get-Sha256 $target
$manifest='manifest/'+$m.buildId+'.deployment.json'
Write-JsonFile $m (Join-Path $project $manifest)
& "$PSScriptRoot\Compile-Profile.ps1" -ManifestPath $manifest
Write-Host "Staged $($m.buildId): body enabled, combat build gate disabled, diagnostics=$Diagnostics. No live deployment performed."