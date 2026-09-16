$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = Split-Path -Parent $PSScriptRoot
$bootstrapPath = Join-Path $root 'tools\Bootstrap-BiologyFailedInstallRecovery.ps1'

function Assert-True([bool]$Value,[string]$Message) {
    if (-not $Value) { throw $Message }
}

function New-ZipFixture([string]$Path,[object[]]$Entries) {
    Add-Type -AssemblyName System.IO.Compression
    Add-Type -AssemblyName System.IO.Compression.FileSystem

    $stream = [IO.File]::Open($Path,[IO.FileMode]::Create,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
    $archive = [IO.Compression.ZipArchive]::new($stream,[IO.Compression.ZipArchiveMode]::Create,$false)
    try {
        foreach ($item in @($Entries)) {
            $entry = $archive.CreateEntry([string]$item.name)
            if (-not [bool]$item.directory) {
                $entryStream = $entry.Open()
                try {
                    $bytes = [Text.UTF8Encoding]::new($false).GetBytes([string]$item.content)
                    $entryStream.Write($bytes,0,$bytes.Length)
                } finally {
                    $entryStream.Dispose()
                }
            }
        }
    } finally {
        $archive.Dispose()
        $stream.Dispose()
    }
}

function Assert-ZipRejected([string]$Base,[string]$Name,[string]$Entry,[string]$ExpectedPattern) {
    $path = Join-Path $Base ($Name + '.zip')
    New-ZipFixture $path @([pscustomobject]@{ name=$Entry; directory=$Entry.EndsWith('/'); content='unsafe' })
    $threw = $false
    try {
        Assert-SafeArtifactZip $path
    } catch {
        $threw = $true
        Assert-True ($_.Exception.Message -match $ExpectedPattern) "Unsafe ZIP '$Entry' failed for an unexpected reason: $($_.Exception.Message)"
    }
    Assert-True $threw "Unsafe ZIP entry was accepted: $Entry"
}

# Load only the exact validator function from the bootstrap AST. Dot-sourcing the
# bootstrap would execute the recovery operation, which is intentionally not a
# cloud-test action.
$tokens = $null
$parseErrors = $null
$ast = [Management.Automation.Language.Parser]::ParseFile($bootstrapPath,[ref]$tokens,[ref]$parseErrors)
Assert-True (@($parseErrors).Count -eq 0) ('Recovery bootstrap failed to parse: ' + ((@($parseErrors) | ForEach-Object Message) -join '; '))
$validatorAst = $ast.Find({
    param($node)
    $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'Assert-SafeArtifactZip'
},$true)
Assert-True ($null -ne $validatorAst) 'Could not find Assert-SafeArtifactZip in the recovery bootstrap.'
Invoke-Expression $validatorAst.Extent.Text

$temp = Join-Path ([IO.Path]::GetTempPath()) ('biology-recovery-zip-safety-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $temp | Out-Null
try {
    # Reproduce the attended W15 failure shape with a real explicit ZIP directory
    # entry. The pre-W15 split produced a terminal empty segment for this entry.
    $repro = Join-Path $temp 'directory-repro.zip'
    New-ZipFixture $repro @(
        [pscustomobject]@{ name='engine/config/'; directory=$true; content='' },
        [pscustomobject]@{ name='engine/config/base.ini'; directory=$false; content='fixture' }
    )
    $reproArchive = [IO.Compression.ZipFile]::OpenRead($repro)
    try {
        $directoryEntry = @($reproArchive.Entries | Where-Object FullName -eq 'engine/config/')[0]
        $legacyParts = @($directoryEntry.FullName.Replace('\','/').TrimStart('/') -split '/')
        Assert-True ($legacyParts.Count -eq 3 -and $legacyParts[2] -eq '') 'Directory-entry fixture did not reproduce the terminal empty segment that triggered W15.'
    } finally {
        $reproArchive.Dispose()
    }
    Assert-SafeArtifactZip $repro

    # Release-shaped fixture: explicit ordinary and nested directory entries plus
    # representative payload files must all pass validation.
    $release = Join-Path $temp 'release-shaped.zip'
    New-ZipFixture $release @(
        [pscustomobject]@{ name='engine/'; directory=$true; content='' },
        [pscustomobject]@{ name='engine/config/'; directory=$true; content='' },
        [pscustomobject]@{ name='engine/config/base/'; directory=$true; content='' },
        [pscustomobject]@{ name='engine/config/base/biology.ini'; directory=$false; content='fixture' },
        [pscustomobject]@{ name='mods/'; directory=$true; content='' },
        [pscustomobject]@{ name='mods/Biology/'; directory=$true; content='' },
        [pscustomobject]@{ name='mods/Biology/info.json'; directory=$false; content='{}' },
        [pscustomobject]@{ name='biology/'; directory=$true; content='' },
        [pscustomobject]@{ name='biology/build-manifest.json'; directory=$false; content='{}' }
    )
    Assert-SafeArtifactZip $release

    # Ordinary safe file entries remain accepted.
    $safeFile = Join-Path $temp 'safe-file.zip'
    New-ZipFixture $safeFile @([pscustomobject]@{ name='mods/Biology/archive/pc/mod/Biology.archive'; directory=$false; content='fixture' })
    Assert-SafeArtifactZip $safeFile

    # Traversal, rooted/drive-qualified paths, dot segments, doubled separators,
    # illegal/trailing characters, and Windows device names remain fail-closed.
    Assert-ZipRejected $temp 'parent-traversal' '../escape.txt' 'path segment'
    Assert-ZipRejected $temp 'nested-parent-traversal' 'safe/../escape.txt' 'path segment'
    Assert-ZipRejected $temp 'dot-segment' 'safe/./file.txt' 'path segment'
    Assert-ZipRejected $temp 'rooted' '/rooted.txt' 'rooted artifact entry'
    Assert-ZipRejected $temp 'drive-qualified' 'C:/drive.txt' 'rooted artifact entry'
    Assert-ZipRejected $temp 'alternate-stream' 'safe/name:stream.txt' 'rooted artifact entry'
    Assert-ZipRejected $temp 'double-separator' 'safe//file.txt' 'path segment'
    Assert-ZipRejected $temp 'double-directory-terminator' 'safe// ' 'path segment'
    Assert-ZipRejected $temp 'illegal-character' 'safe/bad?.txt' 'path segment'
    Assert-ZipRejected $temp 'trailing-dot' 'safe/trailing.' 'path segment'
    Assert-ZipRejected $temp 'trailing-space' 'safe/trailing ' 'path segment'
    Assert-ZipRejected $temp 'reserved-con' 'CON' 'path segment'
    Assert-ZipRejected $temp 'reserved-nul-extension' 'safe/NUL.txt' 'path segment'
    Assert-ZipRejected $temp 'reserved-com' 'safe/COM1.log' 'path segment'

    # The exact failed-report/artifact binding still happens before ZIP safety,
    # and repository acquisition still happens only after the ZIP passes. This
    # preserves the zero-local-repo/read-first boundary while testing the actual
    # validator independently above.
    $bootstrap = Get-Content -Raw -LiteralPath $bootstrapPath
    $reportHashCheck = $bootstrap.IndexOf('if ($reportHash -ne $ExpectedFailedCandidateReportSha256)',[StringComparison]::Ordinal)
    $reportedArtifactCheck = $bootstrap.IndexOf("throw 'Failed report artifact SHA-256 does not match the parent-supplied retained artifact identity.'",[StringComparison]::Ordinal)
    $artifactHashCheck = $bootstrap.IndexOf('if ($artifactHash -ne $ExpectedArtifactSha256)',[StringComparison]::Ordinal)
    $validatorCall = $bootstrap.IndexOf('Assert-SafeArtifactZip $ArtifactZipPath',[StringComparison]::Ordinal)
    $seedLookup = $bootstrap.IndexOf('$seedRepo = Find-Seed',[StringComparison]::Ordinal)
    Assert-True ($reportHashCheck -ge 0 -and $reportedArtifactCheck -gt $reportHashCheck -and $artifactHashCheck -gt $reportedArtifactCheck -and $validatorCall -gt $artifactHashCheck -and $seedLookup -gt $validatorCall) 'Recovery bootstrap no longer preserves exact report/artifact binding before ZIP validation and source acquisition afterward.'
    Assert-True ($bootstrap -match 'No usable local cprealpass checkout found\. Creating signed seed clone') 'Recovery bootstrap lost zero-local-repo acquisition support.'
    Assert-True ($bootstrap -match 'PLAN STATUS: SAFE-TO-APPLY') 'Recovery bootstrap lost its complete read/plan-before-mutation gate.'

    $recoveryCore = Get-Content -Raw -LiteralPath (Join-Path $root 'tools\BiologyFailedInstallRecovery.Core.ps1')
    Assert-True ($recoveryCore -match 'preserve-shared') 'Recovery core no longer marks shared dependencies preserve-shared.'
    Assert-True ($recoveryCore -notmatch 'Remove-Item[^\r\n]*Plan\.shared') 'Recovery core must not delete shared dependency plan entries.'

    Write-Host 'PASS: W15 failed-install recovery accepts ordinary explicit ZIP directory entries while traversal/root/drive/dot/unsafe/reserved paths stay fail-closed, and exact evidence binding/read-plan-first/shared-preservation/zero-local-repo contracts remain intact.'
} finally {
    if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Recurse -Force }
}
