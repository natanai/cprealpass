$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'Test-InstalledRuntimeActivationProbe.ps1 requires PowerShell 7 or newer.' }

$project = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$probePath = Join-Path $project 'tools\Probe-InstalledRuntimeActivation.ps1'
$bootstrapPath = Join-Path $project 'tools\Bootstrap-InstalledRuntimeActivationProbe.ps1'

function Read([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "Missing W13.1 evidence asset: $Path" }
    Get-Content -Raw -LiteralPath $Path
}
function Require([string]$Text,[string]$Pattern,[string]$Message) {
    if ($Text -notmatch $Pattern) { throw $Message }
}
function Reject([string]$Text,[string]$Pattern,[string]$Message) {
    if ($Text -match $Pattern) { throw $Message }
}
function Assert-Parses([string]$Path) {
    $tokens = $null
    $errors = $null
    [void][Management.Automation.Language.Parser]::ParseFile($Path,[ref]$tokens,[ref]$errors)
    if (@($errors).Count -gt 0) {
        throw ("PowerShell parse failure in ${Path}: " + (@($errors | ForEach-Object Message) -join ' | '))
    }
}

Assert-Parses $probePath
Assert-Parses $bootstrapPath
$probe = Read $probePath
$bootstrap = Read $bootstrapPath

# Inner probe: exact installed-candidate identity and first-boundary evidence.
Require $probe '68b50ed9e3c629ca252326918dbbb68b9bc35494' 'W13.1 probe must default to the exact canonical attended candidate revision.'
Require $probe 'biology\\build-manifest\.json' 'W13.1 probe must inspect the installed schema-2 Biology receipt.'
Require $probe 'sourceRevision' 'W13.1 probe must bind evidence to the installed source revision.'
Require $probe 'Get-FileHash.*SHA256|Get-FileHash\s+-Algorithm\s+SHA256' 'W13.1 probe must hash installed receipt-owned files.'
Require $probe 'foreach \(\$entry in \$entries\)' 'W13.1 probe must verify the full installed receipt rather than a few hand-picked files.'
Require $probe 'r6/scripts/CyberpunkRealism/RealpassSettings\.reds' 'W13.1 probe must inspect the activation accessor source at its installed loader path.'
Require $probe 'r6/scripts/CyberpunkRealism/BiologyRuntimeAvailability\.reds' 'W13.1 probe must inspect the runtime-availability path.'
Require $probe 'r6/scripts/CyberpunkRealism/BodyRuntime\.reds' 'W13.1 probe must inspect the body runtime source path.'
Require $probe 'r6/scripts/CyberpunkRealism/BiologyRadialHubNative\.reds' 'W13.1 probe must inspect the radial hub hook source path.'
Require $probe 'engine/config/base/scripts\.ini' 'W13.1 probe must inspect the installed redscript loader config.'
Require $probe 'r6/config/cybercmd/scc\.toml' 'W13.1 probe must inspect the installed redscript/cybercmd config.'
Require $probe 'scriptsBlobPath' 'W13.1 probe must follow the REDscript output path configured by scc.toml.'
Require $probe 'Configured REDscript output blob from scc\.toml' 'W13.1 probe must record the exact configured compiled REDscript blob.'
Require $probe 'Configured REDscript output at-or-after latest verified payload timestamp' 'W13.1 probe must classify compiled-blob freshness against the installed candidate.'
Require $probe 'InvokeScc task configured' 'W13.1 probe must verify the configured startup compiler task.'
Require $probe 'bin/x64/plugins/cybercmd\.asi' 'W13.1 probe must inspect the standalone cybercmd task-runner path.'
Require $probe 'red4ext/RED4ext\.dll' 'W13.1 probe must inspect RED4ext only as an alternate task-provider presence check.'
Require $probe 'Compatible scc\.toml task runner present \(cybercmd or RED4ext\)' 'W13.1 probe must explicitly classify whether any supported scc.toml task runner is present.'
Require $probe 'STATIC ROOT-CAUSE EVIDENCE' 'W13.1 probe must report the static stale-output/no-task-runner cause when proven.'
Require $probe 'r6/logs/redscript_rCURRENT\.log' 'W13.1 probe may capture the REDscript current log as secondary context.'
Require $probe 'secondary' 'W13.1 probe must explicitly demote stale/absent REDscript log evidence below the configured output blob.'
Require $probe 'Get-Content.*-Tail 500' 'W13.1 probe must bound secondary REDscript log capture.'
Require $probe 'r6/cache/modded/mods\.json' 'W13.1 probe must inspect official REDmod generated mod metadata.'
Require $probe 'r6/cache/modded/tweakdb\.bin' 'W13.1 probe must inspect the generated base TweakDB output.'
Require $probe 'r6/cache/modded/tweakdb_ep1\.bin' 'W13.1 probe must inspect the generated EP1 TweakDB output when present.'
Require $probe 'BiologyLauncherActivationMarker' 'W13.1 probe must look for the exact deployed activation marker as corroborating evidence.'
Require $probe 'absence is INCONCLUSIVE|absence is inconclusive' 'W13.1 probe must not mistake plaintext marker absence in a binary TweakDB for proof that the sentinel is absent.'
Require $probe 'BOUNDARY 1 — ARTIFACT / INSTALL PLACEMENT' 'W13.1 probe must classify artifact/install placement explicitly.'
Require $probe 'BOUNDARY 2 — REDSCRIPT STARTUP / CONFIGURED COMPILE OUTPUT' 'W13.1 probe must classify the configured startup/compiler-output boundary explicitly.'
Require $probe 'FIRST PROVEN BROKEN BOUNDARY' 'W13.1 probe must report the earliest actually proven broken boundary.'
Require $probe 'NONE FROM READ-ONLY EXTERNAL EVIDENCE YET' 'W13.1 probe must preserve uncertainty when downstream breakage is not yet proven.'
Require $probe 'READ-ONLY|read-only' 'W13.1 probe must explicitly declare the installed game read-only.'
Require $probe 'not gameplay acceptance|not.*gameplay acceptance' 'W13.1 probe must not misreport evidence collection as attended acceptance.'
Require $probe 'Exception type:' 'W13.1 probe must preserve exception type on failure.'
Require $probe 'Error:' 'W13.1 probe must preserve actual error text on failure.'

