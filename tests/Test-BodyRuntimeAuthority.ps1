$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\tools\Common.ps1"
$project = Get-ProjectRoot
$script:checks = 0
function Check($condition,[string]$message) { if (-not $condition) { throw $message }; $script:checks++ }
function Read-Project([string]$relative) {
    $path = Join-Path $project $relative
    Check (Test-Path -LiteralPath $path -PathType Leaf) "Missing required file: $relative"
    return Get-Content -Raw -LiteralPath $path
}

$authority = Read-Project 'src/redscript/CyberpunkRealism/BodyRuntimeAuthority.reds'
$authorityAccess = Read-Project 'src/redscript/CyberpunkRealism/BodyRuntimeAuthorityAccess.reds'
$consumer = Read-Project 'src/redscript/CyberpunkRealism/BiologyRuntimeConsumer.reds'
$runtime = Read-Project 'src/redscript/CyberpunkRealism/BodyRuntime.reds'
$presentation = Read-Project 'src/redscript/CyberpunkRealism/BiologyPresentation.reds'
$bodyStatus = Read-Project 'src/redscript/CyberpunkRealism/BodyStatusPresentation.reds'
$nativeHooks = Read-Project 'src/redscript/CyberpunkRealism/BodyNativeHooks.reds'
$ownedBuilder = Read-Project 'tools/Build-OwnedAcceptance.ps1'
$packageBuilder = Read-Project 'tools/Build-BiologyPackage.ps1'
$dependencyGraph = Read-Project 'manifest/dependency-graph.json'

# The body remains one persistent ScriptableSystem. This follow-up may add retrieval
# and diagnostics, but it must not add another persistent body, UI state authority,
# static pseudo-cache, or fallback physiology.
Check ($runtime -match 'public class CRBodyRuntime extends ScriptableSystem') 'CRBodyRuntime is no longer the authoritative ScriptableSystem.'
Check ($runtime -match 'private persistent let body: ref<CRBodyState>') 'Persistent physiology moved away from CRBodyRuntime.'
Check ($runtime -match 'private persistent let bodySchemaVersion: Int32') 'Body save schema authority moved away from CRBodyRuntime.'
Check ($authority -notmatch 'persistent let') 'Authority seam must not persist a second body or lifecycle state.'
Check ($consumer -notmatch 'persistent let') 'Menu consumer seam must remain read-only/transient.'
Check ($authority -notmatch 'static let crAuthority') 'Unsupported static ScriptableSystem cache returned.'
Check ($consumer -notmatch 'new CRBodyState') 'Menu consumer manufactured substitute physiology.'

# Registration/retrieval contract: callers with real game ownership pass an explicit
# GameInstance, the container is checked, and the module-qualified registered class
# name is visible at the boundary. There is no global GetGameInstance bootstrap in
# this explicit authority seam.
Check ($authority -match 'public static func Get\(game: GameInstance\) -> ref<CRBodyRuntime>') 'Body authority lacks explicit GameInstance retrieval.'
Check ($authority -match 'let container: ref<ScriptableSystemsContainer> = GameInstance\.GetScriptableSystemsContainer\(game\)') 'Body authority does not validate the supplied session container.'
Check ($authority -match 'container\.Get\(n"CyberpunkRealism\.Integration\.CRBodyRuntime"\) as CRBodyRuntime') 'Body authority does not use the registered module-qualified system name.'
Check ($authority -match 'public static func SessionProbe\(game: GameInstance\) -> Int32') 'Body authority lacks registration/session probe.'
Check ($authority -notmatch 'GetScriptableSystemsContainer\(GetGameInstance\(\)\)') 'Explicit authority seam regressed to parameterless global GameInstance retrieval.'

# Body-owned lifecycle/time/player work must use the ScriptableSystem-owned session.
foreach ($required in @(
    'GetPlayerSystem\(this\.GetGameInstance\(\)\)',
    'GetBlackboardSystem\(this\.GetGameInstance\(\)\)',
    'GetTimeSystem\(this\.GetGameInstance\(\)\)',
    'GetSimTime\(this\.GetGameInstance\(\)\)',
    'GetDelaySystem\(this\.GetGameInstance\(\)\)'
)) {
    Check ($authority -match $required) "Session-owned body runtime path missing: $required"
}
Check ($authority -match '@addField\(CRBodyTickCallback\)[\s\S]*?crOwner: wref<CRBodyRuntime>') 'Tick callback does not carry the authoritative body instance.'
Check ($authority -match '@replaceMethod\(CRBodyTickCallback\)[\s\S]*?this\.crOwner\.HandleTick') 'Tick callback still rediscovers the body globally.'
Check ($authority -match 'EnsureActive\(this\.GetGame\(\)\)') 'Player attachment does not supply its game-owned session to Biology readiness.'

# Subordinate systems must have explicit same-session retrieval paths. Their state is
# not copied into the body or UI.
foreach ($system in @(
    'CRPainRuntime',
    'CRFieldCareActionRuntime',
    'CRInjuryProvenanceRuntime',
    'CRInjuryEffectsRuntime'
)) {
    Check ($authority -match "public static func Get\(game: GameInstance\) -> ref<$system>") "Missing explicit-session retrieval for $system."
}
Check ($authority -match 'CRBodyRuntime\.Get\(this\.GetGameInstance\(\)\)') 'Subordinate runtime lifecycle does not resolve body from its own session.'

