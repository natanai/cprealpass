$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'Test-LegacyFrameworkTransition.ps1 requires PowerShell 7 or newer.' }
$project = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
. (Join-Path $project 'tools/LegacyFrameworkTransition.Core.ps1')

function Assert-True([bool]$Condition,[string]$Message) { if (-not $Condition) { throw $Message } }
function Write-Utf8([string]$Path,[string]$Text) { New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Path) | Out-Null; [IO.File]::WriteAllText($Path,$Text,[Text.UTF8Encoding]::new($false)) }
function Sha([string]$Path) { (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToUpperInvariant() }

function New-Fixture {
    $root = Join-Path ([IO.Path]::GetTempPath()) ('biology-w11-' + [guid]::NewGuid().ToString('N'))
    $game = Join-Path $root 'game'; New-Item -ItemType Directory -Force -Path $game | Out-Null
    $baseline = Join-Path $root 'baseline.csv'
    '"Path","SizeBytes","Sha256"' | Set-Content -LiteralPath $baseline -Encoding utf8
    $distribution = Join-Path $root 'distribution.json'
    @{schemaVersion=3;removedDependencies=@('mod-settings','archivexl','red4ext')} | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $distribution -Encoding utf8
    $profiles = Join-Path $root 'profiles.json'
    @{schemaVersion=2;profiles=@{'biology-runtime'=@('redscript')}} | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $profiles -Encoding utf8
    $contract = Join-Path $root 'contract.json'; Copy-Item -LiteralPath (Join-Path $project 'manifest/legacy-framework-transition.json') -Destination $contract

    $spec = @(
        @{path='red4ext/RED4ext.dll';component='red4ext';content='red4ext-fixture'},
        @{path='red4ext/plugins/ArchiveXL/ArchiveXL.dll';component='archivexl';content='archivexl-fixture'},
        @{path='red4ext/plugins/mod_settings/mod_settings.dll';component='mod-settings';content='mod-settings-fixture'},
        @{path='engine/tools/scc.exe';component='redscript';content='redscript-fixture'}
    )
    $files = [Collections.Generic.List[object]]::new()
    foreach ($item in $spec) {
        $full = Join-Path $game $item.path.Replace('/',[IO.Path]::DirectorySeparatorChar)
        Write-Utf8 $full $item.content
        $files.Add([ordered]@{path=$item.path;sha256=(Sha $full);owner=('upstream:'+$item.component);component=$item.component;route='fixture';replacePolicy='generic-dependency-shared'})
    }
    $manifest = [ordered]@{
        schemaVersion=2;product='Biology';buildId='fixture';version='fixture';gameVersion='2.31';sourceRevision='7e61724071b8c95ba5c334ab9e8d11c43381c94e';playableRuntimeIncluded=$true;officialPackageRoot='mods/Biology';files=@($files.ToArray());uninstall=[ordered]@{schemaVersion=1;biologyOwnedPolicy='biology-owned';genericDependencyPolicy='preserve';preferencePath='red4ext/plugins/mod_settings/user.ini';preferenceSection='CyberpunkRealism.Settings.CRRealpassSettings'}
    }
    $manifestPath = Join-Path $game 'biology/build-manifest.json'; New-Item -ItemType Directory -Force -Path (Split-Path -Parent $manifestPath) | Out-Null; $manifest | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $manifestPath -Encoding utf8
    [pscustomobject]@{Root=$root;Game=$game;Baseline=$baseline;Distribution=$distribution;Profiles=$profiles;Contract=$contract;Manifest=$manifestPath}
}
function Plan($f) { Get-LegacyFrameworkTransitionPlan -GameRoot $f.Game -BaselinePath $f.Baseline -ManifestPath $f.Manifest -TransitionContractPath $f.Contract -DistributionPath $f.Distribution -ProfilesPath $f.Profiles }
function Cleanup-Fixture($f) { if (Test-Path -LiteralPath $f.Root) { Remove-Item -LiteralPath $f.Root -Recurse -Force } }

# Exact hashes + baseline absence => safe; redscript is not a deletion candidate.
$f = New-Fixture
try {
    $p = Plan $f
    Assert-True $p.safeToApply ('Exact-hash fixture should be safe to apply. Blockers: ' + (@($p.blockers) -join ' | '))
    Assert-True (@($p.deletionCandidates).Count -eq 3) 'Expected exactly three retired dependency files in deletion set.'
    Assert-True (@($p.deletionCandidates | Where-Object component -eq 'redscript').Count -eq 0) 'redscript entered deletion set.'
    Assert-True (@($p.preservedRedscript).Count -eq 1) 'redscript preservation set missing.'
} finally { Cleanup-Fixture $f }

# Changed retired file blocks.
$f = New-Fixture
try {
    Write-Utf8 (Join-Path $f.Game 'red4ext/RED4ext.dll') 'changed-after-install'
    $p = Plan $f
    Assert-True (-not $p.safeToApply) 'Changed retired file should block cleanup.'
    Assert-True ((@($p.blockers) -join "`n") -match 'changed from the installed receipt') 'Changed-file blocker missing.'
} finally { Cleanup-Fixture $f }

# Missing retired file is safely reported already absent.
$f = New-Fixture
try {
    Remove-Item -LiteralPath (Join-Path $f.Game 'red4ext/plugins/ArchiveXL/ArchiveXL.dll') -Force
    $p = Plan $f
    Assert-True $p.safeToApply 'Already-absent retired file should not force broader deletion.'
    Assert-True (@($p.alreadyAbsent | Where-Object component -eq 'archivexl').Count -eq 1) 'Missing file not classified AlreadyAbsent.'
} finally { Cleanup-Fixture $f }

# Vanilla overlap blocks even with exact hash.
$f = New-Fixture
try {
    $path = 'red4ext/RED4ext.dll'; $full = Join-Path $f.Game 'red4ext/RED4ext.dll'
    ('"Path","SizeBytes","Sha256"' + "`n" + ('"{0}","{1}","{2}"' -f $path,(Get-Item $full).Length,(Sha $full))) | Set-Content -LiteralPath $f.Baseline -Encoding utf8
    $p = Plan $f
    Assert-True (-not $p.safeToApply) 'Vanilla-overlap retired path should block cleanup.'
    Assert-True ((@($p.blockers) -join "`n") -match 'vanilla baseline contains') 'Vanilla-overlap blocker missing.'
} finally { Cleanup-Fixture $f }

# Unreceipted mod payload is competing-consumer evidence and blocks whole cleanup.
$f = New-Fixture
try {
    Write-Utf8 (Join-Path $f.Game 'mods/OtherMod/info.json') '{"name":"OtherMod"}'
    $p = Plan $f
    Assert-True (-not $p.safeToApply) 'Unreceipted mod payload should block cleanup.'
    Assert-True (@($p.consumerEvidence | Where-Object { $_ -eq 'mods/OtherMod/info.json' }).Count -eq 1) 'Consumer evidence path missing.'
} finally { Cleanup-Fixture $f }

# Biology-only old preference state is preserved; foreign section blocks.
$f = New-Fixture
try {
    $ini = Join-Path $f.Game 'red4ext/plugins/mod_settings/user.ini'
    Write-Utf8 $ini "[CyberpunkRealism.Settings.CRRealpassSettings]`nbiologyEnabled=true`n"
    $p = Plan $f
    Assert-True $p.safeToApply 'Biology-only old preference state should be preserved without blocking.'
    Assert-True (@($p.deletionCandidates | Where-Object path -eq 'red4ext/plugins/mod_settings/user.ini').Count -eq 0) 'Preference file entered deletion set.'
    Write-Utf8 $ini "[CyberpunkRealism.Settings.CRRealpassSettings]`nbiologyEnabled=true`n[Another.Mod]`nvalue=true`n"
    $p2 = Plan $f
    Assert-True (-not $p2.safeToApply) 'Foreign Mod Settings section should block cleanup.'
    Assert-True ((@($p2.consumerEvidence) -join "`n") -match 'Another.Mod') 'Foreign preference consumer evidence missing.'
} finally { Cleanup-Fixture $f }

# Executor re-hashes immediately, deletes exact retired files, preserves redscript and protected roots.
$f = New-Fixture
try {
    New-Item -ItemType Directory -Force -Path (Join-Path $f.Game 'red4ext/plugins') | Out-Null
    $p = Plan $f
    $redscript = Join-Path $f.Game 'engine/tools/scc.exe'; $redscriptHash = Sha $redscript
    Invoke-LegacyRetiredFileRemoval -GameRoot $f.Game -DeletionCandidates @($p.deletionCandidates) -ProtectedDirectories @((Get-Content -Raw -LiteralPath $f.Contract | ConvertFrom-Json).protectedDirectories)
    Assert-True (Test-Path -LiteralPath $redscript -PathType Leaf) 'redscript was removed by transition executor.'
    Assert-True ((Sha $redscript) -eq $redscriptHash) 'redscript changed during transition executor.'
    Assert-True (Test-Path -LiteralPath (Join-Path $f.Game 'red4ext/plugins') -PathType Container) 'Protected red4ext/plugins root was removed.'
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $f.Game 'red4ext/plugins/mod_settings/mod_settings.dll'))) 'Exact Mod Settings payload was not removed.'
} finally { Cleanup-Fixture $f }

