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
$nameplatePath = Join-Path $project 'src/redscript/CyberpunkRealism/NameplatesNative.reds'
$nameplates = Get-Content -Raw -LiteralPath $nameplatePath
$bodyHooks = Get-Content -Raw -LiteralPath (Join-Path $project 'src/redscript/CyberpunkRealism/BodyNativeHooks.reds')
$combat = Get-Content -Raw -LiteralPath (Join-Path $project 'src/redscript/CyberpunkRealism/CombatNativeBridge.reds')
$outfits = Get-Content -Raw -LiteralPath (Join-Path $project 'src/redscript/CyberpunkRealism/PhysicalOutfits.reds')
$biology = Get-Content -Raw -LiteralPath (Join-Path $project 'src/redscript/CyberpunkRealism/BiologyCyberwareShell.reds')
$health = Get-Content -Raw -LiteralPath (Join-Path $project 'src/redscript/CyberpunkRealism/NoHealthbars.reds')
$profileBuilder = Get-Content -Raw -LiteralPath (Join-Path $project 'tools/Build-OwnedRuntimeProfile.ps1')
$profiles = Get-Content -Raw -LiteralPath (Join-Path $project 'manifest/profiles.json') | ConvertFrom-Json
$script:checks = 0
function Check($condition,[string]$message) { if (-not $condition) { throw $message }; $script:checks++ }

Check ($contract.schemaVersion -eq 4) 'Configuration contract is not the current master-plus-presentation schema.'
Check ($contract.surface.provider -eq 'mod-settings') 'RealPass is not configured to identify itself in Mod Settings.'
Check ($contract.surface.publicGameplaySettings -eq $false) 'Per-authority public gameplay settings are enabled.'
Check ($contract.surface.publicBalanceSettings -eq $false) 'Public balance settings are enabled.'
Check ($contract.surface.publicMasterEnable -eq $true) 'Global RealPass master enable is missing.'
Check ($contract.surface.publicPresentationPreferences -eq $true) 'Accepted binary presentation preference is not represented.'
Check (Test-Path -LiteralPath $surfacePath) 'RealPass Mod Settings runtime-property surface is missing.'

Check ($surface.Contains('@runtimeProperty("ModSettings.mod", "RealPass")')) 'RealPass settings metadata does not register a visible mod.'
Check ($surface.Contains('public class CRRealpassSettings extends ScriptableSystem')) 'RealPass settings are not hosted by a ScriptableSystem singleton.'
Check ($surface.Contains('enabled: Bool = true;')) 'Global RealPass master setting is missing or does not default on.'
Check ($surface.Contains('e3FirstPersonHudVisuals: Bool = true;')) 'E3 first-person HUD setting is missing or does not default on.'
Check ($surface.Contains('ModSettings.RegisterListenerToClass(this)')) 'RealPass settings are not registered for live Mod Settings updates.'
Check ($surface.Contains('ModSettings.UnregisterListenerToClass(this)')) 'RealPass settings do not unregister cleanly.'
Check ($surface.Contains('@if(ModuleExists("ModSettingsModule"))')) 'Mod Settings listener calls are not guarded by provider availability.'
Check (-not ($surface -match '(?m)^\s*import\s+ModSettings')) 'RealPass settings source imports provider internals directly.'
Check (-not ($surface -match '(?m)(?<!["''])\bModSettings\.(?:GetInstance|GetMods|GetCategories|GetVars|AcceptChanges|RejectChanges|RestoreDefaults)\b')) 'RealPass settings source directly couples policy to Mod Settings internals.'
Check (-not ($surface -match '(?m)public\s+let\s+\w+\s*:\s*(?:Float|Int32|Uint32)\b')) 'Numeric settings leaked into the public surface.'
$boolFields = @([regex]::Matches($surface,'(?m)public\s+let\s+(?<name>\w+)\s*:\s*Bool\b') | ForEach-Object { $_.Groups['name'].Value })
Check ($boolFields.Count -eq 2 -and $boolFields -contains 'enabled' -and $boolFields -contains 'e3FirstPersonHudVisuals') 'RealPass settings surface is not exactly the master switch plus E3 presentation toggle.'

Check (-not $policy.Contains('traditionalHealthBarsEnabled')) 'Traditional healthbar player preference survived in runtime policy.'
Check ($policy.Contains('public static func TraditionalHealthBars') -and $policy.Contains('return false;')) 'Final no-healthbar authored release decision is not fixed in policy.'

# Analgesic-overuse presentation is authored behavior, not a separate player setting.
Check (-not $pain.Contains('CRRealpassSettings')) 'Pain presentation became independently configurable instead of following the global runtime/body gate.'
Check ($pain.Contains('CRPainNativeEffects.SyncIntoxication(player, pain.intoxication)')) 'Authored analgesic-overuse presentation call is missing.'
Check ($pain.Contains('player.crPainModifiers.Sync(player, pain)')) 'Pain-derived weapon handling was accidentally removed.'

# Both public settings must be consumed by owned seams.
Check ($nameplates.Contains('CRRealpassSettings.UseE3FirstPersonHudVisuals(puppet.GetGame())')) 'E3 presentation preference is not consumed by the owned nameplate seam.'
Check ($bodyHooks.Contains('CRRealpassSettings.IsEnabled(GetGameInstance())')) 'Global master switch is not consumed by body native hooks.'
Check ($combat.Contains('CRRealpassSettings.IsEnabled(GetGameInstance())')) 'Global master switch is not consumed by combat runtime policy.'
Check ($outfits.Contains('CRRealpassSettings.IsEnabled(GetGameInstance())')) 'Global master switch is not consumed by physical Outfits.'
Check ($biology.Contains('CRRealpassSettings.IsEnabled(GetGameInstance())')) 'Global master switch is not consumed by Biology shell presentation.'
Check ($health.Contains('CRRealpassSettings.IsEnabled(GetGameInstance())')) 'Global master switch is not consumed by healthbar presentation.'
Check ($health.Contains('PlayerHealthReplacementAccepted') -and $health.Contains('return true;')) 'Attended player-health suppression acceptance is not recorded in runtime source.'

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
    Check ($contract.releaseProfile.$id -eq $true) "Release authority not locked on while RealPass is enabled: $id"
}
Check ($contract.releaseProfile.diagnostics -eq $false) 'Release diagnostics not locked off.'
Check ($contract.releaseProfile.traditionalActorHealthBarsFinalTarget -eq $false) 'Final release target re-enabled traditional actor health bars.'
Check ($contract.releaseProfile.e3InspiredFirstPersonHud -eq $true -and $contract.releaseProfile.e3InspiredNpcNameplates -eq $true) 'E3-inspired authored presentation target is not locked on.'
Check ($contract.developmentFeedbackFallback.traditionalPlayerHealthBarsVisibleUntilReplacementAccepted -eq $false) 'Old player healthbar fallback was re-enabled after attended rejection.'

Write-Host "PASS: $script:checks Mod Settings/runtime checks; public controls are the global RealPass master switch and E3 HUD/nameplate presentation toggle, with no subsystem/balance tuning."
