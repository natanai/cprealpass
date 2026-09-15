# Biology integration/orchestrator workflow

Status: **canonical parent-thread policy**
Last updated: **2026-09-15**

This document defines the long-lived **parent integration thread** for Biology.

The parent thread is not primarily a feature-development lane. Its job is to keep the work from multiple implementation agents coherent, testable, and evidence-driven.

The project should generally look like this:

```text
                    PARENT / INTEGRATION THREAD
                              |
              +---------------+---------------+
              |               |               |
              v               v               v
        worker lane A    worker lane B    worker lane C
        own branch       own branch       own branch
              |               |               |
              +------ PR / CI / review -------+
                              |
                              v
                        canonical main
                              |
                              v
                    one release-shaped build
                              |
                              v
                     attended local test
                              |
                              v
                   versioned test evidence
                              |
                              v
                route findings back to lanes
```

## Parent-thread responsibilities

The parent integration thread owns five things:

1. **Merge orchestration** — decide merge order, inspect PR scope/CI, handle integration conflicts deliberately, and keep canonical `main` coherent.
2. **Local-test orchestration** — give the user one clean, reproducible test path against an exact `main` SHA and release-shaped artifact.
3. **Evidence capture** — turn screenshots, logs, PowerShell output and observed behavior into a durable test record tied to the exact candidate.
4. **Finding triage** — classify each live-test finding by subsystem/ownership and decide whether it goes back to an existing worker lane, becomes a follow-up for the original agent, or deserves a new lane.
5. **Redistribution** — produce copy/paste-ready handoffs or issue updates so implementation agents receive the evidence they actually need without depending on the parent chat transcript.

The parent thread should remain aware of the current active roadmap, open issues/PRs, exact canonical `main`, and the most recent attended test record.

## What the parent thread should NOT become

The parent thread should not quietly turn into a fourth broad implementation lane.

It may make:

- small merge-conflict resolutions;
- integration-only glue;
- documentation/test-contract updates;
- tiny cross-lane fixes where ownership is genuinely integration-specific.

It should normally route substantive subsystem work back to a worker branch rather than implementing it itself. This keeps the parent context focused on project state, merge order, testing, and redistribution.

If a substantive fix clearly belongs to Biology UI, presentation/HUD, REDmod packaging, combat, clothing, body simulation, or another defined subsystem, the parent should assign it to that owner instead of absorbing it.

## Merge queue and readiness

A worker agent saying “ready” is an input, not the merge decision.

Before merging a worker PR, the parent should verify:

- the PR is based on an identified canonical `main` revision or clearly documents any stack/dependency;
- the owned scope matches its handoff/issue;
- unrelated subsystem redesign did not leak into the branch;
- relevant CI/tests are green on the exact PR head;
- user-attended acceptance is not being falsely claimed for behavior that has not been live-tested;
- dependencies on other open branches are explicit;
- any shared/canonical file conflicts have a deliberate resolution plan;
- the PR explains remaining direct-game probes or attended-test requirements.

Do not merge based only on commit volume or “lots of progress.”

## Merge order

Prefer this order when dependencies exist:

1. foundational package/schema/contract changes;
2. runtime/UI/presentation lanes that depend on those foundations;
3. independent implementation lanes;
4. integration-only glue or conflict resolution;
5. combined `main` CI;
6. one combined attended test.

When lanes are truly independent and green, sequential merges to `main` are acceptable.

When interaction risk is high, the parent may first create a short-lived integration branch such as:

```text
integration/<milestone-name>
```

from current `main`, combine the candidate lane heads there, resolve conflicts, and run CI before allowing the same combination onto canonical `main`.

Do **not** maintain a long-lived divergent “integration branch” as a second mainline. Integration branches are disposable staging tools only.

## Canonical-main rule

The parent thread should always know the exact current `main` SHA before:

- reviewing merge order;
- creating a local-test handoff;
- generating a release-shaped artifact;
- asking the user to launch the game;
- routing a regression back to an implementation lane.

A worker branch may have started from an older SHA. That is normal. The parent decides whether it can merge cleanly as-is, must be updated/rebased, or should be tested only after another prerequisite lands.

## Local attended testing

The parent thread owns the final test handoff after selected worker lanes have merged.

Use `docs/CLEAN-ROOM-TESTING.md` and the mandatory test-mode rules in `AGENTS.md`.

Every test handoff must state:

1. **Test mode:** `ITERATION` or `MILESTONE CLEAN-ROOM`.
2. **Exact canonical `main` SHA.**
3. **Game-state evidence:** baseline-verified reused install, or why a reinstall/clean-room reset is required.
4. **Exact artifact/package identity.**
5. **What changed since the previous attended test.**
6. **A focused test checklist** derived from the merged issues/acceptance criteria.

The local repository is disposable and should be replaced/fresh-cloned for every user-facing test build.

The Cyberpunk installation does **not** need to be reinstalled for every small iteration. Reuse is allowed only when the repository tooling can account for prior Biology payload and prove the game returns to the recorded vanilla baseline. Structural package/framework/REDmod milestones, game patches, unexplained residue, or failed baseline proof escalate to a milestone clean-room test.

