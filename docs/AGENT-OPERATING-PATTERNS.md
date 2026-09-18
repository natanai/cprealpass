# Canonical agent and operator workflow patterns

Status: **mandatory operating convention**  
Last updated: **2026-09-17**

This file records project-owner workflow conventions that future parent and worker agents must preserve. It exists so these rules do not depend on chat memory.

## 1. Local repository state is always disposable

Every separate user-facing local instruction must begin from this assumption:

```text
Existing local cprealpass repo/worktree: ASSUME NONE
Required repository source: ACQUIRE EXACT PINNED REVISION EACH TIME
Temporary clone/worktree afterward: DISPOSABLE
```

A command may opportunistically discover and validate an existing `natanai/cprealpass` checkout, but correctness must never depend on one surviving from a prior turn. Do not tell the user to maintain a permanent repo under `C:\Games`, and do not point a later operation at an earlier temporary path merely because it once existed.

Repo-dependent operator commands must be zero-local-repo-safe: resolve/fetch an exact expected revision, create disposable source/worktree state when necessary, record the exact revision used, and clean temporary repo/worktree state when the operation is finished.

The persistent state on the user's PC is the supported Cyberpunk installation and any explicitly machine-managed operator handoff bundle—not an assumed repository checkout.

## 2. Worker conversation reuse is preferred when context is still useful

The project owner prefers reusing a recent worker ChatGPT conversation for **several closely related sequential assignments** when that conversation still has useful repository/subsystem context.

Do not automatically create a brand-new worker conversation for every attended follow-up. Prefer reuse when:

- the worker conversation is still manageable;
- its repo/subsystem knowledge materially reduces rediscovery;
- the new assignment is adjacent enough that the existing context helps;
- no parallelism requires a separate simultaneous worker.

Create a new worker conversation when the existing one is too long/unwieldy, materially stale, genuinely unrelated, or when concurrent work requires another independent agent.

Git ownership remains clean even when the conversation is reused: a materially distinct implementation assignment should normally still receive its own GitHub issue and branch.

## 3. Worker numbering follows the conversation, not the Git issue

`W##` identifies the worker **conversation lineage**. The decimal suffix identifies the sequential assignment given to that same worker conversation.

Example:

```text
W15.1 = first assignment handled by worker conversation W15
W15.2 = second assignment routed into that same conversation
W15.3 = third assignment routed into that same conversation
W16.1 = first assignment in a newly opened worker conversation W16
```

Therefore a reused worker may move from one GitHub issue/branch to another while keeping the same base `W##` and incrementing only the decimal suffix.

Do **not** interpret `.2` as "replacement chat because the old chat became too long." If a new ChatGPT worker conversation is opened, allocate the next base worker number and start it at `.1` unless the owner explicitly directs otherwise.

Parent conversation numbering follows the same idea when applicable: the identifier should describe the actual conversation lineage/assignment structure rather than pretending Git issue identity and chat identity are the same thing.

## 4. Git issue/branch identity is independent from worker-conversation identity

Conversation continuity and Git ownership are separate dimensions.

A reused worker conversation may receive:

```text
W15.1 -> issue #72 -> agent/failed-install-recovery-zip-validation
W15.2 -> issue #74 -> agent/operator-evidence-lifecycle
```

That is expected. Keep each implementation assignment reviewable with an exact branch/base/head, issue, scope, tests, PR, and parent merge decision even when the same worker conversation carries multiple assignments.

Workers do not merge their own PRs. Parent/integration reviews and merges.

## 5. Parent tests integrated canonical builds, not worker branches

Workers may implement, statically validate, fixture-test, and open PRs. They should not ask the user to install/play a worker branch unless the parent explicitly chooses an exceptional path.

Normal attended flow is:

```text
worker implementation -> PR -> parent review/merge -> canonical main -> one release-shaped candidate -> attended test -> durable evidence -> routing
```

The user should not repeatedly install separate worker builds when an integrated milestone test is the relevant proof.

## 6. Every worker and operator action resolves exact current state independently

At worker startup, resolve and report the exact current worker-branch head. Do not trust a handoff SHA without checking.

For local commands, pin the exact intended canonical/source revision. Fetch/verify it independently. Network fallback may use cached source only under the repository's exact-head fail-closed rules.

Do not make claims about current `main`, a worker head, or a local installed candidate from stale chat state when the repository or local evidence can resolve it directly.

## 7. The user should not manage a mental KEEP/delete list

Manual loose-file retention under `C:\Games` is not the desired steady-state workflow.

A local operator operation should produce **one obvious user handoff report/bundle**. If any part of that result is needed by later steps, the parent should archive the redistributable durable evidence in the repository after the user returns it.

Durable evidence should prefer text/JSON and include the identity needed to reproduce or authenticate later work, such as:

- exact source/main SHA;
- game/tool versions and relevant hashes;
- artifact identity/hash/size when applicable;
- build manifest or payload path/hash inventory;
- install/recovery plan facts;
- result classification and proof boundary.

Do not require the user to remember that an arbitrary report, plan, ZIP, or artifact directory must stay loose in `C:\Games` for an unknown number of turns.

## 8. Large binary artifacts are not normal long-term evidence dependencies

A candidate ZIP may exist temporarily for an immediate build/install/test step, but later correctness should not depend on the user remembering to retain that binary when equivalent exact text/hash evidence can safely describe or deterministically reconstruct the required boundary.

If an exact binary truly must survive temporarily, the tooling must machine-manage that retention with a bounded lifecycle and a safe cleanup path. "Please remember to keep this folder" is not the normal contract.

