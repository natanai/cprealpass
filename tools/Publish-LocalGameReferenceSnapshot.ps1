[CmdletBinding()]
param(
    [string]$GameRoot = 'C:\Games\Steam\steamapps\common\Cyberpunk 2077'
)

$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'Publish-LocalGameReferenceSnapshot.ps1 requires PowerShell 7 or newer.' }
. "$PSScriptRoot\Common.ps1"

$project = Get-ProjectRoot
$game = Assert-GameRoot $GameRoot
Assert-GameStopped

$dirtyOutsideReference = @(& git -C $project status --porcelain=v1 --untracked-files=no -- . ':(exclude)reference/cyberpunk')
if ($LASTEXITCODE -ne 0) { throw 'Unable to inspect repository state before publishing game snapshot.' }
if ($dirtyOutsideReference.Count -gt 0) {
    throw "Refusing to publish game snapshot from a checkout with other tracked changes:`n$($dirtyOutsideReference -join "`n")"
}

& "$PSScriptRoot\Refresh-LocalGameReference.ps1" -RepoRoot $project -GamePath $game
if ($LASTEXITCODE -ne 0) { throw 'Refresh-LocalGameReference.ps1 failed.' }

$changes = @(& git -C $project status --porcelain=v1 -- 'reference/cyberpunk')
if ($LASTEXITCODE -ne 0) { throw 'Unable to inspect refreshed snapshot changes.' }
if ($changes.Count -eq 0) {
    Write-Host 'No GitHub-safe game-reference metadata changed; no snapshot branch was created.' -ForegroundColor Green
    return $null
}

$stamp = [DateTime]::UtcNow.ToString('yyyyMMdd-HHmmss')
$branch = "local-game-snapshot-$stamp"
$current = (& git -C $project branch --show-current).Trim()
if ([string]::IsNullOrWhiteSpace($current)) { throw 'Snapshot publishing requires a named current Git branch.' }

& git -C $project switch -c $branch
if ($LASTEXITCODE -ne 0) { throw "Could not create snapshot branch: $branch" }
& git -C $project add -- 'reference/cyberpunk'
if ($LASTEXITCODE -ne 0) { throw 'Could not stage GitHub-safe game-reference metadata.' }

# Fresh disposable test clones are not required to have a user-level Git author
# configured. Scope a neutral identity to this one generated metadata commit only.
$commitAuthorName = 'RealPass Snapshot'
$commitAuthorEmail = 'realpass-snapshot@users.noreply.github.com'
& git -C $project -c "user.name=$commitAuthorName" -c "user.email=$commitAuthorEmail" commit -m "Capture local Cyberpunk game snapshot $stamp"
if ($LASTEXITCODE -ne 0) { throw 'Could not commit local game-reference snapshot.' }
& git -C $project push -u origin $branch
if ($LASTEXITCODE -ne 0) { throw 'Could not push local game-reference snapshot branch.' }

Write-Host ''
Write-Host 'PUBLISHED: current GitHub-safe game snapshot.' -ForegroundColor Green
Write-Host "Branch: $branch" -ForegroundColor Cyan
Write-Host "Previous branch: $current"
Write-Host 'No Cyberpunk-owned file content was uploaded.' -ForegroundColor Green
Write-Host 'Give the branch name to a remote agent if this state should be merged/archived.' -ForegroundColor Cyan
return $branch
