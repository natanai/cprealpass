[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [ValidatePattern('^[A-Fa-f0-9]{40}$')]
    [string]$MainSha,
    [Parameter(Mandatory=$true)]
    [ValidatePattern('^[A-Za-z0-9][A-Za-z0-9._-]{0,119}$')]
    [string]$EvidenceId,
    [string]$GamesRoot = 'C:\Games',
    [string]$GameRoot = 'C:\Games\Steam\steamapps\common\Cyberpunk 2077'
)

$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'Bootstrap-BiologyManagedFailedInstallRecovery.ps1 requires PowerShell 7 or newer.' }
$MainSha = $MainSha.ToLowerInvariant()
$GamesRoot = [IO.Path]::GetFullPath($GamesRoot)
$GameRoot = [IO.Path]::GetFullPath($GameRoot)
New-Item -ItemType Directory -Force -Path $GamesRoot | Out-Null

$signature = [DateTime]::Now.ToString('yyyyMMdd-HHmmss') + '-' + [guid]::NewGuid().ToString('N').Substring(0,8)
$repoUrl = 'https://github.com/natanai/cprealpass.git'
$repoPattern = '(?i)(?:github\.com[/:])natanai/cprealpass(?:\.git)?$'
$seedRepo = $null
$seedCreated = $false
$worktree = $null
$resolvedHead = $null
$inputEvidence = $null
$mutationStarted = $false
$failed = $false
$reportPath = Join-Path $GamesRoot ('Biology-Managed-Recovery-' + $MainSha.Substring(0,8) + '-' + $signature + '.txt')
$bundlePath = $null

function Add-Evidence([string]$Text = '') { Add-Content -LiteralPath $reportPath -Value $Text -Encoding utf8 }
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
            $stdout=$process.StandardOutput.ReadToEnd(); $stderr=$process.StandardError.ReadToEnd(); $process.WaitForExit(); $exit=$process.ExitCode
        } catch {
            if ($null -eq $exit) { $exit=-1 }
            $diag=$_.Exception.ToString(); $stderr=if ([string]::IsNullOrWhiteSpace($stderr)){$diag}else{$stderr.TrimEnd()+"`r`n"+$diag}
        }
    } finally { $process.Dispose() }
    [pscustomobject]@{ExitCode=$exit;StdOut=$stdout;StdErr=$stderr}
}
function Record-Process([string]$Label,$Result) {
    Add-Evidence ("--- $Label ---"); Add-Evidence ('exit=' + $Result.ExitCode); Add-Evidence 'stdout:'; Add-Evidence $Result.StdOut.TrimEnd(); Add-Evidence 'stderr:'; Add-Evidence $Result.StdErr.TrimEnd()
}
function Find-Seed {
    foreach ($directory in @(Get-ChildItem -LiteralPath $GamesRoot -Directory -ErrorAction SilentlyContinue)) {
        $top=Invoke-NativeSafe 'git' @('-C',$directory.FullName,'rev-parse','--show-toplevel'); if ($top.ExitCode -ne 0){continue}
        $origin=Invoke-NativeSafe 'git' @('-C',$directory.FullName,'remote','get-url','origin'); if ($origin.ExitCode -ne 0){continue}
        if ($origin.StdOut.Trim() -notmatch $repoPattern){continue}
        Add-Evidence ('Seed candidate accepted by Git origin: ' + $directory.FullName); return $directory.FullName
    }
    return $null
}
function Resolve-PinnedMain([string]$Seed,[string]$ExpectedHead) {
    $remote='refs/remotes/origin/main'
    $fetch=Invoke-NativeSafe 'git' @('-C',$Seed,'fetch','origin',("+refs/heads/main:{0}" -f $remote)); Record-Process 'git fetch origin main' $fetch
    if ($fetch.ExitCode -eq 0) {
        $resolve=Invoke-NativeSafe 'git' @('-C',$Seed,'rev-parse','--verify',$remote); Record-Process 'git rev-parse fetched origin/main' $resolve
        if ($resolve.ExitCode -ne 0){throw 'Could not resolve fetched canonical main head.'}
        $head=$resolve.StdOut.Trim().ToLowerInvariant(); if ($head -ne $ExpectedHead){throw "Canonical main moved. Expected $ExpectedHead but fetched $head."}; return $head
    }
    Add-Evidence 'Fetch failed; evaluating exact cached-origin/offline fallback.'
    $cached=Invoke-NativeSafe 'git' @('-C',$Seed,'rev-parse','--verify',$remote); Record-Process 'git rev-parse cached origin/main' $cached
    if ($cached.ExitCode -ne 0){throw 'Could not fetch main and no cached origin/main ref is available.'}
    $head=$cached.StdOut.Trim().ToLowerInvariant(); if ($head -ne $ExpectedHead){throw "Cached origin/main $head does not equal expected $ExpectedHead."}
    $obj=Invoke-NativeSafe 'git' @('-C',$Seed,'cat-file','-e',("{0}^{{commit}}" -f $ExpectedHead)); Record-Process 'git cat-file expected main commit' $obj
    if ($obj.ExitCode -ne 0){throw 'Expected cached commit object is unavailable.'}; Add-Evidence 'Offline exact-head fallback: ACCEPTED.'; return $head
}
function Assert-GameStopped { if (Get-Process -Name 'Cyberpunk2077' -ErrorAction SilentlyContinue) { throw 'Cyberpunk 2077 is running. Close the game before failed-install recovery.' } }

