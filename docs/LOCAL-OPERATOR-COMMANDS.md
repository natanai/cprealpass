# Biology local operator command catalog

Status: **canonical user-run command surface**  
Last updated: 2026-09-16

## Why this exists

The project owner can provide direct evidence from the supported local Cyberpunk 2077 installation, but agents should not invent a fresh PowerShell procedure every time. **Agents must reuse this catalog for routine local operations.** If a recurring operation is missing or awkward, improve the repository tool, this document, and its CI contract first.

Canonical game root unless the user says otherwise:

```text
C:\Games\Steam\steamapps\common\Cyberpunk 2077
```

The operator environment deliberately treats local repository state as disposable. **Never assume any prior local cprealpass clone/worktree still exists across separate user instructions/turns.** Zero local repo is a normal supported condition, not an edge case.

For operator evidence that must survive across turns, the normal contract is now **one managed handoff bundle -> parent ingestion into `docs/operator-evidence/<evidence-id>/` -> repo-confirmed local cleanup**. The user should not maintain a mental list of loose reports/plans/ZIPs to KEEP or delete.

## Mandatory repository discovery/bootstrap rule

Repository/workspace paths are **not stable**. The retired `C:\Games\CyberpunkRealism` convention must not be assumed or recreated.

Before a repo-dependent PowerShell/CMD operation uses source, the repository-owned bootstrap or documented bootstrap layer must:

1. inspect only immediate child directories under `C:\Games`;
2. ask Git whether each candidate is usable with `git -C <candidate> rev-parse --show-toplevel`;
3. ask Git for `git -C <candidate> remote get-url origin` and accept only an origin resolving to `natanai/cprealpass`;
4. accept both ordinary clones and valid linked worktrees; a linked worktree normally has a `.git` pointer file and is not disqualified for lacking a physical config beneath the worktree;
5. fail closed on broken worktrees/missing common repositories because the Git validation commands will fail;
6. use a matching checkout local-first when safe, rather than cloning merely because it is a worktree;
7. if no usable checkout exists, clone `https://github.com/natanai/cprealpass.git` into a uniquely signed folder under `C:\Games`;
8. create a fresh uniquely signed detached checkout/worktree for branch/head-pinned evidence or candidate work instead of mutating an arbitrary discovered checkout;
9. print/record the exact seed and disposable checkout paths used.

Unique signatures must contain a **timestamp and random suffix**, for example:

```text
20260915-031500-a1b2c3d4
```

### Exact-head network/fallback rule

A branch/head-pinned bootstrap still attempts a fetch first. Network failure is not permission to use a stale local branch.

If `git fetch origin <branch>` fails, continuation is allowed only when **both** are true:

- cached `refs/remotes/origin/<branch>` equals the supplied exact 40-character expected head; and
- `git cat-file -e <expected-head>^{commit}` proves that exact commit object exists locally.

Any missing ref, mismatched SHA, or missing commit object is fail-closed. Successful fallback must be reported explicitly as an exact-head cached-origin/offline decision. This rule applies to valid ordinary clones and valid linked worktrees alike.

### Independent-operation rule

A disposable probe/audit/candidate worktree may be removed as soon as that instruction is finished. A later command must independently rediscover or reacquire source. Never point a later mutator at a path merely because an earlier probe printed it.

Durable cross-turn operator state should be represented by one managed handoff bundle. The parent/assistant ingests the returned redistributable `evidence.json` + `report.txt` into `docs/operator-evidence/<evidence-id>/`; later commands resolve that stable evidence ID from an exact canonical checkout. The local PC does not need GitHub write credentials.

Large candidate ZIPs are not normal long-term evidence dependencies. When an exact binary must survive temporarily, the producing tool machine-manages its bounded artifact root and records exact path/hash/inventory in the handoff evidence. Cleanup is performed only by the repo-owned cleanup entrypoint after durable repository evidence is confirmed.

Older pre-W15 tools may still print historical `KEEP UNTIL ...` wording inside their own evidence. That is compatibility evidence, **not** the normal operator contract going forward; use the managed W15.2 wrappers below instead of asking the user to remember those loose files indefinitely.

### Bootstrap-loader boundary

The one-line launcher that gets a repository-owned bootstrap is itself part of the operator path.

