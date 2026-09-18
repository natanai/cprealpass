# Biology E3 component mapping

Status: W03.4 live-presentation design-archaeology contract  
Last updated: 2026-09-17  
Issues: #78 / #40

## Evidence boundary

W13 accepted the live REDscript startup boundary on integrated candidate `f643bbc1c50a69d223c2cf54e9fc7f68215e33fd`: all Biology REDscript compiled on actual Cyberpunk 2.31 startup. W03.2 therefore treats the remaining “still retail” result as presentation/hook behavior.

Project E3 `2.31.p2` is reference archaeology only. The user-supplied archive/source was inspected outside Git; Biology does not ship it. Current installed Cyberpunk 2.31 / REDmod source remains authoritative for current controller ownership when available.

## Mapping rule

For each Project E3 area: identify the visual responsibility, the current 2.31 authority, whether the responsibility materially contributes to ordinary E3 presentation, the narrow Biology seam, and the ON/OFF acceptance test. Native gameplay/data/visibility authority should survive unless a narrowly proven post-native presentation correction is needed.

| Project E3 reference area | Visual responsibility | Current CP2077 2.31 controller/resource | Biology W03.2 decision / seam | E3 ON/OFF acceptance |
|---|---|---|---|---|
| `core/baseControllers/hudGameController.reds` | Global HUD context fades/show-hide behavior. | `inkHUDGameController`. | **Audited, no takeover.** Project E3 changed a broad base controller, but Biology can establish the ordinary visual language through narrower child controllers. A global override would increase risk to scanner/contextual HUD. | Ordinary HUD is coherent without changing global context/scanner ownership. |
| `cyberpunk/quests/quest_tracker.reds` | Quest title/objective composition and state presentation. | `QuestTrackerGameController`; native Journal authority. | **In scope.** `E3QuestHudNative.reds` adds a stronger Biology-owned red wash/rails/`OBJECTIVES` label after native updates; it does not replace Journal logic. | Same tracked quest: ON clearly red/minimal; OFF hides Biology overlay; text/counters remain identical. |
| `cyberpunk/mappins/minimapMappins.reds`, `questMappins.reds` | Minimap marker/clamping/quest presentation. | Current `MinimapContainerController` plus native mappin systems. | **Visually in scope, logically native.** `E3NavigationHudNative.reds` frames the current minimap; no old mappin logic is imported. | Same route/POIs in both states; ON navigation corner belongs to E3 language. |
| `cyberpunk/widgets/compass/*` | Historical E3 compass/POI/quest-marker composition. | Installed 2.31 evidence identifies current persistent `MinimapContainerController`; `IronsightGameController` is separate weapon/ironsight ownership. | **Historical reference only.** Do not restore the old compass subsystem or mount persistent navigation styling on ironsight. | ON is visibly E3-inspired while current route/minimap semantics remain available and aiming/scanner are not recolored. |
| `cyberpunk/weapons/weaponRoster.reds` | Weapon/ammo roster layout/decorator/format. | `WeaponRosterGameController`. | **In scope.** `E3WeaponHudNative.reds` adds a stronger owned wash/frame/`WEAPON // AMMO` label around native data. | Same weapon/ammo values; ON visibly red/minimal; OFF native. |
| `cyberpunk/widgets/dpad_hint/dpad_hint.reds` | Quick-slot/D-pad/phone hotkey presentation. | `HotkeysWidgetController` and native slot/input data. | **In scope visually.** `E3HotkeyHudNative.reds`; no input semantics changed. | Same slots/actions; ON belongs to red/minimal composition; OFF native. |
| `cyberpunk/weapons/crosshairs/crosshairController_Tech_Hex.reds` | Tech-specific focus/charge/spread visual behavior. | Current crosshair controller family plus `gameuiCrosshairContainerController`; Tech-Hex specialization remains `CrosshairGameController_Tech_Hex`. | **In scope visually.** W03.1 was too Tech-Hex-specific. W03.2 adds a generic Biology focus frame on `gameuiCrosshairContainerController` and keeps a restrained Tech-Hex inner treatment. Native crosshair/ADS/spread/vision authority remains untouched. | Ordinary weapon types show a coherent E3 focus language; scanner/non-default vision follows native container visibility; OFF removes Biology frame. |
| `cyberpunk/interactions/interactionsUI.reds` | Ordinary interaction title/options/progress presentation. Project E3 replaced substantial choice layout logic. | `interactionWidgetGameController`; native `InteractionChoiceHubData`, timing, choice spawning and input. | **Materially in scope, behavior preserved.** `E3InteractionHudNative.reds` wraps `OnInitialize`/`OnUpdateInteraction` only to add an owned red/minimal shell. It does **not** copy Project E3's replacement interaction logic. | Ordinary prompt is visibly part of E3 language ON; OFF yields; choices/timers/input are unchanged. |
| `cyberpunk/activityLog/activityLogControllers.reds` | Recurrent transient activity text and animation. | `activityLogEntryLogicController`. | **Materially in scope at low depth.** `E3ActivityHudNative.reds` post-styles each native-created entry red/uppercase. Queue, timing and animations remain native. | New activity entries are E3-styled ON and native OFF; no stale persistent widget. |
| `cyberpunk/interactions/dialogUI.reds` | Dialogue choices, tags, icon/color/layout behavior. | Native dialogue controllers. | **Audited, intentionally not ported.** Project E3's change is behavior/layout-heavy and contextual; W03.2 does not need to take over conversation choice logic to establish ordinary first-person presentation. | Dialogue remains native and functional in both states; no scanner/prompt regression. |
| `core/listControllers/phoneWaveformGameController.reds` | Phone-call portrait/waveform presentation. | `PhoneWaveformGameController`. | **Out of W03.2 ordinary-HUD target.** | Native. |
| `cyberpunk/Player/healthbar.reds` | Historical E3 player health surface. | `healthbarWidgetGameController`. | **Do not recreate.** Biology's barless actor-health policy is independent. `E3FirstPersonHud.reds` remains non-health presentation only. | HP bar suppression is unchanged by E3 ON/OFF and is not counted as E3 success. |
| `cyberpunk/widgets/healthbar/nameplateVisuals.reds` | Projected identity visibility and E3 name/level/frame styling. | `NameplateVisualsLogicController`; native `NPCNextToTheCrosshair` identity/focus data. | **Core in scope.** W03.2 keeps native identity first, uses only public `GetDisplayName()` as a conservative civilian fallback, and post-refreshes after native `SetElementVisibility(...)` so native visibility evaluation cannot erase the Biology presentation. Biology-owned text/frame live inside the native projection root; no second world-space system is created. | Random civilian can show legitimate baseline identity without scanner; police/combatants show full identity treatment, not a strip; OFF returns native presentation. |
| `cyberpunk/widgets/healthbar/npcNamePlate.reds` | Screen-projection lifecycle / display-name container visibility. | `NpcNameplateGameController`. | **Core in scope.** Keep exact narrow `OnScreenProjectionUpdate` adapter with native `GetNameplateVisible()` and enabled-record gates. | Look/focus appears/disappears with native projection; no stale label after look-away/context changes. |
| Project E3 NPC tweak files | Historical nameplate schema/record tuning. | Native `UINameplate_Record` / character records. | **Reference only.** No Project E3 tweak payload. A defined disabled native nameplate remains an explicit no. W03.2 removes the overly specific W03.1 requirement that every public civilian use exactly `UINameplate.CrowdSettings`. | Hidden/disabled/alternative/quest policy remains protected. |
| Project E3 mappin/UI tweak files | Historical marker/icon/clamping styles. | Native current mappin profiles. | **Reference only.** No Project E3 TweakDB authority copied. | Native navigation semantics remain unchanged. |
| `cyberpunk/hud/scanner/scanner_border.reds` and scanner resources in `basegame_3e_demo_hud.archive` | Old E3 scanner/focus composition. | Modern native scanner, quickhack list, RAM, scan details, target highlight. | **Hard preserve current/native.** No Biology scanner/quickhack hook/resource. | Modern scanner looks/behaves the same with E3 ON and OFF. |
| `archive/pc/mod/basegame_3e_demo_hud.archive` | Historical archive-backed HUD layouts/assets across many areas. | Current native UI resources plus Biology-owned runtime INK. | **Reference only; forbidden from player artifact.** W03.2 reproduces only needed visual language in owned code. | Player artifact contains no Project E3 archive/runtime content. |

