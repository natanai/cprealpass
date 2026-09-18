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
Write-Host 'Primary evidence is the installed official REDmod decompiled script tree.' -ForegroundColor DarkGray
Write-Host 'Read-only targeted symbol/signature evidence only; no game files are modified.' -ForegroundColor DarkGray

$contracts = @(
    [pscustomobject]@{
        path = 'cyberpunk/UI/Player/healthbar.script'
        patterns = @(
            '\bhealthbarWidgetGameController\b',
            '\bevent\s+OnInitialize\s*\('
        )
    },
    [pscustomobject]@{
        path = 'cyberpunk/UI/quests/quest_tracker.script'
        patterns = @(
            '\bclass\s+QuestTrackerGameController\b',
            '\bevent\s+OnInitialize\s*\(',
            '\bfunction\s+UpdateTrackerData\s*\('
        )
    },
    [pscustomobject]@{
        path = 'cyberpunk/UI/widgets/minimap/minimap.script'
        patterns = @(
            '\bMinimapContainerController\b',
            '\bevent\s+OnInitialize\s*\('
        )
    },
    [pscustomobject]@{
        path = 'cyberpunk/UI/weapons/weaponRoster.script'
        patterns = @(
            '\bWeaponRosterGameController\b',
            '\bevent\s+OnInitialize\s*\(',
            '\bfunction\s+SetRosterSlotData\s*\('
        )
    },
    [pscustomobject]@{
        path = 'cyberpunk/UI/widgets/dpad_hint/dpad_hint.script'
        patterns = @(
            '\bclass\s+HotkeysWidgetController\b',
            '\bevent\s+OnInitialize\s*\('
        )
    },
    [pscustomobject]@{
        path = 'cyberpunk/UI/weapons/crosshairs/crosshairContainerController.script'
        patterns = @(
            '\bgameuiCrosshairContainerController\b',
            '\bevent\s+OnInitialize\s*\('
        )
    },
    [pscustomobject]@{
        path = 'cyberpunk/UI/weapons/crosshairs/crosshairBaseControllers.script'
        patterns = @(
            '\bgameuiCrosshairBaseGameController\b',
            '\bevent\s+OnInitialize\s*\(',
            '\bfunction\s+OnCrosshairStateChange\s*\(',
            '\bfunction\s+OnState_Scanning\s*\('
        )
    },
    [pscustomobject]@{
        path = 'cyberpunk/UI/interactions/interactionsUI.script'
        patterns = @(
            '\bclass\s+interactionWidgetGameController\b',
            '\bevent\s+OnInitialize\s*\(',
            '\bevent\s+OnUpdateInteraction\s*\('
        )
    },
    [pscustomobject]@{
        path = 'cyberpunk/UI/activityLog/activityLogControllers.script'
        patterns = @(
            '\bclass\s+activityLogEntryLogicController\b',
            '\bevent\s+OnInitialize\s*\(',
            '\bfunction\s+SetText\s*\('
        )
    },
    [pscustomobject]@{
        path = 'cyberpunk/UI/widgets/healthbar/nameplateVisuals.script'
        patterns = @(
            '\bclass\s+NameplateVisualsLogicController\b',
            '\bm_nameTextMain\b',
            '\bm_nameFrame\b',
            '\bfunction\s+SetElementVisibility\s*\(',
            '\bfunction\s+IsAnyElementVisible\s*\(',
            '\bfunction\s+IsQuestTarget\s*\('
        )
    },
    [pscustomobject]@{
        path = 'cyberpunk/UI/widgets/healthbar/npcNamePlate.script'
        patterns = @(
            '\bNpcNameplateGameController\b',
            '\bm_displayName\b',
            '\bc_DisplayRangeNotAggressive\b',
            '\bc_MaxDisplayRangeNotAggressive\b',
            '\bevent\s+OnInitialize\s*\(',
            '\bevent\s+OnScreenProjectionUpdate\s*\(',
            '\bSNameplateRangesData\.GetDisplayRangeNotAggressive\s*\(',
            '\bSNameplateRangesData\.GetMaxDisplayRangeNotAggressive\s*\('
        )
    },
    [pscustomobject]@{
        path = 'cyberpunk/UI/weapons/crosshairs/ironsight.script'
        patterns = @(
            '\bclass\s+IronsightGameController\b'
        )
    }
)

$hits = [Collections.Generic.List[object]]::new()
foreach ($contract in $contracts) {
    $fullPath = Join-Path $scriptRoot $contract.path
    if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
        throw "Required installed presentation source missing: $($contract.path)"
    }

    foreach ($pattern in $contract.patterns) {
        $matches = @(Select-String -LiteralPath $fullPath -Pattern $pattern -AllMatches -ErrorAction Stop)
        if ($matches.Count -eq 0) {
            throw "Expected presentation symbol/signature not found in $($contract.path): $pattern"
        }

        foreach ($match in $matches) {
            $line = $match.Line.Trim()
            if ($line.Length -gt 300) { $line = $line.Substring(0,300) + ' ...' }
            $hits.Add([pscustomobject]@{
                path = $contract.path
                lineNumber = $match.LineNumber
                text = $line
            })
        }
    }
}

$deduped = @($hits | Sort-Object path,lineNumber,text -Unique)
Write-Host "Targeted presentation symbol hits: $($deduped.Count)"
foreach ($hit in $deduped) {
    Write-Host ("  {0}:{1}  {2}" -f $hit.path,$hit.lineNumber,$hit.text)
}

Write-Host ''
Write-Host 'PASS: all W03.4 current-controller, crosshair-state, and nameplate-lifecycle contracts were found in the installed official REDmod script tree.' -ForegroundColor Green
