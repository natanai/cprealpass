. "$PSScriptRoot/../tools/Common.ps1"
$project=Get-ProjectRoot
$script:checks=0
function Check($condition,$message){if(-not $condition){throw $message};$script:checks++}
function Reject([scriptblock]$action,[string]$message){$rejected=$false;try{& $action|Out-Null}catch{$rejected=$true};Check $rejected $message}
$report=Get-Content -Raw (Join-Path $project 'reports/integration-bundle-build.json')|ConvertFrom-Json
Check ($report.verified -and (Get-Sha256 $report.archive) -eq $report.archiveSha256) 'Bundle archive does not match the build receipt'
$work=Join-Path $project ('staging/integration-roundtrip-'+[guid]::NewGuid().ToString('N'))
$extract=Join-Path $work 'relocated'
[IO.Compression.ZipFile]::ExtractToDirectory($report.archive,$extract)
$bundle=Join-Path $extract 'realpass'
& "$bundle/tools/Verify-IntegrationBundle.ps1"
$index=Get-Content -Raw "$bundle/bundle-index.json"|ConvertFrom-Json
$manifest=Get-Content -Raw "$bundle/manifest/deployment.json"|ConvertFrom-Json
$expectedManifest=Get-Content -Raw (Join-Path $project ('manifest/'+$report.buildId+'.deployment.json'))|ConvertFrom-Json
Check ($manifest.files.Count -eq $expectedManifest.files.Count -and $manifest.files.Count -eq $report.payloadFiles -and $index.files.Count -eq $report.indexedFiles) 'Integrated payload/notices/tools missing'
foreach($expectedFile in $expectedManifest.files){
 $bundledFile=@($manifest.files|Where-Object destination -eq $expectedFile.destination)
 Check ($bundledFile.Count -eq 1 -and $bundledFile[0].sha256 -eq $expectedFile.sha256) 'Bundle differs from selected candidate payload'
}
foreach($file in $manifest.files){Check ($file.source -eq ('payload/'+$file.destination.Replace('\','/'))) 'Bundled manifest retained a workspace staging path'}
Check (@($index.files|Where-Object path -match '^(snapshots|logs)/|Cyberpunk2077\.exe$|final\.redscripts$').Count -eq 0) 'Bundle leaked saves, local diagnostics or game binaries'
Check (@($index.files|Where-Object path -match '^LICENSES/').Count -eq 8) 'Required dependency licenses missing'
$liveReceipt=Join-Path $project 'snapshots/deployment-state/current.json'
$liveBefore=Get-Sha256 $liveReceipt
$game=Join-Path $work 'game';$state=Join-Path $work 'state';$saves=Join-Path $work 'saves'
New-Item -ItemType Directory -Force "$game/bin/x64","$game/red4ext",$saves|Out-Null
Copy-Item -LiteralPath 'C:/Games/Steam/steamapps/common/Cyberpunk 2077/bin/x64/Cyberpunk2077.exe' -Destination "$game/bin/x64/Cyberpunk2077.exe"
Copy-Item -LiteralPath 'C:/Games/Steam/steamapps/common/Cyberpunk 2077/red4ext/config.ini' -Destination "$game/red4ext/config.ini"
[IO.File]::WriteAllText((Join-Path $saves 'fixture.dat'),'fixture save content; not an engine save')
$saveHash=Get-Sha256 (Join-Path $saves 'fixture.dat')
# Existing managed quiet build -> relocated bundle -> original quiet build.
$base=& "$project/tools/Deploy.ps1" -GameRoot $game -ManifestPath "$project/manifest/m3-body-attended-test1-quiet.deployment.json" -StateRoot $state
$basePointer=Get-Sha256 (Join-Path $state 'current.json')
& "$bundle/tools/Install-IntegrationBundle.ps1" -GameRoot $game -StateRoot $state -WhatIf | Out-Host
Check ((Get-Sha256 (Join-Path $state 'current.json')) -eq $basePointer -and -not (Test-Path -LiteralPath "$state/save-backups")) 'Dry run changed ownership or copied saves'
Reject {& "$bundle/tools/Install-IntegrationBundle.ps1" -GameRoot $game -StateRoot "$bundle/state" -SaveRoot $saves} 'Installer allowed disposable state inside the bundle'
Reject {& "$bundle/tools/Install-IntegrationBundle.ps1" -GameRoot $game -StateRoot $state} 'Actual install allowed missing save backup input'
Check ((Get-Sha256 (Join-Path $state 'current.json')) -eq $basePointer) 'Missing-save rejection changed game state'
# A changed payload must fail before any game writes or backups.
$payload=Join-Path $bundle 'payload/r6/scripts/CyberpunkRealism/DarkFuturePreviewUIBridge.reds'
$bytes=[IO.File]::ReadAllBytes($payload)
[IO.File]::AppendAllText($payload,"`n// tampered fixture")
Reject {& "$bundle/tools/Install-IntegrationBundle.ps1" -GameRoot $game -StateRoot $state -SaveRoot $saves} 'Changed payload installed'
Check ((Get-Sha256 (Join-Path $state 'current.json')) -eq $basePointer -and -not (Test-Path -LiteralPath "$state/save-backups")) 'Tamper rejection changed the installation or backed up saves'
[IO.File]::WriteAllBytes($payload,$bytes)
$extra=Join-Path $bundle 'payload/unindexed.reds';[IO.File]::WriteAllText($extra,'unindexed')
Reject {& "$bundle/tools/Verify-IntegrationBundle.ps1"} 'Unindexed payload accepted'
Remove-Item -LiteralPath $extra
Reject {& "$bundle/tools/Backup-Saves.ps1" -SaveRoot $saves -BackupRoot "$saves/recursive"} 'Save backup accepted a destination inside the live saves'
$installed=& "$bundle/tools/Install-IntegrationBundle.ps1" -GameRoot $game -StateRoot $state -SaveRoot $saves
$r=Get-Content -Raw $installed|ConvertFrom-Json
Check ($r.buildId -eq $report.buildId -and $r.schemaVersion -eq 3 -and $r.parentDeploymentId -eq (Get-Content -Raw $base|ConvertFrom-Json).deploymentId) 'Relocated install lost the original rollback parent'
$baseManifest=Get-Content -Raw (Join-Path $project 'manifest/m3-body-attended-test1-quiet.deployment.json')|ConvertFrom-Json
$baseFiles=@{}
foreach($baseFile in $baseManifest.files){$baseFiles[$baseFile.destination.Replace([char]92,[char]47)]=$baseFile.sha256}
$expectedChanges=@(
 foreach($candidateFile in $expectedManifest.files){
  $candidateDestination=$candidateFile.destination.Replace([char]92,[char]47)
  if(-not $baseFiles.ContainsKey($candidateDestination) -or $baseFiles[$candidateDestination] -ne $candidateFile.sha256){$candidateDestination}
 }
 foreach($baseDestination in $baseFiles.Keys){
  if(@($expectedManifest.files|Where-Object {$_.destination.Replace([char]92,[char]47) -eq $baseDestination}).Count -eq 0){$baseDestination}
 }
)
Check (@($r.files|Where-Object action -ne 'preserve').Count -eq $expectedChanges.Count) 'Body/presentation upgrade changed unexpected payload count'
foreach($changed in @($r.files|Where-Object action -ne 'preserve')){
 Check ( $changed.destination.Replace([char]92,[char]47) -in $expectedChanges) 'Body/presentation upgrade changed unexpected destination'
}
$backups=@(Get-ChildItem -LiteralPath "$state/save-backups" -Filter backup.json -File -Recurse)
Check ($backups.Count -eq 1) 'Expected one durable pre-install save backup'
$b=Get-Content -Raw $backups[0].FullName|ConvertFrom-Json
Check ($b.status -eq 'verified' -and $b.files.Count -eq 1 -and $b.files[0].sha256 -eq $saveHash -and (Get-Sha256 (Join-Path $saves 'fixture.dat')) -eq $saveHash) 'Save backup missing, corrupt or mutated live saves'
& "$bundle/tools/Rollback.ps1" -ReceiptPath $installed
& "$bundle/tools/Verify-Deployment.ps1" -ReceiptPath $base
Check ((Get-Sha256 (Join-Path $state 'current.json')) -eq $basePointer) 'Rollback failed to restore the exact original ownership pointer'
# The same archive also supports an initial managed install and recovery.
$newState=Join-Path $work 'fresh-state';$newGame=Join-Path $work 'fresh-game'
New-Item -ItemType Directory -Force "$newGame/bin/x64","$newGame/red4ext"|Out-Null
Copy-Item -LiteralPath "$game/bin/x64/Cyberpunk2077.exe" -Destination "$newGame/bin/x64/Cyberpunk2077.exe"
Copy-Item -LiteralPath "$game/red4ext/config.ini" -Destination "$newGame/red4ext/config.ini"
$fresh=& "$bundle/tools/Install-IntegrationBundle.ps1" -GameRoot $newGame -StateRoot $newState -SaveRoot $saves
Check ((Get-Content -Raw $fresh|ConvertFrom-Json).schemaVersion -eq 2) 'Initial managed bundle install did not use schema-2 deployment'
& "$bundle/tools/Rollback.ps1" -ReceiptPath $fresh
Check (-not (Test-Path -LiteralPath "$newGame/r6/scripts/CyberpunkRealism/BodyRuntime.reds")) 'Fresh-install rollback left new gameplay scripts behind'
# Existing historical build IDs cannot be silently rebuilt from current sources.
$pinned=Join-Path $project 'manifest/m3-body-attended-test1-quiet.deployment.json';$pinnedHash=Get-Sha256 $pinned
Reject {& "$project/tools/Build-BodyAttended.ps1" -BuildId 'm3-body-attended-test1-quiet'} 'Historical quiet manifest could be overwritten'
Reject {& "$project/tools/Build-BodyPresentation.ps1" -BuildId 'm3-body-presentation2-quiet'} 'Historical presentation manifest could be overwritten'
Check ((Get-Sha256 $pinned) -eq $pinnedHash -and (Get-Sha256 $liveReceipt) -eq $liveBefore) 'Bundle tests changed live profile or receipt'
Write-JsonFile ([ordered]@{testedAtUtc=[DateTime]::UtcNow.ToString('o');passed=$true;checks=$script:checks;testedArchive=$report.archive;testedArchiveSha256=$report.archiveSha256;payloadFiles=$manifest.files.Count;indexedFiles=$index.files.Count;relocated=$true;upgraded=$true;initialInstall=$true;rollback=$true;saveBackupVerified=$true;liveStateUnchanged=$true;scope='Actual portable bundle installer and deployment tools, isolated game roots and synthetic save bytes; no game launch or native save acceptance.'}) (Join-Path $project 'reports/integration-bundle-tests.json')
Write-Host "PASS: $script:checks integrated bundle/install/recovery checks."