# realpass project status

Last updated: 2026-09-12
Working branch: `chatgpt-continuation`
Baseline branch tip when this status ledger was introduced: `4b9dbbeb5e0ef243900b2daec4baf800e2a4af64`

## Release target

realpass is intended to become one coherent Cyberpunk 2077 + Phantom Liberty realism mod. The target player experience is: download one release package, copy/extract it into the Cyberpunk 2077 game root (or run one equally simple installer if dependency licensing forces that route), then launch the game normally through Steam. The player should not need to understand the source mods, development staging, manifest system, or deployment receipts.

The gameplay target is physical and physiological realism rather than generalized difficulty. In-scope authorities are body/needs, injury, realistic projectile/impact behavior, physical armor/clothing coverage, relevant cyberware physiology, presentation required to communicate those systems, and diagnostics for development. Weather, economy overhauls, arbitrary scarcity, added random encounters, travel restrictions and a separate outfit/transmog system are out of scope.

## Overall completion estimate

**50% toward a first credible 1.0 release.**

This percentage is a weighted engineering estimate, not a claim that half the source is written. A subsystem receives credit only for work that advances a releasable, gameplay-validated, safely installable mod. Offline models, static contracts and compilation scaffolding without native gameplay validation remain partial credit.

| Workstream | Weight | Current completion | Weighted contribution | Notes |
| --- | ---: | ---: | ---: | --- |
| Scope, architecture and authority ownership | 10% | 95% | 9.5% | Realism rules, exclusions, module boundaries and authority ownership are explicit and machine-tested. |
| Body / needs / sleep / exertion | 20% | 58% | 11.6% | Significant original model/runtime work and broad integration scaffolding exist; calibration and native acceptance remain incomplete. |
| Combat / injury / blood loss / armor | 25% | 46% | 11.5% | Causal models, native bridges, armor wear, impairment, blood loss and field care have extensive offline tests; broad native combat acceptance is the next major gate. |
| Unified settings and independent toggles | 10% | 30% | 3.0% | Machine-readable settings/module contracts and independence tests exist; the final player-facing runtime settings authority is not wired end-to-end. |
| Presentation / scanner / nameplates | 10% | 65% | 6.5% | Modern-scanner/nameplate candidate plus actor-healthbar suppression are integrated for attended testing; exact native/E3 rendering still needs acceptance and standalone presentation remains open. |
| Distribution / one-package installation | 10% | 25% | 2.5% | Safe package policy, artifact checks, local deploy/upgrade/rollback and CI artifact scaffolding exist; redistribution-cleared one-package release does not yet. |
| Native gameplay, save and quest validation | 10% | 15% | 1.5% | Earlier smoke evidence exists, but the new broad body/combat/save/boss/Phantom Liberty candidate has not yet been run on the user's game. |
| Documentation / handoff / reproducibility | 5% | 78% | 3.9% | Durable worklog/status, architecture, calibration, acceptance and operator docs now preserve most project intent and test procedure. |
| **Total** | **100%** |  | **50.0%** | |

The increase from the original 43% baseline reflects real closed engineering gates: machine-readable contracts, cloud-safe CI, broader offline regression coverage, safe artifact policy, an immutable broad attended builder, no-healthbar presentation work, and one-command compile/preflight/deploy orchestration. It does **not** award native-game acceptance that has not happened yet.

## Current known-good state

