#requires -Version 7.0
[CmdletBinding()]
param(
    [string]$GamePath = 'C:\Games\Steam\steamapps\common\Cyberpunk 2077',
    [string]$ReportPath
)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/Common.ps1"
$project = Get-ProjectRoot
$GamePath = [IO.Path]::GetFullPath($GamePath)
$archiveRoot = Join-Path $GamePath 'archive\pc'
$oodleSource = Join-Path $GamePath 'bin\x64\oo2ext_7_win64.dll'

if (-not (Test-Path -LiteralPath $archiveRoot -PathType Container)) {
    throw "Cyberpunk archive root not found: $archiveRoot"
}
$archiveFiles = @(
    Get-ChildItem -LiteralPath $archiveRoot -Recurse -File -Filter '*.archive' -ErrorAction Stop |
        Sort-Object FullName
)
if ($archiveFiles.Count -eq 0) {
    throw "No Cyberpunk .archive files found recursively under: $archiveRoot"
}
if (-not (Test-Path -LiteralPath $oodleSource -PathType Leaf)) {
    throw "Cyberpunk Oodle library not found: $oodleSource"
}

$stamp = [DateTime]::Now.ToString('yyyyMMdd-HHmmss') + '-' + [guid]::NewGuid().ToString('N').Substring(0,8)
if ([string]::IsNullOrWhiteSpace($ReportPath)) {
    $ReportPath = Join-Path $project "reports\biology-w02-4-native-region-$stamp.txt"
} elseif (-not [IO.Path]::IsPathRooted($ReportPath)) {
    $ReportPath = Join-Path $project $ReportPath
}
$ReportPath = [IO.Path]::GetFullPath($ReportPath)
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $ReportPath) | Out-Null

$workRoot = Join-Path $project "game-reference\extracted\w02-4-native-region-$stamp"
$extractRoot = Join-Path $workRoot 'cr2w'
$jsonRoot = Join-Path $workRoot 'json'
New-Item -ItemType Directory -Force -Path $extractRoot,$jsonRoot | Out-Null

$report = [Collections.Generic.List[string]]::new()
function Add-Report([string]$Text = '') {
    $script:report.Add($Text)
    Write-Host $Text
}

function Invoke-Captured([string]$Label,[string]$Exe,[string[]]$Arguments) {
    Add-Report ''
    Add-Report "=== $Label ==="
    Add-Report ("COMMAND: " + $Exe + " " + ($Arguments -join ' '))
    $output = @(& $Exe @Arguments 2>&1)
    $exitCode = $LASTEXITCODE
    foreach ($line in $output) {
        $text = [string]$line
        if ($text.Length -gt 600) {
            $text = $text.Substring(0,600) + ' ...'
        }
        Add-Report $text
    }
    Add-Report "EXIT_CODE=$exitCode"
    if ($exitCode -ne 0) {
        throw "$Label failed with exit code $exitCode"
    }
    return @($output | ForEach-Object { [string]$_ })
}

$createdLocalOodle = $false
$localOodle = Join-Path ([Environment]::GetFolderPath([Environment+SpecialFolder]::LocalApplicationData)) 'oo2ext_7_win64.dll'
$sourceOodleHash = Get-Sha256 $oodleSource
$probeSucceeded = $false

