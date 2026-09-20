param(
    [string]$GameRoot = 'C:\Games\Steam\steamapps\common\Cyberpunk 2077',
    [string]$OutputRoot,
    [switch]$Diagnostics
)
$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'Build-BiologyPackage.ps1 requires PowerShell 7 or newer.' }
. "$PSScriptRoot\Common.ps1"

$project = Get-ProjectRoot
$game = Assert-GameRoot $GameRoot
Assert-GameStopped

$gameVersion = (Get-Item -LiteralPath (Join-Path $game 'bin\x64\Cyberpunk2077.exe')).VersionInfo.ProductVersion
if ($gameVersion -ne '2.31') { throw "Biology integrated packaging currently supports Cyberpunk 2077 2.31; installed game reports $gameVersion." }

if (-not $OutputRoot) { $OutputRoot = Join-Path $project 'staging\biology-packages' }
$OutputRoot = [IO.Path]::GetFullPath($OutputRoot)
New-Item -ItemType Directory -Force -Path $OutputRoot | Out-Null

$revision = 'source-archive'
$shortRevision = 'archive'
if (Test-Path -LiteralPath (Join-Path $project '.git')) {
    $dirty = @(& git -C $project status --porcelain=v1 --untracked-files=no)
    if ($LASTEXITCODE -ne 0) { throw 'Unable to inspect repository state.' }
    if ($dirty.Count -gt 0) {
        throw "Biology package build requires no modified tracked files. Commit/push the candidate or use a fresh clone/download first.`n$($dirty -join "`n")"
    }
    $revision = (& git -C $project rev-parse HEAD).Trim()
    if ($LASTEXITCODE -ne 0 -or $revision -notmatch '^[A-Fa-f0-9]{40}$') { throw 'Unable to resolve repository revision.' }
    $shortRevision = $revision.Substring(0,12).ToLowerInvariant()
}

$packageContract = Get-Content -Raw -LiteralPath (Join-Path $project 'manifest\redmod-package.json') | ConvertFrom-Json
$dependencyGraph = Get-Content -Raw -LiteralPath (Join-Path $project 'manifest\dependency-graph.json') | ConvertFrom-Json
$info = Get-Content -Raw -LiteralPath (Join-Path $project 'mods\Biology\info.json') | ConvertFrom-Json
if ($packageContract.product -ne 'Biology' -or $packageContract.packageId -ne 'Biology') { throw 'Unexpected Biology REDmod package contract.' }
if ($packageContract.redmod.packageRoot -ne 'mods/Biology') { throw 'Biology REDmod package root drifted.' }
if ($info.name -ne 'Biology') { throw 'mods/Biology/info.json does not declare Biology.' }

$stamp = [DateTime]::UtcNow.ToString('yyyyMMdd-HHmmss')
$buildId = "biology-integrated-$stamp-$shortRevision"
$runtimeBuildId = $buildId + '-runtime'
$packageRoot = Join-Path $OutputRoot ($buildId + '-root')
$zipPath = Join-Path $OutputRoot ($buildId + '.zip')
if ((Test-Path -LiteralPath $packageRoot) -or (Test-Path -LiteralPath $zipPath)) { throw "Biology package output already exists for build ID: $buildId" }
New-Item -ItemType Directory -Force -Path $packageRoot | Out-Null

# Hard gate: exact-compile the complete current runtime against Cyberpunk 2077 2.31.
$profileArgs = @{ BuildId = $runtimeBuildId; GameRoot = $game }
if ($Diagnostics) { $profileArgs.Diagnostics = $true }
$runtimeManifestRelative = & "$PSScriptRoot\Build-OwnedRuntimeProfile.ps1" @profileArgs
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace([string]$runtimeManifestRelative)) { throw 'Integrated Biology runtime profile build/exact compile failed.' }
$runtimeManifestPath = Resolve-SafeChildPath $project ([string]$runtimeManifestRelative)
$runtimeManifest = Get-Content -Raw -LiteralPath $runtimeManifestPath | ConvertFrom-Json
if ($runtimeManifest.schemaVersion -ne 1 -or -not $runtimeManifest.ownedRuntime -or $runtimeManifest.gameVersion -ne $gameVersion) { throw 'Unexpected integrated Biology runtime manifest.' }
$compileReportPath = Join-Path $project ('reports\compile-' + $runtimeBuildId + '.json')
if (-not (Test-Path -LiteralPath $compileReportPath -PathType Leaf)) { throw 'Integrated exact-compile report is missing.' }
$compileReport = Get-Content -Raw -LiteralPath $compileReportPath | ConvertFrom-Json
if ($compileReport.passed -ne $true -or $compileReport.exitCode -ne 0 -or $compileReport.outputPresent -ne $true) { throw 'Integrated exact compile did not pass.' }

$files = [Collections.Generic.List[object]]::new()
$dependencyComponents = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
function Add-FileRecord([string]$RelativePath,[string]$Owner,[string]$Component,[string]$Route,[string]$ReplacePolicy) {
    $normalized = $RelativePath.Replace('\','/').TrimStart('/')
    $target = Resolve-SafeChildPath $packageRoot $normalized
    if (-not (Test-Path -LiteralPath $target -PathType Leaf)) { throw "Cannot record missing package file: $normalized" }
    if (@($files | Where-Object { $_.path -eq $normalized }).Count -gt 0) { throw "Duplicate package ownership path: $normalized" }
    $files.Add([ordered]@{
        path = $normalized
        sha256 = Get-Sha256 $target
        owner = $Owner
        component = $Component
        route = $Route
        replacePolicy = $ReplacePolicy
    })
}
function Copy-IntoPackage([string]$Source,[string]$RelativePath,[string]$ExpectedSha256,[string]$Owner,[string]$Component,[string]$Route,[string]$ReplacePolicy) {
    $destination = Resolve-SafeChildPath $packageRoot $RelativePath
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $destination) | Out-Null
    Copy-VerifiedPayload $Source $destination $ExpectedSha256
    Add-FileRecord $RelativePath $Owner $Component $Route $ReplacePolicy
}

# Official REDmod identity plus a deliberately inert REDmod-owned activation record.
# The loose REDscript runtime may still compile when launcher mods are OFF; all
# Biology behavior therefore fails closed unless this record exists in active TweakDB.
$infoSource = Join-Path $project 'mods\Biology\info.json'
Copy-IntoPackage $infoSource 'mods/Biology/info.json' (Get-Sha256 $infoSource) 'Biology' 'biology-redmod-identity' 'REDMOD-NATIVE' 'biology-owned'
$activationRelative = 'mods/Biology/tweaks/base/gameplay/static_data/database/items/weapons/parts/biology_activation.tweak'
$activationSource = Resolve-SafeChildPath $project $activationRelative
if (-not (Test-Path -LiteralPath $activationSource -PathType Leaf)) { throw 'Biology REDmod activation marker source is missing.' }
$activationText = Get-Content -Raw -LiteralPath $activationSource
$activationPackage = [regex]::Match($activationText,'(?m)^\s*package\s+Items\s*$')
$activationRecord = [regex]::Match($activationText,'(?m)^\s*BiologyLauncherActivationMarker\s*:\s*IconicWeaponModAbilityBase\s*$')
if (-not $activationPackage.Success -or -not $activationRecord.Success -or $activationPackage.Index -gt $activationRecord.Index -or $activationText -match '(?m)^\s*using\s+Items\s*$' -or $activationText -notmatch '(?m)^\s*stackable\s*=\s*true\s*;\s*$') {
    throw 'Biology REDmod activation marker no longer matches the supported-source package/read-path contract.'
}
Copy-IntoPackage $activationSource $activationRelative (Get-Sha256 $activationSource) 'Biology' 'biology-launcher-activation' 'REDMOD-NATIVE' 'biology-owned'

# Supplemental runtime. Project-original files are Biology-owned. The retained
# generic runtime is redscript (SCC/config) plus standalone cybercmd (the startup
# task runner that executes scc.toml/InvokeScc without restoring RED4ext/CET).
# Both upstream components are exact-hash inventoried and shared at uninstall time.
$routeByComponent = @{
    'redscript' = 'REDSCRIPT-BETTER'
    'cybercmd' = 'REDSCRIPT-STARTUP'
}
foreach ($entry in @($runtimeManifest.files)) {
    $source = Resolve-SafeChildPath $project ([string]$entry.source)
    if ((Get-Sha256 $source) -ne [string]$entry.sha256) { throw "Runtime source hash mismatch: $($entry.source)" }
    $destination = ([string]$entry.destination).Replace('\','/')
    $origin = if ($entry.PSObject.Properties.Name -contains 'origin') { [string]$entry.origin } else { 'pinned-generic-framework' }
    if ($origin -eq 'project-original') {
        Copy-IntoPackage $source $destination ([string]$entry.sha256) 'Biology' ([string]$entry.component) 'REDSCRIPT-BETTER' 'biology-owned'
    } else {
        $component = [string]$entry.component
        if (-not $routeByComponent.ContainsKey($component)) { throw "Unexpected retained generic component in Biology runtime: $component" }
        [void]$dependencyComponents.Add($component)
        Copy-IntoPackage $source $destination ([string]$entry.sha256) ('upstream:' + $component) $component $routeByComponent[$component] 'generic-dependency-shared'
    }
}

$expectedRetained = @('redscript','cybercmd')
foreach ($id in $expectedRetained) {
    if (-not $dependencyComponents.Contains($id)) { throw "Playable Biology candidate is missing retained dependency payload: $id" }
}
foreach ($id in @($dependencyComponents)) {
    if ($id -notin $expectedRetained) { throw "Unexpected dependency entered playable Biology package: $id" }
}

# License snapshots follow both retained generic components and are preserved by
# the player uninstaller rather than treated as Biology-owned payload.
$licenseRoot = Join-Path $packageRoot 'LICENSES'
New-Item -ItemType Directory -Force -Path $licenseRoot | Out-Null
foreach ($component in @($dependencyComponents | Sort-Object)) {
    $matches = @(Get-ChildItem -LiteralPath (Join-Path $project 'LICENSES') -File -Filter ($component + '-v*.txt'))
    if ($matches.Count -ne 1) { throw "Expected exactly one tracked license snapshot for retained component '$component', found $($matches.Count)." }
    $relative = 'LICENSES/' + $component + '.txt'
    $destination = Resolve-SafeChildPath $packageRoot $relative
    Copy-Item -LiteralPath $matches[0].FullName -Destination $destination
    Add-FileRecord $relative ('upstream:' + $component) ('license-notice:' + $component) $routeByComponent[$component] 'generic-dependency-shared'
}

# The release carries its collision-safe player installer. Parent attended
# candidate tooling invokes the same repository source directly against the exact
# package root, so parent and player installation semantics cannot diverge.
$installerSource = Join-Path $project 'tools\Install-BiologyRelease.ps1'
$installerCoreSource = Join-Path $project 'tools\BiologyReleaseInstall.Core.ps1'
$installerBinary = Join-Path $packageRoot 'Install Biology.exe'
& "$PSScriptRoot\Build-BiologyInstaller.ps1" -OutputPath $installerBinary | Out-Null
Add-FileRecord 'Install Biology.exe' 'Biology' 'biology-player-installer' 'REDMOD-NATIVE' 'biology-owned'
Copy-IntoPackage $installerSource 'Install Biology.ps1' (Get-Sha256 $installerSource) 'Biology' 'biology-player-installer' 'REDMOD-NATIVE' 'biology-owned'
Copy-IntoPackage $installerCoreSource 'BiologyReleaseInstall.Core.ps1' (Get-Sha256 $installerCoreSource) 'Biology' 'biology-player-installer' 'REDMOD-NATIVE' 'biology-owned'

$installText = @'
Biology — REDmod-first player release

SUPPORTED GAME
Cyberpunk 2077 2.31 with the official REDmod tools installed

INSTALL
1. Close Cyberpunk 2077.
2. Extract this package to a temporary/staging folder OUTSIDE the Cyberpunk 2077 game root. DO NOT extract/copy the package directly into the Cyberpunk 2077 game root.
3. Double-click "Install Biology.exe" in the extracted folder. Select your Cyberpunk 2077 folder and click Install Biology. No PowerShell installation or security-policy change is required.
4. The installer verifies every inventoried package hash before writing. Shared dependency files must be absent or byte-identical. Upgrades replace only unchanged files owned by the previous Biology receipt; conflicts stop before changes. A failed transaction restores its prior files when they have not changed concurrently.
5. Verify mods\Biology\info.json is present.
6. Use the supported REDlauncher/store REDmod flow with Enable mods ON.
7. Launch normally through Steam.

Do not bypass the Biology installer with a blind ZIP merge. standalone cybercmd's shared ASI-loader/config files may already belong to another mod, so direct overwrite is not a supported Biology installation/update path.

PLAYER ENABLE/DISABLE CONTRACT
- REDlauncher Enable mods ON: Biology's REDmod activation record is active and Biology runs.
- REDlauncher Enable mods OFF: the REDmod activation record is absent, so Biology's supplemental REDscript hooks fail closed to native Cyberpunk behavior even though shared redscript/cybercmd compilation plumbing can still load.
- redscript/cybercmd are runtime plumbing only. Neither component is Biology activation authority; the REDmod-owned marker remains the sole whole-mod signal.
- REDlauncher is the whole-mod activation boundary. Biology does not maintain a second in-game master switch.
- The only normal in-game preference is E3 HUD + nameplates. It is presentation-only, save-persistent, and editable from the Biology body screen.
- Turning launcher mods OFF is not uninstall and does not delete saves, Biology state, or the E3 presentation preference.

UNINSTALL
Double-click "Uninstall Biology.exe" in the Cyberpunk 2077 game root. No PowerShell, Git, Vortex, mod manager, or game reinstall is required. The uninstaller removes only exact-hash Biology-owned payload, preserves changed/ambiguous files, preserves the shared redscript/cybercmd dependencies, and never targets saves. Because the E3 preference lives in Biology save state, uninstall leaves it untouched together with the save.

The release evidence distinguishes compile/model/lifecycle checks from native gameplay and save-reload observations.
'@
[IO.File]::WriteAllText((Join-Path $packageRoot 'INSTALL.txt'),$installText.TrimStart() + "`n",[Text.UTF8Encoding]::new($false))
Add-FileRecord 'INSTALL.txt' 'Biology' 'biology-package-metadata' 'REDMOD-NATIVE' 'biology-owned'

$uninstallText = @'
Biology player uninstall

Close Cyberpunk 2077, then double-click "Uninstall Biology.exe" in the game root.

The uninstaller is driven by biology\build-manifest.json. It will:
- refuse unsafe/rooted/traversal/duplicate ownership paths;
- remove only Biology-owned files whose SHA-256 still matches the package receipt;
- preserve any changed or ambiguous Biology-owned file for manual review;
- preserve the retained generic/shared redscript and cybercmd dependencies rather than guessing whether another mod needs them;
- remove only now-empty Biology-owned directories and never recursively delete shared roots;
- never access or delete Cyberpunk saves, which also means save-backed Biology preference/state is preserved;
- ask the official REDmod tool to refresh deployment using the explicit game root, without recursively clearing shared REDmod cache directories.

If a changed Biology file is preserved, the ownership receipt itself is also preserved so the remaining file stays auditable.
'@
[IO.File]::WriteAllText((Join-Path $packageRoot 'UNINSTALL.txt'),$uninstallText.TrimStart() + "`n",[Text.UTF8Encoding]::new($false))
Add-FileRecord 'UNINSTALL.txt' 'Biology' 'biology-package-metadata' 'REDMOD-NATIVE' 'biology-owned'

$version = [string]$info.version + '+' + $stamp + '.' + $shortRevision
$versionText = @(
    ('Biology ' + $version),
    ('Cyberpunk 2077 ' + $gameVersion),
    ('source ' + $revision),
    'REDmod package mods/Biology'
) -join "`n"
[IO.File]::WriteAllText((Join-Path $packageRoot 'BIOLOGY-VERSION.txt'),$versionText + "`n",[Text.UTF8Encoding]::new($false))
Add-FileRecord 'BIOLOGY-VERSION.txt' 'Biology' 'biology-package-metadata' 'REDMOD-NATIVE' 'biology-owned'

$biologyDir = Join-Path $packageRoot 'biology'
New-Item -ItemType Directory -Force -Path $biologyDir | Out-Null
$provenance = [ordered]@{
    schemaVersion = 3
    product = 'Biology'
    buildId = $buildId
    version = $version
    sourceRevision = $revision
    gameVersion = $gameVersion
    redmodFirst = $true
    officialPackageRoot = 'mods/Biology'
    launcherActivation = [ordered]@{
        mechanism = 'REDmod-owned inert TweakDB marker'
        record = 'Items.BiologyLauncherActivationMarker'
        accessor = 'CRRealpassSettings.IsLauncherActivated()'
        failClosed = $true
        launcherOffTarget = 'Biology behavior inactive / native Cyberpunk behavior'
        publicMasterPreference = $false
    }
    preferences = [ordered]@{
        provider = 'biology-owned'
        persistence = 'Cyberpunk save / ScriptableSystem persistent field'
        editor = 'Biology body shell'
        controls = @('presentation.e3-first-person-hud-visuals')
    }
    playableRuntimeIncluded = $true
    exactCompile = [ordered]@{
        required = $true
        passed = $true
        buildId = $runtimeBuildId
        sourceCount = [int]$compileReport.sourceCount
        baseBundleSha256 = [string]$compileReport.baseBundleSha256
        scope = [string]$compileReport.scope
    }
    retainedDependencies = @(
        [ordered]@{ id='redscript'; uninstall='preserve'; reason='Required by accepted Biology-owned additive/wrapper REDscript runtime, ScriptableSystem persistence, Ink UI, native seams, and SCC configuration.' },
        [ordered]@{ id='cybercmd'; uninstall='preserve'; reason='Required only to execute redscript scc.toml InvokeScc at startup and regenerate the configured r6/cache/modded/final.redscripts without restoring RED4ext/CET.' }
    )
    removedDependencies = @('mod-settings','archivexl','red4ext','tweakxl','codeware','input-loader','darkfuture','project-e3-hud')
    sourceModsRequired = @()
    localLifecycleEvidence = 'docs/evidence/AUTONOMOUS-COMPLETION-2026-09-20.md; exact artifact/source/installed receipt reconciliation is in the local release report'
    directGameGatesRemaining = @('rendered UI and actual REDlauncher checkbox ON/OFF behavior','E3 preference body-shell edit + native save/reload persistence','in-save body/combat/quest/performance observation','PKG-05 safe overlap/precedence fixture')
}
Write-JsonFile $provenance (Join-Path $biologyDir 'provenance.json')
Add-FileRecord 'biology/provenance.json' 'Biology' 'biology-package-metadata' 'REDMOD-NATIVE' 'biology-owned'

# Build the Windows player uninstaller into the exact same release-shaped root.
$uninstallerPath = Join-Path $packageRoot 'Uninstall Biology.exe'
& "$PSScriptRoot\Build-BiologyUninstaller.ps1" -OutputPath $uninstallerPath | Out-Null
if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $uninstallerPath -PathType Leaf)) { throw 'Biology player uninstaller build failed.' }
Add-FileRecord 'Uninstall Biology.exe' 'Biology' 'biology-player-uninstaller' 'REDMOD-NATIVE' 'biology-owned'

