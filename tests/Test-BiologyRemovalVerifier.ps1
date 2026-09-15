$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\tools\Common.ps1"
$project = Get-ProjectRoot
$path = Join-Path $project 'tools\Verify-BiologyRemoval.ps1'
if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw 'Missing Biology removal verifier.' }
$text = Get-Content -Raw -LiteralPath $path
foreach ($needle in @('mods/Biology','r6/scripts/CyberpunkRealism','Uninstall Biology.exe','Generic redscript/RED4ext/ArchiveXL/Mod Settings')) {
    if (-not $text.Contains($needle)) { throw "Removal verifier lost required contract text: $needle" }
}
if ($text -match '(?i)Remove-Item|Directory\.Delete|File\.Delete') { throw 'Removal verifier must remain read-only.' }
Write-Host 'PASS: Biology removal verifier is read-only, checks Biology-specific residue, and deliberately permits preserved generic dependencies.'
