# Biology attended testing contract

Status: **canonical attended-test workflow**  
Last updated: **2026-09-15**

## Purpose

Biology testing has two goals that must not be conflated:

1. prove a focused change on an accounted installation;
2. periodically prove the whole release-shaped product from a genuinely clean player-like installation.

A full Cyberpunk reinstall is deliberately **not** required for every small iteration. Conversely, Biology must never layer a new candidate onto unexplained residue.

Every user-facing attended build uses fresh canonical source. Routine local commands come from `docs/LOCAL-OPERATOR-COMMANDS.md`; agents should not reconstruct repository tooling as chat-only PowerShell.

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
3. Run the Biology ownership-aware reset:

   ```powershell
   pwsh ./tools/Reset-BiologyIteration.ps1 `
     -GameRoot 'C:\Games\Steam\steamapps\common\Cyberpunk 2077'
   ```

4. The reset removes only safely proven package-owned files and refuses changed/ambiguous files.
5. The reset performs the strict full baseline comparison before another candidate may be layered onto the reused installation.
6. Build the next release-shaped artifact with `Build-BiologyPackage.ps1`.
7. Install the generated ZIP contents exactly as a player package would be installed.
8. Deploy through `Deploy-BiologyRedmod.ps1` or the corresponding supported player REDmod flow.
9. Launch normally through Steam and test the exact artifact named by the parent.

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
6. Bootstrap a disposable workspace from the exact canonical main SHA using Command 0 in `docs/LOCAL-OPERATOR-COMMANDS.md`.
7. The milestone preparation command asks whether to run the exhaustive whole-game comparison against the tracked baseline.
   - **Yes:** run the strict hash comparison with durable progress.
   - **No:** allowed only after the just-completed uninstall + residual-directory deletion + reinstall; run the fast vanilla sanity check instead.
8. Build/install the exact release-shaped Biology candidate and deploy REDmod through the repository-owned helper.
9. Return the generated report/evidence to the parent before gameplay launch when the operator command requests it.
10. Run the parent-issued attended checklist against that exact artifact.
11. Record meaningful results under `docs/test-runs/`.

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
-> canonical milestone preparation command
-> optional exhaustive baseline check OR fresh-reinstall fast sanity
-> pristine candidate source
-> Build-BiologyPackage.ps1
-> exact compile succeeds
-> generated Biology ZIP
-> install exact ZIP
-> Deploy-BiologyRedmod.ps1 / supported enable flow
-> parent evidence review
-> Steam Play
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

If those facts cannot be stated, the build is not ready for an attended handoff.
