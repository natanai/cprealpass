$ErrorActionPreference = 'Stop'
$project = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$settingsPath = Join-Path $project 'manifest/settings.json'
$modulesPath = Join-Path $project 'manifest/runtime-modules.json'
$settings = Get-Content -Raw -LiteralPath $settingsPath | ConvertFrom-Json
$modules = Get-Content -Raw -LiteralPath $modulesPath | ConvertFrom-Json

if ($settings.schemaVersion -ne 2 -or $settings.product -ne 'realpass') { throw 'Unexpected configuration contract.' }
if ($settings.surface.provider -ne 'none' -or $settings.surface.publicGameplaySettings -ne $false -or $settings.surface.publicBalanceSettings -ne $false) {
    throw 'Release must not expose a gameplay/balance settings surface.'
}
if ($settings.surface.persistenceOwner -ne 'realpass') { throw 'Configuration ownership must remain realpass-owned.' }

$moduleById = @{}
foreach ($module in @($modules.modules)) { $moduleById[$module.id] = $module }
$release = $settings.releaseProfile
foreach ($id in @('body','injury','combat','armor','cyberwarePhysiology','presentation')) {
    if (-not $moduleById.ContainsKey($id)) { throw "Release authority missing from module contract: $id" }
    if ($release.$id -ne $true) { throw "Release profile does not lock authority on: $id" }
    if ($moduleById[$id].playerFacingToggle -ne $false) { throw "Release authority is still player-toggleable: $id" }
}
if ($release.diagnostics -ne $false) { throw 'Release diagnostics must be off.' }
if ($release.traditionalActorHealthBars -ne $false) { throw 'Traditional actor health bars must be off.' }
if ($release.nativeModernScanner -ne $true) { throw 'Native modern scanner must remain on.' }

$developmentKeys = @($settings.developmentProfileKeys)
foreach ($id in @('body','injury','combat','armor','cyberwarePhysiology','presentation','diagnostics')) {
    if ($developmentKeys -notcontains $id) { throw "Development isolation key missing: $id" }
}
if ($developmentKeys.Count -ne 7) { throw 'Unexpected development profile surface.' }

$forbidden = @($settings.forbiddenPublicSettings)
foreach ($required in @('body.enabled','injury.enabled','combat.enabled','armor.enabled','presentation.enabled','presentation.traditionalHealthBars','weather','economy','fast-travel-restrictions','outfit-or-transmog-system')) {
    if ($forbidden -notcontains $required) { throw "Forbidden public setting missing: $required" }
}
if (@($settings.accessibilityPolicy.currentPublicControls).Count -ne 0) { throw 'No public controls are accepted yet.' }
if ($settings.accessibilityPolicy.allowedInFuture -ne $true) { throw 'Accessibility policy must remain separately extensible.' }

Write-Host 'PASS: locked realpass release configuration has all gameplay authorities on, diagnostics/healthbars off, and no public gameplay/balance toggles.'
