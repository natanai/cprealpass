$ErrorActionPreference = 'Stop'
$project = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$settingsPath = Join-Path $project 'manifest/settings.json'
$modulesPath = Join-Path $project 'manifest/runtime-modules.json'
$surfacePath = Join-Path $project 'src/redscript/CyberpunkRealism/RealpassSettings.reds'
$uiPath = Join-Path $project 'src/redscript/CyberpunkRealism/BiologyPreferencesNative.reds'
$settings = Get-Content -Raw -LiteralPath $settingsPath | ConvertFrom-Json
$modules = Get-Content -Raw -LiteralPath $modulesPath | ConvertFrom-Json
$surface = Get-Content -Raw -LiteralPath $surfacePath
$ui = Get-Content -Raw -LiteralPath $uiPath

if ($settings.schemaVersion -ne 5 -or $settings.product -ne 'realpass') { throw 'Unexpected configuration contract.' }
if ($settings.playerFacingProduct -ne 'Biology') { throw 'Player-facing product identity must be Biology.' }
if ($settings.surface.semanticOwner -ne 'biology') { throw 'Settings semantics must be Biology-owned.' }
if ($settings.surface.provider -ne 'biology-owned-body-shell' -or $settings.surface.providerRole -ne 'self-contained-preference-editor') { throw 'Biology settings are not self-contained.' }
if ($settings.surface.persistenceOwner -ne 'cyberpunk-save-scriptable-system' -or $settings.surface.persistenceScope -ne 'per-save') { throw 'E3 preference persistence authority is not save-backed Biology state.' }
if ($settings.surface.activationOwner -ne 'redlauncher-redmod-sentinel') { throw 'Whole-mod activation authority drifted from REDlauncher/REDmod.' }
if ($settings.surface.publicGameplaySettings -ne $false -or $settings.surface.publicBalanceSettings -ne $false) { throw 'Release must not expose gameplay/balance settings.' }
if ($settings.surface.publicMasterEnable -ne $false) { throw 'Redundant in-game Biology master switch returned.' }
if ($settings.surface.publicPresentationPreferences -ne $true) { throw 'Constrained presentation preference is missing.' }
if ($settings.numericPublicBalanceControlsAllowed -ne $false) { throw 'Numeric public balance controls must remain forbidden.' }

$moduleById = @{}
foreach ($module in @($modules.modules)) { $moduleById[$module.id] = $module }
$release = $settings.releaseProfile
foreach ($id in @('body','injury','combat','armor','cyberwarePhysiology','presentation')) {
    if (-not $moduleById.ContainsKey($id)) { throw "Release authority missing from module contract: $id" }
    if ($release.$id -ne $true) { throw "Release profile does not lock authority on: $id" }
    if ($moduleById[$id].playerFacingToggle -ne $false) { throw "Individual release authority is still player-toggleable: $id" }
}
if ($release.diagnostics -ne $false) { throw 'Release diagnostics must be off.' }
if ($release.traditionalActorHealthBarsFinalTarget -ne $false) { throw 'Final target must still remove traditional actor health bars.' }
if ($release.nativeModernScanner -ne $true) { throw 'Native modern scanner must remain on.' }
if ($release.e3InspiredFirstPersonHud -ne $true -or $release.e3InspiredNpcNameplates -ne $true) { throw 'E3 presentation target drifted.' }

$fallback = $settings.developmentFeedbackFallback
if ($fallback.traditionalPlayerHealthBarsVisibleUntilReplacementAccepted -ne $false -or $fallback.traditionalNpcHealthBarsVisibleUntilReplacementAccepted -ne $false) { throw 'Attended barless acceptance regressed.' }
if ($fallback.rule -notmatch 'E3 preference does not own health-bar suppression') { throw 'E3 preference incorrectly owns health-bar policy.' }

