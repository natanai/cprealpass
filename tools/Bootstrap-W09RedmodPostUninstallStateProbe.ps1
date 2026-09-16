[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$Branch,
    [Parameter(Mandatory=$true)]
    [ValidatePattern('^[A-Fa-f0-9]{40}$')]
    [string]$ExpectedHead,
    [string]$GameRoot = 'C:\Games\Steam\steamapps\common\Cyberpunk 2077',
    [string]$GamesRoot = 'C:\Games'
)

$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'Bootstrap-W09RedmodPostUninstallStateProbe.ps1 requires PowerShell 7 or newer.' }

$ExpectedHead = $ExpectedHead.ToLowerInvariant()
$GameRoot = [IO.Path]::GetFullPath($GameRoot)
$GamesRoot = [IO.Path]::GetFullPath($GamesRoot)
$signature = "$(Get-Date -Format 'yyyyMMdd-HHmmss')-$([guid]::NewGuid().ToString('N').Substring(0,8))"
$repoUrl = 'https://github.com/natanai/cprealpass.git'
$repoPattern = '(?i)(?:github\.com[/:])natanai/cprealpass(?:\.git)?$'
$checkout = Join-Path $GamesRoot "cprealpass-w09-redmod-state-$signature"
$reportPath = Join-Path $GamesRoot "Biology-W09-Redmod-Post-Uninstall-State-$signature.txt"
$seedRepo = $null
$failed = $false

New-Item -ItemType Directory -Force -Path $GamesRoot | Out-Null

function Add-Evidence([string]$Text = '') {
    Add-Content -LiteralPath $reportPath -Value $Text -Encoding utf8
}

function Invoke-NativeSafe(
    [string]$FilePath,
    [string[]]$Arguments,
    [string]$WorkingDirectory = '',
    [switch]$Echo
) {
    $psi = [Diagnostics.ProcessStartInfo]::new()
    $psi.FileName = $FilePath
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.CreateNoWindow = $true
    if (-not [string]::IsNullOrWhiteSpace($WorkingDirectory)) { $psi.WorkingDirectory = $WorkingDirectory }
    foreach ($argument in $Arguments) { [void]$psi.ArgumentList.Add($argument) }

    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $psi
    $stdout = ''
    $stderr = ''
    $exitCode = $null
    $exceptionText = ''
    try {
        if (-not $process.Start()) { throw "Unable to start child process: $FilePath" }
        $stdoutTask = $process.StandardOutput.ReadToEndAsync()
        $stderrTask = $process.StandardError.ReadToEndAsync()
        $process.WaitForExit()
        $stdout = $stdoutTask.GetAwaiter().GetResult()
        $stderr = $stderrTask.GetAwaiter().GetResult()
        $exitCode = $process.ExitCode
    } catch {
        $exceptionText = $_.Exception.ToString()
        if ($null -eq $exitCode) { $exitCode = -1 }
    } finally {
        $process.Dispose()
    }

    Add-Evidence ("CHILD: {0}" -f $FilePath)
    Add-Evidence ("ARGS: {0}" -f (($Arguments | ForEach-Object { "[$_]" }) -join ' '))
    Add-Evidence ("EXIT: {0}" -f $exitCode)
    Add-Evidence 'STDOUT:'
    Add-Evidence $stdout
    Add-Evidence 'STDERR:'
    Add-Evidence $stderr
    if (-not [string]::IsNullOrWhiteSpace($exceptionText)) {
        Add-Evidence 'CHILD EXCEPTION:'
        Add-Evidence $exceptionText
    }
    Add-Evidence ''

    if ($Echo) {
        if (-not [string]::IsNullOrWhiteSpace($stdout)) { Write-Host $stdout }
        if (-not [string]::IsNullOrWhiteSpace($stderr)) { Write-Host $stderr }
        if (-not [string]::IsNullOrWhiteSpace($exceptionText)) { Write-Host $exceptionText -ForegroundColor Yellow }
    }

    return [pscustomobject]@{
        ExitCode = $exitCode
        StdOut = $stdout
        StdErr = $stderr
        ExceptionText = $exceptionText
    }
}

