param()
. "$PSScriptRoot\Common.ps1"
$project = Get-ProjectRoot
& "$PSScriptRoot\Acquire-Components.ps1"
& "$PSScriptRoot\Acquire-Toolchain.ps1"
& "$PSScriptRoot\Stage-Components.ps1" -Profile m3-body-alpha2
$relative = 'manifest/m3-body-alpha2.deployment.json'
& "$PSScriptRoot\Apply-BodyPreset.ps1" -ManifestPath $relative
& "$PSScriptRoot\Apply-SourcePatch.ps1" -ManifestPath $relative -PatchPath 'config/patches/darkfuture-sleep-clamp.json'
$path = Resolve-SafeChildPath $project $relative
$manifest = Get-Content -Raw $path | ConvertFrom-Json
$overlay = Get-Content -Raw (Join-Path $project 'config/diagnostics-overlay.json') | ConvertFrom-Json
$overlay | Add-Member -NotePropertyName sha256 -NotePropertyValue (Get-Sha256 (Resolve-SafeChildPath $project $overlay.source))
$manifest.files += $overlay
Write-JsonFile $manifest $path
& "$PSScriptRoot\Compile-Profile.ps1" -ManifestPath $relative
Write-Host 'Body alpha 2 staged and compiled only. Keep the tested live build until the combined next batch is ready.'
