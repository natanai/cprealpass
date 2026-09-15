[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$Branch,
    [Parameter(Mandatory=$true)][ValidatePattern('^[0-9a-fA-F]{40}$')][string]$ExpectedHead,
    [string]$GamesRoot = 'C:\Games',
    [string]$GamePath = 'C:\Games\Steam\steamapps\common\Cyberpunk 2077'
)

$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'Bootstrap-PresentationAudit.ps1 requires PowerShell 7 or newer.' }

$GamesRoot = [IO.Path]::GetFullPath($GamesRoot)
$GamePath = [IO.Path]::GetFullPath($GamePath)
$signature = [DateTime]::Now.ToString('yyyyMMdd-HHmmss') + '-' + [guid]::NewGuid().ToString('N').Substring(0,8)
$reportPath = Join-Path $GamesRoot ('Biology-Presentation-Audit-' + $signature + '.txt')
$repoUrl = 'https://github.com/natanai/cprealpass.git'
$repoPattern = '(?i)(?:github\.com[/:])natanai/cprealpass(?:\.git)?$'
$seedRepo = $null
$auditRoot = $null
$fetchedHead = $null
$auditExit = $null
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

    [pscustomobject]@{
        ExitCode = $exitCode
        StdOut = $stdout
        StdErr = $stderr
        Output = @($combined)
    }
}

function Invoke-GitSafe([string[]]$Arguments,[switch]$Echo) {
    Invoke-NativeSafe -FilePath 'git' -Arguments $Arguments -Echo:$Echo
}

function Get-CprealpassSeed {
    foreach ($directory in @(Get-ChildItem -LiteralPath $GamesRoot -Directory -ErrorAction SilentlyContinue)) {
        # A normal clone has .git/config. Worktrees use a .git pointer file; those are
        # deliberately not selected as the reusable seed because their common repo may
        # have been removed. If only worktrees remain, create a fresh signed seed clone.
        $configPath = Join-Path $directory.FullName '.git\config'
        if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) { continue }

        try {
            $config = Get-Content -Raw -LiteralPath $configPath -ErrorAction Stop
        } catch {
            Add-Evidence "Skipping unreadable Git config candidate: $($directory.FullName)"
            continue
        }

        $urls = [regex]::Matches($config, '(?im)^\s*url\s*=\s*(?<url>.+?)\s*$')
        $matchesRepo = $false
        foreach ($urlMatch in $urls) {
            $normalized = $urlMatch.Groups['url'].Value.Trim().TrimEnd('/')
            if ($normalized -match $repoPattern) {
                $matchesRepo = $true
                break
            }
        }
        if (-not $matchesRepo) { continue }

        $check = Invoke-GitSafe -Arguments @('-C',$directory.FullName,'rev-parse','--show-toplevel')
        if ($check.ExitCode -eq 0) {
            return $directory.FullName
        }

        Add-Evidence "Skipping unusable cprealpass seed candidate: $($directory.FullName)"
        foreach ($line in $check.Output) { Add-Evidence ("  git: " + [string]$line) }
    }
    return $null
}

if (-not (Test-Path -LiteralPath $GamesRoot -PathType Container)) {
    throw "Games root does not exist: $GamesRoot"
}

@(
    'BIOLOGY PRESENTATION LOCAL AUDIT BOOTSTRAP',
    ('Started: ' + [DateTime]::Now.ToString('o')),
    ('Branch: ' + $Branch),
    ('Expected head: ' + $ExpectedHead),
    ('Game: ' + $GamePath),
    'Policy: branch checkout is disposable; the installed game is read-only for this audit.',
    ''
) | Set-Content -LiteralPath $reportPath -Encoding utf8

