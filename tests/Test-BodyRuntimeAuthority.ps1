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
$availability = Read-Project 'src/redscript/CyberpunkRealism/BiologyRuntimeAvailability.reds'
$presentation = Read-Project 'src/redscript/CyberpunkRealism/BiologyPresentation.reds'
$bodyStatus = Read-Project 'src/redscript/CyberpunkRealism/BodyStatusPresentation.reds'
$nativeHooks = Read-Project 'src/redscript/CyberpunkRealism/BodyNativeHooks.reds'
$ownedBuilder = Read-Project 'tools/Build-OwnedAcceptance.ps1'
$packageBuilder = Read-Project 'tools/Build-BiologyPackage.ps1'

# Registration / retrieval contract: explicit game-owned probing populates only a
# weak reference to the existing ScriptableSystem. Physiology itself remains on the
# original persistent CRBodyRuntime fields.
Check ($authority -match 'GetForGame\(game: GameInstance\)') 'Authority seam lacks explicit GameInstance retrieval.'
Check ($authority -match 'GetScriptableSystemsContainer\(game\)\.Get\(n"CyberpunkRealism\.Integration\.CRBodyRuntime"\)') 'Authority seam must retrieve the fully-qualified body ScriptableSystem from the supplied session.'
Check ($authority -match 'private static let crAuthorityInstance: wref<CRBodyRuntime>') 'Authority cache must be a weak reference, not duplicate body state.'
Check ($runtime -match 'private persistent let body: ref<CRBodyState>') 'Persistent physiology moved away from CRBodyRuntime.'
Check ($runtime -match 'private persistent let bodySchemaVersion: Int32') 'Body save schema authority moved away from CRBodyRuntime.'
Check ($authority -notmatch 'persistent let') 'Authority seam must not create persistent physiology or a second saved runtime.'

# Session lifecycle: ScriptableSystem attach/restore re-bind authority; detach drops
# it only after the existing teardown path runs. Player attachment provides a known
# game-owned context to distinguish registration failure from caller-context failure.
Check ($authority -match '@wrapMethod\(CRBodyRuntime\)[\s\S]*?private func OnAttach\(\)') 'Body authority does not bind during ScriptableSystem attach.'
Check ($authority -match '@wrapMethod\(CRBodyRuntime\)[\s\S]*?private func OnRestored\(saveVersion: Int32, gameVersion: Int32\)') 'Body authority does not re-bind on save restore.'
Check ($authority -match '@wrapMethod\(CRBodyRuntime\)[\s\S]*?private func OnDetach\(\)') 'Body authority lacks session detach cleanup.'
Check ($authority -match 'CRBodyRuntime\.GetForGame\(this\.GetGame\(\)\)') 'Player attach does not probe the body runtime through the player-owned GameInstance.'
Check ($authority -match 'public func AuthorityGame\(\) -> GameInstance[\s\S]*?this\.GetGameInstance\(\)') 'Runtime does not expose its own ScriptableSystem-owned GameInstance.'

# Once the runtime is found, body timing/player/menu/delay work must stay on that
# same session rather than jumping back through the global convenience function.
foreach ($required in @(
    'GetPlayerSystem\(this\.GetGameInstance\(\)\)',
    'GetBlackboardSystem\(this\.GetGameInstance\(\)\)',
    'GetTimeSystem\(this\.GetGameInstance\(\)\)',
    'GetSimTime\(this\.GetGameInstance\(\)\)',
    'GetDelaySystem\(this\.GetGameInstance\(\)\)'
)) {
    Check ($authority -match $required) "Session-owned body runtime path missing: $required"
}
Check ($authority -notmatch 'GetScriptableSystemsContainer\(GetGameInstance\(\)\)') 'Authority seam regressed to global ScriptableSystem retrieval.'

# Readiness must remain authority-backed. Retry may activate the same singleton, but
# missing registration/context, unsupported saves, initialization failure and stopped
# runtime all remain explicit diagnostic failures.
Check ($authority -match '@replaceMethod\(CRBiologyRuntimeAvailability\)[\s\S]*?public static func EnsureActive\(\)') 'Readiness path was not replaced by session-owned authority.'
foreach ($reason in @(
    'BODY RUNTIME BUILD GATE CLOSED',
    'BODY RUNTIME SYSTEM MISSING: NOT REGISTERED',
    'BODY RUNTIME SYSTEM MISSING: SESSION CONTEXT UNAVAILABLE',
    'BODY SAVE VERSION UNSUPPORTED',
    'BODY RUNTIME NOT INITIALIZED',
    'BODY RUNTIME NOT RUNNING'
)) {
    Check ($authority.Contains($reason)) "Missing explicit runtime diagnostic: $reason"
}
Check ($presentation -match 'Diagnostic\(result, CRBiologyRuntimeAvailability\.FailureReason\(\)\)') 'Biology overview no longer surfaces authoritative runtime failure.'
Check ($presentation -notmatch 'diagnosticFailure\s*=\s*false[\s\S]*STABLE') 'Presentation introduced a fake healthy fallback.'
Check ($bodyStatus -match 'if Equals\(result, ""\)[\s\S]*?return "STABLE"') 'Healthy STABLE status no longer depends on a real evaluated body state.'

# Existing save/time behavior must remain the single runtime path. The authority seam
# changes context ownership only; it must not replace wait/sleep/time-skip commits.
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

# Subordinate body systems must resolve from the same authoritative session, not a
# second GameInstance path.
foreach ($system in @(
    'CyberpunkRealism\.Integration\.CRPainRuntime',
    'CyberpunkRealism\.Integration\.CRFieldCareActionRuntime',
    'CyberpunkRealism\.Integration\.CRInjuryProvenanceRuntime',
    'CRInjuryEffectsRuntime'
)) {
    Check ($authority -match "GetScriptableSystemsContainer\(body\.AuthorityGame\(\)\)\.Get\(n\`"$system\`"\)") "Subordinate runtime is not bound to body session: $system"
}

# Packaging: the accepted builder enumerates the complete project REDscript source
# set into the exact owned-runtime manifest, and the final Biology package consumes
# that exact manifest. Presence of this file is therefore package-covered rather
# than relying on a separate compile-only source route.
Check ($ownedBuilder -match "Get-ChildItem[^\r\n]+CyberpunkRealism[^\r\n]+Filter '\*\.reds'") 'Owned acceptance builder no longer enumerates project REDscript files.'
Check ($packageBuilder -match 'owned-runtime-manifest\.json') 'Biology package builder no longer consumes the exact owned-runtime manifest.'
Check ($ownedBuilder -match 'exact') 'Owned-runtime builder no longer documents/enforces exact compilation semantics.'

Write-Host "PASS: $script:checks body-runtime authority checks. Static/cloud coverage cannot prove CP2077 2.31 ScriptableSystem registration; exact local compile and attended game evidence remain required."
