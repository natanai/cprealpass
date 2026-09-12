# realpass project status

Last updated: 2026-09-12
Working branch: `chatgpt-continuation`
Baseline branch tip when this status ledger was introduced: `4b9dbbeb5e0ef243900b2daec4baf800e2a4af64`

## Release target

realpass is intended to become one coherent Cyberpunk 2077 + Phantom Liberty realism mod. The target player experience is: download one release package, copy/extract it into the Cyberpunk 2077 game root (or run one equally simple installer if dependency licensing forces that route), then launch the game normally through Steam. The player should not need to understand the source mods, development staging, manifest system, or deployment receipts.

The gameplay target is physical and physiological realism rather than generalized difficulty. In-scope authorities are body/needs, injury, realistic projectile/impact behavior, physical armor/clothing coverage, relevant cyberware physiology, presentation required to communicate those systems, and diagnostics for development. Weather, economy overhauls, arbitrary scarcity, added random encounters, travel restrictions and a separate outfit/transmog system are out of scope.

## Overall completion estimate

**43% toward a first credible 1.0 release** at the time this ledger was created.

This percentage is a weighted engineering estimate, not a claim that 43% of lines of code are written. A subsystem receives credit only for work that advances a releasable, gameplay-validated, safely installable mod. Offline models without native validation count as partial progress.

| Workstream | Weight | Current completion | Weighted contribution | Notes |
| --- | ---: | ---: | ---: | --- |
| Scope, architecture and authority ownership | 10% | 90% | 9.0% | Core realism rules and module boundaries are now explicit. |
| Body / needs / sleep / exertion | 20% | 55% | 11.0% | Significant original model/runtime work exists; current source activation remains gated and calibration/native acceptance is incomplete. |
| Combat / injury / blood loss / armor | 25% | 40% | 10.0% | Large original model and native bridge surface exists, but combat remains intentionally disabled pending integrated acceptance and calibration. |
| Unified settings and independent toggles | 10% | 10% | 1.0% | Desired contract is documented, but public realpass-owned settings authority is not yet implemented end-to-end. |
| Presentation / scanner / nameplates | 10% | 60% | 6.0% | Nameplate/toilet fixes were observed; modern-scanner candidate still requires native acceptance and E3 remains a redistribution problem. |
| Distribution / one-package installation | 10% | 15% | 1.5% | Safe local bundle/deploy/rollback infrastructure exists, but there is no cloud-built, redistribution-cleared, drag-and-drop release yet. |
| Native gameplay, save and quest validation | 10% | 15% | 1.5% | Some smoke evidence exists; broad body/combat/save/Phantom Liberty acceptance is still open. |
| Documentation / handoff / reproducibility | 5% | 50% | 2.5% | Architecture and roadmap exist; this status/ledger system is being formalized now. |
| **Total** | **100%** |  | **42.5% ≈ 43%** | |

## Current known-good state

- `main` contains the local-agent work through commit `938c8b9`, including the scanned-NPC/toilet fixes and the modern scanner restoration candidate.
- `chatgpt-continuation` starts from that state and contains the clarified realism scope, module architecture and refocused roadmap.
- Original realpass body, combat, wound, armor-wear, blood-loss, field-care and NPC-body models are present in source.
- Native adapters for several of those systems exist, but the primary body/combat policies in source remain deliberately gated until coherent gameplay acceptance is possible.
- The project already has verified file deployment, upgrade, rollback, hashing and save-backup machinery for local integration testing.
- The project has explicit provenance and license records for framework dependencies, Dark Future adaptations and the Project E3 HUD dependency.

## Principal release blockers

1. **Single authority / settings consolidation.** Replace scattered upstream switches and hard-coded development gates with one realpass-owned module/settings contract. Every major module must be independently disable-able without orphaned state or hidden dependencies.
2. **Body acceptance and calibration.** Validate actual game-time behavior, consumption, sleep/wait, exertion, bathroom/washing interactions, persistence and save/reload in one coherent session.
3. **Combat activation.** Validate weapon/ammunition mapping, hit-region routing, actual armor coverage, penetration, tissue/cyberware injury, blood loss, impairment, field care and recovery as one pipeline. Eliminate health-sponge behavior where safe while preserving authored exceptions.
4. **Presentation independence.** Preserve the useful E3-inspired look without requiring a redistributable copy of Project E3 HUD. Current published E3 permissions require the original mod and block a true standalone one-ZIP release.
5. **Distribution licensing.** Confirm transitive redistribution obligations for all bundled frameworks and adapted third-party material. Do not publish a package containing blocked or unreviewed assets.
6. **Cloud release build.** Add GitHub Actions that can run safe CI, construct the permitted artifact, verify contents/hashes, and eventually attach a release ZIP.
7. **Install UX.** Reduce installation to a game-root-shaped archive or one simple installer. Development-only receipt/state complexity should remain hidden from ordinary players while preserving safe upgrades and rollback.
8. **Compatibility acceptance.** Validate player/NPC symmetry, bosses, MaxTac, nonlethal outcomes, quest immunity, Phantom Liberty critical sequences, save migration, performance and script latency.

## Immediate priority order

1. Introduce machine-readable runtime module and distribution contracts.
2. Add automated contract tests and cloud-safe CI.
3. Establish a public project worklog and update this percentage after meaningful milestones.
4. Consolidate runtime feature gates around one realpass authority before wiring a player-facing settings UI.
5. Audit package contents against scope and licensing; remove inherited features rather than merely hiding them.
6. Prepare the next large attended gameplay acceptance batch instead of fragmented micro-tests.

## Rules for future agents

- Read `REALISM-SPEC.md`, `docs/MODULAR-ARCHITECTURE.md`, `docs/ROADMAP.md`, this file, and `docs/WORKLOG.md` before changing behavior.
- Treat the percentages here as conservative release-readiness estimates. Update them only when a real gate closes or reopens, and explain the change in `docs/WORKLOG.md`.
- Do not reactivate body or combat merely because scripts compile. Native gameplay acceptance is required.
- Do not add features outside the realism scope simply because an upstream dependency offers them.
- Do not redistribute Project E3 HUD assets under the current recorded permission model.
- Keep local game files, saves, generated staging state, downloaded dependencies and deployment receipts out of the public repository.
- Prefer a few coherent, reviewable batches over dozens of speculative patches.
