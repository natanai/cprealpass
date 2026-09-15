$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'Test-IntegratedBiologyPackage.ps1 requires PowerShell 7 or newer.' }
. "$PSScriptRoot\..\tools\Common.ps1"

$project = Get-ProjectRoot
$package = Get-Content -Raw -LiteralPath (Join-Path $project 'manifest/redmod-package.json') | ConvertFrom-Json
$deps = Get-Content -Raw -LiteralPath (Join-Path $project 'manifest/dependency-graph.json') | ConvertFrom-Json
$install = Get-Content -Raw -LiteralPath (Join-Path $project 'manifest/redmod-install-contract.json') | ConvertFrom-Json
$settings = Get-Content -Raw -LiteralPath (Join-Path $project 'src/redscript/CyberpunkRealism/RealpassSettings.reds')
$builderPath = Join-Path $project 'tools/Build-BiologyPackage.ps1'
$deployPath = Join-Path $project 'tools/Deploy-BiologyRedmod.ps1'
$docPath = Join-Path $project 'docs/REDMOD-INTEGRATED-ASSEMBLY.md'
foreach ($path in @($builderPath,$deployPath,$docPath)) { if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Missing integrated package asset: $path" } }
$builder = Get-Content -Raw -LiteralPath $builderPath
$deploy = Get-Content -Raw -LiteralPath $deployPath
$doc = Get-Content -Raw -LiteralPath $docPath

$script:checks = 0
function Check($condition,[string]$message) { if (-not $condition) { throw $message }; $script:checks++ }

Check ($package.schemaVersion -eq 2) 'Integrated REDmod package schema was not promoted.'
Check ($package.status -eq 'playable-integrated-candidate') 'Package is still described as a non-playable foundation.'
Check ($package.integratedBaseRevision -eq 'bfd6f7469139c64f0b9185724619a37e4ced5eca') 'Integrated candidate base revision drifted.'
Check ($package.canonicalBuilder -eq 'tools/Build-BiologyPackage.ps1') 'Canonical builder is not Build-BiologyPackage.ps1.'
Check ($package.canonicalBuildCommand -eq 'pwsh ./tools/Build-BiologyPackage.ps1') 'Canonical build command is ambiguous.'
Check ($package.exactCompileRequiredBeforeArtifact -eq $true) 'Exact compilation is not a package-emission requirement.'
Check ($package.redmod.packageRoot -eq 'mods/Biology') 'Official REDmod identity is not mods/Biology.'
Check ($package.redmod.deployCommand -match 'deploy -root=<Cyberpunk 2077>') 'Package contract does not require deterministic explicit REDmod root.'
$runtimeEntry = @($package.firstPartyFiles | Where-Object { $_.component -eq 'biology-owned-runtime' })
Check ($runtimeEntry.Count -eq 1 -and $runtimeEntry[0].destinationRoot -eq 'r6/scripts/CyberpunkRealism' -and $runtimeEntry[0].route -eq 'REDSCRIPT-BETTER') 'Package contract lost Biology-owned supplemental REDscript destination/route.'

Check ($builder.Contains('Build-OwnedRuntimeProfile.ps1')) 'Integrated builder bypasses the exact-compiled owned runtime profile.'
Check ($builder -match 'reports[\\/]compile-') 'Integrated builder does not consume the exact compile report.'
Check ($builder.Contains('$compileReport.passed -ne $true')) 'Integrated builder does not fail closed on compile result.'
Check ($builder.Contains('$compileReport.exitCode -ne 0')) 'Integrated builder does not require compiler exit code zero.'
Check ($builder.Contains('$compileReport.outputPresent -ne $true')) 'Integrated builder does not require compiler output.'
Check ($builder -match '\$gameVersion\s+-ne\s+''2\.31''') 'Integrated builder does not pin the supported game version.'
Check ($builder.Contains("'mods/Biology/info.json'")) 'Integrated builder does not include official Biology REDmod metadata.'
Check ($builder -match '\$expectedRetained\s*=\s*@\(''redscript'',''red4ext'',''archivexl'',''mod-settings''\)') 'Integrated builder retained dependency set is not exact/fail-closed.'
foreach ($blocked in @('tweakxl','codeware','input-loader','darkfuture','project-e3')) {
    Check ($builder.ToLowerInvariant().Contains($blocked)) "Integrated builder does not explicitly reject/exclude $blocked."
}
Check ($builder.Contains('biology/build-manifest.json')) 'Integrated owner manifest is not generated.'
Check ($builder.Contains('biology/provenance.json')) 'Integrated provenance is not generated.'
Check ($builder.Contains('BIOLOGY-VERSION.txt')) 'Integrated Biology version marker is missing.'
Check ($builder.Contains('SHA256SUMS.txt')) 'Integrated checksums are missing.'
Check ($builder.Contains('playableRuntimeIncluded = $true')) 'Integrated artifact does not declare that playable runtime is included.'
Check ($builder.Contains('sourceModsRequired = @()')) 'Integrated artifact does not explicitly reject source-mod runtime requirements.'
Check (-not $builder.Contains('Build-RedmodFoundation.ps1')) 'Playable builder delegates to non-playable foundation skeleton.'

Check ($deploy -match 'tools\\redmod\\bin\\redMod\.exe') 'Deploy helper does not use the official probed REDmod executable.'
Check ($deploy -match '-root=\$game') 'Deploy helper does not pass an explicit game root.'
Check ($deploy.Contains("FileVersion -ne '2.3.1.0'")) 'Deploy helper does not guard the directly evidenced REDmod file version.'
Check ($deploy.Contains("ProductVersion -ne '2.31'")) 'Deploy helper does not guard the directly evidenced REDmod product version.'

$dep = @{}
foreach ($entry in @($deps.dependencies)) { $dep[$entry.id] = $entry }
Check ($dep['redscript'].status -eq 'required-current-runtime' -and $dep['redscript'].route -eq 'REDSCRIPT-BETTER' -and $dep['redscript'].bundledByBiology -eq $true) 'redscript is not recorded as the direct retained runtime dependency.'
Check ($dep['mod-settings'].status -eq 'temporary-retained-blocker' -and $dep['mod-settings'].route -eq 'REMOVE/RETHINK' -and $dep['mod-settings'].bundledByBiology -eq $true) 'Mod Settings temporary provider blocker is not explicit.'
Check ($dep['mod-settings'].ownerLaneBlocker -match 'Lane C') 'Settings-provider removal blocker is not routed to Lane C.'
foreach ($id in @('archivexl','red4ext')) {
    Check ($dep[$id].status -eq 'temporary-transitive' -and $dep[$id].bundledByBiology -eq $true) "$id is not recorded as temporary transitive settings plumbing."
}
foreach ($id in @('tweakxl','codeware','input-loader')) {
    Check ($dep[$id].status -eq 'not-required' -and $dep[$id].bundledByBiology -eq $false) "$id unexpectedly survives the integrated candidate."
}
foreach ($id in @('darkfuture','project-e3-hud')) {
    Check ($dep[$id].status -eq 'blocked-runtime' -and $dep[$id].bundledByBiology -eq $false) "$id source/reference runtime became packageable."
}

Check ($settings.Contains('public static func IsEnabled(game: GameInstance)')) 'Biology master semantics are not provider-neutral.'
Check ($settings.Contains('public static func UseE3FirstPersonHudVisuals(game: GameInstance)')) 'E3 presentation semantics are not provider-neutral.'
Check ($settings.Contains('@if(ModuleExists("ModSettingsModule"))')) 'Current optional settings adapter is not guarded.'
Check ($settings.Contains('ModSettings.RegisterListenerToClass(this)')) 'Current accessible settings adapter disappeared without a replacement provider.'
Check ($doc -match 'player-accessible persistent provider') 'Integrated documentation does not state the exact settings-provider removal blocker.'
Check ($doc -match 'presentation/settings lane blocker') 'Settings removal work is not routed back to the owning lane.'
Check ($doc -match 'MILESTONE CLEAN-ROOM') 'Structural integrated candidate does not require milestone clean-room attended acceptance.'
Check ($doc -match 'PKG-06') 'Transition/rollback rule is not documented.'

Check ($install.ownerManifest.path -eq 'biology/build-manifest.json') 'Install contract lost exact owner manifest.'
foreach ($root in @('bin','engine','r6','red4ext')) {
    Check (@($install.neverRecursivelyOwnedRoots) -contains $root) "Install contract permits recursive ownership of shared root $root."
}
Check (@($install.remainingDirectGameGates).Count -ge 5) 'Direct-game gates were collapsed into source/CI assumptions.'

Write-Host "PASS: $script:checks integrated Biology package checks; canonical builder is playable/REDmod-first, exact-compile-gated, dependency-minimal for current consumers, and still explicit about live-game gates."