try {
    Add-Report 'BIOLOGY W02.4 NATIVE DETAIL REGION PROBE'
    Add-Report "Generated: $([DateTime]::Now.ToString('o'))"
    Add-Report "GamePath: $GamePath"
    Add-Report "ArchiveRoot: $archiveRoot"
    Add-Report "ArchiveFiles: $($archiveFiles.Count)"
    foreach ($archiveFile in $archiveFiles) {
        Add-Report ("ARCHIVE: " + [IO.Path]::GetRelativePath($archiveRoot,$archiveFile.FullName))
    }
    Add-Report "GameOodleSHA256: $sourceOodleHash"
    Add-Report 'TargetResource: gameplay\gui\fullscreen\ripperdoc\ripperdoc.inkwidget'
    Add-Report 'Purpose: identify the actual CP2077 2.31 INK child/layout geometry behind RipperdocInventoryController content.'
    Add-Report 'Mutation boundary: read-only game archives; temporary local extraction only.'

    if (-not (Test-Path -LiteralPath $localOodle -PathType Leaf)) {
        Copy-Item -LiteralPath $oodleSource -Destination $localOodle
        if ((Get-Sha256 $localOodle) -ne $sourceOodleHash) {
            throw 'Temporary Oodle copy hash mismatch.'
        }
        $createdLocalOodle = $true
        Add-Report "TemporaryOodleCopyCreated: $localOodle"
    } else {
        Add-Report "ExistingLocalOodlePreserved: $localOodle"
    }

    $toolchain = & (Join-Path $PSScriptRoot 'Acquire-ArchiveToolchain.ps1')
    $dotnet = [string]$toolchain.dotnetExe
    $cli = [string]$toolchain.cliDll
    Add-Report "WolvenKitCLI: $cli"
    Add-Report "WolvenKitCLISHA256: $($toolchain.cliDllSha256)"

    $resourceRegex = '(?i)^gameplay[\\/]gui[\\/]fullscreen[\\/]ripperdoc[\\/]ripperdoc\.inkwidget

    $resourcePaths = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($line in $archiveOutput) {
        foreach ($match in [regex]::Matches($line,'(?i)([A-Za-z0-9_./\\-]*ripperdoc[A-Za-z0-9_./\\-]*\.inkwidget)')) {
            $null = $resourcePaths.Add($match.Groups[1].Value.Replace('/','\'))
        }
    }

    Add-Report ''
    Add-Report "MATCHED_RESOURCE_PATHS=$($resourcePaths.Count)"
    foreach ($path in @($resourcePaths | Sort-Object)) {
        Add-Report "RESOURCE: $path"
    }
    if ($resourcePaths.Count -ne 1) {
        throw "Expected exactly one installed Ripperdoc fullscreen .inkwidget resource; found $($resourcePaths.Count)."
    }

    $unbundleArguments = [Collections.Generic.List[string]]::new()
    $unbundleArguments.Add($cli)
    $unbundleArguments.Add('unbundle')
    foreach ($archiveFile in $archiveFiles) {
        $unbundleArguments.Add($archiveFile.FullName)
    }
    $unbundleArguments.Add('--outpath')
    $unbundleArguments.Add($extractRoot)
    $unbundleArguments.Add('--regex')
    $unbundleArguments.Add($resourceRegex)
    Invoke-Captured 'EXTRACT RIPPERDOC FULLSCREEN INKWIDGET' $dotnet $unbundleArguments.ToArray() | Out-Null

    $extracted = @(Get-ChildItem -LiteralPath $extractRoot -Recurse -File -Filter '*.inkwidget')
    Add-Report ''
    Add-Report "EXTRACTED_INKWIDGETS=$($extracted.Count)"
    foreach ($file in $extracted) {
        Add-Report ("EXTRACTED: " + [IO.Path]::GetRelativePath($extractRoot,$file.FullName) + " SHA256=" + (Get-Sha256 $file.FullName))
    }
    if ($extracted.Count -ne 1) {
        throw "Expected exactly one extracted Ripperdoc fullscreen .inkwidget; found $($extracted.Count)."
    }

    Invoke-Captured 'SERIALIZE RIPPERDOC INKWIDGET TO JSON' $dotnet @(
        $cli,'convert','serialize',$extractRoot,'--outpath',$jsonRoot,'--pattern','*.inkwidget'
    ) | Out-Null

    $jsonFiles = @(Get-ChildItem -LiteralPath $jsonRoot -Recurse -File -Filter '*.json')
    Add-Report ''
    Add-Report "SERIALIZED_JSON_FILES=$($jsonFiles.Count)"
    if ($jsonFiles.Count -eq 0) {
        throw 'No JSON was produced from the extracted Ripperdoc .inkwidget resource.'
    }

    $needles = @(
        'RipperdocInventoryController',
        'inventoryViewAnchor',
        'virtualGridContainer',
        'scrollBarContainer',
        'labelPrefix',
        'labelSuffix',
        'item_area_extended'
    )

    $relevantFiles = 0
    foreach ($file in $jsonFiles) {
        $raw = Get-Content -Raw -LiteralPath $file.FullName
        $fileRelevant = $false
        foreach ($needle in $needles) {
            if ($raw.IndexOf($needle,[StringComparison]::OrdinalIgnoreCase) -ge 0) {
                $fileRelevant = $true
                break
            }
        }
        if (-not $fileRelevant) {
            continue
        }

        $relevantFiles++
        Add-Report ''
        Add-Report ("=== RELEVANT JSON: " + [IO.Path]::GetRelativePath($jsonRoot,$file.FullName) + " ===")
        foreach ($needle in $needles) {
            $cursor = 0
            $occurrence = 0
            while ($occurrence -lt 4) {
                $index = $raw.IndexOf($needle,$cursor,[StringComparison]::OrdinalIgnoreCase)
                if ($index -lt 0) {
                    break
                }
                $occurrence++
                $start = [Math]::Max(0,$index-1200)
                $length = [Math]::Min(3000,$raw.Length-$start)
                $snippet = $raw.Substring($start,$length) -replace '[\r\n]+',' '
                Add-Report ("NEEDLE[$needle]#$occurrence OFFSET=$index")
                Add-Report $snippet
                $cursor = $index + $needle.Length
            }
        }
    }

    Add-Report ''
    Add-Report "RELEVANT_JSON_FILES=$relevantFiles"
    if ($relevantFiles -eq 0) {
        throw 'Serialized Ripperdoc resource did not expose the expected controller/widget-reference names.'
    }

    Add-Report ''
    Add-Report 'PROBE_RESULT=PASS'
    Add-Report 'PROOF_BOUNDARY=Installed archive/INK structure and serialized widget properties only; this does not prove Biology runtime placement.'
    $probeSucceeded = $true
}
catch {
    Add-Report ''
    Add-Report 'PROBE_RESULT=FAIL'
    Add-Report ("ERROR=" + $_.Exception.Message)
    throw
}
finally {
    try {
        if ($createdLocalOodle -and (Test-Path -LiteralPath $localOodle -PathType Leaf)) {
            if ((Get-Sha256 $localOodle) -eq $sourceOodleHash) {
                Remove-Item -LiteralPath $localOodle -Force
                Add-Report "TemporaryOodleCopyRemoved: $localOodle"
            } else {
                Add-Report 'WARNING: temporary Oodle destination changed; preserving it rather than deleting.'
            }
        }
    }
    catch {
        Add-Report ("WARNING: Oodle cleanup failed: " + $_.Exception.Message)
    }

    try {
        if (Test-Path -LiteralPath $workRoot -PathType Container) {
            Remove-Item -LiteralPath $workRoot -Recurse -Force
            Add-Report "TemporaryExtractionRemoved: $workRoot"
        }
    }
    catch {
        Add-Report ("WARNING: extraction cleanup failed: " + $_.Exception.Message)
    }

    $report | Set-Content -LiteralPath $ReportPath -Encoding utf8
    Write-Host ''
    Write-Host "LOCAL EVIDENCE REPORT: $ReportPath" -ForegroundColor Cyan
    Write-Host 'Attach that .txt file to the W02 worker conversation.' -ForegroundColor DarkGray
}

if (-not $probeSucceeded) {
    exit 1
}

    $archiveArguments = [Collections.Generic.List[string]]::new()
    $archiveArguments.Add($cli)
    $archiveArguments.Add('archive')
    foreach ($archiveFile in $archiveFiles) {
        $archiveArguments.Add($archiveFile.FullName)
    }
    $archiveArguments.Add('--list')
    $archiveArguments.Add('--regex')
    $archiveArguments.Add($resourceRegex)
    $archiveOutput = Invoke-Captured 'LIST RIPPERDOC FULLSCREEN INKWIDGET' $dotnet $archiveArguments.ToArray()

    $resourcePaths = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($line in $archiveOutput) {
        foreach ($match in [regex]::Matches($line,'(?i)([A-Za-z0-9_./\\-]*ripperdoc[A-Za-z0-9_./\\-]*\.inkwidget)')) {
            $null = $resourcePaths.Add($match.Groups[1].Value.Replace('/','\'))
        }
    }

    Add-Report ''
    Add-Report "MATCHED_RESOURCE_PATHS=$($resourcePaths.Count)"
    foreach ($path in @($resourcePaths | Sort-Object)) {
        Add-Report "RESOURCE: $path"
    }
    if ($resourcePaths.Count -ne 1) {
        throw "Expected exactly one installed Ripperdoc fullscreen .inkwidget resource; found $($resourcePaths.Count)."
    }

    Invoke-Captured 'EXTRACT RIPPERDOC FULLSCREEN INKWIDGET' $dotnet @(
        $cli,'unbundle',$archiveRoot,'--outpath',$extractRoot,'--gamepath',$GamePath,'--regex',$resourceRegex
    ) | Out-Null

    $extracted = @(Get-ChildItem -LiteralPath $extractRoot -Recurse -File -Filter '*.inkwidget')
    Add-Report ''
    Add-Report "EXTRACTED_INKWIDGETS=$($extracted.Count)"
    foreach ($file in $extracted) {
        Add-Report ("EXTRACTED: " + [IO.Path]::GetRelativePath($extractRoot,$file.FullName) + " SHA256=" + (Get-Sha256 $file.FullName))
    }
    if ($extracted.Count -ne 1) {
        throw "Expected exactly one extracted Ripperdoc fullscreen .inkwidget; found $($extracted.Count)."
    }

    Invoke-Captured 'SERIALIZE RIPPERDOC INKWIDGET TO JSON' $dotnet @(
        $cli,'convert','serialize',$extractRoot,'--outpath',$jsonRoot,'--pattern','*.inkwidget'
    ) | Out-Null

    $jsonFiles = @(Get-ChildItem -LiteralPath $jsonRoot -Recurse -File -Filter '*.json')
    Add-Report ''
    Add-Report "SERIALIZED_JSON_FILES=$($jsonFiles.Count)"
    if ($jsonFiles.Count -eq 0) {
        throw 'No JSON was produced from the extracted Ripperdoc .inkwidget resource.'
    }

    $needles = @(
        'RipperdocInventoryController',
        'inventoryViewAnchor',
        'virtualGridContainer',
        'scrollBarContainer',
        'labelPrefix',
        'labelSuffix',
        'item_area_extended'
    )

    $relevantFiles = 0
    foreach ($file in $jsonFiles) {
        $raw = Get-Content -Raw -LiteralPath $file.FullName
        $fileRelevant = $false
        foreach ($needle in $needles) {
            if ($raw.IndexOf($needle,[StringComparison]::OrdinalIgnoreCase) -ge 0) {
                $fileRelevant = $true
                break
            }
        }
        if (-not $fileRelevant) {
            continue
        }

        $relevantFiles++
        Add-Report ''
        Add-Report ("=== RELEVANT JSON: " + [IO.Path]::GetRelativePath($jsonRoot,$file.FullName) + " ===")
        foreach ($needle in $needles) {
            $cursor = 0
            $occurrence = 0
            while ($occurrence -lt 4) {
                $index = $raw.IndexOf($needle,$cursor,[StringComparison]::OrdinalIgnoreCase)
                if ($index -lt 0) {
                    break
                }
                $occurrence++
                $start = [Math]::Max(0,$index-1200)
                $length = [Math]::Min(3000,$raw.Length-$start)
                $snippet = $raw.Substring($start,$length) -replace '[\r\n]+',' '
                Add-Report ("NEEDLE[$needle]#$occurrence OFFSET=$index")
                Add-Report $snippet
                $cursor = $index + $needle.Length
            }
        }
    }

    Add-Report ''
    Add-Report "RELEVANT_JSON_FILES=$relevantFiles"
    if ($relevantFiles -eq 0) {
        throw 'Serialized Ripperdoc resource did not expose the expected controller/widget-reference names.'
    }

    Add-Report ''
    Add-Report 'PROBE_RESULT=PASS'
    Add-Report 'PROOF_BOUNDARY=Installed archive/INK structure and serialized widget properties only; this does not prove Biology runtime placement.'
    $probeSucceeded = $true
}
catch {
    Add-Report ''
    Add-Report 'PROBE_RESULT=FAIL'
    Add-Report ("ERROR=" + $_.Exception.Message)
    throw
}
finally {
    try {
        if ($createdLocalOodle -and (Test-Path -LiteralPath $localOodle -PathType Leaf)) {
            if ((Get-Sha256 $localOodle) -eq $sourceOodleHash) {
                Remove-Item -LiteralPath $localOodle -Force
                Add-Report "TemporaryOodleCopyRemoved: $localOodle"
            } else {
                Add-Report 'WARNING: temporary Oodle destination changed; preserving it rather than deleting.'
            }
        }
    }
    catch {
        Add-Report ("WARNING: Oodle cleanup failed: " + $_.Exception.Message)
    }

    try {
        if (Test-Path -LiteralPath $workRoot -PathType Container) {
            Remove-Item -LiteralPath $workRoot -Recurse -Force
            Add-Report "TemporaryExtractionRemoved: $workRoot"
        }
    }
    catch {
        Add-Report ("WARNING: extraction cleanup failed: " + $_.Exception.Message)
    }

    $report | Set-Content -LiteralPath $ReportPath -Encoding utf8
    Write-Host ''
    Write-Host "LOCAL EVIDENCE REPORT: $ReportPath" -ForegroundColor Cyan
    Write-Host 'Attach that .txt file to the W02 worker conversation.' -ForegroundColor DarkGray
}

if (-not $probeSucceeded) {
    exit 1
}
