# W14.1 — Release Installer Create-Path Repair

Parent: **P01.2**  
Issue: **#70 — Attended follow-up — collision-safe release installer fails on first create action**  
Branch: **`agent/release-installer-create-repair`**

## Startup rule

Independently resolve and report the exact current worker-branch head at startup. Do not assume the branch still equals the parent-routing/base SHA below.

Parent routing base was:

`04d4c1584df4b0823e093422b98cf4c5575c7b19`

## Read first

- `AGENTS.md`
- `AGREED-GOALS.md`
- `docs/THREAD-LEDGER.md`
- `docs/DECISION-HISTORY.md`
- `docs/PARALLEL-AGENT-WORKFLOW.md`
- `docs/INTEGRATION-ORCHESTRATOR.md`
- `docs/LOCAL-OPERATOR-COMMANDS.md`
- `docs/handoffs/W13-INSTALLED-RUNTIME-ACTIVATION-FOLLOWUP.md`
- `tools/BiologyReleaseInstall.Core.ps1`
- `tools/Install-BiologyRelease.ps1`
- `tools/Bootstrap-BiologyPostTransitionCandidate.ps1`
- `tools/Prepare-BiologyMilestoneTest.ps1`
- `tests/Test-BiologyReleaseInstallSafety.ps1`
- issue #70 and the latest comments on issue #68

## Triggering attended evidence

After W13 merged, parent P01.2 rebuilt exact canonical source `04d4c1584df4b0823e093422b98cf4c5575c7b19` through Command 13.

The following all passed before installation:

- W11 transition evidence hash matched;
- all 42 retired framework paths remained absent;
- Biology-specific removal verifier passed;
- redscript `0.5.31` and cybercmd `0.0.13` verified;
- all 62 Biology REDscript sources exact-compiled offline;
- release-shaped package built;
- artifact policy passed;
- collision-safe install `-WhatIf` preflight passed.

Exact retained attempted artifact:

- ZIP: `biology-integrated-20260916-144813-04d4c1584df4.zip`
- SHA-256: `76A86A77A3C7AE36306B203C7946B88C5D56E1F7B0689489DA7EAF6D8783C796`
- bytes: `1979796`

The real install then failed:

```text
Install-BiologyRelease.ps1: Exception calling "Replace" with "4" argument(s): "The path is empty. (Parameter 'path')"
```

The outer bootstrap correctly stopped and reported:

- `RESULT: FAIL-CLOSED`
- `Game mutation started: True`
- `Installed receipt exact revision verified: False`
- `REDmod deployment passed: False`

Do not infer that the installed game is clean or complete. Parent will not improvise cleanup. W14 owns only the source repair; parent owns the next exact rebuild/install and attended validation.

## Likely boundary — verify, do not assume

At the routed base, `Copy-BiologyReleaseVerified` stages a temporary file and then calls:

```powershell
[IO.File]::Replace($temporary,$Destination,$null,$true)
```

for both `create` and `replace` install actions, with a typed `catch [IO.FileNotFoundException]` intended to fall back to `Move-Item` when the destination does not exist.

The attended failure is consistent with the `create` path reaching `File.Replace` with no existing destination while PowerShell surfaces/wraps the .NET exception in a way the typed catch does not handle. **Reproduce this with a focused fixture before deciding the fix.**

## Goal

Make the collision-safe release installer correctly and safely execute all planned action classes:

- `create` — install an absent destination without relying on exception-type guessing;
- `preserve` — leave exact matching files untouched;
- permitted `replace` — atomically replace only paths allowed by policy, especially `bin/x64/plugins/cybercmd.asi`;
- protected shared collision — continue to fail before mutation for non-identical `bin/x64/global.ini` or `bin/x64/version.dll`.

## Required safety properties

1. Full release hash validation and collision planning still complete before game-file writes begin.
2. Create and replace semantics are explicit; do not use a thrown exception as the normal create/replace branch selector.
3. Destination state is rechecked after preflight and immediately before each write.
4. A create operation must not overwrite a path that appeared after preflight.
5. A replace operation must not proceed if the preflight destination identity changed.
6. Temporary files are verified and cleaned on failure.
7. The ownership receipt remains published last, only after all inventoried payload files verify.
8. Non-identical `global.ini` / `version.dll` remain fail-closed before mutation.
9. Only `cybercmd.asi` remains replaceable within standalone cybercmd.
10. Parent/player candidate paths continue using the guarded installer rather than blind ZIP merge.

## Regression coverage

Extend `tests/Test-BiologyReleaseInstallSafety.ps1` (or add a narrowly named companion test) so the real copy/write executor is exercised, not just planning.

At minimum prove:

- absent ordinary file => successful create with exact hash;
- absent protected shared loader/config => successful create with exact hash;
- matching existing protected shared loader/config => preserve unchanged;
- differing protected shared loader/config => fail before any payload mutation;
- permitted differing `cybercmd.asi` => successful replace with exact hash;
- simulated destination change between plan and execution => fail closed;
- ownership receipt publication remains last/verified through the release installer path;
- no blind `Expand-Archive -Force` regression.

If the attended error has a different independently reproduced root cause, fix that cause while preserving the same safety requirements and document the evidence.

## Scope boundaries

Do **not** broaden into:

- W13 REDscript/cybercmd startup architecture beyond what installer testing requires;
- Biology UI or body runtime behavior;
- E3 presentation;
- physiology/combat/scanner changes;
- REDmod activation sentinel redesign;
- dependency strategy redesign;
- uninstaller redesign;
- installed-game cleanup or mutation.

Do not ask the user to install/play the worker branch. Do not ask for a Cyberpunk reinstall. Do not merge your own PR.

## Return to parent

Open a PR to `main` and return:

- independently resolved startup head;
- exact final worker head;
- independently reproduced root cause;
- repair summary;
- focused regression results;
- full CI status, distinguishing unrelated inherited failures if any;
- PR number and mergeability.

Parent P01.2 will review/merge, then rebuild from the new exact canonical `main`, re-enter the collision-safe candidate route, and only after successful install/deploy resume W13's before/after-launch `final.redscripts` acceptance.
