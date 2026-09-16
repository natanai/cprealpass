[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$Branch,
    [Parameter(Mandatory=$true)][ValidatePattern('^[0-9a-fA-F]{40}$')][string]$ExpectedHead,
    [string]$GamesRoot = 'C:\Games',
    [string]$GameRoot = 'C:\Games\Steam\steamapps\common\Cyberpunk 2077'
)

$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'Bootstrap-RedmodActivationSentinelProbe.ps1 requires PowerShell 7 or newer.' }

$GamesRoot = [IO.Path]::GetFullPath($GamesRoot)
$GameRoot = [IO.Path]::GetFullPath($GameRoot)
$signature = [DateTime]::Now.ToString('yyyyMMdd-HHmmss') + '-' + [guid]::NewGuid().ToString('N').Substring(0,8)
$reportPath = Join-Path $GamesRoot ('Biology-Redmod-Activation-Sentinel-Probe-' + $signature + '.txt')
$repoUrl = 'https://github.com/natanai/cprealpass.git'
$repoPattern = '(?i)(?:github\.com[/:])natanai/cprealpass(?:\.git)?$'
$seedRepo = $null
$auditRoot = $null
$fetchedHead = $null
$failed = $false

function Add-Evidence([string]$text) {
    Add-Content -LiteralPath $reportPath -Value $text -Encoding utf8
}

function Invoke-NativeSafe([string]$FilePath,[string[]]$Arguments,[switch]$Echo) {
    $psi = [Diagnostics.ProcessStartInfo]::new()
    $psi.FileName = $FilePath
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.CreateNoWindow = $true
    foreach ($argument in $Arguments) { [void]$psi.ArgumentList.Add($argument) }

    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $psi
    $stdout = ''
    $stderr = ''
    $exitCode = $null
    try {
        if (-not $process.Start()) { throw "Unable to start native process: $FilePath" }
        $stdout = $process.StandardOutput.ReadToEnd()
        $stderr = $process.StandardError.ReadToEnd()
        $process.WaitForExit()
        $exitCode = $process.ExitCode
    } finally {
        $process.Dispose()
    }

    $combined = @()
    if (-not [string]::IsNullOrWhiteSpace($stdout)) { $combined += @($stdout.TrimEnd() -split "`r?`n") }
    if (-not [string]::IsNullOrWhiteSpace($stderr)) { $combined += @($stderr.TrimEnd() -split "`r?`n") }
    if ($Echo) {
        foreach ($line in $combined) {
            Add-Evidence ([string]$line)
            Write-Host $line
        }
    }
    [pscustomobject]@{ ExitCode=$exitCode; StdOut=$stdout; StdErr=$stderr; Output=@($combined) }
}

function Invoke-GitSafe([string[]]$Arguments,[switch]$Echo) {
    Invoke-NativeSafe -FilePath 'git' -Arguments $Arguments -Echo:$Echo
}

function Record-Process([string]$Label,$Result) {
    Add-Evidence ("--- $Label ---")
    Add-Evidence ('exit=' + $Result.ExitCode)
    Add-Evidence 'stdout:'
    Add-Evidence $Result.StdOut.TrimEnd()
    Add-Evidence 'stderr:'
    Add-Evidence $Result.StdErr.TrimEnd()
}

function Get-CprealpassSeed {
    foreach ($directory in @(Get-ChildItem -LiteralPath $GamesRoot -Directory -ErrorAction SilentlyContinue)) {
        $top = Invoke-GitSafe -Arguments @('-C',$directory.FullName,'rev-parse','--show-toplevel')
        if ($top.ExitCode -ne 0) { continue }
        $origin = Invoke-GitSafe -Arguments @('-C',$directory.FullName,'remote','get-url','origin')
        if ($origin.ExitCode -ne 0) { continue }
        $originUrl = $origin.StdOut.Trim()
        if ($originUrl -notmatch $repoPattern) { continue }
        Add-Evidence ('Seed candidate accepted by Git origin: ' + $directory.FullName)
        Add-Evidence ('Seed top-level: ' + $top.StdOut.Trim())
        Add-Evidence ('Seed origin: ' + $originUrl)
        return $directory.FullName
    }
    return $null
}

function Resolve-PinnedHead([string]$Seed) {
    $remoteRef = "refs/remotes/origin/$Branch"
    $fetch = Invoke-GitSafe -Arguments @('-C',$Seed,'fetch','origin',("+refs/heads/{0}:{1}" -f $Branch,$remoteRef))
    Record-Process 'git fetch' $fetch
    if ($fetch.ExitCode -eq 0) {
        $resolve = Invoke-GitSafe -Arguments @('-C',$Seed,'rev-parse','--verify',$remoteRef)
        Record-Process 'git rev-parse fetched remote branch' $resolve
        if ($resolve.ExitCode -ne 0) { throw 'Could not resolve fetched branch head.' }
        $head = $resolve.StdOut.Trim()
        Add-Evidence ('Fetched head: ' + $head)
        if ($head -ne $ExpectedHead) { throw "Branch head moved. Expected $ExpectedHead but fetched $head. Refusing to probe a different revision." }
        return $head
    }

    Add-Evidence 'Fetch failed; evaluating fail-closed cached-origin exact-head fallback.'
    $cached = Invoke-GitSafe -Arguments @('-C',$Seed,'rev-parse','--verify',$remoteRef)
    Record-Process 'git rev-parse cached remote branch' $cached
    if ($cached.ExitCode -ne 0) { throw "Could not fetch $Branch and no cached origin branch ref is available." }
    $cachedHead = $cached.StdOut.Trim()
    if ($cachedHead -ne $ExpectedHead) { throw "Could not fetch $Branch and cached origin head '$cachedHead' does not equal expected '$ExpectedHead'." }
    $object = Invoke-GitSafe -Arguments @('-C',$Seed,'cat-file','-e',("{0}^{{commit}}" -f $ExpectedHead))
    Record-Process 'git cat-file expected commit' $object
    if ($object.ExitCode -ne 0) { throw "Cached origin ref matches expected head but commit object $ExpectedHead is unavailable." }
    Add-Evidence ('Offline exact-head fallback: ACCEPTED; cached origin/' + $Branch + ' and commit object both equal the expected frozen head.')
    return $cachedHead
}

