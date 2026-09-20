param([string]$GameRoot='C:\Games\Steam\steamapps\common\Cyberpunk 2077')
. "$PSScriptRoot\Common.ps1"
$project = Get-ProjectRoot
$GameRoot = Assert-GameRoot $GameRoot
$preset = Get-Content -Raw (Join-Path $project 'config/body-alpha1.json') | ConvertFrom-Json
$iniPath = Resolve-SafeChildPath $GameRoot 'red4ext/plugins/mod_settings/user.ini'
if (-not (Test-Path -LiteralPath $iniPath)) { throw 'No persisted Mod Settings file yet.' }
$values = @{}
$section = ''
$iniText = [IO.File]::ReadAllText($iniPath)
foreach ($line in ($iniText -split '\r?\n')) {
    if ($line -match '^\s*\[([^]]+)\]\s*$') { $section=$Matches[1];continue }
    if ($section -ne 'DarkFuture.Settings.DFSettings' -or $line -notmatch '^\s*([^=;#]+?)\s*=\s*(.*?)\s*$') { continue }
    $name=$Matches[1];$value=$Matches[2]
    if ($values.ContainsKey($name)) { throw "Duplicate Dark Future setting: $name" }
    $values[$name]=$value
}
$results = @(foreach ($setting in $preset.settings) {
    $expected = [string]$setting.value
    if ($expected -match '^DF\w+\.(\w+)$') { $expected=$Matches[1] }
    $actual = if ($values.ContainsKey($setting.name)) { $values[$setting.name] } else { $null }
    [double]$expectedNumber=0
    [double]$actualNumber=0
    $numeric = [double]::TryParse($expected,[Globalization.NumberStyles]::Float,[Globalization.CultureInfo]::InvariantCulture,[ref]$expectedNumber)
    $matchesValue = if ($numeric) { $null -ne $actual -and [double]::TryParse($actual,[Globalization.NumberStyles]::Float,[Globalization.CultureInfo]::InvariantCulture,[ref]$actualNumber) -and [Math]::Abs($actualNumber-$expectedNumber) -lt 0.00001 } else { $null -ne $actual -and $actual -eq $expected }
    [ordered]@{name=$setting.name;expected=$expected;saved=$actual;matches=$matchesValue}
})
$context = @(foreach ($name in @('showHUDUI','compatibilityProjectE3HUD','compatibilityProjectE3UI','timescale','limitedEnergySleepingInVehicles')) { [ordered]@{name=$name;saved=$(if($values.ContainsKey($name)){$values[$name]}else{$null})} })
$report = [ordered]@{auditedAtUtc=[DateTime]::UtcNow.ToString('o');preset=$preset.id;sourcePath=$iniPath;sourceSha256=(Get-Sha256 $iniPath);allPresetValuesMatch=(@($results | Where-Object {-not $_.matches}).Count -eq 0);settings=$results;context=$context;scope='Persisted settings snapshot only; does not inspect unsaved in-game values or measure the real world-clock ratio.'}
$path=Join-Path $project 'reports/body-saved-settings.json'
Write-JsonFile $report $path
Write-Host "Compared $($results.Count) saved preset values. All match: $($report.allPresetValuesMatch). Report: $path"
if(-not $report.allPresetValuesMatch){$results | Where-Object {-not $_.matches} | ForEach-Object {[pscustomobject]$_}}
