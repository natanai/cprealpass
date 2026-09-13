$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\tools\Common.ps1"
$project = Get-ProjectRoot
$contract = Get-Content -Raw -LiteralPath (Join-Path $project 'manifest/settings.json') | ConvertFrom-Json
$package = Get-Content -Raw -LiteralPath (Join-Path $project 'manifest/package.json') | ConvertFrom-Json
$policyPath = Join-Path $project 'src/redscript/CyberpunkRealism/RuntimePolicyModel.reds'
$policy = Get-Content -Raw -LiteralPath $policyPath
$retiredSource = Join-Path $project 'src/redscript/CyberpunkRealism/RealpassSettings.reds'
$builder = Get-Content -Raw -LiteralPath (Join-Path $project 'tools/Build-AttendedAcceptance.ps1')
$script:checks = 0
function Check($condition,[string]$message) { if (-not $condition) { throw $message }; $script:checks++ }

Check ($contract.schemaVersion -eq 2) 'Configuration contract is not the locked-release schema.'
Check ($contract.surface.provider -eq 'none') 'A gameplay settings provider is still configured.'
Check ($contract.surface.publicGameplaySettings -eq $false) 'Public gameplay settings are still enabled.'
Check ($contract.surface.publicBalanceSettings -eq $false) 'Public balance settings are still enabled.'
Check (-not (Test-Path -LiteralPath $retiredSource)) 'Retired Mod Settings gameplay surface is still active source.'
Check (-not $policy.Contains('traditionalHealthBarsEnabled')) 'Traditional healthbar preference survived in runtime policy.'
Check ($policy.Contains('public static func TraditionalHealthBars') -and $policy.Contains('return false;')) 'No-healthbar authored release decision is not fixed in policy.'

foreach ($file in @($package.files)) {
    Check ([string]$file.source -ne 'src/redscript/CyberpunkRealism/RealpassSettings.reds') 'Retired settings source remains in package.'
}
foreach ($requirement in @($package.requiredExternalComponents)) {
    Check ([string]$requirement -notmatch '(?i)Mod Settings') 'Mod Settings remains an active source-package prerequisite.'
}

# The attended builder is being migrated to an owned-runtime base. Until that
# migration lands it must not be mistaken for a release path: this test explicitly
# records the required end-state strings and will be tightened with the builder.
Check (-not $contract.releaseProfile.traditionalActorHealthBars) 'Release profile re-enabled traditional actor health bars.'
foreach ($id in @('body','injury','combat','armor','cyberwarePhysiology','presentation')) {
    Check ($contract.releaseProfile.$id -eq $true) "Release authority not locked on: $id"
}
Check ($contract.releaseProfile.diagnostics -eq $false) 'Release diagnostics not locked off.'

Write-Host "PASS: $script:checks locked-configuration runtime checks; no player gameplay settings source or Mod Settings package dependency remains."
