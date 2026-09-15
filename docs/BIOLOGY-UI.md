# realpass Biology interface

Status: canonical architecture revised from first live test; native shell redesign in progress
Last updated: 2026-09-14
Governing goals: `AGREED-GOALS.md` G-033, G-040 through G-049, G-055 through G-065, G-072

## Product intent

**Biology** is the canonical player-facing home for realpass bodily simulation. It owns the body-shaped menu experience: needs, sensations, injury/conditions, pain/analgesia, elimination, fatigue/rest, recovery, hygiene where retained, and relevant cyberware/body state.

The core hierarchy is now:

`top hub -> BIOLOGY -> shared body/anatomy shell -> BIOLOGY | CYBERWARE`

Cyberware is therefore a subsection/mode of Biology rather than the parent category. This deliberately reuses Cyberpunk's existing body silhouette, anatomical hover/zoom language, category anchors and interaction grammar instead of creating an unrelated second body screen.

The vanilla `cyberware_equip` fullscreen remains the technical shell because it already contains the most appropriate body presentation. The player-facing top-hub label should be **BIOLOGY**. Inside the screen, the player can switch cleanly between:

- **BIOLOGY** — embodied state, body systems, needs, conditions and contextual responses;
- **CYBERWARE** — the normal cyberware equipment/slot experience.

Normal hub entry defaults to Biology. A direct ripperdoc/vendor context may default the internal mode to Cyberware because that is the task the player intentionally entered, while Biology remains the parent conceptual screen.

## Backpack / Biology / Cyberware boundary

- **Backpack = possessions.** It answers what V is carrying.
- **Biology = the body.** It answers what V can perceive, know or deliberately inspect about their embodied state.
- **Cyberware = installed equipment in the body.** It remains fully accessible, but lives as a Biology submode.
- **Simulation = authoritative hidden physical state.** It can remain exact and high-resolution independently of what the overview shows.

Biology must never maintain a duplicate food, drink, medical or cyberware inventory.

## Governing presentation pipeline

Normal play follows:

`hidden biological state -> perceptible/knowable interpretation -> gameplay/visual/audio cues + Biology overview`

The primary player experience is qualitative and embodied. A hydration value, blood deficit, sleep pressure, bladder volume, analgesic load or tissue-damage fraction existing internally does **not** mean it deserves permanent screen space.

> realpass calculates quantities; the player experiences consequences.

The stronger acceptance rule is: **players should not feel that they need to poll Biology's detailed values to understand V's body.** If repeatedly opening categories to check bars becomes the practical way to know whether V is hungry, exhausted, dehydrated, bleeding or impaired, the embodied feedback is insufficient and should be improved rather than making the meters more prominent.

## Two levels of visibility

### Biology overview

The unzoomed body view stays quiet and qualitative. It may expose states such as:

- thirsty / very thirsty;
- hungry / weak with hunger;
- tired / exhausted;
- need to urinate / bowel pressure;
- bleeding;
- pain / analgesic disorientation;
- impaired arm or leg;
- active head/torso/limb condition;
- relevant recovery or care state.

Healthy, irrelevant and imperceptible state should fade into the background. **No hydration/nutrition/fatigue/pain/blood/bladder percentage wall belongs on this overview.**

### Deliberate drill-down

Once the player deliberately clicks/zooms into a body system or affected region, **exact authoritative values may be shown as restrained bars and numbers**. This is not a return to HUD health bars: it is deep inspection requested by the player.

Examples of appropriate drill-down values include:

- hydration/nutrition/energy projections;
- body-water or energy-balance context where useful;
- bladder/bowel accumulation;
- blood deficit relative to modeled blood capacity;
- perceived pain / analgesia / overuse state;
- regional function;
- tissue, bone and cyberware damage for the selected region;
- external/internal bleed rate where the model tracks it.

The bar is a view of the authoritative model, never a second state variable. Where a bar is normalized from an authored gameplay scale rather than a literal clinical percentage, the UI should avoid implying medical precision.

This deeper visibility is particularly useful during development/calibration, but it is intentionally available to players as inspection depth too.

## Reusing the Cyberware anatomy shell

The existing Cyberware screen already supplies useful native presentation machinery:

- central body silhouette;
- body-system/category anchors around the body;
- hover highlighting;
- category selection;
- zoom-in / zoom-out animations;
- left/right layout behavior;
- familiar Cyberpunk interaction language.

Biology should reuse those mechanics rather than add a floating hub panel beside them.

In Biology mode, stock cyberware slot contents can be hidden while relevant category anchors remain usable as body-system nodes. Existing labels that already describe anatomy (`ARMS`, `SKELETON`, `NERVOUS SYSTEM`, `INTEGUMENTARY SYSTEM`, `CIRCULATORY SYSTEM`, `LEGS`, etc.) are valuable native language. Cyberware-specific categories may be relabeled or omitted in Biology mode only where the realpass body model actually supports a replacement concept.

Do **not** invent biological detail merely to fill every Cyberware slot. A system/node can stay absent or quiet until realpass has an authoritative model behind it.

Selecting a Biology node should use the stock body hover/zoom animation controller where possible, then reveal the qualitative explanation plus any deeper exact inspection values for that system/region.

