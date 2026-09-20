Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$project = Split-Path -Parent $PSScriptRoot
. "$project\tools\Common.ps1"
$scratch = Join-Path $project ('staging\deployment-tests-' + [guid]::NewGuid().ToString('N'))
$game = Join-Path $scratch 'game'
$state = Join-Path $scratch 'state'
New-Item -ItemType Directory -Force -Path "$game\bin\x64","$game\engine\config" | Out-Null
Copy-Item -LiteralPath 'C:\Games\Steam\steamapps\common\Cyberpunk 2077\bin\x64\Cyberpunk2077.exe' -Destination "$game\bin\x64\Cyberpunk2077.exe"
$version = (Get-Item "$game\bin\x64\Cyberpunk2077.exe").VersionInfo.ProductVersion
$payload = 'tests\fixtures\payload.txt'
$hash = Get-Sha256 (Join-Path $project $payload)
$manifestPath = Join-Path $scratch 'deployment.json'
$script:checks = 0
function Assert-True($Condition, $Message) { if (-not $Condition) { throw $Message }; $script:checks++ }
function Expect-Failure([scriptblock]$Action, [string]$Pattern) {
    $caught = $null
    try { & $Action | Out-Null } catch { $caught = $_.Exception.Message }
    Assert-True ($caught -and $caught -match $Pattern) "Expected failure matching '$Pattern', got '$caught'"
}
function Save-Manifest { Write-JsonFile $script:manifest $manifestPath }
function Deploy-Test { & "$project\tools\Deploy.ps1" -GameRoot $game -ManifestPath $manifestPath -StateRoot $state }
$liveStatePath = Join-Path $project 'snapshots\deployment-state\current.json'
$liveBefore = Get-ExistingHash $liveStatePath
Set-Content "$game\engine\config\existing.txt" 'original' -NoNewline
Copy-Item (Join-Path $project $payload) "$game\engine\config\identical.txt"
$oldHash = Get-Sha256 "$game\engine\config\existing.txt"
$script:manifest = [ordered]@{schemaVersion=1; buildId='deployment-regression'; gameVersion=$version; files=@(
    [ordered]@{source=$payload; destination='engine\config\existing.txt'; component='test'; sha256=$hash},
    [ordered]@{source=$payload; destination='engine\config\identical.txt'; component='test'; sha256=$hash},
    [ordered]@{source=$payload; destination='engine\config\new.txt'; component='test'; sha256=$hash}
)}
Save-Manifest
Expect-Failure { Deploy-Test } 'Unknown collision'
Assert-True ((Get-Sha256 "$game\engine\config\existing.txt") -eq $oldHash) 'Unknown file was changed.'
$manifest.files[0].expectedPriorSha256=$oldHash
$manifest.files[0].replacementReason='Regression fixture explicitly owned by this test.'
Save-Manifest
& "$project\tools\Deploy.ps1" -GameRoot $game -ManifestPath $manifestPath -StateRoot $state -WhatIf | Out-Null
Assert-True (-not (Test-Path "$game\engine\config\new.txt")) 'WhatIf wrote game files.'
$receiptPath = Deploy-Test
& "$project\tools\Verify-Deployment.ps1" -GameRoot $game -ReceiptPath $receiptPath
$repeat = Deploy-Test
Assert-True ($receiptPath -eq $repeat) 'Idempotent deployment discarded original receipt.'
$receipt = Get-Content -Raw $receiptPath | ConvertFrom-Json
Set-Content "$game\engine\config\new.txt" 'player change' -NoNewline
Expect-Failure { & "$project\tools\Rollback.ps1" -ReceiptPath $receiptPath } 'drifted|missing or changed'
Assert-True ((Get-Sha256 "$game\engine\config\existing.txt") -eq $hash) 'Rollback changed a file before drift rejection.'
Copy-Item (Join-Path $project $payload) "$game\engine\config\new.txt" -Force
$backup = Join-Path (Split-Path $receiptPath) $receipt.files[0].backup
Set-Content $backup 'corruption' -NoNewline
Expect-Failure { & "$project\tools\Rollback.ps1" -ReceiptPath $receiptPath } 'corrupt backup'
Assert-True ((Get-Sha256 "$game\engine\config\existing.txt") -eq $hash) 'Rollback changed file before backup rejection.'
Set-Content $backup 'original' -NoNewline
& "$project\tools\Rollback.ps1" -ReceiptPath $receiptPath -WhatIf | Out-Null
Assert-True (Test-Path "$game\engine\config\new.txt") 'Rollback WhatIf changed files.'
& "$project\tools\Rollback.ps1" -ReceiptPath $receiptPath
& "$project\tools\Verify-Deployment.ps1" -ReceiptPath $receiptPath
Assert-True ((Get-Sha256 "$game\engine\config\existing.txt") -eq $oldHash) 'Original not restored.'
Assert-True ((Get-Sha256 "$game\engine\config\identical.txt") -eq $hash) 'Identical pre-existing file removed.'
Assert-True (-not (Test-Path "$game\engine\config\new.txt")) 'New file not removed.'
& "$project\tools\Rollback.ps1" -ReceiptPath $receiptPath
foreach ($bad in @('..\escape.txt','C:\escape.txt','file:stream','CON.txt','dir\file.','dir\..\escape.txt')) {
    Expect-Failure { Resolve-SafeChildPath $game $bad } 'relative path|Unsafe|escapes'
}
$manifest.files += $manifest.files[1]
Save-Manifest
Expect-Failure { Deploy-Test } 'Duplicate destination'
$manifest.files = @($manifest.files | Select-Object -First 3)
$manifest.files[0].sha256 = '0' * 64
Save-Manifest
Expect-Failure { Deploy-Test } 'staged hash'
$manifest.files[0].sha256=$hash
$manifest.gameVersion='wrong-version'
Save-Manifest
Expect-Failure { Deploy-Test } 'version mismatch'
$manifest.gameVersion=$version
Save-Manifest
# Simulate a process interruption after only one planned copy.
$receiptPath = Deploy-Test
$receipt = Get-Content -Raw $receiptPath | ConvertFrom-Json
$receipt.status='incomplete'
Write-JsonFile $receipt $receiptPath
Write-JsonFile $receipt "$state\current.json"
Remove-Item -LiteralPath "$game\engine\config\new.txt"
& "$project\tools\Rollback.ps1" -ReceiptPath $receiptPath
Assert-True ((Get-Sha256 "$game\engine\config\existing.txt") -eq $oldHash) 'Interrupted deployment recovery failed.'
Assert-True ((Get-ExistingHash $liveStatePath) -eq $liveBefore) 'Tests modified live deployment state.'
Write-Host "PASS: $script:checks deployment safety assertions. Fixtures retained: $scratch"
