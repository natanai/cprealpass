# Biology attended testing contract

Status: **canonical attended-test workflow**  
Last updated: **2026-09-16**

## Purpose

Biology testing has two goals that must not be conflated:

1. prove a focused change on an accounted installation;
2. periodically prove the whole release-shaped product from a genuinely clean player-like installation.

A full Cyberpunk reinstall is deliberately **not** required for every small iteration. Conversely, Biology must never layer a new candidate onto unexplained residue.

Every user-facing attended build uses fresh canonical source. Routine local commands come from `docs/LOCAL-OPERATOR-COMMANDS.md`; agents should not reconstruct repository tooling as chat-only PowerShell.

## Canonical one-session attended handoff

Once the parent says an exact integrated Biology candidate is **READY FOR PC TEST**, the ordinary owner workflow is one attended session, not a sequence of separate pre-launch and post-launch probes.

The repository-owned source of truth is `tools/Start-BiologyAttendedSession.ps1`; `tools/Start-BiologyAttendedSession.cmd` is only a thin launcher into that PowerShell engine. The parent supplies the exact canonical `main` revision and any test-plan-specific preparation input. The same session may perform exact-source/candidate preparation when the selected test plan requires it, then establishes the pre-launch baseline before it reports readiness.

The owner interaction is:

```text
<run one command or the thin .cmd launcher>
READY TO LAUNCH CYBERPUNK
Listener active. Leave this window open.
After you have exited the game, return here and type END.

<launch Cyberpunk normally, test, exit>
END

ATTACH THIS ONE EVIDENCE BUNDLE TO CHATGPT:
C:\Games\Biology-Operator-Evidence-<session-id>.zip
TYPE SENT AFTER THE FILE HAS BEEN ATTACHED
SENT
SESSION ENDED CLEANLY
```

The session tool never launches Cyberpunk itself. While the same console waits for `END`, it quietly observes the Cyberpunk process. At `END` it finalizes bounded before/after and startup evidence, including configured REDscript output/current log state, REDmod generated state, task-runner state, relevant current logs, crash artifacts, and Windows crash/hang events when available. Therefore a launch that is never observed or exits immediately still returns the best evidence available to the current tooling without requiring the owner to run a second diagnostic chain afterward.

`SENT` is the cleanup gate. Before that confirmation, the one handoff ZIP is preserved. After confirmation, the session removes only exact session-owned repo/worktree/staging/test artifacts that it can prove safe to remove. The installed Biology candidate is not automatically disposable and remains installed unless an explicit test plan separately authorizes candidate removal or rollback.

Historical commands and records may still show separate preparation/probe phases. They remain useful implementation and recovery primitives, but they are not the normal meaning of a new READY FOR PC TEST handoff.

## Canonical Biology route

The current player-candidate builder is:

```powershell
pwsh ./tools/Build-BiologyPackage.ps1
```

It emits a game-root-shaped Biology ZIP containing the official first-party identity:

```text
mods/Biology/info.json
```

and exact package ownership metadata under:

```text
biology/build-manifest.json
```

The build exact-compiles the accepted Biology REDscript runtime against the supported Cyberpunk 2077 2.31 script bundle before artifact emission. It does not deploy or launch the game.

For deterministic direct deployment after package installation, use:

```powershell
pwsh ./tools/Deploy-BiologyRedmod.ps1 `
  -GameRoot 'C:\Games\Steam\steamapps\common\Cyberpunk 2077'
```

The helper owns native argument construction and fails closed on the REDmod false-positive conditions discovered during attended testing. Do not replace it with a hand-written raw `redMod.exe` invocation from old notes.

The old RealPass clean-room builder/finalizer/reset path has been retired from the active tree. Git history preserves it if historical research is ever needed.

## Test mode A — iteration test

Use iteration mode only when all of these are true:

- Cyberpunk itself has not patched since the relevant recorded vanilla baseline;
- package/dependency structure has not changed in a way that makes residue uncertain;
- the prior installed Biology package still has a valid `biology/build-manifest.json`;
- current files can be accounted for safely under that manifest;
- the repository reset can return the installation to the tracked vanilla baseline without unexplained differences.

### Iteration cycle

1. Close Cyberpunk.
2. Use fresh canonical source for the candidate.
3. Run the Biology ownership-aware reset when the test plan requires a reused-install reset:

   ```powershell
   pwsh ./tools/Reset-BiologyIteration.ps1 `
     -GameRoot 'C:\Games\Steam\steamapps\common\Cyberpunk 2077'
   ```

