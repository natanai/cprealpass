param([Parameter(Mandatory=$true)][string]$ManifestPath)
. "$PSScriptRoot/Common.ps1"
$project=Get-ProjectRoot
$manifestFull=Resolve-SafeChildPath $project $ManifestPath
$m=Get-Content -Raw $manifestFull|ConvertFrom-Json
if($m.schemaVersion -ne 1 -or $m.buildId -notmatch '^[a-zA-Z0-9][a-zA-Z0-9._-]*$'){throw 'Invalid integration profile'}
# This local bundle currently supports the body-only quiet candidate. Later
# combat/E3 activation needs an explicit packaging policy and acceptance pass.
$body=@($m.files|Where-Object destination -eq 'r6/scripts/CyberpunkRealism/BodyRuntime.reds')
$combat=@($m.files|Where-Object destination -eq 'r6/scripts/CyberpunkRealism/CombatNativeBridge.reds')
if($body.Count -ne 1 -or $combat.Count -ne 1){throw 'Missing body/combat policies'}
$bodyText=Get-Content -Raw (Resolve-SafeChildPath $project $body[0].source)
$combatText=Get-Content -Raw (Resolve-SafeChildPath $project $combat[0].source)
if($bodyText -notmatch 'public class CRBodyRuntimePolicy extends IScriptable \{\s+public static func Enabled\(\) -> Bool \{\s+return true;' -or $bodyText -notmatch 'public class CRBodyTestPolicy extends IScriptable \{\s+public static func Diagnostics\(\) -> Bool \{\s+return false;' -or $combatText -notmatch 'public class CRCombatRuntimePolicy extends IScriptable \{\s+public static func Enabled\(\) -> Bool \{\s+return false;'){throw 'Local body bundle requires body enabled, diagnostics off and combat disabled'}
& "$PSScriptRoot/Compile-Profile.ps1" -ManifestPath $ManifestPath
$work=Join-Path $project ('staging/integration-bundle-'+[guid]::NewGuid().ToString('N'))
$bundle=Join-Path $work 'realpass'
New-Item -ItemType Directory -Force -Path $bundle|Out-Null
$registry=Get-Content -Raw (Join-Path $project 'manifest/components.json')|ConvertFrom-Json
$licenseFiles=@{red4ext='red4ext-v1.30.0.txt';redscript='redscript-v0.5.31.txt';archivexl='archivexl-v1.27.3.txt';tweakxl='tweakxl-v1.11.4.txt';codeware='codeware-v1.20.3.txt';'mod-settings'='mod-settings-v0.2.21.txt';'input-loader'='input-loader-v0.2.3.txt';darkfuture='darkfuture-2.0.txt'}
$seen=@{};$componentIds=@{}
foreach($file in $m.files){
 $source=Resolve-SafeChildPath $project $file.source
 $relative='payload/'+$file.destination.Replace('\','/')
 $destination=Resolve-SafeChildPath $bundle $relative
 if($seen.ContainsKey($destination)){throw 'Duplicate bundled game destination'}
 $seen[$destination]=$true;$componentIds[$file.component]=$true
 if($file.component -notin @('cyberpunk-realism-body','project-diagnostics') -and -not $licenseFiles.ContainsKey($file.component)){throw "Unreviewed component: $($file.component)"}
 if($file.destination -match '(^|[\/])(Cyberpunk2077\.exe|final\.redscripts|UserSettings\.json|.*\.sav)$'){throw 'Game binaries, compiled cache or user files cannot enter this bundle'}
 if($file.destination -match '(^|[\\/])inputUserMappings\.xml$' -and ($file.destination.Replace('\','/') -ne 'red4ext/plugins/input_loader/inputUserMappings.xml' -or $file.component -ne 'input-loader')){throw 'Only the pinned Input Loader template is allowed; never bundle live game input mappings'}
 Copy-VerifiedPayload $source $destination $file.sha256
 $file.source=$relative
}
Write-JsonFile $m (Join-Path $bundle 'manifest/deployment.json')
$components=@(foreach($id in ($componentIds.Keys|Sort-Object)){
 if($licenseFiles.ContainsKey($id)){
  $component=@($registry.components|Where-Object id -eq $id)
  if($component.Count -ne 1){throw "Missing provenance: $id"}
  $license='LICENSES/'+$licenseFiles[$id]
  $source=Join-Path $project $license
  Copy-VerifiedPayload $source (Join-Path $bundle $license) (Get-Sha256 $source)
  $component[0]|Select-Object id,name,author,pinnedVersion,sourceUrl,archiveSha256,license,licenseUrl
 }else{
  [pscustomobject]@{id=$id;name=$id;author='realpass project';license='Project original; local development bundle'}
 }
})
Write-JsonFile ([ordered]@{buildId=$m.buildId;distribution='local-integration-only';components=$components;limitations='E3 missing; full Dark Future remains the integration base; standalone extraction and public transitive-notice review incomplete.'}) (Join-Path $bundle 'provenance/components.json')
$recipePaths=@('config/body-alpha1.json','config/patches/darkfuture-sleep-clamp.json','config/patches/darkfuture-body-tick.json','config/patches/darkfuture-body-authority.json','config/patches/darkfuture-body-previews.json','config/patches/darkfuture-backpack-layout.json','config/patches/darkfuture-injury-authority.json')
$careUI=@($m.files|Where-Object destination -eq 'r6/scripts/CyberpunkRealism/FieldCareUI.reds')
if($careUI.Count -eq 1 -and (Get-Content -Raw (Resolve-SafeChildPath $bundle $careUI[0].source)) -match 'public class CRFieldCarePopup extends CustomPopup'){
 $recipePaths+='config/patches/darkfuture-fieldcare-modal.json'
}
if(@($m.files|Where-Object destination -eq 'r6/scripts/CyberpunkRealism/FieldCareItemUse.reds').Count -eq 1){
 $recipePaths+='config/patches/darkfuture-fieldcare-consume.json'
}
if(@($m.files|Where-Object destination -eq 'r6/scripts/CyberpunkRealism/RealpassLocalization.reds').Count -eq 1){
 $recipePaths+='config/patches/darkfuture-realpass-presentation.json'
}
foreach($relative in $recipePaths){
 $source=Join-Path $project $relative
 Copy-VerifiedPayload $source (Join-Path $bundle ('provenance/'+$relative)) (Get-Sha256 $source)
}
foreach($name in @('Common','Deploy','Upgrade','Rollback','Verify-Deployment','Backup-Saves','Verify-IntegrationBundle','Install-IntegrationBundle')){
 $source=Join-Path $project ('tools/'+$name+'.ps1')
 Copy-VerifiedPayload $source (Join-Path $bundle ('tools/'+$name+'.ps1')) (Get-Sha256 $source)
}
$readme=Get-Content -Raw (Join-Path $project 'package/INTEGRATED-README.md')
[IO.File]::WriteAllText((Join-Path $bundle 'README.md'),$readme.Replace('{{BUILD_ID}}',$m.buildId))
$files=@(Get-ChildItem -LiteralPath $bundle -Recurse -File|Sort-Object FullName|ForEach-Object{
 [pscustomobject]@{path=$_.FullName.Substring($bundle.Length+1).Replace('\','/');sha256=Get-Sha256 $_.FullName;length=$_.Length}
})
Write-JsonFile ([ordered]@{schemaVersion=1;buildId=$m.buildId;distribution='local-integration-only';files=$files}) (Join-Path $bundle 'bundle-index.json')
& (Join-Path $bundle 'tools/Verify-IntegrationBundle.ps1')
$archive=Join-Path $project ('dist/realpass-integrated-'+$m.buildId+'-'+[guid]::NewGuid().ToString('N')+'.zip')
[IO.Compression.ZipFile]::CreateFromDirectory($work,$archive,[IO.Compression.CompressionLevel]::Optimal,$false)
$zip=[IO.Compression.ZipFile]::OpenRead($archive)
try{
 foreach($file in $files){
  $entry=$zip.GetEntry('realpass/'+$file.path)
  if($null -eq $entry){throw 'Missing ZIP entry'}
  $stream=$entry.Open();$sha=[Security.Cryptography.SHA256]::Create()
  try{$hash=[Convert]::ToHexString($sha.ComputeHash($stream))}finally{$stream.Dispose();$sha.Dispose()}
  if($hash -ne $file.sha256){throw 'ZIP payload verification failed'}
 }
 if($zip.Entries.Count -ne $files.Count+1){throw 'Unexpected ZIP contents'}
}finally{$zip.Dispose()}
Write-JsonFile ([ordered]@{builtAtUtc=[DateTime]::UtcNow.ToString('o');buildId=$m.buildId;distribution='local-integration-only';archive=$archive;archiveSha256=Get-Sha256 $archive;bundleRoot=$bundle;payloadFiles=$m.files.Count;indexedFiles=$files.Count;verified=$true;installed=$false}) (Join-Path $project 'reports/integration-bundle-build.json')
Write-Host "Verified full local integration bundle: $archive"