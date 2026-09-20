$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\tools\Common.ps1"
$project = Get-ProjectRoot
$policyPath = Join-Path $project 'manifest/native-seams.json'
if (-not (Test-Path -LiteralPath $policyPath)) { throw 'Missing native seam policy.' }
$policy = Get-Content -Raw -LiteralPath $policyPath | ConvertFrom-Json
$script:checks = 0
function Check($condition,[string]$message) { if (-not $condition) { throw $message }; $script:checks++ }

Check ($policy.schemaVersion -eq 1) 'Unexpected native seam schema.'
Check ($policy.product -eq 'realpass') 'Native seam policy must identify realpass.'
Check ($policy.gameVersion -eq '2.31') 'Native seam policy must record the current accepted compile target.'
$annotations = @($policy.hookAnnotations)
foreach ($required in @('@wrapMethod','@replaceMethod','@addMethod','@addField')) {
    Check ($annotations -contains $required) "Native seam policy omits hook annotation: $required"
}

$sourceRoot = Join-Path $project 'src/redscript/CyberpunkRealism'
$allowed = @($policy.allowedHookFiles)
Check ($allowed.Count -gt 0) 'Native seam allowlist is empty.'
Check (($allowed | Sort-Object -Unique).Count -eq $allowed.Count) 'Native seam allowlist contains duplicates.'
foreach ($name in $allowed) {
    Check (Test-Path -LiteralPath (Join-Path $sourceRoot $name) -PathType Leaf) "Native seam allowlist references missing file: $name"
}

$hookFiles = [Collections.Generic.List[string]]::new()
$violations = [Collections.Generic.List[string]]::new()
Get-ChildItem -LiteralPath $sourceRoot -File -Filter '*.reds' | ForEach-Object {
    $text = Get-Content -Raw -LiteralPath $_.FullName
    $found = @($annotations | Where-Object { $text.Contains([string]$_) })
    if ($found.Count -gt 0) {
        $hookFiles.Add($_.Name)
        if ($allowed -notcontains $_.Name) {
            $violations.Add($_.Name + ' -> ' + ($found -join ', '))
        }
    }
}
if ($violations.Count -gt 0) {
    throw "Native hook annotations escaped the explicit seam allowlist:`n - $($violations -join "`n - ")"
}
Check ($hookFiles.Count -gt 0) 'No native hook files were detected; seam test is not exercising production source.'

foreach ($name in @($policy.stableCoreExamples)) {
    $path = Join-Path $sourceRoot $name
    Check (Test-Path -LiteralPath $path -PathType Leaf) "Stable-core example is missing: $name"
    $text = Get-Content -Raw -LiteralPath $path
    foreach ($annotation in $annotations) {
        Check (-not $text.Contains([string]$annotation)) "Stable simulation core gained patch-sensitive hook $($annotation): $name"
    }
}

Write-Host "PASS: $script:checks native-seam checks; $($hookFiles.Count) hook-bearing REDscript files are confined to the explicit Cyberpunk 2.31 boundary allowlist."
