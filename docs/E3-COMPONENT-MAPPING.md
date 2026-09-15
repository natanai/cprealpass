# Biology E3 component mapping

Status: attended follow-up design-archaeology contract  
Last updated: 2026-09-15  
Issue: #40

## Purpose and clarified scope

The attended `8cf04566...` Biology candidate proved that a small red biomonitor frame plus a narrow combat/nameplate strip is not enough to make ordinary gameplay read as the intended red/minimal 2018/E3-inspired presentation.

The Project E3 inventory is audited here so Biology can understand which native systems created that historical presentation. **The implementation target is deliberately much narrower than Project E3 itself:** Biology is bringing in only the **neutral first-person HUD visual language and NPC nameplates**. It is not recreating Project E3 as a whole.

For this contract, “neutral first-person HUD” means the persistent/default ordinary-gameplay surfaces that collectively dominate the player's view most of the time:

- quest/objective tracker;
- minimap/navigation presentation;
- weapon/ammo presentation;
- ordinary crosshair/focus presentation while applicable;
- quick-slot/D-pad presentation;
- Biology's existing non-health lower-left presentation;
- NPC nameplates.

Context-specific systems such as dialogue-choice redesign, interaction-menu redesign, activity-log replacement animations, phone-call presentation, and the old Project E3 scanner are **not part of this follow-up**. The modern scanner/quickhack experience is a hard preserve.

Project E3 HUD remains **reference material only**. Biology must not execute or redistribute its archive, scripts, tweak payload, settings implementation, or save/runtime authority.

The durable reference inventory remains `config/realpass-e3.json`. For this follow-up, the complete user-supplied Project E3 `2.31.p2` reference ZIP was inspected locally outside Git. The listed script/tweak/archive files matched the preserved inventory names, sizes and hashes; no Project E3 source body is added to this repository.

Direct installed-game evidence now supplements that archaeology. The 2026-09-15 read-only local presentation audit against Cyberpunk 2077 2.31:

- exact-compiled the Biology candidate against the installed `r6\cache\final.redscripts` successfully;
- read the installed official REDmod decompiled scripts under `tools\redmod\scripts`;
- confirmed `MinimapContainerController` in `cyberpunk/UI/widgets/minimap/minimap.script` as the current persistent minimap host;
- separately confirmed `IronsightGameController` in the weapon/ironsight script path;
- confirmed the current nameplate controller/text/frame symbols used by the Biology adapter.

Therefore historical Project E3 controller ownership is not assumed to be current-game ownership. Installed REDmod source wins when it can establish the supported 2.31 contract directly.

## Design rule

For every reference area below, the question is not “copy this Project E3 file.” The question is:

> What visible responsibility did the reference have, does it belong to Biology's clarified neutral-HUD/nameplate scope, what current 2.31 native controller owns the authoritative information, and what is the smallest Biology-owned presentation seam that can reproduce the materially important visual language without stealing gameplay/scanner authority?

`E3 OFF` means the Biology-owned E3-specific presentation yields. It does **not** change Biology simulation and does **not** restore actor HP bars while Biology remains enabled.

## Reference → native → Biology mapping

