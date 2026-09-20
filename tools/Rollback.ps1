param([Parameter(Mandatory=$true)][string]$ReceiptPath, [switch]$WhatIf)
. "$PSScriptRoot\Common.ps1"
$receiptPathResolved = (Resolve-Path -LiteralPath $ReceiptPath).Path
$receipt = Get-Content -Raw -LiteralPath $receiptPathResolved | ConvertFrom-Json
if ($receipt.schemaVersion -notin @(2,3)) { throw 'Legacy receipts require manual review; do not infer ownership.' }
$GameRoot = Assert-GameRoot $receipt.gameRoot
Assert-GameStopped
$currentPath = Join-Path $receipt.stateRoot 'current.json'
$lock = Open-StateLock $receipt.stateRoot
try {
    $current = Get-Content -Raw -LiteralPath $currentPath | ConvertFrom-Json
    if ($current.deploymentId -ne $receipt.deploymentId -or $current.gameRoot -ne $GameRoot) { throw 'Receipt is not the active deployment.' }
    $chain = @(Get-ReceiptChain $receipt)
    if ($receiptPathResolved -ne (Get-CanonicalReceiptPath $receipt.stateRoot $receipt.deploymentId)) { throw 'Receipt path mismatch.' }
    if ($receipt.status -eq 'rolled-back' -and $receipt.schemaVersion -eq 2) { Write-Host 'Already rolled back.'; return }
    $plan = @(foreach ($file in $receipt.files) {
        $destination = Resolve-SafeChildPath $GameRoot $file.destination
        $actual = Get-ExistingHash $destination
        # Only exact before/after bytes can be recovered. Never overwrite unrelated user drift.
        if ($actual -ne $file.deployedSha256 -and $actual -ne $file.priorSha256) { throw "Refusing rollback; file drifted: $destination" }
        if ($receipt.status -eq 'deployed' -and $actual -ne $file.deployedSha256) { throw "Refusing rollback; deployed file missing or changed: $destination" }
        if ($receipt.status -eq 'rolled-back' -and $actual -ne $file.priorSha256) { throw "Refusing rollback; restored file changed: $destination" }
        $backup = $null
        if ($file.action -in @('replace','remove')) { $backup = Get-VerifiedReceiptBackup $receipt $file }
        [ordered]@{destination=$destination;actual=$actual;prior=$file.priorSha256;action=$file.action;backup=$backup}
    })
    if ($WhatIf) { $plan | ForEach-Object { [pscustomobject]$_ } | Select-Object destination,action; return }
    $receipt.status = 'rolling-back'
    Write-JsonFile $receipt $receiptPathResolved
    Write-JsonFile $receipt $currentPath
    foreach ($item in $plan) {
        Assert-GameStopped
        if ((Get-ExistingHash $item.destination) -ne $item.actual) { throw 'Destination changed during rollback.' }
        if ($item.action -in @('replace','remove')) { Copy-VerifiedPayload $item.backup $item.destination $item.prior }
        elseif ($item.action -eq 'create' -and (Test-Path -LiteralPath $item.destination)) { Remove-Item -LiteralPath $item.destination }
        if ((Get-ExistingHash $item.destination) -ne $item.prior) { throw 'Rollback verification failed.' }
    }
    # The parent receipt stays immutable throughout its child's lifetime. Publish it
    # only after all before-images are restored, including recovery after interruption.
    if ($receipt.schemaVersion -eq 3) {
        $parent = $chain[1]
        foreach ($file in $parent.files) {
            if ((Get-ExistingHash (Resolve-SafeChildPath $GameRoot $file.destination)) -ne $file.deployedSha256) { throw 'Restored parent verification failed.' }
        }
        $receipt.status = 'rolled-back'
        Write-JsonFile $receipt $receiptPathResolved
        Copy-VerifiedPayload $parent.receiptPath $currentPath $receipt.parentReceiptSha256
        Write-Host "Upgrade rolled back; active build restored to $($parent.buildId)."
    } else {
        $receipt.status = 'rolled-back'
        Write-JsonFile $receipt $receiptPathResolved
        Write-JsonFile $receipt $currentPath
        Write-Host "Rollback verified for $($receipt.deploymentId)."
    }
} finally { $lock.Dispose() }
