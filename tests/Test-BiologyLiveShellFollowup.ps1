$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\tools\Common.ps1"
$project = Get-ProjectRoot
$source = Join-Path $project 'src\redscript\CyberpunkRealism'
$script:checks = 0
function Check($condition,[string]$message) { if (-not $condition) { throw $message }; $script:checks++ }
function Text([string]$name) { return Get-Content -Raw -LiteralPath (Join-Path $source $name) }

$followup = Text 'BiologyLiveShellFollowupNative.reds'
$shell = Text 'BiologyCyberwareShell.reds'
$detail = Text 'BiologySessionPresentation.reds'

# First-open entry is not allowed until the stock asynchronous Ripperdoc shell has
# completed all ten category/minigrid controllers and its required native controllers
# exist. This prevents the attended fixed/wrong shoulder target before initialization.
Check ($followup.Contains('ArraySize(this.m_equipmentMinigrids) >= 10')) 'First-open Biology detail is not gated on complete native minigrid initialization.'
Check ($followup.Contains('IsDefined(this.m_animationController)') -and $followup.Contains('IsDefined(this.m_inventoryView)') -and $followup.Contains('IsDefined(this.m_selector)')) 'Native detail readiness does not require the stock animation/content/selector controllers.'
Check ($followup.Contains('private final func CREnterBiologyDetail(area: gamedataEquipmentArea) -> Bool')) 'W02.2 does not wrap the existing Biology overview -> detail transition.'
Check ($followup.Contains('if this.crBiologyShellMode && !this.CRBiologyNativeDetailReady()')) 'Biology detail can still enter before the native shell is ready.'

# A selected Biology area remains the source of truth. W02.2 only resets stale native
# Cyberware shell markers before the existing transition commits that same area.
Check ($followup.Contains('this.m_dollHoverArea = gamedataEquipmentArea.Invalid;')) 'First-open native doll hover state is not normalized.'
Check ($followup.Contains('this.m_dollSelected = false;')) 'First-open native doll selected state is not normalized.'
Check ($followup.Contains('this.m_animationController.SetOutside();')) 'First-open animation depth is not normalized to overview before selection.'
Check ($shell.Contains('this.crBiologySelectedArea = area;') -and $shell.Contains('this.m_filterArea = area;') -and $shell.Contains('this.m_lastAreaVisited = area;')) 'Selected Biology area is not propagated into both Biology and native shell identity.'
Check ($shell.Contains('CRBiologySessionPresentation.Detail(player.GetGame(), this.crBiologySelectedArea)')) 'Detail rendering is not requested for the selected Biology system identity.'

# Biology now opens the real native detail/content transition. It suppresses only the
# stock Cyberware item-list chrome, leaving the native controller/root/layout intact.
Check ($followup.Contains('this.DisplayInventory(true);')) 'Biology detail does not open the native Ripperdoc inventory/detail surface.'
Check ($followup.Contains('this.m_inventoryView.CRSetBiologyDetailSurface(true);')) 'Biology detail does not switch the native content controller into Biology presentation mode.'
Check ($followup.Contains('this.AnimateMinigrids();')) 'Biology detail does not reuse native minigrid/detail positioning after the selected area is committed.'
Check ($followup.Contains('inkVirtualCompoundRef.Get(this.m_virtualGridContainer)')) 'Biology is not suppressing the stock Cyberware item grid at its native controller boundary.'
Check ($followup.Contains('virtualGrid.SetVisible(!active);')) 'Native Cyberware item-grid visibility is not restored symmetrically.'
Check ($followup.Contains('inkTextRef.SetVisible(this.m_labelPrefix, !active);') -and $followup.Contains('inkTextRef.SetVisible(this.m_labelSuffix, !active);')) 'Stock Cyberware filter labels are not restored symmetrically.'

# Detail binding is refreshed only after the native content surface has opened. The
# actual values remain supplied by the pre-existing authoritative session projection.
$displayIndex = $followup.IndexOf('this.DisplayInventory(true);')
$refreshIndex = $followup.IndexOf('this.CRRefreshBiologyDetail();')
Check ($displayIndex -ge 0 -and $refreshIndex -gt $displayIndex) 'Selected-system detail is refreshed before the native detail surface opens.'
Check ($detail.Contains('public static func Detail(game: GameInstance, area: gamedataEquipmentArea)')) 'Authoritative session detail projection is missing.'
Check ($detail.Contains('result.valid = true;')) 'Session detail contract never marks supplied authoritative detail valid.'

# Back is the inverse native transition: restore Cyberware content chrome, hide the
# native detail surface, and re-enable Biology nodes only after native readiness.
Check ($followup.Contains('public final func CRHandleBiologyBack() -> Bool')) 'W02.2 does not complete the Biology detail -> overview Back transition.'
Check ($followup.Contains('this.m_inventoryView.CRSetBiologyDetailSurface(false);')) 'Back does not restore native Cyberware content chrome.'
Check ($followup.Contains('this.DisplayInventory(false);')) 'Back does not close the native Ripperdoc detail/content surface.'
Check ($followup.Contains('this.CRSyncBiologyNodeInteractivity(this.crBiologyShellMode && this.CRBiologyNativeDetailReady());')) 'Back does not restore Biology interactivity deterministically.'

# Async spawn remains the readiness authority on first open. Existing stock behavior is
# wrapped, not replaced, and later Cyberware mode gets its normal grid/labels back.
Check ($followup.Contains('protected cb func OnMinigridSpawned(widget: ref<inkWidget>, userData: ref<IScriptable>) -> Bool')) 'Native asynchronous minigrid completion seam is not wrapped.'
Check ($followup.Contains('let result: Bool = wrappedMethod(widget, userData);')) 'Native OnMinigridSpawned behavior was replaced instead of wrapped.'
Check ($shell.Contains('inkWidgetRef.SetVisible(this.m_gridContainer, true);') -and $shell.Contains('this.UpdateTitle(this.GetAreaHeader(area));')) 'Stock Cyberware minigrid contents/titles are no longer restorable.'

# This lane consumes presentation data only. Runtime authority/startup repair remains
# outside W02.2 and must not be silently absorbed into the live-shell adapter.
Check (-not $followup.Contains('CRBodyRuntime')) 'W02.2 live-shell adapter absorbed body-runtime authority.'
Check (-not $followup.Contains('CRBiologyRuntimeAvailability')) 'W02.2 live-shell adapter absorbed runtime lifecycle/readiness.'

Write-Host "PASS: $script:checks W02.2 Biology live-shell first-open/detail checks."
