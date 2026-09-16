# W16.1 — Operator Evidence Lifecycle

Parent: **P01.2**  
Issue: **#74 — Managed operator evidence lifecycle — repo-backed handoff state and automatic local cleanup**  
Branch: **`agent/operator-evidence-lifecycle`**

## Conversation reuse

Use the **existing W15 worker conversation** for this follow-up. The project owner prefers reusing a recent worker conversation for several closely related sequential tasks when its repository/subsystem context is still useful. Keep the new Git issue/branch boundaries clean, but do not make the user open another ChatGPT worker thread for this lane.

## Startup rule

Independently resolve and report the exact current worker-branch head at startup. Do not assume this handoff commit/base is still current.

Parent routing base:

`8817b54d9431cbd23847820f2a7e9a3d7064e6af`

## Read first

- `AGENTS.md`
- `AGREED-GOALS.md`
- `docs/THREAD-LEDGER.md`
- `docs/PARALLEL-AGENT-WORKFLOW.md`
- `docs/INTEGRATION-ORCHESTRATOR.md`
- `docs/LOCAL-OPERATOR-COMMANDS.md`
- `docs/test-runs/README.md`
- `docs/test-runs/2026-09-16-bf20fe1f-failed-install-recovery-evidence-gap.md`
- `docs/handoffs/W14-RELEASE-INSTALLER-CREATE-REPAIR.md`
- `docs/handoffs/W15-FAILED-INSTALL-RECOVERY-ZIP-VALIDATION.md`
- `tools/Bootstrap-BiologyPostTransitionCandidate.ps1`
- `tools/Bootstrap-BiologyFailedInstallRecovery.ps1`
- `tools/BiologyFailedInstallRecovery.Core.ps1`
- `tools/Build-BiologyPackage.ps1`
- issue #74

## Triggering attended evidence

After W15 merged, parent reran the exact failed-install recovery. The previously retained candidate ZIP was no longer present under `C:\Games`, so recovery correctly stopped before mutation:

```text
RESULT: FAIL-CLOSED
Error: Retained failed candidate artifact does not exist.
Recovery mutation started: False
Installed game remained unchanged by W14 recovery because failure occurred before recovery mutation began.
```

The parent has preserved this finding in the canonical attended test record listed above.

The user explicitly wants a better lifecycle: they should **not need to remember what loose files under `C:\Games` to keep or delete**. If durable evidence is needed later, it should become repo-backed after it is returned to the parent, and local residue should be removable through a repo-owned safe cleanup path when no longer needed.

## Goal

Design and implement a managed operator evidence lifecycle that eliminates manual cross-turn KEEP/delete memory as the normal contract.

### Required behavior

1. **One handoff surface per operation.** A local operator command should produce one obvious attachable report/bundle for the user rather than multiple independently retained loose artifacts with different lifetimes.
2. **Repo-backed durable evidence.** Small redistributable evidence needed later must have a canonical repository representation after parent ingestion: report text, exact source/main SHA, relevant game/tool identities, candidate/artifact identity, ownership/payload hash inventory, and any recovery/install-plan facts needed by future steps.
3. **No local GitHub write credential requirement.** The local PC should not push evidence. Parent/assistant will commit returned text/JSON evidence after the user attaches it. Local tools may later fetch/read that durable record starting from zero local repo state.
4. **Binary ZIPs are not durable manual dependencies.** Do not make a prior candidate ZIP sitting under `C:\Games` the only proof source when exact text/hash evidence can safely describe the relevant payload. Prefer a recovery evidence manifest / payload inventory or deterministic reconstruction. If an exact binary must temporarily survive, its lifecycle must be machine-managed and bounded, not a human memory instruction.
5. **Safe local cleanup.** Provide a repo-owned, zero-local-repo-safe cleanup entrypoint that only removes a local report/artifact bundle after it can verify that the required durable evidence exists in the repository and matches the expected hashes/identity. It must fail closed on mismatches, changed/foreign content, or ambiguous paths.
6. **Independent later operations.** Subsequent commands must resolve previous evidence by stable repo-backed run/evidence identity and exact hashes. Do not assume an old loose path survives.
7. **Current state repair.** Provide a bounded safe path forward from the current failed install even though the original `04d4c158...` candidate ZIP is missing. Use the parent-reviewed report/source/build identity plus exact-source reconstruction or a read-only residue proof. Do not guess/delete. If only empty, safely attributable Biology-owned directories exist, prove that before removing them. If any ambiguous file exists, fail closed.
8. **Preserve W14/W15 safety.** No weakening of protected shared loader collision policy, exact-hash deletion rules, read/plan-first recovery, reparse-point refusal, or shared redscript/cybercmd preservation.
9. **Update canonical workflow docs.** Replace manual `KEEP THIS FILE UNTIL ...` as the normal pattern in `docs/LOCAL-OPERATOR-COMMANDS.md` and adjust collaboration guidance so parent ingestion + repo-backed retrieval + safe cleanup are the preferred lifecycle.
10. **Thread reuse policy.** Update the parent-owned/thread workflow documentation only as needed to reflect the owner's preference that a recent worker conversation can carry several closely related sequential issues/branches while its context remains useful. Do not sacrifice clean Git issue/branch ownership.

