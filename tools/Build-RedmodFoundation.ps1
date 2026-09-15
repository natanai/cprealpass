param(
    [string]$ContractPath = 'manifest/redmod-package.json',
    [string]$OutputRoot
)

$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'Build-RedmodFoundation.ps1 requires PowerShell 7 or newer.' }
. "$PSScriptRoot\Common.ps1"

$project = Get-ProjectRoot
$contractFile = Resolve-SafeChildPath $project $ContractPath
$contract = Get-Content -Raw -LiteralPath $contractFile | ConvertFrom-Json
if ($contract.schemaVersion -ne 1 -or $contract.product -ne 'Biology' -or $contract.packageId -ne 'Biology') {
    throw 'Unexpected REDmod package contract.'
}
if ($contract.supportedGameVersion -ne '2.31') { throw 'Foundation contract must stay pinned to Cyberpunk 2077 2.31 until explicitly migrated.' }

$infoPath = Resolve-SafeChildPath $project $contract.redmod.metadata
$info = Get-Content -Raw -LiteralPath $infoPath | ConvertFrom-Json
if ($info.name -ne 'Biology' -or $info.version -notmatch '^\d+\.\d+\.\d+(?:[-+][A-Za-z0-9.-]+)?$') {
    throw 'mods/Biology/info.json has invalid Biology identity/version.'
}
if ($null -eq $info.customSounds) { throw 'Biology info.json must declare customSounds, even when empty.' }

if (-not $OutputRoot) { $OutputRoot = Join-Path $project 'staging\redmod-foundation-packages' }
$OutputRoot = [IO.Path]::GetFullPath($OutputRoot)
New-Item -ItemType Directory -Force -Path $OutputRoot | Out-Null

$revision = 'source-archive'
$shortRevision = 'archive'
if (Test-Path -LiteralPath (Join-Path $project '.git')) {
    $candidateRevision = (& git -C $project rev-parse HEAD).Trim()
    if ($LASTEXITCODE -eq 0 -and $candidateRevision -match '^[A-Fa-f0-9]{40}$') {
        $revision = $candidateRevision.ToLowerInvariant()
        $shortRevision = $revision.Substring(0, 12)
    }
}

$buildId = "biology-redmod-foundation-$($info.version)-$shortRevision"
$packageRoot = Join-Path $OutputRoot ($buildId + '-root')
$zipPath = Join-Path $OutputRoot ($buildId + '.zip')
if (Test-Path -LiteralPath $packageRoot) { Remove-Item -LiteralPath $packageRoot -Recurse -Force }
if (Test-Path -LiteralPath $zipPath) { Remove-Item -LiteralPath $zipPath -Force }
New-Item -ItemType Directory -Force -Path $packageRoot | Out-Null

$owned = [Collections.Generic.List[object]]::new()
$seen = @{}
function Add-OwnedFile([string]$RelativePath, [string]$Owner, [string]$Component, [string]$Route, [string]$ReplacePolicy) {
    $normalized = $RelativePath.Replace('\','/').TrimStart('/')
    if ($seen.ContainsKey($normalized)) { throw "Duplicate foundation destination: $normalized" }
    $seen[$normalized] = $true
    $absolute = Resolve-SafeChildPath $packageRoot $normalized
    if (-not (Test-Path -LiteralPath $absolute -PathType Leaf)) { throw "Owned file not materialized: $normalized" }
    $owned.Add([ordered]@{
        path = $normalized
        sha256 = Get-Sha256 $absolute
        owner = $Owner
        component = $Component
        route = $Route
        replacePolicy = $ReplacePolicy
    })
}

foreach ($entry in @($contract.files)) {
    if ($entry.owner -ne 'Biology' -or $entry.route -ne 'REDMOD-NATIVE') {
        throw "Foundation REDmod payload contains a non-Biology/non-REDmod-native entry: $($entry.destination)"
    }
    $source = Resolve-SafeChildPath $project ([string]$entry.source)
    if (-not (Test-Path -LiteralPath $source -PathType Leaf)) { throw "Foundation source missing: $($entry.source)" }
    $destination = Resolve-SafeChildPath $packageRoot ([string]$entry.destination)
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $destination) | Out-Null
    $hash = Get-Sha256 $source
    Copy-VerifiedPayload $source $destination $hash
    Add-OwnedFile ([string]$entry.destination) 'Biology' ([string]$entry.component) ([string]$entry.route) 'biology-owned'
}

$install = @'
Biology REDmod foundation package

STATUS
This is the non-playable REDmod package/dependency foundation. It proves package shape and ownership; it does not yet contain the integrated Biology runtime.

INSTALL SHAPE
1. Cyberpunk 2077 and official REDmod support must be installed.
2. Close Cyberpunk 2077.
3. Copy the package contents into the Cyberpunk 2077 game root so this path exists exactly:
   mods\Biology\info.json
4. Enable REDmod-compatible mods using the supported REDlauncher/Steam flow, then allow REDmod deployment to complete before play.
5. After enable/deploy has been proven on the supported 2.31 installation, ordinary Steam launch is the target normal-play path. Biology does not require a custom permanent launcher.

DEVELOPER / DIAGNOSTIC DEPLOY
Official REDmod documentation exposes tools\redmod\bin\redMod.exe deploy -root=<Cyberpunk 2077> and the game's -modded flag. The exact installed 2.31 executable/version/help output is a direct-game evidence gate tracked in docs/REDMOD-PACKAGE-FOUNDATION.md.

