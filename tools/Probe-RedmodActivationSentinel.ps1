[CmdletBinding()]
param(
    [string]$GameRoot = 'C:\Games\Steam\steamapps\common\Cyberpunk 2077',
    [string]$ReportPath
)

$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'Probe-RedmodActivationSentinel.ps1 requires PowerShell 7 or newer.' }
. "$PSScriptRoot\Common.ps1"

$project = Get-ProjectRoot
$game = Assert-GameRoot $GameRoot
$redmodRoot = Join-Path $game 'tools\redmod'
$redmodExe = Join-Path $redmodRoot 'bin\redMod.exe'
$tweakRoot = Join-Path $redmodRoot 'tweaks'
$tweakDbScript = Join-Path $redmodRoot 'scripts\core\data\tweakDB.script'
$tweakDbRecords = Join-Path $redmodRoot 'scripts\core\data\tweakDBRecords.script'

foreach ($required in @($redmodExe,$tweakDbScript,$tweakDbRecords)) {
    if (-not (Test-Path -LiteralPath $required -PathType Leaf)) { throw "Required official REDmod file not found: $required" }
}
if (-not (Test-Path -LiteralPath $tweakRoot -PathType Container)) { throw "Official REDmod tweak source tree not found: $tweakRoot" }

$version = (Get-Item -LiteralPath $redmodExe).VersionInfo
if ($version.ProductVersion -ne '2.31') {
    throw "Activation-sentinel probe is pinned to Cyberpunk/REDmod 2.31; installed REDmod reports product version '$($version.ProductVersion)'."
}

if ([string]::IsNullOrWhiteSpace($ReportPath)) {
    $reportRoot = Join-Path $project 'reports'
    New-Item -ItemType Directory -Force -Path $reportRoot | Out-Null
    $stamp = [DateTime]::UtcNow.ToString('yyyyMMdd-HHmmss')
    $ReportPath = Join-Path $reportRoot "redmod-activation-sentinel-probe-$stamp.txt"
} else {
    $ReportPath = [IO.Path]::GetFullPath($ReportPath)
    $parent = Split-Path -Parent $ReportPath
    if (-not [string]::IsNullOrWhiteSpace($parent)) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
}

function Normalize-Relative([string]$Path,[string]$Root) {
    return [IO.Path]::GetRelativePath($Root,$Path).Replace('\','/')
}
function Compact([string]$Text,[int]$Max = 240) {
    $value = ($Text -replace '\s+',' ').Trim()
    if ($value.Length -le $Max) { return $value }
    return $value.Substring(0,$Max) + ' ...'
}
function Add-Bounded([Collections.Generic.List[string]]$List,[string]$Value,[int]$Limit) {
    if ($List.Count -lt $Limit) { $List.Add($Value) }
}

$tweakFiles = @(Get-ChildItem -LiteralPath $tweakRoot -Recurse -File -Filter '*.tweak' | Sort-Object FullName)
if ($tweakFiles.Count -eq 0) { throw 'Official REDmod tweak source tree contains no .tweak files.' }

$templateMatches = [Collections.Generic.List[string]]::new()
$typedBoolMatches = [Collections.Generic.List[string]]::new()
$unbasedTypedBoolMatches = [Collections.Generic.List[string]]::new()
$packageUsingMatches = [Collections.Generic.List[string]]::new()
$filesWithTemplate = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)

foreach ($file in $tweakFiles) {
    $relative = Normalize-Relative $file.FullName $redmodRoot
    $lines = @(Get-Content -LiteralPath $file.FullName)
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = [string]$lines[$i]
        $lineNo = $i + 1
        if ($line -match '\bIconicWeaponModAbilityBase\b') {
            [void]$filesWithTemplate.Add($relative)
            Add-Bounded $templateMatches ("{0}:{1}: {2}" -f $relative,$lineNo,(Compact $line)) 24
        }
        if ($line -match '^\s*bool\s+[A-Za-z_][A-Za-z0-9_]*\s*=') {
            Add-Bounded $typedBoolMatches ("{0}:{1}: {2}" -f $relative,$lineNo,(Compact $line)) 24
        }
        if ($line -match '^\s*(package|using)\b') {
            Add-Bounded $packageUsingMatches ("{0}:{1}: {2}" -f $relative,$lineNo,(Compact $line)) 24
        }

        # Evidence for the narrow replacement shape we care about: a source group
        # with no inherited base followed by an explicitly typed bool flat. This is
        # intentionally a bounded source-pattern probe, not a claim that CI can
        # emulate the native tweak compiler.
        if ($line -match '^\s*(?<group>[A-Za-z_][A-Za-z0-9_.]*)\s*\{\s*$' -and $line -notmatch ':') {
            $max = [Math]::Min($i + 24,$lines.Count - 1)
            for ($j = $i + 1; $j -le $max; $j++) {
                $candidate = [string]$lines[$j]
                if ($candidate -match '^\s*}\s*;?\s*$') { break }
                if ($candidate -match '^\s*bool\s+[A-Za-z_][A-Za-z0-9_]*\s*=') {
                    Add-Bounded $unbasedTypedBoolMatches ("{0}:{1}-{2}: {3} | {4}" -f $relative,$lineNo,($j + 1),(Compact $line),(Compact $candidate)) 16
                    break
                }
            }
        }
    }
}