try {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) { throw 'git is not available on PATH.' }
    if (-not (Get-Command pwsh -ErrorAction SilentlyContinue)) { throw 'PowerShell 7 (pwsh) is not available on PATH.' }
    if (-not (Test-Path -LiteralPath $GamePath -PathType Container)) { throw "Cyberpunk game directory does not exist: $GamePath" }

    $gameExe = Join-Path $GamePath 'bin\x64\Cyberpunk2077.exe'
    if (-not (Test-Path -LiteralPath $gameExe -PathType Leaf)) { throw "Cyberpunk executable does not exist: $gameExe" }
    $gameVersion = (Get-Item -LiteralPath $gameExe).VersionInfo.ProductVersion
    $gameSha256 = (Get-FileHash -LiteralPath $gameExe -Algorithm SHA256).Hash
    Add-Evidence "Cyberpunk product version: $gameVersion"
    Add-Evidence "Cyberpunk executable SHA-256: $gameSha256"

    $seedRepo = Get-CprealpassSeed

    if ([string]::IsNullOrWhiteSpace($seedRepo)) {
        $seedRepo = Join-Path $GamesRoot ('cprealpass-repo-' + $signature)
        Add-Evidence "No usable cprealpass seed checkout found. Cloning seed: $seedRepo"
        Write-Host "No usable cprealpass seed checkout found. Cloning: $seedRepo" -ForegroundColor Cyan
        $clone = Invoke-GitSafe -Arguments @('clone',$repoUrl,$seedRepo) -Echo
        if ($clone.ExitCode -ne 0) { throw "Could not clone natanai/cprealpass (git exit $($clone.ExitCode))." }
    } else {
        Add-Evidence "Existing cprealpass seed found: $seedRepo"
        Write-Host "Using existing cprealpass seed: $seedRepo"
    }

    Add-Evidence "Fetching branch: $Branch"
    $fetch = Invoke-GitSafe -Arguments @('-C',$seedRepo,'fetch','origin',("+refs/heads/{0}:refs/remotes/origin/{0}" -f $Branch)) -Echo
    if ($fetch.ExitCode -ne 0) { throw "Could not fetch $Branch (git exit $($fetch.ExitCode))." }

    $resolve = Invoke-GitSafe -Arguments @('-C',$seedRepo,'rev-parse',("refs/remotes/origin/{0}" -f $Branch))
    if ($resolve.ExitCode -ne 0) {
        foreach ($line in $resolve.Output) { Add-Evidence ("git: " + [string]$line) }
        throw 'Could not resolve fetched branch head.'
    }
    $fetchedHead = $resolve.StdOut.Trim()
    Add-Evidence "Fetched head: $fetchedHead"
    if ($fetchedHead -ne $ExpectedHead) {
        throw "Branch head moved. Expected $ExpectedHead but fetched $fetchedHead. Refusing to audit a different revision."
    }

    $auditRoot = Join-Path $GamesRoot ('cprealpass-presentation-audit-' + $signature)
    if (Test-Path -LiteralPath $auditRoot) { throw "Unique audit path unexpectedly exists: $auditRoot" }

    Add-Evidence "Creating disposable audit checkout: $auditRoot"
    $worktree = Invoke-GitSafe -Arguments @('-C',$seedRepo,'worktree','add','--detach',$auditRoot,$ExpectedHead) -Echo
    if ($worktree.ExitCode -ne 0) { throw "Could not create disposable audit checkout (git exit $($worktree.ExitCode))." }

    Write-Host ''
    Write-Host "AUDIT CHECKOUT: $auditRoot" -ForegroundColor Cyan
    Write-Host "AUDIT HEAD:     $ExpectedHead" -ForegroundColor Cyan
    Write-Host ''

    Add-Evidence ''
    Add-Evidence '=== INNER PRESENTATION AUDIT PROCESS OUTPUT ==='
    $auditProcess = Invoke-NativeSafe -FilePath 'pwsh' -Arguments @(
        '-NoLogo','-NoProfile','-File',(Join-Path $auditRoot 'tools\Audit-PresentationContracts.ps1'),
        '-GamePath',$GamePath,
        '-ReportPath',$reportPath
    ) -Echo
    $auditExit = $auditProcess.ExitCode

    Add-Evidence ''
    Add-Evidence '=== LOCAL AUDIT BOOTSTRAP CONTEXT ==='
    Add-Evidence "Seed checkout: $seedRepo"
    Add-Evidence "Disposable audit checkout: $auditRoot"
    Add-Evidence "Requested branch: $Branch"
    Add-Evidence "Fetched head: $fetchedHead"
    Add-Evidence "Audited head: $ExpectedHead"
    Add-Evidence "Audit process exit code: $auditExit"
    Add-Evidence ('Completed: ' + [DateTime]::Now.ToString('o'))

    if ($auditExit -ne 0) {
        throw "Presentation audit returned exit code $auditExit. See INNER PRESENTATION AUDIT PROCESS OUTPUT above for captured stdout/stderr and child error evidence."
    }
} catch {
    $failed = $true
    Add-Evidence ''
    Add-Evidence '=== LOCAL AUDIT BOOTSTRAP FAILURE ==='
    Add-Evidence ('Time: ' + [DateTime]::Now.ToString('o'))
    Add-Evidence ('Exception type: ' + $_.Exception.GetType().FullName)
    Add-Evidence ('Error: ' + $_.Exception.Message)
    Add-Evidence "Seed checkout: $seedRepo"
    Add-Evidence "Disposable audit checkout: $auditRoot"
    Add-Evidence "Requested branch: $Branch"
    Add-Evidence "Fetched head: $fetchedHead"
    Add-Evidence "Expected head: $ExpectedHead"
    Add-Evidence "Audit process exit code: $auditExit"
    Write-Host ''
    Write-Host 'The audit encountered a failure. The text report contains the child stdout/stderr and exception evidence.' -ForegroundColor Yellow
} finally {
    Write-Host ''
    Write-Host '============================================================' -ForegroundColor Cyan
    Write-Host 'ATTACH THIS FILE TO CHATGPT:' -ForegroundColor Cyan
    Write-Host $reportPath -ForegroundColor Yellow
    Write-Host '============================================================' -ForegroundColor Cyan
}

if ($failed) { exit 1 }
