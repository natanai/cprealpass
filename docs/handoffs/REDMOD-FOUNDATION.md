# Handoff — REDmod foundation / package / dependency lane

Use this as the source-of-truth handoff for a new agent thread.

## Goal

Build the official REDmod-first foundation for **Biology** without redesigning gameplay or UI semantics. The lane should establish the package/deploy/dependency architecture that later integrated runtime work can plug into.

## Repository / branch

- Repository: `natanai/cprealpass`
- Create branch: `agent/redmod-foundation`
- Base: current canonical `main` **including** the pre-REDmod live-baseline/roadmap documentation. Record the exact starting SHA in the PR.
- Do not work directly on `main`.

## Read first

1. `AGENTS.md`
2. `AGREED-GOALS.md`
3. `docs/PRE-REDMOD-LIVE-BASELINE-2026-09-15.md`
4. `docs/ACTIVE-REDMOD-ROADMAP.md`
5. `docs/BIOLOGY-REDMOD-MIGRATION.md`
6. `docs/PARALLEL-AGENT-WORKFLOW.md`
7. `docs/CLEAN-ROOM-TESTING.md`
8. `docs/RELEASE-ARCHITECTURE.md`
9. current package/dependency manifests and tests

## Attended evidence you must preserve

The pre-refactor candidate at `ec8ba06451c3cbacabfad24f1479e1537147d0c9` exact-compiled, packaged, launched, and exposed some Biology/RealPass UI, but it still uses the transitional root-shaped redscript/RED4ext/ArchiveXL/Mod Settings stack.

The REDmod refactor exists to reduce/justify that stack, not merely repackage it unchanged.

## Owned scope

You own:

- `mods/Biology` REDmod package skeleton and identity;
- official REDmod build/deploy/enable/load proof;
- REDmod-first release artifact shape;
- package ownership/uninstall model;
- dependency inventory and removal/retention rationale;
- runtime-seam classification **at package/dependency level**;
- load-order/overlap evidence where REDmod can deterministically control precedence;
- clean-room/package tooling needed to build/test this architecture;
- migration of content that is unambiguously REDMOD-NATIVE and does not conflict with another lane's owned source.

Issue IDs: `PKG-01`..`PKG-07`, `DEP-01`..`DEP-06` in `docs/ACTIVE-REDMOD-ROADMAP.md`.

## Non-goals / boundaries

Do not redesign:

- body/metabolism/injury/combat equations;
- Biology screen layout/content semantics;
- E3-inspired HUD/nameplate visuals;
- Cyberware UI behavior;
- clothing/combat balance.

Do not mass-rename internal `CR*`/`RealPass` identifiers just for aesthetics.

Do not introduce a new third-party dependency without explicit evidence that vanilla + REDmod + narrow Biology-owned scripting cannot meet the requirement.

If another lane needs a dependency, make that lane provide the concrete consumer/use case before you add package plumbing.

## Required classification output

For every current runtime/package component, record one of:

- `REDMOD-NATIVE`
- `REDMOD-POSSIBLE-BUT-BRITTLE`
- `REDSCRIPT-BETTER`
- `REQUIRES-NATIVE-EXTENSION`
- `REMOVE/RETHINK`
- `UNKNOWN — NEEDS DIRECT GAME PROBE`

At minimum cover:

- redscript;
- RED4ext;
- ArchiveXL;
- Mod Settings;
- current loose script destinations;
- settings payload;
- UI/runtime assets;
- any tweaks/archives/localization;
- build/install/uninstall tooling.

Make this machine-readable where practical and cross-link the rationale in docs.

## Deliverables

Before reporting ready to merge, provide:

1. valid Biology REDmod skeleton/metadata;
2. documented official deployment/enable/Steam-launch procedure for current supported game;
3. dependency graph with feature-specific consumers;
4. removal candidates and blockers;
5. updated package/build tooling or a prototype that proves the intended path;
6. tests/contracts preventing regression to unexplained legacy payload;
7. exact direct-game probes still needed, if any;
8. PR against `main` with CI status and explicit overlap with active UI/presentation branches.

## Acceptance criteria

This lane is ready when:

- a fresh clone can construct the REDmod-first Biology package skeleton without modifying the game;
- official tooling recognizes/deploys the skeleton;
- package identity is Biology;
- every retained framework has a current feature-specific justification;
- project-original vs dependency ownership is explicit;
- install/disable/remove paths are understandable without old rollback history;
- REDmod precedence claims are based on evidence, not assumption;
- no gameplay/presentation source-mod runtime is reintroduced;
- tests/CI for this lane pass.

## Coordination

Parallel lanes:

- `agent/biology-ui-runtime` owns Biology menu/body-state behavior.
- `agent/presentation-hud-nameplates` owns E3-inspired HUD/nameplates/settings presentation behavior.

Expect to merge foundational schema/package changes first when they establish contracts those lanes need. Otherwise avoid forcing them to wait.

## Local evidence

If direct Cyberpunk/REDmod evidence would answer a question better than web searching, ask the user for **one read-only PowerShell command** that writes large output to a file. Use the tracked `reference/cyberpunk/` data first.
