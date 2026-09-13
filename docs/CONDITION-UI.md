# realpass Condition interface

Status: canonical injury/personal-condition UX design; first owned native slice implemented, native acceptance pending
Last updated: 2026-09-13
Governing goals: `AGREED-GOALS.md` G-040 through G-057

## Product intent

The final realpass injury interface lives inside Cyberpunk's existing Cyberware/body screen. The stock body visualization and paper-doll zoom/drill-down language are the shell; realpass owns all new condition state, condition cards, explanatory text and treatment behavior.

The current backpack `FIELD CARE` popup is a development prototype. It is not the intended final navigation path and is excluded from the owned acceptance runtime; Condition mode is replacing it.

## Current implementation status

The first project-original native slice exists in `ConditionNativeUI.reds`. It dynamically mounts a `CYBERWARE | CONDITION` switch and qualitative condition panel on the stock `RipperDocGameController`, lists active conditions only, maps the six realpass body regions onto stock anatomical areas, and calls the stock `DollHover`/`DollSelect` selection path instead of introducing a custom camera system.

`ConditionPresentation.reds` is the read-only projection from authoritative regional injury state plus bounded provenance. The UI has no native-HP dependency and does not mutate injuries directly.

Ordinary inventory/Cyberware context exposes model-approved **dressing** and **limb support**. They begin through the timed field-care runtime: the menu must be closed, the player must remain stationary/out of combat with hands available, and interruption cancels the action. Trauma Kits are no longer wound-care currency.

Ripperdoc context exposes distinct professional actions when the model says they can help:

- **Clinical care** controls external/internal bleeding and establishes professional biological aftercare. It does not directly erase tissue/bone trauma or replace lost blood; subsequent biological recovery still occurs through the shared body clock.
- **Cyberware repair** reduces structural chrome damage only. It does not treat biological tissue, bone or blood loss.

`ProfessionalCareModel.reds` owns professional-care eligibility and deliberately does not own pricing/economy. The first acceptance slice treats the click as completion of an appropriate professional service; service price/time presentation can be calibrated later without making realpass an economy overhaul.

The first project-original pain slice now also exists. `PainModel.reds` derives physical pain from biological regional injury, models diminishing Trauma Kit analgesia and an overuse/intoxication envelope, and derives pain-only weapon-handling factors. `PainRuntime.reds` persists analgesic state while synchronizing decay to `CRBodyRuntime` elapsed body time rather than creating another timer. `PainNativeEffects.reds` projects perceived pain into native weapon sway/spread/recoil and reuses CDPR's existing fullscreen drunk effect loops for excessive overlapping analgesia without applying the stock alcohol status effect.

This code is **not yet native-accepted**. Cloud/offline tests can verify authority boundaries and pure treatment/pain behavior, but exact stock-controller hook signatures, dynamic Ink layout, paper-doll behavior, item interception, native drunk loops, weapon sway and installed-game interactions must pass the user's local 2.31 compile/preflight and attended test before this interface is considered working in Cyberpunk.

## Two modes

The body screen has a conceptual mode switch:

`CYBERWARE | CONDITION`

### Cyberware

Preserve vanilla behavior as closely as practical. Installed cyberware slots, equipment flow, stock paper-doll zoom and ripperdoc behavior remain CDPR's responsibility.

### Condition

realpass takes over only the condition layer:

- installed-cyberware cards/minigrids are hidden or visually deprioritized for the Condition view;
- the central stock body remains visible;
- active realpass conditions appear as selectable entries associated with relevant anatomy;
- healthy regions remain visually quiet rather than filling the screen with `OK` cards;
- selecting a condition uses the stock regional paper-doll zoom/drill-down where available;
- the zoomed/detail view becomes the place to understand and tend the selected condition.

The current first slice overlays its realpass panel rather than fully suppressing/dimming every vanilla cyberware minigrid. That visual handoff is intentionally left for native acceptance/calibration rather than making a broad resource replacement before the stock-controller integration is proven.

## Patch-resilience rule

