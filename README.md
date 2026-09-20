# Biology

**Biology** is a Cyberpunk 2077 + Phantom Liberty systemic body/physiology overhaul in development. It starts from the vanilla game and replaces selected mechanics with project-original physical and physiological systems while preserving CDPR names, item identities, screens, animations, inventory/equipment authority, and interaction language wherever those remain useful.

The repository is still named `cprealpass`, and some internal identifiers remain `RealPass` / `CR*`. Those internal names are migration residue, not the player-facing product identity. Do not perform a risky mass rename merely for cosmetics.

Biology is intended to be one authored simulation, not a repackaged gameplay-mod stack and not a menu of unrelated difficulty toggles.

## Read this first

Use current files and live GitHub issues/PRs to determine active work. Do not infer the present project state from dated baseline documents or merged worker handoffs.

1. [`AGENTS.md`](AGENTS.md) — mandatory agent workflow, evidence, local-command and attended-test rules.
2. [`ROADMAP.md`](ROADMAP.md) — **current active work and follow-up lanes**.
3. [`AGREED-GOALS.md`](AGREED-GOALS.md) — canonical product intent.
4. [`docs/ACTIVE-REDMOD-ROADMAP.md`](docs/ACTIVE-REDMOD-ROADMAP.md) — current attended-follow-up ledger and acceptance gates.
5. [`docs/BIOLOGY-REDMOD-MIGRATION.md`](docs/BIOLOGY-REDMOD-MIGRATION.md) — current REDmod-first architecture and dependency-routing policy.
6. [`docs/INTEGRATION-ORCHESTRATOR.md`](docs/INTEGRATION-ORCHESTRATOR.md) — parent merge/test/evidence-routing policy.
7. [`docs/LOCAL-OPERATOR-COMMANDS.md`](docs/LOCAL-OPERATOR-COMMANDS.md) — canonical user-run local command surface.

Dated files under `docs/test-runs/` and the pre-REDmod baseline are evidence records. They are not active work instructions unless a current document explicitly points to a fact from them.

## Current milestone state

The first integrated REDmod-first milestone has progressed beyond the original three migration branches.

The exact attended artifact built from `8cf045664b5e4d8b4b014edfc98bf2f8eb270ba5`:

- exact-compiled and packaged successfully;
- installed into a clean Cyberpunk 2077 2.31 game;
- was recognized by official REDmod as `Biology`;
- completed a real five-stage REDmod deployment through the corrected explicit-root helper;
- launched into attended testing.

That attended test then exposed the current follow-up work:

- Biology menu shell/drill-down/navigation still does not reuse the native Cyberware interaction grammar cleanly;
- Biology drill-down lacks a proper Back path and can leak Biology body visuals when switching modes from an invalid drilled-down state;
- the body screen reports `[ BIOLOGY ERROR ] BODY RUNTIME SYSTEM MISSING` in a live session;
- E3 presentation ON still leaves most of the ordinary first-person HUD in the modern retail layout;
- civilians receive no ambient E3-style nameplate on ordinary look/focus, while police currently show only a narrow red strip;
- the modern scanner/quickhack UI remains intact and is a preserve requirement;
- player-friendly disable/hard-uninstall behavior is now an explicit release requirement.

See `ROADMAP.md` and the open issues rather than the original merged branch handoffs.

## Current active lanes

The parent integration thread currently routes substantial follow-up work to dedicated branches/issues. At the time of this milestone the important lanes are:

- **#39** `agent/biology-ui-attended-followup` — Biology shell reuse, native drill-down/back behavior, selector visibility and mode-state cleanup;
- **#40** `agent/presentation-attended-followup` — complete E3-inspired first-person HUD/nameplate follow-up, including Project E3 reference archaeology without runtime dependency;
- **#41** `agent/body-runtime-attended-followup` — authoritative body runtime registration/lifecycle failure;
- **#44** `agent/player-uninstall-vanilla-toggle` — REDlauncher-off vanilla-play behavior and a self-contained Biology uninstaller.

Branches and PR numbers change. `ROADMAP.md` plus current GitHub issues/PRs are authoritative for live coordination.

## Core product rules

