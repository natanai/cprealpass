# T004 — Biology detail visibility and native E3 content-region acceptance

Date: 2026-09-18 (owner local)  
Test ID: **T004**  
Test mode: ITERATION  
Cyberpunk version: 2.31  
Canonical source: `ffa6f64d6c837146d032aaab565d671c932453a2`  
Predecessor: **T003**  
Gameplay disposition: **PARTIAL / follow-up required**  
Operational attended-session result: **PASS**

GitHub tracking: issue #100.

## Integrated work

- W02.5 / PR #98 — retain/retry Biology detail subtree, preserve native grid layout while hidden, bounded mount-state breadcrumb.
- W03.5 / PR #99 — bind E3 quest/weapon chrome to semantic current-2.31 native content regions.
- Prior accepted listener/session, ambient nameplate, and reticle-artifact work remained on canonical main.

## Exact candidate / evidence

Managed build ID: `biology-integrated-20260918-185428-ffa6f64d6c83`  
Candidate artifact SHA-256: `FC1628406DB1B057ABEEEB1BFD85488C57847A3DE3B25B9D88080587812D52B5`

Returned bundle:

`Biology-Operator-Evidence-attended-ffa6f64d6c83-20260918-135422-a8b63136.zip`

Bundle SHA-256:

`3B400EE0EEF3F2E58926C6A1255279B8582C14361C2477E21DF12C554E9BA1FE`

Evidence ID:

`attended-ffa6f64d6c83-20260918-135422-a8b63136`

## Operational/session acceptance

**PASS.**

Listener classification:
- `STARTED-AND-EXITED`
- basis: `direct-process-polling`
- READY: `2026-09-18T18:54:48.9612139Z`

The managed listener observed two Cyberpunk launch/exit cycles during the same attended hold:
- PID 8436: START `18:55:11.8196601Z`, EXIT `19:09:45.1607363Z`, duration **873.341 s**
- PID 19544: START `19:13:48.8172429Z`, EXIT `19:17:03.8071318Z`, duration **194.99 s**

Bounded startup evidence independently proved startup via configured REDscript output advancement, current REDscript log advancement, and fresh runtime logs. No crash artifacts were reported.

The evidence bundle's own proof boundary explicitly does not decide gameplay/UI acceptance.

## Screenshot bindings

Ordinary gameplay / E3:
- SHA-256 `8B3A5E595979ECF64FE778D3AC7BFF8528E0D817CAB121B731BA061F44AF9ADF`

Biology ARMS detail with mount breadcrumb:
- SHA-256 `E6C1B5A9C2CD7322E7B5063ECE73E78BAE7729183D476BE981F0886BBDFC63A8`

Biology overview:
- SHA-256 `35A87B10BAFDC12B1BEF1BED250AE7DAA8F30230ADAFEFA497667DDC0758A85F`

Lower-left hotkey/quickslot crop:
- SHA-256 `D09DA3211BD22E9496F2CC320AC656593C037BB36C5AE3057921C6825B669418`

## Findings

### T004-F01 — Biology mount succeeds, but detail children remain invisible

**FAIL / next W02 follow-up.**

The ARMS drill-down remains correct and the selector explicitly displays:

`ARMS [BIOLOGY LAYOUT: MOUNTED]`

Yet no Biology detail title, summary, metric rows, or values are visible.

This materially narrows the defect. The W02.5 native-region resolver and reparent verification succeeded live. The remaining failure is **after mount success**: effective size/layout, clipping, visibility/opacity, child arrangement, z-order/covering, content population timing, or later native async mutation.

Do not reopen earlier mount-resolution hypotheses unless new direct evidence contradicts the attended `MOUNTED` breadcrumb. Do not infer body-runtime absence from invisible children.

### T004-F02 — quest content host is now reached, but presentation remains partial

**PARTIAL / next W03 follow-up.**

The right-hand quest tracker now shows a small Biology/E3 chrome element at its top edge, demonstrating that W03.5 reached a semantically relevant quest region. However the treatment does not compose coherently around the visible objective stack and still reads largely as native/current UI with a small marker attached.

Preserve the semantic-host improvement, but refine the chrome using the actual tracker child geometry/content bounds rather than enlarging it with a guessed global offset.

### T004-F03 — weapon/ammo detached-center regression appears corrected

**MATERIAL PASS / KEEP.**

The previous T003 `WEAPON // AMMO` chrome floating near the lower center is no longer visible there. The weapon/ammo presentation is back at the lower-right native region.

This accepts the specific T003 detached-center failure as repaired, but it does not by itself prove the complete weapon presentation target. Preserve W03.5's semantic weapon-host binding.

### T004-F04 — lower-left hotkey/quickslot chrome is visibly mis-composed

**FAIL / next W03 follow-up.**

The close crop shows Biology-owned red geometry overlapping/misaligned with the cyan native quickslot/D-pad widgets. Current `E3HotkeyHudNative.reds` still mounts a fill shell on `HotkeysWidgetController.GetRootCompoundWidget()`, the same root-assumption pattern already disproven for Biology detail, quest, and weapon surfaces.

Treat this as a native content-region problem until direct hierarchy evidence proves otherwise. Identify the actual current 2.31 semantic hotkey/quickslot content host and bind chrome there. Do not compensate with screenshot-derived global offsets.

### T004-F05 — ambient framed nameplate and reticle cleanup remain live

**KEEP.**

The ordinary gameplay capture still shows the framed ambient nameplate, and the old two-corner reticle artifact remains absent. Preserve both behaviors.

## Acceptance not exercised / not inferred

T004 remained focused on W02.5/W03.5 visual acceptance. It does not close issue #41 and does not claim WAIT/save-reload/SLEEP persistence acceptance.

E3 OFF, modern scanner/quickhack, ordinary Cyberware, and any other checklist item not directly visible or explicitly reported remain unexercised rather than silently PASS.

## Routing

| Finding | Route | State after T004 |
|---|---|---|
| T004-F01 Biology `MOUNTED` but blank | W02.6 / new follow-up under #39 | implementation diagnosis/repair required |
| T004-F02 quest host reached but treatment partial | W03.6 / new follow-up under #40 | implementation refinement required |
| T004-F03 weapon detached-center fixed | W03.6 | KEEP semantic host binding |
| T004-F04 lower-left hotkey chrome mis-composed | W03.6 / new follow-up under #40 | implementation diagnosis/repair required |
| T004-F05 nameplate + reticle wins | W03.6 | KEEP |
| listener/session | existing release path | PASS / preserve |
| body persistence | issue #41 | separate future attended acceptance |

## Lessons

- Positive attended breadcrumbs are valuable: `MOUNTED` conclusively moves W02 diagnosis past host resolution/reparent.
- Reusing a controller root for custom chrome is now a repeated failure mode across multiple CP2077 2.31 UI surfaces. Workers should identify semantic child/content regions before adding presentation geometry.
- The live-evidence hold is useful, but it must stay bounded. When an owner sees ambiguous visual behavior, parent may briefly keep the game open and let responsible workers request a small set of screenshots/ordinary state changes before END. No new local commands, probes, installs, or open-ended play should be introduced during the hold.
- Preserve proven partial wins instead of reworking whole systems: W03.5 corrected the weapon chrome's detached-center placement, while nameplates and reticle cleanup remain healthy.

## Next boundary

T005 is unallocated. Parent should route W02.6 and W03.6 before the next combined visual attended run. Issue #41 remains available for a separate focused persistence test.
