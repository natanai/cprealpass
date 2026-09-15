$ErrorActionPreference = 'Stop'
$project = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$settingsPath = Join-Path $project 'manifest/settings.json'
$modulesPath = Join-Path $project 'manifest/runtime-modules.json'
$surfacePath = Join-Path $project 'src/redscript/CyberpunkRealism/RealpassSettings.reds'
$settings = Get-Content -Raw -LiteralPath $settingsPath | ConvertFrom-Json
$modules = Get-Content -Raw -LiteralPath $modulesPath | ConvertFrom-Json
$surface = Get-Content -Raw -LiteralPath $surfacePath

if ($settings.schemaVersion -ne 4 -or $settings.product -ne 'realpass') { throw 'Unexpected configuration contract.' }
if ($settings.surface.provider -ne 'mod-settings') { throw 'RealPass must identify itself through the Mod Settings surface.' }
if ($settings.surface.publicGameplaySettings -ne $false -or $settings.surface.publicBalanceSettings -ne $false) {
    throw 'Release must not expose per-authority gameplay or balance settings.'
}
if ($settings.surface.publicMasterEnable -ne $true) { throw 'Global RealPass master enable is not represented by contract.' }
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
    throw 'Authored RealPass presentation must retain the E3-inspired first-person HUD/nameplate target.'
}

$fallback = $settings.developmentFeedbackFallback
if ($fallback.traditionalPlayerHealthBarsVisibleUntilReplacementAccepted -ne $false -or $fallback.traditionalNpcHealthBarsVisibleUntilReplacementAccepted -ne $false) {
    throw 'Attended barless acceptance regressed to the old healthbar fallback.'
}

# The user-facing settings page is intentionally minimal. Mod Settings itself proves
# that RealPass is installed; fake one-value enum rows are not used as a feature ledger.
$ledger = @($settings.featureLedger)
if ($ledger.Count -ne 0) { throw 'RealPass Mod Settings should not contain a fake read-only feature ledger.' }

$controls = @($settings.publicControls)
if ($controls.Count -ne 2) { throw "Expected exactly two public RealPass settings, found $($controls.Count)." }
$master = @($controls | Where-Object id -eq 'realpass.enabled')
$e3 = @($controls | Where-Object id -eq 'presentation.e3-first-person-hud-visuals')
if ($master.Count -ne 1 -or $master[0].type -ne 'bool' -or $master[0].default -ne $true -or $master[0].authority -ne 'global-master') {
    throw 'Global RealPass master setting contract is invalid.'
}
if ($e3.Count -ne 1 -or $e3[0].type -ne 'bool' -or $e3[0].default -ne $true -or $e3[0].authority -ne 'presentation-only') {
    throw 'E3 first-person HUD presentation setting contract is invalid.'
}

$forbidden = @($settings.forbiddenPublicSettings)
foreach ($required in @('body.enabled','injury.enabled','combat.enabled','armor.enabled','cyberwarePhysiology.enabled','damage-scale','hunger-rate','hydration-rate','bleed-scale','pain-scale','armor-scale','maxdoc-dose-or-decay-scale','cosmetic-transmog-authority')) {
    if ($forbidden -notcontains $required) { throw "Forbidden public setting missing: $required" }
}

# Machine-check the actual runtime-property surface, not just its JSON declaration.
if ($surface -match '(?m)public\s+let\s+\w+\s*:\s*(?:Float|Int32|Uint32)\b') {
    throw 'RealPass Mod Settings source contains a numeric setting type.'
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
if (-not $surface.Contains('extends ScriptableSystem')) { throw 'RealPass settings must use a ScriptableSystem singleton for live Mod Settings updates.' }
if (-not $surface.Contains('ModSettings.RegisterListenerToClass(this)')) { throw 'RealPass settings singleton is not registered for live Mod Settings updates.' }
if (-not $surface.Contains('ModSettings.UnregisterListenerToClass(this)')) { throw 'RealPass settings singleton is not unregistered cleanly.' }
if (-not $surface.Contains('public static func IsEnabled(game: GameInstance) -> Bool')) { throw 'Global master runtime accessor is missing.' }
if (-not $surface.Contains('CRRealpassSettings.IsEnabled(game)')) { throw 'E3 presentation preference does not respect the global master switch.' }

Write-Host 'PASS: RealPass exposes one global master switch plus one presentation-only E3 HUD/nameplate toggle, both default on, with no subsystem/balance controls.'
