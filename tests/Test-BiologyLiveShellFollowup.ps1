$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\tools\Common.ps1"
$project = Get-ProjectRoot
$source = Join-Path $project 'src\redscript\CyberpunkRealism'
$script:checks = 0
function Check($condition,[string]$message) { if (-not $condition) { throw $message }; $script:checks++ }
function Text([string]$name) { return Get-Content -Raw -LiteralPath (Join-Path $source $name) }

$followup = Text 'BiologyLiveShellFollowupNative.reds'
$shell = Text 'BiologyCyberwareShell.reds'
$sync = Text 'BiologyModeSyncNative.reds'
$detail = Text 'BiologySessionPresentation.reds'

# Stock Ripperdoc category layout is asynchronous. W02.2 tracks the actual native
# completion boundary and synchronizes Biology label interactivity from native
# OnMinigridSpawned instead of inventing a timer or a second shell lifecycle.
Check ($followup.Contains('ArraySize(this.m_equipmentMinigrids) >= 10')) 'Native Biology detail readiness does not require all ten stock minigrids.'
Check ($followup.Contains('IsDefined(this.m_animationController)') -and $followup.Contains('IsDefined(this.m_inventoryView)') -and $followup.Contains('IsDefined(this.m_selector)')) 'Native detail readiness does not require the stock animation/content/selector controllers.'
Check ($followup.Contains('protected cb func OnMinigridSpawned(widget: ref<inkWidget>, userData: ref<IScriptable>) -> Bool')) 'Native asynchronous minigrid completion seam is not wrapped.'
Check ($followup.Contains('let result: Bool = wrappedMethod(widget, userData);')) 'Native OnMinigridSpawned behavior was replaced instead of wrapped.'
Check ($followup.Contains('this.CRSyncBiologyNodeInteractivity(this.CRBiologyNativeDetailReady());')) 'Biology node interactivity is not synchronized to native shell readiness.'

# The pre-existing native synchronization wrapper must enforce the same readiness
# predicate. This makes first-open gating independent of REDscript wrapper order.
Check ($sync.Contains('this.crBiologyShellMode') -and $sync.Contains('&& this.CRBiologyNativeDetailReady()') -and $sync.Contains('CRBiologyDetailPresentation.Supported(minigrid.CRBiologyArea())')) 'Spawned Biology nodes can become interactive before the W02.2 native shell readiness boundary.'
Check ($sync.Contains('this.CRSyncBiologyNodeInteractivity(this.crBiologyShellMode && this.CRBiologyNativeDetailReady());')) 'Existing Biology initialization does not honor W02.2 first-open readiness.'

# The existing Biology event/method path remains the one selected-system authority.
# W02.2 touches native DollHover/DollSelect only after that path has committed the area.
Check (-not $followup.Contains('@wrapMethod(RipperDocGameController)') -or -not $followup.Contains('OnCRBiologyAreaSelectEvent')) 'W02.2 must not annotate a mod-added Biology event.'
Check ($shell.Contains('this.crBiologySelectedArea = area;') -and $shell.Contains('this.m_filterArea = area;') -and $shell.Contains('this.m_lastAreaVisited = area;')) 'Selected Biology area is not propagated into both Biology and native shell identity.'
Check ($shell.Contains('CRBiologySessionPresentation.Detail(player.GetGame(), this.crBiologySelectedArea)')) 'Detail rendering is not requested for the selected Biology system identity.'

# First-open native selection markers are normalized inside the native DollHover seam,
# but only after Biology has already committed a real selected system in Item depth.
Check ($followup.Contains('private func DollHover(area: gamedataEquipmentArea) -> Void')) 'W02.2 does not wrap native DollHover.'
Check ($followup.Contains('NotEquals(this.crBiologySelectedArea, gamedataEquipmentArea.Invalid)')) 'Native selection normalization is not scoped to a committed Biology area.'
Check ($followup.Contains('Equals(area, this.crBiologySelectedArea)')) 'Native doll focus is not tied to the selected Biology system identity.'
Check ($followup.Contains('this.m_dollHoverArea = gamedataEquipmentArea.Invalid;')) 'First-open native doll hover state is not normalized.'
Check ($followup.Contains('this.m_dollSelected = false;')) 'First-open native doll selected state is not normalized.'
Check ($followup.Contains('this.m_animationController.SetOutside();')) 'First-open animation depth is not normalized to overview before stock selection.'

