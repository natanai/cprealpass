# Biology parent/worker thread ledger

Status: **canonical active conversation/lane registry**  
Last updated: **2026-09-15**

> **MANDATORY:** Read this file before creating a new worker thread, reusing an old thread, replacing a thread that has become too long, or handing parent/orchestrator responsibility to a new conversation.

This ledger exists because Git branches/issues/PRs track code state, while ChatGPT conversations carry temporary working context. Both matter, but they are not the same thing.

The repository is the durable source of truth. A conversation is only a working context attached to a lane.

## Core rule

**A clear new goal should normally get a new lane/thread, even when an older usable conversation exists.**

An older `USABLE` thread is not the default destination for new work. Reuse it only when its existing context is directly valuable to a true continuation of the same goal. Do not keep stretching an old lane merely because it is convenient or already open.

When the user reports that a thread is becoming too long, treat that as an orchestration event. Update this ledger, stop treating that conversation as the active working surface, and create a replacement thread/handoff before continuing substantial work there.

## Lane IDs vs thread instances

A **lane** is the durable workstream/goal. A **thread instance** is one ChatGPT conversation carrying that lane at a particular time.

Official IDs use:

```text
P01.1   parent/orchestrator lane P01, first conversation instance
P01.2   same parent/orchestrator lane after the first parent thread becomes too long
W06.1   worker lane W06, first conversation instance
W06.2   same worker goal moved to a replacement conversation
W07.1   a genuinely new worker goal/lane
```

Rules:

- `P##` = parent/orchestrator lane.
- `W##` = worker lane.
- `.1`, `.2`, `.3`, ... = conversation generation for the **same** goal.
- A thread becoming too long increments only the generation when the same lane continues.
- A materially new goal gets a **new base lane ID**, not a new generation of an unrelated old lane.
- Branch and issue numbers remain the technical implementation identifiers; thread IDs exist to track conversation continuity.

## Recommended ChatGPT thread title

Use this shape for new/replacement conversations when practical:

```text
[P01.1] PARENT — Integration Orchestrator
[W06.1] INTEGRATION — Exact-Compile Repair
[W05.1] RELEASE — Player Disable / Uninstall
```

Existing conversations do not need to be renamed retroactively; the ledger maps their current visible title/alias to the official ID.

## Thread-state vocabulary

`ACTIVE`
: The conversation is currently receiving ongoing work. There should normally be only one active parent thread and only one active conversation instance for a given worker lane.

`USABLE`
: The conversation is not actively assigned work, but its existing context may be useful for a direct continuation. **Do not prefer it over a fresh lane for a new goal.**

`TOO-LONG`
: The user has reported the conversation has become too long or unwieldy. Do not continue substantial work there. Create a successor thread and record the successor ID.

`RETIRED`
: Do not route new work into this conversation. Historical context remains in chat/Git history only.

## Lane-work-state vocabulary

`IN-PROGRESS`
: Worker/parent is actively doing work.

`WAITING`
: Lane is temporarily waiting on another lane, user evidence, or an integration decision.

`READY-PARENT`
: Worker implementation is complete enough to return to the parent for review/integration; remaining attended/integration acceptance may still be pending.

`BLOCKED`
: A concrete blocker prevents the lane from progressing safely.

`MERGED`
: The lane's implementation is represented on canonical `main`.

`SUPERSEDED`
: Another lane now owns the work; do not continue implementation here unless the parent explicitly reopens it.

`CLOSED`
: Lane is complete without further active implementation.

## Current ledger

| Thread ID | Current visible title / alias | Role / goal | Thread state | Lane work state | GitHub / branch | Parent routing note |
|---|---|---|---|---|---|---|
| **P01.1** | `PARENT 1` | Parent / integration orchestrator | **ACTIVE** | **IN-PROGRESS** | Issue #35; integration PR #49; parent-owned `integration/attended-followups-2026-09-15` | Current parent. PR #49 is blocked on W06.1 exact-compile repair. If this conversation becomes too long, replace it with **P01.2** and update this table before continuing. |
| **W06.1** | `Lane - INTEGRATION EXACT-COMPILE REPAIR` | Cross-lane exact-compile repair for the integrated attended follow-ups | **ACTIVE** | **IN-PROGRESS** | Issue #50; `agent/integration-exact-compile-repair`; PR to target `integration/attended-followups-2026-09-15` | **User confirmed this thread is actively running.** Return repaired head to P01.1; do not merge #49 from the worker lane. |
| **W05.1** | `Lane - PLAYER DISABLE / UNINSTALL ARCHITECTURE` | Launcher-off vanilla behavior + self-contained Biology uninstaller | **USABLE** | **READY-PARENT** | Issue #44; PR #45; `agent/player-uninstall-vanilla-toggle`; head `f78f4daf9f9c4a612adfe5700cab87c40a3affe9` | Worker implementation is ready for parent integration/attended acceptance. Reuse only for directly relevant #44 knowledge or a narrowly requested correction. |
| **W03.1** | `Thread 3 — E3 HUD, NPC nameplates, presentation settings` | E3-inspired neutral HUD + ambient NPC nameplates | **USABLE** | **READY-PARENT** | Issue #40; PR #46; `agent/presentation-attended-followup`; head `ff08ac0661180ad09afedba920e3962c4117c928` | Native compile/audit completed on worker head. Parent owns combined integration and attended acceptance. |
| **W04.1** | `ATTENDED RUNTIME-AUTHORITY FOLLOW-UP` | Authoritative live Biology body runtime/session ownership | **USABLE** | **READY-PARENT** | Issue #41; PR #47; `agent/body-runtime-attended-followup`; head `44b9613155bcd2751d94ba7f04d2d27497eafacf` | Worker source is ready, but its interaction with #39 exposed the exact-compile defect now owned by W06.1. Do not reopen this lane by default for cross-lane repair. |
| **W02.1** | `Thread 2 — Biology UI and body runtime` | Biology native Cyberware shell/drill-down/back/mode-state follow-up | **USABLE** | **READY-PARENT** | Issue #39; PR #43; `agent/biology-ui-attended-followup`; head `cc9a84bf72b5660078e50ca3a3f10d1486907372` | Use this existing context only for a direct Biology-shell continuation that genuinely benefits from it. Cross-lane compile repair is W06.1. |
| **W01.1** | `Thread 1 — REDmod foundation` | Original REDmod package/deployment foundation | **USABLE** | **MERGED** | Issue #28; PR #31; historical branch `agent/redmod-foundation` | Foundation work is already represented on main. This conversation is historical-useful context, not the default lane for new REDmod goals. A new distinct REDmod task should normally receive a new W## lane. |

