param([string]$ManifestPath='manifest/m3-body-alpha1.deployment.json', [string]$GameRoot='C:\Games\Steam\steamapps\common\Cyberpunk 2077')
. "$PSScriptRoot\Common.ps1"
$project=Get-ProjectRoot
$game=Assert-GameRoot $GameRoot

# The offline compiler is a development-only build dependency, not part of the
# player runtime package. Fresh disposable clones intentionally do not carry this
# binary, so acquire the one pinned upstream release asset on demand and verify it
# before use. This keeps attended clean-room builds reproducible without requiring
# a pre-existing vendor directory or a manual download.
$cli=Join-Path $project 'vendor\redscript\redscript-cli.exe'
$cliExpected='CDCBED2E0C943322BBCBBAC4A9C62EF29ADC5620E4B0934F0D2A31A8282B5B62'
$cliUri=[uri]'https://github.com/jac3km4/redscript/releases/download/v0.5.31/redscript-cli.exe'
if(-not (Test-Path -LiteralPath $cli -PathType Leaf)){
    if($cliUri.Scheme -ne 'https' -or $cliUri.Host -ne 'github.com'){throw 'Offline compiler source must be the pinned official GitHub release asset.'}
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $cli) | Out-Null
    $partial="$cli.$([guid]::NewGuid().ToString('N')).partial"
    try{
        Write-Host 'Acquiring pinned redscript 0.5.31 offline compiler for this fresh build checkout...'
        Invoke-WebRequest -Uri $cliUri -OutFile $partial
        if((Get-Sha256 $partial) -ne $cliExpected){throw 'Downloaded offline compiler hash mismatch.'}
        Move-Item -LiteralPath $partial -Destination $cli
    }finally{
        if(Test-Path -LiteralPath $partial){Remove-Item -LiteralPath $partial -Force}
    }
}
if((Get-Sha256 $cli) -ne $cliExpected){throw 'Offline compiler hash mismatch.'}

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
