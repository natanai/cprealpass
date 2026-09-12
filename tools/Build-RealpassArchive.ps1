param(
    [Parameter(Mandatory=$true)][string]$ArchivePath,
    [string]$RecipePath='config/patches/realpass-modern-scanner.json'
)
. "$PSScriptRoot/Common.ps1"
$project=Get-ProjectRoot
$archive=Resolve-SafeChildPath $project $ArchivePath
$recipePath=Resolve-SafeChildPath $project $RecipePath
$recipeHash=Get-Sha256 $recipePath
$recipe=Get-Content -Raw -LiteralPath $recipePath|ConvertFrom-Json
if($recipe.schemaVersion -ne 1 -or $recipe.id -ne 'realpass-modern-scanner-v1' -or $recipe.distribution -ne 'local-integration-only'){throw 'Unexpected scanner archive recipe'}
if((Get-Sha256 $archive) -ne $recipe.expectedArchiveSha256){throw 'Scanner archive requires the exact original E3 asset'}
if(@($recipe.excludedResources).Count -eq 0 -or @($recipe.excludedResources).Count -ge $recipe.expectedResourceCount){throw 'Invalid scanner exclusion count'}
$toolchain=& "$PSScriptRoot/Acquire-ArchiveToolchain.ps1"
$relative='staging/e3-native-scanner-'+[guid]::NewGuid().ToString('N').Substring(0,12)
$work=Resolve-SafeChildPath $project $relative
$original=Resolve-SafeChildPath $work 'original'
$kept=Resolve-SafeChildPath $work 'basegame_3e_demo_hud'
$packed=Resolve-SafeChildPath $work 'packed'
$verified=Resolve-SafeChildPath $work 'verified'
foreach($directory in @($original,$kept,$packed,$verified)){New-Item -ItemType Directory -Path $directory -Force|Out-Null}
function Invoke-ArchiveTool([string]$Phase,[string[]]$Arguments) {
    $output=& $toolchain.dotnetExe $toolchain.cliDll @Arguments 2>&1
    $code=$LASTEXITCODE
    [IO.File]::WriteAllText((Join-Path $work ($Phase+'.log')),($output|Out-String),[Text.UTF8Encoding]::new($false))
    if($code -ne 0){throw "Archive $Phase failed; see the staged log"}
}
function Inventory([string]$Root) {
    $result=@{}
    foreach($file in Get-ChildItem -LiteralPath $Root -File -Recurse){
        $path=[IO.Path]::GetRelativePath($Root,$file.FullName).Replace('\','/')
        $safe=Resolve-SafeChildPath $Root $path
        if($result.ContainsKey($path)){throw 'Duplicate extracted resource path'}
        $result[$path]=[pscustomobject]@{path=$path;sha256=(Get-Sha256 $safe);source=$safe}
    }
    return $result
}
Invoke-ArchiveTool 'extract-original' @('unbundle',$archive,'--outpath',$original,'--verbosity','Minimal')
$before=Inventory $original
if($before.Count -ne $recipe.expectedResourceCount){throw 'Original archive resource count differs'}
$excluded=@{}
foreach($resource in $recipe.excludedResources) {
    $null=Resolve-SafeChildPath $original $resource.path
    if($excluded.ContainsKey($resource.path) -or !$before.ContainsKey($resource.path)){throw 'Duplicate or missing scanner exclusion'}
    if($before[$resource.path].sha256 -ne $resource.sha256){throw 'Scanner exclusion hash differs'}
    $excluded[$resource.path]=$true
}
foreach($resource in $before.Values){
    if(!$excluded.ContainsKey($resource.path)){
        Copy-VerifiedPayload $resource.source (Resolve-SafeChildPath $kept $resource.path) $resource.sha256
    }
}
Invoke-ArchiveTool 'pack' @('pack',$kept,'--outpath',$packed,'--verbosity','Minimal')
$output=Resolve-SafeChildPath $packed 'basegame_3e_demo_hud.archive'
if(!(Test-Path -LiteralPath $output -PathType Leaf)){throw 'Filtered archive was not produced'}
Invoke-ArchiveTool 'extract-verify' @('unbundle',$output,'--outpath',$verified,'--verbosity','Minimal')
$after=Inventory $verified
if($after.Count -ne ($before.Count-$excluded.Count)){throw 'Repacked resource count differs'}
foreach($resource in $before.Values){
    if($excluded.ContainsKey($resource.path)){
        if($after.ContainsKey($resource.path)){throw 'Excluded E3 scanner resource remains in archive'}
    }elseif(!$after.ContainsKey($resource.path) -or $after[$resource.path].sha256 -ne $resource.sha256){
        throw "Unrelated E3 resource changed: $($resource.path)"
    }
}
if((Get-Sha256 $archive) -ne $recipe.expectedArchiveSha256 -or (Get-Sha256 $recipePath) -ne $recipeHash){throw 'Archive build input changed'}
$reportPath=Resolve-SafeChildPath $work 'archive-build.json'
$report=[ordered]@{
    builtAtUtc=[DateTime]::UtcNow.ToString('o')
    passed=$true
    source=$ArchivePath
    sourceSha256=$recipe.expectedArchiveSha256
    recipe=$RecipePath
    recipeSha256=$recipeHash
    output=[IO.Path]::GetRelativePath($project,$output).Replace('\','/')
    outputSha256=(Get-Sha256 $output)
    sourceResources=$before.Count
    omittedResources=$excluded.Count
    retainedResources=$after.Count
    retainedResourcesByteIdentical=$true
    omissions=@($recipe.excludedResources)
    resources=@($after.Values|Sort-Object path|Select-Object path,sha256)
    toolchainReport=$toolchain.reportPath
    distribution='local-integration-only'
    compiled=$false
    installed=$false
    nativeRenderingVerified=$false
}
Write-JsonFile $report $reportPath
Write-Host "Verified filtered E3 archive: $($excluded.Count) scanner overrides omitted; $($after.Count) other resources byte identical."
[pscustomobject]@{archivePath=$output;sha256=$report.outputSha256;reportPath=$reportPath;retainedResources=$after.Count;omittedResources=$excluded.Count}
