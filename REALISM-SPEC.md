# realpass specification

## Product definition

realpass is one coherent realism pass for Cyberpunk 2077 + Phantom Liberty. It is not a curated stack, a compatibility preset, or a reskin of other gameplay/presentation mods. The gameplay and presentation behavior that defines realpass must be authored in this repository and owned by realpass. Other mods may be studied as references and may have informed design questions, but their gameplay scripts, archives, assets and runtime state are not part of the finished product.

The target is not "hardcore mode" and not a general rebalance. The target is plausible cause and effect: bodies need food, water, sleep and recovery; exertion has consequences; bullets interact with clothing, armor, cyberware and tissue; injuries impair and can require treatment; presentation removes unnecessary gamey abstraction where doing so remains usable.

### One authored experience

Development remains modular because isolated gates make calibration, fault-finding and regression testing possible. **The released mod is not modular from the player's perspective.** A normal release enables the complete accepted realpass experience as one authored balance. There is no public menu for disabling combat, needs, injury, armor or other core authorities and no collection of balance sliders that lets two realpass players effectively run different games.

Development-only gates and diagnostics may temporarily isolate a subsystem. They are build/test controls, not player preferences. Accessibility options are considered separately only when they do not change simulation authority or balance. Traditional actor health bars are intentionally not part of the authored realpass presentation.

## Runtime ownership rule

Gameplay and presentation runtime code must be project-original realpass code. Generic modding frameworks may remain when they provide only infrastructure such as script loading, data loading, UI primitives or input plumbing. A framework must not own realpass gameplay policy or simulation state.

Dark Future and Project E3 HUD are reference/inspiration sources only for the finished architecture. They may remain represented in provenance, historical recipes and research notes, but an owned-runtime test or release build must fail closed if it contains their scripts, archives, assets, tweak payloads or persistent-system dependencies.

This ownership rule is stricter than licensing. Code being legally adaptable does not make it appropriate to use as realpass runtime code.

## Vanilla-first replacement rule

realpass should alter the **minimum necessary layer** of the vanilla game. Keep CDPR's existing names, item identities, animations, screens, assets and interaction structures whenever they can host the realism model cleanly. Replace the mechanic underneath them instead of inventing a parallel branded ecosystem.

Examples:

- MaxDoc stays MaxDoc; realpass changes what its inhaler does rather than renaming another item into a "Trauma Kit".
- Bounce Back stays Bounce Back and Health Booster stays Health Booster; their realistic roles are authored separately rather than aliased together.
- The stock Cyberware/body screen remains the shell for Condition inspection/treatment instead of shipping a separate medical menu where the vanilla shell already provides the right body/zoom language.
- The native modern scanner remains authoritative instead of restoring a reference mod's scanner replacement.

This rule is both a product goal and a stability strategy. Prefer semantic hooks at stable native action/controller boundaries feeding realpass-owned models. Avoid full resource replacements, duplicated vanilla state and variant-by-variant patches unless the vanilla surface cannot support the accepted behavior.

## Scope boundary

### In scope

- Basic needs and physiology: nutrition, hydration, sleep/fatigue, exertion, recovery, delayed elimination, and hygiene only where it can be represented without constant busywork.
- Injury and treatment: regional injury, blood loss, impairment, stabilization, treatment and recovery.
- Realistic combat: projectile/ammunition behavior, hit region, penetration, armor coverage, cybernetic structure, tissue injury, incapacitation and death.
- Clothing and armor as physical equipment. Ordinary clothing is clothing; ballistic protection comes from actual protective equipment and only where that protection is present.
- Cyberware where it changes a relevant physical or biological subsystem.
- Sparse presentation changes that support the realism model, including a realpass-owned HUD/nameplate treatment, readable NPC identity and removal of unnecessary RPG clutter.

### Explicitly not part of the realism pass

- Weather simulation or weather control.
- Economy overhauls, arbitrary scarcity systems, price rebalancing or unrelated inventory difficulty.
- Added random encounters, travel restrictions, summon currencies or other difficulty-for-difficulty's-sake systems.
- A new outfit/transmog/wardrobe mechanic. realpass does not treat "outfit" as a separate simulation layer: clothing is clothing and armor is armor. Appearance-only systems supplied by the base game are not an authority that realpass should expand into.
- Features inherited from source/reference mods merely because they exist.
- A public subsystem-toggle menu whose purpose is to let players opt out of core realpass simulation.

A mechanic belongs only if it serves the single physical model. Development modularity is a validation technique, not a justification for shipping optional feature sprawl.

