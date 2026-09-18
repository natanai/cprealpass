[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$Branch,
    [Parameter(Mandatory=$true)][ValidatePattern('^[0-9a-fA-F]{40}$')][string]$ExpectedHead,
    [string]$GamesRoot = 'C:\Games',
    [string]$LibraryPath = 'C:\Games\Cyberpunk-ReferenceMods',
    [string[]]$ReferenceName,
    [string]$OutputRoot = 'C:\Games\Biology-Reference-Bundles'
)

$ErrorActionPreference='Stop'
if($PSVersionTable.PSVersion.Major -lt 7){throw 'PowerShell 7 or newer is required.'}
$GamesRoot=[IO.Path]::GetFullPath($GamesRoot)
$LibraryPath=[IO.Path]::GetFullPath($LibraryPath)
$OutputRoot=[IO.Path]::GetFullPath($OutputRoot)
$repoUrl='https://github.com/natanai/cprealpass.git'
$repoPattern='(?i)(?:github\.com[/:])natanai/cprealpass(?:\.git)?$'
$stamp=[DateTime]::Now.ToString('yyyyMMdd-HHmmss')+'-'+[guid]::NewGuid().ToString('N').Substring(0,8)
$seed=$null;$worktree=$null;$createdSeed=$false;$child=$null;$finalBundle=$null

