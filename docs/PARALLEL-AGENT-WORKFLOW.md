# Parallel-agent development workflow

Status: **canonical collaboration policy**  
Last updated: **2026-09-16**

> **MANDATORY THREAD REGISTRY:** Before opening a worker conversation, routing another assignment into an existing one, or replacing one that has become too long, read `docs/AGENT-OPERATING-PATTERNS.md` and `docs/THREAD-LEDGER.md`.

The project owner can often run **2–3 agents concurrently**. Large work should be decomposed into independent branches when that improves throughput without creating merge/conflict risk. Conversation reuse is a separate question from Git branch ownership: one recent worker conversation may carry several closely related **sequential** issues/branches when its context remains useful.

Current code work still belongs in root `ROADMAP.md`, `ACTIVE-REDMOD-ROADMAP.md`, and current GitHub issues/PRs; current conversation/assignment continuity belongs in `THREAD-LEDGER.md`. This policy does **not** hard-code current worker branch names.

Parallel implementation is coordinated by one parent/integration conversation. Its canonical policy lives in `INTEGRATION-ORCHESTRATOR.md`.

The normal flow is:

```text
parent / integration conversation
        |
        +-- worker conversation W15
        |      +-- W15.1 -> issue/branch A -> PR -> parent merge
        |      `-- W15.2 -> issue/branch B -> PR -> parent merge
        |
        +-- independent worker conversation W16.1 when parallelism or unrelated work requires it
        |
        v
canonical main -> one release-shaped build -> attended local test -> durable evidence -> routing
```

## Parent / worker distinction

Workers own implementation. The parent owns integration state and the canonical conversation/assignment ledger.

The parent should:

- maintain `docs/THREAD-LEDGER.md` so active/usable/too-long/retired conversations and their sequential assignments are explicit;
- track current `main`, worker PRs/issues, and merge dependencies;
- decide merge order and whether a short-lived integration branch is needed;
- coordinate attended testing after selected work is integrated;
- capture attended results under `docs/test-runs/`;
- ingest small redistributable operator evidence under `docs/operator-evidence/` when later commands need it;
- route findings to a useful existing worker conversation or a new one according to `docs/AGENT-OPERATING-PATTERNS.md`.

The parent should not silently become another broad subsystem developer.

## Conversation numbering and assignment rule

`W##` identifies the worker **conversation lineage**. The decimal suffix is the sequential assignment number in that same conversation.

Canonical example:

```text
W15.1 -> issue #72 -> agent/failed-install-recovery-zip-validation
W15.2 -> issue #74 -> agent/operator-evidence-lifecycle
W16.1 -> first assignment in a newly opened worker conversation
```

Therefore:

- **closely related sequential work + useful manageable context** -> reuse the conversation and increment the decimal suffix;
- **new issue/branch but same useful sequential context** -> a new issue/branch is expected and does not require a new conversation;
- **conversation too long, materially stale, genuinely unrelated work, or simultaneous parallel work** -> open the next base `W##` and start it at `.1`;
- **old conversation merely exists** -> that alone is never a reason to reuse it.

Do not interpret `.2` as “replacement conversation.” If W15 becomes too long, the replacement is the next worker base (for example `W16.1`), not `W15.3` merely because another chat was opened.

A `USABLE` conversation is a context reserve that may deliberately receive another closely related sequential assignment; it is not a standing license to absorb unrelated work.

## Core parallelism rule

Agents should proactively look for safe parallelism. If a task contains multiple reasonably independent workstreams, the current agent should:

1. identify separable work;
2. keep one assignment in its current branch/conversation;
3. tell the user when another independent worker would materially help;
4. provide a copy/paste-ready handoff for the new conversation;
5. name repository, official assignment ID, branch, exact base revision, ownership boundary, non-goals, and merge dependency;
6. ensure the parent records the assignment in `THREAD-LEDGER.md`;
7. continue its own work unless actually blocked.

Do not split two implementations that must continuously edit the same core file/schema or where one depends on an unresolved interface from the other.

## Branch rules

Every implementation assignment uses its own branch. Do not use `main` as a shared scratchpad.

Recommended naming:

```text
agent/<short-domain>-<short-goal>
chatgpt/<short-domain>-<short-goal>
integration/<short-milestone>   # parent-owned, short-lived only
```

An assignment records:

- official `P##.#` or `W##.#` ID from `THREAD-LEDGER.md`;
- repository `natanai/cprealpass`;
- base branch/ref and exact base SHA;
- intended branch name;
- issue/PR identity;
- dependency on open work;
- owned scope and explicit non-goals.

Conversation continuity never permits branch ambiguity. A reused worker may move from one merged/closed branch to a new branch only because the parent/user explicitly routed the next assignment there.

## Ownership boundaries

Every handoff must state what the assignment owns and what it must not redesign.

For cross-cutting files such as `AGREED-GOALS.md`, `AGENTS.md`, root `ROADMAP.md`, `THREAD-LEDGER.md`, central manifests, shared schemas, and CI test lists, prefer one designated owner. `THREAD-LEDGER.md` is normally parent-owned; a worker edits it only when its handoff explicitly delegates that canonical-doc change.

If attended evidence reveals a deeper adjacent defect outside scope, route it explicitly rather than silently absorbing it.

## Required handoff packet

A copy/paste-ready handoff should contain:

