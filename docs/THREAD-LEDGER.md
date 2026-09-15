# Biology parent/worker thread ledger

Status: **canonical active conversation/lane registry**  
Last updated: **2026-09-15**

> **MANDATORY:** Read this file before creating a new worker thread, reusing an old thread, replacing a thread that has become too long, or handing parent/orchestrator responsibility to a new conversation.

The repository is the durable source of truth. Git issues/branches/PRs track code state; ChatGPT conversations carry temporary working context attached to a lane.

## Core rule

**A clear new goal should normally get a new lane/thread, even when an older usable conversation exists.**

An older `USABLE` thread is a context reserve, not the default destination for new work. Reuse it only when its existing context is directly useful to a true continuation of the same goal.

When the user reports that a thread is becoming too long, treat that as an orchestration event: update this ledger, stop treating that conversation as the active working surface, and create a replacement thread/handoff before continuing substantial work there.

## Lane IDs vs thread instances

A **lane** is the durable workstream/goal. A **thread instance** is one ChatGPT conversation carrying that lane at a particular time.

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
- `.1`, `.2`, `.3`, ... = conversation generation for the same goal.
- A thread becoming too long increments only the generation when the same lane continues.
- A materially new goal gets a new base lane ID.
- Branch and issue numbers remain the implementation identifiers; thread IDs track conversation continuity.

## Recommended ChatGPT thread title

```text
[P01.1] PARENT — Integration Orchestrator
[W06.1] INTEGRATION — Exact-Compile Repair
[W05.1] RELEASE — Player Disable / Uninstall
```

Existing conversations do not need retroactive renaming; this ledger maps their visible title/alias to the official ID.

## Thread-state vocabulary

`ACTIVE`
: The conversation is currently receiving ongoing work.

`USABLE`
: The conversation is not actively assigned work, but its existing context may help with a direct continuation. **Do not prefer it over a fresh lane for a new goal.**

`TOO-LONG`
: The user has reported the conversation has become too long or unwieldy. Do not continue substantial work there.

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
: The lane's implementation is represented on canonical `main`.

`SUPERSEDED`
: Another lane now owns the work.

`CLOSED`
: The lane's assigned goal is complete; no further active implementation is expected.

## Current ledger

| Thread ID | Current visible title / alias | Role / goal | Thread state | Lane work state | GitHub / branch | Parent routing note |
|---|---|---|---|---|---|---|
| **P01.1** | `PARENT 1` | Parent / integration orchestrator | **ACTIVE** | **IN-PROGRESS** | Issue #35; integration PR #49; parent-owned `integration/attended-followups-2026-09-15` | Current parent. Exact compile now passes; parent is finishing PR #49 integration and preparing one attended candidate. If this conversation becomes too long, replace it with **P01.2** before continuing. |
| **W06.1** | `Lane - INTEGRATION EXACT-COMPILE REPAIR` | Cross-lane exact-compile repair for the integrated attended follow-ups | **USABLE** | **CLOSED** | Issue #50 closed; PR #52 merged into PR #49; `agent/integration-exact-compile-repair`; repaired head `8f533d8451d2a894fe3ead0eed05ac0adefb69a0` | Parent exact compile passed on integrated head `1a97607332bb6237fb7516b35d1a292403fb2740`. Reuse this thread only if the same compile-repair topic directly resurfaces; a different integration failure gets a new W## lane. |
| **W05.1** | `Lane - PLAYER DISABLE / UNINSTALL ARCHITECTURE` | Launcher-off vanilla behavior + self-contained Biology uninstaller | **USABLE** | **READY-PARENT** | Issue #44; PR #45; `agent/player-uninstall-vanilla-toggle`; head `f78f4daf9f9c4a612adfe5700cab87c40a3affe9` | Worker implementation is already represented in PR #49. Remaining validation is parent/integration attended acceptance. |
| **W03.1** | `Thread 3 — E3 HUD, NPC nameplates, presentation settings` | E3-inspired neutral HUD + ambient NPC nameplates | **USABLE** | **READY-PARENT** | Issue #40; PR #46; `agent/presentation-attended-followup`; head `ff08ac0661180ad09afedba920e3962c4117c928` | Worker implementation is already represented in PR #49. Parent owns combined attended acceptance. |
| **W04.1** | `ATTENDED RUNTIME-AUTHORITY FOLLOW-UP` | Authoritative live Biology body runtime/session ownership | **USABLE** | **READY-PARENT** | Issue #41; PR #47; `agent/body-runtime-attended-followup`; head `44b9613155bcd2751d94ba7f04d2d27497eafacf` | Worker implementation plus the W06 repair are represented in PR #49. Do not reopen by default for unrelated runtime work. |
| **W02.1** | `Thread 2 — Biology UI and body runtime` | Biology native Cyberware shell/drill-down/back/mode-state follow-up | **USABLE** | **READY-PARENT** | Issue #39; PR #43; `agent/biology-ui-attended-followup`; head `cc9a84bf72b5660078e50ca3a3f10d1486907372` | Worker implementation is already represented in PR #49. Use this context only for a direct shell continuation that truly benefits from it. |
| **W01.1** | `Thread 1 — REDmod foundation` | Original REDmod package/deployment foundation | **USABLE** | **MERGED** | Issue #28; PR #31; historical branch `agent/redmod-foundation` | Foundation work is already on main. A new distinct REDmod goal should normally receive a new W## lane. |