# Change after planning is fail-closed before the first target is removed.
$f = New-Fixture
try {
    $p = Plan $f
    $target = Join-Path $f.Game 'red4ext/plugins/mod_settings/mod_settings.dll'; Write-Utf8 $target 'changed-after-plan'
    $earlierRed4ext = Join-Path $f.Game 'red4ext/RED4ext.dll'
    $earlierArchiveXl = Join-Path $f.Game 'red4ext/plugins/ArchiveXL/ArchiveXL.dll'
    $threw = $false
    try { Invoke-LegacyRetiredFileRemoval -GameRoot $f.Game -DeletionCandidates @($p.deletionCandidates) -ProtectedDirectories @((Get-Content -Raw -LiteralPath $f.Contract | ConvertFrom-Json).protectedDirectories) } catch { $threw = $true }
    Assert-True $threw 'Executor should reject a file changed after planning.'
    Assert-True (Test-Path -LiteralPath $target -PathType Leaf) 'Changed file should remain after fail-closed rejection.'
    Assert-True (Test-Path -LiteralPath $earlierRed4ext -PathType Leaf) 'Preflight failure partially removed RED4ext before detecting a later changed target.'
    Assert-True (Test-Path -LiteralPath $earlierArchiveXl -PathType Leaf) 'Preflight failure partially removed ArchiveXL before detecting a later changed target.'
} finally { Cleanup-Fixture $f }

