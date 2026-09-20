# Biology integration/orchestrator workflow

Status: **canonical parent-thread policy**  
Last updated: **2026-09-17**

> **MANDATORY CURRENT-THREAD LOOKUP:** Before opening, reusing, replacing, or routing work to any ChatGPT conversation, read `AGENT-OPERATING-PATTERNS.md`, `docs/test-runs/TEST-LEDGER.md`, the latest completed numbered attended record, and `THREAD-LEDGER.md`. Also inspect any open `[T###]` attended tracking issue. The parent owns these continuity records and must keep them current.

The long-lived parent integration conversation keeps Biology workers coherent, mergeable and testable. It is not primarily a feature-development lane and must not quietly become a fourth broad implementation lane.

Current worker implementation names belong in root `ROADMAP.md`, `ACTIVE-REDMOD-ROADMAP.md`, GitHub issues/PRs, and the canonical conversation registry in `THREAD-LEDGER.md`. This policy intentionally stays branch-agnostic.

## Parent responsibilities

The parent owns six things:

1. **Conversation/assignment continuity** — maintain `THREAD-LEDGER.md`, including the active parent, active worker conversations, sequential assignments, usable historical context, and too-long/retired transitions.
2. **Merge orchestration** — exact-main awareness, PR scope/CI/overlap review, merge order and conflict resolution.
3. **Local-test orchestration** — one reproducible attended path against an exact integrated artifact.
4. **Evidence capture** — convert screenshots, logs, tool-generated reports and observations into durable test/evidence records.
5. **Finding triage** — give every actionable attended finding an explicit owner/route.
6. **Redistribution** — produce issue updates/copy-paste handoffs so workers do not depend on the parent chat transcript.

## What the parent may implement

The parent may handle small merge-conflict resolution, integration-only glue, canonical documentation/test-contract alignment, durable evidence ingestion, and tiny fixes whose ownership is genuinely integration-specific.

Substantive body runtime, Biology UI, presentation, package/release, combat, clothing or simulation work normally goes to a worker assignment.

## Conversation/assignment registry rule

`docs/THREAD-LEDGER.md` is the official registry for conversation continuity. `docs/AGENT-OPERATING-PATTERNS.md` defines the worker numbering/reuse rule.

For workers, `W##` identifies the conversation lineage and the decimal suffix identifies the sequential assignment handled in that same conversation. The canonical example is:

```text
W15.1 -> issue #72 -> first assignment in worker conversation W15
W15.2 -> issue #74 -> second assignment in that same conversation
W16.1 -> first assignment in a newly opened worker conversation
```

The parent should deliberately reuse a recent worker conversation when its repo/subsystem context is still materially useful and the next work is sequential. A new issue/branch/PR is still expected when the implementation goal is distinct enough to deserve clean Git ownership; conversation reuse never means branch reuse by accident.

Open a new worker conversation only when the existing one is too long/unwieldy, materially stale, genuinely unrelated to the next assignment, or simultaneous parallel work needs another independent agent. A new conversation receives the next unused base `W##` and starts at `.1`; `.2` is not a replacement-chat marker.

A `USABLE` conversation is a context reserve that may receive another closely related sequential assignment by deliberate parent/user routing. It is not a standing assignment and should not absorb unrelated work merely because it exists.

## Current-state lookup

Before merge/test/routing decisions, the parent should read:

1. `AGENTS.md`
2. `AGENT-OPERATING-PATTERNS.md`
3. `THREAD-LEDGER.md`
4. root `ROADMAP.md`
5. `AGREED-GOALS.md`
6. this document
7. `PARALLEL-AGENT-WORKFLOW.md`
8. `CLEAN-ROOM-TESTING.md`
9. `ACTIVE-REDMOD-ROADMAP.md`
10. `LOCAL-OPERATOR-COMMANDS.md`
11. latest relevant `docs/test-runs/` and `docs/operator-evidence/` records
12. current open issues/PRs

Do not reconstruct current state from merged worker handoffs, dated baseline files, or old chat titles.

## Merge queue and readiness

A worker saying “ready” is an input, not the merge decision. Before merging, verify exact branch/head/base SHA, issue/handoff scope, CI on that exact head, overlap/dependencies, no unrelated redesign, no false attended claims, and explicit remaining direct-game acceptance.

When an assignment becomes ready, update its ledger work state to `READY-PARENT` rather than leaving the user to remember which conversation has finished.

## Merge order

Prefer foundational/shared contract changes first when other work depends on them, then independent runtime/UI/presentation/release assignments, then small integration glue.

When interaction risk is high, the parent may create a **short-lived integration branch** such as `integration/<milestone-name>` from current main, combine the intended heads there, run CI and resolve conflicts. Do not maintain a long-lived second mainline.

## Canonical-main rule

Before reviewing final merge order, generating a test artifact, or asking the user to launch, the parent must know the **exact canonical `main` SHA**. Worker branches may start from older SHAs; the parent decides whether they can merge cleanly, must update/rebase, or depend on another PR landing first.

## Local attended testing

Every user-facing handoff must state:

1. **Test mode:** `ITERATION` or `MILESTONE CLEAN-ROOM`.
2. Exact canonical main SHA.
3. Game-state evidence, described accurately.
4. Exact artifact/package identity and checksum when available.
5. What changed since the previous attended run.
6. Focused acceptance checks derived from merged work.

### ITERATION

