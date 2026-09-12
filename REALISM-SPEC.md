# realpass specification

## Simulation principles

1. Relative biological timing matters more than survival-meter pressure.
2. State changes must form causal chains: intake → absorption → body state → delayed waste; exertion → heat and resource use; wake time → fatigue → sleep debt and recovery; injury → impairment → treatment → recovery.
3. Exact values may exist internally, but normal play should communicate state mainly through animation, audio, movement, stamina, contextual effects, and subtle HUD cues.
4. Cyberware modifies the relevant biological or structural subsystem; it is not a generic stat bonus.
5. Player and NPC physical rules should be as symmetrical as the engine permits.

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
- Avoid stacked damage, armor, or injury overhauls unless overlap is explicitly disabled or patched.

## Presentation

Use **realpass** as the mod's in-game display name, retaining dependency author credits and stable internal save identities. Weather control is not a priority or release requirement; preserve authored weather while completing presentation, physiology and combat.

- Make E3-era HUD/UI presentation part of the default build, including names above NPCs when looking at them. Verify the selected release implements the requested focus behavior.
- Remove unnecessary floating numbers and RPG clutter.
- Do not expose every need as a permanent percentage dashboard.
- Exact diagnostic state belongs in a status/inspection surface, not the primary play HUD.

## Acceptance questions for every mechanic

- What real or internally plausible process is represented?
- Does its timescale remain credible relative to other systems?
- Does it duplicate an existing authority?
- Does it create arbitrary punishment without a physical rationale?
- Can the feature be tuned, disabled, tested, and safely removed?
- Does it preserve Phantom Liberty quest integrity and acceptable script latency?

