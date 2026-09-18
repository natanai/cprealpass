# Biology parent/worker thread ledger

Status: **canonical active conversation/lane registry**  
Last updated: **2026-09-18**

> **MANDATORY:** Read this file together with `docs/AGENT-OPERATING-PATTERNS.md` before creating a new worker conversation, routing another assignment into an existing worker conversation, replacing a conversation that has become too long, or handing parent/orchestrator responsibility to a new conversation.

The repository is the durable source of truth. Git issues/branches/PRs track implementation state; ChatGPT conversations carry temporary working context. Conversation identity and Git issue/branch identity are intentionally separate.


## Parent recovery snapshot — 2026-09-18

This snapshot exists because a substantial recent parent-chat segment disappeared from the visible conversation. Treat GitHub and durable test records as the continuity source.

- Parent: **P02**, active integration/orchestration by explicit owner handoff. P01.2 is predecessor history.
- Latest completed numbered attended session: **T004**, exact tested source `ffa6f64d6c837146d032aaab565d671c932453a2`; see `docs/test-runs/TEST-LEDGER.md` and the completed T004 record.
- T004 operational listener/session: PASS; direct polling handled two observed launch/exit cycles during the same attended hold.
- T004 Biology: selector breadcrumb proves `BIOLOGY LAYOUT: MOUNTED`, but title/summary/metrics remain invisible. Diagnosis is now post-mount -> **W02.6 / issue #101**, `agent/biology-detail-post-mount-visibility`, handoff `docs/handoffs/W02.6-BIOLOGY-DETAIL-POST-MOUNT.md`, initial handoff head `0a4b1f65e3e09fce097235981a8b10030c3e1018`.
- T004 E3: quest semantic host is reached but treatment remains tiny/partial; weapon detached-center regression is repaired; lower-left hotkey/quickslot chrome is visibly mis-composed -> **W03.6 / issue #102**, `agent/e3-quest-hotkey-content-region`, handoff `docs/handoffs/W03.6-E3-QUEST-HOTKEY-CONTENT-REGIONS.md`, initial handoff head `25a4cf6ffea73779f66fdee6daee334f88e3278b`.
- Ambient framed nameplates remain live and the old two-corner reticle artifact remains absent; KEEP both.
- Body-runtime persistence issue #41 remains open for a separate live WAIT/save-reload/SLEEP acceptance boundary; T004 intentionally did not exercise it.
- The next unallocated live test ID is **T005**.
- A bounded **LIVE EVIDENCE HOLD** may be used before END when ambiguous UI evidence would benefit from a few worker-requested screenshots/ordinary state changes. It must not introduce commands, probes, installs, file mutation, or open-ended testing.

## Core rule

A recent worker conversation may carry **several closely related sequential assignments** when its existing repo/subsystem context is still materially useful and no parallelism requires another conversation.

A materially distinct implementation assignment should still receive its own GitHub issue and branch even when it is routed into the same worker conversation. Do not create a new ChatGPT conversation merely to obtain a new issue/branch number.

Create a new worker conversation when the current one is too long/unwieldy, materially stale, genuinely unrelated to the next work, or simultaneous parallel work requires another independent agent.

## Conversation IDs vs Git implementation IDs

For workers, `W##` identifies the **conversation lineage**. The decimal suffix identifies the sequential assignment handled by that same conversation.

```text
W15.1 = first assignment handled in worker conversation W15
W15.2 = second assignment routed into that same conversation
W15.3 = third assignment routed into that same conversation
W16.1 = first assignment in a newly opened worker conversation W16
```

The concrete W15 example is canonical:

```text
W15.1 -> issue #72 -> agent/failed-install-recovery-zip-validation
W15.2 -> issue #74 -> agent/operator-evidence-lifecycle
```

Rules:
- `P##.#` = parent/orchestrator conversation/assignment identifier as recorded by the parent ledger.
- `W##` = worker conversation lineage.
- `.1`, `.2`, `.3`, ... = sequential assignments in that same worker conversation.
- A new issue or branch does **not** by itself require a new worker conversation or new base `W##`.
- A new worker conversation gets the next unused base number and starts at `.1` unless the owner explicitly directs otherwise.
- `.2` does **not** mean “replacement chat because `.1` became too long.”
- Branch and issue numbers remain the implementation identifiers; worker IDs describe actual conversation lineage/assignment continuity.