1. official assignment ID and recommended chat title;
2. goal;
3. repository / branch / exact base SHA;
4. canonical reading, including `docs/AGENT-OPERATING-PATTERNS.md`, `docs/THREAD-LEDGER.md`, and this workflow;
5. owned scope;
6. non-goals;
7. known evidence;
8. deliverables;
9. acceptance criteria;
10. overlap/merge dependencies;
11. local evidence policy — read `docs/LOCAL-OPERATOR-COMMANDS.md` before asking the user to run anything;
12. merge/test rule — worker does not merge itself or ask the user to install/play its worker branch unless the parent explicitly chooses that exceptional path;
13. completion report — return exact head, CI, PR, remaining parent-owned acceptance, and whether the conversation remains `USABLE`.

## Progress reporting

An active assignment should report its official ID, branch/head, completed work, remaining work, tests/CI, any direct local evidence genuinely needed, overlap risks, merge dependencies, remaining attended acceptance, and PR number.

If a new problem is sequential and closely related, the parent may route it as the next decimal assignment in the same conversation. If it is independent enough to benefit from concurrent work or the current conversation is no longer suitable, recommend the next base worker conversation instead.

## Conversation too long / replacement procedure

When a worker conversation is too long:

1. stop substantial work there;
2. mark it `TOO-LONG` in `THREAD-LEDGER.md`;
3. allocate the next unused base worker ID and start the replacement conversation at `.1`;
4. provide a self-contained handoff with exact Git state, completed work, blockers/evidence, and immediate next action;
5. keep the old conversation as historical context only.

A replacement conversation does **not** inherit the old base number with a larger decimal suffix. Decimals enumerate sequential assignments within one conversation.

## PR and merge rules

Before a worker PR is merged:

- scope must be coherent and reviewable;
- relevant cloud-safe contracts must pass or any inherited canonical failure must be explicitly identified;
- base SHA/dependencies must be clear;
- overlapping files with other workers must be called out;
- superseded active code/docs should not remain as competing instructions;
- remaining attended checks must be explicit;
- the parent must understand the merge-queue position;
- the assignment should be reportable as `READY-PARENT`.

Workers do not merge their own PRs.

## Integration order

The parent normally:

1. inspects `THREAD-LEDGER.md`, ready PRs, and current `main`;
2. merges foundational/shared contract changes first where required;
3. updates dependent branches when necessary;
4. merges independent implementation assignments;
5. resolves conflicts deliberately;
6. verifies combined `main` CI;
7. builds one release-shaped candidate from fresh canonical source;
8. coordinates one attended test;
9. writes durable test/evidence records;
10. routes actionable findings and updates the ledger.

The user prefers integrated milestone testing rather than repeatedly installing separate worker builds.

## Local command and evidence coordination

Parallel agents must not send competing ad-hoc PowerShell blocks. Read `docs/LOCAL-OPERATOR-COMMANDS.md` first.

- use the catalogued entrypoint when one exists;
- assume zero local repository state unless independently proven otherwise;
- prefer a reusable repo tool over chat-embedded orchestration;
- one local operation should produce one obvious attachable evidence bundle/report;
- if returned evidence is needed later, the parent archives the redistributable record in `docs/operator-evidence/`;
- later zero-repo commands resolve that evidence by stable evidence ID and exact hashes, not by remembering an old loose path;
- local cleanup is tool-owned and fail-closed after repository evidence is confirmed;
- the local PC does not need GitHub write credentials for evidence ingestion.

Open-ended `KEEP THIS FILE UNTIL ...` instructions are not the steady-state contract. A binary candidate may survive temporarily only when the tooling machine-manages that bounded lifecycle.

## Relationship to attended testing

Player-facing testing normally happens after selected work is integrated into canonical `main` so one release-shaped package exercises the combined state. Use `docs/CLEAN-ROOM-TESTING.md` and `docs/LOCAL-OPERATOR-COMMANDS.md`.

Every attended handoff binds evidence to exact canonical source, exact artifact, game-state evidence, test mode, and a focused acceptance checklist.

## Conflict prevention

Before routing work, inspect `THREAD-LEDGER.md` and current issues/PRs. Common conflict hotspots include `AGREED-GOALS.md`, `AGENTS.md`, roadmaps, `THREAD-LEDGER.md`, decision history, central runtime/package manifests, shared schemas/controllers, distribution manifests, and CI lists.

One assignment should own the canonical resolution when those surfaces overlap.

## Current work lookup rule

Do not derive current code implementation state from this policy file, and do not derive current conversation state from old chat titles.

To find current work:

1. read `docs/AGENT-OPERATING-PATTERNS.md` for numbering/reuse/evidence conventions;
2. read `THREAD-LEDGER.md` for active/usable/too-long/retired conversation state;
3. read root `ROADMAP.md` and `ACTIVE-REDMOD-ROADMAP.md` for product work;
4. inspect current GitHub issues/PRs;
5. inspect the latest attended test/evidence record when work is test-driven.

## Definition of success

The workflow is working when:

- large tasks are split when useful without the user designing the split;
- recent worker conversations are deliberately reused for several closely related sequential assignments when that reduces rediscovery;
- each implementation assignment still has clean issue/branch/PR ownership;
- new conversations are opened when parallelism, unrelated scope, staleness, or length requires them;
- canonical docs remain singular rather than accumulating competing active instructions;
- attended failures become durable evidence and named follow-ups;
- the user tests one coherent combined build;
- local evidence is repo-backed when needed later and local cleanup is machine-managed;
- a new parent/worker can recover current state from the repository, ledger, GitHub, and durable evidence without the previous chat transcript.
