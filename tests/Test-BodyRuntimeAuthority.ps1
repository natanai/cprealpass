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
$runtime = Read-Project 'src/redscript/CyberpunkRealism/BodyRuntime.reds'
$pain = Read-Project 'src/redscript/CyberpunkRealism/PainRuntime.reds'
$effects = Read-Project 'src/redscript/CyberpunkRealism/InjuryEffectsNative.reds'
$availability = Read-Project 'src/redscript/CyberpunkRealism/BiologyRuntimeAvailability.reds'
$sessionPresentation = Read-Project 'src/redscript/CyberpunkRealism/BiologySessionPresentation.reds'
$shell = Read-Project 'src/redscript/CyberpunkRealism/BiologyCyberwareShell.reds'
$nativeHooks = Read-Project 'src/redscript/CyberpunkRealism/BodyNativeHooks.reds'
$ownedBuilder = Read-Project 'tools/Build-OwnedAcceptance.ps1'
$packageBuilder = Read-Project 'tools/Build-BiologyPackage.ps1'
$dependencyGraph = Read-Project 'manifest/dependency-graph.json'

# The body remains exactly one persistent Biology ScriptableSystem. Session lookup and
# menu projection are stateless helpers, never alternate physiology authorities.
Check ($runtime -match 'public class CRBodyRuntime extends ScriptableSystem') 'CRBodyRuntime is no longer the authoritative ScriptableSystem.'
Check ($runtime -match 'private persistent let body: ref<CRBodyState>') 'Persistent physiology moved away from CRBodyRuntime.'
Check ($runtime -match 'private persistent let bodySchemaVersion: Int32') 'Body save schema authority moved away from CRBodyRuntime.'
Check ($authority -match 'public class CRBiologySessionAuthority extends IScriptable') 'Explicit-session authority helper is missing.'
Check ($authority -notmatch 'persistent let') 'Session authority helper must not persist a second body or lifecycle state.'
Check ($authority -notmatch 'new CRBodyState') 'Session authority helper manufactured substitute physiology.'
Check ($sessionPresentation -notmatch 'persistent let') 'Session presentation helper must remain read-only/transient.'
Check ($sessionPresentation -notmatch 'new CRBodyState') 'Session presentation helper manufactured substitute physiology.'
Check (-not (Test-Path -LiteralPath (Join-Path $project 'src/redscript/CyberpunkRealism/BodyRuntimeAuthorityAccess.reds'))) 'Superseded project-class authority patch layer still exists.'
Check (-not (Test-Path -LiteralPath (Join-Path $project 'src/redscript/CyberpunkRealism/BiologyRuntimeConsumer.reds'))) 'Superseded stacked Biology consumer patch layer still exists.'

# Project-owned behavior is declared on project classes or helpers directly. The
# authority helper itself must never masquerade as a redscript native patch surface.
foreach ($annotation in @('@addMethod','@replaceMethod','@addField','@wrapMethod')) {
    Check (-not $authority.Contains($annotation)) "Session authority helper contains native patch annotation: $annotation"
}
Check ($runtime -notmatch '@(?:addMethod|replaceMethod|addField)\(CR') 'CRBodyRuntime ownership regressed to project-class patch annotations.'
Check ($pain -notmatch '@(?:addMethod|replaceMethod|addField)\(CR') 'CRPainRuntime ownership regressed to project-class patch annotations.'

# Explicit GameInstance lookup uses the registered ScriptableSystem container and the
# actual module-qualified class names without a pseudo-cache or global bootstrap.
Check ($authority -match 'public static func Body\(game: GameInstance\) -> ref<CRBodyRuntime>') 'Body authority lacks explicit GameInstance retrieval.'
Check ($authority -match 'GameInstance\.GetScriptableSystemsContainer\(game\)') 'Body authority does not validate the supplied session container.'
Check ($authority -match 'container\.Get\(n"CyberpunkRealism\.Integration\.CRBodyRuntime"\) as CRBodyRuntime') 'Body authority does not use the registered module-qualified system name.'
Check ($authority -match 'public static func BodyProbe\(game: GameInstance\) -> Int32') 'Body authority lacks registration/session probe.'
Check ($authority -notmatch 'GetGameInstance\(\)') 'Explicit authority helper regressed to parameterless global GameInstance retrieval.'
foreach ($systemMethod in @('Pain','FieldCare','Provenance','InjuryEffects')) {
    Check ($authority -match "public static func $systemMethod\(game: GameInstance\)") "Missing explicit-session subordinate lookup: $systemMethod"
}

