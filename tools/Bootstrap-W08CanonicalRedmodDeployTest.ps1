[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [ValidatePattern('^[A-Fa-f0-9]{40}$')]
    [string]$ExpectedHead,
    [string]$GamePath = 'C:\Games\Steam\steamapps\common\Cyberpunk 2077',
    [string]$GamesRoot = 'C:\Games'
)

$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'Bootstrap-W08CanonicalRedmodDeployTest.ps1 requires PowerShell 7 or newer.' }

$ExpectedHead = $ExpectedHead.ToLowerInvariant()
$signature = "$(Get-Date -Format 'yyyyMMdd-HHmmss')-$([guid]::NewGuid().ToString('N').Substring(0,8))"
$repoUrl = 'https://github.com/natanai/cprealpass.git'
$checkout = Join-Path $GamesRoot "Biology-W08-Deploy-$($ExpectedHead.Substring(0,8))-$signature"
$reportPath = Join-Path $GamesRoot "Biology-W08-Deploy-$($ExpectedHead.Substring(0,8))-$signature.txt"
$failed = $false

function Add-Evidence([string]$Text = '') {
    Add-Content -LiteralPath $reportPath -Value $Text -Encoding utf8
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
        if (-not $process.Start()) { throw "Unable to start child process: $FilePath" }
        $stdout = $process.StandardOutput.ReadToEnd()
        $stderr = $process.StandardError.ReadToEnd()
        $process.WaitForExit()
        $exitCode = $process.ExitCode
    } catch {
        $stderr = (($stderr + "`r`n" + $_.Exception.ToString()).Trim())
        if ($null -eq $exitCode) { $exitCode = -1 }
    } finally {
        $process.Dispose()
    }

    Add-Evidence ("CHILD: {0}" -f $FilePath)
    Add-Evidence ("EXIT: {0}" -f $exitCode)
    Add-Evidence 'STDOUT:'
    Add-Evidence $stdout
    Add-Evidence 'STDERR:'
    Add-Evidence $stderr
    if ($Echo) {
        if (-not [string]::IsNullOrWhiteSpace($stdout)) { Write-Host $stdout }
        if (-not [string]::IsNullOrWhiteSpace($stderr)) { Write-Host $stderr }
    }
    return [pscustomobject]@{ ExitCode=$exitCode; StdOut=$stdout; StdErr=$stderr }
}

function Assert-GameStopped {
    $running = @(Get-Process -Name 'Cyberpunk2077' -ErrorAction SilentlyContinue)
    if ($running.Count -gt 0) { throw 'Cyberpunk 2077 is running. Close the game completely before the deploy test.' }
}

New-Item -ItemType Directory -Force -Path $GamesRoot | Out-Null
@(
    '=== W08 CANONICAL REDMOD DEPLOY ATTENDED GATE ===',
    ('Generated: ' + [DateTime]::Now.ToString('o')),
    ('Expected canonical head: ' + $ExpectedHead),
    ('Game path: ' + $GamePath),
    ('Disposable candidate checkout: ' + $checkout),
    'Purpose: verify the post-W08 canonical-main release package builds, installs, and passes official REDmod 2.31 deployment after a separately verified Biology hard uninstall.',
    'Proof boundary: this is NOT a full vanilla/hash clean-room claim. Shared generic dependencies intentionally preserved by the player uninstaller may already exist.',
    ''
) | Set-Content -LiteralPath $reportPath -Encoding utf8