Historical parent continuity such as `P01.1 -> P01.2` remains recorded as history. Future parent numbering should describe the actual parent conversation/assignment structure rather than being inferred from Git identity.

## Recommended ChatGPT thread title

```text
[P01.2] PARENT — Integration Orchestrator
[W15.2] RELEASE — Managed Operator Evidence Lifecycle
[W14.1] RELEASE — Collision-Safe Installer Create-Path Repair
```

Existing conversations do not need retroactive renaming; this ledger maps their visible title/alias to the official ID.

## Thread-state vocabulary

`ACTIVE`
: The conversation is currently receiving ongoing work.

`USABLE`
: The conversation is not actively assigned work, but its existing context remains useful enough that the parent may deliberately route another closely related sequential assignment into it.

`TOO-LONG`
: The conversation has become too long or unwieldy. Do not continue substantial work there; open the next worker base ID at `.1` if more work is required.

`RETIRED`
: Do not route new work into this conversation.

## Lane-work-state vocabulary

`IN-PROGRESS`
: Work is actively underway.

`WAITING`
: Temporarily waiting on another lane, user evidence, or an integration decision.

`READY-PARENT`
: Worker implementation is complete enough to return to the parent for review/integration; remaining attended/integration acceptance may still be pending.

`BLOCKED`
: A concrete blocker prevents safe progress.

`MERGED`
: The assignment's implementation is represented on canonical `main`.

`SUPERSEDED`
: Another assignment now owns the work.

`CLOSED`
: The assignment is complete without further implementation.

## Current ledger