## Attended test records

Every meaningful attended milestone should produce a durable test record under:

```text
docs/test-runs/
```

Recommended name:

```text
YYYY-MM-DD-<short-main-sha>-<slug>.md
```

The record should contain:

- date/time window;
- Cyberpunk version;
- exact canonical `main` SHA;
- artifact/package identifier and build command;
- test mode;
- vanilla-baseline evidence/reset state;
- merged PRs/issues included in the candidate;
- expected acceptance checklist;
- observed results;
- screenshots/logs supplied by the user;
- KEEP / FIX / REMOVE observations where useful;
- new finding IDs;
- ownership/routing decision for every actionable finding;
- whether the candidate is accepted, partially accepted, or rejected for the milestone.

The purpose is not bureaucracy. It prevents live evidence from being trapped in a chat and gives future agents a factual record of what actually appeared in-game.

Use `docs/test-runs/README.md` for the template.

## Routing findings after a test

For each finding, the parent should choose one of four routes.

### Route A — return to the original worker lane/thread

Prefer the original agent when:

- the finding is plainly inside that lane's original ownership;
- the implementation context is still current;
- the branch/PR is still active or a small follow-up is natural;
- there is value in the original agent seeing whether its intended behavior matched the attended result.

Example: the HUD agent's PR renders the wrong nameplate spacing in-game. Send that evidence back to the HUD agent first.

### Route B — new follow-up branch for the same subsystem

Prefer a new agent/thread when:

- the original branch is already merged/closed and the new work is substantial;
- the test exposed a deeper problem not anticipated by the original implementation;
- the original thread has become too long/stale to work efficiently;
- an independent implementation/review would reduce risk.

The parent should create or recommend a new issue/branch with a copy/paste-ready handoff containing the exact test evidence.

### Route C — cross-lane integration issue

Use this when the failure only appears from the interaction of multiple lanes and no single original lane owns it cleanly.

Examples:

- REDmod package routing causes Biology UI assets not to load;
- presentation settings conflict with the new Biology navigation shell;
- two individually correct hooks compete after merge.

The parent may own a narrow integration branch or create a dedicated integration issue.

### Route D — parent handles a tiny integration-only fix

Use sparingly for:

- obvious merge glue;
- a stale cross-reference;
- a test contract that must reflect already-agreed behavior;
- a trivial conflict that does not require subsystem redesign.

Do not use this route merely because the parent is convenient.

## How to redistribute evidence

When sending a finding to an implementation agent, include:

- exact tested `main` SHA;
- exact package/build identity;
- game version;
- screenshot/log description;
- expected behavior;
- observed behavior;
- whether it reproduces with a setting ON/OFF or specific menu/context;
- affected roadmap/issue IDs if known;
- explicit ownership boundary;
- whether the agent should amend its existing PR, open a follow-up PR, or only investigate/report.

The implementation agent should not need to reconstruct the failure from the parent's conversation history.

## Local evidence and targeted probes

The parent may ask the user for direct local evidence when needed.

Prefer one copy/paste-ready read-only PowerShell block that either:

- emits a small filtered result; or
- writes large output to a file the user can return.

If a worker agent needs local evidence, the parent can coordinate it so the user does not receive three overlapping or contradictory game-file probes at once.

Durable conclusions from a probe should be written back into repository docs/tests/reference metadata by the appropriate owner.

## Active-worker communication

The parent thread should periodically inspect active issues/PRs and report a concise project state such as:

```text
Lane A — REDmod foundation: PR open, CI green, merge dependency: none
Lane B — Biology UI/runtime: still implementing, needs one game probe
Lane C — HUD/nameplates: PR open, CI green, should merge after Lane A
Next combined test: after A + C + B are integrated
```

This is preferred over asking the user to manually remember which thread owns which work.

## Parent-thread continuity

Because a parent conversation can itself become long, the repository—not chat memory—is the source of continuity.

Before a parent thread ends, it should update durable state where needed and give the user a new-parent handoff containing:

- current `main` SHA;
- open worker issues/PRs;
- merge order/dependencies;
- most recent attended test record;
- unresolved findings and their owners;
- next test mode/artifact expectation.

A replacement parent thread should begin by reading:

1. `AGENTS.md`
2. `ROADMAP.md`
3. `AGREED-GOALS.md`
4. `docs/INTEGRATION-ORCHESTRATOR.md`
5. `docs/PARALLEL-AGENT-WORKFLOW.md`
6. `docs/CLEAN-ROOM-TESTING.md`
7. the latest file under `docs/test-runs/`
8. current open issues/PRs.

## Definition of success

The parent/integration model is working when:

- worker agents can focus on clearly owned implementation;
- merges happen in a deliberate order instead of whichever thread finishes first;
- the user tests one coherent canonical build, not mystery mixtures of branches;
- local game state remains auditable against vanilla;
- attended screenshots/logs become durable repository evidence;
- each regression has a named owner and branch/issue route;
- the user does not have to manually coordinate three agent conversations;
- a new parent thread can recover project state from the repository without needing the old chat transcript.
