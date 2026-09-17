Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-BiologyAttendedSha256([string]$Path) {
    return (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToUpperInvariant()
}

function Get-BiologyAttendedBoundedTail([string]$Path,[int]$TailLines = 500,[int]$MaxChars = 65536) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $null }
    $text = (@(Get-Content -LiteralPath $Path -Tail $TailLines -ErrorAction Stop) -join "`n")
    if ($text.Length -gt $MaxChars) { return $text.Substring($text.Length - $MaxChars) }
    return $text
}

function Get-BiologyAttendedFileState([string]$Path,[switch]$IncludeTail,[int]$TailLines = 500,[int]$MaxTailChars = 65536) {
    $full = [IO.Path]::GetFullPath($Path)
    if (-not (Test-Path -LiteralPath $full -PathType Leaf)) {
        return [pscustomobject]@{ path=$full; exists=$false; bytes=$null; lastWriteUtc=$null; sha256=$null; tail=$null }
    }
    $item = Get-Item -LiteralPath $full
    $tail = if ($IncludeTail) { Get-BiologyAttendedBoundedTail -Path $full -TailLines $TailLines -MaxChars $MaxTailChars } else { $null }
    return [pscustomobject]@{
        path = $full
        exists = $true
        bytes = [long]$item.Length
        lastWriteUtc = $item.LastWriteTimeUtc.ToString('o')
        sha256 = Get-BiologyAttendedSha256 $full
        tail = $tail
    }
}