| Project E3 reference area | Reference responsibility | Current CP2077 2.31 native authority | Biology decision | Biology-owned seam | E3 ON/OFF acceptance |
|---|---|---|---|---|---|
| `core/baseControllers/hudGameController.reds` | Simplified generic HUD context fades. | `inkHUDGameController`. | **Archaeology only in this follow-up.** A base-controller takeover is broader than the clarified neutral-HUD target and risks contextual/scanner surfaces. Coherence is produced through the persistent neutral child controllers instead. | None. | Neutral HUD must still read coherently E3-inspired without changing scanner/context-controller ownership. |
| `cyberpunk/quests/quest_tracker.reds` | Quest title/objective arrangement and objective-state visuals. | `QuestTrackerGameController`; native Journal data. | **In scope.** The tracker is present through ordinary play and was an attended source of the “still retail” appearance. Preserve quest logic; restyle its native root. | `E3QuestHudNative.reds`. | Same tracked quest/view: ON is red/minimal; OFF yields to native styling; objective text/counters are identical. |
| `cyberpunk/activityLog/activityLogControllers.reds` | Activity notification text/animation. | `activityLogEntryLogicController`. | **Out of clarified scope.** Transient activity notifications are contextual, not part of the persistent neutral HUD. | None. | No requirement to change activity-log styling in this follow-up. |
| `cyberpunk/interactions/dialogUI.reds` | Dialogue-choice layout, colors, tags and icons. | Native dialogue controllers. | **Out of clarified scope.** Dialogue is a contextual interaction system rather than the neutral HUD. | None. | Dialogue behavior/presentation remains native unless separately requested later. |
| `cyberpunk/interactions/interactionsUI.reds` | Contextual interaction-choice layout and progress presentation. | `interactionWidgetGameController`; native interaction data. | **Out of clarified scope.** Do not expand this follow-up into an interaction UI rewrite. | None. | Interaction behavior remains native. |
| `cyberpunk/mappins/minimapMappins.reds` | Minimap mappin/clamping/police-state presentation. | `MinimapContainerController` plus native minimap/mappin systems, directly confirmed from installed 2.31 REDmod scripts. | **In scope visually, native logically.** Keep route/POI/police data and behavior native while integrating the persistent minimap/navigation corner into the red/minimal HUD language. | `E3NavigationHudNative.reds` on `MinimapContainerController`. | Same location: ON navigation/minimap area reads as part of the E3 HUD; OFF yields; route information is unchanged. |
| `cyberpunk/mappins/questMappins.reds` | Quest marker visual presentation. | Native quest mappin controllers/data rendered through the current minimap system. | **Do not recreate Project E3 marker logic.** Native quest marker semantics remain; the persistent minimap host carries the E3 visual language. | `E3NavigationHudNative.reds`. | Quest marker/routing remains correct in both modes. |
| `cyberpunk/quests/mappinsControllers.reds` | Empty in preserved 2.31.p2 reference. | N/A. | **No implementation required.** | None. | N/A. |
| `cyberpunk/widgets/compass/*` | Historical archive-backed compass/POI/quest-marker system mounted by Project E3 on `IronsightGameController`. | Current persistent minimap authority is `MinimapContainerController`; `IronsightGameController` remains a separate weapon/ironsight controller in installed 2.31 REDmod source. | **Historical design reference only.** Do not import the compass subsystem, custom widget paths, optimizer/mappin pools, or attach Biology's persistent navigation skin to the weapon/ironsight root. Reproduce only the neutral red/minimal navigation language on the current minimap host. | `E3NavigationHudNative.reds` wraps `MinimapContainerController.OnInitialize`. | ON minimap/navigation corner is red/minimal and coherent; aiming/scanner-adjacent weapon presentation is not recolored by the navigation adapter. |
| `cyberpunk/weapons/weaponRoster.reds` | Weapon/ammo layout and formatting. | `WeaponRosterGameController`; native weapon/ammo authority. | **In scope.** Weapon/ammo is persistent ordinary HUD. Keep data native and restyle the root. | `E3WeaponHudNative.reds`. | Same equipped weapon: data identical; ON visibly red/minimal; OFF native. |
| `cyberpunk/weapons/crosshairs/crosshairController_Tech_Hex.reds` | Tech crosshair layout/spread/charge and ADS behavior. | `CrosshairGameController_Tech_Hex`. | **In scope visually only.** Crosshair/focus is part of ordinary first-person HUD when applicable. Do not copy Project E3 aiming/ADS behavior or hide useful aiming information. | `E3CrosshairHudNative.reds`. | ON uses restrained red/minimal styling without changing spread/charge/aim semantics; OFF native. |
| `cyberpunk/Player/healthbar.reds` | Historical bespoke player healthbar. | `healthbarWidgetGameController`. | **Do not recreate health.** Biology's locked barless-health policy supersedes this reference behavior. Existing non-health lower-left E3 framing may remain. | `NoHealthbars.reds` remains Biology-wide; `E3FirstPersonHud.reds` is presentation-only. | Player HP remains suppressed in both E3 states while Biology is enabled; HUD ON/OFF distinction is proven elsewhere. |
| `cyberpunk/widgets/dpad_hint/dpad_hint.reds` | Persistent quick-slot/D-pad presentation. | `HotkeysWidgetController` / native hotkey data. | **In scope visually.** Preserve all input/slot semantics; style only the neutral HUD surface. | `E3HotkeyHudNative.reds`. | Same quick-slot state: ON joins red/minimal HUD; OFF native; controls unchanged. |
| `core/listControllers/phoneWaveformGameController.reds` | Phone-call portrait/waveform presentation. | `PhoneWaveformGameController`. | **Out of clarified scope.** Phone-call UI is contextual, not neutral HUD. | None. | No phone-call redesign required. |
| `cyberpunk/widgets/healthbar/nameplateVisuals.reds` | Resolved/displayed names and made name/frame presentation a primary identity surface; historical code showed non-turret identity rather than merely decorating an already-visible health strip. | `NameplateVisualsLogicController`; `NPCNextToTheCrosshair`; native character/nameplate records. | **Core in-scope behavior and visuals.** Native incoming identity wins. For an otherwise-empty ordinary public crowd identity, use only the public entity display name when native nameplate/scanner records permit it. | `NameplatesNative.reds` for identity resolution; `E3NameplatesNative.reds` for visible red/minimal text/frame treatment. | Random civilian direct focus with E3 ON shows baseline identity without scanner; police/combatants show a complete identity treatment, not just a red strip. |
| `cyberpunk/widgets/healthbar/npcNamePlate.reds` | Extended range and forced native display-name visibility during screen-projection updates. | `NpcNameplateGameController`; native screen projection and nameplate record. | **Core in-scope lifecycle seam.** Preserve native projection/distance/scene authority but ensure permitted identity can actually render during ordinary focus. Do not create a second floating-label system. | `E3NameplatesNative.reds` wraps the verified projection callback narrowly. | Look/focus shows permitted ambient identity; look-away/dialog/scanner transitions do not leave stale widgets. |
| `r6/tweaks/.../ui/npc/nameplate.yaml`, `schema.yaml` | Historical nameplate record/schema tuning. | Native `UINameplate_Record` / `Character_Record.UiNameplate()`. | **Reference only.** No Project E3 tweak payload is copied. | Native record permission is read by Biology nameplate code. | Hidden/disabled/alternative identities stay protected. |
| Project E3 mappin/UI tweak files | Historical profile/icon/clamping changes. | Native mappin records/profiles. | **Reference only.** Biology does not import Project E3 TweakDB authority. | Native minimap host styling only. | Navigation semantics unchanged. |
| `r6/tweaks/.../ui/choice_caption/choice_ui_icon.yaml` | Dialogue/interaction choice-icon presentation. | Native choice/icon systems. | **Out of clarified scope.** | None. | Native. |
| `cyberpunk/hud/scanner/scanner_border.reds` plus scanner/quickhack/focus resources in `basegame_3e_demo_hud.archive` | Old E3 scanner/focus composition. | Current native Cyberpunk scanner, quickhack list, RAM, scan-details and target highlighting. | **Hard preserve native/current. Never reproduce.** The attended scanner screenshot is an explicit PASS. | **No Biology scanner hook/resource.** | Modern scanner/quickhack remains current retail Cyberpunk with E3 ON and OFF. |
| `archive/pc/mod/basegame_3e_demo_hud.archive` | Historical archive-backed HUD resources across many systems. | Current native game GUI resources. | **Reference only; forbidden from Biology package.** | No copied archive/assets. | Player artifact contains no Project E3 archive/runtime content. |