Do not commit proprietary game content or unnecessary third-party binaries to the repository merely to solve lifecycle management.

## 9. Parent ingests durable evidence; local PC does not need GitHub write credentials

The user returns the one attachable report/bundle to the parent conversation. The parent/assistant is responsible for committing appropriate redistributable evidence or a durable summarized record to GitHub.

Local operator tools may later fetch/read that repo-backed evidence beginning from zero local repo state. They should not require the user's PC to push commits or hold GitHub write credentials.

## 10. Local cleanup is tool-owned and fail-closed

Once required evidence has been confirmed durable in the repository, a repo-owned cleanup entrypoint should remove only the corresponding local handoff report/artifact bundle that it can prove is safe to remove.

Cleanup must be exact-path/hash/identity bounded and fail closed on mismatches, foreign files, changed content, ambiguous roots, or reparse-point/symlink hazards.

The user should not need to decide manually which evidence files are safe to delete. Temporary repo/worktree state may be removed automatically; durable local handoff state should be removed only after the durable repo-backed equivalent is confirmed.

## 11. Evidence failures are still evidence

PASS and FAIL outcomes must both produce a durable, attachable report. If a command fails before mutation, the report must say so explicitly. If mutation began, the report must say so explicitly and preserve enough evidence for bounded recovery.

Parent should record meaningful attended failures under `docs/test-runs/` and route actionable defects to a worker issue/branch rather than leaving them only in conversation history.

## 12. Reuse existing worker threads deliberately, not blindly

Conversation reuse is a preference, not a reason to overload one worker forever. Before routing another assignment into an existing worker, parent should ask:

- Is this conversation still short/manageable enough?
- Does its existing context materially help?
- Is sequential work appropriate, or do we need another worker in parallel?
- Can the new work keep a clean issue/branch boundary?

If yes, reuse the conversation and increment its decimal assignment number. If no, open the next `W##.1` worker conversation with a self-contained handoff.

## 13. `READY FOR PC TEST` means one command plus one live attended session

When the parent says a build is **ready for PC testing**, the user-facing interaction is not a chain of pre-launch probes and post-launch probes.

The canonical flow is:

```text
ONE COMMAND
-> exact candidate preparation / bounded preflight internally
-> quiet listener reports READY TO LAUNCH
-> user launches Cyberpunk normally
-> user performs attended checks
-> user exits Cyberpunk
-> user types END into the same PowerShell window
-> listener finalizes before/after evidence
-> one evidence handoff
-> user confirms it was sent
-> tool performs exact bounded cleanup
-> SESSION ENDED CLEANLY
```

Any baseline needed to interpret the launch belongs inside that same session. If Cyberpunk fails to launch, the listener should already have captured the process/log/output evidence needed to classify the failure as far as current tooling allows. Do not respond to a normal launch failure by making the owner run a second diagnostic chain that should have been part of the attended session.

A separate local diagnostic may still be requested while **investigating a build that is not yet ready**. Language must distinguish that from an attended handoff.

The full mandatory contract is `docs/ATTENDED-TEST-SESSION.md`. Future attended-session tooling must implement one reusable lifecycle engine rather than feature-specific pre/post command chains.

## 14. Canonical references

Future agents should read these together:

- `AGENTS.md` — project-wide agent gatekeeping and architecture rules;
- `docs/AGENT-OPERATING-PATTERNS.md` — owner-specific workflow conventions in this file;
- `docs/ATTENDED-TEST-SESSION.md` — mandatory one-command quiet-listener attended PC test contract;
- `docs/THREAD-LEDGER.md` — current conversation/assignment registry;
- `docs/PARALLEL-AGENT-WORKFLOW.md` — branch/handoff/merge workflow;
- `docs/INTEGRATION-ORCHESTRATOR.md` — parent responsibilities;
- `docs/LOCAL-OPERATOR-COMMANDS.md` — user-run operator command contract;
- `docs/test-runs/` — durable attended evidence.

When any of these conflict with an older historical handoff or chat transcript, update the canonical docs rather than propagating the stale pattern.


## 15. Attended PC tests are numbered and repository-recoverable

Owner-run live attended sessions use a monotonic parent-owned `T###` identity. The canonical index is `docs/test-runs/TEST-LEDGER.md`.

Rules:

- every new owner-run live session receives the next `T###`, including reruns;
- acceptance checks use `T###-A##`;
- attended findings use `T###-F##`;
- worker fixture tests, CI, and read-only audits keep their own IDs and are referenced rather than consuming `T###`;
- before launch, record the in-flight test in GitHub without moving the exact candidate SHA merely for bookkeeping;
- after evidence returns, commit a completed `T###-...` record and update the test ledger;
- record what changed since the predecessor, exact source/artifact/evidence identity, PASS/FAIL/PARTIAL observations, routes, lessons, what remains unaccepted, and the next intended boundary;
- screenshots may remain outside Git when binary retention is undesirable, but their hashes and grounded visual observations belong in the completed record;
- the machine/session result (for example listener PASS) is distinct from gameplay acceptance.

Fresh-parent recovery order is:

```text
exact current main
-> docs/test-runs/TEST-LEDGER.md
-> any open [T###] attended tracking issue
-> latest completed numbered test record
-> docs/THREAD-LEDGER.md
-> current GitHub issues/PRs/CI
-> older chat only as supplemental context
```

Repository/GitHub state wins over chat recollection when chat history is missing, truncated, or contradictory.