- If the exact reviewed script already exists in an exact reviewed checkout, execute that local copy first.
- Do not redownload it merely because the checkout is a linked worktree.
- If no exact local script/revision exists, an exact-revision GitHub raw download is an explicit network fallback.
- Never download an unpinned `main` script and silently treat it as the reviewed revision.
- A network failure before the repository-owned bootstrap starts cannot be repaired by pretending stale source is current; report that acquisition failure to the owning thread.

The repo-owned bootstrap itself must still be independently zero-local-repo-safe after it starts. Thus a downloaded bootstrap may discover a useful existing worktree or may make its own uniquely signed seed clone if none exists.

## Mandatory evidence-report rule

When an agent asks the user to run a local evidence/audit/probe/candidate-preparation operation, it must generate a **plain-text `.txt` evidence report** for the user to attach back to ChatGPT. Managed lifecycle operations additionally package that report with its machine-readable record into one `Biology-Operator-Evidence-<evidence-id>.zip` handoff bundle.

- Do not make copy/pasting console output into chat the normal handoff.
- The report must be useful for **failure and success** outcomes (`FAIL`/`PASS`).
- Use a unique filename containing timestamp plus random suffix or exact revision/build identity.
- Print the absolute report/bundle path at the end of the operation.
- Tell the user to attach the one obvious handoff file to the owning ChatGPT thread.
- Machine-readable JSON may be included for automation; under the managed lifecycle it travels inside the same bundle rather than becoming a second loose file the user must manage.

`tools/Audit-GameContracts.ps1` follows the legacy text-only rule directly and prints an absolute `LOCAL EVIDENCE REPORT:` line. Repository-owned `Bootstrap-*.ps1` evidence entrypoints must obey the failure-durable contract below.

## Canonical failure-durable probe/bootstrap contract

A repo-owned local probe is **not complete unless its useful evidence survives failure**. A nonzero child exit code by itself is not enough: if the attachable report says only `exit 1` while child stderr or a terminating exception was lost, that is an incomplete probe.

For user-returned local probes/audits/candidate preparation, the canonical bootstrap must:

1. **Pin revision identity.** When branch-specific, require the intended branch plus an exact 40-character expected head, fetch that branch, record the fetched head, and refuse a different revision. Apply the exact-head cached-origin rule above only after fetch failure.
2. **Use disposable isolation.** Discover `natanai/cprealpass` by valid Git origin or create a uniquely signed seed clone, then use a uniquely signed detached/disposable checkout or worktree for the requested revision.
3. **Default the installed game/tool tree to read-only.** The Cyberpunk/REDmod installation must be treated as read-only unless mutation is explicitly the purpose of the operator command.
4. **Fingerprint the authority being inspected.** Record the exact supported game/native/tool identity relevant to the question, such as product/file version and, when useful, SHA-256 of the executable/tool actually inspected.
5. **Collect bounded evidence.** Capture only the files/symbols/schema excerpts needed for the current question rather than dumping proprietary trees or huge console transcripts.
6. **State the proof boundary.** Clearly distinguish source/symbol/schema evidence from exact compilation, official REDmod deployment, or live-runtime/attended proof. Source evidence must never be reported as deployment or runtime acceptance.
7. **Produce one obvious attachable handoff.** Text-only legacy probes may return one `.txt`; managed lifecycle operations return one ZIP containing exactly `evidence.json` and `report.txt`.
8. **Preserve child-process diagnostics before throwing.** For every child process whose output matters, capture **stdout, stderr, exit code, and actual exception/error text** into that report. On nonzero exit, throw only after those diagnostics have been persisted.
9. **Record bootstrap context.** The report must include requested branch/head when applicable, fetched head, disposable checkout/worktree path, and game/native/tool identity.
10. **Always expose one attachment handoff.** Success and failure paths must print one obvious attachment path, such as:

```text
ATTACH THIS FILE TO CHATGPT:
<absolute path to report.txt or Biology-Operator-Evidence-....zip>
```

For external/native child processes, the preferred PowerShell implementation uses `System.Diagnostics.ProcessStartInfo` with `UseShellExecute = false`, `RedirectStandardOutput = true`, `RedirectStandardError = true`, and `ArgumentList` for safe argument boundaries. Read stdout/stderr, wait for exit, persist both streams plus the exit code, and only then evaluate success/failure. **Text written to native stderr is evidence, not a PowerShell failure classification by itself; the process exit code is authoritative.** The outer `catch` must add the exception type and message to the report, and the attachment handoff belongs in a `finally`-equivalent path.

