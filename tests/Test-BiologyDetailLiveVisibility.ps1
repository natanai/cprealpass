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
Check ($shell.Contains('this.m_inventoryView.CRMountBiologyDetailInNativeRegion(this.crBiologyNativeContent);')) 'W02.5 does not perform/retry the native-region mount on the retained panel.'
Check (-not $shell.Contains('if this.m_inventoryView.CRMountBiologyDetailInNativeRegion(nativeContent)')) 'W02.5 still discards the panel when the first mount attempt fails.'
Check ($shell.Contains('detailLayoutReady = this.CRSyncBiologyNativeContentLayout();')) 'W02.5 does not retry native layout at live detail depth.'
Check ($shell.Contains('this.crBiologyNativeContent.SetVisible(detail && detailLayoutReady);')) 'W02.5 no longer fails closed when live native-region resolution genuinely fails.'

# W02.4 hides the Cyberware virtual grid while Biology telemetry occupies the same
# region. Hidden native geometry must continue participating in layout during Biology
# detail and its stock policy must be restored on exit.
Check ($followup.Contains('this.crBiologyVirtualGridAffectsLayoutWhenHidden = virtualGrid.GetAffectsLayoutWhenHidden();')) 'W02.5 does not capture the stock virtual-grid hidden-layout policy.'
Check ($followup.Contains('virtualGrid.SetAffectsLayoutWhenHidden(true);')) 'W02.5 can still collapse the native geometry donor when hiding Cyberware content.'
Check ($followup.Contains('virtualGrid.SetVisible(false);')) 'Biology detail no longer suppresses the stock Cyberware item grid.'
Check ($followup.Contains('virtualGrid.SetAffectsLayoutWhenHidden(this.crBiologyVirtualGridAffectsLayoutWhenHidden);')) 'W02.5 does not restore the stock virtual-grid layout policy.'
Check ($followup.Contains('this.crBiologyVirtualGridLayoutPolicyCaptured = false;')) 'W02.5 does not clear the temporary native-grid policy capture after restoration.'

# The mount adapter must distinguish each live boundary and verify the reparent itself.
foreach ($status in @('TARGET_MISSING','GRID_MISSING','ROOT_MISSING','PARENT_MISSING','REPARENT_UNCONFIRMED','MOUNTED')) {
    Check ($followup.Contains('"' + $status + '"')) "W02.5 mount trace is missing status: $status"
}
Check ($followup.Contains('private final func CRBiologyDirectParentOwnsWidget')) 'W02.5 does not verify the direct native parent after reparent.'
Check ($followup.Contains('if !this.CRBiologyDirectParentOwnsWidget(nativeParent, target)')) 'W02.5 reports mount success without verifying the target is actually attached.'
Check ($followup.Contains('public final func CRBiologyDetailMountStatus() -> String')) 'W02.5 does not expose the bounded live mount result to the shell.'

# T003 proved the stock selector remains visible even when Biology detail disappears.
# Use that existing native label as a bounded attended breadcrumb for BOTH successful
# and failed native mounts, so a blank MOUNTED screen proves the failure moved later.
Check ($sync.Contains('public final func CRSetBiologyLayoutDiagnostic(status: String) -> Void')) 'W02.5 lacks bounded native-selector mount diagnostics.'
Check ($sync.Contains('[BIOLOGY LAYOUT: ')) 'W02.5 failure diagnostic does not identify the Biology layout boundary.'
Check ($shell.Contains('this.m_selector.CRSetBiologyLayoutDiagnostic(this.m_inventoryView.CRBiologyDetailMountStatus());')) 'W02.5 does not surface the exact live inventory mount result in attended UI evidence.'
Check ($sync.Contains('INCLUDING') -and $sync.Contains('MOUNTED')) 'W02.5 does not preserve positive MOUNTED evidence for a still-blank attended detail screen.'
Check (-not $sync.Contains('Equals(status, "MOUNTED")')) 'W02.5 still hides the successful MOUNTED breadcrumb instead of distinguishing post-mount failures.'
Check ($shell.Contains('this.m_selector.CRSetBiologyLayoutDiagnostic("INVENTORY_MISSING");')) 'W02.5 cannot distinguish a missing inventory controller from deeper mount failures.'

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
Check ($followup.Contains('target.SetMargin(nativeRegion.GetMargin());') -and $followup.Contains('target.SetTranslation(nativeRegion.GetTranslation());')) 'W02.5 no longer derives placement from live native geometry.'

Write-Host "PASS: $script:checks W02.5 live detail visibility/native-region checks."
