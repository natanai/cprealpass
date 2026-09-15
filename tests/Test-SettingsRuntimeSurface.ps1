$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\tools\Common.ps1"
$project = Get-ProjectRoot
$contract = Get-Content -Raw -LiteralPath (Join-Path $project 'manifest/settings.json') | ConvertFrom-Json
$surfacePath = Join-Path $project 'src/redscript/CyberpunkRealism/RealpassSettings.reds'
$surface = Get-Content -Raw -LiteralPath $surfacePath
$policyPath = Join-Path $project 'src/redscript/CyberpunkRealism/RuntimePolicyModel.reds'
$policy = Get-Content -Raw -LiteralPath $policyPath
$painPath = Join-Path $project 'src/redscript/CyberpunkRealism/PainNativeEffects.reds'
$pain = Get-Content -Raw -LiteralPath $painPath
$profileBuilder = Get-Content -Raw -LiteralPath (Join-Path $project 'tools/Build-OwnedRuntimeProfile.ps1')
$profiles = Get-Content -Raw -LiteralPath (Join-Path $project 'manifest/profiles.json') | ConvertFrom-Json
$script:checks = 0
function Check($condition,[string]$message) { if (-not $condition) { throw $message }; $script:checks++ }

Check ($contract.schemaVersion -eq 3) 'Configuration contract is not the current constrained-public-surface schema.'
Check ($contract.surface.provider -eq 'mod-settings') 'RealPass is not configured to identify itself in Mod Settings.'
Check ($contract.surface.publicGameplaySettings -eq $false) 'Public gameplay settings are enabled.'
Check ($contract.surface.publicBalanceSettings -eq $false) 'Public balance settings are enabled.'
Check ($contract.surface.publicPresentationPreferences -eq $true) 'Accepted binary presentation preferences are not represented.'
Check ($contract.surface.purpose -eq 'binary presentation/accessibility preferences only') 'Mod Settings still claims ownership of a descriptive feature ledger.'
Check (Test-Path -LiteralPath $surfacePath) 'RealPass Mod Settings runtime-property surface is missing.'

# Live acceptance showed the previous custom one-value enum ledger was not discovered
# by Mod Settings. Keep the provider declaration conventional: a plain Bool field with
# standard mod/category/display metadata. Simulation status lives in manifests/Biology.
Check ($surface.Contains('@runtimeProperty("ModSettings.mod", "RealPass")')) 'RealPass settings metadata does not register a visible mod.'
Check ($surface.Contains('@runtimeProperty("ModSettings.category", "Presentation")')) 'RealPass settings page lacks its conventional presentation category.'
Check ($surface.Contains('fullscreenDisorientationEffects: Bool = true;')) 'Accepted binary presentation preference is missing.'
Check (-not $surface.Contains('CRRealpassManagedState')) 'Undiscoverable one-value managed-state enum ledger returned to Mod Settings.'
Check (-not ($surface -match '(?m)public\s+let\s+\w+\s*:\s*(?:Float|Int32|Uint32)\b')) 'Numeric settings leaked into the public surface.'
Check (-not ($surface -match '(?m)^\s*import\s+ModSettings')) 'RealPass settings surface directly imports the provider API.'
Check (-not ($surface -match '(?m)(?<!["''])\bModSettings\.(?:Register|Unregister|GetInstance|GetVars|AcceptChanges|RejectChanges)\b')) 'RealPass settings surface directly couples simulation to provider methods.'

Check (-not $policy.Contains('traditionalHealthBarsEnabled')) 'Traditional healthbar player preference survived in runtime policy.'
Check ($policy.Contains('public static func TraditionalHealthBars') -and $policy.Contains('return false;')) 'Final no-healthbar authored release decision is not fixed in policy.'

# The public boolean gates only native disorientation presentation; pain/weapon
# modifiers continue regardless of that preference.
Check ($pain.Contains('CRRealpassSettings.ShowFullscreenDisorientationEffects()')) 'Fullscreen disorientation preference is not consumed by its presentation seam.'
Check ($pain.Contains('player.crPainModifiers.Sync(player, pain)')) 'Pain-derived weapon handling was accidentally placed behind the preference.'

$ownedProfile = @($profiles.profiles.'m1-owned-settings')
foreach ($component in @('red4ext','redscript','archivexl','mod-settings')) {
    Check ($ownedProfile -contains $component) "Owned settings profile missing required generic component: $component"
}
foreach ($component in @('darkfuture','project-e3-hud','input-loader')) {
    Check ($ownedProfile -notcontains $component) "Owned settings profile contains forbidden source/reference runtime: $component"
}
Check ($profileBuilder.Contains("`$genericIds = @('red4ext','redscript','archivexl','mod-settings')")) 'Owned runtime builder is not using the constrained settings plumbing profile.'
Check ($profileBuilder.Contains("-Profile 'm1-owned-settings'")) 'Owned runtime builder does not stage the narrow settings profile.'
Check ($profileBuilder.Contains("settingsProvider = 'mod-settings'")) 'Owned runtime report does not identify the accepted settings provider.'

foreach ($id in @('body','injury','combat','armor','cyberwarePhysiology','presentation')) {
    Check ($contract.releaseProfile.$id -eq $true) "Release authority not locked on: $id"
}
Check ($contract.releaseProfile.diagnostics -eq $false) 'Release diagnostics not locked off.'
Check ($contract.releaseProfile.traditionalActorHealthBarsFinalTarget -eq $false) 'Final release target re-enabled traditional actor health bars.'
Check ($contract.developmentFeedbackFallback.traditionalPlayerHealthBarsVisibleUntilReplacementAccepted -eq $true) 'Transitional player feedback fallback is not explicit.'

Write-Host "PASS: $script:checks conventional Mod Settings discovery checks; RealPass exposes presentation-only booleans and never simulation policy."