## Current integration relationship

```text
P01.1 parent
  |
  +-- PR #49 integrated candidate
  |     +-- #43 / W02.1 READY-PARENT
  |     +-- #46 / W03.1 READY-PARENT
  |     +-- #47 / W04.1 READY-PARENT
  |     +-- #45 / W05.1 READY-PARENT
  |     +-- #52 / W06.1 CLOSED
  |
  +-- exact CP2077 2.31 compile PASS on integrated runtime
  +-- next: green current-head CI -> merge PR #49 -> one attended candidate
```

No separate implementation worker is currently active. The parent should not send the user back into ready/closed worker threads merely because those conversations remain usable.

## Creating a new lane/thread

Before giving the user a new worker handoff:
1. Check this ledger for a truly matching active lane.
2. Decide whether the task is a continuation or a new goal.
3. Prefer a **new W## lane** when the goal is materially new, an old branch is merged/closed, or the old conversation has stale/overgrown context.
4. Assign the next unused base ID.
5. Add the new row here with `ACTIVE / IN-PROGRESS` before or alongside the handoff.
6. Put the official ID in the handoff and recommended chat title.
7. Record branch, issue, base/head state and merge dependency.

## Reusing a `USABLE` thread

Reuse is appropriate only when all of the following are true:
- the goal is genuinely the same/substantially continuous;
- existing conversation knowledge materially reduces rediscovery;
- existing branch/issue ownership still fits;
- the conversation has not been marked `TOO-LONG`;
- the parent explicitly routes work back there or the user specifically chooses it.

Otherwise create a new lane.

## When the user says a thread is too long

1. Change that row's thread state to `TOO-LONG`.
2. Keep the old row as the continuity record.
3. For the **same ongoing lane**, create the **next generation** (`W06.2`, `P01.2`, etc.).
4. Add the successor row with `ACTIVE` and record the predecessor.
5. Provide a self-contained handoff with current branch/head, issue/PR, completed work, blockers, evidence and next action.
6. If the work goal itself changed, assign a fresh `W##` instead of `.2`.
7. Mark the predecessor `RETIRED` later if its context is no longer useful.

The parent follows the same rule: `P01.1 -> P01.2` is a routine continuity event, not an emergency reconstruction from chat memory.

## Parent maintenance requirement

The parent owns this ledger. Update it whenever:
- a worker thread is created;
- a thread becomes active/inactive;
- a worker returns `READY-PARENT`;
- a lane is blocked, closed, superseded or merged;
- the user reports a thread is too long;
- a replacement conversation is created;
- work is deliberately routed back to a `USABLE` thread;
- a new parent thread takes over.

A parent handoff is incomplete if this ledger does not accurately identify the active parent and active workers.

## Worker responsibility

Workers read this ledger through `docs/PARALLEL-AGENT-WORKFLOW.md` and their handoff. A worker should not self-reactivate an old lane or absorb a new goal merely because related context exists in its conversation.

When reporting completion, include the official thread ID so the parent can update `READY-PARENT`, `CLOSED`, `MERGED`, `SUPERSEDED`, etc.

## Relationship to GitHub state

This ledger does not replace issues, PRs, branches, `ROADMAP.md`, or test records.

Use:
- this file for conversation/lane continuity and thread usability;
- GitHub issues for scope/acceptance;
- branches/PRs for implementation state;
- `ROADMAP.md` / active roadmap for product work state;
- `docs/test-runs/` for attended evidence.

If the ledger and GitHub disagree about code state, GitHub is authoritative for the code and the parent must repair this ledger.