# realpass modular architecture

## Goal

Ship one coherent realism mod, not a bundle of separately branded feature mods. Source projects may be used as references or dependencies during development, but retained behavior should be adapted into a realpass-owned module boundary wherever licensing and technical constraints permit.

A module exists because it owns a distinct physical phenomenon. A setting does not exist merely because an upstream mod exposed one.

## Runtime module map

### Body / needs

Owns nutrition, hydration, wake time, fatigue, exertion, recovery, digestion/elimination and the minimum hygiene interactions that survive the busywork test.

Master switch: `body.enabled`

Suggested subordinate switches: `nutrition`, `hydration`, `sleep`, `exertion`, `elimination`, `hygiene`.

### Injury

Owns wound state, regional impairment, blood loss, stabilization, treatment and recovery.

Master switch: `injury.enabled`

This module consumes impacts produced by combat. When disabled, combat must fall back safely rather than leaving half-active bleeding or impairment state.

### Ballistics / combat

Owns weapon/projectile profiles, ammunition, hit region, penetration and terminal-effect decisions. It should output a physical impact result rather than a second independent damage model.

Master switch: `combat.enabled`

This module should minimize or bypass level-driven health inflation where technically safe while preserving authored exceptions.

### Armor / clothing

Owns physical protective coverage and armor wear. Normal clothing contributes no meaningful ballistic protection unless a specific item is actually protective by construction.

Master switch: `armor.enabled`

There is no realpass outfit module. realpass should not add a separate wardrobe/transmog simulation layer.

### Cyberware physiology

Owns only cyberware consequences that alter physical protection, biological demand, structural damage, treatment or recovery.

Master switch: `cyberwarePhysiology.enabled`

It must not become a generic cyberware rebalance.

### Presentation

Owns HUD/nameplate/status presentation required to communicate the above systems cleanly. It may preserve selected E3 presentation while allowing superior modern scanner functionality to remain native.

Master switch: `presentation.enabled`

Presentation should never become an alternate gameplay authority.

### Diagnostics

Owns debug/status visibility needed for calibration and testing.

Master switch: `diagnostics.enabled`

Default: off.

## Configuration principles

- One realpass settings surface.
- One master toggle per major module.
- Sub-toggles only for genuinely separable processes.
- Disabling a module must not leave persistent penalties, orphaned listeners, incompatible save state or hidden dependencies on an unrelated module.
- Defaults should describe the intended realpass experience, not upstream defaults.
- Upstream configuration should be treated as migration/input data, not as the public product structure.
- Development diagnostics are not player-facing gameplay features.

## Dependency direction

Preferred one-way flow:

`clock/lifecycle → body state`

`weapon/ammunition → impact → armor/cyberware → tissue injury → blood loss/impairment → treatment/recovery`

`body + injury + equipment state → presentation`

Presentation must not write simulation state. Economy, weather, travel restrictions and outfit systems should have no dependency edges because they are outside scope.

## Consolidation test for imported features

For every feature inherited from a source mod:

1. Name the physical phenomenon it represents.
2. Identify the realpass module that should own that phenomenon.
3. If no in-scope module owns it, remove it from the realpass build.
4. If another module already owns it, adapt or disable the duplicate.
5. If it remains, expose only the minimum controls needed to tune or disable the real phenomenon.
6. Verify that the source feature can be removed from packaging without silently removing unrelated realpass behavior.

## Clothing and armor rule

The simulation should distinguish appearance from protection by physical equipment rather than by an abstract outfit slot. Clothing can affect appearance and, where appropriate later, physical properties such as coverage or insulation; ballistic armor protects according to actual protective construction and coverage. No generic outfit bonus, transmog armor authority or arbitrary clothing armor value belongs in the realism model.

## Combat acceptance target

A gunshot should be explainable as a causal chain: what projectile struck, where it struck, what material/protection it encountered, whether it penetrated, what tissue or cybernetic structure was affected, what immediate impairment resulted, whether bleeding or other physiological consequences follow, and what treatment can change the outcome.

If the result is primarily explained by the target's level, a large generic health pool or stacked percentage bonuses, the realism pass has not yet reached its target.
