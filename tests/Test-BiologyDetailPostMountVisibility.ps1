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

# T004 proved the old W17.1 reparent could succeed live, but W17.1 proves that seam
# lived inside the inventory scroll/grid subtree. Positive mount evidence must now name
# the authored cyberwareContainer seam under the native Inventory lifecycle root.
Check ($followup.Contains('this.crBiologyDetailMountStatus = "CONTENT_HOST_MOUNTED";')) 'W17.1 lacks positive authored content-host mount evidence.'
Check ($shell.Contains('this.m_selector.CRSetBiologyLayoutDiagnostic(this.CRBiologyDetailPostMountStatus(detailLayoutReady));')) 'W17.1 does not expose post-mount state through the T004-proven native selector surface.'
Check ($sync.Contains('[BIOLOGY LAYOUT: ')) 'W17.1 removed the attended Biology layout breadcrumb before visual acceptance.'

# Biology now matches the authored content container's layout family rather than the
# virtualized grid. Copy live cyberwareContainer placement only; Biology remains
# fit-to-content so it owns the extent of its actual telemetry/actions.
Check ($shell.Contains('this.crBiologyNativeContent.SetFitToContent(true);')) 'Biology detail panel is not content-sized at creation.'
Check ($followup.Contains('let contentPanel: ref<inkVerticalPanel> = contentHost as inkVerticalPanel;')) 'W17.1 does not verify same-family vertical-panel host semantics.'
Check ($followup.Contains('target.SetFitToContent(true);')) 'Biology detail panel is not content-sized after authored-host synchronization.'
Check ($followup.Contains('target.SetOpacity(1.0);')) 'Biology-owned panel opacity is not normalized after mount.'
foreach ($needle in @(
    'target.SetAnchor(contentHost.GetAnchor());',
    'target.SetAnchorPoint(contentHost.GetAnchorPoint());',
    'target.SetHAlign(contentHost.GetHAlign());',
    'target.SetVAlign(contentHost.GetVAlign());',
    'target.SetMargin(contentHost.GetMargin());',
    'target.SetPadding(contentHost.GetPadding());',
    'target.SetTranslation(contentHost.GetTranslation());')) {
    Check ($followup.Contains($needle)) "W17.1 stopped using authored content-host geometry: $needle"
}
Check (-not $followup.Contains('inkVirtualCompoundRef.Get(this.m_virtualGridContainer)')) 'W17.1 still treats the virtualized item-list child as a layout authority.'
Check (-not $followup.Contains('inkMargin(800.0, 300.0')) 'W17.1 hard-codes serialized native offsets instead of reading live authored geometry.'

# Bounded post-mount evidence must distinguish effective geometry/opacity/order rather
# than sending the next attended session back through mount discovery.
Check ($followup.Contains('public final func CRBiologyDetailPostMountStatus(target: ref<inkWidget>) -> String')) 'W17.1 post-mount inventory snapshot is missing.'
Check ($followup.Contains('inventoryRoot.GetOpacity()')) 'W17.1 does not report the native inventory-root opacity that can hide all descendants.'
Check ($followup.Contains('target.IsVisible()')) 'W17.1 does not report Biology panel visibility.'
Check ($followup.Contains('target.GetOpacity()')) 'W17.1 does not report Biology panel opacity.'
Check ($followup.Contains('target.GetDesiredSize()')) 'W17.1 does not report Biology desired size.'
Check ($followup.Contains('target.GetSize()')) 'W17.1 does not report Biology stored size.'
Check ($followup.Contains('target.GetSizeRule()')) 'W17.1 does not report Biology size-rule state.'
Check ($followup.Contains('target.GetSizeCoefficient()')) 'W17.1 does not report Biology size coefficient.'
Check ($followup.Contains('targetCompound.GetNumChildren()')) 'W17.1 does not report Biology child count.'
Check ($followup.Contains('nativeParent.GetChildSize(target)')) 'W17.1 does not report the native parent assigned size for Biology.'
Check ($followup.Contains('nativeParent.GetDesiredSize()')) 'W17.1 does not report native parent effective/desired size.'
Check ($followup.Contains('nativeParent.GetChildPosition(target)')) 'W17.1 does not report Biology position within the native parent for clipping diagnosis.'
Check ($followup.Contains('this.CRBiologyChildIndex(nativeParent, target)')) 'W17.1 does not report Biology sibling index.'
Check ($followup.Contains('this.CRBiologyChildIndex(nativeParent, nativeRegion)')) 'W17.1 does not report the authored stock content-host sibling index for covering/order diagnosis.'
Check ($followup.Contains('nativeParent.GetChildOrder()')) 'W17.1 does not report native child ordering direction.'
Check ($followup.Contains('let layoutMatch: Bool = Equals(target.GetAnchor(), nativeRegion.GetAnchor())')) 'W17.1 does not report whether authored host anchor/alignment/margin/translation survived post-mount.'
Check ($followup.Contains('targetMargin.left == nativeMargin.left') -and $followup.Contains('targetTranslation.X == nativeTranslation.X')) 'W17.1 authored-layout match omits margin/translation evidence.'

