$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\tools\Common.ps1"
$project = Get-ProjectRoot
$path = Join-Path $project 'tools/Build-OwnedAcceptance.ps1'
$source = Get-Content -Raw -LiteralPath $path
$script:checks = 0
function Check($condition,[string]$message) { if (-not $condition) { throw $message }; $script:checks++ }

Check ($source.Contains("'src/redscript/CyberpunkRealism'")) 'Owned builder does not start from the RealPass source tree.'
Check ($source.Contains("Get-ChildItem -LiteralPath `$sourceRoot -File -Filter '*.reds'")) 'Owned builder does not discover the current owned REDscript tree.'
Check ($source.Contains("`$retiredProductionSources = @('FieldCareUI.reds','RealpassLocalization.reds','FieldCareItemUse.reds')")) 'Retired source-mod/prototype sources are not explicitly prohibited from production.'
Check ($source.Contains('Retired legacy/prototype production source reappeared')) 'Owned builder does not fail if retired production source reappears.'
Check ($source.Contains('candidateFiles = @($sourceFiles)')) 'Owned builder is still silently excluding production REDscript instead of compiling the whole current source tree.'
Check (-not $source.Contains("`$excluded = @('FieldCareUI.reds')")) 'Owned builder still treats the obsolete backpack prototype as acceptable production source.'

foreach ($needle in @('DarkFuture','Project\s*E3','Codeware')) {
    Check ($source.Contains($needle)) "Owned builder lost forbidden-runtime guard: $needle"
}
Check ($source.Contains('import\s+ModSettings')) 'Owned builder does not reject direct Mod Settings imports.'
# Register/Unregister listener calls are the one allowed provider lifecycle boundary.
Check ($source.Contains('ModSettings\.(?:GetInstance|GetMods|GetCategories|GetVars|AcceptChanges|RejectChanges|RestoreDefaults)')) 'Owned builder does not reject direct Mod Settings policy/API coupling.'
Check (-not $source.Contains('ModSettings\.(?:Register|Unregister|GetInstance')) 'Owned builder still treats allowed listener lifecycle calls as forbidden policy coupling.'
Check (-not $source.Contains('ModSettings|Mod Settings')) 'Owned builder still blanket-rejects accepted Mod Settings runtime-property metadata.'
Check ($source.Contains('Trauma\s+Kit') -and $source.Contains('UseTraumaKit')) 'Owned builder no longer rejects Dark Future Trauma Kit identity leakage.'
Check ($source.Contains('vanillaIdentityPolicy')) 'Owned acceptance report does not record vanilla-identity policy.'
Check ($source.Contains('retiredProductionSources')) 'Owned acceptance report does not record retired production sources.'
Check ($source.Contains("component = 'realpass-owned-runtime'")) 'Owned manifest does not label project runtime ownership.'
Check ($source.Contains("origin = 'project-original'")) 'Owned manifest does not preserve source provenance.'
Check ($source.Contains('ownedRuntime = $true')) 'Owned manifest/report does not assert the owned-runtime boundary.'
Check ($source.Contains('sourceModsRequired = @()')) 'Owned report no longer records zero source-mod runtime requirements.'
Check ($source.Contains('traditionalActorHealthBarsFinalTarget = $false')) 'Owned report lost the final no-traditional-actor-HP target.'
Check ($source.Contains('developmentHealthbarFallbackUntilReplacementAccepted = $true')) 'Owned report does not record the transitional feedback fallback.'

foreach ($needle in @(
    "Set-PolicyOnce `$text 'CRBodyRuntimePolicy' 'Enabled' `$true 'false'",
    "Set-PolicyOnce `$text 'CRBodyTestPolicy' 'Diagnostics' ([bool]`$Diagnostics) 'false'",
    "Set-PolicyOnce `$text 'CRCombatRuntimePolicy' 'Enabled' `$true 'false'"
)) {
    Check ($source.Contains($needle)) "Owned builder lost immutable staged policy transition: $needle"
}
Check ($source.Contains('Build ID already exists; owned acceptance profiles are immutable')) 'Owned candidate IDs can overwrite evidence.'
Check ($source.Contains('Test-RuntimeOriginPolicy.ps1')) 'Owned builder does not re-run runtime-origin policy before compilation.'
Check ($source.Contains('Compile-Profile.ps1')) 'Owned builder does not exact-compile the generated candidate.'
Check ($source.Contains('Assert-GameStopped')) 'Owned builder no longer requires the game to be stopped for exact compile evidence.'

foreach ($forbidden in @('Upgrade.ps1','Deploy.ps1','Copy-Item -LiteralPath $sourcePath','Start-Process','Register-ScheduledTask','New-Service')) {
    Check (-not $source.Contains($forbidden)) "Owned builder gained a live/unattended side effect: $forbidden"
}
Check ($source.Contains('Nothing was deployed or launched')) 'Owned builder does not make its compile-only boundary explicit.'

Write-Host "PASS: $script:checks owned acceptance-builder contract checks."
