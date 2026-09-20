param([string]$ManifestPath='manifest/m3-body-runtime-prototype.deployment.json')
. "$PSScriptRoot/../tools/Common.ps1"
$project = Get-ProjectRoot
$script:checks = 0
function Check([bool]$Condition,[string]$Message) { if (-not $Condition) { throw $Message }; $script:checks++ }
function Reject([scriptblock]$Action,[string]$Message) { $rejected=$false; try { & $Action | Out-Null } catch { $rejected=$true }; Check $rejected $Message }
$configPath = Join-Path $project 'config/realpass-e3.json'
$config = Get-Content -Raw -LiteralPath $configPath | ConvertFrom-Json
$basePath = Resolve-SafeChildPath $project $ManifestPath
$baseHash = Get-Sha256 $basePath
$base = Get-Content -Raw -LiteralPath $basePath | ConvertFrom-Json
$livePointer = Join-Path $project 'snapshots/deployment-state/current.json'
$liveHash = if (Test-Path -LiteralPath $livePointer) { Get-Sha256 $livePointer } else { $null }
$fixtureRelative = 'staging/e3-tests-' + [guid]::NewGuid().ToString('N')
$fixture = Resolve-SafeChildPath $project $fixtureRelative
foreach ($directory in @('tools','config','manifest','reports','source')) { New-Item -ItemType Directory -Force -Path (Join-Path $fixture $directory) | Out-Null }
foreach ($name in @('Common.ps1','Build-RealpassPresentation.ps1')) { Copy-Item -LiteralPath (Join-Path $project ('tools/'+$name)) -Destination (Join-Path $fixture ('tools/'+$name)) }
Copy-Item -LiteralPath $configPath -Destination (Join-Path $fixture 'config/realpass-e3.json')
foreach ($file in $config.files) {
    $input = Resolve-SafeChildPath $project ($config.referenceRoot+'/'+$file.path)
    $target = Resolve-SafeChildPath $fixture ($config.referenceRoot+'/'+$file.path)
    Copy-VerifiedPayload $input $target $file.sha256
}
$df = @($base.files | Where-Object destination -eq 'r6/scripts/Dark Future/Settings/DFSettings.reds')[0]
$dfSource = Resolve-SafeChildPath $project $df.source
Copy-VerifiedPayload $dfSource (Join-Path $fixture 'source/DFSettings.reds') $df.sha256
$dialogue = @($base.files | Where-Object destination -eq 'r6/scripts/Dark Future/Gameplay/DFInteractionSystem.reds')[0]
Copy-VerifiedPayload (Resolve-SafeChildPath $project $dialogue.source) (Join-Path $fixture 'source/DFInteractionSystem.reds') $dialogue.sha256
New-Item -ItemType Directory -Force (Join-Path $fixture 'config/patches') | Out-Null
Copy-Item -LiteralPath (Join-Path $project 'config/patches/darkfuture-e3-dialogue.json') -Destination (Join-Path $fixture 'config/patches/darkfuture-e3-dialogue.json')
foreach ($path in @('config/patches/realpass-e3-nameplates.json','patches/project-e3-hud/realpassNameplates.reds')) {
    $source = Resolve-SafeChildPath $project $path
    Copy-VerifiedPayload $source (Resolve-SafeChildPath $fixture $path) (Get-Sha256 $source)
}
$fixtureManifest = [ordered]@{schemaVersion=1;buildId='fixture-base';gameVersion='2.31';files=@([ordered]@{source='source/DFSettings.reds';destination=$df.destination;component='darkfuture';sha256=$df.sha256})}
$fixtureManifest.files += [ordered]@{source='source/DFInteractionSystem.reds';destination=$dialogue.destination;component='darkfuture';sha256=$dialogue.sha256}
$fixtureManifestPath = Join-Path $fixture 'manifest/base.json'
Write-JsonFile $fixtureManifest $fixtureManifestPath
$fixtureBaseHash = Get-Sha256 $fixtureManifestPath
$builder = Join-Path $fixture 'tools/Build-RealpassPresentation.ps1'
& $builder -BuildId 'fixture-e3' -ManifestPath 'manifest/base.json' -ScannerMode E3
$outputPath = Join-Path $fixture 'manifest/fixture-e3.deployment.json'
$output = Get-Content -Raw -LiteralPath $outputPath | ConvertFrom-Json
$report = Get-Content -Raw -LiteralPath (Join-Path $fixture 'reports/presentation-fixture-e3.json') | ConvertFrom-Json
Check (@($output.files).Count -eq 39) 'Expected unchanged base membership plus 36 E3 files and one support script'
Check ($output.realpassE3.includesRestrictedThirdPartyAssets -and $output.realpassE3.distribution -eq 'local-integration-only') 'Restricted third-party metadata missing'
Check (-not $report.compiled -and -not $report.installed -and -not $report.persistedSettingsFilesChanged) 'Stager falsely claimed runtime work'
Check ((Get-Sha256 $fixtureManifestPath) -eq $fixtureBaseHash) 'Base manifest mutated'
Check ((Get-Sha256 (Join-Path $fixture 'source/DFSettings.reds')) -eq $df.sha256) 'Original DF settings mutated'
foreach ($file in $output.files) { Check ((Get-Sha256 (Resolve-SafeChildPath $fixture $file.source)) -eq $file.sha256) ('Staged hash mismatch: '+$file.destination) }
Check (@($output.files | Where-Object destination -like '*desktop.ini').Count -eq 0) 'Desktop metadata became payload'
$archive = @($output.files | Where-Object destination -like '*.archive')[0]
Check ($archive.sha256 -eq @($config.files | Where-Object path -like '*.archive')[0].sha256) 'E3 archive bytes changed'
$settings = @($output.files | Where-Object destination -eq 'r6/scripts/Project E3 - HUD/core/ModSettings.reds')[0]
$text = [IO.File]::ReadAllText((Resolve-SafeChildPath $fixture $settings.source))
Check ($text.Contains('class ProjectE3HUDSettings') -and $text.Contains('"ModSettings.mod", "realpass (E3 HUD)"')) 'Grouping changed internal settings identity'
Check ($text.Contains('let EnableCompassPOIs: Bool = false;') -and $text.Contains('let ShowEnemyLevel: Bool = false;') -and $text.Contains('let EnablePoliceBlink: Bool = false;')) 'Minimal defaults absent'
foreach ($path in @('r6/tweaks/Project E3 - HUD/ui/npc/schema.yaml','r6/tweaks/Project E3 - HUD/ui/npc/nameplate.yaml')) {
    $entry = @($output.files | Where-Object destination -eq $path)[0]
    $text = [IO.File]::ReadAllText((Resolve-SafeChildPath $fixture $entry.source))
    Check (@($text -split '\r?\n' | Where-Object {$_ -match '^\s*[^#\s]'}).Count -eq 0) 'Blanket nameplate records remain active'
}
$entry = @($output.files | Where-Object destination -like '*healthbar/npcNamePlate.reds')[0]
$text = [IO.File]::ReadAllText((Resolve-SafeChildPath $fixture $entry.source))
Check (-not $text.Contains('@wrapMethod(NpcNameplateGameController)') -and $text.Contains('GetDisplayRangeNotAggressive')) 'Forced name visibility remains or range configuration vanished'
$entry = @($output.files | Where-Object destination -like '*healthbar/nameplateVisuals.reds')[0]
$text = [IO.File]::ReadAllText((Resolve-SafeChildPath $fixture $entry.source))
Check ($text.Contains('return data.name;') -and -not $text.Contains('record.FullDisplayName()')) 'Name discovery bypasses native-provided data'
Check ($text.Contains('return this.RealpassScannedCrowdName(data.npc);') -and $text.Contains('let showNameplate: Bool = !isTurret && this.m_npcNamesEnabled && IsStringValid')) 'Scanned fallback or empty-frame guard missing'
$support = @($output.files | Where-Object destination -eq 'r6/scripts/realpass/Presentation/realpassNameplates.reds')
Check ($support.Count -eq 1 -and $report.scriptFilesAdded -eq 23) 'Nameplate support absent from staged payload'
Check ($support[0].sha256 -eq (Get-Sha256 (Join-Path $project 'patches/project-e3-hud/realpassNameplates.reds'))) 'Support source altered during staging'
$entry = @($output.files | Where-Object destination -eq $df.destination)[0]
$text = [IO.File]::ReadAllText((Resolve-SafeChildPath $fixture $entry.source))
Check ($text.Contains('instance.compatibilityProjectE3HUD = true;') -and [regex]::Matches($text,'this\.compatibilityProjectE3HUD = true;').Count -eq 2) 'Runtime compatibility gates absent'
Check ($text.Contains('instance.compatibilityProjectE3UI = false;') -and [regex]::Matches($text,'this\.compatibilityProjectE3UI = false;').Count -eq 2) 'Missing separate-UI compatibility guard'
$entry = @($output.files | Where-Object destination -eq $dialogue.destination)[0]
$text = [IO.File]::ReadAllText((Resolve-SafeChildPath $fixture $entry.source))
Check ($text.Contains('this.m_humanityLossHolder.GetParentWidget() as inkCompoundWidget') -and $text.Contains('if IsDefined(parent) { parent.RemoveChild(this.m_humanityLossHolder); }')) 'Caption cleanup does not use its actual guarded owner'
Check ($text.Contains('while IsDefined(hubWidget) && depth < 4') -and $text.Contains('IsDefined(hubVert) && hubVert.GetNumChildren()')) 'Caption hierarchy remains unsafe'
Check ((Get-Sha256 (Join-Path $fixture 'source/DFInteractionSystem.reds')) -eq $dialogue.sha256) 'Original dialogue source mutated'
$publishedHash = Get-Sha256 $outputPath
Reject { & $builder -BuildId 'fixture-e3' -ManifestPath 'manifest/base.json' -ScannerMode E3 } 'Existing build ID was overwritten'
Check ((Get-Sha256 $outputPath) -eq $publishedHash) 'Rejected reuse mutated the published build'
$first = @($config.files | Where-Object path -like '*.reds')[0]
$tamperPath = Resolve-SafeChildPath $fixture ($config.referenceRoot+'/'+$first.path)
$originalBytes = [IO.File]::ReadAllBytes($tamperPath)
try {
    [IO.File]::AppendAllText($tamperPath,'// tamper')
    Reject { & $builder -BuildId 'fixture-tampered' -ManifestPath 'manifest/base.json' -ScannerMode E3 } 'Changed reference bytes accepted'
    Check (-not (Test-Path -LiteralPath (Join-Path $fixture 'manifest/fixture-tampered.deployment.json'))) 'Failed reference validation published a manifest'
} finally { [IO.File]::WriteAllBytes($tamperPath,$originalBytes) }
$extraPath = Resolve-SafeChildPath $fixture ($config.referenceRoot+'/extra.reds')
[IO.File]::WriteAllText($extraPath,'// unexpected reference file')
try { Reject { & $builder -BuildId 'fixture-extra' -ManifestPath 'manifest/base.json' -ScannerMode E3 } 'Unindexed reference payload accepted' } finally { Remove-Item -LiteralPath $extraPath }
$collision = $fixtureManifest | ConvertTo-Json -Depth 8 | ConvertFrom-Json
$collision.files += [pscustomobject]@{source='source/DFSettings.reds';destination=$first.path;component='other';sha256=$df.sha256}
Write-JsonFile $collision (Join-Path $fixture 'manifest/collision.json')
Reject { & $builder -BuildId 'fixture-collision' -ManifestPath 'manifest/collision.json' -ScannerMode E3 } 'Destination collision accepted'
Reject { & $builder -BuildId 'fixture-path' -ManifestPath '../manifest/base.json' -ScannerMode E3 } 'Unsafe base path accepted'
Check ((Get-Sha256 $basePath) -eq $baseHash) 'Real base profile mutated by fixture'
if ($null -ne $liveHash) { Check ((Get-Sha256 $livePointer) -eq $liveHash) 'Live receipt changed' }
Write-JsonFile ([ordered]@{passed=$true;checks=$script:checks;fixture=$fixtureRelative;baseManifest=$ManifestPath;builderSha256=(Get-Sha256 (Join-Path $project 'tools/Build-RealpassPresentation.ps1'));configSha256=(Get-Sha256 $configPath);scope='Actual staging/immutability/hash/collision/name-policy checks in an isolated fixture. No native UI, full compilation, game or deployment.'}) (Join-Path $project 'reports/realpass-e3-tests.json')
Write-Host "realpass E3 staging checks passed: $script:checks"
