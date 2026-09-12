param()
. "$PSScriptRoot\Common.ps1"
$project=Get-ProjectRoot
$m=Get-Content -Raw (Join-Path $project 'manifest/m3-body-alpha2.deployment.json')|ConvertFrom-Json
$m.buildId='m3-body-core-prototype'
$stage='staging\body-core-'+[guid]::NewGuid().ToString('N')
foreach($name in @('InjuryModel','BodyModel','SleepModel')) {
 $relative="$stage\$name.reds"
 $source=Join-Path $project "src/redscript/CyberpunkRealism/$name.reds"
 $target=Resolve-SafeChildPath $project $relative
 $hash=Get-Sha256 $source
 Copy-VerifiedPayload $source $target $hash
 $m.files += [pscustomobject]@{source=$relative;destination="r6/scripts/CyberpunkRealism/$name.reds";component='cyberpunk-realism-body';sha256=$hash}
}
Write-JsonFile $m (Join-Path $project 'manifest/m3-body-core-prototype.deployment.json')
& "$PSScriptRoot\Compile-Profile.ps1" -ManifestPath 'manifest/m3-body-core-prototype.deployment.json'
Write-Host 'Pure body/sleep core staged. The separate runtime profile contains integration; neither is promoted as gameplay-verified.'