`tools/Bootstrap-RedmodActivationSentinelProbe.ps1`, `tools/Bootstrap-PresentationAudit.ps1`, the W11 transition bootstraps, and the managed W15.2 entrypoints are current examples.

---

## Command 0 — bootstrap a disposable milestone workspace when no repo exists locally

This is the ordinary **MILESTONE CLEAN-ROOM** path after a genuinely fresh uninstall/residual-directory deletion/reinstall. It is not the special post-W11 transition path; use the managed post-transition command below for that.

The parent supplies the exact canonical `main` SHA. The acquisition logic is bounded to immediate `C:\Games` children, is worktree-aware, and must use the exact-head rule above. Once an exact detached operator checkout is materialized, run:

```powershell
pwsh '<exact-operator-checkout>\tools\Prepare-BiologyMilestoneTest.ps1' `
  -MainSha '<40-character canonical main SHA>' `
  -GameRoot 'C:\Games\Steam\steamapps\common\Cyberpunk 2077' `
  -WorkspaceRoot '<uniquely-signed milestone root>'
```

A documented bootstrap/loader should materialize `<exact-operator-checkout>`; do not restore the old `.git\config`-only discovery sample. If no local checkout exists, create a uniquely signed seed such as `cprealpass-repo-$Signature`; if fetch fails, only the exact cached `origin/main` + commit-object proof may continue.

`Prepare-BiologyMilestoneTest.ps1` verifies the exact SHA, asks whether to run the **exhaustive full-file/hash vanilla comparison**, creates a second pristine candidate checkout, builds the release-shaped ZIP, installs/deploys it, records evidence, and stops before game launch.

The exhaustive hash check defaults to **No**. Skipping it after a fresh uninstall + residual-directory deletion + reinstall is allowed, but evidence must say `exhaustive-hash-check-skipped`; an agent must never report that as “verified against recorded vanilla baseline.”

---

## Command 1 — fast vanilla sanity check

Use after a genuinely fresh Steam reinstall when an exhaustive whole-game hash comparison is unnecessary:

```powershell
pwsh ./tools/Test-VanillaGameSanity.ps1 `
  -GameRoot 'C:\Games\Steam\steamapps\common\Cyberpunk 2077'
```

This is deliberately **not a full-file/hash proof**. When requested as user evidence, capture the result in the required `.txt` report.

---

## Command 2 — exhaustive vanilla baseline comparison

Use when residue is uncertain, when reusing a game install for iteration, or when the user explicitly chooses the stronger check:

```powershell
pwsh ./tools/Compare-GameToVanillaBaseline.ps1 `
  -GameRoot 'C:\Games\Steam\steamapps\common\Cyberpunk 2077'
