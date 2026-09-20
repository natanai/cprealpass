$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\tools\Common.ps1"
$project = Get-ProjectRoot
$script:checks = 0
function Check($condition,[string]$message) { if (-not $condition) { throw $message }; $script:checks++ }

$goals = Get-Content -Raw -LiteralPath (Join-Path $project 'AGREED-GOALS.md')
$doc = Get-Content -Raw -LiteralPath (Join-Path $project 'docs/BIOLOGY-UI.md')
$shellPath = Join-Path $project 'src/redscript/CyberpunkRealism/BiologyCyberwareShell.reds'
$detailPath = Join-Path $project 'src/redscript/CyberpunkRealism/BiologyDetailPresentation.reds'
$overviewPath = Join-Path $project 'src/redscript/CyberpunkRealism/BiologyPresentation.reds'
$bodyStatusPath = Join-Path $project 'src/redscript/CyberpunkRealism/BodyStatusPresentation.reds'
$actionsPath = Join-Path $project 'src/redscript/CyberpunkRealism/BiologyActionsNative.reds'
$syncPath = Join-Path $project 'src/redscript/CyberpunkRealism/BiologyModeSyncNative.reds'
$oldPath = Join-Path $project 'src/redscript/CyberpunkRealism/BiologyNativeUI.reds'
foreach ($path in @($shellPath,$detailPath,$overviewPath,$bodyStatusPath,$actionsPath,$syncPath)) {
    Check (Test-Path -LiteralPath $path) "Missing revised Biology shell source: $path"
}
Check (-not (Test-Path -LiteralPath $oldPath)) 'Invisible floating BiologyNativeUI prototype remains in production source.'

$shell = Get-Content -Raw -LiteralPath $shellPath
$detail = Get-Content -Raw -LiteralPath $detailPath
$overview = Get-Content -Raw -LiteralPath $overviewPath
$bodyStatus = Get-Content -Raw -LiteralPath $bodyStatusPath
$actions = Get-Content -Raw -LiteralPath $actionsPath
$sync = Get-Content -Raw -LiteralPath $syncPath

foreach ($goal in @('G-041','G-043','G-045','G-046','G-063','G-064','G-066','G-072')) {
    Check ($goals.Contains($goal)) "Shared Biology/Cyberware goal missing: $goal"
}
Check ($goals.Contains('BIOLOGY -> shared body/anatomy shell -> BIOLOGY | CYBERWARE')) 'Canonical hierarchy is not explicit.'
Check ($doc.Contains('top hub -> BIOLOGY -> shared body/anatomy shell -> BIOLOGY | CYBERWARE')) 'Biology UI doc does not mirror the canonical hierarchy.'
Check ($doc.Contains('The Biology screen is **always available**')) 'Biology doc no longer requires healthy-state inspectability.'
Check ($doc -match '(?is)nothing meaningful is active.{0,80}overview.{0,40}`STABLE`') 'Biology doc does not lock the terse normal-state STABLE token.'

# Keep Cyberpunk's menu identity/route. Biology is the visible parent name, not a new
# fullscreen implementation.
Check ($shell.Contains('@wrapMethod(MenuHubLogicController)')) 'Biology does not hook the stock hub label boundary.'
Check ($shell.Contains('HubMenuItems.Cyberware')) 'Biology does not reuse the stock Cyberware hub destination.'
Check ($shell.Contains('biologyData.label = "BIOLOGY"')) 'Stock Cyberware hub destination is not relabeled Biology.'
Check ($shell.Contains('HubMenuUtils.SetMenuData(this.m_btnCyberware, biologyData)')) 'Relabeled Biology data is not put back on the stock Cyberware button.'
Check (-not $shell.Contains('OpenMenuRequest')) 'Biology shell invented a parallel fullscreen route.'

# Overview reuses stock category controllers and stock body anatomy.
Check ($shell.Contains('let supported: Bool = CRBiologyDetailPresentation.Supported(area)')) 'Biology overview nodes are not keyed to modeled native areas.'
Check ($shell.Contains('this.GetRootWidget().SetVisible(supported)')) 'Supported Biology overview nodes are not persistent while healthy.'
Check ($shell.Contains('this.m_gridContainer, false') -and $shell.Contains('this.m_gridContainer, true')) 'Biology/Cyberware does not hide/restore stock equipment-card contents.'
Check ($shell.Contains('this.UpdateTitle(this.GetAreaHeader(area))')) 'Cyberware mode does not restore native category labels.'
Check ($shell.Contains('this.DollHover(evt.area)')) 'Biology overview hover does not reuse native doll hover.'

