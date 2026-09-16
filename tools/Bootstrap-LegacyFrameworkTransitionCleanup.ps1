[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$Branch,
    [Parameter(Mandatory=$true)][ValidatePattern('^[0-9a-fA-F]{40}$')][string]$ExpectedHead,
    [Parameter(Mandatory=$true)][string]$PlanPath,
    [Parameter(Mandatory=$true)][ValidatePattern('^[A-Fa-f0-9]{64}$')][string]$ExpectedPlanSha256,
    [string]$GamesRoot = 'C:\Games',
    [string]$GameRoot = 'C:\Games\Steam\steamapps\common\Cyberpunk 2077'
)

$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'Bootstrap-LegacyFrameworkTransitionCleanup.ps1 requires PowerShell 7 or newer.' }
$GamesRoot = [IO.Path]::GetFullPath($GamesRoot)
$GameRoot = [IO.Path]::GetFullPath($GameRoot)
$PlanPath = [IO.Path]::GetFullPath($PlanPath)
$signature = [DateTime]::Now.ToString('yyyyMMdd-HHmmss') + '-' + [guid]::NewGuid().ToString('N').Substring(0,8)
$reportPath = Join-Path $GamesRoot ('Biology-Legacy-Framework-Transition-Cleanup-' + $signature + '.txt')
$innerReport = Join-Path $GamesRoot ('Biology-Legacy-Framework-Transition-Cleanup-Inner-' + $signature + '.txt')
$repoUrl = 'https://github.com/natanai/cprealpass.git'
$repoPattern = '(?i)(?:github\.com[/:])natanai/cprealpass(?:\.git)?$'
$seedRepo = $null; $worktree = $null; $failed = $false

function Add-Evidence([string]$Text) { Add-Content -LiteralPath $reportPath -Value $Text -Encoding utf8 }
function Invoke-NativeSafe([string]$FilePath,[string[]]$Arguments) {
    $psi = [Diagnostics.ProcessStartInfo]::new(); $psi.FileName=$FilePath; $psi.UseShellExecute=$false; $psi.RedirectStandardOutput=$true; $psi.RedirectStandardError=$true; $psi.CreateNoWindow=$true
    foreach ($argument in $Arguments) { [void]$psi.ArgumentList.Add($argument) }
    $process=[Diagnostics.Process]::new(); $process.StartInfo=$psi; $stdout=''; $stderr=''; $exitCode=$null
    try { if (-not $process.Start()) { throw "Unable to start native process: $FilePath" }; $stdout=$process.StandardOutput.ReadToEnd(); $stderr=$process.StandardError.ReadToEnd(); $process.WaitForExit(); $exitCode=$process.ExitCode } finally { $process.Dispose() }
    [pscustomobject]@{ExitCode=$exitCode;StdOut=$stdout;StdErr=$stderr}
}
function Record-Process([string]$Label,$Result) { Add-Evidence ("--- $Label ---"); Add-Evidence ('exit=' + $Result.ExitCode); Add-Evidence 'stdout:'; Add-Evidence $Result.StdOut.TrimEnd(); Add-Evidence 'stderr:'; Add-Evidence $Result.StdErr.TrimEnd() }
function Find-Seed {
    foreach ($directory in @(Get-ChildItem -LiteralPath $GamesRoot -Directory -ErrorAction SilentlyContinue)) {
        $config=Join-Path $directory.FullName '.git\config'; if (-not (Test-Path -LiteralPath $config -PathType Leaf)) { continue }
        try { $text=Get-Content -Raw -LiteralPath $config } catch { continue }; if ($text -notmatch $repoPattern) { continue }
        $check=Invoke-NativeSafe 'git' @('-C',$directory.FullName,'rev-parse','--show-toplevel'); if ($check.ExitCode -eq 0) { return $directory.FullName }
    }
    return $null
}

@(
    'BIOLOGY W11.1 LEGACY FRAMEWORK TRANSITION CLEANUP BOOTSTRAP',
    ('Started: ' + [DateTime]::Now.ToString('o')),
    ('Requested branch: ' + $Branch),
    ('Expected head: ' + $ExpectedHead),
    ('Game root: ' + $GameRoot),
    ('Plan path: ' + $PlanPath),
    ('Expected plan SHA-256: ' + $ExpectedPlanSha256.ToUpperInvariant()),
    'Installed-game mode: MUTATING, limited to the exact plan after full revalidation.',
    ''
) | Set-Content -LiteralPath $reportPath -Encoding utf8

