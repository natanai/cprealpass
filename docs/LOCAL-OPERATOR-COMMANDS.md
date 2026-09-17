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

For ordinary owner-facing attended testing after the parent says **READY FOR PC TEST**, use **Command 17 — one-command attended test session**. Do not turn a normal attended test into separate manual pre-launch probe, evidence-return, game-launch, and post-launch diagnostic instructions.

For other operator evidence that must survive across turns, the managed contract remains **one managed handoff bundle -> parent ingestion into `docs/operator-evidence/<evidence-id>/` -> repo-confirmed local cleanup**. This is not a human `KEEP` list.

## Mandatory repository discovery/bootstrap rule

Repository/workspace paths are **not stable**. The retired `C:\Games\CyberpunkRealism` convention must not be assumed or recreated.

Before a repo-dependent PowerShell/CMD operation uses source, the repository-owned bootstrap or documented bootstrap layer must:

1. inspect only immediate child directories under `C:\Games`;
2. ask Git whether each candidate is usable with `git -C <candidate> rev-parse --show-toplevel`;
3. ask Git for `git -C <candidate> remote get-url origin` and accept only an origin resolving to `natanai/cprealpass`;
4. accept ordinary clones and valid linked worktrees;
5. fail closed on broken worktrees/missing common repositories;
6. use a matching checkout local-first when safe;
7. if no usable checkout exists, clone `https://github.com/natanai/cprealpass.git` into a uniquely signed folder under `C:\Games`;
8. create a fresh uniquely signed detached checkout/worktree for branch/head-pinned evidence or candidate work;
9. record the exact seed and disposable checkout paths used.

Unique signatures must contain a **timestamp and random suffix**, for example:

```text
20260916-183600-a1b2c3d4
```

### Exact-head network/fallback rule

A branch/head-pinned bootstrap attempts a fetch first. Network failure is not permission to use stale source.

If `git fetch origin <branch>` fails, continuation is allowed only when both are true:

- cached `refs/remotes/origin/<branch>` equals the supplied exact 40-character expected head; and
- `git cat-file -e <expected-head>^{commit}` proves that exact commit object exists locally.

Any missing ref, mismatched SHA, or missing object is fail-closed. A successful fallback must be described as the **exact-head cached-origin** decision.

### Independent-operation rule

A disposable probe/audit/candidate worktree may be removed as soon as that operation is finished. A later operation must rediscover or reacquire source independently. Durable cross-turn state belongs in managed repository evidence, not in a remembered arbitrary local path.

### Bootstrap-loader boundary

The one-line launcher that gets a repository-owned bootstrap is itself part of the operator path.

- If the exact reviewed script exists in an exact reviewed checkout, execute that local copy first.
- Do not redownload it merely because the checkout is a linked worktree.
- If no exact local script/revision exists, an exact-revision GitHub raw download is an explicit network fallback.
- Never download unpinned `main` and silently treat it as the reviewed revision.
- A network failure before the repository-owned bootstrap starts cannot be repaired by pretending stale source is current.

The repository-owned bootstrap must still be independently zero-local-repo-safe after it starts.

## Mandatory evidence-report rule

When an agent asks the owner to run a local evidence/audit/probe/candidate operation, it must generate a plain-text `.txt` report. Managed lifecycle operations package the report with a machine-readable record into one obvious attachable handoff such as `Biology-Operator-Evidence-<evidence-id>.zip`.

- Do not make copy/pasting console output the normal handoff.
- Reports must remain useful on PASS and FAIL.
- Use unique timestamp/random-suffix or exact-revision identity.
- Print the absolute handoff path.
- Managed ZIPs contain `evidence.json` and `report.txt`; the owner should have one obvious file to attach.

## Canonical failure-durable probe/bootstrap contract

A repo-owned local probe is incomplete unless useful diagnostics survive failure. For evidence-bearing child processes, prefer `System.Diagnostics.ProcessStartInfo` with `UseShellExecute = false`, redirected stdout/stderr, and `ArgumentList`. Capture stdout, stderr, exit code, and actual exception text before deciding success or throwing. Native stderr alone is evidence; the native exit code and explicit acceptance rules classify success.

Branch-specific evidence operations pin exact revision identity, use disposable isolation, default the installed game/tool tree to read-only unless mutation is explicitly the purpose, fingerprint relevant authority, collect bounded evidence, state proof boundaries, and always expose one attachment handoff.

---

## Command 0 — bootstrap a disposable milestone workspace when no repo exists locally

For a milestone clean-room after a genuine fresh Steam uninstall/residual-directory deletion/reinstall, use exact canonical main and the repository milestone preparation path:

```powershell
pwsh '<exact-operator-checkout>\tools\Prepare-BiologyMilestoneTest.ps1' `
  -MainSha '<40-character canonical main SHA>' `
  -GameRoot 'C:\Games\Steam\steamapps\common\Cyberpunk 2077' `
  -WorkspaceRoot '<uniquely-signed milestone root>'
```

The exhaustive whole-game hash comparison defaults to No after a genuine reinstall; skipping it must be recorded as `exhaustive-hash-check-skipped`, not as baseline hash verification.

---

## Command 1 — fast vanilla sanity check

```powershell
pwsh ./tools/Test-VanillaGameSanity.ps1 `
  -GameRoot 'C:\Games\Steam\steamapps\common\Cyberpunk 2077'
```

This is deliberately **not a full-file/hash proof**.

---

## Command 2 — exhaustive vanilla baseline comparison

```powershell
pwsh ./tools/Compare-GameToVanillaBaseline.ps1 `
  -GameRoot 'C:\Games\Steam\steamapps\common\Cyberpunk 2077'
```

The comparison emits durable `VERIFY [...]` progress and checks the tracked baseline by full path/hash.

---

## Command 3 — capture/publish a new vanilla baseline

```powershell
pwsh ./tools/Capture-VanillaGameBaseline.ps1 `
  -GameRoot 'C:\Games\Steam\steamapps\common\Cyberpunk 2077' `
  -Publish
```

Use deliberately after a supported game patch/reference change, not after every test.

---

## Command 4 — build the release-shaped Biology package

```powershell
pwsh ./tools/Build-BiologyPackage.ps1 `
  -GameRoot 'C:\Games\Steam\steamapps\common\Cyberpunk 2077'
```

The builder exact-compiles the merged Biology runtime, creates the game-root-shaped package with schema-2 ownership metadata, and does not deploy or launch the game.

---

## Command 5 — deploy installed Biology through official REDmod

```powershell
pwsh ./tools/Deploy-BiologyRedmod.ps1 `
  -GameRoot 'C:\Games\Steam\steamapps\common\Cyberpunk 2077'
```

The helper fails closed on `No root specified`, `Invalid root path found`, and `No mods found, no deployment is needed`. Positive deployment requires `[DEPLOY]` activity and `Commandlet deploy has succeeded`.

---

## Command 6 — reset an iteration install back to tracked vanilla baseline

```powershell
pwsh ./tools/Reset-BiologyIteration.ps1 `
  -GameRoot 'C:\Games\Steam\steamapps\common\Cyberpunk 2077'
```

This is ownership/hash conservative and finishes with the strict baseline comparison.

---

## Command 7 — verify Biology-specific residue after player hard uninstall

With Cyberpunk closed, **double-click `Uninstall Biology.exe`** in the game root for the player-facing hard removal. Development verification is read-only:

```powershell
pwsh ./tools/Verify-BiologyRemoval.ps1 `
  -GameRoot 'C:\Games\Steam\steamapps\common\Cyberpunk 2077'
```

---

## Command 8 — direct compatibility audit

```powershell
pwsh ./tools/Audit-GameContracts.ps1 `
  -GamePath 'C:\Games\Steam\steamapps\common\Cyberpunk 2077'
```

The tool emits `LOCAL EVIDENCE REPORT:` with an attachable report. Branch-specific presentation audits use `tools/Bootstrap-PresentationAudit.ps1`; branch-specific activation evidence uses the repository activation bootstrap.

---

## Command 9 — ask the installed official REDmod tool what it can do

```powershell
pwsh ./tools/Probe-OfficialRedmod.ps1 `
  -GameRoot 'C:\Games\Steam\steamapps\common\Cyberpunk 2077'
```

This is read-only official-tool evidence, not runtime acceptance. Community/modder practice is **fallback evidence**, not proof that the community/modder route is necessary.

---

## Command 10 — publish the current GitHub-safe game reference snapshot

```powershell
pwsh ./tools/Publish-LocalGameReferenceSnapshot.ps1 `
  -GamePath 'C:\Games\Steam\steamapps\common\Cyberpunk 2077'
```

It publishes derived metadata only, never proprietary Cyberpunk payload.

---

## Command 11 — branch-pinned read-only pre-W10 framework transition probe

`Bootstrap-LegacyFrameworkTransitionProbe.ps1` is issue-64/W11 historical transition tooling. It is read-only against the installed game, worktree-aware, exact-head/offline-safe, and emits an attachable report plus hash-bound plan.

---

## Command 12 — parent-authorized exact W11 framework retirement

