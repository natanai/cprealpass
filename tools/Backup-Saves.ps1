param([string]$SaveRoot, [string]$BackupRoot)
. "$PSScriptRoot\Common.ps1"
Assert-GameStopped
$project=Get-ProjectRoot
if(-not $SaveRoot){$baseline=Get-Content -Raw (Join-Path $project 'manifest\baseline.json') | ConvertFrom-Json;$SaveRoot=$baseline.saves.root}
$SaveRoot=(Resolve-Path -LiteralPath $SaveRoot).Path.TrimEnd('\')
if(-not $BackupRoot){$BackupRoot=Join-Path $project 'snapshots\saves'}
$destination=Resolve-SafeChildPath ([IO.Path]::GetFullPath($BackupRoot)) ([DateTime]::UtcNow.ToString('yyyyMMdd-HHmmss')+'-'+[guid]::NewGuid().ToString('N').Substring(0,8))
if($destination.StartsWith($SaveRoot+'\',[StringComparison]::OrdinalIgnoreCase)){throw 'Backup location must be outside the live save directory.'}
$files=@(Get-ChildItem -LiteralPath $SaveRoot -File -Recurse)
if($files.Count -eq 0){throw 'Save directory contains no files; backup not established.'}
$records=@(foreach($file in $files){
    $relative=$file.FullName.Substring($SaveRoot.Length+1)
    $source=Resolve-SafeChildPath $SaveRoot $relative
    $target=Resolve-SafeChildPath $destination ('files\'+$relative)
    $hash=Get-Sha256 $source
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $target) | Out-Null
    Copy-Item -LiteralPath $source -Destination $target
    if((Get-Sha256 $target) -ne $hash -or (Get-Sha256 $source) -ne $hash){throw 'Save changed during backup; do not treat snapshot as verified.'}
    [ordered]@{path=$relative;sha256=$hash;length=$file.Length}
})
Assert-GameStopped
$after=@(Get-ChildItem -LiteralPath $SaveRoot -Recurse -File)
if($after.Count -ne $files.Count){throw 'Save directory changed during backup.'}
foreach($record in $records){if((Get-Sha256 (Resolve-SafeChildPath $SaveRoot $record.path)) -ne $record.sha256){throw 'Save changed during backup.'}}
Write-JsonFile ([ordered]@{createdAtUtc=[DateTime]::UtcNow.ToString('o');source=$SaveRoot;status='verified';files=$records}) (Join-Path $destination 'backup.json')
Write-Host "Verified backup of $($files.Count) save files: $destination"
return $destination