try {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) { throw 'git is not available on PATH.' }
    if (-not (Get-Command pwsh -ErrorAction SilentlyContinue)) { throw 'PowerShell 7 (pwsh) is not available on PATH.' }
    if (-not (Test-Path -LiteralPath $GameRoot -PathType Container)) { throw "Cyberpunk game directory does not exist: $GameRoot" }
    if (-not (Test-Path -LiteralPath $PlanPath -PathType Leaf)) { throw "Approved transition plan does not exist: $PlanPath" }
    $actualPlanHash=(Get-FileHash -Algorithm SHA256 -LiteralPath $PlanPath).Hash.ToUpperInvariant()
    if ($actualPlanHash -ne $ExpectedPlanSha256.ToUpperInvariant()) { throw "Approved plan hash mismatch. Expected $($ExpectedPlanSha256.ToUpperInvariant()), actual $actualPlanHash." }

    $seedRepo=Find-Seed
    if (-not $seedRepo) { $seedRepo=Join-Path $GamesRoot ('cprealpass-repo-' + $signature); $clone=Invoke-NativeSafe 'git' @('clone',$repoUrl,$seedRepo); Record-Process 'git clone' $clone; if ($clone.ExitCode -ne 0) { throw "Could not clone natanai/cprealpass (git exit $($clone.ExitCode))." } }
    else { Add-Evidence ('Seed checkout: ' + $seedRepo) }
    $fetch=Invoke-NativeSafe 'git' @('-C',$seedRepo,'fetch','origin',("+refs/heads/{0}:refs/remotes/origin/{0}" -f $Branch)); Record-Process 'git fetch' $fetch; if ($fetch.ExitCode -ne 0) { throw "Could not fetch $Branch." }
    $resolve=Invoke-NativeSafe 'git' @('-C',$seedRepo,'rev-parse',("refs/remotes/origin/{0}" -f $Branch)); Record-Process 'git rev-parse' $resolve; if ($resolve.ExitCode -ne 0) { throw 'Could not resolve fetched branch head.' }
    $fetchedHead=$resolve.StdOut.Trim(); Add-Evidence ('Fetched head: ' + $fetchedHead); if ($fetchedHead -ne $ExpectedHead) { throw "Branch head moved. Expected $ExpectedHead but fetched $fetchedHead." }
    $worktree=Join-Path $GamesRoot ('cprealpass-w11-cleanup-' + $signature)
    $add=Invoke-NativeSafe 'git' @('-C',$seedRepo,'worktree','add','--detach',$worktree,$ExpectedHead); Record-Process 'git worktree add' $add; if ($add.ExitCode -ne 0) { throw 'Could not create disposable cleanup checkout.' }
    Add-Evidence ('Disposable checkout: ' + $worktree)

    $cleanup=Invoke-NativeSafe 'pwsh' @('-NoLogo','-NoProfile','-File',(Join-Path $worktree 'tools\Remove-LegacyFrameworkTransition.ps1'),'-PlanPath',$PlanPath,'-ExpectedPlanSha256',$ExpectedPlanSha256,'-GameRoot',$GameRoot,'-ReportPath',$innerReport,'-Confirm:$false')
    Record-Process 'inner transition cleanup' $cleanup
    if (Test-Path -LiteralPath $innerReport -PathType Leaf) { Add-Evidence ''; Add-Evidence '=== INNER CLEANUP REPORT ==='; Add-Evidence (Get-Content -Raw -LiteralPath $innerReport) }
    if ($cleanup.ExitCode -ne 0) { throw "Legacy-framework transition cleanup returned exit code $($cleanup.ExitCode)." }
    Add-Evidence 'Proof boundary: targeted transition mutation completed; subsequent W09+W10 build/deploy/gameplay acceptance is still parent-owned.'
} catch {
    $failed=$true; Add-Evidence ''; Add-Evidence '=== BOOTSTRAP FAILURE ==='; Add-Evidence ('Exception type: ' + $_.Exception.GetType().FullName); Add-Evidence ('Error: ' + $_.Exception.Message); Add-Evidence ('Seed checkout: ' + $seedRepo); Add-Evidence ('Disposable checkout: ' + $worktree)
} finally {
    Add-Evidence ('Completed: ' + [DateTime]::Now.ToString('o'))
    Write-Host ''
    Write-Host 'ATTACH THIS FILE TO CHATGPT:' -ForegroundColor Cyan
    Write-Host $reportPath -ForegroundColor Yellow
}
if ($failed) { exit 1 }
