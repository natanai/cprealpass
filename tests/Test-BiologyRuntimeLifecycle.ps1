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

# STATE-01/02: one persistent authority. #41 adds session-aware access without adding
# a second body state, while #39 only consumes that authority from the native shell.
Check ($runtime.Contains('private persistent let body: ref<CRBodyState>;')) 'Body authority must remain persistent on CRBodyRuntime.'
Check ($runtime.Contains('private func OnRestored(saveVersion: Int32, gameVersion: Int32) -> Void')) 'Body runtime must explicitly handle save restoration.'
Check ($runtime.Contains('this.ResetTransientState();')) 'Body restore must rebuild transient state instead of duplicating persisted body state.'
Check ($availability.Contains('let runtime: ref<CRBodyRuntime> = CRBodyRuntime.Get();')) 'Legacy readiness path must still point at authoritative CRBodyRuntime.'
Check ($availability.Contains('if !runtime.IsRunning() || !runtime.OwnsNeeds()')) 'Biology readiness must recover a restored/non-running runtime.'
Check ($availability.Contains('runtime.Activate();')) 'Biology readiness must retry authoritative activation.'
Check (-not $availability.Contains('new CRBodyState')) 'Biology readiness must not create duplicate body state.'
Check (-not $availability.Contains('CRBodyModel.Create')) 'Biology readiness must not bypass CRBodyRuntime body creation.'
Check ($presentation.Contains('CRBiologyRuntimeAvailability.EnsureActive()')) 'Legacy Biology view-model reads must retain fail-obvious readiness handling.'
Check ($status.Contains('return CRBiologyRuntimeAvailability.EnsureActive();')) 'Shared body presentation ownership must retain the readiness bridge.'

# STATE-04: runtime failure remains explicit. UI integration must not cosmetically
# disguise #41-style authority failure as a healthy STABLE body.
Check ($availability.Contains('BODY RUNTIME BUILD GATE CLOSED')) 'Readiness diagnostics must distinguish a closed build gate.'
Check ($availability.Contains('BODY RUNTIME SYSTEM MISSING')) 'Readiness diagnostics must distinguish a missing ScriptableSystem.'
Check ($availability.Contains('BODY STATE NOT INITIALIZED')) 'Readiness diagnostics must distinguish initialization failure.'
Check ($presentation.Contains('public let diagnosticFailure: Bool = false;')) 'Biology view model must explicitly distinguish diagnostic failure.'
Check ($presentation.Contains('[ BIOLOGY ERROR ]')) 'Biology runtime failure must be visibly distinct from physiology status.'
Check (-not $presentation.Contains('[ BIOLOGY ERROR ] STABLE')) 'Unavailable body state must never be disguised as STABLE.'
Check ($shell.Contains('[ BIOLOGY ERROR ] BODY DETAIL UNAVAILABLE')) 'Detail must also fail visibly rather than fabricate body values.'

# Native actions use the same authority. The action-owned GameInstance is now passed
# through the attended runtime-authority seam and unavailable Biology yields to vanilla.
Check ($hooks.Contains('public static func Ready() -> Bool')) 'Native body consumers must retain the compatibility readiness bridge.'
Check ($hooks.Contains('return CRBiologyRuntimeAvailability.EnsureActive();')) 'Compatibility readiness must still delegate to authoritative availability.'
Check ($hooks.Contains('!CRBodyRuntimeMasterPolicy.Ready(gameInstance)')) 'MaxDoc/native action interception must use the action-owned session when checking Biology readiness.'
Check ($hooks -match 'if !IsDefined\(executor\)[\s\S]*?!CRBodyRuntimeMasterPolicy\.Ready\(gameInstance\)[\s\S]*?wrappedMethod\(actionEffects, gameInstance\);[\s\S]*?return;') 'MaxDoc/native action interception must fail open to vanilla when Biology is unavailable.'

# Stock minigrids spawn asynchronously. Biology must apply overview-node state at the
# native creation boundary and make those overview labels noninteractive in detail.
Check ($sync.Contains('protected cb func OnMinigridSpawned(widget: ref<inkWidget>, userData: ref<IScriptable>) -> Bool')) 'Biology must observe native asynchronous minigrid creation.'
Check ($sync.Contains('let result: Bool = wrappedMethod(widget, userData);')) 'Biology minigrid hook must preserve stock creation first.'
Check ($sync.Contains('minigrid.CRSetBiologyMode(this.crBiologyShellMode);')) 'Newly spawned native node must inherit active mode.'
Check ($sync.Contains('minigrid.CRSetBiologyLabelInteractive(') -and $sync.Contains('!this.CRBodyShellInDetail()')) 'Newly spawned Biology node does not respect detail-depth interactivity.'
Check ($shell.Contains('inkWidgetRef.SetVisible(this.m_gridContainer, false);')) 'Biology mode must hide stock equipment cards rather than duplicate them.'
Check ($shell.Contains('this.UpdateTitle(this.GetAreaHeader(area));')) 'Cyberware mode must restore stock category title.'

# Navigation relabel remains on the native cyberware_equip route.
Check ($navigation.Contains('@wrapMethod(HubMenuUtility)')) 'Biology navigation must relabel canonical menu-data source.'
Check ($navigation.Contains('public static func CreateMenuData(player: wref<PlayerPuppet>) -> ref<MenuDataBuilder>')) 'Biology must wrap expected native menu-data builder seam.'
Check ($navigation.Contains('this.m_data[i].label = "BIOLOGY";')) 'Canonical Cyberware destination data must become BIOLOGY.'
Check ($navigation.Contains('@wrapMethod(gameuiInventoryGameController)')) 'Inventory adjacent navigation must be repaired at its independent native seam.'
Check ($navigation.Contains('data.fullscreenName = n"cyberware_equip";')) 'Navigation relabel must preserve cyberware_equip routing.'
Check ($navigation.Contains('data.identifier = EnumInt(HubMenuItems.Cyberware);')) 'Navigation relabel must preserve native Cyberware identifier.'

# The internal selector is discoverable at overview depth and hidden at native detail
# depth. Pixel-perfect placement remains attended acceptance rather than CI proof.
Check ($shell.Contains('this.crBiologyModeBar.SetMargin(inkMargin(0.0, 154.0, 0.0, 0.0));')) 'Biology/Cyberware selector regressed to the attended y=92 collision band.'
Check ($shell.Contains('CRShellText(text, name, 28)')) 'Biology/Cyberware selector remains at the undersized prototype scale.'
Check ($shell.Contains('this.crBiologyModeBar.SetVisible(!this.CRBodyShellInDetail())')) 'Internal mode selector is still available while drilled down.'

Write-Host "PASS: $script:checks Biology runtime-consumer and native-shell lifecycle checks."