try {
    Assert-GameStopped
    if (-not (Test-Path -LiteralPath $GamePath -PathType Container)) { throw "Cyberpunk game directory does not exist: $GamePath" }

    $gameExe = Join-Path $GamePath 'bin\x64\Cyberpunk2077.exe'
    $redmodExe = Join-Path $GamePath 'tools\redmod\bin\redMod.exe'
    foreach ($required in @($gameExe,$redmodExe)) {
        if (-not (Test-Path -LiteralPath $required -PathType Leaf)) { throw "Required supported-install file missing: $required" }
    }
    Add-Evidence ('Cyberpunk product version: ' + (Get-Item -LiteralPath $gameExe).VersionInfo.ProductVersion)
    Add-Evidence ('Cyberpunk executable SHA-256: ' + (Get-FileHash -LiteralPath $gameExe -Algorithm SHA256).Hash)
    Add-Evidence ('REDmod product version: ' + (Get-Item -LiteralPath $redmodExe).VersionInfo.ProductVersion)
    Add-Evidence ('REDmod executable SHA-256: ' + (Get-FileHash -LiteralPath $redmodExe -Algorithm SHA256).Hash)

    Write-Host 'Creating exact disposable canonical-main checkout...' -ForegroundColor Cyan
    $clone = Invoke-NativeSafe -FilePath 'git' -Arguments @('clone','--no-checkout',$repoUrl,$checkout) -Echo
    if ($clone.ExitCode -ne 0) { throw "Repository clone failed with exit code $($clone.ExitCode)." }
    $checkoutResult = Invoke-NativeSafe -FilePath 'git' -Arguments @('-C',$checkout,'checkout','--detach',$ExpectedHead) -Echo
    if ($checkoutResult.ExitCode -ne 0) { throw "Exact checkout failed with exit code $($checkoutResult.ExitCode)." }
    $headResult = Invoke-NativeSafe -FilePath 'git' -Arguments @('-C',$checkout,'rev-parse','HEAD')
    if ($headResult.ExitCode -ne 0) { throw 'Could not read disposable checkout head.' }
    $fetchedHead = $headResult.StdOut.Trim().ToLowerInvariant()
    Add-Evidence ('Fetched head: ' + $fetchedHead)
    if ($fetchedHead -ne $ExpectedHead) { throw "Wrong checkout. Expected $ExpectedHead; found $fetchedHead." }

    Add-Evidence ''
    Add-Evidence '=== PRE-INSTALL BIOLOGY-SPECIFIC RESIDUE CHECK ==='
    $verifier = Join-Path $checkout 'tools\Verify-BiologyRemoval.ps1'
    $verify = Invoke-NativeSafe -FilePath 'pwsh' -Arguments @('-NoLogo','-NoProfile','-File',$verifier,'-GameRoot',$GamePath) -Echo
    if ($verify.ExitCode -ne 0) { throw "Pre-install Biology residue verification failed with exit code $($verify.ExitCode)." }

    Write-Host ''
    Write-Host 'Building exact canonical release-shaped Biology package...' -ForegroundColor Cyan
    Add-Evidence ''
    Add-Evidence '=== RELEASE PACKAGE BUILD ==='
    $builder = Join-Path $checkout 'tools\Build-BiologyPackage.ps1'
    $build = Invoke-NativeSafe -FilePath 'pwsh' -Arguments @('-NoLogo','-NoProfile','-File',$builder,'-GameRoot',$GamePath) -Echo
    if ($build.ExitCode -ne 0) { throw "Biology package build failed with exit code $($build.ExitCode)." }

    $packageRoot = Join-Path $checkout 'staging\biology-packages'
    $zips = @(Get-ChildItem -LiteralPath $packageRoot -File -Filter '*.zip' -ErrorAction Stop | Sort-Object LastWriteTimeUtc)
    if ($zips.Count -ne 1) { throw "Expected exactly one release-shaped Biology ZIP in fresh checkout; found $($zips.Count)." }
    $zip = $zips[0].FullName
    $zipHash = (Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash.ToUpperInvariant()
    $zipBytes = (Get-Item -LiteralPath $zip).Length
    Add-Evidence ('Artifact: ' + $zip)
    Add-Evidence ('Artifact SHA-256: ' + $zipHash)
    Add-Evidence ('Artifact bytes: ' + $zipBytes)

    Write-Host ''
    Write-Host 'Installing exact generated package into the supported game root...' -ForegroundColor Cyan
    Expand-Archive -LiteralPath $zip -DestinationPath $GamePath -Force
    foreach ($relative in @('mods\Biology\info.json','biology\build-manifest.json','Uninstall Biology.exe','BIOLOGY-VERSION.txt')) {
        $installed = Join-Path $GamePath $relative
        if (-not (Test-Path -LiteralPath $installed -PathType Leaf)) { throw "Installed package precondition missing after extraction: $relative" }
    }
    $manifest = Get-Content -Raw -LiteralPath (Join-Path $GamePath 'biology\build-manifest.json') | ConvertFrom-Json
    Add-Evidence ('Installed buildId: ' + [string]$manifest.buildId)
    Add-Evidence ('Installed version: ' + [string]$manifest.version)
    Add-Evidence ('Installed sourceRevision: ' + [string]$manifest.sourceRevision)
    if (([string]$manifest.sourceRevision).ToLowerInvariant() -ne $ExpectedHead) {
        throw "Installed package sourceRevision does not match canonical head: $($manifest.sourceRevision)"
    }

    Write-Host ''
    Write-Host 'Running official REDmod deployment...' -ForegroundColor Cyan
    Add-Evidence ''
    Add-Evidence '=== OFFICIAL REDMOD DEPLOY ==='
    $deployScript = Join-Path $checkout 'tools\Deploy-BiologyRedmod.ps1'
    $deploy = Invoke-NativeSafe -FilePath 'pwsh' -Arguments @('-NoLogo','-NoProfile','-File',$deployScript,'-GameRoot',$GamePath) -Echo
    if ($deploy.ExitCode -ne 0) { throw "Official REDmod deployment helper failed with exit code $($deploy.ExitCode)." }
    if ($deploy.StdOut -notmatch '(?m)\[DEPLOY\].*Stage 3/5' -or $deploy.StdOut -notmatch 'Commandlet deploy has succeeded') {
        throw 'Deployment helper exited 0 but expected explicit official REDmod compilation/deploy success evidence was not observed.'
    }
    if ($deploy.StdOut -match "Expected end of file but got: 'using'" -or $deploy.StdErr -match "Expected end of file but got: 'using'") {
        throw 'W08 regression: official REDmod still rejected the standalone tweak with the attended using-parser error.'
    }

    Add-Evidence ''
    Add-Evidence 'PASS: exact canonical-main release package built, installed, and official REDmod 2.31 deployment completed with explicit deployment-stage evidence.'
    Add-Evidence 'STOP BEFORE GAME LAUNCH: return this report to the parent integration thread first.'
    Write-Host ''
    Write-Host 'PASS: W08 canonical official REDmod deploy gate passed.' -ForegroundColor Green
    Write-Host 'STOP BEFORE GAME LAUNCH and attach the report to ChatGPT.' -ForegroundColor Yellow
} catch {
    $failed = $true
    Add-Evidence ''
    Add-Evidence '=== W08 CANONICAL DEPLOY GATE FAILURE ==='
    Add-Evidence ('Time: ' + [DateTime]::Now.ToString('o'))
    Add-Evidence ('Exception type: ' + $_.Exception.GetType().FullName)
    Add-Evidence ('Error: ' + $_.Exception.Message)
    if ($_.InvocationInfo) {
        Add-Evidence ('Script line: ' + $_.InvocationInfo.ScriptLineNumber)
        Add-Evidence ('Position: ' + $_.InvocationInfo.PositionMessage)
    }
    Write-Host ''
    Write-Host ('FAIL: ' + $_.Exception.Message) -ForegroundColor Yellow
} finally {
    Write-Host ''
    Write-Host '============================================================' -ForegroundColor Cyan
    Write-Host 'ATTACH THIS FILE TO CHATGPT:' -ForegroundColor Cyan
    Write-Host $reportPath -ForegroundColor Yellow
    Write-Host '============================================================' -ForegroundColor Cyan
}

if ($failed) { exit 1 }