# Body-owned lifecycle/time/player work uses the ScriptableSystem-owned session and
# the tick callback carries the already-resolved authoritative instance.
foreach ($required in @(
    'GetPlayerSystem\(this\.GetGameInstance\(\)\)',
    'GetTimeSystem\(this\.GetGameInstance\(\)\)',
    'GetSimTime\(this\.GetGameInstance\(\)\)',
    'GetDelaySystem\(this\.GetGameInstance\(\)\)'
)) {
    Check ($runtime -match $required) "Session-owned body runtime path missing: $required"
}
Check ($runtime -match 'CRPlayerBodyLifecycle\.Allowed\(this\.Player\(\), allowMenu\)') 'Body runtime does not delegate player eligibility to the shared player-session lifecycle adapter.'
Check ($nativeHooks -match 'GetBlackboardSystem\(player\.GetGame\(\)\)') 'Player lifecycle adapter does not use the authoritative player session for menu state.'
Check ($nativeHooks -match 'GetTimeSystem\(player\.GetGame\(\)\)\.IsPausedState\(\)') 'Player lifecycle adapter does not use the authoritative player session for pause state.'
Check ($runtime -match 'public let crOwner: wref<CRBodyRuntime>') 'Tick callback does not carry the authoritative body instance.'
Check ($runtime -match 'this\.crOwner\.HandleTick\(this\.generation\)') 'Tick callback still rediscovers the body globally.'
Check ($runtime -match 'callback\.crOwner = this') 'Scheduled tick does not retain the owning CRBodyRuntime.'
Check ($runtime -match 'public func HasUnsupportedSaveVersion\(\) -> Bool') 'Unsupported-save diagnostic is no longer owned directly by CRBodyRuntime.'
Check ($pain -match 'CRBiologySessionAuthority\.Body\(this\.GetGameInstance\(\)\)') 'Pain runtime no longer shares its own session with the body authority.'
Check ($effects -match 'CRBiologySessionAuthority\.Body\(this\.GetGameInstance\(\)\)') 'Injury-effects runtime no longer shares its own session with the body authority.'
Check ($effects -match 'GetPlayerSystem\(this\.GetGameInstance\(\)\)') 'Injury-effects refresh regressed to global session discovery.'

# Readiness/gates accept explicit sessions directly from their owning project classes.
Check ($availability -match 'public static func Enabled\(game: GameInstance\) -> Bool') 'Biology availability lacks explicit-session enable check.'
Check ($availability -match 'public static func EnsureActive\(game: GameInstance\) -> Bool') 'Biology availability lacks explicit-session activation.'
Check ($availability -match 'CRBiologySessionAuthority\.Body\(game\)') 'Biology availability does not resolve the authoritative runtime from the supplied session.'
Check ($nativeHooks -match 'public static func Enabled\(game: GameInstance\) -> Bool') 'Master policy lacks directly owned explicit-session enable overload.'
Check ($nativeHooks -match 'public static func Ready\(game: GameInstance\) -> Bool') 'Master policy lacks directly owned explicit-session readiness overload.'
Check ($nativeHooks -match 'EnsureActive\(game\)') 'Master policy explicit-session readiness does not delegate to authoritative availability.'

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
    Check ($availability.Contains($reason)) "Missing explicit runtime diagnostic: $reason"
}

