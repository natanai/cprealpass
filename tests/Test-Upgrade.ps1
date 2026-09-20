Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$project = Split-Path -Parent $PSScriptRoot
. "$project\tools\Common.ps1"
$scratch = Join-Path $project ('staging\upgrade-tests-' + [guid]::NewGuid().ToString('N'))
$game = Join-Path $scratch 'game'
$state = Join-Path $scratch 'state'
New-Item -ItemType Directory -Force -Path "$game\bin\x64","$game\r6\scripts","$scratch\source" | Out-Null
Copy-Item -LiteralPath 'C:\Games\Steam\steamapps\common\Cyberpunk 2077\bin\x64\Cyberpunk2077.exe' -Destination "$game\bin\x64\Cyberpunk2077.exe"
$version = (Get-Item "$game\bin\x64\Cyberpunk2077.exe").VersionInfo.ProductVersion
$script:checks = 0
function Assert-True($Condition, $Message) { if (-not $Condition) { throw $Message }; $script:checks++ }
function Expect-Failure([scriptblock]$Action, [string]$Pattern) {
    $caught = $null
    try { & $Action | Out-Null } catch { $caught = $_.Exception.Message }
    Assert-True ($caught -and $caught -match $Pattern) "Expected '$Pattern', got '$caught'"
}
foreach ($value in @('A','B','C','original')) { Set-Content -LiteralPath "$scratch\source\$value.txt" -Value $value -NoNewline }
$hashA = Get-Sha256 "$scratch\source\A.txt"
$hashB = Get-Sha256 "$scratch\source\B.txt"
$hashC = Get-Sha256 "$scratch\source\C.txt"
$hashOriginal = Get-Sha256 "$scratch\source\original.txt"
function Payload([string]$Name, [string]$Value) {
    [ordered]@{source=("$scratch\source\$Value.txt".Substring($project.Length+1));destination="r6/scripts/$Name.txt";component='fixture';sha256=(Get-Sha256 "$scratch\source\$Value.txt")}
}
function Save-TestManifest($Id, $Files) {
    $path = Join-Path $scratch "$Id.json"
    Write-JsonFile ([ordered]@{schemaVersion=1;buildId=$Id;gameVersion=$version;files=@($Files)}) $path
    $path
}
function Upgrade-Test($Path) { & "$project\tools\Upgrade.ps1" -GameRoot $game -StateRoot $state -ManifestPath $Path }
function Rollback-Test($Path) { & "$project\tools\Rollback.ps1" -ReceiptPath $Path }
function Current { Get-Content -Raw "$state\current.json" | ConvertFrom-Json }
function Assert-File($Name, $Expected) { Assert-True ((Get-ExistingHash "$game\r6\scripts\$Name.txt") -eq $Expected) "Unexpected bytes: $Name" }
$liveStatePath = Join-Path $project 'snapshots\deployment-state\current.json'
$liveBefore = Get-Sha256 $liveStatePath
Copy-Item "$scratch\source\original.txt" "$game\r6\scripts\restore.txt"
Copy-Item "$scratch\source\A.txt" "$game\r6\scripts\identical.txt"
Set-Content "$game\player-save-sentinel.dat" 'Do not change player data' -NoNewline
$saveHash = Get-Sha256 "$game\player-save-sentinel.dat"
$replaced = Payload 'restore' 'A'
$replaced.expectedPriorSha256 = $hashOriginal
$replaced.replacementReason = 'Explicit test fixture'
$m1 = Save-TestManifest 'upgrade-v1' @((Payload 'keep' 'A'), (Payload 'identical' 'A'), (Payload 'drop-created' 'A'), $replaced)
$r1 = & "$project\tools\Deploy.ps1" -GameRoot $game -StateRoot $state -ManifestPath $m1
$r1Hash = Get-Sha256 $r1
$m2 = Save-TestManifest 'upgrade-v2' @((Payload 'keep' 'B'), (Payload 'identical' 'B'), (Payload 'new' 'B'))
$m3 = Save-TestManifest 'upgrade-v3' @((Payload 'keep' 'C'), (Payload 'new' 'C'), (Payload 'drop-created' 'C'))
$stateHash = Get-Sha256 "$state\current.json"
& "$project\tools\Upgrade.ps1" -GameRoot $game -StateRoot $state -ManifestPath $m2 -WhatIf | Out-Null
Assert-True ((Get-Sha256 "$state\current.json") -eq $stateHash) 'Upgrade WhatIf changed state.'
Assert-File 'keep' $hashA
Assert-File 'new' $null
$bad = Get-Content -Raw $m2 | ConvertFrom-Json
$bad.gameVersion = 'wrong'
Write-JsonFile $bad "$scratch\bad.json"
Expect-Failure { Upgrade-Test "$scratch\bad.json" } 'version mismatch'
$bad.gameVersion = $version
$bad.files += $bad.files[0]
Write-JsonFile $bad "$scratch\bad.json"
Expect-Failure { Upgrade-Test "$scratch\bad.json" } 'Duplicate destination'
$bad = Get-Content -Raw $m2 | ConvertFrom-Json
$bad.files[0].sha256 = '0'*64
Write-JsonFile $bad "$scratch\bad.json"
Expect-Failure { Upgrade-Test "$scratch\bad.json" } 'staged hash'
$bad = Get-Content -Raw $m2 | ConvertFrom-Json
$bad.buildId = 'upgrade-v1'
Write-JsonFile $bad "$scratch\bad.json"
Expect-Failure { Upgrade-Test "$scratch\bad.json" } 'new build ID'
Copy-Item "$scratch\source\C.txt" "$game\r6\scripts\external.txt"
$external = Save-TestManifest 'external-collision' @((Payload 'external' 'B'))
Expect-Failure { Upgrade-Test $external } 'Unknown collision'
Assert-File 'external' $hashC
Copy-Item "$scratch\source\C.txt" "$game\r6\scripts\keep.txt" -Force
Expect-Failure { Upgrade-Test $m2 } 'drifted'
Copy-Item "$scratch\source\A.txt" "$game\r6\scripts\keep.txt" -Force
$baseReceipt = Get-Content -Raw $r1 | ConvertFrom-Json
$baseBackup = Join-Path (Split-Path $r1) ($baseReceipt.files | Where-Object action -eq 'replace').backup
Copy-Item "$scratch\source\C.txt" $baseBackup -Force
Expect-Failure { Upgrade-Test $m2 } 'corrupt backup'
Assert-File 'keep' $hashA
Copy-Item "$scratch\source\original.txt" $baseBackup -Force
$r2 = Upgrade-Test $m2
Assert-True ((Get-Sha256 $r1) -eq $r1Hash) 'Upgrade changed parent receipt.'
Assert-True ((Current).schemaVersion -eq 3) 'Expected chained receipt.'
Assert-File 'keep' $hashB
Assert-File 'drop-created' $null
Assert-File 'restore' $hashOriginal
Assert-File 'identical' $hashB
Assert-File 'new' $hashB
& "$project\tools\Verify-Deployment.ps1" -ReceiptPath $r2
Assert-True ((Upgrade-Test $m2) -eq $r2) 'Repeat upgrade discarded history.'
Expect-Failure { Rollback-Test $r1 } 'not the active'
# Parent tampering is rejected before any rollback writes.
$parentBytes = [IO.File]::ReadAllBytes($r1)
Add-Content -LiteralPath $r1 -Value ' '
Expect-Failure { Rollback-Test $r2 } 'Parent receipt missing or changed'
[IO.File]::WriteAllBytes($r1, $parentBytes)
Assert-File 'keep' $hashB
$second = Get-Content -Raw $r2 | ConvertFrom-Json
$removedBackup = Join-Path (Split-Path $r2) ($second.files | Where-Object action -eq 'remove').backup
Copy-Item "$scratch\source\C.txt" $removedBackup -Force
Expect-Failure { Rollback-Test $r2 } 'corrupt backup'
Assert-File 'keep' $hashB
Copy-Item "$scratch\source\A.txt" $removedBackup -Force
# Reject a damaged before-image relationship even when its hash is well-formed.
$secondBytes = [IO.File]::ReadAllBytes($r2)
$damaged = Get-Content -Raw $r2 | ConvertFrom-Json
($damaged.files | Where-Object destination -eq 'r6/scripts/keep.txt').priorSha256 = $hashC
Write-JsonFile $damaged $r2
Write-JsonFile $damaged "$state\current.json"
Expect-Failure { Rollback-Test $r2 } 'before-image does not match'
Assert-File 'keep' $hashB
[IO.File]::WriteAllBytes($r2, $secondBytes)
[IO.File]::WriteAllBytes("$state\current.json", $secondBytes)
$r2Hash = Get-Sha256 $r2
$r3 = Upgrade-Test $m3
Assert-True ((Get-Sha256 $r2) -eq $r2Hash) 'Second upgrade mutated parent.'
Assert-File 'identical' $hashA
Assert-File 'drop-created' $hashC
Assert-File 'restore' $hashOriginal
& "$project\tools\Verify-Deployment.ps1" -ReceiptPath $r3
# Resume a rollback stopped after some files had already returned to v2.
$third = Get-Content -Raw $r3 | ConvertFrom-Json
$third.status = 'rolling-back'
Write-JsonFile $third $r3
Write-JsonFile $third "$state\current.json"
Copy-Item "$scratch\source\B.txt" "$game\r6\scripts\keep.txt" -Force
Remove-Item -LiteralPath "$game\r6\scripts\drop-created.txt"
Rollback-Test $r3
Assert-True ((Current).receiptPath -eq $r2) 'Rollback did not reactivate v2.'
Assert-File 'identical' $hashB
Assert-File 'drop-created' $null
$stateHash = Get-Sha256 "$state\current.json"
& "$project\tools\Rollback.ps1" -ReceiptPath $r2 -WhatIf | Out-Null
Assert-True ((Get-Sha256 "$state\current.json") -eq $stateHash) 'Rollback WhatIf changed state.'
Rollback-Test $r2
Assert-True ((Current).receiptPath -eq $r1) 'Rollback did not reactivate v1.'
Assert-File 'restore' $hashA
Assert-File 'identical' $hashA
Assert-File 'drop-created' $hashA
Assert-File 'new' $null
& "$project\tools\Verify-Deployment.ps1" -ReceiptPath $r1
# Simulate interruption between child receipt completion and parent-pointer publication.
Copy-Item -LiteralPath $r2 -Destination "$state\current.json" -Force
Rollback-Test $r2
Assert-True ((Current).receiptPath -eq $r1) 'Completed rollback pointer recovery failed.'
# Simulate an interrupted upgrade with a mix of untouched and deployed files.
$r2 = Upgrade-Test $m2
$second = Get-Content -Raw $r2 | ConvertFrom-Json
$second.status = 'incomplete'
Write-JsonFile $second $r2
Write-JsonFile $second "$state\current.json"
Copy-Item "$scratch\source\A.txt" "$game\r6\scripts\keep.txt" -Force
Copy-Item "$scratch\source\A.txt" "$game\r6\scripts\drop-created.txt" -Force
Remove-Item -LiteralPath "$game\r6\scripts\new.txt"
Rollback-Test $r2
Assert-True ((Current).receiptPath -eq $r1) 'Partial upgrade recovery lost parent.'
Assert-File 'keep' $hashA
Assert-File 'restore' $hashA
Assert-File 'drop-created' $hashA
Assert-File 'new' $null
Rollback-Test $r1
Assert-File 'restore' $hashOriginal
Assert-File 'identical' $hashA
Assert-File 'keep' $null
Assert-File 'drop-created' $null
Assert-File 'external' $hashC
Assert-True ((Get-Sha256 "$game\player-save-sentinel.dat") -eq $saveHash) 'Save sentinel was changed.'
Assert-True ((Get-Sha256 $liveStatePath) -eq $liveBefore) 'Live deployment state was changed.'
$report = [ordered]@{testedAtUtc=[DateTime]::UtcNow.ToString('o');passed=$true;assertions=$script:checks;fixture=$scratch;liveStateUnchanged=$true;scope='Three-version upgrade chain; baseline restoration; repeat apply; dry runs; drift, collision, source and backup rejection; interrupted upgrade and rollback-pointer recovery.'}
Write-JsonFile $report (Join-Path $project 'reports\upgrade-tests.json')
Write-Host "PASS: $script:checks upgrade safety assertions. Fixtures retained: $scratch"
