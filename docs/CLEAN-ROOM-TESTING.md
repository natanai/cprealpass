# RealPass attended testing contract

Status: canonical attended-test workflow
Last updated: 2026-09-15

## Purpose

RealPass is intended to ship as a simple game-root-shaped package that a player can extract/copy into Cyberpunk 2077 and then launch normally through Steam.

Testing must therefore answer two separate questions without conflating them:

1. **Is this specific RealPass change working?** — ordinary iteration.
2. **Does the whole current product work from a truly clean player-like installation?** — milestone clean-room acceptance.

A full Cyberpunk reinstall is deliberately **not** required for every small iteration. At the same time, RealPass must never silently accumulate unknown files across test builds.

The local RealPass source checkout is cheaper to replace than the game and is therefore treated more strictly: **every user-facing attended build test should use a fresh clone/download of canonical `main`.**

## Test mode A — iteration test

Use iteration mode for focused UI, gameplay, calibration, or bug-fix testing when all of the following are true:

- Cyberpunk itself has not patched since the recorded vanilla baseline;
- the bundled framework/dependency set and package layout have not changed in a way that could invalidate cleanup;
- the prior installed RealPass package still has its `realpass/build-manifest.json`;
- that manifest accounts for the files installed by the prior package;
- removing those package-owned files and comparing the game to the recorded vanilla baseline produces no unexplained drift.

### Iteration cycle

1. Close Cyberpunk.
2. Delete/re-create `C:\Games\CyberpunkRealism` from current canonical `main`.
3. If a prior RealPass package is installed, run the manifest-based reset tool:

   ```powershell
   Set-Location 'C:\Games\CyberpunkRealism'
   pwsh ./tools/Reset-RealPassIteration.ps1
   ```

4. The reset removes only files that are both:
   - listed in the installed package manifest; and
   - absent from the recorded vanilla baseline.

   It refuses to guess about changed files, vanilla-path overlaps, missing manifests, or unexplained residue.
5. The reset then performs a full baseline comparison. Any extra, missing, size-changed, or hash-changed file fails the reset.
6. Build the new release-shaped test package with:

   ```powershell
   pwsh ./tools/Build-CleanRoomTestPackage.ps1
   ```

7. Merge the ZIP contents into the game root exactly as a player would.
8. Launch normally through Steam and test that package.

If step 3 or 5 cannot prove the game is back at baseline, **do not install another candidate over it**. Escalate to milestone clean-room mode.

## Test mode B — milestone clean-room

Use milestone clean-room mode for:

- large product milestones;
- major structural/runtime/package changes;
- Cyberpunk patches;
- bundled framework or dependency changes;
- changes that may replace or move files rather than merely add owned files;
- unexplained baseline drift;
- missing/corrupt previous package manifest;
- any case where agents are not confident residue can be proven absent;
- periodic confidence checks even when iteration cleanup has been succeeding.

### Strong clean-room reset

1. Close Cyberpunk.
2. Uninstall Cyberpunk 2077 in Steam.
3. After uninstall finishes, manually remove any remaining `Cyberpunk 2077` game directory if it still exists.
4. Reinstall Cyberpunk 2077 through Steam.
5. Optionally launch vanilla once, load a save/menu, then exit. If doing so, capture the baseline **after** this vanilla launch so normal first-run artifacts are represented.
6. Before installing RealPass, capture a GitHub-safe vanilla baseline with:

   ```powershell
   Set-Location 'C:\Games\CyberpunkRealism'
   pwsh ./tools/Capture-VanillaGameBaseline.ps1
   ```

7. Use a fresh clone/download of canonical `main` for the package build.
8. Build `Build-CleanRoomTestPackage.ps1` and merge the generated ZIP into the vanilla game root.
9. Launch through Steam and test.

Deleting the game install directory is distinct from deleting save data. RealPass testing must not delete saves/settings unless the user explicitly requests that separately.

## Vanilla baseline contract

The tracked vanilla baseline lives under:

```text
reference/cyberpunk/vanilla-baseline/
```

It contains **derived metadata only**:

- game version;
- capture timestamp;
- relative file paths;
- file sizes;
- SHA-256 hashes;
- aggregate counts/size.

It must never contain Cyberpunk executables, archives, DLLs, textures, audio, meshes, scripts, or other proprietary game content.

The baseline is intentionally stronger than Steam Verify for residue detection. Steam Verify can restore missing/changed Steam-owned files, but it is not relied on to discover/delete arbitrary extra mod files. A recorded path/hash baseline lets us detect those extras explicitly.

The baseline should be refreshed/replaced after a legitimate game patch or a deliberate change to what counts as the clean supported installation.

## Current installation snapshot vs vanilla baseline

These are different things:

