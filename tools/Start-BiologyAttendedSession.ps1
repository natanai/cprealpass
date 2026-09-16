[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [ValidatePattern('^[A-Fa-f0-9]{40}$')]
    [string]$MainSha,
    [ValidateSet('Auto','ObserveInstalled','ManagedPostTransition')]
    [string]$PreparationMode = 'Auto',
    [ValidatePattern('^[A-Za-z0-9][A-Za-z0-9._-]{0,119}$')]
    [string]$TransitionEvidenceId,
    [string]$GamesRoot = 'C:\Games',
    [string]$GameRoot = 'C:\Games\Steam\steamapps\common\Cyberpunk 2077'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'Start-BiologyAttendedSession.ps1 requires PowerShell 7 or newer.' }

$MainSha = $MainSha.ToLowerInvariant()
$GamesRoot = [IO.Path]::GetFullPath($GamesRoot).TrimEnd('\','/')
$GameRoot = [IO.Path]::GetFullPath($GameRoot)
$signature = [DateTime]::Now.ToString('yyyyMMdd-HHmmss') + '-' + [guid]::NewGuid().ToString('N').Substring(0,8)
$sessionId = 'attended-' + $MainSha.Substring(0,12) + '-' + $signature
$sessionRoot = Join-Path $GamesRoot ('Biology-Attended-Session-' + $signature)
$bundlePath = Join-Path $GamesRoot ('Biology-Operator-Evidence-' + $sessionId + '.zip')
$repoUrl = 'https://github.com/natanai/cprealpass.git'
$repoPattern = '(?i)(?:github\.com[/:])natanai/cprealpass(?:\.git)?$'
$seedRepo = $null
$seedCreated = $false
$worktree = $null
$prepBundlePath = $null
$prepEvidence = $null
$before = $null
$after = $null
$listener = $null
$startupDiagnostics = $null
$coreLoaded = $false
$finalized = $false
$cleanupAllowed = $false
$resolvedPreparationMode = $PreparationMode
$preparation = $null

function Invoke-BiologySessionNative([string]$FilePath,[string[]]$Arguments) {
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
    $exitCode = -1
    try {
        try {
            if (-not $process.Start()) { throw "Unable to start native process: $FilePath" }
            $stdout = $process.StandardOutput.ReadToEnd()
            $stderr = $process.StandardError.ReadToEnd()
            $process.WaitForExit()
            $exitCode = $process.ExitCode
        } catch {
            $diagnostic = $_.Exception.ToString()
            if ([string]::IsNullOrWhiteSpace($stderr)) { $stderr = $diagnostic }
            else { $stderr = $stderr.TrimEnd() + "`r`n" + $diagnostic }
        }
    } finally {
        $process.Dispose()
    }
    return [pscustomobject]@{ ExitCode=$exitCode; StdOut=$stdout; StdErr=$stderr }
}

function Get-BiologySessionNormalizedTextSha256([string]$Path) {
    $text = [IO.File]::ReadAllText($Path).Replace("`r`n","`n").Replace("`r","`n")
    $bytes = [Text.UTF8Encoding]::new($false).GetBytes($text)
    $sha = [Security.Cryptography.SHA256]::Create()
    try { return ([Convert]::ToHexString($sha.ComputeHash($bytes))).ToUpperInvariant() }
    finally { $sha.Dispose() }
}

function Find-BiologySessionSeed {
    foreach ($directory in @(Get-ChildItem -LiteralPath $GamesRoot -Directory -ErrorAction SilentlyContinue)) {
        $top = Invoke-BiologySessionNative 'git' @('-C',$directory.FullName,'rev-parse','--show-toplevel')
        if ($top.ExitCode -ne 0) { continue }
        $origin = Invoke-BiologySessionNative 'git' @('-C',$directory.FullName,'remote','get-url','origin')
        if ($origin.ExitCode -ne 0) { continue }
        if ($origin.StdOut.Trim() -match $repoPattern) { return $directory.FullName }
    }
    return $null
}

function Resolve-BiologySessionPinnedMain([string]$Seed,[string]$ExpectedHead) {
    $remoteRef = 'refs/remotes/origin/main'
    $fetch = Invoke-BiologySessionNative 'git' @('-C',$Seed,'fetch','origin',("+refs/heads/main:{0}" -f $remoteRef))
    if ($fetch.ExitCode -eq 0) {
        $resolved = Invoke-BiologySessionNative 'git' @('-C',$Seed,'rev-parse','--verify',$remoteRef)
        if ($resolved.ExitCode -ne 0) { throw 'Could not resolve fetched canonical main head.' }
        $head = $resolved.StdOut.Trim().ToLowerInvariant()
        if ($head -ne $ExpectedHead) { throw "Canonical main moved. Expected $ExpectedHead but fetched $head." }
        return $head
    }
    $cached = Invoke-BiologySessionNative 'git' @('-C',$Seed,'rev-parse','--verify',$remoteRef)
    if ($cached.ExitCode -ne 0) { throw 'Fetch failed and cached origin/main is unavailable.' }
    $cachedHead = $cached.StdOut.Trim().ToLowerInvariant()
    if ($cachedHead -ne $ExpectedHead) { throw "Fetch failed and cached origin/main '$cachedHead' does not equal expected '$ExpectedHead'." }
    $object = Invoke-BiologySessionNative 'git' @('-C',$Seed,'cat-file','-e',("{0}^{{commit}}" -f $ExpectedHead))
    if ($object.ExitCode -ne 0) { throw 'Exact cached canonical main commit object is unavailable.' }
    return $cachedHead
}

function Assert-BiologySessionOwnedPath([string]$Path,[string]$Prefix) {
    $full = [IO.Path]::GetFullPath($Path)
    if (-not $full.StartsWith($GamesRoot + [IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)) {
        throw "Session-owned path escapes GamesRoot: $full"
    }
    if (-not [IO.Path]::GetFileName($full).StartsWith($Prefix,[StringComparison]::Ordinal)) {
        throw "Session-owned path has unexpected identity: $full"
    }
    return $full
}

function Write-BiologySessionOwnerMarker {
    New-Item -ItemType Directory -Force -Path $sessionRoot | Out-Null
    $marker = [ordered]@{
        product='Biology'; kind='attended-session'; sessionId=$sessionId
        sourceRevision=$MainSha; createdUtc=[DateTime]::UtcNow.ToString('o')
    }
    $marker | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $sessionRoot 'session-owner.json') -Encoding utf8
}

function Assert-BiologySessionOwnerMarker {
    [void](Assert-BiologySessionOwnedPath $sessionRoot 'Biology-Attended-Session-')
    $markerPath = Join-Path $sessionRoot 'session-owner.json'
    if (-not (Test-Path -LiteralPath $markerPath -PathType Leaf)) { throw 'Session cleanup marker is missing.' }
    $rootItem = Get-Item -Force -LiteralPath $sessionRoot
    if ($rootItem.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Session cleanup refuses a reparse-point session root.' }
    $marker = Get-Content -Raw -LiteralPath $markerPath | ConvertFrom-Json
    if ([string]$marker.product -ne 'Biology' -or [string]$marker.kind -ne 'attended-session' -or [string]$marker.sessionId -ne $sessionId -or ([string]$marker.sourceRevision).ToLowerInvariant() -ne $MainSha) {
        throw 'Session cleanup marker identity does not match this exact session.'
    }
}

function Import-BiologySessionPreparationBundle([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw 'Managed preparation evidence bundle is missing.' }
    $temp = Join-Path $sessionRoot 'preparation-evidence'
    if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Recurse -Force }
    New-Item -ItemType Directory -Force -Path $temp | Out-Null
    Expand-Archive -LiteralPath $Path -DestinationPath $temp
    $evidencePath = Join-Path $temp 'evidence.json'
    $reportPath = Join-Path $temp 'report.txt'
    foreach ($required in @($evidencePath,$reportPath)) {
        if (-not (Test-Path -LiteralPath $required -PathType Leaf)) { throw 'Managed preparation bundle does not contain evidence.json and report.txt.' }
    }
    $record = Get-Content -Raw -LiteralPath $evidencePath | ConvertFrom-Json
    [void](Assert-BiologyOperatorEvidenceRecord $record)
    if (([string]$record.sourceRevision).ToLowerInvariant() -ne $MainSha) { throw 'Managed preparation evidence is not for the requested canonical source revision.' }
    if ((Get-BiologyOperatorTextSha256 $reportPath) -ne ([string]$record.handoff.reportSha256).ToUpperInvariant()) { throw 'Managed preparation report hash does not match its evidence record.' }
    return [pscustomobject]@{ evidence=$record; report=(Get-Content -Raw -LiteralPath $reportPath) }
}

function Invoke-BiologySessionPreparation {
    $effective = $PreparationMode
    if ($effective -eq 'Auto') {
        if ([string]::IsNullOrWhiteSpace($TransitionEvidenceId)) { $effective = 'ObserveInstalled' }
        else { $effective = 'ManagedPostTransition' }
    }
    if (@(Get-Process -Name 'Cyberpunk2077' -ErrorAction SilentlyContinue).Count -gt 0) {
        throw 'Cyberpunk 2077 is already running. Close it before starting the attended session.'
    }

    if ($effective -eq 'ObserveInstalled') {
        $receiptPath = Join-Path $GameRoot 'biology\build-manifest.json'
        if (-not (Test-Path -LiteralPath $receiptPath -PathType Leaf)) { throw 'Installed Biology ownership receipt is missing; cannot bind this session to the requested canonical source.' }
        $receipt = Get-Content -Raw -LiteralPath $receiptPath | ConvertFrom-Json
        if ([int]$receipt.schemaVersion -ne 2 -or [string]$receipt.product -ne 'Biology') { throw 'Installed Biology ownership receipt has an unexpected schema/product.' }
        if (([string]$receipt.sourceRevision).ToLowerInvariant() -ne $MainSha) { throw "Installed Biology source revision '$($receipt.sourceRevision)' does not equal requested canonical source '$MainSha'." }
        return [pscustomobject]@{
            mode=$effective; evidence=$null
            report='Installed Biology receipt matched the exact requested canonical source. No candidate mutation was performed by session preparation.'
            child=$null
        }
    }

    if ([string]::IsNullOrWhiteSpace($TransitionEvidenceId)) { throw 'ManagedPostTransition preparation requires -TransitionEvidenceId.' }
    $wrapper = Join-Path $worktree 'tools\Bootstrap-BiologyManagedPostTransitionCandidate.ps1'
    if (-not (Test-Path -LiteralPath $wrapper -PathType Leaf)) { throw 'Managed W15.2 candidate wrapper is missing from the exact canonical checkout.' }
    $child = Invoke-BiologySessionNative 'pwsh' @('-NoLogo','-NoProfile','-File',$wrapper,'-MainSha',$MainSha,'-TransitionEvidenceId',$TransitionEvidenceId,'-GamesRoot',$GamesRoot,'-GameRoot',$GameRoot)
    $match = [regex]::Match($child.StdOut,'(?im)^ATTACH THIS ONE EVIDENCE BUNDLE TO CHATGPT:\s*\r?\n(?<path>[A-Za-z]:\\[^\r\n]+\.zip)\s*$')
    if (-not $match.Success) {
        throw "Managed W15.2 candidate preparation did not expose its evidence bundle path. Exit=$($child.ExitCode). STDERR=$($child.StdErr.Trim())"
    }
    $script:prepBundlePath = [IO.Path]::GetFullPath($match.Groups['path'].Value.Trim())
    $imported = Import-BiologySessionPreparationBundle $script:prepBundlePath
    return [pscustomobject]@{ mode=$effective; evidence=$imported.evidence; report=$imported.report; child=$child }
}

function Get-BiologySessionReport(
    [string]$Result,[string]$Phase,[string]$PreparationModeResolved,$Preparation,
    $BeforeSnapshot,$AfterSnapshot,$ListenerResult,$Comparison,$StartupDiagnostics,[string]$FailureText
) {
    $lines = [Collections.Generic.List[string]]::new()
    $lines.Add('BIOLOGY ATTENDED TEST SESSION EVIDENCE')
    $lines.Add('Evidence ID: ' + $sessionId)
    $lines.Add('Canonical source revision: ' + $MainSha)
    $lines.Add('Result: ' + $Result)
    $lines.Add('Phase: ' + $Phase)
    $lines.Add('Preparation mode: ' + $PreparationModeResolved)
    $lines.Add('Game root: ' + $GameRoot)
    $lines.Add('Evidence bundle: ' + $bundlePath)
    $lines.Add('Installed Biology candidate is NOT a session-cleanup target.')
    $lines.Add('Proof boundary: this report captures source/candidate identity plus bounded process, REDscript configured-output/current-log, REDmod generated-output, and task-runner evidence. The owner/parent decides gameplay and UI acceptance.')
    if (-not [string]::IsNullOrWhiteSpace($FailureText)) { $lines.Add('Failure: ' + $FailureText) }
    $lines.Add('')

    if ($null -ne $Preparation) {
        $lines.Add('=== PREPARATION ===')
        $lines.Add('Mode: ' + [string]$Preparation.mode)
        if ($null -ne $Preparation.evidence) {
            $lines.Add('Managed preparation evidence ID: ' + [string]$Preparation.evidence.evidenceId)
            $lines.Add('Managed preparation result: ' + [string]$Preparation.evidence.result)
            if ($null -ne $Preparation.evidence.artifact) {
                $lines.Add('Candidate artifact: ' + [string]$Preparation.evidence.artifact.name)
                $lines.Add('Candidate artifact SHA-256: ' + [string]$Preparation.evidence.artifact.sha256)
            }
        }
        $lines.Add(([string]$Preparation.report).TrimEnd())
        if ($null -ne $Preparation.child) {
            $lines.Add('Managed preparation child exit: ' + [string]$Preparation.child.ExitCode)
            if (-not [string]::IsNullOrWhiteSpace([string]$Preparation.child.StdErr)) { $lines.Add('Managed preparation stderr: ' + $Preparation.child.StdErr.TrimEnd()) }
        }
        $lines.Add('')
    }

    if ($null -ne $ListenerResult) {
        $lines.Add('=== PROCESS LISTENER ===')
        $lines.Add('Launch classification: ' + [string]$ListenerResult.classification)
        foreach ($event in @($ListenerResult.events)) { $lines.Add(($event | ConvertTo-Json -Compress -Depth 6)) }
        $lines.Add('')
    }

    if ($null -ne $StartupDiagnostics) {
        $lines.Add('=== STARTUP/EXIT DIAGNOSTICS (BOUNDED) ===')
        $lines.Add(($StartupDiagnostics | ConvertTo-Json -Depth 18))
        $lines.Add('')
    }

    if ($null -ne $Comparison) {
        $lines.Add('=== BEFORE/AFTER CHANGES ===')
        foreach ($change in @($Comparison.changedFiles)) { $lines.Add(($change | ConvertTo-Json -Compress -Depth 6)) }
        $lines.Add('')
        $lines.Add('=== REDSCRIPT CURRENT LOG DELTA (BOUNDED) ===')
        if ([string]::IsNullOrWhiteSpace([string]$Comparison.redscriptCurrentLogDelta)) { $lines.Add('<none captured>') }
        else { $lines.Add([string]$Comparison.redscriptCurrentLogDelta) }
        $lines.Add('')
    }

    if ($null -ne $BeforeSnapshot) {
        $lines.Add('=== PRE-LAUNCH SNAPSHOT (MACHINE-READABLE MIRROR) ===')
        $lines.Add(($BeforeSnapshot | ConvertTo-Json -Depth 18))
        $lines.Add('')
    }
    if ($null -ne $AfterSnapshot) {
        $lines.Add('=== POST-EXIT SNAPSHOT (MACHINE-READABLE MIRROR) ===')
        $lines.Add(($AfterSnapshot | ConvertTo-Json -Depth 18))
        $lines.Add('')
    }
    return ($lines -join "`r`n") + "`r`n"
}

function Finalize-BiologySession([string]$Result,[string]$Phase,$Preparation,[string]$PreparationModeResolved,[string]$FailureText='') {
    $comparison = $null
    if ($null -ne $before -and $null -ne $after) { $comparison = Compare-BiologyAttendedSnapshots $before $after }
    $report = Get-BiologySessionReport -Result $Result -Phase $Phase -PreparationModeResolved $PreparationModeResolved -Preparation $Preparation -BeforeSnapshot $before -AfterSnapshot $after -ListenerResult $listener -Comparison $comparison -StartupDiagnostics $startupDiagnostics -FailureText $FailureText
    $gameRecord = $null
    if ($null -ne $after) { $gameRecord = [ordered]@{ productVersion=$after.gameProductVersion; redmodProductVersion=$after.redmodProductVersion; gameRoot=$GameRoot } }
    elseif ($null -ne $before) { $gameRecord = [ordered]@{ productVersion=$before.gameProductVersion; redmodProductVersion=$before.redmodProductVersion; gameRoot=$GameRoot } }

    $prepSummary = $null
    if ($null -ne $Preparation -and $null -ne $Preparation.evidence) {
        $prepSummary = [ordered]@{ evidenceId=[string]$Preparation.evidence.evidenceId; result=[string]$Preparation.evidence.result; operation=[string]$Preparation.evidence.operation }
    }
    $recordData = [pscustomobject]@{
        game = $gameRecord
        install = [ordered]@{ preparationMode=$PreparationModeResolved; installedCandidatePreserved=$true }
        attendedSession = [ordered]@{
            sessionId=$sessionId; phase=$Phase; listener=$listener; before=$before; after=$after
            comparison=$comparison; startupDiagnostics=$startupDiagnostics; preparation=$prepSummary
        }
    }
    $script:prepEvidence = if ($null -ne $Preparation) { $Preparation.evidence } else { $null }
    [void](Write-BiologyAttendedEvidenceBundle -BundlePath $bundlePath -EvidenceId $sessionId -SourceRevision $MainSha -Result $Result -RecordData $recordData -ReportText $report -PreparationEvidence $script:prepEvidence)
    $script:finalized = $true
    $script:cleanupAllowed = $true

    if ($prepBundlePath -and (Test-Path -LiteralPath $prepBundlePath -PathType Leaf)) { Remove-Item -LiteralPath $prepBundlePath -Force }

    Write-Host ''
    Write-Host 'ATTACH THIS ONE EVIDENCE BUNDLE TO CHATGPT:' -ForegroundColor Cyan
    Write-Host $bundlePath -ForegroundColor Yellow
    Write-Host 'TYPE SENT AFTER THE FILE HAS BEEN ATTACHED' -ForegroundColor Cyan
}

function Write-BiologySessionFallbackBundle([string]$FailureText) {
    $temp = Join-Path ([IO.Path]::GetTempPath()) ('biology-attended-bootstrap-failure-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Force -Path $temp | Out-Null
    try {
        $reportPath = Join-Path $temp 'report.txt'
        @(
            'BIOLOGY ATTENDED TEST SESSION FAIL-CLOSED',
            ('Evidence ID: ' + $sessionId),
            ('Canonical source revision requested: ' + $MainSha),
            'Phase: BOOTSTRAP/SOURCE ACQUISITION FAILED BEFORE READY',
            ('Game root: ' + $GameRoot),
            ('Error: ' + $FailureText),
            'Cyberpunk was not launched by this tool.',
            'Proof boundary: exact source/bootstrap preparation failed before the attended listener could safely reach READY. No gameplay acceptance is asserted.'
        ) | Set-Content -LiteralPath $reportPath -Encoding utf8
        $reportHash = Get-BiologySessionNormalizedTextSha256 $reportPath
        $record = [ordered]@{
            schemaVersion=1; product='Biology'; evidenceId=$sessionId; operation='attended-test-session'
            createdUtc=[DateTime]::UtcNow.ToString('o'); sourceRevision=$MainSha; result='FAIL-CLOSED'
            proofBoundary='Attended-session bootstrap failed before exact source/candidate readiness. This record preserves the requested revision and failure reason; it does not assert runtime acceptance.'
            game=$null; artifact=$null
            install=[ordered]@{preparationMode=$PreparationMode;installedCandidatePreserved=$true}
            recovery=[ordered]@{mode='none';eligible=$false}
            cleanup=[ordered]@{artifactRootName=$null;artifactZipName=$null;packageRootName=$null}
            handoff=[ordered]@{bundleName=[IO.Path]::GetFileName($bundlePath);reportSha256=$reportHash}
            attendedSession=[ordered]@{sessionId=$sessionId;phase='BOOTSTRAP-FAILED-BEFORE-READY';failure=$FailureText}
        }
        $record | ConvertTo-Json -Depth 16 | Set-Content -LiteralPath (Join-Path $temp 'evidence.json') -Encoding utf8
        if (Test-Path -LiteralPath $bundlePath) { Remove-Item -LiteralPath $bundlePath -Force }
        Compress-Archive -LiteralPath (Join-Path $temp 'evidence.json'),(Join-Path $temp 'report.txt') -DestinationPath $bundlePath -CompressionLevel Optimal
        $script:finalized = $true
        $script:cleanupAllowed = $true
    } finally {
        if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Recurse -Force }
    }
}

function Wait-BiologySessionSentConfirmation {
    while ($true) {
        $answer = Read-Host
        if ($answer.Trim().Equals('SENT',[StringComparison]::OrdinalIgnoreCase)) { return }
        Write-Host 'Evidence is preserved. Type SENT only after the bundle has been attached.' -ForegroundColor Yellow
    }
}

function Remove-BiologySessionResidue {
    if (-not $cleanupAllowed -or -not $finalized) { throw 'Session cleanup is not authorized before evidence finalization and SENT confirmation.' }

    if ($null -ne $prepEvidence -and $prepEvidence.PSObject.Properties.Name -contains 'cleanup' -and $null -ne $prepEvidence.cleanup -and -not [string]::IsNullOrWhiteSpace([string]$prepEvidence.cleanup.artifactRootName)) {
        [void](Remove-BiologyManagedArtifactRoot -GamesRoot $GamesRoot -Evidence $prepEvidence)
    }
    if ($prepBundlePath -and (Test-Path -LiteralPath $prepBundlePath)) { throw 'Managed preparation handoff unexpectedly remained after final evidence bundle creation.' }

    Assert-BiologySessionOwnerMarker
    Remove-Item -LiteralPath $sessionRoot -Recurse -Force
    if (Test-Path -LiteralPath $sessionRoot) { throw 'Attended-session staging root remained after cleanup.' }

    if ($worktree -and $seedRepo -and (Test-Path -LiteralPath $worktree)) {
        $remove = Invoke-BiologySessionNative 'git' @('-C',$seedRepo,'worktree','remove','--force',$worktree)
        if ($remove.ExitCode -ne 0 -or (Test-Path -LiteralPath $worktree)) { throw "Could not remove exact attended-session worktree. $($remove.StdErr.Trim())" }
    }

    if ($seedCreated -and $seedRepo -and (Test-Path -LiteralPath $seedRepo)) {
        [void](Assert-BiologySessionOwnedPath $seedRepo 'cprealpass-repo-')
        $seedItem = Get-Item -Force -LiteralPath $seedRepo
        if ($seedItem.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Session cleanup refuses a reparse-point seed repository.' }
        Remove-Item -LiteralPath $seedRepo -Recurse -Force
        if (Test-Path -LiteralPath $seedRepo) { throw 'Session-created seed repository remained after cleanup.' }
    }

    [void](Assert-BiologySessionOwnedPath $bundlePath 'Biology-Operator-Evidence-attended-')
    if (Test-Path -LiteralPath $bundlePath -PathType Leaf) { Remove-Item -LiteralPath $bundlePath -Force }
    if (Test-Path -LiteralPath $bundlePath) { throw 'Attended-session evidence bundle remained after confirmed cleanup.' }
}

function Complete-BiologySessionAfterEvidence([int]$ExitCode) {
    Wait-BiologySessionSentConfirmation
    Remove-BiologySessionResidue
    Write-Host 'SESSION ENDED CLEANLY' -ForegroundColor Green
    exit $ExitCode
}

New-Item -ItemType Directory -Force -Path $GamesRoot | Out-Null
Write-BiologySessionOwnerMarker

try {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) { throw 'git is not available on PATH.' }
    if (-not (Get-Command pwsh -ErrorAction SilentlyContinue)) { throw 'PowerShell 7 (pwsh) is not available on PATH.' }
    if (-not (Test-Path -LiteralPath $GameRoot -PathType Container)) { throw "Cyberpunk game directory does not exist: $GameRoot" }

    $seedRepo = Find-BiologySessionSeed
    if (-not $seedRepo) {
        $seedRepo = Join-Path $GamesRoot ('cprealpass-repo-' + $signature)
        $seedCreated = $true
        $clone = Invoke-BiologySessionNative 'git' @('clone','--no-checkout',$repoUrl,$seedRepo)
        if ($clone.ExitCode -ne 0) { throw "Could not clone natanai/cprealpass. $($clone.StdErr.Trim())" }
    }
    [void](Resolve-BiologySessionPinnedMain $seedRepo $MainSha)

    $worktree = Join-Path $GamesRoot ('cprealpass-attended-session-' + $MainSha.Substring(0,8) + '-' + $signature)
    $add = Invoke-BiologySessionNative 'git' @('-C',$seedRepo,'worktree','add','--detach',$worktree,$MainSha)
    if ($add.ExitCode -ne 0) { throw "Could not create exact attended-session worktree. $($add.StdErr.Trim())" }
    $head = Invoke-BiologySessionNative 'git' @('-C',$worktree,'rev-parse','HEAD')
    if ($head.ExitCode -ne 0 -or $head.StdOut.Trim().ToLowerInvariant() -ne $MainSha) { throw 'Attended-session worktree is not at the exact requested canonical main revision.' }

    . (Join-Path $worktree 'tools\BiologyReleaseInstall.Core.ps1')
    . (Join-Path $worktree 'tools\BiologyFailedInstallRecovery.Core.ps1')
    . (Join-Path $worktree 'tools\BiologyOperatorEvidence.Core.ps1')
    . (Join-Path $worktree 'tools\BiologyAttendedSession.Core.ps1')
    $coreLoaded = $true

    $preparation = Invoke-BiologySessionPreparation
    $resolvedPreparationMode = [string]$preparation.mode
    $prepEvidence = $preparation.evidence
    if ($null -ne $prepEvidence -and [string]$prepEvidence.result -ne 'PASS') {
        try { $before = Get-BiologyAttendedSnapshot $GameRoot } catch {}
        Finalize-BiologySession -Result 'FAIL-CLOSED' -Phase 'PREPARATION-FAILED-BEFORE-READY' -Preparation $preparation -PreparationModeResolved $resolvedPreparationMode -FailureText ('Managed preparation result: ' + [string]$prepEvidence.result)
        Complete-BiologySessionAfterEvidence 1
    }

    $before = Get-BiologyAttendedSnapshot $GameRoot
    if (@($before.processes).Count -gt 0) { throw 'Cyberpunk 2077 started before the listener reached READY; session refused ambiguous pre-launch state.' }
    if ($null -eq $before.installedReceipt -or $before.installedReceipt.PSObject.Properties.Name -contains 'parseError') { throw 'Installed Biology ownership receipt is unavailable or malformed after preparation.' }
    if (([string]$before.installedReceipt.sourceRevision).ToLowerInvariant() -ne $MainSha) { throw 'Installed Biology receipt does not match the exact requested canonical source after preparation.' }

    $listener = Invoke-BiologyAttendedQuietListener
    $after = Get-BiologyAttendedSnapshot $GameRoot
    $startupDiagnostics = Get-BiologyAttendedStartupDiagnostics -GameRoot $GameRoot -SinceUtc ([DateTime]::Parse([string]$before.capturedUtc))
    $result = if ([string]$listener.classification -eq 'STARTED-AND-EXITED') { 'PASS' } else { 'PARTIAL' }
    Finalize-BiologySession -Result $result -Phase 'POST-END-EVIDENCE-FINALIZED' -Preparation $preparation -PreparationModeResolved $resolvedPreparationMode
    Complete-BiologySessionAfterEvidence 0
} catch {
    $failureText = $_.Exception.GetType().FullName + ': ' + $_.Exception.Message
    if ($coreLoaded -and -not $finalized) {
        try {
            if ($null -eq $before) { try { $before = Get-BiologyAttendedSnapshot $GameRoot } catch {} }
            if ($null -ne $before -and $null -eq $after -and @(Get-Process -Name 'Cyberpunk2077' -ErrorAction SilentlyContinue).Count -eq 0) {
                try { $after = Get-BiologyAttendedSnapshot $GameRoot } catch {}
            }
            Finalize-BiologySession -Result 'FAIL-CLOSED' -Phase 'SESSION-FAILED' -Preparation $preparation -PreparationModeResolved $resolvedPreparationMode -FailureText $failureText
            Complete-BiologySessionAfterEvidence 1
        } catch {
            Write-Host ('SESSION CLEANUP/EVIDENCE FAIL-CLOSED: ' + $_.Exception.Message) -ForegroundColor Yellow
            if (Test-Path -LiteralPath $bundlePath -PathType Leaf) {
                Write-Host 'ATTACH THIS ONE EVIDENCE BUNDLE TO CHATGPT:' -ForegroundColor Cyan
                Write-Host $bundlePath -ForegroundColor Yellow
            }
            Write-Host 'Exact session-owned residue was preserved because cleanup could not be proven safe.' -ForegroundColor Yellow
        }
    } else {
        try {
            Write-BiologySessionFallbackBundle -FailureText $failureText
            Write-Host 'ATTACH THIS ONE EVIDENCE BUNDLE TO CHATGPT:' -ForegroundColor Cyan
            Write-Host $bundlePath -ForegroundColor Yellow
            Write-Host 'TYPE SENT AFTER THE FILE HAS BEEN ATTACHED' -ForegroundColor Cyan
            Complete-BiologySessionAfterEvidence 1
        } catch {
            Write-Host ('SESSION BOOTSTRAP EVIDENCE/CLEANUP FAIL-CLOSED: ' + $_.Exception.Message) -ForegroundColor Yellow
            if (Test-Path -LiteralPath $bundlePath -PathType Leaf) {
                Write-Host 'ATTACH THIS ONE EVIDENCE BUNDLE TO CHATGPT:' -ForegroundColor Cyan
                Write-Host $bundlePath -ForegroundColor Yellow
            }
            Write-Host ('Session staging retained for diagnosis: ' + $sessionRoot) -ForegroundColor Yellow
        }
    }
    exit 1
}
