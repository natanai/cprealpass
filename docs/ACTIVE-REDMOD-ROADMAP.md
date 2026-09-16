# Biology — active REDmod follow-up roadmap

Status: **ACTIVE FOLLOW-UP LEDGER**  
Last updated: **2026-09-15**

This file tracks current post-integration work and attended acceptance. `docs/THREAD-LEDGER.md` is authoritative for active conversation/lane state; current GitHub issues/PRs are authoritative for implementation state.

For historical pre-REDmod evidence, use `PRE-REDMOD-LIVE-BASELINE-2026-09-15.md`. For exact integrated attended evidence, use `docs/test-runs/`.

## Read before working

1. `AGENTS.md`
2. `AGREED-GOALS.md`
3. `docs/THREAD-LEDGER.md`
4. root `ROADMAP.md`
5. this file
6. the focused architecture doc for the subsystem
7. `docs/BIOLOGY-REDMOD-MIGRATION.md`
8. `docs/PARALLEL-AGENT-WORKFLOW.md`
9. `docs/INTEGRATION-ORCHESTRATOR.md`
10. `docs/LOCAL-OPERATOR-COMMANDS.md` before requesting local commands
11. the relevant GitHub issue and all current comments

Do not use merged worker handoffs or dated baseline records to infer a current branch assignment.

---

# 1. Integrated foundation now on main

The current canonical line already contains the implementations from:

- original REDmod package/dependency foundation;
- Biology native shell/navigation follow-up;
- authoritative body-runtime follow-up and exact-compile repair;
- E3-inspired HUD/nameplate presentation follow-up;
- launcher-off / self-contained player uninstaller work;
- REDmod activation-sentinel and standalone tweak-grammar repairs;
- W09 post-uninstall REDmod output-path recovery;
- W10 self-contained settings provider and settings-stack dependency exit;
- W11 pre-W10 legacy-framework transition cleanup.

W09 / PR #62:

- official deployment remains authoritative;
- the deploy helper only ensures that missing `<game>/r6/cache/modded` exists immediately before official `redMod.exe deploy`;
- it never clears or fabricates shared REDmod output;
- issue #59 remains open for direct attended acceptance.

W10 / PR #63:

- REDlauncher/REDmod is the sole public whole-mod activation boundary;
- the only normal in-game preference is `presentation.e3-first-person-hud-visuals`;
- that Boolean is Biology-owned save-backed ScriptableSystem state edited through Biology-owned Ink UI;
- Mod Settings, ArchiveXL, and RED4ext are removed from production architecture;
- redscript is the only retained bundled generic runtime dependency;
- live persistence and launcher-OFF behavior remain parent-attended gates.

W11 / PR #65:

- the one-time transition is exact-receipt/hash/baseline/consumer driven and fails closed;
- its mutator deletes only plan-bound retired Mod Settings / ArchiveXL / RED4ext files after immediate revalidation;
- redscript remains outside the deletion set and is reverified after cleanup;
- the successful attended read-only probe classified the preserved installation `SAFE-TO-APPLY` with 42 exact retirement candidates, no competing-consumer evidence, and all five redscript paths present/protected;
- issue #64 is closed; actual cleanup execution and verification remain P01.2-owned.

Do not reopen merged worker lanes merely because their acceptance issues remain open.

---

# 2. Current implementation state

There is currently **no active worker implementation lane**.

P01.2 owns the immediate transition/test gate:

- execute the exact W11 SAFE-TO-APPLY plan against the preserved installation through the repository-owned parent-authorized cleanup entrypoint;
- preserve the plan/cleanup evidence and fail closed if the installation changed after the read-only probe;
- only after successful cleanup move to the exact canonical-main candidate build/install/deploy cycle.

Issue #66 separately tracks cross-cutting operator-bootstrap hardening discovered during W11's first failed bootstrap. It does not reopen W11 and does not invalidate the repaired W11 cleanup bootstrap already merged on main.

---

# 3. Parent-attended acceptance still open

## Issue #59 — W09 repaired REDmod deployment

Directly prove official REDmod 2.31 completes the repaired deployment path on the exact integrated candidate.

