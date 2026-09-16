$ErrorActionPreference = 'Stop'
$project = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$runPath = Join-Path $PSScriptRoot 'Run-CI.ps1'
$readmePath = Join-Path $PSScriptRoot 'README.md'
$workflowPath = Join-Path $project '.github\workflows\ci.yml'

function Assert-True([bool]$Condition,[string]$Message) {
    if (-not $Condition) { throw $Message }
}

$runText = Get-Content -Raw -LiteralPath $runPath
$listed = @([regex]::Matches($runText,"'(?<name>Test-[^']+\.ps1)'") | ForEach-Object { $_.Groups['name'].Value })
Assert-True ($listed.Count -gt 0) 'Run-CI.ps1 contains no Test-*.ps1 entries.'

$duplicates = @($listed | Group-Object | Where-Object Count -gt 1 | ForEach-Object Name)
if ($duplicates.Count -gt 0) { throw ('Run-CI.ps1 contains duplicate test entries: ' + ($duplicates -join ', ')) }

foreach ($name in $listed) {
    Assert-True (Test-Path -LiteralPath (Join-Path $PSScriptRoot $name) -PathType Leaf) "Run-CI.ps1 lists missing test: $name"
}

$allTests = @(Get-ChildItem -LiteralPath $PSScriptRoot -Filter 'Test-*.ps1' -File | Select-Object -ExpandProperty Name | Sort-Object)
$listedSet = @{}
foreach ($name in $listed) { $listedSet[$name.ToLowerInvariant()] = $true }
$excluded = @($allTests | Where-Object { -not $listedSet.ContainsKey($_.ToLowerInvariant()) })

$readme = Get-Content -Raw -LiteralPath $readmePath
$section = [regex]::Match($readme,'(?ms)^## Intentional non-cloud / local-only tests\s*(?<body>.*?)(?=^## |\z)')
Assert-True $section.Success 'tests/README.md must contain an "Intentional non-cloud / local-only tests" section.'
$documented = @([regex]::Matches($section.Groups['body'].Value,'`(?<name>Test-[^`]+\.ps1)`') | ForEach-Object { $_.Groups['name'].Value } | Sort-Object -Unique)

$missingDocs = @($excluded | Where-Object { $_ -notin $documented })
if ($missingDocs.Count -gt 0) {
    throw ('Test-*.ps1 files excluded from cloud CI without an explicit local-only/intentional README entry: ' + ($missingDocs -join ', '))
}
$staleDocs = @($documented | Where-Object { $_ -notin $excluded })
if ($staleDocs.Count -gt 0) {
    throw ('tests/README.md marks tests local-only that are not currently excluded from Run-CI.ps1: ' + ($staleDocs -join ', '))
}

# Policy tests may validate durable lookup/numbering rules, and may explicitly
# REJECT stale transient strings. They must not positively REQUIRE today's worker
# assignment/state. Live worker identity/state belongs to THREAD-LEDGER + GitHub.
foreach ($name in @('Test-ActiveRoadmap.ps1','Test-ThreadLedger.ps1','Test-IntegrationOrchestrator.ps1','Test-ActiveGuidanceHygiene.ps1')) {
    $text = Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot $name)
    foreach ($pattern in @(
        '(?i)Require[^\r\n]*no active worker',
        '(?i)must be ACTIVE while',
        '(?i)must remain IN-PROGRESS',
        '(?i)current managed-evidence assignment',
        '(?i)current worker.*must (?:be|remain).*W\d+\.\d+'
    )) {
        if ($text -match $pattern) { throw "$name freezes transient worker state with pattern: $pattern" }
    }
}

$workflow = Get-Content -Raw -LiteralPath $workflowPath
Assert-True ($workflow -match 'actions/checkout@v7') 'CI workflow must use the verified current Node-24-compatible checkout major.'
Assert-True ($workflow -match 'actions/upload-artifact@v7') 'CI workflow must use the verified current Node-24-compatible upload-artifact major.'
Assert-True ($workflow -notmatch 'actions/(?:checkout|upload-artifact)@v4') 'CI workflow still uses the Node-20 v4 action major.'

Write-Host "PASS: CI suite hygiene accepted $($listed.Count) unique cloud tests; every listed test exists, $($excluded.Count) intentional non-cloud Test-*.ps1 files are explicitly documented, policy tests do not positively freeze transient worker state, and workflow actions use Node-24-compatible majors."