# Native Biology shell owns one refresh implementation and supplies its controlled
# player's session to the read-only session projection. #39's native anchor remains
# authoritative; the removed #41 replacement layer must not return.
Check ($sessionPresentation -match 'public static func Current\(game: GameInstance\) -> ref<CRBiologyViewModel>') 'Session overview projection is missing.'
Check ($sessionPresentation -match 'public static func Detail\(game: GameInstance, area: gamedataEquipmentArea\) -> ref<CRBiologyDetailViewModel>') 'Session detail projection is missing.'
Check ($sessionPresentation -match 'CRBiologyRuntimeAvailability\.EnsureActive\(game\)') 'Session presentation does not require authoritative readiness.'
Check ($sessionPresentation -match 'return "STABLE"') 'Session body presentation lost healthy stable state.'
Check ($sessionPresentation -match 'if !IsDefined\(runtime\) \|\| !IsDefined\(body\)') 'STABLE can be reached without a real runtime/body guard.'
Check ($shell -match 'public final func CRRefreshBiologyOverview\(\) -> Void') 'Biology overview shell refresh is missing.'
Check ($shell -match 'private final func CRRefreshBiologyDetail\(\) -> Void') 'Biology detail shell refresh is missing.'
Check ($shell -match 'this\.GetPlayerControlledObject\(\)') 'Biology shell does not derive context from its controlled game object.'
Check ($shell -match 'CRBiologySessionPresentation\.Current\(player\.GetGame\(\)\)') 'Biology overview does not pass the menu-owned GameInstance.'
Check ($shell -match 'CRBiologySessionPresentation\.Detail\(player\.GetGame\(\), this\.crBiologySelectedArea\)') 'Biology detail does not use the same authoritative session.'
Check ($shell -match '\[ BIOLOGY ERROR \] BODY RUNTIME PLAYER UNAVAILABLE') 'Player-unavailable menu failure is no longer explicit.'
Check ($shell -match 'crBiologyNativeContent') '#39 native content anchor disappeared.'
Check ($shell -notmatch 'crBiologyDetailPanel') 'Stale parallel Biology detail panel returned.'
Check ($shell -notmatch '@replaceMethod\(RipperDocGameController\)') 'Biology shell refresh ownership is stacked through replacement annotations again.'
Check ($shell -match 'Equals\(this\.m_filterMode, RipperdocModes\.Item\)') 'RipperdocModes comparison is not using compiler-supported enum equality.'
Check ($shell -notmatch 'm_filterMode\s*==\s*RipperdocModes\.Item') 'Unsupported RipperdocModes OperatorEqual comparison returned.'

# Existing save/load and time progression remain one CRBodyRuntime path. The repair
# changes source ownership/context routing, not the physiology/timeskip model.
foreach ($contract in @(
    'private func OnRestored\(saveVersion: Int32, gameVersion: Int32\)',
    'public func BeginSkip\(\)',
    'public func FinishSkipHours\(hoursRequested: Float, sleeping: Bool\)',
    'public func Observe\(\)',
    'public func GetBodySnapshot\(\)'
)) {
    Check ($runtime -match $contract) "Body lifecycle contract disappeared: $contract"
}
Check ($nativeHooks -match 'MarkNextTimeSkipAsWait\(\)') 'Wait classification hook disappeared.'
Check ($nativeHooks -match 'FinishSkipHours\(Cast<Float>\(hours\), this\.crRealpassSleeping\)') 'Committed wait/sleep progression hook disappeared.'
Check ($nativeHooks -match 'CRBiologySessionAuthority\.Body\(gameInstance\)') 'Native action path no longer resolves body from its explicit GameInstance.'
Check ($nativeHooks -match 'CRBiologySessionAuthority\.Pain\(gameInstance\)') 'MaxDoc path no longer resolves pain runtime from its explicit GameInstance.'

# REDmod-first packaging still exact-compiles the complete owned source tree and
# remains independent of Codeware as a runtime authority.
Check ($ownedBuilder.Contains('$sourceRoot = Resolve-SafeChildPath $project ''src/redscript/CyberpunkRealism''')) 'Owned acceptance builder source root no longer points at the complete project REDscript tree.'
Check ($ownedBuilder.Contains('$sourceFiles = @(Get-ChildItem -LiteralPath $sourceRoot -File -Filter ''*.reds'' | Sort-Object Name)')) 'Owned acceptance builder no longer enumerates every project REDscript file.'
Check ($packageBuilder.Contains('$runtimeManifestRelative = & "$PSScriptRoot\Build-OwnedRuntimeProfile.ps1" @profileArgs')) 'Biology package builder no longer obtains its exact runtime manifest from the owned-runtime profile builder.'
Check ($packageBuilder.Contains('$runtimeManifest = Get-Content -Raw -LiteralPath $runtimeManifestPath | ConvertFrom-Json')) 'Biology package builder no longer consumes the runtime manifest it exact-compiled.'
Check ($ownedBuilder -match 'exact') 'Owned-runtime builder no longer documents/enforces exact compilation semantics.'
Check ($dependencyGraph -match '"id": "codeware"[\s\S]*?"status": "not-required"') 'Dependency graph no longer records Codeware as non-required.'
Check ($dependencyGraph -match '"id": "redscript"[\s\S]*?"status": "required-current-runtime"') 'Dependency graph no longer records redscript as required current runtime.'

Write-Host "PASS: $script:checks compile-valid body-runtime authority checks. Cloud/static coverage proves source ownership and packaging contracts only; CP2077 2.31 exact compilation remains the final authority."
