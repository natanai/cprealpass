. "$PSScriptRoot\..\tools\Common.ps1"
$project=Get-ProjectRoot
$workRelative='staging\compile-failure-'+[guid]::NewGuid().ToString('N')
$work=Resolve-SafeChildPath $project $workRelative
New-Item -ItemType Directory -Force -Path $work|Out-Null
$source=Join-Path $work 'Broken.reds'
[IO.File]::WriteAllText($source,'module CompileFailureFixture public func BrokenReturnType() -> Bool { return 1; }')
$m=Get-Content -Raw (Join-Path $project 'manifest/m3-body-alpha2.deployment.json')|ConvertFrom-Json
$m.buildId='compile-failure-fixture'
$m.files += [pscustomobject]@{source=($workRelative+'\Broken.reds');destination='r6/scripts/compile-fixture.reds';component='test';sha256=(Get-Sha256 $source)}
$manifest=Join-Path $work 'manifest.json'
Write-JsonFile $m $manifest
$liveCache='C:\Games\Steam\steamapps\common\Cyberpunk 2077\r6\cache\final.redscripts'
$before=Get-Sha256 $liveCache
$failure=$null
try { & "$project\tools\Compile-Profile.ps1" -ManifestPath ($workRelative+'\manifest.json') } catch { $failure=$_.Exception.Message }
$r=Get-Content -Raw (Join-Path $project 'reports/compile-compile-failure-fixture.json')|ConvertFrom-Json
if($failure -notmatch 'Offline compilation failed' -or $r.passed -or $r.diagnosticErrors -lt 1 -or $r.outputPresent){throw 'Compiler guard accepted invalid source'}
if((Get-Sha256 $liveCache) -ne $before){throw 'Compiler test altered live game cache'}
Write-JsonFile ([ordered]@{testedAtUtc=[DateTime]::UtcNow.ToString('o');passed=$true;invalidSourceRejected=$true;nativeCompilerExitCode=$r.exitCode;errorCount=$r.diagnosticErrors;liveCacheUnchanged=$true;scope='Actual invalid redscript source compiled with the pinned CLI; wrapper must reject diagnostic errors even when native exit code is zero.'}) (Join-Path $project 'reports/compile-guard-tests.json')
Write-Host "PASS: invalid source rejected (native exit $($r.exitCode)); live cache unchanged."
