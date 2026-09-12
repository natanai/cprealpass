param([string]$ManifestPath = 'manifest/m3-body-alpha1.deployment.json')
. "$PSScriptRoot\Common.ps1"
$project=Get-ProjectRoot
$manifestPathFull=Resolve-SafeChildPath $project $ManifestPath
$manifest=Get-Content -Raw $manifestPathFull | ConvertFrom-Json
$preset=Get-Content -Raw (Join-Path $project 'config\body-alpha1.json') | ConvertFrom-Json
$matches=@($manifest.files | Where-Object destination -eq 'r6/scripts/Dark Future/Settings/DFSettings.reds')
if($matches.Count -ne 1){throw 'Expected exactly one Dark Future settings source.'}
$file=$matches[0]
$path=Resolve-SafeChildPath $project $file.source
if((Get-Sha256 $path) -ne $preset.sourceSha256){throw 'Preset requires the exact unmodified release source. Restage before reapplying.'}
$content=Get-Content -Raw -LiteralPath $path
foreach($setting in $preset.settings){
    $pattern='(?m)^(\s*public let '+[regex]::Escape($setting.name)+': [A-Za-z0-9_]+ = )'+[regex]::Escape($setting.expected)+';'
    $regex=[regex]::new($pattern)
    if($regex.Matches($content).Count -ne 1){throw "Setting missing or changed upstream: $($setting.name)"}
    $value=$setting.value
    $content=$regex.Replace($content, [System.Text.RegularExpressions.MatchEvaluator]{param($match) $match.Groups[1].Value+$value+';'})
}
$notice="// Local adaptation: Cyberpunk Realism restrained-body-alpha1. Changes: project defaults only.`n// Original: DarkFortuneTeller/DarkFuture, 2.0-release, CC BY-SA 4.0.`n// https://github.com/DarkFortuneTeller/DarkFuture ; https://creativecommons.org/licenses/by-sa/4.0/`n"
[IO.File]::WriteAllText($path,$notice+$content)
$file.sha256=Get-Sha256 $path
Write-JsonFile $manifest $manifestPathFull
Write-JsonFile ([ordered]@{preset=$preset.id;originalSha256=$preset.sourceSha256;patchedSha256=$file.sha256;changes=$preset.settings}) (Join-Path $project 'reports\body-alpha1-preset.json')
Write-Host "Applied $($preset.settings.Count) checked defaults; updated manifest hash."
