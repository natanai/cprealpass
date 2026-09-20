param(
    [string]$GameRoot = 'C:\Games\Steam\steamapps\common\Cyberpunk 2077',
    [datetime]$SinceUtc = [DateTime]::UtcNow.AddDays(-2),
    [string]$Reason = 'manual review'
)
. "$PSScriptRoot\Common.ps1"
$GameRoot=Assert-GameRoot $GameRoot
$project=Get-ProjectRoot
$baseline=Get-Content -Raw (Join-Path $project 'manifest\baseline.json') | ConvertFrom-Json
$stamp=[DateTime]::UtcNow.ToString('yyyyMMdd-HHmmss')+'-'+[guid]::NewGuid().ToString('N').Substring(0,8)
$destination=Join-Path $project "logs\diagnostics-$stamp"
New-Item -ItemType Directory -Force -Path $destination | Out-Null
$issues=[Collections.Generic.List[string]]::new()
function Copy-DiagnosticFile([string]$Source,[string]$Relative,[long]$Limit=20971520){
    $item=Get-Item -LiteralPath $Source
    $target=Resolve-SafeChildPath $destination $Relative
    if($item.Length -gt $Limit){return [ordered]@{source=$Source;length=$item.Length;copied=$false;reason='Size cap; original remains available locally.'}}
    try{
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $target) | Out-Null
        Copy-Item -LiteralPath $Source -Destination $target
        return [ordered]@{source=$Source;length=$item.Length;copied=$true;copiedTo=$target;modifiedAtUtc=$item.LastWriteTimeUtc.ToString('o')}
    }catch{$issues.Add($_.Exception.Message);return [ordered]@{source=$Source;copied=$false;reason=$_.Exception.Message}}
}
$receiptPath=Join-Path $project 'snapshots\deployment-state\current.json'
$receipt=if(Test-Path $receiptPath){Get-Content -Raw $receiptPath | ConvertFrom-Json}else{$null}
if($receipt){Copy-Item -LiteralPath $receiptPath -Destination (Join-Path $destination 'deployment-receipt.json')}
Copy-Item -LiteralPath (Join-Path $project 'manifest\deployment.json') -Destination (Join-Path $destination 'deployment-manifest.json')
$critical=@(foreach($f in $baseline.criticalFiles){
    $actual=Get-ExistingHash (Resolve-SafeChildPath $GameRoot $f.path)
    [ordered]@{path=$f.path;expected=$f.sha256;actual=$actual;matchesBaseline=($actual -eq $f.sha256)}
})
$logs=@(foreach($relative in @('red4ext\logs','red4ext\plugins','r6\logs','bin\x64\plugins\cyber_engine_tweaks')){
    $folder=Resolve-SafeChildPath $GameRoot $relative
    if(-not(Test-Path -LiteralPath $folder)){continue}
    foreach($file in Get-ChildItem -LiteralPath $folder -File -Recurse -Filter '*.log' | Where-Object LastWriteTimeUtc -ge $SinceUtc | Sort-Object LastWriteTimeUtc -Descending | Select-Object -First 30){
        $rel=$file.FullName.Substring($GameRoot.Length+1)
        $copy=Copy-DiagnosticFile (Resolve-SafeChildPath $GameRoot $rel) ('game\'+$rel)
        $signals=if($copy.copied){@(Get-Content -LiteralPath $copy.copiedTo -Tail 2000 | Select-String -Pattern '\b(error|fatal|failed|exception|warning|warn)\b' | ForEach-Object Line)}else{@()}
        [ordered]@{path=$rel;capture=$copy;reviewSignals=$signals}
    }
})
$crashRoot=Join-Path $env:LOCALAPPDATA 'REDEngine\ReportQueue'
$crashes=@(if(Test-Path -LiteralPath $crashRoot){
    foreach($file in Get-ChildItem -LiteralPath $crashRoot -Recurse -File -Force | Where-Object LastWriteTimeUtc -ge $SinceUtc | Sort-Object LastWriteTimeUtc -Descending | Select-Object -First 80){
        $relative=$file.FullName.Substring($crashRoot.Length+1)
        if($file.Extension -in @('.txt','.log','.json','.xml')){Copy-DiagnosticFile (Resolve-SafeChildPath $crashRoot $relative) ('engine-crash\'+$relative) 2097152}
        else{[ordered]@{source=$file.FullName;length=$file.Length;copied=$false;reason='Binary crash artifact retained at original local path.'}}
    }
})
$events=@()
$eventQuery='not run'
try{
    $records=@(Get-WinEvent -FilterHashtable @{LogName='Application';Id=@(1000,1001,1002);StartTime=$SinceUtc.ToLocalTime()} -MaxEvents 300 -ErrorAction Stop)
    $events=@($records | Where-Object {$_.Message -match '(?i)Cyberpunk2077\.exe'} | ForEach-Object {[ordered]@{id=$_.Id;timeCreatedUtc=$_.TimeCreated.ToUniversalTime().ToString('o');provider=$_.ProviderName;message=$_.Message}})
    $eventQuery='complete; last 300 matching event IDs inspected'
}catch{
    if($_.FullyQualifiedErrorId -match 'NoMatchingEventsFound'){$eventQuery='complete; no matching event IDs'}
    else{$eventQuery='unavailable: '+$_.Exception.Message}
}
$report=[ordered]@{capturedAtUtc=[DateTime]::UtcNow.ToString('o');reason=$Reason;sinceUtc=$SinceUtc.ToUniversalTime().ToString('o');gameRoot=$GameRoot;running=[bool](Get-Process Cyberpunk2077 -ErrorAction SilentlyContinue);buildId=$(if($receipt){$receipt.buildId}else{$null});deploymentStatus=$(if($receipt){$receipt.status}else{$null});criticalFiles=$critical;logs=$logs;engineCrashArtifacts=$crashes;windowsCrashEvents=$events;eventQuery=$eventQuery;captureIssues=@($issues);bundlePath=$destination;runtimeVerdict='REQUIRES REVIEW: absence of errors is not proof of correct gameplay; process exit alone is not classified as a crash.'}
$path=Join-Path $project "reports\diagnostics-$stamp.json"
Write-JsonFile $report $path
Write-JsonFile $report (Join-Path $destination 'summary.json')
Write-Host "Diagnostics: $path. $($logs.Count) logs, $($crashes.Count) crash artifacts, $($events.Count) relevant Windows events."
