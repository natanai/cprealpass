# realpass Condition interface

Status: canonical injury/personal-condition UX design
Last updated: 2026-09-13
Governing goals: `AGREED-GOALS.md` G-040 through G-049, G-050 through G-053

## Product intent

The final realpass injury interface lives inside Cyberpunk's existing Cyberware/body screen. The stock body visualization and paper-doll zoom/drill-down language are the shell; realpass owns all new condition state, condition cards, explanatory text and treatment behavior.

The current backpack `FIELD CARE` popup is a development prototype. It is not the intended final navigation path and should be removed from production once Condition mode reaches native acceptance.

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

### 6. Professional care

If the selected condition exceeds field treatment, state that clearly.

Examples:

- internal bleeding requires clinical care;
- serious bone injury benefits from professional care;
- structural cyberware damage requires mechanical/ripperdoc repair.

When the same screen is opened in an appropriate ripperdoc/clinical context, those actions may become interactive rather than informational.

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

The Condition screen may initiate treatment, but treatment completion occurs through the realpass action runtime, not by mutating the UI copy of state.

A field-care action should continue to require the player to leave/close the menu and remain still for its authored duration. The UI starts an action; the gameplay runtime validates and commits it.

## Ripperdoc / professional context

The stock cyberware/ripperdoc controller already distinguishes whether it was opened as ordinary inventory or through a vendor/ripperdoc context. realpass should use that native context instead of inventing a parallel clinic detection system where possible.

Professional-care actions must still be realpass-owned. The fact that the screen is a ripperdoc screen is permission/context, not an external gameplay authority.

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
11. Professional/mechanical care is unavailable in ordinary context and available only in accepted clinical/ripperdoc context.
12. The backpack prototype is removed from the release profile once this interface passes.
13. No Dark Future/Project E3 runtime script/asset/state is required by this screen.
14. Save/reload preserves current regional injury and the bounded explanatory history needed for current conditions.

## Implementation order

1. Keep `CRInjuryState` authoritative.
2. Record bounded provenance only after a wound is actually accepted.
3. Add pure presentation helpers that turn region + provenance into condition descriptors.
4. Mount a minimal Condition toggle/overview on the stock Cyberware/ripperdoc controller.
5. Reuse/trigger stock regional selection and zoom rather than implementing a new camera system.
6. Build regional detail content and field-treatment initiation.
7. Add ripperdoc-context professional/mechanical care.
8. Remove the backpack Field Care prototype from the owned release profile.
9. Exact-compile and native-test every step before expanding the UI surface.
