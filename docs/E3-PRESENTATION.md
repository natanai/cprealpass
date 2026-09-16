# Biology E3-inspired presentation target

Status: canonical visual target / implementation contract  
Last updated: 2026-09-16  
Current worker: W03.2 / issue #78 (continuing issue #40)

## Product decision

Biology targets the red/minimal 2018/E3-inspired **ordinary first-person HUD** and **NPC nameplates** while keeping Cyberpunk 2077's modern scanner/quickhack behavior.

Project E3 is design/reference material only. Biology does not execute or redistribute its archive, scripts, tweaks, settings implementation, old scanner, or gameplay authority. Current installed Cyberpunk 2.31 / REDmod source is the preferred authority for native controller ownership; Project E3 tells us which presentation responsibilities materially created the historical look.

## W03.2 attended boundary

The W13 attended startup candidate at `f643bbc1c50a69d223c2cf54e9fc7f68215e33fd` proved the supported mods-ON launch regenerated the configured REDscript output and compiled all Biology REDscript on actual game startup without REDscript errors. W03.2 therefore treats the missing E3 result as a **presentation/hook behavior problem**, not as stale REDscript startup.

The same live candidate still read overwhelmingly as retail/current Cyberpunk in ordinary play: quest/objective tracker, minimap/navigation, weapon/ammo, ordinary interaction/control prompts, crosshair/focus, and surrounding HUD composition remained insufficiently transformed. Civilian ordinary-look nameplates remained absent and police/combatants did not yet have a complete ambient identity treatment.

## In-scope ordinary presentation

W03.2 owns the visually persistent or materially recurring first-person surfaces that determine whether ordinary play reads as E3-inspired:

- quest/objective tracker;
- minimap/navigation framing, while preserving current native route/mappin semantics;
- weapon/ammo presentation;
- quick-slot/D-pad presentation;
- ordinary crosshair/focus presentation across normal weapon types;
- ordinary interaction prompts where they materially dominate moment-to-moment play;
- lightweight activity-log treatment because transient retail activity text is visually recurrent;
- Biology's existing lower-left non-health E3 presentation;
- civilian and police/combatant ordinary-look NPC nameplates.

Dialogue has been audited because Project E3 changed it, but W03.2 does **not** replace the conversation-choice system: it is a contextual conversation surface with a large behavior/choice-layout footprint, not necessary to establish the ordinary neutral HUD target. Phone UI is likewise not part of this lane.

## Required player-facing result

With Biology active and **E3-inspired HUD + nameplates = On**:

- ordinary gameplay must read as a coherent red/minimal E3-inspired presentation rather than retail Cyberpunk plus one small red widget;
- quest, navigation, weapon/ammo, hotkeys, applicable crosshair/focus, ordinary prompts, recurrent activity feedback and nameplates must belong to a common visual language while native information/interaction remains authoritative;
- relevant NPCs can receive an ambient E3-style identity treatment during ordinary look/focus without requiring scanner mode;
- scanner-acquired native identity may enrich the ordinary nameplate afterward;
- the modern scanner/quickhack UI remains current/native;
- traditional actor HP bars remain suppressed because that is a Biology-wide rule, not an E3 success criterion.

With E3 presentation **Off** while Biology remains active:

- Biology-owned E3 overlay widgets yield cleanly;
- Biology does not try to reconstruct native colors by painting native roots white;
- native quest/navigation/weapon/input/interaction data and behavior are unchanged;
- Biology simulation and Biology-wide actor-healthbar suppression are unchanged;
- the modern scanner remains unchanged.

## Implementation rule: owned overlays, native authority

W03.1 relied heavily on thin red rails plus `SetTintColor` on native controller roots. Live evidence showed that was too weak visually, and root tinting was also a poor OFF contract because child widgets may carry their own styles and "white" is not proof of native restoration.

W03.2 therefore uses **Biology-owned reversible INK overlays/labels** attached to narrow current native controllers. E3 OFF hides those owned widgets rather than guessing the original state of native roots. Native controller logic runs first and remains authoritative.

