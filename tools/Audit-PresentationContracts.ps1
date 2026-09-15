[CmdletBinding()]
param(
    [string]$GamePath = 'C:\Games\Steam\steamapps\common\Cyberpunk 2077',
    [string]$ReportPath
)

$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'Audit-PresentationContracts.ps1 requires PowerShell 7 or newer.' }

$repoRoot = Split-Path -Parent $PSScriptRoot
$reportRoot = Join-Path $repoRoot 'reports'
New-Item -ItemType Directory -Force -Path $reportRoot | Out-Null
if ([string]::IsNullOrWhiteSpace($ReportPath)) {
    $name = 'presentation-local-audit-' + [DateTime]::Now.ToString('yyyyMMdd-HHmmss') + '-' + [guid]::NewGuid().ToString('N').Substring(0,8) + '.txt'
    $ReportPath = Join-Path $reportRoot $name
} elseif (-not [IO.Path]::IsPathRooted($ReportPath)) {
    $ReportPath = Join-Path $repoRoot $ReportPath
}
$ReportPath = [IO.Path]::GetFullPath($ReportPath)

$failed = $false
try {
    & (Join-Path $PSScriptRoot 'Audit-GameContracts.ps1') -RepoRoot $repoRoot -GamePath $GamePath -ReportPath $ReportPath
} catch {
    $failed = $true
    Add-Content -LiteralPath $ReportPath -Value "`r`nPRESENTATION AUDIT WRAPPER: exact compile/native audit failed: $($_.Exception.Message)"
}

if (-not $failed) {
    try {
        $probeOutput = @(& (Join-Path $PSScriptRoot 'Probe-PresentationNativeContracts.ps1') -GamePath $GamePath *>&1)
        Add-Content -LiteralPath $ReportPath -Value "`r`n=== PRESENTATION NATIVE SYMBOL PROBE ==="
        foreach ($entry in $probeOutput) {
            $text = [string]$entry
            Add-Content -LiteralPath $ReportPath -Value $text
            Write-Host $text
        }
    } catch {
        $failed = $true
        $message = "Presentation native symbol probe failed: $($_.Exception.Message)"
        Add-Content -LiteralPath $ReportPath -Value "`r`n$message"
        Write-Host $message -ForegroundColor Red
    }
}

Add-Content -LiteralPath $ReportPath -Value "`r`nPRESENTATION LOCAL AUDIT RESULT: $(if ($failed) { 'FAIL' } else { 'PASS' })"
Write-Host ''
Write-Host "LOCAL EVIDENCE REPORT: $ReportPath" -ForegroundColor Cyan
Write-Host 'Attach that .txt file to the owning ChatGPT thread; do not paste the console transcript.' -ForegroundColor DarkGray

if ($failed) { throw "Presentation local audit failed. Evidence report: $ReportPath" }