4. The reset removes only safely proven package-owned files and refuses changed/ambiguous files.
5. The reset performs the strict full baseline comparison before another candidate may be layered onto the reused installation.
6. Build/install/deploy the exact release-shaped candidate through the canonical tools or let the parent-selected attended session preparation mode reuse those repository-owned primitives.
7. When the parent declares that exact candidate READY FOR PC TEST, start the one-command attended session described above.
8. After `READY TO LAUNCH CYBERPUNK`, launch normally through Steam and test the exact artifact named by the parent.
9. Exit Cyberpunk, type `END` in the same console, attach the one returned evidence ZIP, then type `SENT` so exact session-owned residue can be cleaned.

If any of those checks fail, the correct response is a milestone reset, not broader deletion logic.

## Test mode B — milestone clean-room

Use milestone mode for structural package/dependency changes, Cyberpunk/REDmod/framework updates, moved install paths, unexplained residue, missing/corrupt ownership metadata, or deliberate release-level confidence.

The **first REDmod structural milestone is already complete**: the 2026-09-15 integrated candidate was built from clean source, installed into a proven clean Cyberpunk 2077 2.31 installation, recognized as `Biology` by official REDmod, and completed a real five-stage deployment. That evidence is recorded under `docs/test-runs/`.

Future structural milestones still use **MILESTONE CLEAN-ROOM** when the current change justifies it; the repository must not keep describing the already-completed first migration as future work.

### Strong clean-room reset

1. Close Cyberpunk.
2. Uninstall Cyberpunk 2077 in Steam.
3. Delete any residual Cyberpunk 2077 installation directory left behind after uninstall.
4. Reinstall through Steam with the supported official REDmod tooling.
5. Optionally launch vanilla once and exit.
6. Bootstrap exact canonical source using Command 0 in `docs/LOCAL-OPERATOR-COMMANDS.md` when the milestone preparation plan requires the clean-room workspace.
7. The milestone preparation command asks whether to run the exhaustive whole-game comparison against the tracked baseline.
   - **Yes:** run the strict hash comparison with durable progress.
   - **No:** allowed only after the just-completed uninstall + residual-directory deletion + reinstall; run the fast vanilla sanity check instead.
8. Build/install the exact release-shaped Biology candidate and deploy REDmod through repository-owned tooling, directly or through the parent-selected attended session preparation mode.
9. When the exact integrated candidate is READY FOR PC TEST, use the one-command attended session. Do not require a separate prelaunch evidence return and a later postlaunch probe as the ordinary handoff.
10. After the listener prints `READY TO LAUNCH CYBERPUNK`, launch normally through Steam and run the parent-issued attended checklist.
11. Exit, type `END`, attach the one evidence bundle, type `SENT`, and let the session clean its exact owned residue.
12. Record meaningful results under `docs/test-runs/`.

A fresh Steam reinstall is strong clean-room evidence but is **not** the normal Biology uninstall path. Player removal is moving to the manifest-safe self-contained uninstaller tracked by the release architecture/current issue #44.

## Exhaustive verification after a fresh reinstall

The exhaustive post-reinstall hash pass is **optional** after a genuine Steam uninstall, residual-directory deletion, and reinstall. It defaults to No in the canonical milestone preparation flow because immediately reading 85+ GiB again can be redundant.

If skipped, evidence must say something equivalent to:

```text
fresh Steam reinstall + fast vanilla sanity; exhaustive hash check skipped
```

It must not say the installation was `verified against recorded vanilla baseline`.

