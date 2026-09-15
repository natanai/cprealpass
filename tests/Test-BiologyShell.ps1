$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\tools\Common.ps1"
$project = Get-ProjectRoot
$script:checks = 0
function Check($condition,[string]$message) { if (-not $condition) { throw $message }; $script:checks++ }

$goals = Get-Content -Raw -LiteralPath (Join-Path $project 'AGREED-GOALS.md')
$doc = Get-Content -Raw -LiteralPath (Join-Path $project 'docs/BIOLOGY-UI.md')
$shellPath = Join-Path $project 'src/redscript/CyberpunkRealism/BiologyCyberwareShell.reds'
$detailPath = Join-Path $project 'src/redscript/CyberpunkRealism/BiologyDetailPresentation.reds'
$actionsPath = Join-Path $project 'src/redscript/CyberpunkRealism/BiologyActionsNative.reds'
$syncPath = Join-Path $project 'src/redscript/CyberpunkRealism/BiologyModeSyncNative.reds'
$hubPath = Join-Path $project 'src/redscript/CyberpunkRealism/BiologyRadialHubNative.reds'
$livePath = Join-Path $project 'src/redscript/CyberpunkRealism/BiologyLivePresentationNative.reds'
$oldPath = Join-Path $project 'src/redscript/CyberpunkRealism/BiologyNativeUI.reds'
foreach ($path in @($shellPath,$detailPath,$actionsPath,$syncPath,$hubPath,$livePath)) {
    Check (Test-Path -LiteralPath $path) "Missing revised Biology shell source: $path"
}
Check (-not (Test-Path -LiteralPath $oldPath)) 'Invisible floating BiologyNativeUI prototype remains in production source.'

$shell = Get-Content -Raw -LiteralPath $shellPath
$detail = Get-Content -Raw -LiteralPath $detailPath
$actions = Get-Content -Raw -LiteralPath $actionsPath
$sync = Get-Content -Raw -LiteralPath $syncPath
$hub = Get-Content -Raw -LiteralPath $hubPath
$live = Get-Content -Raw -LiteralPath $livePath

foreach ($goal in @('G-041','G-043','G-045','G-046','G-063','G-064','G-066','G-072')) {
    Check ($goals.Contains($goal)) "Shared Biology/Cyberware goal missing: $goal"
}
Check ($goals.Contains('BIOLOGY -> shared body/anatomy shell -> BIOLOGY | CYBERWARE')) 'Canonical hierarchy is not explicit.'
Check ($doc.Contains('top hub -> BIOLOGY -> shared body/anatomy shell -> BIOLOGY | CYBERWARE')) 'Biology UI doc does not mirror the canonical hierarchy.'
Check ($doc.Contains('players should not feel that they need to poll Biology')) 'Biology UI doc lost the no-meter-polling acceptance principle.'
Check ($doc.Contains('Deliberate drill-down') -and $doc.Contains('exact authoritative values')) 'Biology doc does not distinguish overview from exact drill-down.'

# Live acceptance showed that re-running individual hub SetMenusData methods can hit
# secondary/hidden menu representations. Relabel at the visible MenuItemController
# render boundary instead while preserving Cyberware's identifier/fullscreen route.
Check ($hub.Contains('@wrapMethod(MenuItemController)')) 'Top/menu Biology label is not bound at MenuItemController.Init.'
Check ($hub.Contains('@wrapMethod(RadialMenuItemController)')) 'Radial Biology label is not bound at RadialMenuItemController.Init.'
Check ($hub.Contains('Deref(menuData).identifier == EnumInt(HubMenuItems.Cyberware)')) 'Biology label wrapper does not narrowly target the stock Cyberware identifier.'
Check ($hub.Contains('inkTextRef.SetText(this.m_label, "BIOLOGY")')) 'Visible stock Cyberware menu labels are not rewritten to Biology.'
Check (-not $hub.Contains('SetMenusData(')) 'Biology label fix regressed to a specific hub-controller SetMenusData seam.'
Check ($shell.Contains('HubMenuItems.Cyberware')) 'Biology does not reuse the stock Cyberware hub destination.'
Check (-not $shell.Contains('OpenMenuRequest') -and -not $shell.Contains('fullscreenName')) 'Biology shell invented a parallel fullscreen route instead of reusing stock cyberware_equip.'

# Biology/Cyberware are sibling modes within one body screen, with normal hub entry
# defaulting Biology and an actual ripperdoc remaining equipment-first.
Check ($shell.Contains('"BIOLOGY"') -and $shell.Contains('"CYBERWARE"')) 'Shared shell does not expose both internal modes.'
Check ($shell.Contains('CRApplyBiologyShellMode(NotEquals(this.m_screen, CyberwareScreenType.Ripperdoc))')) 'Normal/ripperdoc mode defaults are not explicit.'
Check ($shell.Contains('this.m_gridContainer, false') -and $shell.Contains('this.m_gridContainer, true')) 'Biology mode does not hide/restore stock cyberware slot contents.'
Check ($shell.Contains('this.UpdateTitle(this.GetAreaHeader(area))')) 'Cyberware mode does not restore the stock category label through the verified minigrid instance helper.'
Check (-not $shell.Contains('this.UpdateTitle(GetAreaHeader(area))')) 'Cyberware label restore regressed to an unresolved global GetAreaHeader call.'
Check ($shell.Contains('CRSetStockMetersVisible(!biology)')) 'Biology mode leaves cyberware-specific stock meters visible.'

