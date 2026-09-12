param()
. "$PSScriptRoot\Common.ps1"
$project=Get-ProjectRoot
$m=Get-Content -Raw (Join-Path $project 'manifest/m3-body-alpha2.deployment.json')|ConvertFrom-Json
$m.buildId='m3-body-runtime-prototype'
$stage='staging\body-runtime-'+[guid]::NewGuid().ToString('N')
foreach($name in @('RealpassLocalization','FieldCareItemUse','BloodLossModel','BloodLossNative','FieldCareActionModel','FieldCareActionRuntime','NPCBodyModel','InjuryEffectsModel','InjuryEffectsNative','ArmorWearModel','ArmorWearNative','StockProtectionCatalog','WoundModel','CombatWoundsNative','FieldCareModel','FieldCareRuntime','FieldCareUI','InjuryModel','BallisticProfiles','CombatProfilesNative','ImpactModel','HitModel','CombatNativeBridge','SleepModel','BodyInteractionRuntime','BodyForecast','ItemServing','DarkFuturePreviewUIBridge','BodyModel','BodyInputs','ServingModel','BodyPresentation','ClockModel','BodyRuntime','DarkFutureBridge','DarkFutureMenuBridge','DarkFutureIntakeBridge','DarkFutureAuthorityBridge')) {
  $source=Join-Path $project "src/redscript/CyberpunkRealism/$name.reds"
  $relative="$stage\$name.reds"
  $target=Resolve-SafeChildPath $project $relative
  $hash=Get-Sha256 $source
  Copy-VerifiedPayload $source $target $hash
  $component=if($name -eq 'RealpassLocalization'){'darkfuture'}else{'cyberpunk-realism-body'}
  $m.files += [pscustomobject]@{source=$relative;destination="r6/scripts/CyberpunkRealism/$name.reds";component=$component;sha256=$hash}
}
$relativeManifest='manifest/m3-body-runtime-prototype.deployment.json'
Write-JsonFile $m (Join-Path $project $relativeManifest)
& "$PSScriptRoot\Apply-SourcePatch.ps1" -ManifestPath $relativeManifest -PatchPath 'config/patches/darkfuture-body-tick.json'
& "$PSScriptRoot\Apply-SourcePatch.ps1" -ManifestPath $relativeManifest -PatchPath 'config/patches/darkfuture-body-authority.json'
& "$PSScriptRoot\Apply-SourcePatch.ps1" -ManifestPath $relativeManifest -PatchPath 'config/patches/darkfuture-body-previews.json'
& "$PSScriptRoot\Apply-SourcePatch.ps1" -ManifestPath $relativeManifest -PatchPath 'config/patches/darkfuture-backpack-layout.json'
& "$PSScriptRoot\Apply-SourcePatch.ps1" -ManifestPath $relativeManifest -PatchPath 'config/patches/darkfuture-fieldcare-modal.json'
& "$PSScriptRoot\Apply-SourcePatch.ps1" -ManifestPath $relativeManifest -PatchPath 'config/patches/darkfuture-fieldcare-consume.json'
& "$PSScriptRoot\Apply-SourcePatch.ps1" -ManifestPath $relativeManifest -PatchPath 'config/patches/darkfuture-injury-authority.json'
& "$PSScriptRoot\Apply-SourcePatch.ps1" -ManifestPath $relativeManifest -PatchPath 'config/patches/darkfuture-realpass-presentation.json'
& "$PSScriptRoot\Compile-Profile.ps1" -ManifestPath $relativeManifest
Write-Host 'Runtime adapter staged with activation disabled; model calibration, scripted/body interactions and native UI/save validation remain open.'
