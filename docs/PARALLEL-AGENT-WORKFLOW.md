# Parallel-agent development workflow

Status: **canonical collaboration policy**  
Last updated: **2026-09-15**

> **MANDATORY THREAD REGISTRY:** Before creating a worker conversation, reusing an older one, or replacing one that has become too long, read and update `THREAD-LEDGER.md`.

The project owner can often run **2–3 agents concurrently**. Large work should be decomposed into independent branches whenever doing so improves throughput without creating unnecessary merge/conflict risk.

This document defines the collaboration policy. Current code work still belongs in root `ROADMAP.md`, `ACTIVE-REDMOD-ROADMAP.md`, and current GitHub issues/PRs; current **conversation/lane continuity** belongs in `THREAD-LEDGER.md`.

Parallel implementation is coordinated by one parent/integration thread. Its canonical policy lives in `INTEGRATION-ORCHESTRATOR.md`.

The default pattern is:

```text
                   parent / integration thread
                              |
current canonical main        |
      |                       |
      +-- worker branch A  -> PR -> CI --+
      |                       |           |
      +-- worker branch B  -> PR -> CI --+--> parent merge/integration review
      |                       |           |             |
      +-- worker branch C  -> PR -> CI --+             v
                                                   canonical main
                                                         |
                                                         v
                                              one release-shaped build
                                                         |
                                                         v
                                                attended local test
                                                         |
                                                         v
                                              durable evidence + routing
```

## Parent / worker distinction

Worker lanes own implementation. The parent owns integration state **and the canonical conversation/thread ledger**.

The parent should:

- maintain `docs/THREAD-LEDGER.md` so active/usable/too-long/retired conversations are explicit;
- track current `main`, open worker PRs/issues and merge dependencies;
- decide merge order and whether a short-lived integration branch is needed;
- coordinate the local-test handoff after selected lanes are integrated;
- capture attended results under `docs/test-runs/`;
- route findings to the original worker, a new follow-up lane, a cross-lane issue, or a tiny integration-only fix.

The parent should **not** silently become another broad subsystem developer.

## Lane and conversation rule

A lane is a goal/workstream; a ChatGPT conversation is a temporary context carrying that lane.

Use the IDs and state vocabulary in `THREAD-LEDGER.md`.

The default decision rule is:

- **same goal + existing context is materially useful** -> an existing `ACTIVE`/`USABLE` thread may continue;
- **same goal + thread became too long** -> create the next conversation generation for the same lane (`W06.1 -> W06.2`);
- **materially new goal** -> create a new worker lane ID (`W07.1`), even if an older related thread exists;
- **old thread merely exists** -> that alone is never a reason to reuse it.

A `USABLE` conversation is a context reserve, not a standing assignment.

## Core rule

Agents should proactively look for safe parallelism.

If a task is large and contains multiple reasonably independent workstreams, the current agent should:

1. identify separable lanes;
2. keep one lane in its current branch/thread;
3. tell the user additional agents can work in parallel;
4. provide a copy/paste-ready handoff for each recommended new thread;
5. name repository, official thread/lane ID, branch, exact base revision, ownership boundary and merge dependency;
6. ensure the parent adds/updates the new lane in `THREAD-LEDGER.md`;
7. continue its own lane unless actually blocked.

The user should not have to invent the division of labor or remember which chat is still active.

## When to split

Prefer parallel branches when work separates cleanly by stable interface, file family, evidence task or product layer. Examples:

- package/release tooling vs body simulation;
- native/game-data investigation vs implementation;
- Biology body shell vs first-person presentation;
- runtime authority vs visual shell, when the consumer contract is explicit;
- build/test tooling vs unrelated runtime feature work;
- documentation/contract cleanup vs a feature lane;
- uninstall/release UX vs visual presentation.

Also prefer a fresh lane when an apparently related task has a **new concrete goal**. Do not force unrelated follow-up work into an old conversation simply because it already knows the subsystem.

