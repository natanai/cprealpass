$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\tools\Common.ps1"
$project = Get-ProjectRoot
$sourceRoot = Join-Path $project 'src/redscript/CyberpunkRealism'
$paths = [ordered]@{
    lowerLeft = Join-Path $sourceRoot 'E3FirstPersonHud.reds'
    quest = Join-Path $sourceRoot 'E3QuestHudNative.reds'
    navigation = Join-Path $sourceRoot 'E3NavigationHudNative.reds'
    weapon = Join-Path $sourceRoot 'E3WeaponHudNative.reds'
    crosshair = Join-Path $sourceRoot 'E3CrosshairHudNative.reds'
    hotkey = Join-Path $sourceRoot 'E3HotkeyHudNative.reds'
    interaction = Join-Path $sourceRoot 'E3InteractionHudNative.reds'
    activity = Join-Path $sourceRoot 'E3ActivityHudNative.reds'
    nameplate = Join-Path $sourceRoot 'E3NameplatesNative.reds'
    identity = Join-Path $sourceRoot 'NameplatesNative.reds'
    health = Join-Path $sourceRoot 'NoHealthbars.reds'
    settings = Join-Path $sourceRoot 'RealpassSettings.reds'
    preferenceUi = Join-Path $sourceRoot 'BiologyPreferencesNative.reds'
    primitives = Join-Path $sourceRoot 'E3PresentationPrimitives.reds'
}
$mappingPath = Join-Path $project 'docs/E3-COMPONENT-MAPPING.md'
$presentationPath = Join-Path $project 'docs/E3-PRESENTATION.md'
$seams = Get-Content -Raw -LiteralPath (Join-Path $project 'manifest/native-seams.json') | ConvertFrom-Json
$contract = Get-Content -Raw -LiteralPath (Join-Path $project 'manifest/settings.json') | ConvertFrom-Json
$script:checks = 0
function Check($condition,[string]$message) { if (-not $condition) { throw $message }; $script:checks++ }

foreach ($path in @($paths.Values) + @($mappingPath,$presentationPath)) {
    Check (Test-Path -LiteralPath $path -PathType Leaf) "Missing W03.6 E3 presentation contract/source: $path"
}

$source = @{}
foreach ($key in $paths.Keys) { $source[$key] = Get-Content -Raw -LiteralPath $paths[$key] }
$mapping = Get-Content -Raw -LiteralPath $mappingPath
$presentation = Get-Content -Raw -LiteralPath $presentationPath

# Coherent HUD chrome: root-fitted shells remain, but T002's full-root red slabs are gone.
Check ($source.primitives.Contains('AddPanelChrome')) 'W03.4 shared compact HUD chrome primitive is missing.'
Check ($source.primitives.Contains('AddAnchoredRect')) 'W03.4 compact lower-right chrome primitive is missing.'
Check (-not $source.primitives.Contains('AddFillWash')) 'Full-root wash primitive survived W03.4 visual cleanup.'
foreach ($key in @('lowerLeft','quest','navigation','weapon','hotkey','interaction')) {
    Check ($source[$key].Contains('CreateFillShell')) "$key lost the root-fitted/native-content shell."
    Check (-not $source[$key].Contains('AddFillWash')) "$key still paints an attended full-root red slab."
    Check ($source[$key].Contains('UseE3FirstPersonHudVisuals(GetGameInstance())')) "$key is not gated by the single E3 preference."
}
foreach ($key in @('lowerLeft','navigation','weapon','interaction')) {
    Check ($source[$key].Contains('AddPanelChrome')) "$key lost the shared compact panel chrome language."
}
Check ($source.primitives.Contains('AddSegmentedRegionChrome')) 'W03.6 shared native-region segmented chrome primitive is missing.'
Check ($source.quest.Contains('AddSegmentedRegionChrome')) 'W03.6 quest tracker does not use host-relative segmented region chrome.'
Check ($source.hotkey.Contains('AddSegmentedRegionChrome')) 'W03.6 hotkey/quickslot panel does not use host-relative segmented region chrome.'

