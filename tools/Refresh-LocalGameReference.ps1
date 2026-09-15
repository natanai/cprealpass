[CmdletBinding()]
param(
    [string]$RepoRoot = "C:\Games\CyberpunkRealism",
    [string]$GamePath = "C:\Games\Steam\steamapps\common\Cyberpunk 2077"
)

$ErrorActionPreference = "Stop"

function Write-CsvOrHeader {
    param(
        [Parameter(Mandatory = $true)] $Rows,
        [Parameter(Mandatory = $true)] [string] $Path,
        [Parameter(Mandatory = $true)] [string[]] $Columns
    )

    $items = @($Rows)
    if ($items.Count -gt 0) {
        $items | Select-Object $Columns | Export-Csv -Path $Path -NoTypeInformation -Encoding UTF8
    }
    else {
        $header = ($Columns | ForEach-Object { '"' + ($_ -replace '"', '""') + '"' }) -join ','
        Set-Content -Path $Path -Value $header -Encoding UTF8
    }
}

$RepoRoot = [IO.Path]::GetFullPath($RepoRoot)
$GamePath = [IO.Path]::GetFullPath($GamePath)
$ExePath = Join-Path $GamePath "bin\x64\Cyberpunk2077.exe"

if (-not (Test-Path (Join-Path $RepoRoot ".git"))) {
    throw "RealPass Git repository not found at: $RepoRoot"
}

if (-not (Test-Path $ExePath)) {
    throw "Cyberpunk 2077 executable not found at: $ExePath"
}

$Out = Join-Path $RepoRoot "reference\cyberpunk"
New-Item -ItemType Directory -Force -Path $Out | Out-Null

Write-Host "" 
Write-Host "Refreshing GitHub-safe Cyberpunk reference..." -ForegroundColor Cyan
Write-Host "Game access is read-only. This tool writes only under reference\cyberpunk." -ForegroundColor DarkGray

$Exe = Get-Item $ExePath
$AllFiles = @(Get-ChildItem -LiteralPath $GamePath -File -Recurse -ErrorAction SilentlyContinue)

$RelativeFiles = @(
    $AllFiles | ForEach-Object {
        [PSCustomObject]@{
            Path      = $_.FullName.Substring($GamePath.Length).TrimStart("\")
            Extension = $_.Extension
            SizeBytes = $_.Length
        }
    } | Sort-Object Path
)

$ArchiveContainers = @(
    $RelativeFiles |
        Where-Object Extension -eq ".archive" |
        Select-Object Path, SizeBytes
)

$Environment = [ordered]@{
    generatedUtc = (Get-Date).ToUniversalTime().ToString("o")
    game = [ordered]@{
        name = "Cyberpunk 2077"
        version = $Exe.VersionInfo.ProductVersion
        executableVersion = $Exe.VersionInfo.FileVersion
    }
    counts = [ordered]@{
        files = $RelativeFiles.Count
        archives = $ArchiveContainers.Count
        redscriptFiles = @($RelativeFiles | Where-Object Extension -eq ".reds").Count
        tweakFiles = @($RelativeFiles | Where-Object Extension -in @(".yaml", ".yml")).Count
    }
    note = "Generated from the local supported installation. Absolute machine paths intentionally omitted."
}

$Environment |
    ConvertTo-Json -Depth 8 |
    Set-Content -Path (Join-Path $Out "environment.json") -Encoding UTF8

Write-CsvOrHeader -Rows $RelativeFiles -Path (Join-Path $Out "filesystem-index.csv") -Columns @("Path", "Extension", "SizeBytes")
Write-CsvOrHeader -Rows $ArchiveContainers -Path (Join-Path $Out "archives.csv") -Columns @("Path", "SizeBytes")

$PluginRoot = Join-Path $GamePath "red4ext\plugins"
$Plugins = @()
if (Test-Path $PluginRoot) {
    $Plugins = @(
        Get-ChildItem $PluginRoot -Directory -ErrorAction SilentlyContinue |
            Sort-Object Name |
            ForEach-Object {
                $PluginDir = $_
                $Dlls = @(
                    Get-ChildItem $PluginDir.FullName -Filter "*.dll" -Recurse -File -ErrorAction SilentlyContinue |
                        Sort-Object FullName |
                        ForEach-Object {
                            [ordered]@{
                                File = $_.Name
                                FileVersion = $_.VersionInfo.FileVersion
                                ProductVersion = $_.VersionInfo.ProductVersion
                            }
                        }
                )

                [ordered]@{
                    Name = $PluginDir.Name
                    DLLs = $Dlls
                }
            }
    )
}

$Plugins |
    ConvertTo-Json -Depth 8 |
    Set-Content -Path (Join-Path $Out "red4ext-plugins.json") -Encoding UTF8

$PluginNames = @($Plugins | ForEach-Object { $_.Name })
$Frameworks = [ordered]@{
    RED4ext = Test-Path (Join-Path $GamePath "red4ext")
    CyberEngineTweaks = Test-Path (Join-Path $GamePath "bin\x64\plugins\cyber_engine_tweaks")
    Redscript = Test-Path (Join-Path $GamePath "r6\scripts")
    ArchiveXL = [bool]($PluginNames -match "^ArchiveXL$")
    TweakXL = [bool]($PluginNames -match "^TweakXL$")
    Codeware = [bool]($PluginNames -match "^Codeware$")
}

$Frameworks |
    ConvertTo-Json -Depth 5 |
    Set-Content -Path (Join-Path $Out "frameworks.json") -Encoding UTF8

$ScriptRoot = Join-Path $GamePath "r6\scripts"
$Scripts = @()
if (Test-Path $ScriptRoot) {
    $Scripts = @(
        Get-ChildItem $ScriptRoot -File -Recurse -ErrorAction SilentlyContinue |
            ForEach-Object {
                [PSCustomObject]@{
                    Path = $_.FullName.Substring($ScriptRoot.Length).TrimStart("\")
                    Extension = $_.Extension
                    SizeBytes = $_.Length
                }
            } |
            Sort-Object Path
    )
}
Write-CsvOrHeader -Rows $Scripts -Path (Join-Path $Out "installed-scripts.csv") -Columns @("Path", "Extension", "SizeBytes")

$ArchivePayloadRoot = Join-Path $GamePath "archive\pc\mod"
$ArchivePayloads = @()
if (Test-Path $ArchivePayloadRoot) {
    $ArchivePayloads = @(
        Get-ChildItem $ArchivePayloadRoot -File -ErrorAction SilentlyContinue |
            ForEach-Object {
                [PSCustomObject]@{
                    File = $_.Name
                    Extension = $_.Extension
                    SizeBytes = $_.Length
                }
            } |
            Sort-Object File
    )
}
Write-CsvOrHeader -Rows $ArchivePayloads -Path (Join-Path $Out "archive-payloads.csv") -Columns @("File", "Extension", "SizeBytes")

Write-Host "" 
Write-Host "Reference refreshed." -ForegroundColor Green
Write-Host "Cyberpunk version : $($Exe.VersionInfo.ProductVersion)"
Write-Host "Indexed files      : $($RelativeFiles.Count)"
Write-Host "Archive containers : $($ArchiveContainers.Count)"
Write-Host "Archive payloads   : $($ArchivePayloads.Count)"
Write-Host "" 
Write-Host "No game files were modified." -ForegroundColor Green
Write-Host "Generated metadata is in: $Out" -ForegroundColor Cyan
Write-Host "" 
Write-Host "Git changes:" -ForegroundColor Cyan
Push-Location $RepoRoot
try {
    git status --short -- reference/cyberpunk
}
finally {
    Pop-Location
}
