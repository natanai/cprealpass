# Biology attended testing contract

Status: canonical attended-test workflow  
Last updated: 2026-09-15

## Purpose

Biology is intended to ship as a REDmod-first, game-root-shaped package that a player can extract/copy into Cyberpunk 2077, enable/deploy through the supported REDmod path, and then launch normally through Steam.

Testing must answer two separate questions without conflating them:

1. **Is this specific Biology change working?** — ordinary iteration.
2. **Does the whole current product work from a truly clean player-like installation?** — milestone clean-room acceptance.

A full Cyberpunk reinstall is deliberately **not** required for every small iteration. At the same time, Biology must never silently accumulate unknown files across test builds.

The local source checkout is cheaper to replace than the game and is therefore treated more strictly: **every user-facing attended build test uses a fresh clone/download of canonical `main`.**

Routine user-run commands are standardized in `docs/LOCAL-OPERATOR-COMMANDS.md`. Agents should use those repository-owned entrypoints rather than inventing new PowerShell orchestration in chat.

## Canonical integrated candidate

The active REDmod-first attended package builder is:

```powershell
pwsh ./tools/Build-BiologyPackage.ps1
```

It produces a game-root-shaped ZIP named like:

```text
biology-integrated-<UTC timestamp>-<12-char source SHA>.zip
```

The official first-party package identity inside the ZIP is:

```text
mods/Biology/info.json
```

The builder exact-compiles the complete merged Biology REDscript candidate against the supported installed Cyberpunk 2077 2.31 `r6/cache/final.redscripts` before it can emit the ZIP. It does **not** install, deploy, launch, or modify the game.

`Build-CleanRoomTestPackage.ps1` is the known-working pre-REDmod/RealPass fallback retained temporarily under PKG-06. It is no longer the canonical integrated candidate route and must not be used for the REDmod-first milestone merely because it still exists.

## Test mode A — iteration test

Use iteration mode for a focused follow-up only when all of the following are true:

- Cyberpunk itself has not patched since the recorded vanilla baseline;
- package/dependency layout has not changed structurally since the accepted milestone;
- the prior installed Biology package still has `biology/build-manifest.json`;
- that manifest accounts for every installed package payload file;
- removing those exact package-owned files and comparing the entire game to the recorded vanilla baseline produces no unexplained drift.

### Iteration cycle

1. Close Cyberpunk.
2. Delete/re-create the local source workspace from current canonical `main`.
3. Run the Biology manifest-based reset:

   ```powershell
   pwsh ./tools/Reset-BiologyIteration.ps1 \
     -GameRoot 'C:\Games\Steam\steamapps\common\Cyberpunk 2077'
   ```

4. The reset removes only files that are all of the following:
   - listed by the installed `biology/build-manifest.json` or are its known generated metadata;
   - hash-identical to that installed package record;
   - absent from the recorded vanilla baseline.
5. The reset then performs a strict full-game baseline comparison. Any extra, missing, size-changed, or hash-changed file fails the reset.
6. Build the next release-shaped candidate from fresh canonical source:

   ```powershell
   pwsh ./tools/Build-BiologyPackage.ps1 \
     -GameRoot 'C:\Games\Steam\steamapps\common\Cyberpunk 2077'
   ```

7. Merge the generated ZIP contents into the game root exactly as a player would.
8. Deploy REDmod through the supported path. For deterministic developer/probe use:

   ```powershell
   pwsh ./tools/Deploy-BiologyRedmod.ps1 \
     -GameRoot 'C:\Games\Steam\steamapps\common\Cyberpunk 2077'
   ```

   The helper uses official `tools/redmod/bin/redMod.exe deploy` with an explicit `-root=<Cyberpunk 2077>` and never relies on REDmod's default-root heuristic.
9. Use the supported REDmod enable flow as required, then launch normally through Steam and test that exact candidate.

If cleanup or the baseline comparison cannot prove the game is back at baseline, **do not install another candidate over it**. Escalate to milestone clean-room mode.

The legacy `Reset-RealPassIteration.ps1` exists only for a prior RealPass-era package whose owner manifest is `realpass/build-manifest.json`. It is not the active Biology reset route.

## Test mode B — milestone clean-room

Use milestone clean-room mode for:

- large product milestones;
- major structural/runtime/package changes;
- REDmod package/dependency changes;
- Cyberpunk patches;
- bundled framework changes;
- changes that move or replace installed paths;
- unexplained baseline drift;
- missing/corrupt previous owner manifests;
- periodic release-level confidence checks.

**The first attended test of the integrated REDmod-first package is a MILESTONE CLEAN-ROOM test.** The package/dependency architecture changed structurally from the pre-REDmod baseline.

### Strong clean-room reset

