# Biology integration/orchestrator workflow

Status: **canonical parent-thread policy**  
Last updated: **2026-09-15**

The long-lived parent integration thread keeps parallel Biology workers coherent, mergeable and testable. It is not primarily a feature-development lane and must not quietly become a fourth broad implementation lane.

Current worker names belong in root `ROADMAP.md`, `ACTIVE-REDMOD-ROADMAP.md`, and GitHub issues/PRs. This policy intentionally stays branch-agnostic.

## Parent-thread responsibilities

The parent owns five things:

1. **Merge orchestration** — exact-main awareness, PR scope/CI/overlap review, merge order and conflict resolution.
2. **Local-test orchestration** — one reproducible attended path against an exact integrated artifact.
3. **Evidence capture** — convert screenshots, logs, tool-generated reports and observations into durable test records.
4. **Finding triage** — give every actionable attended finding an explicit owner/route.
5. **Redistribution** — produce issue updates/copy-paste handoffs so workers do not depend on the parent chat transcript.

## What the parent may implement

The parent may handle:

- small merge-conflict resolution;
- integration-only glue;
- canonical documentation/test-contract alignment;
- tiny fixes whose ownership is genuinely integration-specific.

Substantive body runtime, Biology UI, presentation, package/release, combat, clothing or simulation work normally goes to a worker lane.

## Current-state lookup

Before making merge/test decisions, the parent should read:

1. `AGENTS.md`
2. root `ROADMAP.md`
3. `AGREED-GOALS.md`
4. this document
5. `PARALLEL-AGENT-WORKFLOW.md`
6. `CLEAN-ROOM-TESTING.md`
7. `ACTIVE-REDMOD-ROADMAP.md`
8. `LOCAL-OPERATOR-COMMANDS.md`
9. latest relevant `docs/test-runs/` record
10. current open issues/PRs

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

Prefer the **original agent** when the finding is clearly in its still-current owned scope and a follow-up on that implementation is natural.

### Route B — new follow-up branch for the same subsystem

Prefer a **new agent/thread** when the original branch is already merged, the defect is substantial/deeper than expected, or the original context has become stale.

### Route C — cross-lane integration issue

Use when the failure exists only because multiple otherwise-correct lanes interact and no single worker owns it cleanly.

### Route D — parent handles a tiny integration-only fix

Use sparingly for stale cross-references, trivial merge glue, canonical test-contract alignment or another truly small integration concern.

Do not use Route D merely because the parent is convenient.

## Redistributing attended evidence

A worker handoff should include:

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

The parent should periodically summarize:

```text
<lane> — issue/branch/PR — status — CI — merge dependency — remaining attended acceptance
```

Do not ask the user to remember which old thread owns what.

## Parent-thread continuity

The repository and GitHub state, not chat memory, are the source of continuity.

Before replacing a parent thread, update durable state where needed and provide:

- current main SHA;
- active worker issues/PRs;
- merge order/dependencies;
- latest attended test record;
- unresolved findings/owners;
- next expected test mode/artifact.

Reusable startup packet: `docs/handoffs/PARENT-INTEGRATION.md`.

## Definition of success

The orchestration model is working when:

- workers focus on clear subsystem ownership;
- merges happen deliberately;
- active docs do not resurrect merged branch plans;
- the user tests one coherent canonical artifact;
- local commands are standardized and report-file based where useful;
- screenshots/logs become durable repository evidence;
- every regression has a named route/owner;
- a replacement parent can recover current state without the previous chat transcript.
