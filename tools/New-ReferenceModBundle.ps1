[CmdletBinding()]
param(
    [string]$LibraryPath = 'C:\Games\Cyberpunk-ReferenceMods',
    [string[]]$ReferenceName,
    [string]$ReferenceNameJson = '',
    [string]$OutputRoot = 'C:\Games\Biology-Reference-Bundles',
    [switch]$IncludeBiologyNativeUi,
    [string]$GamePath = 'C:\Games\Steam\steamapps\common\Cyberpunk 2077',
    [switch]$SuppressHandoffMarker,
    [ValidatePattern('^$|^[0-9a-fA-F]{40}$')][string]$WorkflowSourceRevision = '',
    [ValidateRange(1,20)][int]$MaxTextFileMiB = 2,
    [ValidateRange(1,200)][int]$MaxCopiedTextMiB = 40
)

$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'PowerShell 7 or newer is required.' }
Add-Type -AssemblyName System.IO.Compression.FileSystem

function Full([string]$p) { [IO.Path]::GetFullPath($p) }
function Under([string]$child,[string]$parent) {
    $c=(Full $child).TrimEnd('\')+'\'
    $p=(Full $parent).TrimEnd('\')+'\'
    $c.StartsWith($p,[StringComparison]::OrdinalIgnoreCase)
}
function Sha([string]$p) { (Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToUpperInvariant() }
function SafeName([string]$s) {
    $v=[regex]::Replace($s,'[^A-Za-z0-9._-]+','_').Trim('_')
    if ($v) { $v } else { 'reference' }
}
function IsText([string]$p) {
    $ext=[IO.Path]::GetExtension($p).ToLowerInvariant()
    if ($ext -in @('.reds','.redscript','.script','.lua','.ps1','.json','.jsonc','.yaml','.yml','.toml','.ini','.cfg','.conf','.xml','.tweak','.xl','.md','.txt','.csv','.js','.ts','.css','.html','.cpp','.c','.h','.hpp','.cs')) { return $true }
    [IO.Path]::GetFileName($p) -match '^(?i)(readme|license|changelog|manifest|metadata|info|dependencies|requirements)(?:[._-].*)?$'
}
function Classify([string]$p) {
    $ext=[IO.Path]::GetExtension($p).ToLowerInvariant()
    if (IsText $p) { return 'text/source/config' }
    if ($ext -in @('.zip','.7z','.rar','.archive','.pak','.bundle')) { return 'archive/resource-container' }
    if ($ext -in @('.dll','.exe','.asi','.red4ext','.bin','.inkwidget','.inkatlas','.xbm','.mesh','.app','.ent','.mi','.wem','.opuspak','.bk2','.streamingsector','.phys','.anim','.anims','.mlsetup','.mt','.world')) { return 'binary/resource' }
    'other'
}
function Native([string]$exe,[string[]]$arguments) {
    $psi=[Diagnostics.ProcessStartInfo]::new()
    $psi.FileName=$exe
    $psi.UseShellExecute=$false
    $psi.RedirectStandardOutput=$true
    $psi.RedirectStandardError=$true
    $psi.CreateNoWindow=$true
    foreach($a in $arguments){[void]$psi.ArgumentList.Add($a)}
    $p=[Diagnostics.Process]::new(); $p.StartInfo=$psi
    try {
        if(-not $p.Start()){throw "Could not start $exe"}
        $o=$p.StandardOutput.ReadToEnd(); $e=$p.StandardError.ReadToEnd(); $p.WaitForExit()
        [pscustomobject]@{ExitCode=$p.ExitCode;StdOut=$o;StdErr=$e}
    } finally {$p.Dispose()}
}
function NativeLive([string]$exe,[string[]]$arguments) {
    $psi=[Diagnostics.ProcessStartInfo]::new()
    $psi.FileName=$exe
    $psi.UseShellExecute=$false
    $psi.RedirectStandardOutput=$true
    $psi.RedirectStandardError=$true
    $psi.CreateNoWindow=$true
    foreach($a in $arguments){[void]$psi.ArgumentList.Add($a)}
    $p=[Diagnostics.Process]::new(); $p.StartInfo=$psi
    try {
        if(-not $p.Start()){throw "Could not start $exe"}
        $stdout=[Text.StringBuilder]::new(); $stderr=[Text.StringBuilder]::new()
        $outDone=$false; $errDone=$false
        $outTask=$p.StandardOutput.ReadLineAsync(); $errTask=$p.StandardError.ReadLineAsync()
        while(-not ($p.HasExited -and $outDone -and $errDone)){
            if(-not $outDone -and $outTask.IsCompleted){
                $line=$outTask.GetAwaiter().GetResult()
                if($null -eq $line){$outDone=$true}else{
                    Write-Host $line
                    [void]$stdout.AppendLine($line)
                    $outTask=$p.StandardOutput.ReadLineAsync()
                }
            }
            if(-not $errDone -and $errTask.IsCompleted){
                $line=$errTask.GetAwaiter().GetResult()
                if($null -eq $line){$errDone=$true}else{
                    Write-Host $line -ForegroundColor DarkYellow
                    [void]$stderr.AppendLine($line)
                    $errTask=$p.StandardError.ReadLineAsync()
                }
            }
            if(-not ($p.HasExited -and $outDone -and $errDone)){Start-Sleep -Milliseconds 50}
        }
        $p.WaitForExit()
        [pscustomobject]@{ExitCode=$p.ExitCode;StdOut=$stdout.ToString();StdErr=$stderr.ToString()}
    } finally {$p.Dispose()}
}
function FolderFiles([IO.DirectoryInfo]$root) {
    $out=[Collections.Generic.List[IO.FileInfo]]::new()
    $stack=[Collections.Generic.Stack[IO.DirectoryInfo]]::new(); $stack.Push($root)
    while($stack.Count -gt 0){
        $d=$stack.Pop()
        foreach($x in @($d.GetFileSystemInfos() | Sort-Object Name)){
            if(($x.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0){continue}
            if($x -is [IO.DirectoryInfo]){$stack.Push($x)} else {$out.Add([IO.FileInfo]$x)}
        }
    }
    @($out)
}

$project=Full (Join-Path $PSScriptRoot '..')
$LibraryPath=Full $LibraryPath
$OutputRoot=Full $OutputRoot
if(-not (Test-Path -LiteralPath $LibraryPath -PathType Container)){throw "Reference library missing: $LibraryPath"}
if(Under $OutputRoot $LibraryPath){throw 'OutputRoot must be outside the private reference library.'}
if(Under $OutputRoot $project){throw 'OutputRoot must be outside the cprealpass checkout.'}
New-Item -ItemType Directory -Force -Path $OutputRoot | Out-Null

$children=@(Get-ChildItem -LiteralPath $LibraryPath -Force | Sort-Object Name)
if($children.Count -eq 0){throw 'Reference library is empty.'}
if(( -not $ReferenceName -or $ReferenceName.Count -eq 0) -and -not [string]::IsNullOrWhiteSpace($ReferenceNameJson)){
    try{$ReferenceName=@($ReferenceNameJson|ConvertFrom-Json)}catch{throw "ReferenceNameJson is invalid JSON: $($_.Exception.Message)"}
}
if(-not $ReferenceName -or $ReferenceName.Count -eq 0){
    Write-Host 'Available private references:' -ForegroundColor Cyan
    for($i=0;$i -lt $children.Count;$i++){Write-Host ("[{0}] {1}" -f ($i+1),$children[$i].Name)}
    $tokens=@((Read-Host 'Enter numbers separated by commas') -split ',' | ForEach-Object {$_.Trim()} | Where-Object {$_})
    if($tokens.Count -eq 0){throw 'No references selected.'}
    $picked=[Collections.Generic.List[string]]::new()
    foreach($t in $tokens){$n=0;if(-not [int]::TryParse($t,[ref]$n)-or$n-lt1-or$n-gt$children.Count){throw "Invalid selection: $t"};$picked.Add($children[$n-1].Name)}
    $ReferenceName=@($picked)
}
$selected=[Collections.Generic.List[object]]::new()
foreach($name in @($ReferenceName|Select-Object -Unique)){
    if([IO.Path]::IsPathRooted($name)-or$name.Contains('\')-or$name.Contains('/')-or$name -in @('.','..')){throw "ReferenceName must be an immediate-child name: $name"}
    $m=@($children|Where-Object Name -eq $name)
    if($m.Count -ne 1){throw "Reference not found or ambiguous: $name"}
    $selected.Add($m[0])
}

$stamp=[DateTime]::Now.ToString('yyyyMMdd-HHmmss')+'-'+[guid]::NewGuid().ToString('N').Substring(0,8)
$zipPath=Join-Path $OutputRoot ('Biology-Private-ReferenceBundle-'+$stamp+'.zip')
$stage=Join-Path $OutputRoot ('reference-staging-'+$stamp)
New-Item -ItemType Directory -Path $stage | Out-Null
$payload=Join-Path $stage 'payload'; $inventories=Join-Path $stage 'archive-inventory'
New-Item -ItemType Directory -Path $payload,$inventories | Out-Null
$index=[Collections.Generic.List[object]]::new()
$signals=[Collections.Generic.List[object]]::new()
$refs=[Collections.Generic.List[object]]::new()
$archives=[Collections.Generic.List[object]]::new()
$notes=[Collections.Generic.List[string]]::new()
$copied=[int64]0; $oneLimit=[int64]$MaxTextFileMiB*1MB; $allLimit=[int64]$MaxCopiedTextMiB*1MB
$seven=Get-Command 7z,7zz -ErrorAction SilentlyContinue|Select-Object -First 1
$nativeUi=[ordered]@{requested=[bool]$IncludeBiologyNativeUi;status='not-requested'}

function AnalyzeText([string]$ref,[string]$rel,[string]$text){
    $lineNo=0
    foreach($line in ($text -split "\r?\n")){
        $lineNo++
        if($line -match '@(wrapMethod|replaceMethod|addMethod|addField)\b'){$signals.Add([pscustomobject]@{reference=$ref;path=$rel;line=$lineNo;kind='redscript-hook';signal=$line.Trim()})}
        if($line -match '(?i)\b(ArchiveXL|TweakXL|RED4ext|Codeware|Cyber Engine Tweaks|CET|Input Loader|redscript|REDmod)\b'){$signals.Add([pscustomobject]@{reference=$ref;path=$rel;line=$lineNo;kind='framework';signal=$line.Trim()})}
        if($line -match '(?i)\b(ink[A-Za-z0-9_]+|Controller|Widget|HUD|Nameplate|Quest|Minimap|Interaction)\b'){$signals.Add([pscustomobject]@{reference=$ref;path=$rel;line=$lineNo;kind='ui-symbol';signal=$line.Trim()})}
    }
    if([IO.Path]::GetFileName($rel)-match '(?i)(readme|manifest|metadata|info|package|modinfo)'){
        $v=[regex]::Match($text,'(?im)^\s*(?:version|ver)\s*[:= -]\s*[vV]?([0-9]+\.[0-9]+(?:\.[0-9]+)?)')
        if($v.Success){$notes.Add("$ref :: $rel :: version=$($v.Groups[1].Value)")}
    }
    if([IO.Path]::GetExtension($rel) -ieq '.json'){
        try{
            $j=$text|ConvertFrom-Json -Depth 40
            foreach($property in @('name','version','author')){
                if($j.PSObject.Properties.Name -contains $property -and $null -ne $j.$property -and "$($j.$property)"){
                    $notes.Add("$ref :: $rel :: $property=$($j.$property)")
                }
            }
            if($j.PSObject.Properties.Name -contains 'dependencies' -and $null -ne $j.dependencies){
                $notes.Add("$ref :: $rel :: dependencies field present")
                if($j.dependencies -is [pscustomobject]){
                    foreach($dependency in @($j.dependencies.PSObject.Properties)){
                        $notes.Add("$ref :: $rel :: dependency=$($dependency.Name) value=$($dependency.Value)")
                    }
                }elseif($j.dependencies -is [System.Collections.IEnumerable] -and -not ($j.dependencies -is [string])){
                    foreach($dependency in @($j.dependencies)){$notes.Add("$ref :: $rel :: dependency=$dependency")}
                }else{
                    $notes.Add("$ref :: $rel :: dependency=$($j.dependencies)")
                }
            }
        }catch{}
    }
}
function CopyText([string]$ref,[string]$rel,[byte[]]$bytes){
    if(-not (IsText $rel)){return 'not-text'}
    if($bytes.LongLength -gt $oneLimit){return 'skipped-per-file-limit'}
    if($script:copied+$bytes.LongLength -gt $allLimit){return 'skipped-total-text-limit'}
    $dest=Full (Join-Path (Join-Path $payload (SafeName $ref)) $rel)
    if(-not (Under $dest $payload)){throw "Unsafe payload path: $rel"}
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dest)|Out-Null
    [IO.File]::WriteAllBytes($dest,$bytes); $script:copied+=$bytes.LongLength
    try{AnalyzeText $ref $rel ([Text.Encoding]::UTF8.GetString($bytes))}catch{}
    'copied-private-text'
}
function ArchiveInventory([string]$ref,[string]$rel,[string]$path){
    $ext=[IO.Path]::GetExtension($path).ToLowerInvariant()
    $out=Join-Path $inventories ((SafeName ($ref+'-'+$rel))+'.txt')
    if($ext -eq '.zip'){
        try{
            $z=[IO.Compression.ZipFile]::OpenRead($path)
            try{@("ZIP: $rel","Entries: $($z.Entries.Count)") + @($z.Entries|Sort-Object FullName|ForEach-Object{"$($_.Length) $($_.FullName)"})|Set-Content -LiteralPath $out -Encoding utf8}
            finally{$z.Dispose()}
            $archives.Add([pscustomobject]@{reference=$ref;path=$rel;tool='System.IO.Compression.ZipFile';status='listed';inventory=('archive-inventory/'+[IO.Path]::GetFileName($out))})
            return 'listed-native-zip'
        }catch{$archives.Add([pscustomobject]@{reference=$ref;path=$rel;tool='System.IO.Compression.ZipFile';status='list-failed';detail=$_.Exception.Message});return 'zip-list-failed'}
    }
    if($seven){
        $r=Native $seven.Source @('l','-slt','--',$path)
        @("TOOL: $($seven.Source)","EXIT: $($r.ExitCode)",$r.StdOut,$r.StdErr)|Set-Content -LiteralPath $out -Encoding utf8
        if($r.ExitCode -eq 0){$archives.Add([pscustomobject]@{reference=$ref;path=$rel;tool=$seven.Source;status='listed';inventory=('archive-inventory/'+[IO.Path]::GetFileName($out))});return 'listed-7zip'}
        $archives.Add([pscustomobject]@{reference=$ref;path=$rel;tool=$seven.Source;status='tool-could-not-list';detail='Contents remain opaque; no interpretation was invented.'});return 'opaque-tool-could-not-list'
    }
    $archives.Add([pscustomobject]@{reference=$ref;path=$rel;tool=$null;status='opaque-no-safe-listing-tool';detail='Contents were not interpreted.'})
    'opaque-no-safe-listing-tool'
}
function AddDiskFile([string]$ref,[string]$rel,[string]$path){
    $info=Get-Item -LiteralPath $path; $class=Classify $rel
    $inspect=if($class -eq 'archive/resource-container'){ArchiveInventory $ref $rel $path}elseif($class -eq 'text/source/config'){'private-text-copy-eligible'}else{'hash-and-metadata-only'}
    $copy='not-text'
    if($class -eq 'text/source/config'){$copy=CopyText $ref $rel ([IO.File]::ReadAllBytes($path))}
    $index.Add([pscustomobject]@{reference=$ref;path=$rel.Replace('\','/');bytes=$info.Length;sha256=Sha $path;classification=$class;inspectability=$inspect;privatePayload=$copy})
}

function CollectBiologyNativeUi {
    Write-Host '[NATIVE 1/4] Validating installed Cyberpunk 2077 and REDmod evidence roots...' -ForegroundColor Cyan
    $nativeRoot=Join-Path $stage 'native-game-evidence'
    New-Item -ItemType Directory -Force -Path $nativeRoot|Out-Null
    $resolvedGame=Full $GamePath
    $exe=Join-Path $resolvedGame 'bin\x64\Cyberpunk2077.exe'
    $scriptRoot=Join-Path $resolvedGame 'tools\redmod\scripts'
    if(-not (Test-Path -LiteralPath $exe -PathType Leaf)){throw "Cyberpunk executable missing for native UI evidence: $exe"}
    if(-not (Test-Path -LiteralPath $scriptRoot -PathType Container)){throw "Installed official REDmod script tree missing: $scriptRoot"}

    Write-Host '[NATIVE 2/4] Locating and hashing official Ripperdoc scripts...' -ForegroundColor Cyan
    $scriptMatches=@(
        Get-ChildItem -LiteralPath $scriptRoot -Recurse -File -ErrorAction Stop |
        Where-Object {$_.Name -ieq 'ripperdoc.script' -or $_.Name -ieq 'ripperdocInventoryController.script'} |
        Sort-Object FullName
    )
    foreach($required in @('ripperdoc.script','ripperdocInventoryController.script')){
        if(@($scriptMatches|Where-Object Name -ieq $required).Count -lt 1){throw "Required installed native script not found: $required"}
    }

    $scriptRecords=[Collections.Generic.List[object]]::new()
    foreach($script in $scriptMatches){
        $relative=[IO.Path]::GetRelativePath($resolvedGame,$script.FullName)
        AddDiskFile 'CP2077-installed-official-scripts' $relative $script.FullName
        $record=[pscustomobject]@{path=$relative.Replace('\','/');bytes=[int64]$script.Length;sha256=Sha $script.FullName}
        $scriptRecords.Add($record)
        $notes.Add("CP2077 installed official script :: $($record.path) :: sha256=$($record.sha256)")
    }

    Write-Host ("[NATIVE 2/4] Found {0} matching official script file(s)." -f $scriptMatches.Count) -ForegroundColor Cyan
    Write-Host '[NATIVE 3/4] Running read-only INK/resource hierarchy probe. Archive scanning may take several minutes; probe output will stream live.' -ForegroundColor Cyan
    $probeReport=Join-Path $nativeRoot 'biology-detail-native-region.txt'
    $targetJson=Join-Path $nativeRoot 'ripperdoc-target.inkwidget.json'
    $ancestryJson=Join-Path $nativeRoot 'ripperdoc-widget-ancestry.json'
    $processReport=Join-Path $nativeRoot 'probe-process.txt'
    $probe=NativeLive 'pwsh' @(
        '-NoLogo','-NoProfile','-File',(Join-Path $PSScriptRoot 'Probe-BiologyDetailNativeRegion.ps1'),
        '-GamePath',$resolvedGame,
        '-ReportPath',$probeReport,
        '-PrivateTargetJsonPath',$targetJson,
        '-PrivateWidgetAncestryJsonPath',$ancestryJson
    )
    @(
      ('ExitCode: '+$probe.ExitCode),
      '--- STDOUT ---',
      $probe.StdOut,
      '--- STDERR ---',
      $probe.StdErr
    )|Set-Content -LiteralPath $processReport -Encoding utf8

    Write-Host ("[NATIVE 3/4] INK/resource probe finished with exit code {0}." -f $probe.ExitCode) -ForegroundColor Cyan
    $probeText=if(Test-Path -LiteralPath $probeReport -PathType Leaf){Get-Content -Raw -LiteralPath $probeReport}else{''}
    $targetPath=$null
    $sourceArchive=$null
    $resourceSha=$null
    foreach($pair in @(
        @{Name='targetPath';Pattern='(?m)^TARGET_RESOURCE_DISCOVERED=(?<v>.+)$'},
        @{Name='sourceArchive';Pattern='(?m)^TARGET_SOURCE_ARCHIVE=(?<v>.+)$'},
        @{Name='resourceSha';Pattern='(?m)^TARGET_RESOURCE_SHA256=(?<v>[0-9A-Fa-f]{64})$'}
    )){
        $m=[regex]::Match($probeText,$pair.Pattern)
        if($m.Success){Set-Variable -Name $pair.Name -Value $m.Groups['v'].Value.Trim()}
    }

    $targetJsonRecord=$null
    if(Test-Path -LiteralPath $targetJson -PathType Leaf){
        $info=Get-Item -LiteralPath $targetJson
        $targetJsonRecord=[ordered]@{path='native-game-evidence/ripperdoc-target.inkwidget.json';bytes=[int64]$info.Length;sha256=Sha $targetJson}
        $index.Add([pscustomobject]@{
            reference='CP2077-installed-native-INK'
            path=$targetJsonRecord.path
            bytes=$targetJsonRecord.bytes
            sha256=$targetJsonRecord.sha256
            classification='text/source/config'
            inspectability='serialized-by-repository-native-region-probe'
            privatePayload='copied-private-proprietary-game-json'
        })
        $notes.Add("CP2077 installed native INK :: $targetPath :: sha256=$resourceSha :: serializedJsonSha256=$($targetJsonRecord.sha256)")
    }

    $ancestryRecord=$null
    if(Test-Path -LiteralPath $ancestryJson -PathType Leaf){
        $info=Get-Item -LiteralPath $ancestryJson
        $ancestryRecord=[ordered]@{path='native-game-evidence/ripperdoc-widget-ancestry.json';bytes=[int64]$info.Length;sha256=Sha $ancestryJson}
        $index.Add([pscustomobject]@{
            reference='CP2077-installed-native-INK-derived-ancestry'
            path=$ancestryRecord.path
            bytes=$ancestryRecord.bytes
            sha256=$ancestryRecord.sha256
            classification='text/source/config'
            inspectability='derived-by-repository-native-region-probe'
            privatePayload='private-derived-widget-ancestry'
        })
    }

    $gameVersion=(Get-Item -LiteralPath $exe).VersionInfo.ProductVersion
    $captureStatus=if($probe.ExitCode -ne 0){'probe-failed-transparent'}elseif($targetJsonRecord -and $ancestryRecord){'captured'}elseif($targetJsonRecord){'captured-target-json-ancestry-missing'}else{'probe-passed-json-missing'}
    $summary=[ordered]@{
        requested=$true
        status=$captureStatus
        gameVersion=$gameVersion
        gameExecutableSha256=Sha $exe
        officialScripts=@($scriptRecords)
        nativeInk=[ordered]@{
            resourcePath=$targetPath
            sourceArchive=$sourceArchive
            resourceSha256=$resourceSha
            serializedJson=$targetJsonRecord
            widgetAncestry=$ancestryRecord
            focus='RipperDocGameController/inventoryViewAnchor -> RipperdocInventoryController -> virtualGridContainer; specifically preserve HandleId 219 / package-copy 743 direct-parent object, sibling order and ancestor layout constraints.'
        }
        probe=[ordered]@{
            exitCode=$probe.ExitCode
            report='native-game-evidence/biology-detail-native-region.txt'
            process='native-game-evidence/probe-process.txt'
        }
    }
    $summary|ConvertTo-Json -Depth 12|Set-Content -LiteralPath (Join-Path $nativeRoot 'summary.json') -Encoding utf8
    $script:nativeUi=$summary
    Write-Host ("[NATIVE 4/4] Native UI evidence status: {0}" -f $captureStatus) -ForegroundColor Cyan
}

function ZipSingleRoot([string]$path){
    try{
        $z=[IO.Compression.ZipFile]::OpenRead($path)
        try{
            $roots=@($z.Entries|ForEach-Object{
                $p=$_.FullName.Replace('\','/').TrimStart('/')
                if($p){$p.Split('/')[0]}
            }|Where-Object{$_}|Select-Object -Unique)
            if($roots.Count -eq 1){return [string]$roots[0]}
        }finally{$z.Dispose()}
    }catch{}
    $null
}
function HashZipEntry($entry){
    $s=$entry.Open()
    $sha=[Security.Cryptography.SHA256]::Create()
    try{[Convert]::ToHexString($sha.ComputeHash($s))}finally{$sha.Dispose();$s.Dispose()}
}

try{
    Write-Host ("REFERENCE BUNDLE START — {0} selected reference(s)." -f $selected.Count) -ForegroundColor Cyan
    if($IncludeBiologyNativeUi){
        Write-Host 'PHASE 1/4 — Current installed Biology/Cyberware native UI evidence.' -ForegroundColor Cyan
        try{CollectBiologyNativeUi}
        catch{
            $nativeFailRoot=Join-Path $stage 'native-game-evidence'
            New-Item -ItemType Directory -Force -Path $nativeFailRoot|Out-Null
            @(
              'BIOLOGY/CYBERWARE NATIVE UI REFERENCE SUB-CAPABILITY FAILED',
              ('Error: '+$_.Exception.Message),
              'The third-party reference bundle continues. No native hierarchy interpretation is invented.'
            )|Set-Content -LiteralPath (Join-Path $nativeFailRoot 'collection-failure.txt') -Encoding utf8
            $nativeUi=[ordered]@{requested=$true;status='failed-transparent';error=$_.Exception.Message}
        }
    } else {
        Write-Host 'PHASE 1/4 — Native Biology/Cyberware companion not requested.' -ForegroundColor DarkGray
    }
    Write-Host 'PHASE 2/4 — Indexing, hashing, and extracting bounded private reference text.' -ForegroundColor Cyan
    $folders=@($selected|Where-Object PSIsContainer|ForEach-Object Name)
    foreach($item in $selected){
        Write-Host ("[REFERENCE] Starting {0}" -f $item.Name) -ForegroundColor Cyan
        $dup=$null
        if(-not $item.PSIsContainer -and $item.Extension -ieq '.zip'){
            $base=[IO.Path]::GetFileNameWithoutExtension($item.Name)
            $zipRoot=ZipSingleRoot $item.FullName
            $dup=[string]($folders|Where-Object {$_ -ieq $base -or ($zipRoot -and $_ -ieq $zipRoot)}|Select-Object -First 1)
        }
        if($dup){
            $refs.Add([pscustomobject]@{name=$item.Name;type='zip';status='skipped-duplicate-payload';duplicateOf=$dup;sourceBytes=[int64]$item.Length;sourceSha256=Sha $item.FullName})
            Write-Host ("[REFERENCE] Duplicate payload skipped: {0} -> {1}" -f $item.Name,$dup) -ForegroundColor DarkGray
            continue
        }
        $start=$index.Count
        if($item.PSIsContainer){
            foreach($f in FolderFiles ([IO.DirectoryInfo]$item)){AddDiskFile $item.Name ([IO.Path]::GetRelativePath($item.FullName,$f.FullName)) $f.FullName}
            $refs.Add([pscustomobject]@{name=$item.Name;type='folder';status='included';indexedFiles=($index.Count-$start)})
            Write-Host ("[REFERENCE] Completed {0}: {1} indexed file(s)." -f $item.Name,($index.Count-$start)) -ForegroundColor Cyan
        }elseif($item.Extension -ieq '.zip'){
            $z=[IO.Compression.ZipFile]::OpenRead($item.FullName)
            try{
                foreach($e in @($z.Entries|Sort-Object FullName)){
                    if(-not $e.Name){continue}
                    $rel=$e.FullName.Replace('/','\')
                    if([IO.Path]::IsPathRooted($rel)-or$rel.Contains('..\')){$index.Add([pscustomobject]@{reference=$item.Name;path=$e.FullName;bytes=$e.Length;classification='unsafe-archive-entry';inspectability='not-extracted'});continue}
                    $class=Classify $rel
                    $hash=HashZipEntry $e
                    $copy='not-text'
                    if($class -eq 'text/source/config'){
                        if($e.Length -gt $oneLimit){$copy='skipped-per-file-limit'}
                        elseif($script:copied+$e.Length -gt $allLimit){$copy='skipped-total-text-limit'}
                        else{
                            $ms=[IO.MemoryStream]::new()
                            try{$s=$e.Open();try{$s.CopyTo($ms)}finally{$s.Dispose()};$copy=CopyText $item.Name $rel $ms.ToArray()}finally{$ms.Dispose()}
                        }
                    }
                    $index.Add([pscustomobject]@{reference=$item.Name;path=$e.FullName;bytes=$e.Length;sha256=$hash;classification=$class;inspectability=if($class -eq 'text/source/config'){'private-text-copy-eligible'}else{'zip-entry-hash-only'};privatePayload=$copy})
                }
            }finally{$z.Dispose()}
            $inspect=ArchiveInventory $item.Name $item.Name $item.FullName
            $refs.Add([pscustomobject]@{name=$item.Name;type='zip';status='included';sourceBytes=[int64]$item.Length;sourceSha256=Sha $item.FullName;indexedFiles=($index.Count-$start);archiveInspectability=$inspect})
            Write-Host ("[REFERENCE] Completed {0}: {1} indexed file(s)." -f $item.Name,($index.Count-$start)) -ForegroundColor Cyan
        }else{AddDiskFile $item.Name $item.Name $item.FullName;$refs.Add([pscustomobject]@{name=$item.Name;type='file';status='included';sourceBytes=[int64]$item.Length;sourceSha256=Sha $item.FullName;indexedFiles=1})}
    }

    Write-Host 'PHASE 3/4 — Writing manifest, hashes, signals, and provenance summaries.' -ForegroundColor Cyan
    @(
      'PRIVATE THIRD-PARTY REFERENCE MATERIAL - ANALYSIS ONLY',
      '',
      'Do not commit or redistribute third-party payload from this bundle.',
      'Reference mods are engineering evidence only. Biology must implement its own code against current Cyberpunk/REDmod contracts.',
      'The source reference library was read only and no reference mod was installed into Cyberpunk.'
    )|Set-Content -LiteralPath (Join-Path $stage 'PRIVATE-THIRD-PARTY-REFERENCE.txt') -Encoding utf8
    @($index)|ConvertTo-Json -Depth 8|Set-Content -LiteralPath (Join-Path $stage 'file-index.json') -Encoding utf8
    @($signals)|ConvertTo-Json -Depth 8|Set-Content -LiteralPath (Join-Path $stage 'signals.json') -Encoding utf8
    $gameAccess=if($IncludeBiologyNativeUi){'read-only native UI inspection requested; no installation or mutation'}else{'not accessed or modified'}
    $manifest=[ordered]@{
      schemaVersion=1;kind='private-reference-mod-archaeology-bundle';createdUtc=[DateTime]::UtcNow.ToString('o')
      analysisOnly=$true;redistributionAllowed=$false;workflowSourceRevision=$WorkflowSourceRevision;sourceLibrary=$LibraryPath;referenceSelections=@($refs)
      provenanceVersionNotes=@($notes|Select-Object -Unique);fileCount=$index.Count;copiedTextBytes=$copied
      archiveInventory=@($archives);nativeBiologyUi=$nativeUi;sourceMutation='none';gameInstallation=$gameAccess
      duplicatePolicy='Selected ZIPs whose basename or sole top-level root matches a selected extracted sibling folder are hash-recorded but their duplicate payload is skipped.'
      archivePolicy='ZIP contents are listed natively. Other archive/resource containers use safe 7z/7zz listing only when already available and successful; otherwise internals are explicitly opaque.'
    }
    $manifest|ConvertTo-Json -Depth 12|Set-Content -LiteralPath (Join-Path $stage 'manifest.json') -Encoding utf8
    $opaque=@($archives|Where-Object{$_.status -like 'opaque*' -or $_.status -eq 'tool-could-not-list'})
    @(
      'BIOLOGY PRIVATE REFERENCE-MOD ARCHAEOLOGY BUNDLE',
      ('Created UTC: '+$manifest.createdUtc),
      ('Source library: '+$LibraryPath),
      'Source-library mutation: NONE',
      ('Cyberpunk install access/mutation: '+$gameAccess),
      ('Selected references: '+$refs.Count),
      ('Indexed files: '+$index.Count),
      ('Copied private text/source/config bytes: '+$copied),
      ('Extracted signals: '+$signals.Count),
      ('Opaque archive/resource containers: '+$opaque.Count),
      ('Native Biology/Cyberware UI evidence: '+$nativeUi.status),
      '',
      'PRIVATE ANALYSIS ONLY. Commit only redistribution-safe derived conclusions using docs/reference-mods/reference-record.schema.json.'
    )|Set-Content -LiteralPath (Join-Path $stage 'report.txt') -Encoding utf8

    Write-Host 'PHASE 4/4 — Compressing the final private reference bundle.' -ForegroundColor Cyan
    Compress-Archive -Path (Join-Path $stage '*') -DestinationPath $zipPath -CompressionLevel Optimal
    Write-Host ("REFERENCE BUNDLE COMPLETE: {0}" -f $zipPath) -ForegroundColor Green
    if(-not (Test-Path -LiteralPath $zipPath -PathType Leaf)){throw 'Reference bundle ZIP was not created.'}
    if(-not $SuppressHandoffMarker){
        Write-Host ''
        Write-Host 'ATTACH THIS ONE REFERENCE BUNDLE TO CHATGPT:' -ForegroundColor Cyan
        Write-Host $zipPath -ForegroundColor Yellow
    }
    return $zipPath
}finally{
    if(Test-Path -LiteralPath $stage -PathType Container){Remove-Item -LiteralPath $stage -Recurse -Force}
}
