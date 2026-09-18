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

# W02.3 must compose Biology telemetry inside the native RipperdocInventoryController
# root. Parenting beside the controller under m_inventoryViewAnchor reproduces the live
# top-left placement because that sibling does not inherit the authored inventory region.
Check ($shell.Contains('nativeContentParent = this.m_inventoryView.GetRootWidget() as inkCompoundWidget;')) 'Biology detail is not parented inside the native inventory controller root.'
Check (-not $shell.Contains('let nativeContentParent: ref<inkCompoundWidget> = inkCompoundRef.Get(this.m_inventoryViewAnchor) as inkCompoundWidget;')) 'Biology detail still mounts beside the native inventory controller under m_inventoryViewAnchor.'
Check ($shell.Contains('this.crBiologyNativeContent.Reparent(nativeContentParent, -1);')) 'Biology detail is not attached to the resolved native content root.'
Check ($shell.Contains('this.crBiologyNativeContent.SetAnchor(inkEAnchor.TopLeft);')) 'Biology detail lacks an explicit anchor inside the native content region.'
Check ($shell.Contains('this.crBiologyNativeContent.SetHAlign(inkEHorizontalAlign.Left);') -and $shell.Contains('this.crBiologyNativeContent.SetVAlign(inkEVerticalAlign.Top);')) 'Biology detail alignment is not deterministic inside the native content region.'

# Functional hierarchy only: title, summary, metric rows, then contextual actions.
# Broad visual redesign remains deliberately deferred.
Check ($shell.Contains('this.crBiologyDetailTitle = this.CRShellText("", n"CRBiologyDetailHeading", 30);')) 'Selected-system title is not given a clear functional hierarchy.'
Check ($shell.Contains('this.crBiologyDetailSummary = this.CRShellWrappedText("", n"CRBiologyDetailSummary", 18, 680.0);')) 'Selected-system summary is not wrapped within the detail region.'
Check ($shell.Contains('row.SetSize(Vector2(680.0, 40.0));')) 'Biology metric rows do not use the W02.3 legible row geometry.'
Check ($shell.Contains('background.SetSize(Vector2(300.0, 10.0));') -and $shell.Contains('value.SetTranslation(565.0, 0.0);')) 'Metric bar/value geometry is not composed coherently.'
Check ($shell.Contains('this.crBioActionsPanel.SetSize(Vector2(680.0, 0.0));') -and $shell.Contains('this.crBioActionsPanel.Reparent(this.crBiologyNativeContent, -1);')) 'Contextual actions are not kept inside the same native detail composition.'

# Preserve W02.2 first-open selection identity and native detail transition.
Check ($shell.Contains('this.crBiologySelectedArea = area;') -and $shell.Contains('this.m_filterArea = area;') -and $shell.Contains('this.m_lastAreaVisited = area;')) 'W02.3 disturbed selected-system identity propagation.'
Check ($followup.Contains('Equals(area, this.crBiologySelectedArea)') -and $followup.Contains('this.DisplayInventory(true);')) 'W02.3 disturbed W02.2 correct-anatomy/native-detail entry.'
Check ($shell.Contains('CRBiologySessionPresentation.Detail(player.GetGame(), this.crBiologySelectedArea)')) 'W02.3 no longer binds detail to the selected authoritative system.'

# Back/reopen behavior and stock Cyberware authority remain intact.
Check ($sync.Contains('if this.CRHandleBiologyBack()')) 'Native Back no longer delegates Biology detail to its overview reset.'
Check ($shell.Contains('this.crBiologySelectedArea = gamedataEquipmentArea.Invalid;') -and $shell.Contains('this.DollHover(gamedataEquipmentArea.Invalid);')) 'Biology Back no longer clears selected anatomy deterministically.'
Check ($followup.Contains('CRSetBiologyDetailSurface(false);') -and $followup.Contains('this.DisplayInventory(false);')) 'Native detail surface is not restored on Biology Back.'
Check ($shell.Contains('inkWidgetRef.SetVisible(this.m_gridContainer, true);') -and $shell.Contains('this.UpdateTitle(this.GetAreaHeader(area));')) 'Stock Cyberware category contents/titles are no longer restorable.'
Check (-not $shell.Contains('CRBodyRuntime.Get().')) 'W02.3 layout work absorbed body-runtime authority.'

Write-Host "PASS: $script:checks W02.3 Biology native detail layout checks."
