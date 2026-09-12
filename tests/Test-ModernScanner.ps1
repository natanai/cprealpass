param(
    [Parameter(Mandatory=$true)][string]$BaseManifestPath,
    [Parameter(Mandatory=$true)][string]$CandidateManifestPath
)
. "$PSScriptRoot/../tools/Common.ps1"
$project=Get-ProjectRoot
$base=Get-Content -Raw -LiteralPath (Resolve-SafeChildPath $project $BaseManifestPath)|ConvertFrom-Json
$candidatePath=Resolve-SafeChildPath $project $CandidateManifestPath
$candidate=Get-Content -Raw -LiteralPath $candidatePath|ConvertFrom-Json
$recipePath=Join-Path $project 'config/patches/realpass-modern-scanner.json'
$recipe=Get-Content -Raw -LiteralPath $recipePath|ConvertFrom-Json
$script:checks=0
function Check([bool]$Condition,[string]$Message){if(!$Condition){throw $Message};$script:checks++}
Check ($candidate.realpassE3.scannerMode -eq 'Modern') 'Candidate does not declare modern scanner'
Check ($candidate.realpassE3.distribution -eq 'local-integration-only') 'Filtered E3 archive lost its distribution restriction'
$before=@{}
foreach($file in $base.files){$before[$file.destination]=$file}
$after=@{}
foreach($file in $candidate.files){
    Check (!$after.ContainsKey($file.destination)) 'Duplicate candidate file'
    $after[$file.destination]=$file
    Check ((Get-Sha256 (Resolve-SafeChildPath $project $file.source)) -eq $file.sha256) 'Candidate payload hash differs'
    Check ($before.ContainsKey($file.destination)) 'Scanner change unexpectedly added a payload file'
    if($file.destination -ne $recipe.sourceArchive){Check ($file.sha256 -eq $before[$file.destination].sha256) 'Scanner change modified an unrelated source/tweak'}
}
Check ($after.Count -eq $before.Count-1 -and !$after.ContainsKey($recipe.omittedScript)) 'Expected exactly the E3 scanner script to be omitted'
foreach($destination in $before.Keys){Check ($after.ContainsKey($destination) -or $destination -eq $recipe.omittedScript) 'Unexpected dropped payload'}
Check ($after[$recipe.sourceArchive].sha256 -ne $before[$recipe.sourceArchive].sha256) 'Modern candidate retains the original scanner archive'
$provenance=Get-Content -Raw -LiteralPath (Resolve-SafeChildPath $project $candidate.realpassE3.provenance)|ConvertFrom-Json
$reportRelative=[IO.Path]::GetRelativePath($project,$provenance.scannerArchiveReport).Replace('\','/')
$reportPath=Resolve-SafeChildPath $project $reportRelative
$report=Get-Content -Raw -LiteralPath $reportPath|ConvertFrom-Json
Check ($report.passed -and $report.retainedResourcesByteIdentical) 'Archive did not complete content verification'
Check ($report.recipeSha256 -eq (Get-Sha256 $recipePath)) 'Archive recipe changed after build'
Check ($report.sourceSha256 -eq $recipe.expectedArchiveSha256 -and $report.outputSha256 -eq $after[$recipe.sourceArchive].sha256) 'Archive provenance does not match candidate'
Check ($report.sourceResources -eq $recipe.expectedResourceCount -and $report.omittedResources -eq @($recipe.excludedResources).Count) 'Archive source/exclusion count differs'
Check ($report.retainedResources+$report.omittedResources -eq $report.sourceResources) 'Archive content accounting differs'
$resources=@{}
foreach($resource in $report.resources){$resources[$resource.path]=$resource}
$verifyRoot=Resolve-SafeChildPath (Split-Path -Parent $reportPath) 'verified'
foreach($resource in $report.resources){
    Check ((Get-Sha256 (Resolve-SafeChildPath $verifyRoot $resource.path)) -eq $resource.sha256) 'Re-extracted preserved resource differs'
}
foreach($omission in $recipe.excludedResources){
    Check (!$resources.ContainsKey($omission.path) -and !(Test-Path -LiteralPath (Resolve-SafeChildPath $verifyRoot $omission.path))) 'E3 scanner resource remains packed'
}
foreach($path in @('base/gameplay/gui/widgets/healthbar/npcnameplate.inkwidget','base/gameplay/gui/widgets/healthbar/playerhealthbar.inkwidget','base/gameplay/gui/widgets/minimap/minimap.inkwidget','base/gameplay/gui/widgets/interactions/dialog.inkwidget')){
    Check ($resources.ContainsKey($path)) 'Working E3 HUD resource was removed'
}
$toolBuilder=Join-Path $project 'tools/Build-RealpassArchive.ps1'
$unsafeRejected=$false
try { & $toolBuilder -ArchivePath '../outside.archive'|Out-Null } catch {$unsafeRejected=$_.Exception.Message -match 'Unsafe path segment'}
Check $unsafeRejected 'Archive builder accepted an escaping path'
Write-JsonFile ([ordered]@{
    testedAtUtc=[DateTime]::UtcNow.ToString('o')
    passed=$true
    checks=$script:checks
    buildId=$candidate.buildId
    manifestSha256=(Get-Sha256 $candidatePath)
    payloadFiles=$after.Count
    archiveResources=$report.retainedResources
    omittedArchiveResources=$report.omittedResources
    allOtherPayloadsUnchanged=$true
    scope='Actual candidate delta and staged payload verification; archive roundtrip evidence and re-extracted asset hashes, exclusions and working-HUD preservation. Native rendered layout and quickhack behavior remain unverified.'
}) (Join-Path $project 'reports/realpass-modern-scanner-tests.json')
Write-Host "PASS: $($script:checks) modern-scanner candidate/asset checks."
