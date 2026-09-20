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

$probe = Get-Content -Raw -LiteralPath (Join-Path $project 'tools\Probe-BiologyDetailNativeRegion.ps1')

# T002 and the attended local probes disproved a guessed static INK path. Discover the
# installed 2.31 resource and identify it by its native controller/widget-ref contract.
Check ($probe.Contains("Get-ChildItem -LiteralPath `$archiveRoot -Recurse -File -Filter '*.archive'")) 'W02.4 probe does not enumerate installed archives recursively.'
Check ($probe.Contains("`$candidateRegex = '(?i)\.inkwidget$'")) 'W02.4 probe does not discover installed INK resources generically.'
Check ($probe.Contains('Sort-Object Priority, Path, RelativeArchive')) 'W02.4 probe does not prioritize likely Ripperdoc/Cyberware/fullscreen candidates.'
Check ($probe.Contains("'RipperDocGameController'")) 'W02.4 probe does not identify the live target by RipperDocGameController.'
Check ($probe.Contains("'RipperdocInventoryController'")) 'W02.4 probe does not identify the live target by RipperdocInventoryController.'
Check ($probe.Contains("'inventoryViewAnchor'")) 'W02.4 probe does not require the native inventory anchor contract.'
Check ($probe.Contains("'virtualGridContainer'")) 'W02.4 probe does not require the native virtual-grid contract.'
Check ($probe.Contains('TARGET_RESOURCE_DISCOVERED=')) 'W02.4 probe does not report the discovered live target resource.'
Check (-not $probe.Contains("`$targetResource = 'gameplay\gui\fullscreen\ripperdoc\ripperdoc.inkwidget'")) 'W02.4 probe still hard-codes the disproven legacy Ripperdoc resource path.'
Check (-not $probe.Contains("`$targetResourceHash = '13533725445430520621'")) 'W02.4 probe still hard-codes the disproven legacy Ripperdoc resource hash.'
Check (-not $probe.Contains("`$cli,'archive',`$archiveRoot,'--list'")) 'W02.4 probe still passes the non-recursive archive root to WolvenKit archive.'
Check (-not $probe.Contains("`$cli,'unbundle',`$archiveRoot")) 'W02.4 probe still passes the non-recursive archive root to WolvenKit unbundle.'

# Current 2.31 archaeology resolves the authored selected-content hierarchy:
# Inventory -> cyberwareContainer -> GridAndSlider -> grid -> scrollRect ->
# virtualGridContainer. Biology must bind to the direct cyberwareContainer seam and
# must not treat the scrolling virtual-grid subtree as a generic content host.
Check ($followup.Contains('private final func CRFindBiologyAuthoredContentHost(inventoryRoot: ref<inkCompoundWidget>) -> ref<inkWidget>')) 'W17.1 authored content-host resolver is missing.'
Check ($followup.Contains('Equals(child.GetName(), n"cyberwareContainer")')) 'W17.1 does not resolve the exact authored cyberwareContainer by name.'
Check ($followup.Contains('let contentPanel: ref<inkVerticalPanel> = contentHost as inkVerticalPanel;')) 'W17.1 does not verify the authored content host is the expected vertical-panel layout family.'
Check ($followup.Contains('public final func CRMountBiologyDetailInAuthoredContentHost(target: ref<inkWidget>) -> Bool')) 'W17.1 authored content-host mount adapter is missing.'
Check ($followup.Contains('target.Reparent(inventoryRoot, -1);')) 'Biology detail is not mounted as a sibling of cyberwareContainer under the Inventory lifecycle root.'
Check ($followup.Contains('this.crBiologyDetailNativeRegion = contentHost;')) 'W17.1 diagnostics do not retain the authored content-host identity.'
Check ($followup.Contains('this.crBiologyDetailMountStatus = "CONTENT_HOST_MOUNTED";')) 'W17.1 does not expose positive authored-host mount evidence.'
Check (-not $followup.Contains('CRFindBiologyDetailRegionParent')) 'Obsolete virtual-grid parent discovery still exists.'
Check (-not $followup.Contains('inkVirtualCompoundRef.Get(this.m_virtualGridContainer)')) 'Biology still treats the virtualized item-list child as a layout authority.'

