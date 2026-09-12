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

Check ((Count '@wrapMethod(healthbarWidgetGameController)') -eq 3) 'Expected three player-health lifecycle/visibility hooks.'
Check ((Count '@wrapMethod(NameplateVisualsLogicController)') -eq 2) 'Expected two NPC-health visibility hooks.'
Check ((Count '@wrapMethod(BossHealthBarGameController)') -eq 1) 'Expected one boss-health visibility hook.'
Check ($source.Contains('private final func UpdateHealthbarVisibility() -> Void')) 'NPC health visibility hook signature missing.'
Check ($source.Contains('private final func ShowBossHealthBar(puppet: ref<NPCPuppet>, useSilentUpdate: Bool) -> Void')) 'Boss health hook signature missing.'
Check ($source.Contains('protected cb func OnUpdateHealthBarVisibility() -> Bool')) 'Player health visibility hook signature missing.'
Check ($source.Contains('return false;')) 'Authored no-healthbar default is not closed.'

foreach ($field in @('m_healthBar','m_overshieldBarRef','m_lostHealthAggregationBar','m_damegePreview','m_fullBar','m_healthTextPath','m_maxHealthTextPath')) {
    Check ($source.Contains($field)) "Player health suppression lost field: $field"
}
foreach ($field in @('m_healthbarWidget','m_damagePreviewWrapper','m_damagePreviewWidget','m_damagePreviewArrow')) {
    Check ($source.Contains($field)) "NPC health suppression lost field: $field"
}
Check ($source.Contains('this.m_healthbarVisible = false;')) 'NPC controller can retain a logical healthbar-visible state.'
Check ($source.Contains('this.HideBossHealthBar();') -and $source.Contains('this.GetRootWidget().SetVisible(false);')) 'Boss health HUD is not forced closed.'

# Player suppression deliberately hides children, not the entire biomonitor root, so
# RAM/buffs can remain available even while HP is unknown to the player.
$playerHelper = [regex]::Match($source,'(?s)private func CRHideTraditionalPlayerHealth\(\) -> Void \{(.*?)\n\}').Groups[1].Value
Check (-not $playerHelper.Contains('GetRootWidget().SetVisible(false)')) 'Player helper hides RAM/buffs with the whole biomonitor root.'
Check (-not $playerHelper.Contains('m_quickhacksContainer')) 'Player helper hides quickhack/RAM information.'

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

Write-Host "PASS: $checks no-healthbar presentation contract checks; HP UI is hidden without becoming a damage authority."
