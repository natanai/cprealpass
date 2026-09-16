[CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true)][string]$PlanPath,
    [Parameter(Mandatory=$true)][ValidatePattern('^[A-Fa-f0-9]{64}$')][string]$ExpectedPlanSha256,
    [string]$GameRoot = 'C:\Games\Steam\steamapps\common\Cyberpunk 2077',
    [string]$ReportPath
)

$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'Remove-LegacyFrameworkTransition.ps1 requires PowerShell 7 or newer.' }
. "$PSScriptRoot\Common.ps1"
. "$PSScriptRoot\LegacyFrameworkTransition.Core.ps1"

$project = Get-ProjectRoot
$game = Assert-GameRoot $GameRoot
Assert-GameStopped
$stamp = [DateTime]::UtcNow.ToString('yyyyMMdd-HHmmss')
if (-not $ReportPath) { $ReportPath = Join-Path $project ('reports\legacy-framework-transition-cleanup-' + $stamp + '.txt') }
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $ReportPath) | Out-Null

$planFull = [IO.Path]::GetFullPath($PlanPath)
$expectedPlanHash = $ExpectedPlanSha256.ToUpperInvariant()
$baselinePath = Join-Path $project 'reference\cyberpunk\vanilla-baseline\files.csv'
$manifestPath = Join-Path $game 'biology\build-manifest.json'
$contractPath = Join-Path $project 'manifest\legacy-framework-transition.json'
$distributionPath = Join-Path $project 'manifest\distribution.json'
$profilesPath = Join-Path $project 'manifest\profiles.json'
$contract = Get-Content -Raw -LiteralPath $contractPath | ConvertFrom-Json

function Add-Report([string]$Text) { Add-Content -LiteralPath $ReportPath -Value $Text -Encoding utf8 }
function Get-CandidateSignature($Entries) {
    (@($Entries | Sort-Object path | ForEach-Object { ([string]$_.path) + '|' + ([string]$_.expectedSha256).ToUpperInvariant() }) -join "`n")
}

@(
    'BIOLOGY W11.1 LEGACY FRAMEWORK TRANSITION CLEANUP',
    ('Started UTC: ' + [DateTime]::UtcNow.ToString('o')),
    ('Game root: ' + $game),
    ('Plan path: ' + $planFull),
    ('Expected plan SHA-256: ' + $expectedPlanHash),
    'Policy: exact planned files only; no recursive shared-root deletion; redscript and legacy preference state are never targeted.',
    ''
) | Set-Content -LiteralPath $ReportPath -Encoding utf8