1. Close Cyberpunk.
2. Uninstall Cyberpunk 2077 in Steam.
3. After uninstall finishes, manually remove any residual Cyberpunk 2077 game directory if it still exists.
4. Reinstall Cyberpunk 2077 through Steam, including supported official REDmod tooling.
5. Optionally launch vanilla once, load a save/menu, then exit.
6. Bootstrap a disposable milestone workspace from the exact canonical `main` SHA using **Command 0** in `docs/LOCAL-OPERATOR-COMMANDS.md`.
7. `Prepare-BiologyMilestoneTest.ps1` asks whether the user wants the **exhaustive full-file/hash comparison** against the tracked vanilla baseline.
   - If **Yes**, run the strict baseline comparison with visible durable progress.
   - If **No**, this is allowed only when the user confirms they just completed the Steam uninstall + residual-directory deletion + reinstall. Run `Test-VanillaGameSanity.ps1` instead.
   - The fast sanity path checks the supported game/REDmod versions and obvious loose-mod roots, but it is **not** equivalent to verified whole-game hashes.
8. The same canonical milestone command creates a second pristine candidate clone at the exact SHA, builds the release-shaped Biology ZIP, installs that exact ZIP, and deploys REDmod with an explicit game root.
9. Return the generated `milestone-prep.json` / console evidence to the parent integration thread before launching the game.
10. Launch normally through Steam only after the parent issues the attended checklist, then execute the combined acceptance checklist from `ACTIVE-REDMOD-ROADMAP.md` plus the merged Lane B/Lane C PR requirements.
11. Record the attended result under `docs/test-runs/` against the exact main SHA and exact artifact.

Deleting the game install directory is distinct from deleting save data. Biology testing must not delete saves/settings unless the user explicitly requests that separately.

### Why the exhaustive post-reinstall hash pass is optional

A fresh uninstall, deletion of the residual install directory, and Steam reinstall is already strong evidence that stale Biology/mod files were removed. Re-hashing every game file immediately afterward can be expensive and redundant for a user who just performed that reset.

Therefore, after that exact fresh-reinstall sequence, the exhaustive baseline comparison is **optional at the user's choice** and defaults to **No** in the canonical milestone command. Skipping it does not weaken the requirement for a clean reinstall; it only avoids a second expensive proof step.

When skipped, the evidence must say something equivalent to:

```text
fresh Steam reinstall + fast vanilla sanity; exhaustive hash check skipped
```

It must **not** say `verified against recorded vanilla baseline`.

The exhaustive comparison remains required for iteration cleanup on a reused install, for unexplained residue/drift, or whenever the parent specifically needs full hash-level proof.

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

It never contains Cyberpunk executables, archives, DLLs, textures, audio, meshes, scripts, saves, or other proprietary game content.

The baseline is intentionally stronger than Steam Verify for residue detection. Steam Verify can restore missing/changed Steam-owned files, but it is not relied on to discover/delete arbitrary extra mod files. A recorded path/hash baseline detects those extras explicitly.

## Current installation snapshot vs vanilla baseline

These are different:

- `reference/cyberpunk/` root files such as `filesystem-index.csv`, `frameworks.json`, and `installed-scripts.csv` describe the **current observed installation** when the local reference was last refreshed;
- `reference/cyberpunk/vanilla-baseline/` describes the known-clean vanilla reference used to detect residue.

The current snapshot may legitimately describe a Biology-installed test environment. The vanilla baseline must not.

Git history is the running archive of GitHub-safe snapshots. Refresh/commit the current snapshot after meaningful game/framework/install changes rather than creating a proprietary game mirror.

## Capturing and publishing a clean baseline

Baseline capture is a deliberate maintenance operation, **not a mandatory second full-game scan after every milestone reinstall**. Use it when the tracked clean reference itself needs to change — for example after a supported Cyberpunk patch or when the parent intentionally refreshes the canonical clean reference.

On a genuinely clean installation:

```powershell
pwsh ./tools/Capture-VanillaGameBaseline.ps1 \
  -GameRoot 'C:\Games\Steam\steamapps\common\Cyberpunk 2077' \
  -Publish
```

The tool:

1. requires Cyberpunk to be closed;
2. refuses obvious mod-shaped files in the candidate vanilla baseline;
3. permits only the exact zero-byte REDmod `.stub` marker under `mods`;
4. refreshes the ordinary GitHub-safe current snapshot;
5. hashes the full clean game file set;
6. writes only safe metadata under `reference/cyberpunk/vanilla-baseline/`;
7. when `-Publish` is supplied, creates a dedicated `local-vanilla-baseline-*` branch, commits only `reference/cyberpunk/`, and pushes that branch.

Hashing the full game reads a large amount of data. That cost belongs to deliberate baseline maintenance or stronger verification, not every milestone by default and not every quick iteration.

## Verifying a game against the baseline

