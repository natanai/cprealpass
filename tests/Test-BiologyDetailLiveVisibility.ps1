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

# T003: selected anatomy/native ARMS/Back survived, but all Biology detail content
# disappeared. The custom subtree must survive an initialization-time mount miss so
# detail entry can retry against the settled native hierarchy.
Check ($shell.Contains('this.crBiologyNativeContent = new inkVerticalPanel();')) 'W02.5 does not retain the Biology detail panel independently of initial native mount success.'
Check ($shell.Contains('this.crBiologyNativeContent.SetVisible(false);')) 'W02.5 retained detail panel is not initially fail-closed.'
Check ($shell.Contains('this.crBiologyNativeContent.SetAffectsLayoutWhenHidden(true);')) 'W02.5 hidden detail panel does not remain layout-participating while native layout settles.'
Check ($shell.Contains('this.m_inventoryView.CRMountBiologyDetailInAuthoredContentHost(this.crBiologyNativeContent);')) 'W02.5 does not perform/retry the native-region mount on the retained panel.'
Check (-not $shell.Contains('if this.m_inventoryView.CRMountBiologyDetailInAuthoredContentHost(nativeContent)')) 'W02.5 still discards the panel when the first mount attempt fails.'
Check ($shell.Contains('detailLayoutReady = this.CRSyncBiologyNativeContentLayout();')) 'W02.5 does not retry native layout at live detail depth.'
Check ($shell.Contains('this.crBiologyNativeContent.SetVisible(detail && detailLayoutReady);')) 'W02.5 no longer fails closed when live native-region resolution genuinely fails.'

# W17.1 proves Biology must suppress the authored cyberwareContainer as a unit rather
# than borrowing visibility/layout behavior from the virtualized item-list child.
Check ($followup.Contains('this.crBiologyContentHostWasVisible = contentHost.IsVisible();')) 'W17.1 does not capture stock content-host visibility.'
Check ($followup.Contains('contentHost.SetVisible(false);')) 'Biology detail does not suppress the authored Cyberware content host.'
Check ($followup.Contains('contentHost.SetVisible(this.crBiologyContentHostWasVisible);')) 'Biology does not restore the authored Cyberware content host exactly.'
Check ($followup.Contains('this.crBiologyContentHostVisibilityCaptured = false;')) 'Biology does not clear its bounded stock-visibility capture.'
Check (-not $followup.Contains('crBiologyVirtualGridLayoutPolicyCaptured')) 'Obsolete virtual-grid hidden-layout policy remains active.'
Check (-not $followup.Contains('inkVirtualCompoundRef.Get(this.m_virtualGridContainer)')) 'Biology still manipulates the virtualized item list as its presentation boundary.'

# The mount adapter must distinguish each live authored-host boundary and verify reparent.
foreach ($status in @('TARGET_MISSING','ROOT_MISSING','CONTENT_HOST_MISSING','CONTENT_HOST_TYPE_MISMATCH','REPARENT_UNCONFIRMED','CONTENT_HOST_MOUNTED')) {
    Check ($followup.Contains('"' + $status + '"')) "W17.1 mount trace is missing status: $status"
}
Check ($followup.Contains('private final func CRBiologyDirectParentOwnsWidget')) 'W17.1 does not verify the direct Inventory parent after reparent.'
Check ($followup.Contains('if !this.CRBiologyDirectParentOwnsWidget(inventoryRoot, target)')) 'W17.1 reports host mount success without verifying the target is attached.'
Check ($followup.Contains('public final func CRBiologyDetailMountStatus() -> String')) 'W17.1 does not expose the bounded live mount result to the shell.'

# T003 proved the stock selector remains visible even when Biology detail disappears.
# Use that existing native label as a bounded attended breadcrumb for BOTH successful
# and failed native mounts, so a blank MOUNTED screen proves the failure moved later.
Check ($sync.Contains('public final func CRSetBiologyLayoutDiagnostic(status: String) -> Void')) 'W02.5 lacks bounded native-selector mount diagnostics.'
Check ($sync.Contains('[BIOLOGY LAYOUT: ')) 'W02.5 failure diagnostic does not identify the Biology layout boundary.'
Check ($shell.Contains('this.m_selector.CRSetBiologyLayoutDiagnostic(this.CRBiologyDetailPostMountStatus(detailLayoutReady));')) 'W02.6 no longer surfaces the live mount result through the native selector breadcrumb.'
Check ($followup.Contains('this.crBiologyDetailMountStatus = "CONTENT_HOST_MOUNTED";')) 'W17.1 positive authored-host mount state is missing.'
Check (-not $sync.Contains('Equals(status, "CONTENT_HOST_MOUNTED")')) 'The selector suppresses successful authored-host evidence instead of exposing the breadcrumb.'
Check ($shell.Contains('return "INVENTORY_MISSING " + this.crBiologyDetailContentStatus;')) 'The attended breadcrumb can no longer distinguish a missing inventory controller from post-mount state.'

# Preserve the actual selected-system/runtime path and native navigation. Invisible UI
# must not be misdiagnosed as body-runtime failure or repaired with fake data.
Check ($shell.Contains('CRBiologySessionPresentation.Detail(player.GetGame(), this.crBiologySelectedArea)')) 'W02.5 disturbed authoritative selected-system detail binding.'
Check ($shell.Contains('this.DollHover(area);') -and $shell.Contains('this.DollSelect(true);')) 'W02.5 disturbed native anatomy focus/selection.'
Check ($sync.Contains('if this.CRHandleBiologyBack()')) 'W02.5 disturbed native Back routing.'
Check ($followup.Contains('CRSetBiologyDetailSurface(false);') -and $followup.Contains('this.DisplayInventory(false);')) 'W02.5 disturbed native detail restoration.'
Check ($shell.Contains('inkWidgetRef.SetVisible(this.m_gridContainer, true);')) 'W02.5 disturbed ordinary Cyberware restoration.'
Check (-not $followup.Contains('CRBodyRuntime')) 'W02.5 presentation repair broadened into body-runtime authority.'

# No return to the arbitrary screen-space offsets disproved by T002.
Check (-not $shell.Contains('this.crBiologyNativeContent.SetAnchor(inkEAnchor.TopLeft);')) 'W02.5 reintroduced a screen-origin TopLeft fallback.'
Check (-not $shell.Contains('this.crBiologyNativeContent.SetMargin(inkMargin(0.0, 42.0, 0.0, 0.0));')) 'W02.5 reintroduced the old arbitrary root-relative margin.'
Check (-not $shell.Contains('this.crBiologyNativeContent.SetSize(Vector2(720.0, 0.0));')) 'W02.5 reintroduced the old fixed detail width.'
Check ($followup.Contains('target.SetMargin(contentHost.GetMargin());') -and $followup.Contains('target.SetTranslation(contentHost.GetTranslation());')) 'W17.1 no longer derives placement from the live authored content host.'

Write-Host "PASS: $script:checks W17.1 live authored-host visibility checks."
