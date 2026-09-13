# realpass internal modular architecture

## Goal

Ship one coherent realism mod with one authored balance. The internal code remains modular so individual authorities can be isolated, calibrated and regression-tested during development, but that modularity is **not** the final player product. A release build enables the accepted realpass systems together.

Gameplay and presentation implementations are realpass-owned. Dark Future, Project E3 HUD and other gameplay/presentation mods are reference material only; their runtime scripts/assets/state are forbidden from an owned-runtime candidate. Generic frameworks may remain only as plumbing when realpass genuinely needs their APIs.

## Internal authority map

### Body / needs

Owns nutrition, hydration, wake time, fatigue, exertion, recovery, digestion/elimination and the minimum hygiene interactions that survive the busywork test.

Development gate: `body`.

Internal facets such as nutrition, hydration, sleep, exertion, elimination and hygiene may be isolated in tests, but are not final player-facing switches.

### Injury

Owns wound state, regional impairment, blood loss, stabilization, treatment and recovery.

Development gate: `injury`.

It consumes impacts produced by combat. Development builds may isolate injury to diagnose failures; a release build does not offer an injury-off mode.

### Ballistics / combat

Owns weapon/projectile profiles, ammunition, hit region, penetration and terminal-effect decisions. It outputs a physical impact result rather than a second independent RPG damage model.

Development gate: `combat`.

The release minimizes or bypasses level-driven health inflation where technically safe while preserving authored exceptions needed for quest integrity.

### Armor / clothing

Owns physical protective coverage and armor wear. Normal clothing contributes no meaningful ballistic protection unless a specific item is actually protective by construction.

Development gate: `armor`.

There is no realpass outfit module and no player switch that changes clothing into an abstract armor system.

### Cyberware physiology

Owns only cyberware consequences that alter physical protection, biological demand, structural damage, treatment or recovery.

Development gate: `cyberwarePhysiology`.

It must not become a generic cyberware rebalance.

### Presentation

Owns realpass HUD/nameplate/status behavior required to communicate the physical model. The modern native scanner remains authoritative where it is superior; selected E3-era ideas must be recreated with realpass-owned implementation rather than imported E3 runtime content.

Development gate: `presentation`.

The authored release removes traditional actor health bars and unnecessary RPG clutter. Presentation never owns simulation state.

### Diagnostics

Owns finite observability needed for calibration and testing.

Development gate: `diagnostics`.

Always off in a normal release.

## Release configuration

The final configuration is deliberately simple:

- accepted body authority: on;
- accepted injury authority: on;
- accepted combat authority: on;
- accepted armor authority: on;
- accepted cyberware-physiology authority: on where implemented;
- accepted presentation authority: on;
- diagnostics: off;
- traditional actor health bars: off.

There is no normal player-facing subsystem enable/disable menu and no balance-slider matrix. Two players using the same realpass version should be playing the same authored simulation.

Internal gates remain valuable because they let a developer answer “which authority caused this?” without deleting code or changing the public product definition. Build/test tooling may expose those gates explicitly; release tooling must lock them to the accepted profile.

## Runtime ownership

Owned-runtime code follows this hierarchy:

`Cyberpunk native game APIs → thin realpass adapter → realpass model/state → realpass presentation`

Not:

`Cyberpunk → another gameplay mod → realpass bridge → another mod's UI/state`.

A generic framework such as redscript/RED4ext/Codeware may appear below a thin adapter only when it supplies infrastructure rather than gameplay policy. Every such dependency must be justified independently and removed if no accepted realpass runtime file needs it.

## Dependency direction

Preferred one-way flow:

`native clock/lifecycle/input → body state`

`native weapon/ammunition/equipment signals → impact → armor/cyberware → tissue injury → blood loss/impairment → treatment/recovery`

`body + injury + equipment state → realpass presentation`

Presentation must not write simulation state. Economy, weather, travel restrictions and outfit systems have no dependency edges because they are outside scope.

## Reference-mod rule

For every useful idea observed in another mod:

1. Name the physical or presentation problem the idea helps expose.
2. Re-derive the behavior from native game signals and the realpass model.
3. Implement the chosen behavior in realpass-owned source/data.
4. Keep attribution/research notes where relevant, but do not make the reference mod a hidden runtime host.
5. Prove an owned-runtime deployment contains no reference-mod scripts, archives, tweak payloads or required save state.

“Adapted enough to look like realpass” is not the target. The executing implementation itself must belong to realpass.

## Clothing and armor rule

The simulation distinguishes appearance from protection by physical equipment rather than by an abstract outfit slot. Clothing can affect appearance and, where appropriate later, physical properties such as coverage or insulation; ballistic armor protects according to actual protective construction and coverage. No generic outfit bonus, transmog armor authority or arbitrary clothing armor value belongs in the realism model.

## Combat acceptance target

A gunshot should be explainable as a causal chain: what projectile struck, where it struck, what material/protection it encountered, whether it penetrated, what tissue or cybernetic structure was affected, what immediate impairment resulted, whether bleeding or other physiological consequences follow, and what treatment can change the outcome.

If the result is primarily explained by target level, a large generic health pool, stacked percentage bonuses or another mod's hidden damage authority, the realism pass has not reached its target.
