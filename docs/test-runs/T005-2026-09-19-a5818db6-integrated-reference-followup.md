# T005 — integrated Biology detail, E3 presentation, and body persistence acceptance

Date: 2026-09-19 (owner local)  
Test ID: **T005**  
Test mode: MILESTONE CLEAN-ROOM  
Cyberpunk version: 2.31  
Canonical source: `a5818db6596e335824d75f596fc8204cc419de4f`  
Predecessor: **T004**  
Gameplay disposition: **PARTIAL / follow-up required**  
Operational attended-session result: **PASS**

GitHub tracking: issue #132.

## Integrated work

- W17.1 / PR #110 — current-2.31 Ripperdoc archaeology retired the old virtual-grid host and mounted Biology beside the authored `cyberwareContainer` under native Inventory/RipperdocInventoryController authority.
- W18.1 / PR #111 — direct Project E3 source/archive archaeology plus current-native quest/hotkey/weapon/nameplate presentation work.
- Existing authoritative body runtime and persistence implementation remained on main for #41 acceptance.
- Reference-mod archaeology process #105 was complete before launch.

Combined-main CI before test:
- Biology CI run #2058 / `35477885334`
- conclusion: **PASS**

## Exact candidate / evidence

Managed build ID:
`biology-integrated-20260920-002342-a5818db6596e`

Candidate artifact:
`biology-integrated-20260920-002342-a5818db6596e.zip`

Candidate artifact SHA-256:
`67EEBA35FE6A813C2F26FDC23A7D60FAFCF2679B1FA70834A055158F281FC6B5`

Returned bundle:
`Biology-Operator-Evidence-attended-a5818db6596e-20260919-192331-458e64ed.zip`

Bundle SHA-256:
`4775275579850361C34BD2D57419AA12D00599B7B493F9A756E4C57BB1DA1C55`

Evidence ID:
`attended-a5818db6596e-20260919-192331-458e64ed`

Preparation mode:
`ManagedPostTransition`

## Operational/session acceptance

**PASS.**

Listener:
- classification: `STARTED-AND-EXITED`
- basis: `direct-process-polling`
- READY: `2026-09-20T00:24:06.3021333Z`
- process start: `2026-09-20T00:24:47.0904270Z`
- process exit: `2026-09-20T00:35:12.7390328Z`
- observed duration: **625.649 s**
- evidence finalized: `2026-09-20T00:35:17.1578692Z`

Startup evidence:
- configured REDscript output advanced after READY;
- REDscript current log advanced after READY;
- two fresh runtime-adjacent logs;
- current REDscript compilation completed successfully;
- no crash artifacts;
- no matching Windows Application crash/hang events.

The managed evidence result is `PASS`, but its proof boundary does not decide gameplay/UI acceptance.

## Screenshot bindings

Biology / metabolism-state capture:
- SHA-256 `6553342E980D1CD6FE00E77806EB4372A14D22A6B0462D3CBC967AD3EE03C948`

Ordinary gameplay / E3 nameplate:
- SHA-256 `DB9F5CFD0E8B789083F9D13544FFA6DDD6C6F85D81E103390B3E1085E17BB284`

Biology Back-transition stock-grid flash:
- SHA-256 `2856A4097D4B5E42D74738E024BA7782F0407834FD0D8C22DC4B85E40A48C054`

Scanner / police identity mismatch:
- SHA-256 `213EA928F2A262B2D0D6B75B2F00CA4B291B34B5B9BEE417F3C7B6ECA21E9379`

## Material progress / KEEP

### Biology runtime and visible content are present

The old `BODY RUNTIME SYSTEM MISSING` failure is not present. Biology visibly reports `BODY STABLE`, and the returned Biology capture shows populated runtime-facing values rather than a blank shell.

This does **not** close #41: persistence and combat injury integration still require live acceptance.

### E3 presentation is materially more present

The ordinary gameplay capture shows substantially more red/minimal E3 treatment than earlier T001-T004 captures, including a visibly transformed quest/objective region and broader HUD participation.

Do not treat the remaining nameplate findings as evidence that the whole E3 lane failed.

### Modern scanner presentation remains current/native

The scanner capture remains the modern CP2077 scanner/quickhack presentation rather than a recreated old E3 scanner. Preserve this.

## Findings

### T005-F01 — Biology Back transition leaks stock Cyberware content

**FAIL / W19.1 / #133.**

