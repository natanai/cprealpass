param(
    [string]$GameRoot = 'C:\Games\Steam\steamapps\common\Cyberpunk 2077',
    [string]$ManifestPath,
    [string]$StateRoot,
    [switch]$WhatIf
)
. "$PSScriptRoot\Common.ps1"
$GameRoot = Assert-GameRoot $GameRoot
Assert-GameStopped
$project = Get-ProjectRoot
if (-not $StateRoot) { $StateRoot = Join-Path $project 'snapshots\deployment-state' }
if (-not $ManifestPath) { $ManifestPath = Join-Path $project 'manifest\deployment.json' }
$manifest = Get-Content -Raw -LiteralPath $ManifestPath | ConvertFrom-Json
if ($manifest.schemaVersion -ne 1 -or $manifest.buildId -notmatch '^[a-zA-Z0-9][a-zA-Z0-9._-]*$') { throw 'Invalid deployment schema/build ID.' }
$actualVersion = (Get-Item -LiteralPath (Join-Path $GameRoot 'bin\x64\Cyberpunk2077.exe')).VersionInfo.ProductVersion
if ($manifest.gameVersion -ne $actualVersion) { throw "Game version mismatch: expected $($manifest.gameVersion), actual $actualVersion" }
$currentPath = Join-Path $StateRoot 'current.json'
$lock = Open-StateLock $StateRoot
try {
    $seen = @{}
    $manifestFiles = @($manifest.files)
    $planIndex = 0
    $plan = @(foreach ($file in $manifestFiles) {
        $planIndex++
        Write-Progress -Activity 'Planning realpass deployment' -Status "Hash-checking $planIndex / $($manifestFiles.Count): $($file.destination)" -PercentComplete ([Math]::Floor((100.0*$planIndex)/$manifestFiles.Count))
        $source = Resolve-SafeChildPath $project ([string]$file.source)
        $destination = Resolve-SafeChildPath $GameRoot ([string]$file.destination)
        if ($seen.ContainsKey($destination)) { throw "Duplicate destination: $destination" }
        $seen[$destination] = $true
        if ($file.sha256 -notmatch '^[a-fA-F0-9]{64}$' -or (Get-Sha256 $source) -ne $file.sha256) { throw "Invalid staged hash: $source" }
        $existing = Get-ExistingHash $destination
        $expectedPrior = Get-OptionalProperty $file 'expectedPriorSha256'
        $reason = Get-OptionalProperty $file 'replacementReason'
        if ($existing -and $existing -ne $file.sha256 -and ($expectedPrior -ne $existing -or [string]::IsNullOrWhiteSpace($reason))) { throw "Unknown collision; expected prior hash and replacement reason required: $destination" }
        $action = if ($existing -eq $file.sha256) { 'preserve' } elseif ($existing) { 'replace' } else { 'create' }
        [ordered]@{source=$source; destination=$file.destination; component=$file.component; priorSha256=$existing; deployedSha256=$file.sha256; action=$action; replacementReason=$reason; backup=$(if ($action -eq 'replace') {'backup\' + $file.destination} else {$null})}
    })
    Write-Progress -Activity 'Planning realpass deployment' -Completed
    if (Test-Path -LiteralPath $currentPath) {
        $current = Get-Content -Raw -LiteralPath $currentPath | ConvertFrom-Json
        if ($current.gameRoot -ne $GameRoot) { throw 'State directory belongs to a different game root.' }
        if ($current.status -ne 'rolled-back' -and @($current.files).Count -gt 0) {
            $same = $current.status -eq 'deployed' -and $current.buildId -eq $manifest.buildId -and @($current.files).Count -eq $plan.Count
            foreach ($f in $current.files) {
                $match = @($plan | Where-Object { $_.destination -eq $f.destination -and $_.deployedSha256 -eq $f.deployedSha256 -and $_.priorSha256 -eq $f.deployedSha256 })
                if ($match.Count -ne 1) { $same = $false }
            }
            if ($same) { Write-Host 'Already deployed and hash verified; original rollback receipt retained.'; return $current.receiptPath }
            throw 'Use Upgrade.ps1 to replace an active full build while preserving its rollback chain, or explicitly roll it back first.'
        }
    }
    if ($WhatIf) { $plan | ForEach-Object { [pscustomobject]$_ } | Select-Object destination,component,action; return }
    $id = $manifest.buildId + '-' + [guid]::NewGuid().ToString('N')
    $snapshot = Resolve-SafeChildPath $StateRoot $id
    $receiptPath = Join-Path $snapshot 'receipt.json'
    # Complete and verify every backup before writing any game file.
    $backupItems = @($plan | Where-Object { $_.backup })
    $backupIndex = 0
    foreach ($item in $plan) {
        if ($item.backup) {
            $backupIndex++
            Write-Progress -Activity 'Backing up files that realpass will replace' -Status "$backupIndex / $($backupItems.Count): $($item.destination)" -PercentComplete ([Math]::Floor((100.0*$backupIndex)/$backupItems.Count))
            $backup = Resolve-SafeChildPath $snapshot $item.backup
            New-Item -ItemType Directory -Force -Path (Split-Path -Parent $backup) | Out-Null
            Copy-Item -LiteralPath (Resolve-SafeChildPath $GameRoot $item.destination) -Destination $backup
            if ((Get-Sha256 $backup) -ne $item.priorSha256) { throw 'Backup verification failed.' }
        }
    }
    Write-Progress -Activity 'Backing up files that realpass will replace' -Completed
    $receipt = [ordered]@{schemaVersion=2; deploymentId=$id; buildId=$manifest.buildId; gameRoot=$GameRoot; stateRoot=[IO.Path]::GetFullPath($StateRoot); receiptPath=$receiptPath; status='prepared'; deployedAtUtc=[DateTime]::UtcNow.ToString('o'); files=$plan}
    Write-JsonFile $receipt $receiptPath
    Write-JsonFile $receipt $currentPath
    try {
        $applyIndex = 0
        foreach ($item in $plan) {
            $applyIndex++
            Write-Progress -Activity 'Applying realpass runtime' -Status "$applyIndex / $($plan.Count): $($item.destination)" -PercentComplete ([Math]::Floor((100.0*$applyIndex)/$plan.Count))
            $destination = Resolve-SafeChildPath $GameRoot $item.destination
            if ((Get-ExistingHash $destination) -ne $item.priorSha256) { throw "Destination changed after preflight: $destination" }
            if ((Get-Sha256 $item.source) -ne $item.deployedSha256) { throw 'Source changed after preflight.' }
            if ($item.action -ne 'preserve') {
                New-Item -ItemType Directory -Force -Path (Split-Path -Parent $destination) | Out-Null
                Copy-VerifiedPayload $item.source $destination $item.deployedSha256
            }
            if ((Get-Sha256 $destination) -ne $item.deployedSha256) { throw "Post-copy hash failed: $destination" }
        }
        Write-Progress -Activity 'Applying realpass runtime' -Completed
        $receipt.status = 'deployed'
    } catch {
        Write-Progress -Activity 'Applying realpass runtime' -Completed
        $receipt.status = 'incomplete'
        Write-JsonFile $receipt $receiptPath
        Write-JsonFile $receipt $currentPath
        throw "Deployment incomplete. Recovery receipt: $receiptPath. $($_.Exception.Message)"
    }
    Write-JsonFile $receipt $receiptPath
    Write-JsonFile $receipt $currentPath
    Write-Host "Deployed $($plan.Count) files. Receipt: $receiptPath"
    return $receiptPath
} finally { $lock.Dispose() }