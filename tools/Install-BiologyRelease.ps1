[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$GameRoot,
    [string]$PackageRoot = $PSScriptRoot,
    [switch]$WhatIf
)
$ErrorActionPreference = 'Stop'
# Developer/automation convenience entry point. Players double-click the EXE.
# Both routes execute the same native planner, transaction and receipt checks.
$binary = Join-Path ([IO.Path]::GetFullPath($PackageRoot)) 'Install Biology.exe'
if (-not (Test-Path -LiteralPath $binary -PathType Leaf)) { throw 'The release is missing Install Biology.exe. Build/extract the complete current package.' }
$game = [IO.Path]::GetFullPath($GameRoot).TrimEnd('\','/')
if ($game.Contains('"')) { throw 'Invalid game folder.' }
$start = [Diagnostics.ProcessStartInfo]::new()
$start.FileName = $binary
$start.Arguments = $(if ($WhatIf) { '--check' } else { '--install' }) + ' --game-root="' + $game + '"'
$start.UseShellExecute = $false
$start.CreateNoWindow = $true
$start.WindowStyle = [Diagnostics.ProcessWindowStyle]::Hidden
$start.RedirectStandardOutput = $true
$start.RedirectStandardError = $true
$process = [Diagnostics.Process]::Start($start)
$output = $process.StandardOutput.ReadToEndAsync()
$errors = $process.StandardError.ReadToEndAsync()
$process.WaitForExit()
$stdout = $output.GetAwaiter().GetResult()
$stderr = $errors.GetAwaiter().GetResult()
$exitCode = $process.ExitCode
$process.Dispose()
if ($stdout) { Write-Host $stdout.TrimEnd() }
if ($exitCode -ne 0) { throw "Biology installer refused/stopped (exit $exitCode): $stderr" }
