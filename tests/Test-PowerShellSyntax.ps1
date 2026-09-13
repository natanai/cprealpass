$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\tools\Common.ps1"
$project = Get-ProjectRoot

# Cloud contract tests frequently inspect orchestration scripts as text. That is useful
# for policy assertions but it can miss a PowerShell parser error in a path that CI
# never executes (for example an installed-game-only builder). Parse every tracked
# operational/test script without executing it so local preflight does not become the
# first place basic syntax is discovered.
$roots = @(
    (Join-Path $project 'tools'),
    (Join-Path $project 'tests')
)
$files = @($roots | ForEach-Object { Get-ChildItem -LiteralPath $_ -Recurse -File -Filter '*.ps1' } | Sort-Object FullName -Unique)
if ($files.Count -lt 20) { throw 'Unexpectedly small PowerShell surface; syntax gate is not covering the repository.' }

$failures = [Collections.Generic.List[string]]::new()
foreach ($file in $files) {
    $tokens = $null
    $parseErrors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$tokens, [ref]$parseErrors) | Out-Null
    foreach ($parseError in @($parseErrors)) {
        $relative = [IO.Path]::GetRelativePath($project, $file.FullName).Replace('\','/')
        $failures.Add("${relative}:$($parseError.Extent.StartLineNumber):$($parseError.Extent.StartColumnNumber) $($parseError.Message)")
    }
}

if ($failures.Count -gt 0) {
    throw "PowerShell parser errors found:`n - $($failures -join "`n - ")"
}
Write-Host "PASS: parsed $($files.Count) repository PowerShell scripts without syntax errors."
