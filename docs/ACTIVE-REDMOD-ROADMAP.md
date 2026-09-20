# Biology — active REDmod follow-up roadmap

Status: **ACTIVE FOLLOW-UP LEDGER**  
Last updated: **2026-09-16**

This file tracks current post-integration work and attended acceptance. `docs/THREAD-LEDGER.md` is authoritative for active conversation/assignment state; current GitHub issues/PRs are authoritative for implementation state. `docs/AGENT-OPERATING-PATTERNS.md` is authoritative for worker reuse/numbering and managed operator evidence conventions.

For historical pre-REDmod evidence, use `PRE-REDMOD-LIVE-BASELINE-2026-09-15.md`. For exact integrated attended evidence, use `docs/test-runs/`.

## Read before working

1. `AGENTS.md`
2. `AGREED-GOALS.md`
3. `docs/AGENT-OPERATING-PATTERNS.md`
4. `docs/THREAD-LEDGER.md`
5. root `ROADMAP.md`
6. this file
7. the focused architecture doc for the subsystem
8. `docs/BIOLOGY-REDMOD-MIGRATION.md`
9. `docs/PARALLEL-AGENT-WORKFLOW.md`
10. `docs/INTEGRATION-ORCHESTRATOR.md`
11. `docs/LOCAL-OPERATOR-COMMANDS.md` before requesting local commands
12. the relevant GitHub issue and all current comments

Do not use merged worker handoffs or dated baseline records to infer a current branch assignment.

---

# 1. Integrated foundation now on main

The current canonical line already contains implementations from:

- original REDmod package/dependency foundation;
- Biology native shell/navigation follow-up;
- authoritative body-runtime follow-up and exact-compile repair;
- E3-inspired HUD/nameplate presentation follow-up;
- launcher-off / self-contained player uninstaller work;
- REDmod activation-sentinel and standalone tweak-grammar repairs;
- W09 post-uninstall REDmod output-path recovery;
- W10 self-contained settings provider and settings-stack dependency exit;
- W11 pre-W10 legacy-framework transition cleanup;
- W12 operator bootstrap hardening;
- W13 installed REDscript startup/task-runner repair and guarded shared cybercmd install path;
- W14 collision-safe installer create-path repair and exact failed-install recovery;
- W15.1 failed-install recovery ZIP directory-entry validation repair.

W11 / PR #65 remains important transition provenance:

- the one-time transition is exact-receipt/hash/baseline/consumer driven and fails closed;
- its mutator deletes only plan-bound retired Mod Settings / ArchiveXL / RED4ext files after immediate revalidation;
- redscript remains outside the deletion set and is reverified after cleanup;
- the successful attended read-only probe classified the preserved installation `SAFE-TO-APPLY` with 42 exact retirement candidates, no competing-consumer evidence, and all five redscript paths present/protected;
- issue #64 is closed.

W13-W15.1 are merged release-path repairs. Do not reopen their design from W15.2 unless new direct evidence invalidates an established safety boundary.

---

# 2. Current implementation state

The current active worker assignment is **W15.2 / issue #74 / PR #75 — Managed Operator Evidence Lifecycle**. `docs/THREAD-LEDGER.md` and GitHub remain the live authority if that assignment advances after this document is read.

W15.2 is intentionally the second sequential assignment in the existing W15 worker conversation:

```text
W15.1 -> issue #72 -> failed-install recovery ZIP validation repair -> merged
W15.2 -> issue #74 -> operator evidence lifecycle -> active PR #75
```

The implementation goal is release/operator infrastructure only:

- one attachable managed handoff surface per local operation;
- parent-ingested redistributable evidence under `docs/operator-evidence/<evidence-id>/`;
- future exact failed-install recovery from schema-2 payload/hash evidence rather than a retained candidate ZIP;
- a bounded legacy path for the current missing-ZIP failed state that may remove only proven-empty Biology-owned roots and otherwise fails closed;
- exact repo-backed local cleanup that refuses changed, foreign, reparse-point, or incomplete managed state;
- zero-local-repo later operations by stable evidence ID;
- shared redscript/cybercmd remains preserve-only.