When backing out of a Biology drill-down, the stock Cyberware slots/grid briefly becomes visible before Biology overview restoration completes. The captured transient frame still shows selected LEGS anatomy while the stock slot/grid surface is visible.

This is a transition/lifecycle ordering failure, not a return to the old W02 virtual-grid host.

Current source has a strong lead: the Biology `DollHover(Invalid)` closing path restores `cyberwareContainer` visibility via `CRSetBiologyDetailSurface(false)` before calling `DisplayInventory(false)`. W19.1 must independently verify the native 2.31 lifecycle and make the transition visually atomic without timers.

### T005-F02 — E3 nameplate frame remains detached from the actual name

**FAIL / W20.1 / #134.**

Ambient identity text is live, but the Biology-owned segmented frame is visibly above/detached from `NC RESIDENT`.

The current implementation uses a fixed 340x46 runtime-created canvas centered on the controller root. W18.1 already established that structural E3 fidelity depends on authored INK/resource geometry; this finding is the anticipated authored-resource follow-up, not an invitation to add another screenshot-derived offset.

### T005-F03 — police scan identity enrichment flows in the wrong direction

**FAIL / W20.1 / #134.**

Owner observation:
1. police initially present ambient as generic `NC RESIDENT`;
2. scanner initially reveals a more specific police identity;
3. after scanner release/recheck, projected/scanner name regresses toward `NC RESIDENT` instead of discovered identity enriching the ambient nameplate;
4. ordinary civilian scan/enrichment behaves correctly.

The captured scanner frame shows native scan-results classification `BEAT COP` while the projected central name reads `NC RESIDENT`.

Current Biology code writes an ambient fallback into otherwise-empty `NPCNextToTheCrosshair.name` before native `SetVisualData`. W20.1 must determine whether this presentation fallback is contaminating police scanner/name authority. Native discovered identity must flow toward ambient presentation, never backward.

### T005-F04 — live player Health loss does not produce visible Biology injury change

**FAIL / W21.1 / #135.**

The owner deliberately entered combat with police and took live damage. Native Health decreased normally, but Biology showed no corresponding injury/body metric change.

The body runtime is present and the exact candidate compiled/started successfully, so this does not reopen the old missing-runtime/startup failure.

W21.1 must first prove that the exact package path staged the combat-enabled `CRCombatRuntimePolicy.BuildEnabled` copy, then trace:

`DamageSystem.ProcessOneShotProtection -> CRNativeWoundBridge.Prepare -> native resource loss -> SendDamageEvents -> CRNativeWoundBridge.Commit -> CRBodyRuntime.RecordInjury -> CRBodyInputs.Drain -> presentation`

and identify the first boundary that can coexist with visible native Health loss while Biology injury state remains unchanged.

## Acceptance not completed / not inferred

T005 does **not** close #41.

The required full continuity sequence was not accepted as a PASS:
- menu close/reopen;
- WAIT producing/continuing authoritative state;
- save/reload persistence;
- SLEEP continuing the same body state.

These remain for T006 after the T005 runtime/combat failure is repaired.

Likewise, any checklist item not directly visible or explicitly reported remains unexercised rather than silently PASS.

## Routing

| Finding / result | Route | State after T005 |
|---|---|---|
| T005-F01 Back transition stock-grid flash | W19.1 / #133 / #39 | repair required |
| T005-F02 nameplate frame alignment | W20.1 / #134 / #40 | authored/native structure repair required |
| T005-F03 police scan identity regression | W20.1 / #134 / #40 | native knowledge direction repair required |
| T005-F04 combat damage not reflected in Biology | W21.1 / #135 / #41 | native hit/wound routing diagnosis required |
| body runtime availability | #41 | materially live; KEEP |
| E3 broader presentation | #40 | materially improved; KEEP |
| modern scanner presentation | #40 | PASS / KEEP |
| listener/session/startup | release path | PASS / KEEP |
| WAIT/save-reload/SLEEP continuity | #41 | still unaccepted |

## Next boundary

**T006 is unallocated and blocked** until W19.1, W20.1, and W21.1 return READY-PARENT and are integrated.

T006 should be a focused integrated acceptance of:
- atomic Biology detail/Back/Cyberware transitions;
- authored/aligned E3 nameplate + correct police identity enrichment;
- live player hit -> Biology injury state;
- then the remaining WAIT -> save/reload -> SLEEP body continuity sequence.
