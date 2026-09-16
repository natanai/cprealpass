$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = Split-Path -Parent $PSScriptRoot
. (Join-Path $root 'tools\BiologyReleaseInstall.Core.ps1')
. (Join-Path $root 'tools\BiologyFailedInstallRecovery.Core.ps1')
. (Join-Path $root 'tools\BiologyOperatorEvidence.Core.ps1')

function Assert-True([bool]$Value,[string]$Message) {
    if (-not $Value) { throw $Message }
}

function Write-TestFile([string]$Base,[string]$Relative,[string]$Text) {
    $path = Resolve-BiologyReleaseChild $Base $Relative
    $parent = Split-Path -Parent $path
    if (-not [string]::IsNullOrWhiteSpace($parent)) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
    [IO.File]::WriteAllText($path,$Text,[Text.UTF8Encoding]::new($false))
    return [pscustomobject]@{ path=$path; sha256=(Get-BiologyOperatorSha256 $path) }
}

function New-ExactEvidence([string]$SourceRevision,[object[]]$Files,[string]$ReceiptHash,[bool]$Eligible=$true) {
    return [pscustomobject]@{
        schemaVersion = 1
        product = 'Biology'
        evidenceId = 'fixture-exact-evidence'
        operation = 'fixture'
        createdUtc = [DateTime]::UtcNow.ToString('o')
        sourceRevision = $SourceRevision
        result = 'FAIL-CLOSED'
        proofBoundary = 'fixture'
        game = [pscustomobject]@{ productVersion='2.31' }
        artifact = [pscustomobject]@{ name='fixture.zip'; sha256=('A' * 64); bytes=1; buildId='fixture-build' }
        install = [pscustomobject]@{ gameMutationStarted=$true }
        recovery = [pscustomobject]@{ mode='exact-payload-manifest'; eligible=$Eligible; receiptSha256=$ReceiptHash }
        cleanup = [pscustomobject]@{ artifactRootName=$null; artifactZipName=$null; packageRootName=$null }
        handoff = [pscustomobject]@{ bundleName='Biology-Operator-Evidence-fixture-exact-evidence.zip'; reportSha256=('B' * 64) }
        payloadManifest = [pscustomobject]@{ schemaVersion=2; product='Biology'; gameVersion='2.31'; sourceRevision=$SourceRevision; buildId='fixture-build'; files=$Files }
    }
}

function New-ManifestEntry([string]$Path,[string]$Hash,[string]$Policy,[string]$Component='fixture') {
    return [pscustomobject]@{ path=$Path; sha256=$Hash; replacePolicy=$Policy; component=$Component }
}

function Write-EvidenceBundle([string]$Path,[string]$EvidenceJson,[string]$ReportText) {
    $dir = Join-Path ([IO.Path]::GetTempPath()) ('biology-evidence-bundle-write-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    try {
        [IO.File]::WriteAllText((Join-Path $dir 'evidence.json'),$EvidenceJson,[Text.UTF8Encoding]::new($false))
        [IO.File]::WriteAllText((Join-Path $dir 'report.txt'),$ReportText,[Text.UTF8Encoding]::new($false))
        if (Test-Path -LiteralPath $Path) { Remove-Item -LiteralPath $Path -Force }
        Compress-Archive -LiteralPath (Join-Path $dir 'evidence.json'),(Join-Path $dir 'report.txt') -DestinationPath $Path -CompressionLevel Optimal
    } finally {
        if (Test-Path -LiteralPath $dir) { Remove-Item -LiteralPath $dir -Recurse -Force }
    }
}

