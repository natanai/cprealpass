# Biology integration/orchestrator workflow

Status: **canonical parent-thread policy**  
Last updated: **2026-09-15**

> **MANDATORY CURRENT-THREAD LOOKUP:** Before creating, reusing, replacing, or routing work to any ChatGPT conversation, read `THREAD-LEDGER.md`. The parent owns that ledger and must keep it current.

The long-lived parent integration thread keeps parallel Biology workers coherent, mergeable and testable. It is not primarily a feature-development lane and must not quietly become a fourth broad implementation lane.

Current worker implementation names belong in root `ROADMAP.md`, `ACTIVE-REDMOD-ROADMAP.md`, GitHub issues/PRs, and the canonical conversation registry in `THREAD-LEDGER.md`. This policy intentionally stays branch-agnostic.

## Parent-thread responsibilities

The parent owns six things:

1. **Thread/lane continuity** — maintain `THREAD-LEDGER.md`, including the active parent, active workers, usable historical threads, replacements and too-long transitions.
2. **Merge orchestration** — exact-main awareness, PR scope/CI/overlap review, merge order and conflict resolution.
3. **Local-test orchestration** — one reproducible attended path against an exact integrated artifact.
4. **Evidence capture** — convert screenshots, logs, tool-generated reports and observations into durable test records.
5. **Finding triage** — give every actionable attended finding an explicit owner/route.
6. **Redistribution** — produce issue updates/copy-paste handoffs so workers do not depend on the parent chat transcript.

## What the parent may implement

The parent may handle:

- small merge-conflict resolution;
- integration-only glue;
- canonical documentation/test-contract alignment;
- tiny fixes whose ownership is genuinely integration-specific.

Substantive body runtime, Biology UI, presentation, package/release, combat, clothing or simulation work normally goes to a worker lane.

## Thread/lane registry rule

`docs/THREAD-LEDGER.md` is the official registry for conversation continuity.

The parent must use it to distinguish:

- **lane goal** from **conversation instance**;
- currently `ACTIVE` conversations from merely `USABLE` older ones;
- worker completion (`READY-PARENT`) from thread usability;
- a thread that has become `TOO-LONG` from a lane that is still active.

A clear new goal should normally receive a new worker lane/thread even when an older usable conversation exists. Old usable threads are context reserves, not default routing destinations.

When the user reports that any thread—including the parent—has become too long, update the ledger before continuing substantial work there. The same lane may continue in the next thread generation (`P01.1 -> P01.2`, `W06.1 -> W06.2`); a materially new goal gets a new base lane ID instead.

## Current-state lookup

Before making merge/test/routing decisions, the parent should read:

1. `AGENTS.md`
2. `THREAD-LEDGER.md`
3. root `ROADMAP.md`
4. `AGREED-GOALS.md`
5. this document
6. `PARALLEL-AGENT-WORKFLOW.md`
7. `CLEAN-ROOM-TESTING.md`
8. `ACTIVE-REDMOD-ROADMAP.md`
9. `LOCAL-OPERATOR-COMMANDS.md`
10. latest relevant `docs/test-runs/` record
11. current open issues/PRs

Do not reconstruct current state from merged worker handoffs or dated baseline files.

## Merge queue and readiness

A worker saying “ready” is an input, not the merge decision.

Before merging, verify:

- exact branch/head/base SHA;
- owned scope matches the issue/handoff;
- unrelated redesign did not leak in;
- relevant CI/tests are green on the exact head;
- attended behavior is not being falsely claimed from source/CI;
- dependencies/overlaps with other workers are explicit;
- shared-file conflicts have a deliberate resolution plan;
- remaining local/direct-game acceptance is documented.

When a worker becomes ready, update its ledger row to `READY-PARENT` rather than leaving the user to remember which chat has finished.

## Merge order

Prefer foundational/shared contract changes first when other work depends on them, then independent runtime/UI/presentation/release lanes, then small integration glue.

When interaction risk is high, the parent may create a **short-lived integration branch** such as:

```text
integration/<milestone-name>
```

from current main, combine the intended heads there, run CI and resolve conflicts. Do not maintain a long-lived second mainline.

## Canonical-main rule

Before reviewing final merge order, generating a test artifact, or asking the user to launch, the parent must know the **exact canonical `main` SHA**.

Worker branches may start from older SHAs. The parent decides whether they can merge cleanly, must update/rebase, or depend on another PR landing first.

## Local attended testing

Every user-facing handoff must state:

1. **Test mode:** `ITERATION` or `MILESTONE CLEAN-ROOM`.
2. Exact canonical main SHA.
3. Game-state evidence, described accurately.
4. Exact artifact/package identity and checksum when available.
5. What changed since the previous attended run.
6. Focused acceptance checks derived from the merged work.

### ITERATION

Use when package/game structure has not changed in a way that makes residue uncertain and the current ownership/reset policy can account safely for the previous Biology install.

