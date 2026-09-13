$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\tools\Common.ps1"
$project = Get-ProjectRoot
$path = Join-Path $project 'src/redscript/CyberpunkRealism/NoHealthbars.reds'
$source = Get-Content -Raw -LiteralPath $path
$settings = Get-Content -Raw -LiteralPath (Join-Path $project 'manifest/settings.json') | ConvertFrom-Json
$modules = Get-Content -Raw -LiteralPath (Join-Path $project 'manifest/runtime-modules.json') | ConvertFrom-Json
$checks = 0
function Check($condition,[string]$message) { if (-not $condition) { throw $message }; $script:checks++ }
function Count([string]$needle) { return [regex]::Matches($source,[regex]::Escape($needle)).Count }

Check ((Count '@wrapMethod(healthbarWidgetGameController)') -eq 4) 'Expected four verified player-health lifecycle/direct-visibility hooks.'
Check ((Count '@wrapMethod(NameplateVisualsLogicController)') -eq 2) 'Expected two NPC-health visibility hooks.'
Check ((Count '@wrapMethod(BossHealthBarGameController)') -eq 1) 'Expected one boss-health visibility hook.'
Check ((Count '@wrapMethod(CompanionHealthBarGameController)') -eq 1) 'Expected one dedicated companion-health visibility hook.'
Check ($source.Contains('private final func UpdateHealthbarVisibility() -> Void')) 'NPC health visibility hook signature missing.'
Check ($source.Contains('private final func ShowBossHealthBar(puppet: ref<NPCPuppet>, useSilentUpdate: Bool) -> Void')) 'Boss health hook signature missing.'
Check ($source.Contains('protected cb func OnInitialize() -> Bool')) 'Player health initialize hook signature missing.'
Check ($source.Contains('protected cb func OnUpdateHealthBarVisibility() -> Bool')) 'Player health visibility hook signature missing.'
Check ($source.Contains('public final func EvaluateHealthBarVisibility(isInOverclockedState: Bool) -> Void')) 'Direct overclock health visibility hook signature missing.'
Check ($source.Contains('public final func EvaluateOvershieldBarVisibility() -> Void')) 'Overshield visibility hook signature missing.'
Check ($source.Contains('protected cb func OnFlatheadStatusChanged(value: Bool) -> Bool')) 'Companion health hook signature missing.'
Check (-not $source.Contains('OnStatsChanged')) 'Unnecessary player stat callback hook reintroduced compile risk.'
Check ($source.Contains('return false;')) 'Authored no-healthbar default is not closed.'

foreach ($field in @('m_healthBar','m_overshieldBarRef','m_lostHealthAggregationBar','m_damegePreview','m_fullBar','m_healthTextPath','m_maxHealthTextPath')) {
    Check ($source.Contains($field)) "Player health suppression lost field: $field"
}
foreach ($field in @('m_healthbarWidget','m_damagePreviewWrapper','m_damagePreviewWidget','m_damagePreviewArrow')) {
    Check ($source.Contains($field)) "NPC health suppression lost field: $field"
}
Check ($source.Contains('this.m_healthbarVisible = false;')) 'NPC controller can retain a logical healthbar-visible state.'
Check ($source.Contains('this.HideBossHealthBar();') -and $source.Contains('this.GetRootWidget().SetVisible(false);')) 'Boss health HUD is not forced closed.'

# Every native player-health path that can directly re-show a bar must finish by
# applying the common child-only suppression helper.
foreach ($method in @('OnInitialize','OnUpdateHealthBarVisibility','EvaluateHealthBarVisibility','EvaluateOvershieldBarVisibility')) {
    $pattern = '(?s)func ' + [regex]::Escape($method) + '\([^\)]*\).*?\{(.*?)\n\}'
    $body = [regex]::Match($source,$pattern).Groups[1].Value
    Check ($body.Contains('this.CRHideTraditionalPlayerHealth();')) "Player visibility path does not reapply suppression: $method"
}

# Player suppression deliberately hides children, not the entire biomonitor root, so
# RAM/buffs and contextual condition indicators can remain available even while HP
# is unknown. Dark Future keys its conditions HUD off the native moduleShown state,
# so realpass must not falsify that controller state merely to hide HP pixels.
$playerHelper = [regex]::Match($source,'(?s)private func CRHideTraditionalPlayerHealth\(\) -> Void \{(.*?)\n\}').Groups[1].Value
Check (-not $playerHelper.Contains('GetRootWidget().SetVisible(false)')) 'Player helper hides RAM/buffs with the whole biomonitor root.'
Check (-not $playerHelper.Contains('m_quickhacksContainer')) 'Player helper hides quickhack/RAM information.'
Check (-not $source.Contains('m_moduleShown = false')) 'Healthbar suppression disables the shared HUD module state used by contextual condition cues.'
Check (-not $source.Contains('DarkFutureHUDSystem = null')) 'Healthbar suppression severs Dark Future contextual HUD integration.'

# Companion is an actor-health readout and is intentionally hidden. Do not expand
# this policy into generic objective/vehicle durability HUDs without a separate,
# explicit acceptance decision.
$companion = [regex]::Match($source,'(?s)protected cb func OnFlatheadStatusChanged\(value: Bool\) -> Bool \{(.*?)\n\}').Groups[1].Value
Check ($companion.Contains('wrappedMethod(value)') -and $companion.Contains('GetRootWidget().SetVisible(false)')) 'Companion actor HP is not suppressed after native state handling.'
Check (-not $source.Contains('@wrapMethod(vehicle')) 'No-healthbar presentation unexpectedly wraps vehicle UI.'
Check (-not $source.Contains('ObjectiveHealth')) 'No-healthbar presentation unexpectedly wraps objective durability UI.'

# Presentation code must not become a damage authority.
foreach ($forbidden in @('SetStatPoolValue','ApplyDamage','ProcessLocalizedDamage','nativeHealthFraction =','m_currentHealth =','m_maximumHealth =')) {
    Check (-not $source.Contains($forbidden)) "Healthbar presentation mutates combat/health state: $forbidden"
}

$presentation = @($settings.categories | Where-Object id -eq 'presentation')
Check ($presentation.Count -eq 1) 'Presentation settings category missing.'
$healthSetting = @($presentation[0].settings | Where-Object key -eq 'presentation.traditionalHealthBars')
Check ($healthSetting.Count -eq 1 -and $healthSetting[0].default -eq $false -and $healthSetting[0].dependency -eq 'presentation.enabled') 'Traditional healthbar setting must exist and default off under presentation.'
$module = @($modules.modules | Where-Object id -eq 'presentation')
Check ($module.Count -eq 1 -and @($module[0].subtoggles) -contains 'traditionalHealthBars' -and @($module[0].owns) -contains 'healthbar-suppression') 'Presentation module does not own healthbar suppression.'

Write-Host "PASS: $checks no-healthbar presentation contract checks; actor HP stays hidden while shared non-health HUD/condition state remains available and presentation never becomes damage authority."
