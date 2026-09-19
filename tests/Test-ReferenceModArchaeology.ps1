$ErrorActionPreference='Stop'
. "$PSScriptRoot\..\tools\Common.ps1"
$project=Get-ProjectRoot

function Read([string]$rel){
    $p=Join-Path $project $rel
    if(-not (Test-Path -LiteralPath $p -PathType Leaf)){throw "Missing reference archaeology contract file: $rel"}
    Get-Content -Raw -LiteralPath $p
}
function Require([string]$text,[string]$pattern,[string]$message){if($text -notmatch $pattern){throw $message}}
function Reject([string]$text,[string]$pattern,[string]$message){if($text -match $pattern){throw $message}}
function Fingerprint([string]$root){
    @(
        Get-ChildItem -LiteralPath $root -Recurse -Force -File |
        Sort-Object FullName |
        ForEach-Object {
            ([IO.Path]::GetRelativePath($root,$_.FullName).Replace('\','/'))+' '+(Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash
        }
    ) -join [Environment]::NewLine
}

$builder=Read 'tools/New-ReferenceModBundle.ps1'
$bootstrap=Read 'tools/Bootstrap-ReferenceModBundle.ps1'
$nativeProbe=Read 'tools/Probe-BiologyDetailNativeRegion.ps1'
$agents=Read 'AGENTS.md'
$catalog=Read 'docs/LOCAL-OPERATOR-COMMANDS.md'
$readme=Read 'docs/reference-mods/README.md'
$schemaText=Read 'docs/reference-mods/reference-record.schema.json'
$templateText=Read 'docs/reference-mods/reference-record.template.json'

Require $bootstrap "'rev-parse','--show-toplevel'" 'Reference bootstrap must validate local checkout candidates through Git.'
Require $bootstrap "'remote','get-url','origin'" 'Reference bootstrap must validate cprealpass origin.'
Require $bootstrap "'clone','--no-checkout'" 'Reference bootstrap must support zero local repo.'
Require $bootstrap 'exact-sha-archive' 'Reference bootstrap must expose an immutable exact-SHA archive acquisition mode.'
Require $bootstrap ([regex]::Escape("https://github.com/natanai/cprealpass/archive/{0}.zip")) 'Reference bootstrap must use an immutable commit-SHA archive URL for fallback acquisition.'
Require $bootstrap ([regex]::Escape('Invoke-WebRequest -Uri $archiveUrl -OutFile $archiveZip')) 'Reference bootstrap must download the exact-SHA archive only through the pinned URL.'
Require $bootstrap ([regex]::Escape('Expand-Archive -LiteralPath $archiveZip')) 'Reference bootstrap must expand the exact-SHA source archive before invoking repository tooling.'
Require $bootstrap 'Exact-SHA archive does not contain the expected Command 18 repository files' 'Reference bootstrap must validate expected repository-owned files after archive extraction.'
Require $bootstrap 'Clone evidence:' 'Reference bootstrap failure diagnostics must preserve clone evidence when archive fallback also fails.'
Require $bootstrap "'fetch','origin'" 'Reference bootstrap must fetch the selected branch before use.'
Require $bootstrap "'cat-file','-e'" 'Reference bootstrap must prove the exact cached commit before offline fallback.'
Require $bootstrap "'worktree','add','--detach'" 'Reference bootstrap must use a disposable exact-head checkout.'
Require $bootstrap 'ATTACH THIS ONE REFERENCE BUNDLE TO CHATGPT:' 'Reference bootstrap must expose one obvious bundle path.'
Reject $bootstrap [regex]::Escape('.git\config') 'Reference bootstrap must not use .git/config-only worktree discovery.'
Reject $bootstrap '(?i)Start-Process.*Cyberpunk|Cyberpunk2077\.exe|Deploy-BiologyRedmod' 'Reference bootstrap must never launch/install/deploy into Cyberpunk.'

Require $builder ([regex]::Escape("sourceMutation='none'")) 'Bundle manifest must declare no source-library mutation.'
Require $builder ([regex]::Escape("else{'not accessed or modified'}")) 'Bundle must preserve no-game-access as the default reference-only boundary.'
Require $builder ([regex]::Escape('gameInstallation=$gameAccess')) 'Bundle manifest must record the resolved game-access boundary.'
Require $builder 'skipped-duplicate-payload' 'Builder must suppress duplicate selected ZIP payload.'
Require $builder 'opaque-no-safe-listing-tool|opaque-tool-could-not-list' 'Builder must represent uninspectable resource containers explicitly.'
Require $builder 'PRIVATE-THIRD-PARTY-REFERENCE' 'Bundle must carry a prominent private-analysis marker.'
Require $builder 'WorkflowSourceRevision' 'Bundle must bind evidence to exact workflow source.'
Require $builder 'SuppressHandoffMarker' 'Inner builder must allow the canonical bootstrap to own the single attach marker.'
Require $bootstrap "'-SuppressHandoffMarker'" 'Bootstrap must suppress the child attach marker before printing its one owner-facing handoff path.'
Require $builder 'IncludeBiologyNativeUi' 'Builder must expose the optional current-game Biology/Cyberware UI companion.'
Require $builder 'ripperdoc\.script' 'Native companion must capture the installed official ripperdoc.script.'
Require $builder 'ripperdocInventoryController\.script' 'Native companion must capture the installed official ripperdocInventoryController.script.'
Require $builder 'Probe-BiologyDetailNativeRegion\.ps1' 'Native companion must reuse the established read-only installed-resource probe.'
Require $builder 'ripperdoc-widget-ancestry\.json' 'Native companion must include the derived widget ancestry artifact when the probe can produce it.'
Require $bootstrap 'IncludeBiologyNativeUi' 'Bootstrap must forward the optional native UI evidence request.'
Require $nativeProbe 'PrivateTargetJsonPath' 'Native-region probe must support preserving the serialized target JSON privately outside Git.'
Require $nativeProbe 'PrivateWidgetAncestryJsonPath' 'Native-region probe must support preserving a derived widget ancestry report privately outside Git.'
Require $nativeProbe 'Get-WidgetAncestryEvidence' 'Native-region probe must derive the authored HandleId parent/child graph from serialized INK evidence.'
Require $nativeProbe 'HANDLE_ID_219_OR_743' 'Native-region probe must preserve targeted object context for the decisive HandleId 219/743 parent evidence.'
Require $nativeProbe 'declaredChildren' 'Native ancestry must preserve child membership/order evidence when present.'
Require $nativeProbe 'fitToContent' 'Native ancestry must preserve fit-to-content evidence.'
Require $nativeProbe 'renderTranslation' 'Native ancestry must preserve authored translation/layout evidence.'
Require $nativeProbe 'Full serialized target JSON may be preserved privately' 'Native-region probe must document its private serialized-resource handoff.'
Require $bootstrap 'ReferenceNameJson' 'Bootstrap must forward multiple selected reference names losslessly as one JSON argument.'
Require $bootstrap 'NativeLive' 'Bootstrap must expose a live-streaming child process path for long reference work.'
Reject $bootstrap 'function Native(?:Live)?\(\[string\]\$exe,\[string\[\]\]\$args\)' 'Command 18 bootstrap native helpers must not shadow PowerShell automatic $args.'
Reject $builder 'function Native(?:Live)?\(\[string\]\$exe,\[string\[\]\]\$args\)' 'Reference builder native helpers must not shadow PowerShell automatic $args.'
Require $bootstrap 'function Native\(\[string\]\$exe,\[string\[\]\]\$arguments\)' 'Bootstrap Native helper must use a non-reserved argument parameter.'
Require $bootstrap 'function NativeLive\(\[string\]\$exe,\[string\[\]\]\$arguments\)' 'Bootstrap NativeLive helper must use a non-reserved argument parameter.'
Require $builder 'function Native\(\[string\]\$exe,\[string\[\]\]\$arguments\)' 'Builder Native helper must use a non-reserved argument parameter.'
Require $builder 'function NativeLive\(\[string\]\$exe,\[string\[\]\]\$arguments\)' 'Builder NativeLive helper must use a non-reserved argument parameter.'
Require $bootstrap ([regex]::Escape('foreach($a in $arguments){[void]$psi.ArgumentList.Add($a)}')) 'Bootstrap native helpers must populate ProcessStartInfo.ArgumentList from the forwarded argument array.'
Reject $bootstrap '\$args\b' 'Command 18 bootstrap must not use PowerShell automatic $args as an ordinary argument variable anywhere.'
Require $bootstrap 'function Git\(\[string\[\]\]\$arguments\)' 'Git helper must use a non-reserved argument parameter.'
Require $bootstrap ([regex]::Escape('$childArgs=@(')) 'Bootstrap must build child invocation in a non-reserved local variable.'
Require $builder ([regex]::Escape('foreach($a in $arguments){[void]$psi.ArgumentList.Add($a)}')) 'Builder native helpers must populate ProcessStartInfo.ArgumentList from the forwarded argument array.'
Require $bootstrap 'REFERENCE BUNDLE WORK STARTING' 'Bootstrap must announce that child progress will stream live.'
Require $bootstrap ([regex]::Escape('$child=NativeLive ''pwsh'' $childArgs')) 'Bootstrap must use live streaming for the long-running child builder.'
Require $builder 'NativeLive' 'Reference builder must support live streaming for long native probe subprocesses.'
Require $builder 'REFERENCE BUNDLE START' 'Reference builder must print an explicit start phase.'
Require $builder 'PHASE 1/4' 'Reference builder must show native-evidence phase progress.'
Require $builder 'PHASE 2/4' 'Reference builder must show reference indexing phase progress.'
Require $builder 'PHASE 3/4' 'Reference builder must show manifest/provenance phase progress.'
Require $builder 'PHASE 4/4' 'Reference builder must show final bundle compression phase progress.'
Require $builder '\[NATIVE 3/4\].*probe' 'Reference builder must visibly announce the potentially long INK/resource probe.'
Require $builder ([regex]::Escape('$probe=NativeLive ''pwsh'' @(')) 'Reference builder must stream the native INK/resource probe output live.'
Require $builder '\[REFERENCE\] Starting' 'Reference builder must show per-reference start progress.'
Require $builder '\[REFERENCE\] Completed' 'Reference builder must show per-reference completion progress.'
Require $bootstrap 'Available private references:' 'Bootstrap must display reference selection in the visible parent process.'
Require $bootstrap ([regex]::Escape("Read-Host 'Enter numbers separated by commas'")) 'Bootstrap must own the interactive reference selection prompt before spawning the redirected child.'
Require $bootstrap ([regex]::Escape('$ReferenceName=@($picked)')) 'Bootstrap must materialize visible selections before invoking the child builder.'
Require $builder 'ZipSingleRoot' 'Builder must recognize ZIP/extracted-folder duplicates by the ZIP sole top-level root as well as basename.'

Require $agents 'REFERENCE-MOD ARCHAEOLOGY GATE' 'AGENTS must require reference archaeology before speculative probing when relevant.'
Require $agents 'mod and any dependencies wanted' 'Worker request convention must name desired mod/dependencies.'
Require $catalog 'Command 18 — private reference-mod archaeology bundle' 'Operator catalog must expose Command 18.'
Require $catalog 'Bootstrap-ReferenceModBundle\.ps1' 'Operator catalog must name the reference bootstrap.'
Require $catalog 'private third-party reference material' 'Operator catalog must prohibit treating private bundles as redistributable repo evidence.'
Require $readme 'redistribution-safe derived knowledge only' 'Reference README must state the Git-safe boundary.'
Require $readme 'exact uncertainty' 'Reference README must require an uncertainty-focused worker request.'

$schema=$schemaText|ConvertFrom-Json -Depth 30
if($schema.title -notmatch 'redistribution-safe'){throw 'Reference record schema title must identify redistribution-safe scope.'}
if($schema.properties.source.properties.selectedIdentities.items.properties.sha256.pattern -ne '^[0-9A-Fa-f]{64}$'){throw 'Reference record schema must require SHA-256 identities.'}
$template=$templateText|ConvertFrom-Json -Depth 30
if($template.schemaVersion -ne 1){throw 'Reference record template schemaVersion mismatch.'}
if(-not $schema.properties.mappings.items.properties.widgetAncestry){throw 'Reference record schema must support redistribution-safe derived widget ancestry.'}
if(-not $template.mappings[0].widgetAncestry){throw 'Reference record template must demonstrate derived widget ancestry without proprietary object bodies.'}

$temp=Join-Path ([IO.Path]::GetTempPath()) ('biology-reference-test-'+[guid]::NewGuid().ToString('N'))
$library=Join-Path $temp 'library'
$out=Join-Path $temp 'out'
$mod=Join-Path $library 'Project E3'
$expanded=Join-Path $temp 'expanded'
try{
    New-Item -ItemType Directory -Force -Path (Join-Path $mod 'scripts'),(Join-Path $mod 'config'),(Join-Path $mod 'archive\pc\mod'),$out|Out-Null
    @(
      '# Project E3 fixture',
      'Version: 2.31.2',
      'Requires redscript and TweakXL'
    )|Set-Content -LiteralPath (Join-Path $mod 'README.md') -Encoding utf8
    @(
      '@wrapMethod(NameplateVisualsLogicController)',
      'protected cb func OnInitialize() -> Bool {',
      '  let x: inkWidget;',
      '}'
    )|Set-Content -LiteralPath (Join-Path $mod 'scripts\hud.reds') -Encoding utf8
    '{"name":"Project E3 fixture","version":"2.31.2","dependencies":{"TweakXL":"test"}}'|Set-Content -LiteralPath (Join-Path $mod 'config\info.json') -Encoding utf8
    [IO.File]::WriteAllBytes((Join-Path $mod 'archive\pc\mod\e3.archive'),[byte[]](1,2,3,4,5,6,7,8))
    Compress-Archive -Path $mod -DestinationPath (Join-Path $library 'Downloaded E3 Package.zip') -CompressionLevel Fastest

    $before=Fingerprint $library
    $sourceRevision='aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
    $bundle=& (Join-Path $project 'tools\New-ReferenceModBundle.ps1') -LibraryPath $library -ReferenceName @('Project E3','Downloaded E3 Package.zip') -OutputRoot $out -WorkflowSourceRevision $sourceRevision
    if(-not $?){throw 'Reference builder invocation failed.'}
    $bundlePath=[string](@($bundle)[-1])
    if(-not (Test-Path -LiteralPath $bundlePath -PathType Leaf)){throw "Reference bundle missing: $bundlePath"}
    $after=Fingerprint $library
    if($before -ne $after){throw 'Reference builder mutated the source reference library.'}

    Expand-Archive -LiteralPath $bundlePath -DestinationPath $expanded
    foreach($required in @('manifest.json','file-index.json','signals.json','report.txt','PRIVATE-THIRD-PARTY-REFERENCE.txt')){
        if(-not (Test-Path -LiteralPath (Join-Path $expanded $required) -PathType Leaf)){throw "Bundle missing required member: $required"}
    }
    $manifest=Get-Content -Raw -LiteralPath (Join-Path $expanded 'manifest.json')|ConvertFrom-Json -Depth 30
    if($manifest.workflowSourceRevision -ne $sourceRevision){throw 'Bundle did not record exact workflow source revision.'}
    if($manifest.sourceMutation -ne 'none'){throw 'Bundle does not prove source mutation boundary.'}
    if($manifest.gameInstallation -ne 'not accessed or modified'){throw 'Bundle does not prove game-install boundary.'}
    if(@($manifest.provenanceVersionNotes|Where-Object {$_ -match 'version=2\.31\.2'}).Count -lt 1){throw 'Discoverable reference version metadata was not recorded.'}
    if(@($manifest.provenanceVersionNotes|Where-Object {$_ -match 'dependency=TweakXL'}).Count -lt 1){throw 'Discoverable dependency metadata was not recorded.'}
    $dup=@($manifest.referenceSelections|Where-Object name -eq 'Downloaded E3 Package.zip')
    if($dup.Count -ne 1 -or $dup[0].status -ne 'skipped-duplicate-payload' -or $dup[0].duplicateOf -ne 'Project E3'){throw 'Selected extracted folder did not suppress differently named ZIP payload with the same sole root.'}

    if(-not (Test-Path -LiteralPath (Join-Path $expanded 'payload\Project_E3\README.md') -PathType Leaf)){throw 'README metadata was not exposed in private payload.'}
    if(-not (Test-Path -LiteralPath (Join-Path $expanded 'payload\Project_E3\scripts\hud.reds') -PathType Leaf)){throw 'redscript source was not exposed in private payload.'}
    if(Test-Path -LiteralPath (Join-Path $expanded 'payload\Project_E3\archive\pc\mod\e3.archive')){throw 'Binary archive payload must not be copied into private text payload.'}

    $idx=@(Get-Content -Raw -LiteralPath (Join-Path $expanded 'file-index.json')|ConvertFrom-Json -Depth 30)
    $resource=@($idx|Where-Object path -eq 'archive/pc/mod/e3.archive')
    if($resource.Count -ne 1 -or $resource[0].classification -ne 'archive/resource-container'){throw 'Resource archive was not hash/inventory classified.'}
    if(-not $resource[0].sha256 -or $resource[0].sha256.Length -ne 64){throw 'Resource archive SHA-256 missing.'}

    $sig=@(Get-Content -Raw -LiteralPath (Join-Path $expanded 'signals.json')|ConvertFrom-Json -Depth 30)
    if(@($sig|Where-Object kind -eq 'redscript-hook').Count -lt 1){throw 'redscript hook signal was not extracted.'}
    if(@($sig|Where-Object kind -eq 'framework').Count -lt 1){throw 'dependency/framework signal was not extracted.'}

    # The native-game companion is optional and must fail transparently without
    # suppressing the third-party reference bundle when current game evidence is unavailable.
    $nativeOut=Join-Path $temp 'native-out'
    New-Item -ItemType Directory -Path $nativeOut|Out-Null
    $nativeBundle=& (Join-Path $project 'tools\New-ReferenceModBundle.ps1') -LibraryPath $library -ReferenceName @('Project E3') -OutputRoot $nativeOut -WorkflowSourceRevision $sourceRevision -IncludeBiologyNativeUi -GamePath (Join-Path $temp 'missing-game')
    $nativeBundlePath=[string](@($nativeBundle)[-1])
    if(-not (Test-Path -LiteralPath $nativeBundlePath -PathType Leaf)){throw 'Native-companion transparent-failure bundle was not produced.'}
    $nativeExpanded=Join-Path $temp 'native-expanded'
    Expand-Archive -LiteralPath $nativeBundlePath -DestinationPath $nativeExpanded
    $nativeManifest=Get-Content -Raw -LiteralPath (Join-Path $nativeExpanded 'manifest.json')|ConvertFrom-Json -Depth 30
    if($nativeManifest.nativeBiologyUi.status -ne 'failed-transparent'){throw 'Unavailable native UI sub-capability did not fail transparently inside the private bundle.'}
    if($nativeManifest.gameInstallation -notmatch '^read-only native UI inspection requested'){throw 'Native companion manifest did not preserve its read-only game boundary.'}
    if(-not (Test-Path -LiteralPath (Join-Path $nativeExpanded 'native-game-evidence\collection-failure.txt') -PathType Leaf)){throw 'Transparent native companion failure report is missing.'}
}finally{
    if(Test-Path -LiteralPath $temp){Remove-Item -LiteralPath $temp -Recurse -Force}
}

Write-Host 'PASS: private reference-mod archaeology is exact-source, read-only, duplicate-aware, private-payload bounded, hash-inventoried, opaque-safe, and constrained to redistribution-safe derived Git records.'
