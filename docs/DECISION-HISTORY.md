# Biology decision and correction history

Status: **canonical chronology of product decisions and user corrections**
Last updated: **2026-09-15**

This document answers a different question from `AGREED-GOALS.md`:

- `AGREED-GOALS.md` says **what is true now**.
- this file says **when the direction changed, what was misunderstood, and what must not be repeated**.

If a historical note, old branch, commit message, workplan, prototype, or legacy `RealPass` name conflicts with a current locked goal, the current locked goal wins. Git history preserves old implementation context; old handoff packets do not remain in the working tree merely to preserve history.

## Required reading order for agents

1. `AGENTS.md` — parallel-work, evidence, local-game access, clean-room and patch-resilience rules.
2. `AGREED-GOALS.md` — current product requirements.
3. `docs/BIOLOGY-REDMOD-MIGRATION.md` — current REDmod/self-contained migration direction.
4. **this file** — dated corrections and superseded interpretations.
5. `docs/PARALLEL-AGENT-WORKFLOW.md` — branch/lane/handoff/merge policy.
6. the narrow current architecture document relevant to the task.
7. machine-readable manifests/tests for implementation contracts.

Do not reconstruct current product intent from old commits before reading these files.

## Timestamp convention

Times are recorded in the project owner's local timezone, **CDT / UTC-05:00**, when a durable timestamp is available. Older decisions for which only the date survived are marked **date-only** rather than inventing a time.

---

## Corrections agents must not repeat

### 2026-09-13 — date-only — RealPass is not a runtime wrapper around Dark Future or Project E3

**Earlier misunderstanding:** development had drifted toward treating Dark Future and Project E3 as runtime hosts that RealPass could patch or selectively keep executing.

**User correction:** the finished gameplay and presentation runtime must be project-owned. Dark Future, Project E3, and similar mods are research/provenance references only. Generic frameworks may remain only as plumbing when genuinely necessary.

**Do not repeat:** do not solve a feature by quietly restoring another gameplay/presentation mod as an executing dependency. Re-derive the needed behavior from native Cyberpunk contracts and implement it in project-owned code/data.

Current authority: `AGREED-GOALS.md` G-010 through G-012.

### 2026-09-13 — date-only — internal modularity is not player-selectable simulation modularity

**Earlier misunderstanding:** a broad Mod Settings surface and per-system activation controls were treated as desirable because internal modules existed.

**User correction:** the product is one authored simulation. Development gates are useful for isolation, calibration and debugging, but players do not independently switch body, injury, combat, armor, bleeding, recovery or cyberware physiology on and off.

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

**User correction:** a broad candidate should be tested like the final product: fresh/canonical source, genuinely vanilla game directory, release-shaped package, supported install/deploy path, normal Steam launch.

**Do not repeat:** do not call an accumulated in-place developer deployment a release-like acceptance pass. A full game reinstall is periodic/structural, not required for every small iteration; baseline evidence determines whether a reused install is clean enough.

Current authority: `docs/CLEAN-ROOM-TESTING.md` and G-083.

### 2026-09-14 19:57:40 CDT — the public settings surface is intentionally tiny

Recorded by merge commit `bb70113`; provider choice was later revised by the Biology/REDmod decision below.

**Earlier misunderstanding #1:** one iteration removed/retired normal settings presence too aggressively.

**Earlier misunderstanding #2:** a later workplan over-corrected toward a feature ledger plus several presentation/accessibility toggles.

**User correction:** the normal product contains only the whole-mod enable boundary plus the E3 first-person HUD visual preference; no feature ledger, fake status rows, patch notes, diagnostics, balance values or individual simulation-authority switches.

**Later refinement:** Mod Settings itself is no longer locked. The two-setting semantics are product policy; the provider may become Biology-owned or the whole-mod enable state may move to install/deploy if that is more robust.

Current authority: G-073 and `docs/SETTINGS-ARCHITECTURE.md`.

### 2026-09-14 19:57:40 CDT — enabled actor presentation is barless

Recorded by merge commit `bb70113` after attended feedback.

**Earlier misunderstanding:** the native red player-health bar was restored as a development fallback because replacement feedback was not yet complete.

**User correction:** seeing that bar in the attended build was itself rejected. While the overhaul is enabled, traditional actor HP bars / HP-number feedback should remain suppressed where technically safe. Native actor-health presentation may return only when the whole-mod enable boundary is off.

**Do not repeat:** do not reintroduce a traditional HP bar merely because E3 visuals or Biology cues are incomplete, and do not replace it with a new percentage HP bar.

Current authority: G-033, G-074 and `docs/SETTINGS-ARCHITECTURE.md`.

### 2026-09-14 19:57:40 CDT — removing the external Project E3 runtime did not mean abandoning the E3 visual target

Recorded by merge commit `bb70113`.

