[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [ValidatePattern('^[A-Fa-f0-9]{40}$')]
    [string]$ExpectedHead,
    [string]$GamePath = 'C:\Games\Steam\steamapps\common\Cyberpunk 2077',
    [string]$GamesRoot = 'C:\Games'
)

$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'Bootstrap-BiologyHardUninstallTest.ps1 requires PowerShell 7 or newer.' }

$ExpectedHead = $ExpectedHead.ToLowerInvariant()
$signature = "$(Get-Date -Format 'yyyyMMdd-HHmmss')-$([guid]::NewGuid().ToString('N').Substring(0,8))"
$repoUrl = 'https://github.com/natanai/cprealpass.git'
$checkout = Join-Path $GamesRoot "Biology-Hard-Uninstall-Verify-$($ExpectedHead.Substring(0,8))-$signature"
$reportPath = Join-Path $GamesRoot "Biology-Hard-Uninstall-Verify-$($ExpectedHead.Substring(0,8))-$signature.txt"
$verifyExit = $null
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
    if ($running.Count -gt 0) { throw 'Cyberpunk 2077 is running. Close the game completely before testing the uninstaller.' }
}

function Test-BiologyPreferenceSection([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $false }
    $text = Get-Content -Raw -LiteralPath $Path -ErrorAction Stop
    return $text -match '(?m)^\[CyberpunkRealism\.Settings\.CRRealpassSettings\]\s*$'
}

New-Item -ItemType Directory -Force -Path $GamesRoot | Out-Null
@(
    '=== BIOLOGY HARD-UNINSTALL ATTENDED VERIFICATION ===',
    ('Generated: ' + [DateTime]::Now.ToString('o')),
    ('Expected canonical head: ' + $ExpectedHead),
    ('Game path: ' + $GamePath),
    ('Disposable verification checkout: ' + $checkout),
    'Purpose: intentionally mutate the installed game only through the packaged player-facing Uninstall Biology.exe, then perform read-only residue verification.',
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

    Write-Host 'Creating exact disposable verifier checkout...' -ForegroundColor Cyan
    $clone = Invoke-NativeSafe -FilePath 'git' -Arguments @('clone','--no-checkout',$repoUrl,$checkout) -Echo
    if ($clone.ExitCode -ne 0) { throw "Repository clone failed with exit code $($clone.ExitCode)." }
    $checkoutResult = Invoke-NativeSafe -FilePath 'git' -Arguments @('-C',$checkout,'checkout','--detach',$ExpectedHead) -Echo
    if ($checkoutResult.ExitCode -ne 0) { throw "Exact checkout failed with exit code $($checkoutResult.ExitCode)." }
    $headResult = Invoke-NativeSafe -FilePath 'git' -Arguments @('-C',$checkout,'rev-parse','HEAD')
    if ($headResult.ExitCode -ne 0) { throw 'Could not read disposable checkout head.' }
    $fetchedHead = $headResult.StdOut.Trim().ToLowerInvariant()
    Add-Evidence ('Fetched head: ' + $fetchedHead)
    if ($fetchedHead -ne $ExpectedHead) { throw "Wrong checkout. Expected $ExpectedHead; found $fetchedHead." }

    $uninstaller = Join-Path $GamePath 'Uninstall Biology.exe'
    $manifest = Join-Path $GamePath 'biology\build-manifest.json'
    $biologyRedmod = Join-Path $GamePath 'mods\Biology'
    foreach ($required in @($uninstaller,$manifest,$biologyRedmod)) {
        if (-not (Test-Path -LiteralPath $required)) { throw "Installed Biology hard-uninstall precondition missing: $required" }
    }

    try {
        $manifestObject = Get-Content -Raw -LiteralPath $manifest | ConvertFrom-Json
        Add-Evidence ('Installed Biology buildId: ' + [string]$manifestObject.buildId)
        Add-Evidence ('Installed Biology version: ' + [string]$manifestObject.version)
        Add-Evidence ('Installed Biology sourceRevision: ' + [string]$manifestObject.sourceRevision)
    } catch {
        Add-Evidence ('Installed manifest metadata could not be summarized: ' + $_.Exception.Message)
    }

    $preferencesPath = Join-Path $GamePath 'red4ext\plugins\mod_settings\user.ini'
    $prePreference = Test-BiologyPreferenceSection $preferencesPath
    Add-Evidence ('Biology preference section present before uninstall: ' + $prePreference)

    Write-Host ''
    Write-Host 'Launching the packaged player-facing Uninstall Biology.exe.' -ForegroundColor Cyan
    Write-Host 'For this first acceptance test, leave "Also remove Biology preferences" UNCHECKED.' -ForegroundColor Yellow
    Write-Host 'Complete the uninstall, then TAKE A SCREENSHOT OF ITS FINAL REPORT before closing the window.' -ForegroundColor Yellow
    Start-Process -FilePath $uninstaller | Out-Null
    Read-Host 'After the uninstaller window is CLOSED, return here and press Enter to run read-only cleanup verification' | Out-Null

    Assert-GameStopped
    Add-Evidence ''
    Add-Evidence '=== POST-UNINSTALL READ-ONLY VERIFIER ==='
    $verifier = Join-Path $checkout 'tools\Verify-BiologyRemoval.ps1'
    $verify = Invoke-NativeSafe -FilePath 'pwsh' -Arguments @('-NoLogo','-NoProfile','-File',$verifier,'-GameRoot',$GamePath) -Echo
    $verifyExit = $verify.ExitCode
    if ($verifyExit -ne 0) { throw "Verify-BiologyRemoval.ps1 failed with exit code $verifyExit. Child diagnostics are preserved above." }

    $postPreference = Test-BiologyPreferenceSection $preferencesPath
    Add-Evidence ('Biology preference section present after uninstall: ' + $postPreference)
    if ($prePreference -and -not $postPreference) {
        throw 'The default hard-uninstall test unexpectedly removed the pre-existing Biology Mod Settings preference section.'
    }

    $modsJson = Join-Path $GamePath 'r6\cache\modded\mods.json'
    if (Test-Path -LiteralPath $modsJson -PathType Leaf) {
        $modsJsonText = Get-Content -Raw -LiteralPath $modsJson -ErrorAction Stop
        $biologyMention = $modsJsonText -match '(?i)\bBiology\b|mods[\\/]Biology'
        Add-Evidence ('Biology mentioned in r6/cache/modded/mods.json after uninstall: ' + $biologyMention)
        if ($biologyMention) { throw 'REDmod cache manifest still mentions Biology after the player uninstaller completed.' }
    } else {
        Add-Evidence 'r6/cache/modded/mods.json is absent after uninstall; no stale Biology entry can be present there.'
    }

    Add-Evidence ''
    Add-Evidence 'PASS: packaged hard uninstall completed and no Biology-specific package/runtime residue was found by the canonical read-only verifier.'
    Write-Host ''
    Write-Host 'PASS: Biology hard-uninstall residue verification passed.' -ForegroundColor Green
} catch {
    $failed = $true
    Add-Evidence ''
    Add-Evidence '=== HARD-UNINSTALL TEST FAILURE ==='
    Add-Evidence ('Time: ' + [DateTime]::Now.ToString('o'))
    Add-Evidence ('Exception type: ' + $_.Exception.GetType().FullName)
    Add-Evidence ('Error: ' + $_.Exception.Message)
    Add-Evidence ('Verifier exit code: ' + $verifyExit)
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