The intended seams are:

- `QuestTrackerGameController` for quest/objective presentation;
- current `MinimapContainerController` for navigation/minimap framing;
- `WeaponRosterGameController` for weapon/ammo framing;
- `HotkeysWidgetController` for quick-slot/D-pad presentation;
- current `gameuiCrosshairContainerController` for cross-weapon ordinary focus framing, plus the existing Tech-Hex specialization;
- `interactionWidgetGameController` for an ordinary interaction-prompt shell without replacing InteractionChoiceHubData/timer/input logic;
- `activityLogEntryLogicController` for a lightweight per-entry red/uppercase skin without taking over queue/animation authority;
- `NameplateVisualsLogicController` plus `NpcNameplateGameController` for projected ambient identity treatment.

## Nameplate lifecycle and knowledge boundary

Biology does not invent a second NPC identity database.

Identity precedence is:

1. native `NPCNextToTheCrosshair.name` wins whenever the game already supplies identity;
2. if that is empty, an ordinary public civilian may use the entity's existing `GameObject.GetDisplayName()` when hidden/alternative/quest policy does not block it and a defined native nameplate record is not explicitly disabled;
3. Biology does **not** derive `FullDisplayName`, archetype, affiliation, scanner-only records, or another hidden identity;
4. scanning can later supply richer native `NPCNextToTheCrosshair.name`, which automatically supersedes the fallback.

W03.2 also addresses a concrete lifecycle defect in W03.1: native `NameplateVisualsLogicController.SetElementVisibility(...)` runs during `SetVisualData` and may hide the name text after earlier styling. Biology therefore reapplies its **owned projected nameplate widget after native `SetElementVisibility`**, rather than replacing native visibility logic wholesale.

## Modern scanner is a hard preserve

Biology E3 presentation must not hook or replace scanner/quickhack controllers, load Project E3 scanner resources, recreate the 2018 scanner, or recolor the current scanner into an old composition. The modern scanner/quickhack surface is a previously attended PASS and remains outside W03.2 ownership.

The generic crosshair-container seam is specifically useful because current native crosshair-container vision logic owns whether that container is visible in default vision. Biology's child frame therefore follows native visibility rather than requiring a scanner hook.

## Ownership / provenance

The full Project E3 inventory and per-area decisions are recorded in `E3-COMPONENT-MAPPING.md` and `config/realpass-e3.json`. The user-supplied Project E3 2.31.p2 source/archive may be inspected outside Git for archaeology, but none of that third-party runtime is shipped by Biology.

## Patch-resilience rule

For every W03.2 presentation seam:

1. prefer installed official REDmod decompiled source when it can establish current 2.31 class/lifecycle ownership;
2. use Project E3 only to understand visual responsibility/history;
3. keep current native gameplay/data/visibility authority unless the accepted presentation requires a narrowly proven post-native correction;
4. prefer post-native Biology-owned overlays to copied controller bodies;
5. register hook-bearing Biology files in `manifest/native-seams.json`;
6. preserve scanner/quickhack ownership by deliberate absence of scanner hooks;
7. let the parent exact-build and attend the integrated candidate before merge.

## Parent attended acceptance contract

The parent should test the integrated candidate, not this worker branch directly:

1. ordinary gameplay — E3 ON;
2. same location/view — E3 OFF;
3. quest/objective tracker — matched ON/OFF;
4. minimap/navigation plus ordinary weapon/ammo/hotkey composition;
5. at least one ordinary interaction prompt and one activity-log event;
6. random civilian direct look/focus — E3 ON before scanner;
7. police/combatant direct focus — E3 ON;
8. same relevant NPC after scanning/identity acquisition where applicable;
9. modern scanner/quickhack — E3 ON;
10. ordinary combat/navigation/interaction gameplay to catch stale or overlapping widgets.

A reviewer must be able to identify the E3-ON ordinary-gameplay screenshot without looking at the setting state. A tiny Biology frame, a narrow strip over cops, or hidden HP bars is insufficient.
