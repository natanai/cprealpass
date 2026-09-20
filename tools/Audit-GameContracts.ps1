[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$GamePath = 'C:\Games\Steam\steamapps\common\Cyberpunk 2077',
    [string]$ReportPath,
    [switch]$SkipCompile
)

$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'Audit-GameContracts.ps1 requires PowerShell 7 or newer.' }

if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
    $RepoRoot = Split-Path -Parent $PSScriptRoot
}
$RepoRoot = [IO.Path]::GetFullPath($RepoRoot)
$GamePath = [IO.Path]::GetFullPath($GamePath)
$tools = Join-Path $RepoRoot 'tools'
. (Join-Path $tools 'Common.ps1')

if (-not (Test-Path -LiteralPath (Join-Path $RepoRoot '.git'))) {
    throw "Biology/cprealpass Git repository not found at: $RepoRoot"
}

$reportRoot = Join-Path $RepoRoot 'reports'
New-Item -ItemType Directory -Force -Path $reportRoot | Out-Null
if ([string]::IsNullOrWhiteSpace($ReportPath)) {
    $reportName = 'local-game-contract-audit-' + [DateTime]::Now.ToString('yyyyMMdd-HHmmss') + '-' + [guid]::NewGuid().ToString('N').Substring(0,8) + '.txt'
    $ReportPath = Join-Path $reportRoot $reportName
} elseif (-not [IO.Path]::IsPathRooted($ReportPath)) {
    $ReportPath = Join-Path $RepoRoot $ReportPath
}
$ReportPath = [IO.Path]::GetFullPath($ReportPath)
$reportParent = Split-Path -Parent $ReportPath
New-Item -ItemType Directory -Force -Path $reportParent | Out-Null

