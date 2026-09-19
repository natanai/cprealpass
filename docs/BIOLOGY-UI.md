# Biology interface

Status: **canonical architecture; current attended follow-ups #39 and #41 pending integration/live acceptance**  
Last updated: 2026-09-15  
Governing goals: `AGREED-GOALS.md` G-033, G-040 through G-049, G-055 through G-065, G-072

## Product intent

**Biology** is the canonical player-facing home for bodily simulation. It owns the body-shaped menu experience: needs, sensations, injury/conditions, pain/analgesia, elimination, fatigue/rest, recovery, hygiene where retained, and relevant cyberware/body state.

The hierarchy is:

`top hub -> BIOLOGY -> shared body/anatomy shell -> BIOLOGY | CYBERWARE`

Cyberware is installed equipment within the body, so it is a Biology submode rather than the parent category. The vanilla `cyberware_equip` / Ripperdoc anatomy fullscreen remains the preferred technical shell because it already provides the body silhouette, system anchors, selection/zoom language, category strip, Back stack, content region, and familiar Cyberpunk interaction grammar.

Normal hub access defaults to Biology. A direct ripperdoc/vendor context may default the internal mode to Cyberware for usability while preserving Biology as the parent screen.

## Navigation identity

Every ordinary player-facing doorway that represents the stock Cyberware destination should read **BIOLOGY** once the shared shell is accepted. The underlying native destination/identifier may remain Cyberware where doing so preserves stock routing; player-facing hierarchy changes do not require risky cosmetic renames of internal identifiers.

Inside the shared body screen, a clear **BIOLOGY | CYBERWARE** selector exposes the two overview modes without covering or competing with the stock top navigation.

### Overview/detail state rule

The attended Cyberware flow establishes the preferred interaction model:

- **overview:** `BIOLOGY | CYBERWARE` mode switching is available;
- **detail/drill-down:** mode switching is unavailable;
- **Back/Cancel:** returns from detail to the current mode's overview first;
- after returning to overview, mode switching becomes available again.

Biology must mirror this rule rather than permitting a Biology-detail -> Cyberware transition and then attempting to clean up leaked anatomy state afterward.

## Backpack / Biology / Cyberware boundary

- **Backpack = possessions.**
- **Biology = embodied state.**
- **Cyberware = installed equipment.**
- **Simulation = authoritative hidden physical state.**

Biology never maintains duplicate food, drink, medical, cyberware, or treatment inventory state.

## Overview rule

The Biology screen is **always available**, even when V has no urgent needs, injury, or pain. Healthy state must not make the body screen disappear or make supported body-system nodes unselectable.

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

When nothing meaningful is active, the overview simply reads **`STABLE`**. The supported body nodes remain visible and selectable.

## Exact values belong to deliberate drill-down

The overview does **not** show a permanent hydration/nutrition/fatigue/pain/blood/bladder meter wall.

Once the player deliberately selects a modeled body system or region, exact authoritative values may appear as restrained bars and numbers. Appropriate detail values include hydration/nutrition/energy, bladder/bowel load, circulating volume/blood deficit, bleed rates, pain/analgesia/disorientation, regional function, tissue/bone/cyberware integrity, exertion reserve, and cleanliness/hygiene where retained.

The bar is only a view of the authoritative model. It never becomes a second state variable.

The stronger acceptance rule remains: **players should not feel that they need to poll Biology's exact values to know how V feels.** If repeated menu checking becomes optimal play, embodied feedback needs improvement.

## Drill-down must reuse the native Cyberware interaction grammar

Biology detail is not a separate custom overlay state. Where the native Cyberware/Ripperdoc shell already provides the structure, reuse it:

- selected body-region zoom/focus;
- top body-part/category navigation strip;
- keyboard/controller left-right category cycling;
- native Back/Cancel stack;
- native content/item region;
- native selection/animation behavior;
- appropriate native interaction affordances.

Biology-specific telemetry and contextual actions belong inside those native regions. Overview labels must not remain floating over a zoomed body.

A normal Biology sequence must work repeatedly:

`Biology overview -> body system detail -> Back -> Biology overview`

Back must **not** force the user to close the entire pause/menu stack merely to escape a Biology drill-down.

## Reusing the Cyberware anatomy shell

Biology should reuse the native:

- central body silhouette;
- anatomical/system anchors;
- hover highlighting;
- selection and zoom animations;
- left/right layout behavior;
- category navigation strip;
- detail content region;
- Back hierarchy.

In Biology mode, stock cyberware equipment-card contents may be hidden while supported categories become body-system nodes. Existing labels such as Arms, Skeleton, Nervous System, Integumentary System, Circulatory System, and Legs are useful native language.

Do not invent physiology just to fill every Cyberware category. Unsupported nodes may be omitted until Biology has an authoritative model behind them.

## Conditions

Conditions are a Biology subsection, not a separate top-level screen. Regional injury remains authoritative for head, torso, left/right arms, and left/right legs.

A selected condition may expose region, condition type, approximate severity, likely cause/protection context, biological vs cybernetic damage, bleeding, functional consequence, exact regional bars, field care, and professional/mechanical care where relevant.

Healthy regions may report concise `NO CONDITION` at drill-down depth while remaining visually quiet on the overview.

## Contextual items/actions

Biology is primarily observational. Actions appear only when relevant, for example:

- hunger -> `EAT…`
- thirst -> `DRINK…`
- external bleeding -> appropriate dressing action;
- appropriate limb injury -> support;
- ripperdoc context -> clinical/mechanical care.

Use the native-style detail content area to surface **actual present carried items/actions** where the authoritative model says they are applicable.

`Eat…` and `Drink…` enumerate V's actual carried items and preserve Cyberpunk's item-action/transaction path. Biology never creates a second inventory or manually decrements an item merely because it displayed it.

Do not invent unsupported treatments merely to populate the native content area.

## Cyberware mode

Internal **CYBERWARE** restores ordinary Cyberpunk equipment behavior: slots, equip/upgrade interactions, cyberware capacity/armor presentation, and ripperdoc purchasing/service flows.

Switching modes must not duplicate, consume, unequip, or corrupt cyberware/items.

While Cyberware is in native detail depth, Biology switching remains unavailable until Back returns to overview. Biology detail must obey the same rule.

## Runtime availability rule

`STABLE` is valid only when authoritative body state is actually available and normal.

Do **not** convert a missing/uninitialized body runtime into `STABLE` just to make the UI look finished. A genuine runtime compatibility/lifecycle failure must fail obviously in diagnostics while ordinary successful UI remains concise.

Issue #41 owns authoritative body-runtime availability/lifecycle. The interface consumes that authority; it must not manufacture a second body state or cache fake healthy values.

At minimum runtime acceptance must cover:

- ScriptableSystem registration/availability timing;
- correct game/session authority;
- player/session initialization;
- menu-controller access;
- save/reload persistence;
- wait/sleep/time-skip progression;
- fail-obvious diagnostics when authority is genuinely missing.

## Current attended evidence — integrated REDmod milestone

Historical pre-REDmod evidence remains in `PRE-REDMOD-LIVE-BASELINE-2026-09-15.md`. It is not the current implementation status.

The current attended findings came from the exact integrated artifact built from:

`8cf045664b5e4d8b4b014edfc98bf2f8eb270ba5`

Artifact:

`biology-integrated-20260915-061136-8cf045664b5e.zip`

SHA-256:

`42BACC73173EB95D84F3278593CD06DDAF665AA714F4C692DB03D553B91557CC`

On Cyberpunk 2077 2.31, official REDmod recognition/deployment had already been proven before the attended session. The body-screen observations were:

1. the outer Biology destination was present;
2. Biology still behaved too much like a parallel/custom overlay instead of fully repurposing the native Cyberware shell;
3. Biology overview labels remained visible during body drill-down;
4. the `BIOLOGY | CYBERWARE` selector was too small and easy to miss;
5. Biology allowed a direct switch to Cyberware while drilled down, producing a stuck/leaked Biology skeleton state;
6. native Cyberware demonstrated the preferred opposite behavior: mode switching is unavailable while drilled down until Back returns to overview;
7. Biology had no usable detail -> overview Back route, forcing the player to leave the whole menu;
8. native Cyberware detail demonstrated the desired focused-region layout, category strip, content/item area, and Back hierarchy;
9. the live screen displayed `[ BIOLOGY ERROR ] BODY RUNTIME SYSTEM MISSING`, proving the authoritative body runtime was unavailable through that session/menu path.

Those findings are routed separately:

- issue #39 / PR #43 owns native shell reuse, drill-down/back behavior, selector visibility, detail content placement, and mode-state gating;
- issue #41 / PR #47 owns body runtime/session authority and must not be cosmetically hidden by the UI lane.

Source/CI fixes in either PR are not live acceptance until the parent integration thread exact-compiles the combined candidate and records a new attended result.

## Acceptance criteria

Biology UI is accepted only when an attended integrated build demonstrates all of the following:

1. ordinary body navigation identity is consistently presented as **BIOLOGY** where appropriate;
2. Biology opens the familiar native body/anatomy fullscreen;
3. a legible, discoverable, non-overlapping **BIOLOGY | CYBERWARE** selector exists at overview depth;
4. normal hub entry defaults to Biology while direct ripperdoc context remains practical;
5. Biology reuses native body silhouette/hover/zoom/category interaction behavior;
6. supported Biology nodes remain visible/clickable while healthy;
7. authoritative body state is available through menu reopen/save/reload and is never replaced by fake `STABLE` data;
8. normal overview is terse (`STABLE` or concise non-normal tokens), not a meter wall or explanatory paragraph;
9. selecting a modeled body system hides overview-only labels and enters the native-style detail structure;
10. the native category strip / left-right navigation can move among appropriate Biology systems without exposing unsupported Cyberware-only categories as fake physiology;
11. Back/Cancel from Biology detail returns to Biology overview rather than closing the whole menu;
12. `BIOLOGY | CYBERWARE` switching is unavailable during detail depth in both modes and returns after Back;
13. repeated overview -> detail -> Back and Biology <-> Cyberware overview cycles leave no stale skeleton/selection/overlay state;
14. exact values appear only at deliberate drill-down depth and read directly from the authoritative model;
15. contextual food/drink/care actions surface only applicable actual inventory/actions and preserve canonical transaction/treatment authority;
16. Cyberware equip/upgrade/capacity/vendor behavior remains stock and does not lose/duplicate item state;
17. save/reload and time progression preserve the single shared physiological body;
18. superseded overlay/prototype paths are no longer active once the replacement becomes authoritative.