Check ($source.quest.Contains('@wrapMethod(QuestTrackerGameController)')) 'Quest/objective tracker lost its native controller seam.'
Check ($source.navigation.Contains('@wrapMethod(MinimapContainerController)') -and $source.navigation.Contains('"NAV // ROUTE"')) 'Current minimap host lost W03.4 compact chrome.'
Check (-not $source.navigation.Contains('@wrapMethod(IronsightGameController)')) 'Navigation styling regressed to historical ironsight ownership.'
Check ($source.weapon.Contains('@wrapMethod(WeaponRosterGameController)') -and $source.weapon.Contains('"WEAPON // AMMO"')) 'Weapon/ammo roster lost W03.4 compact chrome.'
Check ($source.quest.Contains('CRResolveBiologyE3QuestHost') -and $source.quest.Contains('this.m_questTrackerContainer')) 'W03.5 quest chrome is not bound to the native semantic tracker content region.'
Check ($source.quest.Contains('CreateFillShell(this.crBiologyE3QuestHost')) 'W03.5 quest chrome still mounts against a controller/root coordinate space instead of the resolved content host.'
Check (-not $source.quest.Contains('inkCompoundRef.Get(this.m_ObjectiveContainer)')) 'W03.5 quest chrome contaminates the native objective child list instead of failing closed on an unresolved tracker host.'
Check ($source.quest.Contains('this.m_QuestTitle') -and $source.quest.Contains('crBiologyE3NativeQuestTitleTint')) 'W03.5 quest presentation does not transform and reversibly restore the actual native quest title.'
Check ($source.quest.Contains('QuestTrackerObjectiveLogicController') -and $source.quest.Contains('this.m_objectiveTitle') -and $source.quest.Contains('this.m_trackingIcon') -and $source.quest.Contains('this.m_trackingFrame')) 'W03.6 quest completion does not style the actual native objective-row content.'
Check ($source.quest.Contains('CRRefreshBiologyE3ObjectiveStyles') -and $source.quest.Contains('inkCompoundRef.GetNumChildren(this.m_ObjectiveContainer)')) 'W03.6 quest controller does not refresh native objective-row styling after tracker data changes.'
Check ($source.quest.Contains('crBiologyE3NativeObjectiveTitleTint') -and $source.quest.Contains('crBiologyE3NativeTrackingIconTint') -and $source.quest.Contains('crBiologyE3NativeTrackingFrameTint')) 'W03.6 objective presentation cannot restore native row styling when E3 is off.'
Check (-not $source.quest.Contains('Reparent(this.m_ObjectiveContainer') -and -not $source.quest.Contains('CreateFillShell(inkCompoundRef.Get(this.m_ObjectiveContainer)')) 'W03.6 quest completion contaminates the objective-controller child list.'
Check (-not $source.quest.Contains('SetTranslation(')) 'W03.5 quest repair introduced an arbitrary local/global translation instead of binding to the native content region.'
Check ($source.weapon.Contains('CRResolveBiologyE3WeaponHost') -and $source.weapon.Contains('this.m_onFootContainer') -and $source.weapon.Contains('this.m_weaponAmmoWrapper')) 'W03.5 weapon chrome is not bound to the native semantic on-foot/ammo content regions.'
Check ($source.weapon.Contains('CreateFillShell(this.crBiologyE3WeaponHost')) 'W03.5 weapon chrome still mounts against a controller/root coordinate space instead of the resolved content host.'
Check ($source.weapon.Contains('this.m_weaponName') -and $source.weapon.Contains('this.m_weaponCurrentAmmo') -and $source.weapon.Contains('this.m_weaponTotalAmmo')) 'W03.5 weapon presentation does not target the actual native weapon/ammo text widgets.'
Check ($source.weapon.Contains('crBiologyE3NativeWeaponNameTint') -and $source.weapon.Contains('crBiologyE3NativeCurrentAmmoTint') -and $source.weapon.Contains('crBiologyE3NativeTotalAmmoTint')) 'W03.5 weapon E3 OFF path cannot restore captured native weapon/ammo tints.'
Check (-not $source.weapon.Contains('SetTranslation(')) 'W03.5 weapon repair introduced an arbitrary local/global translation instead of binding to the native content region.'
Check ($source.primitives.Contains('TraceMountedRegion') -and $source.primitives.Contains('GetSize()') -and $source.primitives.Contains('GetTranslation()') -and $source.primitives.Contains('GetMargin()')) 'W03.5 lacks bounded native-host/chrome geometry trace evidence.'
Check ($source.quest.Contains('TraceMountedRegion') -and $source.weapon.Contains('TraceMountedRegion')) 'W03.5 quest/weapon adapters do not emit bounded content-region mount/state evidence.'
Check (-not $source.quest.Contains('return NULL;') -and -not $source.weapon.Contains('return NULL;')) 'W03.5 reintroduced a NULL return token that redscript 0.5.31 does not resolve in Biology source.'
Check (-not $source.quest.Contains('crBiologyE3QuestLastEnabled != enabled') -and -not $source.weapon.Contains('crBiologyE3WeaponLastEnabled != enabled')) 'W03.5 reintroduced Bool inequality syntax that the exact redscript 0.5.31 compile rejects.'
Check ($source.hotkey.Contains('@wrapMethod(HotkeysWidgetController)')) 'Quick-slot/D-pad lost its native controller seam.'
Check ($source.hotkey.Contains('CRResolveBiologyE3HotkeyHost') -and $source.hotkey.Contains('this.m_dpadHintsPanel')) 'W03.6 hotkey chrome is not bound to the native m_dpadHintsPanel semantic content host.'
Check ($source.hotkey.Contains('CreateFillShell(this.crBiologyE3HotkeyHost')) 'W03.6 hotkey chrome still mounts against the controller root instead of the semantic content host.'
Check (-not $source.hotkey.Contains('this.GetRootCompoundWidget()')) 'W03.6 hotkey repair regressed to controller-root composition.'
Check (-not $source.hotkey.Contains('SetTranslation(')) 'W03.6 hotkey repair introduced an arbitrary screenshot-derived/global translation.'
Check ($source.hotkey.Contains('TraceMountedRegion')) 'W03.6 hotkey adapter does not emit bounded native-host/chrome geometry evidence.'
Check ($source.interaction.Contains('@wrapMethod(interactionWidgetGameController)') -and $source.interaction.Contains('"INTERACTION"')) 'Ordinary interaction prompt lost W03.4 compact chrome.'
Check (-not $source.interaction.Contains('@replaceMethod') -and -not $source.interaction.Contains('FromVariant<InteractionChoiceHubData>') -and -not $source.interaction.Contains('AsyncSpawnFromLocal')) 'Interaction presentation took over native choice/input behavior.'

