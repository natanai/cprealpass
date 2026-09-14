# realpass Biology interface

Status: canonical player-facing body/needs UI design; presentation migration active; native standalone shell acceptance pending
Last updated: 2026-09-14
Governing goals: `AGREED-GOALS.md` G-033, G-040 through G-049, G-055 through G-065, and G-072

## Product intent

**Biology** is the canonical player-facing home for realpass bodily simulation. It replaces the earlier idea that injury presentation should live as a `CYBERWARE | CONDITION` mode and replaces the accidental development direction that put more body-state information into Backpack.

The core division is deliberately simple:

- **Backpack = possessions.** It answers what V is carrying.
- **Biology = embodied state.** It answers what V can presently perceive, know or reasonably infer about their body.
- **Simulation = hidden physical state.** It may remain numerical and high-resolution without becoming a collection of player-visible meters.

The previous `CONDITION-UI.md` architecture is superseded where it places the canonical interface under Cyberware. Conditions remain an important Biology subsection.

## Governing presentation pipeline

Normal player-facing state follows:

`hidden biological state -> perceptible/knowable interpretation -> Biology UI and/or embodied gameplay cues`

This distinction is architectural, not cosmetic. A hydration value, bladder volume, energy balance, sleep pressure, blood deficit, analgesic load or tissue-damage fraction is simulation data. The existence of that number does not create an entitlement to a percentage bar.

Exact values remain appropriate for model logic, save migration, forecasting and development diagnostics. Normal play should instead expose the consequence V could experience: thirst, hunger, weakness, fatigue, urinary urgency, pain, dizziness, impaired function, bleeding, and so on, according to what the authored model actually supports.

> realpass calculates quantities; the player experiences consequences.

## Biology information architecture

Exact visual grouping remains open to attended native calibration, but the conceptual hierarchy is:

### Bodily needs / sensations

Qualitative, currently meaningful states such as thirsty, hungry, tired, urinary/bowel pressure, hygiene sensation where retained, and other future physiological sensations only when backed by the realpass model.

These are **not permanent meters**. If no need is meaningfully perceptible, the screen may omit or quiet it.

### Conditions

Conditions are meaningful active injury, impairment, illness/pathology when modeled, recognized physiological effects, or cyberware/body damage. Healthy regions remain visually quiet.

Regional injury remains authoritative at minimum for head, torso, left/right arms and left/right legs. A Biology condition can still use stock anatomical drill-down/paper-doll language where robust, but that is presentation reuse rather than Cyberware owning the interface.

### Effects

Perceptible state that is useful to distinguish from an underlying condition, for example pain/analgesia, dizziness/disorientation or another model-backed transient effect. Avoid duplicate bars or second damage systems.

### Contextual responses

Biology is primarily observational. An action appears because a bodily state makes it relevant, not because every possible command needs a permanent button.

Examples:

- `Hungry -> Eat…`
- `Thirsty -> Drink…`
- an applicable wound -> field-care options;
- an appropriate professional context -> clinical/mechanical care.

## Inventory boundary

Biology must never create a second food, drink or medical inventory.

`Eat…`, `Drink…` and treatment selection are **filtered views into actual carried items**. Backpack/inventory remains the source of truth for item identity and quantity, and consumption/treatment must use the ordinary authoritative transaction path.

This means a food item can be reached from either direction without duplicating state:

- Backpack: *I have an apple; use it.*
- Biology: *I am hungry; show me applicable food I actually have.*

Both routes resolve to the same item and the same realpass serving/intake behavior.

## What leaves Backpack

Realpass-owned player-facing physiology should not be injected into Backpack: hydration/hunger state, fatigue, elimination, pain/injury severity, blood/body-health summaries, field-care body dashboards, or survival-bar serving previews.

Inventory information that genuinely describes possessions may remain. A future physical encumbrance/capacity representation, if retained, must be justified as inventory/equipment information rather than smuggling the body dashboard back into Backpack.

The development patch `config/patches/darkfuture-body-previews.json` has been narrowed accordingly: it retains time-skip forecast correctness but no longer injects realpass body UI into Dark Future Backpack screens.

## Qualitative body projection

