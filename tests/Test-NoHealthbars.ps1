$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\tools\Common.ps1"
$project = Get-ProjectRoot
$path = Join-Path $project 'src/redscript/CyberpunkRealism/NoHealthbars.reds'
$source = Get-Content -Raw -LiteralPath $path
$settings = Get-Content -Raw -LiteralPath (Join-Path $project 'manifest/settings.json') | ConvertFrom-Json
$modules = Get-Content -Raw -LiteralPath (Join-Path $project 'manifest/runtime-modules.json') | ConvertFrom-Json
$script:checks = 0
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

# Development fallback is explicit and fail-readable: until attended acceptance says
# replacement feedback works, native actor HP may remain visible. These gates are not
# player preferences and are expected to flip only as acceptance evidence closes.
Check ($source.Contains('public class CRFeedbackReadiness')) 'Replacement-readiness policy is missing.'
Check ($source.Contains('PlayerHealthReplacementAccepted() -> Bool') -and $source.Contains('NPCHealthReplacementAccepted() -> Bool')) 'Player/NPC replacement acceptance gates are not distinct.'
$playerGate = [regex]::Match($source,'(?s)PlayerHealthReplacementAccepted\(\) -> Bool\s*\{\s*return (?<value>true|false);').Groups['value'].Value
$npcGate = [regex]::Match($source,'(?s)NPCHealthReplacementAccepted\(\) -> Bool\s*\{\s*return (?<value>true|false);').Groups['value'].Value
Check ($playerGate -eq 'false' -and $npcGate -eq 'false') 'Unaccepted replacement feedback is suppressing native actor health too early.'
Check ($source.Contains('return !CRFeedbackReadiness.PlayerHealthReplacementAccepted();')) 'Player healthbar fallback is not tied to replacement acceptance.'
Check ($source.Contains('return !CRFeedbackReadiness.NPCHealthReplacementAccepted();')) 'NPC healthbar fallback is not tied to replacement acceptance.'

foreach ($field in @('m_healthBar','m_overshieldBarRef','m_lostHealthAggregationBar','m_damegePreview','m_fullBar','m_healthTextPath','m_maxHealthTextPath')) {
    Check ($source.Contains($field)) "Future player health suppression lost field: $field"
}
foreach ($field in @('m_healthbarWidget','m_damagePreviewWrapper','m_damagePreviewWidget','m_damagePreviewArrow')) {
    Check ($source.Contains($field)) "Future NPC health suppression lost field: $field"
}
Check ($source.Contains('this.m_healthbarVisible = false;')) 'Accepted NPC suppression cannot clear the controller healthbar-visible state.'
Check ($source.Contains('this.HideBossHealthBar();') -and $source.Contains('this.GetRootWidget().SetVisible(false);')) 'Accepted boss-health suppression path is incomplete.'

foreach ($method in @('OnInitialize','OnUpdateHealthBarVisibility','EvaluateHealthBarVisibility','EvaluateOvershieldBarVisibility')) {
    $pattern = '(?s)func ' + [regex]::Escape($method) + '\([^\)]*\).*?\{(.*?)\n\}'
    $body = [regex]::Match($source,$pattern).Groups[1].Value
    Check ($body.Contains('this.CRApplyPlayerHealthPresentation();')) "Player visibility path does not reapply the acceptance-gated policy: $method"
}

$playerHelper = [regex]::Match($source,'(?s)private func CRApplyPlayerHealthPresentation\(\) -> Void \{(.*?)\n\}').Groups[1].Value
Check ($playerHelper.Contains('ShowTraditionalPlayerHealthBars()')) 'Player helper does not preserve native fallback while replacements are unaccepted.'
Check (-not $playerHelper.Contains('GetRootWidget().SetVisible(false)')) 'Player helper would hide RAM/buffs with the whole biomonitor root.'
Check (-not $playerHelper.Contains('m_quickhacksContainer')) 'Player helper hides quickhack/RAM information.'
Check (-not $source.Contains('m_moduleShown = false')) 'Healthbar presentation disables shared HUD module state used by contextual cues.'
Check (-not $source.Contains('DarkFuture')) 'Healthbar presentation contains a source-mod runtime dependency.'

$companion = [regex]::Match($source,'(?s)protected cb func OnFlatheadStatusChanged\(value: Bool\) -> Bool \{(.*?)\n\}').Groups[1].Value
Check ($companion.Contains('wrappedMethod(value)') -and $companion.Contains('ShowTraditionalNPCHealthBars()')) 'Companion health path is not acceptance-gated after native state handling.'
Check (-not $source.Contains('@wrapMethod(vehicle')) 'Healthbar presentation unexpectedly wraps vehicle UI.'
Check (-not $source.Contains('ObjectiveHealth')) 'Healthbar presentation unexpectedly wraps objective durability UI.'

foreach ($forbidden in @('SetStatPoolValue','ApplyDamage','ProcessLocalizedDamage','nativeHealthFraction =','m_currentHealth =','m_maximumHealth =')) {
    Check (-not $source.Contains($forbidden)) "Healthbar presentation mutates combat/health state: $forbidden"
}

# Final authored target remains barless even though development currently keeps the
# fallback visible until replacement cues pass attended acceptance.
Check ($settings.schemaVersion -eq 3) 'Current settings contract missing.'
Check ($settings.releaseProfile.presentation -eq $true) 'Presentation authority is not enabled in the release profile.'
Check ($settings.releaseProfile.traditionalActorHealthBarsFinalTarget -eq $false) 'Final release target re-enabled traditional actor HP bars.'
Check ($settings.developmentFeedbackFallback.traditionalPlayerHealthBarsVisibleUntilReplacementAccepted -eq $true) 'Player fallback is not declared.'
Check ($settings.developmentFeedbackFallback.traditionalNpcHealthBarsVisibleUntilReplacementAccepted -eq $true) 'NPC fallback is not declared.'
$module = @($modules.modules | Where-Object id -eq 'presentation')
Check ($module.Count -eq 1 -and $module[0].releaseEnabled -eq $true -and @($module[0].owns) -contains 'healthbar-suppression') 'Presentation module does not own eventual release healthbar suppression.'
Check ($module[0].fixedReleaseChoices.traditionalActorHealthBars -eq $false) 'Presentation module lost final actor-healthbar policy.'

Write-Host "PASS: $script:checks replacement-gated healthbar contract checks; native actor HP remains available during the unaccepted replacement phase while the final RealPass target and suppression seams remain intact."