**Earlier misunderstanding:** “Project E3 executing HUD is gone” was interpreted as though the desired E3 look itself was no longer a product target.

**User correction:** the project should still reproduce the recognizable red E3-era first-person HUD language and E3-inspired NPC nameplates. The finished implementation must be project-owned and standalone, while the **modern scanner/quickhack UI remains authoritative**.

**Do not repeat:** do not restore the old E3 scanner, and do not claim the full E3 HUD is complete merely because the toggle or nameplate seam exists.

Current authority: G-070 through G-074 and `docs/E3-PRESENTATION.md`.

### 2026-09-14 19:59:08 CDT — “quiet when healthy” does not mean Biology disappears

Recorded by commit `17a2a14`; integrated into main at **20:24:58 CDT** by merge commit `9e05e2c`.

**Earlier misunderstanding:** the instruction to keep healthy/irrelevant state visually quiet was implemented/interpreted as permission for healthy state to hide the Biology surface or make normal body-system nodes unavailable.

**User correction:** Biology is always available for inspection. Supported nodes remain selectable when normal. The healthy overview is terse — `STABLE` — while exact values remain available only through deliberate drill-down.

**Do not repeat:** do not turn “quiet overview” into “uninspectable healthy body,” and do not turn persistent inspectability into an always-visible meter wall.

Current authority: `docs/BIOLOGY-UI.md`, G-045 and G-066.

### 2026-09-14 20:36 CDT — instruction sprawl itself is now treated as a project risk

**User correction:** outdated handoff packets and superseded instruction files were making it too easy for agents to follow an obsolete direction.

**Current rule:** current product intent lives in a small canonical set. Superseded workplans/status packets are removed from the working tree rather than left beside current instructions. History remains recoverable from Git. New user corrections are recorded here with a timestamp and linked to the current goal/architecture they changed.

### 2026-09-14 22:03 CDT — official REDmod should be the default route, but stability outranks ideology

**Earlier architecture:** the current owned runtime was trending toward a game-root-shaped package that bundled redscript + RED4ext + ArchiveXL + Mod Settings as generic plumbing.

**User direction:** investigate whether the product can rely primarily on CDPR's official REDmod route so it is as self-contained, patch-resilient and drop-in as practical.

**Clarification accepted in the same discussion:** REDmod should be the preferred route where it cleanly owns the behavior, but official whole-file `.script` replacement can be **more** brittle than a narrow additive/wrapper seam. Do not force every feature through REDmod merely to call the result “official.”

**Current rule:** classify every current runtime seam. Use vanilla/REDmod first; keep redscript or a native extension only when it demonstrably reduces the compatibility surface or provides capability REDmod cannot. Historical framework dependencies have no entitlement to survive.

**Do not repeat:** do not treat REDmod-first as “REDmod-only,” and do not preserve RED4ext/ArchiveXL/Mod Settings merely because older RealPass builds already use them.

Current authority: G-013 through G-016 and `docs/BIOLOGY-REDMOD-MIGRATION.md`.

### 2026-09-14 — date-only — the product is named Biology, and that concept owns the whole overhaul

**Earlier framing:** “RealPass” described a broad realism pass, while “Biology” was primarily the body-menu concept.

**User correction:** the entire mod should become **Biology**. The name is not narrow: the body concept naturally reaches food, combat, clothing/armor, cyberware, treatment and other physical systems that determine what happens to V.

**Do not repeat:** do not treat Biology as merely one module inside a larger RealPass product, and do not use the new name as permission to add unrelated economy/weather/travel/hardship systems.

**Migration rule:** player-facing/package/new-documentation identity changes now. Repository and internal `RealPass`/`CR*` identifiers may migrate gradually; do not perform a dangerous mass rename for cosmetic consistency.

Current authority: G-001, G-005, `docs/BIOLOGY-REDMOD-MIGRATION.md`.

### 2026-09-14 — date-only — multi-agent parallel branches are the normal workflow for large separable work

**User direction:** because 2–3 agents can often work on the repository at once, large undertakings should be split across separate branches when independent workstreams exist, then merged to `main` and tested together.

**Current rule:** agents must proactively look for safe parallel lanes. If a large task can be split, the current agent should say so, keep one lane, and provide copy/paste-ready handoffs for other threads with branch/base/scope/deliverables/acceptance/merge dependencies.

**Do not repeat:** do not silently serialize a large project when meaningful safe parallelism exists; equally, do not create competing branches that repeatedly edit the same unresolved core implementation simply to maximize agent count.

Current authority: G-093, `AGENTS.md`, `docs/PARALLEL-AGENT-WORKFLOW.md`.

### 2026-09-15 — date-only — Project E3 scope is the neutral persistent HUD plus nameplates, not a broad UI port