# Prove the presentation path itself populated content rather than inferring from an
# invisible screen. The status is set at the exact authoritative detail projection.
Check ($shell.Contains('this.crBiologyDetailContentStatus = "PLAYER_ERROR";')) 'W17.1 cannot distinguish a player/runtime error from post-mount visibility.'
Check ($shell.Contains('this.crBiologyDetailContentStatus = "DETAIL_ERROR";')) 'W17.1 cannot distinguish invalid detail projection from post-mount visibility.'
Check ($shell.Contains('this.crBiologyDetailContentStatus = "DATA" + IntToString(i);')) 'W17.1 does not prove how many authoritative metric rows were populated.'
Check ($shell.Contains('this.crBiologyDetailTitle.GetDesiredSize()')) 'W17.1 does not report representative title effective size.'
Check ($shell.Contains('this.crBiologyDetailTitle.IsVisible()')) 'W17.1 does not report representative title visibility.'
Check ($shell.Contains('this.crBiologyMetricRows[0].GetDesiredSize()')) 'W17.1 does not report representative metric-row effective size.'
Check ($shell.Contains('this.crBiologyMetricRows[0].IsVisible()')) 'W17.1 does not report representative metric-row visibility.'

# Do not mask a native lifecycle bug by forcing the stock inventory controller opaque.
# DisplayInventory/ShowArea/Hide remains the native opacity authority.
Check (-not $followup.Contains('this.GetRootWidget().SetOpacity(1.0);')) 'W17.1 forces the native inventory controller opaque instead of preserving its lifecycle.'
Check ($followup.Contains('this.DisplayInventory(true);')) 'W17.1 no longer reuses native inventory show/opacity lifecycle entering Biology detail.'
Check ($followup.Contains('this.DisplayInventory(false);')) 'W17.1 no longer reuses native inventory hide/opacity lifecycle leaving Biology detail.'
Check ($followup.Contains('contentHost.SetVisible(false);')) 'W17.1 does not hide the authored Cyberware content container during Biology detail.'
Check ($followup.Contains('contentHost.SetVisible(this.crBiologyContentHostWasVisible);')) 'W17.1 does not restore the authored Cyberware content container on exit.'

# Preserve the T002/T003 invariants and do not escape through absolute coordinates.
Check (-not $shell.Contains('this.crBiologyNativeContent.SetAnchor(inkEAnchor.TopLeft);')) 'W17.1 reintroduced a screen-origin TopLeft fallback.'
Check (-not $shell.Contains('this.crBiologyNativeContent.SetMargin(inkMargin(0.0, 42.0, 0.0, 0.0));')) 'W17.1 reintroduced the old arbitrary root-relative offset.'
Check (-not $shell.Contains('this.crBiologyNativeContent.SetSize(Vector2(720.0, 0.0));')) 'W17.1 reintroduced the old arbitrary detail extent.'
Check ($shell.Contains('CRBiologySessionPresentation.Detail(player.GetGame(), this.crBiologySelectedArea)')) 'W17.1 disturbed authoritative selected-system detail binding.'
Check ($sync.Contains('if this.CRHandleBiologyBack()')) 'W17.1 disturbed native Back routing.'
Check ($shell.Contains('inkWidgetRef.SetVisible(this.m_gridContainer, true);')) 'W17.1 disturbed ordinary Cyberware restoration.'
Check (-not $followup.Contains('CRBodyRuntime')) 'W17.1 post-mount presentation work broadened into body-runtime authority.'

Write-Host "PASS: $script:checks W17.1 authored-host post-mount Biology detail visibility checks."
