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
Check ($doc.Contains('players should not feel that they need to poll Biology')) 'Biology UI doc lost the no-meter-polling acceptance principle.'
Check ($doc.Contains('The Biology screen is **always available**')) 'Biology doc no longer requires healthy-state inspectability.'
Check ($doc -match '(?i)overview.*(simply|simply reads|reads).*`STABLE`|nothing meaningful.*`STABLE`') 'Biology doc does not lock the terse normal-state token.'
Check ($doc.Contains('Every ordinary player-facing doorway') -and $doc.Contains('underlying native destination/identifier')) 'Biology navigation-label consistency/native routing boundary is not documented.'
Check ($doc -match '(?is)overview:\*\*?\s*`BIOLOGY \| CYBERWARE` mode switching is available.*detail/drill-down:\*\*?\s*mode switching is unavailable') 'Biology doc does not lock overview-only mode switching.'
Check ($doc.Contains('Back must **not** force the user to close the entire pause/menu stack')) 'Biology doc does not lock detail Back to overview behavior.'

# Reuse the stock hub routing: relabel the existing Cyberware menu data instead of
# inventing a second fullscreen/menu identifier.
Check ($shell.Contains('@wrapMethod(MenuHubLogicController)')) 'Biology does not hook the stock hub label boundary.'
Check ($shell.Contains('public final func SetMenusData(menuData: ref<MenuDataBuilder>, perkPoints: Int32, attrPoints: Int32) -> Void')) 'Biology hub wrapper drifted from the verified Cyberpunk 2.31 MenuHubLogicController signature.'
Check ($shell.Contains('wrappedMethod(menuData, perkPoints, attrPoints)')) 'Biology hub wrapper does not call the verified stock SetMenusData signature.'
Check (-not $shell.Contains('tarotIsBlocked: Bool, mapIsBlocked: Bool, perkPoints: Int32, attrPoints: Int32')) 'Biology shell reintroduced the RadialMenuHub SetMenusData signature on MenuHubLogicController.'
Check ($shell.Contains('HubMenuItems.Cyberware')) 'Biology does not reuse the stock Cyberware hub destination.'
Check ($shell.Contains('biologyData.label = "BIOLOGY"')) 'Stock Cyberware hub destination is not relabeled Biology.'
Check ($shell.Contains('HubMenuUtils.SetMenuData(this.m_btnCyberware, biologyData)')) 'Relabeled Biology data is not put back on the stock Cyberware button.'
Check (-not $shell.Contains('OpenMenuRequest') -and -not $shell.Contains('fullscreenName')) 'Biology shell invented a parallel fullscreen route instead of reusing stock cyberware_equip.'

# Biology/Cyberware are sibling modes within one body screen, with normal hub entry
# defaulting Biology and an actual ripperdoc remaining equipment-first.
Check ($shell.Contains('"BIOLOGY"') -and $shell.Contains('"CYBERWARE"')) 'Shared shell does not expose both internal modes.'
Check ($shell.Contains('CRApplyBiologyShellMode(NotEquals(this.m_screen, CyberwareScreenType.Ripperdoc))')) 'Normal/ripperdoc mode defaults are not explicit.'
Check ($shell.Contains('this.m_gridContainer, false') -and $shell.Contains('this.m_gridContainer, true')) 'Biology mode does not hide/restore stock cyberware slot contents.'
Check ($shell.Contains('this.UpdateTitle(this.GetAreaHeader(area))')) 'Cyberware mode does not restore the stock category label through the verified minigrid instance helper.'
Check (-not $shell.Contains('this.UpdateTitle(GetAreaHeader(area))')) 'Cyberware label restore regressed to an unresolved global GetAreaHeader call.'
Check ($shell.Contains('CRSetStockMetersVisible(!biology)')) 'Biology mode leaves cyberware-specific stock meters visible.'

# Supported body nodes are controlled by whether Biology models that area, not by
# whether a current need/condition is severe. Overview composition may still inspect
# hasEffects/hasConditions; node visibility itself must remain support-only.
Check ($shell.Contains('let supported: Bool = CRBiologyDetailPresentation.Supported(area)')) 'Biology node visibility is not keyed to modeled-system support.'
Check ($shell.Contains('this.crBiologyMode = active && supported;')) 'Biology node activation is not support-only.'
Check ($shell.Contains('this.GetRootWidget().SetVisible(supported)')) 'Supported Biology nodes are not retained in Biology mode.'
Check (-not $shell.Contains('this.crBiologyMode = active && supported &&') -and -not $shell.Contains('SetVisible(supported &&')) 'Biology node visibility is incorrectly gated on current urgency/state.'

