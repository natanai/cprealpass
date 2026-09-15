[CmdletBinding()]
param(
    [string]$GameRoot = 'C:\Games\Steam\steamapps\common\Cyberpunk 2077'
)

$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'Probe-OfficialRedmod.ps1 requires PowerShell 7 or newer.' }
. "$PSScriptRoot\Common.ps1"

$project = Get-ProjectRoot
$game = Assert-GameRoot $GameRoot
$redmodRoot = Join-Path $game 'tools\redmod'
$redmod = Join-Path $redmodRoot 'bin\redMod.exe'
if (-not (Test-Path -LiteralPath $redmod -PathType Leaf)) {
    throw "Official REDmod executable not found: $redmod"
}

function Invoke-ReadOnlyTool([string]$FilePath,[string[]]$Arguments,[string]$WorkingDirectory) {
    $psi = [Diagnostics.ProcessStartInfo]::new()
    $psi.FileName = $FilePath
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.CreateNoWindow = $true
    $psi.WorkingDirectory = $WorkingDirectory
    foreach ($arg in $Arguments) { [void]$psi.ArgumentList.Add($arg) }

    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $psi
    if (-not $process.Start()) { throw "Could not start official tool: $FilePath" }
    $stdout = $process.StandardOutput.ReadToEnd()
    $stderr = $process.StandardError.ReadToEnd()
    $process.WaitForExit()
    [pscustomobject]@{
        ExitCode = $process.ExitCode
        StdOut = $stdout.TrimEnd()
        StdErr = $stderr.TrimEnd()
    }
}

$version = (Get-Item -LiteralPath $redmod).VersionInfo
$help = Invoke-ReadOnlyTool -FilePath $redmod -Arguments @('--help') -WorkingDirectory $game

$metadata = Join-Path $redmodRoot 'metadata.json'
$scc = @(Get-ChildItem -LiteralPath $redmodRoot -Recurse -File -Filter 'scc.exe' -ErrorAction SilentlyContinue | Select-Object -First 1)
$scripts = Join-Path $redmodRoot 'scripts'
$tweaks = Join-Path $redmodRoot 'tweaks'

$reportRoot = Join-Path $project 'reports'
New-Item -ItemType Directory -Force -Path $reportRoot | Out-Null
$stamp = [DateTime]::UtcNow.ToString('yyyyMMdd-HHmmss')
$reportPath = Join-Path $reportRoot "official-redmod-probe-$stamp.txt"

$lines = [Collections.Generic.List[string]]::new()
$lines.Add('Biology official REDmod direct capability probe')
$lines.Add('Generated UTC: ' + [DateTime]::UtcNow.ToString('o'))
$lines.Add('Game root: ' + $game)
$lines.Add('REDmod root: ' + $redmodRoot)
$lines.Add('REDmod executable: ' + $redmod)
$lines.Add('REDmod SHA-256: ' + (Get-Sha256 $redmod))
$lines.Add('File version: ' + $version.FileVersion)
$lines.Add('Product version: ' + $version.ProductVersion)
$lines.Add('Company: ' + $version.CompanyName)
$lines.Add('Metadata present: ' + (Test-Path -LiteralPath $metadata -PathType Leaf))
$lines.Add('SCC present: ' + ($scc.Count -gt 0))
if ($scc.Count -gt 0) { $lines.Add('SCC path: ' + $scc[0].FullName) }
$lines.Add('REDmod scripts directory present: ' + (Test-Path -LiteralPath $scripts -PathType Container))
$lines.Add('REDmod tweaks directory present: ' + (Test-Path -LiteralPath $tweaks -PathType Container))
$lines.Add('')
$lines.Add('redMod.exe --help exit code: ' + $help.ExitCode)
$lines.Add('--- stdout ---')
$lines.Add($help.StdOut)
$lines.Add('--- stderr ---')
$lines.Add($help.StdErr)
$lines.Add('')
$lines.Add('Probe policy: read-only. No game/package/deploy files were modified by this script.')

[IO.File]::WriteAllLines($reportPath,$lines,[Text.UTF8Encoding]::new($false))

Write-Host 'PASS: queried the installed CDPR REDmod tool directly without modifying the game.' -ForegroundColor Green
Write-Host "REDmod: $($version.FileVersion) / product $($version.ProductVersion)"
Write-Host "Report: $reportPath"
Write-Host 'Return the report file to the requesting agent when the exact official capability surface matters.' -ForegroundColor DarkGray
return $reportPath
