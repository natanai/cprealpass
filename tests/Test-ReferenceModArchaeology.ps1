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
$agents=Read 'AGENTS.md'
$catalog=Read 'docs/LOCAL-OPERATOR-COMMANDS.md'
$readme=Read 'docs/reference-mods/README.md'
$schemaText=Read 'docs/reference-mods/reference-record.schema.json'
$templateText=Read 'docs/reference-mods/reference-record.template.json'

Require $bootstrap "'rev-parse','--show-toplevel'" 'Reference bootstrap must validate local checkout candidates through Git.'
Require $bootstrap "'remote','get-url','origin'" 'Reference bootstrap must validate cprealpass origin.'
Require $bootstrap "'clone','--no-checkout'" 'Reference bootstrap must support zero local repo.'
Require $bootstrap "'fetch','origin'" 'Reference bootstrap must fetch the selected branch before use.'
Require $bootstrap "'cat-file','-e'" 'Reference bootstrap must prove the exact cached commit before offline fallback.'
Require $bootstrap "'worktree','add','--detach'" 'Reference bootstrap must use a disposable exact-head checkout.'
Require $bootstrap 'ATTACH THIS ONE REFERENCE BUNDLE TO CHATGPT:' 'Reference bootstrap must expose one obvious bundle path.'
Reject $bootstrap [regex]::Escape('.git\config') 'Reference bootstrap must not use .git/config-only worktree discovery.'
Reject $bootstrap '(?i)Start-Process.*Cyberpunk|Cyberpunk2077\.exe|Deploy-BiologyRedmod' 'Reference bootstrap must never launch/install/deploy into Cyberpunk.'

Require $builder 'sourceMutation=.none.|sourceMutation=''none''' 'Bundle manifest must declare no source-library mutation.'
Require $builder 'gameInstallation=.not accessed or modified.|gameInstallation=''not accessed or modified''' 'Bundle manifest must declare no game installation access.'
Require $builder 'skipped-duplicate-payload' 'Builder must suppress duplicate selected ZIP payload.'
Require $builder 'opaque-no-safe-listing-tool|opaque-tool-could-not-list' 'Builder must represent uninspectable resource containers explicitly.'
Require $builder 'PRIVATE-THIRD-PARTY-REFERENCE' 'Bundle must carry a prominent private-analysis marker.'
Require $builder 'WorkflowSourceRevision' 'Bundle must bind evidence to exact workflow source.'

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
    Compress-Archive -Path $mod -DestinationPath (Join-Path $library 'Project E3.zip') -CompressionLevel Fastest

    $before=Fingerprint $library
    $sourceRevision='aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
    $bundle=& (Join-Path $project 'tools\New-ReferenceModBundle.ps1') -LibraryPath $library -ReferenceName @('Project E3','Project E3.zip') -OutputRoot $out -WorkflowSourceRevision $sourceRevision
    if($LASTEXITCODE -and $LASTEXITCODE -ne 0){throw "Reference builder returned exit $LASTEXITCODE"}
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
    $dup=@($manifest.referenceSelections|Where-Object name -eq 'Project E3.zip')
    if($dup.Count -ne 1 -or $dup[0].status -ne 'skipped-duplicate-payload'){throw 'Selected extracted folder did not suppress duplicate ZIP payload.'}

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
}finally{
    if(Test-Path -LiteralPath $temp){Remove-Item -LiteralPath $temp -Recurse -Force}
}

Write-Host 'PASS: private reference-mod archaeology is exact-source, read-only, duplicate-aware, private-payload bounded, hash-inventoried, opaque-safe, and constrained to redistribution-safe derived Git records.'
