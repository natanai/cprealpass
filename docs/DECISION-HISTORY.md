# RealPass decision and correction history

Status: **canonical chronology of product decisions and user corrections**
Last updated: **2026-09-14 20:36 CDT (UTC-05:00)**

This document answers a different question from `AGREED-GOALS.md`:

- `AGREED-GOALS.md` says **what is true now**.
- this file says **when the direction changed, what was misunderstood, and what must not be repeated**.

If a historical note, old branch, commit message, workplan, or prototype conflicts with a current locked goal, the current locked goal wins. Git history preserves old implementation context; old handoff packets do not remain in the working tree merely to preserve history.

## Required reading order for agents

1. `AGENTS.md` — evidence, local-game access, clean-room and patch-resilience rules.
2. `AGREED-GOALS.md` — current product requirements.
3. **this file** — dated corrections and superseded interpretations.
4. the narrow current architecture document relevant to the task, such as `docs/BIOLOGY-UI.md`, `docs/SETTINGS-ARCHITECTURE.md`, `docs/E3-PRESENTATION.md`, `docs/PATCH-RESILIENCE.md`, or `docs/RELEASE-ARCHITECTURE.md`.
5. machine-readable manifests/tests for implementation contracts.

Do not reconstruct current product intent from old commits before reading these files.

## Timestamp convention

Times are recorded in the project owner's local timezone, **CDT / UTC-05:00**, when a durable commit timestamp or current conversation timestamp is available. Older decisions for which only the date survived in the durable worklog are marked **date-only** rather than inventing a time.

---

## Corrections agents must not repeat

### 2026-09-13 — date-only — RealPass is not a runtime wrapper around Dark Future or Project E3

**Earlier misunderstanding:** development had drifted toward treating Dark Future and Project E3 as runtime hosts that RealPass could patch or selectively keep executing.

**User correction:** the finished gameplay and presentation runtime must be **RealPass-owned**. Dark Future, Project E3, and similar mods are research/provenance references only. Generic frameworks may remain only as plumbing when genuinely necessary.

**Do not repeat:** do not solve a feature by quietly restoring another gameplay/presentation mod as an executing dependency. Re-derive the needed behavior from native Cyberpunk contracts and implement it in RealPass-owned code/data.

Current authority: `AGREED-GOALS.md` G-010 through G-012.

### 2026-09-13 — date-only — internal modularity is not player-selectable simulation modularity

**Earlier misunderstanding:** a broad Mod Settings surface and per-system activation controls were treated as desirable because internal modules existed.

**User correction:** RealPass is one authored simulation. Development gates are useful for isolation, calibration and debugging, but players do not independently switch body, injury, combat, armor, bleeding, recovery or cyberware physiology on and off.

**Do not repeat:** do not expose internal architecture as a gameplay settings menu or add balance sliders because the corresponding internal variable exists.

Current authority: G-002 and `docs/SETTINGS-ARCHITECTURE.md`.

### 2026-09-14 16:38:58 CDT — Biology, not Conditions or Backpack, owns bodily state

Recorded by the Biology architecture commit (`0c32e4d`).

**Earlier misunderstanding:** bodily information was split into Backpack-style meters and a `CYBERWARE | CONDITION` concept in which Conditions effectively competed with Cyberware as the body screen.

**User correction:** **Backpack = possessions; Biology = embodied state; Cyberware = installed equipment.** Biology is the parent body/anatomy destination. Conditions are a subsection of Biology. Cyberware remains available inside the shared body shell as its equipment mode.

**Do not repeat:** do not put hunger, thirst, pain, elimination, injury severity or general physiology meters back into Backpack, and do not resurrect `Condition` as the top-level body UI.

Current authority: G-043 through G-049, G-063 through G-066, `docs/BIOLOGY-UI.md`.

### 2026-09-14 18:48:51 CDT — direct game evidence is available through the user

Recorded by commit `da91316`; strengthened at **19:23:01 CDT** by `f5ed895`.

**Earlier failure mode:** agents searched old public scripts, guides, or community examples for facts that could be established more authoritatively from the user's installed Cyberpunk build.

**User correction:** when a foundational decision depends on a real class, method, event, TweakDB record, resource path, controller, state machine or archive fact, agents may and should ask the user to run a targeted read-only command against the installed game.

**Do not repeat:** do not make web evidence the foundation of a native seam merely because remote agents cannot see `C:\Games\Steam\steamapps\common\Cyberpunk 2077` directly. Read `reference/cyberpunk/` first; ask for a narrow local probe when it can remove uncertainty.

Current authority: `AGENTS.md`, `docs/LOCAL-GAME-REFERENCE.md`, `docs/PATCH-RESILIENCE.md`.

### 2026-09-14 19:36:58 CDT — broad acceptance must be clean-room and release-shaped

Recorded by commit `c7787a5` and merged to main shortly afterward.

**Earlier misunderstanding:** accumulated developer installs plus in-place upgrade/deploy tooling were being treated as the canonical broad acceptance environment.

**User correction:** a broad candidate should be tested like the final product: fresh/canonical source, genuinely vanilla game directory, game-root-shaped RealPass package, ordinary folder merge, normal Steam launch.

**Do not repeat:** do not call an in-place `Prepare-OwnedSession.ps1 -Deploy` run a broad release-like acceptance pass. It remains useful for narrow iteration. The clean-room package workflow is the broad acceptance authority.

Current authority: `docs/CLEAN-ROOM-TESTING.md` and `tools/Build-CleanRoomTestPackage.ps1`.