## Nameplate knowledge model

Biology does not maintain a second NPC identity database.

Identity precedence is:

1. **Native focus/nameplate identity already supplied in `NPCNextToTheCrosshair.name` wins.**
2. If that is empty and the target is an ordinary public crowd identity whose native `UiNameplate()` record permits a name, Biology may use `GameObject.GetDisplayName()` for the baseline ambient E3 nameplate.
3. Authored hidden names, alternative identities, `hide_nametag`, dynamic `Puppet.HideNameplate`, disabled nameplate records and quest-specific identity policy are not overridden by the generic crowd fallback.
4. If scanning later causes native focus/nameplate data to become richer, that native supplied value automatically returns to step 1 and enriches the ordinary post-scan nameplate without Biology storing a second identity state.

Thus baseline ambient presentation is **not scanner-gated**, but scanner-acquired native knowledge can still enrich it.

## Modern scanner exclusion

Biology neutral-HUD/nameplate code must not hook or replace scanner/quickhack controllers or load scanner/quickhack/focus-mode resources. The historical `config/patches/realpass-modern-scanner.json` remains provenance showing which Project E3 resources were omitted during the retired integration; it is not a recipe for Biology.

## Follow-up implementation set

The clarified issue #40 implementation set is intentionally limited to:

- existing lower-left neutral E3 framing, without a health meter;
- quest/objective tracker;
- current `MinimapContainerController` navigation/minimap presentation;
- weapon/ammo roster;
- ordinary crosshair/focus styling where applicable;
- quick-slot/D-pad styling;
- ambient NPC identity/nameplate visibility and styling;
- unchanged Biology-wide barless-health policy;
- unchanged native modern scanner/quickhack presentation.

Not included: dialogue redesign, interaction-menu redesign, activity-log replacement, phone UI, old scanner behavior, Project E3 gameplay/settings systems, or broad Project E3 archive/runtime import.