# The inner probe may write only the requested external report; installed game is evidence-only.
Reject $probe '(?i)redMod\.exe.*deploy|Invoke-.*deploy' 'W13.1 inner probe must not redeploy Biology.'
Reject $probe '(?i)Start-Process[^\r\n]*Cyberpunk|Cyberpunk2077\.exe[^\r\n]*Start' 'W13.1 inner probe must not launch Cyberpunk.'
Reject $probe '(?i)(Copy-Item|Move-Item|Remove-Item|Set-Content|Add-Content)[^\r\n]*\$GameRoot' 'W13.1 inner probe must not mutate the installed game root.'

# Bootstrap: exact-head, local-first, failure-durable, disposable, and still read-only against the game.
Require $bootstrap '\[Parameter\(Mandatory=\$true\)\]\[string\]\$Branch' 'W13.1 bootstrap must require the exact worker branch.'
Require $bootstrap '\[Parameter\(Mandatory=\$true\)\]\[ValidatePattern\(''\^\[0-9a-fA-F\]\{40\}\$''\)\]\[string\]\$ExpectedHead' 'W13.1 bootstrap must require an exact 40-character worker head.'
Require $bootstrap '68b50ed9e3c629ca252326918dbbb68b9bc35494' 'W13.1 bootstrap must default to the exact installed canonical candidate revision.'
Require $bootstrap "'rev-parse','--show-toplevel'" 'W13.1 bootstrap must validate discovered repos through Git.'
Require $bootstrap "'remote','get-url','origin'" 'W13.1 bootstrap must validate cprealpass identity by origin.'
Reject $bootstrap [regex]::Escape('.git\config') 'W13.1 bootstrap must not regress to .git/config-only discovery.'
Require $bootstrap 'cprealpass-repo-' 'W13.1 bootstrap must support zero-local-repo acquisition with a uniquely signed seed clone.'
Require $bootstrap 'cached remote branch' 'W13.1 bootstrap must inspect cached origin branch after fetch failure.'
Require $bootstrap "'cat-file','-e'" 'W13.1 bootstrap must prove the expected commit object before offline fallback.'
Require $bootstrap 'Offline exact-head fallback: ACCEPTED' 'W13.1 bootstrap must record an accepted exact-head offline fallback.'
Require $bootstrap "'worktree','add','--detach'" 'W13.1 bootstrap must isolate the exact worker revision in a detached worktree.'
Require $bootstrap 'Probe-InstalledRuntimeActivation\.ps1' 'W13.1 bootstrap must invoke the repository-owned read-only inner probe.'
Require $bootstrap 'Biology-Installed-Runtime-Activation-Probe-' 'W13.1 bootstrap must write one plainly named attachable text report.'
Require $bootstrap 'ProcessStartInfo' 'W13.1 bootstrap must use ProcessStartInfo for evidence-bearing child processes.'
Require $bootstrap 'RedirectStandardOutput\s*=\s*\$true' 'W13.1 bootstrap must preserve child stdout.'
Require $bootstrap 'RedirectStandardError\s*=\s*\$true' 'W13.1 bootstrap must preserve child stderr.'
Require $bootstrap 'ArgumentList\.Add' 'W13.1 bootstrap must preserve native argument boundaries.'
Require $bootstrap 'StartException' 'W13.1 bootstrap must preserve child start exceptions.'
Require $bootstrap 'INNER W13\.1 PROBE PROCESS OUTPUT' 'W13.1 bootstrap must label persisted inner probe diagnostics.'
Require $bootstrap 'Exception type:' 'W13.1 bootstrap must preserve outer exception type.'
Require $bootstrap 'Error:' 'W13.1 bootstrap must preserve outer error text.'
Require $bootstrap 'finally\s*\{' 'W13.1 bootstrap must expose cleanup/attachment from a finally-equivalent path.'
Require $bootstrap 'ATTACH THIS FILE TO CHATGPT:' 'W13.1 bootstrap must expose one obvious report handoff.'
Require $bootstrap "'worktree','remove','--force'" 'W13.1 bootstrap must clean its disposable exact-head worktree.'
Require $bootstrap 'READ_ONLY_INSTALLED_GAME=YES' 'W13.1 bootstrap must attest that the installed-game operation is read-only.'
Require $bootstrap 'GAME_LAUNCHED=NO' 'W13.1 bootstrap must attest that it did not launch the game.'
Require $bootstrap 'WORKER_BRANCH_INSTALLED_OR_PLAYED=NO' 'W13.1 bootstrap must attest that it did not install/play the worker branch.'
Reject $bootstrap 'C:\\Games\\CyberpunkRealism' 'W13.1 bootstrap must not restore the retired fixed repository path.'
Reject $bootstrap '(?i)redMod\.exe.*deploy|Invoke-.*deploy|Build-BiologyPackage\.ps1|Install-OwnedRuntime\.ps1' 'W13.1 bootstrap must not install, build, or redeploy a candidate.'
Reject $bootstrap '(?i)Start-Process[^\r\n]*Cyberpunk|Cyberpunk2077\.exe[^\r\n]*Start' 'W13.1 bootstrap must not launch Cyberpunk.'

Write-Host 'PASS: W13.1 installed-runtime activation evidence tooling is exact-head, zero-local-repo-safe, read-only against the installed game, candidate-revision-bound, receipt/hash-aware, prioritizes the scc.toml-configured REDscript output/task-runner boundary, and refuses to guess beyond the first proven failure.'