- `reference/cyberpunk/` root files such as `filesystem-index.csv`, `frameworks.json`, and `installed-scripts.csv` describe the **current observed installation** when `Refresh-LocalGameReference.ps1` was last run.
- `reference/cyberpunk/vanilla-baseline/` describes the **known-clean vanilla reference state** used to detect residue.

The current snapshot may legitimately describe a RealPass-installed test environment. The vanilla baseline must not.

Git history is the running archive of those GitHub-safe snapshots. Refresh/commit the current snapshot after meaningful game/framework/install changes rather than inventing a second proprietary game mirror.

## Capturing and publishing a clean baseline

On a genuinely clean installation, run:

```powershell
Set-Location 'C:\Games\CyberpunkRealism'
pwsh ./tools/Capture-VanillaGameBaseline.ps1 -Publish
```

The tool:

1. requires Cyberpunk to be closed;
2. refuses obvious mod-shaped files in the candidate vanilla baseline;
3. refreshes the ordinary GitHub-safe current snapshot;
4. hashes the full clean game file set;
5. writes only safe metadata under `reference/cyberpunk/vanilla-baseline/`;
6. when `-Publish` is supplied, creates a dedicated `local-vanilla-baseline-*` branch, commits only `reference/cyberpunk/`, and pushes that branch.

The user can then give the branch name to a remote agent, which can review/merge the metadata without ever receiving proprietary game files.

Hashing the full game reads a large amount of data and may take several minutes. That cost is intentional and belongs to milestone baseline capture, not every quick iteration.

## Verifying a game against the baseline

Use:

```powershell
pwsh ./tools/Compare-GameToVanillaBaseline.ps1
```

The check is strict. It reports and fails on:

- files present now but absent from baseline;
- baseline files that are missing;
- size changes;
- SHA-256 changes.

This is the evidence required before calling a reused installation clean enough for another iteration package.

## Why manifest-based cleanup is safe and limited

Every finalized RealPass player package includes:

```text
realpass/build-manifest.json
```

That manifest records every packaged runtime file and its exact hash. `Reset-RealPassIteration.ps1` uses it only as an ownership record for the immediately installed test package.

The reset is intentionally conservative:

- it never deletes a path that existed in the vanilla baseline;
- it never deletes a package-owned path whose current hash no longer matches the installed manifest;
- it never guesses if the manifest is missing or malformed;
- after cleanup it still requires the full vanilla-baseline comparison to pass.

If any of those checks fail, the correct response is a milestone reset, not increasingly aggressive deletion logic.

## Fresh repository rule

For every user-facing attended build test — iteration or milestone — the candidate should be built from the repository exactly as another person would receive it:

- use current canonical `main`;
- delete/re-create the local `C:\Games\CyberpunkRealism` workspace rather than carrying local branch/stash/generated state forward;
- no uncommitted source changes;
- no stale generated `staging`, `vendor`, `reports`, deployment receipts, or retired scripts should be assumed as inputs.

Generated dependency caches and staging produced *after* the fresh checkout by the package builder are allowed; they are build outputs, not hidden source inputs.

## Package-under-test rule

Do not treat the repository root as the player mod. The repository contains source, tests, tools and documentation that should not be copied into the game.

The package under test is the generated **game-root-shaped artifact** containing only runtime payload and approved bundled generic framework files/notices.

The intended test action is:

```text
fresh canonical source -> generated RealPass ZIP -> merge into proven-clean game root -> Steam Play
```

The same package shape used for attended testing should converge on the eventual downloadable release ZIP.

## When an agent may ask for each mode

An agent saying a build is ready must explicitly name the mode.

Choose **ITERATION** when the game can be proven baseline-clean by manifest cleanup + baseline comparison.

Choose **MILESTONE CLEAN-ROOM** when the change is structural, the game/framework version changed, residue cannot be proven absent, or periodic release-level confidence is the purpose of the test.

Do not ask for a full reinstall merely because it is safer in the abstract. Do not skip a reinstall merely because it is inconvenient when the baseline evidence has failed.

## Narrow investigation exception

Targeted native-signature checks, read-only game-reference inspection, exact compile probes and other narrow diagnostics do not require fresh source/game state when the answer cannot be influenced by installed mod residue. These are evidence-gathering steps, not attended package acceptance.

## Agent handoff checklist

Before telling the user to launch a build, state all four:

1. `Test mode: ITERATION` or `Test mode: MILESTONE CLEAN-ROOM`.
2. Exact canonical `main` revision.
3. Game-state evidence: baseline comparison passed, or milestone reinstall/baseline capture completed.
4. Exact generated package/ZIP to merge into the game root.

If you cannot state those four things, the build is not ready for an attended test handoff.