Start-Transcript -LiteralPath $ReportPath -Force | Out-Null
try {
    $exePath = Join-Path $GamePath 'bin\x64\Cyberpunk2077.exe'
    $baseBundle = Join-Path $GamePath 'r6\cache\final.redscripts'
    if (-not (Test-Path -LiteralPath $exePath -PathType Leaf)) { throw "Cyberpunk executable not found: $exePath" }
    if (-not (Test-Path -LiteralPath $baseBundle -PathType Leaf)) { throw "Cyberpunk base script bundle not found: $baseBundle" }

    Write-Host ''
    Write-Host '=== Biology native-contract audit ===' -ForegroundColor Cyan
    Write-Host 'Game access is read-only. Output is written only to the active cprealpass checkout.' -ForegroundColor DarkGray
    Write-Host "Repository: $RepoRoot" -ForegroundColor DarkGray
    Write-Host "Evidence report: $ReportPath" -ForegroundColor DarkGray
    Write-Host ''

    # Refresh the redistribution-safe machine/game snapshot first so later agents can
    # distinguish the actual installed environment from assumptions in old web examples.
    & (Join-Path $tools 'Refresh-LocalGameReference.ps1') -RepoRoot $RepoRoot -GamePath $GamePath
    if ($LASTEXITCODE -ne 0) { throw 'Local game reference refresh failed.' }

    $referenceRoot = Join-Path $RepoRoot 'reference\cyberpunk'
    $policyPath = Join-Path $RepoRoot 'manifest\native-seams.json'
    $sourceRoot = Join-Path $RepoRoot 'src\redscript\CyberpunkRealism'
    $policy = Get-Content -Raw -LiteralPath $policyPath | ConvertFrom-Json

    # Fingerprint the small set of official files that define the most important script
    # and database compatibility boundaries. Avoid hashing every multi-gigabyte archive:
    # archive path/size inventory is already captured by Refresh-LocalGameReference.ps1.
    $sentinelRelative = @(
        'bin\x64\Cyberpunk2077.exe',
        'r6\cache\final.redscripts',
        'r6\cache\tweakdb.bin'
    )
    $sentinels = [Collections.Generic.List[object]]::new()
    foreach ($relative in $sentinelRelative) {
        $path = Join-Path $GamePath $relative
        if (Test-Path -LiteralPath $path -PathType Leaf) {
            $item = Get-Item -LiteralPath $path
            $sentinels.Add([ordered]@{
                path = $relative.Replace('\','/')
                sizeBytes = $item.Length
                sha256 = Get-Sha256 $path
                lastWriteUtc = $item.LastWriteTimeUtc.ToString('o')
            })
        }
    }

    # Inventory every project-owned hook boundary. This is intentionally derived from
    # our source rather than a hand-maintained duplicate list of method names. Exact
    # compilation below is the authoritative signature/type compatibility check.
    $hooks = [Collections.Generic.List[object]]::new()
    $hookPattern = [regex]'(?ms)^\s*@(?<annotation>wrapMethod|replaceMethod|addMethod|addField)\((?<target>[^\r\n\)]+)\)\s*\r?\n\s*(?<declaration>(?:public|private|protected)[^\r\n]+)'
    foreach ($name in @($policy.allowedHookFiles | Sort-Object)) {
        $path = Join-Path $sourceRoot ([string]$name)
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Native seam policy references missing source: $name" }
        $text = Get-Content -Raw -LiteralPath $path
        foreach ($match in $hookPattern.Matches($text)) {
            $hooks.Add([ordered]@{
                source = [string]$name
                sourceSha256 = Get-Sha256 $path
                annotation = '@' + $match.Groups['annotation'].Value
                target = $match.Groups['target'].Value.Trim()
                declaration = $match.Groups['declaration'].Value.Trim()
            })
        }
    }
    if ($hooks.Count -eq 0) { throw 'No native hook declarations were discovered; audit parser is not exercising production seams.' }

    $canonicalHookText = (@($hooks | ForEach-Object {
        ([string]$_.source + '|' + [string]$_.sourceSha256 + '|' + [string]$_.annotation + '|' + [string]$_.target + '|' + [string]$_.declaration)
    }) -join "`n")
    $sha = [Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [Text.Encoding]::UTF8.GetBytes($canonicalHookText)
        $hookFingerprint = ([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-','')
    } finally {
        $sha.Dispose()
    }

    $revision = (& git -C $RepoRoot rev-parse HEAD).Trim()
    if ($LASTEXITCODE -ne 0) { throw 'Unable to resolve repository revision.' }
    $gameVersion = (Get-Item -LiteralPath $exePath).VersionInfo.ProductVersion
    $baseBundleSha = Get-Sha256 $baseBundle

    $previousPath = Join-Path $referenceRoot 'native-contracts.json'
    $previous = $null
    if (Test-Path -LiteralPath $previousPath -PathType Leaf) {
        try { $previous = Get-Content -Raw -LiteralPath $previousPath | ConvertFrom-Json } catch { $previous = $null }
    }

    $compilePassed = $null
    $compileBuildId = $null
    if (-not $SkipCompile) {
        # Exact compilation is the highest-value early warning for native method/type
        # changes. Acquire only the pinned redscript toolchain; no game files are written.
        & (Join-Path $tools 'Acquire-Components.ps1') -ComponentIds @('redscript')
        if ($LASTEXITCODE -ne 0) { throw 'Pinned redscript toolchain acquisition failed.' }

        & (Join-Path $RepoRoot 'tests\Test-NativeSeamPolicy.ps1')
        if ($LASTEXITCODE -ne 0) { throw 'Native seam policy check failed.' }

        $compileBuildId = 'contract-audit-' + [DateTime]::UtcNow.ToString('yyyyMMdd-HHmmss') + '-' + $revision.Substring(0,12).ToLowerInvariant()
        & (Join-Path $tools 'Build-OwnedAcceptance.ps1') -BuildId $compileBuildId -GameRoot $GamePath
        if ($LASTEXITCODE -ne 0) { throw 'Exact owned-source compilation failed.' }
        $compilePassed = $true
    }

    $contractSnapshot = [ordered]@{
        schemaVersion = 1
        generatedUtc = [DateTime]::UtcNow.ToString('o')
        sourceRevision = $revision
        gameVersion = $gameVersion
        baseScriptBundleSha256 = $baseBundleSha
        nativeSeamPolicyGameVersion = [string]$policy.gameVersion
        hookCount = $hooks.Count
        hookFingerprintSha256 = $hookFingerprint
        sentinels = @($sentinels.ToArray())
        hooks = @($hooks.ToArray())
        note = 'Derived compatibility metadata only. No proprietary game content is embedded.'
    }
    Write-JsonFile $contractSnapshot $previousPath

    $changes = [ordered]@{
        previousSnapshotPresent = $null -ne $previous
        gameVersionChanged = if ($null -eq $previous) { $null } else { [string]$previous.gameVersion -ne $gameVersion }
        baseScriptBundleChanged = if ($null -eq $previous) { $null } else { [string]$previous.baseScriptBundleSha256 -ne $baseBundleSha }
        hookFingerprintChanged = if ($null -eq $previous) { $null } else { [string]$previous.hookFingerprintSha256 -ne $hookFingerprint }
    }

    $audit = [ordered]@{
        schemaVersion = 1
        generatedUtc = [DateTime]::UtcNow.ToString('o')
        sourceRevision = $revision
        gameVersion = $gameVersion
        readOnlyGameAudit = $true
        nativeSeamPolicyPassed = $true
        exactCompileAttempted = -not [bool]$SkipCompile
        exactCompilePassed = $compilePassed
        compileBuildId = $compileBuildId
        changesFromPreviousTrackedSnapshot = $changes
        contractSnapshot = 'reference/cyberpunk/native-contracts.json'
        textEvidenceReport = $ReportPath
        scope = 'Static/native contract compatibility audit. Runtime semantics, UI rendering, save behavior, quest behavior and gameplay feel still require attended testing.'
    }
    Write-JsonFile $audit (Join-Path $referenceRoot 'compatibility-audit.json')

    Write-Host ''
    Write-Host 'PASS: Biology native-contract audit completed.' -ForegroundColor Green
    Write-Host "Game version:            $gameVersion"
    Write-Host "Base script SHA-256:     $baseBundleSha"
    Write-Host "Biology native hooks:    $($hooks.Count)"
    Write-Host "Hook fingerprint SHA-256:$hookFingerprint"
    if ($SkipCompile) {
        Write-Host 'Exact compile:            skipped by request' -ForegroundColor Yellow
    } else {
        Write-Host 'Exact compile:            passed' -ForegroundColor Green
    }
    if ($null -ne $previous) {
        Write-Host "Previous base changed:   $($changes.baseScriptBundleChanged)"
        Write-Host "Hook surface changed:    $($changes.hookFingerprintChanged)"
    }
    Write-Host ''
    Write-Host 'Tracked audit outputs:' -ForegroundColor Cyan
    Write-Host '  reference/cyberpunk/native-contracts.json'
    Write-Host '  reference/cyberpunk/compatibility-audit.json'
    Write-Host ''
    Write-Host 'Git changes:' -ForegroundColor Cyan
    & git -C $RepoRoot status --short -- reference/cyberpunk
} catch {
    Write-Host ''
    Write-Host 'FAIL: Biology native-contract audit did not complete.' -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    throw
} finally {
    try { Stop-Transcript | Out-Null } catch { }
    Write-Host ''
    Write-Host "LOCAL EVIDENCE REPORT: $ReportPath" -ForegroundColor Cyan
    Write-Host 'Return that .txt file to the owning ChatGPT thread; do not paste the console transcript.' -ForegroundColor DarkGray
}