- Executing Biology gameplay/presentation behavior must be **Biology-owned**. Dark Future and Project E3 are research/provenance references only.
- **Backpack = possessions. Biology = embodied state. Cyberware = installed equipment.**
- Biology stays inspectable while healthy. Exact body values belong behind deliberate drill-down rather than a permanent meter wall.
- Combat is causal and physical: projectile/ammunition → region → encountered protection/material → penetration/impact → tissue/chrome injury → physiology → treatment/recovery.
- Vanilla item names/identities should be preserved unless a later explicit decision changes them.
- The modern Cyberpunk scanner/quickhack experience remains authoritative.
- Traditional actor HP bars/numbers remain suppressed while Biology is enabled where technically safe.
- E3-inspired HUD/nameplate presentation is Biology-owned and optional presentation; health-bar suppression is not proof that the E3 presentation is working.
- REDmod is the preferred package/deployment route where robust, with narrow Biology-owned wrappers/additive seams allowed when they are materially safer than whole-file replacement.

Weather overhaul, economy overhaul, artificial scarcity, generic hardship encounters, travel restrictions, and unrelated difficulty systems remain outside the Biology product boundary unless a later explicit decision changes that.

## Release direction

The preferred player-facing package remains centered on one recognizable REDmod identity:

```text
Cyberpunk 2077/
└── mods/
    └── Biology/
        ├── info.json
        └── ...Biology-owned REDmod content
```

Unavoidable supplemental framework files may live outside `mods/Biology` only when an actual current feature requires them. Every such dependency must be pinned, justified, owned in the package manifest and removable safely.

The desired player experience is:

1. copy/install one Biology release;
2. use the normal REDlauncher/Steam mod-enable path;
3. launch normally through Steam;
4. turn REDmod off for a convenient vanilla-play mode once the activation audit proves all Biology behavior yields cleanly;
5. use a self-contained `Uninstall Biology.exe` for hard removal rather than reinstalling the whole game.

See `docs/RELEASE-ARCHITECTURE.md` and issue #44 for implementation status.

## Local game evidence and commands

The supported game installation path currently used for direct evidence is:

```text
C:\Games\Steam\steamapps\common\Cyberpunk 2077
```

Repository/workspace paths are **not stable**. Attended workspaces are disposable and milestone-specific.

Before asking the user to run PowerShell/CMD, read [`docs/LOCAL-OPERATOR-COMMANDS.md`](docs/LOCAL-OPERATOR-COMMANDS.md). Do not reconstruct an old absolute checkout path or paste the internals of a repository tool into chat when a canonical command exists.

Foundational game-internal claims should prefer direct evidence from the supported 2.31 installation when practical. See [`docs/LOCAL-GAME-REFERENCE.md`](docs/LOCAL-GAME-REFERENCE.md) and [`docs/PATCH-RESILIENCE.md`](docs/PATCH-RESILIENCE.md).

## Testing

Attended testing distinguishes:

- **ITERATION** — reuse an installation only when the prior Biology package can be safely accounted for under current cleanup policy;
- **MILESTONE CLEAN-ROOM** — use a Steam uninstall + residual-directory deletion + reinstall for structural/package/framework/game-patch milestones or unexplained residue.

After a genuinely fresh reinstall, the extra exhaustive whole-game hash pass is optional at the user's choice; the fast-sanity result must not be mislabeled as full baseline verification.

A full Steam reinstall is not the normal Biology uninstall mechanism. Issue #44 is establishing the player-facing disable/uninstaller path.

See [`docs/CLEAN-ROOM-TESTING.md`](docs/CLEAN-ROOM-TESTING.md).

## Repository layout

- `src/redscript` / `src/tweaks` — Biology simulation, presentation, and game-facing adapters.
- `manifest` — runtime, feature, acceptance, dependency, ownership, distribution and native-seam contracts.
- `tests` — cloud-safe models/contracts and policy guards.
- `tools` — dependency acquisition, exact compilation, game-reference audits, packaging and developer/operator utilities.
- `reference/cyberpunk` — redistribution-safe metadata derived from the supported installed game.
- `docs` — canonical architecture/workflow docs plus dated attended evidence.
- `LICENSES` / `THIRD_PARTY.md` — dependency and historical-reference provenance.

Downloaded frameworks, proprietary Cyberpunk assets, local extractions, Project E3 reference payloads, generated staging/reports, deployment state and saves stay outside the public repository unless represented only by redistribution-safe derived metadata.