Use the catalogued exhaustive command:

```powershell
pwsh ./tools/Compare-GameToVanillaBaseline.ps1 \
  -GameRoot 'C:\Games\Steam\steamapps\common\Cyberpunk 2077'
```

The check is strict. It reports and fails on:

- files present now but absent from baseline;
- baseline files that are missing;
- size changes;
- SHA-256 changes.

Because the scan can take several minutes, it emits both native `Write-Progress` and durable console progress similar to:

```text
VERIFY [#######-------------]  35% | 1842/5200 files | 29.4/84.0 GiB | elapsed 00:01:42
```

This is the evidence required before calling a **reused iteration installation** fully baseline-verified. For a just-completed milestone reinstall, the user may choose the documented fast-sanity path instead.

## Why manifest-based cleanup is safe and limited

Every finalized Biology candidate contains:

```text
biology/build-manifest.json
```

That manifest records every ordinary package payload file with its exact hash, owner, component, route and replace policy. `Reset-BiologyIteration.ps1` uses it only as the ownership record for the immediately installed candidate.

The reset is intentionally conservative:

- it never deletes a path that existed in the vanilla baseline;
- it never deletes a package-owned path whose current hash no longer matches the installed manifest;
- it never guesses if the manifest is missing or malformed;
- it never recursively owns shared roots such as `bin`, `engine`, `r6`, `archive`, or `red4ext`;
- after cleanup it still requires the full vanilla-baseline comparison to pass.

If any of those checks fail, the correct response is a milestone reset, not increasingly aggressive deletion logic.

## Fresh repository rule

For every user-facing attended build test — iteration or milestone — the candidate is built from the repository exactly as another person would receive it:

- current canonical `main` named by the parent;
- fresh clone/download rather than a long-lived modified working tree;
- no uncommitted source changes;
- no stale generated `staging`, `vendor`, `reports`, deployment receipts, or retired scripts assumed as inputs.

Generated dependency caches and staging produced *after* the fresh checkout by the canonical package builder are allowed; they are build outputs, not hidden source inputs.

For milestone tests with no pre-existing local repo, use the disposable `C:\Games\Biology-Test-<date>-<short-sha>` convention from `docs/LOCAL-OPERATOR-COMMANDS.md`. The operator clone and pristine candidate clone are intentionally separate.

## Package-under-test rule

Do not treat the repository root as the player mod. The repository contains source, tests, tools and documentation that must not be copied into the game.

The package under test is the generated **game-root-shaped Biology ZIP** containing only runtime payload, approved exact dependency files/notices, and package metadata.

The intended flow is:

```text
fresh canonical main
-> canonical milestone/operator command
-> optional exhaustive baseline check OR fresh-reinstall fast sanity
-> pristine candidate clone
-> Build-BiologyPackage.ps1
-> exact compile succeeds
-> generated Biology ZIP
-> merge into clean game root
-> explicit-root REDmod deploy / supported enable flow
-> parent evidence review
-> Steam Play
```

The same package shape used for attended testing converges on the eventual downloadable release ZIP.

## Exact compilation is not attended acceptance

A narrow exact-compile/build diagnostic may use an existing supported local game install under the narrow investigation exception, because it only reads the supported game bundle and does not install/deploy a package.

A successful exact compile proves source compatibility with the 2.31 script bundle. It does **not** prove:

- REDmod recognizes Biology;
- enablement persists;
- the body UI works live;
- HUD/nameplates render correctly;
- save/reload behavior;
- clean uninstall/reset;
- PKG-05 overlap precedence.

Those remain parent-coordinated direct/attended gates.

## When an agent may ask for each mode

An agent saying a build is ready must explicitly name the mode.

Choose **ITERATION** when the package architecture is already accepted and the game can be proven baseline-clean by exact manifest cleanup + baseline comparison.

Choose **MILESTONE CLEAN-ROOM** when the change is structural, the game/framework version changed, residue cannot be proven absent, or release-level confidence is the purpose of the test.

Do not ask for a full reinstall merely because it is safer in the abstract. Do not skip a reinstall when the structural-change rule requires it. After a genuine milestone reinstall, do not force the additional exhaustive hash pass if the user declines it; record the fast-sanity evidence accurately instead.

## Agent handoff checklist

Before telling the user to launch a build, state all four:

1. `Test mode: ITERATION` or `Test mode: MILESTONE CLEAN-ROOM`.
2. Exact canonical `main` revision.
3. Game-state evidence, accurately classified as either full baseline verification or fresh-reinstall + fast-sanity with exhaustive hash check skipped.
4. Exact generated Biology ZIP merged into the game root.

For the REDmod-first structural milestone, also state the exact deployment/enable action and record its result separately from gameplay acceptance.

If those facts cannot be stated, the build is not ready for an attended handoff.
