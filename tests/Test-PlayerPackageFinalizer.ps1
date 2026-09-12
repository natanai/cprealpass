$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\tools\Common.ps1"
$project = Get-ProjectRoot
$finalizer = Join-Path $project 'tools/Finalize-PlayerPackage.ps1'
$workRel = 'staging/player-package-finalizer-tests-' + [guid]::NewGuid().ToString('N')
$work = Resolve-SafeChildPath $project $workRel
$root = Join-Path $work 'root'
New-Item -ItemType Directory -Force -Path (Join-Path $root 'r6/scripts/CyberpunkRealism') | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $root 'realpass') | Out-Null
[IO.File]::WriteAllText((Join-Path $root 'INSTALL.txt'),"fixture install`n")
[IO.File]::WriteAllText((Join-Path $root 'UNINSTALL.txt'),"fixture uninstall`n")
[IO.File]::WriteAllText((Join-Path $root 'r6/scripts/CyberpunkRealism/RuntimePolicyModel.reds'),'fixture source')
[IO.File]::WriteAllText((Join-Path $root 'realpass/provenance.json'),'{"components":[{"id":"realpass-project-original"}]}')

$planRel = $workRel + '/plan.json'
$planPath = Resolve-SafeChildPath $project $planRel
$plan = [ordered]@{
    schemaVersion = 1
    product = 'realpass'
    files = @(
        [ordered]@{path='INSTALL.txt';component='realpass-project-original';owner='realpass';replacePolicy='realpass-owned'},
        [ordered]@{path='UNINSTALL.txt';component='realpass-project-original';owner='realpass';replacePolicy='realpass-owned'},
        [ordered]@{path='r6/scripts/CyberpunkRealism/RuntimePolicyModel.reds';component='realpass-project-original';owner='realpass';replacePolicy='realpass-owned'},
        [ordered]@{path='realpass/provenance.json';component='realpass-project-original';owner='realpass';replacePolicy='realpass-owned'}
    )
}
Write-JsonFile $plan $planPath

& $finalizer -Root $root -PlanPath $planRel -Version '0.0.0-fixture' -GameVersion '2.31' -SourceRevision 'abcdef1234567' | Out-Null
$manifestPath = Join-Path $root 'realpass/build-manifest.json'
$sumsPath = Join-Path $root 'SHA256SUMS.txt'
$versionPath = Join-Path $root 'REALPASS-VERSION.txt'
foreach ($generated in @($manifestPath,$sumsPath,$versionPath)) {
    if (-not (Test-Path -LiteralPath $generated -PathType Leaf)) { throw "Finalizer failed to create: $generated" }
}
$manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
if ($manifest.schemaVersion -ne 1 -or $manifest.product -ne 'realpass' -or $manifest.version -ne '0.0.0-fixture' -or $manifest.gameVersion -ne '2.31') { throw 'Generated owner manifest identity is invalid.' }
if (@($manifest.files).Count -ne 4) { throw 'Generated owner manifest did not contain every planned payload file.' }
foreach ($entry in @($manifest.files)) {
    if ($entry.owner -ne 'realpass' -or $entry.replacePolicy -ne 'realpass-owned' -or $entry.sha256 -notmatch '^[A-Fa-f0-9]{64}$') { throw "Invalid owner manifest entry: $($entry.path)" }
}
$sums = Get-Content -Raw -LiteralPath $sumsPath
if ($sums -notmatch 'realpass/build-manifest\.json' -or $sums -notmatch 'REALPASS-VERSION\.txt' -or $sums -match '(?m)SHA256SUMS\.txt$') { throw 'SHA256SUMS coverage/self-reference rule is invalid.' }

# Identical input and metadata arguments must produce identical final metadata.
$manifestHash1 = Get-Sha256 $manifestPath
$sumsHash1 = Get-Sha256 $sumsPath
& $finalizer -Root $root -PlanPath $planRel -Version '0.0.0-fixture' -GameVersion '2.31' -SourceRevision 'abcdef1234567' | Out-Null
if ((Get-Sha256 $manifestPath) -ne $manifestHash1 -or (Get-Sha256 $sumsPath) -ne $sumsHash1) { throw 'Player package metadata is not deterministic across identical finalization.' }

# An unplanned payload must fail closed.
$unplanned = Join-Path $root 'r6/scripts/CyberpunkRealism/Surprise.reds'
[IO.File]::WriteAllText($unplanned,'unplanned')
$rejectedUnplanned = $false
try { & $finalizer -Root $root -PlanPath $planRel -Version '0.0.0-fixture' -GameVersion '2.31' -SourceRevision 'abcdef1234567' | Out-Null } catch { $rejectedUnplanned = $_.Exception.Message -match 'Unplanned package file present' }
if (-not $rejectedUnplanned) { throw 'Unplanned player package payload was not rejected.' }
Remove-Item -LiteralPath $unplanned

# A distribution-blocked dependency may never enter a package plan.
$blockedRel = $workRel + '/blocked-plan.json'
$blockedPath = Resolve-SafeChildPath $project $blockedRel
$blockedPlan = [ordered]@{
    schemaVersion=1; product='realpass'; files=@(
        [ordered]@{path='r6/scripts/CyberpunkRealism/RuntimePolicyModel.reds';component='project-e3-hud';owner='realpass';replacePolicy='realpass-owned'}
    )
}
Write-JsonFile $blockedPlan $blockedPath
$rejectedBlocked = $false
try { & $finalizer -Root $root -PlanPath $blockedRel -Version '0.0.0-fixture' -GameVersion '2.31' -SourceRevision 'abcdef1234567' | Out-Null } catch { $rejectedBlocked = $_.Exception.Message -match 'Blocked component in player package plan: project-e3-hud' }
if (-not $rejectedBlocked) { throw 'Blocked Project E3 component was not rejected by package finalizer.' }

Write-Host 'PASS: player package finalizer is deterministic, owns every planned file, rejects unplanned payload, and rejects blocked dependencies.'