P01.2 owns merge, real local recovery/cleanup, evidence ingestion, resumed candidate preparation, and attended testing. The worker does not mutate the installed game or ask the user to install/play PR #75.

---

# 3. Parent-attended acceptance still open

## Issue #44 — launcher OFF / uninstall reliability

Directly prove:

- REDlauncher ON -> Biology active;
- REDlauncher OFF -> Biology inactive/native behavior;
- no old blank Mod Settings row;
- no Biology-caused ArchiveXL/RED4ext/Mod Settings warning/footprint from the current package;
- hard uninstall remains safe;
- reinstall-after-uninstall works through the guarded release/deploy path.

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

# 4. Current failed-install evidence caveat

The attended W14 candidate built from exact source `04d4c1584df4b0823e093422b98cf4c5575c7b19` failed on the first mutating installer action. Its historical candidate ZIP was later absent. After W15.1 merged, the exact recovery rerun correctly returned `FAIL-CLOSED` before mutation because that binary proof source no longer existed.

This is an evidence-lifecycle gap, not permission to guess the old payload. W15.2 preserves the known candidate/report/source/build identity and provides a deliberately narrower current-state proof: known Biology-owned roots may be removed only when literally empty and known ambiguous package files are absent. Any file, foreign content, changed state, or reparse-point ambiguity fails closed.

Future managed candidate operations record exact schema-2 payload path/hash/replace-policy inventory plus ownership receipt hash so a later recovery does not depend on the user retaining the old ZIP.

A full Cyberpunk reinstall is not the default response to this gap. Parent must first use the reviewed repo-backed recovery boundary after W15.2 merges.

---

# 5. Next combined candidate sequence

```text
W15.2 worker implementation + CI
        -> P01.2 review/merge if sound
        -> repo-backed evidence available by stable evidence ID
        -> parent-owned read/plan-first failed-install recovery
        -> repo-confirmed managed local evidence/artifact cleanup when eligible
        -> exact canonical-main supported-game compile
        -> one release-shaped Biology ZIP
        -> guarded install
        -> official REDmod deploy
        -> durable operator/test evidence
        -> one attended gameplay cycle
        -> record under docs/test-runs/ and docs/operator-evidence/ as appropriate
        -> close accepted issues or route materially new findings
```

Do not layer separate worker branches into the user's game installation.

---

# 6. Local evidence policy

Before asking the user to run PowerShell/CMD, read `docs/LOCAL-OPERATOR-COMMANDS.md`.

Rules:

- use repository-owned entrypoints rather than reconstructing their internals in chat;
- assume zero local repo state unless independently proven otherwise;
- attended workspaces are disposable;
- one managed operation should return one obvious attachment bundle/report;
- parent/assistant ingests small redistributable evidence into `docs/operator-evidence/`; the local PC does not need GitHub write credentials;
- later operations resolve stable evidence IDs and exact hashes rather than old loose paths;
- cleanup is repo-confirmed, exact-inventory bounded, and tool-owned;
- no open-ended human `KEEP` memory is the normal contract;
- do not casually rerun the exhaustive vanilla hash pass or ask for a Cyberpunk reinstall when narrower exact evidence is sufficient;
- source/CI never substitutes for direct deployment or live-runtime acceptance.

---

# 7. Historical identifiers

Older identifiers such as `PKG-*`, `DEP-*`, `NAV-*`, `BIO-*`, `STATE-*`, `PRES-*`, and `SET-*` remain useful when tracing why a feature exists, but they are not automatically active work because their text appears in history.

Current implementation work is defined by `docs/THREAD-LEDGER.md`, root `ROADMAP.md`, this file, and current GitHub issues/PRs.
