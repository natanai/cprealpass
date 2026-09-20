$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\tools\Common.ps1"
$project = Get-ProjectRoot
$source = Join-Path $project 'src\redscript\CyberpunkRealism'
$script:checks = 0
function Check($condition,[string]$message) { if (-not $condition) { throw $message }; $script:checks++ }
function Text([string]$name) { return Get-Content -Raw -LiteralPath (Join-Path $source $name) }

$followup = Text 'BiologyLiveShellFollowupNative.reds'
$shell = Text 'BiologyCyberwareShell.reds'

# T005-F01 proved that restoring cyberwareContainer at Biology detail -> Back can expose
# stock Cyberware for a rendered frame while native Inventory is still fading/hiding.
# Stock content ownership must therefore span Biology mode, not merely Biology detail.
Check ($followup.Contains('public final func CRSetBiologyStockContentSuppressed(suppressed: Bool) -> Void')) 'W19.1 mode-owned stock-content suppression seam is missing.'
Check ($followup.Contains('this.crBiologyContentHostWasVisible = contentHost.IsVisible();')) 'W19.1 no longer captures exact stock content visibility before Biology takes ownership.'
Check ($followup.Contains('contentHost.SetVisible(false);')) 'W19.1 does not suppress authored cyberwareContainer.'
Check ($followup.Contains('contentHost.SetVisible(this.crBiologyContentHostWasVisible);')) 'W19.1 does not restore exact stock content visibility when Cyberware regains ownership.'
Check ($followup.Contains('this.crBiologyContentHostVisibilityCaptured = false;')) 'W19.1 does not release the bounded stock-visibility capture on restoration.'

$detailSetterStart = $followup.IndexOf('public final func CRSetBiologyDetailSurface(active: Bool) -> Void')
$detailSetterEnd = $followup.IndexOf('@addMethod(RipperdocInventoryController)', $detailSetterStart + 1)
if ($detailSetterEnd -lt 0) { $detailSetterEnd = $followup.Length }
$detailSetter = $followup.Substring($detailSetterStart, $detailSetterEnd - $detailSetterStart)
Check ($detailSetter.Contains('if active {')) 'Biology detail setter no longer distinguishes activation.'
Check ($detailSetter.Contains('this.CRSetBiologyStockContentSuppressed(true);')) 'Biology detail activation does not suppress stock content.'
Check (-not $detailSetter.Contains('CRSetBiologyStockContentSuppressed(false)')) 'Biology detail deactivation incorrectly restores stock content during Back.'
Check (-not $detailSetter.Contains('contentHost.SetVisible(this.crBiologyContentHostWasVisible);')) 'Biology detail deactivation still restores cyberwareContainer directly.'

$backStart = $followup.IndexOf('if closingBiologyDetail {')
$backEnd = $followup.IndexOf([Environment]::NewLine + '  }', $backStart)
$backBlock = $followup.Substring($backStart, $backEnd - $backStart)
$closeIndex = $backBlock.IndexOf('this.DisplayInventory(false);')
$markerIndex = $backBlock.IndexOf('inventoryView.CRSetBiologyDetailSurface(false);')
Check ($closeIndex -ge 0) 'Biology Back no longer delegates detail close to native DisplayInventory(false).'
Check ($markerIndex -gt $closeIndex) 'Biology clears its detail marker before native DisplayInventory(false) begins the close lifecycle.'
Check (-not $backBlock.Contains('CRSetBiologyStockContentSuppressed(false)')) 'Biology Back restores stock content before native close/zoom-out settles.'

$selectStart = $followup.IndexOf('private func DollSelect(select: Bool) -> Void')
$selectEnd = $followup.IndexOf('@wrapMethod(RipperDocGameController)', $selectStart + 1)
$selectBlock = $followup.Substring($selectStart, $selectEnd - $selectStart)
$suppressIndex = $selectBlock.IndexOf('this.m_inventoryView.CRSetBiologyDetailSurface(true);')
$openIndex = $selectBlock.IndexOf('this.DisplayInventory(true);')
Check ($suppressIndex -ge 0 -and $openIndex -gt $suppressIndex) 'Biology opens native Inventory before suppressing stock Cyberware content.'

Check ($shell.Contains('this.m_inventoryView.CRSetBiologyStockContentSuppressed(biology);')) 'Biology/Cyberware mode switch does not own stock content suppression/restoration.'
Check ($shell.Contains('this.m_inventoryView.CRSetBiologyStockContentSuppressed(false);')) 'Shared-screen teardown does not restore captured stock content.'
Check ($shell.Contains('if this.CRBodyShellInDetail()')) 'Mode switching no longer remains overview-only.'

Check (-not $followup.Contains('DelaySystem')) 'W19.1 introduced a delay-system workaround.'
Check (-not $followup.Contains('RegisterListener')) 'W19.1 introduced a frame/listener workaround.'
Check (-not $followup.Contains('inkVirtualCompoundRef.Get(this.m_virtualGridContainer)')) 'W19.1 regressed to the virtualized item-grid boundary.'
Check (-not $followup.Contains('SetMargin(inkMargin(')) 'W19.1 introduced screenshot-derived placement compensation.'

Write-Host "PASS: $script:checks T005-F01 Biology Back transition ownership checks."
