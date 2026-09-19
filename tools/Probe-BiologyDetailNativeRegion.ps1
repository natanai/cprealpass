#requires -Version 7.0
[CmdletBinding()]
param(
    [string]$GamePath = 'C:\Games\Steam\steamapps\common\Cyberpunk 2077',
    [string]$ReportPath,
    [string]$PrivateTargetJsonPath,
    [string]$PrivateWidgetAncestryJsonPath
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

function Add-RegexSnippets([string]$Raw,[string]$Label,[string]$Pattern,[int]$MaxOccurrences = 12) {
    $matches = [regex]::Matches($Raw,$Pattern,[Text.RegularExpressions.RegexOptions]::IgnoreCase)
    $take = [Math]::Min($MaxOccurrences,$matches.Count)
    for ($i=0; $i -lt $take; $i++) {
        $match = $matches[$i]
        $start = [Math]::Max(0,$match.Index-6000)
        $length = [Math]::Min(14000,$Raw.Length-$start)
        $snippet = $Raw.Substring($start,$length) -replace '[\r\n]+',' '
        Add-Report ("TARGETED[$Label]#$($i+1) OFFSET=$($match.Index)")
        Add-Report $snippet
    }
}

function Has-Property($Object,[string]$Name) {
    if ($null -eq $Object) { return $false }
    if ($Object -is [Collections.IDictionary]) { return $Object.Contains($Name) }
    return @($Object.PSObject.Properties.Name) -contains $Name
}
function Get-PropertyValue($Object,[string]$Name) {
    if ($null -eq $Object) { return $null }
    if ($Object -is [Collections.IDictionary]) {
        if ($Object.Contains($Name)) { return $Object[$Name] }
        return $null
    }
    $property=$Object.PSObject.Properties[$Name]
    if ($null -ne $property) { return $property.Value }
    return $null
}
function Get-NodeProperties($Object) {
    if ($null -eq $Object) { return @() }
    if ($Object -is [Collections.IDictionary]) {
        return @(
            foreach($key in @($Object.Keys)){
                [pscustomobject]@{Name=[string]$key;Value=$Object[$key]}
            }
        )
    }
    return @($Object.PSObject.Properties)
}
function Get-CNameValue($Value) {
    if ($null -eq $Value) { return $null }
    if ($Value -is [string]) { return [string]$Value }
    if (Has-Property $Value '$value') { return [string](Get-PropertyValue $Value '$value') }
    return $null
}
function Get-HandleRefIds($Value) {
    $found = [Collections.Generic.List[string]]::new()
    function Walk-Refs($Node) {
        if ($null -eq $Node) { return }
        if ($Node -is [string] -or $Node.GetType().IsPrimitive -or $Node -is [decimal]) { return }
        if ($Node -is [Collections.IDictionary]) {
            if (Has-Property $Node 'HandleRefId') {
                $id = [string](Get-PropertyValue $Node 'HandleRefId')
                if ($id -and -not $found.Contains($id)) { $found.Add($id) }
            }
            foreach($key in @($Node.Keys)){ Walk-Refs $Node[$key] }
            return
        }
        if ($Node -is [System.Collections.IEnumerable] -and -not ($Node -is [pscustomobject])) {
            foreach ($item in $Node) { Walk-Refs $item }
            return
        }
        if (Has-Property $Node 'HandleRefId') {
            $id = [string](Get-PropertyValue $Node 'HandleRefId')
            if ($id -and -not $found.Contains($id)) { $found.Add($id) }
        }
        foreach ($property in @(Get-NodeProperties $Node)) { Walk-Refs $property.Value }
    }
    Walk-Refs $Value
    @($found)
}
function Get-WidgetAncestryEvidence([string]$Raw) {
    # WolvenKit serialization can contain JSON keys that differ only by case
    # (for example selected / Selected). -AsHashtable preserves those distinct
    # keys whereas PSCustomObject conversion rejects them.
    $document = $Raw | ConvertFrom-Json -Depth 100 -AsHashtable
    $handles = [Collections.Generic.Dictionary[string,object]]::new([StringComparer]::OrdinalIgnoreCase)
    $order = [Collections.Generic.List[string]]::new()
    function Walk-Handles($Node) {
        if ($null -eq $Node) { return }
        if ($Node -is [string] -or $Node.GetType().IsPrimitive -or $Node -is [decimal]) { return }
        if ($Node -is [Collections.IDictionary]) {
            if (Has-Property $Node 'HandleId') {
                $id = [string](Get-PropertyValue $Node 'HandleId')
                if ($id -and -not $handles.ContainsKey($id)) {
                    $handles.Add($id,$Node)
                    $order.Add($id)
                }
            }
            foreach($key in @($Node.Keys)){ Walk-Handles $Node[$key] }
            return
        }
        if ($Node -is [System.Collections.IEnumerable] -and -not ($Node -is [pscustomobject])) {
            foreach ($item in $Node) { Walk-Handles $item }
            return
        }
        if (Has-Property $Node 'HandleId') {
            $id = [string](Get-PropertyValue $Node 'HandleId')
            if ($id -and -not $handles.ContainsKey($id)) {
                $handles.Add($id,$Node)
                $order.Add($id)
            }
        }
        foreach ($property in @(Get-NodeProperties $Node)) { Walk-Handles $property.Value }
    }
    Walk-Handles $document

    $summaries = [Collections.Generic.Dictionary[string,object]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($id in $order) {
        $wrapper = $handles[$id]
        $wrapperData = Get-PropertyValue $wrapper 'Data'
        $data = if ((Has-Property $wrapper 'Data') -and $null -ne $wrapperData) { $wrapperData } else { $wrapper }
        $parentValue = Get-PropertyValue $data 'parentWidget'
        $childrenValue = Get-PropertyValue $data 'children'
        $parent = if ($null -ne $parentValue) { @((Get-HandleRefIds $parentValue))[0] } else { $null }
        $declaredChildren = if ($null -ne $childrenValue) { @(Get-HandleRefIds $childrenValue) } else { @() }
        $clip = [ordered]@{}
        foreach ($property in @(Get-NodeProperties $data | Where-Object Name -Match '(?i)clip')) { $clip[$property.Name]=$property.Value }
        $renderTransform=Get-PropertyValue $data 'renderTransform'
        $summaries.Add($id,[ordered]@{
            handleId=$id
            type=if(Has-Property $data '$type'){[string](Get-PropertyValue $data '$type')}else{$null}
            name=if(Has-Property $data 'name'){Get-CNameValue (Get-PropertyValue $data 'name')}else{$null}
            parentHandleId=$parent
            declaredChildren=$declaredChildren
            clipping=$clip
            fitToContent=if(Has-Property $data 'fitToContent'){Get-PropertyValue $data 'fitToContent'}else{$null}
            layout=if(Has-Property $data 'layout'){Get-PropertyValue $data 'layout'}else{$null}
            size=if(Has-Property $data 'size'){Get-PropertyValue $data 'size'}else{$null}
            opacity=if(Has-Property $data 'opacity'){Get-PropertyValue $data 'opacity'}else{$null}
            visible=if(Has-Property $data 'visible'){Get-PropertyValue $data 'visible'}else{$null}
            renderTranslation=if($null -ne $renderTransform -and (Has-Property $renderTransform 'translation')){Get-PropertyValue $renderTransform 'translation'}else{$null}
        })
    }

    # Fill children/order from explicit parent references when the resource does not
    # expose a direct children array. This is derived from the same serialized graph,
    # not from screenshot geometry.
    foreach ($id in $order) {
        $summary=$summaries[$id]
        $parent=[string]$summary.parentHandleId
        if($parent -and $summaries.ContainsKey($parent)){
            $parentSummary=$summaries[$parent]
            if(@($parentSummary.declaredChildren).Count -eq 0){
                $inverse=@($order|Where-Object {$summaries[$_].parentHandleId -eq $parent})
                $parentSummary.declaredChildren=$inverse
            }
        }
    }

    $starts=[Collections.Generic.List[string]]::new()
    foreach($candidate in @('221','746','219','743')){
        if($summaries.ContainsKey($candidate) -and -not $starts.Contains($candidate)){$starts.Add($candidate)}
    }
    foreach($id in $order){
        if($summaries[$id].name -ieq 'virtualGridContainer' -and -not $starts.Contains($id)){$starts.Add($id)}
    }

    $chains=[Collections.Generic.List[object]]::new()
    foreach($start in $starts){
        $chain=[Collections.Generic.List[object]]::new()
        $seen=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
        $current=$start
        while($current -and $summaries.ContainsKey($current) -and $seen.Add($current)){
            $summary=$summaries[$current]
            $parent=[string]$summary.parentHandleId
            $siblingOrder=$null
            if($parent -and $summaries.ContainsKey($parent)){
                $siblings=@($summaries[$parent].declaredChildren)
                for($i=0;$i -lt $siblings.Count;$i++){if([string]$siblings[$i] -eq $current){$siblingOrder=$i;break}}
            }
            $chain.Add([ordered]@{
                handleId=$summary.handleId;type=$summary.type;name=$summary.name;parentHandleId=$summary.parentHandleId
                childOrder=$siblingOrder;children=@($summary.declaredChildren);clipping=$summary.clipping;fitToContent=$summary.fitToContent
                layout=$summary.layout;size=$summary.size;opacity=$summary.opacity;visible=$summary.visible;renderTranslation=$summary.renderTranslation
            })
            $current=$parent
        }
        $chains.Add([ordered]@{startHandleId=$start;widgets=@($chain)})
    }

    [ordered]@{
        schemaVersion=1
        generatedUtc=[DateTime]::UtcNow.ToString('o')
        handleCount=$handles.Count
        focus='virtualGridContainer direct parent and authored ancestor chain; specifically HandleId 219 / package-copy 743 when present.'
        chains=@($chains)
        exactFocusHandles=@(
            foreach($id in @('219','743')){if($summaries.ContainsKey($id)){$summaries[$id]}}
        )
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

    $toolchainArgs=@{}
    if(-not [string]::IsNullOrWhiteSpace($ToolCacheRoot)){$toolchainArgs.CacheRoot=$ToolCacheRoot}
    $toolchain = & (Join-Path $PSScriptRoot 'Acquire-ArchiveToolchain.ps1') @toolchainArgs
    $dotnet = [string]$toolchain.dotnetExe
    $cli = [string]$toolchain.cliDll
    Add-Report "WolvenKitCLI: $cli"
    Add-Report "WolvenKitCLISHA256: $($toolchain.cliDllSha256)"

    Write-Host ''
    Write-Host "Scanning $($archiveFiles.Count) installed archives for resolvable INK resources..." -ForegroundColor Cyan

    $candidates = [Collections.Generic.List[object]]::new()
    $seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)

    $archiveStopwatch = [Diagnostics.Stopwatch]::StartNew()
    for ($archiveIndex = 0; $archiveIndex -lt $archiveFiles.Count; $archiveIndex++) {
        $archiveFile = $archiveFiles[$archiveIndex]
        $relativeArchive = [IO.Path]::GetRelativePath($archiveRoot,$archiveFile.FullName)
        Write-Host ("[ARCHIVE {0}/{1}] {2}" -f ($archiveIndex+1),$archiveFiles.Count,$relativeArchive) -ForegroundColor DarkGray
        $beforeCandidates = $candidates.Count
        $oneArchive = [Diagnostics.Stopwatch]::StartNew()
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
        $oneArchive.Stop()
        Write-Host ("  done in {0:N1}s; +{1} candidate(s); cumulative {2}" -f $oneArchive.Elapsed.TotalSeconds,($candidates.Count-$beforeCandidates),$candidates.Count) -ForegroundColor DarkGray
    }
    $archiveStopwatch.Stop()
    Write-Host ("Archive scan complete in {0:N1}s; discovered {1} candidate(s)." -f $archiveStopwatch.Elapsed.TotalSeconds,$candidates.Count) -ForegroundColor Cyan

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
        Write-Host ("[CANDIDATE {0}/{1}] priority={2} {3}" -f ($i+1),$orderedCandidates.Count,$candidate.Priority,$candidate.Path) -ForegroundColor DarkGray

        $extract = Invoke-QuietCaptured $dotnet @(
            $cli,'unbundle',$candidate.Archive.FullName,
            '--outpath',$candidateExtract,
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

    if (-not [string]::IsNullOrWhiteSpace($PrivateTargetJsonPath)) {
        if (-not [IO.Path]::IsPathRooted($PrivateTargetJsonPath)) {
            throw 'PrivateTargetJsonPath must be an absolute path outside the checkout.'
        }
        $privateJson = [IO.Path]::GetFullPath($PrivateTargetJsonPath)
        $projectBoundary = [IO.Path]::GetFullPath($project).TrimEnd('\') + '\'
        if (($privateJson + '\').StartsWith($projectBoundary,[StringComparison]::OrdinalIgnoreCase)) {
            throw 'PrivateTargetJsonPath must remain outside the cprealpass checkout because it contains proprietary serialized game resource data.'
        }
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $privateJson) | Out-Null
        Copy-Item -LiteralPath $target.JsonFile.FullName -Destination $privateJson -Force
        Add-Report ("PRIVATE_TARGET_JSON=" + $privateJson)
        Add-Report ("PRIVATE_TARGET_JSON_SHA256=" + (Get-Sha256 $privateJson))
    }

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
    Add-Report '=== TARGETED HANDLE/ANCESTRY EVIDENCE ==='
    Add-Report 'Focus: preserve exact serialized object context for W17.1 around virtualGridContainer parent HandleId 219 (package-copy 743) and its direct references.'
    Add-RegexSnippets $target.Raw 'HANDLE_ID_219_OR_743' '"HandleId"\s*:\s*"?(219|743)"?\b'
    Add-RegexSnippets $target.Raw 'HANDLE_REF_219_OR_743' '"HandleRefId"\s*:\s*"?(219|743)"?\b'
    Add-RegexSnippets $target.Raw 'HANDLE_ID_GRID_LABEL_SCROLL' '"HandleId"\s*:\s*"?(208|210|215|221|727|730|737|746)"?\b'
    Add-RegexSnippets $target.Raw 'PARENT_WIDGET' '"parentWidget"\s*:'
    Add-Report 'Full serialized target JSON may be preserved privately by the caller with -PrivateTargetJsonPath for exact ancestry reconstruction without broad needle re-probing.'

    Add-Report ''
    Add-Report '=== DERIVED WIDGET ANCESTRY ==='
    try {
        $ancestry = Get-WidgetAncestryEvidence $target.Raw
        Add-Report ("ANCESTRY_HANDLE_COUNT=" + $ancestry.handleCount)
        foreach($chain in @($ancestry.chains)){
            Add-Report ("ANCESTRY_CHAIN_START=" + $chain.startHandleId)
            foreach($widget in @($chain.widgets)){
                Add-Report ("WIDGET=" + ($widget | ConvertTo-Json -Depth 20 -Compress))
            }
        }
        if (-not [string]::IsNullOrWhiteSpace($PrivateWidgetAncestryJsonPath)) {
            if (-not [IO.Path]::IsPathRooted($PrivateWidgetAncestryJsonPath)) { throw 'PrivateWidgetAncestryJsonPath must be absolute.' }
            $ancestryPath=[IO.Path]::GetFullPath($PrivateWidgetAncestryJsonPath)
            $projectBoundary=[IO.Path]::GetFullPath($project).TrimEnd('\')+'\'
            if (($ancestryPath+'\').StartsWith($projectBoundary,[StringComparison]::OrdinalIgnoreCase)) {
                throw 'PrivateWidgetAncestryJsonPath must remain outside the cprealpass checkout.'
            }
            New-Item -ItemType Directory -Force -Path (Split-Path -Parent $ancestryPath)|Out-Null
            $ancestry|ConvertTo-Json -Depth 30|Set-Content -LiteralPath $ancestryPath -Encoding utf8
            Add-Report ("PRIVATE_WIDGET_ANCESTRY_JSON=" + $ancestryPath)
            Add-Report ("PRIVATE_WIDGET_ANCESTRY_JSON_SHA256=" + (Get-Sha256 $ancestryPath))
        }
    } catch {
        Add-Report ("ANCESTRY_DERIVATION_FAILED=" + $_.Exception.Message)
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
    Write-Host 'Return that report to the requesting worker/parent; private callers may also preserve the serialized target and derived ancestry outside Git.' -ForegroundColor DarkGray
}

if (-not $probeSucceeded) {
    exit 1
}
