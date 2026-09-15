# Biology REDmod package/dependency foundation — completed foundation record

Issue: #28  
Original lane: `agent/redmod-foundation`  
Original canonical start: `6fab5ba706e2a10387bb8629cccdb0868533bb97`  
Target game: Cyberpunk 2077 2.31

## Current status

This document records the **completed foundation phase** from merged PR #31. It is no longer the canonical build/install/test route.

After PRs #31, #32 and #33 were merged, the parent orchestrator created the integrated assembly follow-up from canonical main:

`bfd6f7469139c64f0b9185724619a37e4ced5eca`

The active package/dependency contract is now:

- `docs/REDMOD-INTEGRATED-ASSEMBLY.md`
- `manifest/redmod-package.json`
- `manifest/redmod-install-contract.json`
- `manifest/dependency-graph.json`
- `manifest/redmod-classification.json`
- `tools/Build-BiologyPackage.ps1`
- `tools/Deploy-BiologyRedmod.ps1`
- `tools/Reset-BiologyIteration.ps1`

The old `Build-RedmodFoundation.ps1` output was deliberately **non-playable**. Do not hand it to a player or use it for the integrated milestone merely because it still exists in source/history.

## What the foundation established

Merged PR #31 established rules that remain authoritative:

1. the official first-party REDmod identity is `mods/Biology`;
2. REDmod is package/deployment authority, not a requirement to rewrite every runtime seam as a whole-file REDmod script replacement;
3. narrow Biology-owned additive/wrapper seams may remain REDscript when that route is smaller and more patch-resilient;
4. every supplemental dependency needs a concrete current consumer;
5. Dark Future and Project E3 may be reference/provenance material only and may never execute in Biology;
6. installed files require exact ownership, hashes and safe uninstall semantics;
7. shared framework/game roots are never recursively Biology-owned;
8. structural package/dependency changes require milestone clean-room attended acceptance;
9. direct-game behavior gates stay open until observed rather than being inferred from CI or upstream documentation.

## Direct REDmod 2.31 evidence from the foundation phase

The supported local read-only probe recorded:

```text
tools/redmod/bin/redMod.exe
file version 2.3.1.0
product version 2.31
```

It confirmed the `deploy` module and global `-root` parameter. It also showed that relying on REDmod's default-root heuristic can resolve incorrectly when invoked outside the game root.

Biology tooling therefore always passes:

```text
-root=<Cyberpunk 2077>
```

Evidence: `docs/evidence/REDMOD-2.31-PROBE-2026-09-15.md`.

The probe did **not** establish Biology package recognition, launcher enablement, relaunch persistence, clean uninstall, or conflict precedence. Those remain direct-game gates in the integrated assembly.

## REDmod-first does not mean REDmod-only

Official REDmod script modding replaces vanilla-path `.script` files. The merged Biology runtime instead uses project-owned REDscript classes plus narrow annotations such as `@wrapMethod`, `@addMethod`, `@replaceMethod`, and `@addField`.

For these current seams, copying whole vanilla `.script` files would cause Biology to own much more upstream implementation than the feature requires. That broadens patch/conflict surface. The foundation therefore classified the current runtime/hook family `REDSCRIPT-BETTER`; the integrated assembly retains that conclusion and exact-compiles the complete merged source against Cyberpunk 2077 2.31 before artifact emission.

## Dependency conclusion after integration

The foundation originally marked Mod Settings / ArchiveXL / RED4ext as removal candidates pending the presentation/settings lane. The integrated follow-up has re-audited that assumption against merged PR #33.

| Component | Integrated status | Why |
| --- | --- | --- |
| REDmod | required platform | official package/deployment authority; game-provided, never bundled |
| redscript | required current runtime / `REDSCRIPT-BETTER` | direct consumer: complete merged Biology additive/wrapper runtime |
| Mod Settings | temporary retained blocker / `REMOVE/RETHINK` | PR #33 made semantics provider-neutral but did not implement another accessible persistent provider for the two public booleans |
| ArchiveXL | temporary transitive / `REMOVE/RETHINK` | no direct Biology consumer; current Mod Settings dependency only |
| RED4ext | temporary transitive / `REMOVE/RETHINK` | no Biology-owned native plugin; current settings-chain plumbing only |
| TweakXL | not required | no current consumer |
| Codeware | not required | no current consumer |
| Input Loader | not required | no current consumer |
| Dark Future | blocked | reference/provenance only |
| Project E3 runtime | blocked | presentation is Biology-owned after PR #33 |

Retaining the settings chain in this candidate does not grant it permanent architectural status. The exact removal blocker is routed back to Lane C in `REDMOD-INTEGRATED-ASSEMBLY.md`.

## Foundation artifact vs integrated artifact

### Historical foundation skeleton

`Build-RedmodFoundation.ps1` established:

- `mods/Biology/info.json`;
- ownership/provenance/checksum machinery;
- no gameplay runtime;
- no claim of playability.

### Current integrated candidate

`Build-BiologyPackage.ps1` now assembles:

- official `mods/Biology` identity;
- complete merged Biology-owned REDscript runtime;
- exact retained generic runtime files/notices;
- exact owner/component/route/replace-policy/SHA-256 metadata;
- provenance/version/checksums;
- game-root-shaped ZIP;
- mandatory integrated exact compile before ZIP emission.

The current route is documented in `REDMOD-INTEGRATED-ASSEMBLY.md` and `CLEAN-ROOM-TESTING.md`.

## PKG-06 transition rule

The old pre-REDmod clean-room package path is **not deleted merely because the integrated REDmod-first architecture exists**.

PKG-06 closes only after the new route has actually:

- exact-compiled the integrated source;
- produced the release-shaped artifact reproducibly;
- deployed successfully through official REDmod;
- demonstrated equal or better functional/reproducibility behavior in direct testing.

Until then, the old working route remains a rollback/reference path and must not be confused with the canonical integrated handoff.

## Remaining direct-game gates

The integrated follow-up intentionally leaves these open:

- Biology REDmod recognition/deployment;
- enable/disable behavior;
- normal relaunch persistence;
- clean uninstall/reset against the recorded vanilla baseline;
- PKG-05 harmless reversible overlap/precedence fixture;
- combined Lane B/Lane C attended behavior requirements.

The parent integration thread coordinates the single MILESTONE CLEAN-ROOM attended test after the integrated follow-up is merged.

## Upstream REDmod references

- https://www.cyberpunk.net/en/modding-support
- https://cdn-l-cyberpunk.cdprojektred.com/REDmod-docs.pdf
- https://github.com/CDPR-Modding-Documentation/Cyberpunk-Modding-Docs/blob/main/for-mod-creators-theory/modding-tools/redmod/README.md
- https://github.com/CDPR-Modding-Documentation/Cyberpunk-Modding-Docs/blob/main/for-mod-creators-theory/modding-tools/redmod/script-modding.md

These establish the public REDmod contract. Direct supported-install behavior remains stronger evidence for local recognition, enablement, persistence and precedence questions.