### 2026-09-14 19:57:40 CDT — the Mod Settings page is exactly two booleans

Recorded by merge commit `bb70113`.

**Earlier misunderstanding #1:** one iteration removed/retired normal Mod Settings presence too aggressively.

**Earlier misunderstanding #2:** a later workplan over-corrected toward a feature ledger plus several presentation/accessibility toggles.

**User correction:** the normal RealPass page contains exactly:

1. `Enable RealPass` — global all-or-nothing master switch, default On;
2. `E3 first-person HUD visuals` — presentation-only preference, default On.

No feature ledger, fake status rows, patch notes, diagnostics, balance values or individual simulation-authority switches belong there.

**Do not repeat:** do not infer additional settings from internal configuration values or old workplans.

Current authority: G-073 and `docs/SETTINGS-ARCHITECTURE.md`.

### 2026-09-14 19:57:40 CDT — RealPass-on actor presentation is barless

Recorded by merge commit `bb70113` after attended feedback.

**Earlier misunderstanding:** the native red player-health bar was restored as a development fallback because replacement feedback was not yet complete.

**User correction:** seeing that bar in the attended build was itself rejected. While **Enable RealPass = On**, traditional actor HP bars / HP-number feedback should remain suppressed where technically safe. Native actor-health presentation may return only when the **global RealPass master switch is Off**.

**Do not repeat:** do not reintroduce a traditional HP bar merely because E3 visuals or Biology cues are still incomplete, and do not replace it with a new RealPass percentage HP bar.

Current authority: G-033, G-074 and `docs/SETTINGS-ARCHITECTURE.md`.

### 2026-09-14 19:57:40 CDT — removing the external Project E3 runtime did not mean abandoning the E3 visual target

Recorded by merge commit `bb70113`.

**Earlier misunderstanding:** “Project E3 executing HUD is gone” was interpreted as though the desired E3 look itself was no longer a product target.

**User correction:** RealPass should still reproduce the recognizable red E3-era first-person HUD language and E3-inspired NPC nameplates. The finished implementation must simply be **RealPass-owned and standalone**, while the **modern scanner/quickhack UI remains authoritative**.

**Do not repeat:** do not restore the old E3 scanner, and do not claim the full E3 HUD is complete merely because the toggle or nameplate seam exists.

Current authority: G-070 through G-073 and `docs/E3-PRESENTATION.md`.

### 2026-09-14 19:59:08 CDT — “quiet when healthy” does not mean Biology disappears

Recorded by commit `17a2a14`; integrated into main at **20:24:58 CDT** by merge commit `9e05e2c`.

**Earlier misunderstanding:** the instruction to keep healthy/irrelevant state visually quiet was implemented/interpreted as permission for healthy state to hide the Biology surface or make normal body-system nodes unavailable.

**User correction:** Biology is always available for inspection. Supported nodes remain selectable when normal. The healthy overview is terse — `STABLE` — while exact values remain available only through deliberate drill-down.

**Do not repeat:** do not turn “quiet overview” into “uninspectable healthy body,” and do not turn persistent inspectability into an always-visible meter wall.

Current authority: `docs/BIOLOGY-UI.md`. G-045/G-066 should be read in that light.

### 2026-09-14 20:36 CDT — instruction sprawl itself is now treated as a project risk

**User correction:** outdated handoff packets and superseded instruction files were making it too easy for agents to follow an obsolete direction.

**Current rule:** current product intent lives in a small canonical set. Superseded workplans/status packets are removed from the working tree rather than left beside current instructions. History remains recoverable from Git. New user corrections are recorded here with a timestamp and linked to the current goal/architecture they changed.

---

## Current product snapshot

This section is intentionally short. The detailed requirements remain in `AGREED-GOALS.md`.

- RealPass is one authored physical/physiological realism overhaul, not a difficulty-mod bundle.
- Executing gameplay/presentation behavior is RealPass-owned; source mods are reference only.
- Native Cyberpunk identity and semantic systems are preferred where they can carry the intended behavior.
- Backpack owns possessions; Biology owns body state; Cyberware is installed equipment inside the shared body/anatomy experience.
- Biology is persistently inspectable, terse at overview depth, exact only on deliberate drill-down.
- Combat is causal and regional/material-aware, not level/HP-sponge driven.
- MaxDoc remains MaxDoc and acts as analgesia rather than magical wound repair.
- Traditional actor HP presentation is hidden while RealPass is enabled.
- Mod Settings exposes only the RealPass master switch and the E3 visual preference.
- RealPass targets an owned red E3-inspired first-person HUD/nameplate language while preserving the modern scanner.
- Vanilla Outfits are being reinterpreted as physical equipment loadouts, not a separate cosmetic protection authority.
- Broad acceptance is clean-room, release-shaped and launched normally through Steam.
- Direct installed-game evidence outranks community examples for foundational native contracts when a targeted local probe is practical.
- Patch-sensitive logic belongs in small explicit compatibility seams; the simulation core should survive ordinary game patches unchanged.

## Maintenance rule

When the user changes, narrows, reverses or corrects a product decision:

1. update `AGREED-GOALS.md` if the current requirement changed;
2. append a timestamped entry here describing both the superseded interpretation and the correction;
3. update the affected focused architecture doc and machine-readable contract/test in the same batch;
4. remove any obsolete active workplan/instruction packet that now contradicts the canonical set;
5. do not erase Git history merely to make the current tree clean.