`Bootstrap-LegacyFrameworkTransitionCleanup.ps1` is the mutating half of Command 11. It requires the exact reviewed branch/head and plan path/hash, rechecks safety immediately before deletion, protects shared roots/redscript/preferences, and deletes only the approved exact retired files.

---

## Command 13 — legacy post-W11 candidate preparation compatibility entrypoint

`tools/Bootstrap-BiologyPostTransitionCandidate.ps1` remains supported as the inner/legacy compatibility implementation because existing W12 evidence and tests depend on its report semantics. It is zero-local-repo-safe, worktree-aware, exact-head/offline-safe, builds/installs/deploys the release-shaped candidate, records evidence, retains its bounded candidate artifact state, and prints `STOP_BEFORE_GAME_LAUNCH=YES`.

Its historical report may contain `KEEP UNTIL ATTENDED TEST`. **Do not use that wording as a new human-memory contract.** New owner-facing attended tests use Command 17.

---

## Command 14 — managed post-W11 candidate preparation

Repository-owned entrypoint:

```text
tools/Bootstrap-BiologyManagedPostTransitionCandidate.ps1
```

Typical standalone invocation:

```powershell
pwsh '<exact-main-checkout>\tools\Bootstrap-BiologyManagedPostTransitionCandidate.ps1' `
  -MainSha '<exact 40-character canonical main SHA>' `
  -TransitionEvidenceId '<repo-backed transition evidence id>' `
  -GameRoot 'C:\Games\Steam\steamapps\common\Cyberpunk 2077'
```

This wrapper independently supports zero local repo state, resolves exact canonical main, invokes the legacy inner preparation, and records exact source revision, artifact identity, schema-2 payload inventory, receipt hash, mutation/deployment state, recovery eligibility, and exact managed artifact cleanup metadata in one `Biology-Operator-Evidence-<id>.zip` containing `evidence.json` and `report.txt`.

For W15.3, Command 17 may invoke this wrapper internally when a selected attended plan needs managed post-transition candidate preparation. The owner should not have to return its intermediate ZIP before launching the game in the ordinary attended flow.

---

## Command 15 — repository-evidence-backed failed-install recovery

Repository-owned entrypoint:

```text
tools/Bootstrap-BiologyManagedFailedInstallRecovery.ps1
```

It reacquires exact canonical source and derives safe recovery from durable repository evidence. Exact Biology-owned files are removable only when installed hashes exactly match evidence; changed/foreign/ambiguous content and reparse points fail closed. Generic redscript/cybercmd entries are always preserved shared dependencies. The legacy pre-lifecycle escape hatch permits only proven empty Biology-owned roots. This command does not launch Cyberpunk or deploy REDmod.

---

## Command 16 — repo-confirmed local operator evidence cleanup

Repository-owned entrypoint:

```text
tools/Bootstrap-BiologyOperatorEvidenceCleanup.ps1
```

Inputs are exact canonical main, stable EvidenceId, and the local handoff ZIP. Cleanup authenticates local `evidence.json`/`report.txt` against durable repository copies, then validates a recorded machine-managed candidate artifact root by exact inventory and hashes.

Cleanup fails closed on evidence mismatch, wrong ID, changed/foreign content, reparse points, path ambiguity, or **any missing expected artifact file**. Only after validation may it remove that exact managed artifact root and matching handoff ZIP.

**Commands 14-16 remain standalone preparation/recovery compatibility and recovery operations; they are not the ordinary READY FOR PC TEST handoff.** Command 17 reuses their safe primitives inside one attended session when appropriate.

---

## Command 17 — one-command attended test session

This is the normal owner-facing command after P01.2 says an exact canonical candidate is **READY FOR PC TEST**.

Canonical PowerShell engine:

```text
tools/Start-BiologyAttendedSession.ps1
```

Thin launcher:

```text
tools/Start-BiologyAttendedSession.cmd
```

The `.cmd` contains no session logic; it only invokes the canonical PowerShell engine and forwards arguments. From an exact reviewed checkout the parent may give the owner one invocation such as:

```text
Start-BiologyAttendedSession.cmd -MainSha <exact-canonical-main-sha>
```

When the test plan needs W11 transition-backed candidate preparation, the same one invocation adds the stable evidence ID:

```text
Start-BiologyAttendedSession.cmd -MainSha <exact-canonical-main-sha> -TransitionEvidenceId <evidence-id>
```

`-PreparationMode Auto` is the default: with a transition evidence ID it reuses managed post-transition preparation; without one it binds the session to an already installed schema-2 Biology candidate whose `sourceRevision` exactly equals the requested main SHA. The parent chooses the correct mode based on the test plan; the owner should not be asked to reconstruct that decision.

Zero local repo remains supported through the bootstrap-loader boundary above: the parent may provide one exact-revision loader command that materializes the reviewed session entrypoint. Never substitute an unpinned download of current `main`.

The owner interaction is exactly one continuous console lifecycle:

```text
READY TO LAUNCH CYBERPUNK
Listener active. Leave this window open.
After you have exited the game, return here and type END.

