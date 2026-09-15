# Parallel-agent development workflow

Status: **canonical collaboration policy**
Last updated: **2026-09-14**

The project owner can often run **2–3 agents concurrently**. Large work should therefore be decomposed into independent branches whenever doing so improves throughput without creating unnecessary merge/conflict risk.

The default development pattern is:

```text
current canonical main
      |
      +-- agent/lane-a-...   -> PR -> CI -> merge
      |
      +-- agent/lane-b-...   -> PR -> CI -> merge
      |
      +-- agent/lane-c-...   -> PR -> CI -> merge
                                  |
                                  v
                         combined canonical main
                                  |
                                  v
                      one attended combined test
```

## Core rule

Agents should **proactively look for safe parallelism**.

If a task is large and contains two or more reasonably independent workstreams, the current agent should not silently serialize all of them. It should:

1. identify the separable lanes;
2. keep one lane in the current thread/branch;
3. tell the user that additional agents can usefully work in parallel;
4. provide a copy/paste-ready handoff for each recommended new thread;
5. name the intended branch, base revision, ownership boundary and merge dependency;
6. continue its own lane without waiting unless the work is actually blocked.

The user should not have to invent the division of labor from scratch.

## When to split work

Prefer parallel branches when work can be separated by a stable interface, file family, evidence task or product layer. Good examples:

- REDmod packaging/dependency migration vs gameplay simulation changes;
- native/game-data research vs implementation;
- Biology UI shell vs combat model/calibration;
- clothing/armor authority vs food/body-need routing;
- build/test tooling vs runtime code;
- documentation/contract cleanup vs a separate implementation lane;
- different subsystems that share only already-defined model interfaces.

A large undertaking is a strong candidate for 2–3 lanes if each lane can make meaningful progress and pass its own tests without repeatedly editing the same central files.

## When not to split

Do **not** parallelize merely to maximize agent count when the work is tightly coupled.

Keep work together when:

- two agents would edit the same core file/algorithm throughout the task;
- lane B cannot make a correct decision until lane A establishes an unresolved interface;
- the change is small enough that coordination overhead exceeds implementation time;
- the work is a single delicate migration where partial independent implementations would create competing authorities;
- one lane would need to guess at another lane's unmerged schema or API.

When unsure, split **research/audit** from **implementation** before splitting two implementations of the same behavior.

## Branch rules

Every parallel lane works on its own branch. Do not use `main` as a shared scratchpad.

Recommended branch naming:

```text
agent/<short-domain>-<short-goal>
chatgpt/<short-domain>-<short-goal>
```

Existing project branch conventions may also be used; clarity matters more than the literal prefix.

A lane must record its starting point:

- repository: `natanai/cprealpass`;
- base branch: normally `main`;
- exact base SHA;
- intended branch name;
- whether it depends on another open PR/branch.

If the lane truly depends on unmerged work, either:

- branch explicitly from that dependency and document the stack; or
- wait for that dependency to merge.

Do not quietly base a branch on another agent's unpublished/unidentified worktree.

## Ownership boundaries

Each handoff must state what the lane **owns** and what it must **not** redesign.

Example:

```text
Lane owns:
- REDmod package skeleton
- info.json/deploy proof
- dependency classification manifest

Lane must not change:
- body simulation equations
- Biology visual layout
- combat injury semantics
```

This reduces accidental competing implementations.

For cross-cutting canonical files such as `AGREED-GOALS.md`, `AGENTS.md`, shared manifests, or central model schemas, prefer one designated lane to make the final edit. Other lanes should report required changes in their PR/handoff rather than all editing the same canonical file independently.

## Required handoff packet for a new agent/thread

When recommending a parallel lane, provide a handoff the user can paste into a new thread. It should contain:

1. **Goal** — the concrete outcome, not “continue project.”
2. **Repository and branch** — exact repo, proposed branch, and base SHA/ref.
3. **Canonical reading** — relevant goals/docs/files that must be read first.
4. **Owned scope** — what this lane may change.
5. **Non-goals / boundaries** — what belongs to another lane.
6. **Known evidence** — relevant game snapshot paths, accepted decisions, current failures.
7. **Deliverables** — code/docs/tests/manifest/PR expected.
8. **Acceptance criteria** — what must be true before the lane reports ready to merge.
9. **Coordination dependencies** — other active branches/PRs and expected merge order.
10. **User assistance allowed** — targeted PowerShell/game-data probe if direct local evidence would help.

A good handoff is self-contained enough that the new agent does not need the original chat transcript.

## Example handoff shape