function Get-CprealpassSeed {
    foreach ($directory in @(Get-ChildItem -LiteralPath $GamesRoot -Directory -ErrorAction SilentlyContinue)) {
        $configPath = Join-Path $directory.FullName '.git\config'
        if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) { continue }
        try {
            $config = Get-Content -Raw -LiteralPath $configPath -ErrorAction Stop
        } catch {
            Add-Evidence "Skipping unreadable Git config candidate: $($directory.FullName)"
            continue
        }
        $urls = [regex]::Matches($config,'(?im)^\s*url\s*=\s*(?<url>.+?)\s*$')
        $matchesRepo = $false
        foreach ($urlMatch in $urls) {
            $normalized = $urlMatch.Groups['url'].Value.Trim().TrimEnd('/')
            if ($normalized -match $repoPattern) { $matchesRepo = $true; break }
        }
        if (-not $matchesRepo) { continue }
        $check = Invoke-NativeSafe -FilePath 'git' -Arguments @('-C',$directory.FullName,'rev-parse','--show-toplevel')
        if ($check.ExitCode -eq 0) { return $directory.FullName }
        Add-Evidence "Skipping unusable cprealpass seed candidate: $($directory.FullName)"
    }
    return $null
}

function Assert-GameStopped {
    $running = @(Get-Process -Name 'Cyberpunk2077' -ErrorAction SilentlyContinue)
    if ($running.Count -gt 0) { throw 'Cyberpunk 2077 is running. Close the game completely so the failed-redeploy filesystem state remains stable while it is inspected.' }
}

@(
    '=== W09.1 REDMOD POST-UNINSTALL DEPLOY STATE PROBE ===',
    ('Generated: ' + [DateTime]::Now.ToString('o')),
    ('Requested branch: ' + $Branch),
    ('Expected head: ' + $ExpectedHead),
    ('Game root: ' + $GameRoot),
    ('Disposable checkout: ' + $checkout),
    'Policy: the installed Cyberpunk/REDmod tree is READ-ONLY for this probe. No deploy, install, uninstall, cache creation, cache deletion, or game launch is performed.',
    'Purpose: inspect the exact failed-redeploy filesystem state and bounded official-tool evidence before choosing any W09 repair.',
    ''
) | Set-Content -LiteralPath $reportPath -Encoding utf8

