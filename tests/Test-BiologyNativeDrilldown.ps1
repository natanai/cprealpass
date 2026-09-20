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
$actions = Text 'BiologyActionsNative.reds'

# The attended bug came from treating mode and detail as independent dimensions.
# They are now one explicit native-depth state machine: switching is overview-only.
Check ($shell.Contains('public final func CRBodyShellInDetail() -> Bool')) 'Shared detail-depth predicate is missing.'
Check ($shell.Contains('if this.CRBodyShellInDetail()')) 'Mode transition is not rejected while native/detail state is active.'
Check ($shell.Contains('this.crBiologyModeBar.SetVisible(!this.CRBodyShellInDetail())')) 'Mode selector is not overview-only.'
Check ($sync.Contains('@wrapMethod(RipperDocGameController)') -and $sync.Contains('private func DisplayInventory(visible: Bool) -> Void')) 'Native Cyberware drill-down does not gate the shared mode selector.'
Check ($sync.Contains('wrappedMethod(visible);')) 'Cyberware detail routing was replaced instead of wrapped.'

# Biology entry adopts the native Ripperdoc depth/focus grammar, not a second detail
# screen layered over the body.
foreach ($needle in @(
    'this.m_filterMode = RipperdocModes.Item;',
    'this.m_isInventoryOpen = true;',
    'this.DollHover(area);',
    'this.DollSelect(true);',
    'this.m_selector.CRSetBiologyDetailMode(true);',
    'this.m_selector.Show(this.EquipmentAreaToIndex(area));',
    'this.SetButtonHints(true, false);')) {
    Check ($shell.Contains($needle)) "Biology native drill-down entry contract missing: $needle"
}
Check ($shell.Contains('this.crBiologyNativeContent = new inkVerticalPanel();')) 'Biology detail content is not retained for live authored-host retry.'
Check ($shell.Contains('this.m_inventoryView.CRMountBiologyDetailInAuthoredContentHost(this.crBiologyNativeContent);')) 'Biology detail does not resolve the authored selected-content seam at detail depth.'
Check ($followup.Contains('Equals(child.GetName(), n"cyberwareContainer")')) 'Biology detail is not tied to the authored cyberwareContainer.'
Check ($followup.Contains('target.Reparent(inventoryRoot, -1);')) 'Biology detail is not mounted beside cyberwareContainer under the native Inventory lifecycle root.'
Check (-not $followup.Contains('inkVirtualCompoundRef.Get(this.m_virtualGridContainer)')) 'Biology detail still mounts relative to the virtualized item-list subtree.'
Check (-not $shell.Contains('crBiologyDetailBack')) 'Parallel Biology detail Back widget still exists.'

# Native selector owns left/right arrows and option-switch input. Biology changes names
# and skips only unsupported Cyberware-only categories.
Check ($sync.Contains('@wrapMethod(RipperdocSelectorController)')) 'Native Ripperdoc selector is not reused.'
Check ($sync.Contains('private func SwitchIndicator(toNext: Bool) -> Void')) 'Native left/right selector cycling is not wrapped.'
Check ($sync.Contains('wrappedMethod(toNext);')) 'Cyberware selector behavior is not preserved outside Biology.'
Check ($sync.Contains('this.m_names[0] = "HEAD / BRAIN";') -and $sync.Contains('this.m_names[9] = "LEGS";')) 'Biology selector labels are not applied to native selector names.'
Check (-not $sync.Contains('index == 3') -and -not $sync.Contains('index == 5')) 'Unsupported Eyes/Hands indices were accidentally added to Biology selector support.'
Check ($sync.Contains('new RipperdocSelectorChangeEvent()')) 'Biology cycling does not emit the native selector-change event.'
Check ($shell.Contains('this.m_animationController.StartSlide(evt.SlidingRight, area);')) 'Native body slide animation is not reused for Biology category cycling.'

# Back must consume Biology Item depth and reconstruct the overview without closing the
# entire pause/menu stack. Every relevant native depth marker is reset deterministically.
Check ($sync.Contains('protected cb func OnBack(userData: ref<IScriptable>) -> Bool')) 'Native Back seam is not wrapped.'
Check ($sync.Contains('if this.CRHandleBiologyBack()')) 'Biology detail does not consume native Back first.'
foreach ($needle in @(
    'this.m_filterMode = RipperdocModes.Default;',
    'this.m_isInventoryOpen = false;',
    'this.m_filterArea = gamedataEquipmentArea.Invalid;',
    'this.m_lastAreaVisited = gamedataEquipmentArea.Invalid;',
    'this.m_animationController.SetOutside();',
    'this.ClearMinigridSelection();',
    'this.ResetMinigridPositions();',
    'this.AnimateMinigrids();',
    'this.m_selector.CRSetBiologyDetailMode(false);')) {
    Check ($shell.Contains($needle)) "Biology Back/reset contract missing: $needle"
}

# Overview labels are explicitly suppressed during detail and restored on Back. This
# protects repeated overview -> detail -> Back cycles from accumulating stale state.
Check ($shell.Contains('this.CRSetBiologyOverviewNodesVisible(false);')) 'Overview labels are not removed entering detail.'
Check ($shell.Contains('this.CRSetCategoryMode(true);')) 'Overview Biology nodes are not rebuilt/restored on Back.'
Check ($shell.Contains('this.CRSyncBiologyNodeInteractivity(true);')) 'Overview Biology node interactivity is not restored on Back.'
Check ($shell.Contains('this.crBiologySelectedArea = gamedataEquipmentArea.Invalid;')) 'Selected Biology area is not cleared for repeated cycles.'

# Contextual content must remain transaction-backed and detail-scoped.
Check ($actions.Contains('if !this.crBiologyShellMode || !this.CRBiologyInDetail()')) 'Actions can still leak into overview.'
Check ($actions.Contains('GetItemList(player, items)') -and $actions.Contains('GetItemQuantity(player, itemID)')) 'Carried Biology items are not read from native inventory authority.'
Check ($actions.Contains('ItemActionsHelper.EatItem') -and $actions.Contains('ItemActionsHelper.DrinkItem')) 'Food/drink does not use native item actions.'
Check ($actions.Contains('CRBiologySessionAuthority.Body(player.GetGame())') -and $actions.Contains('runtime.UseFieldCare') -and $actions.Contains('CRProfessionalCareRuntime.CompleteForSession(player.GetGame()')) 'Treatment actions no longer use authoritative player-session care runtimes.'
Check (-not $actions.Contains('RemoveItem(')) 'Biology detail manually decrements inventory.'

# Stock Cyberware remains reachable/restorable rather than being replaced by Biology.
Check ($shell.Contains('this.CRSetCategoryMode(biology);')) 'Shared shell no longer restores stock Cyberware categories by mode.'
Check ($shell.Contains('inkWidgetRef.SetVisible(this.m_gridContainer, true);')) 'Cyberware stock equipment grids cannot be restored.'
Check ($sync.Contains('return wrappedMethod(evt);')) 'Native Cyberware selector-change behavior is not reachable outside Biology detail.'
Check ($sync.Contains('let result: Bool = wrappedMethod(userData);')) 'Native Cyberware Back behavior is not reachable outside Biology detail.'

Write-Host "PASS: $script:checks attended Biology drill-down state-machine checks."
