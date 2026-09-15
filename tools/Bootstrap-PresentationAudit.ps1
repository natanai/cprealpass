[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$Branch,
    [Parameter(Mandatory=$true)][ValidatePattern('^[0-9a-fA-F]{40}$')][string]$ExpectedHead,
    [string]$GamesRoot = 'C:\Games',
    [string]$GamePath = 'C:\Games\Steam\steamapps\common\Cyberpunk 2077'
)

$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'Bootstrap-PresentationAudit.ps1 requires PowerShell 7 or newer.' }

$GamesRoot = [IO.Path]::GetFullPath($GamesRoot)
$GamePath = [IO.Path]::GetFullPath($GamePath)
$signature = [DateTime]::Now.ToString('yyyyMMdd-HHmmss') + '-' + [guid]::NewGuid().ToString('N').Substring(0,8)
$reportPath = Join-Path $GamesRoot ('Biology-Presentation-Audit-' + $signature + '.txt')
$repoUrl = 'https://github.com/natanai/cprealpass.git'
$repoPattern = '(?i)(?:github\.com[/:])natanai/cprealpass(?:\.git)?$'
$seedRepo = $null
$auditRoot = $null
$failed = $false

function Add-Evidence([string]$text) {
    Add-Content -LiteralPath $reportPath -Value $text -Encoding utf8
}

if (-not (Test-Path -LiteralPath $GamesRoot -PathType Container)) {
    throw "Games root does not exist: $GamesRoot"
}

@(
    'BIOLOGY PRESENTATION LOCAL AUDIT BOOTSTRAP',
    ('Started: ' + [DateTime]::Now.ToString('o')),
    ('Branch: ' + $Branch),
    ('Expected head: ' + $ExpectedHead),
    ('Game: ' + $GamePath),
    ''
) | Set-Content -LiteralPath $reportPath -Encoding utf8

try {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) { throw 'git is not available on PATH.' }
    if (-not (Get-Command pwsh -ErrorAction SilentlyContinue)) { throw 'PowerShell 7 (pwsh) is not available on PATH.' }
    if (-not (Test-Path -LiteralPath $GamePath -PathType Container)) { throw "Cyberpunk game directory does not exist: $GamePath" }

    foreach ($directory in @(Get-ChildItem -LiteralPath $GamesRoot -Directory -ErrorAction SilentlyContinue)) {
        if (-not (Test-Path -LiteralPath (Join-Path $directory.FullName '.git'))) { continue }
        $origin = (& git -C $directory.FullName remote get-url origin 2>$null)
        if ($LASTEXITCODE -ne 0) { continue }
        $normalized = ([string]$origin).Trim().TrimEnd('/')
        if ($normalized -match $repoPattern) {
            $seedRepo = $directory.FullName
            break
        }
    }

    if ([string]::IsNullOrWhiteSpace($seedRepo)) {
        $seedRepo = Join-Path $GamesRoot ('cprealpass-repo-' + $signature)
        Add-Evidence "No existing cprealpass checkout found. Cloning seed: $seedRepo"
        & git clone $repoUrl $seedRepo 2>&1 | Tee-Object -FilePath $reportPath -Append | Write-Host
        if ($LASTEXITCODE -ne 0) { throw "Could not clone natanai/cprealpass (git exit $LASTEXITCODE)." }
    } else {
        Add-Evidence "Existing cprealpass seed found: $seedRepo"
        Write-Host "Using existing cprealpass seed: $seedRepo"
    }

    Add-Evidence "Fetching branch: $Branch"
    & git -C $seedRepo fetch origin "+refs/heads/$($Branch):refs/remotes/origin/$($Branch)" 2>&1 | Tee-Object -FilePath $reportPath -Append | Write-Host
    if ($LASTEXITCODE -ne 0) { throw "Could not fetch $Branch (git exit $LASTEXITCODE)." }

    $fetchedHead = (& git -C $seedRepo rev-parse "refs/remotes/origin/$Branch").Trim()
    if ($LASTEXITCODE -ne 0) { throw 'Could not resolve fetched branch head.' }
    Add-Evidence "Fetched head: $fetchedHead"
    if ($fetchedHead -ne $ExpectedHead) {
        throw "Branch head moved. Expected $ExpectedHead but fetched $fetchedHead. Refusing to audit a different revision."
    }

    $auditRoot = Join-Path $GamesRoot ('cprealpass-presentation-audit-' + $signature)
    if (Test-Path -LiteralPath $auditRoot) { throw "Unique audit path unexpectedly exists: $auditRoot" }

    Add-Evidence "Creating disposable audit checkout: $auditRoot"
    & git -C $seedRepo worktree add --detach $auditRoot $ExpectedHead 2>&1 | Tee-Object -FilePath $reportPath -Append | Write-Host
    if ($LASTEXITCODE -ne 0) { throw "Could not create disposable audit checkout (git exit $LASTEXITCODE)." }

    Write-Host ''
    Write-Host "AUDIT CHECKOUT: $auditRoot" -ForegroundColor Cyan
    Write-Host "AUDIT HEAD:     $ExpectedHead" -ForegroundColor Cyan
    Write-Host ''

    & pwsh -NoLogo -NoProfile -File (Join-Path $auditRoot 'tools\Audit-PresentationContracts.ps1') -GamePath $GamePath -ReportPath $reportPath
    $auditExit = $LASTEXITCODE

    Add-Evidence ''
    Add-Evidence '=== LOCAL AUDIT BOOTSTRAP CONTEXT ==='
    Add-Evidence "Seed checkout: $seedRepo"
    Add-Evidence "Disposable audit checkout: $auditRoot"
    Add-Evidence "Requested branch: $Branch"
    Add-Evidence "Audited head: $ExpectedHead"
    Add-Evidence "Audit process exit code: $auditExit"
    Add-Evidence ('Completed: ' + [DateTime]::Now.ToString('o'))

    if ($auditExit -ne 0) { throw "Presentation audit returned exit code $auditExit." }
} catch {
    $failed = $true
    Add-Evidence ''
    Add-Evidence '=== LOCAL AUDIT BOOTSTRAP FAILURE ==='
    Add-Evidence ('Time: ' + [DateTime]::Now.ToString('o'))
    Add-Evidence ('Error: ' + $_.Exception.Message)
    Add-Evidence "Seed checkout: $seedRepo"
    Add-Evidence "Disposable audit checkout: $auditRoot"
    Add-Evidence "Expected head: $ExpectedHead"
    Write-Host ''
    Write-Host 'The audit encountered a failure. The text report contains the evidence.' -ForegroundColor Yellow
} finally {
    Write-Host ''
    Write-Host '============================================================' -ForegroundColor Cyan
    Write-Host 'ATTACH THIS FILE TO CHATGPT:' -ForegroundColor Cyan
    Write-Host $reportPath -ForegroundColor Yellow
    Write-Host '============================================================' -ForegroundColor Cyan
}

if ($failed) { exit 1 }