## When not to split

Do not parallelize merely to maximize agent count when:

- both agents would continuously edit the same core file/schema;
- one lane cannot make a correct decision until another defines an unresolved interface;
- the change is small enough that coordination costs more than implementation;
- partial implementations would create competing authorities;
- a lane would need to guess at another lane's unpublished schema/API.

When unsure, split research/audit from implementation before splitting two implementations of the same behavior.

## Branch rules

Every worker lane uses its own branch. Do not use `main` as a shared scratchpad.

Recommended naming:

```text
agent/<short-domain>-<short-goal>
chatgpt/<short-domain>-<short-goal>
integration/<short-milestone>   # parent-owned, short-lived only
```

A lane must record:

- official `P##.#` or `W##.#` conversation/thread ID from `THREAD-LEDGER.md`;
- repository: `natanai/cprealpass`;
- base branch/ref;
- exact base SHA;
- intended branch name;
- dependency on any open PR/branch;
- owned scope and explicit non-goals.

If work truly depends on unmerged code, either branch explicitly from that dependency and document the stack or wait for it to merge.

Do not quietly base work on another agent's unidentified/unpublished worktree.

## Ownership boundaries

Every handoff must state what the lane owns and what it must not redesign.

For cross-cutting files such as `AGREED-GOALS.md`, `AGENTS.md`, root `ROADMAP.md`, `THREAD-LEDGER.md`, central manifests, shared model schemas and CI test lists, prefer one designated owner. Other lanes should report required changes rather than independently creating conflicting canonical edits.

`THREAD-LEDGER.md` is parent-owned. Workers report state changes; the parent performs the canonical routing update unless the handoff explicitly delegates that tiny documentation change.

If attended evidence reveals a deeper defect adjacent to but outside a lane's scope, route it explicitly instead of absorbing it silently.

## Required handoff packet

A copy/paste-ready handoff should contain:

1. **Official thread/lane ID and recommended chat title** from `THREAD-LEDGER.md`.
2. **Goal** — concrete outcome.
3. **Repository / branch / exact base SHA**.
4. **Canonical reading**, including `docs/THREAD-LEDGER.md` and this workflow.
5. **Owned scope**.
6. **Non-goals / boundaries**.
7. **Known evidence** — including exact attended artifact/test record when relevant.
8. **Deliverables**.
9. **Acceptance criteria**.
10. **Coordination dependencies / overlap risks**.
11. **Local evidence policy** — read `docs/LOCAL-OPERATOR-COMMANDS.md` before asking the user to run anything.
12. **Merge/test rule** — worker does not merge itself or ask the user to install that worker branch unless the parent explicitly chooses that path.
13. **Completion report rule** — return the thread ID, exact head, CI, remaining attended acceptance and whether the thread should remain `USABLE` afterward.

A good handoff should not require the receiving agent to reconstruct the task from the original chat transcript.

## Progress reporting

An active lane should report:

- official thread/lane ID;
- branch name and exact head SHA;
- what is complete;
- what remains;
- tests/CI status;
- direct local evidence needed, if any;
- overlaps with other active branches;
- merge dependencies;
- remaining attended acceptance;
- PR number when opened.

If the lane discovers another large independent problem, explicitly recommend a **new** branch/thread and new `W##` ID rather than expanding scope indefinitely.

## Thread too long / replacement procedure

When the user reports that a worker thread is too long:

1. Stop treating that conversation as active for substantial new work.
2. Tell the parent to mark it `TOO-LONG` in `THREAD-LEDGER.md`.
3. If the same goal continues, create the next generation (`W03.2`, etc.) and preserve the lane/branch/issue relationship.
4. If the goal changes materially, create a new `W##` lane instead.
5. Give the replacement thread a self-contained handoff with current branch/head, issue/PR, completed work, blocker/evidence and immediate next action.

Do not ask a replacement conversation to infer state from the old chat.

## PR and merge rules

Before a worker PR is merged:

- scope must be coherent and reviewable;
- relevant cloud-safe contracts must pass;
- base SHA/dependencies must be clear;
- overlapping files with other workers must be called out;
- superseded active code/docs should be removed rather than left as competing instructions;
- remaining direct-game/attended checks must be explicit;
- the parent should understand how the PR fits the current merge queue;
- the worker's lane state should be reportable as `READY-PARENT` in `THREAD-LEDGER.md`.

Do not merge merely because an agent reports lots of progress.

## Integration order

The parent should normally:

1. inspect `THREAD-LEDGER.md`, ready PRs and current canonical `main`;
2. merge foundational/shared contract changes first where required;
3. update/rebase dependent branches if necessary;
4. merge independent implementation lanes;
5. resolve conflicts deliberately;
6. verify combined `main` CI;
7. build one combined release-shaped candidate from fresh canonical source;
8. coordinate one attended test;
9. write the durable test record;
10. route each actionable finding and update the ledger.

The user prefers integrated milestone testing rather than repeatedly reinstalling separate worker builds.

## Local command/evidence coordination

Parallel agents must not send the user competing ad-hoc PowerShell blocks.

Before requesting a local command, read `docs/LOCAL-OPERATOR-COMMANDS.md`.

- use the catalogued entrypoint when one exists;
- do not assume a permanent repository path;
- prefer a reusable repo tool over chat-embedded orchestration;
- if output is materially useful to an agent, the repo-owned tool should write a plain-text report the user can return rather than requiring a large console paste;
- the parent should coordinate overlapping probes so the user is not asked for the same evidence repeatedly.

## Relationship to attended testing

Parallel development does not mean parallel contamination of the game install.

Player-facing testing normally happens after selected lanes are integrated into canonical `main` so one release-shaped package exercises the combined state.

Use the tiers in `docs/CLEAN-ROOM-TESTING.md` and the canonical commands in `docs/LOCAL-OPERATOR-COMMANDS.md`.

Every attended handoff still binds evidence to:

- exact canonical `main` SHA;
- exact package/artifact;
- game-state evidence;
- test mode;
- focused acceptance checklist.

## Conflict prevention

Before creating a lane, inspect `THREAD-LEDGER.md` and current issues/PRs when practical.

Common conflict hotspots include:

- `AGREED-GOALS.md`;
- `AGENTS.md`;
- `ROADMAP.md` / `docs/ACTIVE-REDMOD-ROADMAP.md`;
- `docs/THREAD-LEDGER.md`;
- `docs/DECISION-HISTORY.md`;
- central runtime/package manifests;
- body-runtime/shared body schemas;
- shared UI shell/controller files;
- package/distribution manifests;
- CI test lists.

These can still change in parallel when necessary, but one lane should own the canonical resolution and the parent should coordinate the merge.

## Current work lookup rule

Do not derive current **code implementation state** from this policy file, and do not derive current **conversation state** from old chat titles alone.

To find current work:

1. read `THREAD-LEDGER.md` for active/usable/too-long/retired conversation state;
2. read root `ROADMAP.md`;
3. read `ACTIVE-REDMOD-ROADMAP.md`;
4. inspect current GitHub issues/PRs;
5. inspect the latest attended test record when the work is test-driven.

Merged branch names may appear in Git history and dated evidence; that does not make them active again. A `USABLE` chat may remain valuable context without being an active implementation lane.

## Definition of success

The workflow is working when:

- large tasks are split when useful without the user designing the split;
- new goals usually get clean new lanes instead of being stuffed into whichever old chat is available;
- workers have clear ownership and do not redefine each other's scope;
- a parent thread keeps merge/test state and conversation state coherent;
- canonical docs remain singular rather than accumulating competing active instructions;
- attended failures become durable evidence and named follow-ups;
- the user tests one coherent combined build;
- local evidence requests are standardized and reusable;
- a new parent/worker can recover current state from the repository, ledger and GitHub without the previous chat transcript.
