# W15.1 — Failed-Install Recovery ZIP Validation Repair

Parent: **P01.2**  
Issue: **#72 — Attended follow-up — W14 failed-install recovery rejects ordinary ZIP directory entries**  
Branch: **`agent/failed-install-recovery-zip-validation`**

## Startup rule

Independently resolve and report the exact current worker-branch head at startup. Do not assume the branch still equals the routing base below.

Parent routing base:

`b1e19c163e0bd24ce0648fe378c62eb801784300`

## Read first

- `AGENTS.md`
- `AGREED-GOALS.md`
- `docs/THREAD-LEDGER.md`
- `docs/PARALLEL-AGENT-WORKFLOW.md`
- `docs/INTEGRATION-ORCHESTRATOR.md`
- `docs/LOCAL-OPERATOR-COMMANDS.md`
- `docs/handoffs/W14-RELEASE-INSTALLER-CREATE-REPAIR.md`
- `tools/Bootstrap-BiologyFailedInstallRecovery.ps1`
- `tools/BiologyFailedInstallRecovery.Core.ps1`
- `tests/Test-BiologyReleaseInstallSafety.ps1`
- issue #72

## Triggering attended evidence

Parent executed the merged W14 failed-install recovery against the exact failed candidate/report.

The recovery correctly authenticated:
- Cyberpunk 2.31;
- failed candidate report SHA-256 `9709493A5D4C36F5960CAE2BF09781F664CEA32EB949A85375E44F2F7E943A1E`;
- failed attempted source `04d4c1584df4b0823e093422b98cf4c5575c7b19`;
- retained artifact SHA-256 `76A86A77A3C7AE36306B203C7946B88C5D56E1F7B0689489DA7EAF6D8783C796`.

It then stopped before source acquisition or installed-game mutation with:

```text
Unsafe artifact ZIP path segment: engine/config/
```

The report explicitly records:

```text
RESULT: FAIL-CLOSED
Recovery mutation started: False
Installed game remained unchanged by W14 recovery because failure occurred before recovery mutation began.
```

## Likely boundary — verify, do not assume

At the routing base, `Assert-SafeArtifactZip` normalizes an archive entry and splits it on `/`, rejecting empty path segments. An ordinary ZIP directory entry such as `engine/config/` therefore appears to generate a trailing empty segment and be falsely rejected.

Reproduce this with a focused archive fixture before changing the validator.

## Goal

Repair the recovery bootstrap ZIP validator so ordinary safe directory entries are accepted without weakening archive traversal/path safety.

Required regression coverage:

- safe ordinary file entries pass;
- safe ordinary directory entries ending in `/` pass;
- nested safe directory entries pass;
- `../` traversal fails;
- rooted or drive-qualified entries fail;
- `.` / `..` internal segments fail;
- unsafe/reserved path names remain fail-closed as appropriate;
- a release-shaped ZIP fixture with explicit directory entries proceeds beyond `Assert-SafeArtifactZip`;
- exact failed-report/artifact SHA binding remains unchanged;
- recovery stays read/plan-first and preserves shared redscript/cybercmd;
- zero-local-repo behavior remains supported.

## Scope boundaries

Do **not** broaden into:

- W14 create/replace installer semantics;
- REDscript/cybercmd startup architecture;
- Biology UI/body runtime/E3;
- REDmod sentinel redesign;
- dependency strategy;
- general uninstaller redesign;
- installed-game cleanup/mutation from the worker lane.

Do not ask the user to install/play the worker branch. Do not ask for a Cyberpunk reinstall. Do not merge your own PR.

## Return to parent

Open a PR to `main` and return:

- independently resolved startup head;
- exact final worker head;
- fixture reproduction of the directory-entry rejection;
- repair summary;
- focused regression results;
- full CI status, separating inherited bookkeeping failures if any;
- PR number and mergeability.

Parent P01.2 will review/merge, rerun the exact recovery against the unchanged failed installed state, and only after recovery PASS resume exact candidate rebuild/install/deploy.
