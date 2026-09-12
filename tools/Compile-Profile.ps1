param([string]$ManifestPath='manifest/m3-body-alpha1.deployment.json', [string]$GameRoot='C:\Games\Steam\steamapps\common\Cyberpunk 2077')
. "$PSScriptRoot\Common.ps1"
$project=Get-ProjectRoot
$game=Assert-GameRoot $GameRoot
$cli=Join-Path $project 'vendor\redscript\redscript-cli.exe'
if((Get-Sha256 $cli) -ne 'CDCBED2E0C943322BBCBBAC4A9C62EF29ADC5620E4B0934F0D2A31A8282B5B62'){throw 'Offline compiler hash mismatch.'}
$manifest=Get-Content -Raw (Resolve-SafeChildPath $project $ManifestPath) | ConvertFrom-Json
if((Get-Item (Join-Path $game 'bin\x64\Cyberpunk2077.exe')).VersionInfo.ProductVersion -ne $manifest.gameVersion){throw 'Game version does not match compile profile.'}
$work=Join-Path $project ('staging\compile-'+[guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $work | Out-Null
$argsList=@('compile','-b',(Join-Path $game 'r6\cache\final.redscripts'),'-o',(Join-Path $work 'final.redscripts'))
$count=0
foreach($file in $manifest.files){
    $path=Resolve-SafeChildPath $project $file.source
    if((Get-Sha256 $path) -ne $file.sha256){throw "Staged file hash mismatch: $path"}
    if($file.destination -match '\.reds$'){$argsList+=@('-s',$path);$count++}
}
$log=Join-Path $project ('logs\compile-'+$manifest.buildId+'-'+[DateTime]::UtcNow.ToString('yyyyMMdd-HHmmss')+'.log')
& $cli @argsList 2>&1 | Tee-Object -FilePath $log | Out-Host
$code=$LASTEXITCODE
$output=Join-Path $work 'final.redscripts'
$logText=Get-Content -Raw -LiteralPath $log
$diagnosticErrors=@([regex]::Matches($logText,'(?m)^\s*ERROR\s+\[')).Count
$outputPresent=(Test-Path -LiteralPath $output -PathType Leaf) -and (Get-Item -LiteralPath $output).Length -gt 0
$passed=$code -eq 0 -and $diagnosticErrors -eq 0 -and $outputPresent
$result=[ordered]@{buildId=$manifest.buildId;compiledAtUtc=[DateTime]::UtcNow.ToString('o');sourceCount=$count;exitCode=$code;passed=$passed;diagnosticErrors=$diagnosticErrors;outputPresent=$outputPresent;logPath=$log;output=$output;baseBundleSha256=Get-Sha256 (Join-Path $game 'r6\cache\final.redscripts');scope='Offline language/type compilation only; native hooks, archive loading, TweakDB, UI, and saved state require runtime verification.'}
Write-JsonFile $result (Join-Path $project ('reports\compile-'+$manifest.buildId+'.json'))
if(-not $passed){throw "Offline compilation failed (exit=$code, errors=$diagnosticErrors, output=$outputPresent); see $log"}
Write-Host "Offline compilation passed for $count script sources. Game cache was not modified."