| Thread ID | Current visible title / alias | Role / goal | Thread state | Lane work state | GitHub / branch | Parent routing note |
|---|---|---|---|---|---|---|
| **P02** | `[P02] PARENT — Integration Orchestrator` | Parent / integration orchestrator | **ACTIVE** | **IN-PROGRESS** | Issue #35; read `docs/handoffs/PARENT-P02.md` first | Owner-designated successor parent. Owns pre-T005 archaeology gates, worker routing, merge/integration, attended execution, durable evidence ingestion, and finding routing. |
| **P01.2** | `[P01.2] PARENT — Integration Orchestrator` | Predecessor parent / integration orchestrator | **RETIRED** | **CLOSED** | Issue #35; historical handoff `docs/handoffs/PARENT-P01.2.md` | Superseded by P02 at owner request. Preserve its durable evidence and decisions; do not route new parent work here. |
| **W15.2** | existing W15 worker conversation | Managed operator evidence lifecycle | **USABLE** | **MERGED** | Issue #74; PR #75 merged; `agent/operator-evidence-lifecycle` | Historical release/operator context; subsequent W15.3-W15.5 listener/session work is also merged. |
| **W15.1** | `[W15.1] RELEASE — Failed-Install Recovery ZIP Validation Repair` | Accept ordinary safe ZIP directory entries without weakening failed-install recovery validation | **USABLE** | **MERGED** | Issue #72; PR #73 merged; `agent/failed-install-recovery-zip-validation`; worker head `5e7ee3611104f68213c095d7fc54821a1d7a511f` | First assignment in the same W15 conversation. Retained as immediately useful recovery context; W15.2 is a new issue/branch in that same conversation, not a replacement chat. |
| **W14.1** | `[W14.1] RELEASE — Collision-Safe Installer Create-Path Repair` | Repair guarded installer create execution and provide exact failed-install recovery | **USABLE** | **MERGED** | Issue #70; PR #71 merged; `agent/release-installer-create-repair`; worker head `48d8f630a9ba24f5f2b339886a5c1bcfff6c559b` | W14 implementation is merged. Its attended first-install failure and recovery boundary are provenance for W15.1/W15.2; do not reopen its create/replace design in W15.2. |
| **W13.1** | `[W13.1] RUNTIME — Installed Biology Activation Follow-Up` | Repair the installed REDscript startup/task-runner boundary | **USABLE** | **MERGED** | Issue #68; PR #69 merged; `agent/installed-runtime-activation-followup`; worker head `6736e456d90879abe1c4d3fd0c96c2df8da7bd05` | Standalone cybercmd startup repair and guarded shared-loader install safety are merged. Downstream attended acceptance remains parent-owned. |
| **P01.1** | `PARENT 1` | Parent / integration orchestrator | **TOO-LONG** | **CLOSED** | Issue #35 | Predecessor parent. User reported this conversation was becoming too long on 2026-09-15. Do not continue substantial orchestration here; use P01.2 and the durable handoff. |
| **W12.1** | `[W12.1] RELEASE — Operator Bootstrap Hardening` | Worktree-aware/local-first operator bootstrap hardening plus repository-owned post-W11 canonical candidate preparation | **USABLE** | **MERGED** | Issue #66 closed completed; PR #67 merged; `agent/operator-bootstrap-hardening`; worker head `bc1ba45b9ca4625f32b91de3caee8157f9531d3d` | Command 13 introduced the post-transition candidate path and exact-head zero-local-repo behavior. W15.2 replaces its open-ended loose-file retention as the steady-state evidence lifecycle. |
| **W11.1** | `[W11.1] RELEASE — Legacy Framework Transition Cleanup` | Safely retire pre-W10 Mod Settings / ArchiveXL / RED4ext residue before the next attended candidate | **USABLE** | **MERGED** | Issue #64 closed; PR #65 merged; `agent/pre-w10-framework-transition-cleanup`; worker head `052888059bb2f1e75a64804494d302ced6b51e9f` | Attended cleanup PASSed: all 42 approved retired framework files were deleted, protected redscript was reverified, shared roots were preserved, and the legacy preference file remained untouched. |
| **W10.1** | `[W10.1] SETTINGS — Self-Contained Provider` | Remove Biology's Mod Settings reliance and replace the public preference surface with Biology-owned persistence | **USABLE** | **MERGED** | Issue #61; PR #63 merged; `agent/self-contained-settings-provider`; worker head `134ae11a20d8ae432686a7711cbb72f70e006fa6` | Mod Settings, ArchiveXL and RED4ext are removed from production; launcher activation and Biology-owned save state remain authoritative. |
| **W09.1** | `[W09.1] REDMOD — Post-Uninstall Deploy Recovery` | Repair official REDmod 2.31 post-uninstall/reinstall output/cache-state failure | **USABLE** | **MERGED** | Issue #59 closed completed; PR #62 merged; `agent/redmod-post-uninstall-deploy-recovery`; worker head `096cbf5d3a1e4f2b19ffc0509e1afcb70d76abaa` | Attended exact candidate proved the helper-created missing `r6/cache/modded` path allows official REDmod 2.31 deployment. |
| **W08.1** | `[W08.1] REDMOD — Standalone Tweak Grammar Repair` | Determine and implement official REDmod 2.31 standalone tweak/package grammar | **USABLE** | **MERGED** | Issue #55 closed completed; PR #56 merged; `agent/redmod-standalone-tweak-grammar-repair`; worker head `f5e675586e4cbf46027a71bf530186ba13591956` | Attended official REDmod no longer reported the prior `using` parser error and progressed to generated TweakDB output writing. |
| **W07.1** | `[W07.1] REDMOD — Activation Sentinel Repair` | Repair REDmod-owned launcher activation sentinel after attended TweakDB compile failure | **USABLE** | **MERGED** | Issue #53 closed as superseded by #55; PR #54 merged; `agent/redmod-activation-sentinel-repair`; worker head `b0f98c4d6df006395aaf7b5e98ab2aac2c4a1210` | Worker repair and generalized operator-probe hardening are on main. |
| **W06.1** | `Lane - INTEGRATION EXACT-COMPILE REPAIR` | Cross-lane exact-compile repair for integrated attended follow-ups | **USABLE** | **MERGED** | Issue #50 closed; PR #52; `agent/integration-exact-compile-repair`; repaired head `8f533d8451d2a894fe3ead0eed05ac0adefb69a0` | Parent exact compile passed on the integrated runtime; repair is on main through PR #49. |
| **W05.1** | `Lane - PLAYER DISABLE / UNINSTALL ARCHITECTURE` | Launcher-off vanilla behavior + self-contained Biology uninstaller | **USABLE** | **MERGED** | Issue #44; PR #45 closed as superseded by integration; `agent/player-uninstall-vanilla-toggle` | Player-facing hard uninstall and Biology-specific residue verifier attended-passed; remaining launcher behavior is parent acceptance. |
| **W03.1** | `Thread 3 — E3 HUD, NPC nameplates, presentation settings` | E3-inspired neutral HUD + ambient NPC nameplates | **USABLE** | **MERGED** | Issue #40; PR #46 closed as superseded by integration; `agent/presentation-attended-followup` | Implementation is on main through PR #49; issue #40 remains for attended acceptance. |
| **W04.1** | `ATTENDED RUNTIME-AUTHORITY FOLLOW-UP` | Authoritative live Biology body runtime/session ownership | **USABLE** | **MERGED** | Issue #41; PR #47 closed as superseded by integration; `agent/body-runtime-attended-followup` | Implementation plus W06 compile repair are on main; issue #41 remains for attended acceptance. |
| **W02.1** | `Thread 2 — Biology UI and body runtime` | Biology native Cyberware shell/drill-down/back/mode-state follow-up | **USABLE** | **MERGED** | Issue #39; PR #43 closed as superseded by integration; `agent/biology-ui-attended-followup` | Implementation is on main through PR #49; issue #39 remains for attended acceptance. |
| **W01.1** | `Thread 1 — REDmod foundation` | Original REDmod package/deployment foundation | **USABLE** | **MERGED** | Issue #28; PR #31; historical branch `agent/redmod-foundation` | Foundation work is already on main. |
| **W02.6** | existing W02 worker conversation | Biology post-mount detail visibility | **USABLE** | **MERGED** | Issue #101; PR #103 merged; `agent/biology-detail-post-mount-visibility` | Implementation is on current main. Remaining acceptance is live T005; W17.1 now performs fresh reference/native archaeology before another layout iteration. |
| **W03.6** | existing W03 worker conversation | E3 quest/hotkey native content-region completion | **USABLE** | **READY-PARENT** | Issue #102; PR #104 open/draft; `agent/e3-quest-hotkey-content-region` | Do not merge yet. W03.7 supersedes the immediate parent gate by reconciling current main and completing full Project E3 archaeology first. |
| **W03.7** | existing W03 worker conversation | Project E3 full archaeology + W03.6/current-main reconciliation | **ACTIVE** | **IN-PROGRESS** | Issue #106; `agent/e3-reference-archaeology-integration`; handoff `docs/handoffs/W03.7-E3-REFERENCE-ARCHAEOLOGY.md` | Sequential W03 assignment. Consume the private Project E3 bundle from W16.1; return a current-main-reconciled PR for P02. |
| **W04.2** | existing W04 worker conversation | Body runtime persistence / authority proof | **USABLE** | **MERGED** | Issue #41; PR #90 merged | Source authority/persistence audit is merged; live WAIT/save-reload/SLEEP acceptance remains for T005. |
| **W15.3-W15.5** | existing W15 worker conversation | One-command attended session, prior-install transition, listener observation repair | **USABLE** | **MERGED** | Issues #79/#83/#86; PRs #82/#85/#88 merged | Command 17 owner lifecycle and listener fixes are on main and have passed subsequent attended sessions. |
| **W16.1** | new W16 worker conversation | Private reference-mod archaeology handoff tooling | **ACTIVE** | **IN-PROGRESS** | Issue #105; `agent/reference-mod-archaeology-workflow`; handoff `docs/handoffs/W16.1-REFERENCE-MOD-ARCHAEOLOGY.md` | Build one read-only private handoff bundle from `C:\Games\Cyberpunk-ReferenceMods`; no third-party payload committed to Git. |
| **W17.1** | new W17 worker conversation | Biology Cyberware/native-screen reference archaeology | **ACTIVE** | **IN-PROGRESS** | Issue #107; `agent/biology-ui-reference-archaeology`; handoff `docs/handoffs/W17.1-BIOLOGY-UI-REFERENCE-ARCHAEOLOGY.md` | Fresh conversation due W02 continuity problems; inspect native 2.31 + Cyberware-EX/reference implementations before T005. |

