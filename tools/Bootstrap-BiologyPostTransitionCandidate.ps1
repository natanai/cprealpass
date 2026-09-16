[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [ValidatePattern('^[A-Fa-f0-9]{40}$')]
    [string]$MainSha,
    [Parameter(Mandatory=$true)]
    [string]$TransitionCleanupReportPath,
    [Parameter(Mandatory=$true)]
    [ValidatePattern('^[A-Fa-f0-9]{64}$')]
    [string]$ExpectedTransitionCleanupReportSha256,
    [string]$GamesRoot = 'C:\Games',
    [string]$GameRoot = 'C:\Games\Steam\steamapps\common\Cyberpunk 2077'
)

$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'Bootstrap-BiologyPostTransitionCandidate.ps1 requires PowerShell 7 or newer.' }

$MainSha = $MainSha.ToLowerInvariant()
$ExpectedTransitionCleanupReportSha256 = $ExpectedTransitionCleanupReportSha256.ToUpperInvariant()
$GamesRoot = [IO.Path]::GetFullPath($GamesRoot)
$GameRoot = [IO.Path]::GetFullPath($GameRoot)
$TransitionCleanupReportPath = [IO.Path]::GetFullPath($TransitionCleanupReportPath)
New-Item -ItemType Directory -Force -Path $GamesRoot | Out-Null

$signature = [DateTime]::Now.ToString('yyyyMMdd-HHmmss') + '-' + [guid]::NewGuid().ToString('N').Substring(0,8)
$shortSha = $MainSha.Substring(0,8)
$reportPath = Join-Path $GamesRoot ('Biology-Post-Transition-Candidate-Prep-' + $shortSha + '-' + $signature + '.txt')
$artifactRoot = Join-Path $GamesRoot ('Biology-Candidate-Artifacts-' + $shortSha + '-' + $signature)
$repoUrl = 'https://github.com/natanai/cprealpass.git'
$repoPattern = '(?i)(?:github\.com[/:])natanai/cprealpass(?:\.git)?$'
$seedRepo = $null
$seedCreated = $false
$worktree = $null
$resolvedHead = $null
$artifactZip = $null
$artifactHash = $null
$artifactBytes = $null
$gameMutationStarted = $false
$installedReceiptVerified = $false
$deployPassed = $false
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
    $startException = $null
    try {
        try {
            if (-not $process.Start()) { throw "Unable to start native process: $FilePath" }
            $stdout = $process.StandardOutput.ReadToEnd()
            $stderr = $process.StandardError.ReadToEnd()
            $process.WaitForExit()
            $exitCode = $process.ExitCode
        } catch {
            $startException = $_.Exception.ToString()
            if ($null -eq $exitCode) { $exitCode = -1 }
            if ([string]::IsNullOrWhiteSpace($stderr)) { $stderr = $startException }
            else { $stderr = $stderr.TrimEnd() + "`r`n" + $startException }
        }
    } finally {
        $process.Dispose()
    }
    [pscustomobject]@{ ExitCode=$exitCode; StdOut=$stdout; StdErr=$stderr; StartException=$startException }
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
        $originUrl = $origin.StdOut.Trim()
        if ($originUrl -notmatch $repoPattern) { continue }
        Add-Evidence ('Seed candidate accepted by Git origin: ' + $directory.FullName)
        Add-Evidence ('Seed top-level: ' + $top.StdOut.Trim())
        Add-Evidence ('Seed origin: ' + $originUrl)
        return $directory.FullName
    }
    return $null
}

