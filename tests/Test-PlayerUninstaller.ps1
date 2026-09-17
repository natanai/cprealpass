$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'Test-PlayerUninstaller.ps1 requires PowerShell 7 or newer.' }
. "$PSScriptRoot\..\tools\Common.ps1"
$project = Get-ProjectRoot

function Assert-True([bool]$Value,[string]$Message) {
    if (-not $Value) { throw $Message }
}

function Write-FixtureFile([string]$Root,[string]$Relative,[string]$Content) {
    $path = Join-Path $Root $Relative
    $parent = Split-Path -Parent $path
    New-Item -ItemType Directory -Force -Path $parent | Out-Null
    [IO.File]::WriteAllText($path,$Content,[Text.UTF8Encoding]::new($false))
    return $path
}

function New-PriorInstallFixture([string]$Root,[switch]$UnexpectedOwnedRoot,[switch]$ChangeOwnedAfterReceipt) {
    New-Item -ItemType Directory -Force -Path (Join-Path $Root 'bin\x64') | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $Root 'r6') | Out-Null
    [IO.File]::WriteAllText((Join-Path $Root 'bin\x64\Cyberpunk2077.exe'),'fixture-game',[Text.UTF8Encoding]::new($false))

    $owned = @(
        'Install Biology.ps1',
        'BiologyReleaseInstall.Core.ps1',
        'INSTALL.txt',
        'UNINSTALL.txt',
        'BIOLOGY-VERSION.txt',
        'SHA256SUMS.txt',
        'Uninstall Biology.exe',
        'mods\Biology\info.json',
        'r6\scripts\CyberpunkRealism\Fixture.reds',
        'biology\provenance.json'
    )
    $shared = @(
        [pscustomobject]@{ path='engine\tools\scc.exe'; owner='upstream:redscript'; component='redscript' },
        [pscustomobject]@{ path='bin\x64\version.dll'; owner='upstream:cybercmd'; component='cybercmd' }
    )
    $entries = [Collections.Generic.List[object]]::new()
    foreach ($relative in $owned) {
        $path = Write-FixtureFile $Root $relative ('owned:' + $relative)
        $entries.Add([ordered]@{
            path=$relative.Replace('\','/'); sha256=(Get-FileHash -Algorithm SHA256 -LiteralPath $path).Hash.ToUpperInvariant()
            owner='Biology'; component='fixture-biology'; route='TEST'; replacePolicy='biology-owned'
        })
    }
    foreach ($item in $shared) {
        $path = Write-FixtureFile $Root ([string]$item.path) ('shared:' + [string]$item.path)
        $entries.Add([ordered]@{
            path=([string]$item.path).Replace('\','/'); sha256=(Get-FileHash -Algorithm SHA256 -LiteralPath $path).Hash.ToUpperInvariant()
            owner=[string]$item.owner; component=[string]$item.component; route='TEST'; replacePolicy='generic-dependency-shared'
        })
    }
    $unexpectedPath = $null
    if ($UnexpectedOwnedRoot) {
        $unexpectedPath = Write-FixtureFile $Root 'Unexpected-Biology-Root.txt' 'unexpected-root-owned'
        $entries.Add([ordered]@{
            path='Unexpected-Biology-Root.txt'; sha256=(Get-FileHash -Algorithm SHA256 -LiteralPath $unexpectedPath).Hash.ToUpperInvariant()
            owner='Biology'; component='forged-root'; route='TEST'; replacePolicy='biology-owned'
        })
    }

    $manifest = [ordered]@{
        schemaVersion=2; product='Biology'; buildId='prior-fixture'; version='fixture'; gameVersion='2.31'; sourceRevision=('1' * 40)
        playableRuntimeIncluded=$true; officialPackageRoot='mods/Biology'; files=@($entries)
        uninstall=[ordered]@{
            schemaVersion=2; playerBinary='Uninstall Biology.exe'; biologyOwnedPolicy='biology-owned'; genericDependencyPolicy='preserve'
            savePolicy='never-target'; preferencePolicy='stored-in-save-never-target'; redmodRefresh='official-redmod-deploy-explicit-root'
        }
    }
    $manifestPath = Join-Path $Root 'biology\build-manifest.json'
    $manifest | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $manifestPath -Encoding utf8

    $changedPath = Join-Path $Root 'mods\Biology\info.json'
    if ($ChangeOwnedAfterReceipt) {
        [IO.File]::WriteAllText($changedPath,'changed-after-receipt',[Text.UTF8Encoding]::new($false))
    }

    return [pscustomobject]@{
        root=$Root; manifest=$manifestPath; owned=@($owned); shared=@($shared); unexpected=$unexpectedPath; changed=$changedPath
    }
}

function Invoke-TransitionFixture([string]$TransitionExe,[string]$GameRoot,[string]$ReportPath) {
    & $TransitionExe ("--game-root=$GameRoot") ("--report=$ReportPath")
    return $LASTEXITCODE
}

$work = Join-Path ([IO.Path]::GetTempPath()) ('biology-uninstaller-ci-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $work | Out-Null
try {
    $player = Join-Path $work 'Uninstall Biology.exe'
    $tests = Join-Path $work 'BiologyUninstallCoreTests.exe'
    $transition = Join-Path $work 'BiologyPriorInstallTransition.exe'
    & (Join-Path $project 'tools\Build-BiologyUninstaller.ps1') -OutputPath $player -TestOutputPath $tests -TransitionOutputPath $transition | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'Biology uninstaller build helper failed.' }
    if (-not (Test-Path -LiteralPath $player -PathType Leaf) -or (Get-Item -LiteralPath $player).Length -le 0) { throw 'Player-facing Uninstall Biology.exe was not produced.' }
    if (-not (Test-Path -LiteralPath $tests -PathType Leaf)) { throw 'Biology uninstaller safety test executable was not produced.' }
    if (-not (Test-Path -LiteralPath $transition -PathType Leaf)) { throw 'Receipt-bounded prior-install transition helper was not produced.' }

    & $tests
    if ($LASTEXITCODE -ne 0) { throw "Biology uninstaller core tests failed with exit code $LASTEXITCODE." }

    $core = Get-Content -Raw -LiteralPath (Join-Path $project 'src\uninstaller\BiologyUninstallCore.cs')
    $program = Get-Content -Raw -LiteralPath (Join-Path $project 'src\uninstaller\BiologyUninstallerProgram.cs')
    $transitionSource = Get-Content -Raw -LiteralPath (Join-Path $project 'src\uninstaller\BiologyPriorInstallTransitionProgram.cs')
    $packageBuilder = Get-Content -Raw -LiteralPath (Join-Path $project 'tools\Build-BiologyPackage.ps1')
    foreach ($needle in @(
        'generic-dependency-shared',
        'PreserveChangedBiologyOwned',
        'BiologyOwnedPrefixes',
        'IsAllowedBiologyOwnedPath',
        'SharedRootNames',
        'stored-in-save-never-target',
        'official-redmod-deploy-explicit-root',
        'No mods found, no deployment is needed',
        'Install Biology.ps1',
        'BiologyReleaseInstall.Core.ps1'
    )) {
        if (-not ($core.Contains($needle))) { throw "Uninstaller core lost required safety contract: $needle" }
    }

    # Root-level ownership authority is intentionally narrow. Derive every
    # literal root Biology-owned payload currently emitted by the package builder
    # and require that exact filename to be represented in the core allowlist.
    # This makes future package-root additions fail CI until the deletion contract
    # is reviewed deliberately instead of reproducing the W15.4 drift.
    $emittedRootOwned = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($match in [regex]::Matches($packageBuilder,"(?m)^\s*Add-FileRecord\s+'(?<path>[^']+)'[^\r\n]*'biology-owned'\s*$")) {
        $path = $match.Groups['path'].Value
        if ($path -notmatch '[\\/]') { [void]$emittedRootOwned.Add($path) }
    }
    foreach ($match in [regex]::Matches($packageBuilder,"(?m)^\s*Copy-IntoPackage\s+\$[A-Za-z0-9_]+\s+'(?<path>[^']+)'[^\r\n]*'biology-owned'\s*$")) {
        $path = $match.Groups['path'].Value
        if ($path -notmatch '[\\/]') { [void]$emittedRootOwned.Add($path) }
    }
    $allowlistMatch = [regex]::Match($core,'(?s)BiologyOwnedRootFiles\s*=\s*new HashSet<string>\(StringComparer\.OrdinalIgnoreCase\)\s*\{(?<body>.*?)\};')
    Assert-True $allowlistMatch.Success 'Could not resolve the Biology-owned root-file allowlist for package contract comparison.'
    Assert-True ($emittedRootOwned.Count -ge 7) 'Package-builder root ownership scan found fewer intentional Biology-owned root files than expected.'
    foreach ($path in @($emittedRootOwned | Sort-Object)) {
        Assert-True ($allowlistMatch.Groups['body'].Value.Contains('"' + $path + '"')) "Package builder emits Biology-owned root file not accepted by uninstaller root allowlist: $path"
    }

    foreach ($forbidden in @('red4ext/plugins/mod_settings/user.ini','BiologyPreferenceCleaner','RemovePreferences','preferenceSection','preferencePath')) {
        if ($core.Contains($forbidden) -or $program.Contains($forbidden)) { throw "Provider-specific preference residue remains in uninstaller: $forbidden" }
    }
    foreach ($needle in @(
        'options.SkipRedmodRefresh = true',
        'Directory.Exists(biologyRedmod)',
        'REDmod refresh was deliberately not run because mods/Biology still contains',
        'AppendResidualDirectory(result, biologyScripts',
        'AppendResidualDirectory(result, biologyMetadata',
        'save-backed Biology preference/state'
    )) {
        if (-not ($program.Contains($needle)) -and -not ($core.Contains($needle))) { throw "Player uninstaller lost current safety contract: $needle" }
    }
    foreach ($needle in @(
        'BiologyUninstallPlanner.Build',
        'AssertReplacementPreflight',
        'AssertNoUntrackedOwnedNamespaceContent',
        'allowedDirectories',
        'untracked directory inside Biology-owned namespace',
        'BiologyUninstallExecutor.Execute',
        'SkipRedmodRefresh = true',
        'Game mutation started:'
    )) {
        if (-not $transitionSource.Contains($needle)) { throw "Prior-install transition helper lost safety contract: $needle" }
    }
    if ($core -match '(?i)Directory\.Delete\([^\)]*,\s*true\s*\)' -or $core -match '(?i)DeleteDirectory\w*Recursive') { throw 'Player uninstaller contains recursive directory deletion.' }
    if ($program -match '(?i)powershell|pwsh|vortex') { throw 'Player uninstaller unexpectedly invokes a developer/mod-manager tool.' }

    # Exact current Biology-owned root files are accepted by the same core used by
    # the player uninstaller. Shared dependency files survive the transition.
    $happy = New-PriorInstallFixture (Join-Path $work 'transition-happy')
    $happyReport = Join-Path $work 'transition-happy-report.txt'
    $happyExit = Invoke-TransitionFixture $transition $happy.root $happyReport
    Assert-True ($happyExit -eq 0) 'Valid prior Biology schema-2 candidate did not transition successfully.'
    $happyText = Get-Content -Raw -LiteralPath $happyReport
    Assert-True ($happyText -match '(?m)^RESULT: PASS\s*$') 'Valid prior-install transition did not report PASS.'
    Assert-True ($happyText -match '(?im)^Game mutation started:\s*True\s*$') 'Successful prior-install transition did not record its bounded mutation.'
    foreach ($relative in $happy.owned) {
        Assert-True (-not (Test-Path -LiteralPath (Join-Path $happy.root $relative))) "Biology-owned transition file remained: $relative"
    }
    Assert-True (-not (Test-Path -LiteralPath $happy.manifest)) 'Prior Biology receipt remained after successful transition.'
    foreach ($item in $happy.shared) {
        Assert-True (Test-Path -LiteralPath (Join-Path $happy.root ([string]$item.path))) "Shared dependency was removed during prior transition: $($item.path)"
    }

    # Adding another root-level filename to a forged Biology-owned receipt does
    # not gain deletion authority merely because current package root files were
    # added to the explicit allowlist.
    $unexpected = New-PriorInstallFixture (Join-Path $work 'transition-unexpected-root') -UnexpectedOwnedRoot
    $unexpectedReport = Join-Path $work 'transition-unexpected-report.txt'
    $unexpectedExit = Invoke-TransitionFixture $transition $unexpected.root $unexpectedReport
    Assert-True ($unexpectedExit -ne 0) 'Arbitrary Biology-owned root file was accepted by transition planner.'
    $unexpectedText = Get-Content -Raw -LiteralPath $unexpectedReport
    Assert-True ($unexpectedText -match '(?m)^RESULT: FAIL-CLOSED\s*$') 'Arbitrary root-file refusal did not fail closed.'
    Assert-True ($unexpectedText -match '(?im)^Game mutation started:\s*False\s*$') 'Arbitrary root-file refusal began mutation.'
    Assert-True (Test-Path -LiteralPath $unexpected.unexpected -PathType Leaf) 'Arbitrary root file was deleted despite allowlist refusal.'
    Assert-True (Test-Path -LiteralPath $unexpected.manifest -PathType Leaf) 'Receipt was removed despite arbitrary root-file refusal.'
    Assert-True (Test-Path -LiteralPath (Join-Path $unexpected.root 'Install Biology.ps1') -PathType Leaf) 'Known Biology root file changed during failed arbitrary-root preflight.'

    # Foreign directory structure under a Biology-owned namespace is also an
    # ambiguity. Even an empty directory not implied by the receipt fails before
    # any exact receipt-owned deletion begins.
    $foreignDirectory = New-PriorInstallFixture (Join-Path $work 'transition-foreign-directory')
    $foreignDirectoryPath = Join-Path $foreignDirectory.root 'mods\Biology\foreign-empty'
    New-Item -ItemType Directory -Force -Path $foreignDirectoryPath | Out-Null
    $foreignDirectoryReport = Join-Path $work 'transition-foreign-directory-report.txt'
    $foreignDirectoryExit = Invoke-TransitionFixture $transition $foreignDirectory.root $foreignDirectoryReport
    Assert-True ($foreignDirectoryExit -ne 0) 'Untracked empty directory inside Biology-owned namespace was accepted.'
    $foreignDirectoryText = Get-Content -Raw -LiteralPath $foreignDirectoryReport
    Assert-True ($foreignDirectoryText -match '(?m)^RESULT: FAIL-CLOSED\s*$') 'Untracked directory refusal did not fail closed.'
    Assert-True ($foreignDirectoryText -match '(?im)^Game mutation started:\s*False\s*$') 'Untracked directory refusal began mutation.'
    Assert-True (Test-Path -LiteralPath $foreignDirectoryPath -PathType Container) 'Untracked directory was removed despite preflight refusal.'
    Assert-True (Test-Path -LiteralPath $foreignDirectory.manifest -PathType Leaf) 'Receipt was removed despite untracked directory refusal.'
    Assert-True (Test-Path -LiteralPath (Join-Path $foreignDirectory.root 'BiologyReleaseInstall.Core.ps1') -PathType Leaf) 'Known Biology root file changed during failed directory preflight.'

    # A receipt-listed Biology-owned file whose bytes changed is preserved and
    # blocks the entire replacement transition before any game mutation begins.
    $changed = New-PriorInstallFixture (Join-Path $work 'transition-changed') -ChangeOwnedAfterReceipt
    $changedReport = Join-Path $work 'transition-changed-report.txt'
    $changedExit = Invoke-TransitionFixture $transition $changed.root $changedReport
    Assert-True ($changedExit -ne 0) 'Changed Biology-owned content was accepted for prior-install transition.'
    $changedText = Get-Content -Raw -LiteralPath $changedReport
    Assert-True ($changedText -match '(?m)^RESULT: FAIL-CLOSED\s*$') 'Changed Biology-owned transition did not fail closed.'
    Assert-True ($changedText -match '(?im)^Game mutation started:\s*False\s*$') 'Changed Biology-owned transition began mutation.'
    Assert-True (Test-Path -LiteralPath $changed.changed -PathType Leaf) 'Changed Biology-owned file was deleted.'
    Assert-True (Test-Path -LiteralPath $changed.manifest -PathType Leaf) 'Receipt was removed despite changed Biology-owned file.'
    Assert-True (Test-Path -LiteralPath (Join-Path $changed.root 'BiologyReleaseInstall.Core.ps1') -PathType Leaf) 'Another exact Biology-owned root file changed during failed preflight.'

    # The attended candidate path must build and collision-preflight the exact
    # target first, then retire a prior schema-2 candidate, verify residue, and
    # preflight again before target installation.
    $candidate = Get-Content -Raw -LiteralPath (Join-Path $project 'tools\Bootstrap-BiologyPostTransitionCandidate.ps1')
    foreach ($needle in @(
        '=== EXACT COMPILE / RELEASE-SHAPED TARGET BUILD ===',
        '=== COLLISION-SAFE TARGET PREFLIGHT AGAINST CURRENT INSTALL ===',
        'BiologyPriorInstallTransition.exe',
        '-TransitionOutputPath',
        '=== POST-TRANSITION BIOLOGY-SPECIFIC RESIDUE VERIFICATION ===',
        '=== COLLISION-SAFE INSTALL PREFLIGHT AFTER PRIOR-STATE TRANSITION ===',
        'Target install mutation started:'
    )) {
        Assert-True ($candidate.Contains($needle)) "Attended preparation lost prior-install transition contract: $needle"
    }
    $buildIndex = $candidate.IndexOf('=== EXACT COMPILE / RELEASE-SHAPED TARGET BUILD ===',[StringComparison]::Ordinal)
    $initialPreflightIndex = $candidate.IndexOf('=== COLLISION-SAFE TARGET PREFLIGHT AGAINST CURRENT INSTALL ===',[StringComparison]::Ordinal)
    $transitionIndex = $candidate.IndexOf('=== PRIOR SCHEMA-2 BIOLOGY CANDIDATE TRANSITION ===',[StringComparison]::Ordinal)
    $verifyIndex = $candidate.IndexOf('=== POST-TRANSITION BIOLOGY-SPECIFIC RESIDUE VERIFICATION ===',[StringComparison]::Ordinal)
    $secondPreflightIndex = $candidate.IndexOf('=== COLLISION-SAFE INSTALL PREFLIGHT AFTER PRIOR-STATE TRANSITION ===',[StringComparison]::Ordinal)
    Assert-True ($buildIndex -ge 0 -and $buildIndex -lt $initialPreflightIndex -and $initialPreflightIndex -lt $transitionIndex -and $transitionIndex -lt $verifyIndex -and $verifyIndex -lt $secondPreflightIndex) 'Attended preparation no longer protects the prior candidate behind target build/preflight or residue verification.'

    Write-Host 'PASS: player-facing Biology uninstaller and attended prior-install transition share the same schema-2/hash/path authority; package-root ownership is CI-synchronized, exact current root files transition, arbitrary root claims, foreign owned-namespace directory structure, and changed Biology content fail before mutation, and shared dependencies remain preserved.'
}
finally {
    if (Test-Path -LiteralPath $work) { Remove-Item -LiteralPath $work -Recurse -Force }
}