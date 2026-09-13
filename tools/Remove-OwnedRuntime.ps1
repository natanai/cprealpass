param(
    [string]$GameRoot = 'C:\Games\Steam\steamapps\common\Cyberpunk 2077',
    [string]$StateRoot
)
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\Common.ps1"
$project = Get-ProjectRoot
$GameRoot = Assert-GameRoot $GameRoot
Assert-GameStopped
if (-not $StateRoot) { $StateRoot = Join-Path $project 'snapshots\deployment-state' }
$StateRoot = [IO.Path]::GetFullPath($StateRoot)
$statePath = Join-Path $StateRoot 'owned-current.json'
if (-not (Test-Path -LiteralPath $statePath -PathType Leaf)) {
    Write-Host 'No flat owned-runtime install state is present. Nothing to remove.'
    return
}
$state = Get-Content -Raw -LiteralPath $statePath | ConvertFrom-Json
if ($state.schemaVersion -ne 1 -or $state.mode -ne 'flat-owned-development-install') { throw 'Unexpected owned-runtime state file.' }
if ([IO.Path]::GetFullPath([string]$state.gameRoot) -ne [IO.Path]::GetFullPath($GameRoot)) { throw 'Owned-runtime state belongs to another game root.' }
$files = @($state.files)
for ($i = 0; $i -lt $files.Count; $i++) {
    $file = $files[$i]
    $percent = if ($files.Count -gt 0) { [int](100.0 * ($i + 1) / $files.Count) } else { 100 }
    Write-Progress -Activity 'Removing owned realpass runtime' -Status "$($i + 1)/$($files.Count): $($file.destination)" -PercentComplete $percent
    $path = Resolve-SafeChildPath $GameRoot ([string]$file.destination)
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { continue }
    $currentHash = Get-Sha256 $path
    if ($currentHash -eq [string]$file.sha256) {
        Remove-Item -LiteralPath $path -Force
    } else {
        Write-Warning "Leaving changed file in place: $path"
    }
}
Write-Progress -Activity 'Removing owned realpass runtime' -Completed
foreach ($relative in @('r6/scripts/CyberpunkRealism','r6/tweaks/CyberpunkRealism')) {
    $path = Resolve-SafeChildPath $GameRoot $relative
    if (Test-Path -LiteralPath $path -PathType Container) {
        $remaining = @(Get-ChildItem -LiteralPath $path -Force -Recurse -ErrorAction SilentlyContinue)
        if ($remaining.Count -eq 0) { Remove-Item -LiteralPath $path -Force }
    }
}
Remove-Item -LiteralPath $statePath -Force
Write-Host 'Owned realpass payload removed where hashes still matched the recorded install.'
Write-Host 'If stock game files ever need repair, use Steam Verify Files or reinstall Cyberpunk. Steam may not remove unrelated extra mod files, so this cleanup tool remains the first step for realpass-owned files.'
