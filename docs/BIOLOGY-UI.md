# realpass Biology interface

Status: canonical player-facing body/needs UI; owned native source implemented; exact local compile and attended acceptance pending
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

The owned native implementation is intentionally dynamic REDscript rather than a wholesale replacement of a stock `.inkwidget`. Exact spacing/typography remain attended calibration details, but the conceptual hierarchy is fixed.

### Bodily needs / sensations

Qualitative, currently meaningful states such as thirsty, hungry, tired, urinary/bowel pressure, hygiene sensation where retained, and other future physiological sensations only when backed by the realpass model.

These are **not permanent meters**. If no need is meaningfully perceptible, the screen quiets it.

### Conditions

Conditions are meaningful active injury, impairment, illness/pathology when modeled, recognized physiological effects, or cyberware/body damage. Healthy regions remain visually quiet.

Regional injury remains authoritative at minimum for head, torso, left/right arms and left/right legs. Conditions are selectable in Biology and show the existing qualitative detail projection; the former Cyberware-mounted `CYBERWARE | CONDITION` prototype has been removed from production source.

### Effects

Perceptible state useful to distinguish from the underlying condition, currently including meaningful pain, MaxDoc analgesia and analgesic-overuse disorientation. These remain qualitative and never become a second damage system.

### Contextual responses

Biology is primarily observational. An action appears because a bodily state makes it relevant, not because every possible command needs a permanent button.

Current source behavior includes:

- `Hungry -> Eat…`
- `Thirsty -> Drink…`
- an applicable wound -> dressing/support actions;
- ripperdoc context -> clinical/mechanical professional care when the model says it can help.

## Inventory boundary

Biology never creates a second food, drink or medical inventory.

`Eat…` and `Drink…` enumerate the player's **actual carried item stacks** through the stock transaction system, filter those records through `CRItemServing`, and then invoke Cyberpunk's own `ItemActionsHelper.ConsumeItem(...)`. The existing `ConsumeAction.CompleteAction` adapter observes the successfully completed stock action and submits that same record to the realpass body runtime.

Biology therefore does not manually subtract items and does not call the body-consumption method directly.

A food item can be reached from either direction without duplicated state:

- Backpack: *I have an apple; use it.*
- Biology: *I am hungry; show me applicable food I actually have.*

Both routes resolve to the same stock consumable transaction and the same realpass serving/intake behavior.

## What leaves Backpack

Realpass-owned player-facing physiology is not injected into Backpack: hydration/hunger state, fatigue, elimination, pain/injury severity, blood/body-health summaries, field-care body dashboards, or survival-bar serving previews.

Inventory information that genuinely describes possessions may remain. A future physical encumbrance/capacity representation, if retained, must be justified as inventory/equipment information rather than smuggling the body dashboard back into Backpack.

The development patch `config/patches/darkfuture-body-previews.json` is narrowed accordingly: it retains time-skip forecast correctness but no longer injects realpass body UI into Dark Future Backpack screens. That patch remains migration/reference material rather than a release runtime dependency.

## Qualitative body projection

`BodyStatusPresentation.reds` is the player-facing qualitative projection for needs. Its thresholds are **provisional presentation calibration**, not clinical claims. It converts hidden body state into phrases and suppresses healthy regional injury rows.

Current development language includes hunger, thirst, fatigue, urinary/bowel pressure and hygiene perception. Exact fluid, calorie, bladder-volume and sleep-pressure numbers are not normal player-facing output. Serving forecasts likewise describe likely relevance to hunger/thirst without printing hidden ml/kcal quantities.

`BiologyPresentation.reds` composes that need projection with active regional conditions and perceptible pain/analgesia effects. It also produces only qualitative action relevance (`showEat`, `showDrink`) rather than exposing the underlying meter values to the UI.

## Native Biology surfaces

`BiologyNativeUI.reds` is the owned native seam.

### Ordinary hub context

