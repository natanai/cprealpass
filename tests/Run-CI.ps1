$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'Run-CI.ps1 requires PowerShell 7 or newer.' }

# Only tests reproducible from the public source tree belong here. Tests that
# intentionally exercise acquired third-party source, generated deployment
# manifests, the installed game, or live deployment state remain local-only.
$tests = @(
    'Test-ModuleContract.ps1',
    'Test-SettingsContract.ps1',
    'Test-DistributionContract.ps1',
    'Test-InstallContract.ps1',
    'Test-FeatureInventory.ps1',
    'Test-AcceptanceLedger.ps1',
    'Test-ActivationGates.ps1',
    'Test-AttendedBuilder.ps1',
    'Test-ArtifactPolicy.ps1',
    'Test-PlayerPackageFinalizer.ps1',
    'Test-PackageMetadata.ps1',
    'Test-RuntimePolicyModel.ps1',
    'Test-NoHealthbars.ps1',
    'Test-BodyModel.ps1',
    'Test-BodyInputs.ps1',
    'Test-BodyPresentation.ps1',
    'Test-BodyForecast.ps1',
    'Test-BodyInteractions.ps1',
    'Test-SleepFatigue.ps1',
    'Test-ClockModel.ps1',
    'Test-CombatCore.ps1',
    'Test-BallisticProfiles.ps1',
    'Test-InjuryBody.ps1',
    'Test-WoundPipeline.ps1',
    'Test-ArmorWear.ps1',
    'Test-FieldCare.ps1',
    'Test-FieldCareTimed.ps1',
    'Test-FieldCareUI.ps1',
    'Test-BloodLoss.ps1',
    'Test-InjuryEffects.ps1',
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
Write-Host "`nPASS: $($tests.Count) cloud-safe realpass checks in $([Math]::Round($elapsed.TotalSeconds,1)) seconds."
