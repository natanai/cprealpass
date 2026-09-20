$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\tools\Common.ps1"
$project = Get-ProjectRoot
$sourcePath = Join-Path $project 'src/redscript/CyberpunkRealism/E3NameplatesNative.reds'
$identityPath = Join-Path $project 'src/redscript/CyberpunkRealism/NameplatesNative.reds'
$mappingPath = Join-Path $project 'docs/E3-COMPONENT-MAPPING.md'
$presentationPath = Join-Path $project 'docs/E3-PRESENTATION.md'
foreach ($path in @($sourcePath,$identityPath,$mappingPath,$presentationPath)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Missing W20.1 contract file: $path" }
}

$source = Get-Content -Raw -LiteralPath $sourcePath
$identity = Get-Content -Raw -LiteralPath $identityPath
$mapping = Get-Content -Raw -LiteralPath $mappingPath
$presentation = Get-Content -Raw -LiteralPath $presentationPath
$script:checks = 0
function Check($condition,[string]$message) {
    if (-not $condition) { throw $message }
    $script:checks++
}

# T005-F02: authored native name/frame geometry is structural authority.
Check (-not $source.Contains('CRBiologyE3IdentityChrome')) 'Detached Biology identity canvas returned.'
Check (-not $source.Contains('Vector2(340.0, 46.0)')) 'Fixed 340x46 nameplate geometry returned.'
Check (-not $source.Contains('new inkCanvas()')) 'Nameplate adapter creates parallel runtime canvas geometry.'
Check ($source.Contains('this.m_nameTextMain') -and $source.Contains('this.m_nameFrame')) 'Native authored name/frame widgets are no longer the presentation surface.'
Check ($source.Contains('crBiologyE3NativeNameTint') -and $source.Contains('crBiologyE3NativeFrameTint') -and $source.Contains('crBiologyE3NativeFrameOpacity') -and $source.Contains('crBiologyE3NativeFrameVisible')) 'E3 OFF cannot restore captured native name/frame style.'

# T005-F03: Biology fallback never becomes native/scanner identity input.
Check (-not $source.Contains('data.name = ambientName')) 'Biology ambient fallback is still written into native identity data.'
Check ($source.Contains('wrappedMethod(puppet, data, isNewNpc)')) 'W20.1 lost the exact-compiled SetVisualData wrapper call shape.'
Check ($identity.Contains('return data.name;')) 'Native NPCNextToTheCrosshair identity no longer wins in the ambient resolver.'
Check ($identity.Contains('return puppet.GetDisplayName();')) 'Public ambient fallback was lost for legitimate empty-name civilians/combatants.'
Check ($identity.Contains('presentation-only') -and $identity.Contains('must never be written back')) 'Identity helper does not document the one-way authority boundary.'

# Native visibility runs first; Biology presentation refresh runs afterwards.
$nativeVisibility = $source.IndexOf('wrappedMethod(incomingData);')
$presentationRefresh = $source.IndexOf('this.CRRefreshBiologyE3Nameplate(this.crBiologyE3LastPuppet, this.crBiologyE3LastData);')
Check ($nativeVisibility -ge 0 -and $presentationRefresh -gt $nativeVisibility) 'Biology ambient rendering no longer runs after native visibility handling.'
Check ($source.Contains('public final func IsAnyElementVisible() -> Bool') -and $source.Contains('CRBiologyE3ShouldShowAmbientName')) 'Ambient fallback no longer participates in the native projected-root visibility gate.'
Check ($source.Contains('this.c_DisplayRangeNotAggressive = 10.0') -and $source.Contains('this.c_MaxDisplayRangeNotAggressive = 20.0')) 'Known-good ambient display range was lost.'
Check ($source.Contains('SNameplateRangesData.GetDisplayRangeNotAggressive()') -and $source.Contains('SNameplateRangesData.GetMaxDisplayRangeNotAggressive()')) 'E3 OFF cannot restore native display range.'

# T007: scanner/native detailed identity owns scanner context. Biology may not leave an
# ambient projected fallback visible beside the native detailed scanner panel.
Check ($source.Contains('public let crBiologyE3ScannerActive: Bool;')) 'Nameplate visuals do not track native scanner ownership.'
Check ($source.Contains('this.m_isScanning') -and $source.Contains('CRSyncBiologyE3IdentityOwner')) 'NpcNameplate controller does not synchronize Biology ambient ownership to native scanning state.'
Check ($source.Contains('inkWidgetRef.SetVisible(this.m_displayName, false);')) 'Scanner entry does not suppress the conflicting ambient projected name surface.'
Check ($identity.Contains('this.crBiologyE3ScannerActive')) 'Public ambient fallback is still allowed during scanner ownership.'
Check ($identity.Contains('this.m_forceHide') -and $identity.Contains('this.m_npcNamesEnabled')) 'Ambient fallback ignores native force-hide/name-enable policy.'
Check ($source.Contains('CRRestoreBiologyE3NameplateStyle')) 'Nameplate styling has no explicit per-cycle native restoration helper.'
Check ($source.Contains('this.crBiologyE3HasNativeNameTint = false;') -and $source.Contains('this.crBiologyE3HasNativeFrameStyle = false;')) 'Nameplate native-style capture survives across cycles and can restore stale state.'
Check (-not $source.Contains('SetLetterCase(') -and -not $source.Contains('SetFontStyle(')) 'Nameplate mutates text style that has no reversible native capture path.'
Check ($source.Contains('this.SetVisualData(this.crBiologyE3LastPuppet, this.crBiologyE3LastData);')) 'Scanner/preference ownership change does not re-run native identity from unchanged native data.'
Check (-not $source.Contains('data.name =')) 'Biology writes presentation fallback into native identity data.'

# Scanner/quickhack remains native/current.
foreach ($forbidden in @('ScannerGameController','ScannerDetailsGameController','ScannerNPCHeaderGameController','quickhackWidgetGameController','QuickHackGameController','scanner.inkwidget','scanner_hud.inkwidget')) {
    Check (-not $source.Contains($forbidden)) "W20.1 crossed the modern scanner/quickhack boundary: $forbidden"
}

Check ($mapping.Contains('W20.1 — T005 nameplate structure and identity-authority correction')) 'Durable component mapping lacks W20.1 authority correction.'
Check ($presentation.Contains('W20.1 — T005 authored nameplate and one-way identity authority')) 'Canonical E3 presentation contract lacks W20.1 correction.'
Check ($mapping.Contains('discovered identity -> unmodified native values') -and $mapping.Contains('presentation fallback only')) 'Mapping does not preserve one-way native identity authority.'
Check ($presentation.Contains('Biology generic ambient fallback -> native SetVisualData / scanner knowledge')) 'Presentation contract does not explicitly forbid backward fallback flow.'

Write-Host "PASS: $script:checks W20.1 nameplate checks; native identity input is untouched, public fallback is presentation-only, authored native name/frame geometry owns structure, scanner remains native, and E3 OFF restoration is preserved."
