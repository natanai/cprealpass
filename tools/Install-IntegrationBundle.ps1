param(
 [Parameter(Mandatory=$true)][string]$GameRoot,
 [Parameter(Mandatory=$true)][string]$StateRoot,
 [string]$SaveRoot,
 [switch]$WhatIf
)
if($PSVersionTable.PSVersion.Major -lt 7){throw 'PowerShell 7 or newer is required.'}
. "$PSScriptRoot/Common.ps1"
$bundle=Get-ProjectRoot
$StateRoot=[IO.Path]::GetFullPath($StateRoot).TrimEnd('\','/')
$bundleFull=[IO.Path]::GetFullPath($bundle).TrimEnd('\','/')
if($StateRoot -eq $bundleFull -or $StateRoot.StartsWith($bundleFull+'\',[StringComparison]::OrdinalIgnoreCase)){throw 'Use a durable StateRoot outside the extracted bundle; reuse the existing deployment-state folder for upgrades.'}
$GameRoot=Assert-GameRoot $GameRoot
Assert-GameStopped
& "$PSScriptRoot/Verify-IntegrationBundle.ps1"
$manifest=Join-Path $bundle 'manifest/deployment.json'
$current=Join-Path $StateRoot 'current.json'
$command='Deploy.ps1'
if(Test-Path -LiteralPath $current){
 $receipt=Get-Content -Raw $current|ConvertFrom-Json
 if($receipt.status -eq 'deployed'){$command='Upgrade.ps1'}elseif($receipt.status -ne 'rolled-back'){throw "Existing deployment requires recovery: $current"}
}
# Full existing collision/hash/version/receipt preflight precedes any save copy.
& "$PSScriptRoot/$command" -GameRoot $GameRoot -ManifestPath $manifest -StateRoot $StateRoot -WhatIf | Out-Host
if($WhatIf){Write-Host 'Dry run only. No game or save files changed.';return}
if([string]::IsNullOrWhiteSpace($SaveRoot)){throw 'Provide SaveRoot for a verified backup of existing saves before installing this local candidate.'}
$backup=& "$PSScriptRoot/Backup-Saves.ps1" -SaveRoot $SaveRoot -BackupRoot (Join-Path $StateRoot 'save-backups')
Assert-GameStopped
$installed=& "$PSScriptRoot/$command" -GameRoot $GameRoot -ManifestPath $manifest -StateRoot $StateRoot
# Idempotent upgrades can return without a path; the durable pointer is canonical.
if(-not $installed){$installed=(Get-Content -Raw $current|ConvertFrom-Json).receiptPath}
& "$PSScriptRoot/Verify-Deployment.ps1" -GameRoot $GameRoot -ReceiptPath $installed
Write-Host "Installed and verified. Save backup: $backup"
Write-Host "Recovery receipt: $installed"
return $installed