Prefer dynamic realpass widgets attached to the stock controller/root/anchors over replacing whole `.inkwidget` resources. If a future game patch moves an anchor, the adapter should be fixable without changing the injury, pain or treatment models.

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

- `LEFT ARM — Ballistic trauma`
- `TORSO — Blunt trauma`
- `HEAD — Concussive trauma`
- `RIGHT LEG — Cyberware structural damage`

Healthy regions remain visually quiet. Multiple recent causes may be explained when useful, but current regional physical state remains authoritative.

## Regional zoom mapping

Use CDPR's existing regional zooms wherever possible. The first source slice maps head→Frontal Cortex, torso→Integumentary System, either arm→Arms and either leg→Legs solely to drive stock selection language. Left/right identity remains in realpass condition state and text.

If vanilla has one `Arms` or `Legs` zoom rather than distinct left/right camera states, realpass keeps left/right conditions separate inside that shared zoom instead of inventing fragile custom camera assets.

## Detail-view hierarchy

The selected condition should communicate, in approximately this order:

1. **Condition / region** — penetrating trauma, blunt trauma, cyberware structural damage, etc.
2. **When / likely cause** — approximate time, projectile/impact family, protection encountered/defeated when useful, using bounded provenance rather than exact energy numbers.
3. **Current condition** — qualitative tissue/bone/external bleed/internal bleed/chrome/function state.
4. **Pain / analgesia** — qualitative pain, whether analgesia is active, and disorientation warning when overused.
5. **Functional consequences** — only effects realpass is actually applying.
6. **Field treatment** — only plausible applicable actions and required supplies.
7. **Professional care** — what requires clinical or mechanical service.

Normal presentation should not expose raw injury percentages, blood-rate numbers, analgesic load or a pain meter.

## Pain and Trauma Kits

Pain is an embodied consequence, not another HP pool. Biological tissue/bone injury produces pain; chrome-only structural damage does not automatically create nociceptive pain unless surrounding biology is also hurt.

A **Trauma Kit is analgesia only**. It may reduce perceived pain and therefore reduce pain-derived aim/weapon instability, but it does not change:

- tissue damage;
- bone damage or support state;
- external/internal bleeding;
- blood deficit;
- cyberware damage;
- structural impairment from an injured limb;
- native HP.

Repeated overlapping Trauma Kit use has diminishing pain relief. Excess concurrent analgesic load enters an intoxication/disorientation envelope. The native adapter reuses Cyberpunk's own `status_drunk_level_1/2/3` fullscreen effect loops and associated fullscreen audio parameter rather than applying `BaseStatusEffect.Drunk`, because the stock alcohol status carries unrelated weapon/gameplay packages.

Significant perceived pain is intended to make weapon handling visibly less stable through weapon sway plus restrained spread/recoil effects. Analgesia reduces this **pain-derived** component; a fractured/damaged arm's separate structural penalties remain.

Existing V pain/grunt vocalizations are a desired contextual cue but remain pending exact native event identification and throttling. Do not guess/spam audio events.

## Field treatment and supplies

Field treatment uses separate physical supplies from Trauma Kits.

Current development mapping:

- `APPLY DRESSING — Medical Gauze x1 — 8 sec` (`Items.GenericJunkItem4`, stock Medical Gauze);
- `SUPPORT LIMB — support material x1 — 12 sec` (`Items.CommonMaterial1` as the current provisional rigid-support supply).

The support-material presentation may be replaced with a clearer realpass-owned item/data mapping before release. The architectural requirement is fixed: **neither action consumes Trauma Kits**.

Field actions remain subject to context rules: out of combat, hands available, stationary, menu closed during progression, valid current body state and available supply. The Condition UI initiates care; the timed action/body runtime performs validation, inventory transaction and authoritative commit.

## Professional care

When the selected condition exceeds field treatment, say so clearly. In accepted ripperdoc context, model-approved `CLINICAL CARE` and `REPAIR CYBERWARE` controls are exposed.

Clinical care and mechanical repair are separate by design:

