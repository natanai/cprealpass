$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\tools\Common.ps1"
$project = Get-ProjectRoot
$sourceRoot = Join-Path $project 'src/redscript/CyberpunkRealism'
$hudPath = Join-Path $sourceRoot 'E3FirstPersonHud.reds'
$nameplatePath = Join-Path $sourceRoot 'E3NameplatesNative.reds'
$identityPath = Join-Path $sourceRoot 'NameplatesNative.reds'
$healthPath = Join-Path $sourceRoot 'NoHealthbars.reds'
$settingsPath = Join-Path $sourceRoot 'RealpassSettings.reds'
$seams = Get-Content -Raw -LiteralPath (Join-Path $project 'manifest/native-seams.json') | ConvertFrom-Json
$contract = Get-Content -Raw -LiteralPath (Join-Path $project 'manifest/settings.json') | ConvertFrom-Json
$script:checks = 0
function Check($condition,[string]$message) { if (-not $condition) { throw $message }; $script:checks++ }

foreach ($path in @($hudPath,$nameplatePath,$identityPath,$healthPath,$settingsPath)) {
    Check (Test-Path -LiteralPath $path -PathType Leaf) "Missing presentation source: $path"
}
$hud = Get-Content -Raw -LiteralPath $hudPath
$nameplate = Get-Content -Raw -LiteralPath $nameplatePath
$identity = Get-Content -Raw -LiteralPath $identityPath
$health = Get-Content -Raw -LiteralPath $healthPath
$settings = Get-Content -Raw -LiteralPath $settingsPath

# First-person E3 slice: a Biology-owned red visual language attached to a verified
# native HUD host. It is not a health meter and it has an explicit visible-off path.
Check ($hud.Contains('@addField(healthbarWidgetGameController)')) 'E3 HUD does not own a controller-local widget root.'
Check ($hud.Contains('@wrapMethod(healthbarWidgetGameController)')) 'E3 HUD is not attached to the verified first-person HUD host.'
Check ($hud.Contains('CRBiologyE3HudFrame')) 'E3 HUD root is missing Biology ownership naming.'
Check ($hud.Contains('CRBiologyE3HudTopRail') -and $hud.Contains('CRBiologyE3HudLeftRail') -and $hud.Contains('CRBiologyE3HudLowerRail')) 'E3 HUD lacks the asymmetric rail/bracket treatment.'
Check ($hud.Contains('label.SetText("BIOLOGY")')) 'E3 HUD lacks an unmistakable Biology visual identifier.'
Check ($hud.Contains('new HDRColor(1.1761, 0.1400, 0.1200, 1.0)')) 'E3 HUD does not establish the intended red presentation language.'
Check ($hud.Contains('CRRealpassSettings.UseE3FirstPersonHudVisuals(GetGameInstance())')) 'E3 HUD is not gated by the presentation preference.'
Check ($hud.Contains('crBiologyE3HudFrame.SetVisible(')) 'E3 HUD has no explicit ON/OFF visual yield path.'
foreach ($forbidden in @('m_healthBar','m_healthTextPath','m_maxHealthTextPath','StatPoolType.Health','GetStatPoolValue','SetStatPoolValue','ApplyDamage','ProcessLocalizedDamage')) {
    Check (-not $hud.Contains($forbidden)) "E3 HUD incorrectly became a health-state surface: $forbidden"
}