### MILESTONE CLEAN-ROOM

Use for structural package/framework/game-patch changes, unexplained residue, or deliberate release-level confidence. A fresh Steam uninstall + residual-directory deletion + reinstall is strong evidence; the additional exhaustive whole-game hash pass may be skipped only under the documented policy and must not then be reported as full baseline verification.

A Steam reinstall is not normal Biology uninstall. Player disable/hard-removal work is tracked separately in current release UX work.

## Local command rule

Before giving the user PowerShell/CMD instructions, read `LOCAL-OPERATOR-COMMANDS.md`.

- Use a canonical repository-owned command when one exists.
- Do not assume a permanent repository checkout path.
- Prefer a self-bootstrapping/active-checkout-aware tool over chat-embedded orchestration.
- Do not paste a repository tool's internals into chat merely to avoid invoking it.
- Long-running operations need durable console progress.
- If diagnostic output is materially useful to an agent, the tool should write a plain-text report under the active checkout's `reports/` directory and print that path.
- Ask the user to return the report file instead of manually copy/pasting a large console transcript.
- If a recurring probe is missing, improve the repository tool/catalog/test contract first.

The parent coordinates overlapping local probes so multiple workers do not ask the user for the same evidence independently.

## Attended test records

Every meaningful attended milestone should produce a record under:

```text
docs/test-runs/
```

Recommended name:

```text
YYYY-MM-DD-<short-main-sha>-<slug>.md
```

Record:

- date/time window;
- Cyberpunk version;
- exact canonical main SHA;
- artifact/checksum;
- test mode;
- game-state evidence;
- merged PRs/issues;
- expected checks;
- observed results;
- screenshot/log/report context;
- finding IDs;
- **Owner / route** for each actionable finding;
- milestone disposition: accepted, partially accepted or rejected.

## Routing findings

### Route A — return to the original worker lane/thread

Prefer the **original agent** only when the finding is clearly in its still-current owned scope, the ledger marks that thread `ACTIVE` or `USABLE`, and the existing context materially helps a true continuation.

Do not route to an old thread solely because it exists.

### Route B — new follow-up branch/thread for the same subsystem

Prefer a **new agent/thread** when the original branch is already merged, the defect is substantial/deeper than expected, the goal is materially new, or the original context has become stale/too long.

Assign a new `W##` lane in `THREAD-LEDGER.md` unless this is strictly a replacement conversation for the same still-active lane.

### Route C — cross-lane integration issue

Use when the failure exists only because multiple otherwise-correct lanes interact and no single worker owns it cleanly.

### Route D — parent handles a tiny integration-only fix

Use sparingly for stale cross-references, trivial merge glue, canonical test-contract alignment or another truly small integration concern.

Do not use Route D merely because the parent is convenient.

## Redistributing attended evidence

A worker handoff should include:

- official thread/lane ID from `THREAD-LEDGER.md`;
- exact tested main SHA;
- exact artifact/checksum;
- Cyberpunk version;
- expected vs observed behavior;
- screenshot/log/report evidence;
- setting/menu/context needed to reproduce;
- issue/roadmap IDs;
- explicit ownership boundary;
- whether to amend an active PR or open a follow-up PR;
- overlap/dependency with other workers.

The implementation worker should not need the parent conversation to understand the failure.

## Active-worker reporting

The parent should periodically summarize from the ledger:

```text
<thread ID> — <lane> — issue/branch/PR — thread state — lane work state — CI — merge dependency — remaining attended acceptance
```

Do not ask the user to remember which old thread owns what.

## Parent-thread continuity

The repository and GitHub state, not chat memory, are the source of continuity.

Before replacing a parent thread:

1. mark the current parent thread `TOO-LONG` in `THREAD-LEDGER.md` when that is the reason for replacement;
2. create the next parent conversation generation (for example `P01.2`);
3. add the successor row as `ACTIVE`;
4. update durable integration state where needed;
5. provide the replacement parent the current integration packet.

That packet must include:

- current main SHA;
- active/usable thread ledger state;
- active worker issues/PRs;
- merge order/dependencies;
- latest attended test record;
- unresolved findings/owners;
- next expected test mode/artifact.

Reusable startup packet: `docs/handoffs/PARENT-INTEGRATION.md`.

## Definition of success

The orchestration model is working when:

- workers focus on clear subsystem ownership;
- new goals normally receive clean new lanes rather than opportunistically reusing old chats;
- the parent can identify exactly which conversations are active, usable, too long or retired from `THREAD-LEDGER.md`;
- merges happen deliberately;
- active docs do not resurrect merged branch plans;
- the user tests one coherent canonical artifact;
- local commands are standardized and report-file based where useful;
- screenshots/logs become durable repository evidence;
- every regression has a named route/owner;
- a replacement parent can recover current state without the previous chat transcript.
