$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$project = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$corePath = Join-Path $project 'tools\BiologyAttendedSession.Core.ps1'
$sessionPath = Join-Path $project 'tools\Start-BiologyAttendedSession.ps1'
$cmdPath = Join-Path $project 'tools\Start-BiologyAttendedSession.cmd'
$catalogPath = Join-Path $project 'docs\LOCAL-OPERATOR-COMMANDS.md'
$cleanRoomPath = Join-Path $project 'docs\CLEAN-ROOM-TESTING.md'
$contractPath = Join-Path $project 'docs\ATTENDED-TEST-SESSION.md'
foreach ($path in @($corePath,$sessionPath,$cmdPath,$catalogPath,$cleanRoomPath,$contractPath)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Missing W15.3 contract file: $path" }
}

function Assert-True([bool]$Value,[string]$Message) { if (-not $Value) { throw $Message } }
function Require([string]$Text,[string]$Pattern,[string]$Message) { if ($Text -notmatch $Pattern) { throw $Message } }
function Reject([string]$Text,[string]$Pattern,[string]$Message) { if ($Text -match $Pattern) { throw $Message } }
function Write-FixtureFile([string]$Root,[string]$Relative,[string]$Text) {
    $path = Join-Path $Root $Relative
    $parent = Split-Path -Parent $path
    New-Item -ItemType Directory -Force -Path $parent | Out-Null
    [IO.File]::WriteAllText($path,$Text,[Text.UTF8Encoding]::new($false))
    return $path
}

$session = Get-Content -Raw -LiteralPath $sessionPath
$core = Get-Content -Raw -LiteralPath $corePath
$cmd = Get-Content -Raw -LiteralPath $cmdPath
$catalog = Get-Content -Raw -LiteralPath $catalogPath
$cleanRoom = Get-Content -Raw -LiteralPath $cleanRoomPath
$contract = Get-Content -Raw -LiteralPath $contractPath

Require $core 'READY TO LAUNCH CYBERPUNK' 'Session listener must expose the canonical READY state.'
Require $core 'ReadLineAsync' 'Quiet listener must watch process state while the same console waits for END.'
Require $core "Equals\('END'" 'Quiet listener must use END as the finalization command.'
Require $session "Equals\('SENT'" 'Cleanup must be gated on explicit SENT confirmation.'
Require $session 'SESSION ENDED CLEANLY' 'Successful confirmed cleanup must expose the canonical clean-ended state.'
Require $session 'Bootstrap-BiologyManagedPostTransitionCandidate\.ps1' 'Session engine must reuse the W15.2 managed candidate preparation path when that plan is selected.'
Require $session 'Remove-BiologyManagedArtifactRoot' 'Session cleanup must reuse the W15.2 hash/inventory-bounded candidate artifact cleanup primitive.'
Require $session 'installedCandidatePreserved=\$true' 'Session evidence must explicitly preserve the installed Biology candidate.'
Require $session "'cat-file','-e'" 'Session exact-source acquisition must preserve cached-origin exact-head fail-closed fallback.'
Require $session "'remote','get-url','origin'" 'Session exact-source acquisition must validate repository identity by Git origin.'
Require $session 'PREPARATION-FAILED-BEFORE-READY' 'Pre-launch preparation failure must finalize through the same managed evidence path.'
Require $session 'BOOTSTRAP/SOURCE ACQUISITION FAILED BEFORE READY' 'Bootstrap/source failure must still emit one fail-closed evidence bundle.'
Require $session '-not \$cleanupAllowed -or -not \$finalized' 'Cleanup must be impossible before evidence finalization and owner confirmation.'
Require $session 'session-owner\.json' 'Cleanup must bind the staging root to an exact session ownership marker.'
Require $session 'ReparsePoint' 'Session-owned cleanup must fail closed on reparse-point roots.'
Require $session 'Managed preparation handoff unexpectedly remained' 'Final cleanup must not silently carry a second intermediate handoff bundle.'
Reject $session '(?i)Start-Process[^\r\n]*Cyberpunk|&\s*[^\r\n]*Cyberpunk2077\.exe' 'Session engine must never launch Cyberpunk for the owner.'
Require $core 'redscript_rCURRENT\.log' 'Session evidence must capture current REDscript log state.'
Require $core 'scriptsBlobPath' 'Session evidence must capture the configured REDscript output path.'
Require $core 'r6\\cache\\modded\\mods\.json' 'Session evidence must capture official REDmod generated state.'
Require $core 'cybercmd\.asi' 'Session evidence must capture cybercmd task-runner state.'
Require $core 'red4ext\\logs' 'Startup failure evidence must include bounded framework logs when present.'
Require $core 'REDEngine\\ReportQueue' 'Startup failure evidence must inspect current REDEngine crash artifacts when present.'
Require $core 'Get-WinEvent' 'Startup failure evidence must make the bounded Windows crash/hang event query when available.'