## Current integration relationship

```text
P02 parent
  |
  +-- current canonical main: 2657bae32c9d855fd90e5ffc7780148c6a8cf023
  +-- latest completed attended session: T004
  +-- next unallocated attended session: T005
  |
  +-- W02.6 / PR #103 MERGED
  |     `-- post-mount Biology detail sizing/diagnostics; live acceptance pending
  +-- W03.6 / PR #104 READY-PARENT but NOT YET MERGED
  |     `-- branch diverged after W02.6 merged
  |
  +-- pre-T005 process gate #105
        +-- W16.1 private reference-bundle tooling
        +-- W03.7 full Project E3 archaeology + current-main reconciliation
        +-- W17.1 Biology Cyberware/native-screen archaeology
```

**T005 is not ready yet.** P02 will allocate it only after the three pre-test lanes return, the selected E3/Biology work is merged deliberately, current-main CI is green, and the required exact supported-game compile/audit boundary is satisfied.

The next owner-facing live test remains one Command 17 attended session and should include Biology detail/navigation, E3 presentation, and #41 persistence acceptance.

## Routing another assignment

Before giving the user another worker handoff:
1. Check this ledger and `docs/AGENT-OPERATING-PATTERNS.md`.
2. Decide whether an existing recent worker conversation still has materially useful context and is manageable.
3. If yes and work is sequential, route the next assignment into that conversation and increment its decimal suffix, even when the new assignment gets a new GitHub issue/branch.
4. If the conversation is too long/stale/unrelated, or parallel execution requires a separate worker, allocate the next unused base `W##` and start at `.1`.
5. Record branch, issue, exact base/head state, scope, non-goals, and merge dependency independently from the conversation ID.