## Design guidance

A reasonable design may use a canonical repository subtree such as:

```text
docs/operator-evidence/<evidence-id>/
```

with redistributable text/JSON only, for example:

- `report.txt`
- `evidence.json`
- `payload-manifest.json`

But choose the smallest singular design that fits existing `docs/test-runs/` / evidence architecture rather than creating competing authorities.

The durable evidence record should be sufficient for later recovery without the original ZIP whenever that is safely possible. It may include:

- exact attempted/canonical source revision;
- game version and relevant executable/tool hashes;
- build ID / version;
- artifact historical SHA-256 and size;
- package file path + SHA-256 + ownership/replace policy inventory;
- exact receipt hash if applicable;
- preflight action inventory if needed;
- result/mutation/deployment state;
- local cleanup targets with exact path/identity boundaries.

Do **not** commit proprietary game files, generated `final.redscripts`, unnecessary third-party binaries, or other redistribution-sensitive material.

## Current-state evidence available to parent

Parent has the exact candidate-preparation report for attempted source:

`04d4c1584df4b0823e093422b98cf4c5575c7b19`

It records:

- failed candidate ZIP name `biology-integrated-20260916-144813-04d4c1584df4.zip`;
- historical ZIP SHA-256 `76A86A77A3C7AE36306B203C7946B88C5D56E1F7B0689489DA7EAF6D8783C796`;
- bytes `1979796`;
- build ID `biology-integrated-20260916-144813-04d4c1584df4`;
- exact source revision;
- W11 transition evidence hash;
- successful exact compile/build/preflight;
- failure on first mutating installer action before receipt verification and before REDmod deployment.

If additional exact evidence must be archived to the repo for current recovery, state precisely what parent should ingest. Do not ask the user to reconstruct missing files manually.

## Regression coverage

Add focused tests proving at least:

- repo-backed evidence records are schema/identity/hash validated;
- later bootstrap can retrieve exact evidence starting from zero local repo state;
- local cleanup refuses to delete before matching durable evidence is confirmed;
- cleanup removes only the exact intended local evidence/artifact paths and refuses changed/foreign paths;
- current failed-install recovery can proceed safely without the missing prior ZIP when equivalent exact evidence is sufficient, or produces a read-only proof explaining why not;
- shared redscript/cybercmd remains preserve-only;
- no game launch is introduced;
- operator docs no longer rely on open-ended human `KEEP` memory.

## Scope boundaries

Do not broaden into:

- Biology UI/body/E3 redesign;
- physiology/combat/scanner work;
- REDscript startup redesign beyond evidence needed to reconstruct current failed candidate state;
- dependency strategy redesign;
- general uninstaller redesign;
- arbitrary cleanup of `C:\Games`;
- requiring the user to maintain a persistent local repo.

Do not mutate the user's installed game from the worker lane. Do not ask the user to install or play the worker branch. Do not ask for a Cyberpunk reinstall. Do not merge your own PR.

## Return to parent

Open a PR to `main` and return:

- independently resolved startup head;
- exact final worker head;
- chosen evidence schema/location and lifecycle;
- how parent ingests returned evidence;
- how later zero-repo commands resolve it;
- safe local cleanup entrypoint and proof boundary;
- exact current-state missing-artifact recovery path;
- focused tests and full CI status;
- PR number and mergeability;
- any evidence parent must archive before attended recovery.

Parent P01.2 owns merge, canonical evidence ingestion, real local cleanup/recovery execution, and resumed candidate validation.