function Under([string]$child,[string]$parent){
    $c=[IO.Path]::GetFullPath($child).TrimEnd('\')+'\'
    $p=[IO.Path]::GetFullPath($parent).TrimEnd('\')+'\'
    $c.StartsWith($p,[StringComparison]::OrdinalIgnoreCase)
}
function Native([string]$exe,[string[]]$args){
    $psi=[Diagnostics.ProcessStartInfo]::new()
    $psi.FileName=$exe;$psi.UseShellExecute=$false;$psi.RedirectStandardOutput=$true;$psi.RedirectStandardError=$true;$psi.CreateNoWindow=$true
    foreach($a in $args){[void]$psi.ArgumentList.Add($a)}
    $p=[Diagnostics.Process]::new();$p.StartInfo=$psi
    try{
        if(-not $p.Start()){throw "Could not start $exe"}
        $o=$p.StandardOutput.ReadToEnd();$e=$p.StandardError.ReadToEnd();$p.WaitForExit()
        [pscustomobject]@{ExitCode=$p.ExitCode;StdOut=$o;StdErr=$e}
    }finally{$p.Dispose()}
}
function Git([string[]]$args){Native 'git' $args}
function SeedRepo {
    foreach($d in @(Get-ChildItem -LiteralPath $GamesRoot -Directory -ErrorAction SilentlyContinue)){
        $top=Git @('-C',$d.FullName,'rev-parse','--show-toplevel')
        if($top.ExitCode -ne 0){continue}
        $origin=Git @('-C',$d.FullName,'remote','get-url','origin')
        if($origin.ExitCode -ne 0 -or $origin.StdOut.Trim() -notmatch $repoPattern){continue}
        return $d.FullName
    }
    $null
}
function ResolveHead([string]$repo){
    $remoteRef="refs/remotes/origin/$Branch"
    $fetch=Git @('-C',$repo,'fetch','origin',("+refs/heads/{0}:{1}" -f $Branch,$remoteRef))
    if($fetch.ExitCode -eq 0){
        $r=Git @('-C',$repo,'rev-parse','--verify',$remoteRef)
        if($r.ExitCode -ne 0){throw 'Fetched branch ref could not be resolved.'}
        $head=$r.StdOut.Trim()
        if($head -ne $ExpectedHead){throw "Branch head moved. Expected $ExpectedHead but fetched $head."}
        return $head
    }
    $cached=Git @('-C',$repo,'rev-parse','--verify',$remoteRef)
    if($cached.ExitCode -ne 0){throw "Fetch failed and no cached origin/$Branch exists."}
    $head=$cached.StdOut.Trim()
    if($head -ne $ExpectedHead){throw "Fetch failed and cached origin/$Branch is $head, not expected $ExpectedHead."}
    $obj=Git @('-C',$repo,'cat-file','-e',("{0}^{{commit}}" -f $ExpectedHead))
    if($obj.ExitCode -ne 0){throw "Cached ref matches but commit object $ExpectedHead is unavailable."}
    Write-Host 'Exact-head cached-origin fallback accepted.' -ForegroundColor Yellow
    $head
}
function FailureBundle([string]$message){
    New-Item -ItemType Directory -Force -Path $OutputRoot|Out-Null
    $tmp=Join-Path $OutputRoot ('reference-failure-'+$stamp)
    New-Item -ItemType Directory -Path $tmp|Out-Null
    $path=Join-Path $OutputRoot ('Biology-Private-ReferenceBundle-FAIL-CLOSED-'+$stamp+'.zip')
    @(
      'BIOLOGY PRIVATE REFERENCE-MOD ARCHAEOLOGY - FAIL CLOSED',
      ('Time UTC: '+[DateTime]::UtcNow.ToString('o')),
      ('Branch: '+$Branch),
      ('Expected head: '+$ExpectedHead),
      ('Library: '+$LibraryPath),
      ('Error: '+$message),
      ('Seed checkout: '+$seed),
      ('Disposable checkout: '+$worktree),
      '',
      'No reference mod was installed into Cyberpunk.',
      'No source reference-library file was intentionally modified.',
      '',
      'CHILD STDOUT',
      $(if($child){$child.StdOut}else{''}),
      'CHILD STDERR',
      $(if($child){$child.StdErr}else{''})
    )|Set-Content -LiteralPath (Join-Path $tmp 'report.txt') -Encoding utf8
    @(
      'PRIVATE REFERENCE WORKFLOW FAILURE BUNDLE',
      'This contains diagnostic text only. It is not a successful reference payload.'
    )|Set-Content -LiteralPath (Join-Path $tmp 'PRIVATE-THIRD-PARTY-REFERENCE.txt') -Encoding utf8
    Compress-Archive -Path (Join-Path $tmp '*') -DestinationPath $path -CompressionLevel Optimal
    Remove-Item -LiteralPath $tmp -Recurse -Force
    $path
}

try{
    if(-not (Test-Path -LiteralPath $GamesRoot -PathType Container)){throw "Games root missing: $GamesRoot"}
    if(-not (Test-Path -LiteralPath $LibraryPath -PathType Container)){throw "Reference library missing: $LibraryPath"}
    if(Under $OutputRoot $LibraryPath){throw 'OutputRoot must be outside the reference library.'}
    New-Item -ItemType Directory -Force -Path $OutputRoot|Out-Null
    if(-not (Get-Command git -ErrorAction SilentlyContinue)){throw 'git is not available on PATH.'}
    if(-not (Get-Command pwsh -ErrorAction SilentlyContinue)){throw 'pwsh is not available on PATH.'}

    $seed=SeedRepo
    if(-not $seed){
        $seed=Join-Path $GamesRoot ('cprealpass-repo-'+$stamp)
        Write-Host "No usable local cprealpass checkout found; cloning exact-source seed: $seed" -ForegroundColor Cyan
        $clone=Git @('clone','--no-checkout',$repoUrl,$seed)
        if($clone.ExitCode -ne 0){throw "Could not clone cprealpass. $($clone.StdErr.Trim())"}
        $createdSeed=$true
    }else{Write-Host "Using Git-validated local seed: $seed"}

    [void](ResolveHead $seed)
    $worktree=Join-Path $GamesRoot ('cprealpass-reference-bundle-'+$stamp)
    $wt=Git @('-C',$seed,'worktree','add','--detach',$worktree,$ExpectedHead)
    if($wt.ExitCode -ne 0){throw "Could not create detached exact-head checkout. $($wt.StdErr.Trim())"}

    $args=@('-NoLogo','-NoProfile','-File',(Join-Path $worktree 'tools\New-ReferenceModBundle.ps1'),'-LibraryPath',$LibraryPath,'-OutputRoot',$OutputRoot,'-WorkflowSourceRevision',$ExpectedHead)
    if($ReferenceName -and $ReferenceName.Count -gt 0){$args += '-ReferenceNameJson';$args += ($ReferenceName | ConvertTo-Json -Compress)}
    $child=Native 'pwsh' $args
    if($child.StdOut){Write-Host $child.StdOut.TrimEnd()}
    if($child.ExitCode -ne 0){throw "Reference bundle builder failed with exit $($child.ExitCode). $($child.StdErr.Trim())"}
    $m=[regex]::Match($child.StdOut,'(?im)^([A-Za-z]:\\[^\r\n]+Biology-Private-ReferenceBundle-[^\r\n]+\.zip)\s*$')
    if(-not $m.Success){throw 'Builder succeeded but did not return an attachable bundle path.'}
    $finalBundle=[IO.Path]::GetFullPath($m.Groups[1].Value.Trim())
    if(-not (Test-Path -LiteralPath $finalBundle -PathType Leaf)){throw "Returned bundle is missing: $finalBundle"}

    Write-Host ''
    Write-Host 'ATTACH THIS ONE REFERENCE BUNDLE TO CHATGPT:' -ForegroundColor Cyan
    Write-Host $finalBundle -ForegroundColor Yellow
}catch{
    $finalBundle=FailureBundle $_.Exception.Message
    Write-Host ''
    Write-Host 'REFERENCE WORKFLOW FAILED CLOSED.' -ForegroundColor Yellow
    Write-Host 'ATTACH THIS ONE REFERENCE BUNDLE TO CHATGPT:' -ForegroundColor Cyan
    Write-Host $finalBundle -ForegroundColor Yellow
    exit 1
}finally{
    if($worktree -and (Test-Path -LiteralPath $worktree)){
        if($seed -and (Test-Path -LiteralPath $seed)){[void](Git @('-C',$seed,'worktree','remove','--force',$worktree))}
        if(Test-Path -LiteralPath $worktree){Remove-Item -LiteralPath $worktree -Recurse -Force -ErrorAction SilentlyContinue}
    }
    if($createdSeed -and $seed -and (Test-Path -LiteralPath $seed)){Remove-Item -LiteralPath $seed -Recurse -Force -ErrorAction SilentlyContinue}
}