`BodyStatusPresentation.reds` is now the player-facing qualitative projection for needs. Its current thresholds are **provisional presentation calibration**, not clinical claims. It intentionally converts hidden body state into phrases and suppresses healthy regional injury rows.

Current development language includes hunger, thirst, fatigue, urinary/bowel pressure and hygiene perception. Exact fluid, calorie, bladder-volume and sleep-pressure numbers are no longer normal player-facing output. Serving forecasts likewise describe likely relevance to hunger/thirst without printing hidden ml/kcal quantities.

## Communicating urgency outside Biology

Biology is the place the player may deliberately inspect their body; it should not become the only place the body exists.

As a state becomes important, the preferred escalation is some combination of subtle embodied cue, qualitative Biology entry, stronger visual/audio/control/performance consequence when physiologically justified, and urgent impairment only when the underlying model warrants it.

The exact cue mapping remains calibration work. Do not invent effects merely to make a number noticeable.

## Conditions and injury detail

The prior condition-detail principles still apply inside Biology: region and condition type, approximate severity/current state, likely cause/time/protection context when provenance supports it, biological vs cybernetic damage, external vs internal bleeding, pain and functional consequences actually applied, plausible field care, and professional biological or mechanical care where context permits.

Normal presentation does not expose raw injury percentages, exact bleed rates, analgesic load or native HP.

## Cyberware boundary

Cyberware returns to its normal equipment purpose. The earlier source prototype in `ConditionNativeUI.reds` that mounts `CYBERWARE | CONDITION` on `RipperDocGameController` is now **legacy migration code, not canonical architecture**.

Do not expand that prototype. The replacement Biology shell should be realpass-owned and patch-resilient. It may reuse stable stock body/anatomical widgets or drill-down behavior, but should not require another gameplay mod's Conditions UI at release.

## Current implementation status

Implemented in source/design:

1. Canonical goals ledger now makes Biology the body-interface owner and supersedes `CYBERWARE | CONDITION`.
2. Realpass body-status presentation is qualitative rather than raw-number body telemetry.
3. Healthy regional injury rows are suppressed from the general body summary.
4. Normal serving forecast text no longer exposes ml/kcal quantities.
5. Dark Future Backpack migration patches no longer inject RealPass body status, field-care widgets or body-meter food previews.
6. Time-skip body forecasting remains intact because it is simulation correctness rather than Backpack presentation.
7. `BiologyPresentation.reds` provides a realpass-owned qualitative Biology view-model over current needs and active conditions.

Still pending native implementation/acceptance:

1. Replace/rename the currently visible Conditions shell with the final **Biology** screen in the owned runtime.
2. Build the Biology layout/groups against the accepted native shell.
3. Implement context-filtered carried-item lists for `Eat…` and `Drink…` using the authoritative inventory transaction path.
4. Move field/professional condition actions into Biology and retire the old Cyberware-mounted Condition prototype.
5. Add/calibrate non-menu embodied cues for needs where justified by the simulation.
6. Exact-compile/preflight and attended-test the complete native candidate against the installed Cyberpunk 2.31 environment.

Do not mark the Biology migration complete merely because the projection/docs are correct; the visible native screen and inventory actions require attended acceptance.

## Acceptance criteria

Biology is accepted only when an attended build demonstrates all of the following:

1. The menu is player-facing as **Biology**, not Conditions.
2. Backpack no longer carries RealPass bodily-status bars/dashboard elements.
3. Cyberware performs its vanilla equipment role without the old canonical `CYBERWARE | CONDITION` switch.
4. Hunger/thirst/fatigue/elimination appear qualitatively only when meaningful.
5. Hidden numerical body state remains available to simulation/diagnostics but is not exposed as normal percentages/quantities.
6. Active injuries/conditions remain selectable and healthy regions remain quiet.
7. Condition detail is driven by realpass injury/provenance state, not native HP.
8. `Eat…` and `Drink…` show only applicable items actually carried by V and do not create duplicate inventory state.
9. Selecting an item from Biology uses the same authoritative item/consumption path as using that item from inventory.
10. Field/professional care remains context-valid and transactional.
11. Urgent body state can communicate through believable gameplay/visual/audio consequences rather than requiring constant menu checking.
12. No Dark Future/Project E3 executing UI/runtime is required by the release implementation.
13. Save/reload and time progression preserve the single shared physiological body.
