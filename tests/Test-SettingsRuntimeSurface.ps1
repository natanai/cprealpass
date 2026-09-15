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
$e3Hud = Get-Content -Raw -LiteralPath (Join-Path $project 'src/redscript/CyberpunkRealism/E3FirstPersonHud.reds')
$e3Nameplates = Get-Content -Raw -LiteralPath (Join-Path $project 'src/redscript/CyberpunkRealism/E3NameplatesNative.reds')
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
Check ($contract.playerFacingProduct -eq 'Biology') 'Player-facing settings contract is not branded Biology.'
Check ($contract.surface.semanticOwner -eq 'biology') 'Settings semantics are not explicitly Biology-owned.'
Check ($contract.surface.providerRole -eq 'optional-ui-and-persistence-adapter') 'Settings provider is being treated as semantic architecture rather than an adapter.'
Check ($contract.surface.provider -eq 'mod-settings') 'Current settings adapter is not recorded accurately.'
Check ($contract.surface.publicGameplaySettings -eq $false) 'Per-authority public gameplay settings are enabled.'
Check ($contract.surface.publicBalanceSettings -eq $false) 'Public balance settings are enabled.'
Check ($contract.surface.publicMasterEnable -eq $true) 'Global Biology master enable is missing.'
Check ($contract.surface.publicPresentationPreferences -eq $true) 'Accepted binary presentation preference is not represented.'
Check (Test-Path -LiteralPath $surfacePath) 'Biology settings runtime-property surface is missing.'

Check ($surface.Contains('@runtimeProperty("ModSettings.mod", "Biology")')) 'Player-facing settings metadata does not register Biology.'
Check ($surface.Contains('@runtimeProperty("ModSettings.displayName", "Enable Biology")')) 'Global master is not labeled Enable Biology.'
Check ($surface.Contains('@runtimeProperty("ModSettings.displayName", "E3-inspired HUD + nameplates")')) 'Presentation preference does not describe its player-facing outcome.'
Check (-not $surface.Contains('@runtimeProperty("ModSettings.mod", "RealPass")')) 'Obsolete RealPass product branding remains player-facing.'
Check (-not $surface.Contains('@runtimeProperty("ModSettings.displayName", "Enable RealPass")')) 'Obsolete Enable RealPass label remains player-facing.'
Check ($surface.Contains('public class CRRealpassSettings extends ScriptableSystem')) 'Compatibility settings class is not hosted by a ScriptableSystem singleton.'
Check ($surface.Contains('enabled: Bool = true;')) 'Global Biology master setting is missing or does not default on.'
Check ($surface.Contains('e3FirstPersonHudVisuals: Bool = true;')) 'E3 presentation setting is missing or does not default on.'
Check ($surface.Contains('ModSettings.RegisterListenerToClass(this)')) 'Settings are not registered for live adapter updates.'
Check ($surface.Contains('ModSettings.UnregisterListenerToClass(this)')) 'Settings adapter does not unregister cleanly.'
Check ($surface.Contains('@if(ModuleExists("ModSettingsModule"))')) 'Provider listener calls are not guarded by provider availability.'
Check (-not ($surface -match '(?m)^\s*import\s+ModSettings')) 'Settings source imports provider internals directly.'
Check (-not ($surface -match '(?m)(?<!["''])\bModSettings\.(?:GetInstance|GetMods|GetCategories|GetVars|AcceptChanges|RejectChanges|RestoreDefaults)\b')) 'Settings source directly couples semantics to Mod Settings internals.'
Check (-not ($surface -match '(?m)public\s+let\s+\w+\s*:\s*(?:Float|Int32|Uint32)\b')) 'Numeric settings leaked into the public surface.'
$boolFields = @([regex]::Matches($surface,'(?m)public\s+let\s+(?<name>\w+)\s*:\s*Bool\b') | ForEach-Object { $_.Groups['name'].Value })
Check ($boolFields.Count -eq 2 -and $boolFields -contains 'enabled' -and $boolFields -contains 'e3FirstPersonHudVisuals') 'Settings surface is not exactly the master switch plus E3 presentation toggle.'

Check (-not $policy.Contains('traditionalHealthBarsEnabled')) 'Traditional healthbar player preference survived in runtime policy.'
Check ($policy.Contains('public static func TraditionalHealthBars') -and $policy.Contains('return false;')) 'Final no-healthbar authored release decision is not fixed in policy.'

