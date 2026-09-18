# T003 — Biology native detail placement and E3 visual acceptance

Date: 2026-09-18 (owner local)  
Test ID: **T003**  
Test mode: ITERATION  
Cyberpunk version: 2.31  
Canonical source: `67593bfbb12b4a6ebcec7042066d48b4f5fac427`  
Predecessor: **T002**  
Gameplay disposition: **PARTIAL / follow-up required**  
Operational attended-session result: **PASS**

GitHub tracking: issue #95.

## Integrated work

- W03.4 / PR #94 — E3 visual completion and reticle-artifact removal.
- W02.4 / PR #93 — Biology detail mounted beside native `m_virtualGridContainer` under its authored parent.
- Prior release/session/listener work already on canonical main.

## Exact candidate / evidence

Managed build ID: `biology-integrated-20260918-142252-67593bfbb12b`  
Candidate artifact SHA-256: `FDC22CB07A832EEAFBE9A254408F715A0F36C37C68B1FB7E56A133AA520BC025`

Returned bundle:

`Biology-Operator-Evidence-attended-67593bfbb12b-20260918-092246-0d4c2ea4.zip`

Bundle SHA-256:

`14DD5F5AA7ACC9FCD5D2B556079699A9FE23CC3FE878777D286232E5EE0DE2CC`

Evidence ID:

`attended-67593bfbb12b-20260918-092246-0d4c2ea4`

## Operational/session acceptance

**PASS.**

- READY: `2026-09-18T14:23:14.4381406Z`
- process START observed: PID 9140 at `14:24:16.3277712Z`
- process EXIT observed: `14:26:43.3315712Z`
- observed duration: **147.004 seconds**
- classification: `STARTED-AND-EXITED`
- classification basis: `direct-process-polling`

Bounded startup evidence independently reported startup as proven via configured REDscript output advancement, current REDscript log advancement, and fresh runtime logs. REDscript compilation completed successfully.

This is operational/session evidence only; gameplay acceptance follows the screenshots and owner observations below.

## Screenshot bindings

Biology ARMS drill-down:
- SHA-256 `9EB1C56B3BA9B52CC445CB9F223CA0070BA59D57B1E75F581CDB49FB627D28B5`

Gameplay / E3:
- SHA-256 `46A6600A0C46B21606D80A051B458C398E360CAEF32B02CEC5497707BBB509ED`

Biology overview:
- SHA-256 `F8F2F8A6600BBD994F5264380EA5A6595379B4D6D7EEB73F12105D9C7AFD5E29`

## Findings

### T003-F01 — Biology detail presentation disappears entirely

**FAIL / issue #96 / parent issue #39.**

The selected ARMS anatomy drill-down itself works: the native arm presentation is enlarged, the ARMS selector is active, and Back is available. But the screenshot contains no Biology detail title, summary, or numerical telemetry anywhere.

This is a new presentation regression relative to T002. W02.4 intentionally fails closed when native-region geometry cannot be resolved; T003 is consistent with that path hiding the panel, but the exact failing boundary must be proven rather than guessed.

Next W02 work must instrument and prove:
- native virtual-grid resolution;
- direct-parent traversal;
- reparent success;
- copied geometry values;
- detail-time remount result;
- whether the panel is hidden by the fail-closed gate versus mounted but clipped/zero-sized/hidden later.

Do not infer a body-runtime failure from invisible UI alone.

### T003-F02 — old reticle-corner artifact appears repaired

**MATERIAL PASS / KEEP / issue #97 / parent issue #40.**

The previous two-corner red box around the reticle is absent in the returned gameplay capture. Preserve W03.4's removal of `CRBiologyE3FocusFrame`; do not reintroduce replacement reticle geometry.

### T003-F03 — ambient nameplate lifecycle and compact framing remain live

**MATERIAL PASS / KEEP / issue #97.**

The gameplay capture shows ordinary-focus `NC RESIDENT` identity with a segmented red frame. This preserves the W03.3 lifecycle improvement and proves W03.4's compact nameplate framing is materially visible.

### T003-F04 — weapon/ammo chrome is attached to the wrong visual region

**FAIL / issue #97.**

The compact red `WEAPON // AMMO` label/frame is visibly detached from the actual lower-right weapon/ammo HUD and floats nearer the lower center of the screen. The native ammo/weapon presentation remains at lower right.

This directly proves that controller-root attachment is not sufficient to establish the authored visual coordinate space for this surface.

Next W03 work must bind chrome to the actual current 2.31 native weapon/ammo content region or copy geometry only inside the correct native parent hierarchy. Do not repair with a guessed global offset.

### T003-F05 — right-hand quest tracker still does not visibly participate

**FAIL / issue #97.**

The right-side `FOOL ON THE HILL` objective stack remains essentially current/native in the screenshot; the intended W03.4 quest chrome is not visibly composed around that stack.

Treat this as another root-vs-content-region problem until direct hierarchy evidence proves otherwise. Diagnose the actual visual child/parent used by the current quest tracker and bind Biology-owned presentation there while leaving native quest data/visibility authoritative.

## Acceptance not exercised / not inferred

T003 was deliberately focused on W02.4/W03.4 visual acceptance. It does not close issue #41 and does not claim the long WAIT -> save/reload -> SLEEP persistence sequence.

Any checklist item not directly visible or reported remains unexercised rather than silently PASS.

## Routing

| Finding | Route | State after T003 |
|---|---|---|
| T003-F01 Biology detail invisible | W02.5 / issue #96 | implementation follow-up required |
| T003-F02 old reticle artifact absent | W03.5 / issue #97 | KEEP |
| T003-F03 ambient framed nameplate live | W03.5 / issue #97 | KEEP |
| T003-F04 WEAPON // AMMO chrome detached | W03.5 / issue #97 | implementation follow-up required |
| T003-F05 quest tracker untreated | W03.5 / issue #97 | implementation follow-up required |
| listener/session | existing release path | PASS / preserve |
| body persistence | issue #41 | separate future attended acceptance |

## Lessons

- Fail-closed UI placement can turn a bad-location defect into an invisible-content defect; the next worker must expose bounded live geometry/mount state so parent evidence can distinguish these cases.
- A controller root is not automatically the authored visual content region. This hierarchy lesson now appears independently in Biology detail and E3 weapon/quest surfaces.
- Preserve proven partial wins while repairing geometry: ambient names, compact nameplate framing, and removal of the old reticle-corner artifact are now live KEEP behaviors.
- Do not use global screen offsets to compensate for local-coordinate-space mistakes.

## Next boundary

T004 remains unallocated. Parent should integrate W02.5 and W03.5 before another combined visual retest. Issue #41 persistence remains a separate attended boundary unless parent intentionally allocates a focused persistence session first.
