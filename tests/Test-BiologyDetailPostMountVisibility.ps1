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

# T004 is conclusive for this lane: native resolution/reparent reached MOUNTED live.
# W02.6 must diagnose/repair only what happens after that successful mount.
Check ($followup.Contains('this.crBiologyDetailMountStatus = "MOUNTED";')) 'W02.6 lost the T004-proven positive mount boundary.'
Check ($shell.Contains('this.m_selector.CRSetBiologyLayoutDiagnostic(this.CRBiologyDetailPostMountStatus(detailLayoutReady));')) 'W02.6 does not expose post-mount state through the T004-proven native selector surface.'
Check ($sync.Contains('[BIOLOGY LAYOUT: ')) 'W02.6 removed the attended Biology layout breadcrumb before visual acceptance.'

# A virtualized grid and a normal vertical panel do not share content-sizing semantics.
# Preserve native positioning but let Biology size from its actual children.
Check ($shell.Contains('this.crBiologyNativeContent.SetFitToContent(true);')) 'Biology detail panel is not content-sized at creation.'
Check ($followup.Contains('target.SetFitToContent(true);')) 'Biology detail panel is not content-sized after live native-region synchronization.'
Check ($followup.Contains('target.SetOpacity(1.0);')) 'Biology-owned panel opacity is not normalized after mount.'
Check (-not $followup.Contains('target.SetSizeRule(nativeRegion.GetSizeRule());')) 'W02.6 still copies the virtual grid size rule onto Biology.'
Check (-not $followup.Contains('target.SetSizeCoefficient(nativeRegion.GetSizeCoefficient());')) 'W02.6 still copies the virtual grid size coefficient onto Biology.'
Check (-not $followup.Contains('target.SetSize(nativeRegion.GetSize());')) 'W02.6 still copies the virtual grid fixed extent onto Biology.'
foreach ($needle in @(
    'target.SetAnchor(nativeRegion.GetAnchor());',
    'target.SetAnchorPoint(nativeRegion.GetAnchorPoint());',
    'target.SetHAlign(nativeRegion.GetHAlign());',
    'target.SetVAlign(nativeRegion.GetVAlign());',
    'target.SetMargin(nativeRegion.GetMargin());',
    'target.SetPadding(nativeRegion.GetPadding());',
    'target.SetTranslation(nativeRegion.GetTranslation());')) {
    Check ($followup.Contains($needle)) "W02.6 stopped using native positioning geometry: $needle"
}

# Bounded post-mount evidence must distinguish effective geometry/opacity/order rather
# than sending the next attended session back through mount discovery.
Check ($followup.Contains('public final func CRBiologyDetailPostMountStatus(target: ref<inkWidget>) -> String')) 'W02.6 post-mount inventory snapshot is missing.'
Check ($followup.Contains('inventoryRoot.GetOpacity()')) 'W02.6 does not report the native inventory-root opacity that can hide all descendants.'
Check ($followup.Contains('target.IsVisible()')) 'W02.6 does not report Biology panel visibility.'
Check ($followup.Contains('target.GetOpacity()')) 'W02.6 does not report Biology panel opacity.'
Check ($followup.Contains('target.GetDesiredSize()')) 'W02.6 does not report Biology desired size.'
Check ($followup.Contains('nativeParent.GetChildSize(target)')) 'W02.6 does not report the native parent assigned size for Biology.'
Check ($followup.Contains('nativeParent.GetDesiredSize()')) 'W02.6 does not report native parent effective/desired size.'
Check ($followup.Contains('nativeParent.GetChildPosition(target)')) 'W02.6 does not report Biology position within the native parent for clipping diagnosis.'
Check ($followup.Contains('this.CRBiologyChildIndex(nativeParent, target)')) 'W02.6 does not report Biology sibling index.'
Check ($followup.Contains('this.CRBiologyChildIndex(nativeParent, nativeRegion)')) 'W02.6 does not report the native grid sibling index for covering/order diagnosis.'
Check ($followup.Contains('nativeParent.GetChildOrder()')) 'W02.6 does not report native child ordering direction.'

# Prove the presentation path itself populated content rather than inferring from an
# invisible screen. The status is set at the exact authoritative detail projection.
Check ($shell.Contains('this.crBiologyDetailContentStatus = "PLAYER_ERROR";')) 'W02.6 cannot distinguish a player/runtime error from post-mount visibility.'
Check ($shell.Contains('this.crBiologyDetailContentStatus = "DETAIL_ERROR";')) 'W02.6 cannot distinguish invalid detail projection from post-mount visibility.'
Check ($shell.Contains('this.crBiologyDetailContentStatus = "DATA" + IntToString(i);')) 'W02.6 does not prove how many authoritative metric rows were populated.'
Check ($shell.Contains('this.crBiologyDetailTitle.GetDesiredSize()')) 'W02.6 does not report representative title effective size.'
Check ($shell.Contains('this.crBiologyDetailTitle.IsVisible()')) 'W02.6 does not report representative title visibility.'
Check ($shell.Contains('this.crBiologyMetricRows[0].GetDesiredSize()')) 'W02.6 does not report representative metric-row effective size.'
Check ($shell.Contains('this.crBiologyMetricRows[0].IsVisible()')) 'W02.6 does not report representative metric-row visibility.'

# Do not mask a native lifecycle bug by forcing the stock inventory controller opaque.
# DisplayInventory/ShowArea/Hide remains the native opacity authority.
Check (-not $followup.Contains('this.GetRootWidget().SetOpacity(1.0);')) 'W02.6 forces the native inventory controller opaque instead of diagnosing its lifecycle.'
Check ($followup.Contains('this.DisplayInventory(true);')) 'W02.6 no longer reuses native inventory show/opacity lifecycle entering Biology detail.'
Check ($followup.Contains('this.DisplayInventory(false);')) 'W02.6 no longer reuses native inventory hide/opacity lifecycle leaving Biology detail.'

# Preserve the T002/T003 invariants and do not escape through absolute coordinates.
Check (-not $shell.Contains('this.crBiologyNativeContent.SetAnchor(inkEAnchor.TopLeft);')) 'W02.6 reintroduced a screen-origin TopLeft fallback.'
Check (-not $shell.Contains('this.crBiologyNativeContent.SetMargin(inkMargin(0.0, 42.0, 0.0, 0.0));')) 'W02.6 reintroduced the old arbitrary root-relative offset.'
Check (-not $shell.Contains('this.crBiologyNativeContent.SetSize(Vector2(720.0, 0.0));')) 'W02.6 reintroduced the old arbitrary detail extent.'
Check ($shell.Contains('CRBiologySessionPresentation.Detail(player.GetGame(), this.crBiologySelectedArea)')) 'W02.6 disturbed authoritative selected-system detail binding.'
Check ($sync.Contains('if this.CRHandleBiologyBack()')) 'W02.6 disturbed native Back routing.'
Check ($shell.Contains('inkWidgetRef.SetVisible(this.m_gridContainer, true);')) 'W02.6 disturbed ordinary Cyberware restoration.'
Check (-not $followup.Contains('CRBodyRuntime')) 'W02.6 post-mount presentation work broadened into body-runtime authority.'

Write-Host "PASS: $script:checks W02.6 post-mount Biology detail visibility checks."
