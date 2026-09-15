# Biology — CURRENT ROADMAP

**This file is the active-work entry point.**

Use it together with current GitHub issues/PRs. Dated baseline documents and merged worker handoffs are evidence/history, not the source of current branch assignments.

Before implementation work, read:

1. `AGENTS.md`
2. `AGREED-GOALS.md`
3. `docs/ACTIVE-REDMOD-ROADMAP.md`
4. `docs/BIOLOGY-REDMOD-MIGRATION.md`
5. `docs/PARALLEL-AGENT-WORKFLOW.md`
6. `docs/INTEGRATION-ORCHESTRATOR.md`
7. `docs/LOCAL-OPERATOR-COMMANDS.md` before asking the user to run local commands
8. the latest relevant file under `docs/test-runs/`
9. current open GitHub issues/PRs

## Where the project is now

The original three REDmod migration lanes have already been integrated. Do **not** restart work on their merged branches merely because older docs mention them.

The first integrated REDmod-first attended artifact was built from:

`8cf045664b5e4d8b4b014edfc98bf2f8eb270ba5`

Artifact:

`biology-integrated-20260915-061136-8cf045664b5e.zip`

SHA-256:

`42BACC73173EB95D84F3278593CD06DDAF665AA714F4C692DB03D553B91557CC`

Cyberpunk version: `2.31`

The package built and exact-compiled successfully. Official REDmod later recognized `Biology` and completed a real five-stage deployment after the deploy helper was repaired to reject false-positive root handling.

The attended in-game run then exposed the current work below.

## Active follow-up lanes

### #39 — Biology UI shell / native drill-down behavior

Branch:

`agent/biology-ui-attended-followup`

Owns:

- reuse of the native Cyberware anatomy/detail interaction grammar instead of a parallel overlay;
- proper Biology drill-down Back/Cancel behavior;
- hiding overview-only labels during detail mode;
- readable/discoverable `BIOLOGY | CYBERWARE` selector;
- blocking Biology/Cyberware mode switching while either side is drilled down;
- preventing Biology body/skeleton visuals from leaking into Cyberware;
- contextual Biology actions/items only through authoritative inventory/treatment paths.

Does **not** own the missing body runtime authority itself; that is #41.

### #40 — E3 first-person HUD and ambient NPC nameplates

Branch:

`agent/presentation-attended-followup`

Owns:

- making E3 ON visibly transform the ordinary first-person HUD, not merely add one red widget;
- quest/objective presentation, minimap/compass framing, weapon/ammo, interactions/prompts, crosshair/focus and other materially important HUD areas identified by the preserved Project E3 reference inventory;
- ambient ordinary-look/focus NPC identity/nameplates;
- police/combatant nameplate completion beyond the current narrow red strip;
- scan-acquired information enriching native-authority nameplates where appropriate;
- preserving the modern scanner/quickhack UI;
- durable mapping from Project E3 reference responsibilities to current 2.31 native seams and Biology-owned implementation.

Project E3 is reference/provenance only and must not execute or ship as a Biology dependency.

### #41 — body runtime authority missing in live Biology session

Branch:

`agent/body-runtime-attended-followup`

Owns the attended live failure:

`[ BIOLOGY ERROR ] BODY RUNTIME SYSTEM MISSING`

It must determine whether the authority is unregistered, uninitialized, unavailable in the current GameInstance/menu context, transiently unavailable, disabled by a gate, omitted from the package route, or otherwise broken.

No UI lane may hide this failure or manufacture fake healthy state.

### #44 — player disable / hard uninstall architecture

Branch:

`agent/player-uninstall-vanilla-toggle`

Draft PR: `#45`

Owns the release requirement that normal players should not need to reinstall Cyberpunk to remove Biology.

Target states:

1. REDlauncher `Enable mods` ON → Biology active.
2. REDlauncher `Enable mods` OFF → Biology behavior inactive / convenient vanilla-play mode.
3. `Uninstall Biology.exe` → safe hard removal of manifest-proven Biology-owned files without PowerShell, Git, Vortex or deleting saves.

Changed/shared files must be retained and reported instead of guessed about.

## Parent integration/orchestration thread

One long-lived parent thread coordinates worker PRs and attended evidence. It should not become a fourth broad feature lane.

The parent owns:

- canonical-main awareness;
- PR/CI/scope review and merge order;
- one integrated release-shaped test candidate;
- durable test records under `docs/test-runs/`;
- finding routing back to the correct worker/new follow-up/integration issue;
- standardized local-test handoffs.

Copy/paste parent startup packet:

- `docs/handoffs/PARENT-INTEGRATION.md`

## Current integration cycle

```text
current follow-up workers
        -> PR / CI / overlap review
        -> parent-selected merge order
        -> canonical main
        -> one release-shaped Biology candidate
        -> attended local test
        -> durable test record
        -> route remaining findings
```

Do not layer multiple worker branches into the user's game installation for convenience.

## Current attended facts to preserve

The latest attended run established all of the following:

- official REDmod package recognition/deployment works when invoked with the corrected explicit-root helper;
- the Biology outer destination renders and the anatomy screen can be entered;
- the live body screen currently reports `BODY RUNTIME SYSTEM MISSING`;
- Biology drill-down leaves overview labels behind and lacks a usable Back path;
- switching from a Biology drill-down directly into Cyberware can leave the Biology body presentation stuck;
- native Cyberware itself demonstrates the preferred design: while drilled down, cross-mode switching is unavailable until the user backs out;
- the native Cyberware detail shell includes a focused region, top A/D body-part strip, item/content region and normal back-stack behavior that Biology should reuse;
- with E3 ON, a random civilian ordinary look/focus currently shows no E3 nameplate;
- with E3 ON, police currently show only a narrow red strip rather than the intended complete identity treatment;
- the ordinary quest/objective/minimap/weapon/prompt HUD still reads overwhelmingly modern/retail with E3 ON;
- the modern scanner/quickhack UI remains intact and must stay native/current.

Those are direct attended facts. Source tests may prevent regressions but cannot convert them into live acceptance.

## Historical evidence

The original pre-REDmod clean-room evidence remains intentionally available in:

- `docs/PRE-REDMOD-LIVE-BASELINE-2026-09-15.md`

The integrated REDmod milestone/deployment record lives under:

- `docs/test-runs/`

Historical records may contain old branch names, old paths, old player-facing labels or superseded expectations because they document what actually happened at that time. Do not copy those details back into active instructions without revalidating them.
