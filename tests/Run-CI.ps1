$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'Run-CI.ps1 requires PowerShell 7 or newer.' }

# Only tests reproducible from the public source tree and relevant to the current
# vanilla-first, project-owned runtime path belong here. Exact integrated compilation
# against Cyberpunk's proprietary final.redscripts remains a local build gate inside
# Build-BiologyPackage.ps1 rather than a cloud-CI claim.
$tests = @(
    'Test-PowerShellSyntax.ps1',
    'Test-BiologyProductDirection.ps1',
    'Test-ActiveRoadmap.ps1',
    'Test-IntegrationOrchestrator.ps1',
    'Test-ModuleContract.ps1',
    'Test-SettingsContract.ps1',
    'Test-SettingsRuntimeSurface.ps1',
    'Test-RuntimeOriginPolicy.ps1',
    'Test-NativeSeamPolicy.ps1',
    'Test-GameContractAudit.ps1',
    'Test-CleanRoomTestingContract.ps1',
    'Test-RedmodFoundation.ps1',
    'Test-IntegratedBiologyPackage.ps1',
    'Test-BiologyShell.ps1',
    'Test-BiologyRuntimeLifecycle.ps1',
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
    'Test-PlayerPackageFinalizer.ps1',
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

$failed = @()
$started = [DateTime]::UtcNow
foreach ($name in $tests) {
    $path = Join-Path $PSScriptRoot $name
    if (-not (Test-Path -LiteralPath $path)) { throw "Missing CI test: $name" }
    Write-Host "`n=== CI: $name ==="
    & pwsh -NoLogo -NoProfile -NonInteractive -File $path
    if ($LASTEXITCODE -ne 0) {
        $failed += $name
        Write-Error "FAILED: $name (exit $LASTEXITCODE)" -ErrorAction Continue
    }
}

$elapsed = [DateTime]::UtcNow - $started
if ($failed.Count -gt 0) {
    throw "CI failed: $($failed -join ', ')"
}
Write-Host "`nPASS: $($tests.Count) cloud-safe owned-path Biology checks in $([Math]::Round($elapsed.TotalSeconds,1)) seconds."
