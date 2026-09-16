[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [ValidatePattern('^[A-Fa-f0-9]{40}$')]
    [string]$MainSha,
    [Parameter(Mandatory=$true)]
    [string]$FailedCandidateReportPath,
    [Parameter(Mandatory=$true)]
    [ValidatePattern('^[A-Fa-f0-9]{64}$')]
    [string]$ExpectedFailedCandidateReportSha256,
    [Parameter(Mandatory=$true)]
    [string]$ArtifactZipPath,
    [Parameter(Mandatory=$true)]
    [ValidatePattern('^[A-Fa-f0-9]{64}$')]
    [string]$ExpectedArtifactSha256,
    [string]$GamesRoot = 'C:\Games',
    [string]$GameRoot = 'C:\Games\Steam\steamapps\common\Cyberpunk 2077'
)

$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'Bootstrap-BiologyFailedInstallRecovery.ps1 requires PowerShell 7 or newer.' }

$MainSha = $MainSha.ToLowerInvariant()
$ExpectedFailedCandidateReportSha256 = $ExpectedFailedCandidateReportSha256.ToUpperInvariant()
$ExpectedArtifactSha256 = $ExpectedArtifactSha256.ToUpperInvariant()
$GamesRoot = [IO.Path]::GetFullPath($GamesRoot)
$GameRoot = [IO.Path]::GetFullPath($GameRoot)
$FailedCandidateReportPath = [IO.Path]::GetFullPath($FailedCandidateReportPath)
$ArtifactZipPath = [IO.Path]::GetFullPath($ArtifactZipPath)
New-Item -ItemType Directory -Force -Path $GamesRoot | Out-Null

$signature = [DateTime]::Now.ToString('yyyyMMdd-HHmmss') + '-' + [guid]::NewGuid().ToString('N').Substring(0,8)
$shortSha = $MainSha.Substring(0,8)
$reportPath = Join-Path $GamesRoot ('Biology-Failed-Install-Recovery-' + $shortSha + '-' + $signature + '.txt')
$repoUrl = 'https://github.com/natanai/cprealpass.git'
$repoPattern = '(?i)(?:github\.com[/:])natanai/cprealpass(?:\.git)?$'
$seedRepo = $null
$seedCreated = $false
$worktree = $null
$extractRoot = Join-Path $GamesRoot ('Biology-W14-Recovery-Artifact-' + $signature)
$resolvedHead = $null
$failedSourceRevision = $null
$mutationStarted = $false
$failed = $false

function Add-Evidence([string]$Text = '') {
    Add-Content -LiteralPath $reportPath -Value $Text -Encoding utf8
}

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
    $stdout = ''
    $stderr = ''
    $exitCode = $null
    try {
        try {
            if (-not $process.Start()) { throw "Unable to start native process: $FilePath" }
            $stdout = $process.StandardOutput.ReadToEnd()
            $stderr = $process.StandardError.ReadToEnd()
            $process.WaitForExit()
            $exitCode = $process.ExitCode
        } catch {
            if ($null -eq $exitCode) { $exitCode = -1 }
            $diagnostic = $_.Exception.ToString()
            $stderr = if ([string]::IsNullOrWhiteSpace($stderr)) { $diagnostic } else { $stderr.TrimEnd() + "`r`n" + $diagnostic }
        }
    } finally {
        $process.Dispose()
    }
    return [pscustomobject]@{ ExitCode=$exitCode; StdOut=$stdout; StdErr=$stderr }
}

function Record-Process([string]$Label,$Result) {
    Add-Evidence ("--- $Label ---")
    Add-Evidence ('exit=' + $Result.ExitCode)
    Add-Evidence 'stdout:'
    Add-Evidence $Result.StdOut.TrimEnd()
    Add-Evidence 'stderr:'
    Add-Evidence $Result.StdErr.TrimEnd()
}

function Find-Seed {
    foreach ($directory in @(Get-ChildItem -LiteralPath $GamesRoot -Directory -ErrorAction SilentlyContinue)) {
        $top = Invoke-NativeSafe 'git' @('-C',$directory.FullName,'rev-parse','--show-toplevel')
        if ($top.ExitCode -ne 0) { continue }
        $origin = Invoke-NativeSafe 'git' @('-C',$directory.FullName,'remote','get-url','origin')
        if ($origin.ExitCode -ne 0) { continue }
        if ($origin.StdOut.Trim() -notmatch $repoPattern) { continue }
        Add-Evidence ('Seed candidate accepted by Git origin: ' + $directory.FullName)
        Add-Evidence ('Seed top-level: ' + $top.StdOut.Trim())
        Add-Evidence ('Seed origin: ' + $origin.StdOut.Trim())
        return $directory.FullName
    }
    return $null
}