## Reusing a `USABLE` conversation

Reuse is appropriate when:
- the conversation is still manageable;
- its repo/subsystem context materially reduces rediscovery;
- the new assignment is closely related enough for that context to help;
- work is sequential rather than a simultaneous conflict;
- the parent explicitly routes the assignment or the user specifically chooses reuse.

A new issue or branch is compatible with reuse and is often desirable for clean Git ownership. `W15.1 -> W15.2` is the canonical example.

## When a worker conversation becomes too long

1. Mark the old conversation `TOO-LONG`.
2. Keep its rows as continuity/history.
3. Open the **next unused worker base ID** and start the new conversation at `.1`.
4. Give that new conversation a self-contained handoff with current branch/head, issue/PR, completed work, blockers/evidence, and immediate next action.
5. Do not label the replacement conversation `.2`; `.2` means a second sequential assignment in the same conversation.
6. Mark the predecessor `RETIRED` later if its context is no longer useful.

Historical parent `P01.1 -> P01.2` remains recorded as parent continuity and does not redefine the worker numbering rule above.

## Parent maintenance requirement

The parent owns this ledger except where a worker handoff explicitly delegates the narrow canonical-doc update, as W15.2 does. Update it whenever:
- a worker conversation is created;
- another sequential assignment is deliberately routed into an existing conversation;
- a conversation becomes active/inactive/too-long/retired;
- a worker returns `READY-PARENT`;
- an assignment becomes blocked, closed, superseded, or merged;
- a new parent conversation takes over.

A parent handoff is incomplete if this ledger does not accurately identify the active parent and active worker assignments.

## Worker responsibility

Workers read this ledger through `docs/PARALLEL-AGENT-WORKFLOW.md` and their handoff. A worker must not absorb unrelated or concurrent work merely because its conversation exists, but it may accept a new closely related sequential issue/branch when the parent/user explicitly routes it there.

When reporting completion, include the official assignment ID, exact branch/head, issue/PR, CI state, and remaining parent-owned attended acceptance.

## Relationship to GitHub state

This ledger does not replace issues, PRs, branches, `ROADMAP.md`, or test records.

Use:
- this file for conversation/assignment continuity and thread usability;
- GitHub issues for scope/acceptance;
- branches/PRs for implementation state;
- `ROADMAP.md` / active roadmap for product work state;
- `docs/test-runs/` for attended evidence;
- `docs/operator-evidence/` for small redistributable operator handoff state that future zero-local-repo commands must authenticate.

If the ledger and GitHub disagree about code state, GitHub is authoritative for code state and the parent must repair this ledger.