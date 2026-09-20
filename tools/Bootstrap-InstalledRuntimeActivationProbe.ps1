[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$Branch,
    [Parameter(Mandatory=$true)][ValidatePattern('^[0-9a-fA-F]{40}$')][string]$ExpectedHead,
    [ValidatePattern('^[0-9a-fA-F]{40}$')][string]$ExpectedInstalledSourceRevision = '68b50ed9e3c629ca252326918dbbb68b9bc35494',
    [string]$GamesRoot = 'C:\Games',
    [string]$GameRoot = 'C:\Games\Steam\steamapps\common\Cyberpunk 2077'
)

$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'Bootstrap-InstalledRuntimeActivationProbe.ps1 requires PowerShell 7 or newer.' }

$ExpectedHead = $ExpectedHead.ToLowerInvariant()
$ExpectedInstalledSourceRevision = $ExpectedInstalledSourceRevision.ToLowerInvariant()
$GamesRoot = [IO.Path]::GetFullPath($GamesRoot)
$GameRoot = [IO.Path]::GetFullPath($GameRoot)
$signature = "$(Get-Date -Format 'yyyyMMdd-HHmmss')-$([guid]::NewGuid().ToString('N').Substring(0,8))"
$reportPath = Join-Path $GamesRoot "Biology-Installed-Runtime-Activation-Probe-$signature.txt"
$repoPattern = '^(?:(?:https://github\.com/)|(?:git@github\.com:))natanai/cprealpass(?:\.git)?/?$'
$seed = $null
$createdSeed = $false
$worktree = $null
$worktreeAdded = $false
$reportStarted = $false

function Add-Evidence([string]$Text = '') {
    if (-not $script:reportStarted) {
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $script:reportPath) | Out-Null
        Set-Content -LiteralPath $script:reportPath -Value '' -Encoding utf8
        $script:reportStarted = $true
    }
    Add-Content -LiteralPath $script:reportPath -Value $Text -Encoding utf8
}

function Invoke-NativeSafe([string]$FilePath,[string[]]$Arguments) {
    $psi = [Diagnostics.ProcessStartInfo]::new()
    $psi.FileName = $FilePath
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.CreateNoWindow = $true
    foreach ($arg in $Arguments) { [void]$psi.ArgumentList.Add($arg) }
    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $psi
    try {
        [void]$process.Start()
        $stdoutTask = $process.StandardOutput.ReadToEndAsync()
        $stderrTask = $process.StandardError.ReadToEndAsync()
        $process.WaitForExit()
        $stdoutTask.Wait()
        $stderrTask.Wait()
        [pscustomobject]@{
            ExitCode = $process.ExitCode
            StdOut = $stdoutTask.Result
            StdErr = $stderrTask.Result
            StartException = $null
        }
    } catch {
        [pscustomobject]@{
            ExitCode = $null
            StdOut = ''
            StdErr = ''
            StartException = $_.Exception.ToString()
        }
    } finally {
        $process.Dispose()
    }
}

function Record-Process([string]$Label,$Result) {
    Add-Evidence ("--- PROCESS: $Label ---")
    Add-Evidence ('Exit code: ' + $(if ($null -eq $Result.ExitCode) { '<not-started>' } else { [string]$Result.ExitCode }))
    if ($Result.StartException) {
        Add-Evidence 'Start exception:'
        Add-Evidence $Result.StartException.TrimEnd()
    }
    Add-Evidence 'stdout:'
    Add-Evidence $(if ([string]::IsNullOrWhiteSpace($Result.StdOut)) { '<empty>' } else { $Result.StdOut.TrimEnd() })
    Add-Evidence 'stderr:'
    Add-Evidence $(if ([string]::IsNullOrWhiteSpace($Result.StdErr)) { '<empty>' } else { $Result.StdErr.TrimEnd() })
}

function Invoke-Git([string]$Repo,[string[]]$Arguments,[string]$Label,[switch]$AllowFailure) {
    $args = @()
    if (-not [string]::IsNullOrWhiteSpace($Repo)) { $args += @('-C',$Repo) }
    $args += $Arguments
    $result = Invoke-NativeSafe 'git' $args
    Record-Process $Label $result
    if (-not $AllowFailure -and ($null -eq $result.ExitCode -or $result.ExitCode -ne 0)) {
        throw "$Label failed."
    }
    return $result
}