# Analgesic-overuse presentation is authored behavior, not a separate player setting.
Check (-not $pain.Contains('CRRealpassSettings')) 'Pain presentation became independently configurable instead of following the global runtime/body gate.'
Check ($pain.Contains('CRPainNativeEffects.SyncIntoxication(player, pain.intoxication)')) 'Authored analgesic-overuse presentation call is missing.'
Check ($pain.Contains('player.crPainModifiers.Sync(player, pain)')) 'Pain-derived weapon handling was accidentally removed.'

# Both public settings must be consumed by Biology-owned semantics. The E3 preference
# drives the actual visual slices; the name-data enrichment seam may also consult it.
Check ($e3Hud.Contains('CRRealpassSettings.UseE3FirstPersonHudVisuals(GetGameInstance())')) 'E3 preference is not consumed by the first-person HUD slice.'
Check ($e3Nameplates.Contains('CRRealpassSettings.UseE3FirstPersonHudVisuals(puppet.GetGame())')) 'E3 preference is not consumed by the NPC nameplate slice.'
Check ($nameplates.Contains('CRRealpassSettings.UseE3FirstPersonHudVisuals(puppet.GetGame())')) 'Scanned-civilian name enrichment lost the accepted presentation gate.'
Check (-not $health.Contains('UseE3FirstPersonHudVisuals')) 'E3 preference incorrectly owns Biology-wide health-bar suppression.'
Check ($bodyHooks.Contains('CRRealpassSettings.IsEnabled(GetGameInstance())')) 'Global master switch is not consumed by body native hooks.'
Check ($combat.Contains('CRRealpassSettings.IsEnabled(GetGameInstance())')) 'Global master switch is not consumed by combat runtime policy.'
Check ($outfits.Contains('CRRealpassSettings.IsEnabled(GetGameInstance())')) 'Global master switch is not consumed by physical Outfits.'
Check ($biology.Contains('CRRealpassSettings.IsEnabled(GetGameInstance())')) 'Global master switch is not consumed by Biology shell presentation.'
Check ($health.Contains('CRRealpassSettings.IsEnabled(GetGameInstance())')) 'Global master switch is not consumed by healthbar presentation.'
Check ($health.Contains('PlayerHealthReplacementAccepted') -and $health.Contains('return true;')) 'Attended player-health suppression acceptance is not recorded in runtime source.'

$ownedProfile = @($profiles.profiles.'m1-owned-settings')
foreach ($component in @('red4ext','redscript','archivexl','mod-settings')) {
    Check ($ownedProfile -contains $component) "Owned settings profile missing required current adapter component: $component"
}
foreach ($component in @('darkfuture','project-e3-hud','input-loader')) {
    Check ($ownedProfile -notcontains $component) "Owned settings profile contains forbidden source/reference runtime: $component"
}
Check ($profileBuilder.Contains("`$genericIds = @('red4ext','redscript','archivexl','mod-settings')")) 'Owned runtime builder is not using the constrained current settings plumbing profile.'
Check ($profileBuilder.Contains("-Profile 'm1-owned-settings'")) 'Owned runtime builder does not stage the narrow current settings profile.'
Check ($profileBuilder.Contains("settingsProvider = 'mod-settings'")) 'Owned runtime report does not identify the current settings adapter.'

foreach ($id in @('body','injury','combat','armor','cyberwarePhysiology','presentation')) {
    Check ($contract.releaseProfile.$id -eq $true) "Release authority not locked on while Biology is enabled: $id"
}
Check ($contract.releaseProfile.diagnostics -eq $false) 'Release diagnostics not locked off.'
Check ($contract.releaseProfile.traditionalActorHealthBarsFinalTarget -eq $false) 'Final release target re-enabled traditional actor health bars.'
Check ($contract.releaseProfile.e3InspiredFirstPersonHud -eq $true -and $contract.releaseProfile.e3InspiredNpcNameplates -eq $true) 'E3-inspired authored presentation target is not locked on.'
Check ($contract.releaseProfile.nativeModernScanner -eq $true) 'Native modern scanner target is not locked on.'
Check ($contract.developmentFeedbackFallback.traditionalPlayerHealthBarsVisibleUntilReplacementAccepted -eq $false) 'Old player healthbar fallback was re-enabled after attended rejection.'

Write-Host "PASS: $script:checks Biology settings/runtime checks; visible branding is Biology, semantic accessors are provider-neutral, and the E3 toggle owns only the HUD/nameplate skin."
