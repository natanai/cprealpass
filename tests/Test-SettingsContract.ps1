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

$fallback = $settings.developmentFeedbackFallback
if ($fallback.traditionalPlayerHealthBarsVisibleUntilReplacementAccepted -ne $true -or $fallback.traditionalNpcHealthBarsVisibleUntilReplacementAccepted -ne $true) {
    throw 'Development feedback fallback must remain replacement-gated while replacements are unaccepted.'
}

$ledger = @($settings.featureLedger)
foreach ($required in @('runtime-active','body-and-physiology','injury-bleeding-and-recovery','pain-and-maxdoc-analgesia','combat-and-ballistics','physical-armor-and-protection','presentation-and-feedback')) {
    if ($ledger -notcontains $required) { throw "Feature ledger missing: $required" }
}
if ($ledger.Count -gt 8) { throw 'Feature ledger is becoming an implementation dump rather than a concise status surface.' }

$controls = @($settings.publicControls)
if ($controls.Count -lt 1) { throw 'Expected at least one accepted binary presentation preference.' }
foreach ($control in $controls) {
    if ([string]$control.type -ne 'bool') { throw "Public control is not binary: $($control.id)" }
    if ([string]$control.authority -ne 'presentation-only') { throw "Public control gained simulation authority: $($control.id)" }
}
if (@($controls.id) -notcontains 'presentation.fullscreen-disorientation-effects') { throw 'Accepted fullscreen disorientation preference is missing.' }

$forbidden = @($settings.forbiddenPublicSettings)
foreach ($required in @('body.enabled','injury.enabled','combat.enabled','armor.enabled','cyberwarePhysiology.enabled','damage-scale','hunger-rate','hydration-rate','bleed-scale','pain-scale','armor-scale','maxdoc-dose-or-decay-scale','cosmetic-transmog-authority')) {
    if ($forbidden -notcontains $required) { throw "Forbidden public setting missing: $required" }
}

# Machine-check the actual runtime-property surface, not just its JSON declaration.
if ($surface -match '(?m)public\s+let\s+\w+\s*:\s*(?:Float|Int32|Uint32)\b') {
    throw 'RealPass Mod Settings source contains a numeric setting type.'
}
foreach ($forbiddenField in @('bodyEnabled','injuryEnabled','combatEnabled','armorEnabled','cyberwarePhysiologyEnabled','presentationEnabled','traditionalHealthBars')) {
    if ($surface -match ('(?m)public\s+let\s+' + [regex]::Escape($forbiddenField) + '\b')) {
        throw "Core authority or final presentation policy leaked into player settings: $forbiddenField"
    }
}
$boolFields = @([regex]::Matches($surface,'(?m)public\s+let\s+(?<name>\w+)\s*:\s*Bool\b') | ForEach-Object { $_.Groups['name'].Value })
if ($boolFields.Count -ne 1 -or $boolFields[0] -ne 'fullscreenDisorientationEffects') {
    throw "Unexpected editable boolean settings surface: $($boolFields -join ', ')"
}
if (-not $surface.Contains('CRRealpassManagedState')) { throw 'Feature ledger is not using the one-value managed-state type.' }

Write-Host 'PASS: RealPass settings identify the active mod, keep a concise managed-feature ledger, expose only accepted binary presentation preferences, and forbid numeric/core-authority tuning.'