## Internal authority boundaries

The implementation keeps clear internal authorities so they can be independently tested and repaired during development:

1. **Needs / body** — food, water, sleep, exertion, elimination and recovery.
2. **Injury** — regional injury, bleeding, impairment, stabilization and healing.
3. **Ballistics / combat** — weapon, ammunition, penetration, hit-region and terminal-effect rules.
4. **Armor / clothing** — physical coverage, protection and wear; no generic clothing armor.
5. **Cyberware physiology** — only physical/biological consequences relevant to the above systems.
6. **Presentation** — HUD, nameplates, inspection/status surfaces and removal of gamey clutter.
7. **Diagnostics** — development-only observability, off in normal play.

Each phenomenon has one authority. Internal development gates must leave clean state when disabled, but final release configuration enables the accepted gameplay/presentation authorities together.

## Simulation principles

1. Relative biological timing matters more than survival-meter pressure.
2. State changes must form causal chains: intake → absorption → body state → delayed waste; exertion → heat and resource use; wake time → fatigue → sleep debt and recovery; injury → impairment → treatment → recovery.
3. Exact values may exist internally, but normal play should communicate state mainly through animation, audio, movement, stamina, contextual effects, and subtle HUD cues.
4. Cyberware modifies the relevant biological or structural subsystem; it is not a generic stat bonus.
5. Player and NPC physical rules should be as symmetrical as the engine permits.
6. Prefer one authoritative model per phenomenon. Reference mods may inform questions and edge cases but never remain a hidden second authority.
7. Prefer direct native game signals and thin realpass adapters over broad gameplay-mod hosts.
8. Prefer preserving vanilla identity and replacing behavior under it over renaming/rebuilding a parallel item/UI ecosystem.

## Human timescale guardrails

- No starvation over a handful of in-world hours.
- No dangerous dehydration after ordinary short activity.
- Bladder filling follows fluid absorption with delay and baseline production.
- Digestion and bowel state are not one-to-one reactions to individual food items.
- Sleep need follows time awake, exertion, stimulants, injury, prior sleep, and accumulated debt.
- Hygiene and elimination systems are rejected if their best achievable implementation is constant busywork.

Numeric calibration is intentionally deferred until the selected time-scale authority and needs implementation are measured in game. Every chosen multiplier must be recorded with its real-time and in-world-time interpretation.

## Combat model

Target pipeline:

`weapon → projectile/ammunition → impact region → clothing/material → ballistic armor → cybernetic structure → tissue injury → physiological consequence`

Required qualities:

- Minimize level-based damage scaling and health inflation.
- Unarmored head and center-mass rifle hits are normally catastrophic or immediately incapacitating.
- Weapon categories differ by projectile behavior, controllability, capacity, and terminal effect—not only DPS.
- Protection applies where protective equipment is actually present.
- Ordinary clothing supplies negligible ballistic protection.
- Armor has projectile-dependent penetration limits and preferably degradation.
- Unprotected limbs remain vulnerable; injury affects locomotion or weapon use where feasible.
- Getting shot must resolve through the physical pipeline rather than through a generic damage sponge whenever the engine permits.
- Avoid stacked damage, armor, or injury overhauls; realpass is the sole authority for the phenomena it owns.

## Presentation

Use **realpass** as the mod's in-game display name. Preserve authored weather while completing presentation, physiology and combat.

- Recreate only the selected E3-era ideas we actually want with realpass-owned code/assets; do not depend on Project E3 HUD at runtime.
- Keep superior modern game functionality such as the modern scanner/quickhack flow.
- Retain readable names above NPCs when appropriate using a realpass-owned implementation.
- Remove traditional actor health bars, unnecessary floating numbers and RPG clutter.
- Do not expose every need as a permanent percentage dashboard.
- Exact diagnostic state belongs in a development/status inspection surface, not the primary play HUD.
- Presentation is subordinate to simulation: a visual feature should not become a second gameplay system.

## Acceptance questions for every mechanic

- What real or internally plausible process is represented?
- Does its timescale remain credible relative to other systems?
- Does it duplicate an existing authority?
- Does it create arbitrary punishment without a physical rationale?
- Is it actually in scope, or merely inherited from a reference mod?
- Is the executing implementation physically ours in the repository?
- Does it preserve the vanilla identity/surface where that surface remains useful?
- Can it be isolated internally for testing without becoming a public gameplay option?
- Does the final locked configuration preserve Phantom Liberty quest integrity and acceptable script latency?
