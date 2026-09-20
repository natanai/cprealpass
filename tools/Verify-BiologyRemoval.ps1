[CmdletBinding()]
param(
    [string]$GameRoot = 'C:\Games\Steam\steamapps\common\Cyberpunk 2077'
)

$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'Verify-BiologyRemoval.ps1 requires PowerShell 7 or newer.' }
. "$PSScriptRoot\Common.ps1"

# Read-only verification: this tool does not delete or modify game files.
$game = Assert-GameRoot $GameRoot
$biologySpecific = @(
    'mods/Biology',
    'r6/scripts/CyberpunkRealism',
    'biology',
    'Uninstall Biology.exe',
    'Install Biology.exe',
    'Install Biology.ps1',
    'BiologyReleaseInstall.Core.ps1',
    'BIOLOGY-VERSION.txt'
)
$residue = [Collections.Generic.List[string]]::new()
foreach ($relative in $biologySpecific) {
    $full = Resolve-SafeChildPath $game $relative
    if (Test-Path -LiteralPath $full) { $residue.Add($relative.Replace('\\','/')) }
}

# Root package instructions/checksums are checked only when their contents still
# identify Biology. Other tools/mods may legitimately use generic root filenames.
foreach ($relative in @('INSTALL.txt','UNINSTALL.txt','SHA256SUMS.txt')) {
    $full = Resolve-SafeChildPath $game $relative
    if (-not (Test-Path -LiteralPath $full -PathType Leaf)) { continue }
    $text = Get-Content -Raw -LiteralPath $full -ErrorAction Stop
    if ($text -match '(?i)\bBiology\b|mods[\\/]Biology|Uninstall Biology\.exe|CyberpunkRealism') {
        $residue.Add($relative)
    }
}

if ($residue.Count -gt 0) {
    Write-Host 'Biology-specific residue remains:' -ForegroundColor Yellow
    foreach ($path in $residue) { Write-Host " - $path" }
    throw 'Biology removal verification found package-specific residue. Review the uninstaller report before attempting another install.'
}

Write-Host 'PASS: no Biology-specific package/runtime residue was found.' -ForegroundColor Green
Write-Host 'Generic redscript/RED4ext/ArchiveXL/Mod Settings files are intentionally outside this check because player uninstall preserves shared dependencies.' -ForegroundColor DarkGray
return $true
