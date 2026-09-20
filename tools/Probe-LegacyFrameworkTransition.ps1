[CmdletBinding()]
param(
    [string]$GameRoot = 'C:\Games\Steam\steamapps\common\Cyberpunk 2077',
    [string]$ReportPath,
    [string]$PlanPath
)

$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'Probe-LegacyFrameworkTransition.ps1 requires PowerShell 7 or newer.' }
. "$PSScriptRoot\Common.ps1"
. "$PSScriptRoot\LegacyFrameworkTransition.Core.ps1"

$project = Get-ProjectRoot
$game = Assert-GameRoot $GameRoot
Assert-GameStopped
$stamp = [DateTime]::UtcNow.ToString('yyyyMMdd-HHmmss')
if (-not $ReportPath) { $ReportPath = Join-Path $project ('reports\legacy-framework-transition-probe-' + $stamp + '.txt') }
if (-not $PlanPath) { $PlanPath = Join-Path $project ('reports\legacy-framework-transition-plan-' + $stamp + '.json') }
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $ReportPath) | Out-Null
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $PlanPath) | Out-Null

$baselinePath = Join-Path $project 'reference\cyberpunk\vanilla-baseline\files.csv'
$manifestPath = Join-Path $game 'biology\build-manifest.json'
$contractPath = Join-Path $project 'manifest\legacy-framework-transition.json'
$distributionPath = Join-Path $project 'manifest\distribution.json'
$profilesPath = Join-Path $project 'manifest\profiles.json'
$failed = $false

function Add-Report([string]$Text) { Add-Content -LiteralPath $ReportPath -Value $Text -Encoding utf8 }

@(
    'BIOLOGY W11.1 LEGACY FRAMEWORK TRANSITION PROBE',
    ('Started UTC: ' + [DateTime]::UtcNow.ToString('o')),
    ('Game root: ' + $game),
    'Mode: READ-ONLY. No game file is deleted or modified by this probe.',
    ''
) | Set-Content -LiteralPath $ReportPath -Encoding utf8

try {
    $gameExe = Resolve-SafeChildPath $game 'bin\x64\Cyberpunk2077.exe'
    $redmodExe = Resolve-SafeChildPath $game 'tools\redmod\bin\redMod.exe'
    Add-Report '=== SUPPORTED INSTALL FINGERPRINT ==='
    Add-Report ('Cyberpunk product version: ' + (Get-Item -LiteralPath $gameExe).VersionInfo.ProductVersion)
    Add-Report ('Cyberpunk SHA-256: ' + (Get-Sha256 $gameExe))
    if (Test-Path -LiteralPath $redmodExe -PathType Leaf) {
        Add-Report ('REDmod file version: ' + (Get-Item -LiteralPath $redmodExe).VersionInfo.FileVersion)
        Add-Report ('REDmod product version: ' + (Get-Item -LiteralPath $redmodExe).VersionInfo.ProductVersion)
        Add-Report ('REDmod SHA-256: ' + (Get-Sha256 $redmodExe))
    } else {
        Add-Report 'REDmod executable: MISSING'
    }
    Add-Report ''

    $plan = Get-LegacyFrameworkTransitionPlan -GameRoot $game -BaselinePath $baselinePath -ManifestPath $manifestPath -TransitionContractPath $contractPath -DistributionPath $distributionPath -ProfilesPath $profilesPath
    $plan | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $PlanPath -Encoding utf8
    $planHash = Get-Sha256 $PlanPath

    Add-Report '=== RECEIPT / CURRENT-PRODUCTION AUTHORITY ==='
    Add-Report ('Installed source revision: ' + $plan.installedSourceRevision)
    Add-Report ('Installed receipt SHA-256: ' + $plan.receiptSha256)
    Add-Report ('Tracked vanilla baseline SHA-256: ' + $plan.baselineSha256)
    Add-Report ('Transition contract SHA-256: ' + $plan.transitionContractSha256)
    Add-Report ('Current distribution SHA-256: ' + $plan.currentDistributionSha256)
    Add-Report ('Current profiles SHA-256: ' + $plan.currentProfilesSha256)
    Add-Report ''

    Add-Report '=== EXACT RETIRED PAYLOAD ==='
    foreach ($entry in @($plan.retiredFiles)) {
        Add-Report ("{0} | {1} | expected={2} | actual={3} | {4}" -f $entry.component,$entry.path,$entry.expectedSha256,$entry.actualSha256,$entry.state)
    }
    Add-Report ''
    Add-Report '=== REDSCRIPT PRESERVATION SET ==='
    foreach ($entry in @($plan.preservedRedscript)) { Add-Report ("PRESERVE | {0} | {1}" -f $entry.path,$entry.state) }
    Add-Report ''

    Add-Report '=== CONSUMER / AMBIGUITY EVIDENCE ==='
    if (@($plan.consumerEvidence).Count -eq 0) { Add-Report 'none detected on bounded mod-consumer surfaces' }
    else { foreach ($entry in @($plan.consumerEvidence)) { Add-Report ([string]$entry) } }
    foreach ($warning in @($plan.warnings)) { Add-Report ('WARNING: ' + $warning) }
    Add-Report ''

    if ($plan.safeToApply) {
        Add-Report 'DECISION: SAFE-TO-APPLY'
        Add-Report 'The exact deletion set is fully receipt/hash/baseline bounded and no competing-consumer evidence was found by the bounded scan.'
        Add-Report ('Deletion candidates: ' + @($plan.deletionCandidates).Count)
        Add-Report ('Already absent retired files: ' + @($plan.alreadyAbsent).Count)
    } else {
        Add-Report 'DECISION: BLOCKED / FAIL-CLOSED'
        foreach ($blocker in @($plan.blockers)) { Add-Report ('BLOCKER: ' + $blocker) }
        $failed = $true
    }
    Add-Report ''
    Add-Report ('PLAN PATH: ' + [IO.Path]::GetFullPath($PlanPath))
    Add-Report ('PLAN SHA-256: ' + $planHash)
    Add-Report ('Completed UTC: ' + [DateTime]::UtcNow.ToString('o'))

    Write-Host "LEGACY FRAMEWORK TRANSITION DECISION: $(if ($plan.safeToApply) { 'SAFE-TO-APPLY' } else { 'BLOCKED' })"
    Write-Host "PLAN: $([IO.Path]::GetFullPath($PlanPath))"
    Write-Host "PLAN SHA-256: $planHash"
    Write-Host "REPORT: $([IO.Path]::GetFullPath($ReportPath))"
} catch {
    $failed = $true
    Add-Report ''
    Add-Report '=== PROBE FAILURE ==='
    Add-Report ('Exception type: ' + $_.Exception.GetType().FullName)
    Add-Report ('Error: ' + $_.Exception.Message)
    Add-Report ('Completed UTC: ' + [DateTime]::UtcNow.ToString('o'))
    throw
} finally {
    Write-Host "REPORT: $([IO.Path]::GetFullPath($ReportPath))"
}

if ($failed) { exit 2 }