$temp = Join-Path ([IO.Path]::GetTempPath()) ('biology-operator-evidence-lifecycle-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $temp | Out-Null
try {
    # The checked-in legacy record is deliberately narrower than exact-payload
    # recovery. Its report identity is text-normalized so Git/Windows newline
    # conversion cannot turn equivalent durable evidence into a false mismatch.
    $legacyRoot = Join-Path $root 'docs\operator-evidence\legacy-20260916-04d4c158-first-install-failure'
    $legacyEvidencePath = Join-Path $legacyRoot 'evidence.json'
    $legacyReportPath = Join-Path $legacyRoot 'report.txt'
    foreach ($required in @($legacyEvidencePath,$legacyReportPath)) { Assert-True (Test-Path -LiteralPath $required -PathType Leaf) "Missing durable legacy evidence: $required" }
    $legacy = Get-Content -Raw -LiteralPath $legacyEvidencePath | ConvertFrom-Json
    [void](Assert-BiologyOperatorEvidenceRecord $legacy)
    Assert-True ([string]$legacy.recovery.mode -eq 'empty-owned-roots-only') 'Legacy current-state evidence is not constrained to empty-owned-roots-only.'
    Assert-True ((Get-BiologyOperatorTextSha256 $legacyReportPath) -eq ([string]$legacy.handoff.reportSha256).ToUpperInvariant()) 'Legacy durable report does not match its normalized evidence hash.'
    Assert-True ([string]$legacy.sourceRevision -eq '04d4c1584df4b0823e093422b98cf4c5575c7b19') 'Legacy evidence lost the exact failed candidate source revision.'
    Assert-True ([string]$legacy.artifact.sha256 -eq '76A86A77A3C7AE36306B203C7946B88C5D56E1F7B0689489DA7EAF6D8783C796') 'Legacy evidence lost the historical candidate artifact identity.'

    # Exact-payload evidence reconstructs the W14 recovery proof without the old
    # candidate ZIP. Exact Biology-owned bytes are removable; changed/foreign
    # content fails; generic/shared dependencies are inspect/preserve only.
    $sourceRevision = '1' * 40
    $fixtureFiles = Join-Path $temp 'fixture-files'
    New-Item -ItemType Directory -Force -Path $fixtureFiles | Out-Null
    $ownedInfo = Write-TestFile $fixtureFiles 'mods/Biology/info.json' '{"name":"Biology"}'
    $ownedProvenance = Write-TestFile $fixtureFiles 'biology/provenance.json' '{"product":"Biology"}'
    $sharedArtifact = Write-TestFile $fixtureFiles 'bin/x64/global.ini' 'artifact-shared'
    $receiptFixture = Write-TestFile $fixtureFiles 'biology/build-manifest.json' '{"fixture":"receipt"}'
    $manifestEntries = @(
        (New-ManifestEntry 'mods/Biology/info.json' $ownedInfo.sha256 'biology-owned' 'biology-redmod-identity'),
        (New-ManifestEntry 'biology/provenance.json' $ownedProvenance.sha256 'biology-owned' 'biology-package-metadata'),
        (New-ManifestEntry 'bin/x64/global.ini' $sharedArtifact.sha256 'generic-dependency-shared' 'cybercmd')
    )
    $exactEvidence = New-ExactEvidence $sourceRevision $manifestEntries $receiptFixture.sha256
    [void](Assert-BiologyOperatorEvidenceRecord $exactEvidence)

    $exactGame = Join-Path $temp 'exact-game'
    New-Item -ItemType Directory -Force -Path $exactGame | Out-Null
    Write-TestFile $exactGame 'mods/Biology/info.json' '{"name":"Biology"}' | Out-Null
    Write-TestFile $exactGame 'biology/provenance.json' '{"product":"Biology"}' | Out-Null
    Write-TestFile $exactGame 'biology/build-manifest.json' '{"fixture":"receipt"}' | Out-Null
    $liveShared = Write-TestFile $exactGame 'bin/x64/global.ini' 'different-live-shared'
    $exactPlan = New-BiologyEvidenceBackedFailedInstallRecoveryPlan -GameRoot $exactGame -Evidence $exactEvidence
    Assert-True (@($exactPlan.files | Where-Object action -eq 'remove-exact').Count -eq 3) 'Exact durable evidence did not plan the two owned files plus receipt for exact removal.'
    Assert-True (@($exactPlan.shared | Where-Object action -eq 'preserve-shared').Count -eq 1) 'Exact durable evidence did not preserve shared payload.'
    Invoke-BiologyFailedInstallRecoveryPlan -Plan $exactPlan
    Assert-True (-not (Test-Path -LiteralPath (Resolve-BiologyReleaseChild $exactGame 'mods/Biology'))) 'Exact evidence recovery left Biology REDmod-owned state.'
    Assert-True (-not (Test-Path -LiteralPath (Resolve-BiologyReleaseChild $exactGame 'biology'))) 'Exact evidence recovery left Biology metadata-owned state.'
    Assert-True ((Get-BiologyOperatorSha256 $liveShared.path) -eq $liveShared.sha256) 'Exact evidence recovery changed shared dependency state.'

    $changedGame = Join-Path $temp 'changed-game'
    New-Item -ItemType Directory -Force -Path $changedGame | Out-Null
    $changedOwned = Write-TestFile $changedGame 'mods/Biology/info.json' 'changed'
    $threw = $false
    try { New-BiologyEvidenceBackedFailedInstallRecoveryPlan -GameRoot $changedGame -Evidence $exactEvidence | Out-Null } catch { $threw=$true; Assert-True ($_.Exception.Message -match 'changed/ambiguous') 'Changed durable-evidence-owned content failed for an unexpected reason.' }
    Assert-True $threw 'Changed Biology-owned content did not fail exact evidence recovery planning.'
    Assert-True ((Get-BiologyOperatorSha256 $changedOwned.path) -eq $changedOwned.sha256) 'Changed Biology-owned content was mutated despite plan failure.'

    $foreignGame = Join-Path $temp 'foreign-game'
    New-Item -ItemType Directory -Force -Path $foreignGame | Out-Null
    Write-TestFile $foreignGame 'mods/Biology/info.json' '{"name":"Biology"}' | Out-Null
    $foreignFile = Write-TestFile $foreignGame 'mods/Biology/foreign.txt' 'foreign'
    $threw = $false
    try { New-BiologyEvidenceBackedFailedInstallRecoveryPlan -GameRoot $foreignGame -Evidence $exactEvidence | Out-Null } catch { $threw=$true; Assert-True ($_.Exception.Message -match 'foreign/unrecognized') 'Foreign durable-evidence-owned-root content failed for an unexpected reason.' }
    Assert-True $threw 'Foreign content inside a Biology-owned root did not fail exact evidence recovery planning.'
    Assert-True (Test-Path -LiteralPath $foreignFile.path -PathType Leaf) 'Foreign content was deleted despite exact recovery plan failure.'

    # The current legacy escape hatch never guesses old payload hashes. It may
    # remove only exact Biology-owned roots that are literally empty after a
    # known top-level package-file absence check.
    $legacyGame = Join-Path $temp 'legacy-game'
    New-Item -ItemType Directory -Force -Path (Resolve-BiologyReleaseChild $legacyGame 'mods/Biology') | Out-Null
    New-Item -ItemType Directory -Force -Path (Resolve-BiologyReleaseChild $legacyGame 'r6/scripts/CyberpunkRealism') | Out-Null
    New-Item -ItemType Directory -Force -Path (Resolve-BiologyReleaseChild $legacyGame 'biology') | Out-Null
    $legacyPlan = New-BiologyLegacyEmptyFailedInstallRecoveryPlan -GameRoot $legacyGame -Evidence $legacy
    Assert-True (@($legacyPlan.files).Count -eq 0 -and @($legacyPlan.shared).Count -eq 0) 'Legacy recovery unexpectedly authorized file deletion.'
    Assert-True (@($legacyPlan.directories).Count -eq 3) 'Legacy recovery did not identify the three empty owned roots.'
    Invoke-BiologyFailedInstallRecoveryPlan -Plan $legacyPlan
    foreach ($relative in @($legacy.recovery.ownedRoots)) { Assert-True (-not (Test-Path -LiteralPath (Resolve-BiologyReleaseChild $legacyGame ([string]$relative)))) "Legacy recovery left empty Biology-owned root: $relative" }

    $legacyAmbiguous = Join-Path $temp 'legacy-ambiguous'
    $ambiguous = Write-TestFile $legacyAmbiguous 'mods/Biology/unknown.txt' 'unknown'
    $threw=$false
    try { New-BiologyLegacyEmptyFailedInstallRecoveryPlan -GameRoot $legacyAmbiguous -Evidence $legacy | Out-Null } catch { $threw=$true; Assert-True ($_.Exception.Message -match 'non-empty') 'Legacy ambiguous root failed for an unexpected reason.' }
    Assert-True $threw 'Legacy recovery accepted a non-empty Biology-owned root without exact payload evidence.'
    Assert-True (Test-Path -LiteralPath $ambiguous.path -PathType Leaf) 'Legacy ambiguous content was deleted.'

    $legacyTopLevel = Join-Path $temp 'legacy-top-level'
    $blocked = Write-TestFile $legacyTopLevel 'BIOLOGY-VERSION.txt' 'ambiguous-old-package-file'
    $threw=$false
    try { New-BiologyLegacyEmptyFailedInstallRecoveryPlan -GameRoot $legacyTopLevel -Evidence $legacy | Out-Null } catch { $threw=$true; Assert-True ($_.Exception.Message -match 'ambiguous Biology-owned file') 'Legacy top-level ambiguity failed for an unexpected reason.' }
    Assert-True $threw 'Legacy recovery accepted a known package file without exact payload evidence.'
    Assert-True (Test-Path -LiteralPath $blocked.path -PathType Leaf) 'Legacy top-level ambiguous file was deleted.'

    # Parent ingestion is represented by durable evidence.json/report.txt. Local
    # cleanup requires one returned ZIP whose two text members still match the
    # repository copies after newline normalization.
    $durableRoot = Join-Path $temp 'durable-evidence'
    New-Item -ItemType Directory -Force -Path $durableRoot | Out-Null
    $durableReport = "fixture report`nsecond line`n"
    [IO.File]::WriteAllText((Join-Path $durableRoot 'report.txt'),$durableReport,[Text.UTF8Encoding]::new($false))
    $bundleRecord = New-ExactEvidence $sourceRevision $manifestEntries $receiptFixture.sha256 $false
    $bundleRecord.handoff.reportSha256 = Get-BiologyOperatorTextSha256 (Join-Path $durableRoot 'report.txt')
    $bundleRecord.cleanup.artifactRootName = $null
    $bundleRecord | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath (Join-Path $durableRoot 'evidence.json') -Encoding utf8
    $evidenceJson = Get-Content -Raw -LiteralPath (Join-Path $durableRoot 'evidence.json')
    $matchingBundle = Join-Path $temp 'matching-bundle.zip'
    Write-EvidenceBundle $matchingBundle $evidenceJson $durableReport
    $resolvedRecord = Test-BiologyOperatorEvidenceBundleAgainstRepository -BundlePath $matchingBundle -RepositoryEvidenceRoot $durableRoot
    Assert-True ([string]$resolvedRecord.evidenceId -eq 'fixture-exact-evidence') 'Matching handoff bundle did not resolve durable evidence.'

    $changedBundle = Join-Path $temp 'changed-bundle.zip'
    Write-EvidenceBundle $changedBundle $evidenceJson ($durableReport + "changed`n")
    $threw=$false
    try { Test-BiologyOperatorEvidenceBundleAgainstRepository -BundlePath $changedBundle -RepositoryEvidenceRoot $durableRoot | Out-Null } catch { $threw=$true; Assert-True ($_.Exception.Message -match 'does not exactly match') 'Changed handoff bundle failed for an unexpected reason.' }
    Assert-True $threw 'Changed local handoff report matched durable repository evidence.'

    # Managed candidate artifact cleanup is hash/inventory bounded. Exact known
    # content is removed; one foreign file prevents any recursive deletion.
    function New-CleanupFixture([string]$GamesRoot,[string]$RootName) {
        $artifactRoot = Join-Path $GamesRoot $RootName
        $packageRootName = 'fixture-root'
        $packageRoot = Join-Path $artifactRoot $packageRootName
        New-Item -ItemType Directory -Force -Path $packageRoot | Out-Null
        foreach ($entry in @($manifestEntries)) {
            $text = switch ([string]$entry.path) {
                'mods/Biology/info.json' { '{"name":"Biology"}' }
                'biology/provenance.json' { '{"product":"Biology"}' }
                'bin/x64/global.ini' { 'artifact-shared' }
                default { throw "Unknown cleanup fixture path: $($entry.path)" }
            }
            Write-TestFile $packageRoot ([string]$entry.path) $text | Out-Null
        }
        Write-TestFile $packageRoot 'biology/build-manifest.json' '{"fixture":"receipt"}' | Out-Null
        $zipPath = Join-Path $artifactRoot 'fixture.zip'
        [IO.File]::WriteAllBytes($zipPath,[byte[]](1,2,3,4))
        return [pscustomobject]@{ root=$artifactRoot; zip=$zipPath; packageRootName=$packageRootName }
    }

    $cleanupGames = Join-Path $temp 'cleanup-games'
    New-Item -ItemType Directory -Force -Path $cleanupGames | Out-Null
    $cleanupRootName = 'Biology-Candidate-Artifacts-fixture'
    $cleanupFixture = New-CleanupFixture $cleanupGames $cleanupRootName
    $cleanupEvidence = New-ExactEvidence $sourceRevision $manifestEntries $receiptFixture.sha256 $false
    $cleanupEvidence.artifact.sha256 = Get-BiologyOperatorSha256 $cleanupFixture.zip
    $cleanupEvidence.artifact.bytes = (Get-Item -LiteralPath $cleanupFixture.zip).Length
    $cleanupEvidence.cleanup.artifactRootName = $cleanupRootName
    $cleanupEvidence.cleanup.artifactZipName = 'fixture.zip'
    $cleanupEvidence.cleanup.packageRootName = $cleanupFixture.packageRootName
    Assert-True (Remove-BiologyManagedArtifactRoot -GamesRoot $cleanupGames -Evidence $cleanupEvidence) 'Exact managed artifact root was not removed.'
    Assert-True (-not (Test-Path -LiteralPath $cleanupFixture.root)) 'Managed artifact root remains after exact cleanup.'

    $foreignCleanupName = 'Biology-Candidate-Artifacts-foreign-fixture'
    $foreignCleanup = New-CleanupFixture $cleanupGames $foreignCleanupName
    $foreignCleanupEvidence = New-ExactEvidence $sourceRevision $manifestEntries $receiptFixture.sha256 $false
    $foreignCleanupEvidence.artifact.sha256 = Get-BiologyOperatorSha256 $foreignCleanup.zip
    $foreignCleanupEvidence.artifact.bytes = (Get-Item -LiteralPath $foreignCleanup.zip).Length
    $foreignCleanupEvidence.cleanup.artifactRootName = $foreignCleanupName
    $foreignCleanupEvidence.cleanup.artifactZipName = 'fixture.zip'
    $foreignCleanupEvidence.cleanup.packageRootName = $foreignCleanup.packageRootName
    Write-TestFile $foreignCleanup.root 'foreign.txt' 'do-not-delete' | Out-Null
    $threw=$false
    try { Remove-BiologyManagedArtifactRoot -GamesRoot $cleanupGames -Evidence $foreignCleanupEvidence | Out-Null } catch { $threw=$true; Assert-True ($_.Exception.Message -match 'foreign file') 'Foreign managed artifact content failed for an unexpected reason.' }
    Assert-True $threw 'Managed artifact cleanup accepted foreign content.'
    Assert-True (Test-Path -LiteralPath $foreignCleanup.root -PathType Container) 'Managed artifact cleanup deleted a root containing foreign content.'

    # Zero-local-repo and no-launch contracts are visible in each operator
    # bootstrap. Recovery never deploys REDmod; cleanup never targets the game.
    foreach ($relative in @(
        'tools/Bootstrap-BiologyManagedPostTransitionCandidate.ps1',
        'tools/Bootstrap-BiologyManagedFailedInstallRecovery.ps1',
        'tools/Bootstrap-BiologyOperatorEvidenceCleanup.ps1'
    )) {
        $text = Get-Content -Raw -LiteralPath (Join-Path $root $relative)
        foreach ($required in @('git','clone','--no-checkout','fetch','origin','cat-file')) { Assert-True ($text -match [regex]::Escape($required)) "$relative is missing zero-local-repo exact-source contract text: $required" }
        Assert-True ($text -notmatch '(?i)Start-Process[^\r\n]*Cyberpunk') "$relative must never launch Cyberpunk."
    }
    $managedRecovery = Get-Content -Raw -LiteralPath (Join-Path $root 'tools\Bootstrap-BiologyManagedFailedInstallRecovery.ps1')
    Assert-True ($managedRecovery -notmatch 'Deploy-BiologyRedmod\.ps1') 'Managed failed-install recovery must not deploy REDmod.'
    Assert-True ($managedRecovery -match 'PLAN STATUS: SAFE-TO-APPLY') 'Managed failed-install recovery lost its complete read/plan-first gate.'
    $cleanupBootstrap = Get-Content -Raw -LiteralPath (Join-Path $root 'tools\Bootstrap-BiologyOperatorEvidenceCleanup.ps1')
    Assert-True ($cleanupBootstrap -match 'Test-BiologyOperatorEvidenceBundleAgainstRepository') 'Cleanup does not require durable repository evidence match before deletion.'
    Assert-True ($cleanupBootstrap -match 'Remove-BiologyManagedArtifactRoot') 'Cleanup does not use the hash/inventory-bounded artifact-root remover.'

    Write-Host 'PASS: managed operator evidence is repo-backed and schema/hash validated; exact failed-install recovery no longer requires the old ZIP; the legacy current state is empty-root-only; shared dependencies stay preserved; and local cleanup is durable-evidence + exact-inventory bounded.'
} finally {
    if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Recurse -Force }
}