function Resolve-PinnedHead([string]$Seed,[string]$BranchName,[string]$ExpectedHead) {
    $remoteRef = "refs/remotes/origin/$BranchName"
    $fetch = Invoke-NativeSafe 'git' @('-C',$Seed,'fetch','origin',("+refs/heads/{0}:{1}" -f $BranchName,$remoteRef))
    Record-Process ("git fetch origin $BranchName") $fetch
    if ($fetch.ExitCode -eq 0) {
        $resolve = Invoke-NativeSafe 'git' @('-C',$Seed,'rev-parse','--verify',$remoteRef)
        Record-Process 'git rev-parse fetched remote branch' $resolve
        if ($resolve.ExitCode -ne 0) { throw 'Could not resolve fetched canonical main head.' }
        $head = $resolve.StdOut.Trim().ToLowerInvariant()
        Add-Evidence ('Fetched head: ' + $head)
        if ($head -ne $ExpectedHead) { throw "Canonical main moved. Expected $ExpectedHead but fetched $head." }
        return $head
    }

    Add-Evidence 'Fetch failed; evaluating fail-closed cached-origin exact-head fallback.'
    $cached = Invoke-NativeSafe 'git' @('-C',$Seed,'rev-parse','--verify',$remoteRef)
    Record-Process 'git rev-parse cached remote branch' $cached
    if ($cached.ExitCode -ne 0) { throw "Could not fetch $BranchName and no cached origin branch ref is available." }
    $cachedHead = $cached.StdOut.Trim().ToLowerInvariant()
    if ($cachedHead -ne $ExpectedHead) { throw "Could not fetch $BranchName and cached origin head '$cachedHead' does not equal expected '$ExpectedHead'." }
    $object = Invoke-NativeSafe 'git' @('-C',$Seed,'cat-file','-e',("{0}^{{commit}}" -f $ExpectedHead))
    Record-Process 'git cat-file expected commit' $object
    if ($object.ExitCode -ne 0) { throw "Cached origin ref matches expected head but commit object $ExpectedHead is unavailable." }
    Add-Evidence ('Offline exact-head fallback: ACCEPTED; cached origin/' + $BranchName + ' and commit object both equal the expected frozen head.')
    return $cachedHead
}

function Assert-GameStopped {
    $running = @(Get-Process -Name 'Cyberpunk2077' -ErrorAction SilentlyContinue)
    if ($running.Count -gt 0) { throw 'Cyberpunk 2077 is running. Close the game completely before preparing a candidate.' }
}