try {
    Assert-GameStopped
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) { throw 'git is not available on PATH.' }
    if (-not (Test-Path -LiteralPath $GameRoot -PathType Container)) { throw "Cyberpunk game directory does not exist: $GameRoot" }

    $seedRepo = Get-CprealpassSeed
    if ([string]::IsNullOrWhiteSpace($seedRepo)) {
        $seedRepo = Join-Path $GamesRoot "cprealpass-repo-$signature"
        Add-Evidence "No usable cprealpass seed checkout found. Cloning seed: $seedRepo"
        $clone = Invoke-NativeSafe -FilePath 'git' -Arguments @('clone',$repoUrl,$seedRepo) -Echo
        if ($clone.ExitCode -ne 0) { throw "Could not clone natanai/cprealpass (git exit $($clone.ExitCode))." }
    } else {
        Add-Evidence "Existing cprealpass seed found: $seedRepo"
    }

    $fetch = Invoke-NativeSafe -FilePath 'git' -Arguments @('-C',$seedRepo,'fetch','origin',("+refs/heads/{0}:refs/remotes/origin/{0}" -f $Branch)) -Echo
    if ($fetch.ExitCode -ne 0) { throw "Could not fetch $Branch (git exit $($fetch.ExitCode))." }

    $resolve = Invoke-NativeSafe -FilePath 'git' -Arguments @('-C',$seedRepo,'rev-parse',("refs/remotes/origin/{0}" -f $Branch))
    if ($resolve.ExitCode -ne 0) { throw 'Could not resolve fetched branch head.' }
    $fetchedHead = $resolve.StdOut.Trim().ToLowerInvariant()
    Add-Evidence "Fetched head: $fetchedHead"
    if ($fetchedHead -ne $ExpectedHead) {
        throw "Branch head moved. Expected $ExpectedHead but fetched $fetchedHead. Refusing to inspect under a different revision identity."
    }

    $worktree = Invoke-NativeSafe -FilePath 'git' -Arguments @('-C',$seedRepo,'worktree','add','--detach',$checkout,$ExpectedHead) -Echo
    if ($worktree.ExitCode -ne 0) { throw "Could not create disposable probe checkout (git exit $($worktree.ExitCode))." }
    Add-Evidence "Disposable checkout created: $checkout"
    Add-Evidence "Probed head: $ExpectedHead"
    Add-Evidence ''

    $gameExe = Join-Path $GameRoot 'bin\x64\Cyberpunk2077.exe'
    $redmodExe = Join-Path $GameRoot 'tools\redmod\bin\redMod.exe'
    foreach ($required in @($gameExe,$redmodExe)) {
        if (-not (Test-Path -LiteralPath $required -PathType Leaf)) { throw "Required supported-install file missing: $required" }
    }

    Add-Evidence '=== EXACT SUPPORTED-INSTALL FINGERPRINTS ==='
    $gameVersion = (Get-Item -LiteralPath $gameExe).VersionInfo
    $redmodVersion = (Get-Item -LiteralPath $redmodExe).VersionInfo
    Add-Evidence ('Cyberpunk file version: ' + $gameVersion.FileVersion)
    Add-Evidence ('Cyberpunk product version: ' + $gameVersion.ProductVersion)
    Add-Evidence ('Cyberpunk executable SHA-256: ' + (Get-FileHash -LiteralPath $gameExe -Algorithm SHA256).Hash.ToUpperInvariant())
    Add-Evidence ('REDmod file version: ' + $redmodVersion.FileVersion)
    Add-Evidence ('REDmod product version: ' + $redmodVersion.ProductVersion)
    Add-Evidence ('REDmod executable SHA-256: ' + (Get-FileHash -LiteralPath $redmodExe -Algorithm SHA256).Hash.ToUpperInvariant())
    if ($redmodVersion.ProductVersion -ne '2.31') { throw "W09 probe is pinned to REDmod 2.31; installed product version is '$($redmodVersion.ProductVersion)'." }
    Add-Evidence ''

    $prelauncher = Join-Path $GameRoot 'REDprelauncher.exe'
    Add-Evidence '=== OFFICIAL LAUNCHER PRESENCE/FINGERPRINT ==='
    Add-Evidence ('REDprelauncher.exe present at game root: ' + (Test-Path -LiteralPath $prelauncher -PathType Leaf))
    if (Test-Path -LiteralPath $prelauncher -PathType Leaf) {
        $prelauncherVersion = (Get-Item -LiteralPath $prelauncher).VersionInfo
        Add-Evidence ('REDprelauncher file version: ' + $prelauncherVersion.FileVersion)
        Add-Evidence ('REDprelauncher product version: ' + $prelauncherVersion.ProductVersion)
        Add-Evidence ('REDprelauncher SHA-256: ' + (Get-FileHash -LiteralPath $prelauncher -Algorithm SHA256).Hash.ToUpperInvariant())
    }
    Add-Evidence ''

    $cacheParent = Join-Path $GameRoot 'r6\cache'
    $moddedRoot = Join-Path $cacheParent 'modded'
    $tweakDbEp1 = Join-Path $moddedRoot 'tweakdb_ep1.bin'
    $modsJson = Join-Path $moddedRoot 'mods.json'

    Add-Evidence '=== EXACT FAILED-REDEPLOY FILESYSTEM STATE ==='
    Add-Evidence ('r6/cache exists as directory: ' + (Test-Path -LiteralPath $cacheParent -PathType Container))
    Add-Evidence ('r6/cache/modded exists as directory: ' + (Test-Path -LiteralPath $moddedRoot -PathType Container))
    Add-Evidence ('r6/cache/modded exists as file: ' + (Test-Path -LiteralPath $moddedRoot -PathType Leaf))
    Add-Evidence ('r6/cache/modded/tweakdb_ep1.bin exists as file: ' + (Test-Path -LiteralPath $tweakDbEp1 -PathType Leaf))
    Add-Evidence ('r6/cache/modded/mods.json exists as file: ' + (Test-Path -LiteralPath $modsJson -PathType Leaf))

    if (Test-Path -LiteralPath $moddedRoot -PathType Container) {
        $children = @(Get-ChildItem -LiteralPath $moddedRoot -Force -ErrorAction Stop | Sort-Object Name)
        Add-Evidence ('Immediate child count: ' + $children.Count)
        if ($children.Count -eq 0) {
            Add-Evidence 'Immediate children: <none>'
        } else {
            Add-Evidence 'Immediate children (non-recursive):'
            foreach ($child in $children) {
                $kind = if ($child.PSIsContainer) { 'DIRECTORY' } else { 'FILE' }
                Add-Evidence ("  [{0}] {1}" -f $kind,$child.Name)
            }
        }
    } else {
        Add-Evidence 'Immediate children: <not enumerated because r6/cache/modded is not a directory>'
    }
    Add-Evidence ''

    Add-Evidence '=== BOUNDED OFFICIAL REDMOD TOOL EVIDENCE ==='
    Add-Evidence 'The following child call is read-only capability/help output from the exact installed redMod.exe. It is not a deploy.'
    $help = Invoke-NativeSafe -FilePath $redmodExe -Arguments @('--help') -WorkingDirectory $GameRoot
    if ($help.ExitCode -ne 0) { throw "Official redMod.exe --help returned exit code $($help.ExitCode)." }

    Add-Evidence '=== PROOF BOUNDARY ==='
    Add-Evidence 'Filesystem statements above are direct read-only observations of the installed game in the current failed-redeploy state.'
    Add-Evidence 'Executable hashes/versions and --help output are direct official-tool evidence, but they do NOT prove historical causation or an internal launcher/REDmod directory-creation code path.'
    Add-Evidence 'This probe does NOT run REDmod deploy, does NOT invoke REDlauncher, does NOT test write/delete permissions, and does NOT constitute official deployment/runtime acceptance.'
    Add-Evidence 'Whether the preceding no-mod refresh caused any observed directory absence must be inferred only together with the separately recorded attended sequence and the uninstaller source, which itself does not recursively delete r6/cache/modded.'
    Add-Evidence ''
    Add-Evidence 'PASS: W09.1 read-only post-uninstall REDmod filesystem/tool evidence captured.'
} catch {
    $failed = $true
    Add-Evidence ''
    Add-Evidence '=== W09.1 PROBE FAILURE ==='
    Add-Evidence ('Time: ' + [DateTime]::Now.ToString('o'))
    Add-Evidence ('Exception type: ' + $_.Exception.GetType().FullName)
    Add-Evidence ('Error: ' + $_.Exception.Message)
    if ($_.InvocationInfo) {
        Add-Evidence ('Script line: ' + $_.InvocationInfo.ScriptLineNumber)
        Add-Evidence ('Position: ' + $_.InvocationInfo.PositionMessage)
    }
    Add-Evidence ('Requested branch: ' + $Branch)
    Add-Evidence ('Expected head: ' + $ExpectedHead)
    Add-Evidence ('Seed checkout: ' + $seedRepo)
    Add-Evidence ('Disposable checkout: ' + $checkout)
    Add-Evidence 'FAIL: W09.1 probe did not complete; useful child stdout/stderr/exit/exception evidence above remains authoritative for diagnosis.'
} finally {
    Write-Host ''
    Write-Host '============================================================' -ForegroundColor Cyan
    Write-Host 'ATTACH THIS FILE TO CHATGPT:' -ForegroundColor Cyan
    Write-Host $reportPath -ForegroundColor Yellow
    Write-Host '============================================================' -ForegroundColor Cyan
}

if ($failed) { exit 1 }
