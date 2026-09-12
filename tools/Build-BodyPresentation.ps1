param([Parameter(Mandatory=$true)][ValidatePattern('^[a-zA-Z0-9][a-zA-Z0-9._-]*$')][string]$BuildId)
. "$PSScriptRoot\Common.ps1"
$project=Get-ProjectRoot
$manifestPath='manifest/'+$BuildId+'.deployment.json'
if(Test-Path -LiteralPath (Join-Path $project $manifestPath)){throw 'Build ID already exists. Use a new ID; historical profiles are immutable.'}
$m=Get-Content -Raw (Join-Path $project 'manifest/m3-body-test1-caption-fix.deployment.json')|ConvertFrom-Json
$m.buildId=$BuildId
$destination='r6/scripts/CyberpunkRealism/DarkFuturePreviewUIBridge.reds'
$entry=@($m.files|Where-Object destination -eq $destination)
if($entry.Count -ne 1){throw 'Expected one existing body presentation bridge'}
$source=Join-Path $project 'src/redscript/CyberpunkRealism/DarkFuturePreviewUIBridge.reds'
$relative='staging/body-presentation-'+[guid]::NewGuid().ToString('N')+'/DarkFuturePreviewUIBridge.reds'
$hash=Get-Sha256 $source
Copy-VerifiedPayload $source (Resolve-SafeChildPath $project $relative) $hash
$entry[0].source=$relative;$entry[0].sha256=$hash
Write-JsonFile $m (Join-Path $project $manifestPath)
& "$PSScriptRoot/Apply-SourcePatch.ps1" -ManifestPath $manifestPath -PatchPath 'config/patches/darkfuture-backpack-layout.json'
& "$PSScriptRoot/Compile-Profile.ps1" -ManifestPath $manifestPath
Write-Host "Staged $BuildId with top-anchored backpack needs, needs-inspection hint and toilet caption fix. No game files changed."