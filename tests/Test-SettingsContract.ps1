$ErrorActionPreference = 'Stop'
$project = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$settingsPath = Join-Path $project 'manifest/settings.json'
$modulesPath = Join-Path $project 'manifest/runtime-modules.json'
$surfacePath = Join-Path $project 'src/redscript/CyberpunkRealism/RealpassSettings.reds'
$settings = Get-Content -Raw -LiteralPath $settingsPath | ConvertFrom-Json
$modules = Get-Content -Raw -LiteralPath $modulesPath | ConvertFrom-Json
$surface = Get-Content -Raw -LiteralPath $surfacePath

if ($settings.schemaVersion -ne 4 -or $settings.product -ne 'realpass') { throw 'Unexpected configuration contract.' }
if ($settings.playerFacingProduct -ne 'Biology') { throw 'Player-facing product identity must be Biology.' }
if ($settings.surface.semanticOwner -ne 'biology') { throw 'Settings semantics must be Biology-owned.' }
if ($settings.surface.providerRole -ne 'optional-ui-and-persistence-adapter') { throw 'Current settings provider is not classified as a replaceable adapter.' }
if ($settings.surface.provider -ne 'mod-settings') { throw 'Current settings adapter is not recorded accurately.' }
if ($settings.surface.publicGameplaySettings -ne $false -or $settings.surface.publicBalanceSettings -ne $false) {
    throw 'Release must not expose per-authority gameplay or balance settings.'
}
if ($settings.surface.publicMasterEnable -ne $true) { throw 'Global Biology master enable is not represented by contract.' }
if ($settings.surface.publicPresentationPreferences -ne $true) { throw 'Constrained presentation preferences are not enabled by contract.' }
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
if ($release.e3InspiredFirstPersonHud -ne $true -or $release.e3InspiredNpcNameplates -ne $true) {
    throw 'Authored Biology presentation must retain the E3-inspired first-person HUD/nameplate target.'
}

$fallback = $settings.developmentFeedbackFallback
if ($fallback.traditionalPlayerHealthBarsVisibleUntilReplacementAccepted -ne $false -or $fallback.traditionalNpcHealthBarsVisibleUntilReplacementAccepted -ne $false) {
    throw 'Attended barless acceptance regressed to the old healthbar fallback.'
}
if ($fallback.rule -notmatch 'E3 preference does not own health-bar suppression') {
    throw 'Settings contract conflates Biology-wide health suppression with the optional E3 skin.'
}

# The user-facing settings page is intentionally minimal. The current provider is a
# replaceable adapter; its page should communicate Biology rather than transitional
# internal RealPass identifiers.
$ledger = @($settings.featureLedger)
if ($ledger.Count -ne 0) { throw 'Biology settings should not contain a fake read-only feature ledger.' }

$controls = @($settings.publicControls)
if ($controls.Count -ne 2) { throw "Expected exactly two public Biology settings, found $($controls.Count)." }
$master = @($controls | Where-Object id -eq 'realpass.enabled')
$e3 = @($controls | Where-Object id -eq 'presentation.e3-first-person-hud-visuals')
if ($master.Count -ne 1 -or $master[0].type -ne 'bool' -or $master[0].default -ne $true -or $master[0].authority -ne 'global-master') {
    throw 'Global Biology master setting contract is invalid.'
}
if ($master[0].compatibilityId -ne $true -or $master[0].displayName -ne 'Enable Biology') {
    throw 'Transitional master ID is not explicitly separated from Biology player-facing naming.'
}
if ($e3.Count -ne 1 -or $e3[0].type -ne 'bool' -or $e3[0].default -ne $true -or $e3[0].authority -ne 'presentation-only') {
    throw 'E3 HUD/nameplate presentation setting contract is invalid.'
}
if ($e3[0].displayName -ne 'E3-inspired HUD + nameplates') { throw 'E3 preference label does not describe its visible outcome.' }
if ($e3[0].description -notmatch 'barless-health policy' -or $e3[0].description -notmatch 'scanner/quickhack') {
    throw 'E3 preference semantics do not preserve the independent health/scanner rules.'
}

$forbidden = @($settings.forbiddenPublicSettings)
foreach ($required in @('body.enabled','injury.enabled','combat.enabled','armor.enabled','cyberwarePhysiology.enabled','damage-scale','hunger-rate','hydration-rate','bleed-scale','pain-scale','armor-scale','maxdoc-dose-or-decay-scale','cosmetic-transmog-authority')) {
    if ($forbidden -notcontains $required) { throw "Forbidden public setting missing: $required" }
}

# Machine-check the actual runtime-property surface, not just its JSON declaration.
if ($surface -match '(?m)public\s+let\s+\w+\s*:\s*(?:Float|Int32|Uint32)\b') {
    throw 'Biology settings source contains a numeric setting type.'
}
foreach ($forbiddenField in @('bodyEnabled','injuryEnabled','combatEnabled','armorEnabled','cyberwarePhysiologyEnabled','presentationEnabled','traditionalHealthBars','fullscreenDisorientationEffects')) {
    if ($surface -match ('(?m)public\s+let\s+' + [regex]::Escape($forbiddenField) + '\b')) {
        throw "Unexpected setting leaked into player settings: $forbiddenField"
    }
}
$boolFields = @([regex]::Matches($surface,'(?m)public\s+let\s+(?<name>\w+)\s*:\s*Bool\b') | ForEach-Object { $_.Groups['name'].Value })
if ($boolFields.Count -ne 2 -or $boolFields -notcontains 'enabled' -or $boolFields -notcontains 'e3FirstPersonHudVisuals') {
    throw "Unexpected editable boolean settings surface: $($boolFields -join ', ')"
}
if (-not $surface.Contains('@runtimeProperty("ModSettings.mod", "Biology")')) { throw 'Settings page still lacks Biology product identity.' }
if (-not $surface.Contains('@runtimeProperty("ModSettings.displayName", "Enable Biology")')) { throw 'Biology master label is missing.' }
if ($surface.Contains('@runtimeProperty("ModSettings.mod", "RealPass")') -or $surface.Contains('@runtimeProperty("ModSettings.displayName", "Enable RealPass")')) {
    throw 'Obsolete RealPass branding is still player-facing.'
}
if (-not $surface.Contains('extends ScriptableSystem')) { throw 'Settings must use a ScriptableSystem singleton for live adapter updates.' }
if (-not $surface.Contains('ModSettings.RegisterListenerToClass(this)')) { throw 'Settings singleton is not registered for current provider updates.' }
if (-not $surface.Contains('ModSettings.UnregisterListenerToClass(this)')) { throw 'Settings singleton is not unregistered cleanly.' }
if (-not $surface.Contains('@if(ModuleExists("ModSettingsModule"))')) { throw 'Provider integration is not optional/guarded.' }
if ($surface -match '(?m)^\s*import\s+ModSettings') { throw 'Provider internals leaked into Biology semantic settings source.' }
if (-not $surface.Contains('public static func IsEnabled(game: GameInstance) -> Bool')) { throw 'Global master runtime accessor is missing.' }
if (-not $surface.Contains('public static func UseE3FirstPersonHudVisuals(game: GameInstance) -> Bool')) { throw 'E3 semantic accessor is missing.' }
if (-not $surface.Contains('CRRealpassSettings.IsEnabled(game)')) { throw 'E3 presentation preference does not respect the global master switch.' }

Write-Host 'PASS: Biology exposes one global master switch plus one presentation-only E3 HUD/nameplate toggle, with provider-neutral semantics and no subsystem/balance controls.'
