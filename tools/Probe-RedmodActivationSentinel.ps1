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
$modsAbilities = Join-Path $tweakRoot 'base\gameplay\static_data\database\items\weapons\parts\mods_abilities.tweak'

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
function Compact([string]$Text,[int]$Max = 260) {
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
    foreach ($required in @($redmodExe,$tweakDbScript,$tweakDbRecords,$modsAbilities)) {
        if (-not (Test-Path -LiteralPath $required -PathType Leaf)) { throw "Required official REDmod file not found: $required" }
    }
    if (-not (Test-Path -LiteralPath $tweakRoot -PathType Container)) { throw "Official REDmod tweak source tree not found: $tweakRoot" }

    $version = (Get-Item -LiteralPath $redmodExe).VersionInfo
    if ($version.ProductVersion -ne '2.31') {
        throw "Activation-sentinel probe is pinned to Cyberpunk/REDmod 2.31; installed REDmod reports product version '$($version.ProductVersion)'."
    }

    Add-Report ''
    Add-Report '=== W08.1 INNER OFFICIAL-SOURCE TWEAK GRAMMAR PROBE ==='
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
    Add-Report ('Exact native base file: ' + (Normalize-Relative $modsAbilities $redmodRoot))

    $paths = @($tweakFiles | ForEach-Object { $_.FullName })
    $templateMatches = [Collections.Generic.List[string]]::new()
    $typedBoolMatches = [Collections.Generic.List[string]]::new()
    $unbasedTypedBoolMatches = [Collections.Generic.List[string]]::new()
    $packageUsingPairs = [Collections.Generic.List[string]]::new()
    $usingFirst = [Collections.Generic.List[string]]::new()
    $crossPackageInheritance = [Collections.Generic.List[string]]::new()
    $qualifiedBaseMatches = [Collections.Generic.List[string]]::new()
    $readFailures = [Collections.Generic.List[string]]::new()

    Add-SelectStringMatches $templateMatches @(Select-String -LiteralPath $paths -SimpleMatch 'IconicWeaponModAbilityBase' -ErrorAction Stop) $redmodRoot 24
    Add-SelectStringMatches $typedBoolMatches @(Select-String -LiteralPath $paths -Pattern '^\s*bool\s+[A-Za-z_][A-Za-z0-9_]*\s*=' -ErrorAction Stop) $redmodRoot 24
    Add-SelectStringMatches $qualifiedBaseMatches @(Select-String -LiteralPath $paths -SimpleMatch 'Items.IconicWeaponModAbilityBase' -ErrorAction Stop) $redmodRoot 16

    foreach ($file in $tweakFiles) {
        try {
            $lines = @(Get-Content -LiteralPath $file.FullName -ErrorAction Stop)
            $relative = Normalize-Relative $file.FullName $redmodRoot
            $directives = [Collections.Generic.List[object]]::new()
            for ($i = 0; $i -lt $lines.Count; $i++) {
                $line = [string]$lines[$i]
                $directive = [regex]::Match($line,'^\s*(?<kind>package|using)\s+(?<name>[A-Za-z_][A-Za-z0-9_.]*)\s*$')
                if ($directive.Success) {
                    $directives.Add([pscustomobject]@{ Kind=$directive.Groups['kind'].Value; Name=$directive.Groups['name'].Value; Line=$i + 1; Text=(Compact $line) })
                }
                if ($crossPackageInheritance.Count -lt 24 -and $line -match ':\s*[A-Za-z_][A-Za-z0-9_]*\.[A-Za-z_][A-Za-z0-9_]*\s*(?:\{|$)') {
                    Add-Bounded $crossPackageInheritance ("{0}:{1}: {2}" -f $relative,($i + 1),(Compact $line)) 24
                }
            }
            if ($directives.Count -gt 0 -and $directives[0].Kind -eq 'using') {
                Add-Bounded $usingFirst ("{0}:{1}: {2}" -f $relative,$directives[0].Line,$directives[0].Text) 24
            }
            if ($directives.Count -gt 1 -and $directives[0].Kind -eq 'package' -and $directives[1].Kind -eq 'using') {
                Add-Bounded $packageUsingPairs ("{0}:{1}-{2}: {3} | {4}" -f $relative,$directives[0].Line,$directives[1].Line,$directives[0].Text,$directives[1].Text) 24
            }

            if ($unbasedTypedBoolMatches.Count -lt 16) {
                for ($i = 0; $i -lt $lines.Count; $i++) {
                    $line = [string]$lines[$i]
                    if ($line -notmatch '^\s*(?<group>[A-Za-z_][A-Za-z0-9_.]*)\s*\{\s*$') { continue }
                    $max = [Math]::Min($i + 24,$lines.Count - 1)
                    for ($j = $i + 1; $j -le $max; $j++) {
                        $candidate = [string]$lines[$j]
                        if ($candidate -match '^\s*}\s*;?\s*$') { break }
                        if ($candidate -match '^\s*bool\s+[A-Za-z_][A-Za-z0-9_]*\s*=') {
                            Add-Bounded $unbasedTypedBoolMatches ("{0}:{1}-{2}: {3} | {4}" -f $relative,($i + 1),($j + 1),(Compact $line),(Compact $candidate)) 16
                            break
                        }
                    }
                }
            }
        } catch {
            Add-Bounded $readFailures ((Normalize-Relative $file.FullName $redmodRoot) + ': ' + $_.Exception.Message) 12
        }
    }

    $nativeBaseHeader = [Collections.Generic.List[string]]::new()
    $baseLines = @(Get-Content -LiteralPath $modsAbilities -ErrorAction Stop)
    $baseRelative = Normalize-Relative $modsAbilities $redmodRoot
    for ($i = 0; $i -lt [Math]::Min(24,$baseLines.Count); $i++) {
        $line = [string]$baseLines[$i]
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        Add-Bounded $nativeBaseHeader ("{0}:{1}: {2}" -f $baseRelative,($i + 1),(Compact $line)) 12
    }

    $tweakDbSignatures = [Collections.Generic.List[string]]::new()
    Add-SelectStringMatches $tweakDbSignatures @(Select-String -LiteralPath $tweakDbScript -Pattern '\bGetBool\b|\bGetRecord\b|\bGetItemRecord\b' -ErrorAction Stop) $redmodRoot 32
    $itemRecordSignatures = [Collections.Generic.List[string]]::new()
    Add-SelectStringMatches $itemRecordSignatures @(Select-String -LiteralPath $tweakDbRecords -Pattern '\bgamedataItem_Record\b' -ErrorAction Stop) $redmodRoot 12

    Add-Report ''
    Add-Report 'QUESTION A — What package/header context owns IconicWeaponModAbilityBase in the exact shipped base file?'
    foreach ($entry in $nativeBaseHeader) { Add-Report $entry }
    Add-Report 'Base symbol matches (bounded):'
    if ($templateMatches.Count -eq 0) { Add-Report 'NO MATCHES' } else { foreach ($entry in $templateMatches) { Add-Report $entry } }

    Add-Report ''
    Add-Report 'QUESTION B — What directive ordering does shipped 2.31 .tweak source use?'
    Add-Report 'Representative package-then-using pairs:'
    if ($packageUsingPairs.Count -eq 0) { Add-Report 'NO MATCHES' } else { foreach ($entry in $packageUsingPairs) { Add-Report $entry } }
    Add-Report 'Files whose first package/import directive is using:'
    if ($usingFirst.Count -eq 0) { Add-Report 'NO MATCHES' } else { foreach ($entry in $usingFirst) { Add-Report $entry } }

    Add-Report ''
    Add-Report 'QUESTION C — Does official source show qualified-base inheritance or the specific Items.IconicWeaponModAbilityBase spelling?'
    Add-Report 'Cross-package-looking inheritance examples (bounded lexical matches):'
    if ($crossPackageInheritance.Count -eq 0) { Add-Report 'NO MATCHES' } else { foreach ($entry in $crossPackageInheritance) { Add-Report $entry } }
    Add-Report 'Exact Items.IconicWeaponModAbilityBase matches:'
    if ($qualifiedBaseMatches.Count -eq 0) { Add-Report 'NO MATCHES' } else { foreach ($entry in $qualifiedBaseMatches) { Add-Report $entry } }

    Add-Report ''
    Add-Report 'QUESTION D — Does shipped source grammar use explicitly typed bool flats, and are there unbased group examples?'
    if ($typedBoolMatches.Count -eq 0) { Add-Report 'NO TYPED BOOL MATCHES' } else { foreach ($entry in $typedBoolMatches) { Add-Report $entry } }
    Add-Report 'Unbased groups containing explicitly typed bool flats (bounded lexical scan):'
    if ($unbasedTypedBoolMatches.Count -eq 0) { Add-Report 'NO MATCHES' } else { foreach ($entry in $unbasedTypedBoolMatches) { Add-Report $entry } }

    Add-Report ''
    Add-Report 'QUESTION E — What TweakDB read APIs are declared by the shipped 2.31 engine scripts?'
    if ($tweakDbSignatures.Count -eq 0) { Add-Report 'NO MATCHES for GetBool/GetRecord/GetItemRecord' } else { foreach ($entry in $tweakDbSignatures) { Add-Report $entry } }
    Add-Report ''
    Add-Report 'QUESTION F — Is gamedataItem_Record declared in the shipped generated TweakDB record surface?'
    if ($itemRecordSignatures.Count -eq 0) { Add-Report 'NO MATCHES' } else { foreach ($entry in $itemRecordSignatures) { Add-Report $entry } }

    if ($readFailures.Count -gt 0) {
        Add-Report ''
        Add-Report 'Per-file read failures (bounded; other evidence remains usable):'
        foreach ($entry in $readFailures) { Add-Report $entry }
    }

    Add-Report ''
    Add-Report 'Interpretation boundary: this report is direct supported-install source/schema evidence from CDPR-shipped 2.31 .tweak and engine-script surfaces. It does NOT claim that any Biology standalone tweak compiles/deploys, that package membership is accepted for mod-owned source, or that launcher ON/OFF behavior is proven. Official REDmod compile/deploy acceptance remains a parent P01.1 gate.'
    Add-Report 'PASS: bounded official REDmod 2.31 standalone-tweak grammar evidence captured.'
    Write-Host 'PASS: captured bounded, read-only official REDmod 2.31 standalone-tweak grammar evidence.' -ForegroundColor Green
} catch {
    $failed = $true
    Add-Report ''
    Add-Report '=== W08.1 INNER PROBE FAILURE ==='
    Add-Report ('Time: ' + [DateTime]::Now.ToString('o'))
    Add-Report ('Exception type: ' + $_.Exception.GetType().FullName)
    Add-Report ('Error: ' + $_.Exception.Message)
    if ($_.InvocationInfo) {
        Add-Report ('Script line: ' + $_.InvocationInfo.ScriptLineNumber)
        Add-Report ('Position: ' + (Compact $_.InvocationInfo.PositionMessage 500))
    }
    Add-Report 'FAIL: official-source standalone-tweak grammar probe did not complete.'
    Write-Host ('FAIL: ' + $_.Exception.Message) -ForegroundColor Yellow
} finally {
    Write-Host "ATTACH THIS FILE TO CHATGPT: $ReportPath" -ForegroundColor Cyan
}

if ($failed) { exit 1 }
