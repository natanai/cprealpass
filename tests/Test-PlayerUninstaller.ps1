$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'Test-PlayerUninstaller.ps1 requires PowerShell 7 or newer.' }
. "$PSScriptRoot\..\tools\Common.ps1"
$project = Get-ProjectRoot

$work = Join-Path ([IO.Path]::GetTempPath()) ('biology-uninstaller-ci-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $work | Out-Null
try {
    $player = Join-Path $work 'Uninstall Biology.exe'
    $tests = Join-Path $work 'BiologyUninstallCoreTests.exe'
    & (Join-Path $project 'tools\Build-BiologyUninstaller.ps1') -OutputPath $player -TestOutputPath $tests | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'Biology uninstaller build helper failed.' }
    if (-not (Test-Path -LiteralPath $player -PathType Leaf) -or (Get-Item -LiteralPath $player).Length -le 0) {
        throw 'Player-facing Uninstall Biology.exe was not produced.'
    }
    if (-not (Test-Path -LiteralPath $tests -PathType Leaf)) { throw 'Biology uninstaller safety test executable was not produced.' }

    & $tests
    if ($LASTEXITCODE -ne 0) { throw "Biology uninstaller core tests failed with exit code $LASTEXITCODE." }

    $core = Get-Content -Raw -LiteralPath (Join-Path $project 'src\uninstaller\BiologyUninstallCore.cs')
    $program = Get-Content -Raw -LiteralPath (Join-Path $project 'src\uninstaller\BiologyUninstallerProgram.cs')
    foreach ($needle in @(
        'generic-dependency-shared',
        'PreserveChangedBiologyOwned',
        'mods\Biology\',
        'r6\scripts\CyberpunkRealism\',
        'red4ext/plugins/mod_settings/user.ini',
        'official-redmod-deploy-explicit-root',
        'No mods found, no deployment is needed'
    )) {
        if (-not ($core.Contains($needle))) { throw "Uninstaller core lost required safety contract: $needle" }
    }
    if ($core -match '(?i)Directory\.Delete\([^\)]*,\s*true\s*\)' -or $core -match '(?i)DeleteDirectory\w*Recursive') {
        throw 'Player uninstaller contains recursive directory deletion.'
    }
    if ($program -match '(?i)powershell|pwsh|vortex') { throw 'Player uninstaller unexpectedly invokes a developer/mod-manager tool.' }

    Write-Host 'PASS: player-facing Biology uninstaller compiles as one EXE and its deterministic safety suite passes.'
}
finally {
    if (Test-Path -LiteralPath $work) { Remove-Item -LiteralPath $work -Recurse -Force }
}
