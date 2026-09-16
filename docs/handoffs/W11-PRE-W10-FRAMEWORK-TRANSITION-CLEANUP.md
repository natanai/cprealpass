# W11.1 — pre-W10 legacy framework transition cleanup

Status: **ACTIVE worker handoff**  
Parent: **P01.2**  
Issue: **#64**  
Branch: `agent/pre-w10-framework-transition-cleanup`

## Paste into the worker conversation

```text
[W11.1] RELEASE — Legacy Framework Transition Cleanup

Work on repo natanai/cprealpass.

This is worker lane W11.1.

Work ONLY on the already-created branch:

agent/pre-w10-framework-transition-cleanup

Issue:
#64 — Pre-W10 transition cleanup — safely retire legacy Mod Settings / ArchiveXL / RED4ext residue before attended candidate

Parent:
P01.2

At startup, resolve and report the exact current head of this worker branch. Do not assume a stale SHA from chat text.

Do NOT merge your own PR.
Do NOT ask the user to install or play your worker branch.
Do NOT ask the user to reinstall Cyberpunk merely to remove these retired files unless direct evidence proves a narrower safe transition is impossible.
Do NOT remove redscript.
Do NOT redesign W09 REDmod deploy recovery, W10 settings, Biology UI/runtime, E3 presentation, scanner, combat, physiology, or balance.

READ FIRST:
- AGENTS.md
- AGREED-GOALS.md
- ROADMAP.md
- docs/THREAD-LEDGER.md
- docs/handoffs/PARENT-P01.2.md
- docs/ACTIVE-REDMOD-ROADMAP.md
- docs/INTEGRATION-ORCHESTRATOR.md
- docs/PARALLEL-AGENT-WORKFLOW.md
- docs/CLEAN-ROOM-TESTING.md
- docs/LOCAL-OPERATOR-COMMANDS.md
- docs/DEPENDENCY-AUDIT.md
- docs/SETTINGS-ARCHITECTURE.md
- docs/PLAYER-DISABLE-UNINSTALL.md
- docs/test-runs/2026-09-15-w09-post-uninstall-redmod-state.md
- issue #64 and current comments

CURRENT INSTALLED-STATE CAVEAT

The user's current Cyberpunk installation is NOT the new W09+W10 package.

Preserved sequence:
1. Cyberpunk 2077 / REDmod 2.31 was previously brought to a fresh state.
2. An older Biology candidate was installed.
3. The player-facing Uninstall Biology.exe was attended-tested and Biology-specific residue verification passed; generic/shared dependencies were intentionally preserved.
4. The pre-W10 candidate from exact source `7e61724071b8c95ba5c334ab9e8d11c43381c94e` was then built and installed.
5. Official REDmod later reached Stage 3 and failed because `r6/cache/modded` was absent.
6. Launcher-OFF gameplay otherwise appeared normal, but Windows Security reported ArchiveXL.dll and the pause menu showed a blank/inert old Mod Settings gap.

W10 / PR #63 is now merged. Current production no longer ships Mod Settings 0.2.21, ArchiveXL 1.27.3, or RED4ext 1.30.0. Current production DOES still require redscript 0.5.31.

Simply overlaying the new W10 package could therefore leave retired old framework files on disk and contaminate launcher-OFF acceptance.

GOAL

Build the smallest safe, repository-owned transition path from that preserved pre-W10 installed state to one where old Biology-introduced Mod Settings / ArchiveXL / RED4ext payload is either:
- proven safe to remove and removed exactly; or
- left untouched with a fail-closed report explaining why ownership/safety cannot be proven.

This is a migration/transition problem, not a redesign of the normal player uninstaller.

EVIDENCE-FIRST REQUIREMENTS

Before deleting anything, establish:
- exact installed `biology/build-manifest.json` / receipt identity if present;
- exact retired dependency paths and expected hashes from the pre-W10 package/receipt;
- current on-disk hashes and path types for those exact entries;
- whether tracked vanilla baseline proves each path was absent before Biology;
- whether there is evidence of another installed consumer that makes automatic deletion unsafe;
- current W10 production no longer requires the retired three components;
- redscript is retained and must not be deleted.

Do not infer file ownership merely because a path lives under a framework directory.
Do not recursively delete shared roots.
Do not broaden the normal uninstaller's generic-dependency policy.

The existing `Reset-BiologyIteration.ps1` may be useful implementation/reference evidence, but the current attended-test contract restricts ITERATION mode to cases where package/dependency structure has not materially changed. W10 is a dependency-structure change. Do not silently reclassify this transition as an ordinary iteration reset.

LOCAL EVIDENCE POLICY

If you need direct installed-game evidence, read docs/LOCAL-OPERATOR-COMMANDS.md first.

Any user-run probe/bootstrap must:
- pin this exact branch plus an exact 40-character worker head;
- discover/create a cprealpass seed and use a uniquely signed disposable checkout/worktree;
- treat the installed game/tool tree read-only on the first evidence pass;
- fingerprint relevant Cyberpunk/REDmod identity;
- capture bounded evidence only;
- preserve child stdout, stderr, exit code, and exception text before throwing;
- produce one attachable `.txt` on BOTH success and failure;
- print exactly one obvious `ATTACH THIS FILE TO CHATGPT:` path.

If mutation is later required, make it a separate, explicitly bounded transition action whose deletion set is fully planned and reported before execution.

OWNED SCOPE

- read-only pre-W10 residue/receipt probe if needed;
- exact pre-W10 dependency-path/hash reconstruction from durable package metadata/history;
- safe transition planner/executor for ONLY retired Mod Settings / ArchiveXL / RED4ext files when ownership is proven;
- fail-closed changed/ambiguous/shared-consumer behavior;
- bounded removal of now-empty directories only when safe, never shared roots;
- tests for exact-hash, changed-file, missing-file, vanilla-overlap, shared-consumer/ambiguity, redscript-preservation and protected-root cases;
- docs/LOCAL-OPERATOR-COMMANDS.md update if a new operator entrypoint is added;
- any narrowly necessary install/uninstall contract documentation for this transition.

NON-GOALS

- no full settings redesign;
- no redscript elimination;
- no W09 cache/output redesign;
- no activation-sentinel redesign unless direct new evidence invalidates it;
- no body runtime/UI/presentation/scanner/combat/physiology work;
- no general-purpose mod-manager cleanup tool;
- no assumption that all generic framework files belong to Biology.

DELIVERABLES

1. Evidence-backed decision on whether safe targeted retirement is possible for the preserved state.
2. If possible, a narrow repository-owned transition tool/bootstrap with durable report output and fail-closed semantics.
3. Regression tests and documentation.
4. Full cloud CI green.
5. Open a PR to main; do not merge it.
6. Return to P01.2 with:
   - W11.1 identifier;
   - exact final worker head;
   - PR number;
   - CI result;
   - files/scope changed;
   - evidence obtained vs still requiring attended execution;
   - exact parent command/report handoff if cleanup is ready;
   - confirmation that redscript and unrelated/shared mod state remain protected.

FINAL ACCEPTANCE BOUNDARY

P01.2 owns actual cleanup execution on the user's preserved install and the next combined candidate:
- exact canonical-main compile;
- release-shaped build;
- install;
- W09-repaired official REDmod deploy;
- artifact/checksum/deploy evidence;
- attended launcher ON/OFF, Biology UI/runtime, E3 preference persistence/presentation, nameplates, and modern scanner acceptance.
```
