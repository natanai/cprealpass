$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'Test-OperatorBootstrapHardening.ps1 requires PowerShell 7 or newer.' }

$project = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$bootstrapPath = Join-Path $project 'tools\Bootstrap-BiologyPostTransitionCandidate.ps1'
$source = Get-Content -Raw -LiteralPath $bootstrapPath
$catalog = Get-Content -Raw -LiteralPath (Join-Path $project 'docs\LOCAL-OPERATOR-COMMANDS.md')

function Assert-True([bool]$Condition,[string]$Message) { if (-not $Condition) { throw $Message } }
function Require([string]$Text,[string]$Pattern,[string]$Message) { if ($Text -notmatch $Pattern) { throw $Message } }

$tokens = $null
$parseErrors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile($bootstrapPath,[ref]$tokens,[ref]$parseErrors)
if (@($parseErrors).Count -gt 0) { throw ('W12 bootstrap parse failure: ' + (@($parseErrors | ForEach-Object Message) -join ' | ')) }
function Get-FunctionSource([string]$Name) {
    $node = $ast.Find({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq $Name },$true)
    if ($null -eq $node) { throw "Could not find function '$Name' in W12 bootstrap." }
    return $node.Extent.Text
}
Invoke-Expression (Get-FunctionSource 'Invoke-NativeSafe')
Invoke-Expression (Get-FunctionSource 'Find-Seed')
Invoke-Expression (Get-FunctionSource 'Resolve-PinnedHead')

# The attended regression that created #66: native stderr is captured evidence,
# but exit 0 remains success.
$stderrProbe = Invoke-NativeSafe 'pwsh' @('-NoLogo','-NoProfile','-NonInteractive','-Command','[Console]::Error.WriteLine("expected-native-stderr"); exit 0')
Assert-True ($stderrProbe.ExitCode -eq 0) 'Exit-0 native stderr was misclassified as process failure.'
Assert-True ($stderrProbe.StdErr -match 'expected-native-stderr') 'Native stderr was not preserved.'

# Preserve the valuable W12 compatibility regression: exact transition evidence,
# worktree/offline handling, failure durability and exact artifact identity. The
# W15.2 managed lifecycle now owns steady-state retention/cleanup, so this test
# deliberately does NOT make W12's historical KEEP/MAY DELETE wording normative.
Require $source 'TransitionCleanupReportPath' 'W12 bootstrap must require parent-supplied W11 cleanup evidence.'
Require $source 'ExpectedTransitionCleanupReportSha256' 'W12 bootstrap must pin the cleanup evidence hash.'
Require $source 'Transition-state classification:' 'W12 bootstrap must state the transition proof boundary.'
Require $source 'Verify-BiologyRemoval\.ps1' 'W12 bootstrap must re-run Biology-specific residue verification.'
Require $source 'Build-BiologyPackage\.ps1' 'W12 bootstrap must build through the canonical release builder.'
Require $source 'Retained artifact SHA-256:' 'W12 compatibility bootstrap must still record the exact candidate artifact SHA-256.'
Require $source 'Retained artifact bytes:' 'W12 compatibility bootstrap must still record the exact candidate artifact size.'
Require $source 'Installed receipt sourceRevision:' 'W12 bootstrap must verify installed source revision.'
Require $source 'Deploy-BiologyRedmod\.ps1' 'W12 bootstrap must deploy through the canonical REDmod helper.'
Require $source 'STOP_BEFORE_GAME_LAUNCH=YES' 'W12 bootstrap must stop before game launch.'
Require $source 'RESULT: PASS' 'W12 bootstrap must report success.'
Require $source 'RESULT: FAIL-CLOSED' 'W12 bootstrap must report failure durably.'
Require $source "'worktree','remove','--force'" 'W12 bootstrap must clean its disposable worktree.'
Require $source "'rev-parse','--show-toplevel'" 'W12 bootstrap must use Git-validated worktree-aware discovery.'
Require $source "'remote','get-url','origin'" 'W12 bootstrap must validate origin through Git.'
Assert-True ($source -notmatch [regex]::Escape('.git\config')) 'W12 bootstrap regressed to .git/config-only discovery.'
Require $source 'cached remote branch' 'W12 bootstrap must inspect cached origin ref after fetch failure.'
Require $source "'cat-file','-e'" 'W12 bootstrap must prove the expected commit object exists.'
Require $source 'Offline exact-head fallback: ACCEPTED' 'W12 bootstrap must record accepted exact-head fallback.'
Require $source 'cprealpass-repo-' 'W12 bootstrap must support uniquely signed zero-repo acquisition.'
if ($source -match '(?i)Start-Process[^\r\n]*Cyberpunk') { throw 'W12 bootstrap must not launch Cyberpunk.' }

