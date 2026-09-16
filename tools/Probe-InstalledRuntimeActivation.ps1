[CmdletBinding()]
param(
    [string]$GameRoot = 'C:\Games\Steam\steamapps\common\Cyberpunk 2077',
    [Parameter(Mandatory=$true)][string]$ReportPath,
    [ValidatePattern('^[A-Fa-f0-9]{40}$')]
    [string]$ExpectedInstalledSourceRevision = '68b50ed9e3c629ca252326918dbbb68b9bc35494'
)

$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'Probe-InstalledRuntimeActivation.ps1 requires PowerShell 7 or newer.' }

$GameRoot = [IO.Path]::GetFullPath($GameRoot)
$ReportPath = [IO.Path]::GetFullPath($ReportPath)
$ExpectedInstalledSourceRevision = $ExpectedInstalledSourceRevision.ToLowerInvariant()
$reportParent = Split-Path -Parent $ReportPath
if (-not [string]::IsNullOrWhiteSpace($reportParent)) {
    New-Item -ItemType Directory -Force -Path $reportParent | Out-Null
}

function Add-Evidence([string]$Text = '') {
    Add-Content -LiteralPath $ReportPath -Value $Text -Encoding utf8
}

function Get-Sha256([string]$Path) {
    (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToUpperInvariant()
}

function Assert-SafeRelativePath([string]$RelativePath) {
    $relative = $RelativePath.Replace('\','/').TrimStart('/')
    if ([string]::IsNullOrWhiteSpace($relative) -or [IO.Path]::IsPathRooted($relative) -or $relative.Contains(':')) {
        throw "Unsafe installed receipt path: $RelativePath"
    }
    foreach ($part in @($relative -split '/')) {
        if ($part -in @('','..','.') -or $part -match '[<>"|?*]' -or $part -match '[ .]$') {
            throw "Unsafe installed receipt path segment: $RelativePath"
        }
    }
    return $relative
}

function Resolve-SafeGameChild([string]$RelativePath) {
    $relative = Assert-SafeRelativePath $RelativePath
    $root = $GameRoot.TrimEnd([IO.Path]::DirectorySeparatorChar,[IO.Path]::AltDirectorySeparatorChar)
    $candidate = [IO.Path]::GetFullPath((Join-Path $root $relative.Replace('/',[IO.Path]::DirectorySeparatorChar)))
    if (-not $candidate.StartsWith($root + [IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)) {
        throw "Installed receipt path escapes game root: $RelativePath"
    }
    return $candidate
}

function Record-File([string]$Label,[string]$Path) {
    Add-Evidence ("--- $Label ---")
    Add-Evidence ('path=' + $Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        Add-Evidence 'exists=NO'
        return $null
    }
    $item = Get-Item -LiteralPath $Path
    Add-Evidence 'exists=YES'
    Add-Evidence ('bytes=' + $item.Length)
    Add-Evidence ('lastWriteUtc=' + $item.LastWriteTimeUtc.ToString('o'))
    Add-Evidence ('sha256=' + (Get-Sha256 $Path))
    return $item
}

function Add-BoundedText([string]$Label,[string]$Path,[int]$MaxChars = 65536) {
    Add-Evidence ("--- $Label ---")
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        Add-Evidence '<missing>'
        return
    }
    $text = Get-Content -Raw -LiteralPath $Path -ErrorAction Stop
    if ($text.Length -gt $MaxChars) {
        Add-Evidence ("<truncated to first $MaxChars characters of $($text.Length)>")
        Add-Evidence $text.Substring(0,$MaxChars)
    } else {
        Add-Evidence $text.TrimEnd()
    }
}

function Test-FileContainsByteSequence([string]$Path,[byte[]]$Needle) {
    if ($Needle.Count -eq 0) { return $false }
    $chunkSize = 1MB
    $buffer = New-Object byte[] ($chunkSize + $Needle.Count - 1)
    $carry = 0
    $stream = [IO.File]::Open($Path,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::ReadWrite)
    try {
        while ($true) {
            $read = $stream.Read($buffer,$carry,$chunkSize)
            if ($read -le 0) { break }
            $total = $carry + $read
            $lastStart = $total - $Needle.Count
            for ($i = 0; $i -le $lastStart; $i++) {
                if ($buffer[$i] -ne $Needle[0]) { continue }
                $match = $true
                for ($j = 1; $j -lt $Needle.Count; $j++) {
                    if ($buffer[$i + $j] -ne $Needle[$j]) { $match = $false; break }
                }
                if ($match) { return $true }
            }
            $carry = [Math]::Min($Needle.Count - 1,$total)
            if ($carry -gt 0) {
                [Array]::Copy($buffer,$total - $carry,$buffer,0,$carry)
            }
        }
    } finally {
        $stream.Dispose()
    }
    return $false
}

function Search-BinaryMarker([string]$Path,[string]$Marker) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return 'FILE-MISSING' }
    $ascii = [Text.Encoding]::ASCII.GetBytes($Marker)
    if (Test-FileContainsByteSequence $Path $ascii) { return 'ASCII-PRESENT' }
    $utf16 = [Text.Encoding]::Unicode.GetBytes($Marker)
    if (Test-FileContainsByteSequence $Path $utf16) { return 'UTF16LE-PRESENT' }
    return 'NOT-FOUND-IN-PLAINTEXT'
}

