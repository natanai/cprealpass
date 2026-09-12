$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'Run-CI.ps1 requires PowerShell 7 or newer.' }

$tests = @(
    'Test-ModuleContract.ps1',
    'Test-DistributionContract.ps1',
    'Test-BodyModel.ps1',
    'Test-ClockModel.ps1',
    'Test-CombatCore.ps1',
    'Test-BallisticProfiles.ps1',
    'Test-InjuryBody.ps1',
    'Test-WoundPipeline.ps1',
    'Test-ArmorWear.ps1',
    'Test-FieldCare.ps1',
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