# T002 reticle artifact: exact owner identified and deleted.
Check ($source.crosshair.Contains('T002 conclusively identified the previous CRBiologyE3FocusFrame as the reticle artifact')) 'W03.4 source does not preserve the concrete reticle-artifact diagnosis.'
Check (-not $source.crosshair.Contains('private let crBiologyE3FocusFrame') -and -not $source.crosshair.Contains('SetName(n"CRBiologyE3FocusFrame")')) 'The centered 112x112 reticle artifact canvas still exists as runtime geometry.'
Check (-not $source.crosshair.Contains('n"CRBiologyE3FocusTLH"') -and -not $source.crosshair.Contains('n"CRBiologyE3FocusBRH"')) 'Reticle corner widget geometry survived W03.4.'
Check ($source.crosshair.Contains('@wrapMethod(gameuiCrosshairBaseGameController)')) 'W03.4 crosshair treatment is not attached to the native crosshair hierarchy.'
Check ($source.crosshair.Contains('crBiologyE3NativeCrosshairTint') -and $source.crosshair.Contains('GetTintColor()')) 'W03.4 crosshair treatment cannot restore the native tint on E3 OFF.'
Check ($source.crosshair.Contains('OnCrosshairStateChange')) 'W03.4 crosshair tint is not refreshed through native crosshair state changes.'
Check (-not $source.crosshair.Contains('new inkCanvas()') -and -not $source.crosshair.Contains('AddRect(')) 'Crosshair repair added replacement reticle geometry instead of removing the proven artifact owner.'

