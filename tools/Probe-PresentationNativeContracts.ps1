[CmdletBinding()]
param(
    [string]$GamePath = 'C:\Games\Steam\steamapps\common\Cyberpunk 2077'
)

$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'Probe-PresentationNativeContracts.ps1 requires PowerShell 7 or newer.' }

$GamePath = [IO.Path]::GetFullPath($GamePath)
$scriptRoot = Join-Path $GamePath 'tools\redmod\scripts'
if (-not (Test-Path -LiteralPath $scriptRoot -PathType Container)) {
    throw "Official REDmod decompiled script tree not found: $scriptRoot"
}

Write-Host ''
Write-Host '=== Supported-install presentation native-contract probe ===' -ForegroundColor Cyan
Write-Host "Script source: $scriptRoot" -ForegroundColor DarkGray
Write-Host 'Read-only symbol/signature evidence only; no game files are modified.' -ForegroundColor DarkGray

$patterns = @(
    '\bclass\s+MinimapContainerController\b',
    '\bclass\s+IronsightGameController\b',
    '\bclass\s+QuestTrackerGameController\b',
    '\bclass\s+WeaponRosterGameController\b',
    '\bclass\s+HotkeysWidgetController\b',
    '\bclass\s+CrosshairGameController_Tech_Hex\b',
    '\bclass\s+NpcNameplateGameController\b',
    '\bclass\s+NameplateVisualsLogicController\b',
    '\bfunc\s+OnCompassUpdate\s*\(',
    '\bfunc\s+OnPlayerAttach\s*\(',
    '\bfunc\s+GetQuestMappin\s*\(',
    '\bfunc\s+GetPOIMappin\s*\(',
    '\bfunc\s+UpdateTrackerData\s*\(',
    '\bfunc\s+SetRosterSlotData\s*\(',
    '\bfunc\s+OnScreenProjectionUpdate\s*\(',
    '\bm_displayName\b',
    '\bm_nameTextMain\b',
    '\bm_nameFrame\b'
)

# REDmod's official decompiled game sources are .script files. Tolerate .reds too so
# the probe remains useful if a supported toolchain starts exposing redscript copies.
$files = @(Get-ChildItem -LiteralPath $scriptRoot -Recurse -File | Where-Object {
    $_.Extension -in @('.script','.reds')
})
if ($files.Count -eq 0) { throw "No .script/.reds files found under official REDmod script tree: $scriptRoot" }

$hits = [Collections.Generic.List[object]]::new()
foreach ($file in $files) {
    foreach ($match in @(Select-String -LiteralPath $file.FullName -Pattern $patterns -AllMatches -ErrorAction Stop)) {
        $relative = [IO.Path]::GetRelativePath($scriptRoot, $file.FullName).Replace('\','/')
        $line = $match.Line.Trim()
        if ($line.Length -gt 300) { $line = $line.Substring(0,300) + ' ...' }
        $hits.Add([pscustomobject]@{
            path = $relative
            lineNumber = $match.LineNumber
            text = $line
        })
    }
}

if ($hits.Count -eq 0) {
    throw 'No expected presentation controller/symbol evidence found in the official REDmod script tree.'
}

$deduped = @($hits | Sort-Object path,lineNumber,text -Unique)
Write-Host "Presentation symbol hits: $($deduped.Count)"
foreach ($hit in $deduped) {
    Write-Host ("  {0}:{1}  {2}" -f $hit.path,$hit.lineNumber,$hit.text)
}

$minimapContainerFound = @($deduped | Where-Object { $_.text -match '\bclass\s+MinimapContainerController\b' }).Count -gt 0
$ironsightFound = @($deduped | Where-Object { $_.text -match '\bclass\s+IronsightGameController\b' }).Count -gt 0

Write-Host ''
Write-Host "MinimapContainerController found: $minimapContainerFound"
Write-Host "IronsightGameController found:    $ironsightFound"
Write-Host 'PASS: current installed REDmod script sources yielded presentation controller/signature evidence.' -ForegroundColor Green