Do not copy repository tests, tools, reports, staging, vendor files, ReferenceMods, saves, stock game files, or historical source-mod runtime into a player install.
'@
$installPath = Join-Path $packageRoot 'INSTALL.txt'
[IO.File]::WriteAllText($installPath, $install.TrimStart() + "`n", [Text.UTF8Encoding]::new($false))
Add-OwnedFile 'INSTALL.txt' 'Biology' 'biology-release-metadata' 'REDMOD-NATIVE' 'biology-owned'

$uninstall = @'
Biology REDmod foundation package

DISABLE
Use the supported REDmod launcher/store control to disable REDmod-compatible mods. Disabling is not uninstalling and must never be treated as a destructive save-state reset.

UNINSTALL
1. Close Cyberpunk 2077.
2. Remove only Biology-owned files listed in biology\build-manifest.json.
3. For this foundation skeleton, the only runtime package path is mods\Biology\info.json plus Biology release metadata written by this package.
4. Remove empty Biology-owned directories only after their listed files are gone.
5. Never delete shared game, engine, r6, red4ext, archive, or framework directories wholesale.

If ownership cannot be proven from the installed manifest, stop and use the milestone clean-room procedure in docs/CLEAN-ROOM-TESTING.md rather than guessing.
'@
$uninstallPath = Join-Path $packageRoot 'UNINSTALL.txt'
[IO.File]::WriteAllText($uninstallPath, $uninstall.TrimStart() + "`n", [Text.UTF8Encoding]::new($false))
Add-OwnedFile 'UNINSTALL.txt' 'Biology' 'biology-release-metadata' 'REDMOD-NATIVE' 'biology-owned'

$versionPath = Join-Path $packageRoot 'BIOLOGY-VERSION.txt'
[IO.File]::WriteAllText($versionPath, "Biology $($info.version)`nBuild: $buildId`nSource: $revision`nGame: $($contract.supportedGameVersion)`n", [Text.UTF8Encoding]::new($false))
Add-OwnedFile 'BIOLOGY-VERSION.txt' 'Biology' 'biology-release-metadata' 'REDMOD-NATIVE' 'biology-owned'

$metadataRoot = Resolve-SafeChildPath $packageRoot ([string]$contract.generatedMetadata.root)
New-Item -ItemType Directory -Force -Path $metadataRoot | Out-Null
$provenancePath = Resolve-SafeChildPath $packageRoot ([string]$contract.generatedMetadata.provenance)
$provenance = [ordered]@{
    schemaVersion = 1
    product = 'Biology'
    packageId = 'Biology'
    version = [string]$info.version
    buildId = $buildId
    sourceRevision = $revision
    foundationBaseRevision = [string]$contract.foundationBaseRevision
    gameVersion = [string]$contract.supportedGameVersion
    redmodFirst = $true
    playableRuntimeIncluded = $false
    dependencyGraph = 'manifest/dependency-graph.json'
    classification = 'manifest/redmod-classification.json'
}
Write-JsonFile $provenance $provenancePath
Add-OwnedFile ([string]$contract.generatedMetadata.provenance) 'Biology' 'biology-release-metadata' 'REDMOD-NATIVE' 'biology-owned'

$ownerManifestPath = Resolve-SafeChildPath $packageRoot ([string]$contract.generatedMetadata.ownerManifest)
$ownerManifest = [ordered]@{
    schemaVersion = 1
    product = 'Biology'
    packageId = 'Biology'
    version = [string]$info.version
    buildId = $buildId
    sourceRevision = $revision
    gameVersion = [string]$contract.supportedGameVersion
    playableRuntimeIncluded = $false
    files = @($owned.ToArray())
    selfVerification = [ordered]@{
        manifestPath = [string]$contract.generatedMetadata.ownerManifest
        manifestSha256Location = [string]$contract.generatedMetadata.checksums
        checksumFileSha256Location = 'release artifact hash / external transport checksum'
        note = 'The manifest cannot contain its own byte hash without recursion; SHA256SUMS.txt hashes the finalized manifest.'
    }
}
Write-JsonFile $ownerManifest $ownerManifestPath

$checksumPath = Resolve-SafeChildPath $packageRoot ([string]$contract.generatedMetadata.checksums)
$checksumLines = [Collections.Generic.List[string]]::new()
foreach ($file in @(Get-ChildItem -LiteralPath $packageRoot -Recurse -File | Sort-Object FullName)) {
    if ($file.FullName -eq $checksumPath) { continue }
    $relative = [IO.Path]::GetRelativePath($packageRoot, $file.FullName).Replace('\','/')
    $checksumLines.Add("$(Get-Sha256 $file.FullName)  $relative")
}
[IO.File]::WriteAllLines($checksumPath, $checksumLines, [Text.UTF8Encoding]::new($false))

# Verify the final tree before archiving. SHA256SUMS itself is transport metadata and
# is intentionally not self-hashed; every other finalized file must match its line.
foreach ($line in $checksumLines) {
    if ($line -notmatch '^(?<hash>[A-F0-9]{64})  (?<path>.+)$') { throw "Malformed checksum line: $line" }
    $target = Resolve-SafeChildPath $packageRoot $Matches.path
    if ((Get-Sha256 $target) -ne $Matches.hash) { throw "Final checksum mismatch: $($Matches.path)" }
}

Compress-Archive -Path (Join-Path $packageRoot '*') -DestinationPath $zipPath -CompressionLevel Optimal
if (-not (Test-Path -LiteralPath $zipPath -PathType Leaf) -or (Get-Item -LiteralPath $zipPath).Length -le 0) {
    throw 'REDmod foundation archive was not created.'
}

Write-Host "PASS: Biology REDmod foundation artifact built without touching Cyberpunk: $zipPath" -ForegroundColor Green
return $zipPath