if (-not (Test-Path -LiteralPath $GamesRoot -PathType Container)) { throw "Games root does not exist: $GamesRoot" }

@(
    'BIOLOGY W07.1 REDMOD ACTIVATION SENTINEL PROBE BOOTSTRAP',
    ('Started: ' + [DateTime]::Now.ToString('o')),
    ('Branch: ' + $Branch),
    ('Expected head: ' + $ExpectedHead),
    ('Game root: ' + $GameRoot),
    'Policy: branch checkout is disposable; the installed game is read-only for this probe.',
    ''
) | Set-Content -LiteralPath $reportPath -Encoding utf8

try {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) { throw 'git is not available on PATH.' }
    if (-not (Get-Command pwsh -ErrorAction SilentlyContinue)) { throw 'PowerShell 7 (pwsh) is not available on PATH.' }
    if (-not (Test-Path -LiteralPath $GameRoot -PathType Container)) { throw "Cyberpunk game directory does not exist: $GameRoot" }

    $seedRepo = Get-CprealpassSeed
    if ([string]::IsNullOrWhiteSpace($seedRepo)) {
        $seedRepo = Join-Path $GamesRoot ('cprealpass-repo-' + $signature)
        Add-Evidence "No usable cprealpass seed checkout found. Cloning seed: $seedRepo"
        Write-Host "No usable cprealpass seed checkout found. Cloning: $seedRepo" -ForegroundColor Cyan
        $clone = Invoke-GitSafe -Arguments @('clone',$repoUrl,$seedRepo) -Echo
        Record-Process 'git clone' $clone
        if ($clone.ExitCode -ne 0) { throw "Could not clone natanai/cprealpass (git exit $($clone.ExitCode))." }
    } else {
        Add-Evidence "Existing cprealpass seed found: $seedRepo"
        Write-Host "Using existing cprealpass seed: $seedRepo"
    }

    $fetchedHead = Resolve-PinnedHead $seedRepo

    $auditRoot = Join-Path $GamesRoot ('cprealpass-redmod-activation-probe-' + $signature)
    if (Test-Path -LiteralPath $auditRoot) { throw "Unique audit path unexpectedly exists: $auditRoot" }
    Add-Evidence "Creating disposable probe checkout: $auditRoot"
    $worktree = Invoke-GitSafe -Arguments @('-C',$seedRepo,'worktree','add','--detach',$auditRoot,$ExpectedHead) -Echo
    Record-Process 'git worktree add' $worktree
    if ($worktree.ExitCode -ne 0) { throw "Could not create disposable probe checkout (git exit $($worktree.ExitCode))." }

    Write-Host ''
    Write-Host "PROBE CHECKOUT: $auditRoot" -ForegroundColor Cyan
    Write-Host "PROBE HEAD:     $ExpectedHead" -ForegroundColor Cyan
    Write-Host ''

    Add-Evidence ''
    Add-Evidence '=== INNER PROBE PROCESS OUTPUT ==='
    $probe = Invoke-NativeSafe -FilePath 'pwsh' -Arguments @(
        '-NoLogo','-NoProfile','-File',(Join-Path $auditRoot 'tools\Probe-RedmodActivationSentinel.ps1'),
        '-GameRoot',$GameRoot,
        '-ReportPath',$reportPath
    ) -Echo
    $probeExit = $probe.ExitCode

    Add-Evidence ''
    Add-Evidence '=== PROBE BOOTSTRAP CONTEXT ==='
    Add-Evidence "Seed checkout: $seedRepo"
    Add-Evidence "Disposable probe checkout: $auditRoot"
    Add-Evidence "Requested branch: $Branch"
    Add-Evidence "Fetched head: $fetchedHead"
    Add-Evidence "Probed head: $ExpectedHead"
    Add-Evidence "Probe process exit code: $probeExit"
    Add-Evidence ('Completed: ' + [DateTime]::Now.ToString('o'))
    if ($probeExit -ne 0) { throw "Activation-sentinel probe returned exit code $probeExit. See INNER PROBE FAILURE / process output above." }
} catch {
    $failed = $true
    Add-Evidence ''
    Add-Evidence '=== PROBE BOOTSTRAP FAILURE ==='
    Add-Evidence ('Time: ' + [DateTime]::Now.ToString('o'))
    Add-Evidence ('Exception type: ' + $_.Exception.GetType().FullName)
    Add-Evidence ('Error: ' + $_.Exception.Message)
    Add-Evidence "Seed checkout: $seedRepo"
    Add-Evidence "Disposable probe checkout: $auditRoot"
    Add-Evidence "Requested branch: $Branch"
    Add-Evidence "Fetched head: $fetchedHead"
    Add-Evidence "Expected head: $ExpectedHead"
    Write-Host ''
    Write-Host 'The probe encountered a failure. The text report contains the inner error evidence.' -ForegroundColor Yellow
} finally {
    Write-Host ''
    Write-Host '============================================================' -ForegroundColor Cyan
    Write-Host 'ATTACH THIS FILE TO CHATGPT:' -ForegroundColor Cyan
    Write-Host $reportPath -ForegroundColor Yellow
    Write-Host '============================================================' -ForegroundColor Cyan
}

if ($failed) { exit 1 }
