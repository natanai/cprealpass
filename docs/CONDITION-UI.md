# realpass Condition interface

Status: canonical injury/personal-condition UX design; first owned native slice implemented, native acceptance pending
Last updated: 2026-09-13
Governing goals: `AGREED-GOALS.md` G-040 through G-049, G-050 through G-053

## Product intent

The final realpass injury interface lives inside Cyberpunk's existing Cyberware/body screen. The stock body visualization and paper-doll zoom/drill-down language are the shell; realpass owns all new condition state, condition cards, explanatory text and treatment behavior.

The current backpack `FIELD CARE` popup is a development prototype. It is not the intended final navigation path and is excluded from the owned acceptance runtime; Condition mode is replacing it.

## Current implementation status

The first project-original native slice now exists in `ConditionNativeUI.reds`. It dynamically mounts a `CYBERWARE | CONDITION` switch and qualitative condition panel on the stock `RipperDocGameController`, lists active conditions only, maps the six realpass body regions onto stock anatomical areas, and calls the stock `DollHover`/`DollSelect` selection path instead of introducing a custom camera system.

`ConditionPresentation.reds` is the read-only projection from authoritative regional injury state plus bounded provenance. The UI has no native-HP dependency and does not mutate injuries directly.

Ordinary inventory/Cyberware context exposes model-approved **dressing** and **limb support** actions. They still begin through the timed field-care runtime: the menu must be closed, the player must remain stationary/out of combat with hands available, and interruption cancels the action without turning the trauma kit into a universal heal.

Ripperdoc context now exposes two distinct professional actions when the model says they can help:

- **Clinical care** controls external/internal bleeding and establishes professional biological aftercare. It does not directly erase tissue/bone trauma or replace lost blood; subsequent biological recovery still occurs through the shared body clock.
- **Cyberware repair** reduces structural chrome damage only. It does not treat biological tissue, bone or blood loss.

`ProfessionalCareModel.reds` owns professional-care eligibility. It deliberately does not own pricing/economy. The first acceptance slice treats the click as completion of an appropriate professional service; service price/time presentation can be calibrated later without making realpass an economy overhaul.

This code is **not yet native-accepted**. Cloud/offline tests can verify authority boundaries and pure treatment behavior, but the exact stock-controller hook signatures, dynamic Ink layout, paper-doll behavior and installed-game interactions must pass the user's local 2.31 compile/preflight and attended test before this interface is considered working in Cyberpunk.

## Two modes

The body screen has a conceptual mode switch:

`CYBERWARE | CONDITION`

### Cyberware

Preserve vanilla behavior as closely as practical. Installed cyberware slots, equipment flow, stock paper-doll zoom and ripperdoc behavior remain CDPR's responsibility.

### Condition

Realpass takes over only the condition layer:

- installed-cyberware cards/minigrids are hidden or visually deprioritized for the Condition view;
- the central stock body remains visible;
- active realpass conditions appear as selectable entries anchored to the relevant anatomy;
- healthy regions remain visually quiet rather than filling the screen with `OK` cards;
- selecting a condition uses the stock regional paper-doll zoom/drill-down where available;
- the zoomed/detail view becomes the place to understand and tend the selected condition.

The current first slice overlays its realpass panel rather than fully suppressing/dimming every vanilla cyberware minigrid. That visual handoff is intentionally left for native acceptance/calibration rather than making a broad resource replacement before the stock-controller integration is proven.

The exact switch widget/position is an implementation detail. It should look native and must not require a separate Mod Settings dependency.

## Vanilla shell we intend to reuse

The current game controller used by the cyberware/ripperdoc body UI already distinguishes inventory-vs-ripperdoc context, owns anatomical anchors (arms, legs, hands, system, nervous system, skeleton, ocular, integumentary, frontal cortex, cardiovascular), and drives paper-doll selection/zoom.

realpass should wrap/extend that controller rather than ship a copied third-party UI.

### Patch-resilience rule

Prefer dynamic realpass widgets attached to the stock controller/root/anchors over replacing whole `.inkwidget` resources. If a future game patch moves an anchor, the adapter should be fixable without changing the injury model or condition data.

## Condition identity