A **BIOLOGY** entry opens the Biology panel and shows current body sensations, meaningful effects and active conditions. Selecting a condition shows its qualitative state, function, pain/cause explanation, field-care guidance and professional-care guidance.

Applicable dressing/support actions enter the existing interruptible field-care runtime. The action remains queued while a menu is open; once the player closes menus it progresses only while the runtime's safety/movement/hands checks continue to pass.

### Ripperdoc context

The vanilla Cyberware screen remains an equipment screen. In actual `CyberwareScreenType.Ripperdoc` context, a separate **BIOLOGY** professional-care entry exposes the same active-condition language and only the clinical/mechanical actions the respective models currently consider useful.

This is intentionally not a `CYBERWARE | CONDITION` mode. It gives a professional provider a Biology doorway without making Cyberware the owner of body state.

## Communicating urgency outside Biology

Biology is the place the player may deliberately inspect their body; it should not become the only place the body exists.

Existing injury/pain mechanics already communicate substantial states through impairment, bleeding consequences, native weapon handling changes and analgesic-disorientation visuals. For hunger/thirst/elimination/fatigue specifically, additional non-menu cue mapping remains a **live calibration question**, not an unimplemented architectural dependency: do not invent audiovisual effects merely to make hidden values noticeable.

## Conditions and injury detail

Condition detail inside Biology includes region and condition type, approximate severity/current state, likely cause/protection context when provenance supports it, biological vs cybernetic damage, external vs internal bleeding, pain and functional consequences actually applied, plausible field care, and professional biological or mechanical care where context permits.

Normal presentation does not expose raw injury percentages, exact bleed rates, analgesic load or native HP.

## Cyberware boundary

Cyberware retains its vanilla equipment purpose. `ConditionNativeUI.reds` has been removed from production source. No `CYBERWARE | CONDITION` switch is part of the owned candidate.

The ripperdoc Biology doorway is a contextual care surface only; it does not replace/dim Cyberware slots or take over the Cyberware navigation model.

## Current implementation status

Implemented in source/design:

1. Canonical goals ledger makes Biology the body-interface owner and supersedes `CYBERWARE | CONDITION`.
2. Realpass body-status presentation is qualitative rather than raw-number body telemetry.
3. Healthy regional injury rows are suppressed from the general body summary.
4. Normal serving forecast text no longer exposes ml/kcal quantities.
5. Dark Future Backpack migration patches no longer inject RealPass body status, field-care widgets or body-meter food previews.
6. Time-skip body forecasting remains intact because it is simulation correctness rather than Backpack presentation.
7. `BiologyPresentation.reds` provides a realpass-owned qualitative view model over current needs, effects and active conditions.
8. `BiologyNativeUI.reds` mounts the ordinary Biology panel on the native hub.
9. `Eat…` / `Drink…` enumerate actual carried items and invoke the stock consumable action instead of maintaining duplicate inventory state.
10. Active conditions are selectable in Biology and use existing realpass condition/provenance projection.
11. Field-care actions originate in Biology and still commit through the shared field-care/body runtime.
12. Ripperdoc context exposes model-approved clinical/mechanical care through a Biology professional-care panel.
13. The old Cyberware-mounted Condition native prototype is removed from production source.

Still pending **acceptance/calibration**, not architecture:

1. Exact-compile the completed owned source candidate against the installed Cyberpunk 2077 2.31 scripts/framework environment.
2. Deploy the exact compiled candidate with the flat owned-file installer and verify installed hashes/source-mod residue checks.
3. Attend one broad live session to verify Biology layout/input, actual item use/animation, field-care menu boundary, ripperdoc context, body/combat/injury/pain/save/reload/time progression and ordinary quest/Phantom Liberty compatibility.
4. Calibrate spacing/typography and any additional need-state embodied cues only from that live evidence.

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
11. Important body state is also communicated by existing justified gameplay consequences where those consequences exist; no permanent needs meter is introduced to compensate for missing calibration.
12. No Dark Future/Project E3 executing UI/runtime is required by the release implementation.
13. Save/reload and time progression preserve the single shared physiological body.