## Issue #44 — launcher OFF / uninstall reliability

Directly prove:

- REDlauncher ON -> Biology active;
- REDlauncher OFF -> Biology inactive/native behavior;
- no old blank Mod Settings row;
- no Biology-caused ArchiveXL/RED4ext/Mod Settings warning/footprint from the new package;
- hard uninstall remains safe;
- reinstall-after-uninstall works through the repaired REDmod deploy path.

## Issue #39 — Biology shell/navigation

Directly prove:

- native body-shell interaction grammar;
- overview -> detail -> Back -> overview works repeatedly;
- mode switching is overview-only;
- no Biology visual leakage into Cyberware;
- stock Cyberware remains functional.

## Issue #41 — runtime authority

Directly prove:

- authoritative body runtime exists in an ordinary valid live session;
- no `BODY RUNTIME SYSTEM MISSING`;
- no fake `STABLE` fallback;
- menu open/close, save/reload, and time progression use one authoritative state.

## Issue #40 — E3 presentation

Directly prove:

- E3 ON visibly transforms ordinary first-person presentation;
- quest/objective HUD receives the intended red/minimal treatment;
- civilian and police/combatant ambient nameplates work through ordinary focus/look;
- Biology-owned E3 preference persists across save/reload;
- E3 OFF removes only E3-specific presentation;
- modern scanner/quickhack remains native/current.

---

# 4. Current installed-state caveat

The user's current game is **not yet** the new W09+W10 candidate.

Preserved sequence:

1. supported Cyberpunk 2077 / REDmod 2.31 state was fresh;
2. an older Biology candidate was installed;
3. `Uninstall Biology.exe` was attended-tested and Biology-specific residue verification passed;
4. exact pre-W10 source `7e61724071b8c95ba5c334ab9e8d11c43381c94e` was then built/installed;
5. official REDmod reached Stage 3 and failed because `r6/cache/modded` was absent;
6. launcher-OFF gameplay otherwise looked normal, but ArchiveXL produced a Windows Security warning and the old Mod Settings surface left a blank inert menu gap;
7. the W11 read-only transition probe later proved the exact remaining retired framework footprint SAFE-TO-APPLY under its generated plan.

Do not interpret the old framework symptoms as evidence against the new W10 package, and do not overlay the new candidate before the approved W11 cleanup is executed and verified.

A full Cyberpunk reinstall is not the default cleanup response. The exact narrower transition has now been proven safe for this preserved state; any changed state must still fail closed rather than broadening deletion.

---

# 5. Next combined candidate sequence

```text
W11 SAFE-TO-APPLY plan already proven
        -> parent-authorized plan-bound cleanup
        -> cleanup evidence / redscript preservation verification
        -> exact canonical-main supported-game compile
        -> one release-shaped Biology ZIP
        -> install exact artifact
        -> W09-repaired official REDmod deploy
        -> durable artifact/deploy evidence
        -> one attended gameplay cycle
        -> record under docs/test-runs/
        -> close accepted issues or route materially new findings
```

Do not layer separate worker branches into the user's game installation.

---

# 6. Local evidence policy

Before asking the user to run PowerShell/CMD, read `docs/LOCAL-OPERATOR-COMMANDS.md`.

Rules:

- use repository-owned entrypoints rather than reconstructing their internals in chat;
- do not assume a persistent repo checkout path;
- attended workspaces are disposable;
- the known game path may be used where the catalog allows it;
- user-run evidence tools must preserve useful success/failure diagnostics in one attachable `.txt` report;
- do not casually rerun the ~85 GiB exhaustive vanilla hash pass unless the current transition/test policy requires that level of proof;
- source/CI never substitutes for direct deployment or live-runtime acceptance.

---

# 7. Historical identifiers

Older identifiers such as `PKG-*`, `DEP-*`, `NAV-*`, `BIO-*`, `STATE-*`, `PRES-*`, and `SET-*` remain useful when tracing why a feature exists, but they are not automatically active work because their text appears in history.

Current implementation work is defined by `docs/THREAD-LEDGER.md`, root `ROADMAP.md`, this file, and current GitHub issues/PRs.