# Placement is copied from the live authored cyberwareContainer, not reconstructed from
# its known 800/300 resource margins and not inferred from screenshots.
foreach ($needle in @(
    'target.SetAnchor(contentHost.GetAnchor());',
    'target.SetAnchorPoint(contentHost.GetAnchorPoint());',
    'target.SetHAlign(contentHost.GetHAlign());',
    'target.SetVAlign(contentHost.GetVAlign());',
    'target.SetMargin(contentHost.GetMargin());',
    'target.SetPadding(contentHost.GetPadding());',
    'target.SetTranslation(contentHost.GetTranslation());')) {
    Check ($followup.Contains($needle)) "Authored content-host positioning copy missing: $needle"
}
Check ($followup.Contains('target.SetFitToContent(true);')) 'Biology detail panel does not size from its real content.'
Check (-not $followup.Contains('inkMargin(800.0, 300.0')) 'W17.1 hard-codes serialized native margins instead of reading live authored geometry.'
Check (-not $shell.Contains('this.crBiologyNativeContent.SetAnchor(inkEAnchor.TopLeft);')) 'Biology detail forces a screen-origin TopLeft fallback.'
Check (-not $shell.Contains('this.crBiologyNativeContent.SetMargin(inkMargin(0.0, 42.0, 0.0, 0.0));')) 'Biology detail carries the disproven W02.3 fixed top-left margin.'
Check (-not $shell.Contains('this.crBiologyNativeContent.SetSize(Vector2(720.0, 0.0));')) 'Biology detail still overrides the authored content region with the old fixed width.'

# The stock content subtree is hidden/restored as one authored unit while Inventory
# remains the native show/hide/opacity authority.
Check ($followup.Contains('this.crBiologyContentHostWasVisible = contentHost.IsVisible();')) 'W17.1 does not capture stock cyberwareContainer visibility.'
Check ($followup.Contains('contentHost.SetVisible(false);')) 'W17.1 does not suppress stock cyberwareContainer during Biology detail.'
Check ($followup.Contains('contentHost.SetVisible(this.crBiologyContentHostWasVisible);')) 'W17.1 does not restore stock cyberwareContainer exactly.'
Check ($shell.Contains('this.m_inventoryView.CRMountBiologyDetailInAuthoredContentHost(this.crBiologyNativeContent);')) 'Biology detail-time sync does not revalidate the authored host.'
Check ($shell.Contains('detailLayoutReady = this.CRSyncBiologyNativeContentLayout();')) 'Biology detail visibility is not gated on live authored-host resolution.'
Check ($shell.Contains('this.crBiologyNativeContent.SetVisible(detail && detailLayoutReady);')) 'Biology can display when authored-host resolution fails.'

# Preserve selected-system identity, native anatomy focus, Back, and ordinary Cyberware.
Check ($shell.Contains('this.crBiologySelectedArea = area;') -and $shell.Contains('this.m_filterArea = area;')) 'W17.1 disturbed selected-system identity.'
Check ($followup.Contains('Equals(area, this.crBiologySelectedArea)') -and $followup.Contains('this.DisplayInventory(true);')) 'W17.1 disturbed correct-anatomy native detail entry.'
Check ($shell.Contains('CRBiologySessionPresentation.Detail(player.GetGame(), this.crBiologySelectedArea)')) 'W17.1 disturbed authoritative detail binding.'
Check ($sync.Contains('if this.CRHandleBiologyBack()')) 'W17.1 disturbed native Back routing.'
Check ($followup.Contains('CRSetBiologyDetailSurface(false);') -and $followup.Contains('this.DisplayInventory(false);')) 'W17.1 disturbed native detail close/restoration.'
Check ($shell.Contains('inkWidgetRef.SetVisible(this.m_gridContainer, true);')) 'W17.1 disturbed stock Cyberware restoration.'
Check (-not $followup.Contains('CRBodyRuntime')) 'W17.1 layout adapter absorbed body-runtime authority.'

Write-Host "PASS: $script:checks W17.1 authored Biology detail-region checks."