- `main` contains the local-agent work through commit `938c8b9`, including the scanned-NPC/toilet fixes and the modern scanner restoration candidate.
- `chatgpt-continuation` starts from that state and contains the clarified realism scope, module architecture, machine-readable settings/runtime/distribution contracts and broad acceptance tooling.
- GitHub Actions runs the public-source reproducible model/contract suite and safe development-package policy. The exact branch head immediately before this status refresh was green.
- Original realpass body, combat, wound, armor-wear, blood-loss, field-care and NPC-body models are present in source with substantial offline regression coverage.
- Canonical body/combat activation remains deliberately gated. `Build-AttendedAcceptance.ps1` may open both only in a new immutable generated candidate after validating the full causal runtime chain and compiling the exact profile.
- The default broad attended candidate removes traditional HP bars for V, ordinary NPCs and bosses. The actor-health presentation also covers direct overclock/overshield visibility paths and the dedicated companion actor healthbar while deliberately leaving generic objective/vehicle durability UI alone.
- `Prepare-AttendedSession.ps1` can derive the active local deployment, compile/preflight the broad candidate, and—only with explicit `-Deploy`—establish a verified save backup, perform a reversible upgrade and verify the receipt. It never launches the game.
- The project has verified file deployment, upgrade, rollback, hashing and save-backup machinery for local integration testing.
- The project has explicit provenance and license records for framework dependencies, Dark Future adaptations and the Project E3 HUD dependency.

## Principal release blockers

1. **Broad native gameplay acceptance.** Compile the exact current candidate against the user's installed 2.31 script bundle, then validate player/NPC combat symmetry, no-healthbar presentation, localized injury, armor, bleeding, impairment, treatment, save/reload and time progression in one coherent session.
2. **Combat calibration from native evidence.** Validate weapon/ammunition mapping, hit-region routing, actual armor coverage, penetration and tissue/cyberware consequences. Remove ordinary-human level/HP sponge behavior where the native engine permits while preserving authored boss/quest/nonlethal exceptions.
3. **Single runtime settings authority.** Convert the machine-readable module/settings contract into the final realpass-owned in-game settings surface. Every major module must remain independently disable-able without orphaned state or hidden dependencies.
4. **Presentation independence.** Preserve the useful E3-inspired look without requiring a redistributable copy of Project E3 HUD. Current published E3 permissions require the original mod and block a true standalone one-ZIP release.
5. **Distribution licensing.** Confirm transitive redistribution obligations for every bundled framework and adapted third-party material. Do not publish a package containing blocked or unreviewed assets.
6. **Release artifact.** Evolve the current safe development artifact into the permitted game-root-shaped player package, with deterministic contents, hashes, notices and simple install/upgrade behavior.
7. **Compatibility acceptance.** Validate bosses, MaxTac, companions, nonlethal outcomes, quest immunity, Phantom Liberty critical sequences, save migration, performance and script latency.

## Immediate priority order

1. On the user's PC, sync `chatgpt-continuation` and run the broad attended compile/preflight without deploying. Fix any exact-game-script or acquired-dependency compile mismatch before gameplay conclusions are drawn.
2. If preflight is clean, generate and deploy a fresh immutable candidate through `Prepare-AttendedSession.ps1 -Deploy`, preserving the verified save backup and rollback receipt, then perform the broad attended acceptance plan.
3. Convert each native failure into a narrow acceptance-ledger issue rather than weakening the physical model or reintroducing health-sponge scaling.
4. Continue consolidating the player-facing realpass settings authority and remove inherited/upstream feature ownership where realpass should be authoritative.
5. Continue standalone presentation and licensing work so the eventual package does not depend on redistributing blocked Project E3 material.
6. Promote distribution tooling from development-source artifacts toward a deterministic redistribution-cleared player package only after native behavior is stable.

## Rules for future agents

- Read `REALISM-SPEC.md`, `docs/MODULAR-ARCHITECTURE.md`, `docs/ROADMAP.md`, this file, `docs/WORKLOG.md`, `docs/COMBAT-CALIBRATION.md` and `docs/ATTENDED-ACCEPTANCE.md` before changing behavior.
- Treat the percentages here as conservative release-readiness estimates. Update them only when a real gate closes or reopens, and explain the change in `docs/WORKLOG.md`.
- Do not reactivate body or combat in canonical source merely because scripts compile. Native gameplay acceptance is required.
- Do not add features outside the realism scope simply because an upstream dependency offers them.
- Do not redistribute Project E3 HUD assets under the current recorded permission model.
- Keep local game files, saves, generated staging state, downloaded dependencies and deployment receipts out of the public repository.
- No unattended game launch, background watcher/logger/service or scheduled task may be introduced for testing.
- Prefer a few coherent, reviewable batches over dozens of speculative patches.
