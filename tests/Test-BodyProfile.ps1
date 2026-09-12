. "$PSScriptRoot\..\tools\Common.ps1"
$project=Get-ProjectRoot
$manifestPath=Join-Path $project 'manifest\m3-body-alpha1.deployment.json'
$m=Get-Content -Raw $manifestPath | ConvertFrom-Json
$p=Get-Content -Raw (Join-Path $project 'config\body-alpha1.json') | ConvertFrom-Json
$settingsFile=$m.files | Where-Object destination -eq 'r6/scripts/Dark Future/Settings/DFSettings.reds'
$text=Get-Content -Raw (Resolve-SafeChildPath $project $settingsFile.source)
$checks=0
foreach($setting in $p.settings){
    $pattern='(?m)^\s*public let '+[regex]::Escape($setting.name)+': [A-Za-z0-9_]+ = '+[regex]::Escape($setting.value)+';'
    if([regex]::Matches($text,$pattern).Count -ne 1){throw "Preset not applied: $($setting.name)"}
    $checks++
}
foreach($f in $m.files){if($f.destination -match '\.xml$'){[xml](Get-Content -Raw (Resolve-SafeChildPath $project $f.source)) | Out-Null;$checks++}}
if(@($m.files | Where-Object destination -like 'r6/cache/*').Count -ne 0){throw 'Generated cache files must not be owned immutable payload.'};$checks++
$lookup=@{};foreach($s in $p.settings){$lookup[$s.name]=$s.value}
$thresholds=1..4 | ForEach-Object {[double]$lookup["basicNeedThresholdValue$_"]}
for($i=1;$i -lt $thresholds.Count;$i++){if($thresholds[$i] -ge $thresholds[$i-1]){throw 'Need thresholds must decrease strictly.'};$checks++}
$work=Join-Path $project ('staging\body-roundtrip-'+[guid]::NewGuid().ToString('N'))
$game=Join-Path $work 'game'
New-Item -ItemType Directory -Force -Path "$game\bin\x64","$game\red4ext" | Out-Null
Copy-Item -LiteralPath 'C:\Games\Steam\steamapps\common\Cyberpunk 2077\bin\x64\Cyberpunk2077.exe' -Destination "$game\bin\x64\Cyberpunk2077.exe"
Copy-Item -LiteralPath 'C:\Games\Steam\steamapps\common\Cyberpunk 2077\red4ext\config.ini' -Destination "$game\red4ext\config.ini"
$original=Get-Sha256 "$game\red4ext\config.ini"
$liveState=Get-Sha256 (Join-Path $project 'snapshots\deployment-state\current.json')
$receipt=& "$project\tools\Deploy.ps1" -GameRoot $game -ManifestPath $manifestPath -StateRoot (Join-Path $work 'state')
& "$project\tools\Verify-Deployment.ps1" -ReceiptPath $receipt
# Exercise the full installed payload through an upgrade, changing a real script's
# bytes without changing its behavior and adding a fixture-owned file.
$upgradeManifest = Get-Content -Raw $manifestPath | ConvertFrom-Json
$upgradeManifest.buildId = 'body-upgrade-fixture'
$settingsCopy = Join-Path $work 'DFSettings.reds'
[IO.File]::WriteAllText($settingsCopy, $text + "`r`n// Isolated upgrade fixture; never deploy this test manifest to live.`r`n")
$upgradeSettings = $upgradeManifest.files | Where-Object destination -eq 'r6/scripts/Dark Future/Settings/DFSettings.reds'
$upgradeSettings.source = $settingsCopy.Substring($project.Length+1)
$upgradeSettings.sha256 = Get-Sha256 $settingsCopy
$upgradeManifest.files += [pscustomobject]@{source='tests/fixtures/payload.txt';destination='r6/scripts/project-upgrade-fixture.txt';component='test';sha256=(Get-Sha256 (Join-Path $project 'tests/fixtures/payload.txt'))}
$upgradePath = Join-Path $work 'upgrade.json'
Write-JsonFile $upgradeManifest $upgradePath
$upgraded = & "$project\tools\Upgrade.ps1" -GameRoot $game -ManifestPath $upgradePath -StateRoot (Join-Path $work 'state')
& "$project\tools\Verify-Deployment.ps1" -ReceiptPath $upgraded
if((Get-Sha256 (Join-Path $game $upgradeSettings.destination)) -ne $upgradeSettings.sha256){throw 'Full-package script upgrade failed.'};$checks++
& "$project\tools\Rollback.ps1" -ReceiptPath $upgraded
& "$project\tools\Verify-Deployment.ps1" -ReceiptPath $receipt
if(Test-Path (Join-Path $game 'r6/scripts/project-upgrade-fixture.txt')){throw 'Upgrade-only file remained.'};$checks++
& "$project\tools\Rollback.ps1" -ReceiptPath $receipt
& "$project\tools\Verify-Deployment.ps1" -ReceiptPath $receipt
if((Get-Sha256 "$game\red4ext\config.ini") -ne $original){throw 'Logging config did not restore.'};$checks++
if((Get-Sha256 (Join-Path $project 'snapshots\deployment-state\current.json')) -ne $liveState){throw 'Test altered live ownership state.'};$checks++
Write-JsonFile ([ordered]@{testedAtUtc=[DateTime]::UtcNow.ToString('o');buildId=$m.buildId;assertions=$checks;files=$m.files.Count;roundtrip='passed';upgradeRoundtrip='passed';preset='passed';xml='passed';runtime='not run'}) (Join-Path $project 'reports\body-alpha1-tests.json')
Write-Host "PASS: $checks assertions and $($m.files.Count)-file deployment/rollback."