## Why W03.1 could compile yet still look retail

The earlier implementation mainly added thin 2–4 px rails and tinted native controller roots. That was source-valid but not a reliable visual transformation: many child widgets carry their own states/styles, and mutating a root tint does not guarantee the authored retail composition changes materially. It also made E3 OFF depend on guessing that setting the root tint to white reproduced native state.

W03.2 therefore removes native-root tinting from these adapters and strengthens only **Biology-owned reversible overlays**. This creates a much clearer ON/OFF boundary and makes the effect visible without replacing native controller bodies.

For nameplates, the problem was additionally lifecycle-specific: native `SetElementVisibility(...)` executes within `SetVisualData` and can hide native name text after an earlier presentation refresh. W03.2 refreshes the Biology-owned projected treatment **after** that exact native visibility seam.

## Nameplate knowledge model

1. Native `NPCNextToTheCrosshair.name` always wins.
2. When it is empty, a civilian fallback may use only `GameObject.GetDisplayName()` if the NPC is attached/public, not hidden, not a generic quest-target fallback, has no alternative identity, and a defined native nameplate record is not disabled.
3. Biology does not derive FullDisplayName/archetype/affiliation or require/inspect scanner completion for the baseline label.
4. Scanner-acquired native identity automatically supersedes the fallback later.

## Modern scanner exclusion

W03.2 production presentation files must contain no scanner/quickhack controller/resource ownership. The generic crosshair frame is a child of the current crosshair container, whose native vision visibility remains authoritative, so scanner preservation does not require a Biology scanner hook.

## Parent acceptance

