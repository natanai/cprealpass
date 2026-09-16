$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'Run-CI.ps1 requires PowerShell 7 or newer.' }

# Only tests reproducible from the public source tree and relevant to the current
# Biology-owned runtime path belong here. Exact integrated compilation against
# Cyberpunk's proprietary final.redscripts remains a local build gate inside
# Build-BiologyPackage.ps1 rather than a cloud-CI claim.
$tests = @(
    'Test-PowerShellSyntax.ps1',
    'Test-ActiveGuidanceHygiene.ps1',
    'Test-ThreadLedger.ps1',
    'Test-BiologyProductDirection.ps1',
    'Test-ActiveRoadmap.ps1',
    'Test-IntegrationOrchestrator.ps1',
    'Test-LocalOperatorCommands.ps1',
    'Test-OperatorBootstrapHardening.ps1',
    'Test-ModuleContract.ps1',
    'Test-SettingsContract.ps1',
    'Test-SettingsRuntimeSurface.ps1',
    'Test-SelfContainedSettings.ps1',
    'Test-RuntimeOriginPolicy.ps1',
    'Test-NativeSeamPolicy.ps1',
    'Test-ProjectClassAnnotationOwnership.ps1',
    'Test-GameContractAudit.ps1',
    'Test-CleanRoomTestingContract.ps1',
    'Test-RedmodFoundation.ps1',
    'Test-RedmodPostUninstallDeployRecovery.ps1',
    'Test-RedmodActivationSentinelProbe.ps1',
    'Test-InstalledRuntimeActivationProbe.ps1',
    'Test-RedscriptStartupRuntime.ps1',
    'Test-RedmodActivationSentinelContract.ps1',
    'Test-IntegratedBiologyPackage.ps1',
    'Test-PlayerDisableContract.ps1',
    'Test-PlayerUninstaller.ps1',
    'Test-BiologyRemovalVerifier.ps1',
    'Test-LegacyFrameworkTransition.ps1',
    'Test-BiologyShell.ps1',
    'Test-BiologyNativeDrilldown.ps1',
    'Test-BiologyRuntimeLifecycle.ps1',
    'Test-BodyRuntimeAuthority.ps1',
    'Test-ConditionArchitecture.ps1',
    'Test-PainArchitecture.ps1',
    'Test-OwnedNameplates.ps1',
    'Test-E3OwnedPresentation.ps1',
    'Test-DistributionContract.ps1',
    'Test-InstallContract.ps1',
    'Test-FeatureInventory.ps1',
    'Test-AcceptanceLedger.ps1',
    'Test-ActivationGates.ps1',
    'Test-OwnedAcceptanceBuilder.ps1',
    'Test-OwnedSessionTool.ps1',
    'Test-ArtifactPolicy.ps1',
    'Test-PackageMetadata.ps1',
    'Test-RuntimePolicyModel.ps1',
    'Test-NoHealthbars.ps1',
    'Test-PhysicalOutfits.ps1',
    'Test-BodyModel.ps1',
    'Test-BodyInputs.ps1',
    'Test-BodyPresentation.ps1',
    'Test-BodyForecast.ps1',
    'Test-BodyInteractions.ps1',
    'Test-SleepFatigue.ps1',
    'Test-ClockModel.ps1',
    'Test-CombatCore.ps1',
    'Test-BallisticProfiles.ps1',
    'Test-CombatFeelEnvelope.ps1',
    'Test-InjuryBody.ps1',
    'Test-WoundPipeline.ps1',
    'Test-ArmorWear.ps1',
    'Test-FieldCare.ps1',
    'Test-FieldCareTimed.ps1',
    'Test-ProfessionalCare.ps1',
    'Test-PainModel.ps1',
    'Test-BloodLoss.ps1',
    'Test-InjuryEffects.ps1',
    'Test-BarlessFeedbackEnvelope.ps1',
    'Test-NPCProgression.ps1'
)

$project = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$failed = @()
$results = [Collections.Generic.List[object]]::new()
$started = [DateTime]::UtcNow
foreach ($name in $tests) {
    $path = Join-Path $PSScriptRoot $name
    if (-not (Test-Path -LiteralPath $path)) { throw "Missing CI test: $name" }
    Write-Host "`n=== CI: $name ==="
    $testStarted = [DateTime]::UtcNow
    & pwsh -NoLogo -NoProfile -NonInteractive -File $path
    $exitCode = $LASTEXITCODE
    $testElapsed = [DateTime]::UtcNow - $testStarted
    $passed = $exitCode -eq 0
    $results.Add([pscustomobject]@{ test=$name; passed=$passed; exitCode=$exitCode; seconds=[Math]::Round($testElapsed.TotalSeconds,3) })
    if (-not $passed) { $failed += $name; Write-Error "FAILED: $name (exit $exitCode)" -ErrorAction Continue }
}

$elapsed = [DateTime]::UtcNow - $started
$reportRoot = Join-Path $project 'reports'
New-Item -ItemType Directory -Force -Path $reportRoot | Out-Null
$summaryPath = Join-Path $reportRoot 'ci-suite-summary.json'
$summary = [ordered]@{ schemaVersion=1; generatedUtc=[DateTime]::UtcNow.ToString('o'); passed=$failed.Count -eq 0; totalTests=$tests.Count; failedTests=@($failed); elapsedSeconds=[Math]::Round($elapsed.TotalSeconds,3); results=@($results.ToArray()) }
$summary | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $summaryPath -Encoding utf8
Write-Host "CI suite summary: $summaryPath"
if ($failed.Count -gt 0) { throw "CI failed: $($failed -join ', ')" }
Write-Host "`nPASS: $($tests.Count) cloud-safe owned-path Biology checks in $([Math]::Round($elapsed.TotalSeconds,1)) seconds."
