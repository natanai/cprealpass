$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\tools\Common.ps1"
$project = Get-ProjectRoot
$script:checks = 0

function Check($condition,[string]$message) {
    if (-not $condition) { throw $message }
    $script:checks++
}
function ReadText([string]$relative) {
    $path = Join-Path $project $relative
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Missing W18.1 archaeology contract: $relative" }
    Get-Content -Raw -LiteralPath $path
}

$recordPath = Join-Path $project 'docs/reference-mods/project-e3-hud-2.31-p2.json'
$record = Get-Content -Raw -LiteralPath $recordPath | ConvertFrom-Json -Depth 40
$config = Get-Content -Raw -LiteralPath (Join-Path $project 'config/realpass-e3.json') | ConvertFrom-Json -Depth 40
$archaeology = ReadText 'docs/E3-REFERENCE-ARCHAEOLOGY.md'
$mapping = ReadText 'docs/E3-COMPONENT-MAPPING.md'
$presentation = ReadText 'docs/E3-PRESENTATION.md'
$distribution = ReadText 'manifest/distribution.json'
$scannerPatch = Get-Content -Raw -LiteralPath (Join-Path $project 'config/patches/realpass-modern-scanner.json') | ConvertFrom-Json -Depth 40

Check ($record.schemaVersion -eq 1) 'Project E3 derived record schema version is not 1.'
Check ($record.source.name -eq 'Project E3 - HUD' -and $record.source.version -eq '2.31.p2') 'Project E3 derived source identity/version drifted.'
Check (-not (($record | ConvertTo-Json -Depth 40) -match '(?i)C:\\Games|/mnt/data|Cyberpunk-ReferenceMods')) 'Derived Project E3 record leaked a private/local path.'

$archiveConfig = @($config.files | Where-Object path -eq 'archive/pc/mod/basegame_3e_demo_hud.archive')
$archiveIdentity = @($record.source.selectedIdentities | Where-Object path -eq 'archive/pc/mod/basegame_3e_demo_hud.archive')
Check ($archiveConfig.Count -eq 1 -and $archiveIdentity.Count -eq 1) 'Pinned Project E3 archive identity is missing.'
Check ($archiveIdentity[0].sha256 -eq $archiveConfig[0].sha256) 'Derived Project E3 archive hash does not match the tracked exact reference.'

$deps = @($record.dependencies.name)
foreach ($name in @('redscript','TweakXL','Cyberpunk archive resource override','Mod Settings')) {
    Check ($deps -contains $name) "Project E3 dependency role is missing: $name"
}

$areas = @($record.mappings.referenceArea)
foreach ($needle in @(
    'HUD base fade/context transition',
    'Quest tracker and objective rows',
    'Weapon/ammo HUD',
    'D-pad / quickslots',
    'Ambient NPC nameplates',
    'Nameplate display policy',
    'Modern scanner / quickhack',
    'Minimap / stealth mappins',
    'Top compass / navigation ribbon',
    'World quest/interaction mappins',
    'Interaction prompts',
    'Dialogue choices and caption icons',
    'Activity log',
    'Tech-Hex / ordinary crosshair',
    'Player health/RAM lower-left HUD',
    'Phone waveform / holocall presentation'
)) {
    Check ($areas -contains $needle) "W18.1 derived mapping is missing reference area: $needle"
}

$mechanisms = @($record.mappings.mechanism | Select-Object -Unique)
foreach ($mechanism in @('redscript-hook-replace','tweakxl','archive-resource-replacement')) {
    Check ($mechanisms -contains $mechanism) "W18.1 does not preserve a material Project E3 mechanism: $mechanism"
}