```text
Work on repo natanai/cprealpass.
Create branch: agent/redmod-package-audit
Base: current main at <SHA>.

Read first:
- AGENTS.md
- AGREED-GOALS.md
- docs/BIOLOGY-REDMOD-MIGRATION.md
- docs/PARALLEL-AGENT-WORKFLOW.md

Goal:
Classify and prototype the official REDmod packaging path for Biology.

Own:
- REDmod package skeleton and deployment tooling
- dependency/runtime packaging inventory
- load-order/deploy evidence
- tests/docs for those boundaries

Do not redesign:
- body/combat equations
- Biology UI visual layout
- clothing mechanics

Deliver:
- branch + PR
- classification results
- tests/contracts
- exact remaining blockers

If direct installed-game evidence is needed, ask me for one read-only PowerShell command rather than guessing.
```

## Progress reporting

An active lane should report back with:

- branch name and current head;
- what is complete;
- what remains;
- CI/test status;
- any direct local evidence needed;
- whether it discovered additional safe parallel work;
- whether it is ready for PR/merge.

If the lane discovers a second large independent problem, it should explicitly say something like:

> “This can be split safely. I can continue X here; a second agent can take Y on branch Z. Here is the handoff.”

That is preferred over either blocking the entire lane or quietly expanding scope indefinitely.

## PR and merge rules

Before a parallel branch is merged:

- its scope should be coherent and reviewable;
- relevant cloud-safe tests/contracts should pass;
- the PR should identify its base SHA and any dependent PR;
- it should state overlapping files/areas with other active branches;
- superseded code/docs should be removed rather than left as competing active paths;
- any required follow-up lane should be explicit.

Do not merge a branch merely because it has “lots of progress.” Merge when its owned contract is internally coherent.

## Integration order

When multiple branches are ready:

1. merge foundational schema/contract/package changes first;
2. update/rebase dependent branches against the resulting `main` if necessary;
3. merge independent implementation lanes;
4. resolve integration conflicts deliberately — do not choose “ours/theirs” blindly in canonical files;
5. run post-merge CI on the combined `main`;
6. build **one combined release-shaped candidate** from fresh canonical source;
7. test the combined behavior in-game.

The project owner prefers testing integrated milestones, not separately reinstalling the game for every agent branch.

## Relationship to attended testing

Parallel development does **not** mean parallel local game contamination.

Agents work independently in Git branches, but player-facing testing should normally happen after selected lanes are merged into canonical `main` so one release-shaped package exercises the combined state.

Use the test tiers in `docs/CLEAN-ROOM-TESTING.md`:

- small integrated iteration -> fresh repo + baseline-verified reused game install;
- large structural milestone / dependency or package change -> milestone clean-room test.

The exact test handoff still must identify the canonical `main` SHA and package artifact.

## Conflict prevention

Before creating a lane, inspect active branches/PRs when practical. If another agent is already changing the same subsystem, coordinate rather than create a third competing implementation.

Particular conflict hotspots:

- `AGREED-GOALS.md`;
- `AGENTS.md`;
- `docs/DECISION-HISTORY.md`;
- central runtime manifests;
- `BodyRuntime.reds` / shared body schemas;
- shared UI shell/controller files;
- package/distribution manifests;
- CI test lists.

These can still be changed in parallel when necessary, but one lane should be designated as the integration owner.

## Biology REDmod migration: preferred initial split

For the current large migration described in `docs/BIOLOGY-REDMOD-MIGRATION.md`, the preferred 2–3 agent split is:

### Lane A — official REDmod/package/dependency architecture

Own:
- `mods/Biology` package skeleton;
- official deploy/load/enable workflow;
- dependency inventory and removal candidates;
- release/install/uninstall shape;
- load-order/conflict evidence.

### Lane B — runtime seam classification/migration

Own:
- audit of current `.reds`/native hooks;
- classification as REDMOD-NATIVE / REDMOD-POSSIBLE-BUT-BRITTLE / REDSCRIPT-BETTER / REQUIRES-NATIVE-EXTENSION / REMOVE / UNKNOWN;
- targeted game probes for uncertain native seams;
- low-risk runtime migrations after classification.

### Lane C — Biology product/UI/settings identity

Own:
- player-facing rename from RealPass to Biology;
- Biology/Cyberware hierarchy consistency;
- provider-neutral minimal settings direction;
- removal of stale RealPass/Mod Settings assumptions from current presentation/docs where safe;
- no risky mass rename of internal classes merely for cosmetics.

These lanes should coordinate through documented contracts rather than share a mutable local worktree.

## Definition of success

The workflow is working when:

- large tasks are split when useful without the user having to design the split;
- agents can work independently without silently redefining each other's scope;
- branches are reviewable and merge in a known order;
- canonical docs remain singular rather than forked into competing instructions;
- the user tests one coherent combined build from `main`;
- local game state remains auditable and is not layered with mystery branch residue.