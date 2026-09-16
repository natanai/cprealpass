$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\tools\Common.ps1"
$project = Get-ProjectRoot
$scanner = Join-Path $project 'tools/Test-ArtifactPolicy.ps1'
$work = Join-Path $project ('staging/artifact-policy-tests-' + [guid]::NewGuid().ToString('N'))
$safe = Join-Path $work 'safe'
$runtime = Join-Path $work 'runtime-components'
$bad = Join-Path $work 'bad'
$blocked = Join-Path $work 'blocked'
$unneeded = Join-Path $work 'unneeded'
New-Item -ItemType Directory -Force -Path (Join-Path $safe 'r6/scripts/CyberpunkRealism') | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $runtime 'biology/provenance') | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $bad 'vendor/red4ext') | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $blocked 'biology/provenance') | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $unneeded 'biology/provenance') | Out-Null
[IO.File]::WriteAllText((Join-Path $safe 'r6/scripts/CyberpunkRealism/BodyModel.reds'),'safe runtime fixture')
[IO.File]::WriteAllText((Join-Path $runtime 'biology/provenance/components.json'),'{"components":[{"id":"biology-project-original"},{"id":"redscript"},{"id":"cybercmd"}]}')
[IO.File]::WriteAllText((Join-Path $bad 'vendor/red4ext/forbidden.dll'),'forbidden fixture')
[IO.File]::WriteAllText((Join-Path $blocked 'biology/provenance/components.json'),'{"components":[{"id":"project-e3-hud"}]}')
[IO.File]::WriteAllText((Join-Path $unneeded 'biology/provenance/components.json'),'{"components":[{"id":"codeware"}]}')

& $scanner -Root $safe
& $scanner -Root $runtime

$rejectedForbidden = $false
try { & $scanner -Root $bad } catch { $rejectedForbidden = $_.Exception.Message -match 'forbidden-path' }
if (-not $rejectedForbidden) { throw 'Forbidden vendor content was not rejected.' }

$rejectedBlocked = $false
try { & $scanner -Root $blocked } catch { $rejectedBlocked = $_.Exception.Message -match 'disallowed-component:project-e3-hud' }
if (-not $rejectedBlocked) { throw 'Blocked source-mod component declaration was not rejected.' }

$rejectedUnneeded = $false
try { & $scanner -Root $unneeded } catch { $rejectedUnneeded = $_.Exception.Message -match 'disallowed-component:codeware' }
if (-not $rejectedUnneeded) { throw 'Not-required framework declaration was not rejected.' }

$game = Join-Path $work 'game'
New-Item -ItemType Directory -Force -Path (Join-Path $game 'bin/x64') | Out-Null
[IO.File]::WriteAllText((Join-Path $game 'bin/x64/Cyberpunk2077.exe'),'not a real executable')
$rejectedGame = $false
try { & $scanner -Root $game } catch { $rejectedGame = $_.Exception.Message -match 'Cyberpunk2077.exe' }
if (-not $rejectedGame) { throw 'Game executable fixture was not rejected.' }

Write-Host 'PASS: artifact policy accepts clean Biology plus active redscript/cybercmd component declarations, and fails closed on forbidden paths, blocked components, unneeded frameworks, and game files.'
