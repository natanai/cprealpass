$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'Test-OperatorBootstrapHardening.ps1 requires PowerShell 7 or newer.' }

$project = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$bootstrapPath = Join-Path $project 'tools\Bootstrap-BiologyPostTransitionCandidate.ps1'
if (-not (Test-Path -LiteralPath $bootstrapPath -PathType Leaf)) { throw 'Missing W12 post-transition candidate bootstrap.' }
$source = Get-Content -Raw -LiteralPath $bootstrapPath

function Assert-True([bool]$Condition,[string]$Message) { if (-not $Condition) { throw $Message } }
function Require([string]$Text,[string]$Pattern,[string]$Message) { if ($Text -notmatch $Pattern) { throw $Message } }
function Import-FunctionFromScript([System.Management.Automation.Language.ScriptBlockAst]$Ast,[string]$Name) {
    $node = $Ast.Find({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq $Name },$true)
    if ($null -eq $node) { throw "Could not find function '$Name' in W12 bootstrap." }
    Invoke-Expression $node.Extent.Text
}

$tokens = $null
$parseErrors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile($bootstrapPath,[ref]$tokens,[ref]$parseErrors)
if (@($parseErrors).Count -gt 0) { throw ('W12 bootstrap parse failure: ' + (@($parseErrors | ForEach-Object Message) -join ' | ')) }
Import-FunctionFromScript $ast 'Invoke-NativeSafe'
Import-FunctionFromScript $ast 'Find-Seed'
Import-FunctionFromScript $ast 'Resolve-PinnedHead'

# Regression for the attended failure that created #66: native stderr is evidence,
# not a PowerShell exception boundary. Exit 0 remains success even with stderr.
$stderrProbe = Invoke-NativeSafe 'pwsh' @('-NoLogo','-NoProfile','-NonInteractive','-Command','[Console]::Error.WriteLine("expected-native-stderr"); exit 0')
Assert-True ($stderrProbe.ExitCode -eq 0) 'ProcessStartInfo wrapper misclassified an exit-0 child because it wrote stderr.'
Assert-True ($stderrProbe.StdErr -match 'expected-native-stderr') 'ProcessStartInfo wrapper did not preserve ordinary native stderr.'

# Static contract for the complete post-transition operator path.
Require $source '\[ValidatePattern\(''\^\[A-Fa-f0-9\]\{40\}\$''\)\].*\$MainSha' 'W12 bootstrap must require an exact canonical-main SHA.'
Require $source 'TransitionCleanupReportPath' 'W12 bootstrap must require explicit parent-supplied W11 transition evidence.'
Require $source 'ExpectedTransitionCleanupReportSha256' 'W12 bootstrap must exact-hash the parent-supplied transition evidence.'
Require $source 'Game-state classification target: accounted W11 transition; NOT a vanilla-baseline verification' 'W12 bootstrap must state the transition proof boundary.'
Require $source 'Verify-BiologyRemoval\.ps1' 'W12 bootstrap must re-run the canonical Biology-specific residue verifier before install.'
Require $source 'Build-BiologyPackage\.ps1' 'W12 bootstrap must exact-compile/build through the canonical release builder.'
Require $source "'-OutputRoot',\$artifactRoot" 'W12 bootstrap must retain the package outside disposable repository state.'
Require $source 'Retained artifact SHA-256:' 'W12 bootstrap must report exact artifact SHA-256.'
Require $source 'Retained artifact bytes:' 'W12 bootstrap must report artifact byte size.'
Require $source 'Expand-Archive -LiteralPath \$artifactZip -DestinationPath \$GameRoot' 'W12 bootstrap must install the exact retained ZIP.'
Require $source 'Installed receipt sourceRevision:' 'W12 bootstrap must report and verify the installed receipt revision.'
Require $source 'Deploy-BiologyRedmod\.ps1' 'W12 bootstrap must use the canonical official REDmod deployment helper.'
Require $source 'STOP_BEFORE_GAME_LAUNCH=YES' 'W12 bootstrap must stop before attended game launch.'
Require $source 'RESULT: PASS' 'W12 bootstrap must persist success in its attachable report.'
Require $source 'RESULT: FAIL-CLOSED' 'W12 bootstrap must persist failure in its attachable report.'
Require $source 'ATTACH THIS FILE TO CHATGPT:' 'W12 bootstrap must always expose one attachment handoff.'
Require $source 'Biology-Post-Transition-Candidate-Prep-' 'W12 bootstrap must use a uniquely signed attachable report filename.'
Require $source "'worktree','remove','--force'" 'W12 bootstrap must attempt to remove its disposable exact-source worktree.'
Require $source 'Signed seed clone created by this run was removed' 'W12 bootstrap must remove a seed clone that it created solely for this run.'
Require $source 'KEEP UNTIL ATTENDED TEST' 'W12 bootstrap must clearly label persistent state that must survive repo cleanup.'
Require $source 'MAY DELETE IMMEDIATELY' 'W12 bootstrap must identify disposable repo/worktree state.'
if ($source -match '(?i)Start-Process[^\r\n]*Cyberpunk|Cyberpunk2077\.exe[^\r\n]*Start') { throw 'W12 bootstrap must never launch Cyberpunk automatically.' }

