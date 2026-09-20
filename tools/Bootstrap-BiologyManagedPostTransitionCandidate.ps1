[CmdletBinding(DefaultParameterSetName='RepoTransition')]
param(
    [Parameter(Mandatory=$true)]
    [ValidatePattern('^[A-Fa-f0-9]{40}$')]
    [string]$MainSha,

    [Parameter(Mandatory=$true,ParameterSetName='RepoTransition')]
    [ValidatePattern('^[A-Za-z0-9][A-Za-z0-9._-]{0,119}$')]
    [string]$TransitionEvidenceId,

    [Parameter(Mandatory=$true,ParameterSetName='LocalTransition')]
    [string]$TransitionCleanupReportPath,
    [Parameter(Mandatory=$true,ParameterSetName='LocalTransition')]
    [ValidatePattern('^[A-Fa-f0-9]{64}$')]
    [string]$ExpectedTransitionCleanupReportSha256,

    [string]$GamesRoot = 'C:\Games',
    [string]$GameRoot = 'C:\Games\Steam\steamapps\common\Cyberpunk 2077'
)

$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'Bootstrap-BiologyManagedPostTransitionCandidate.ps1 requires PowerShell 7 or newer.' }

$MainSha = $MainSha.ToLowerInvariant()
$GamesRoot = [IO.Path]::GetFullPath($GamesRoot)
$GameRoot = [IO.Path]::GetFullPath($GameRoot)
$signature = [DateTime]::Now.ToString('yyyyMMdd-HHmmss') + '-' + [guid]::NewGuid().ToString('N').Substring(0,8)
$repoUrl = 'https://github.com/natanai/cprealpass.git'
$repoPattern = '(?i)(?:github\.com[/:])natanai/cprealpass(?:\.git)?$'
$seedRepo = $null
$seedCreated = $false
$worktree = $null
$bundlePath = $null
$childReportPath = $null
$childExit = -1
$childStdOut = ''
$childStdErr = ''
$failed = $true

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
    $stdout=''; $stderr=''; $exit=$null
    try {
        try {
            if (-not $process.Start()) { throw "Unable to start native process: $FilePath" }
            $stdout = $process.StandardOutput.ReadToEnd()
            $stderr = $process.StandardError.ReadToEnd()
            $process.WaitForExit()
            $exit = $process.ExitCode
        } catch {
            if ($null -eq $exit) { $exit = -1 }
            $diagnostic = $_.Exception.ToString()
            $stderr = if ([string]::IsNullOrWhiteSpace($stderr)) { $diagnostic } else { $stderr.TrimEnd() + "`r`n" + $diagnostic }
        }
    } finally { $process.Dispose() }
    return [pscustomobject]@{ ExitCode=$exit; StdOut=$stdout; StdErr=$stderr }
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
    $remoteRef='refs/remotes/origin/main'
    $fetch=Invoke-NativeSafe 'git' @('-C',$Seed,'fetch','origin',("+refs/heads/main:{0}" -f $remoteRef))
    if ($fetch.ExitCode -eq 0) {
        $resolve=Invoke-NativeSafe 'git' @('-C',$Seed,'rev-parse','--verify',$remoteRef)
        if ($resolve.ExitCode -ne 0) { throw 'Could not resolve fetched canonical main head.' }
        $head=$resolve.StdOut.Trim().ToLowerInvariant()
        if ($head -ne $ExpectedHead) { throw "Canonical main moved. Expected $ExpectedHead but fetched $head." }
        return $head
    }
    $cached=Invoke-NativeSafe 'git' @('-C',$Seed,'rev-parse','--verify',$remoteRef)
    if ($cached.ExitCode -ne 0) { throw 'Could not fetch main and no cached origin/main ref is available.' }
    $head=$cached.StdOut.Trim().ToLowerInvariant()
    if ($head -ne $ExpectedHead) { throw "Cached origin/main '$head' does not equal expected '$ExpectedHead'." }
    $object=Invoke-NativeSafe 'git' @('-C',$Seed,'cat-file','-e',("{0}^{{commit}}" -f $ExpectedHead))
    if ($object.ExitCode -ne 0) { throw 'Exact cached main commit object is unavailable.' }
    return $head
}

function Get-ReportValue([string]$Text,[string]$Label) {
    $match=[regex]::Match($Text,("(?im)^{0}:\s*(?<value>.*?)\s*$" -f [regex]::Escape($Label)))
    if ($match.Success) { return $match.Groups['value'].Value.Trim() }
    return $null
}
function Get-ReportBool([string]$Text,[string]$Label,[bool]$Default=$false) {
    $value=Get-ReportValue $Text $Label
    if ($null -eq $value) { return $Default }
    return $value.Equals('True',[StringComparison]::OrdinalIgnoreCase) -or $value.Equals('PASS',[StringComparison]::OrdinalIgnoreCase)
}