function Collect-ScriptSignatures([string]$Path,[string[]]$Patterns,[int]$Limit) {
    $matches = [Collections.Generic.List[string]]::new()
    $lines = @(Get-Content -LiteralPath $Path)
    $relative = Normalize-Relative $Path $redmodRoot
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = [string]$lines[$i]
        foreach ($pattern in $Patterns) {
            if ($line -match $pattern) {
                Add-Bounded $matches ("{0}:{1}: {2}" -f $relative,($i + 1),(Compact $line)) $Limit
                break
            }
        }
    }
    return @($matches)
}

$tweakDbSignatures = @(Collect-ScriptSignatures $tweakDbScript @('\bGetBool\b','\bGetRecord\b','\bGetItemRecord\b') 32)
$itemRecordSignatures = @(Collect-ScriptSignatures $tweakDbRecords @('\bgamedataItem_Record\b') 12)

$linesOut = [Collections.Generic.List[string]]::new()
$linesOut.Add('Biology W07.1 REDmod activation-sentinel source probe')
$linesOut.Add('Generated UTC: ' + [DateTime]::UtcNow.ToString('o'))
$linesOut.Add('Policy: READ-ONLY against the Cyberpunk/REDmod installation. No game, mod, deploy, cache, or package files are modified.')
$linesOut.Add('Game root: ' + $game)
$linesOut.Add('REDmod executable: ' + $redmodExe)
$linesOut.Add('REDmod SHA-256: ' + (Get-Sha256 $redmodExe))
$linesOut.Add('REDmod file version: ' + $version.FileVersion)
$linesOut.Add('REDmod product version: ' + $version.ProductVersion)
$linesOut.Add('Official tweak source files scanned: ' + $tweakFiles.Count)
$linesOut.Add('')
$linesOut.Add('QUESTION A — Is IconicWeaponModAbilityBase present in the shipped 2.31 tweak sources, and where?')
$linesOut.Add('Files containing token: ' + $filesWithTemplate.Count)
if ($templateMatches.Count -eq 0) { $linesOut.Add('NO MATCHES') } else { foreach ($entry in $templateMatches) { $linesOut.Add($entry) } }
$linesOut.Add('')
$linesOut.Add('QUESTION B — Does the shipped source grammar use explicitly typed bool flats?')
if ($typedBoolMatches.Count -eq 0) { $linesOut.Add('NO MATCHES') } else { foreach ($entry in $typedBoolMatches) { $linesOut.Add($entry) } }
$linesOut.Add('')
$linesOut.Add('QUESTION C — Are there shipped unbased groups containing explicitly typed bool flats?')
$linesOut.Add('These are bounded lexical examples only; the owning agent must inspect semantics before selecting a sentinel.')
if ($unbasedTypedBoolMatches.Count -eq 0) { $linesOut.Add('NO MATCHES') } else { foreach ($entry in $unbasedTypedBoolMatches) { $linesOut.Add($entry) } }
$linesOut.Add('')
$linesOut.Add('QUESTION D — Do shipped tweak sources use package/using imports that can explain source-local base visibility?')
if ($packageUsingMatches.Count -eq 0) { $linesOut.Add('NO MATCHES') } else { foreach ($entry in $packageUsingMatches) { $linesOut.Add($entry) } }
$linesOut.Add('')
$linesOut.Add('QUESTION E — What TweakDB read APIs are declared by the shipped 2.31 engine scripts?')
if ($tweakDbSignatures.Count -eq 0) { $linesOut.Add('NO MATCHES for GetBool/GetRecord/GetItemRecord') } else { foreach ($entry in $tweakDbSignatures) { $linesOut.Add($entry) } }
$linesOut.Add('')
$linesOut.Add('QUESTION F — Is gamedataItem_Record declared in the shipped generated TweakDB record surface?')
if ($itemRecordSignatures.Count -eq 0) { $linesOut.Add('NO MATCHES') } else { foreach ($entry in $itemRecordSignatures) { $linesOut.Add($entry) } }
$linesOut.Add('')
$linesOut.Add('Interpretation boundary: this report is direct supported-install source evidence. It does NOT claim that an arbitrary Biology tweak compiles/deploys. Official REDmod compile/deploy acceptance remains an attended parent gate.')
$linesOut.Add('PASS: bounded official REDmod 2.31 activation-sentinel evidence captured.')

[IO.File]::WriteAllLines($ReportPath,$linesOut,[Text.UTF8Encoding]::new($false))
Write-Host 'PASS: captured bounded, read-only official REDmod 2.31 activation-sentinel evidence.' -ForegroundColor Green
Write-Host "ATTACH THIS FILE TO CHATGPT: $ReportPath" -ForegroundColor Cyan
return $ReportPath
