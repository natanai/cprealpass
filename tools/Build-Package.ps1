param([string]$RecipePath='manifest/package.json')
. "$PSScriptRoot\Common.ps1"
$project=Get-ProjectRoot
$recipe=Get-Content -Raw (Resolve-SafeChildPath $project $RecipePath)|ConvertFrom-Json
if($recipe.schemaVersion -ne 1 -or $recipe.id -notmatch '^[a-z0-9][a-z0-9-]*$' -or $recipe.version -notmatch '^[A-Za-z0-9][A-Za-z0-9.-]*$'){throw 'Invalid development source package identity'}
$id=$recipe.id+'-'+$recipe.version+'-'+[guid]::NewGuid().ToString('N')
$work=Resolve-SafeChildPath $project ('staging\package-'+$id)
$seen=@{}
$files=@(foreach($file in $recipe.files){
 if($file.origin -ne 'project-original'){throw 'The development source builder accepts project-original modules only.'}
 $source=Resolve-SafeChildPath $project $file.source
 $destination=Resolve-SafeChildPath $work $file.destination
 if($seen.ContainsKey($destination)){throw 'Duplicate package destination'}
 $seen[$destination]=$true
 $hash=Get-Sha256 $source
 [pscustomobject]@{source=$source;target=$destination;path=$file.destination;sha256=$hash;origin=$file.origin;module=$file.module}
})
foreach($file in $files){Copy-VerifiedPayload $file.source $file.target $file.sha256}
$manifest=[ordered]@{schemaVersion=1;packageId=$recipe.id;version=$recipe.version;status=$recipe.status;gameVersion=$recipe.gameVersion;requiredExternalComponents=$recipe.requiredExternalComponents;files=@($files|Select-Object path,sha256,origin,module)}
$metadataRoot=Join-Path $work 'BiologySource'
New-Item -ItemType Directory -Force -Path $metadataRoot|Out-Null
Write-JsonFile $manifest (Join-Path $metadataRoot 'package-manifest.json')
$out=Join-Path $project 'dist'
New-Item -ItemType Directory -Force -Path $out|Out-Null
$archive=Resolve-SafeChildPath $out ($id+'.zip')
[IO.Compression.ZipFile]::CreateFromDirectory($work,$archive,[IO.Compression.CompressionLevel]::Optimal,$false)
$zip=[IO.Compression.ZipFile]::OpenRead($archive)
try {
 if($zip.Entries.Count -ne $files.Count+1){throw 'Unexpected archive entry count'}
 foreach($file in $files){
  $entry=$zip.GetEntry($file.path.Replace('\','/'))
  if(-not $entry){throw "Missing archive entry: $($file.path)"}
  $stream=$entry.Open();$sha=[Security.Cryptography.SHA256]::Create()
  try{$hash=[Convert]::ToHexString($sha.ComputeHash($stream))}finally{$stream.Dispose();$sha.Dispose()}
  if($hash -ne $file.sha256){throw 'Archive payload hash mismatch'}
 }
}finally{$zip.Dispose()}
$report=[ordered]@{builtAtUtc=[DateTime]::UtcNow.ToString('o');packageId=$recipe.id;version=$recipe.version;status=$recipe.status;archive=$archive;archiveSha256=(Get-Sha256 $archive);payloadFiles=$files.Count;verified=$true;manifest=$manifest;deployment='Not deployed. This is a redistribution-safe Biology development/source artifact, not the canonical playable package.'}
Write-JsonFile $report (Join-Path $project 'reports/package-build.json')
Write-Host "Verified Biology development source package: $archive"