# Live screenshots proved OnInitialize is too early: the stock controller asynchronously
# populates all ten category minigrids and only then calls InitializeEquipmentMinigrids.
# Reapply the selected mode at that exact native completion boundary and lift dynamic
# overlays into the same visible root layer used by established Ripperdoc UI additions.
Check ($live.Contains('@wrapMethod(RipperDocGameController)')) 'Biology live lifecycle seam does not wrap RipperDocGameController.'
Check ($live.Contains('private final func InitializeEquipmentMinigrids() -> Void')) 'Biology does not wait for the stock minigrid-completion boundary.'
Check ($live.Contains('wrappedMethod();')) 'Biology minigrid lifecycle wrapper does not preserve stock initialization.'
Check ($live.Contains('CRApplyBiologyShellMode(this.crBiologyShellMode)')) 'Late minigrid completion does not reapply the selected Biology/Cyberware mode.'
Check ($live.Contains('CRSyncBiologyNodeInteractivity(this.crBiologyShellMode)')) 'Late minigrid completion does not synchronize Biology node interactivity.'
Check ($live.Contains('CRRefreshBiologyActions()')) 'Late minigrid completion does not refresh Biology contextual actions.'
Check ($live.Contains('CRPromoteBiologyOverlay')) 'Biology does not promote its dynamic overlay after stock UI construction.'
Check ($live.Contains('Reparent(root, 5)')) 'Biology overlay is not moved onto the proven visible Ripperdoc root layer.'

# Native anatomy interaction language is reused rather than simulated by another body widget.
Check ($shell.Contains('this.m_animationController.StartHover(evt.area)')) 'Biology nodes do not use stock body hover animation.'
Check ($shell.Contains('this.m_animationController.StartSelect()')) 'Biology node selection does not use stock body zoom/select animation.'
Check ($shell.Contains('this.m_animationController.SetOutside()') -and $shell.Contains('this.m_animationController.StopSelect()')) 'Biology cannot return through the stock zoom-out path.'
foreach ($area in @('FrontalCortexCW','CardiovascularSystemCW','NervousSystemCW','SystemReplacementCW','MusculoskeletalSystemCW','IntegumentarySystemCW','ArmsCW','LegsCW')) {
    Check ($detail.Contains("gamedataEquipmentArea.$area")) "Biology detail projection lost supported native body node: $area"
}
Check (-not $detail.Contains('EyesCW') -and -not $detail.Contains('HandsCW') -and -not $detail.Contains('ImmuneSystemCW')) 'Biology invented unsupported physiology merely to fill cyberware-only nodes.'

# The overview remains qualitative. Exact model values are deliberately exposed only
# through the drill-down projection and are read-only.
$overview = Get-Content -Raw -LiteralPath (Join-Path $project 'src/redscript/CyberpunkRealism/BiologyPresentation.reds')
Check ($overview.Contains('CRBodyStatusPresentation.BodyStatus(body)')) 'Biology overview no longer uses qualitative body interpretation.'
Check (-not $overview.Contains('bloodDeficitMl') -and -not $overview.Contains('tissueDamage') -and -not $overview.Contains('boneDamage')) 'Biology overview leaked exact injury telemetry.'
Check ($detail.Contains('CRBodyRuntime.Get().GetBodySnapshot()') -and $detail.Contains('CRBodyRuntime.Get().GetMeters()')) 'Drill-down is not reading the authoritative shared body.'
Check ($detail.Contains('CRPainRuntime.Get().Read()')) 'Drill-down pain/analgesia is not read from the authoritative pain projection.'
Check ($detail.Contains('CRInjuryModel.Function') -and $detail.Contains('tissueDamage') -and $detail.Contains('boneDamage') -and $detail.Contains('cyberwareDamage')) 'Regional drill-down lacks exact authoritative injury/function detail.'
Check (-not $detail.Contains('CRInjuryModel.Treat(') -and -not $detail.Contains('SetStatPoolValue') -and -not $detail.Contains('RemoveItem(')) 'Drill-down presentation became a simulation/inventory authority.'
Check ($shell.Contains('CRBiologyMetricFills') -or $shell.Contains('crBiologyMetricFills')) 'Shared shell does not render deliberate detail bars.'
Check ($shell.Contains('SetSize(Vector2(270.0 * ClampF(detail.metrics[i].percent / 100.0')) 'Detail bars are not direct projections of the selected metric.'

# Contextual actions remain gateways into authoritative systems.
Check ($actions.Contains('GetItemList(player, items)') -and $actions.Contains('GetItemQuantity(player, itemID)')) 'Shared Biology actions do not enumerate actual carried stacks.'
Check ($actions.Contains('ItemActionsHelper.EatItem') -and $actions.Contains('ItemActionsHelper.DrinkItem') -and $actions.Contains('ItemActionsHelper.ConsumeItem')) 'Shared Biology actions do not preserve stock item action families.'
Check ($actions.Contains('CRBodyRuntime.Get().UseFieldCare')) 'Shared Biology shell lost field-care routing.'
Check ($actions.Contains('CRProfessionalCareRuntime.Complete')) 'Shared Biology shell lost professional-care routing.'
Check (-not $actions.Contains('RemoveItem(') -and -not $actions.Contains('CRBodyRuntime.Get().Consume(')) 'Shared Biology actions bypass native inventory/consumption authority.'
Check ($actions.Contains('public final func CRRefreshBiologyActions() -> Void')) 'Biology action refresh method is missing.'
Check ($actions.Contains('this.CRRefreshBiologyActions();')) 'Biology action callbacks do not call the actual refresh method.'
Check (-not $actions.Contains('CRBioRefreshBiologyActions')) 'Biology actions contain the unresolved stale refresh-method spelling caught by the installed compiler.'
Check ($sync.Contains('CRRefreshBiologyActions')) 'Mode changes do not synchronize contextual action visibility.'

Write-Host "PASS: $script:checks live-validated Biology parent/Cyberware submode, controller-level menu labels, late native minigrid lifecycle, native anatomy reuse, drill-down metrics, and contextual actions."
