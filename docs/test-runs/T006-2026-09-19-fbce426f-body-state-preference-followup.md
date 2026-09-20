# T006 — Biology transition, body-state authority, and E3 preference follow-up

Date: 2026-09-19 (owner local)  
Test ID: **T006**  
Test mode: MILESTONE CLEAN-ROOM  
Cyberpunk version: 2.31  
Canonical source: `fbce426fc3305f67f29ec083bfe8c9f644c2572d`  
Predecessor: **T005**  
Gameplay disposition: **PARTIAL / follow-up required**  
Operational attended-session result: **PASS**

GitHub tracking: issue #140.

## Integrated work

- W19.1 / PR #138 — Biology keeps stock `cyberwareContainer` suppressed through Biology-mode detail/Back lifecycle and restores it when Cyberware regains ownership.
- W20.1 / PR #137 — nameplate structure moved back to native authored frame/text; Biology stopped writing generic ambient fallback into native scanner/name data.
- W21.1 / PR #139 — player hits with otherwise-valid unmapped protection no longer fail readiness solely because of missing Biology protection profiles; injury commit remains bounded by native physical Health loss.
- W22.1 / PR #142 — attended prior-candidate replacement moved from a generated Temp EXE to the existing PowerShell execution path so Windows Application Control does not block candidate replacement.

Combined-main CI before resumed T006:
- Biology CI run #2134 / `35483248280`
- conclusion: **PASS**

## Exact candidate / evidence

Evidence ID:
`attended-fbce426fc330-20260919-213403-2b48215e`

Returned bundle:
`Biology-Operator-Evidence-attended-fbce426fc330-20260919-213403-2b48215e.zip`

Bundle SHA-256:
`AB6D135F2E86D87818BACA38868ECD5FD63C8159F6768979424DE00C004EE76C`

Installed candidate source revision:
`fbce426fc3305f67f29ec083bfe8c9f644c2572d`

Managed build ID:
`biology-integrated-20260920-023413-fbce426fc330`

Preparation mode:
`ManagedPostTransition`

## Operational/session acceptance

**PASS.**

Preparation:
- result: PASS;
- prior schema-2 candidate replacement succeeded through the W22 PowerShell path;
- installed ownership receipt matched exact source;
- exact CP2077 2.31 candidate built and installed.

Listener:
- classification: `STARTED-AND-EXITED`;
- basis: `direct-process-polling`;
- READY: `2026-09-20T02:34:36.4115907Z`;
- process start: `2026-09-20T02:40:48.5269838Z`;
- process exit: `2026-09-20T02:46:40.6990004Z`;
- observed duration: **352.172 s**.

Startup evidence:
- configured REDscript output advanced after READY;
- current REDscript log advanced;
- integrated Biology sources compiled successfully;
- two fresh runtime-adjacent logs;
- no crash artifacts;
- no matching Windows Application crash/hang events.

The managed evidence result is `PASS`, but the proof boundary does not decide gameplay/UI acceptance.

## Screenshot bindings

Clipped Biology E3 preference:
- SHA-256 `29C40BFDAEBA7D4EEAEB251EFBDE303ACADA5FFCE45869ABA971129B62BF1918`

LEGS detail / inert stats:
- SHA-256 `F0CBDCC21B039E7CC02F9F01337A30C7473E9DC388572C33620C15CDF8D54C46`

## Material progress / KEEP

### Biology detail -> Back transition

**PASS / KEEP.**

Owner report:
> "the grid no longer flashes. the drilling in and out system appears to be working flawlessly."

The T005 stock Cyberware slot/grid one-frame leak is no longer observed. Do not reopen W19.1's transition/host problem without new direct evidence.

This materially validates:
- authored Biology content host remains viable;
- Back lifecycle ordering is now visually atomic;
- repeated drill-down/Back no longer leaks stock Cyberware content.

## Findings

### T006-F01 — Biology authoritative stats remain inert

**FAIL / W21.2 / #143 / #41.**

Owner report:
> "the entire stats side of the biology system seems completely inert. everything just stays static at 100 percent."

The captured LEGS detail displays:
- `L NO CONDITION | R NO CONDITION`;
- LEFT LEG FUNCTION 100%;
- RIGHT LEG FUNCTION 100%;
- LEFT BONE INTEGRITY 100%;
- RIGHT BONE INTEGRITY 100%.

This occurs after W21.1 repaired the first T005 combat-profile readiness veto, so the remaining problem must be diagnosed at the next authority boundary rather than reverting that evidence.

W21.2 must distinguish:
- body runtime clock/tick progression not advancing;
- combat injury still failing downstream of readiness;
- injury/body state advancing but detail projection not observing it;
- normal needs progression merely remaining below integer display thresholds during this short session;
- multiple broken boundaries.

The source projection reads from `CRBodyRuntime.Get().GetBodySnapshot()` / `GetMeters()`, so the repair must preserve the single authoritative body state rather than creating UI-local values or polling native Health as a substitute.

### T006-F02 — Biology E3 HUD preference is clipped/unusable

**FAIL / W20.2 / #144 / #40.**

The Biology screen still renders a tiny clipped `E3 HUD` fragment at the extreme top-right edge.

Current source in `BiologyPreferencesNative.reds` creates a free-floating interactive `inkText`, reparents it directly to the `RipperDocGameController` root, anchors TopRight, and applies fixed margins.

On the live 2.31 screen this is not a usable preference control.

W20.2 must keep the save-backed `CRRealpassSettings` preference but mount it in a stable Biology-owned/native content region with a usable hit target and no external settings dependency.

## Acceptance not completed / not inferred

T006 does **not** close #41.

Because the underlying state remained visibly inert, the intended persistence sequence could not provide meaningful acceptance of:
- live injury -> authoritative Biology change;
- close/reopen retention;
- WAIT progression;
- save/reload persistence;
- SLEEP continuation.

Likewise, T006 did not provide enough owner evidence to declare the full police/civilian nameplate identity sequence accepted. Those existing #40 checks remain open unless independently accepted by a later run.

## Routing

| Finding / result | Route | State after T006 |
|---|---|---|
| Biology detail/Back stock-grid flash | W19.1 / #39 | **PASS / KEEP** |
| Biology state/stat progression inert | W21.2 / #143 / #41 | diagnosis + repair required |
| Biology E3 HUD preference clipped/unusable | W20.2 / #144 / #40 | layout/interaction repair required |
| W22 prior-candidate Application Control boundary | #141 | **PASS / KEEP** |
| listener/session/startup | release path | **PASS / KEEP** |
| WAIT/save-reload/SLEEP continuity | #41 | still unaccepted |
| full police/civilian identity acceptance | #40 | still unaccepted |

## Next boundary

**T007 is unallocated and blocked** until W21.2 and W20.2 return READY-PARENT and are integrated.

T007 should prioritize:
- proving that authoritative Biology body state actually changes under meaningful body/combat/time inputs;
- then use a real changed state to complete close/reopen -> WAIT -> save/reload -> SLEEP continuity;
- validating the moved E3 preference as genuinely usable;
- carrying forward any remaining #40 police/civilian identity acceptance that was not completed in T006.