```

The full comparison shows durable progress, for example:

```text
VERIFY [#######-------------]  35% | 1842/5200 files | 29.4/84.0 GiB | elapsed 00:01:42
```

When requested as user evidence, return the generated/captured `.txt` report rather than pasted console output.

---

## Command 3 — capture/publish a new vanilla baseline

Use only when the clean reference itself needs to change, such as after a supported game patch:

```powershell
pwsh ./tools/Capture-VanillaGameBaseline.ps1 `
  -GameRoot 'C:\Games\Steam\steamapps\common\Cyberpunk 2077' `
  -Publish
```

This hashes the full game and therefore has durable `HASH [...]` progress output.

---

## Command 4 — build the release-shaped Biology package

From a pristine exact candidate checkout:

```powershell
pwsh ./tools/Build-BiologyPackage.ps1 `
  -GameRoot 'C:\Games\Steam\steamapps\common\Cyberpunk 2077'
```

The builder exact-compiles the merged Biology runtime against the supported game before emitting a game-root-shaped ZIP. The current package contains the REDmod activation marker, schema-2 ownership receipt, and `Uninstall Biology.exe`. It does not install, deploy, or launch the game.

For normal milestone preparation prefer Command 0. For the accounted W11 transition state use Command 14.

---

## Command 5 — deploy installed Biology through official REDmod

```powershell
pwsh ./tools/Deploy-BiologyRedmod.ps1 `
  -GameRoot 'C:\Games\Steam\steamapps\common\Cyberpunk 2077'
```

The helper is fail-closed. Output containing `No root specified`, `Invalid root path found`, or `No mods found, no deployment is needed` is a deployment **failure** for an installed Biology candidate even if REDmod exits `0`. Positive deployment requires actual `[DEPLOY]` stage output and `Commandlet deploy has succeeded`.

---

## Command 6 — reset an iteration install back to the tracked vanilla baseline

Use only when the package architecture/game version is unchanged and the installed Biology manifest is intact:

```powershell
pwsh ./tools/Reset-BiologyIteration.ps1 `
  -GameRoot 'C:\Games\Steam\steamapps\common\Cyberpunk 2077'
```

This developer reset follows exact-hash/fail-closed ownership semantics and then performs the strict full vanilla comparison.

---

## Command 7 — verify Biology-specific residue after player hard uninstall

The **player-facing** hard-uninstall action is not PowerShell: close Cyberpunk 2077 and **double-click `Uninstall Biology.exe`** in the game root.

For attended/development verification follow with:

```powershell
pwsh ./tools/Verify-BiologyRemoval.ps1 `
  -GameRoot 'C:\Games\Steam\steamapps\common\Cyberpunk 2077'
```

This read-only check covers Biology-specific runtime/package residue. Generic redscript/other framework files are not automatically classified as Biology residue merely because they exist.

---

## Command 8 — direct compatibility audit

Use after a Cyberpunk patch/framework change or when foundational native seams need direct supported-install evidence:

```powershell
pwsh ./tools/Audit-GameContracts.ps1 `
  -GamePath 'C:\Games\Steam\steamapps\common\Cyberpunk 2077'
```

At completion or failure after startup it prints:

```text
LOCAL EVIDENCE REPORT: C:\...\reports\local-game-contract-audit-....txt
```

Attach that `.txt` file to the owning ChatGPT thread. This is investigation evidence, not attended runtime acceptance.

For branch-specific presentation audits use `tools/Bootstrap-PresentationAudit.ps1`; it accepts usable ordinary clones or linked worktrees by Git identity, applies exact-head cached-origin fallback when network fetch fails, creates a signed detached audit checkout, fingerprints game identity, captures child output, and prints `ATTACH THIS FILE TO CHATGPT:`.

---

## Command 9 — ask the installed official REDmod tool what it can do

```powershell
pwsh ./tools/Probe-OfficialRedmod.ps1 `
  -GameRoot 'C:\Games\Steam\steamapps\common\Cyberpunk 2077'
```

This read-only probe queries installed `tools\redmod\bin\redMod.exe`, fingerprints it, inventories official toolset signals, captures `redMod.exe --help`, and writes a text report. Community/modder practice is **fallback evidence**, not proof that the official route is unavailable or inferior.

---

## Command 10 — publish the current GitHub-safe game reference snapshot

```powershell
pwsh ./tools/Publish-LocalGameReferenceSnapshot.ps1 `
  -GamePath 'C:\Games\Steam\steamapps\common\Cyberpunk 2077'
```

It publishes derived metadata only, never proprietary Cyberpunk payload.

---

## Command 11 — branch-pinned read-only pre-W10 framework transition probe

Use only for issue #64/W11. `Bootstrap-LegacyFrameworkTransitionProbe.ps1` treats the installed game as **read-only**, validates exact schema-2 ownership, compares retired framework paths against receipt hashes and vanilla baseline, scans bounded surfaces for another possible consumer, protects redscript and the old Mod Settings preference file, and writes an attachable `.txt` plus hashed JSON plan.

Required parameters:

```text
-Branch <worker branch>
-ExpectedHead <exact 40-character worker head>
-GameRoot C:\Games\Steam\steamapps\common\Cyberpunk 2077
```

Its bootstrap is worktree-aware and supports the exact-head cached-origin fallback. `SAFE-TO-APPLY` authorizes only the separately reviewed W11 transition; it is not gameplay/deployment acceptance.

---

## Command 12 — parent-authorized exact W11 framework retirement

This is the mutating half of Command 11. P01.2 may authorize it only after reviewing a `SAFE-TO-APPLY` report. `Bootstrap-LegacyFrameworkTransitionCleanup.ps1` requires the same exact branch/head plus the exact JSON plan path and SHA-256 emitted by Command 11, re-runs safety immediately before mutation, re-hashes targets, deletes exact retired package files only, and re-verifies protected redscript.

Required parameters:

```text
-Branch <reviewed branch>
-ExpectedHead <exact 40-character reviewed head>
-PlanPath <persistent JSON plan from Command 11>
-ExpectedPlanSha256 <exact plan SHA-256 from Command 11>
-GameRoot C:\Games\Steam\steamapps\common\Cyberpunk 2077
```

The cleanup never recursively owns shared roots and never targets redscript or the legacy Mod Settings preference file. Its bootstrap is independently worktree-aware and exact-head/offline-safe; it does not rely on the Command 11 worktree still existing.

---

## Command 13 — legacy post-W11 candidate preparation compatibility entrypoint

`tools/Bootstrap-BiologyPostTransitionCandidate.ps1` remains supported as the inner/legacy compatibility implementation because existing W12 evidence and tests depend on its exact report semantics. It accepts:

```text
-MainSha <exact 40-character canonical main SHA>
-TransitionCleanupReportPath <reviewed W11 cleanup .txt>
-ExpectedTransitionCleanupReportSha256 <exact SHA-256 of that reviewed cleanup report>
-GameRoot C:\Games\Steam\steamapps\common\Cyberpunk 2077
```

It remains zero-local-repo-safe, worktree-aware, exact-head/offline-safe, classifies the state as **NOT a vanilla-baseline proof**, builds through `Build-BiologyPackage.ps1`, installs/deploys the release-shaped candidate, records `Biology-Post-Transition-Candidate-Prep-...` evidence, retains `Biology-Candidate-Artifacts-...` state, and prints `STOP_BEFORE_GAME_LAUNCH=YES`.

Its historical report may contain `KEEP UNTIL ATTENDED TEST`. Do not use that wording as a new human-memory contract. For new parent operations invoke Command 14, which wraps this implementation and returns one managed evidence ZIP.

---

## Command 14 — managed post-W11 candidate preparation

Repository-owned entrypoint:

```text
tools/Bootstrap-BiologyManagedPostTransitionCandidate.ps1
```

Normal steady-state invocation resolves the reviewed W11 transition record by repository evidence ID:

```powershell
pwsh '<exact-main-checkout>\tools\Bootstrap-BiologyManagedPostTransitionCandidate.ps1' `
  -MainSha '<exact 40-character canonical main SHA>' `
  -TransitionEvidenceId '<repo-backed transition evidence id>' `
  -GameRoot 'C:\Games\Steam\steamapps\common\Cyberpunk 2077'
```

A temporary migration parameter set also accepts the old local W11 cleanup report path/hash so the parent can ingest that one pre-lifecycle record without asking the user to recreate it.

The managed wrapper independently supports zero local repo state, resolves exact canonical `main`, runs the legacy inner candidate preparation, captures its failure-durable report, and when a release artifact exists records:

- exact canonical source revision;
- candidate ZIP name/hash/bytes/build ID;
- schema-2 payload manifest with every path/hash/replace policy;
- exact ownership receipt hash;
- whether game mutation started;
- whether installed receipt verification/deploy passed;
- exact managed artifact root/inventory needed for later cleanup;
- recovery eligibility and proof boundary.

It emits **one user handoff surface**:

```text
C:\Games\Biology-Operator-Evidence-<evidence-id>.zip
```

The ZIP contains exactly `evidence.json` and `report.txt`. Return that ZIP to P01.2. Parent/assistant commits the redistributable members under `docs/operator-evidence/<evidence-id>/`. The local PC never pushes evidence to GitHub.

---

## Command 15 — repository-evidence-backed failed-install recovery

Repository-owned entrypoint:

```text
tools/Bootstrap-BiologyManagedFailedInstallRecovery.ps1
```

The parent supplies exact canonical `main`, stable `EvidenceId`, and the game root. The bootstrap starts from zero local repo state if necessary, fetches/verifies exact `main`, loads `docs/operator-evidence/<evidence-id>/evidence.json`, validates schema/identity/hash fields, and performs a complete read/plan phase before any mutation.

For normal exact-payload evidence, recovery no longer requires the historical candidate ZIP. It derives removable Biology-owned files from the embedded schema-2 payload inventory and receipt hash. Files are removed only when the installed hash exactly matches durable evidence; changed/foreign content, unknown directories, reparse points, and ambiguous state fail closed. Generic redscript/cybercmd entries are always `preserve-shared`.

For the one pre-lifecycle failed attempt from source `04d4c1584df4b0823e093422b98cf4c5575c7b19`, the checked-in legacy record authorizes only `empty-owned-roots-only` recovery. It may remove the known Biology-owned roots only when they are literally empty and known package files are absent. It never guesses missing historical payload hashes; any ambiguous file causes a fail-closed result.

This command does not launch Cyberpunk and does not deploy REDmod.

---

## Command 16 — repo-confirmed local operator evidence cleanup

Repository-owned entrypoint:

```text
tools/Bootstrap-BiologyOperatorEvidenceCleanup.ps1
```

Inputs:

```text
-MainSha <exact canonical main containing the ingested evidence>
-EvidenceId <stable repo-backed evidence id>
-HandoffBundlePath <local Biology-Operator-Evidence-<id>.zip>
```

The cleanup bootstrap independently reacquires exact canonical source, loads the repository evidence record, and requires the local ZIP's `evidence.json` and `report.txt` to match the durable repository copies byte-for-byte after canonical newline normalization. It then validates any machine-managed candidate artifact root against the exact recorded inventory.

Cleanup fails closed on:

- evidence/report mismatch;
- wrong evidence ID;
- changed or foreign artifact files/directories;
- any reparse point;
- artifact-root path ambiguity;
- **any missing expected artifact file**.

Only after every expected artifact file is present and exact does it recursively remove that one recorded managed artifact root and the one matching handoff ZIP. No other `C:\Games` content is targeted. If durable evidence is not yet on the exact repository revision, cleanup refuses deletion.

---

## Parent evidence ingestion rule

When the user returns a managed evidence ZIP, P01.2 should inspect it, preserve meaningful attended failure/success conclusions under `docs/test-runs/` as appropriate, and commit the redistributable handoff members as:

```text
docs/operator-evidence/<evidence-id>/evidence.json
docs/operator-evidence/<evidence-id>/report.txt
```

Do not commit the candidate ZIP, proprietary game files, or unnecessary third-party binaries. Later commands address this evidence by `EvidenceId` plus exact canonical source, not by an old `C:\Games` path.

---

## Rules for agents asking the user to run PowerShell

1. **Look here first.** If a catalog command covers the task, use it rather than reconstructing its internals in chat.
2. **Never assume a permanent repo path.** Repo-dependent operations must use bounded worktree-aware local-first discovery or an exact-revision bootstrap-loader fallback.
3. Do not use or recreate `C:\Games\CyberpunkRealism`; that path convention is retired.
4. Branch-specific/local-audit work should use a fresh uniquely signed worktree/checkout, not silently mutate an arbitrary existing repo.
5. Every user-returned evidence operation must create one obvious handoff file; managed lifecycle operations should return one `Biology-Operator-Evidence-*.zip` rather than a loose KEEP/delete list.
6. Evidence reports must preserve clear PASS/FAIL outcomes and actual child diagnostics. Native stderr by itself is not failure; child exit code and explicit acceptance conditions decide success.
7. Branch-specific probe bootstraps must pin the requested branch and exact head and apply the fail-closed cached-origin rule after fetch failure.
8. For foundational runtime/package questions, probe the installed game/CDPR/REDmod toolchain before assuming a community route is necessary.
9. Prefer one repository-owned entrypoint over a long chain of unrelated commands.
10. Long operations must expose durable console progress; `Write-Progress` alone is insufficient.
11. Do not describe a fast sanity pass as full baseline/hash verification.
12. After a freshly uninstalled/residual-directory-deleted/reinstalled game, let the user choose whether the additional exhaustive hash check is worth the time. Default is **No**.
13. Iteration cleanup on a reused install remains stricter: `Reset-BiologyIteration.ps1` must prove return to tracked baseline before layering another package.
14. After player hard-uninstall, prefer `Verify-BiologyRemoval.ps1`; do not invent destructive cleanup or misclassify intentionally preserved generic dependencies as Biology residue.
15. If a command fails, return its managed evidence/report to the owning agent; do not improvise destructive cleanup commands.
16. A successful probe's disposable checkout is not persistent state. A later operation must bootstrap independently.
17. Parent/assistant, not the local PC, ingests durable evidence into GitHub.
18. Do not ask the user to remember arbitrary report/plan/ZIP paths across turns when equivalent repo-backed evidence exists.
19. Do not ask the user to recreate a missing historical candidate ZIP when exact text/hash evidence or a bounded read-only residue proof can safely establish the needed boundary.
20. If an operation becomes recurring, codify it here and in `tools/` with CI coverage before treating it as standard.
