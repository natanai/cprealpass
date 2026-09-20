$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\tools\Common.ps1"
$project = Get-ProjectRoot
$source = Join-Path $project 'src\redscript\CyberpunkRealism'
$script:checks = 0
function Check($condition,[string]$message) { if (-not $condition) { throw $message }; $script:checks++ }
function Text([string]$name) { return Get-Content -Raw -LiteralPath (Join-Path $source $name) }

$preference = Text 'BiologyPreferencesNative.reds'
$shell = Text 'BiologyCyberwareShell.reds'
$followup = Text 'BiologyLiveShellFollowupNative.reds'

# T006-F02: the old fullscreen-root / TopRight / fixed-margin strategy is live-proven
# clipped. The preference must now be local to the W17.1 authored Biology content seam.
Check ($preference.Contains('CRMountBiologyE3PreferenceInNativeContent(host: ref<inkVerticalPanel>)')) 'W20.2 local preference mount seam is missing.'
Check ($shell.Contains('this.CRMountBiologyE3PreferenceInNativeContent(this.crBiologyNativeContent);')) 'Biology detail does not own the preference panel.'
Check ($preference.Contains('panel.Reparent(host, -1);')) 'Preference panel is not parented to the supplied local Biology content host.'
Check (-not $preference.Contains('GetRootCompoundWidget')) 'Preference still depends on the fullscreen Ripperdoc root.'
Check (-not $preference.Contains('inkEAnchor.TopRight')) 'Preference still uses the live-proven clipped TopRight anchor.'
Check (-not $preference.Contains('158.0, 48.0')) 'Preference still carries the T006 fixed top/right margin coordinates.'

# The host itself remains source/resource-grounded: sibling of authored
# cyberwareContainer under Inventory, with live placement copied from the native widget.
Check ($followup.Contains('Equals(child.GetName(), n"cyberwareContainer")')) 'W17.1 authored content host resolution regressed.'
Check ($followup.Contains('target.Reparent(inventoryRoot, -1);')) 'Biology content is no longer a sibling under the Inventory lifecycle root.'
Check ($followup.Contains('target.SetMargin(contentHost.GetMargin());')) 'Biology content stopped deriving placement from live authored geometry.'
Check ($shell.Contains('this.crBiologyNativeContent.SetVisible(detail && detailLayoutReady);')) 'Preference parent is no longer bounded to valid Biology detail lifecycle.'

# Intentional subsection + usable local hit target.
Check ($preference.Contains('"PRESENTATION"')) 'Preference lacks an intentional Biology subsection heading.'
Check ($preference.Contains('"E3 HUD + NAMEPLATES"')) 'Preference label is incomplete.'
Check ($preference.Contains('this.crBiologyE3PreferenceValue.SetText(enabled ? "ON" : "OFF");')) 'Preference does not expose a clear current ON/OFF value.'
Check ($preference.Contains('row.SetSize(Vector2(680.0, 48.0));')) 'Preference does not provide the intended large local hit target.'
Check ($preference.Contains('row.SetInteractive(true);')) 'Preference hit target is not interactive.'
Check ($preference.Contains('row.RegisterToCallback(n"OnRelease", this, n"OnCRBiologyE3PreferenceToggle");')) 'Preference row does not own release interaction.'
Check ($preference.Contains('row.RegisterToCallback(n"OnHoverOver"') -and $preference.Contains('row.RegisterToCallback(n"OnHoverOut"')) 'Preference lacks hover affordance on its actual hit target.'

# Single authority + bounded lifecycle.
Check ($preference.Contains('CRRealpassSettings.UseE3FirstPersonHudVisuals(player.GetGame())')) 'Preference does not read the player-session saved authority.'
Check ($preference.Contains('CRRealpassSettings.ToggleE3FirstPersonHudVisuals(player.GetGame())')) 'Preference does not write through the player-session saved authority.'
Check ($preference.Contains('widget.SetInteractive(false);') -and $preference.Contains('background.SetInteractive(false);')) 'Decorative preference children can still steal pointer ownership from the row.'
Check (-not $preference.Contains('GetCurrentTarget() != this.crBiologyE3PreferenceRow')) 'T007 brittle current-target rejection returned.'
Check ($preference.Contains('"UNAVAILABLE"')) 'Preference hides a missing save-settings authority instead of failing visibly.'
Check ($preference.Contains('this.CRBiologyInDetail()')) 'Preference callback is not bounded to Biology detail ownership.'
Check ($shell.Contains('this.CRResetBiologyE3Preference();')) 'Shared Ripperdoc teardown does not clear preference widget references.'
Check (-not ($preference -match '(?i)ModSettings|ArchiveXL|RED4ext|Project E3')) 'W20.2 introduced a forbidden external runtime/settings dependency.'

Write-Host "PASS: $script:checks T006-F02 Biology E3 preference placement/lifecycle checks."
