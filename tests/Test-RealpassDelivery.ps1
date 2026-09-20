param(
    [Parameter(Mandatory=$true)][string]$BaseManifestPath,
    [Parameter(Mandatory=$true)][string]$CandidateManifestPath,
    [string]$GameRoot='C:\Games\Steam\steamapps\common\Cyberpunk 2077'
)
. "$PSScriptRoot/../tools/Common.ps1"
$project=Get-ProjectRoot
$liveGame=Assert-GameRoot $GameRoot
Assert-GameStopped
$basePath=Resolve-SafeChildPath $project $BaseManifestPath
$candidatePath=Resolve-SafeChildPath $project $CandidateManifestPath
$base=Get-Content -Raw -LiteralPath $basePath | ConvertFrom-Json
$candidate=Get-Content -Raw -LiteralPath $candidatePath | ConvertFrom-Json
$baseHash=Get-Sha256 $basePath
$candidateHash=Get-Sha256 $candidatePath
$livePointer=Join-Path $project 'snapshots/deployment-state/current.json'
$liveHash=Get-Sha256 $livePointer
$relative='staging/realpass-delivery-'+[guid]::NewGuid().ToString('N')
$fixture=Resolve-SafeChildPath $project $relative
$fixtureGame=Resolve-SafeChildPath $fixture 'game'
$state=Resolve-SafeChildPath $fixture 'state'
New-Item -ItemType Directory -Force -Path (Join-Path $fixtureGame 'bin/x64') | Out-Null
# Only the file's version metadata is read; the copied executable is never launched.
$exe=Resolve-SafeChildPath $liveGame 'bin/x64/Cyberpunk2077.exe'
Copy-VerifiedPayload $exe (Resolve-SafeChildPath $fixtureGame 'bin/x64/Cyberpunk2077.exe') (Get-Sha256 $exe)
$sentinel=Resolve-SafeChildPath $fixtureGame 'player-save-sentinel.dat'
[IO.File]::WriteAllText($sentinel,'Preserve player data.')
$sentinelHash=Get-Sha256 $sentinel
$baseReceipt=& "$project/tools/Deploy.ps1" -GameRoot $fixtureGame -StateRoot $state -ManifestPath $basePath
$basePointerHash=Get-Sha256 (Join-Path $state 'current.json')
& "$project/tools/Verify-Deployment.ps1" -GameRoot $fixtureGame -ReceiptPath $baseReceipt
$candidateReceipt=& "$project/tools/Upgrade.ps1" -GameRoot $fixtureGame -StateRoot $state -ManifestPath $candidatePath
& "$project/tools/Verify-Deployment.ps1" -GameRoot $fixtureGame -ReceiptPath $candidateReceipt
$receipt=Get-Content -Raw -LiteralPath $candidateReceipt | ConvertFrom-Json
if($receipt.buildId -ne $candidate.buildId -or @($receipt.files | Where-Object inPayload).Count -ne @($candidate.files).Count){throw 'Candidate membership differs'}
foreach($file in $candidate.files) {
    if((Get-ExistingHash (Resolve-SafeChildPath $fixtureGame $file.destination)) -ne $file.sha256){throw 'Installed candidate bytes differ'}
}
& "$project/tools/Rollback.ps1" -ReceiptPath $candidateReceipt
if((Get-Sha256 (Join-Path $state 'current.json')) -ne $basePointerHash){throw 'Rollback did not restore exact prior pointer'}
& "$project/tools/Verify-Deployment.ps1" -GameRoot $fixtureGame -ReceiptPath $baseReceipt
$baseDestinations=@{}
foreach($file in $base.files){$baseDestinations[$file.destination]=$true}
foreach($file in $candidate.files) {
    if(!$baseDestinations.ContainsKey($file.destination) -and (Test-Path -LiteralPath (Resolve-SafeChildPath $fixtureGame $file.destination))){throw 'Rollback left a newly added payload file'}
}
if((Get-Sha256 $sentinel) -ne $sentinelHash){throw 'Player sentinel changed'}
if((Get-Sha256 $livePointer) -ne $liveHash){throw 'Live pointer changed during fixture'}
if((Get-Sha256 $basePath) -ne $baseHash -or (Get-Sha256 $candidatePath) -ne $candidateHash){throw 'Build manifest changed'}
Write-JsonFile ([ordered]@{
    testedAtUtc=[DateTime]::UtcNow.ToString('o')
    passed=$true
    buildId=$candidate.buildId
    baseBuild=$base.buildId
    manifestSha256=$candidateHash
    payloadFiles=@($candidate.files).Count
    actions=@($receipt.files | Group-Object action | Select-Object Name,Count)
    allInstalledHashesVerified=$true
    originalPointerRestored=$true
    newFilesRemovedOnRollback=$true
    playerSentinelPreserved=$true
    liveStateUnchanged=$true
    fixture=$relative
    scope='Actual complete candidate install/upgrade/rollback in an isolated root. No native gameplay, TweakDB/UI rendering or save compatibility claimed.'
}) (Join-Path $project ('reports/delivery-'+$candidate.buildId+'.json'))
Write-Host "PASS: $($candidate.buildId) exact payload upgrade and rollback."