## Conditions

Conditions remain a Biology subsection, not a separate top-level page. Regional injury remains authoritative at minimum for head, torso, left/right arms and left/right legs.

A selected condition can show:

- region and condition type;
- approximate severity/current state;
- likely cause/protection context when provenance supports it;
- biological vs cybernetic damage;
- external vs internal bleeding;
- pain and functional consequence;
- exact regional values/bars at this deliberate inspection depth;
- plausible field care;
- professional biological or mechanical care where context permits.

Healthy regions remain visually quiet.

## Contextual actions

Biology is primarily observational. Actions appear because the body makes them relevant.

Examples:

- `Hungry -> Eat…`
- `Thirsty -> Drink…`
- external bleeding -> dressing if applicable;
- appropriate limb injury -> support if applicable;
- ripperdoc context -> clinical/mechanical professional care if the model says it can help.

`Eat…` and `Drink…` enumerate V's **actual carried item stacks** through the stock transaction system, filter them through `CRItemServing`, and preserve their stock `Eat`, `Drink` or fallback `Consume` action. Biology never manually removes the item or maintains duplicate inventory state.

## Cyberware mode

The internal **CYBERWARE** mode preserves normal Cyberpunk equipment behavior:

- installed cyberware slots;
- item selection/equip/upgrade interactions;
- capacity/armor/cyberware-specific presentation;
- ripperdoc purchasing/service behavior where applicable.

Switching back to Biology should restore Biology nodes/state without losing or duplicating the underlying cyberware equipment state.

The hierarchy is conceptual and navigational only: nesting Cyberware beneath Biology must **not** rewrite Cyberpunk's actual cyberware inventory authority.

## Communicating urgency outside Biology

Biology is where the player may deliberately inspect their body; it must not become the only place the body exists.

Injury/pain should communicate through impairment, bleeding/weakness, weapon handling, movement, audiovisual feedback and other justified consequences. Hunger/thirst/fatigue/elimination should similarly become increasingly apparent through believable sensations/consequences as they become important.

The drill-down bars exist to answer *"what exactly is going on?"*, not *"should I be worried yet?"* The game should already be answering the latter.

## First live-test finding (2026-09-14)

The first deployed candidate exact-compiled and launched, but its dynamically-added Biology button on `MenuHubLogicController` did **not** surface as an ordinary navigable Biology page. The visible hub still presented the stock `CYBERWARE` top-level entry.

That live result invalidates the floating-hub-button shell, not the underlying Biology/body models. The replacement architecture is therefore to make the existing body-shaped Cyberware fullscreen the shared Biology/Cyberware shell and rename the top-level hub destination to **BIOLOGY**.

The old floating hub panel should be retired as the canonical ordinary Biology entry after the shared shell is working.

## Implementation targets

1. Relabel the top-level stock `HubMenuItems.Cyberware` destination as **BIOLOGY** while retaining its `cyberware_equip` fullscreen routing.
2. Add a clear internal `BIOLOGY | CYBERWARE` mode switch inside `RipperDocGameController`.
3. Default normal hub access to Biology; preserve sensible Cyberware-first behavior in direct ripperdoc/vendor context.
4. Reuse native cyberware body anchors/category hover and `RipperdocScreenAnimationController` zoom behavior for Biology nodes where the model supports them.
5. Hide stock cyberware slot contents while in Biology mode without destroying/duplicating their inventory state.
6. Keep the central body silhouette and useful anatomical category language.
7. Replace/omit only genuinely cyberware-specific nodes where realpass has an authoritative biological category to present.
8. Add deliberate-detail bars/numbers sourced directly from `CRBodyRuntime`, `CRBodyMeters`, injury state and pain projection.
9. Keep the overview qualitative and meter-free.
10. Preserve existing actual-inventory Eat/Drink, field-care and professional-care transaction boundaries.
11. Retire the invisible floating ordinary hub Biology panel once the shared shell is proven.

## Acceptance criteria

The revised Biology shell is accepted only when an attended build demonstrates all of the following:

1. The top navigation says **BIOLOGY** where Cyberware previously appeared.
2. Clicking it opens the familiar body/anatomy fullscreen, not a separate floating panel.
3. A clear internal Biology/Cyberware switch exists and Cyberware remains fully usable.
4. Normal hub entry defaults to Biology; ripperdoc context remains practical for cyberware service.
5. Biology mode reuses the native body silhouette, hover/zoom language and appropriate anatomy nodes.
6. Biology overview shows meaningful qualitative state but no permanent numerical needs/body bars.
7. Deliberately selecting a body system/region may show exact authoritative values as bars/numbers.
8. Those detail values never become an always-on HUD or replacement actor-healthbar system.
9. A player can understand important needs/injury without repeatedly polling the detail bars.
10. Active conditions remain selectable and healthy state remains quiet.
11. Eat/Drink and care actions still use their existing authoritative transactions.
12. Switching modes does not duplicate, consume, unequip or corrupt cyberware/items.
13. No Dark Future/Project E3 executing UI/runtime is required.
14. Save/reload and time progression preserve the single shared physiological body.