# Save/session/readiness diagnostics remain explicit failures. Healthy presentation
# may say STABLE only after a real initialized body and real meter read.
Check ($authorityAccess -match 'return this\.unsupportedSaveVersion') 'Unsupported-save diagnostic does not read body-owned transient readiness.'
foreach ($reason in @(
    'BODY RUNTIME BUILD GATE CLOSED',
    'BODY RUNTIME SESSION CONTEXT UNAVAILABLE',
    'BODY RUNTIME SYSTEM NOT REGISTERED',
    'BODY RUNTIME SYSTEM MISSING',
    'BODY RUNTIME PLAYER UNAVAILABLE',
    'BODY SAVE VERSION UNSUPPORTED',
    'BODY RUNTIME NOT INITIALIZED',
    'BODY RUNTIME NOT RUNNING'
)) {
    Check ($authority.Contains($reason)) "Missing explicit runtime diagnostic: $reason"
}
Check ($presentation -match 'diagnosticFailure = true') 'Biology diagnostic path no longer remains explicitly unhealthy.'
Check ($consumer -match 'Diagnostic\(result, CRBiologyRuntimeAvailability\.FailureReason\(game\)\)') 'Explicit-session menu path hides runtime failure.'
Check ($consumer -match 'CRBodyStatusPresentation\.BodyStatus\(game, body\)') 'Menu view does not derive status from the retrieved authoritative body.'
Check ($consumer -match 'return "STABLE"') 'Explicit body presentation lost healthy stable state.'
Check ($consumer -match 'if !IsDefined\(runtime\)[\s\S]*?return "BODY UNAVAILABLE"') 'STABLE can be reached without a real runtime.'
Check ($bodyStatus -match 'if Equals\(result, ""\)[\s\S]*?return "STABLE"') 'Legacy healthy status no longer depends on evaluated body needs.'

# The live Biology controller must provide a game-owned context rather than asking
# the presentation layer to rediscover a global session. These replacements preserve
# #39's shell/layout behavior and alter only the data-consumer seam.
Check ($consumer -match '@replaceMethod\(RipperDocGameController\)[\s\S]*?CRRefreshBiologyOverview') 'Biology overview consumer seam is missing.'
Check ($consumer -match 'this\.GetPlayerControlledObject\(\)') 'Biology menu does not derive context from its controlled game object.'
Check ($consumer -match 'CRBiologyPresentation\.Current\(player\.GetGame\(\)\)') 'Biology overview does not pass the menu-owned GameInstance to the runtime.'
Check ($consumer -match 'CRBiologyDetailPresentation\.Current\(player\.GetGame\(\), this\.crBiologySelectedArea\)') 'Biology detail does not use the same authoritative session.'
Check ($consumer -match '\[ BIOLOGY ERROR \] BODY RUNTIME PLAYER UNAVAILABLE') 'Player-unavailable menu failure is no longer explicit.'

# Existing save/load and time progression remain one CRBodyRuntime path. The follow-up
# changes context ownership, not the physiology/timeskip model.
foreach ($contract in @(
    'private func OnRestored\(saveVersion: Int32, gameVersion: Int32\)',
    'public func BeginSkip\(\)',
    'public func FinishSkipHours\(hoursRequested: Float, sleeping: Bool\)',
    'public func Observe\(\)',
    'public func GetBodySnapshot\(\)'
)) {
    Check ($runtime -match $contract) "Body lifecycle contract disappeared: $contract"
}
Check ($authority -match '@replaceMethod\(CRBodyRuntime\)[\s\S]*?public func BeginSkip\(\)') 'Session-owned wait/sleep begin path is missing.'
Check ($authority -match '@replaceMethod\(CRBodyRuntime\)[\s\S]*?public func FinishSkipHours\(hoursRequested: Float, sleeping: Bool\)') 'Session-owned wait/sleep finish path is missing.'
Check ($nativeHooks -match 'MarkNextTimeSkipAsWait\(\)') 'Wait classification hook disappeared.'
Check ($nativeHooks -match 'FinishSkipHours\(Cast<Float>\(hours\), this\.crRealpassSleeping\)') 'Committed wait/sleep progression hook disappeared.'

# REDmod-first packaging must include the follow-up sources in the exact owned source
# set; it must not rely on a compile-only or stale transitional route. Codeware stays
# explicitly non-required, which is why no authority path may depend on its global
# GameInstance convenience guarantee.
Check ($ownedBuilder -match "\$sourceRoot = Resolve-SafeChildPath \$project 'src/redscript/CyberpunkRealism'") 'Owned acceptance builder source root no longer points at the complete project REDscript tree.'
Check ($ownedBuilder -match "\$sourceFiles = @\(Get-ChildItem -LiteralPath \$sourceRoot -File -Filter '\*\.reds'") 'Owned acceptance builder no longer enumerates every project REDscript file.'
Check ($packageBuilder -match 'owned-runtime-manifest\.json') 'Biology package builder no longer consumes the exact owned-runtime manifest.'
Check ($ownedBuilder -match 'exact') 'Owned-runtime builder no longer documents/enforces exact compilation semantics.'
Check ($dependencyGraph -match '"id": "codeware"[\s\S]*?"status": "not-required"') 'Dependency graph no longer records Codeware as non-required.'
Check ($dependencyGraph -match '"id": "redscript"[\s\S]*?"status": "required-current-runtime"') 'Dependency graph no longer records redscript as required current runtime.'

Write-Host "PASS: $script:checks body-runtime authority checks. Cloud/static coverage proves source and packaging contracts only; it cannot prove CP2077 2.31 live ScriptableSystem registration or attended lifecycle acceptance."
