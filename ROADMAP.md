# Biology — CURRENT ROADMAP

**This file is the active-work entry point.**

Use it together with `docs/THREAD-LEDGER.md`, current GitHub issues/PRs, and the latest relevant records under `docs/test-runs/`. Dated baseline documents and merged worker handoffs are evidence/history, not current branch assignments.

Before implementation work, read:

1. `AGENTS.md`
2. `AGREED-GOALS.md`
3. `docs/THREAD-LEDGER.md`
4. `docs/ACTIVE-REDMOD-ROADMAP.md`
5. `docs/BIOLOGY-REDMOD-MIGRATION.md`
6. `docs/PARALLEL-AGENT-WORKFLOW.md`
7. `docs/INTEGRATION-ORCHESTRATOR.md`
8. `docs/LOCAL-OPERATOR-COMMANDS.md` before asking the user to run local commands
9. the latest relevant file under `docs/test-runs/`
10. current open GitHub issues/PRs

## Parent integration/orchestration thread

The active parent is **P01.2**. `docs/THREAD-LEDGER.md` is authoritative for conversation/lane state. The parent coordinates merge/test/evidence/routing work and is not a fourth broad feature-development lane.

Durable parent startup packet:

- `docs/handoffs/PARENT-INTEGRATION.md`
- current replacement packet: `docs/handoffs/PARENT-P01.2.md`

Meaningful attended results remain durable under `docs/test-runs/` and must be tied to the exact canonical main SHA and exact release-shaped artifact.

## Current parent / worker state

The original REDmod foundation, Biology shell/runtime, presentation, player-uninstall, activation-grammar, post-uninstall REDmod recovery, and self-contained settings implementations are all already represented on canonical `main`.

Current implementation lane:

- **W11.1 / issue #64 / `agent/pre-w10-framework-transition-cleanup`** — safely retire legacy pre-W10 Mod Settings / ArchiveXL / RED4ext residue from the preserved installed Biology state before the next combined attended candidate. This lane must be evidence-first and fail closed; it must preserve redscript and unrelated/shared mod state.

Do not reactivate an older merged branch merely because its acceptance issue remains open. The open acceptance issues below are parent-attended gates unless a new failure creates a fresh worker goal.

## Accepted REDmod foundation and current integrated feature state

The first integrated REDmod milestone built from `8cf045664b5e4d8b4b014edfc98bf2f8eb270ba5` established that official REDmod recognized Biology and could complete a real five-stage deployment after explicit-root handling was repaired. That artifact later exposed the attended UI/runtime/presentation failures that became issues #39, #40, and #41; those implementations have since been merged and remain awaiting direct attended re-acceptance.

W09.1 / PR #62 is merged:

- `tools/Deploy-BiologyRedmod.ps1` now creates only a missing `<game>/r6/cache/modded` directory immediately before official REDmod deployment;
- it never clears shared cache contents or synthesizes generated REDmod output;
- issue #59 remains open until the repaired official REDmod 2.31 path is directly attended-passed.

W10.1 / PR #63 is merged:

- REDlauncher/REDmod is the sole public whole-mod activation boundary;
- the only normal in-game preference is the save-backed E3 HUD/nameplates Boolean edited through Biology-owned UI;
- Mod Settings, ArchiveXL, and RED4ext are removed from production release/build/install architecture;
- redscript is the only retained bundled generic runtime dependency;
- source/CI do not constitute live persistence or launcher-OFF acceptance.

The integrated Biology shell/runtime/presentation/uninstaller repairs from the earlier attended follow-ups are also on main. Issues #39, #40, #41, and #44 stay open only for their remaining attended acceptance.

## Installed-game caveat before the next candidate

Do **not** assume the user's current Cyberpunk installation already reflects the W09+W10 package.

The current game still reflects the pre-W10 candidate/dependency footprint used for the failed Stage-3 REDmod deploy and launcher-OFF observation. That old candidate bundled Mod Settings / ArchiveXL / RED4ext, and its player uninstaller intentionally preserved generic/shared dependencies.

Simply overlaying the new W10 package could therefore leave retired framework files on disk and falsely reproduce the old ArchiveXL warning or blank Mod Settings menu gap.

P01.2 routed that transition problem to W11.1 / issue #64. A full Cyberpunk reinstall is not the default response; the transition must first determine whether exact receipt/hash/baseline evidence permits a narrower safe retirement path.

## Open attended acceptance

### #59 — repaired REDmod post-uninstall deploy

Parent must directly prove the W09-repaired official REDmod 2.31 deployment completes all stages on the exact integrated candidate.

### #44 — launcher OFF / hard uninstall contract

Parent must prove:

- REDlauncher ON -> Biology active;
- REDlauncher OFF -> Biology inactive/native behavior;
- no legacy Mod Settings blank row;
- no Biology-caused ArchiveXL/RED4ext/Mod Settings warning/footprint in the new package;
- `Uninstall Biology.exe` remains safe and reinstall-after-uninstall remains reliable.

### #39 — Biology shell/navigation

Parent must prove the native body-shell interaction contract: clean overview/detail/Back behavior, overview-only mode switching, and no Biology visual leakage into Cyberware.

### #41 — body runtime authority

Parent must prove the authoritative body runtime exists in a live valid session, the former `BODY RUNTIME SYSTEM MISSING` failure does not recur, no fake healthy fallback appears, and persistence/session behavior remains authoritative.

### #40 — E3 presentation

Parent must prove E3 ON is visibly unmistakable in ordinary gameplay, including the previously missing random civilian ambient nameplate and incomplete police/combatant treatment; the Biology-owned preference persists; E3 OFF removes only E3-specific presentation; and the modern scanner/quickhack interface remains native.

## Next integration cycle

```text
W11 transition lane
        -> PR / CI / parent review
        -> merge if safe
        -> controlled retirement of proven pre-W10 residue
        -> exact canonical-main compile/build
        -> one release-shaped Biology artifact
        -> official W09-repaired REDmod deploy
        -> attended launcher ON/OFF + Biology UI/runtime + E3 persistence/presentation + scanner checks
        -> durable docs/test-runs record
        -> route any new failure to a fresh lane when materially new
```

Do not ask the user to install/play worker branches by default. The parent coordinates one coherent canonical artifact.

## Historical evidence

The original pre-REDmod clean-room evidence remains in:

- `docs/PRE-REDMOD-LIVE-BASELINE-2026-09-15.md`

Exact attended REDmod/deploy evidence lives under:

- `docs/test-runs/`

Historical records may contain old branch names, old paths, old player-facing labels, or superseded expectations because they document what happened at that time. Do not copy those details back into active instructions without revalidating them.
