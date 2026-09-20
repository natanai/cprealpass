param()
if($PSVersionTable.PSVersion.Major -lt 7){throw 'PowerShell 7 or newer is required.'}
. "$PSScriptRoot/Common.ps1"
$bundle=Get-ProjectRoot
$index=Get-Content -Raw (Join-Path $bundle 'bundle-index.json')|ConvertFrom-Json
if($index.schemaVersion -ne 1 -or $index.distribution -ne 'local-integration-only' -or $index.buildId -notmatch '^[a-zA-Z0-9][a-zA-Z0-9._-]*$'){throw 'Unsupported integration bundle index'}
$seen=@{}
foreach($file in $index.files){
 $path=Resolve-SafeChildPath $bundle $file.path
 if($seen.ContainsKey($path) -or $file.sha256 -notmatch '^[A-Fa-f0-9]{64}$' -or (Get-ExistingHash $path) -ne $file.sha256){throw "Bundle missing, duplicate or changed file: $($file.path)"}
 $seen[$path]=$file.sha256
}
$manifest=Get-Content -Raw (Join-Path $bundle 'manifest/deployment.json')|ConvertFrom-Json
if($manifest.schemaVersion -ne 1 -or $manifest.buildId -ne $index.buildId){throw 'Bundle/profile identity mismatch'}
$destinations=@{}
foreach($file in $manifest.files){
 $source=Resolve-SafeChildPath $bundle $file.source
 $destination=Resolve-SafeChildPath (Join-Path $bundle 'payload') $file.destination
 if($source -ne $destination -or $destinations.ContainsKey($destination) -or -not $seen.ContainsKey($source) -or $seen[$source] -ne $file.sha256){throw 'Bundle payload mapping does not match its verified index'}
 $destinations[$destination]=$true
}
# Reject unindexed payloads/tools/metadata, but allow the report directory created
# by the included deployment verifier. No persistent state belongs in the bundle.
foreach($dir in @('payload','tools','manifest','LICENSES','provenance')){
 $path=Join-Path $bundle $dir
 if(-not (Test-Path -LiteralPath $path -PathType Container)){throw "Missing bundle directory: $dir"}
 foreach($file in Get-ChildItem -LiteralPath $path -File -Recurse -Force){
  if(-not $seen.ContainsKey($file.FullName)){throw "Unindexed bundle file: $($file.FullName)"}
 }
}
Write-Host "Integration bundle verified: $($manifest.files.Count) game payload files; $($index.files.Count) indexed files."