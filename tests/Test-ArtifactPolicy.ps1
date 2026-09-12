$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\tools\Common.ps1"
$project = Get-ProjectRoot
$scanner = Join-Path $project 'tools/Test-ArtifactPolicy.ps1'
$work = Join-Path $project ('staging/artifact-policy-tests-' + [guid]::NewGuid().ToString('N'))
$safe = Join-Path $work 'safe'
$bad = Join-Path $work 'bad'
$blocked = Join-Path $work 'blocked'
New-Item -ItemType Directory -Force -Path (Join-Path $safe 'r6/scripts/CyberpunkRealism') | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $bad 'vendor/red4ext') | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $blocked 'realpass/provenance') | Out-Null
[IO.File]::WriteAllText((Join-Path $safe 'r6/scripts/CyberpunkRealism/BodyModel.reds'),'safe runtime fixture')
[IO.File]::WriteAllText((Join-Path $bad 'vendor/red4ext/forbidden.dll'),'forbidden fixture')
[IO.File]::WriteAllText((Join-Path $blocked 'realpass/provenance/components.json'),'{"components":[{"id":"project-e3-hud"}]}')

# Direct PowerShell script invocation communicates failure by throwing under
# ErrorActionPreference=Stop; LASTEXITCODE is reserved for native processes and
# may be unset on a clean runner.
& $scanner -Root $safe

$rejectedForbidden = $false
try { & $scanner -Root $bad } catch { $rejectedForbidden = $_.Exception.Message -match 'forbidden-path' }
if (-not $rejectedForbidden) { throw 'Forbidden vendor content was not rejected.' }

$rejectedBlocked = $false
try { & $scanner -Root $blocked } catch { $rejectedBlocked = $_.Exception.Message -match 'blocked-component:project-e3-hud' }
if (-not $rejectedBlocked) { throw 'Blocked E3 component declaration was not rejected.' }

# Game/user data must fail even when nested in otherwise plausible runtime folders.
$game = Join-Path $work 'game'
New-Item -ItemType Directory -Force -Path (Join-Path $game 'bin/x64') | Out-Null
[IO.File]::WriteAllText((Join-Path $game 'bin/x64/Cyberpunk2077.exe'),'not a real executable')
$rejectedGame = $false
try { & $scanner -Root $game } catch { $rejectedGame = $_.Exception.Message -match 'Cyberpunk2077.exe' }
if (-not $rejectedGame) { throw 'Game executable fixture was not rejected.' }

Write-Host 'PASS: artifact policy accepts clean runtime content and fails closed on forbidden paths, blocked components, and game files.'
