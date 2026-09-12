$ErrorActionPreference = 'Stop'
$project = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$settingsPath = Join-Path $project 'manifest/settings.json'
$modulesPath = Join-Path $project 'manifest/runtime-modules.json'
$settings = Get-Content -Raw -LiteralPath $settingsPath | ConvertFrom-Json
$modules = Get-Content -Raw -LiteralPath $modulesPath | ConvertFrom-Json

if ($settings.schemaVersion -ne 1 -or $settings.product -ne 'realpass') { throw 'Unexpected settings contract.' }
if ($settings.surface.modName -ne 'realpass' -or $settings.surface.singlePublicSurface -ne $true) { throw 'Settings must expose one realpass surface.' }
if ($settings.surface.persistenceOwner -ne 'realpass') { throw 'Settings persistence must be realpass-owned.' }
if (@($settings.safety.currentAcceptedForAutomaticActivation).Count -ne 0) { throw 'Native automatic activation must remain gated until acceptance.' }

$moduleById = @{}
foreach ($module in @($modules.modules)) { $moduleById[$module.id] = $module }
$settingByKey = @{}
$categoryIds = @{}
foreach ($category in @($settings.categories)) {
    if ($categoryIds.ContainsKey($category.id)) { throw "Duplicate settings category: $($category.id)" }
    $categoryIds[$category.id] = $true
    if (-not $moduleById.ContainsKey($category.id)) { throw "Settings category has no runtime module: $($category.id)" }
    foreach ($setting in @($category.settings)) {
        if ($settingByKey.ContainsKey($setting.key)) { throw "Duplicate setting key: $($setting.key)" }
        $settingByKey[$setting.key] = $setting
        if ($setting.type -ne 'bool') { throw "Unapproved settings type for first public contract: $($setting.key)" }
        if ($null -eq $setting.default) { throw "Setting lacks default: $($setting.key)" }
        if ($setting.dependency -and -not $setting.dependency.StartsWith($category.id + '.')) {
            throw "Cross-module sub-toggle dependency is not allowed: $($setting.key) -> $($setting.dependency)"
        }
    }
}

foreach ($module in @($modules.modules)) {
    if (-not $settingByKey.ContainsKey($module.settingsKey)) { throw "Missing master module setting: $($module.settingsKey)" }
    if ($settingByKey[$module.settingsKey].default -ne $module.releaseDefault) { throw "Module default mismatch: $($module.id)" }
    foreach ($subtoggle in @($module.subtoggles)) {
        $key = $module.id + '.' + $subtoggle
        if (-not $settingByKey.ContainsKey($key)) { throw "Missing approved subtoggle setting: $key" }
        if ($settingByKey[$key].dependency -ne $module.settingsKey) { throw "Subtoggle does not depend on module master: $key" }
    }
}

if ($settingByKey['diagnostics.enabled'].default -ne $false) { throw 'Diagnostics must default off.' }
$diagnosticsCategory = @($settings.categories | Where-Object id -eq 'diagnostics')
if ($diagnosticsCategory.Count -ne 1 -or $diagnosticsCategory[0].developmentOnly -ne $true) { throw 'Diagnostics settings category must remain development-only.' }

$forbidden = @($settings.forbiddenPublicSettings)
foreach ($required in @('weather','economy','fast-travel-restrictions','outfit-or-transmog-system')) {
    if ($forbidden -notcontains $required) { throw "Forbidden public setting missing: $required" }
}
foreach ($key in $settingByKey.Keys) {
    foreach ($forbiddenTerm in $forbidden) {
        if ($key.ToLowerInvariant().Contains($forbiddenTerm.ToLowerInvariant())) { throw "Out-of-scope public setting exposed: $key" }
    }
}

Write-Host "PASS: one realpass settings surface with $($settingByKey.Count) approved settings across $($categoryIds.Count) runtime modules."