$cmdLines = @($cmd -split '\r?\n' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
Assert-True ($cmdLines.Count -le 4) 'Thin CMD launcher grew beyond a launcher-only boundary.'
Require $cmd 'Start-BiologyAttendedSession\.ps1' 'CMD launcher must delegate to the canonical PowerShell session engine.'
Require $cmd '%\*' 'CMD launcher must forward owner-supplied arguments to the PowerShell session engine.'
foreach ($forbidden in @('READY TO LAUNCH','ReadLineAsync','Get-Process','Compress-Archive','Remove-Item','git clone','git fetch','SENT','session-owner')) {
    Reject $cmd ([regex]::Escape($forbidden)) "CMD launcher duplicated session logic: $forbidden"
}

Require $catalog 'Command 17 — one-command attended test session' 'Local operator catalog must expose the W15.3 one-command attended session as the normal ready-for-test path.'
Require $catalog 'READY TO LAUNCH CYBERPUNK' 'Local operator catalog must document the quiet listener READY handoff.'
Require $catalog 'type `END` in the same console' 'Local operator catalog must document same-console END finalization.'
Require $catalog 'TYPE SENT AFTER THE FILE HAS BEEN ATTACHED|type `SENT`' 'Local operator catalog must document confirmation-gated cleanup.'
Require $catalog 'Commands 14-16 remain standalone preparation/recovery compatibility' 'Catalog must demote separate managed prelaunch operations from the ordinary ready-for-test workflow.'
Require $cleanRoom 'one attended session|one-session attended handoff|one-command attended' 'Clean-room policy must define the one-session attended handoff.'
Require $cleanRoom 'READY TO LAUNCH CYBERPUNK' 'Clean-room policy must document the READY listener state.'
Require $cleanRoom '\bEND\b' 'Clean-room policy must document END finalization.'
Require $cleanRoom '\bSENT\b' 'Clean-room policy must document confirmation-gated cleanup.'
Require $contract 'ONE COMMAND OR ONE \.CMD LAUNCHER' 'Canonical attended-test contract must retain one-action entry.'

. $corePath
$temp = Join-Path ([IO.Path]::GetTempPath()) ('biology-attended-session-test-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $temp | Out-Null
try {
    $game = Join-Path $temp 'game'
    Write-FixtureFile $game 'bin\x64\Cyberpunk2077.exe' 'fixture-game' | Out-Null
    Write-FixtureFile $game 'tools\redmod\bin\redMod.exe' 'fixture-redmod' | Out-Null
    $receipt = [ordered]@{schemaVersion=2;product='Biology';sourceRevision=('1'*40);buildId='fixture-build';gameVersion='2.31';files=@() } | ConvertTo-Json -Depth 8
    Write-FixtureFile $game 'biology\build-manifest.json' $receipt | Out-Null
    Write-FixtureFile $game 'mods\Biology\info.json' '{"name":"Biology"}'.Replace('\"','"') | Out-Null
    Write-FixtureFile $game 'engine\config\base\scripts.ini' '[Scripts]' | Out-Null
    Write-FixtureFile $game 'r6\config\cybercmd\scc.toml' 'scriptsBlobPath = "{game_dir}\r6\cache\modded\scripts.bin"'.Replace('\"','"') | Out-Null
    Write-FixtureFile $game 'r6\cache\modded\scripts.bin' 'compiled-v1' | Out-Null
    Write-FixtureFile $game 'r6\cache\modded\scripts.bin.ts' 'timestamp-v1' | Out-Null
    $logPath = Write-FixtureFile $game 'r6\logs\redscript_rCURRENT.log' "baseline`r`n"
    $modsPath = Write-FixtureFile $game 'r6\cache\modded\mods.json' '{"mods":["Biology"]}'.Replace('\"','"')
    Write-FixtureFile $game 'r6\cache\modded\tweakdb.bin' 'tweakdb-v1' | Out-Null
    Write-FixtureFile $game 'bin\x64\plugins\cybercmd.asi' 'runner' | Out-Null

    $before = Get-BiologyAttendedSnapshot $game
    Assert-True ([string]$before.installedReceipt.sourceRevision -eq ('1'*40)) 'Snapshot did not retain exact installed source revision.'
    Assert-True ($null -ne $before.configuredRedscriptOutput) 'Snapshot did not resolve configured REDscript output.'
    Add-Content -LiteralPath $logPath -Value 'startup failure signal fixture' -Encoding utf8
    [IO.File]::WriteAllText($modsPath,'{"mods":["Biology"],"session":2}'.Replace('\"','"'),[Text.UTF8Encoding]::new($false))
    $after = Get-BiologyAttendedSnapshot $game
    $comparison = Compare-BiologyAttendedSnapshots $before $after
    Assert-True (@($comparison.changedFiles | Where-Object name -eq 'redscriptCurrentLog').Count -eq 1) 'Before/after comparison missed changed REDscript log.'
    Assert-True (@($comparison.changedFiles | Where-Object name -eq 'redmodModsJson').Count -eq 1) 'Before/after comparison missed changed REDmod mods.json.'
    Assert-True ([string]$comparison.redscriptCurrentLogDelta -match 'startup failure signal fixture') 'Bounded REDscript delta did not capture post-baseline text.'

    $normal = Get-BiologyAttendedLaunchClassification -Events @(
        [pscustomobject]@{event='START-OBSERVED';pid=10},
        [pscustomobject]@{event='EXIT-OBSERVED';pid=10;observedDurationSeconds=60}
    )
    $quick = Get-BiologyAttendedLaunchClassification -Events @(
        [pscustomobject]@{event='START-OBSERVED';pid=11},
        [pscustomobject]@{event='EXIT-OBSERVED';pid=11;observedDurationSeconds=2}
    )
    $missing = Get-BiologyAttendedLaunchClassification -Events @()
    Assert-True ($normal -eq 'STARTED-AND-EXITED') 'Normal process lifecycle classification regressed.'
    Assert-True ($quick -eq 'STARTED-AND-EXITED-QUICKLY') 'Immediate-exit lifecycle classification regressed.'
    Assert-True ($missing -eq 'NOT-OBSERVED') 'Never-launched lifecycle classification regressed.'

    $bundle = Join-Path $temp 'Biology-Operator-Evidence-attended-fixture.zip'
    $recordData = [pscustomobject]@{
        game=[ordered]@{productVersion='fixture';redmodProductVersion='fixture';gameRoot=$game}
        install=[ordered]@{preparationMode='ObserveInstalled';installedCandidatePreserved=$true}
        attendedSession=[ordered]@{sessionId='attended-fixture';before=$before;after=$after;comparison=$comparison}
    }
    [void](Write-BiologyAttendedEvidenceBundle -BundlePath $bundle -EvidenceId 'attended-fixture' -SourceRevision ('1'*40) -Result 'PARTIAL' -RecordData $recordData -ReportText "fixture report`r`n" -PreparationEvidence $null)
    $expand = Join-Path $temp 'expanded'
    Expand-Archive -LiteralPath $bundle -DestinationPath $expand
    $members = @(Get-ChildItem -LiteralPath $expand -File | Select-Object -ExpandProperty Name | Sort-Object)
    Assert-True (($members -join ',') -eq 'evidence.json,report.txt') 'Attended evidence bundle must contain exactly evidence.json and report.txt.'
    $record = Get-Content -Raw -LiteralPath (Join-Path $expand 'evidence.json') | ConvertFrom-Json
    Assert-True ([string]$record.operation -eq 'attended-test-session') 'Attended evidence bundle lost its operation identity.'
    Assert-True ([string]$record.result -eq 'PARTIAL') 'Attended evidence bundle lost its explicit result.'
} finally {
    if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Recurse -Force }
}

Write-Host 'PASS: W15.3 one-command attended session is exact-source-aware, listener-driven, startup-failure-durable, one-bundle, SENT-gated, W15.2-cleanup-reusing, and CMD-thin.'
