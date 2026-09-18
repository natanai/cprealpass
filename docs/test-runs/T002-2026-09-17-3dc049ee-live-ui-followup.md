# T002 — integrated Biology detail, E3, persistence, and listener validation

Date: 2026-09-17 (owner local)  
Test ID: **T002**  
Test mode: ITERATION  
Cyberpunk version: 2.31  
Canonical source: `3dc049ee99979f924978b671ddbbbda06b472d1b`  
Predecessor: **T001**  
Gameplay disposition: **PARTIAL / follow-up required**  
Operational attended-session result: **PASS**

GitHub tracking: issue #92.

## Integrated work

- W02.3 / PR #87 — Biology detail layout follow-up.
- W15.5 / PR #88 — attended listener observation repair.
- W04.2 / PR #90 — body-runtime persistence/authority source audit.
- W03.3 / PR #89 — E3 live presentation/nameplate follow-up.

## Exact candidate / evidence

Managed build ID: `biology-integrated-20260918-042202-3dc049ee9997`  
Candidate artifact SHA-256: `8010C69762EA8B7D2D7E727B7E09B23CE2EE5FC0B4110EF1D4158A85D7269077`

Returned bundle:

`Biology-Operator-Evidence-attended-3dc049ee9997-20260917-232157-96269e56.zip`

Bundle SHA-256:

`8EFFF72271272DA1773F2E62638D53C3BA4784002C04959B77F5E90D11F4E5FD`

Evidence ID:

`attended-3dc049ee9997-20260917-232157-96269e56`

The managed evidence records schema-2 exact-source candidate identity and Cyberpunk/REDmod 2.31.

## Operational/session acceptance

**PASS.**

The W15.5 listener repair worked directly:

- READY: `2026-09-18T04:22:20.8331670Z`
- process START observed: PID 18256 at `04:23:03.3369960Z`
- process EXIT observed: `04:25:38.0246199Z`
- observed duration: **154.688 seconds**
- classification: `STARTED-AND-EXITED`
- classification basis: `direct-process-polling`

Bounded startup evidence independently reported startup as proven, with configured REDscript output advancement, current REDscript log advancement, and fresh runtime-log signals. REDscript compilation completed with no execution errors.

This directly accepts the T001 listener-defect repair. It does **not** imply gameplay/UI acceptance.

## Screenshot bindings

Gameplay / nameplate / E3 capture:
- SHA-256 `24027AA9ED6BEE2C2DC7C2D165268CF3EF36F6685B91F0118C4D1FE644C2DFDA`
- 2048x1151

Biology layout capture:
- SHA-256 `ABB0094EFD8AF4E6D603796C668200D5877EFA35A772AE6F26BDE6FCE8AC44D7`
- 2048x1151

Binary screenshots are not required in Git for this record; the hashes bind the returned captures.

## Findings

### T002-F01 — Biology telemetry remains wrongly composed

**FAIL / issue #39.**

The owner reports that Biology's numerical stats are now even farther toward the extreme top-left. The returned Biology capture visibly shows the `MUSCULOSKELETAL` telemetry block pressed/clipped against the upper-left edge while the native anatomy composition remains centered/right.

This is a placement/composition failure, not evidence that runtime-backed detail data disappeared.

Route: next W02 sequential follow-up. Preserve live selected-system/runtime data; repair the native content-region composition.

### T002-F02 — E3 hooks now have visible effect, but overall HUD acceptance still fails

**PARTIAL / issue #40.**

The owner reports they still do not see a definite/coherent overall E3 HUD transformation. The gameplay screenshot does show visible Biology/E3 red treatment on multiple HUD surfaces, so the lane is no longer "no material visual effect"; however the result still needs substantial design care and does not satisfy the "unmistakably E3-inspired" acceptance.

Route: next W03 sequential follow-up.

### T002-F03 — ambient NPC nameplate lifecycle is now live

**MATERIAL PASS / KEEP / issue #40.**

The ordinary gameplay capture visibly shows the ambient name `FEDOT VASILYEV`. This is direct evidence that W03.3 crossed the prior missing-nameplate boundary. The owner notes that the nameplate is not yet the full intended E3 design.

Preserve the now-working ordinary-focus nameplate lifecycle while refining presentation.

### T002-F04 — reticle-adjacent red artifact persists

**FAIL / issue #40.**

The strange red bracket/box near the reticle is still visible in the gameplay capture. The W03.3 hypothesis that removing the previous custom projected nameplate canvas would eliminate the artifact was insufficient.

Next presentation work must identify the actual live widget/hook owner rather than adding another speculative overlay.

## Acceptance not exercised

The returned live session was about 2.5 minutes and the owner did not report the complete W04.2 acceptance sequence:

- capture dynamic body values;
- menu close/reopen continuity;
- material WAIT progression;
- save at changed state;
- reload;
- SLEEP progression.

Therefore **do not infer T002-A06..A12** from the source audit or this session. Issue #41 remains open for a future numbered attended acceptance. This is pending evidence, not a new runtime defect.

Likewise, any T002 checklist item not directly reported or visible in returned evidence remains **not exercised**, not silently PASS.

## Routing

| Finding | Route | State after T002 |
|---|---|---|
| T002-F01 Biology telemetry top-left | issue #39 / W02 next sequential assignment | implementation follow-up required |
| T002-F02 E3 overall presentation insufficient | issue #40 / W03 next sequential assignment | implementation follow-up required |
| T002-F03 ambient names now live | issue #40 / W03 | KEEP working lifecycle |
| T002-F04 reticle red box persists | issue #40 / W03 | investigate actual live owner |
| W15.5 listener | issue #86 | attended accepted |
| W04.2 persistence | issue #41 | live acceptance still pending |

## Lessons

- Distinguish operational session PASS from gameplay/UI acceptance.
- When a live hypothesis is disproven (reticle artifact survived removal of suspected widget), the next worker must diagnose the actual owner from evidence rather than stacking another guess.
- A partial presentation breakthrough should be preserved: ambient nameplates are now a proven working seam even though their design is unfinished.
- Do not close a source-audit issue merely because static provenance is convincing when its stated acceptance still requires live wait/save-reload/sleep behavior.

## Next boundary

T003 is unallocated. Parent should first integrate the next W02 and W03 follow-ups, then decide whether to combine their visual retest with the still-pending #41 persistence sequence or keep the persistence acceptance focused enough to avoid another under-exercised session.