function Assert-SafeRelativePath([string]$RelativePath) {
    $relative = $RelativePath.Replace('\','/').TrimStart('/')
    if ([string]::IsNullOrWhiteSpace($relative) -or [IO.Path]::IsPathRooted($relative) -or $relative.Contains(':')) { throw "Unsafe transition evidence path: $RelativePath" }
    foreach ($part in @($relative -split '/')) {
        if ($part -in @('','..','.') -or $part -match '[<>"|?*]' -or $part -match '[ .]$') { throw "Unsafe transition evidence path segment: $RelativePath" }
    }
    return $relative
}

function Resolve-SafeGameChild([string]$RelativePath) {
    $relative = Assert-SafeRelativePath $RelativePath
    $root = $GameRoot.TrimEnd([IO.Path]::DirectorySeparatorChar,[IO.Path]::AltDirectorySeparatorChar)
    $candidate = [IO.Path]::GetFullPath((Join-Path $root $relative.Replace('/',[IO.Path]::DirectorySeparatorChar)))
    if (-not $candidate.StartsWith($root + [IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)) { throw "Transition evidence path escapes game root: $RelativePath" }
    return $candidate
}

@(
    'BIOLOGY POST-W11 TRANSITION CANDIDATE PREPARATION',
    ('Started: ' + [DateTime]::Now.ToString('o')),
    ('Requested canonical main SHA: ' + $MainSha),
    ('Game root: ' + $GameRoot),
    ('Transition cleanup report: ' + $TransitionCleanupReportPath),
    ('Expected transition cleanup report SHA-256: ' + $ExpectedTransitionCleanupReportSha256),
    ('Artifact retention root: ' + $artifactRoot),
    'Game-state classification target: accounted W11 transition; NOT a vanilla-baseline verification.',
    'Installed game is read-only until the exact release artifact is successfully built and transition preconditions are rechecked.',
    'The game is never launched by this tool.',
    ''
) | Set-Content -LiteralPath $reportPath -Encoding utf8

try {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) { throw 'git is not available on PATH.' }
    if (-not (Get-Command pwsh -ErrorAction SilentlyContinue)) { throw 'PowerShell 7 (pwsh) is not available on PATH.' }
    if (-not (Test-Path -LiteralPath $GameRoot -PathType Container)) { throw "Cyberpunk game directory does not exist: $GameRoot" }
    if (-not (Test-Path -LiteralPath $TransitionCleanupReportPath -PathType Leaf)) { throw "Parent-approved W11 cleanup report does not exist: $TransitionCleanupReportPath" }
    Assert-GameStopped

    $actualTransitionHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $TransitionCleanupReportPath).Hash.ToUpperInvariant()
    Add-Evidence ('Transition cleanup report actual SHA-256: ' + $actualTransitionHash)
    if ($actualTransitionHash -ne $ExpectedTransitionCleanupReportSha256) { throw "Transition cleanup report hash mismatch. Expected $ExpectedTransitionCleanupReportSha256, actual $actualTransitionHash." }
    $transitionText = Get-Content -Raw -LiteralPath $TransitionCleanupReportPath -ErrorAction Stop
    if ($transitionText -notmatch 'BIOLOGY W11\.1 LEGACY FRAMEWORK TRANSITION CLEANUP') { throw 'Transition evidence is not a W11.1 cleanup report.' }
    if ($transitionText -notmatch '(?m)^RESULT: PASS\s*$') { throw 'Transition cleanup report does not contain the inner RESULT: PASS decision.' }
    if ($transitionText -match '(?m)^RESULT: FAIL-CLOSED\s*$') { throw 'Transition cleanup report contains a FAIL-CLOSED result.' }
    if ($transitionText -notmatch '(?m)^Shared roots were not recursively deleted\.\s*$') { throw 'Transition cleanup report does not prove the shared-root safety boundary.' }
    $redscriptCountMatch = [regex]::Match($transitionText,'(?m)^Protected redscript files reverified:\s*(?<count>\d+)\s*$')
    if (-not $redscriptCountMatch.Success -or [int]$redscriptCountMatch.Groups['count'].Value -lt 1) { throw 'Transition cleanup report does not prove protected redscript re-verification.' }
    $planHashMatch = [regex]::Match($transitionText,'(?im)^Expected plan SHA-256:\s*(?<hash>[A-F0-9]{64})\s*$')
    if (-not $planHashMatch.Success) { throw 'Transition cleanup report does not identify its approved W11 plan hash.' }
    Add-Evidence ('Approved W11 plan SHA-256 recorded by cleanup: ' + $planHashMatch.Groups['hash'].Value.ToUpperInvariant())

    $retiredPaths = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($match in [regex]::Matches($transitionText,'(?m)^DELETE\s+\|\s+[^|]+\|\s+(?<path>[^|]+?)\s+\|\s+[A-F0-9]{64}\s*$')) {
        [void]$retiredPaths.Add((Assert-SafeRelativePath $match.Groups['path'].Value.Trim()))
    }
    foreach ($match in [regex]::Matches($transitionText,'(?m)^ALREADY ABSENT\s+\|\s+[^|]+\|\s+(?<path>.+?)\s*$')) {
        [void]$retiredPaths.Add((Assert-SafeRelativePath $match.Groups['path'].Value.Trim()))
    }
    if ($retiredPaths.Count -lt 1) { throw 'Transition cleanup report contains no exact retired-file set to recheck.' }
    Add-Evidence ('Exact retired paths carried forward from W11 evidence: ' + $retiredPaths.Count)

    $gameExe = Join-Path $GameRoot 'bin\x64\Cyberpunk2077.exe'
    $redmodExe = Join-Path $GameRoot 'tools\redmod\bin\redMod.exe'
    foreach ($required in @($gameExe,$redmodExe)) { if (-not (Test-Path -LiteralPath $required -PathType Leaf)) { throw "Required supported-install file missing: $required" } }
    Add-Evidence ('Cyberpunk product version: ' + (Get-Item -LiteralPath $gameExe).VersionInfo.ProductVersion)
    Add-Evidence ('Cyberpunk executable SHA-256: ' + (Get-FileHash -LiteralPath $gameExe -Algorithm SHA256).Hash.ToUpperInvariant())
    Add-Evidence ('REDmod product version: ' + (Get-Item -LiteralPath $redmodExe).VersionInfo.ProductVersion)
    Add-Evidence ('REDmod executable SHA-256: ' + (Get-FileHash -LiteralPath $redmodExe -Algorithm SHA256).Hash.ToUpperInvariant())

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

    $resolvedHead = Resolve-PinnedHead $seedRepo 'main' $MainSha
    Add-Evidence ('Resolved canonical main head: ' + $resolvedHead)

    $worktree = Join-Path $GamesRoot ('cprealpass-w12-candidate-' + $shortSha + '-' + $signature)
    $add = Invoke-NativeSafe 'git' @('-C',$seedRepo,'worktree','add','--detach',$worktree,$MainSha)
    Record-Process 'git worktree add exact candidate' $add
    if ($add.ExitCode -ne 0) { throw "Could not create exact disposable candidate checkout (git exit $($add.ExitCode))." }
    Add-Evidence ('Disposable candidate checkout: ' + $worktree)

    $head = Invoke-NativeSafe 'git' @('-C',$worktree,'rev-parse','HEAD')
    Record-Process 'git rev-parse candidate HEAD' $head
    if ($head.ExitCode -ne 0 -or $head.StdOut.Trim().ToLowerInvariant() -ne $MainSha) { throw 'Disposable candidate checkout is not the requested canonical main SHA.' }
    $status = Invoke-NativeSafe 'git' @('-C',$worktree,'status','--porcelain=v1','--untracked-files=no')
    Record-Process 'git status candidate source' $status
    if ($status.ExitCode -ne 0) { throw 'Could not inspect candidate source cleanliness.' }
    if (-not [string]::IsNullOrWhiteSpace($status.StdOut)) { throw 'Candidate source has modified tracked files before build.' }
    Add-Evidence 'Candidate source cleanliness: PASS.'

    foreach ($relative in @($retiredPaths | Sort-Object)) {
        $full = Resolve-SafeGameChild $relative
        if (Test-Path -LiteralPath $full) { throw "A W11-retired framework path is present again before candidate install: $relative" }
    }
    Add-Evidence ('W11 retired-path absence recheck: PASS (' + $retiredPaths.Count + ' exact paths absent).')

    $components = Get-Content -Raw -LiteralPath (Join-Path $worktree 'manifest\components.json') | ConvertFrom-Json
    $redscript = @($components.components | Where-Object { [string]$_.id -eq 'redscript' })
    if ($redscript.Count -ne 1) { throw 'Current source does not contain exactly one redscript component contract.' }
    $retainedRedscriptCount = 0
    foreach ($relative in @($redscript[0].deployment)) {
        $full = Resolve-SafeGameChild ([string]$relative)
        if (-not (Test-Path -LiteralPath $full -PathType Leaf)) { throw "W11-transition state is missing intentionally preserved redscript payload: $relative" }
        $retainedRedscriptCount++
    }
    Add-Evidence ('Intentionally preserved shared redscript deployment paths present: ' + $retainedRedscriptCount)

    Add-Evidence ''
    Add-Evidence '=== PRE-INSTALL BIOLOGY-SPECIFIC RESIDUE VERIFICATION ==='
    $verify = Invoke-NativeSafe 'pwsh' @('-NoLogo','-NoProfile','-File',(Join-Path $worktree 'tools\Verify-BiologyRemoval.ps1'),'-GameRoot',$GameRoot)
    Record-Process 'Verify-BiologyRemoval.ps1' $verify
    if ($verify.ExitCode -ne 0 -or $verify.StdOut -notmatch 'PASS: no Biology-specific package/runtime residue was found') { throw 'Biology-specific residue verification did not PASS before candidate install.' }

    Add-Evidence 'Transition-state classification: W11 plan-bound retired-framework cleanup PASS + current retired-path absence + Biology-specific residue verifier PASS + shared redscript intentionally preserved.'
    Add-Evidence 'Proof boundary: this is an explicitly accounted transition state, NOT a fresh reinstall and NOT verification against the recorded vanilla baseline.'

    New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
    Add-Evidence ''
    Add-Evidence '=== EXACT COMPILE / RELEASE-SHAPED BUILD ==='
    $build = Invoke-NativeSafe 'pwsh' @('-NoLogo','-NoProfile','-File',(Join-Path $worktree 'tools\Build-BiologyPackage.ps1'),'-GameRoot',$GameRoot,'-OutputRoot',$artifactRoot)
    Record-Process 'Build-BiologyPackage.ps1' $build
    if ($build.ExitCode -ne 0) { throw "Biology release-shaped build/exact compile failed with exit code $($build.ExitCode)." }

    $zips = @(Get-ChildItem -LiteralPath $artifactRoot -File -Filter '*.zip' -ErrorAction Stop)
    if ($zips.Count -ne 1) { throw "Expected exactly one retained Biology ZIP under $artifactRoot; found $($zips.Count)." }
    $artifactZip = $zips[0].FullName
    $artifactHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $artifactZip).Hash.ToUpperInvariant()
    $artifactBytes = (Get-Item -LiteralPath $artifactZip).Length
    Add-Evidence ('Retained artifact ZIP: ' + $artifactZip)
    Add-Evidence ('Retained artifact SHA-256: ' + $artifactHash)
    Add-Evidence ('Retained artifact bytes: ' + $artifactBytes)

    $roots = @(Get-ChildItem -LiteralPath $artifactRoot -Directory -Filter '*-root' -ErrorAction Stop)
    if ($roots.Count -ne 1) { throw "Expected exactly one package root under retained artifact directory; found $($roots.Count)." }
    $builtManifestPath = Join-Path $roots[0].FullName 'biology\build-manifest.json'
    if (-not (Test-Path -LiteralPath $builtManifestPath -PathType Leaf)) { throw 'Built artifact ownership receipt is missing.' }
    $builtManifest = Get-Content -Raw -LiteralPath $builtManifestPath | ConvertFrom-Json
    if ([string]$builtManifest.sourceRevision -ne $MainSha) { throw "Built artifact source revision mismatch. Expected $MainSha; found $($builtManifest.sourceRevision)." }
    Add-Evidence ('Built receipt sourceRevision: ' + [string]$builtManifest.sourceRevision)

    Assert-GameStopped
    foreach ($relative in @($retiredPaths | Sort-Object)) {
        if (Test-Path -LiteralPath (Resolve-SafeGameChild $relative)) { throw "Transition state changed before install; retired path returned: $relative" }
    }

    Add-Evidence ''
    Add-Evidence '=== INSTALL EXACT RETAINED ARTIFACT ==='
    $gameMutationStarted = $true
    Expand-Archive -LiteralPath $artifactZip -DestinationPath $GameRoot -Force
    Add-Evidence 'Exact retained ZIP expanded into supported game root.'

    $installedManifestPath = Join-Path $GameRoot 'biology\build-manifest.json'
    if (-not (Test-Path -LiteralPath $installedManifestPath -PathType Leaf)) { throw 'Installed Biology build manifest is missing after artifact expansion.' }
    $installedManifest = Get-Content -Raw -LiteralPath $installedManifestPath | ConvertFrom-Json
    if ([string]$installedManifest.sourceRevision -ne $MainSha) { throw "Installed receipt source revision mismatch. Expected $MainSha; found $($installedManifest.sourceRevision)." }
    $installedReceiptVerified = $true
    Add-Evidence ('Installed receipt sourceRevision: ' + [string]$installedManifest.sourceRevision)
    Add-Evidence ('Installed Biology buildId: ' + [string]$installedManifest.buildId)

    Add-Evidence ''
    Add-Evidence '=== OFFICIAL REDMOD DEPLOY ==='
    $deploy = Invoke-NativeSafe 'pwsh' @('-NoLogo','-NoProfile','-File',(Join-Path $worktree 'tools\Deploy-BiologyRedmod.ps1'),'-GameRoot',$GameRoot)
    Record-Process 'Deploy-BiologyRedmod.ps1' $deploy
    if ($deploy.ExitCode -ne 0) { throw "Official REDmod deployment failed with exit code $($deploy.ExitCode)." }
    if ($deploy.StdOut -notmatch 'PASS: REDmod consumed the explicit game root and completed a real deployment') { throw 'REDmod helper exited zero without its positive deployment acceptance marker.' }
    $deployPassed = $true

    Add-Evidence ''
    Add-Evidence 'RESULT: PASS'
    Add-Evidence ('Canonical source revision: ' + $MainSha)
    Add-Evidence ('Artifact ZIP: ' + $artifactZip)
    Add-Evidence ('Artifact SHA-256: ' + $artifactHash)
    Add-Evidence ('Artifact bytes: ' + $artifactBytes)
    Add-Evidence 'REDmod deployment: PASS'
    Add-Evidence 'STOP_BEFORE_GAME_LAUNCH=YES'
    Add-Evidence 'KEEP UNTIL ATTENDED TEST: the retained artifact ZIP and this candidate-prep report.'
    Add-Evidence 'MAY DELETE IMMEDIATELY: cprealpass repo/worktree source state; the exact ZIP and report are outside disposable repo state.'
    Add-Evidence 'The W11 cleanup evidence may be archived/deleted only after the parent has durably recorded its hash/result; it is not needed by the game at runtime.'
} catch {
    $failed = $true
    Add-Evidence ''
    Add-Evidence 'RESULT: FAIL-CLOSED'
    Add-Evidence ('Exception type: ' + $_.Exception.GetType().FullName)
    Add-Evidence ('Error: ' + $_.Exception.Message)
    Add-Evidence ('Resolved canonical head: ' + $resolvedHead)
    Add-Evidence ('Seed checkout: ' + $seedRepo)
    Add-Evidence ('Disposable candidate checkout: ' + $worktree)
    Add-Evidence ('Artifact ZIP: ' + $artifactZip)
    Add-Evidence ('Artifact SHA-256: ' + $artifactHash)
    Add-Evidence ('Artifact bytes: ' + $artifactBytes)
    Add-Evidence ('Game mutation started: ' + $gameMutationStarted)
    Add-Evidence ('Installed receipt exact revision verified: ' + $installedReceiptVerified)
    Add-Evidence ('REDmod deployment passed: ' + $deployPassed)
    if ($gameMutationStarted) { Add-Evidence 'IMPORTANT: failure occurred after installation mutation began. Do not improvise cleanup; return this report to P01.2.' }
    else { Add-Evidence 'Installed game remained read-only because failure occurred before artifact installation began.' }
} finally {
    if ($worktree -and $seedRepo -and (Test-Path -LiteralPath $worktree)) {
        try {
            $removeWorktree = Invoke-NativeSafe 'git' @('-C',$seedRepo,'worktree','remove','--force',$worktree)
            Record-Process 'cleanup disposable candidate worktree' $removeWorktree
            if ($removeWorktree.ExitCode -ne 0) { Add-Evidence ('WARNING: disposable candidate worktree cleanup failed; it may be deleted manually: ' + $worktree) }
            else { Add-Evidence ('Disposable candidate worktree removed: ' + $worktree) }
        } catch {
            Add-Evidence ('WARNING: exception while removing disposable candidate worktree: ' + $_.Exception.Message)
        }
    }
    if ($seedCreated -and $seedRepo -and (Test-Path -LiteralPath $seedRepo)) {
        try {
            Remove-Item -LiteralPath $seedRepo -Recurse -Force -ErrorAction Stop
            Add-Evidence ('Signed seed clone created by this run was removed: ' + $seedRepo)
        } catch {
            Add-Evidence ('WARNING: signed seed clone cleanup failed; it may be deleted manually: ' + $seedRepo + ' | ' + $_.Exception.Message)
        }
    }
    Add-Evidence ('Completed: ' + [DateTime]::Now.ToString('o'))
    Write-Host ''
    Write-Host '============================================================' -ForegroundColor Cyan
    if (-not $failed) {
        Write-Host 'CANDIDATE PREPARATION PASS — STOP BEFORE GAME LAUNCH' -ForegroundColor Green
        Write-Host ('KEEP ARTIFACT: ' + $artifactZip) -ForegroundColor Yellow
        Write-Host ('ARTIFACT SHA-256: ' + $artifactHash) -ForegroundColor Yellow
    } else {
        Write-Host 'CANDIDATE PREPARATION FAIL-CLOSED' -ForegroundColor Yellow
    }
    Write-Host 'ATTACH THIS FILE TO CHATGPT:' -ForegroundColor Cyan
    Write-Host $reportPath -ForegroundColor Yellow
    Write-Host '============================================================' -ForegroundColor Cyan
}

if ($failed) { exit 1 }