function Test-CprealpassRepo([string]$Candidate) {
    if (-not (Test-Path -LiteralPath $Candidate -PathType Container)) { return $false }
    $top = Invoke-NativeSafe 'git' @('-C',$Candidate,'rev-parse','--show-toplevel')
    if ($top.ExitCode -ne 0) { return $false }
    $origin = Invoke-NativeSafe 'git' @('-C',$Candidate,'remote','get-url','origin')
    if ($origin.ExitCode -ne 0) { return $false }
    return $origin.StdOut.Trim() -match $script:repoPattern
}

function Find-Seed {
    if (-not (Test-Path -LiteralPath $script:GamesRoot -PathType Container)) { return $null }
    foreach ($child in @(Get-ChildItem -LiteralPath $script:GamesRoot -Directory -ErrorAction SilentlyContinue)) {
        if (Test-CprealpassRepo $child.FullName) {
            $top = Invoke-NativeSafe 'git' @('-C',$child.FullName,'rev-parse','--show-toplevel')
            if ($top.ExitCode -eq 0) { return [IO.Path]::GetFullPath($top.StdOut.Trim()) }
        }
    }
    return $null
}

function Resolve-PinnedHead([string]$Repo,[string]$RequestedBranch,[string]$ExpectedCommit) {
    $fetch = Invoke-Git $Repo @('fetch','--no-tags','origin',$RequestedBranch) 'git fetch requested W13 branch' -AllowFailure
    if ($fetch.ExitCode -eq 0) {
        $fetched = Invoke-Git $Repo @('rev-parse','FETCH_HEAD^{commit}') 'resolve fetched W13 head'
        $sha = $fetched.StdOut.Trim().ToLowerInvariant()
        Add-Evidence ('Fetched head: ' + $sha)
        if ($sha -ne $ExpectedCommit) {
            throw "Fetched branch head $sha does not equal expected head $ExpectedCommit."
        }
        return $sha
    }

    Add-Evidence 'Network fetch failed; evaluating exact cached remote branch fallback.'
    $cached = Invoke-Git $Repo @('rev-parse',"refs/remotes/origin/$RequestedBranch^{commit}") 'resolve cached remote branch' -AllowFailure
    if ($cached.ExitCode -ne 0) { throw 'Fetch failed and cached remote branch cannot be resolved.' }
    $cachedSha = $cached.StdOut.Trim().ToLowerInvariant()
    Add-Evidence ('Cached remote branch head: ' + $cachedSha)
    if ($cachedSha -ne $ExpectedCommit) {
        throw "Fetch failed and cached remote branch head $cachedSha does not equal expected head $ExpectedCommit."
    }
    $object = Invoke-Git $Repo @('cat-file','-e',"$ExpectedCommit^{commit}") 'prove expected commit object exists' -AllowFailure
    if ($object.ExitCode -ne 0) { throw 'Fetch failed and exact expected commit object is not available locally.' }
    Add-Evidence 'Offline exact-head fallback: ACCEPTED'
    return $cachedSha
}

