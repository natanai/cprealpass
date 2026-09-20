param([string]$ManifestPath='manifest/m3-body-alpha2.deployment.json')
. "$PSScriptRoot\..\tools\Common.ps1"
$project = Get-ProjectRoot
$manifest = Get-Content -Raw (Resolve-SafeChildPath $project $ManifestPath) | ConvertFrom-Json
$base = Get-Content -Raw (Join-Path $project 'manifest/m3-body-alpha1.deployment.json') | ConvertFrom-Json
$destination = 'r6/scripts/Dark Future/Needs/DFNeedSystemEnergy.reds'
$beforeFile = $base.files | Where-Object destination -eq $destination
$afterFile = $manifest.files | Where-Object destination -eq $destination
$beforePath = Resolve-SafeChildPath $project $beforeFile.source
$afterPath = Resolve-SafeChildPath $project $afterFile.source
if ((Get-Sha256 $beforePath) -ne '233287D821D9D3F15BE2FBA1AC16EE1B5D3A05C6A6549986B76760A0E3E82D62') { throw 'Expected pinned original energy source.' }
if ((Get-Sha256 $afterPath) -ne $afterFile.sha256) { throw 'Candidate source hash mismatch.' }
$work = Join-Path $project ('staging\sleep-tests-'+[guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $work | Out-Null
function Extract-MethodBody([string]$Text,[string]$Name) {
    $pattern = '(?s)public final func '+[regex]::Escape($Name)+'\([^)]*\) -> Float \{(?<body>.*?)\r?\n\t\}'
    $matches = [regex]::Matches($Text,$pattern)
    if ($matches.Count -ne 1) { throw "Expected one pure method: $Name" }
    $body = $matches[0].Groups['body'].Value
    $body = [regex]::Replace($body,'(?m)//[^\r\n]*','')
    $body = [regex]::Replace($body,'let (\w+): Float;', 'float $1 = 0.0f;')
    $body = [regex]::Replace($body,'(?m)^(\s*)if (.+) \{', '$1if ($2) {')
    $body = [regex]::Replace($body,'switch (\w+) \{', 'switch ($1) {')
    $body = [regex]::Replace($body,'\b(\d+\.\d+)\b(?!f)', '${1}f')
    $body
}
# Execute the actual extracted arithmetic as C# float32. Only type/control-flow
# syntax is translated; expressions and branches come from the source.
# This checks math, not REDengine scheduling or save state.
function Make-Harness([string]$Path,[string]$Name) {
    $text = Get-Content -Raw -LiteralPath $Path
    $evaluate = Extract-MethodBody $text 'GetEnergyChangeWithRecoverLimit'
    $loss = Extract-MethodBody $text 'GetEnergyChange'
    $recover = [regex]::Match($text,'energyRecoverAmountSleeping: Float = ([0-9.]+);')
    if (-not $recover.Success) { throw 'Sleep recovery constant missing.' }
    @"
public class $Name {
    public SleepSettings Settings = new SleepSettings();
    private float energyRecoverAmountSleeping = $($recover.Groups[1].Value)f;
    private bool DFIsSleeping(DFTimeSkipType mode) { return mode != DFTimeSkipType.Wait; }
    public float GetEnergyChange() { $loss }
    public float Evaluate(float energyValue, DFTimeSkipType timeSkipType) { $evaluate }
}
"@
}
$code = 'public enum DFTimeSkipType { Wait, FullSleep, LimitedSleep } public class SleepSettings { public float limitedEnergySleepingInVehicles = 70f; public float energyLossRatePct = 60f; }'
$code += (Make-Harness $beforePath 'OriginalSleepMath') + (Make-Harness $afterPath 'PatchedSleepMath')
Set-Content -LiteralPath (Join-Path $work 'ExtractedSleepMath.cs') -Value $code -Encoding utf8
Add-Type -TypeDefinition $code
$original = [OriginalSleepMath]::new()
$patched = [PatchedSleepMath]::new()
$script:checks = 0
function Assert-True($Condition,$Message) { if(-not $Condition){throw $Message};$script:checks++ }
$bugBefore = $original.Evaluate(70.05,[DFTimeSkipType]::LimitedSleep)
$bugAfter = $patched.Evaluate(70.05,[DFTimeSkipType]::LimitedSleep)
Assert-True ($bugBefore -gt 0) 'Original regression case no longer reproduces the positive overshoot.'
Assert-True ($bugAfter -lt 0 -and [Math]::Abs((70.05+$bugAfter)-70.0) -lt 0.00001) 'Fixed step does not settle at the recovery limit.'
foreach ($limit in @(0,20,70,100)) {
    foreach ($rate in @(0,60,100,200)) {
        $original.Settings.limitedEnergySleepingInVehicles = $limit
        $patched.Settings.limitedEnergySleepingInVehicles = $limit
        $original.Settings.energyLossRatePct = $rate
        $patched.Settings.energyLossRatePct = $rate
        foreach ($energy in (@(0..100) + @(19.99,20.01,69.99,70.01,70.05,99.99))) {
            $step = $patched.Evaluate($energy,[DFTimeSkipType]::LimitedSleep)
            $next = $energy+$step
            if ($energy -gt $limit) {
                Assert-True ($step -le 0 -and $next -ge ($limit-0.00001) -and $next -le ($energy+0.00001)) 'Limited sleep increased energy above its cap or crossed below it.'
            } else {
                Assert-True ($step -ge 0 -and $next -le ($limit+0.00001)) 'Sleep recovery crossed its cap.'
            }
            Assert-True ($patched.Evaluate($energy,[DFTimeSkipType]::FullSleep) -eq $original.Evaluate($energy,[DFTimeSkipType]::FullSleep)) 'Ordinary bed sleep changed.'
            Assert-True ($patched.Evaluate($energy,[DFTimeSkipType]::Wait) -eq $original.Evaluate($energy,[DFTimeSkipType]::Wait)) 'Awake depletion changed.'
        }
    }
}
$patched.Settings.limitedEnergySleepingInVehicles = 70
$patched.Settings.energyLossRatePct = 60
[float]$energy = 70.05
for ($i=0;$i -lt 24;$i++) { $energy += $patched.Evaluate($energy,[DFTimeSkipType]::LimitedSleep) }
Assert-True ([Math]::Abs($energy-70.0) -lt 0.00001) 'Repeated sleep steps oscillated at the ceiling.'
$changed = @($manifest.files | Where-Object { $f=$_; ($base.files | Where-Object destination -eq $f.destination).sha256 -ne $f.sha256 })
Assert-True ($manifest.files.Count -eq $base.files.Count -and $changed.Count -eq 1 -and $changed[0].destination -eq $destination) 'Candidate contains unrelated payload changes.'
$report = [ordered]@{testedAtUtc=[DateTime]::UtcNow.ToString('o');buildId=$manifest.buildId;passed=$true;assertions=$script:checks;originalBugDelta=$bugBefore;patchedDelta=$bugAfter;sourceSha256=$beforeFile.sha256;patchedSha256=$afterFile.sha256;fixture=$work;method='Actual method bodies translated from redscript syntax to C# float32 and executed; full profile compiled separately with redscript CLI.';runtime='Not run; no game or background recorder launched.'}
Write-JsonFile $report (Join-Path $project 'reports/sleep-clamp-tests.json')
Write-Host "PASS: $script:checks sleep arithmetic checks. Original delta $bugBefore; fixed delta $bugAfter."