# Native anatomy interaction language is reused rather than simulated by another body widget.
Check ($shell.Contains('this.m_animationController.StartHover(evt.area)')) 'Biology nodes do not use stock body hover animation.'
Check ($shell.Contains('this.m_animationController.StartSelect()')) 'Biology node selection does not use stock body zoom/select animation.'
Check ($shell.Contains('this.m_animationController.SetOutside()') -and $shell.Contains('this.m_animationController.StopSelect()')) 'Biology cannot return through the stock zoom-out path.'
foreach ($area in @('FrontalCortexCW','CardiovascularSystemCW','NervousSystemCW','SystemReplacementCW','MusculoskeletalSystemCW','IntegumentarySystemCW','ArmsCW','LegsCW')) {
    Check ($detail.Contains("gamedataEquipmentArea.$area")) "Biology detail projection lost supported native body node: $area"
}
Check (-not $detail.Contains('EyesCW') -and -not $detail.Contains('HandsCW') -and -not $detail.Contains('ImmuneSystemCW')) 'Biology invented unsupported physiology merely to fill cyberware-only nodes.'

# Overview language is terse qualitative telemetry. No AI-like explanatory prose or
# raw percentages belong on the unzoomed state line.
Check ($bodyStatus.Contains('return "STABLE";')) 'Normal Biology overview is not the terse STABLE token.'
foreach ($token in @('THIRST HIGH','HUNGER CRITICAL','FATIGUE HIGH','BLADDER URGENT','BOWEL HIGH','HYGIENE LOW')) {
    Check ($bodyStatus.Contains('"' + $token + '"')) "Biology overview telemetry token missing: $token"
}
Check (-not $bodyStatus.Contains('No strong bodily need is demanding attention')) 'Verbose old no-needs sentence remains in Biology projection.'
Check (-not $bodyStatus.Contains('bladder becoming noticeable') -and -not $bodyStatus.Contains('need to use the bathroom') -and -not $bodyStatus.Contains('could use a wash')) 'Conversational needs prose remains in Biology overview.'
Check ($overview.Contains('!Equals(result.needs, "STABLE")')) 'Biology hasNeeds logic does not understand the STABLE normal token.'
foreach ($token in @('PAIN CRITICAL','PAIN HIGH','ANALGESIA','DISORIENTATION HIGH')) {
    Check ($overview.Contains('"' + $token + '"')) "Biology effect telemetry token missing: $token"
}
Check (-not $overview.Contains('interfering with concentration') -and -not $overview.Contains('dulling pain without repairing')) 'Explanatory pain prose leaked back into overview telemetry.'

# Exact model values are deliberately exposed only through the drill-down projection
# and are read-only. Healthy detail remains inspectable and can report NO CONDITION.
Check ($detail.Contains('return "NO CONDITION";')) 'Healthy drill-down does not remain inspectable with a concise normal state.'
Check ($detail.Contains('CRBodyRuntime.Get().GetBodySnapshot()') -and $detail.Contains('CRBodyRuntime.Get().GetMeters()')) 'Drill-down is not reading the authoritative shared body.'
Check ($detail.Contains('CRPainRuntime.Get().Read()')) 'Drill-down pain/analgesia is not read from the authoritative pain projection.'
Check ($detail.Contains('CRInjuryModel.Function') -and $detail.Contains('tissueDamage') -and $detail.Contains('boneDamage') -and $detail.Contains('cyberwareDamage')) 'Regional drill-down lacks exact authoritative injury/function detail.'
Check ($detail.Contains('"HYDRATION"') -and $detail.Contains('"NUTRITION"') -and $detail.Contains('"ENERGY"')) 'Metabolism drill-down lost exact needs metrics.'
Check (-not $detail.Contains('No meaningful condition is currently apparent') -and -not $detail.Contains('Whole-body musculoskeletal load')) 'Verbose explanatory drill-down prose remains.'
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

Write-Host "PASS: $script:checks persistent Biology parent/Cyberware submode, terse overview telemetry, healthy drill-down, native anatomy reuse, exact detail metrics, and contextual action checks."
