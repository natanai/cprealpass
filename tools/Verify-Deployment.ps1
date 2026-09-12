param([string]$GameRoot, [string]$ReceiptPath)
. "$PSScriptRoot\Common.ps1"
$project = Get-ProjectRoot
if (-not $ReceiptPath) { $ReceiptPath = Join-Path $project 'snapshots\deployment-state\current.json' }
$receipt = Get-Content -Raw -LiteralPath $ReceiptPath | ConvertFrom-Json
Assert-ReceiptLayout $receipt
if (-not $GameRoot) { $GameRoot = $receipt.gameRoot }
$GameRoot = Assert-GameRoot $GameRoot
if ($GameRoot -ne $receipt.gameRoot) { throw 'Receipt/game root mismatch.' }
if ($receipt.status -notin @('deployed','rolled-back')) { throw "Deployment requires recovery: $($receipt.status)" }
$results = @(foreach ($file in $receipt.files) {
    $path = Resolve-SafeChildPath $GameRoot $file.destination
    $actual = Get-ExistingHash $path
    $expected = if ($receipt.status -eq 'rolled-back') { $file.priorSha256 } else { $file.deployedSha256 }
    [ordered]@{destination=$file.destination; expectedSha256=$expected; actualSha256=$actual; valid=($actual -eq $expected)}
})
$valid = @($results | Where-Object { -not $_.valid }).Count -eq 0
$report = [ordered]@{verifiedAtUtc=[DateTime]::UtcNow.ToString('o'); deploymentId=$receipt.deploymentId; status=$receipt.status; valid=$valid; files=$results}
$reportPath = Join-Path $project ('reports\verify-' + [guid]::NewGuid().ToString('N') + '.json')
Write-JsonFile $report $reportPath
if (-not $valid) { throw "Deployment verification failed. Report: $reportPath" }
Write-Host "Verification passed. Report: $reportPath"
