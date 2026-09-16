[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$Branch,
    [Parameter(Mandatory=$true)][ValidatePattern('^[0-9a-fA-F]{40}$')][string]$ExpectedHead,
    [string]$GamesRoot = 'C:\Games',
    [string]$GameRoot = 'C:\Games\Steam\steamapps\common\Cyberpunk 2077'
)

$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'Bootstrap-LegacyFrameworkTransitionProbe.ps1 requires PowerShell 7 or newer.' }
$GamesRoot = [IO.Path]::GetFullPath($GamesRoot)
$GameRoot = [IO.Path]::GetFullPath($GameRoot)
$signature = [DateTime]::Now.ToString('yyyyMMdd-HHmmss') + '-' + [guid]::NewGuid().ToString('N').Substring(0,8)
$reportPath = Join-Path $GamesRoot ('Biology-Legacy-Framework-Transition-Probe-' + $signature + '.txt')
$planPath = Join-Path $GamesRoot ('Biology-Legacy-Framework-Transition-Plan-' + $signature + '.json')
$innerReport = Join-Path $GamesRoot ('Biology-Legacy-Framework-Transition-Probe-Inner-' + $signature + '.txt')
$repoUrl = 'https://github.com/natanai/cprealpass.git'
$repoPattern = '(?i)(?:github\.com[/:])natanai/cprealpass(?:\.git)?$'
$seedRepo = $null
$worktree = $null
$failed = $false

function Add-Evidence([string]$Text) { Add-Content -LiteralPath $reportPath -Value $Text -Encoding utf8 }
function Invoke-NativeSafe([string]$FilePath,[string[]]$Arguments) {
    $psi = [Diagnostics.ProcessStartInfo]::new()
    $psi.FileName = $FilePath
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.CreateNoWindow = $true
    foreach ($argument in $Arguments) { [void]$psi.ArgumentList.Add($argument) }
    $process = [Diagnostics.Process]::new(); $process.StartInfo = $psi
    $stdout = ''; $stderr = ''; $exitCode = $null
    try {
        if (-not $process.Start()) { throw "Unable to start native process: $FilePath" }
        $stdout = $process.StandardOutput.ReadToEnd(); $stderr = $process.StandardError.ReadToEnd(); $process.WaitForExit(); $exitCode = $process.ExitCode
    } finally { $process.Dispose() }
    [pscustomobject]@{ ExitCode=$exitCode; StdOut=$stdout; StdErr=$stderr }
}
function Record-Process([string]$Label,$Result) {
    Add-Evidence ("--- $Label ---")
    Add-Evidence ('exit=' + $Result.ExitCode)
    Add-Evidence 'stdout:'; Add-Evidence $Result.StdOut.TrimEnd()
    Add-Evidence 'stderr:'; Add-Evidence $Result.StdErr.TrimEnd()
}
function Find-Seed {
    foreach ($directory in @(Get-ChildItem -LiteralPath $GamesRoot -Directory -ErrorAction SilentlyContinue)) {
        $top = Invoke-NativeSafe 'git' @('-C',$directory.FullName,'rev-parse','--show-toplevel')
        if ($top.ExitCode -ne 0) { continue }
        $origin = Invoke-NativeSafe 'git' @('-C',$directory.FullName,'remote','get-url','origin')
        if ($origin.ExitCode -ne 0) { continue }
        $originUrl = $origin.StdOut.Trim()
        if ($originUrl -notmatch $repoPattern) { continue }
        Add-Evidence ('Seed candidate accepted by Git origin: ' + $directory.FullName)
        Add-Evidence ('Seed origin: ' + $originUrl)
        return $directory.FullName
    }
    return $null
}
function Resolve-PinnedHead([string]$Seed) {
    $remoteRef = "refs/remotes/origin/$Branch"
    $fetch = Invoke-NativeSafe 'git' @('-C',$Seed,'fetch','origin',("+refs/heads/{0}:{1}" -f $Branch,$remoteRef))
    Record-Process 'git fetch' $fetch
    if ($fetch.ExitCode -eq 0) {
        $resolve = Invoke-NativeSafe 'git' @('-C',$Seed,'rev-parse','--verify',$remoteRef)
        Record-Process 'git rev-parse fetched remote branch' $resolve
        if ($resolve.ExitCode -ne 0) { throw 'Could not resolve fetched branch head.' }
        $head = $resolve.StdOut.Trim()
        Add-Evidence ('Fetched head: ' + $head)
        if ($head -ne $ExpectedHead) { throw "Branch head moved. Expected $ExpectedHead but fetched $head." }
        return $head
    }

    Add-Evidence 'Fetch failed; evaluating fail-closed cached-origin exact-head fallback.'
    $cached = Invoke-NativeSafe 'git' @('-C',$Seed,'rev-parse','--verify',$remoteRef)
    Record-Process 'git rev-parse cached remote branch' $cached
    if ($cached.ExitCode -ne 0) { throw "Could not fetch $Branch and no cached origin branch ref is available." }
    $cachedHead = $cached.StdOut.Trim()
    if ($cachedHead -ne $ExpectedHead) { throw "Could not fetch $Branch and cached origin head '$cachedHead' does not equal expected '$ExpectedHead'." }
    $object = Invoke-NativeSafe 'git' @('-C',$Seed,'cat-file','-e',("{0}^{{commit}}" -f $ExpectedHead))
    Record-Process 'git cat-file expected commit' $object
    if ($object.ExitCode -ne 0) { throw "Cached origin ref matches expected head but commit object $ExpectedHead is unavailable." }
    Add-Evidence ('Offline exact-head fallback: ACCEPTED; cached origin/' + $Branch + ' and commit object both equal the expected frozen head.')
    return $cachedHead
}