try {
    if (-not (Test-Path -LiteralPath $planFull -PathType Leaf)) { throw "Transition plan does not exist: $planFull" }
    $actualPlanHash = Get-Sha256 $planFull
    if ($actualPlanHash -ne $expectedPlanHash) { throw "Transition plan hash changed. Expected $expectedPlanHash, actual $actualPlanHash." }
    $priorPlan = Get-Content -Raw -LiteralPath $planFull | ConvertFrom-Json
    if ($priorPlan.schemaVersion -ne 1 -or $priorPlan.safeToApply -ne $true) { throw 'Transition plan was not a SAFE-TO-APPLY schema-1 plan.' }
    if ([IO.Path]::GetFullPath([string]$priorPlan.gameRoot) -ne [IO.Path]::GetFullPath($game)) { throw 'Transition plan belongs to a different game root.' }

    $fresh = Get-LegacyFrameworkTransitionPlan -GameRoot $game -BaselinePath $baselinePath -ManifestPath $manifestPath -TransitionContractPath $contractPath -DistributionPath $distributionPath -ProfilesPath $profilesPath
    if ($fresh.safeToApply -ne $true) {
        foreach ($blocker in @($fresh.blockers)) { Add-Report ('BLOCKER: ' + $blocker) }
        throw 'Current installed state no longer satisfies the transition safety plan.'
    }
    foreach ($name in @('receiptSha256','baselineSha256','transitionContractSha256','currentDistributionSha256','currentProfilesSha256')) {
        if ([string]$fresh.$name -ne [string]$priorPlan.$name) { throw "Transition evidence changed since planning: $name" }
    }
    if ((Get-CandidateSignature $fresh.deletionCandidates) -ne (Get-CandidateSignature $priorPlan.deletionCandidates)) {
        throw 'Exact deletion set changed since planning.'
    }

    $redscriptBefore = @{}
    foreach ($entry in @($fresh.preservedRedscript)) {
        $full = Resolve-LegacySafeChildPath $game ([string]$entry.path)
        if (Test-Path -LiteralPath $full -PathType Leaf) { $redscriptBefore[[string]$entry.path] = Get-Sha256 $full }
    }

    Add-Report '=== VALIDATED DELETION SET ==='
    foreach ($entry in @($fresh.deletionCandidates)) { Add-Report ("DELETE | {0} | {1} | {2}" -f $entry.component,$entry.path,$entry.expectedSha256) }
    foreach ($entry in @($fresh.alreadyAbsent)) { Add-Report ("ALREADY ABSENT | {0} | {1}" -f $entry.component,$entry.path) }
    Add-Report ''

    $parentCandidates = [Collections.Generic.List[string]]::new()
    foreach ($entry in @($fresh.deletionCandidates)) {
        $relative = Assert-LegacyRelativePath ([string]$entry.path)
        $full = Resolve-LegacySafeChildPath $game $relative
        if (-not (Test-Path -LiteralPath $full -PathType Leaf)) { throw "Planned file disappeared before deletion: $relative" }
        $actual = Get-Sha256 $full
        if ($actual -ne ([string]$entry.expectedSha256).ToUpperInvariant()) { throw "Planned file changed before deletion: $relative" }
        if ($PSCmdlet.ShouldProcess($full,'Delete exact retired Biology-introduced framework file')) {
            Remove-Item -LiteralPath $full -Force
            $parentCandidates.Add((Split-Path -Parent $full))
        }
    }

    Remove-LegacyEmptyParentDirectories -GameRoot $game -StartDirectories @($parentCandidates.ToArray()) -ProtectedDirectories @($contract.protectedDirectories)

    foreach ($entry in @($fresh.deletionCandidates)) {
        $full = Resolve-LegacySafeChildPath $game ([string]$entry.path)
        if (Test-Path -LiteralPath $full) { throw "Retired dependency path remains after cleanup: $($entry.path)" }
    }
    foreach ($entry in $redscriptBefore.GetEnumerator()) {
        $full = Resolve-LegacySafeChildPath $game ([string]$entry.Key)
        if (-not (Test-Path -LiteralPath $full -PathType Leaf)) { throw "Protected redscript file disappeared during cleanup: $($entry.Key)" }
        if ((Get-Sha256 $full) -ne [string]$entry.Value) { throw "Protected redscript file changed during cleanup: $($entry.Key)" }
    }

    Add-Report 'RESULT: PASS'
    Add-Report ('Deleted exact retired files: ' + @($fresh.deletionCandidates).Count)
    Add-Report ('Retired files already absent: ' + @($fresh.alreadyAbsent).Count)
    Add-Report ('Protected redscript files reverified: ' + $redscriptBefore.Count)
    if (-not [string]::IsNullOrWhiteSpace([string]$fresh.preferencePath)) { Add-Report ('Preserved legacy preference path: ' + [string]$fresh.preferencePath) }
    Add-Report 'Shared roots were not recursively deleted.'
    Add-Report ('Completed UTC: ' + [DateTime]::UtcNow.ToString('o'))
    Write-Host 'PASS: exact pre-W10 Mod Settings / ArchiveXL / RED4ext package payload retired; redscript and shared roots preserved.' -ForegroundColor Green
} catch {
    Add-Report ''
    Add-Report 'RESULT: FAIL-CLOSED'
    Add-Report ('Exception type: ' + $_.Exception.GetType().FullName)
    Add-Report ('Error: ' + $_.Exception.Message)
    Add-Report ('Completed UTC: ' + [DateTime]::UtcNow.ToString('o'))
    throw
} finally {
    Write-Host "REPORT: $([IO.Path]::GetFullPath($ReportPath))"
}
