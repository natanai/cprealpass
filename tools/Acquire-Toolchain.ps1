. "$PSScriptRoot\Common.ps1"
$project=Get-ProjectRoot
$manifest=Get-Content -Raw (Join-Path $project 'manifest\toolchain.json') | ConvertFrom-Json
foreach($tool in $manifest.tools){
    $target=Resolve-SafeChildPath $project $tool.localPath
    if(-not(Test-Path -LiteralPath $target)){
        $uri=[uri]$tool.assetUrl
        if($uri.Scheme -ne 'https' -or $uri.Host -ne 'github.com' -or $tool.sha256 -notmatch '^[a-fA-F0-9]{64}$'){throw 'Toolchain requires a pinned official HTTPS asset and SHA-256.'}
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $target) | Out-Null
        $temp=$target+'.'+[guid]::NewGuid().ToString('N')+'.partial'
        try{
            Invoke-WebRequest $uri -OutFile $temp
            if((Get-Sha256 $temp) -ne $tool.sha256){throw 'Toolchain download hash mismatch.'}
            Move-Item -LiteralPath $temp -Destination $target
        }finally{if(Test-Path -LiteralPath $temp){Remove-Item -LiteralPath $temp}}
    }
    if((Get-Sha256 $target) -ne $tool.sha256){throw 'Cached compiler hash mismatch.'}
    Write-Host "Verified toolchain: $($tool.id) $($tool.version)"
}