function Get-BiologyAttendedConfiguredBlobPath([string]$GameRoot) {
    $config = Join-Path $GameRoot 'r6\config\cybercmd\scc.toml'
    if (-not (Test-Path -LiteralPath $config -PathType Leaf)) { return $null }
    $text = Get-Content -Raw -LiteralPath $config -ErrorAction Stop
    $match = [regex]::Match($text,'(?m)^\s*scriptsBlobPath\s*=\s*"(?<path>[^"]+)"\s*$')
    if (-not $match.Success) { return $null }
    $raw = $match.Groups['path'].Value.Trim()
    $expanded = $raw.Replace('{game_dir}',$GameRoot).Replace('\\','\')
    $full = [IO.Path]::GetFullPath($expanded)
    $root = [IO.Path]::GetFullPath($GameRoot).TrimEnd('\','/')
    if (-not $full.StartsWith($root + [IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)) {
        throw "Configured REDscript output escapes the game root: $raw"
    }
    return $full
}

function Get-BiologyAttendedProcessState {
    $items = [Collections.Generic.List[object]]::new()
    foreach ($process in @(Get-Process -Name 'Cyberpunk2077' -ErrorAction SilentlyContinue | Sort-Object Id)) {
        $startedUtc = $null
        try { $startedUtc = $process.StartTime.ToUniversalTime().ToString('o') } catch {}
        $items.Add([pscustomobject]@{ pid=[int]$process.Id; startTimeUtc=$startedUtc })
    }
    return @($items)
}

function Get-BiologyAttendedSnapshot([string]$GameRoot) {
    $root = [IO.Path]::GetFullPath($GameRoot)
    if (-not (Test-Path -LiteralPath $root -PathType Container)) { throw "Cyberpunk game directory does not exist: $root" }

    $gameExe = Join-Path $root 'bin\x64\Cyberpunk2077.exe'
    $redmodExe = Join-Path $root 'tools\redmod\bin\redMod.exe'
    $receiptPath = Join-Path $root 'biology\build-manifest.json'
    $sccConfig = Join-Path $root 'r6\config\cybercmd\scc.toml'
    $configuredBlob = Get-BiologyAttendedConfiguredBlobPath $root
    $receiptIdentity = $null
    if (Test-Path -LiteralPath $receiptPath -PathType Leaf) {
        try {
            $receipt = Get-Content -Raw -LiteralPath $receiptPath | ConvertFrom-Json
            $receiptIdentity = [pscustomobject]@{
                schemaVersion = $receipt.schemaVersion
                product = [string]$receipt.product
                sourceRevision = ([string]$receipt.sourceRevision).ToLowerInvariant()
                buildId = [string]$receipt.buildId
                gameVersion = [string]$receipt.gameVersion
                fileCount = @($receipt.files).Count
            }
        } catch {
            $receiptIdentity = [pscustomobject]@{ parseError=$_.Exception.Message }
        }
    }

    $files = [ordered]@{}
    $files['gameExe'] = Get-BiologyAttendedFileState $gameExe
    $files['redmodExe'] = Get-BiologyAttendedFileState $redmodExe
    $files['receipt'] = Get-BiologyAttendedFileState $receiptPath
    $files['redmodIdentity'] = Get-BiologyAttendedFileState (Join-Path $root 'mods\Biology\info.json')
    $files['scriptsIni'] = Get-BiologyAttendedFileState (Join-Path $root 'engine\config\base\scripts.ini')
    $files['sccConfig'] = Get-BiologyAttendedFileState $sccConfig
    $files['configuredBlob'] = if ($configuredBlob) { Get-BiologyAttendedFileState $configuredBlob } else { $null }
    $files['configuredBlobTimestamp'] = if ($configuredBlob) { Get-BiologyAttendedFileState ($configuredBlob + '.ts') } else { $null }
    $files['redscriptCurrentLog'] = Get-BiologyAttendedFileState (Join-Path $root 'r6\logs\redscript_rCURRENT.log') -IncludeTail -TailLines 500 -MaxTailChars 65536
    $files['redmodModsJson'] = Get-BiologyAttendedFileState (Join-Path $root 'r6\cache\modded\mods.json') -IncludeTail -TailLines 400 -MaxTailChars 65536
    $files['redmodTweakDb'] = Get-BiologyAttendedFileState (Join-Path $root 'r6\cache\modded\tweakdb.bin')
    $files['redmodTweakDbEp1'] = Get-BiologyAttendedFileState (Join-Path $root 'r6\cache\modded\tweakdb_ep1.bin')
    $files['cybercmdTaskRunner'] = Get-BiologyAttendedFileState (Join-Path $root 'bin\x64\plugins\cybercmd.asi')
    $files['cybercmdLoader'] = Get-BiologyAttendedFileState (Join-Path $root 'bin\x64\version.dll')
    $files['cybercmdLoaderConfig'] = Get-BiologyAttendedFileState (Join-Path $root 'bin\x64\global.ini') -IncludeTail -TailLines 300 -MaxTailChars 32768
    $files['red4extTaskRunner'] = Get-BiologyAttendedFileState (Join-Path $root 'red4ext\RED4ext.dll')
    $files['red4extLoader'] = Get-BiologyAttendedFileState (Join-Path $root 'bin\x64\winmm.dll')

    $gameVersion = $null
    $redmodVersion = $null
    if (Test-Path -LiteralPath $gameExe -PathType Leaf) { $gameVersion = (Get-Item -LiteralPath $gameExe).VersionInfo.ProductVersion }
    if (Test-Path -LiteralPath $redmodExe -PathType Leaf) { $redmodVersion = (Get-Item -LiteralPath $redmodExe).VersionInfo.ProductVersion }

    return [pscustomobject]@{
        capturedUtc = [DateTime]::UtcNow.ToString('o')
        gameRoot = $root
        gameProductVersion = $gameVersion
        redmodProductVersion = $redmodVersion
        configuredRedscriptOutput = $configuredBlob
        installedReceipt = $receiptIdentity
        processes = @(Get-BiologyAttendedProcessState)
        files = [pscustomobject]$files
    }
}

function Get-BiologyAttendedStartupDiagnostics([string]$GameRoot,[datetime]$SinceUtc) {
    $root = [IO.Path]::GetFullPath($GameRoot)
    $logs = [Collections.Generic.List[object]]::new()
    foreach ($relative in @('red4ext\logs','r6\logs','bin\x64\plugins\cyber_engine_tweaks')) {
        $folder = Join-Path $root $relative
        if (-not (Test-Path -LiteralPath $folder -PathType Container)) { continue }
        foreach ($file in @(Get-ChildItem -LiteralPath $folder -File -Recurse -Filter '*.log' -ErrorAction SilentlyContinue |
            Where-Object LastWriteTimeUtc -ge $SinceUtc.ToUniversalTime() |
            Sort-Object LastWriteTimeUtc -Descending | Select-Object -First 30)) {
            $logs.Add([pscustomobject]@{
                relativePath = [IO.Path]::GetRelativePath($root,$file.FullName).Replace('\','/')
                state = Get-BiologyAttendedFileState -Path $file.FullName -IncludeTail -TailLines 400 -MaxTailChars 32768
            })
        }
    }

    $crashes = [Collections.Generic.List[object]]::new()
    if (-not [string]::IsNullOrWhiteSpace($env:LOCALAPPDATA)) {
        $crashRoot = Join-Path $env:LOCALAPPDATA 'REDEngine\ReportQueue'
        if (Test-Path -LiteralPath $crashRoot -PathType Container) {
            foreach ($file in @(Get-ChildItem -LiteralPath $crashRoot -Recurse -File -Force -ErrorAction SilentlyContinue |
                Where-Object LastWriteTimeUtc -ge $SinceUtc.ToUniversalTime() |
                Sort-Object LastWriteTimeUtc -Descending | Select-Object -First 40)) {
                $textual = $file.Extension -in @('.txt','.log','.json','.xml')
                $crashes.Add([pscustomobject]@{
                    relativePath = [IO.Path]::GetRelativePath($crashRoot,$file.FullName).Replace('\','/')
                    bytes = [long]$file.Length
                    lastWriteUtc = $file.LastWriteTimeUtc.ToString('o')
                    sha256 = if ($file.Length -le 20MB) { Get-BiologyAttendedSha256 $file.FullName } else { $null }
                    textTail = if ($textual) { Get-BiologyAttendedBoundedTail -Path $file.FullName -TailLines 500 -MaxChars 65536 } else { $null }
                    note = if ($textual) { 'bounded textual crash evidence' } else { 'binary crash artifact fingerprint only' }
                })
            }
        }
    }

    $events = [Collections.Generic.List[object]]::new()
    $eventQuery = 'not available on this host'
    if (Get-Command Get-WinEvent -ErrorAction SilentlyContinue) {
        try {
            $records = @(Get-WinEvent -FilterHashtable @{LogName='Application';Id=@(1000,1001,1002);StartTime=$SinceUtc.ToLocalTime()} -MaxEvents 300 -ErrorAction Stop)
            foreach ($event in @($records | Where-Object { $_.Message -match '(?i)Cyberpunk2077\.exe' } | Select-Object -First 30)) {
                $message = [string]$event.Message
                if ($message.Length -gt 4000) { $message = $message.Substring(0,4000) }
                $events.Add([pscustomobject]@{ id=$event.Id; timeCreatedUtc=$event.TimeCreated.ToUniversalTime().ToString('o'); provider=$event.ProviderName; message=$message })
            }
            $eventQuery = 'complete; bounded Application crash/hang event query'
        } catch {
            if ($_.FullyQualifiedErrorId -match 'NoMatchingEventsFound') { $eventQuery = 'complete; no matching Application events' }
            else { $eventQuery = 'unavailable: ' + $_.Exception.Message }
        }
    }

    return [pscustomobject]@{
        sinceUtc = $SinceUtc.ToUniversalTime().ToString('o')
        logs = @($logs)
        crashArtifacts = @($crashes)
        windowsEvents = @($events)
        eventQuery = $eventQuery
    }
}

function Get-BiologyAttendedFileDelta([string]$Path,[long]$BaselineBytes,[int]$MaxBytes = 131072) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $null }
    $item = Get-Item -LiteralPath $Path
    $length = [long]$item.Length
    $start = if ($length -ge $BaselineBytes) { $BaselineBytes } else { [Math]::Max(0,$length - $MaxBytes) }
    if (($length - $start) -gt $MaxBytes) { $start = $length - $MaxBytes }
    $stream = [IO.File]::Open($Path,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::ReadWrite)
    try {
        [void]$stream.Seek($start,[IO.SeekOrigin]::Begin)
        $count = [int]($length - $start)
        if ($count -le 0) { return '' }
        $buffer = New-Object byte[] $count
        $read = $stream.Read($buffer,0,$count)
        return [Text.Encoding]::UTF8.GetString($buffer,0,$read)
    } finally { $stream.Dispose() }
}

function Compare-BiologyAttendedSnapshots($Before,$After) {
    $changes = [Collections.Generic.List[object]]::new()
    foreach ($name in @($Before.files.PSObject.Properties.Name | Sort-Object)) {
        $beforeFile = $Before.files.$name
        $afterFile = $After.files.$name
        if ($null -eq $beforeFile -and $null -eq $afterFile) { continue }
        $beforeExists = $null -ne $beforeFile -and [bool]$beforeFile.exists
        $afterExists = $null -ne $afterFile -and [bool]$afterFile.exists
        $beforeHash = if ($null -ne $beforeFile) { [string]$beforeFile.sha256 } else { $null }
        $afterHash = if ($null -ne $afterFile) { [string]$afterFile.sha256 } else { $null }
        $beforeBytes = if ($null -ne $beforeFile) { $beforeFile.bytes } else { $null }
        $afterBytes = if ($null -ne $afterFile) { $afterFile.bytes } else { $null }
        if ($beforeExists -ne $afterExists -or $beforeHash -ne $afterHash -or $beforeBytes -ne $afterBytes) {
            $changes.Add([pscustomobject]@{ name=$name; beforeExists=$beforeExists; afterExists=$afterExists; beforeBytes=$beforeBytes; afterBytes=$afterBytes; beforeSha256=$beforeHash; afterSha256=$afterHash })
        }
    }

    $redscriptDelta = $null
    $beforeLog = $Before.files.redscriptCurrentLog
    $afterLog = $After.files.redscriptCurrentLog
    if ($null -ne $afterLog -and [bool]$afterLog.exists) {
        $baseline = if ($null -ne $beforeLog -and [bool]$beforeLog.exists -and $null -ne $beforeLog.bytes) { [long]$beforeLog.bytes } else { 0L }
        $redscriptDelta = Get-BiologyAttendedFileDelta -Path ([string]$afterLog.path) -BaselineBytes $baseline -MaxBytes 131072
    }

    return [pscustomobject]@{
        changedFiles = @($changes)
        redscriptCurrentLogDelta = $redscriptDelta
    }
}

function Add-BiologyAttendedProcessObservation([Collections.Generic.List[object]]$Events,[hashtable]$Seen,[hashtable]$Active) {
    $now = [DateTime]::UtcNow
    $current = @{}
    foreach ($process in @(Get-Process -Name 'Cyberpunk2077' -ErrorAction SilentlyContinue)) {
        $pid = [int]$process.Id
        $current[$pid] = $true
        if (-not $Seen.ContainsKey($pid)) {
            $Seen[$pid] = $now
            $Active[$pid] = $now
            $Events.Add([pscustomobject]@{ event='START-OBSERVED'; pid=$pid; observedUtc=$now.ToString('o') })
        } elseif (-not $Active.ContainsKey($pid)) {
            $Active[$pid] = $now
        }
    }
    foreach ($pid in @($Active.Keys)) {
        if (-not $current.ContainsKey($pid)) {
            $started = [DateTime]$Active[$pid]
            $duration = [Math]::Round(($now - $started).TotalSeconds,3)
            $Events.Add([pscustomobject]@{ event='EXIT-OBSERVED'; pid=[int]$pid; observedUtc=$now.ToString('o'); observedDurationSeconds=$duration })
            $Active.Remove($pid)
        }
    }
}

function Get-BiologyAttendedLaunchClassification([object[]]$Events) {
    $starts = @($Events | Where-Object event -eq 'START-OBSERVED')
    $exits = @($Events | Where-Object event -eq 'EXIT-OBSERVED')
    if ($starts.Count -eq 0) { return 'NOT-OBSERVED' }
    if ($exits.Count -eq 0) { return 'START-OBSERVED-NO-EXIT' }
    $short = @($exits | Where-Object { $null -ne $_.observedDurationSeconds -and [double]$_.observedDurationSeconds -lt 15.0 })
    if ($short.Count -gt 0) { return 'STARTED-AND-EXITED-QUICKLY' }
    return 'STARTED-AND-EXITED'
}

function Invoke-BiologyAttendedQuietListener([int]$PollMilliseconds = 250) {
    $events = [Collections.Generic.List[object]]::new()
    $seen = @{}
    $active = @{}
    Write-Host 'READY TO LAUNCH CYBERPUNK' -ForegroundColor Green
    Write-Host 'Listener active. Leave this window open.'
    Write-Host 'After you have exited the game, return here and type END.'

    while ($true) {
        $inputTask = [Console]::In.ReadLineAsync()
        while (-not $inputTask.IsCompleted) {
            Add-BiologyAttendedProcessObservation -Events $events -Seen $seen -Active $active
            Start-Sleep -Milliseconds $PollMilliseconds
        }
        Add-BiologyAttendedProcessObservation -Events $events -Seen $seen -Active $active
        $command = [string]$inputTask.Result
        if (-not $command.Trim().Equals('END',[StringComparison]::OrdinalIgnoreCase)) {
            Write-Host 'Listener still active. Type END only after Cyberpunk has exited.'
            continue
        }
        if (@(Get-Process -Name 'Cyberpunk2077' -ErrorAction SilentlyContinue).Count -gt 0) {
            Write-Host 'Cyberpunk is still running. Close it, then type END again.' -ForegroundColor Yellow
            continue
        }
        break
    }

    Add-BiologyAttendedProcessObservation -Events $events -Seen $seen -Active $active
    return [pscustomobject]@{
        endedUtc = [DateTime]::UtcNow.ToString('o')
        classification = Get-BiologyAttendedLaunchClassification @($events)
        events = @($events)
    }
}

function Write-BiologyAttendedEvidenceBundle(
    [string]$BundlePath,
    [string]$EvidenceId,
    [string]$SourceRevision,
    [string]$Result,
    $RecordData,
    [string]$ReportText,
    $PreparationEvidence
) {
    $temp = Join-Path ([IO.Path]::GetTempPath()) ('biology-attended-evidence-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Force -Path $temp | Out-Null
    try {
        $reportPath = Join-Path $temp 'report.txt'
        [IO.File]::WriteAllText($reportPath,$ReportText,[Text.UTF8Encoding]::new($false))
        $reportHash = if (Get-Command Get-BiologyOperatorTextSha256 -ErrorAction SilentlyContinue) {
            Get-BiologyOperatorTextSha256 $reportPath
        } else {
            Get-BiologyAttendedSha256 $reportPath
        }
        $bundleName = [IO.Path]::GetFileName($BundlePath)
        $artifact = $null
        $recovery = [ordered]@{ mode='none'; eligible=$false }
        $cleanup = [ordered]@{ artifactRootName=$null; artifactZipName=$null; packageRootName=$null }
        $payloadManifest = $null
        if ($null -ne $PreparationEvidence) {
            if ($PreparationEvidence.PSObject.Properties.Name -contains 'artifact') { $artifact = $PreparationEvidence.artifact }
            if ($PreparationEvidence.PSObject.Properties.Name -contains 'recovery' -and $null -ne $PreparationEvidence.recovery) { $recovery = $PreparationEvidence.recovery }
            if ($PreparationEvidence.PSObject.Properties.Name -contains 'cleanup' -and $null -ne $PreparationEvidence.cleanup) { $cleanup = $PreparationEvidence.cleanup }
            if ($PreparationEvidence.PSObject.Properties.Name -contains 'payloadManifest') { $payloadManifest = $PreparationEvidence.payloadManifest }
        }
        $record = [ordered]@{
            schemaVersion = 1
            product = 'Biology'
            evidenceId = $EvidenceId
            operation = 'attended-test-session'
            createdUtc = [DateTime]::UtcNow.ToString('o')
            sourceRevision = $SourceRevision.ToLowerInvariant()
            result = $Result
            proofBoundary = 'Attended session evidence records exact candidate/source identity, bounded startup/runtime-adjacent diagnostics, process observations, and before/after state. It does not decide gameplay/UI acceptance for the owner.'
            game = $RecordData.game
            artifact = $artifact
            install = $RecordData.install
            recovery = $recovery
            cleanup = $cleanup
            handoff = [ordered]@{ bundleName=$bundleName; reportSha256=$reportHash }
            attendedSession = $RecordData.attendedSession
        }
        if ($null -ne $payloadManifest) { $record['payloadManifest'] = $payloadManifest }
        $record | ConvertTo-Json -Depth 40 | Set-Content -LiteralPath (Join-Path $temp 'evidence.json') -Encoding utf8
        if (Test-Path -LiteralPath $BundlePath) { Remove-Item -LiteralPath $BundlePath -Force }
        Compress-Archive -LiteralPath (Join-Path $temp 'evidence.json'),(Join-Path $temp 'report.txt') -DestinationPath $BundlePath -CompressionLevel Optimal
        if (-not (Test-Path -LiteralPath $BundlePath -PathType Leaf)) { throw 'Attended-session evidence bundle was not created.' }
        return $record
    } finally {
        if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Recurse -Force }
    }
}
