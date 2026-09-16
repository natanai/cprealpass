$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\tools\Common.ps1"
$project = Get-ProjectRoot
$contract = Get-Content -Raw -LiteralPath (Join-Path $project 'manifest/settings.json') | ConvertFrom-Json
$surfacePath = Join-Path $project 'src/redscript/CyberpunkRealism/RealpassSettings.reds'
$surface = Get-Content -Raw -LiteralPath $surfacePath
$preferenceUi = Get-Content -Raw -LiteralPath (Join-Path $project 'src/redscript/CyberpunkRealism/BiologyPreferencesNative.reds')
$policy = Get-Content -Raw -LiteralPath (Join-Path $project 'src/redscript/CyberpunkRealism/RuntimePolicyModel.reds')
$pain = Get-Content -Raw -LiteralPath (Join-Path $project 'src/redscript/CyberpunkRealism/PainNativeEffects.reds')
$nameplates = Get-Content -Raw -LiteralPath (Join-Path $project 'src/redscript/CyberpunkRealism/NameplatesNative.reds')
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

Check ($contract.schemaVersion -eq 5) 'Configuration contract is not the self-contained settings schema.'
Check ($contract.playerFacingProduct -eq 'Biology') 'Player-facing settings contract is not Biology.'
Check ($contract.surface.semanticOwner -eq 'biology') 'Settings semantics are not Biology-owned.'
Check ($contract.surface.provider -eq 'biology-owned-body-shell') 'External settings provider returned.'
Check ($contract.surface.persistenceOwner -eq 'cyberpunk-save-scriptable-system') 'E3 preference is not save-backed.'
Check ($contract.surface.publicMasterEnable -eq $false) 'Redundant in-game master switch returned.'
Check ($contract.surface.publicPresentationPreferences -eq $true) 'Accepted binary presentation preference is missing.'

Check ($surface.Contains('public persistent let e3FirstPersonHudVisuals: Bool = true;')) 'E3 presentation preference is not a persistent ScriptableSystem field.'
Check ($surface.Contains('public static func IsLauncherActivated() -> Bool')) 'Biology settings lost the REDlauncher activation boundary.'
Check ($surface.Contains('Items.BiologyLauncherActivationMarker.stackable')) 'Biology settings do not consume the REDmod-owned activation marker.'
Check ($surface.Contains('return CRRealpassSettings.IsLauncherActivated();')) 'Persisted preference can influence whole-mod activation.'
Check ($surface.Contains('CRRealpassSettings.IsEnabled(game)') -and $surface.Contains('settings.e3FirstPersonHudVisuals')) 'E3 preference is not subordinate to launcher activation.'
Check ($surface.Contains('settings.e3FirstPersonHudVisuals = enabled;')) 'Replacement persistence authority is not written by the setter.'
Check (-not ($surface -match '(?i)ModSettings|mod_settings|runtimeProperty|ModuleExists')) 'External settings-provider residue remains in production settings source.'
Check (-not ($surface -match '(?m)public\s+(?:persistent\s+)?let\s+\w+\s*:\s*(?:Float|Int32|Uint32)\b')) 'Numeric settings leaked into the public surface.'
$boolFields = @([regex]::Matches($surface,'(?m)public\s+persistent\s+let\s+(?<name>\w+)\s*:\s*Bool\b') | ForEach-Object { $_.Groups['name'].Value })
Check ($boolFields.Count -eq 1 -and $boolFields[0] -eq 'e3FirstPersonHudVisuals') 'Settings surface is not exactly one persistent E3 Boolean.'

Check ($preferenceUi.Contains('@addField(RipperDocGameController)')) 'E3 preference editor is not mounted in Biology/Cyberware shell ownership.'
Check ($preferenceUi.Contains('CRRealpassSettings.ToggleE3FirstPersonHudVisuals')) 'Biology-owned UI does not mutate the E3 preference.'
Check ($preferenceUi.Contains('OnCRBiologyE3PreferenceToggle')) 'Biology-owned E3 editor lacks an interaction callback.'
Check (-not ($preferenceUi -match '(?i)ModSettings|mod_settings|SettingsMainGameController')) 'Biology preference editor registers a stale provider/pause-menu row.'