## Current integration relationship

At the time of this ledger update:

```text
P01.1 parent
  |
  +-- PR #49 integrated candidate (blocked from merge)
  |
  +-- W06.1 / issue #50 ACTIVE exact-compile repair
  |
  +-- W02.1 / #43 READY-PARENT
  +-- W03.1 / #46 READY-PARENT
  +-- W04.1 / #47 READY-PARENT
  +-- W05.1 / #45 READY-PARENT
```

The parent should not send the user back into all ready workers merely because those conversations remain usable. W06.1 is the active repair lane; the other worker threads are context reserves unless a specific finding is routed back to them.

## Creating a new lane/thread

Before giving the user a new worker handoff:

1. Check this ledger for a truly matching active lane.
2. Decide whether the task is a continuation or a new goal.
3. Prefer a **new W## lane** when the goal is materially new, the old branch is merged, or the old conversation has stale/overgrown context.
4. Assign the next unused base ID.
5. Add the new row here with `ACTIVE / IN-PROGRESS` before or alongside the handoff.
6. Put the official ID in the handoff and recommended chat title.
7. Record branch, issue, base/head state and merge dependency.

A new lane is often cleaner than asking an old conversation to mentally discard most of its previous scope.

## Reusing a `USABLE` thread

Reuse is appropriate only when all of the following are true:

- the goal is genuinely the same/substantially continuous;
- existing conversation knowledge materially reduces rediscovery;
- the existing branch/issue ownership still fits;
- the conversation has not been marked `TOO-LONG`;
- the parent explicitly routes work back there or the user specifically chooses it.

Otherwise create a new lane.

## When the user says a thread is too long

Immediately update orchestration state:

1. Change that row's thread state to `TOO-LONG`.
2. Do not delete the old row; it is the continuity record.
3. For the **same ongoing lane**, create the next generation (`W06.2`, `P01.2`, etc.).
4. Add the successor row with `ACTIVE` and record `successor of ...`.
5. Provide a self-contained handoff containing current branch/head, issue/PR, completed work, open blockers, evidence and next action.
6. If the work goal itself is changing, do **not** make `.2`; assign a fresh `W##` instead.
7. Mark the predecessor `RETIRED` later if its context is no longer useful at all.

The parent thread follows the same rule. `P01.1 -> P01.2` should be a routine continuity event, not an emergency reconstruction from chat memory.

## Parent maintenance requirement

The parent owns this ledger as integration state.

Update it whenever any of these happen:

- a worker thread is created;
- a thread becomes active/inactive;
- a worker returns `READY-PARENT`;
- a lane is blocked/superseded/merged;
- the user reports a thread is too long;
- a replacement conversation is created;
- work is deliberately routed back to a previously `USABLE` thread;
- a new parent thread takes over.

A parent handoff is incomplete if this ledger does not accurately identify the active parent and active workers.

## Worker responsibility

Workers must read this ledger through `docs/PARALLEL-AGENT-WORKFLOW.md` and their handoff.

A worker should not self-reactivate an old lane or absorb a new goal just because related context exists in its conversation. If a new substantial goal appears, report it to the parent and recommend a fresh lane.

When reporting completion, include the official thread ID so the parent can update `READY-PARENT`, `MERGED`, `SUPERSEDED`, etc.

## Relationship to GitHub state

This ledger does **not** replace issues, PRs, branches, `ROADMAP.md`, or test records.

Use:

- this file for **conversation/lane continuity and thread usability**;
- GitHub issues for scope/acceptance;
- branches/PRs for implementation state;
- `ROADMAP.md` / active roadmap for product work state;
- `docs/test-runs/` for attended evidence.

If the ledger and GitHub disagree about code state, GitHub is authoritative for the code. The parent must then fix this ledger rather than allowing the discrepancy to persist.