- clinical care can control biological bleeding and establish aftercare, but tissue/bone recovery still takes body time and prior lost blood is not magically replaced;
- mechanical repair addresses chrome damage only and does not treat biology.

Professional economics are not an authority in this milestone. A later accepted native service cost/time may be added without becoming an economy overhaul or altering treatment semantics.

## Injury provenance

`InjuryProvenance.reds` stores a bounded recent explanatory ledger. It records accepted player-wound context such as game time, region/material, projectile family, distance/ricochet, protection encountered/unresolved mapping and wound result fields.

Provenance failure must never veto an accepted wound. It explains how the current state arose; it does not own healing or treatment.

## Pain-state contract

`PainModel.reds` owns the authored relationship between physical biological injury, perceived pain, diminishing analgesia, intoxication and pain-derived weapon factors.

`PainRuntime.reds` persists analgesic state but derives decay from `CRBodyRuntime`'s elapsed body time. It has no independent `DelaySystem`/polling clock.

The native presentation/handling adapter may apply owned weapon modifiers and CDPR visual effect loops, but must not mutate physical injury or HP.

## Acceptance criteria

Condition/injury/pain UX is not accepted until all of the following are demonstrated in the installed game:

1. Cyberware mode still performs its normal vanilla role.
2. Condition mode enters/exits without corrupting cyberware-screen state.
3. Healthy V does not get a wall of empty condition cards.
4. A real accepted injury produces the correct regional condition entry.
5. Selecting head/torso/arm/leg uses the intended stock zoom or documented safe fallback.
6. Left/right remain distinguishable within grouped Arms/Legs zooms.
7. Detail text comes from authoritative injury state/provenance, not native HP.
8. External/internal bleeding and biological/chrome damage remain distinct.
9. Field actions appear only when useful and still validate at commit time.
10. Dressing consumes Medical Gauze; support consumes its support supply; neither consumes Trauma Kits.
11. Trauma Kit consumption removes the vanilla Health Booster effect and changes realpass analgesia only.
12. Analgesia produces diminishing returns and cannot erase all physical pain while the injury persists.
13. Excess overlapping Trauma Kits reach the authored native drunk visual envelope without inheriting stock alcohol gameplay packages.
14. Meaningful pain creates visible weapon/aim instability; analgesia reduces only the pain component, not structural impairment.
15. Clinical/mechanical actions are ordinary-context unavailable and ripperdoc-context available only when their respective models can help.
16. Clinical care does not instantly heal tissue/bone/replace blood; mechanical repair does not heal biology.
17. The backpack Field Care prototype remains absent from the owned runtime.
18. No Dark Future/Project E3 runtime content is required.
19. Save/reload preserves regional injury, analgesic state and bounded explanatory history.
20. V pain vocalizations, if enabled, are contextually correct and rate-limited rather than spammed.

## Implementation status / next order

1. Six-region injury authority — **implemented/model-tested**.
2. Bounded accepted-wound provenance — **implemented/offline-tested**.
3. Qualitative condition descriptors — **implemented/offline-tested**.
4. Native Condition toggle/list on stock controller — **implemented in source; native acceptance pending**.
5. Stock paper-doll zoom reuse — **implemented in source; native acceptance pending**.
6. Field-care initiation/timing — **implemented/offline-tested; native acceptance pending**.
7. Distinct professional clinical/mechanical care — **implemented/model-tested; native acceptance pending**.
8. Trauma Kit pain-only model, diminishing returns and overuse envelope — **implemented/model-tested; native acceptance pending**.
9. Trauma Kit native Health Booster interception — **implemented in source; native exact compile/gameplay pending**.
10. Pain-derived native sway/spread/recoil and drunk visual loops — **implemented in source; native exact compile/gameplay pending**.
11. Separate wound-care supplies — **implemented in development mapping; native inventory/UI acceptance pending**.
12. V pain/grunt cue mapping/throttling — **research/implementation pending**.
13. Final Condition visual polish/minigrid suppression — **native calibration pending**.
14. Exact-compile and attended-test the owned runtime before release polish — **next local gate**.
