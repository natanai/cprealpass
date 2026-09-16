$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'Test-PlayerDisableContract.ps1 requires PowerShell 7 or newer.' }
. "$PSScriptRoot\..\tools\Common.ps1"
$project = Get-ProjectRoot

$markerPath = Join-Path $project 'mods\Biology\tweaks\base\gameplay\static_data\database\items\weapons\parts\biology_activation.tweak'
$settingsPath = Join-Path $project 'src\redscript\CyberpunkRealism\RealpassSettings.reds'
$builderPath = Join-Path $project 'tools\Build-BiologyPackage.ps1'
$installPath = Join-Path $project 'manifest\redmod-install-contract.json'
$packagePath = Join-Path $project 'manifest\redmod-package.json'
$docPath = Join-Path $project 'docs\PLAYER-DISABLE-UNINSTALL.md'
$operatorDocPath = Join-Path $project 'docs\LOCAL-OPERATOR-COMMANDS.md'
$verifyPath = Join-Path $project 'tools\Verify-BiologyRemoval.ps1'
foreach ($path in @($markerPath,$settingsPath,$builderPath,$installPath,$packagePath,$docPath,$operatorDocPath,$verifyPath)) { if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Missing player-disable contract asset: $path" } }

$marker = Get-Content -Raw -LiteralPath $markerPath
$settings = Get-Content -Raw -LiteralPath $settingsPath
$builder = Get-Content -Raw -LiteralPath $builderPath
$install = Get-Content -Raw -LiteralPath $installPath | ConvertFrom-Json
$package = Get-Content -Raw -LiteralPath $packagePath | ConvertFrom-Json
$doc = Get-Content -Raw -LiteralPath $docPath
$operatorDoc = Get-Content -Raw -LiteralPath $operatorDocPath

$markerPackage = [regex]::Match($marker,'(?m)^\s*package\s+Items\s*$')
$markerRecord = [regex]::Match($marker,'(?m)^\s*BiologyLauncherActivationMarker\s*:\s*IconicWeaponModAbilityBase\s*$')
if (-not $markerPackage.Success -or -not $markerRecord.Success -or $markerPackage.Index -gt $markerRecord.Index -or $marker -match '(?m)^\s*using\s+Items\s*$' -or $marker -notmatch '(?m)^\s*stackable\s*=\s*true\s*;\s*$') { throw 'REDmod-owned Biology launcher activation marker grammar drifted.' }
if ($settings -notmatch 'public static func IsLauncherActivated\(\) -> Bool' -or $settings -notmatch 'Items\.BiologyLauncherActivationMarker\.stackable') { throw 'Biology settings accessor does not consume REDmod-owned launcher marker.' }
if ($settings -notmatch '(?s)public static func IsEnabled\(game: GameInstance\) -> Bool\s*\{.*?return CRRealpassSettings\.IsLauncherActivated\(\);.*?\}') { throw 'REDlauncher is not the sole whole-mod activation authority.' }
if ($settings -match '(?m)public\s+(?:persistent\s+)?let\s+enabled\s*:\s*Bool') { throw 'Redundant persisted Biology master switch returned.' }
if ($settings -notmatch 'CRRealpassSettings\.IsEnabled\(game\)' -or $settings -notmatch 'settings\.e3FirstPersonHudVisuals') { throw 'E3 presentation preference is no longer subordinate to launcher activation.' }
if ($settings -match '(?i)ModSettings|mod_settings') { throw 'Launcher activation source still contains old settings-provider residue.' }

if ($builder -notmatch [regex]::Escape('mods/Biology/tweaks/base/gameplay/static_data/database/items/weapons/parts/biology_activation.tweak')) { throw 'Canonical player package builder does not package REDmod activation marker.' }
if ($builder -notmatch [regex]::Escape('Uninstall Biology.exe') -or $builder -notmatch [regex]::Escape('Build-BiologyUninstaller.ps1')) { throw 'Canonical player package builder does not compile/package self-contained uninstaller.' }
if ($builder -notmatch 'generic-dependency-shared') { throw 'Canonical package lost shared/preserve generic dependency policy.' }
$expectedRetainedLiteral = '$expectedRetained = @(''redscript'',''cybercmd'')'
if (-not $builder.Contains($expectedRetainedLiteral)) { throw 'Canonical package is not limited to redscript plus the startup task runner.' }
if ($builder -notmatch "'cybercmd'\s*=\s*'REDSCRIPT-STARTUP'") { throw 'Canonical package does not constrain cybercmd to REDscript startup compilation.' }

if ($install.launcherActivation.signal -ne 'Items.BiologyLauncherActivationMarker.stackable' -or $install.playerUninstaller.binary -ne 'Uninstall Biology.exe') { throw 'Install contract lost launcher activation or player uninstaller identity.' }
if ($install.launcherActivation.publicMasterPreference -ne $false) { throw 'Install contract reintroduced in-game whole-mod master preference.' }
if ($install.playerUninstaller.preferences -notmatch '(?i)stored in saves|saves.*untouched') { throw 'Install contract lost save-backed preference preservation.' }
if ($install.playerUninstaller.genericDependencies -notmatch '(?i)redscript' -or $install.playerUninstaller.genericDependencies -notmatch '(?i)cybercmd') { throw 'Install contract lost exact surviving generic dependency policy.' }
if (@($install.neverRecursivelyOwnedRoots) -notcontains 'mods' -or @($install.neverRecursivelyOwnedRoots) -notcontains 'r6' -or @($install.neverRecursivelyOwnedRoots) -notcontains 'bin') { throw 'Install contract no longer protects shared roots from recursive ownership.' }
if ($package.redmod.launcherActivationMarker -ne 'Items.BiologyLauncherActivationMarker.stackable') { throw 'REDmod package contract and runtime activation signal disagree.' }
if ($doc -notmatch 'Launcher-OFF runtime audit' -or $doc -notmatch 'may still load' -or $doc -notmatch 'Attended checks still required' -or $doc -notmatch 'P01\.1 owns attended|parent.*owns attended') { throw 'Player disable/uninstall documentation lost runtime audit or parent-owned attended acceptance boundary.' }
if ($operatorDoc -notmatch 'Verify-BiologyRemoval\.ps1' -or $operatorDoc -notmatch 'double-click.*Uninstall Biology\.exe') { throw 'Canonical local-operator catalog does not expose player hard-uninstall verification.' }

Write-Host "PASS: REDlauncher/REDmod remains Biology's sole whole-mod activation boundary; E3 state is presentation-only and shared generic runtime is limited to redscript plus cybercmd startup plumbing."
