[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [ValidatePattern('^[A-Fa-f0-9]{40}$')]
    [string]$MainSha,
    [Parameter(Mandatory=$true)]
    [ValidatePattern('^[A-Za-z0-9][A-Za-z0-9._-]{0,119}$')]
    [string]$EvidenceId,
    [Parameter(Mandatory=$true)]
    [string]$HandoffBundlePath,
    [string]$GamesRoot = 'C:\Games'
)

$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'Bootstrap-BiologyOperatorEvidenceCleanup.ps1 requires PowerShell 7 or newer.' }

$MainSha = $MainSha.ToLowerInvariant()
$GamesRoot = [IO.Path]::GetFullPath($GamesRoot).TrimEnd('\','/')
$HandoffBundlePath = [IO.Path]::GetFullPath($HandoffBundlePath)
$signature = [DateTime]::Now.ToString('yyyyMMdd-HHmmss') + '-' + [guid]::NewGuid().ToString('N').Substring(0,8)
$repoUrl = 'https://github.com/natanai/cprealpass.git'
$repoPattern = '(?i)(?:github\.com[/:])natanai/cprealpass(?:\.git)?$'
$seedRepo = $null
$seedCreated = $false
$worktree = $null

function Invoke-NativeSafe([string]$FilePath,[string[]]$Arguments) {
    $psi = [Diagnostics.ProcessStartInfo]::new()
    $psi.FileName = $FilePath
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.CreateNoWindow = $true
    foreach ($argument in $Arguments) { [void]$psi.ArgumentList.Add($argument) }
    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $psi
    try {
        if (-not $process.Start()) { throw "Unable to start native process: $FilePath" }
        $stdout = $process.StandardOutput.ReadToEnd()
        $stderr = $process.StandardError.ReadToEnd()
        $process.WaitForExit()
        return [pscustomobject]@{ ExitCode=$process.ExitCode; StdOut=$stdout; StdErr=$stderr }
    } finally {
        $process.Dispose()
    }
}

function Find-Seed {
    foreach ($directory in @(Get-ChildItem -LiteralPath $GamesRoot -Directory -ErrorAction SilentlyContinue)) {
        $top = Invoke-NativeSafe 'git' @('-C',$directory.FullName,'rev-parse','--show-toplevel')
        if ($top.ExitCode -ne 0) { continue }
        $origin = Invoke-NativeSafe 'git' @('-C',$directory.FullName,'remote','get-url','origin')
        if ($origin.ExitCode -ne 0) { continue }
        if ($origin.StdOut.Trim() -match $repoPattern) { return $directory.FullName }
    }
    return $null
}

function Resolve-PinnedMain([string]$Seed,[string]$ExpectedHead) {
    $remoteRef = 'refs/remotes/origin/main'
    $fetch = Invoke-NativeSafe 'git' @('-C',$Seed,'fetch','origin',("+refs/heads/main:{0}" -f $remoteRef))
    if ($fetch.ExitCode -eq 0) {
        $resolve = Invoke-NativeSafe 'git' @('-C',$Seed,'rev-parse','--verify',$remoteRef)
        if ($resolve.ExitCode -ne 0) { throw 'Could not resolve fetched canonical main head.' }
        $head = $resolve.StdOut.Trim().ToLowerInvariant()
        if ($head -ne $ExpectedHead) { throw "Canonical main moved. Expected $ExpectedHead but fetched $head." }
        return $head
    }

    $cached = Invoke-NativeSafe 'git' @('-C',$Seed,'rev-parse','--verify',$remoteRef)
    if ($cached.ExitCode -ne 0) { throw 'Fetch failed and cached origin/main is unavailable.' }
    $cachedHead = $cached.StdOut.Trim().ToLowerInvariant()
    if ($cachedHead -ne $ExpectedHead) { throw "Fetch failed and cached origin/main '$cachedHead' does not equal expected '$ExpectedHead'." }
    $object = Invoke-NativeSafe 'git' @('-C',$Seed,'cat-file','-e',("{0}^{{commit}}" -f $ExpectedHead))
    if ($object.ExitCode -ne 0) { throw 'Exact cached commit object is unavailable.' }
    return $cachedHead
}

try {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) { throw 'git is not available on PATH.' }
    if (-not (Test-Path -LiteralPath $HandoffBundlePath -PathType Leaf)) { throw 'Local operator handoff bundle does not exist.' }
    if (-not $HandoffBundlePath.StartsWith($GamesRoot + [IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)) {
        throw 'Operator handoff bundle must be an ordinary child of GamesRoot.'
    }
    if ([IO.Path]::GetFileName($HandoffBundlePath) -notlike 'Biology-Operator-Evidence-*.zip') {
        throw 'Operator handoff bundle name is outside the managed lifecycle contract.'
    }

    $seedRepo = Find-Seed
    if (-not $seedRepo) {
        $seedRepo = Join-Path $GamesRoot ('cprealpass-repo-' + $signature)
        $seedCreated = $true
        $clone = Invoke-NativeSafe 'git' @('clone','--no-checkout',$repoUrl,$seedRepo)
        if ($clone.ExitCode -ne 0) { throw 'Could not clone natanai/cprealpass.' }
    }
    [void](Resolve-PinnedMain $seedRepo $MainSha)

    $worktree = Join-Path $GamesRoot ('cprealpass-evidence-cleanup-' + $MainSha.Substring(0,8) + '-' + $signature)
    $add = Invoke-NativeSafe 'git' @('-C',$seedRepo,'worktree','add','--detach',$worktree,$MainSha)
    if ($add.ExitCode -ne 0) { throw 'Could not create exact evidence-cleanup checkout.' }

    . (Join-Path $worktree 'tools\BiologyReleaseInstall.Core.ps1')
    . (Join-Path $worktree 'tools\BiologyFailedInstallRecovery.Core.ps1')
    . (Join-Path $worktree 'tools\BiologyOperatorEvidence.Core.ps1')

    $repositoryEvidenceRoot = Get-BiologyOperatorEvidenceRoot $worktree $EvidenceId
    $record = Test-BiologyOperatorEvidenceBundleAgainstRepository -BundlePath $HandoffBundlePath -RepositoryEvidenceRoot $repositoryEvidenceRoot
    if ([string]$record.evidenceId -ne $EvidenceId) { throw 'Local bundle evidence id does not match requested durable evidence id.' }

    $artifactRemoved = Remove-BiologyManagedArtifactRoot -GamesRoot $GamesRoot -Evidence $record
    Remove-Item -LiteralPath $HandoffBundlePath -Force
    if (Test-Path -LiteralPath $HandoffBundlePath) { throw 'Managed handoff bundle remained after cleanup.' }

    Write-Host 'PASS: durable repository evidence exactly matched the local handoff bundle.' -ForegroundColor Green
    if ($artifactRemoved) { Write-Host 'PASS: exact managed candidate artifact root validated and removed.' -ForegroundColor Green }
    Write-Host 'PASS: local handoff bundle removed. No other C:\Games content was targeted.' -ForegroundColor Green
} finally {
    if ($worktree -and $seedRepo -and (Test-Path -LiteralPath $worktree)) {
        try { [void](Invoke-NativeSafe 'git' @('-C',$seedRepo,'worktree','remove','--force',$worktree)) } catch {}
    }
    if ($seedCreated -and $seedRepo -and (Test-Path -LiteralPath $seedRepo)) {
        try { Remove-Item -LiteralPath $seedRepo -Recurse -Force } catch {}
    }
}