# SHA256SUMS covers every finalized payload file that exists before the ownership
# receipt. The receipt cannot hash itself; it is instead constrained by schema,
# product, path allowlists and re-hashed in memory while uninstall runs.
$sumLines = [Collections.Generic.List[string]]::new()
foreach ($file in @(Get-ChildItem -LiteralPath $packageRoot -Recurse -File -Force | Sort-Object FullName)) {
    $relative = [IO.Path]::GetRelativePath($packageRoot,$file.FullName).Replace('\','/')
    if ($relative -eq 'SHA256SUMS.txt' -or $relative -eq 'biology/build-manifest.json') { continue }
    $sumLines.Add(((Get-Sha256 $file.FullName).ToLowerInvariant() + '  ' + $relative))
}
[IO.File]::WriteAllText((Join-Path $packageRoot 'SHA256SUMS.txt'),($sumLines -join "`n") + "`n",[Text.UTF8Encoding]::new($false))
Add-FileRecord 'SHA256SUMS.txt' 'Biology' 'biology-package-checksums' 'REDMOD-NATIVE' 'biology-owned'

$manifest = [ordered]@{
    schemaVersion = 2
    product = 'Biology'
    buildId = $buildId
    version = $version
    gameVersion = $gameVersion
    sourceRevision = $revision
    playableRuntimeIncluded = $true
    officialPackageRoot = 'mods/Biology'
    files = @($files.ToArray() | Sort-Object path)
    uninstall = [ordered]@{
        schemaVersion = 2
        playerBinary = 'Uninstall Biology.exe'
        biologyOwnedPolicy = 'biology-owned'
        genericDependencyPolicy = 'preserve'
        savePolicy = 'never-target'
        preferencePolicy = 'stored-in-save-never-target'
        redmodRefresh = 'official-redmod-deploy-explicit-root'
    }
    install = [ordered]@{
        playerBinary = 'Install Biology.exe'
        playerScript = 'Install Biology.ps1'
        coreScript = 'BiologyReleaseInstall.Core.ps1'
        sharedLoaderPolicy = 'All shared dependencies: create when absent, preserve when byte-identical, refuse conflicting files before mutation'
        directZipMergeSupported = $false
    }
    metadataHashRule = 'SHA256SUMS.txt hashes every finalized payload file except itself and biology/build-manifest.json. The schema-2 owner receipt inventories and hashes every removable/preserved payload file, and the uninstaller re-hashes the receipt during execution.'
}
Write-JsonFile $manifest (Join-Path $biologyDir 'build-manifest.json')

# Final fail-closed checks.
foreach ($entry in @($manifest.files)) {
    $target = Resolve-SafeChildPath $packageRoot ([string]$entry.path)
    if ((Get-Sha256 $target) -ne [string]$entry.sha256) { throw "Final Biology artifact hash mismatch: $($entry.path)" }
    if ($entry.replacePolicy -notin @('biology-owned','generic-dependency-shared')) { throw "Unexpected package uninstall policy: $($entry.path) / $($entry.replacePolicy)" }
}
$binaryEntry = @($manifest.files | Where-Object path -eq 'Uninstall Biology.exe')
if ($binaryEntry.Count -ne 1 -or $binaryEntry[0].replacePolicy -ne 'biology-owned') { throw 'Player uninstaller is not exact-hash Biology-owned payload.' }
foreach ($installerPath in @('Install Biology.exe','Install Biology.ps1','BiologyReleaseInstall.Core.ps1')) {
    $installerEntry = @($manifest.files | Where-Object path -eq $installerPath)
    if ($installerEntry.Count -ne 1 -or $installerEntry[0].component -ne 'biology-player-installer' -or $installerEntry[0].replacePolicy -ne 'biology-owned') { throw "Player collision-safe installer payload is not exact-hash Biology-owned: $installerPath" }
}
$markerEntry = @($manifest.files | Where-Object path -eq $activationRelative)
if ($markerEntry.Count -ne 1 -or $markerEntry[0].replacePolicy -ne 'biology-owned') { throw 'REDmod launcher activation marker is missing from exact ownership.' }
foreach ($requiredShared in @('bin/x64/global.ini','bin/x64/plugins/cybercmd.asi','bin/x64/version.dll')) {
    $entry = @($manifest.files | Where-Object path -eq $requiredShared)
    if ($entry.Count -ne 1 -or $entry[0].component -ne 'cybercmd' -or $entry[0].replacePolicy -ne 'generic-dependency-shared' -or $entry[0].route -ne 'REDSCRIPT-STARTUP') {
        throw "Required standalone cybercmd startup payload is not exact-hash shared runtime plumbing: $requiredShared"
    }
}
foreach ($blocked in @('darkfuture','project e3','project-e3','input-loader','tweakxl','codeware','mod-settings','mod_settings','archivexl','archive xl','red4ext')) {
    $hit = @(Get-ChildItem -LiteralPath $packageRoot -Recurse -File | Where-Object { $_.FullName.ToLowerInvariant().Contains($blocked) })
    if ($hit.Count -gt 0) { throw "Blocked runtime/dependency content leaked into Biology package: $($hit[0].FullName)" }
}
& "$PSScriptRoot\Test-ArtifactPolicy.ps1" -Root $packageRoot
if ($LASTEXITCODE -ne 0) { throw 'Artifact policy rejected integrated Biology package.' }

Compress-Archive -Path (Join-Path $packageRoot '*') -DestinationPath $zipPath -CompressionLevel Optimal
if (-not (Test-Path -LiteralPath $zipPath -PathType Leaf) -or (Get-Item -LiteralPath $zipPath).Length -le 0) { throw 'Integrated Biology package ZIP was not created.' }

Write-Host ''
Write-Host 'PASS: playable integrated Biology REDmod-first package built with collision-safe player install, self-contained preference authority, REDscript startup compilation plumbing, launcher activation contract, and player uninstaller. Nothing was deployed or launched.' -ForegroundColor Green
Write-Host "Package root: $packageRoot"
Write-Host "ZIP:          $zipPath"
Write-Host "Game version: $gameVersion"
Write-Host "Revision:     $revision"
Write-Host "REDmod ID:    mods/Biology"
return $zipPath
