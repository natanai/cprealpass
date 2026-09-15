$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'Test-RedmodActivationSentinelProbe.ps1 requires PowerShell 7 or newer.' }
. "$PSScriptRoot\..\tools\Common.ps1"
$project = Get-ProjectRoot

function Read([string]$relative) {
    $path = Join-Path $project $relative
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Missing activation-sentinel evidence asset: $relative" }
    Get-Content -Raw -LiteralPath $path
}
function Require([string]$text,[string]$pattern,[string]$message) {
    if ($text -notmatch $pattern) { throw $message }
}

$probe = Read 'tools/Probe-RedmodActivationSentinel.ps1'
$bootstrap = Read 'tools/Bootstrap-RedmodActivationSentinelProbe.ps1'

Require $probe 'tools\\redmod' 'Activation probe must read the installed official REDmod tree.'
Require $probe 'bin\\redMod\.exe' 'Activation probe must fingerprint the installed official REDmod executable.'
Require $probe 'scripts\\core\\data\\tweakDB\.script' 'Activation probe must inspect the shipped TweakDB API surface.'
Require $probe 'scripts\\core\\data\\tweakDBRecords\.script' 'Activation probe must inspect the shipped generated record surface.'
Require $probe "ProductVersion -ne '2\.31'" 'Activation probe must fail closed outside the supported REDmod 2.31 surface.'
Require $probe "Filter '\*\.tweak'" 'Activation probe must inspect CDPR-shipped .tweak sources rather than community examples.'
Require $probe 'IconicWeaponModAbilityBase' 'Activation probe must investigate the exact invalid base from attended evidence.'
Require $probe '\^\\s\*bool' 'Activation probe must look for explicitly typed native bool-flat syntax.'
Require $probe 'GetBool' 'Activation probe must capture the installed GetBool read surface.'
Require $probe 'GetRecord' 'Activation probe must capture the installed GetRecord read surface.'
Require $probe 'gamedataItem_Record' 'Activation probe must capture whether the generated item record surface exists.'
Require $probe 'Select-String' 'Activation probe must use bounded native source searches rather than relying on a guessed schema.'
Require $probe 'READ-ONLY|read-only' 'Activation probe must explicitly declare the installed game read-only.'
Require $probe 'does NOT claim.*compiles/deploys|does not claim.*compiles/deploys' 'Activation probe must not fake native compile/deploy validation.'
Require $probe 'W07\.1 INNER PROBE FAILURE' 'Activation probe must preserve a named failure section in the evidence report.'
Require $probe 'Exception type:' 'Activation probe must preserve the exception type on local failure.'
Require $probe 'InvocationInfo|Script line:' 'Activation probe must preserve actionable source-position evidence on local failure.'
Require $probe 'ATTACH THIS FILE TO CHATGPT:' 'Activation probe must return a text evidence file rather than require pasted console logs.'
if ($probe -match '(?i)redMod\.exe.*deploy|Invoke-.*deploy|Copy-Item.*\$game|Move-Item.*\$game|Remove-Item.*\$game') {
    throw 'Activation probe must not mutate/deploy against the installed game.'
}

Require $bootstrap '\[Parameter\(Mandatory=\$true\)\]\[string\]\$Branch' 'Activation probe bootstrap must require the exact worker branch.'
Require $bootstrap '\[ValidatePattern\(''\^\[0-9a-fA-F\]\{40\}\$''\)\].*\$ExpectedHead' 'Activation probe bootstrap must pin an exact worker head.'
Require $bootstrap 'repoPattern' 'Activation probe bootstrap must discover cprealpass by repository identity.'
Require $bootstrap 'cprealpass-repo-' 'Activation probe bootstrap must support a uniquely signed seed clone.'
Require $bootstrap "'worktree','add','--detach'" 'Activation probe bootstrap must use a detached exact-head worktree.'
Require $bootstrap 'cprealpass-redmod-activation-probe-' 'Activation probe bootstrap must isolate the exact revision in a uniquely signed checkout.'
Require $bootstrap 'Probe-RedmodActivationSentinel\.ps1' 'Activation probe bootstrap must invoke the repository-owned narrow probe.'
Require $bootstrap 'Biology-Redmod-Activation-Sentinel-Probe-' 'Activation probe bootstrap must produce a plainly named text report outside the disposable checkout.'
Require $bootstrap 'RedirectStandardOutput\s*=\s*\$true' 'Activation probe bootstrap must capture child stdout into durable evidence.'
Require $bootstrap 'RedirectStandardError\s*=\s*\$true' 'Activation probe bootstrap must capture child stderr instead of losing the actual probe exception.'
Require $bootstrap 'INNER PROBE PROCESS OUTPUT' 'Activation probe bootstrap must label captured child diagnostics in the report.'
Require $bootstrap 'See INNER PROBE FAILURE / process output above' 'Activation probe bootstrap must route nonzero child exits to their preserved diagnostics.'
Require $bootstrap 'ATTACH THIS FILE TO CHATGPT:' 'Activation probe bootstrap must print the report file handoff on success or failure.'
if ($bootstrap.Contains('C:\Games\CyberpunkRealism')) { throw 'Activation probe bootstrap reintroduced the retired fixed repo path.' }

Write-Host 'PASS: W07.1 activation-sentinel evidence tooling is exact-head, bounded, read-only against the installed game, preserves local failure diagnostics, and explicitly separates source evidence from native compile/deploy acceptance.'