try {
    Add-Evidence '=== W13.1 INSTALLED BIOLOGY RUNTIME ACTIVATION BOOTSTRAP ==='
    Add-Evidence ('Started: ' + [DateTime]::Now.ToString('o'))
    Add-Evidence ('Requested branch: ' + $Branch)
    Add-Evidence ('Expected worker head: ' + $ExpectedHead)
    Add-Evidence ('Expected installed canonical candidate source revision: ' + $ExpectedInstalledSourceRevision)
    Add-Evidence ('Games root: ' + $GamesRoot)
    Add-Evidence ('Game root: ' + $GameRoot)
    Add-Evidence 'Installed-game policy: READ-ONLY. This operation does not deploy, install, remove, rewrite, or launch Cyberpunk 2077.'
    Add-Evidence 'Proof boundary: post-attended runtime evidence only; this bootstrap does not itself claim gameplay acceptance.'

    if (-not (Test-Path -LiteralPath $GamesRoot -PathType Container)) {
        New-Item -ItemType Directory -Force -Path $GamesRoot | Out-Null
    }

    $seed = Find-Seed
    if ($null -eq $seed) {
        $seed = Join-Path $GamesRoot "cprealpass-repo-$signature"
        Add-Evidence ('No usable cprealpass seed checkout found. Cloning seed: ' + $seed)
        $clone = Invoke-NativeSafe 'git' @('clone','--no-checkout','https://github.com/natanai/cprealpass.git',$seed)
        Record-Process 'clone cprealpass seed' $clone
        if ($clone.ExitCode -ne 0) { throw 'Could not acquire cprealpass seed clone.' }
        $createdSeed = $true
    } else {
        Add-Evidence ('Discovered usable cprealpass seed checkout: ' + $seed)
    }

    $origin = Invoke-Git $seed @('remote','get-url','origin') 'validate cprealpass origin'
    if ($origin.StdOut.Trim() -notmatch $repoPattern) { throw 'Discovered seed origin is not natanai/cprealpass.' }

    $resolved = Resolve-PinnedHead $seed $Branch $ExpectedHead
    if ($resolved -ne $ExpectedHead) { throw 'Exact-head resolution invariant failed.' }

    $worktree = Join-Path $GamesRoot "cprealpass-installed-runtime-activation-probe-$signature"
    $addWorktree = Invoke-Git $seed @('worktree','add','--detach',$worktree,$ExpectedHead) 'create detached exact-head W13 probe worktree'
    $worktreeAdded = $true
    Add-Evidence ('Disposable checkout/worktree path: ' + $worktree)

    $actualHead = Invoke-Git $worktree @('rev-parse','HEAD') 'verify detached W13 worktree head'
    $actualSha = $actualHead.StdOut.Trim().ToLowerInvariant()
    Add-Evidence ('Disposable checkout HEAD: ' + $actualSha)
    if ($actualSha -ne $ExpectedHead) { throw "Disposable worktree resolved to $actualSha instead of $ExpectedHead." }

    $probePath = Join-Path $worktree 'tools\Probe-InstalledRuntimeActivation.ps1'
    if (-not (Test-Path -LiteralPath $probePath -PathType Leaf)) { throw "Exact-head W13 inner probe is missing: $probePath" }

    $probe = Invoke-NativeSafe 'pwsh' @(
        '-NoLogo','-NoProfile','-NonInteractive','-File',$probePath,
        '-GameRoot',$GameRoot,
        '-ReportPath',$reportPath,
        '-ExpectedInstalledSourceRevision',$ExpectedInstalledSourceRevision
    )
    Add-Evidence ''
    Add-Evidence '=== INNER W13.1 PROBE PROCESS OUTPUT ==='
    Record-Process 'Probe-InstalledRuntimeActivation.ps1' $probe
    if ($probe.ExitCode -ne 0) {
        throw 'W13.1 inner probe failed. See INNER W13.1 PROBE PROCESS OUTPUT and W13.1 INNER PROBE FAILURE in this report.'
    }

    Add-Evidence ''
    Add-Evidence 'RESULT: PASS'
    Add-Evidence 'READ_ONLY_INSTALLED_GAME=YES'
    Add-Evidence 'GAME_LAUNCHED=NO'
    Add-Evidence 'WORKER_BRANCH_INSTALLED_OR_PLAYED=NO'
    Add-Evidence 'Interpret FIRST PROVEN BROKEN BOUNDARY in this report before changing downstream Biology runtime/UI code.'
} catch {
    Add-Evidence ''
    Add-Evidence '=== W13.1 BOOTSTRAP FAILURE ==='
    Add-Evidence ('Time: ' + [DateTime]::Now.ToString('o'))
    Add-Evidence ('Exception type: ' + $_.Exception.GetType().FullName)
    Add-Evidence ('Error: ' + $_.Exception.Message)
    if ($_.InvocationInfo) {
        Add-Evidence ('Script line: ' + $_.InvocationInfo.ScriptLineNumber)
        Add-Evidence ('Position: ' + $_.InvocationInfo.PositionMessage)
    }
    Add-Evidence 'RESULT: FAIL-CLOSED'
    exit 1
} finally {
    if ($worktreeAdded -and -not [string]::IsNullOrWhiteSpace($seed) -and -not [string]::IsNullOrWhiteSpace($worktree)) {
        try {
            $remove = Invoke-NativeSafe 'git' @('-C',$seed,'worktree','remove','--force',$worktree)
            Record-Process 'remove disposable W13 probe worktree' $remove
        } catch {
            Add-Evidence ('Worktree cleanup warning: ' + $_.Exception.Message)
        }
    }
    if ($createdSeed -and -not [string]::IsNullOrWhiteSpace($seed) -and (Test-Path -LiteralPath $seed -PathType Container)) {
        try {
            Remove-Item -LiteralPath $seed -Recurse -Force
            Add-Evidence ('Removed seed clone created solely for this probe: ' + $seed)
        } catch {
            Add-Evidence ('Seed cleanup warning: ' + $_.Exception.Message)
        }
    }
    Add-Evidence ('Completed: ' + [DateTime]::Now.ToString('o'))
    Write-Host 'ATTACH THIS FILE TO CHATGPT:'
    Write-Host $reportPath
}