Add-Evidence ''
Add-Evidence '=== W13.1 INSTALLED BIOLOGY RUNTIME ACTIVATION INNER PROBE ==='
Add-Evidence ('Started: ' + [DateTime]::Now.ToString('o'))
Add-Evidence ('Game root: ' + $GameRoot)
Add-Evidence ('Expected installed source revision: ' + $ExpectedInstalledSourceRevision)
Add-Evidence 'Policy: installed Cyberpunk/REDmod tree is READ-ONLY. This probe does not deploy, install, remove, rewrite, or launch the game.'
Add-Evidence 'Proof boundary: installed payload identity + live REDscript log/output evidence. Static presence is not attended gameplay acceptance.'

try {
    if (-not (Test-Path -LiteralPath $GameRoot -PathType Container)) { throw "Cyberpunk game directory does not exist: $GameRoot" }

    $running = @(Get-Process -Name 'Cyberpunk2077' -ErrorAction SilentlyContinue)
    Add-Evidence ('Cyberpunk process count: ' + $running.Count)
    if ($running.Count -gt 0) { throw 'Cyberpunk 2077 is running. Close it before collecting a stable post-session runtime report.' }

    $gameExe = Join-Path $GameRoot 'bin\x64\Cyberpunk2077.exe'
    $redmodExe = Join-Path $GameRoot 'tools\redmod\bin\redMod.exe'
    foreach ($required in @($gameExe,$redmodExe)) {
        if (-not (Test-Path -LiteralPath $required -PathType Leaf)) { throw "Required supported-install file missing: $required" }
    }
    $gameVersion = (Get-Item -LiteralPath $gameExe).VersionInfo.ProductVersion
    $redmodVersion = (Get-Item -LiteralPath $redmodExe).VersionInfo.ProductVersion
    Add-Evidence ('Cyberpunk product version: ' + $gameVersion)
    Add-Evidence ('Cyberpunk executable SHA-256: ' + (Get-Sha256 $gameExe))
    Add-Evidence ('REDmod product version: ' + $redmodVersion)
    Add-Evidence ('REDmod executable SHA-256: ' + (Get-Sha256 $redmodExe))

    $receiptPath = Join-Path $GameRoot 'biology\build-manifest.json'
    [void](Record-File 'Installed Biology ownership receipt' $receiptPath)
    if (-not (Test-Path -LiteralPath $receiptPath -PathType Leaf)) { throw 'Installed Biology build manifest is missing.' }
    $receipt = Get-Content -Raw -LiteralPath $receiptPath | ConvertFrom-Json
    if ($receipt.schemaVersion -ne 2 -or $receipt.product -ne 'Biology') { throw 'Installed Biology build manifest is not the schema-2 Biology receipt.' }

    $installedRevision = ([string]$receipt.sourceRevision).ToLowerInvariant()
    Add-Evidence ('Installed receipt sourceRevision: ' + $installedRevision)
    Add-Evidence ('Installed receipt buildId: ' + [string]$receipt.buildId)
    Add-Evidence ('Installed receipt gameVersion: ' + [string]$receipt.gameVersion)
    Add-Evidence ('Installed receipt playableRuntimeIncluded: ' + [string]$receipt.playableRuntimeIncluded)

    $entries = @($receipt.files)
    Add-Evidence ('Installed receipt file count: ' + $entries.Count)
    if ($entries.Count -eq 0) { throw 'Installed Biology receipt contains no files.' }

    $missing = [Collections.Generic.List[string]]::new()
    $mismatch = [Collections.Generic.List[string]]::new()
    $verified = 0
    $latestPayloadWriteUtc = [DateTime]::MinValue

    foreach ($entry in $entries) {
        $relative = Assert-SafeRelativePath ([string]$entry.path)
        $full = Resolve-SafeGameChild $relative
        if (-not (Test-Path -LiteralPath $full -PathType Leaf)) {
            $missing.Add($relative)
            continue
        }
        $actual = Get-Sha256 $full
        if ($actual -ne ([string]$entry.sha256).ToUpperInvariant()) {
            $mismatch.Add(("$relative expected=$($entry.sha256) actual=$actual"))
            continue
        }
        $verified++
        $lastWrite = (Get-Item -LiteralPath $full).LastWriteTimeUtc
        if ($lastWrite -gt $latestPayloadWriteUtc) { $latestPayloadWriteUtc = $lastWrite }
    }

    Add-Evidence ('Receipt files hash-verified: ' + $verified + '/' + $entries.Count)
    Add-Evidence ('Receipt files missing: ' + $missing.Count)
    foreach ($item in @($missing | Select-Object -First 50)) { Add-Evidence ('MISSING | ' + $item) }
    Add-Evidence ('Receipt files hash-mismatched: ' + $mismatch.Count)
    foreach ($item in @($mismatch | Select-Object -First 50)) { Add-Evidence ('MISMATCH | ' + $item) }
    if ($latestPayloadWriteUtc -ne [DateTime]::MinValue) {
        Add-Evidence ('Latest verified payload lastWriteUtc: ' + $latestPayloadWriteUtc.ToString('o'))
    }

    $sourceMatches = $installedRevision -eq $ExpectedInstalledSourceRevision
    Add-Evidence ('Expected candidate revision match: ' + ($(if ($sourceMatches) { 'YES' } else { 'NO' })))

    $criticalRelatives = @(
        'mods/Biology/info.json',
        'mods/Biology/tweaks/base/gameplay/static_data/database/items/weapons/parts/biology_activation.tweak',
        'engine/config/base/scripts.ini',
        'engine/tools/scc.exe',
        'engine/tools/scc_lib.dll',
        'r6/config/cybercmd/scc.toml',
        'r6/scripts/CyberpunkRealism/RealpassSettings.reds',
        'r6/scripts/CyberpunkRealism/BiologyRuntimeAvailability.reds',
        'r6/scripts/CyberpunkRealism/BodyRuntime.reds',
        'r6/scripts/CyberpunkRealism/BiologyRadialHubNative.reds'
    )
    foreach ($relative in $criticalRelatives) {
        [void](Record-File ('Critical installed path: ' + $relative) (Resolve-SafeGameChild $relative))
    }

    $scriptRoot = Resolve-SafeGameChild 'r6/scripts/CyberpunkRealism'
    $installedScripts = if (Test-Path -LiteralPath $scriptRoot -PathType Container) {
        @(Get-ChildItem -LiteralPath $scriptRoot -File -Filter '*.reds' -ErrorAction Stop)
    } else { @() }
    $receiptScripts = @($entries | Where-Object { ([string]$_.path).Replace('\','/') -like 'r6/scripts/CyberpunkRealism/*.reds' })
    Add-Evidence ('Installed Biology REDscript source count: ' + $installedScripts.Count)
    Add-Evidence ('Receipt Biology REDscript source count: ' + $receiptScripts.Count)

    $boundary1Pass = $sourceMatches -and $missing.Count -eq 0 -and $mismatch.Count -eq 0 -and $installedScripts.Count -eq $receiptScripts.Count -and $receiptScripts.Count -gt 0
    if ($boundary1Pass) {
        Add-Evidence 'BOUNDARY 1 — ARTIFACT / INSTALL PLACEMENT: PASS'
    } else {
        Add-Evidence 'BOUNDARY 1 — ARTIFACT / INSTALL PLACEMENT: BROKEN'
    }

    Add-BoundedText 'Installed redscript loader config (scripts.ini)' (Resolve-SafeGameChild 'engine/config/base/scripts.ini') 32768
    Add-BoundedText 'Installed cybercmd redscript config (scc.toml)' (Resolve-SafeGameChild 'r6/config/cybercmd/scc.toml') 32768

    $redscriptLog = Resolve-SafeGameChild 'r6/logs/redscript_rCURRENT.log'
    $logItem = Record-File 'Canonical live REDscript current log' $redscriptLog
    $logPresent = $null -ne $logItem
    $logFresh = $false
    $errorSignals = @()
    $biologySignals = @()

    if ($logPresent) {
        if ($latestPayloadWriteUtc -eq [DateTime]::MinValue) {
            $logFresh = $true
        } else {
            $logFresh = $logItem.LastWriteTimeUtc -ge $latestPayloadWriteUtc
        }
        Add-Evidence ('REDscript log at-or-after latest verified payload timestamp: ' + ($(if ($logFresh) { 'YES' } else { 'NO' })))

        $biologySignals = @(Select-String -LiteralPath $redscriptLog -Pattern 'CyberpunkRealism|CRRealpass|CRBody|Biology' -AllMatches -ErrorAction SilentlyContinue | Select-Object -First 100)
        Add-Evidence ('REDscript log Biology/source signal lines (bounded): ' + $biologySignals.Count)
        foreach ($hit in $biologySignals) { Add-Evidence ('BIOLOGY-LOG | ' + $hit.Line.Trim()) }

        $errorSignals = @(Select-String -LiteralPath $redscriptLog -Pattern '(?i)\b(error|failed|failure|fatal|panic)\b' -AllMatches -ErrorAction SilentlyContinue |
            Where-Object { $_.Line -notmatch '(?i)\b0\s+errors?\b|\bno\s+errors?\b' } |
            Select-Object -First 100)
        Add-Evidence ('REDscript log error/failure signal lines (bounded): ' + $errorSignals.Count)
        foreach ($hit in $errorSignals) { Add-Evidence ('REDSCRIPT-ERROR-SIGNAL | ' + $hit.Line.Trim()) }

        Add-Evidence '--- REDscript current log tail (last 500 lines maximum) ---'
        foreach ($line in @(Get-Content -LiteralPath $redscriptLog -Tail 500 -ErrorAction Stop)) { Add-Evidence $line }
    } else {
        Add-Evidence 'REDscript current log is absent. The installed redscript project documents this file as the canonical successful-setup/runtime log surface.'
    }

    $boundary2State = if (-not $logPresent) {
        'BROKEN — canonical live REDscript log absent'
    } elseif (-not $logFresh) {
        'BROKEN/STALE — canonical live REDscript log predates installed candidate payload'
    } elseif ($errorSignals.Count -gt 0) {
        'ERROR-SIGNALS — live REDscript log is current but contains bounded failure/error evidence'
    } else {
        'LOG-PRESENT — current live REDscript log exists with no bounded failure/error signal'
    }
    Add-Evidence ('BOUNDARY 2 — REDSCRIPT LIVE LOADER / COMPILE: ' + $boundary2State)

    $modsJson = Resolve-SafeGameChild 'r6/cache/modded/mods.json'
    [void](Record-File 'Official REDmod generated mods.json' $modsJson)
    Add-BoundedText 'Official REDmod generated mods.json content' $modsJson 65536

    foreach ($relative in @('r6/cache/modded/tweakdb.bin','r6/cache/modded/tweakdb_ep1.bin')) {
        $path = Resolve-SafeGameChild $relative
        $item = Record-File ('Official REDmod generated output: ' + $relative) $path
        if ($null -ne $item) {
            foreach ($marker in @('BiologyLauncherActivationMarker','Items.BiologyLauncherActivationMarker')) {
                Add-Evidence ("PLAINTEXT MARKER SEARCH | $relative | $marker | " + (Search-BinaryMarker $path $marker))
            }
        }
    }
    Add-Evidence 'Marker-search interpretation: plaintext presence supports deployed-marker output; plaintext absence is INCONCLUSIVE because generated TweakDB binaries may hash/strip record names.'

    $firstProven = if (-not $boundary1Pass) {
        'BOUNDARY 1 — ARTIFACT / INSTALL PLACEMENT'
    } elseif (-not $logPresent -or -not $logFresh) {
        'BOUNDARY 2 — REDSCRIPT LIVE LOADER / COMPILE'
    } else {
        'NONE FROM READ-ONLY EXTERNAL EVIDENCE YET'
    }
    Add-Evidence ('FIRST PROVEN BROKEN BOUNDARY: ' + $firstProven)
    if ($errorSignals.Count -gt 0 -and $firstProven -eq 'NONE FROM READ-ONLY EXTERNAL EVIDENCE YET') {
        Add-Evidence 'NEXT NARROW DECISION: inspect the captured current REDscript error lines before investigating class attachment, registration, activation gating, or UI entrypoints.'
    } elseif ($firstProven -eq 'NONE FROM READ-ONLY EXTERNAL EVIDENCE YET') {
        Add-Evidence 'NEXT NARROW DECISION: source/install and current loader-log presence are accounted for; use this report to decide whether class/hook attachment or activation gating is the first remaining boundary.'
    }

    Add-Evidence 'PROBE RESULT: PASS (evidence collection completed; this is not gameplay acceptance)'
    Add-Evidence ('Completed: ' + [DateTime]::Now.ToString('o'))
} catch {
    Add-Evidence ''
    Add-Evidence '=== W13.1 INNER PROBE FAILURE ==='
    Add-Evidence ('Time: ' + [DateTime]::Now.ToString('o'))
    Add-Evidence ('Exception type: ' + $_.Exception.GetType().FullName)
    Add-Evidence ('Error: ' + $_.Exception.Message)
    if ($_.InvocationInfo) {
        Add-Evidence ('Script line: ' + $_.InvocationInfo.ScriptLineNumber)
        Add-Evidence ('Position: ' + $_.InvocationInfo.PositionMessage)
    }
    throw
}