The exhaustive comparison remains required for the current conservative iteration reset on a reused installation, for unexplained drift, or when the parent explicitly needs hash-level proof.

## Vanilla baseline contract

The tracked baseline lives at:

```text
reference/cyberpunk/vanilla-baseline/
```

It contains derived metadata only: relative paths, sizes, SHA-256 hashes, game/version information, capture time and aggregate counts. It contains no Cyberpunk payload.

Baseline capture is deliberate maintenance work, normally after a supported game patch or when the canonical clean reference itself must change. It is not a mandatory second whole-game scan after every milestone reinstall.

The canonical capture and compare commands are documented in `docs/LOCAL-OPERATOR-COMMANDS.md`.

## Current snapshot versus vanilla baseline

Do not conflate these:

- `reference/cyberpunk/` root metadata describes the **current observed installation** when refreshed;
- `reference/cyberpunk/vanilla-baseline/` describes the known-clean vanilla reference used for residue detection.

A current snapshot may legitimately describe a Biology-installed state. The vanilla baseline may not.

## Manifest-safe iteration cleanup

`Reset-BiologyIteration.ps1` uses `biology/build-manifest.json` as the ownership record for the installed candidate. It is intentionally conservative:

- paths that existed in vanilla are protected;
- package-owned files whose current hash changed are not silently deleted;
- approved dependency files are owned per file rather than by recursively owning shared framework roots;
- missing/malformed ownership evidence causes failure;
- shared roots such as `bin`, `archive`, `engine`, `mods`, `r6`, and `red4ext` are never recursively deleted;
- the current iteration path ends with the strict vanilla-baseline comparison.

If any of those checks fail, the correct response is a milestone reset.

The future player-facing `Uninstall Biology.exe` has a different goal: safe hard removal without requiring a full reinstall. It must remain fail-closed on changed/shared/ambiguous files and is not permission to weaken iteration-test evidence.

## Fresh source rule

For every user-facing attended build, use source another person could actually receive:

- exact canonical `main` named by the parent;
- fresh clone/download or canonical disposable operator/candidate workspace;
- no uncommitted tracked source changes;
- no old generated staging/vendor/report state treated as hidden input.

Generated caches and staging created *after* the fresh checkout by canonical tools are build outputs and are allowed.

Repository/workspace paths are not stable. Do not assume a permanent checkout. The known game path may be used where the command catalog permits it:

```text
C:\Games\Steam\steamapps\common\Cyberpunk 2077
```

## Package-under-test rule

The repository root is not the player mod. The attended artifact is the generated game-root-shaped Biology ZIP, with its exact source SHA and checksum recorded.

Typical milestone flow:

```text
fresh canonical main
-> canonical milestone preparation policy
-> optional exhaustive baseline check OR fresh-reinstall fast sanity
-> exact release-shaped Biology candidate
-> exact compile succeeds
-> install/deploy through canonical repository tools
-> one attended session reaches READY
-> Steam Play
-> owner tests/exits
-> END finalizes one evidence bundle
-> SENT gates exact session-owned cleanup
```

## What compile/build/deploy each prove

Keep evidence claims narrow:

- exact compile proves source compatibility with the supported script bundle;
- package construction proves release-shape/ownership policy;
- REDmod recognition/deploy proves the official tool sees and deploys that installed package;
- none of those alone proves body-runtime lifecycle, UI rendering, save behavior, HUD/nameplates, quest safety, gameplay feel or performance.

The first integrated milestone already proved Biology recognition and five-stage deployment for its exact artifact. Future artifacts must still be identified/tested explicitly; do not regress that historical fact to “unknown,” and do not generalize it into untested runtime acceptance.

## Agent handoff checklist

Before telling the user to launch a build, state:

1. `Test mode: ITERATION` or `Test mode: MILESTONE CLEAN-ROOM`.
2. Exact canonical `main` revision.
3. Game-state evidence, accurately classified.
4. Exact Biology artifact/package and checksum when available.
5. The one attended-session command or thin `.cmd` invocation for that exact candidate.

If those facts cannot be stated, the build is not ready for an attended handoff.