if (@($settings.featureLedger).Count -ne 0) { throw 'Biology settings should not contain a fake feature ledger.' }
$controls = @($settings.publicControls)
if ($controls.Count -ne 1) { throw "Expected exactly one public Biology preference, found $($controls.Count)." }
$e3 = @($controls | Where-Object id -eq 'presentation.e3-first-person-hud-visuals')
if ($e3.Count -ne 1 -or $e3[0].type -ne 'bool' -or $e3[0].default -ne $true -or $e3[0].authority -ne 'presentation-only') { throw 'E3 HUD/nameplate presentation preference contract is invalid.' }
if ($e3[0].displayName -ne 'E3-inspired HUD + nameplates') { throw 'E3 preference label drifted.' }
if ($e3[0].description -notmatch 'barless-health policy' -or $e3[0].description -notmatch 'scanner/quickhack') { throw 'E3 preference semantics do not preserve independent health/scanner rules.' }
if (@($controls | Where-Object id -match 'enabled$').Count -ne 0) { throw 'A whole-mod/subsystem enabled toggle leaked into public settings.' }

$forbidden = @($settings.forbiddenPublicSettings)
foreach ($required in @('biology.enabled','realpass.enabled','body.enabled','injury.enabled','combat.enabled','armor.enabled','cyberwarePhysiology.enabled','damage-scale','hunger-rate','hydration-rate','bleed-scale','pain-scale','armor-scale','maxdoc-dose-or-decay-scale','cosmetic-transmog-authority')) {
    if ($forbidden -notcontains $required) { throw "Forbidden public setting missing: $required" }
}

if ($surface -match '(?i)ModSettings|mod_settings|runtimeProperty|ModuleExists') { throw 'Production settings source still contains external settings-provider residue.' }
if ($surface -match '(?m)public\s+(?:persistent\s+)?let\s+\w+\s*:\s*(?:Float|Int32|Uint32)\b') { throw 'Biology settings source contains a numeric public setting.' }
$boolFields = @([regex]::Matches($surface,'(?m)public\s+persistent\s+let\s+(?<name>\w+)\s*:\s*Bool\b') | ForEach-Object { $_.Groups['name'].Value })
if ($boolFields.Count -ne 1 -or $boolFields[0] -ne 'e3FirstPersonHudVisuals') { throw "Unexpected persistent Boolean settings surface: $($boolFields -join ', ')" }
if ($surface -match '(?m)public\s+(?!persistent\s+)let\s+\w+\s*:\s*Bool\b') { throw 'Non-persistent editable Boolean leaked into settings authority.' }
if (-not $surface.Contains('extends ScriptableSystem')) { throw 'Settings must remain a ScriptableSystem singleton.' }
if (-not $surface.Contains('public static func IsEnabled(game: GameInstance) -> Bool') -or -not $surface.Contains('return CRRealpassSettings.IsLauncherActivated();')) { throw 'Whole-mod runtime accessor is not solely launcher-authorized.' }
if (-not $surface.Contains('public static func UseE3FirstPersonHudVisuals(game: GameInstance) -> Bool')) { throw 'E3 semantic accessor is missing.' }
if (-not $surface.Contains('public static func SetE3FirstPersonHudVisuals') -or -not $surface.Contains('public static func ToggleE3FirstPersonHudVisuals')) { throw 'Biology-owned E3 preference mutation API is missing.' }
if (-not $surface.Contains('settings.e3FirstPersonHudVisuals = enabled;')) { throw 'Replacement persistence authority is not written by the E3 setter.' }

if ($ui -match '(?i)ModSettings|mod_settings|SettingsMainGameController') { throw 'Biology preference UI still registers into the external/pause settings provider.' }
if (-not $ui.Contains('@addField(RipperDocGameController)') -or -not $ui.Contains('CRRealpassSettings.ToggleE3FirstPersonHudVisuals')) { throw 'Biology body shell does not own the E3 preference editor.' }
if (-not $ui.Contains('E3 HUD + NAMEPLATES')) { throw 'Biology-owned E3 preference editor lacks a visible label.' }

Write-Host 'PASS: Biology exposes only one save-persistent presentation Boolean, edits it in Biology-owned UI, and uses REDlauncher/REDmod as the sole whole-mod activation boundary.'
