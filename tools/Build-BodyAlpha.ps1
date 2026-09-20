param()
. "$PSScriptRoot\Common.ps1"
$project=Get-ProjectRoot
& "$PSScriptRoot\Acquire-Components.ps1"
& "$PSScriptRoot\Acquire-Toolchain.ps1"
& "$PSScriptRoot\Stage-Components.ps1" -Profile m3-body-alpha1
& "$PSScriptRoot\Apply-BodyPreset.ps1"
$path=Join-Path $project 'manifest\m3-body-alpha1.deployment.json'
$manifest=Get-Content -Raw $path | ConvertFrom-Json
$overlay=Get-Content -Raw (Join-Path $project 'config\diagnostics-overlay.json') | ConvertFrom-Json
$overlay | Add-Member -NotePropertyName sha256 -NotePropertyValue (Get-Sha256 (Resolve-SafeChildPath $project $overlay.source))
$manifest.files += $overlay
Write-JsonFile $manifest $path
& "$PSScriptRoot\Compile-Profile.ps1"
Write-Host 'Body alpha build staged and compiled. Deployment is a separate operation.'