# Activity remains lightweight and reversible.
Check ($source.activity.Contains('@wrapMethod(activityLogEntryLogicController)')) 'Transient activity presentation is not covered.'
Check ($source.activity.Contains('crBiologyE3NativeActivityTint') -and $source.activity.Contains('SetText')) 'Activity presentation is not reversible for reused entries.'
Check (-not $source.activity.Contains('@replaceMethod') -and -not $source.activity.Contains('new inkAnimController')) 'Activity styling took over native queue/animation behavior.'

# Preserve the now-proven ambient identity lifecycle, but give it a real compact frame.
Check ($source.identity.Contains('CRPublicAmbientNameAllowed')) 'W03.3 ambient identity helper was lost.'
Check (-not $source.identity.Contains('npc.IsCharacterCivilian()')) 'Police/combatants were re-excluded from ambient identity.'
Check ($source.nameplate.Contains('public final func IsAnyElementVisible() -> Bool')) 'Native nameplate-root visibility repair was lost.'
Check ($source.nameplate.Contains('CRBiologyE3ShouldShowAmbientName')) 'Ambient identity no longer participates in the native visible-element gate.'
Check ($source.nameplate.Contains('CRBiologyE3IdentityChrome')) 'W03.4 nameplate is still only red text without a dedicated compact identity frame.'
Check ($source.nameplate.Contains('Vector2(340.0, 46.0)')) 'Nameplate chrome is not constrained to the intended compact projected identity envelope.'
Check ($source.nameplate.Contains('crBiologyE3NativeNameTint') -and $source.nameplate.Contains('crBiologyE3NativeFrameTint')) 'E3 OFF cannot restore native name/frame styling.'
Check ($source.nameplate.Contains('this.m_nameTextMain') -and $source.nameplate.Contains('this.m_nameFrame')) 'W03.4 stopped using native nameplate text/frame authority.'
Check ($source.nameplate.Contains('this.c_DisplayRangeNotAggressive = 10.0') -and $source.nameplate.Contains('this.c_MaxDisplayRangeNotAggressive = 20.0')) 'Proven ambient range behavior was lost.'
Check ($source.nameplate.Contains('SNameplateRangesData.GetDisplayRangeNotAggressive()') -and $source.nameplate.Contains('SNameplateRangesData.GetMaxDisplayRangeNotAggressive()')) 'E3 OFF cannot restore native ambient range.'
foreach ($forbidden in @('m_healthbarWidget','m_damagePreviewWidget','currentHealth','maximumHealth','StatPoolType.Health')) {
    Check (-not $source.nameplate.Contains($forbidden)) "E3 nameplate absorbed health-meter ownership: $forbidden"
}

# Narrow hook traces stay available for the next parent-attended session.
Check ($source.primitives.Contains('FTLog("[Biology:E3] " + hook)')) 'W03.4 presentation hook trace prefix is missing.'
foreach ($key in @('lowerLeft','quest','navigation','weapon','hotkey','interaction','activity','crosshair','nameplate')) {
    Check ($source[$key].Contains('CRBiologyE3Primitives.Trace(')) "$key lacks live hook-execution trace evidence."
}

