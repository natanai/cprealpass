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

# W17.1 source/resource archaeology proves the selected-content seam is the direct
# Inventory child cyberwareContainer. The deeper GridAndSlider/scrollRect/virtualGrid
# subtree is item-list implementation only.
Check ($shell.Contains('this.crBiologyNativeContent = new inkVerticalPanel();')) 'Biology detail creation does not retain a retryable native-content panel.'
Check ($shell.Contains('this.m_inventoryView.CRMountBiologyDetailInAuthoredContentHost(this.crBiologyNativeContent);')) 'Biology detail does not revalidate authored content-host placement at detail depth.'
Check ($followup.Contains('Equals(child.GetName(), n"cyberwareContainer")')) 'Biology detail does not resolve the authored selected-content container.'
Check ($followup.Contains('target.Reparent(inventoryRoot, -1);')) 'Biology detail is not a sibling of cyberwareContainer under the Inventory lifecycle root.'
Check ($followup.Contains('let contentPanel: ref<inkVerticalPanel> = contentHost as inkVerticalPanel;')) 'Biology does not verify same-family vertical-panel host semantics.'
Check (-not $followup.Contains('inkVirtualCompoundRef.Get(this.m_virtualGridContainer)')) 'Biology still uses the virtualized item list as layout authority.'
Check (-not $shell.Contains('this.crBiologyNativeContent.SetAnchor(inkEAnchor.TopLeft);')) 'Biology detail still forces a screen-origin TopLeft anchor.'
Check (-not $shell.Contains('this.crBiologyNativeContent.SetMargin(inkMargin(0.0, 42.0, 0.0, 0.0));')) 'Biology detail still uses the disproven W02.3 fixed root-relative offset.'
Check ($shell.Contains('this.crBiologyNativeContent.SetFitToContent(true);')) 'Biology detail container does not size itself from its title/summary/metric children.'
Check ($followup.Contains('target.SetFitToContent(true);')) 'Authored-host sync does not preserve Biology-owned fit-to-content sizing.'
Check ($followup.Contains('target.SetMargin(contentHost.GetMargin());')) 'Biology detail no longer derives placement from the live authored content host.'

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

Write-Host "PASS: $script:checks W17.1 Biology authored detail layout checks."