# Drill-down adopts native Cyberware depth/state rather than a parallel custom detail
# mode. W17.1 keeps Biology under RipperdocInventoryController's lifecycle root but
# mounts it beside the authored cyberwareContainer, outside the scroll/grid subtree.
Check ($shell.Contains('this.crBiologyNativeContent = new inkVerticalPanel();')) 'Biology detail does not retain its native-content subtree across an initialization-time mount miss.'
Check ($shell.Contains('this.m_inventoryView.CRMountBiologyDetailInAuthoredContentHost(this.crBiologyNativeContent);')) 'Biology detail does not revalidate its authored content-host mount.'
Check (-not $shell.Contains('this.m_inventoryView.GetRootWidget() as inkCompoundWidget')) 'Biology detail still contains obsolete direct-root mount code.'
Check (-not $shell.Contains('let nativeContentParent: ref<inkCompoundWidget> = inkCompoundRef.Get(this.m_inventoryViewAnchor) as inkCompoundWidget;')) 'Biology detail still mounts beside the native inventory controller under the screen anchor.'
Check ($shell.Contains('this.m_filterMode = RipperdocModes.Item;')) 'Biology detail does not adopt native Ripperdoc Item depth.'
Check ($shell.Contains('this.m_isInventoryOpen = true;')) 'Biology detail does not adopt the native detail-open marker.'
Check ($shell.Contains('this.DollHover(area);') -and $shell.Contains('this.DollSelect(true);')) 'Biology detail does not use native body focus/select behavior.'
Check ($shell.Contains('this.m_selector.CRSetBiologyDetailMode(true);')) 'Biology detail does not engage the native Ripperdoc selector.'
Check ($shell.Contains('this.m_selector.Show(this.EquipmentAreaToIndex(area));')) 'Biology does not select the native category indicator for the chosen body area.'
Check ($shell.Contains('this.SetButtonHints(true, false);')) 'Biology detail does not switch native Back hint semantics from close to back.'
Check (-not $shell.Contains('crBiologyDetailBack')) 'Parallel Biology-specific [OVERVIEW] Back control remains active.'

# Overview labels must leave the stage during native detail. The native selector then
# carries body-category navigation while anatomy is focused.
Check ($shell.Contains('this.CRSetBiologyOverviewNodesVisible(false);')) 'Static overview nodes remain active entering Biology detail.'
Check ($shell.Contains('this.crBiologyOverview.SetVisible(this.crBiologyShellMode && !detail)')) 'Overview telemetry is not hidden deterministically in detail.'
Check ($shell.Contains('inkCompoundRef.SetVisible(this.m_selectorAnchor, detail)')) 'Native selector visibility is not tied to Biology detail depth.'

# Native selector input/arrows and selector-change event are reused. Eyes/Hands stay
# Cyberware-only rather than being relabeled as unsupported physiology.
Check ($sync.Contains('@wrapMethod(RipperdocSelectorController)')) 'Biology does not reuse the native Ripperdoc selector controller.'
Check ($sync.Contains('private func SwitchIndicator(toNext: Bool) -> Void')) 'Native selector cycling seam is missing.'
Check ($sync.Contains('selectorEvent = new RipperdocSelectorChangeEvent') -or $sync.Contains('new RipperdocSelectorChangeEvent()')) 'Biology selector does not emit the native selector-change event.'
Check (-not $sync.Contains('index == 3') -and -not $sync.Contains('index == 5')) 'Selector support test unexpectedly includes Cyberware-only Eyes/Hands indices.'
Check ($sync.Contains('this.m_names[0] = "HEAD / BRAIN"') -and $sync.Contains('this.m_names[9] = "LEGS"')) 'Native selector names are not repurposed for Biology.'
Check ($sync.Contains('wrappedMethod(toNext)')) 'Native Cyberware selector behavior is not preserved outside Biology detail.'
Check ($sync.Contains('@wrapMethod(RipperDocGameController)') -and $sync.Contains('OnSelectorChange')) 'Biology does not consume native selector-change events at the Ripperdoc controller.'
Check ($shell.Contains('this.m_animationController.StartSlide(evt.SlidingRight, area)')) 'Biology category cycling does not reuse the native body slide transition.'

