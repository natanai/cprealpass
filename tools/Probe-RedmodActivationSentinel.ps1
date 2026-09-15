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

function Add-Report([string]$Text = '') {
    Add-Content -LiteralPath $ReportPath -Value $Text -Encoding utf8
}
function Normalize-Relative([string]$Path,[string]$Root) {
    return [IO.Path]::GetRelativePath($Root,$Path).Replace('\','/')
}
function Compact([string]$Text,[int]$Max = 240) {
    if ($null -eq $Text) { return '' }
    $value = ($Text -replace '\s+',' ').Trim()
    if ($value.Length -le $Max) { return $value }
    return $value.Substring(0,$Max) + ' ...'
}
function Add-Bounded([Collections.Generic.List[string]]$List,[string]$Value,[int]$Limit) {
    if ($List.Count -lt $Limit) { $List.Add($Value) }
}
function Add-SelectStringMatches(
    [Collections.Generic.List[string]]$Target,
    [object[]]$Matches,
    [string]$Root,
    [int]$Limit
) {
    foreach ($match in @($Matches)) {
        if ($Target.Count -ge $Limit) { break }
        $relative = Normalize-Relative ([string]$match.Path) $Root
        $Target.Add(("{0}:{1}: {2}" -f $relative,$match.LineNumber,(Compact ([string]$match.Line))))
    }
}

$failed = $false
try {
    foreach ($required in @($redmodExe,$tweakDbScript,$tweakDbRecords)) {
        if (-not (Test-Path -LiteralPath $required -PathType Leaf)) { throw "Required official REDmod file not found: $required" }
    }
    if (-not (Test-Path -LiteralPath $tweakRoot -PathType Container)) { throw "Official REDmod tweak source tree not found: $tweakRoot" }

    $version = (Get-Item -LiteralPath $redmodExe).VersionInfo
    if ($version.ProductVersion -ne '2.31') {
        throw "Activation-sentinel probe is pinned to Cyberpunk/REDmod 2.31; installed REDmod reports product version '$($version.ProductVersion)'."
    }

    Add-Report ''
    Add-Report '=== W07.1 INNER OFFICIAL-SOURCE PROBE ==='
    Add-Report ('Generated UTC: ' + [DateTime]::UtcNow.ToString('o'))
    Add-Report 'Policy: READ-ONLY against the Cyberpunk/REDmod installation. No game, mod, deploy, cache, or package files are modified.'
    Add-Report ('Game root: ' + $game)
    Add-Report ('REDmod executable: ' + $redmodExe)
    Add-Report ('REDmod SHA-256: ' + (Get-Sha256 $redmodExe))
    Add-Report ('REDmod file version: ' + $version.FileVersion)
    Add-Report ('REDmod product version: ' + $version.ProductVersion)

    $tweakFiles = @(Get-ChildItem -LiteralPath $tweakRoot -Recurse -File -Filter '*.tweak' -ErrorAction Stop | Sort-Object FullName)
    if ($tweakFiles.Count -eq 0) { throw 'Official REDmod tweak source tree contains no .tweak files.' }
    Add-Report ('Official tweak source files scanned: ' + $tweakFiles.Count)

    $paths = @($tweakFiles | ForEach-Object { $_.FullName })
    $templateMatches = [Collections.Generic.List[string]]::new()
    $typedBoolMatches = [Collections.Generic.List[string]]::new()
    $unbasedTypedBoolMatches = [Collections.Generic.List[string]]::new()
    $packageUsingMatches = [Collections.Generic.List[string]]::new()
    $readFailures = [Collections.Generic.List[string]]::new()

    Add-SelectStringMatches $templateMatches @(Select-String -LiteralPath $paths -SimpleMatch 'IconicWeaponModAbilityBase' -ErrorAction Stop) $redmodRoot 24
    Add-SelectStringMatches $typedBoolMatches @(Select-String -LiteralPath $paths -Pattern '^\s*bool\s+[A-Za-z_][A-Za-z0-9_]*\s*=' -ErrorAction Stop) $redmodRoot 24
    Add-SelectStringMatches $packageUsingMatches @(Select-String -LiteralPath $paths -Pattern '^\s*(package|using)\b' -ErrorAction Stop) $redmodRoot 24

    # Find lexical examples of an unbased group containing an explicitly typed bool.
    # This is intentionally source evidence only, not native compilation proof.
    foreach ($file in $tweakFiles) {
        if ($unbasedTypedBoolMatches.Count -ge 16) { break }
        try {
            $lines = @(Get-Content -LiteralPath $file.FullName -ErrorAction Stop)
            for ($i = 0; $i -lt $lines.Count; $i++) {
                $line = [string]$lines[$i]
                if ($line -notmatch '^\s*(?<group>[A-Za-z_][A-Za-z0-9_.]*)\s*\{\s*$') { continue }
                if ($line -match ':') { continue }
                $max = [Math]::Min($i + 24,$lines.Count - 1)
                for ($j = $i + 1; $j -le $max; $j++) {
                    $candidate = [string]$lines[$j]
                    if ($candidate -match '^\s*}\s*;?\s*$') { break }
                    if ($candidate -match '^\s*bool\s+[A-Za-z_][A-Za-z0-9_]*\s*=') {
                        $relative = Normalize-Relative $file.FullName $redmodRoot
                        Add-Bounded $unbasedTypedBoolMatches ("{0}:{1}-{2}: {3} | {4}" -f $relative,($i + 1),($j + 1),(Compact $line),(Compact $candidate)) 16
                        break
                    }
                }
            }
        } catch {
            Add-Bounded $readFailures ((Normalize-Relative $file.FullName $redmodRoot) + ': ' + $_.Exception.Message) 12
        }
    }

    $tweakDbSignatures = [Collections.Generic.List[string]]::new()
    Add-SelectStringMatches $tweakDbSignatures @(Select-String -LiteralPath $tweakDbScript -Pattern '\bGetBool\b|\bGetRecord\b|\bGetItemRecord\b' -ErrorAction Stop) $redmodRoot 32
    $itemRecordSignatures = [Collections.Generic.List[string]]::new()
    Add-SelectStringMatches $itemRecordSignatures @(Select-String -LiteralPath $tweakDbRecords -Pattern '\bgamedataItem_Record\b' -ErrorAction Stop) $redmodRoot 12

    Add-Report ''
    Add-Report 'QUESTION A — Is IconicWeaponModAbilityBase present in the shipped 2.31 tweak sources, and where?'
    if ($templateMatches.Count -eq 0) { Add-Report 'NO MATCHES' } else { foreach ($entry in $templateMatches) { Add-Report $entry } }
    Add-Report ''
    Add-Report 'QUESTION B — Does the shipped source grammar use explicitly typed bool flats?'
    if ($typedBoolMatches.Count -eq 0) { Add-Report 'NO MATCHES' } else { foreach ($entry in $typedBoolMatches) { Add-Report $entry } }
    Add-Report ''
    Add-Report 'QUESTION C — Are there shipped unbased groups containing explicitly typed bool flats?'
    Add-Report 'These are bounded lexical examples only; the owning agent must inspect semantics before selecting a sentinel.'
    if ($unbasedTypedBoolMatches.Count -eq 0) { Add-Report 'NO MATCHES' } else { foreach ($entry in $unbasedTypedBoolMatches) { Add-Report $entry } }
    if ($readFailures.Count -gt 0) {
        Add-Report 'Per-file read failures (bounded; other evidence remains usable):'
        foreach ($entry in $readFailures) { Add-Report $entry }
    }
    Add-Report ''
    Add-Report 'QUESTION D — Do shipped tweak sources use package/using imports that can explain source-local base visibility?'
    if ($packageUsingMatches.Count -eq 0) { Add-Report 'NO MATCHES' } else { foreach ($entry in $packageUsingMatches) { Add-Report $entry } }
    Add-Report ''
    Add-Report 'QUESTION E — What TweakDB read APIs are declared by the shipped 2.31 engine scripts?'
    if ($tweakDbSignatures.Count -eq 0) { Add-Report 'NO MATCHES for GetBool/GetRecord/GetItemRecord' } else { foreach ($entry in $tweakDbSignatures) { Add-Report $entry } }
    Add-Report ''
    Add-Report 'QUESTION F — Is gamedataItem_Record declared in the shipped generated TweakDB record surface?'
    if ($itemRecordSignatures.Count -eq 0) { Add-Report 'NO MATCHES' } else { foreach ($entry in $itemRecordSignatures) { Add-Report $entry } }
    Add-Report ''
    Add-Report 'Interpretation boundary: this report is direct supported-install source evidence. It does NOT claim that an arbitrary Biology tweak compiles/deploys. Official REDmod compile/deploy acceptance remains an attended parent gate.'
    Add-Report 'PASS: bounded official REDmod 2.31 activation-sentinel evidence captured.'
    Write-Host 'PASS: captured bounded, read-only official REDmod 2.31 activation-sentinel evidence.' -ForegroundColor Green
} catch {
    $failed = $true
    Add-Report ''
    Add-Report '=== W07.1 INNER PROBE FAILURE ==='
    Add-Report ('Time: ' + [DateTime]::Now.ToString('o'))
    Add-Report ('Exception type: ' + $_.Exception.GetType().FullName)
    Add-Report ('Error: ' + $_.Exception.Message)
    if ($_.InvocationInfo) {
        Add-Report ('Script line: ' + $_.InvocationInfo.ScriptLineNumber)
        Add-Report ('Position: ' + (Compact $_.InvocationInfo.PositionMessage 500))
    }
    Add-Report 'FAIL: official-source activation-sentinel probe did not complete.'
    Write-Host ('FAIL: ' + $_.Exception.Message) -ForegroundColor Yellow
} finally {
    Write-Host "ATTACH THIS FILE TO CHATGPT: $ReportPath" -ForegroundColor Cyan
}

if ($failed) { exit 1 }
