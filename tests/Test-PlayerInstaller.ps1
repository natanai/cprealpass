$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\tools\Common.ps1"
$project = Get-ProjectRoot
$work = Join-Path $project ('staging\installer-tests-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $work | Out-Null
$binary = Join-Path $work 'Install Biology.exe'
$tests = Join-Path $work 'InstallTests.exe'
& "$project\tools\Build-BiologyInstaller.ps1" -OutputPath $binary -TestOutputPath $tests | Out-Null
& $tests
if ($LASTEXITCODE -ne 0) { throw 'Native installer safety tests failed.' }
# A real Windows junction must be refused before any target is followed.
$outside = Join-Path $work 'outside'
$probe = Join-Path $work 'probe'
New-Item -ItemType Directory -Path $outside,$probe | Out-Null
[IO.File]::WriteAllText((Join-Path $outside 'file.txt'),'preserve')
$junction = Join-Path $probe 'redirect'
New-Item -ItemType Junction -Path $junction -Target $outside | Out-Null
try {
    & $tests $probe
    if ($LASTEXITCODE -ne 0) { throw 'Native ownership resolver followed a junction.' }
    if ((Get-Content -Raw -LiteralPath (Join-Path $outside 'file.txt')) -ne 'preserve') { throw 'Junction target changed.' }
} finally { [IO.Directory]::Delete($junction,$false) }
Write-Host 'PASS: installer and uninstaller shared resolver refuses a real Windows junction.'
