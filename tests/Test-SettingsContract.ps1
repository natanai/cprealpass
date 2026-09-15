$ErrorActionPreference = 'Stop'
$project = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$settingsPath = Join-Path $project 'manifest/settings.json'
$modulesPath = Join-Path $project 'manifest/runtime-modules.json'
$surfacePath = Join-Path $project 'src/redscript/CyberpunkRealism/RealpassSettings.reds'
$settings = Get-Content -Raw -LiteralPath $settingsPath | ConvertFrom-Json
$modules = Get-Content -Raw -LiteralPath $modulesPath | ConvertFrom-Json
$surface = Get-Content -Raw -LiteralPath $surfacePath

if ($settings.schemaVersion -ne 3 -or $settings.product -ne 'realpass') { throw 'Unexpected configuration contract.' }
if ($settings.surface.provider -ne 'mod-settings') { throw 'RealPass must identify itself through the Mod Settings surface.' }
if ($settings.surface.publicGameplaySettings -ne $false -or $settings.surface.publicBalanceSettings -ne $false) {
    throw 'Release must not expose gameplay or balance settings.'
}
if ($settings.surface.publicPresentationPreferences -ne $true) { throw 'Constrained presentation preferences are not enabled by contract.' }
if ($settings.numericPublicBalanceControlsAllowed -ne $false) { throw 'Numeric public balance controls must remain forbidden.' }

$moduleById = @{}
foreach ($module in @($modules.modules)) { $moduleById[$module.id] = $module }
$release = $settings.releaseProfile
foreach ($id in @('body','injury','combat','armor','cyberwarePhysiology','presentation')) {
    if (-not $moduleById.ContainsKey($id)) { throw "Release authority missing from module contract: $id" }
    if ($release.$id -ne $true) { throw "Release profile does not lock authority on: $id" }
    if ($moduleById[$id].playerFacingToggle -ne $false) { throw "Release authority is still player-toggleable: $id" }
}
if ($release.diagnostics -ne $false) { throw 'Release diagnostics must be off.' }
if ($release.traditionalActorHealthBarsFinalTarget -ne $false) { throw 'Final target must still remove traditional actor health bars.' }
if ($release.nativeModernScanner -ne $true) { throw 'Native modern scanner must remain on.' }
if ($release.e3InspiredFirstPersonHud -ne $true -or $release.e3InspiredNpcNameplates -ne $true) {
    throw 'Authored RealPass presentation must retain the E3-inspired first-person HUD/nameplate target.'
}

$fallback = $settings.developmentFeedbackFallback
if ($fallback.traditionalPlayerHealthBarsVisibleUntilReplacementAccepted -ne $true -or $fallback.traditionalNpcHealthBarsVisibleUntilReplacementAccepted -ne $true) {
    throw 'Development feedback fallback must remain replacement-gated while replacements are unaccepted.'
}

# The user-facing settings page is intentionally minimal. Mod Settings itself proves
# that RealPass is installed; fake one-value enum rows are not used as a feature ledger.
$ledger = @($settings.featureLedger)
if ($ledger.Count -ne 0) { throw 'RealPass Mod Settings should not contain a fake read-only feature ledger.' }

$controls = @($settings.publicControls)
if ($controls.Count -ne 1) { throw "Expected exactly one public RealPass setting, found $($controls.Count)." }
$control = $controls[0]
if ([string]$control.id -ne 'presentation.e3-first-person-hud-visuals') { throw 'The sole public setting must be the E3 first-person HUD visual toggle.' }
if ([string]$control.type -ne 'bool') { throw 'E3 first-person HUD setting must be binary.' }
if ([string]$control.authority -ne 'presentation-only') { throw 'E3 first-person HUD setting gained simulation authority.' }
if ($control.default -ne $true) { throw 'E3 first-person HUD visuals must default on.' }

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
if ($boolFields.Count -ne 1 -or $boolFields[0] -ne 'e3FirstPersonHudVisuals') {
    throw "Unexpected editable boolean settings surface: $($boolFields -join ', ')"
}
if (-not $surface.Contains('extends ScriptableSystem')) { throw 'RealPass settings must use a ScriptableSystem singleton for live Mod Settings updates.' }
if (-not $surface.Contains('ModSettings.RegisterListenerToClass(this)')) { throw 'RealPass settings singleton is not registered for live Mod Settings updates.' }
if (-not $surface.Contains('ModSettings.UnregisterListenerToClass(this)')) { throw 'RealPass settings singleton is not unregistered cleanly.' }

Write-Host 'PASS: RealPass exposes exactly one presentation-only E3 HUD/nameplate toggle, defaults it on, and keeps all simulation/balance controls private.'