# NPC E3 slice: visual decoration is separate from identity enrichment and from the
# Biology-wide healthbar suppression seam.
Check ($nameplate.Contains('@addField(NameplateVisualsLogicController)')) 'E3 nameplate does not own a controller-local widget root.'
Check ($nameplate.Contains('@wrapMethod(NameplateVisualsLogicController)')) 'E3 nameplate is not attached to the verified native nameplate seam.'
Check ($nameplate.Contains('public final func SetVisualData(puppet: ref<GameObject>, const incomingData: script_ref<NPCNextToTheCrosshair>, opt isNewNpc: Bool) -> Void')) 'E3 nameplate hook signature drifted from the verified 2.31 seam.'
Check ($nameplate.Contains('CRBiologyE3NameplateFrame')) 'E3 nameplate root is missing Biology ownership naming.'
Check ($nameplate.Contains('CRBiologyE3NameplateTop') -and $nameplate.Contains('CRBiologyE3NameplateLeft') -and $nameplate.Contains('CRBiologyE3NameplateBottom')) 'E3 nameplate lacks the matching rail/bracket treatment.'
Check ($nameplate.Contains('label.SetText("BIO // ID")')) 'E3 nameplate lacks its Biology-owned identifier detail.'
Check ($nameplate.Contains('new HDRColor(1.1761, 0.1400, 0.1200, 1.0)')) 'E3 nameplate does not use the matching red visual language.'
Check ($nameplate.Contains('CRRealpassSettings.UseE3FirstPersonHudVisuals(puppet.GetGame())')) 'E3 nameplate is not gated by the presentation preference.'
Check ($nameplate.Contains('crBiologyE3NameplateFrame.SetVisible(visible)')) 'E3 nameplate has no explicit ON/OFF visual yield path.'
foreach ($forbidden in @('m_nameTextMain','m_nameFrame','m_nameBG','m_healthbarWidget','m_damagePreviewWidget','currentHealth','maximumHealth','StatPoolType.Health')) {
    Check (-not $nameplate.Contains($forbidden)) "E3 nameplate reaches into source-mod/native health internals: $forbidden"
}
Check (-not $identity.Contains('SetTintColor(')) 'Identity-enrichment seam absorbed visual styling instead of remaining data-only.'

# Modern scanner / quickhack is an exclusion boundary. The owned E3 layer must never
# hook, replace, or reference the scanner resource/controller paths used by the old
# Project E3 scanner.
$combined = $hud + "`n" + $nameplate
foreach ($forbidden in @('ScannerGameController','scannerGameController','ScannerDetailsGameController','ScannerNPCHeaderGameController','quickhackWidgetGameController','QuickHackGameController','scanner.inkwidget','scanner_details.inkwidget','scanner_hud.inkwidget','base\\gameplay\\gui\\widgets\\scanner')) {
    Check (-not $combined.Contains($forbidden)) "Owned E3 presentation crossed the native scanner/quickhack boundary: $forbidden"
}
foreach ($forbidden in @('module ProjectE3','import ProjectE3','patches/project-e3-hud','DarkFuture.','import DarkFuture')) {
    Check (-not $combined.Contains($forbidden)) "Owned E3 presentation gained a source-mod runtime dependency: $forbidden"
}
Check (-not $combined.Contains('ResRef.FromString')) 'Owned E3 presentation depends on an external UI asset resource instead of project-owned INK widgets.'

# Semantic separation: E3 OFF yields only the E3-specific visuals. Biology-wide
# barless health remains master-gated, and native scanner remains release policy.
Check (-not $health.Contains('UseE3FirstPersonHudVisuals')) 'Healthbar suppression is incorrectly controlled by the E3 preference.'
Check ($health.Contains('CRRealpassSettings.IsEnabled(GetGameInstance())')) 'Healthbar suppression lost its Biology-wide master gate.'
Check ($contract.releaseProfile.traditionalActorHealthBarsFinalTarget -eq $false) 'Contract reintroduced traditional actor health bars as an E3 toggle behavior.'
Check ($contract.releaseProfile.nativeModernScanner -eq $true) 'Contract no longer protects the modern native scanner.'
Check ($contract.publicControls[1].authority -eq 'presentation-only') 'E3 preference no longer has presentation-only authority.'
Check ($settings.Contains('@runtimeProperty("ModSettings.displayName", "E3-inspired HUD + nameplates")')) 'Player-facing E3 preference label drifted from the implemented visual slices.'

$allowed = @($seams.allowedHookFiles)
Check ($allowed -contains 'E3FirstPersonHud.reds') 'First-person E3 native seam is not registered in the 2.31 boundary allowlist.'
Check ($allowed -contains 'E3NameplatesNative.reds') 'NPC E3 native seam is not registered in the 2.31 boundary allowlist.'

Write-Host "PASS: $script:checks Biology-owned E3 presentation checks; HUD/nameplates are visibly gated, health suppression is independent, and scanner/quickhack remains native-owned."