Parent P01.2 should integrate and attend: E3 ON/OFF same view; quest; minimap/navigation; weapon/ammo/hotkeys; ordinary interaction prompt and activity entry; random civilian; police/combatant; after-scan enrichment where applicable; modern scanner/quickhack; ordinary combat/navigation/interaction for stale/overlap checks.


## W03.3 attended functional correction

Integrated main 205578b11d818f474dc74a873e6d6ea5a1e1accd disproved W03.2's assumption that source-valid fixed-size child overlays were sufficient. Ordinary HUD remained retail-looking, ambient names remained absent, and scanning could produce a small red rectangle near the reticle.

The corrective mapping is:

| Responsibility | W03.2 live failure | W03.3 seam |
|---|---|---|
| Quest / minimap / weapon / hotkeys / lower-left / prompt | Large fixed-size translated canvases were children of controller-local roots and could be clipped or misplaced. | Use a root-fitted inkEAnchor.Fill Biology shell plus local wash/rails/label; hide only the owned shell on OFF. |
| Ordinary focus | Generic plus Tech-Hex nested treatments created two potential lifecycle owners near reticle/scanner transitions. | Keep only gameuiCrosshairContainerController; remove the Tech-Hex Biology child. |
| Ambient identity | Helper was civilian-only, so police/combatants could never use the public fallback. | Allow attached ordinary NPCs, including civilian/police/combatant, while retaining quest/hidden/alternative/disabled-record gates. |
| Projected nameplate root | Native IsAnyElementVisible() can return false before W03.2's post-projection m_displayName reveal, hiding the whole root. | Wrap NameplateVisualsLogicController.IsAnyElementVisible() so legitimate ambient Biology identity counts as visible; preserve the rest of native projection authority. |
| Nameplate drawing | W03.2 added a fixed 440x82 custom child inside the projected root; after scan it could appear as a clipped red artifact. | Remove custom projected canvas and style native m_nameTextMain / m_nameFrame instead. |
| Non-aggressive range | Current native ordinary nameplate range is 3 with max 10, too narrow for the intended ambient E3 identity role. | E3 ON uses 10 / 20; OFF restores SNameplateRangesData 3 / 10 values. |
| Hook proof | Static/native compile proved signatures, not that each controller fires in the attended ordinary path. | Emit narrow [Biology:E3] trace markers so parent integration can correlate live hook execution with visible results. |

Modern scanner/quickhack remains deliberately unhooked. The trace and nameplate corrections are presentation evidence/behavior only and do not reopen W13 startup or scanner architecture.


## W03.4 visual-completion mapping

T002 on exact integrated source `3dc049ee99979f924978b671ddbbbda06b472d1b` changes the mapping again. Ambient names are now a live KEEP; the remaining defects are visual hierarchy and the reticle artifact.

| Responsibility | T002 evidence | W03.4 decision |
|---|---|---|
| Reticle / ordinary focus | A red top-left and bottom-right corner pair remains beside the native reticle in both supplied captures. | Concrete owner is W03.3 `CRBiologyE3FocusFrame`: centered 112 x 112 canvas with exactly those two corner pairs. Delete it. Do not add replacement reticle geometry. Use captured/restored tint on native `gameuiCrosshairBaseGameController`; native Scanning state keeps the root hidden. |
| Quest / minimap / weapon / hotkeys / lower-left / prompt | Hooks visibly execute, but full-root red washes create large generic red blocks. | Keep the same proven current controllers, remove every full-root wash, and use shared compact chrome: short top/left rules, accent cell, small label band, faint lower-right corner. |
| Ambient identity lifecycle | Ordinary names are now visibly live. | **KEEP unchanged.** Preserve `SetVisualData` enrichment, `SetElementVisibility` refresh, `IsAnyElementVisible` ambient-name gate, native projection and 10 / 20 ordinary range. |
| Nameplate visual design | Name text is visible but still reads as plain red text rather than the intended E3 identity card. | Keep native `m_nameTextMain` + `m_nameFrame`, add a compact 340 x 46 Biology-owned segmented identity chrome behind native text, and capture/restore native text/frame tint on OFF. No health bar/number. |
| Project E3 nameplate archaeology | Reference source uses name text plus name frame and optional background/level framing. | Treat that as visual responsibility evidence only. Biology recreates compact framing in original code and does not copy/ship archive widgets, tweaks, source, levels, health UI or identity derivation. |
| Modern scanner / quickhack | T002 still requires the current scanner to remain native. | No scanner controller/resource hook. Crosshair repair relies on native crosshair state ownership; scanner presentation remains out of scope. |
| Activity log | Existing red/uppercase treatment is lightweight and not implicated in T002 blocks. | Keep current reversible native-entry styling. |

### W03.4 acceptance

The parent-integrated E3 ON capture should show compact, repeated chrome rather than opaque slabs; the ambient nameplate should have a real framed identity treatment; the two-corner reticle artifact must be absent; and the native scanner/quickhack UI must remain unchanged. E3 OFF must hide Biology-owned chrome and restore captured native tint/range state.
