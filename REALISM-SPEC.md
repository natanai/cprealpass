# realpass specification

## Product definition

realpass is one coherent realism pass for Cyberpunk 2077 + Phantom Liberty. It should feel like one mod rather than a stack of unrelated overhauls. Every subsystem must represent a physical, physiological, or presentation-level part of the same world model, and every nonessential subsystem must be independently toggleable without breaking the rest.

The target is not "hardcore mode" and not a general rebalance. The target is plausible cause and effect: bodies need food, water, sleep and recovery; exertion has consequences; bullets interact with clothing, armor, cyberware and tissue; injuries impair and can require treatment; presentation removes unnecessary gamey abstraction where doing so remains usable.

## Scope boundary

### In scope

- Basic needs and physiology: nutrition, hydration, sleep/fatigue, exertion, recovery, delayed elimination, and hygiene only where it can be represented without constant busywork.
- Injury and treatment: regional injury, blood loss, impairment, stabilization, treatment and recovery.
- Realistic combat: projectile/ammunition behavior, hit region, penetration, armor coverage, cybernetic structure, tissue injury, incapacitation and death.
- Clothing and armor as physical equipment. Ordinary clothing is clothing; ballistic protection comes from actual protective equipment and only where that protection is present.
- Cyberware where it changes a relevant physical or biological subsystem.
- Sparse presentation changes that support the realism model, including the selected E3-inspired HUD treatment, readable NPC identity and removal of unnecessary RPG clutter.

### Explicitly not part of the realism pass

- Weather simulation or weather control.
- Economy overhauls, arbitrary scarcity systems, price rebalancing or unrelated inventory difficulty.
- Added random encounters, travel restrictions, summon currencies or other difficulty-for-difficulty's-sake systems.
- A new outfit/transmog/wardrobe mechanic. realpass does not treat "outfit" as a separate simulation layer: clothing is clothing and armor is armor. Appearance-only systems supplied by the base game are not an authority that realpass should expand into.
- Features inherited from source mods merely because they exist. If a source feature does not serve the realpass physical model, it should be omitted rather than exposed as another setting.

A feature is not justified by making it toggleable. Toggleability is required for included modules; it is not a reason to retain out-of-scope features.

## Module rule

The distributed result should have one realpass structure and one settings surface. Internally, major authorities should remain separable so they can be enabled, disabled, tested and removed without overlapping ownership:

1. **Needs / body** — food, water, sleep, exertion, elimination and recovery.
2. **Injury** — regional injury, bleeding, impairment, stabilization and healing.
3. **Ballistics / combat** — weapon, ammunition, penetration, hit-region and terminal-effect rules.
4. **Armor / clothing** — physical coverage, protection and wear; no generic clothing armor.
5. **Cyberware physiology** — only physical/biological consequences relevant to the above systems.
6. **Presentation** — HUD, nameplates, inspection/status surfaces and removal of gamey clutter.
7. **Diagnostics** — development-only observability, off in normal play.

Each gameplay module needs a master enable/disable control. Finer controls are appropriate only where they correspond to a real separable subsystem, not as a way to preserve inherited feature sprawl.

## Simulation principles

1. Relative biological timing matters more than survival-meter pressure.
2. State changes must form causal chains: intake → absorption → body state → delayed waste; exertion → heat and resource use; wake time → fatigue → sleep debt and recovery; injury → impairment → treatment → recovery.
3. Exact values may exist internally, but normal play should communicate state mainly through animation, audio, movement, stamina, contextual effects, and subtle HUD cues.
4. Cyberware modifies the relevant biological or structural subsystem; it is not a generic stat bonus.
5. Player and NPC physical rules should be as symmetrical as the engine permits.
6. Prefer one authoritative model per phenomenon. Imported systems must be reduced or adapted rather than stacked when they compete for the same authority.

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
- Avoid stacked damage, armor, or injury overhauls unless overlap is explicitly disabled or patched.

## Presentation

Use **realpass** as the mod's in-game display name, retaining dependency author credits and stable internal save identities. Preserve authored weather while completing presentation, physiology and combat.

- Make E3-era HUD/UI presentation part of the default build where it does not replace superior modern game functionality; retain readable names above NPCs when appropriate.
- Remove unnecessary floating numbers and RPG clutter.
- Do not expose every need as a permanent percentage dashboard.
- Exact diagnostic state belongs in a status/inspection surface, not the primary play HUD.
- Presentation is subordinate to simulation: a visual feature should not become a second gameplay system.

## Acceptance questions for every mechanic

- What real or internally plausible process is represented?
- Does its timescale remain credible relative to other systems?
- Does it duplicate an existing authority?
- Does it create arbitrary punishment without a physical rationale?
- Is it actually in scope, or merely inherited from a dependency?
- Can the feature be tuned, disabled, tested, and safely removed?
- Does disabling it leave the rest of realpass coherent?
- Does it preserve Phantom Liberty quest integrity and acceptable script latency?