foreach ($needle in @('370','34','336','authored INK','OptionalTracker','m_dpadHintsPanel','Pusula','blanket Always','MinimapContainerController','Biology-owned REDmod archive resource')) {
    Check ($archaeology.Contains($needle)) "W18.1 archaeology document is missing a material derived conclusion: $needle"
}
Check ($archaeology.Contains('does **not** reproduce Project E3 source bodies or archive payloads')) 'W18.1 archaeology doc lost its redistribution boundary.'
Check ($archaeology.Contains('never copy Project E3 resource bytes')) 'W18.1 archaeology doc no longer forbids Project E3 runtime/resource copying.'
Check ($scannerPatch.expectedResourceCount -eq 370) 'Historical Project E3 archive resource count drifted from the exact scanner-split evidence.'
Check (@($scannerPatch.excludedResources).Count -eq 34) 'Historical Project E3 scanner-family exclusion set must preserve exactly 34 resources.'
Check ($scannerPatch.expectedArchiveSha256 -eq $archiveIdentity[0].sha256) 'Historical scanner-split evidence is not pinned to the exact Project E3 archive.'
Check (@($scannerPatch.excludedResources.path | Sort-Object -Unique).Count -eq 34) 'Project E3 scanner-family exclusion paths are not unique.'
foreach ($excludedResource in @($scannerPatch.excludedResources)) {
    Check ([string]$excludedResource.sha256 -match '^[0-9A-F]{64}$') "Project E3 scanner-family exclusion hash is invalid for $($excludedResource.path)."
}
Check (@($record.opaqueAreas).Count -ge 1) 'W18.1 record must represent incomplete archive internals as opaque rather than inventing them.'
Check (-not (@($record.opaqueAreas.pathIdentity) -contains 'Project E3 dependency package/readme metadata')) 'W18.1 left dependency metadata opaque after the public Project E3 2.31 distribution cross-check.'
Check ($archaeology.Contains('config/patches/realpass-modern-scanner.json')) 'W18.1 archaeology doc does not point to the exact 34-resource scanner exclusion evidence.'
foreach ($publishedSurface in @('Action buttons','Wanted stars','Vehicle ammo counter','Quest / area / message / contact / item / level-up / warning / vehicle / radio notifications','Hacking minigame','Speedometer','archive-only coverage gate')) {
    Check ($archaeology.Contains($publishedSurface)) "W18.1 lost published Project E3 surface coverage: $publishedSurface"
}

# The architecture conclusion is intentionally not "copy Project E3". Preserve the
# narrower native-content seams that attended evidence already proved useful.
$quest = ReadText 'src/redscript/CyberpunkRealism/E3QuestHudNative.reds'
$weapon = ReadText 'src/redscript/CyberpunkRealism/E3WeaponHudNative.reds'
$hotkey = ReadText 'src/redscript/CyberpunkRealism/E3HotkeyHudNative.reds'
$crosshair = ReadText 'src/redscript/CyberpunkRealism/E3CrosshairHudNative.reds'
$nameplate = ReadText 'src/redscript/CyberpunkRealism/E3NameplatesNative.reds'
$identity = ReadText 'src/redscript/CyberpunkRealism/NameplatesNative.reds'

Check ($quest.Contains('this.m_questTrackerContainer') -and $quest.Contains('QuestTrackerObjectiveLogicController')) 'W18.1 discarded the W03.6 native quest/content-row seam.'
Check ($weapon.Contains('this.m_onFootContainer') -and $weapon.Contains('this.m_weaponAmmoWrapper')) 'W18.1 discarded the W03.5 native lower-right weapon binding.'
Check ($hotkey.Contains('this.m_dpadHintsPanel') -and -not $hotkey.Contains('this.GetRootCompoundWidget()')) 'W18.1 discarded the W03.6 hotkey semantic-host seam.'
Check (-not $crosshair.Contains('private let crBiologyE3FocusFrame') -and -not $crosshair.Contains('SetName(n"CRBiologyE3FocusFrame")')) 'W18.1 reintroduced the attended reticle artifact owner.'
Check ($nameplate.Contains('CRBiologyE3IdentityChrome') -and $identity.Contains('CRPublicAmbientNameAllowed')) 'W18.1 discarded the live framed ambient-name lifecycle.'

$combined = @($quest,$weapon,$hotkey,$crosshair,$nameplate,$identity) -join [Environment]::NewLine
foreach ($forbidden in @('module ProjectE3','import ProjectE3','basegame_3e_demo_hud.archive','r6/tweaks/Project E3 - HUD')) {
    Check (-not $combined.Contains($forbidden)) "Project E3 reference content leaked into Biology runtime source: $forbidden"
}
Check ($distribution.Contains('Project E3 scripts, archives and tweaks remain forbidden from player runtime artifacts')) 'Distribution contract no longer states the Project E3 runtime exclusion.'

# Scanner/quickhack remains a hard preserve after the full archaeology pass.
foreach ($forbidden in @('ScannerGameController','scannerGameController','ScannerDetailsGameController','ScannerNPCHeaderGameController','quickhackWidgetGameController','QuickHackGameController','scanner.inkwidget','scandetails.inkwidget','quickhacks.inkwidget')) {
    Check (-not $combined.Contains($forbidden)) "W18.1 crossed the native modern scanner/quickhack boundary: $forbidden"
}

Check ($mapping.Contains('E3-REFERENCE-ARCHAEOLOGY.md') -and $mapping.Contains('W18.1')) 'Component mapping does not route future workers to the W18.1 continuation authority.'
Check ($presentation.Contains('W18.1')) 'Canonical E3 presentation contract does not identify the W18.1 engineering-reference continuation.'

Write-Host "PASS: $script:checks W18.1 Project E3 archaeology checks; archive/redscript/TweakXL responsibilities are durable, W03.6 live wins are preserved, third-party runtime content remains excluded, and opaque archive details are not invented."
