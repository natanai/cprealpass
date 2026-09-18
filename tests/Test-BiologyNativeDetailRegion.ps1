$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\tools\Common.ps1"
$project = Get-ProjectRoot
$source = Join-Path $project 'src\redscript\CyberpunkRealism'
$script:checks = 0
function Check($condition,[string]$message) { if (-not $condition) { throw $message }; $script:checks++ }
function Text([string]$name) { return Get-Content -Raw -LiteralPath (Join-Path $source $name) }

$shell = Text 'BiologyCyberwareShell.reds'
$followup = Text 'BiologyLiveShellFollowupNative.reds'
$sync = Text 'BiologyModeSyncNative.reds'

# T002 disproved the W02.3 assumption that RipperdocInventoryController's root owns
# authored content placement. The stock item region is the editable virtual-grid child.
Check ($followup.Contains('inkVirtualCompoundRef.Get(this.m_virtualGridContainer)')) 'W02.4 does not resolve the native Cyberware item-region widget.'
Check ($followup.Contains('public final func CRApplyBiologyDetailRegionLayout(target: ref<inkWidget>) -> Bool')) 'W02.4 native detail-region layout adapter is missing.'

# Biology placement must be copied from native authored geometry, not reconstructed
# from a new absolute screen offset. Cover every layout property that can materially
# move/size the panel inside the native controller root.
foreach ($needle in @(
    'target.SetAnchor(nativeRegion.GetAnchor());',
    'target.SetAnchorPoint(nativeRegion.GetAnchorPoint());',
    'target.SetHAlign(nativeRegion.GetHAlign());',
    'target.SetVAlign(nativeRegion.GetVAlign());',
    'target.SetMargin(nativeRegion.GetMargin());',
    'target.SetPadding(nativeRegion.GetPadding());',
    'target.SetSizeRule(nativeRegion.GetSizeRule());',
    'target.SetSizeCoefficient(nativeRegion.GetSizeCoefficient());',
    'target.SetSize(nativeRegion.GetSize());',
    'target.SetTranslation(nativeRegion.GetTranslation());')) {
    Check ($followup.Contains($needle)) "Native detail-region geometry copy missing: $needle"
}

Check (-not $shell.Contains('this.crBiologyNativeContent.SetAnchor(inkEAnchor.TopLeft);')) 'Biology detail still forces the screen-origin TopLeft anchor.'
Check (-not $shell.Contains('this.crBiologyNativeContent.SetMargin(inkMargin(0.0, 42.0, 0.0, 0.0));')) 'Biology detail still carries the disproven W02.3 fixed top-left margin.'
Check (-not $shell.Contains('this.crBiologyNativeContent.SetSize(Vector2(720.0, 0.0));')) 'Biology detail still overrides the native content-region size with the W02.3 fixed width.'

# Keep native controller-root lifecycle/opacity while using the child as geometry donor.
Check ($shell.Contains('nativeContentParent = this.m_inventoryView.GetRootWidget() as inkCompoundWidget;')) 'Biology no longer participates in the native inventory controller visibility lifecycle.'
Check ($shell.Contains('this.crBiologyNativeContent.Reparent(nativeContentParent, -1);')) 'Biology detail is not kept under the native inventory controller root.'
Check ($shell.Contains('this.m_inventoryView.CRApplyBiologyDetailRegionLayout(this.crBiologyNativeContent);')) 'Biology does not apply native child geometry after mounting.'

# Re-read geometry at detail depth. If the native child cannot be resolved, fail closed
# instead of making the telemetry visible at root/screen origin.
Check ($shell.Contains('private final func CRSyncBiologyNativeContentLayout() -> Bool')) 'Biology lacks a detail-time native geometry refresh.'
Check ($shell.Contains('let detailLayoutReady: Bool = !detail || this.CRSyncBiologyNativeContentLayout();')) 'Biology detail visibility is not gated on native geometry resolution.'
Check ($shell.Contains('this.crBiologyNativeContent.SetVisible(detail && detailLayoutReady);')) 'Biology can still display detail when native layout resolution fails.'

# Preserve W02.2 selected-system identity, native focus, Back, and stock Cyberware.
Check ($shell.Contains('this.crBiologySelectedArea = area;') -and $shell.Contains('this.m_filterArea = area;')) 'W02.4 disturbed selected-system identity.'
Check ($followup.Contains('Equals(area, this.crBiologySelectedArea)') -and $followup.Contains('this.DisplayInventory(true);')) 'W02.4 disturbed correct-anatomy native detail entry.'
Check ($shell.Contains('CRBiologySessionPresentation.Detail(player.GetGame(), this.crBiologySelectedArea)')) 'W02.4 disturbed authoritative detail binding.'
Check ($sync.Contains('if this.CRHandleBiologyBack()')) 'W02.4 disturbed native Back routing.'
Check ($followup.Contains('CRSetBiologyDetailSurface(false);') -and $followup.Contains('this.DisplayInventory(false);')) 'W02.4 disturbed native detail close/restoration.'
Check ($shell.Contains('inkWidgetRef.SetVisible(this.m_gridContainer, true);')) 'W02.4 disturbed stock Cyberware restoration.'
Check (-not $followup.Contains('CRBodyRuntime')) 'W02.4 layout adapter absorbed runtime authority.'

Write-Host "PASS: $script:checks W02.4 native-detail-region geometry checks."