function Resolve-PinnedMain([string]$Seed,[string]$ExpectedHead) {
    $remoteRef = 'refs/remotes/origin/main'
    $fetch = Invoke-NativeSafe 'git' @('-C',$Seed,'fetch','origin',("+refs/heads/main:{0}" -f $remoteRef))
    Record-Process 'git fetch origin main' $fetch
    if ($fetch.ExitCode -eq 0) {
        $resolve = Invoke-NativeSafe 'git' @('-C',$Seed,'rev-parse','--verify',$remoteRef)
        Record-Process 'git rev-parse fetched origin/main' $resolve
        if ($resolve.ExitCode -ne 0) { throw 'Could not resolve fetched canonical main head.' }
        $head = $resolve.StdOut.Trim().ToLowerInvariant()
        if ($head -ne $ExpectedHead) { throw "Canonical main moved. Expected $ExpectedHead but fetched $head." }
        return $head
    }

    Add-Evidence 'Fetch failed; evaluating exact cached-origin/offline fallback.'
    $cached = Invoke-NativeSafe 'git' @('-C',$Seed,'rev-parse','--verify',$remoteRef)
    Record-Process 'git rev-parse cached origin/main' $cached
    if ($cached.ExitCode -ne 0) { throw 'Could not fetch main and no cached origin/main ref is available.' }
    $cachedHead = $cached.StdOut.Trim().ToLowerInvariant()
    if ($cachedHead -ne $ExpectedHead) { throw "Could not fetch main and cached origin/main '$cachedHead' does not equal expected '$ExpectedHead'." }
    $object = Invoke-NativeSafe 'git' @('-C',$Seed,'cat-file','-e',("{0}^{{commit}}" -f $ExpectedHead))
    Record-Process 'git cat-file expected main commit' $object
    if ($object.ExitCode -ne 0) { throw "Cached origin/main matches expected head but commit object $ExpectedHead is unavailable." }
    Add-Evidence 'Offline exact-head fallback: ACCEPTED.'
    return $cachedHead
}

function Assert-GameStopped {
    if (Get-Process -Name 'Cyberpunk2077' -ErrorAction SilentlyContinue) {
        throw 'Cyberpunk 2077 is running. Close the game before failed-install recovery.'
    }
}