# Modern scanner/quickhack is a hard exclusion.
$combined = ($source.Keys | ForEach-Object { $source[$_] }) -join [Environment]::NewLine
foreach ($forbidden in @('ScannerGameController','scannerGameController','ScannerDetailsGameController','ScannerNPCHeaderGameController','quickhackWidgetGameController','QuickHackGameController','scanner.inkwidget','scanner_details.inkwidget','scanner_hud.inkwidget','base\gameplay\gui\widgets\scanner')) {
    Check (-not $combined.Contains($forbidden)) "Owned E3 presentation crossed the modern scanner/quickhack boundary: $forbidden"
}
foreach ($forbidden in @('module ProjectE3','import ProjectE3','patches/project-e3-hud','DarkFuture.','import DarkFuture','basegame_3e_demo_hud.archive')) {
    Check (-not $combined.Contains($forbidden)) "Owned E3 runtime gained forbidden reference-mod dependency: $forbidden"
}
Check (-not $combined.Contains('ResRef.FromString')) 'Owned E3 presentation depends on external E3 UI resources.'

# Health policy and public settings authority stay independent.
Check (-not $source.health.Contains('UseE3FirstPersonHudVisuals')) 'Healthbar suppression is incorrectly controlled by the E3 preference.'
Check ($source.health.Contains('CRRealpassSettings.IsEnabled(GetGameInstance())')) 'Healthbar suppression lost its Biology-wide activation gate.'
Check ($contract.releaseProfile.traditionalActorHealthBarsFinalTarget -eq $false) 'Traditional actor health bars were reintroduced.'
Check ($contract.releaseProfile.nativeModernScanner -eq $true) 'Contract no longer protects the modern native scanner.'
$controls = @($contract.publicControls)
Check ($controls.Count -eq 1) 'E3 preference is no longer the sole in-game public preference.'
Check ($controls[0].id -eq 'presentation.e3-first-person-hud-visuals' -and $controls[0].authority -eq 'presentation-only') 'E3 preference no longer has presentation-only authority.'

foreach ($needle in @('T002','3dc049ee99979f924978b671ddbbbda06b472d1b','CRBiologyE3FocusFrame','112','full-root red','W03.4')) {
    Check ($presentation.Contains($needle)) "Canonical W03.4 presentation contract is missing attended evidence/diagnosis: $needle"
}
foreach ($needle in @('T003','67593bfbb12b4a6ebcec7042066d48b4f5fac427','native HUD content regions','m_questTrackerContainer','m_onFootContainer','W03.5')) {
    Check ($presentation.Contains($needle)) "Canonical W03.5 presentation contract is missing attended/content-region evidence: $needle"
}
foreach ($needle in @('W03.4','CRBiologyE3FocusFrame','compact chrome','ambient')) {
    Check ($mapping.Contains($needle)) "Component mapping is missing W03.4 visual/reticle correction: $needle"
}
foreach ($needle in @('W03.5','T003','m_questTrackerContainer','m_onFootContainer','content region')) {
    Check ($mapping.Contains($needle)) "Component mapping is missing W03.5 native-content-region correction: $needle"
}
foreach ($needle in @('T004','ffa6f64d6c837146d032aaab565d671c932453a2','m_dpadHintsPanel','QuestTrackerObjectiveLogicController','W03.6')) {
    Check ($presentation.Contains($needle)) "Canonical W03.6 presentation contract is missing attended/native-content evidence: $needle"
}
foreach ($needle in @('W03.6','T004','m_dpadHintsPanel','m_objectiveTitle','segmented region')) {
    Check ($mapping.Contains($needle)) "Component mapping is missing W03.6 quest/hotkey content-region correction: $needle"
}

$allowed = @($seams.allowedHookFiles)
foreach ($file in @('E3FirstPersonHud.reds','E3QuestHudNative.reds','E3NavigationHudNative.reds','E3WeaponHudNative.reds','E3CrosshairHudNative.reds','E3HotkeyHudNative.reds','E3InteractionHudNative.reds','E3ActivityHudNative.reds','E3NameplatesNative.reds','NoHealthbars.reds')) {
    Check ($allowed -contains $file) "W03.4 native presentation seam is not registered in the 2.31 boundary allowlist: $file"
}

Write-Host "PASS: $script:checks W03.6 E3 quest/hotkey content-region checks; quest native rows and m_dpadHintsPanel own the visible composition, no controller-root/global-offset regression was introduced, and prior weapon/nameplate/reticle/scanner boundaries remain protected."
