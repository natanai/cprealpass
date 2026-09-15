$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\tools\Common.ps1"
$project = Get-ProjectRoot
$source = Join-Path $project 'src\redscript\CyberpunkRealism'
$script:checks = 0
function Check($condition,[string]$message) { if (-not $condition) { throw $message }; $script:checks++ }
function Text([string]$name) {
    $path = Join-Path $source $name
    Check (Test-Path -LiteralPath $path -PathType Leaf) "Missing Biology lifecycle source: $name"
    return Get-Content -Raw -LiteralPath $path
}

$runtime = Text 'BodyRuntime.reds'
$availability = Text 'BiologyRuntimeAvailability.reds'
$presentation = Text 'BiologyPresentation.reds'
$status = Text 'BodyStatusPresentation.reds'
$hooks = Text 'BodyNativeHooks.reds'
$sync = Text 'BiologyModeSyncNative.reds'
$navigation = Text 'BiologyRadialHubNative.reds'
$shell = Text 'BiologyCyberwareShell.reds'

# STATE-01/02: one persistent authority, with transient lifecycle explicitly rebuilt.
Check ($runtime.Contains('private persistent let body: ref<CRBodyState>;')) 'Body authority must remain persistent on CRBodyRuntime.'
Check ($runtime.Contains('private func OnRestored(saveVersion: Int32, gameVersion: Int32) -> Void')) 'Body runtime must explicitly handle save restoration.'
Check ($runtime.Contains('this.ResetTransientState();')) 'Body restore must rebuild transient state instead of duplicating persisted body state.'
Check ($availability.Contains('let runtime: ref<CRBodyRuntime> = CRBodyRuntime.Get();')) 'Biology readiness must use the authoritative CRBodyRuntime.'
Check ($availability.Contains('if !runtime.IsRunning() || !runtime.OwnsNeeds()')) 'Biology readiness must recover a restored/non-running runtime.'
Check ($availability.Contains('runtime.Activate();')) 'Biology readiness must retry authoritative activation.'
Check (-not $availability.Contains('new CRBodyState')) 'Biology readiness must not create duplicate body state.'
Check (-not $availability.Contains('CRBodyModel.Create')) 'Biology readiness must not bypass CRBodyRuntime body creation.'
Check ($presentation.Contains('CRBiologyRuntimeAvailability.EnsureActive()')) 'Biology view-model reads must establish runtime readiness first.'
Check ($status.Contains('return CRBiologyRuntimeAvailability.EnsureActive();')) 'Shared body presentation ownership must use the same readiness bridge.'

# STATE-04: a failed runtime is explicit and cannot be presented as healthy STABLE.
Check ($availability.Contains('BODY RUNTIME BUILD GATE CLOSED')) 'Readiness diagnostics must distinguish a closed build gate.'
Check ($availability.Contains('BODY RUNTIME SYSTEM MISSING')) 'Readiness diagnostics must distinguish a missing ScriptableSystem.'
Check ($availability.Contains('BODY STATE NOT INITIALIZED')) 'Readiness diagnostics must distinguish initialization failure.'
Check ($presentation.Contains('public let diagnosticFailure: Bool = false;')) 'Biology view model must explicitly distinguish diagnostic failure.'
Check ($presentation.Contains('[ BIOLOGY ERROR ]')) 'Biology runtime failure must be visibly distinct from physiology status.'
Check (-not $presentation.Contains('[ BIOLOGY ERROR ] STABLE')) 'Unavailable body state must never be disguised as STABLE.'

# Native actions must retry the same authority and yield safely when it is unavailable.
Check ($hooks.Contains('public static func Ready() -> Bool')) 'Native body consumers must share the readiness bridge.'
Check ($hooks.Contains('return CRBiologyRuntimeAvailability.EnsureActive();')) 'Native body readiness must delegate to the authoritative bridge.'
Check ($hooks.Contains('!CRBodyRuntimeMasterPolicy.Ready(gameInstance)')) 'MaxDoc/native action interception must use the action-owned session when checking Biology readiness.'
Check ($hooks -match 'if !IsDefined\(executor\)[\s\S]*?!CRBodyRuntimeMasterPolicy\.Ready\(gameInstance\)[\s\S]*?wrappedMethod\(actionEffects, gameInstance\);[\s\S]*?return;') 'MaxDoc/native action interception must fail open to vanilla when Biology is unavailable.'

# BIO-01/02: stock minigrids spawn asynchronously, so mode has to be applied at the
# actual OnMinigridSpawned boundary rather than only during RipperDoc initialization.
Check ($sync.Contains('protected cb func OnMinigridSpawned(widget: ref<inkWidget>, userData: ref<IScriptable>) -> Bool')) 'Biology must observe the native asynchronous minigrid creation boundary.'
Check ($sync.Contains('let result: Bool = wrappedMethod(widget, userData);')) 'Biology minigrid hook must preserve stock creation first.'
Check ($sync.Contains('minigrid.CRSetBiologyMode(this.crBiologyShellMode);')) 'Every newly spawned native node must inherit the active Biology/Cyberware mode.'
Check ($sync.Contains('minigrid.CRSetBiologyLabelInteractive(this.crBiologyShellMode')) 'Every newly spawned Biology node must inherit native-node interactivity.'
Check ($shell.Contains('inkWidgetRef.SetVisible(this.m_gridContainer, false);')) 'Biology mode must hide stock equipment cards rather than duplicating them.'
Check ($shell.Contains('this.UpdateTitle(this.GetAreaHeader(area));')) 'Cyberware mode must restore the stock category title path.'

# NAV-01: relabel the canonical menu data source plus Inventory's independently-built
# adjacent hyperlink, while leaving the native route/identifier intact.
Check ($navigation.Contains('@wrapMethod(HubMenuUtility)')) 'Biology navigation must relabel the canonical menu-data source.'
Check ($navigation.Contains('public static func CreateMenuData(player: wref<PlayerPuppet>) -> ref<MenuDataBuilder>')) 'Biology must wrap the native menu-data builder with the expected seam.'
Check ($navigation.Contains('this.m_data[i].label = "BIOLOGY";')) 'Canonical Cyberware destination data must become BIOLOGY.'
Check ($navigation.Contains('@wrapMethod(gameuiInventoryGameController)')) 'Inventory adjacent navigation must be repaired at its independent native seam.'
Check ($navigation.Contains('data.fullscreenName = n"cyberware_equip";')) 'Navigation relabel must preserve Cyberpunk cyberware_equip routing.'
Check ($navigation.Contains('data.identifier = EnumInt(HubMenuItems.Cyberware);')) 'Navigation relabel must preserve the native Cyberware identifier.'

# NAV-02: the attended y=92 placement collided with stock navigation. The sync layer
# deliberately moves the shared submode control below that band; pixel-perfect proof
# remains an attended game acceptance item.
Check ($sync.Contains('this.crBiologyModeBar.SetMargin(inkMargin(0.0, 154.0, 0.0, 0.0));')) 'Biology/Cyberware selector must not remain at the attended overlapping y=92 placement.'

Write-Host "PASS: $script:checks Biology runtime/navigation lifecycle checks."