**Earlier misunderstanding:** treating the supplied Project E3 component inventory as a feature checklist risked expanding the Biology presentation lane into dialogue choices, interaction menus, activity-log replacement, phone UI, the old scanner, and other contextual Project E3 systems.

**User correction:** Biology is borrowing only the recognizable red/minimal **neutral first-person HUD** and **NPC nameplates**. The neutral HUD explicitly includes the top-right quest/objective tracker because it is present through ordinary gameplay, along with navigation/minimap, weapon/ammo, quick-slot/D-pad, applicable ordinary crosshair/focus, and Biology's existing lower-left treatment. The modern scanner/quickhack UI remains authoritative.

**Do not repeat:** do not infer implementation scope from the breadth of the Project E3 archive. Its complete inventory is archaeology/reference evidence, not a porting backlog. Do not add dialogue, interaction, activity-log, phone, or old-scanner behavior under the E3 presentation toggle unless the user separately asks for those systems later.

Current authority: `docs/E3-PRESENTATION.md`, `docs/E3-COMPONENT-MAPPING.md`, and issue #40.

### 2026-09-15 — date-only — local operator commands must self-bootstrap and return evidence files

**Earlier misunderstanding:** local instructions assumed a durable checkout such as `C:\Games\CyberpunkRealism`, and diagnostic failures were commonly handed back by asking the user to copy/paste large PowerShell transcripts into chat.

**User correction:** there is no permanent local repository path. Before any repo-dependent local command, inspect `C:\Games` for an existing `natanai/cprealpass` checkout; if none exists, create a uniquely signed clone automatically. Branch-specific audits/tests should use their own uniquely signed disposable checkout/worktree. Local evidence commands should always generate a plain-text `.txt` report that the user attaches back to the owning ChatGPT thread instead of pasting terminal output.

**Do not repeat:** do not recreate the retired `C:\Games\CyberpunkRealism` convention, do not make the user manually prepare a repo before a routine evidence command, and do not make pasted console transcripts the normal evidence-return path.

Current authority: `docs/LOCAL-OPERATOR-COMMANDS.md`, `tools/Audit-GameContracts.ps1`, and the local-operator/game-contract CI tests.

---

## Current product snapshot

This section is intentionally short. The detailed requirements remain in `AGREED-GOALS.md`.

- **Biology** is one authored physical/physiological overhaul, not a difficulty-mod bundle.
- Executing gameplay/presentation behavior is Biology-owned; source mods are reference only.
- Biology is the organizing concept for body/needs, injury, combat consequences, protection/clothing/armor, treatment/recovery and relevant cyberware interaction.
- Native Cyberpunk identity and semantic systems are preferred where they can carry the intended behavior.
- Official REDmod is the preferred packaging/runtime route where robust; narrower wrappers may remain when whole-file REDmod replacement would increase fragility.
- The preferred final identity is one self-contained `mods/Biology` package plus only unavoidable explicitly justified framework payload.
- Historical dependency stacks are being audited down rather than assumed permanent.
- Backpack owns possessions; Biology owns body state; Cyberware is installed equipment inside the shared body/anatomy experience.
- Biology is persistently inspectable, terse at overview depth, exact only on deliberate drill-down.
- Combat is causal and regional/material-aware, not level/HP-sponge driven.
- MaxDoc remains MaxDoc and acts as analgesia rather than magical wound repair.
- Traditional actor HP presentation is hidden while Biology is enabled.
- Public preferences remain minimal; Mod Settings itself is no longer a required provider.
- Biology targets an owned red E3-inspired neutral persistent first-person HUD/nameplate language while preserving the modern scanner.
- Vanilla Outfits are being reinterpreted as physical equipment loadouts, not a separate cosmetic protection authority.
- Broad acceptance is release-shaped and launched normally through Steam; milestone clean-room reinstalls are periodic/structural rather than required every iteration.
- Direct installed-game evidence outranks community examples for foundational native/REDmod contracts when a targeted local probe is practical.
- Local repo paths are disposable/discovered at runtime; local evidence is returned as generated `.txt` reports rather than pasted terminal logs.
- Patch-sensitive logic belongs in small explicit compatibility seams; the simulation core should survive ordinary game patches unchanged.
- Large separable work should use parallel branches/agents and converge in `main` before combined attended testing.

## Maintenance rule

When the user changes, narrows, reverses or corrects a product decision:

1. update `AGREED-GOALS.md` if the current requirement changed;
2. append a timestamped entry here describing both the superseded interpretation and the correction;
3. update the affected focused architecture doc and relevant contract/test in the same batch;
4. remove any obsolete active workplan/instruction packet that now contradicts the canonical set;
5. when the work is large and separable, provide parallel branch handoffs under `docs/PARALLEL-AGENT-WORKFLOW.md`;
6. do not erase Git history merely to make the current tree clean.