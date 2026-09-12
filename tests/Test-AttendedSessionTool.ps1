$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\tools\Common.ps1"
$project = Get-ProjectRoot
$path = Join-Path $project 'tools/Prepare-AttendedSession.ps1'
$source = Get-Content -Raw -LiteralPath $path
$script:checks = 0
function Check($condition,[string]$message) { if (-not $condition) { throw $message }; $script:checks++ }

Check ($source.Contains('Build-AttendedAcceptance.ps1')) 'Session tool bypasses exact attended builder.'
Check ($source.Contains('Upgrade.ps1') -and $source.Contains('-WhatIf')) 'Session tool lacks the real upgrade planner preflight.'
Check ($source.Contains('if (-not $Deploy)')) 'Live deployment is not explicitly opt-in.'
Check ($source.Contains('Backup-Saves.ps1')) 'Live deployment does not require a save backup.'
Check ($source.Contains('Verify-Deployment.ps1')) 'Live deployment is not receipt-verified.'
Check ($source.Contains('Assert-GameStopped')) 'Session tool does not require Cyberpunk to be stopped.'
Check ($source.Contains('[switch]$Diagnostics')) 'Attended diagnostics cannot be explicitly selected.'
Check ($source.Contains('[switch]$ShowTraditionalHealthBars')) 'Healthbar comparison build cannot be explicitly selected.'
Check ($source.Contains('traditionalHealthBars = [bool]$ShowTraditionalHealthBars')) 'Session evidence does not record healthbar mode.'
Check ($source.Contains("status = 'preflight-passed'")) 'Preflight evidence status missing.'
Check ($source.Contains("status = 'deployed-and-verified'")) 'Verified deployment evidence status missing.'
Check ($source.Contains('deploymentReceipt')) 'Session evidence does not preserve rollback receipt.'
Check ($source.Contains('saveBackup')) 'Session evidence does not preserve save-backup location.'

# The ordinary path should need only a new build ID: recover the exact active build
# manifest from the verified deployment pointer unless the local agent overrides it.
Check ($source.Contains('$SourceManifestPath = ''manifest/'' + $current.buildId + ''.deployment.json''')) 'Session tool cannot derive the active source manifest.'
Check ($source.Contains('$current.status -ne ''deployed''')) 'Auto-discovery does not reject incomplete deployment state.'
Check ($source.Contains('Current deployed build is')) 'Missing local source manifest is not explained clearly.'
Check ($source.Contains('stateRoot = $StateRoot')) 'Session evidence does not preserve the deployment-state root.'

# Preparation may write only project-local generated state/reports. It must never
# start the game or create an unattended helper environment.
foreach ($danger in @('Start-Process','Cyberpunk2077.exe"','Invoke-WebRequest','Register-ScheduledTask','New-Service','Start-Job','Register-ObjectEvent')) {
    Check (-not $source.Contains($danger)) "Session tool contains unattended side effect: $danger"
}
Check ($source.Contains('This tool does not start Cyberpunk')) 'Tool does not state its launch boundary.'
Check ($source.Contains('rerun the same command with -Deploy')) 'Preflight does not give a deterministic promotion path.'

Write-Host "PASS: $script:checks attended-session orchestration checks; active build is auto-based, preflight is default, and live install requires explicit deploy + verified save backup."