$probeSource = Get-Content -Raw -LiteralPath (Join-Path $project 'tools/Bootstrap-LegacyFrameworkTransitionProbe.ps1')
$cleanupSource = Get-Content -Raw -LiteralPath (Join-Path $project 'tools/Bootstrap-LegacyFrameworkTransitionCleanup.ps1')
Assert-True ($probeSource -match 'ATTACH THIS FILE TO CHATGPT:') 'Probe bootstrap lacks attachment handoff.'
Assert-True ($probeSource -match 'ExpectedHead') 'Probe bootstrap does not pin exact head.'
Assert-True ($probeSource -match 'READ-ONLY') 'Probe bootstrap does not state read-only game policy.'
Assert-True ($cleanupSource -match 'ExpectedPlanSha256') 'Cleanup bootstrap does not pin approved plan hash.'
Assert-True ($cleanupSource -match 'MUTATING') 'Cleanup bootstrap does not explicitly identify mutation.'

# Bootstrap repository discovery must accept ordinary clones and linked worktrees by asking Git for origin identity,
# rather than assuming every usable checkout has a physical .git\config file. Offline continuation is permitted only
# when the cached origin branch and local commit object both equal the exact frozen head.
foreach ($source in @($probeSource,$cleanupSource)) {
    Assert-True ($source -match "'remote','get-url','origin'") 'W11 bootstrap does not validate seed repository identity through Git origin.'
    Assert-True ($source -match "'rev-parse','--show-toplevel'") 'W11 bootstrap does not validate candidate checkout through Git.'
    Assert-True ($source -notmatch [regex]::Escape('.git\config')) 'W11 bootstrap still assumes a physical .git\config and can miss linked worktrees.'
    Assert-True ($source -match 'cached remote branch') 'W11 bootstrap lacks explicit cached-origin branch verification after fetch failure.'
    Assert-True ($source -match "'cat-file','-e'") 'W11 bootstrap does not prove the expected commit object exists before offline fallback.'
    Assert-True ($source -match 'Offline exact-head fallback: ACCEPTED') 'W11 bootstrap does not report the exact-head offline fallback decision.'
}

Write-Host 'PASS: W11 legacy framework transition is exact-hash, baseline-aware, consumer-safe, redscript-preserving, plan-bound, worktree-aware, offline-exact-head-capable, and fail-closed.'
