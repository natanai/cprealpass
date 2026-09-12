. "$PSScriptRoot\..\tools\Common.ps1"
$project=Get-ProjectRoot
$relative='staging/source-patch-fixture-'+[guid]::NewGuid().ToString('N')
$work=Resolve-SafeChildPath $project $relative
New-Item -ItemType Directory -Path $work|Out-Null
[IO.File]::WriteAllText((Join-Path $work 'a.reds'),'alpha beta')
[IO.File]::WriteAllText((Join-Path $work 'b.reds'),'gamma delta')
$manifest=[ordered]@{buildId='source-patch-fixture';files=@(
 [ordered]@{source="$relative/a.reds";destination='r6/scripts/a.reds';component='darkfuture';sha256=(Get-Sha256 (Join-Path $work 'a.reds'))},
 [ordered]@{source="$relative/b.reds";destination='r6/scripts/b.reds';component='darkfuture';sha256=(Get-Sha256 (Join-Path $work 'b.reds'))}
)}
$patch=[ordered]@{schemaVersion=1;id='source-patch-fixture';component='darkfuture';sourceVersion='fixture';license='test';sourceUrl='local fixture';description='Regression fixture only';patches=@(
 [ordered]@{destination='r6/scripts/a.reds';expectedSha256=$manifest.files[0].sha256;edits=@([ordered]@{find='alpha';replace='one';expectedOccurrences=1},[ordered]@{find='beta';replace='two';expectedOccurrences=1})},
 [ordered]@{destination='r6/scripts/b.reds';expectedSha256=$manifest.files[1].sha256;find='gamma';replace='three';expectedOccurrences=1}
)}
$script:checks=0
function Check($condition,$message){if(-not $condition){throw $message};$script:checks++}
Write-JsonFile $manifest (Join-Path $work 'manifest.json')
Write-JsonFile $patch (Join-Path $work 'patch.json')
& "$project/tools/Apply-SourcePatch.ps1" -ManifestPath "$relative/manifest.json" -PatchPath "$relative/patch.json"
$built=Get-Content -Raw (Join-Path $work 'manifest.json')|ConvertFrom-Json
$a=Get-Content -Raw (Resolve-SafeChildPath $project $built.files[0].source)
$b=Get-Content -Raw (Resolve-SafeChildPath $project $built.files[1].source)
Check ($a.EndsWith('one two')) 'Multiple edits not composed into the same source'
Check ($b.EndsWith('three delta')) 'Legacy single-edit form broke'
Check ($a.Contains('Original: DarkFortuneTeller/DarkFuture')) 'Adaptation attribution lost'
Check ((Get-Sha256 (Join-Path $work 'a.reds')) -eq $manifest.files[0].sha256) 'Pinned source modified in place'
foreach($kind in @('missing-match','wrong-hash','empty-edits','duplicate-destination')) {
 $candidate=$patch|ConvertTo-Json -Depth 12|ConvertFrom-Json
 switch($kind){
  'missing-match' {$candidate.patches[1].find='absent'}
  'wrong-hash' {$candidate.patches[1].expectedSha256=('0'*64)}
  'empty-edits' {$candidate.patches[0].edits=@()}
  'duplicate-destination' {$candidate.patches[1].destination=$candidate.patches[0].destination}
 }
 Write-JsonFile $manifest (Join-Path $work 'manifest.json')
 Write-JsonFile $candidate (Join-Path $work 'patch.json')
 $before=Get-Sha256 (Join-Path $work 'manifest.json')
 $stages=@(Get-ChildItem (Join-Path $project 'staging') -Directory -Filter 'patch-source-patch-fixture-*').Count
 $failed=$false
 try { & "$project/tools/Apply-SourcePatch.ps1" -ManifestPath "$relative/manifest.json" -PatchPath "$relative/patch.json" } catch { $failed=$true }
 Check $failed "Invalid patch accepted: $kind"
 Check ((Get-Sha256 (Join-Path $work 'manifest.json')) -eq $before) "Manifest partially updated: $kind"
 Check (@(Get-ChildItem (Join-Path $project 'staging') -Directory -Filter 'patch-source-patch-fixture-*').Count -eq $stages) "Partial patched payload written before full validation: $kind"
}
Write-JsonFile ([ordered]@{testedAtUtc=[DateTime]::UtcNow.ToString('o');passed=$true;assertions=$script:checks;scope='Actual source patch helper: multi-edit composition, legacy input, attribution, immutable source, and no partial mutation on invalid later edits.'}) (Join-Path $project 'reports/source-patch-tests.json')
Write-Host "PASS: $script:checks source-patch safety checks."