# Back/Cancel uses the native menu-dispatcher OnBack seam and native cleanup grammar.
Check ($sync.Contains('protected cb func OnBack(userData: ref<IScriptable>) -> Bool')) 'Biology detail does not hook the native Back stack.'
Check ($sync.Contains('if this.CRHandleBiologyBack()')) 'Native Back does not route Biology detail back to Biology overview.'
Check ($shell.Contains('this.m_filterMode = RipperdocModes.Default;')) 'Biology Back does not restore native overview depth.'
Check ($shell.Contains('this.m_isInventoryOpen = false;')) 'Biology Back does not clear the native detail-open marker.'
Check ($shell.Contains('this.m_animationController.SetOutside();')) 'Biology Back does not restore the native body outside state.'
Check ($shell.Contains('this.ClearMinigridSelection();')) 'Biology Back does not clear native category selection.'
Check ($shell.Contains('this.ResetMinigridPositions();')) 'Biology Back does not reset native category positions.'
Check ($shell.Contains('this.AnimateMinigrids();')) 'Biology Back does not restore native category presentation.'
Check ($shell.Contains('this.m_selector.CRSetBiologyDetailMode(false);')) 'Biology Back does not restore stock selector naming/state.'

# Mode switching is an overview-only state transition in both directions. Native
# Cyberware DisplayInventory depth also hides the mode switch.
Check ($shell.Contains('if this.CRBodyShellInDetail()')) 'Biology/Cyberware mode switching is not gated by shared native detail depth.'
Check ($shell.Contains('this.crBiologyModeBar.SetVisible(!this.CRBodyShellInDetail())')) 'Mode selector remains visible while drilled down.'
Check ($sync.Contains('private func DisplayInventory(visible: Bool) -> Void')) 'Native Cyberware detail does not synchronize mode-selector visibility.'
Check ($sync.Contains('wrappedMethod(visible);')) 'Cyberware DisplayInventory behavior is not preserved.'
Check ($shell.Contains('this.crBiologyModeButton.SetOpacity(biology ? 1.0 : 0.52)')) 'Biology/Cyberware overview selector lacks a strong selected/unselected state.'
Check ($shell.Contains('CRShellText(text, name, 28)')) 'Attended mode selector remains at the undersized prototype typography.'

# Exact values remain read-only projections from authoritative body state.
Check ($bodyStatus.Contains('return "STABLE";')) 'Normal Biology overview is not the terse STABLE token.'
Check ($overview.Contains('!Equals(result.needs, "STABLE")')) 'Biology hasNeeds logic does not understand STABLE.'
Check ($detail.Contains('return "NO CONDITION";')) 'Healthy drill-down does not remain inspectable.'
Check ($detail.Contains('CRBodyRuntime.Get().GetBodySnapshot()') -and $detail.Contains('CRBodyRuntime.Get().GetMeters()')) 'Drill-down is not reading authoritative shared body state.'
Check ($detail.Contains('CRPainRuntime.Get().Read()')) 'Drill-down pain/analgesia is not read from authoritative pain state.'
Check ($shell.Contains('SetSize(Vector2(300.0 * ClampF(detail.metrics[i].percent / 100.0')) 'Detail bars are not projections of the selected authoritative metric.'
Check ($shell.Contains('[ BIOLOGY ERROR ] BODY DETAIL UNAVAILABLE')) 'Unavailable runtime/detail state is not fail-obvious.'

# Contextual actions live at detail depth, are area-scoped, and remain gateways into
# canonical inventory/treatment transactions rather than owning item state.
Check ($actions.Contains('if !this.crBiologyShellMode || !this.CRBiologyInDetail()')) 'Contextual Biology actions still render on overview.'
Check ($actions.Contains('Equals(this.crBiologySelectedArea, gamedataEquipmentArea.SystemReplacementCW)')) 'Food/drink actions are not scoped to the Metabolism body system.'
Check ($actions.Contains('GetItemList(player, items)') -and $actions.Contains('GetItemQuantity(player, itemID)')) 'Biology actions do not enumerate actual carried stacks.'
Check ($actions.Contains('ItemActionsHelper.EatItem') -and $actions.Contains('ItemActionsHelper.DrinkItem') -and $actions.Contains('ItemActionsHelper.ConsumeItem')) 'Biology intake bypasses native item-action families.'
Check ($actions.Contains('CRBodyRuntime.Get().UseFieldCare')) 'Biology field care no longer delegates to authoritative treatment runtime.'
Check ($actions.Contains('CRProfessionalCareRuntime.Complete')) 'Biology professional care no longer delegates to authoritative treatment runtime.'
Check (-not $actions.Contains('RemoveItem(') -and -not $actions.Contains('CRBodyRuntime.Get().Consume(')) 'Biology UI became a duplicate inventory/consumption authority.'
Check ($shell.Contains('this.crBioActionsPanel.Reparent(this.crBiologyNativeContent, -1);')) 'Biology contextual actions are not mounted into the native Cyberware content region.'

Write-Host "PASS: $script:checks Biology shell checks: native overview anatomy, native drill-down state/selector/back, overview-only mode switching, exact detail projection, and authoritative contextual actions."
