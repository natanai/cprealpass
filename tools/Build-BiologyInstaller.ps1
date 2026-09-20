[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$OutputPath,[string]$TestOutputPath)
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\Common.ps1"
$project = Get-ProjectRoot
$compiler = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
if (-not (Test-Path -LiteralPath $compiler)) { $compiler = Join-Path $env:WINDIR 'Microsoft.NET\Framework\v4.0.30319\csc.exe' }
if (-not (Test-Path -LiteralPath $compiler)) { throw 'Windows .NET Framework C# compiler is required to build the installer.' }
$core = Join-Path $project 'src\installer\BiologyInstallCore.cs'
$ownership = Join-Path $project 'src\uninstaller\BiologyUninstallCore.cs'
$program = Join-Path $project 'src\installer\BiologyInstallerProgram.cs'
$OutputPath = [IO.Path]::GetFullPath($OutputPath)
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $OutputPath) | Out-Null
& $compiler /nologo /optimize+ /checked+ /warn:4 /langversion:5 /target:winexe "/out:$OutputPath" /reference:System.dll /reference:System.Core.dll /reference:System.Web.Extensions.dll /reference:System.Windows.Forms.dll /reference:System.Drawing.dll $core $ownership $program
if ($LASTEXITCODE -ne 0) { throw 'Biology installer compilation failed.' }
if ($TestOutputPath) {
    $TestOutputPath = [IO.Path]::GetFullPath($TestOutputPath)
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $TestOutputPath) | Out-Null
    & $compiler /nologo /optimize+ /checked+ /warn:4 /langversion:5 /target:exe "/out:$TestOutputPath" /reference:System.dll /reference:System.Core.dll /reference:System.Web.Extensions.dll $core $ownership (Join-Path $project 'tests\BiologyInstallCoreTests.cs')
    if ($LASTEXITCODE -ne 0) { throw 'Biology installer test compilation failed.' }
}
Write-Host "PASS: Biology player installer compiled: $OutputPath"
return $OutputPath
