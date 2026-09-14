# realpass internal modular architecture

Last updated: 2026-09-14

## Goal

Ship one coherent authored realism mod. Internal authorities remain separable for development, calibration and regression diagnosis, but that modularity is **not** the player product. A release candidate enables the complete accepted simulation together; diagnostics remain off.

Gameplay and presentation execution is RealPass-owned. Historical source/reference mods are research only. The current owned candidate uses project-original REDscript plus pinned redscript plumbing and no broader framework/runtime stack.

## Authority map

### Body

Owns nutrition, hydration, wake/sleep pressure, exertion/fatigue, digestion/elimination, recovery and restrained hygiene state.

Development gate: `body`.

One body clock is shared with injury/pain/recovery. Internal exact state may be diagnostic; player presentation is qualitative.

### Injury

Owns six-region tissue/bone/chrome state, external/internal bleeding, whole-body blood deficit, impairment, pain/analgesia state, stabilization, field care, professional care and biological recovery.

Development gate: `injury`.

It consumes accepted physical wound inputs; presentation/provenance cannot become a second damage authority.

### Combat

Owns weapon/projectile/ammunition profiles, hit-region/material routing, penetration/impact and wound proposals.

Development gate: `combat`.

Its explanation is physical impact, not target level or a generic HP reservoir. Native authored boss/quest/immortality/nonlethal safeguards remain the final compatibility boundary.

### Armor

Owns protective item classification, regional coverage, projectile-dependent protection and armor wear.

Development gate: `armor`.

Ordinary clothing is not generic ballistic armor.

### Cyberware physiology

Current scope is intentionally narrow: a cyberware/metal structural hit can produce distinct chrome damage and mechanical-care requirements.

Development gate: `cyberwarePhysiology`.

This authority is not a general cyberware balance overhaul. New physiological effects require a separate physical rationale.

### Presentation

Owns only the RealPass presentation needed to communicate the simulation:

- Biology qualitative body/condition UI;
- actor-healthbar suppression;
- narrow scanned-civilian public-name fallback;
- coexistence with the native modern scanner/quickhack UI.

Development gate: `presentation`.

Backpack remains possessions; Cyberware remains equipment. Presentation reads the body/injury/combat/armor authorities but does not mutate them as a substitute for gameplay logic.

### Diagnostics

Owns finite attended-development observability.

Development gate: `diagnostics`.

Always off in normal play; never a background watcher/service/recorder.

## Release configuration

The accepted release profile is fixed:

- body: on;
- injury: on;
- combat: on;
- armor: on;
- narrow cyberware structural physiology: on;
- presentation: on;
- diagnostics: off;
- traditional actor health bars: off;
- native modern scanner: on.

There is no public subsystem on/off menu and no balance-slider matrix. The same RealPass version means the same authored simulation.

Canonical source gates remain fail-closed where needed for safe development. `Build-OwnedAcceptance.ps1` opens body/combat only in immutable staged copies of the exact candidate. The release profile is therefore fixed without making repository source unsafe to drop into an arbitrary game install.

## Runtime hierarchy

Preferred direction:

`Cyberpunk native event/API -> thin explicit RealPass seam -> stable RealPass model/state -> qualitative RealPass/native presentation`

The current generic runtime plumbing is simply redscript. A new framework can be introduced only when an owned runtime requirement actually needs it and the distribution/native-seam contracts are updated intentionally.

## Dependency direction

`native clock/lifecycle/consumable/movement -> body`

`native hit/equipment/projectile data -> combat -> armor/cyberware structure -> injury -> blood/pain/impairment -> care/recovery`

`body + injury + equipment state -> Biology / embodied effects`

`native scanner/nameplate data -> narrow presentation fallback -> stock renderer`

No economy/weather/travel/outfit authority exists in the graph because those systems are outside scope.

## Reference-source rule

When an external mod suggests a useful behavior:

1. identify the problem independently;
2. determine the native game signal/model needed to solve it;
3. implement the behavior in RealPass-owned source/data;
4. keep attribution/research history where appropriate;
5. prove the owned candidate has no executing dependency on the reference source.

The finished runtime must stand on vanilla Cyberpunk + its selected generic plumbing, not on hidden source-mod authority.

## Acceptance target

A gunshot should be explainable by projectile, impact region, encountered material/protection, penetration/structural result, biological/chrome injury, immediate impairment, blood/pain consequences and treatment/recovery.

A bodily need should be explainable by the shared physical state and communicated through something V could plausibly perceive, not a permanent arbitrary meter.

If a result is primarily explained by target level, a generic health-sponge pool, a duplicated UI meter authority or another mod's hidden state machine, it does not satisfy the architecture.
