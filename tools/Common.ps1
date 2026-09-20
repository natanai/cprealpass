Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
function Get-ProjectRoot { Split-Path -Parent $PSScriptRoot }
function Resolve-SafeChildPath([string]$Root, [string]$RelativePath) {
    if ([string]::IsNullOrWhiteSpace($RelativePath) -or [IO.Path]::IsPathRooted($RelativePath) -or $RelativePath.Contains(':')) { throw "Expected ordinary relative path: $RelativePath" }
    $parts = $RelativePath -split '[\\/]'
    foreach ($part in $parts) {
        if ($part -in @('','..','.') -or $part -match '[<>"|?*]' -or $part -match '[ .]$' -or $part -match '^(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])(\.|$)') { throw "Unsafe path segment: $RelativePath" }
    }
    $rootFull = [IO.Path]::GetFullPath($Root).TrimEnd('\','/')
    $candidate = [IO.Path]::GetFullPath((Join-Path $rootFull $RelativePath))
    if (-not $candidate.StartsWith($rootFull + '\', [StringComparison]::OrdinalIgnoreCase)) { throw "Path escapes root: $RelativePath" }
    $probe = $candidate
    while ($probe) {
        if (Test-Path -LiteralPath $probe) {
            if ((Get-Item -Force -LiteralPath $probe).Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "Reparse points are not supported: $probe" }
        }
        $probe = Split-Path -Parent $probe
    }
    return $candidate
}
function Assert-GameRoot([string]$GameRoot) {
    $resolved = (Resolve-Path -LiteralPath $GameRoot).Path
    $exe = Resolve-SafeChildPath $resolved 'bin\x64\Cyberpunk2077.exe'
    if (-not (Test-Path -LiteralPath $exe -PathType Leaf)) { throw "Not a Cyberpunk root: $resolved" }
    return $resolved
}
function Assert-GameStopped {
    if (Get-Process -Name Cyberpunk2077 -ErrorAction SilentlyContinue) { throw 'Close Cyberpunk before deployment or rollback.' }
}
function Get-Sha256([string]$Path) { (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToUpperInvariant() }
function Get-OptionalProperty($Object, [string]$Name) {
    if ($Object.PSObject.Properties.Name -contains $Name) { return $Object.$Name }
    return $null
}
function Get-ExistingHash([string]$Path) {
    if (Test-Path -LiteralPath $Path) {
        if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "Expected file: $Path" }
        return Get-Sha256 $Path
    }
    return $null
}
function Write-JsonFile([object]$Value, [string]$Path, [int]$Depth = 16) {
    $parent = Split-Path -Parent $Path
    New-Item -ItemType Directory -Force -Path $parent | Out-Null
    $temp = "$Path.$([guid]::NewGuid().ToString('N')).tmp"
    try {
        $Value | ConvertTo-Json -Depth $Depth | Set-Content -LiteralPath $temp -Encoding utf8
        Move-Item -LiteralPath $temp -Destination $Path -Force
    } finally { if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp } }
}
function Open-StateLock([string]$StateRoot) {
    New-Item -ItemType Directory -Force -Path $StateRoot | Out-Null
    [IO.File]::Open((Join-Path $StateRoot 'deployment.lock'), [IO.FileMode]::OpenOrCreate, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
}

# Schema 3 adds reversible full-build transitions, chained to immutable prior receipts.
function Assert-ReceiptLayout($Receipt) {
    if ($Receipt.schemaVersion -notin @(2,3)) { throw 'Unsupported receipt schema.' }
    if ($Receipt.deploymentId -notmatch '^[a-zA-Z0-9][a-zA-Z0-9._-]*$') { throw 'Invalid receipt deployment ID.' }
    if ($Receipt.status -notin @('prepared','deployed','incomplete','rolling-back','rolled-back')) { throw 'Invalid receipt status.' }
    $seen = @{}
    foreach ($file in $Receipt.files) {
        $path = Resolve-SafeChildPath $Receipt.gameRoot $file.destination
        if ($seen.ContainsKey($path)) { throw 'Duplicate receipt destination.' }
        $seen[$path] = $true
        $prior = $file.priorSha256
        $after = $file.deployedSha256
        if (($null -ne $prior -and $prior -notmatch '^[A-Fa-f0-9]{64}$') -or ($null -ne $after -and $after -notmatch '^[A-Fa-f0-9]{64}$')) { throw 'Invalid receipt hashes.' }
        $valid = switch ($file.action) {
            'create' { $null -eq $prior -and $null -ne $after }
            'replace' { $null -ne $prior -and $null -ne $after -and $prior -ne $after }
            'preserve' { $null -ne $prior -and $prior -eq $after }
            'remove' { $Receipt.schemaVersion -eq 3 -and $null -ne $prior -and $null -eq $after }
            'absent' { $Receipt.schemaVersion -eq 3 -and $null -eq $prior -and $null -eq $after }
            default { $false }
        }
        if (-not $valid) { throw "Invalid receipt action or hashes: $($file.destination)" }
        if ($Receipt.schemaVersion -eq 3 -and $file.inPayload -isnot [bool]) { throw 'Invalid receipt payload membership.' }
        if ($Receipt.schemaVersion -eq 3 -and $file.inPayload -and $null -eq $after) { throw 'Payload cannot be absent.' }
    }
}
function Get-CanonicalReceiptPath([string]$StateRoot, [string]$DeploymentId) {
    if ($DeploymentId -notmatch '^[a-zA-Z0-9][a-zA-Z0-9._-]*$') { throw 'Invalid receipt deployment ID.' }
    Resolve-SafeChildPath $StateRoot ($DeploymentId + '\receipt.json')
}
function Get-ReceiptChain($Receipt) {
    $state = [IO.Path]::GetFullPath($Receipt.stateRoot)
    $game = [IO.Path]::GetFullPath($Receipt.gameRoot)
    $seen = @{}
    $node = $Receipt
    for ($depth = 0; $depth -lt 100; $depth++) {
        Assert-ReceiptLayout $node
        $path = Get-CanonicalReceiptPath $state $node.deploymentId
        if ($node.receiptPath -ne $path -or [IO.Path]::GetFullPath($node.stateRoot) -ne $state -or [IO.Path]::GetFullPath($node.gameRoot) -ne $game) { throw 'Receipt chain root/path mismatch.' }
        if ($seen.ContainsKey($node.deploymentId)) { throw 'Receipt chain cycle.' }
        $seen[$node.deploymentId] = $true
        $node
        if ($node.schemaVersion -eq 2) { return }
        $parentPath = Get-CanonicalReceiptPath $state $node.parentDeploymentId
        if ($node.parentReceiptSha256 -notmatch '^[A-Fa-f0-9]{64}$' -or (Get-ExistingHash $parentPath) -ne $node.parentReceiptSha256) { throw 'Parent receipt missing or changed.' }
        $parent = Get-Content -Raw -LiteralPath $parentPath | ConvertFrom-Json
        if ($parent.status -ne 'deployed') { throw 'Parent receipt is not a completed deployment.' }
        $childFiles = @{}
        foreach ($file in $node.files) { $childFiles[(Resolve-SafeChildPath $game $file.destination)] = $file }
        foreach ($file in $parent.files) {
            $path = Resolve-SafeChildPath $game $file.destination
            if (-not $childFiles.ContainsKey($path) -or $childFiles[$path].priorSha256 -ne $file.deployedSha256) { throw 'Upgrade before-image does not match parent ownership.' }
        }
        $node = $parent
    }
    throw 'Receipt chain depth limit exceeded.'
}
function Get-VerifiedReceiptBackup($Receipt, $File) {
    $snapshot = Split-Path -Parent (Get-CanonicalReceiptPath $Receipt.stateRoot $Receipt.deploymentId)
    $backup = Resolve-SafeChildPath $snapshot $File.backup
    if ((Get-ExistingHash $backup) -ne $File.priorSha256) { throw "Missing or corrupt backup: $backup" }
    $backup
}
function Copy-VerifiedPayload([string]$Source, [string]$Destination, [string]$ExpectedHash) {
    # A torn copy must never turn the owned destination into an unrecoverable hash.
    # The temporary file is on the destination volume so publication is a rename.
    if ((Get-Sha256 $Source) -ne $ExpectedHash) { throw 'Source changed before copy.' }
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Destination) | Out-Null
    $temporary = $Destination + '.codex-tmp-' + [guid]::NewGuid().ToString('N')
    try {
        $output = [IO.File]::Open($temporary, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
        try {
            $inputFile = [IO.File]::OpenRead($Source)
            try { $inputFile.CopyTo($output); $output.Flush($true) } finally { $inputFile.Dispose() }
        } finally { $output.Dispose() }
        if ((Get-Sha256 $temporary) -ne $ExpectedHash) { throw 'Temporary payload hash failed.' }
        [IO.File]::Move($temporary, $Destination, $true)
    } finally { if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary } }
}