Use when package/game structure has not changed in a way that makes residue uncertain and the current ownership/reset policy can account safely for the previous Biology install.

### MILESTONE CLEAN-ROOM

Use for structural package/framework/game-patch changes, unexplained residue, or deliberate release-level confidence. A fresh Steam uninstall + residual-directory deletion + reinstall is strong evidence; the additional exhaustive whole-game hash pass may be skipped only under the documented policy and must not then be reported as full baseline verification.

A Steam reinstall is not normal Biology uninstall. Player disable/hard-removal work is tracked separately in current release UX work.

## Local command and operator-evidence rule

Before giving the user PowerShell/CMD instructions, read `LOCAL-OPERATOR-COMMANDS.md`.

- Use a canonical repository-owned command when one exists.
- Do not assume a permanent repository checkout path; zero local repo is supported.
- Prefer self-bootstrapping/active-checkout-aware tools over chat-embedded orchestration.
- Do not paste a repository tool's internals into chat merely to avoid invoking it.
- Long-running operations need durable console progress.
- One managed operator operation should normally return one obvious attachable evidence bundle/report.
- When returned redistributable state is needed later, the parent ingests `evidence.json` + `report.txt` under `docs/operator-evidence/<evidence-id>/`; the local PC does not need GitHub write credentials.
- Later commands resolve stable evidence IDs and exact hashes, not arbitrary old loose paths.
- Local cleanup is repo-confirmed and fail-closed; human-maintained open-ended KEEP/delete lists are not the steady-state contract.

The parent coordinates overlapping local probes so multiple workers do not ask the user for the same evidence independently.

## Attended test records

Every meaningful attended milestone should produce a record under `docs/test-runs/`, normally named `YYYY-MM-DD-<short-main-sha>-<slug>.md`.

Record date/time window, Cyberpunk version, exact canonical main SHA, artifact/checksum, test mode, game-state evidence, merged PRs/issues, expected checks, observations, screenshot/log/report context, finding IDs, **Owner / route**, and milestone disposition.

## Routing findings

### Route A — deliberately reuse a recent useful worker conversation

Prefer an existing `ACTIVE`/`USABLE` worker conversation when its current context materially helps the next sequential assignment and the conversation remains manageable. This is allowed even when the finding needs a **new GitHub issue, new branch, and new PR**. Increment the decimal assignment suffix in that same worker lineage, as with `W15.1 -> W15.2`.

Do not route into an old conversation solely because it exists.

### Route B — open a new worker conversation

Use the next unused base worker ID at `.1` when the current/relevant conversation is too long, materially stale, genuinely unrelated to the next work, or the work should run in parallel with another assignment. The new conversation receives a self-contained handoff and clean issue/branch ownership.

Do **not** use `.2` to mean a replacement conversation.

### Route C — cross-assignment integration issue

Use when a failure exists only because multiple otherwise-correct assignments interact and no single worker owns it cleanly.

### Route D — parent handles a tiny integration-only fix

Use sparingly for stale cross-references, trivial merge glue, canonical test-contract alignment, durable evidence ingestion, or another truly small integration concern. Do not use Route D merely because the parent is convenient.

## Redistributing attended evidence

A worker handoff should include official assignment ID, exact tested main SHA, exact artifact/checksum, Cyberpunk version, expected vs observed behavior, screenshot/log/report evidence, reproduction context, issue/roadmap IDs, explicit ownership boundary, new/amended Git branch/PR direction, and overlap/dependencies.

The implementation worker should not need the parent conversation transcript to understand the failure.

## Active-worker reporting

The parent should periodically summarize from the ledger:

```text
<assignment ID> — <goal> — issue/branch/PR — conversation state — assignment work state — CI — merge dependency — remaining attended acceptance
```

Do not ask the user to remember which old conversation owns what.

## Parent-thread continuity

The repository and GitHub state, not chat memory, are the source of continuity. Historical parent numbering such as `P01.1 -> P01.2` remains part of the ledger. If a parent conversation must be replaced, update the ledger and provide a self-contained successor packet rather than expecting reconstruction from chat memory.

Reusable startup packet: `docs/handoffs/PARENT-INTEGRATION.md`.

## Definition of success

The orchestration model is working when:

- workers focus on clear subsystem ownership;
- recent useful worker conversations can carry several related sequential assignments without conflating their Git issues/branches;
- new conversations are opened when length, staleness, unrelated scope, or parallelism requires them;
- the parent can identify conversation and assignment state from `THREAD-LEDGER.md`;
- merges happen deliberately;
- active docs/tests do not freeze transient worker state or resurrect merged branch plans;
- the user tests one coherent canonical artifact;
- local commands/evidence are standardized and cleanup is machine-managed;
- screenshots/logs become durable repository evidence;
- every regression has a named route/owner;
- a replacement parent can recover current state without the previous chat transcript.


## Numbered attended-test continuity

Live owner sessions are parent-owned `T###` records. The parent allocates a number before launch, binds it to the exact source SHA and acceptance checklist in GitHub without moving that source SHA, then commits the completed record after evidence returns.

A fresh parent must never infer "what test are we on?" from chat ordering. Read `docs/test-runs/TEST-LEDGER.md` and current `[T###]` GitHub tracking first.

A test may have:
- an operational session result, such as listener/install/startup PASS;
- separate gameplay/UI acceptance results, which may be PARTIAL or FAIL.

Do not let an operational PASS overwrite observed gameplay failures.
