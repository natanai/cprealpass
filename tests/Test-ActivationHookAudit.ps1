$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\tools\Common.ps1"
$project = Get-ProjectRoot
$audit = Get-Content -Raw (Join-Path $project 'manifest/activation-hook-audit.json') | ConvertFrom-Json
$expected = @{}
foreach ($entry in $audit.hooks) {
    $key = "$($entry.source)|$($entry.kind)|$($entry.owner)|$($entry.method)"
    if ($expected.ContainsKey($key) -or -not $entry.activationRoute) { throw "Invalid/duplicate activation review: $key" }
    $expected[$key] = $true
}
$actual = @{}
foreach ($file in Get-ChildItem (Join-Path $project 'src/redscript/CyberpunkRealism') -Filter *.reds) {
    $source = Get-Content -Raw $file.FullName
    foreach ($match in [regex]::Matches($source,'@(?<kind>wrapMethod|replaceMethod|addMethod)\((?<owner>\w+)\)\s*(?:public|protected|private)[^\r\n]*?\bfunc\s+(?<method>\w+)\(')) {
        $kind=$match.Groups['kind'].Value; $method=$match.Groups['method'].Value
        if ($kind -eq 'addMethod' -and $method -notmatch '^On') { continue }
        if ($kind -eq 'replaceMethod') { throw "Whole native method replacement requires a new compatibility review: $($file.Name)" }
        $key="$($file.Name)|$kind|$($match.Groups['owner'].Value)|$method"
        if (-not $expected.ContainsKey($key) -or $actual.ContainsKey($key)) { throw "Unreviewed/duplicate native entry point: $key" }
        $actual[$key]=$true
    }
}
if ($actual.Count -ne $expected.Count) { throw 'Activation review includes stale/missing production entries.' }

# Source ordering guard for the OFF-state regression: restore Biology's previous
# style before native mutation, then capture fresh native state only on E3 apply.
$ordered = @(
    @('E3CrosshairHudNative.reds','OnCrosshairStateChange','CRRestoreBiologyE3CrosshairTint'),
    @('E3ActivityHudNative.reds','SetText','CRRestoreBiologyE3Activity'),
    @('E3WeaponHudNative.reds','SetRosterSlotData','CRRestoreBiologyE3WeaponTints'),
    @('E3QuestHudNative.reds','UpdateTrackerData','CRRestoreBiologyE3QuestStyle')
)
foreach ($row in $ordered) {
    $source=Get-Content -Raw (Join-Path $project ('src/redscript/CyberpunkRealism/'+$row[0]))
    $method=[regex]::Match($source,'(?s)\bfunc '+$row[1]+'\([^\r\n]+\{(?<body>.*?)\n\}')
    $restore=$method.Groups['body'].Value.IndexOf('this.'+$row[2]+'();')
    $native=$method.Groups['body'].Value.IndexOf('wrappedMethod(')
    if (-not $method.Success -or $restore -lt 0 -or $native -le $restore) { throw "E3 restoration no longer precedes native update: $($row[0])" }
}
$actions=Get-Content -Raw (Join-Path $project 'src/redscript/CyberpunkRealism/BiologyActionsNative.reds')
$care=Get-Content -Raw (Join-Path $project 'src/redscript/CyberpunkRealism/FieldCareActionRuntime.reds')
if ($actions -match 'CRBodyRuntime.Get\(\)|CRConditionPresentation.Current\(' -or $care -match 'CRBodyRuntime.Get\(\)') { throw 'Care/action path lost explicit native session ownership.' }
Write-Host "PASS: $($actual.Count) reviewed native entry points plus E3 native-update ordering and care session guards."
