# Attended W08 REDmod deploy — post-uninstall output-path failure

Date: 2026-09-15  
Parent: P01.1  
Exact canonical source: `7e61724071b8c95ba5c334ab9e8d11c43381c94e`  
Cyberpunk 2077: 2.31  
REDmod product version: 2.31  
REDmod SHA-256: `144DF5A984669528CD957B40BB2126FE83B73D66BD0E041CA614C80F74E76A7F`

## Precondition

The immediately preceding player-facing `Uninstall Biology.exe` attended test completed successfully. Official REDmod no-mod refresh reported success, and the canonical read-only verifier reported no Biology-specific package/runtime residue. Generic shared framework dependencies were intentionally preserved.

The canonical W08 deploy bootstrap then re-verified the clean Biology-specific state before installing the new candidate.

## Exact artifact

- ZIP: `biology-integrated-20260915-235306-7e61724071b8.zip`
- SHA-256: `16AF26B935267ACDDC8D8D398F2447BE09D84ED6B6946A381A5D33214162623E`
- bytes: `3237528`
- installed buildId: `biology-integrated-20260915-235306-7e61724071b8`
- installed sourceRevision: `7e61724071b8c95ba5c334ab9e8d11c43381c94e`

## Build result

PASS:
- dependency verification
- 119 owned-runtime policy checks
- 61-source project REDscript exact compile
- 66-source deployable runtime exact compile / 104 files
- self-contained `Uninstall Biology.exe`
- 117-file artifact policy

## Official REDmod result

REDmod recognized Biology and reached Stage 3/5:

```text
[DEPLOY] Stage 1/5 - Initialization
Found mod "Biology" (v0.1.0) in folder "Biology" (enabled; not deployed; TWEAKS; )
Needs deployment: true
[DEPLOY] Stage 2/5 - Script Compilation
[DEPLOY] Stage 3/5 - TweakDB Compilation
Core: [IO]: Low level delete file failed: file='...\r6\cache\modded\tweakdb_ep1.bin', error code=0x3
Core: [IO]: Low level move file failed: 0x3

Commandlet deploy has failed.

could not move file from '<temp>.tmp' to '...\r6\cache\modded\tweakdb_ep1.bin'
Tweak compiler errors:
ERROR: TweakDB compilation has failed!
```

## Interpretation boundary

This is **not** the prior W08 standalone tweak parser failure. The repaired `package Items` source did not produce `Expected end of file but got: 'using'`; REDmod progressed to the output-write phase of TweakDB compilation.

The new failure is a post-hard-uninstall REDmod output/cache-state failure. The current hypothesis is that `r6/cache/modded` was absent after the successful no-mod refresh and REDmod 2.31 did not recreate the destination before moving the compiled TweakDB output. That path-state hypothesis is not yet treated as proven.

## Routing

- W08.1 / issue #55: narrow tweak-grammar failure accepted as fixed and closed.
- New issue #59 / W09.1: official REDmod post-uninstall deploy recovery.
- Issue #44 remains open: hard removal itself passed, but reliable uninstall -> reinstall -> redeploy remains part of the player-facing contract.

Do not use this run as live gameplay acceptance. REDmod deployment did not complete and the game was not launched.