Check (-not $policy.Contains('traditionalHealthBarsEnabled')) 'Traditional healthbar player preference survived in runtime policy.'
Check ($policy.Contains('public static func TraditionalHealthBars') -and $policy.Contains('return false;')) 'Final no-healthbar authored release decision is not fixed in policy.'
Check (-not $pain.Contains('CRRealpassSettings')) 'Pain presentation became independently configurable instead of following global runtime/body activation.'
Check ($pain.Contains('CRPainNativeEffects.SyncIntoxication(player, pain.intoxication)')) 'Authored analgesic-overuse presentation call is missing.'
Check ($pain.Contains('player.crPainModifiers.Sync(player, pain)')) 'Pain-derived weapon handling was accidentally removed.'
Check ($e3Hud.Contains('CRRealpassSettings.UseE3FirstPersonHudVisuals(GetGameInstance())')) 'E3 preference is not consumed by first-person HUD slice.'
Check ($e3Nameplates.Contains('CRRealpassSettings.UseE3FirstPersonHudVisuals(puppet.GetGame())')) 'E3 preference is not consumed by NPC nameplate slice.'
Check ($nameplates.Contains('CRRealpassSettings.UseE3FirstPersonHudVisuals(puppet.GetGame())')) 'Scanned-civilian name enrichment lost the presentation gate.'
Check (-not $health.Contains('UseE3FirstPersonHudVisuals')) 'E3 preference incorrectly owns Biology-wide health-bar suppression.'
foreach ($entry in @($bodyHooks,$combat,$outfits,$biology,$health)) { Check ($entry -match 'CRRealpassSettings\.IsEnabled\(') 'A Biology runtime consumer lost the shared launcher-activation accessor.' }
Check ($health.Contains('PlayerHealthReplacementAccepted') -and $health.Contains('return true;')) 'Attended player-health suppression acceptance is not recorded in runtime source.'

$runtimeProfile = @($profiles.profiles.'biology-runtime')
Check ($runtimeProfile.Count -eq 1 -and $runtimeProfile[0] -eq 'redscript') 'Production runtime staging profile is not redscript-only.'
foreach ($component in @('red4ext','archivexl','mod-settings','darkfuture','project-e3-hud','input-loader')) {
    Check ($runtimeProfile -notcontains $component) "Production runtime profile contains retired/forbidden component: $component"
}
Check ($profileBuilder.Contains("`$genericIds = @('redscript')")) 'Owned runtime builder is not constrained to redscript.'
Check ($profileBuilder.Contains("-Profile 'biology-runtime'")) 'Owned runtime builder does not stage the self-contained Biology profile.'
Check ($profileBuilder.Contains("settingsProvider = 'biology-owned-save-state'")) 'Owned runtime report does not identify Biology-owned save persistence.'

foreach ($id in @('body','injury','combat','armor','cyberwarePhysiology','presentation')) { Check ($contract.releaseProfile.$id -eq $true) "Release authority not locked on while Biology is enabled: $id" }
Check ($contract.releaseProfile.diagnostics -eq $false) 'Release diagnostics not locked off.'
Check ($contract.releaseProfile.traditionalActorHealthBarsFinalTarget -eq $false) 'Final release target re-enabled traditional actor health bars.'
Check ($contract.releaseProfile.e3InspiredFirstPersonHud -eq $true -and $contract.releaseProfile.e3InspiredNpcNameplates -eq $true) 'E3-inspired authored presentation target is not locked on.'
Check ($contract.releaseProfile.nativeModernScanner -eq $true) 'Native modern scanner target is not locked on.'

Write-Host "PASS: $script:checks Biology settings/runtime checks; REDlauncher owns activation, one save-persistent E3 preference is Biology-owned, and the production generic runtime is redscript-only."
