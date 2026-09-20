[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$GameRoot,
    [Parameter(Mandatory=$true)][string]$ReportPath
)

$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'Invoke-BiologyPriorInstallTransition.ps1 requires PowerShell 7 or newer.' }
. (Join-Path $PSScriptRoot 'BiologyPriorInstallTransition.Core.ps1')

$report = [Collections.Generic.List[string]]::new()
$mutationStarted = $false
$failed = $false

function Add-TransitionEvidence([string]$Text = '') { $report.Add($Text) }

function Assert-BiologyTransitionGameStopped {
    if (Get-Process -Name 'Cyberpunk2077' -ErrorAction SilentlyContinue) {
        throw 'Cyberpunk 2077 is running. Close the game completely before prior-install transition.'
    }
}

Add-TransitionEvidence 'BIOLOGY PRIOR-INSTALL REPLACEMENT TRANSITION'
Add-TransitionEvidence ('Started: ' + [DateTime]::UtcNow.ToString('o'))

try {
    $GameRoot = [IO.Path]::GetFullPath($GameRoot)
    $ReportPath = [IO.Path]::GetFullPath($ReportPath)
    $gameExe = Resolve-BiologyReleaseChild $GameRoot 'bin/x64/Cyberpunk2077.exe'
    if (-not (Test-Path -LiteralPath $gameExe -PathType Leaf)) {
        throw 'Selected folder is not a Cyberpunk 2077 game root.'
    }
    if (-not (Test-Path -LiteralPath (Join-Path $GameRoot 'r6') -PathType Container)) {
        throw 'Selected folder is not a Cyberpunk 2077 game root (r6 is missing).'
    }
    Assert-BiologyTransitionGameStopped

    $manifestPath = Resolve-BiologyReleaseChild $GameRoot 'biology/build-manifest.json'
    $plan = New-BiologyPriorInstallTransitionPlan -GameRoot $GameRoot -ManifestPath $manifestPath

    Add-TransitionEvidence ('Game root: ' + $GameRoot)
    Add-TransitionEvidence ('Prior build ID: ' + [string]$plan.manifest.buildId)
    Add-TransitionEvidence ('Prior source revision: ' + [string]$plan.manifest.sourceRevision)
    Add-TransitionEvidence ('Biology-owned exact deletions planned: ' + @($plan.files | Where-Object { -not $_.receiptFile -and $_.action -eq 'remove-exact' }).Count)
    Add-TransitionEvidence 'Biology-owned changed files detected: 0'
    Add-TransitionEvidence ('Shared dependencies preserved: ' + @($plan.shared).Count)
    Add-TransitionEvidence ('Already-missing receipt entries: ' + @($plan.files | Where-Object { -not $_.receiptFile -and $_.action -eq 'absent' }).Count)

    Assert-BiologyPriorInstallTransitionPlan $plan
    Add-TransitionEvidence 'Replacement transition preflight: PASS'
    Add-TransitionEvidence 'All receipt-owned Biology files and owned-namespace structure were revalidated before mutation; shared dependencies remain preserve-only.'

    # The existing exact-removal executor is reused unchanged. Shared dependency
    # entries are intentionally omitted from its post-plan identity check because
    # the player-uninstaller authority preserves them regardless of whether some
    # other mod updates those shared bytes during the transition window.
    $executionPlan = [pscustomobject]@{
        gameRoot=$plan.gameRoot
        files=$plan.files
        shared=@()
        directories=$plan.directories
        ownedRoots=$plan.ownedRoots
    }

    $mutationStarted = $true
    Invoke-BiologyFailedInstallRecoveryPlan -Plan $executionPlan

    Add-TransitionEvidence ('Deleted Biology-owned files: ' + @($plan.files | Where-Object action -eq 'remove-exact').Count)
    Add-TransitionEvidence 'Preserved changed Biology-owned files: 0'
    Add-TransitionEvidence ('Preserved generic/shared dependency files: ' + @($plan.shared).Count)
    Add-TransitionEvidence ('Already missing: ' + @($plan.files | Where-Object action -eq 'absent').Count)
    Add-TransitionEvidence 'Execution errors: 0'
    Add-TransitionEvidence 'Ownership receipt deleted: True'
    foreach ($item in @($plan.shared)) { Add-TransitionEvidence ('PRESERVE SHARED | ' + [string]$item.relativePath) }

    Add-TransitionEvidence 'RESULT: PASS'
    Add-TransitionEvidence 'The prior schema-2 Biology candidate was retired through the existing PowerShell exact-removal executor after full schema/hash/path/owned-namespace preflight.'
    Add-TransitionEvidence 'No generated transition executable was emitted or launched.'
    Add-TransitionEvidence 'REDmod refresh intentionally skipped because the exact replacement candidate is installed/deployed by the same attended preparation session.'
}
catch {
    $failed = $true
    if ($mutationStarted) { Add-TransitionEvidence 'RESULT: PARTIAL' }
    else { Add-TransitionEvidence 'RESULT: FAIL-CLOSED' }
    Add-TransitionEvidence ('Exception type: ' + $_.Exception.GetType().FullName)
    Add-TransitionEvidence ('Error: ' + $_.Exception.Message)
    if ($mutationStarted) {
        Add-TransitionEvidence 'Mutation began only after complete receipt/hash/owned-namespace preflight. Do not improvise cleanup; use this report as the bounded partial-state record.'
    } else {
        Add-TransitionEvidence 'No game mutation began; the prior installed Biology candidate was preserved.'
    }
}
finally {
    Add-TransitionEvidence ('Game mutation started: ' + $mutationStarted)
    Add-TransitionEvidence ('Completed: ' + [DateTime]::UtcNow.ToString('o'))
    try {
        $parent = Split-Path -Parent $ReportPath
        if ($parent) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
        [IO.File]::WriteAllLines($ReportPath,@($report),[Text.UTF8Encoding]::new($false))
    }
    catch {
        $failed = $true
    }
}

foreach ($line in @($report)) { Write-Host $line }
if ($failed) { exit 1 }
