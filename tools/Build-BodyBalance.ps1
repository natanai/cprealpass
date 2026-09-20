param([Parameter(Mandatory=$true)][ValidatePattern('^[a-zA-Z0-9][a-zA-Z0-9._-]*$')][string]$BuildId)
. "$PSScriptRoot/Common.ps1"
$project=Get-ProjectRoot
$manifestPath='manifest/'+$BuildId+'.deployment.json'
if(Test-Path -LiteralPath (Join-Path $project $manifestPath)){throw 'Build ID already exists. Use a new ID; historical profiles are immutable.'}
$m=Get-Content -Raw (Join-Path $project 'manifest/m3-body-presentation3-quiet.deployment.json')|ConvertFrom-Json
$m.buildId=$BuildId
$stage='staging/body-balance-'+[guid]::NewGuid().ToString('N')
foreach($name in @('BodyModel','SleepModel','BodyPresentation','BodyForecast')){
 $entry=@($m.files|Where-Object destination -eq "r6/scripts/CyberpunkRealism/$name.reds")
 if($entry.Count -ne 1){throw "Expected one $name source"}
 $source=Join-Path $project "src/redscript/CyberpunkRealism/$name.reds"
 $relative="$stage/$name.reds"
 $hash=Get-Sha256 $source
 Copy-VerifiedPayload $source (Resolve-SafeChildPath $project $relative) $hash
 $entry[0].source=$relative;$entry[0].sha256=$hash
}
Write-JsonFile $m (Join-Path $project $manifestPath)
& "$PSScriptRoot/Compile-Profile.ps1" -ManifestPath $manifestPath
Write-Host "Staged ${BuildId}: corrected backpack, toilet caption and recoverable exertion fatigue; body enabled, combat and diagnostics disabled. No live deployment."