@(
    'BIOLOGY W11.1 LEGACY FRAMEWORK TRANSITION PROBE BOOTSTRAP',
    ('Started: ' + [DateTime]::Now.ToString('o')),
    ('Requested branch: ' + $Branch),
    ('Expected head: ' + $ExpectedHead),
    ('Game root: ' + $GameRoot),
    'Installed-game mode: READ-ONLY.',
    ''
) | Set-Content -LiteralPath $reportPath -Encoding utf8

try {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) { throw 'git is not available on PATH.' }
    if (-not (Get-Command pwsh -ErrorAction SilentlyContinue)) { throw 'PowerShell 7 (pwsh) is not available on PATH.' }
    if (-not (Test-Path -LiteralPath $GameRoot -PathType Container)) { throw "Cyberpunk game directory does not exist: $GameRoot" }

    $seedRepo = Find-Seed
    if (-not $seedRepo) {
        $seedRepo = Join-Path $GamesRoot ('cprealpass-repo-' + $signature)
        $clone = Invoke-NativeSafe 'git' @('clone',$repoUrl,$seedRepo); Record-Process 'git clone' $clone
        if ($clone.ExitCode -ne 0) { throw "Could not clone natanai/cprealpass (git exit $($clone.ExitCode))." }
        Add-Evidence ('Seed checkout: ' + $seedRepo)
    } else { Add-Evidence ('Seed checkout: ' + $seedRepo) }

    $resolvedHead = Resolve-PinnedHead $seedRepo
    Add-Evidence ('Resolved pinned head: ' + $resolvedHead)

    $worktree = Join-Path $GamesRoot ('cprealpass-w11-probe-' + $signature)
    $add = Invoke-NativeSafe 'git' @('-C',$seedRepo,'worktree','add','--detach',$worktree,$ExpectedHead); Record-Process 'git worktree add' $add
    if ($add.ExitCode -ne 0) { throw "Could not create disposable probe checkout (git exit $($add.ExitCode))." }
    Add-Evidence ('Disposable checkout: ' + $worktree)

    $probe = Invoke-NativeSafe 'pwsh' @('-NoLogo','-NoProfile','-File',(Join-Path $worktree 'tools\Probe-LegacyFrameworkTransition.ps1'),'-GameRoot',$GameRoot,'-ReportPath',$innerReport,'-PlanPath',$planPath)
    Record-Process 'inner transition probe' $probe
    if (Test-Path -LiteralPath $innerReport -PathType Leaf) {
        Add-Evidence ''; Add-Evidence '=== INNER PROBE REPORT ==='; Add-Evidence (Get-Content -Raw -LiteralPath $innerReport)
    }
    if ($probe.ExitCode -ne 0) { throw "Legacy-framework transition probe returned exit code $($probe.ExitCode)." }
    if (-not (Test-Path -LiteralPath $planPath -PathType Leaf)) { throw 'Probe succeeded without producing its transition plan.' }
    Add-Evidence ('Persistent plan path: ' + $planPath)
    Add-Evidence ('Persistent plan SHA-256: ' + (Get-FileHash -Algorithm SHA256 -LiteralPath $planPath).Hash.ToUpperInvariant())
    Add-Evidence 'Proof boundary: read-only installed-state ownership/safety evidence only; no game files were changed and no runtime acceptance is claimed.'
} catch {
    $failed = $true
    Add-Evidence ''; Add-Evidence '=== BOOTSTRAP FAILURE ==='
    Add-Evidence ('Exception type: ' + $_.Exception.GetType().FullName)
    Add-Evidence ('Error: ' + $_.Exception.Message)
    Add-Evidence ('Seed checkout: ' + $seedRepo)
    Add-Evidence ('Disposable checkout: ' + $worktree)
} finally {
    Add-Evidence ('Completed: ' + [DateTime]::Now.ToString('o'))
    Write-Host ''
    Write-Host 'ATTACH THIS FILE TO CHATGPT:' -ForegroundColor Cyan
    Write-Host $reportPath -ForegroundColor Yellow
}
if ($failed) { exit 1 }
