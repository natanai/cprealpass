# realpass Biology interface

Status: canonical architecture; clean-room live acceptance pending
Last updated: 2026-09-15
Governing goals: `AGREED-GOALS.md` G-033, G-040 through G-049, G-055 through G-065, G-072

## Product intent

**Biology** is the canonical player-facing home for realpass bodily simulation. It owns the body-shaped menu experience: needs, sensations, injury/conditions, pain/analgesia, elimination, fatigue/rest, recovery, hygiene where retained, and relevant cyberware/body state.

The hierarchy is:

`top hub -> BIOLOGY -> shared body/anatomy shell -> BIOLOGY | CYBERWARE`

Cyberware is installed equipment within the body, so it is a Biology submode rather than the parent category. The vanilla `cyberware_equip` fullscreen remains the technical shell because it already provides the body silhouette, system anchors, hover/zoom language and familiar Cyberpunk interaction grammar.

Normal hub access defaults to Biology. A direct ripperdoc/vendor context may default the internal mode to Cyberware for usability while preserving Biology as the parent screen.

## Navigation identity

Every ordinary player-facing doorway that represents the stock Cyberware destination should read **BIOLOGY** once the shared shell is accepted: the outer radial hub, the inner tab/navigation strip, and adjacent inventory/menu navigation surfaces that reuse the same destination.

The underlying native destination/identifier remains Cyberware so stock routing stays intact. Only the player-facing hierarchy changes.

Inside the body screen, a clear **BIOLOGY | CYBERWARE** selector exposes the two modes without covering or competing with the stock top navigation.

## Backpack / Biology / Cyberware boundary

- **Backpack = possessions.**
- **Biology = embodied state.**
- **Cyberware = installed equipment.**
- **Simulation = authoritative hidden physical state.**

Biology never maintains duplicate food, drink, medical or cyberware inventory state.

## Overview rule

The Biology screen is **always available**, even when V has no urgent needs, injury or pain. Healthy state must not make the body screen disappear or make its body-system nodes unselectable. The player must always be able to inspect a modeled system and drill into its exact values.

The unzoomed overview is qualitative and terse. It must read like compact instrumentation, not prose or advice.

Preferred status vocabulary is one or two words per signal, for example:

- `STABLE`
- `THIRST`
- `THIRST HIGH`
- `HUNGER`
- `HUNGER CRITICAL`
- `FATIGUE`
- `BLADDER HIGH`
- `BOWEL URGENT`
- `HYGIENE LOW`
- `PAIN HIGH`
- `ANALGESIA`
- `DISORIENTATION`
- `BLEEDING`
- `IMPAIRED`
- `CONDITION ACTIVE`

Do not use conversational filler such as “No strong bodily need is demanding attention,” “the body is doing fine,” or explanatory coaching copy on the overview.

When nothing meaningful is active, the overview should simply read **`STABLE`**. The body nodes remain visible and selectable.

## Exact values belong to deliberate drill-down

The overview does **not** show a permanent hydration/nutrition/fatigue/pain/blood/bladder meter wall.

Once the player deliberately selects/zooms into a modeled body system or region, exact authoritative values may appear as restrained bars and numbers. This visibility is especially useful for development/calibration and remains available to players as inspection depth.

Appropriate detail values include:

- hydration, nutrition and energy;
- bladder/bowel load;
- circulating volume / blood deficit;
- external/internal bleed rate;
- perceived pain, analgesia and disorientation;
- regional function;
- tissue, bone and cyberware integrity;
- exertion reserve;
- cleanliness/hygiene where retained.

The bar is only a view of the authoritative model. It never becomes a second state variable.

The stronger acceptance rule remains: **players should not feel that they need to poll Biology's exact values to know how V feels.** If repeated menu checking becomes optimal play, embodied feedback needs improvement.

## Drill-down copy style

Selected-system summaries should also prefer telemetry over paragraphs. Examples:

- `NO CONDITION`
- `PAIN / ANALGESIA`
- `GLOBAL LOAD`
- `DEFICIT 320 ml | BLEED EXT 40 | BLEED INT 0`
- `L NO CONDITION | R MODERATE FRACTURE`

Exact metrics below the summary carry the detail. Explanatory prose belongs only where a genuinely complex cause/care distinction cannot be communicated by labels, values and concise condition language.

## Reusing the Cyberware anatomy shell

Biology should reuse the native:

- central body silhouette;
- anatomical/system anchors;
- hover highlighting;
- selection and zoom animations;
- left/right layout behavior;
- category interaction grammar.

In Biology mode, stock cyberware slot contents may be hidden while supported categories become body-system nodes. Existing labels such as Arms, Skeleton, Nervous System, Integumentary System, Circulatory System and Legs are useful native language.

Do not invent physiology just to fill every Cyberware category. Unsupported nodes may be omitted until realpass has an authoritative model behind them.

The supported Biology nodes must remain visible regardless of whether their current values are normal.

## Conditions

Conditions are a Biology subsection, not a separate top-level screen. Regional injury remains authoritative for head, torso, left/right arms and left/right legs.

A selected condition may expose region, condition type, approximate severity, likely cause/protection context, biological vs cybernetic damage, bleeding, functional consequence, exact regional bars, field care and professional/mechanical care where relevant.

Healthy regions may report concise `NO CONDITION` at drill-down depth while remaining visually quiet on the overview.

## Contextual actions

Biology is primarily observational. Actions appear only when relevant, for example:

- hunger -> `EAT…`
- thirst -> `DRINK…`
- external bleeding -> dressing;
- appropriate limb injury -> support;
- ripperdoc context -> clinical/mechanical care.

`Eat…` and `Drink…` enumerate V's actual carried items and preserve stock item action/transaction paths. Biology never manually removes items or creates a second inventory.

## Cyberware mode

Internal **CYBERWARE** restores ordinary Cyberpunk equipment behavior: slots, equip/upgrade interactions, cyberware capacity/armor presentation, and ripperdoc purchasing/service flows.

Switching modes must not duplicate, consume, unequip or corrupt cyberware/items.

## Live-test interpretation

A stale in-place test build showed three useful design problems even though it is not valid evidence for the current clean-room candidate:

1. Biology identity appeared in one outer menu but not consistently across inner navigation.
2. The `BIOLOGY | CYBERWARE` selector visually collided with stock text.
3. The bottom overview used verbose prose where compact telemetry was needed.

The clean-room candidate should therefore be evaluated for **label consistency, selector placement, persistent inspectability, terse overview copy and drill-down values** separately from simulation correctness.

## Acceptance criteria

Biology is accepted only when an attended clean-room build demonstrates all of the following:

1. Ordinary Cyberware navigation identity is consistently presented as **BIOLOGY** across the outer hub and relevant inner navigation surfaces.
2. Clicking Biology opens the familiar body/anatomy fullscreen.
3. A legible, non-overlapping **BIOLOGY | CYBERWARE** selector exists.
4. Normal hub entry defaults to Biology; ripperdoc context remains practical for Cyberware service.
5. Biology mode reuses native body silhouette/hover/zoom behavior.
6. Supported Biology nodes remain visible and clickable even when every current state is normal.
7. A normal overview reads `STABLE`, not a sentence.
8. Non-normal overview signals use terse one/two-word telemetry tokens.
9. No permanent exact needs/body meter wall appears on the overview or gameplay HUD.
10. Selecting a modeled body system/region shows exact authoritative bars/numbers.
11. Detail summaries remain compact/data-like where possible.
12. Players can understand important needs/injury without repeatedly polling detail bars.
13. Eat/Drink and care actions preserve authoritative inventory/treatment transactions.
14. Switching modes preserves Cyberware equipment state.
15. Save/reload and time progression preserve the single shared physiological body.