The authoritative physical state remains the six-region `CRInjuryState`:

1. head
2. torso
3. left arm
4. right arm
5. left leg
6. right leg

A **condition entry** is a player-facing interpretation of that physical state plus bounded provenance metadata. It is not a second damage model.

Examples:

- `LEFT ARM — Gunshot wound`
- `TORSO — Blunt trauma`
- `HEAD — Concussive trauma`
- `RIGHT LEG — Cyberware structural damage`

Multiple recent causes may be shown when useful, but the current regional physical state remains authoritative.

## Overview behavior

Condition overview should answer one question quickly: **what currently needs attention?**

Healthy regions: no card required.

A region with a meaningful condition can expose one primary condition card. The title should prioritize the current physical problem rather than raw values.

Possible supporting indicators:

- external bleeding;
- suspected/internal bleeding;
- fracture/bone trauma;
- impaired function;
- damaged chrome;
- supported/stabilized;
- healing/recovering.

Do not turn these into six health bars or exact percentage meters.

## Regional zoom mapping

Use CDPR's existing regional zooms wherever possible.

If the vanilla screen has one `Arms` zoom rather than distinct left/right camera states, realpass should:

1. zoom to Arms using the native transition;
2. keep left/right condition entries distinct in the zoomed content;
3. select/focus the requested side through realpass UI emphasis rather than inventing a fragile custom camera asset.

Apply the same rule to Legs or any other combined stock region.

The first native slice maps head→Frontal Cortex, torso→Integumentary System, either arm→Arms and either leg→Legs solely to drive the existing stock selection language. Left/right identity remains in the realpass condition entry and authoritative region.

## Detail view information hierarchy

The zoomed condition view should communicate, in this approximate order:

### 1. Condition title

Examples:

`LEFT ARM`
`PENETRATING TRAUMA`

or

`RIGHT LEG`
`CYBERWARE STRUCTURAL DAMAGE`

### 2. When / likely cause

Use bounded realpass provenance when available:

- approximate game time/elapsed time;
- ballistic/projectile family or other impact family;
- region struck;
- protection encountered and whether meaningful residual impact reached the body;
- biological/cybernetic contact context;
- distance/ricochet details only when they improve the explanation.

Normal UI should say things like:

`Likely caused by a handgun projectile. No effective protection stopped the impact.`

not:

`Initial energy: 472.38 J; residual: 318.24 J.`

Exact values remain diagnostic data.

### 3. Current condition

Qualitative state derived from the authoritative region:

- soft-tissue trauma: minor/moderate/severe;
- bone trauma: none/suspected/significant;
- external bleeding: none/minor/moderate/severe;
- internal bleeding: none/suspected/significant;
- cyberware damage: none/minor/moderate/severe;
- function: normal/impaired/severely impaired.

### 4. Functional consequences

Explain only effects realpass is actually applying, for example:

- reduced movement from leg injury;
- reduced reload/weapon handling from arm injury;
- reduced stamina from torso injury/blood loss;
- degraded weapon control from head injury.

Do not promise an effect not currently active in the runtime.

### 5. Field treatment

Show only actions that can plausibly help the current state and are currently available.

Examples:

`APPLY DRESSING — Trauma Kit x1 — 8 sec`

`SUPPORT ARM — Trauma Kit x1 — 12 sec`

An action remains subject to realpass context rules: out of combat, hands available, stationary, not interrupted by another menu/action, valid current body state and available supplies.

The first native slice already initiates these through `CRBodyRuntime.UseFieldCare`; the UI does not debit inventory or mutate injury state itself.

### 6. Professional care

If the selected condition exceeds field treatment, state that clearly.

Examples:

- internal bleeding requires clinical care;
- serious biological injury benefits from professional aftercare;
- structural cyberware damage requires mechanical/ripperdoc repair.

When the same screen is opened in stock ripperdoc context, model-approved `CLINICAL CARE` and `REPAIR CYBERWARE` controls are exposed. The actions are distinct by design. Clinical care cannot repair chrome; mechanical repair cannot heal biology. Neither replenishes prior blood loss or native HP.

## Biological vs cybernetic presentation

The same body region can contain both biological and cybernetic injury. Do not collapse them into one generic damage number.