# Biology opens the real native detail/content transition from native DollSelect.
# It suppresses only stock Cyberware list/filter chrome, leaving the native controller,
# anchor, depth state, animation, and Back grammar intact.
Check ($followup.Contains('private func DollSelect(select: Bool) -> Void')) 'W02.2 does not wrap native DollSelect.'
Check ($followup.Contains('this.DisplayInventory(true);')) 'Biology detail does not open the native Ripperdoc inventory/detail surface.'
Check ($followup.Contains('this.m_inventoryView.CRSetBiologyDetailSurface(true);')) 'Biology detail does not switch the native content controller into Biology presentation mode.'
Check ($followup.Contains('this.AnimateMinigrids();')) 'Biology detail does not reuse native minigrid/detail positioning after the selected area is committed.'
Check ($followup.Contains('inkVirtualCompoundRef.Get(this.m_virtualGridContainer)')) 'Biology is not suppressing the stock Cyberware item grid at its native controller boundary.'
Check ($followup.Contains('virtualGrid.SetVisible(!active);')) 'Native Cyberware item-grid visibility is not restored symmetrically.'
Check ($followup.Contains('inkTextRef.SetVisible(this.m_labelPrefix, !active);') -and $followup.Contains('inkTextRef.SetVisible(this.m_labelSuffix, !active);')) 'Stock Cyberware filter labels are not restored symmetrically.'

# The original Biology transition calls DollSelect before refreshing selected-system
# presentation. Because DollSelect is now the native content-open seam, supplied detail
# data binds only after the native surface is available.
$selectIndex = $shell.IndexOf('this.DollSelect(true);')
$refreshIndex = $shell.IndexOf('this.CRRefreshBiologyDetail();')
Check ($selectIndex -ge 0 -and $refreshIndex -gt $selectIndex) 'Selected-system detail is refreshed before the native selection/content transition.'
Check ($detail.Contains('public static func Detail(game: GameInstance, area: gamedataEquipmentArea)')) 'Authoritative session detail projection is missing.'
Check ($detail.Contains('result.valid = true;')) 'Session detail contract never marks supplied authoritative detail valid.'

# Existing Biology Back clears selected area and calls native DollHover(Invalid).
# W02.2 detects only an active Biology detail surface at that native boundary, restores
# Cyberware chrome, and invokes the stock DisplayInventory(false) inverse transition.
Check ($followup.Contains('this.m_inventoryView.CRBiologyDetailSurfaceActive();') -or $followup.Contains('inventoryView.CRBiologyDetailSurfaceActive();')) 'Back cleanup is not scoped to an active Biology detail surface.'
Check ($followup.Contains('CRSetBiologyDetailSurface(false);')) 'Back does not restore native Cyberware content chrome.'
Check ($followup.Contains('this.DisplayInventory(false);')) 'Back does not close the native Ripperdoc detail/content surface.'
Check ($shell.Contains('this.crBiologySelectedArea = gamedataEquipmentArea.Invalid;') -and $shell.Contains('this.DollHover(gamedataEquipmentArea.Invalid);')) 'Existing Biology Back no longer clears selection through the native doll reset path.'

# Stock Cyberware remains reachable/restorable and this lane does not absorb runtime.
Check ($shell.Contains('inkWidgetRef.SetVisible(this.m_gridContainer, true);') -and $shell.Contains('this.UpdateTitle(this.GetAreaHeader(area));')) 'Stock Cyberware minigrid contents/titles are no longer restorable.'
Check (-not $followup.Contains('CRBodyRuntime')) 'W02.2 live-shell adapter absorbed body-runtime authority.'
Check (-not $followup.Contains('CRBiologyRuntimeAvailability')) 'W02.2 live-shell adapter absorbed runtime lifecycle/readiness.'

Write-Host "PASS: $script:checks W02.2 Biology live-shell first-open/detail checks."