@(
 'BIOLOGY MANAGED FAILED-INSTALL RECOVERY',
 ('Started: ' + [DateTime]::Now.ToString('o')),
 ('Requested canonical recovery source: ' + $MainSha),
 ('Repository evidence id: ' + $EvidenceId),
 ('Game root: ' + $GameRoot),
 'Proof boundary: repository-backed exact payload hashes, or legacy empty-owned-root-only evidence. Shared redscript/cybercmd is never deleted.',
 ''
) | Set-Content -LiteralPath $reportPath -Encoding utf8

try {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) { throw 'git is not available on PATH.' }
    if (-not (Get-Command pwsh -ErrorAction SilentlyContinue)) { throw 'PowerShell 7 (pwsh) is not available on PATH.' }
    if (-not (Test-Path -LiteralPath $GameRoot -PathType Container)) { throw "Cyberpunk game directory does not exist: $GameRoot" }
    Assert-GameStopped

    $seedRepo=Find-Seed
    if (-not $seedRepo) {
        $seedRepo=Join-Path $GamesRoot ('cprealpass-repo-' + $signature); $seedCreated=$true
        Add-Evidence ('No usable local cprealpass checkout found. Creating signed seed clone: ' + $seedRepo)
        $clone=Invoke-NativeSafe 'git' @('clone','--no-checkout',$repoUrl,$seedRepo); Record-Process 'git clone seed' $clone
        if ($clone.ExitCode -ne 0){throw 'Could not clone natanai/cprealpass.'}
    }
    $resolvedHead=Resolve-PinnedMain $seedRepo $MainSha; Add-Evidence ('Resolved canonical recovery source: ' + $resolvedHead)
    $worktree=Join-Path $GamesRoot ('cprealpass-managed-recovery-' + $MainSha.Substring(0,8) + '-' + $signature)
    $add=Invoke-NativeSafe 'git' @('-C',$seedRepo,'worktree','add','--detach',$worktree,$MainSha); Record-Process 'git worktree add managed recovery source' $add
    if ($add.ExitCode -ne 0){throw 'Could not create exact disposable managed recovery checkout.'}

    . (Join-Path $worktree 'tools\BiologyReleaseInstall.Core.ps1')
    . (Join-Path $worktree 'tools\BiologyFailedInstallRecovery.Core.ps1')
    . (Join-Path $worktree 'tools\BiologyOperatorEvidence.Core.ps1')
    $evidenceRoot=Get-BiologyOperatorEvidenceRoot $worktree $EvidenceId
    $evidencePath=Join-Path $evidenceRoot 'evidence.json'
    $sourceReport=Join-Path $evidenceRoot 'report.txt'
    foreach ($required in @($evidencePath,$sourceReport)) { if (-not (Test-Path -LiteralPath $required -PathType Leaf)) { throw "Repository-backed operator evidence is incomplete: $required" } }
    $inputEvidence=Get-Content -Raw -LiteralPath $evidencePath | ConvertFrom-Json
    [void](Assert-BiologyOperatorEvidenceRecord $inputEvidence)
    if ([string]$inputEvidence.evidenceId -ne $EvidenceId) { throw 'Repository operator evidence id mismatch.' }
    if ($inputEvidence.handoff -and (Get-BiologyOperatorTextSha256 $sourceReport) -ne ([string]$inputEvidence.handoff.reportSha256).ToUpperInvariant()) { throw 'Repository operator report does not match its evidence record.' }
    Add-Evidence ('Evidence source revision: ' + [string]$inputEvidence.sourceRevision)
    Add-Evidence ('Evidence recovery mode: ' + [string]$inputEvidence.recovery.mode)
    if ($inputEvidence.artifact) { Add-Evidence ('Evidence historical artifact SHA-256: ' + [string]$inputEvidence.artifact.sha256) }

    $gameExe=Join-Path $GameRoot 'bin\x64\Cyberpunk2077.exe'
    if (-not (Test-Path -LiteralPath $gameExe -PathType Leaf)){throw 'Cyberpunk2077.exe is missing from the supplied game root.'}
    $gameVersion=(Get-Item -LiteralPath $gameExe).VersionInfo.ProductVersion
    Add-Evidence ('Cyberpunk product version: ' + $gameVersion)
    Add-Evidence ('Cyberpunk executable SHA-256: ' + (Get-BiologyOperatorSha256 $gameExe))
    if ($inputEvidence.game -and -not [string]::IsNullOrWhiteSpace([string]$inputEvidence.game.productVersion) -and $gameVersion -ne [string]$inputEvidence.game.productVersion) { throw 'Installed Cyberpunk version does not match the durable recovery evidence.' }

    Add-Evidence ''
    Add-Evidence '=== COMPLETE READ/PLAN PHASE — NO GAME MUTATION YET ==='
    if ([string]$inputEvidence.recovery.mode -eq 'exact-payload-manifest') {
        $plan=New-BiologyEvidenceBackedFailedInstallRecoveryPlan -GameRoot $GameRoot -Evidence $inputEvidence
    } elseif ([string]$inputEvidence.recovery.mode -eq 'empty-owned-roots-only') {
        $plan=New-BiologyLegacyEmptyFailedInstallRecoveryPlan -GameRoot $GameRoot -Evidence $inputEvidence
    } else { throw 'Durable operator evidence does not authorize failed-install recovery.' }
    foreach ($item in @($plan.files)) { Add-Evidence ("FILE | {0} | {1} | observed={2}" -f $item.action,$item.relativePath,$item.observedSha256) }
    foreach ($item in @($plan.shared)) { Add-Evidence ("SHARED PRESERVE | {0} | observed={1}" -f $item.relativePath,$item.observedSha256) }
    foreach ($item in @($plan.directories)) { Add-Evidence ("DIR | {0} | {1}" -f $item.action,$item.relativePath) }
    $removeFileCount=@($plan.files | Where-Object action -eq 'remove-exact').Count
    $removeDirectoryCount=@($plan.directories).Count
    Add-Evidence ("Plan summary: exact Biology-owned files to remove={0}; empty Biology-owned directories eligible={1}; shared files preserved={2}." -f $removeFileCount,$removeDirectoryCount,@($plan.shared).Count)
    Add-Evidence 'PLAN STATUS: SAFE-TO-APPLY — all ambiguity checks completed before mutation.'

    Assert-GameStopped
    $mutationStarted=($removeFileCount -gt 0 -or $removeDirectoryCount -gt 0)
    Add-Evidence ''
    Add-Evidence '=== APPLY MANAGED FAILED-INSTALL RECOVERY ==='
    Invoke-BiologyFailedInstallRecoveryPlan -Plan $plan

    Add-Evidence ''
    Add-Evidence '=== POST-RECOVERY READ-ONLY BIOLOGY RESIDUE VERIFIER ==='
    $verify=Invoke-NativeSafe 'pwsh' @('-NoLogo','-NoProfile','-File',(Join-Path $worktree 'tools\Verify-BiologyRemoval.ps1'),'-GameRoot',$GameRoot); Record-Process 'Verify-BiologyRemoval.ps1' $verify
    if ($verify.ExitCode -ne 0 -or $verify.StdOut -notmatch 'PASS: no Biology-specific package/runtime residue was found'){throw 'Post-recovery Biology-specific residue verification did not PASS.'}
    Add-Evidence ''; Add-Evidence 'RESULT: PASS'; Add-Evidence ('Recovery mutation performed: ' + $mutationStarted); Add-Evidence ('Exact Biology-owned files removed: ' + $removeFileCount); Add-Evidence 'Shared redscript/cybercmd deletion count: 0'; Add-Evidence 'Post-recovery Biology-specific residue verifier: PASS'
} catch {
    $failed=$true; Add-Evidence ''; Add-Evidence 'RESULT: FAIL-CLOSED'; Add-Evidence ('Exception type: ' + $_.Exception.GetType().FullName); Add-Evidence ('Error: ' + $_.Exception.Message); Add-Evidence ('Resolved canonical recovery source: ' + $resolvedHead); Add-Evidence ('Recovery mutation started: ' + $mutationStarted)
    if ($mutationStarted){Add-Evidence 'IMPORTANT: managed recovery failed after its exact plan began applying. Return this evidence bundle to P01.2; do not improvise cleanup.'}else{Add-Evidence 'Installed game remained unchanged by managed recovery because failure occurred before recovery mutation began.'}
} finally {
    Add-Evidence ('Completed: ' + [DateTime]::Now.ToString('o'))
    $resultId=('recovery-' + $EvidenceId + '-' + $signature)
    if ($resultId.Length -gt 120){$resultId='recovery-' + $MainSha.Substring(0,12) + '-' + $signature}
    $resultId=$resultId -replace '[^A-Za-z0-9._-]','-'
    $bundleName='Biology-Operator-Evidence-' + $resultId + '.zip'
    $bundlePath=Join-Path $GamesRoot $bundleName
    $handoffTemp=Join-Path ([IO.Path]::GetTempPath()) ('biology-managed-recovery-handoff-' + [guid]::NewGuid().ToString('N'))
    try {
        New-Item -ItemType Directory -Force -Path $handoffTemp | Out-Null
        $reportCopy=Join-Path $handoffTemp 'report.txt'; Copy-Item -LiteralPath $reportPath -Destination $reportCopy
        if (Get-Command Get-BiologyOperatorTextSha256 -ErrorAction SilentlyContinue) { $reportHash=Get-BiologyOperatorTextSha256 $reportCopy } else { $reportHash=(Get-FileHash -LiteralPath $reportCopy -Algorithm SHA256).Hash.ToUpperInvariant() }
        $record=[ordered]@{schemaVersion=1;product='Biology';evidenceId=$resultId;operation='managed-failed-install-recovery';createdUtc=[DateTime]::UtcNow.ToString('o');sourceRevision=$MainSha;result=if($failed){'FAIL-CLOSED'}else{'PASS'};proofBoundary='Result of repository-evidence-backed failed-install recovery. No game launch or REDmod deployment is performed.';game=[ordered]@{productVersion=if(Test-Path -LiteralPath (Join-Path $GameRoot 'bin\x64\Cyberpunk2077.exe')){(Get-Item -LiteralPath (Join-Path $GameRoot 'bin\x64\Cyberpunk2077.exe')).VersionInfo.ProductVersion}else{$null}};artifact=$null;install=[ordered]@{gameMutationStarted=$mutationStarted};recovery=[ordered]@{mode='none';eligible=$false;inputEvidenceId=$EvidenceId};cleanup=[ordered]@{artifactRootName=$null;artifactZipName=$null;packageRootName=$null};handoff=[ordered]@{bundleName=$bundleName;reportSha256=$reportHash}}
        $record | ConvertTo-Json -Depth 16 | Set-Content -LiteralPath (Join-Path $handoffTemp 'evidence.json') -Encoding utf8
        if (Test-Path -LiteralPath $bundlePath){Remove-Item -LiteralPath $bundlePath -Force}
        Compress-Archive -LiteralPath (Join-Path $handoffTemp 'evidence.json'),(Join-Path $handoffTemp 'report.txt') -DestinationPath $bundlePath -CompressionLevel Optimal
    } catch { Write-Warning ('Could not package managed recovery handoff bundle: ' + $_.Exception.Message) }
    finally { if(Test-Path -LiteralPath $handoffTemp){Remove-Item -LiteralPath $handoffTemp -Recurse -Force}; if(Test-Path -LiteralPath $reportPath){Remove-Item -LiteralPath $reportPath -Force} }

    if ($worktree -and $seedRepo -and (Test-Path -LiteralPath $worktree)) { try { [void](Invoke-NativeSafe 'git' @('-C',$seedRepo,'worktree','remove','--force',$worktree)) } catch {} }
    if ($seedCreated -and $seedRepo -and (Test-Path -LiteralPath $seedRepo)) { try { Remove-Item -LiteralPath $seedRepo -Recurse -Force } catch {} }
    Write-Host ''; Write-Host '============================================================' -ForegroundColor Cyan
    if ($failed){Write-Host 'MANAGED FAILED-INSTALL RECOVERY FAIL-CLOSED' -ForegroundColor Yellow}else{Write-Host 'MANAGED FAILED-INSTALL RECOVERY PASS' -ForegroundColor Green}
    Write-Host 'ATTACH THIS ONE EVIDENCE BUNDLE TO CHATGPT:' -ForegroundColor Cyan; Write-Host $bundlePath -ForegroundColor Yellow
    Write-Host 'No manual keep/delete list is required; parent ingestion and the evidence-cleanup command own the local lifecycle.' -ForegroundColor Cyan
    Write-Host '============================================================' -ForegroundColor Cyan
}
if ($failed){exit 1}
