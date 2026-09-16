# Biology — CURRENT ROADMAP

**This file is the active-work entry point.**

Use it together with `docs/THREAD-LEDGER.md`, current GitHub issues/PRs, and the latest relevant records under `docs/test-runs/`. Dated baseline documents and merged worker handoffs are evidence/history, not current branch assignments.

Before implementation work, read:

1. `AGENTS.md`
2. `AGREED-GOALS.md`
3. `docs/AGENT-OPERATING-PATTERNS.md`
4. `docs/THREAD-LEDGER.md`
5. `docs/ACTIVE-REDMOD-ROADMAP.md`
6. `docs/BIOLOGY-REDMOD-MIGRATION.md`
7. `docs/PARALLEL-AGENT-WORKFLOW.md`
8. `docs/INTEGRATION-ORCHESTRATOR.md`
9. `docs/LOCAL-OPERATOR-COMMANDS.md` before asking the user to run local commands
10. the latest relevant file under `docs/test-runs/`
11. current open GitHub issues/PRs

## Parent integration/orchestration thread

The active parent is **P01.2**. `docs/THREAD-LEDGER.md` is authoritative for conversation/assignment state. The parent coordinates merge/test/evidence/routing work and is not a fourth broad feature-development lane.

Durable parent startup packet:

- `docs/handoffs/PARENT-INTEGRATION.md`
- current replacement packet: `docs/handoffs/PARENT-P01.2.md`

Meaningful attended results remain durable under `docs/test-runs/` and must be tied to the exact canonical main SHA and exact release-shaped artifact. Small redistributable operator state needed by later zero-repo commands belongs under `docs/operator-evidence/` after parent ingestion.

## Current parent / worker state

Canonical `main` contains the integrated REDmod foundation, Biology shell/runtime/presentation/uninstaller work, W09-W12 release transition work, W13 REDscript startup repair, W14 collision-safe installer/recovery repair, and W15.1 failed-install ZIP validation repair.

W11.1 / issue #64 / PR #65 remains important provenance: its attended read-only probe established a `SAFE-TO-APPLY` plan for the preserved pre-W10 install with 42 exact retired-framework targets, no competing-consumer evidence, and all five redscript paths protected. That historical proof must not be discarded or misrepresented even though later release work has moved beyond W11.

The current active worker assignment is recorded in `docs/THREAD-LEDGER.md` and GitHub, not frozen into this roadmap. At this revision it is **W15.2 / issue #74 / PR #75**, implementing managed operator evidence lifecycle on `agent/operator-evidence-lifecycle`. W15.2 is the second sequential assignment in the existing W15 worker conversation; W15.1 is already merged.

P01.2 owns merge, durable evidence ingestion, and any real local recovery/cleanup/candidate execution after the worker returns. Do not reactivate an older merged branch merely because its acceptance issue remains open.

## Accepted REDmod foundation and integrated feature state

The first integrated REDmod milestone built from `8cf045664b5e4d8b4b014edfc98bf2f8eb270ba5` established official REDmod recognition/deployment and exposed the attended UI/runtime/presentation findings that became issues #39, #40, and #41. Their implementations are merged and remain parent-attended acceptance gates.

The pre-W10 transition provenance remains source `7e61724071b8c95ba5c334ab9e8d11c43381c94e`. W11 retired Mod Settings / ArchiveXL / RED4ext while preserving redscript and shared roots. W09 repaired the missing official REDmod output directory boundary. W10 made settings self-contained. W13 added the standalone cybercmd REDscript startup executor and guarded shared-loader installation. W14 repaired collision-safe create execution and added exact failed-install recovery. W15.1 repaired safe ZIP directory-entry validation.

The current W15.2 release lane does **not** redesign those systems. It changes how operator evidence survives between attended steps so recovery/cleanup can be exact without relying on a user remembering arbitrary loose files.

## Current installed-state caveat

The attended W14/W15 sequence produced a failed first install from exact source `04d4c1584df4b0823e093422b98cf4c5575c7b19`. The candidate ZIP that W14's original recovery path expected was later absent. W15.1 proved recovery correctly failed closed before mutation rather than guessing.

W15.2 therefore provides a bounded current-state path that does **not** ask the user to recreate the missing ZIP: repo-backed legacy evidence may authorize removal only of empty, safely attributable Biology-owned roots after proving known ambiguous package files are absent. Any file or other ambiguity fails closed. Future candidate operations capture exact schema-2 payload/hash evidence so an old candidate ZIP is no longer the sole recovery proof source.

A full Cyberpunk reinstall is not the default response to this evidence gap. P01.2 must use the exact repo-backed recovery/cleanup path after W15.2 is reviewed and merged.

## Open attended acceptance

### #44 — launcher OFF / hard uninstall contract

Parent must ultimately prove REDlauncher ON/OFF behavior, absence of retired framework/provider residue, safe hard uninstall, and reliable reinstall through the current guarded release path.

### #39 — Biology shell/navigation

Parent must prove the native body-shell interaction contract: clean overview/detail/Back behavior, overview-only mode switching, and no Biology visual leakage into Cyberware.

### #41 — body runtime authority

Parent must prove the authoritative body runtime exists in a live valid session, the former `BODY RUNTIME SYSTEM MISSING` failure does not recur, no fake healthy fallback appears, and persistence/session behavior remains authoritative.

### #40 — E3 presentation

Parent must prove E3 ON is visibly unmistakable in ordinary gameplay, including civilian ambient nameplates and intended police/combatant treatment; the Biology-owned preference persists; E3 OFF removes only E3-specific presentation; and the modern scanner/quickhack interface remains native.

## Next integration cycle

```text
W15.2 / PR #75 worker return
        -> P01.2 review + merge if sound
        -> durable repo-backed operator evidence available by stable evidence ID
        -> parent-owned bounded recovery of the preserved failed-install state
        -> repo-confirmed local evidence/artifact cleanup when eligible
        -> exact canonical-main supported-game compile/build
        -> one release-shaped Biology artifact
        -> guarded install + official REDmod deploy
        -> one attended launcher/runtime/UI/presentation acceptance cycle
        -> durable docs/test-runs + docs/operator-evidence records
        -> close accepted issues or route materially new findings
```

Do not ask the user to install/play worker branches by default. The parent coordinates one coherent canonical artifact.

## Historical evidence

The original pre-REDmod clean-room evidence remains in:

- `docs/PRE-REDMOD-LIVE-BASELINE-2026-09-15.md`

Exact attended REDmod/deploy/recovery evidence lives under:

- `docs/test-runs/`

Historical records may contain old branch names, old paths, old player-facing labels, or superseded expectations because they document what happened at that time. Do not copy those details back into active instructions without revalidating them.