function Assert-SafeArtifactZip([string]$Path) {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archive = [IO.Compression.ZipFile]::OpenRead($Path)
    try {
        foreach ($entry in @($archive.Entries)) {
            $original = [string]$entry.FullName
            $normalized = $original.Replace('\','/')
            if ([IO.Path]::IsPathRooted($original) -or $normalized.StartsWith('/') -or $original.Contains(':')) {
                throw "Unsafe rooted artifact entry: $($entry.FullName)"
            }
            if ([string]::IsNullOrWhiteSpace($normalized)) { continue }

            # ZIP directory entries conventionally end in '/'. Remove exactly
            # that one structural terminator before validating path segments;
            # doubled separators still produce an empty segment and fail closed.
            $relative = $normalized
            if ($relative.EndsWith('/',[StringComparison]::Ordinal)) {
                $relative = $relative.Substring(0,$relative.Length - 1)
            }
            if ([string]::IsNullOrWhiteSpace($relative)) {
                throw "Unsafe artifact ZIP path segment: $($entry.FullName)"
            }

            foreach ($part in @($relative -split '/')) {
                $reservedDevice = $part -match '(?i)^(?:CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])(?:\..*)?$'
                if ($part -in @('','..','.') -or $part -match '[<>"|?*]' -or $part -match '[ .]$' -or $reservedDevice) {
                    throw "Unsafe artifact ZIP path segment: $($entry.FullName)"
                }
            }
        }
    } finally {
        $archive.Dispose()
    }
}

@(
    'BIOLOGY W14.1 FAILED-INSTALL RECOVERY',
    ('Started: ' + [DateTime]::Now.ToString('o')),
    ('Requested canonical recovery source: ' + $MainSha),
    ('Game root: ' + $GameRoot),
    ('Failed candidate report: ' + $FailedCandidateReportPath),
    ('Expected failed report SHA-256: ' + $ExpectedFailedCandidateReportSha256),
    ('Retained failed artifact: ' + $ArtifactZipPath),
    ('Expected retained artifact SHA-256: ' + $ExpectedArtifactSha256),
    'Proof boundary: recover only residue attributable to the exact failed Biology install attempt; this is not a general uninstaller.',
    'Shared redscript/cybercmd payload is inspect-only and must never be removed by this recovery.',
    ''
) | Set-Content -LiteralPath $reportPath -Encoding utf8

try {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) { throw 'git is not available on PATH.' }
    if (-not (Get-Command pwsh -ErrorAction SilentlyContinue)) { throw 'PowerShell 7 (pwsh) is not available on PATH.' }
    if (-not (Test-Path -LiteralPath $GameRoot -PathType Container)) { throw "Cyberpunk game directory does not exist: $GameRoot" }
    if (-not (Test-Path -LiteralPath $FailedCandidateReportPath -PathType Leaf)) { throw 'Failed candidate report does not exist.' }
    if (-not (Test-Path -LiteralPath $ArtifactZipPath -PathType Leaf)) { throw 'Retained failed candidate artifact does not exist.' }
    Assert-GameStopped

    $gameExe = Join-Path $GameRoot 'bin\x64\Cyberpunk2077.exe'
    if (-not (Test-Path -LiteralPath $gameExe -PathType Leaf)) { throw 'Cyberpunk2077.exe is missing from the supplied game root.' }
    Add-Evidence ('Cyberpunk product version: ' + (Get-Item -LiteralPath $gameExe).VersionInfo.ProductVersion)
    Add-Evidence ('Cyberpunk executable SHA-256: ' + (Get-FileHash -LiteralPath $gameExe -Algorithm SHA256).Hash.ToUpperInvariant())

    $reportHash = (Get-FileHash -LiteralPath $FailedCandidateReportPath -Algorithm SHA256).Hash.ToUpperInvariant()
    Add-Evidence ('Failed report actual SHA-256: ' + $reportHash)
    if ($reportHash -ne $ExpectedFailedCandidateReportSha256) { throw 'Failed candidate report SHA-256 does not match the parent-reviewed value.' }
    $failedText = Get-Content -Raw -LiteralPath $FailedCandidateReportPath -ErrorAction Stop
    foreach ($requiredPattern in @(
        'BIOLOGY POST-W11 TRANSITION CANDIDATE PREPARATION',
        '(?m)^RESULT: FAIL-CLOSED\s*$',
        '(?m)^Game mutation started: True\s*$',
        '(?m)^Installed receipt exact revision verified: False\s*$',
        '(?m)^REDmod deployment passed: False\s*$',
        'PASS: no Biology-specific package/runtime residue was found',
        'Collision-safe install preflight: PASS'
    )) {
        if ($failedText -notmatch $requiredPattern) { throw "Failed candidate report does not prove required W14 recovery precondition: $requiredPattern" }
    }
    $sourceMatch = [regex]::Match($failedText,'(?im)^Requested canonical main SHA:\s*(?<sha>[A-F0-9]{40})\s*$')
    if (-not $sourceMatch.Success) { throw 'Failed candidate report does not identify the attempted canonical source revision.' }
    $failedSourceRevision = $sourceMatch.Groups['sha'].Value.ToLowerInvariant()
    Add-Evidence ('Failed attempt canonical source revision: ' + $failedSourceRevision)

    $reportedArtifactHash = [regex]::Match($failedText,'(?im)^Retained artifact SHA-256:\s*(?<hash>[A-F0-9]{64})\s*$')
    if (-not $reportedArtifactHash.Success -or $reportedArtifactHash.Groups['hash'].Value.ToUpperInvariant() -ne $ExpectedArtifactSha256) {
        throw 'Failed report artifact SHA-256 does not match the parent-supplied retained artifact identity.'
    }
    $artifactHash = (Get-FileHash -LiteralPath $ArtifactZipPath -Algorithm SHA256).Hash.ToUpperInvariant()
    Add-Evidence ('Retained artifact actual SHA-256: ' + $artifactHash)
    if ($artifactHash -ne $ExpectedArtifactSha256) { throw 'Retained failed artifact SHA-256 mismatch.' }
    Assert-SafeArtifactZip $ArtifactZipPath

    $seedRepo = Find-Seed
    if (-not $seedRepo) {
        $seedRepo = Join-Path $GamesRoot ('cprealpass-repo-' + $signature)
        $seedCreated = $true
        Add-Evidence ('No usable local cprealpass checkout found. Creating signed seed clone: ' + $seedRepo)
        $clone = Invoke-NativeSafe 'git' @('clone','--no-checkout',$repoUrl,$seedRepo)
        Record-Process 'git clone seed' $clone
        if ($clone.ExitCode -ne 0) { throw "Could not clone natanai/cprealpass (git exit $($clone.ExitCode))." }
    } else {
        Add-Evidence ('Using local-first seed checkout: ' + $seedRepo)
    }

    $resolvedHead = Resolve-PinnedMain $seedRepo $MainSha
    Add-Evidence ('Resolved canonical recovery source: ' + $resolvedHead)
    $worktree = Join-Path $GamesRoot ('cprealpass-w14-recovery-' + $shortSha + '-' + $signature)
    $add = Invoke-NativeSafe 'git' @('-C',$seedRepo,'worktree','add','--detach',$worktree,$MainSha)
    Record-Process 'git worktree add exact recovery source' $add
    if ($add.ExitCode -ne 0) { throw 'Could not create exact disposable W14 recovery checkout.' }

    New-Item -ItemType Directory -Force -Path $extractRoot | Out-Null
    Expand-Archive -LiteralPath $ArtifactZipPath -DestinationPath $extractRoot
    $manifestPath = Join-Path $extractRoot 'biology\build-manifest.json'
    if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) { throw 'Retained failed artifact does not contain biology/build-manifest.json.' }
    $manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
    if ($manifest.schemaVersion -ne 2 -or [string]$manifest.product -ne 'Biology') { throw 'Retained artifact ownership receipt is not a Biology schema-2 receipt.' }
    if ([string]$manifest.sourceRevision -ne $failedSourceRevision) {
        throw "Retained artifact sourceRevision does not match the failed attempt. Artifact=$($manifest.sourceRevision), failed report=$failedSourceRevision"
    }
    Add-Evidence ('Retained artifact buildId: ' + [string]$manifest.buildId)
    Add-Evidence ('Retained artifact sourceRevision: ' + [string]$manifest.sourceRevision)

    . (Join-Path $worktree 'tools\BiologyReleaseInstall.Core.ps1')
    . (Join-Path $worktree 'tools\BiologyFailedInstallRecovery.Core.ps1')

    Add-Evidence ''
    Add-Evidence '=== COMPLETE READ/PLAN PHASE — NO GAME MUTATION YET ==='
    $plan = New-BiologyFailedInstallRecoveryPlan -PackageRoot $extractRoot -GameRoot $GameRoot -Manifest $manifest
    foreach ($item in @($plan.files)) {
        Add-Evidence ("FILE | {0} | {1} | observed={2}" -f $item.action,$item.relativePath,$item.observedSha256)
    }
    foreach ($item in @($plan.shared)) {
        Add-Evidence ("SHARED PRESERVE | {0} | observed={1}" -f $item.relativePath,$item.observedSha256)
    }
    foreach ($item in @($plan.directories)) {
        Add-Evidence ("DIR | {0} | {1}" -f $item.action,$item.relativePath)
    }
    $removeFileCount = @($plan.files | Where-Object action -eq 'remove-exact').Count
    $removeDirectoryCount = @($plan.directories).Count
    Add-Evidence ("Plan summary: exact Biology-owned files to remove={0}; existing known Biology-owned directories eligible if empty={1}; shared files preserved={2}." -f $removeFileCount,$removeDirectoryCount,@($plan.shared).Count)
    Add-Evidence 'PLAN STATUS: SAFE-TO-APPLY — all ambiguity checks completed before mutation.'

    Assert-GameStopped
    $mutationStarted = ($removeFileCount -gt 0 -or $removeDirectoryCount -gt 0)
    Add-Evidence ''
    Add-Evidence '=== APPLY EXACT FAILED-INSTALL RECOVERY ==='
    Invoke-BiologyFailedInstallRecoveryPlan -Plan $plan

    Add-Evidence ''
    Add-Evidence '=== POST-RECOVERY READ-ONLY BIOLOGY RESIDUE VERIFIER ==='
    $verify = Invoke-NativeSafe 'pwsh' @('-NoLogo','-NoProfile','-File',(Join-Path $worktree 'tools\Verify-BiologyRemoval.ps1'),'-GameRoot',$GameRoot)
    Record-Process 'Verify-BiologyRemoval.ps1' $verify
    if ($verify.ExitCode -ne 0 -or $verify.StdOut -notmatch 'PASS: no Biology-specific package/runtime residue was found') {
        throw 'Post-recovery Biology-specific residue verification did not PASS.'
    }

    Add-Evidence ''
    Add-Evidence 'RESULT: PASS'
    Add-Evidence ('Recovery implementation source: ' + $MainSha)
    Add-Evidence ('Recovered failed candidate source: ' + $failedSourceRevision)
    Add-Evidence ('Game mutation performed: ' + $mutationStarted)
    Add-Evidence ('Exact Biology-owned files removed: ' + $removeFileCount)
    Add-Evidence 'Shared redscript/cybercmd deletion count: 0'
    Add-Evidence 'Post-recovery Biology-specific residue verifier: PASS'
    Add-Evidence 'Recovery proof boundary: exact failed-install residue only; no REDmod deployment and no game launch were performed.'
} catch {
    $failed = $true
    Add-Evidence ''
    Add-Evidence 'RESULT: FAIL-CLOSED'
    Add-Evidence ('Exception type: ' + $_.Exception.GetType().FullName)
    Add-Evidence ('Error: ' + $_.Exception.Message)
    Add-Evidence ('Resolved canonical recovery source: ' + $resolvedHead)
    Add-Evidence ('Failed candidate source revision: ' + $failedSourceRevision)
    Add-Evidence ('Recovery mutation started: ' + $mutationStarted)
    if ($mutationStarted) {
        Add-Evidence 'IMPORTANT: recovery failed after its exact plan began applying. Do not improvise further cleanup; return this report to P01.2.'
    } else {
        Add-Evidence 'Installed game remained unchanged by W14 recovery because failure occurred before recovery mutation began.'
    }
} finally {
    if ($extractRoot -and (Test-Path -LiteralPath $extractRoot)) {
        try { Remove-Item -LiteralPath $extractRoot -Recurse -Force -ErrorAction Stop; Add-Evidence ('Temporary retained-artifact extraction removed: ' + $extractRoot) }
        catch { Add-Evidence ('WARNING: temporary artifact extraction cleanup failed: ' + $_.Exception.Message) }
    }
    if ($worktree -and $seedRepo -and (Test-Path -LiteralPath $worktree)) {
        try {
            $removeWorktree = Invoke-NativeSafe 'git' @('-C',$seedRepo,'worktree','remove','--force',$worktree)
            Record-Process 'cleanup disposable recovery worktree' $removeWorktree
            if ($removeWorktree.ExitCode -ne 0) { Add-Evidence ('WARNING: disposable recovery worktree cleanup failed: ' + $worktree) }
        } catch { Add-Evidence ('WARNING: exception while removing recovery worktree: ' + $_.Exception.Message) }
    }
    if ($seedCreated -and $seedRepo -and (Test-Path -LiteralPath $seedRepo)) {
        try { Remove-Item -LiteralPath $seedRepo -Recurse -Force -ErrorAction Stop; Add-Evidence ('Signed seed clone created by this recovery was removed: ' + $seedRepo) }
        catch { Add-Evidence ('WARNING: signed seed clone cleanup failed: ' + $_.Exception.Message) }
    }
    Add-Evidence ('Completed: ' + [DateTime]::Now.ToString('o'))
    Write-Host ''
    Write-Host '============================================================' -ForegroundColor Cyan
    if ($failed) { Write-Host 'W14 FAILED-INSTALL RECOVERY FAIL-CLOSED' -ForegroundColor Yellow }
    else { Write-Host 'W14 FAILED-INSTALL RECOVERY PASS' -ForegroundColor Green }
    Write-Host 'ATTACH THIS FILE TO CHATGPT:' -ForegroundColor Cyan
    Write-Host $reportPath -ForegroundColor Yellow
    Write-Host '============================================================' -ForegroundColor Cyan
}

if ($failed) { exit 1 }