Presentation may use different visual language (for example medical red/amber versus technical/cyan) as long as accessibility and clarity are preserved. Exact colors are not yet locked.

## Injury provenance contract

`InjuryProvenance.reds` stores a bounded recent ledger for explanatory UI. It currently records accepted player wound metadata such as:

- game-world time;
- region/material;
- weapon/ammo records and projectile family;
- distance/ricochet count;
- whether protection was encountered and whether protection mapping was unresolved;
- internal impact bookkeeping needed to derive a qualitative explanation;
- wound result fields.

The ledger is intentionally bounded. Provenance failure must never veto an accepted wound, and provenance never owns recovery/treatment state.

## Treatment navigation

The Condition screen may initiate treatment, but treatment completion occurs through the realpass action/body runtime, not by mutating the UI copy of state.

A field-care action should continue to require the player to leave/close the menu and remain still for its authored duration. The UI starts an action; the gameplay runtime validates and commits it.

Professional actions are context-gated completed services. Clinical care is represented by treatment kind 4 and cyberware repair by kind 5 in the same ordered body-input/treatment authority used by recovery. This preserves one injury state and avoids a second vendor-specific healing model.

## Ripperdoc / professional context

The stock cyberware/ripperdoc controller already distinguishes whether it was opened as ordinary inventory or through a vendor/ripperdoc context. The first native slice uses `CyberwareScreenType.Ripperdoc` for this permission boundary rather than inventing parallel clinic detection.

Professional-care actions remain realpass-owned. The fact that the screen is a ripperdoc screen is permission/context, not an external gameplay authority.

Professional service economics are intentionally not an authority in this milestone. realpass' scope excludes an economy overhaul; a later accepted service cost/time may use native money/UI without creating arbitrary scarcity or changing the physical treatment semantics.

## Acceptance criteria

Condition UI is not accepted until all of the following are demonstrated in the installed game:

1. Cyberware mode still performs its normal vanilla role.
2. Condition mode can be entered/exited without corrupting cyberware screen state.
3. Healthy V does not get a wall of empty condition cards.
4. A real accepted injury produces the correct regional condition entry.
5. Selecting an arm/leg/head/torso condition uses the intended stock zoom or a documented safe fallback.
6. Left/right conditions remain distinguishable even if the native camera groups Arms/Legs.
7. Detail text is derived from current authoritative injury state and bounded provenance, not from native HP.
8. External versus internal bleeding is communicated distinctly.
9. Biological versus cyberware damage is communicated distinctly.
10. Field-care actions only appear when they can help and still pass runtime validation at commit time.
11. Clinical and mechanical actions are unavailable in ordinary context and available only in accepted ripperdoc/clinical context when their respective model says they can help.
12. Clinical care controls bleeding/aftercare without instantly healing tissue/bone or replacing blood; mechanical repair affects chrome without treating biology.
13. The backpack prototype remains absent from the owned runtime once this interface passes.
14. No Dark Future/Project E3 runtime script/asset/state is required by this screen.
15. Save/reload preserves current regional injury and the bounded explanatory history needed for current conditions.

## Implementation order

1. Keep `CRInjuryState` authoritative. **Implemented/model-tested.**
2. Record bounded provenance only after a wound is actually accepted. **Implemented/offline-tested.**
3. Add pure presentation helpers that turn region + provenance into condition descriptors. **Implemented/offline contract-tested.**
4. Mount a minimal Condition toggle/overview on the stock Cyberware/ripperdoc controller. **Implemented in source; native compile/render acceptance pending.**
5. Reuse/trigger stock regional selection and zoom rather than implementing a new camera system. **Implemented in source via `DollHover`/`DollSelect`; native acceptance pending.**
6. Build regional detail content and field-treatment initiation. **Implemented in first source slice; native acceptance pending.**
7. Add ripperdoc-context professional/mechanical care. **Implemented in first source slice + pure model tests; native acceptance pending.**
8. Retire the backpack Field Care prototype from the owned release path. **Owned acceptance builder excludes it; historical source remains as prototype evidence.**
9. Exact-compile and native-test every stock-controller/treatment integration before polishing or expanding the UI surface. **Next local gate.**
