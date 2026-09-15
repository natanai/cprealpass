[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$OutputPath,
    [string]$TestOutputPath
)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\Common.ps1"
$project = Get-ProjectRoot

$core = Join-Path $project 'src\uninstaller\BiologyUninstallCore.cs'
$program = Join-Path $project 'src\uninstaller\BiologyUninstallerProgram.cs'
$tests = Join-Path $project 'tests\BiologyUninstallCoreTests.cs'
foreach ($required in @($core,$program)) {
    if (-not (Test-Path -LiteralPath $required -PathType Leaf)) { throw "Missing Biology uninstaller source: $required" }
}

$compilerCandidates = @(
    (Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'),
    (Join-Path $env:WINDIR 'Microsoft.NET\Framework\v4.0.30319\csc.exe')
)
$compiler = @($compilerCandidates | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1)
if ($compiler.Count -ne 1) {
    throw 'Windows .NET Framework C# compiler was not found. Biology player packaging requires the built-in .NET Framework 4.x compiler to produce the single-binary uninstaller.'
}
$compiler = $compiler[0]

function Invoke-CSharpCompiler([string]$Target,[string]$TargetType,[string[]]$Sources,[string[]]$References) {
    $fullTarget = [IO.Path]::GetFullPath($Target)
    $parent = Split-Path -Parent $fullTarget
    if (-not [string]::IsNullOrWhiteSpace($parent)) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
    if (Test-Path -LiteralPath $fullTarget) { Remove-Item -LiteralPath $fullTarget -Force }

    $arguments = [Collections.Generic.List[string]]::new()
    $arguments.Add('/nologo')
    $arguments.Add('/optimize+')
    $arguments.Add('/checked+')
    $arguments.Add('/warn:4')
    $arguments.Add('/langversion:5')
    $arguments.Add('/target:' + $TargetType)
    $arguments.Add('/platform:anycpu')
    $arguments.Add('/out:' + $fullTarget)
    foreach ($reference in $References) { $arguments.Add('/reference:' + $reference) }
    foreach ($source in $Sources) { $arguments.Add([IO.Path]::GetFullPath($source)) }

    & $compiler @($arguments.ToArray())
    if ($LASTEXITCODE -ne 0) { throw "C# compiler failed for $fullTarget with exit code $LASTEXITCODE." }
    if (-not (Test-Path -LiteralPath $fullTarget -PathType Leaf) -or (Get-Item -LiteralPath $fullTarget).Length -le 0) {
        throw "C# compiler reported success but did not create: $fullTarget"
    }
    return $fullTarget
}

$binary = Invoke-CSharpCompiler -Target $OutputPath -TargetType 'winexe' -Sources @($core,$program) -References @(
    'System.dll',
    'System.Core.dll',
    'System.Web.Extensions.dll',
    'System.Windows.Forms.dll',
    'System.Drawing.dll'
)

if (-not [string]::IsNullOrWhiteSpace($TestOutputPath)) {
    if (-not (Test-Path -LiteralPath $tests -PathType Leaf)) { throw "Missing Biology uninstaller test source: $tests" }
    [void](Invoke-CSharpCompiler -Target $TestOutputPath -TargetType 'exe' -Sources @($core,$tests) -References @(
        'System.dll',
        'System.Core.dll',
        'System.Web.Extensions.dll'
    ))
}

Write-Host "PASS: Biology single-binary player uninstaller compiled: $binary"
return $binary
