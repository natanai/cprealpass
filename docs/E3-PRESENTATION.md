# Biology E3-inspired presentation target

Status: canonical visual target / implementation contract  
Last updated: 2026-09-15

## Product decision

Biology targets the red/minimal 2018/E3-inspired **neutral first-person HUD** and **NPC nameplates** while keeping Cyberpunk 2077's modern scanner/quickhack behavior.

This does **not** mean bringing Project E3 into Biology wholesale. Project E3 is design/reference material only. Biology does not execute or redistribute its scripts, archive, tweaks, settings implementation, scanner, dialogue redesign, activity-log redesign, phone UI, or other contextual systems.

## Clarified neutral-HUD scope

The neutral HUD is the persistent/default ordinary-gameplay layer that defines what the player sees most of the time:

- quest/objective tracker;
- minimap/navigation presentation;
- weapon/ammo presentation;
- ordinary crosshair/focus presentation where applicable;
- quick-slot/D-pad presentation;
- Biology's existing lower-left non-health E3 presentation;
- NPC nameplates.

The quest tracker is explicitly included because it normally occupies the top-right HUD throughout ordinary play. It should participate in the same red/minimal visual language as the other persistent HUD surfaces.

Contextual UI such as dialogue choices, interaction-menu redesign, activity-log replacement animation and phone-call presentation is outside this E3 follow-up unless the project owner later asks for it separately.

## Required player-facing result

With **Enable Biology = On** and **E3-inspired HUD + nameplates = On**:

- ordinary gameplay must read as a coherent red/minimal E3-inspired neutral HUD rather than retail Cyberpunk plus one extra red widget;
- persistent quest, navigation, weapon/ammo, quick-slot and applicable crosshair surfaces must visually belong to that same language while preserving their native information/behavior;
- relevant NPCs can receive an ambient E3-style identity/nameplate during ordinary look/focus without requiring scanner mode;
- scanner-acquired native identity may enrich the ordinary nameplate afterward;
- the modern scanner/quickhack UI remains current/native;
- traditional actor HP bars remain suppressed because that is a Biology-wide rule, not an E3 success criterion.

With E3 presentation **Off** while Biology remains enabled:

- Biology's E3-specific neutral-HUD/nameplate styling yields;
- Biology simulation remains identical;
- Biology-wide actor-healthbar suppression remains identical;
- the modern scanner remains identical.

## Attended evidence and correction

The exact REDmod-first milestone runtime artifact built from `8cf045664b5e4d8b4b014edfc98bf2f8eb270ba5` on Cyberpunk 2077 2.31 proved official Biology REDmod recognition/deployment, but presentation acceptance failed.

Observed:

- ordinary first-person gameplay still read overwhelmingly as the current retail HUD;
- the quest/objective tracker, minimap/navigation, weapon/ammo and surrounding neutral HUD remained visibly current;
- the small Biology red framing was insufficient to make E3 ON recognizable by itself;
- a random civilian looked at directly with E3 ON showed **no E3 nameplate**;
- cops/combatants with E3 ON showed only a narrow red strip, not the intended identity/nameplate presentation;
- E3 OFF removed that red strip, proving at least partial toggle gating;
- the current modern scanner/quickhack presentation remained intact and is an explicit PASS.

Do not use health-bar suppression, the narrow cop strip, or the earlier incorrect civilian-nameplate interpretation as evidence that E3 presentation succeeded.

## Nameplate knowledge boundary

Biology does not invent a second identity database.

Identity precedence is:

1. native `NPCNextToTheCrosshair.name` wins whenever the game already supplies identity;
2. if that is empty, an ordinary public civilian may use `GameObject.GetDisplayName()` only when native nameplate/scanner records permit the public name and no hidden/alternative/quest policy blocks it;
3. hidden names, alternative identities, `hide_nametag`, dynamic `HideNameplate`, disabled nameplate records and quest-specific identity policy remain protected;
4. if scanning later supplies richer native identity, that native value automatically supersedes the fallback and enriches the post-scan ordinary nameplate.

Therefore baseline ambient nameplates are not scanner-gated, but scanning may legitimately enrich them.

## Modern scanner is a hard preserve

Biology E3 presentation must not:

- hook/replace scanner or quickhack controllers;
- recreate Project E3 scanner borders;
- ship Project E3 scanner/quickhack/focus-mode resources;
- recolor or restyle the modern scanner into the old 2018 scanner.

The safest scanner implementation is deliberate absence of an override.

## Ownership / provenance

The full Project E3 component inventory and the Biology decision for each area are documented in `E3-COMPONENT-MAPPING.md` and `config/realpass-e3.json`.

The final Biology runtime uses current native 2.31 controller/data authority plus Biology-owned INK/source. It must not ship `basegame_3e_demo_hud.archive` or execute Project E3 scripts/tweaks.

## Patch-resilience rule

For each in-scope neutral-HUD element:

1. preserve the current native controller as information/interaction authority;
2. hook only the narrow lifecycle/update seam needed for presentation;
3. register every hook-bearing Biology file in `manifest/native-seams.json`;
4. avoid copied vanilla or Project E3 controller bodies when post-native styling is sufficient;
5. exact-compile the combined candidate against supported Cyberpunk 2077 2.31 before packaging.

## Attended acceptance contract

The next parent-integrated candidate should capture matched evidence from the same state/location:

- ordinary gameplay — E3 ON;
- same view — E3 OFF;
- quest/objective tracker — matched ON/OFF;
- random civilian direct look/focus — E3 ON before scanner;
- police/combatant direct focus — E3 ON;
- same relevant NPC after scanning/identity acquisition where applicable;
- modern scanner/quickhack — E3 ON;
- ordinary combat/navigation gameplay to catch stale or overlapping presentation widgets.

A reviewer must be able to identify the E3-ON ordinary-gameplay screenshot without looking at the settings screen. A tiny red Biology frame, a narrow red strip over cops, or hidden HP bars is insufficient.

## Current follow-up implementation

Issue #40's `agent/presentation-attended-followup` branch expands the owned neutral HUD across current native controller roots for quest tracking, navigation, weapon/ammo, applicable crosshair and quick-slot presentation, while keeping game data/interaction authority native. It also changes civilian public-name fallback from scanner-gated to ambient-permitted and uses the native nameplate screen-projection lifecycle so identity can actually appear during ordinary focus.

This remains **source/contract implementation pending exact local 2.31 compile and parent-coordinated attended acceptance**. Cloud CI cannot prove visual placement or in-game fidelity.
