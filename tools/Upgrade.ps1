param(
    [string]$GameRoot = 'C:\Games\Steam\steamapps\common\Cyberpunk 2077',
    [Parameter(Mandatory=$true)][string]$ManifestPath,
    [string]$StateRoot,
    [switch]$WhatIf
)
. "$PSScriptRoot\Common.ps1"
$GameRoot = Assert-GameRoot $GameRoot
Assert-GameStopped
$project = Get-ProjectRoot
if (-not $StateRoot) { $StateRoot = Join-Path $project 'snapshots\deployment-state' }
$StateRoot = [IO.Path]::GetFullPath($StateRoot)
$manifest = Get-Content -Raw -LiteralPath $ManifestPath | ConvertFrom-Json
if ($manifest.schemaVersion -ne 1 -or $manifest.buildId -notmatch '^[a-zA-Z0-9][a-zA-Z0-9._-]*$') { throw 'Invalid deployment schema/build ID.' }
$actualVersion = (Get-Item -LiteralPath (Join-Path $GameRoot 'bin\x64\Cyberpunk2077.exe')).VersionInfo.ProductVersion
if ($manifest.gameVersion -ne $actualVersion) { throw 'Game version mismatch.' }
$currentPath = Join-Path $StateRoot 'current.json'
$lock = Open-StateLock $StateRoot
try {
    $current = Get-Content -Raw -LiteralPath $currentPath | ConvertFrom-Json
    if ($current.gameRoot -ne $GameRoot -or [IO.Path]::GetFullPath($current.stateRoot) -ne $StateRoot) { throw 'State directory belongs to a different root.' }
    if ($current.status -ne 'deployed') { throw 'Active deployment requires recovery or initial deployment; cannot upgrade.' }
    $parentPath = Get-CanonicalReceiptPath $StateRoot $current.deploymentId
    if ((Get-Sha256 $parentPath) -ne (Get-Sha256 $currentPath)) { throw 'Current pointer and receipt disagree; recover before upgrading.' }
    $chain = @(Get-ReceiptChain $current)
    $old = @{}
    foreach ($file in $current.files) {
        $path = Resolve-SafeChildPath $GameRoot $file.destination
        if ((Get-ExistingHash $path) -ne $file.deployedSha256) { throw "Owned file drifted: $path" }
        $old[$path] = $file
    }
    # Require the complete recovery chain to remain usable before any new change.
    foreach ($node in $chain) {
        foreach ($file in $node.files) {
            if ($file.action -in @('replace','remove')) { Get-VerifiedReceiptBackup $node $file | Out-Null }
        }
    }
    $selected = @{}
    $plan = [Collections.Generic.List[object]]::new()
    foreach ($file in $manifest.files) {
        $source = Resolve-SafeChildPath $project $file.source
        $path = Resolve-SafeChildPath $GameRoot $file.destination
        if ($selected.ContainsKey($path)) { throw 'Duplicate destination.' }
        $selected[$path] = $true
        if ($file.sha256 -notmatch '^[A-Fa-f0-9]{64}$' -or (Get-Sha256 $source) -ne $file.sha256) { throw 'Invalid staged hash.' }
        $prior = Get-ExistingHash $path
        $owned = $old.ContainsKey($path) -and ($current.schemaVersion -eq 2 -or $old[$path].inPayload)
        $reason = Get-OptionalProperty $file 'replacementReason'
        if (-not $owned -and $prior -and $prior -ne $file.sha256 -and ((Get-OptionalProperty $file 'expectedPriorSha256') -ne $prior -or [string]::IsNullOrWhiteSpace($reason))) { throw "Unknown collision; expected prior hash and replacement reason required: $path" }
        $action = if ($prior -eq $file.sha256) { 'preserve' } elseif ($prior) { 'replace' } else { 'create' }
        $plan.Add([ordered]@{source=$source;destination=$file.destination;component=$file.component;inPayload=$true;priorSha256=$prior;deployedSha256=$file.sha256;action=$action;replacementReason=$reason;backup=$(if($action -eq 'replace'){'backup\'+$file.destination}else{$null})})
    }
    # Restore dropped paths to their first observed state, not to an arbitrary old mod version.
    foreach ($path in @($old.Keys | Sort-Object)) {
        if ($selected.ContainsKey($path)) { continue }
        $previous = $old[$path]
        $baseline = $previous.priorSha256
        foreach ($node in $chain) {
            foreach ($file in $node.files) {
                if ((Resolve-SafeChildPath $GameRoot $file.destination) -eq $path) { $baseline = $file.priorSha256; break }
            }
        }
        $prior = $previous.deployedSha256
        $source = $null
        if ($baseline -and $baseline -ne $prior) {
            foreach ($node in $chain) {
                foreach ($file in $node.files) {
                    if ((Resolve-SafeChildPath $GameRoot $file.destination) -eq $path -and $file.priorSha256 -eq $baseline -and $file.action -in @('replace','remove')) { $source = Get-VerifiedReceiptBackup $node $file; break }
                }
                if ($source) { break }
            }
            if (-not $source) { throw "Original bytes unavailable for dropped path: $path" }
        }
        $action = if ($null -eq $prior -and $null -eq $baseline) { 'absent' } elseif ($prior -eq $baseline) { 'preserve' } elseif ($null -eq $baseline) { 'remove' } elseif ($null -eq $prior) { 'create' } else { 'replace' }
        $plan.Add([ordered]@{source=$source;destination=$previous.destination;component=$previous.component;inPayload=$false;priorSha256=$prior;deployedSha256=$baseline;action=$action;replacementReason='Restore original state for a path omitted by the new full manifest.';backup=$(if($action -in @('replace','remove')){'backup\'+$previous.destination}else{$null})})
    }
    $same = $current.buildId -eq $manifest.buildId
    foreach ($item in $plan) {
        $path = Resolve-SafeChildPath $GameRoot $item.destination
        if (-not $old.ContainsKey($path) -or $item.priorSha256 -ne $item.deployedSha256) { $same = $false; break }
        $wasPayload = $current.schemaVersion -eq 2 -or $old[$path].inPayload
        if ($wasPayload -ne $item.inPayload) { $same = $false; break }
    }
    if ($same) { Write-Host 'Already deployed and hash verified; upgrade history retained.'; return $parentPath }
    if ($current.buildId -eq $manifest.buildId) { throw 'Changed full build must have a new build ID.' }
    if ($WhatIf) { $plan | ForEach-Object { [pscustomobject]$_ } | Select-Object destination,component,action,inPayload; return }
    $id = $manifest.buildId + '-' + [guid]::NewGuid().ToString('N')
    $receiptPath = Get-CanonicalReceiptPath $StateRoot $id
    $snapshot = Split-Path -Parent $receiptPath
    foreach ($item in $plan) {
        if ($item.backup) {
            $backup = Resolve-SafeChildPath $snapshot $item.backup
            Copy-VerifiedPayload (Resolve-SafeChildPath $GameRoot $item.destination) $backup $item.priorSha256
        }
    }
    $receipt = [ordered]@{schemaVersion=3;deploymentId=$id;buildId=$manifest.buildId;gameRoot=$GameRoot;stateRoot=$StateRoot;receiptPath=$receiptPath;parentDeploymentId=$current.deploymentId;parentReceiptSha256=(Get-Sha256 $parentPath);status='prepared';deployedAtUtc=[DateTime]::UtcNow.ToString('o');files=@($plan.ToArray())}
    Write-JsonFile $receipt $receiptPath
    Write-JsonFile $receipt $currentPath
    try {
        foreach ($item in $plan) {
            Assert-GameStopped
            $destination = Resolve-SafeChildPath $GameRoot $item.destination
            if ((Get-ExistingHash $destination) -ne $item.priorSha256) { throw "Destination changed after preflight: $destination" }
            if ($item.action -in @('create','replace')) { Copy-VerifiedPayload $item.source $destination $item.deployedSha256 }
            elseif ($item.action -eq 'remove') { Remove-Item -LiteralPath $destination }
            if ((Get-ExistingHash $destination) -ne $item.deployedSha256) { throw 'Upgrade post-write verification failed.' }
        }
        $receipt.status = 'deployed'
    } catch {
        $receipt.status = 'incomplete'
        Write-JsonFile $receipt $receiptPath
        Write-JsonFile $receipt $currentPath
        throw "Upgrade incomplete. Recover with Rollback.ps1 -ReceiptPath '$receiptPath'. $($_.Exception.Message)"
    }
    Write-JsonFile $receipt $receiptPath
    Write-JsonFile $receipt $currentPath
    Write-Host "Upgrade verified: $($manifest.buildId). Rollback restores $($current.buildId)."
    $receiptPath
} finally { $lock.Dispose() }
