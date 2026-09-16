# W09.1 — Post-uninstall REDmod deploy-state evidence

Date: 2026-09-15

Issue: #59

Worker branch: `agent/redmod-post-uninstall-deploy-recovery`

Probe revision: `667f0098addbdd512e4c0c74cc02d0626237c726`

Attended production source preceding the probe: `7e61724071b8c95ba5c334ab9e8d11c43381c94e`

## Direct installed-game evidence

The user preserved the exact failed-redeploy state and ran the repository-owned read-only W09 probe. The report fingerprinted:

- Cyberpunk 2077 product version `2.31`
- `Cyberpunk2077.exe` SHA-256 `A7DE82945C03E041FC7339FCF9066224D98DB2F5D80FEA50F7947BB350A60991`
- REDmod file version `2.3.1.0`, product version `2.31`
- `redMod.exe` SHA-256 `144DF5A984669528CD957B40BB2126FE83B73D66BD0E041CA614C80F74E76A7F`
- `REDprelauncher.exe` version `4.2.0.4`

Exact filesystem observations in that preserved failed-redeploy state:

- `r6/cache` exists as a directory
- `r6/cache/modded` does **not** exist as a directory
- `r6/cache/modded` does **not** exist as a file
- `r6/cache/modded/tweakdb_ep1.bin` is absent
- `r6/cache/modded/mods.json` is absent

The preceding attended deploy had reached REDmod Stage 3 / TweakDB compilation and failed with Win32 error `0x3` while moving a generated temporary file to `r6/cache/modded/tweakdb_ep1.bin`. The earlier W08 parser failure did not recur.

## What is and is not proven

1. **Does `r6/cache/modded` currently exist after the failed redeploy?** No. This is directly observed.

2. **Did the successful no-mod refresh remove it, or merely leave a normal no-mod state absent?** Not distinguishable from the surviving evidence. The player uninstaller does not directly own or recursively delete `r6/cache/modded`; it invokes official REDmod refresh. The earlier hard-uninstall report recorded `mods.json` absent but did not record whether the parent directory existed. Historical causation is therefore intentionally left unclaimed.

3. **Does official REDmod 2.31 expect the directory to exist before a deploy that emits TweakDB output?** On the exact observed 2.31 path, operationally yes: REDmod reached TweakDB compilation and attempted to move the generated output into `r6/cache/modded/tweakdb_ep1.bin`, but failed with path-not-found while the parent was absent. This establishes the required precondition for this deploy path; it does not establish an undocumented general implementation guarantee for every REDmod version.

4. **Does REDlauncher or another official path normally create it before deploy?** Not proven. The exact installed `REDprelauncher.exe` was fingerprinted, but no source-level or runtime evidence establishes a launcher directory-creation step. CDPR's REDmod documentation states that REDlauncher can perform deployment and that REDmod rebuilds its cache after cache contents are cleared, but does not document who creates the parent directory.

5. **What failure is established?** The immediate failure is the missing `r6/cache/modded` destination parent. There is no direct evidence from this run for a deeper missing destination, permissions failure, or file lock. Secondary failures remain possible until the parent-owned retest succeeds, so this lane does not overclaim full deployment acceptance.

## CDPR documentation consulted

CDPR Modding Documentation records that `redmod deploy -root=<path>` stages installed mods and compiles tweak files into a modded TweakDB blob:

- https://github.com/CDPR-Modding-Documentation/Cyberpunk-Modding-Docs/blob/main/for-mod-creators/core-mods-explained/redmod/commands/deploy.md

The REDmod usage/troubleshooting documentation says REDmod rebuilds its cache after the cache contents are cleared and identifies REDlauncher as an official deployment path:

- https://github.com/CDPR-Modding-Documentation/Cyberpunk-Modding-Docs/blob/main/for-mod-users/users-modding-cyberpunk-2077/redmod/usage.md

Those docs support the deploy/cache role but do not prove launcher internals or historical deletion causation.

## Smallest repair selected

The repair belongs in `tools/Deploy-BiologyRedmod.ps1`, immediately before the official `redMod.exe deploy` invocation, after:

- explicit game-root validation;
- game-stopped validation;
- installed `mods/Biology/info.json` validation; and
- exact REDmod `2.3.1.0` / product `2.31` validation.

At that boundary the helper:

- resolves only `<game>/r6/cache/modded` through the repository safe-child helper;
- fails closed if that path is occupied by a file;
- creates the directory only when absent, using idempotent directory creation;
- never deletes, clears, replaces, or enumerates existing cache contents;
- never creates/copies `tweakdb_ep1.bin`, `mods.json`, or any other generated REDmod file; and
- still delegates all actual deployment and generated output production to official `redMod.exe`.

This is safer than moving the behavior into the player uninstaller because deploy preparation is needed exactly when an actual REDmod deployment is about to emit output. It also avoids imposing an artificial cache-root lifetime requirement on the valid zero-mod uninstall state.

## Other-REDmod safety

The repair is additive only. If `r6/cache/modded` already exists—whether empty or containing output for one or many other REDmods—the helper leaves the directory and every child untouched. Existing player-uninstaller behavior for zero versus multiple remaining REDmods is unchanged.

## Acceptance boundary

This evidence selects and structurally validates the repair. It does **not** constitute official REDmod 2.31 deploy acceptance for the repaired worker. P01.1 owns the next official deploy retest from the controlled installed-game state.