# Active policy must explicitly scope Command 13's KEEP wording as legacy
# compatibility and route new parent operations through the managed lifecycle.
Require $catalog 'Command 13 — legacy post-W11 candidate preparation compatibility entrypoint' 'Operator catalog must classify the W12 bootstrap as legacy compatibility.'
Require $catalog 'historical report may contain `KEEP UNTIL ATTENDED TEST`' 'Catalog must describe the old KEEP wording only as historical compatibility evidence.'
Require $catalog 'Do not use that wording as a new human-memory contract' 'Catalog must reject W12 KEEP wording as the active retention contract.'
Require $catalog 'Command 14 — managed post-W11 candidate preparation' 'Catalog must make the managed candidate wrapper the current path.'
Require $catalog 'Command 16 — repo-confirmed local operator evidence cleanup' 'Catalog must expose tool-owned managed cleanup.'

# Real Git fixture: the only C:\Games-like child is a linked worktree with a
# .git pointer file. Then make origin unavailable and prove exact cached fallback.
$fixtureRoot = Join-Path ([IO.Path]::GetTempPath()) ('biology-w12-' + [guid]::NewGuid().ToString('N'))
$fixtureGames = Join-Path $fixtureRoot 'games'
$remote = Join-Path $fixtureRoot 'remote.git'
$seed = Join-Path $fixtureRoot 'seed'
$linked = Join-Path $fixtureGames 'linked-worktree'
New-Item -ItemType Directory -Force -Path $fixtureGames | Out-Null

function Git([string[]]$Arguments,[string]$Label) {
    $result = Invoke-NativeSafe 'git' $Arguments
    if ($result.ExitCode -ne 0) { throw "$Label failed: $($result.StdErr) $($result.StdOut)" }
    return $result
}

try {
    [void](Git @('init','--bare',$remote) 'init bare')
    [void](Git @('init',$seed) 'init seed')
    [void](Git @('-C',$seed,'config','user.email','biology-ci@example.invalid') 'config email')
    [void](Git @('-C',$seed,'config','user.name','Biology CI') 'config name')
    Set-Content -LiteralPath (Join-Path $seed 'fixture.txt') -Value 'fixture' -Encoding utf8
    [void](Git @('-C',$seed,'add','fixture.txt') 'add')
    [void](Git @('-C',$seed,'commit','-m','fixture') 'commit')
    [void](Git @('-C',$seed,'branch','-M','main') 'branch main')
    [void](Git @('-C',$seed,'remote','add','origin',$remote) 'remote add')
    [void](Git @('-C',$seed,'push','-u','origin','main') 'push main')
    [void](Git @('-C',$seed,'worktree','add','--detach',$linked,'HEAD') 'add linked worktree')

    Assert-True (Test-Path -LiteralPath (Join-Path $linked '.git') -PathType Leaf) 'Fixture linked worktree lacks .git pointer file.'
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $linked '.git\config') -PathType Leaf)) 'Fixture unexpectedly has worktree-local .git/config.'

    $script:GamesRoot = $fixtureGames
    $origin = (Git @('-C',$linked,'remote','get-url','origin') 'read origin').StdOut.Trim()
    $script:repoPattern = '^' + [regex]::Escape($origin) + '$'
    function Add-Evidence([string]$Text = '') { }
    function Record-Process([string]$Label,$Result) { }

    $found = Find-Seed
    Assert-True ([IO.Path]::GetFullPath($found) -eq [IO.Path]::GetFullPath($linked)) 'Worktree-aware discovery did not accept linked worktree.'

    $expected = (Git @('-C',$linked,'rev-parse','refs/remotes/origin/main') 'resolve cached main').StdOut.Trim()
    [void](Git @('-C',$linked,'remote','set-url','origin',(Join-Path $fixtureRoot 'missing.git')) 'disable remote')
    $resolved = Resolve-PinnedHead $linked 'main' $expected
    Assert-True ($resolved -eq $expected) 'Exact cached-origin fallback failed after fetch failure.'

    $emptyGames = Join-Path $fixtureRoot 'empty-games'
    New-Item -ItemType Directory -Force -Path $emptyGames | Out-Null
    $script:GamesRoot = $emptyGames
    Assert-True ($null -eq (Find-Seed)) 'Zero-repo discovery should return null and allow clone fallback.'
} finally {
    try { if (Test-Path -LiteralPath $seed) { & git -C $seed worktree remove --force $linked 2>$null | Out-Null } } catch { }
    if (Test-Path -LiteralPath $fixtureRoot) { Remove-Item -LiteralPath $fixtureRoot -Recurse -Force }
}

Write-Host 'PASS: W12 compatibility bootstrap preserves exit-0 stderr, linked-worktree discovery, exact cached-origin fallback, zero-repo acquisition, exact artifact identity, failure durability and stop-before-launch; W15.2 owns active evidence retention/cleanup.'
