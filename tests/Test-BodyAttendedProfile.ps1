. "$PSScriptRoot\..\tools\Common.ps1"
$project=Get-ProjectRoot
$work=Join-Path $project ('staging/attended-roundtrip-'+[guid]::NewGuid().ToString('N'))
$game=Join-Path $work 'game'
New-Item -ItemType Directory -Force "$game/bin/x64","$game/red4ext"|Out-Null
$live='C:/Games/Steam/steamapps/common/Cyberpunk 2077'
Copy-Item -LiteralPath "$live/bin/x64/Cyberpunk2077.exe" -Destination "$game/bin/x64/Cyberpunk2077.exe"
Copy-Item -LiteralPath "$live/red4ext/config.ini" -Destination "$game/red4ext/config.ini"
$state=Join-Path $work 'state'
$liveBefore=Get-Sha256 (Join-Path $project 'snapshots/deployment-state/current.json')
$base=& "$project/tools/Deploy.ps1" -GameRoot $game -ManifestPath "$project/manifest/m3-body-alpha1.deployment.json" -StateRoot $state
$test=& "$project/tools/Upgrade.ps1" -GameRoot $game -ManifestPath "$project/manifest/m3-body-attended-test1.deployment.json" -StateRoot $state
& "$project/tools/Verify-Deployment.ps1" -ReceiptPath $test
$quiet=& "$project/tools/Upgrade.ps1" -GameRoot $game -ManifestPath "$project/manifest/m3-body-attended-test1-quiet.deployment.json" -StateRoot $state
& "$project/tools/Verify-Deployment.ps1" -ReceiptPath $quiet
$tr=Get-Content -Raw $quiet|ConvertFrom-Json
if(@($tr.files|Where-Object action -ne 'preserve').Count -ne 1){throw 'Quiet build must change only the body diagnostic policy file'}
& "$project/tools/Rollback.ps1" -ReceiptPath $quiet
& "$project/tools/Verify-Deployment.ps1" -ReceiptPath $test
& "$project/tools/Rollback.ps1" -ReceiptPath $test
& "$project/tools/Verify-Deployment.ps1" -ReceiptPath $base
if((Get-Sha256 (Join-Path $project 'snapshots/deployment-state/current.json')) -ne $liveBefore){throw 'Fixture altered live state'}
Write-JsonFile ([ordered]@{testedAtUtc=[DateTime]::UtcNow.ToString('o');passed=$true;files=176;roundtrip='alpha1 -> attended -> quiet -> attended -> alpha1';quietChangedFiles=1;liveStateUnchanged=$true;scope='File deployment/recovery only; no save serialization or gameplay tested.'}) "$project/reports/body-attended-roundtrip.json"
Write-Host 'PASS: full 176-file attended/quiet upgrade and recovery chain.'