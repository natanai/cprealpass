$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\tools\Common.ps1"
$project = Get-ProjectRoot

function Read([string]$relative) {
    $path = Join-Path $project $relative
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Missing W09 contract file: $relative" }
    Get-Content -Raw -LiteralPath $path
}
function Require([string]$text,[string]$pattern,[string]$message) {
    if ($text -notmatch $pattern) { throw $message }
}

$deploy = Read 'tools/Deploy-BiologyRedmod.ps1'
$uninstaller = Read 'src/uninstaller/BiologyUninstallCore.cs'
$probe = Read 'tools/Bootstrap-W09RedmodPostUninstallStateProbe.ps1'

# Recovery is deliberately placed at the official deploy boundary, after exact
# Biology/REDmod validation, and prepares only the shared directory REDmod writes
# into. It must not synthesize any generated cache payload.
Require $deploy "Resolve-SafeChildPath\s+\$game\s+'r6\\cache\\modded'" 'Deploy helper must resolve exactly r6/cache/modded under the explicit game root.'
Require $deploy 'New-Item\s+-ItemType\s+Directory\s+-Path\s+\$moddedRoot\s+-Force' 'Deploy helper must idempotently create only the missing REDmod output directory.'
Require $deploy 'FileVersion\s+-ne\s+''2\.3\.1\.0''|FileVersion\)\s+-ne\s+''2\.3\.1\.0''' 'Deploy helper must remain pinned to the evidenced REDmod 2.3.1.0 file version.'
Require $deploy 'ProductVersion\s+-ne\s+''2\.31''|ProductVersion\)\s+-ne\s+''2\.31''' 'Deploy helper must remain pinned to the evidenced REDmod 2.31 product version.'
Require $deploy "Invoke-Redmod @\('deploy','-root',\$game\)" 'Deploy helper must continue invoking official REDmod with an explicit game root.'

$prepareIndex = $deploy.IndexOf("Resolve-SafeChildPath `$game 'r6\cache\modded'", [StringComparison]::Ordinal)
$invokeIndex = $deploy.IndexOf("Invoke-Redmod @('deploy','-root',`$game)", [StringComparison]::Ordinal)
if ($prepareIndex -lt 0 -or $invokeIndex -lt 0 -or $prepareIndex -gt $invokeIndex) {
    throw 'REDmod output-root preparation must occur immediately before the first real deploy invocation, not during uninstall/build/package work.'
}

foreach ($forbidden in @(
    'Remove-Item',
    'Directory\.Delete\s*\([^\)]*r6[^\)]*cache[^\)]*modded',
    'tweakdb_ep1\.bin[^\r\n]*(Set-Content|Copy-Item|New-Item)',
    'mods\.json[^\r\n]*(Set-Content|Copy-Item|New-Item)'
)) {
    if ($deploy -match $forbidden) { throw "Deploy helper contains forbidden cache mutation pattern: $forbidden" }
}

# Repository artifacts must never bundle prebuilt REDmod cache output.
$bundled = @(Get-ChildItem -LiteralPath $project -Recurse -File -ErrorAction Stop | Where-Object {
    $relative = [IO.Path]::GetRelativePath($project,$_.FullName).Replace('\\','/')
    $relative -match '(?i)(^|/)r6/cache/modded/' -or
    $relative -match '(?i)(^|/)tweakdb_ep1\.bin$' -or
    $relative -match '(?i)(^|/)mods\.json$'
})
if ($bundled.Count -gt 0) {
    throw ('Generated REDmod cache output is bundled in the repository: ' + (($bundled | ForEach-Object { [IO.Path]::GetRelativePath($project,$_.FullName) }) -join ', '))
}

# Hard uninstall remains ownership-scoped. The W09 repair must not migrate into
# uninstaller cache deletion/recreation, especially when other REDmods exist.
if ($uninstaller -match '(?i)r6[\\/]cache[\\/]modded') {
    throw 'Player uninstaller must not directly own or mutate the shared r6/cache/modded tree.'
}
Require $uninstaller 'CountOtherRedmods' 'Player uninstaller must retain explicit other-REDmod detection.'
Require $uninstaller 'Other REDmods remain installed' 'Player uninstaller must retain the multi-REDmod refresh safety path.'

# The evidence probe is observational only and must distinguish evidence from
# official deploy acceptance.
Require $probe 'READ-ONLY' 'W09 probe must state that installed game inspection is read-only.'
Require $probe 'No deploy, install, uninstall, cache creation, cache deletion, or game launch is performed' 'W09 probe must explicitly prohibit mutation.'
Require $probe 'does NOT constitute official deployment/runtime acceptance' 'W09 probe must preserve the source/filesystem-vs-deploy proof boundary.'

Write-Host 'PASS: W09 post-uninstall REDmod recovery is narrow, idempotent, deploy-boundary-only, and preserves unrelated REDmod cache contents.'