New-Item -ItemType Directory -Force -Path $GamesRoot | Out-Null
try {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) { throw 'git is not available on PATH.' }
    if (-not (Get-Command pwsh -ErrorAction SilentlyContinue)) { throw 'PowerShell 7 (pwsh) is not available on PATH.' }

    $seedRepo=Find-Seed
    if (-not $seedRepo) {
        $seedRepo=Join-Path $GamesRoot ('cprealpass-repo-' + $signature); $seedCreated=$true
        $clone=Invoke-NativeSafe 'git' @('clone','--no-checkout',$repoUrl,$seedRepo)
        if ($clone.ExitCode -ne 0) { throw 'Could not clone natanai/cprealpass.' }
    }
    [void](Resolve-PinnedMain $seedRepo $MainSha)
    $worktree=Join-Path $GamesRoot ('cprealpass-managed-candidate-' + $MainSha.Substring(0,8) + '-' + $signature)
    $add=Invoke-NativeSafe 'git' @('-C',$seedRepo,'worktree','add','--detach',$worktree,$MainSha)
    if ($add.ExitCode -ne 0) { throw 'Could not create exact managed candidate wrapper checkout.' }

    . (Join-Path $worktree 'tools\BiologyReleaseInstall.Core.ps1')
    . (Join-Path $worktree 'tools\BiologyFailedInstallRecovery.Core.ps1')
    . (Join-Path $worktree 'tools\BiologyOperatorEvidence.Core.ps1')

    if ($PSCmdlet.ParameterSetName -eq 'RepoTransition') {
        $transitionRoot=Get-BiologyOperatorEvidenceRoot $worktree $TransitionEvidenceId
        $transitionEvidencePath=Join-Path $transitionRoot 'evidence.json'
        $TransitionCleanupReportPath=Join-Path $transitionRoot 'report.txt'
        foreach ($required in @($transitionEvidencePath,$TransitionCleanupReportPath)) { if (-not (Test-Path -LiteralPath $required -PathType Leaf)) { throw "Repository transition evidence is incomplete: $required" } }
        $transitionRecord=Get-Content -Raw -LiteralPath $transitionEvidencePath | ConvertFrom-Json
        [void](Assert-BiologyOperatorEvidenceRecord $transitionRecord)
        if ([string]$transitionRecord.evidenceId -ne $TransitionEvidenceId) { throw 'Transition evidence id mismatch.' }
        $ExpectedTransitionCleanupReportSha256=([string]$transitionRecord.handoff.reportSha256).ToUpperInvariant()
        if ((Get-BiologyOperatorTextSha256 $TransitionCleanupReportPath) -ne $ExpectedTransitionCleanupReportSha256) { throw 'Repository transition report does not match its durable evidence hash.' }
    } else {
        $TransitionCleanupReportPath=[IO.Path]::GetFullPath($TransitionCleanupReportPath)
        $ExpectedTransitionCleanupReportSha256=$ExpectedTransitionCleanupReportSha256.ToUpperInvariant()
        if (-not (Test-Path -LiteralPath $TransitionCleanupReportPath -PathType Leaf)) { throw 'Transition cleanup report is unavailable.' }
        if ((Get-BiologyOperatorSha256 $TransitionCleanupReportPath) -ne $ExpectedTransitionCleanupReportSha256) { throw 'Legacy local transition cleanup report does not match its parent-reviewed SHA-256.' }
    }

    $child=Invoke-NativeSafe 'pwsh' @('-NoLogo','-NoProfile','-File',(Join-Path $worktree 'tools\Bootstrap-BiologyPostTransitionCandidate.ps1'),'-MainSha',$MainSha,'-TransitionCleanupReportPath',$TransitionCleanupReportPath,'-ExpectedTransitionCleanupReportSha256',(Get-BiologyOperatorSha256 $TransitionCleanupReportPath),'-GamesRoot',$GamesRoot,'-GameRoot',$GameRoot)
    $childExit=$child.ExitCode; $childStdOut=$child.StdOut; $childStdErr=$child.StdErr
    $reportMatch=[regex]::Match($child.StdOut,'(?im)^ATTACH THIS FILE TO CHATGPT:\s*\r?\n(?<path>[A-Za-z]:\\[^\r\n]+\.txt)\s*$')
    if (-not $reportMatch.Success) { throw 'Inner candidate preparation did not expose its failure-durable report path.' }
    $childReportPath=[IO.Path]::GetFullPath($reportMatch.Groups['path'].Value.Trim())
    if (-not (Test-Path -LiteralPath $childReportPath -PathType Leaf)) { throw 'Inner candidate preparation report is missing.' }

    $innerText=Get-Content -Raw -LiteralPath $childReportPath
    $innerPassed=$innerText -match '(?m)^RESULT: PASS\s*$'
    $innerFailed=$innerText -match '(?m)^RESULT: FAIL-CLOSED\s*$'
    if (-not $innerPassed -and -not $innerFailed) { throw 'Inner candidate preparation report has no recognized result.' }

    $artifactRootText=Get-ReportValue $innerText 'Artifact retention root'
    $artifactRoot=$null; $artifactZip=$null; $packageRoot=$null; $manifest=$null; $receiptHash=$null
    if (-not [string]::IsNullOrWhiteSpace($artifactRootText)) {
        $artifactRoot=[IO.Path]::GetFullPath($artifactRootText)
        if (-not $artifactRoot.StartsWith($GamesRoot.TrimEnd('\','/') + [IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)) { throw 'Inner artifact root escaped GamesRoot.' }
        if (Test-Path -LiteralPath $artifactRoot -PathType Container) {
            $zips=@(Get-ChildItem -LiteralPath $artifactRoot -File -Filter '*.zip' -ErrorAction Stop)
            $roots=@(Get-ChildItem -LiteralPath $artifactRoot -Directory -Filter '*-root' -ErrorAction Stop)
            if ($zips.Count -eq 1 -and $roots.Count -eq 1) {
                $artifactZip=$zips[0]
                $packageRoot=$roots[0]
                $manifestPath=Join-Path $packageRoot.FullName 'biology\build-manifest.json'
                if (Test-Path -LiteralPath $manifestPath -PathType Leaf) {
                    $manifest=Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
                    $receiptHash=(Get-FileHash -LiteralPath $manifestPath -Algorithm SHA256).Hash.ToUpperInvariant()
                    if ([int]$manifest.schemaVersion -ne 2 -or [string]$manifest.product -ne 'Biology' -or ([string]$manifest.sourceRevision).ToLowerInvariant() -ne $MainSha) { throw 'Built payload manifest does not match the exact managed candidate source.' }
                    foreach ($file in @($manifest.files)) {
                        $payloadPath=Resolve-BiologyReleaseChild $packageRoot.FullName ([string]$file.path)
                        if (-not (Test-Path -LiteralPath $payloadPath -PathType Leaf) -or (Get-FileHash -LiteralPath $payloadPath -Algorithm SHA256).Hash.ToUpperInvariant() -ne ([string]$file.sha256).ToUpperInvariant()) { throw "Managed candidate payload does not match built manifest: $($file.path)" }
                    }
                }
            }
        }
    }

    $result=if($innerPassed){'PASS'}else{'FAIL-CLOSED'}
    $gameMutationStarted=if($innerPassed){$true}else{Get-ReportBool $innerText 'Game mutation started'}
    $targetInstallMutationStarted=if($innerPassed){$true}else{Get-ReportBool $innerText 'Target install mutation started'}
    $priorTransitionMutationStarted=Get-ReportBool $innerText 'Prior Biology transition mutation started'
    $installedReceiptVerified=if($innerPassed){$true}else{Get-ReportBool $innerText 'Installed receipt exact revision verified'}
    $deployPassed=if($innerPassed){$true}else{Get-ReportBool $innerText 'REDmod deployment passed'}
    $recoveryEligible=($result -eq 'FAIL-CLOSED' -and $targetInstallMutationStarted -and $null -ne $manifest -and $null -ne $receiptHash)
    $evidenceId=if($null -ne $manifest){[string]$manifest.buildId}else{'candidate-' + $MainSha.Substring(0,12) + '-' + $signature}
    if ($evidenceId -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]{0,119}$') { $evidenceId='candidate-' + $MainSha.Substring(0,12) + '-' + $signature }
    $bundleName='Biology-Operator-Evidence-' + $evidenceId + '.zip'
    $bundlePath=Join-Path $GamesRoot $bundleName

    $handoffTemp=Join-Path ([IO.Path]::GetTempPath()) ('biology-candidate-handoff-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Force -Path $handoffTemp | Out-Null
    try {
        $reportOut=Join-Path $handoffTemp 'report.txt'
        @(
            'BIOLOGY MANAGED POST-TRANSITION CANDIDATE EVIDENCE',
            ('Evidence ID: ' + $evidenceId),
            ('Canonical source revision: ' + $MainSha),
            ('Managed result: ' + $result),
            ('Inner candidate exit code: ' + $childExit),
            ('Transition evidence normalized SHA-256: ' + (Get-BiologyOperatorTextSha256 $TransitionCleanupReportPath)),
            ('Transition evidence file SHA-256 supplied to legacy inner command: ' + (Get-BiologyOperatorSha256 $TransitionCleanupReportPath)),
            ('Game mutation started: ' + $gameMutationStarted),
            ('Prior Biology transition mutation started: ' + $priorTransitionMutationStarted),
            ('Target install mutation started: ' + $targetInstallMutationStarted),
            ('Installed receipt exact revision verified: ' + $installedReceiptVerified),
            ('REDmod deployment passed: ' + $deployPassed),
            ('Recovery evidence eligible: ' + $recoveryEligible),
            '',
            '=== INNER FAILURE-DURABLE REPORT ===',
            $innerText.TrimEnd(),
            '',
            '=== INNER CHILD STDOUT ===',
            $childStdOut.TrimEnd(),
            '',
            '=== INNER CHILD STDERR ===',
            $childStdErr.TrimEnd(),
            '',
            'Lifecycle: return this one ZIP to P01.2. After its exact evidence.json/report.txt are committed, use the repo-owned cleanup command; no manual KEEP/delete list is required.'
        ) | Set-Content -LiteralPath $reportOut -Encoding utf8
        $reportHash=Get-BiologyOperatorTextSha256 $reportOut

        $artifactObject=$null; $cleanup=[ordered]@{artifactRootName=$null;artifactZipName=$null;packageRootName=$null}
        if ($null -ne $artifactZip -and $null -ne $packageRoot -and $null -ne $manifest) {
            $artifactObject=[ordered]@{name=$artifactZip.Name;sha256=(Get-FileHash -LiteralPath $artifactZip.FullName -Algorithm SHA256).Hash.ToUpperInvariant();bytes=[long]$artifactZip.Length;buildId=[string]$manifest.buildId}
            $cleanup=[ordered]@{artifactRootName=[IO.Path]::GetFileName($artifactRoot);artifactZipName=$artifactZip.Name;packageRootName=$packageRoot.Name}
        }
        $gameVersion=Get-ReportValue $innerText 'Cyberpunk product version'; $gameHash=Get-ReportValue $innerText 'Cyberpunk executable SHA-256'
        $redmodVersion=Get-ReportValue $innerText 'REDmod product version'; $redmodHash=Get-ReportValue $innerText 'REDmod executable SHA-256'
        $record=[ordered]@{
            schemaVersion=1; product='Biology'; evidenceId=$evidenceId; operation='post-transition-candidate-preparation'; createdUtc=[DateTime]::UtcNow.ToString('o'); sourceRevision=$MainSha; result=$result
            proofBoundary='Exact candidate preparation evidence. Embedded schema-2 payload manifest and receipt hash authenticate later failed-install recovery without retaining the historical ZIP as proof.'
            game=[ordered]@{productVersion=$gameVersion;executableSha256=$gameHash;redmodProductVersion=$redmodVersion;redmodSha256=$redmodHash}
            artifact=$artifactObject
            install=[ordered]@{transitionEvidenceNormalizedSha256=(Get-BiologyOperatorTextSha256 $TransitionCleanupReportPath);transitionEvidenceFileSha256=(Get-BiologyOperatorSha256 $TransitionCleanupReportPath);preflightPassed=($innerText -match 'Collision-safe install preflight(?: after transition)?: PASS');gameMutationStarted=$gameMutationStarted;priorTransitionMutationStarted=$priorTransitionMutationStarted;targetInstallMutationStarted=$targetInstallMutationStarted;installedReceiptVerified=$installedReceiptVerified;redmodDeploymentPassed=$deployPassed}
            recovery=[ordered]@{mode=if($null -ne $manifest){'exact-payload-manifest'}else{'none'};eligible=$recoveryEligible;receiptSha256=$receiptHash}
            cleanup=$cleanup
            handoff=[ordered]@{bundleName=$bundleName;reportSha256=$reportHash}
        }
        if ($null -ne $manifest) { $record['payloadManifest']=$manifest }
        $record | ConvertTo-Json -Depth 32 | Set-Content -LiteralPath (Join-Path $handoffTemp 'evidence.json') -Encoding utf8
        if (Test-Path -LiteralPath $bundlePath) { Remove-Item -LiteralPath $bundlePath -Force }
        Compress-Archive -LiteralPath (Join-Path $handoffTemp 'evidence.json'),(Join-Path $handoffTemp 'report.txt') -DestinationPath $bundlePath -CompressionLevel Optimal
    } finally {
        if (Test-Path -LiteralPath $handoffTemp) { Remove-Item -LiteralPath $handoffTemp -Recurse -Force }
    }

    if (Test-Path -LiteralPath $childReportPath) { Remove-Item -LiteralPath $childReportPath -Force }
    $failed = -not $innerPassed
} catch {
    $failed=$true
    if (-not $bundlePath) {
        $evidenceId='candidate-wrapper-' + $MainSha.Substring(0,12) + '-' + $signature
        $bundleName='Biology-Operator-Evidence-' + $evidenceId + '.zip'
        $bundlePath=Join-Path $GamesRoot $bundleName
        $temp=Join-Path ([IO.Path]::GetTempPath()) ('biology-candidate-wrapper-failure-' + [guid]::NewGuid().ToString('N'))
        try {
            New-Item -ItemType Directory -Force -Path $temp | Out-Null
            $reportOut=Join-Path $temp 'report.txt'
            @('BIOLOGY MANAGED CANDIDATE WRAPPER FAIL-CLOSED',('Canonical source revision: ' + $MainSha),('Exception type: ' + $_.Exception.GetType().FullName),('Error: ' + $_.Exception.Message),('Inner child exit code: ' + $childExit),'stdout:',$childStdOut.TrimEnd(),'stderr:',$childStdErr.TrimEnd()) | Set-Content -LiteralPath $reportOut -Encoding utf8
            if (Get-Command Get-BiologyOperatorTextSha256 -ErrorAction SilentlyContinue) { $reportHash=Get-BiologyOperatorTextSha256 $reportOut } else { $reportHash=(Get-FileHash -LiteralPath $reportOut -Algorithm SHA256).Hash.ToUpperInvariant() }
            $record=[ordered]@{schemaVersion=1;product='Biology';evidenceId=$evidenceId;operation='post-transition-candidate-preparation';createdUtc=[DateTime]::UtcNow.ToString('o');sourceRevision=$MainSha;result='FAIL-CLOSED';proofBoundary='Wrapper failed before it could establish exact payload evidence; no recovery authority is asserted by this record.';game=$null;artifact=$null;install=[ordered]@{gameMutationStarted=$false;priorTransitionMutationStarted=$false;targetInstallMutationStarted=$false};recovery=[ordered]@{mode='none';eligible=$false};cleanup=[ordered]@{artifactRootName=$null;artifactZipName=$null;packageRootName=$null};handoff=[ordered]@{bundleName=$bundleName;reportSha256=$reportHash}}
            $record | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath (Join-Path $temp 'evidence.json') -Encoding utf8
            Compress-Archive -LiteralPath (Join-Path $temp 'evidence.json'),(Join-Path $temp 'report.txt') -DestinationPath $bundlePath -CompressionLevel Optimal
        } finally { if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Recurse -Force } }
    }
} finally {
    if ($childReportPath -and (Test-Path -LiteralPath $childReportPath)) { try { Remove-Item -LiteralPath $childReportPath -Force } catch {} }
    if ($worktree -and $seedRepo -and (Test-Path -LiteralPath $worktree)) { try { [void](Invoke-NativeSafe 'git' @('-C',$seedRepo,'worktree','remove','--force',$worktree)) } catch {} }
    if ($seedCreated -and $seedRepo -and (Test-Path -LiteralPath $seedRepo)) { try { Remove-Item -LiteralPath $seedRepo -Recurse -Force } catch {} }
    Write-Host ''; Write-Host '============================================================' -ForegroundColor Cyan
    if ($failed) { Write-Host 'MANAGED CANDIDATE PREPARATION FAIL-CLOSED' -ForegroundColor Yellow } else { Write-Host 'MANAGED CANDIDATE PREPARATION PASS — STOP BEFORE GAME LAUNCH' -ForegroundColor Green }
    Write-Host 'ATTACH THIS ONE EVIDENCE BUNDLE TO CHATGPT:' -ForegroundColor Cyan
    Write-Host $bundlePath -ForegroundColor Yellow
    Write-Host 'Parent ingestion + the repo-owned cleanup command manage any local artifact lifecycle; no manual KEEP/delete list is required.' -ForegroundColor Cyan
    Write-Host '============================================================' -ForegroundColor Cyan
}
if ($failed) { exit 1 }