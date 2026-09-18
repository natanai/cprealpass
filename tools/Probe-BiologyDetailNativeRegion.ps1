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
$candidateRegex = '(?i)\.inkwidget$'

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

function Invoke-QuietCaptured([string]$Exe,[string[]]$Arguments) {
    $output = @(& $Exe @Arguments 2>&1)
    [pscustomobject]@{
        ExitCode = $LASTEXITCODE
        Output = @($output | ForEach-Object { [string]$_ })
    }
}

function Add-NeedleSnippets([string]$Raw,[string]$Needle,[int]$MaxOccurrences = 6) {
    $cursor = 0
    $occurrence = 0
    while ($occurrence -lt $MaxOccurrences) {
        $index = $Raw.IndexOf($Needle,$cursor,[StringComparison]::OrdinalIgnoreCase)
        if ($index -lt 0) {
            break
        }
        $occurrence++
        $start = [Math]::Max(0,$index-1800)
        $length = [Math]::Min(4400,$Raw.Length-$start)
        $snippet = $Raw.Substring($start,$length) -replace '[\r\n]+',' '
        Add-Report ("NEEDLE[$Needle]#$occurrence OFFSET=$index")
        Add-Report $snippet
        $cursor = $index + $Needle.Length
    }
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
    Add-Report "GameOodleSHA256: $sourceOodleHash"
    Add-Report "CandidateRegex: $candidateRegex"
    Add-Report 'Purpose: discover the installed CP2077 2.31 INK resource that actually carries RipperDocGameController/RipperdocInventoryController, then report its authored detail geometry.'
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

    Write-Host ''
    Write-Host "Scanning $($archiveFiles.Count) installed archives for resolvable INK resources..." -ForegroundColor Cyan

    $candidates = [Collections.Generic.List[object]]::new()
    $seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)

    foreach ($archiveFile in $archiveFiles) {
        $relativeArchive = [IO.Path]::GetRelativePath($archiveRoot,$archiveFile.FullName)
        $result = Invoke-QuietCaptured $dotnet @(
            $cli,'archive',$archiveFile.FullName,'--list','--regex',$candidateRegex
        )
        if ($result.ExitCode -ne 0) {
            throw "WolvenKit could not inspect archive: $relativeArchive"
        }

        foreach ($line in $result.Output) {
            $candidatePath = ([string]$line).Trim().Replace('/','\')
            if ($candidatePath -notmatch '(?i)\.inkwidget$') {
                continue
            }
            $key = $archiveFile.FullName + '|' + $candidatePath
            if (-not $seen.Add($key)) {
                continue
            }

            $priority = 2
            if ($candidatePath -match '(?i)(ripperdoc|cyberware)') {
                $priority = 0
            } elseif ($candidatePath -match '(?i)fullscreen') {
                $priority = 1
            }

            $candidates.Add([pscustomobject]@{
                Archive = $archiveFile
                RelativeArchive = $relativeArchive
                Path = $candidatePath
                Priority = $priority
            })
        }
    }

    Add-Report ''
    Add-Report "DISCOVERED_INKWIDGET_CANDIDATES=$($candidates.Count)"
    if ($candidates.Count -eq 0) {
        throw 'No installed .inkwidget resources were discoverable by WolvenKit path metadata.'
    }

    $orderedCandidates = @($candidates | Sort-Object Priority, Path, RelativeArchive)
    Add-Report "PRIORITY_0_RIPPERDOC_CYBERWARE=$(@($orderedCandidates | Where-Object Priority -eq 0).Count)"
    Add-Report "PRIORITY_1_FULLSCREEN=$(@($orderedCandidates | Where-Object Priority -eq 1).Count)"

    $controllerMatches = [Collections.Generic.List[object]]::new()
    for ($i = 0; $i -lt $orderedCandidates.Count; $i++) {
        $candidate = $orderedCandidates[$i]
        $slot = ('candidate-{0:D4}' -f ($i+1))
        $candidateExtract = Join-Path $extractRoot $slot
        $candidateJson = Join-Path $jsonRoot $slot
        New-Item -ItemType Directory -Force -Path $candidateExtract,$candidateJson | Out-Null

        $exactRegex = '^' + [regex]::Escape($candidate.Path) + '$'
        Add-Report ''
        Add-Report ("TEST_CANDIDATE[$($i+1)] PRIORITY=$($candidate.Priority): " + $candidate.Path + " | ARCHIVE: " + $candidate.RelativeArchive)

        $extract = Invoke-QuietCaptured $dotnet @(
            $cli,'unbundle',$candidate.Archive.FullName,
            '--outpath',$candidateExtract,
            '--gamepath',$GamePath,
            '--regex',$exactRegex
        )
        Add-Report "CANDIDATE_EXTRACT_EXIT=$($extract.ExitCode)"
        if ($extract.ExitCode -ne 0) {
            Add-Report 'CANDIDATE_RESULT=EXTRACT_FAILED'
            continue
        }

        $resources = @(Get-ChildItem -LiteralPath $candidateExtract -Recurse -File -Filter '*.inkwidget')
        Add-Report "CANDIDATE_EXTRACTED_INKWIDGETS=$($resources.Count)"
        if ($resources.Count -ne 1) {
            Add-Report 'CANDIDATE_RESULT=UNEXPECTED_EXTRACT_COUNT'
            continue
        }

        $serialize = Invoke-QuietCaptured $dotnet @(
            $cli,'convert','serialize',$resources[0].FullName,
            '--outpath',$candidateJson
        )
        Add-Report "CANDIDATE_SERIALIZE_EXIT=$($serialize.ExitCode)"
        if ($serialize.ExitCode -ne 0) {
            Add-Report 'CANDIDATE_RESULT=SERIALIZE_FAILED'
            continue
        }

        $jsonFiles = @(Get-ChildItem -LiteralPath $candidateJson -Recurse -File -Filter '*.json')
        if ($jsonFiles.Count -eq 0) {
            Add-Report 'CANDIDATE_RESULT=NO_JSON'
            continue
        }

        $candidateMatched = $false
        foreach ($jsonFile in $jsonFiles) {
            $raw = Get-Content -Raw -LiteralPath $jsonFile.FullName
            $hasGameController = $raw.IndexOf('RipperDocGameController',[StringComparison]::OrdinalIgnoreCase) -ge 0
            $hasInventoryController = $raw.IndexOf('RipperdocInventoryController',[StringComparison]::OrdinalIgnoreCase) -ge 0
            $hasInventoryAnchor = $raw.IndexOf('inventoryViewAnchor',[StringComparison]::OrdinalIgnoreCase) -ge 0
            $hasVirtualGrid = $raw.IndexOf('virtualGridContainer',[StringComparison]::OrdinalIgnoreCase) -ge 0

            if (($hasGameController -or $hasInventoryController) -and ($hasInventoryAnchor -or $hasVirtualGrid)) {
                $candidateMatched = $true
                $controllerMatches.Add([pscustomobject]@{
                    Candidate = $candidate
                    ResourceFile = $resources[0]
                    JsonFile = $jsonFile
                    Raw = $raw
                })
                break
            }
        }

        Add-Report ("CANDIDATE_RESULT=" + $(if ($candidateMatched) { 'CONTROLLER_MATCH' } else { 'NOT_TARGET' }))
        if ($candidateMatched) {
            break
        }
    }

    Add-Report ''
    Add-Report "CONTROLLER_MATCH_COUNT=$($controllerMatches.Count)"
    if ($controllerMatches.Count -ne 1) {
        throw "Expected one installed INK candidate carrying the Ripperdoc controller/detail contract; found $($controllerMatches.Count)."
    }

    $target = $controllerMatches[0]
    Add-Report ("TARGET_RESOURCE_DISCOVERED=" + $target.Candidate.Path)
    Add-Report ("TARGET_SOURCE_ARCHIVE=" + $target.Candidate.RelativeArchive)
    Add-Report ("TARGET_RESOURCE_SHA256=" + (Get-Sha256 $target.ResourceFile.FullName))
    Add-Report ("TARGET_JSON=" + [IO.Path]::GetRelativePath($jsonRoot,$target.JsonFile.FullName))

    $needles = @(
        'RipperDocGameController',
        'RipperdocInventoryController',
        'inventoryViewAnchor',
        'virtualGridContainer',
        'scrollBarContainer',
        'labelPrefix',
        'labelSuffix',
        'minigridTargetAnchor',
        'selectorAnchor',
        'item_area_extended'
    )
    Add-Report ''
    Add-Report '=== TARGET NATIVE INK EVIDENCE ==='
    foreach ($needle in $needles) {
        Add-NeedleSnippets $target.Raw $needle
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