# The acquisition contract must not be gated by a physical .git/config. Git itself
# establishes whether an immediate C:\Games child is a usable clone or linked worktree.
Require $source "'rev-parse','--show-toplevel'" 'W12 bootstrap must validate candidate checkouts through Git.'
Require $source "'remote','get-url','origin'" 'W12 bootstrap must validate cprealpass identity through Git origin.'
Assert-True ($source -notmatch [regex]::Escape('.git\config')) 'W12 bootstrap regressed to .git/config-only discovery.'
Require $source 'cached remote branch' 'W12 bootstrap must inspect cached origin/main after fetch failure.'
Require $source "'cat-file','-e'" 'W12 bootstrap must prove the frozen commit object exists before offline fallback.'
Require $source 'Offline exact-head fallback: ACCEPTED' 'W12 bootstrap must report accepted exact-head offline fallback.'
Require $source "'clone','--no-checkout',\$repoUrl,\$seedRepo" 'W12 bootstrap must support zero-existing-repo acquisition with a signed clone.'
Require $source 'cprealpass-repo-' 'W12 bootstrap must uniquely sign zero-repo seed clones.'

# Dynamic linked-worktree + offline exact-head fixture. The only immediate child
# under GamesRoot is a linked worktree with a .git pointer file, not .git/config.
$fixtureRoot = Join-Path ([IO.Path]::GetTempPath()) ('biology-w12-bootstrap-' + [guid]::NewGuid().ToString('N'))
$fixtureGames = Join-Path $fixtureRoot 'games'
$remote = Join-Path $fixtureRoot 'remote.git'
$seed = Join-Path $fixtureRoot 'seed'
$linked = Join-Path $fixtureGames 'linked-worktree'
New-Item -ItemType Directory -Force -Path $fixtureGames | Out-Null

function Invoke-FixtureGit([string[]]$Arguments,[string]$Label) {
    $result = Invoke-NativeSafe 'git' $Arguments
    if ($result.ExitCode -ne 0) { throw "$Label failed (exit $($result.ExitCode)): $($result.StdErr) $($result.StdOut)" }
    return $result
}

try {
    [void](Invoke-FixtureGit @('init','--bare',$remote) 'git init --bare')
    [void](Invoke-FixtureGit @('init',$seed) 'git init seed')
    [void](Invoke-FixtureGit @('-C',$seed,'config','user.email','biology-ci@example.invalid') 'git config email')
    [void](Invoke-FixtureGit @('-C',$seed,'config','user.name','Biology CI') 'git config name')
    Set-Content -LiteralPath (Join-Path $seed 'fixture.txt') -Value 'w12-fixture' -Encoding utf8
    [void](Invoke-FixtureGit @('-C',$seed,'add','fixture.txt') 'git add')
    [void](Invoke-FixtureGit @('-C',$seed,'commit','-m','fixture') 'git commit')
    [void](Invoke-FixtureGit @('-C',$seed,'branch','-M','main') 'git branch main')
    [void](Invoke-FixtureGit @('-C',$seed,'remote','add','origin',$remote) 'git remote add')
    [void](Invoke-FixtureGit @('-C',$seed,'push','-u','origin','main') 'git push main')
    [void](Invoke-FixtureGit @('-C',$seed,'worktree','add','--detach',$linked,'HEAD') 'git linked worktree add')

    Assert-True (Test-Path -LiteralPath (Join-Path $linked '.git') -PathType Leaf) 'Fixture did not create a linked-worktree .git pointer file.'
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $linked '.git\config') -PathType Leaf)) 'Fixture unexpectedly has a physical linked-worktree .git/config.'

    $script:GamesRoot = $fixtureGames
    $originResult = Invoke-FixtureGit @('-C',$linked,'remote','get-url','origin') 'git read origin'
    $script:repoPattern = '^' + [regex]::Escape($originResult.StdOut.Trim()) + '$'
    function Add-Evidence([string]$Text = '') { }
    function Record-Process([string]$Label,$Result) { }

    $found = Find-Seed
    Assert-True (-not [string]::IsNullOrWhiteSpace([string]$found)) 'Local-first discovery failed to accept a valid linked worktree.'
    Assert-True ([IO.Path]::GetFullPath($found) -eq [IO.Path]::GetFullPath($linked)) 'Local-first discovery returned the wrong fixture checkout.'

    $expected = (Invoke-FixtureGit @('-C',$linked,'rev-parse','refs/remotes/origin/main') 'git resolve cached origin/main').StdOut.Trim()
    $missingRemote = Join-Path $fixtureRoot 'network-unavailable.git'
    [void](Invoke-FixtureGit @('-C',$linked,'remote','set-url','origin',$missingRemote) 'git set unavailable origin')
    $resolved = Resolve-PinnedHead $linked 'main' $expected
    Assert-True ($resolved -eq $expected) 'Exact-head cached-origin fallback did not return the frozen expected head after fetch failure.'

    $emptyGames = Join-Path $fixtureRoot 'empty-games'
    New-Item -ItemType Directory -Force -Path $emptyGames | Out-Null
    $script:GamesRoot = $emptyGames
    $none = Find-Seed
    Assert-True ($null -eq $none) 'Zero-existing-repo discovery should return no seed so the signed clone fallback can run.'
} finally {
    try {
        if (Test-Path -LiteralPath $seed) { & git -C $seed worktree remove --force $linked 2>$null | Out-Null }
    } catch { }
    if (Test-Path -LiteralPath $fixtureRoot) { Remove-Item -LiteralPath $fixtureRoot -Recurse -Force }
}

Write-Host 'PASS: W12 operator bootstrap preserves native stderr without false failure, accepts linked worktrees, uses exact-head cached-origin fallback, supports zero-repo acquisition, retains artifacts outside disposable source, classifies W11 transition evidence, cleans disposable source, and never launches the game.'