<owner launches Cyberpunk normally through Steam and tests>
<owner exits Cyberpunk>
END

ATTACH THIS ONE EVIDENCE BUNDLE TO CHATGPT:
C:\Games\Biology-Operator-Evidence-<session-id>.zip
TYPE SENT AFTER THE FILE HAS BEEN ATTACHED
SENT
SESSION ENDED CLEANLY
```

The listener **never launches Cyberpunk**. While waiting in that same console it watches process start/exit. After `END`, it captures/finalizes:

- exact source/candidate and installed receipt identity;
- pre-launch versus post-exit state;
- the `scc.toml`-configured REDscript output and timestamp companion;
- bounded `r6/logs/redscript_rCURRENT.log` state and new delta;
- official REDmod generated `mods.json` and generated TweakDB file state;
- cybercmd/RED4ext task-runner/loader state relevant to current startup evidence;
- bounded current framework logs;
- bounded REDEngine crash artifacts and Windows Application crash/hang events when available;
- observed Cyberpunk process lifecycle, including `NOT-OBSERVED` and `STARTED-AND-EXITED-QUICKLY` classifications.

Therefore if Cyberpunk never reaches a stable session or exits immediately, the owner still returns this same one bundle. **Do not ask for a second diagnostic chain afterward unless the returned evidence itself proves a genuinely new unanswered boundary.**

After the bundle is finalized, the listener asks the owner to type `SENT`. Before `SENT`, evidence and exact cleanup state are preserved. After `SENT`, cleanup is fail-closed and removes only:

- the exact session staging root authenticated by its session marker;
- the exact disposable session worktree;
- a session-created seed repo, if this session actually created it;
- exact W15.2 managed candidate artifact residue when the embedded managed evidence authorizes hash/inventory-bounded removal;
- the one evidence ZIP after the owner confirms it was attached.

The installed Biology candidate is **not** a generic session-cleanup target. It remains installed unless a separate explicit test plan authorizes candidate removal/rollback. If cleanup cannot prove ownership/safety, it preserves the ambiguous residue and reports fail-closed instead of broadening deletion.

---

## Parent evidence ingestion rule

When the owner returns a managed evidence ZIP, P01.2 inspects it, records meaningful attended conclusions under `docs/test-runs/` as appropriate, and commits redistributable evidence members under:

```text
docs/operator-evidence/<evidence-id>/evidence.json
docs/operator-evidence/<evidence-id>/report.txt
```

The local PC does not need GitHub write credentials. Parent/assistant, not the local operator PC, performs durable repository ingestion. Do not commit candidate ZIPs, proprietary game files, or unnecessary third-party binaries.

For Command 17, `SENT` means the owner confirms the handoff ZIP has been attached to the ChatGPT parent conversation. The session can then clean its exact local residue without waiting for a second owner command. The parent subsequently ingests the returned redistributable evidence into the repository.

---

## Rules for agents asking the owner to run PowerShell/CMD

1. Look here first. Use catalogued entrypoints instead of reconstructing their internals in chat.
2. When READY FOR PC TEST, prefer Command 17 and one continuous console session.
3. Never assume a permanent repo path; zero local repo must remain supported.
4. Do not use or recreate the retired `C:\Games\CyberpunkRealism` checkout path.
5. Branch-specific work pins exact branch/head and uses fail-closed cached-origin fallback after fetch failure.
6. One user-returned operation should create one obvious handoff file.
7. Do not ask the owner to maintain open-ended loose-file retention or deletion lists.
8. Native child stdout/stderr/exit/exception evidence must survive failure.
9. Long operations need durable console output, not only ephemeral progress UI.
10. Do not describe a fast sanity check as full baseline/hash verification.
11. After a genuine fresh reinstall, exhaustive baseline hashing is optional unless the test plan explicitly requires it.
12. Iteration cleanup on a reused install remains stricter and must fail closed to milestone reset when ownership/baseline proof fails.
13. If an operation fails, return its managed evidence rather than improvising destructive cleanup.
14. A successful disposable checkout is not persistent cross-turn state.
15. Parent/assistant, not the local PC, ingests durable evidence into GitHub.
16. Do not ask the owner to recreate a missing historical candidate ZIP when durable exact evidence can safely establish the boundary.
17. If a recurring operation is awkward, improve the repository tool/catalog/CI contract before treating an ad-hoc chain as standard.
