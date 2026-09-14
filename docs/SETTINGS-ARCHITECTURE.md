# realpass configuration architecture

## Goal

RealPass has one authored physical simulation, but that does **not** require an empty settings page. The public configuration surface has three deliberately narrow jobs:

1. make it obvious that RealPass is installed/active;
2. provide a concise feature ledger describing the major systems RealPass owns;
3. expose a very small number of binary presentation/accessibility preferences that do not alter hidden physical simulation.

Configuration must never turn the release into a difficulty/balance sandbox.

The release contract is recorded in `manifest/settings.json` and `manifest/runtime-origin-policy.json`. Internal module ownership remains in `manifest/runtime-modules.json`. `RuntimePolicyModel.reds` remains an engine-independent development/build gate model; those authority gates are not player preferences.

## Release behavior

A normal release keeps the accepted simulation authorities together:

```text
body = on
injury = on
combat = on
armor = on
cyberware physiology = on where implemented
presentation authority = on
diagnostics = off
native modern scanner = on
```

Two players on the same RealPass version should therefore have the same authored damage, ballistics, armor, injury, physiology, pain, treatment and recovery rules.

The player may choose whether certain **presentation channels** are shown when doing so does not alter those rules. A preference is acceptable only when the hidden simulation and gameplay consequences remain identical.

## Mod Settings is a status/ledger surface

RealPass intentionally appears in Cyberpunk's Mod Settings menu.

The surface should be compact and stable. It is **not** patch notes, release history, diagnostics, raw telemetry or a list of every implementation detail.

The first owned surface uses two kinds of entry:

- a one-value informational state such as `Active` / `Managed by RealPass` for the concise feature ledger;
- a true binary preference for an optional presentation/accessibility channel.

Current ledger categories are deliberately broad:

- Body and physiology;
- Injury, bleeding and recovery;
- Pain and MaxDoc analgesia;
- Combat and ballistics;
- Physical armor and protection;
- Presentation and feedback.

Biology should be added to the visible ledger once its native player-facing shell is accepted, rather than advertising unfinished UI merely because a view-model exists in source.

## What players may toggle

Public preferences must be boolean and non-authoritative. Examples that can qualify include contextual vocalization, a fullscreen discomfort effect, or another redundant cue when disabling that cue does not remove or rebalance the underlying state or consequence.

The first accepted preference candidate is:

- **Fullscreen disorientation effects** — controls only the fullscreen/audio loop used to communicate excessive overlapping analgesia. Pain, analgesic load, injury, weapon-handling consequences, blood loss and recovery continue unchanged.

A new public boolean requires the same proof before it is added.

## What players may never tune

Do not expose numeric or scale-style controls for physical simulation. In particular, no public setting may provide:

- damage multipliers;
- hunger/hydration rates;
- bleeding multipliers;
- pain strength or analgesia curves;
- armor/protection scaling;
- MaxDoc dose/decay thresholds;
- recovery speed;
- other Float/Int tuning values that create different simulation balance.

Likewise, normal players do not get switches that disable core authorities such as body simulation, injury, ballistics, armor, bleeding or recovery.

The rule is:

```text
same hidden simulation + optional presentation channel = potentially valid
```

not:

```text
player changes the physical rules = valid RealPass preference
```

## Transitional feedback is acceptance-gated

The final authored presentation still aims to avoid traditional actor HP meters and permanent survival-meter walls. However, attended development must not remove the player's only useful feedback before a RealPass replacement actually works in-game.

During development, suppression is therefore **replacement-gated**:

- leave a native indicator available when removing it would make the current build unreadable;
- treat that native indicator as a temporary fallback, not the final product target;
- suppress it only after the corresponding Biology/HUD/gameplay feedback passes attended acceptance;
- never replace it with a pile of RealPass percentage bars merely to make the fallback disappear.

This distinction matters because the first owned live screenshots showed the stock `HEALTH INDICATOR` still visible while the Biology replacement was not yet usable. Hiding that indicator immediately would make the build less testable without advancing the actual product.

## Development configuration

Internal gates still matter. During development an engineer may need a body-only build, a combat-without-presentation comparison, diagnostics, or another narrow profile. These controls remain build/test tooling only.

The model is:

```text
development authority may run = build acceptance gate AND development profile gate AND valid native lifecycle/state
```

For a release candidate, development-profile authority gates are fixed to the one accepted product configuration.

## Mod Settings dependency boundary

Mod Settings is permitted again because it serves a narrow generic UI/persistence role. It must not own RealPass policy or simulation state.

RealPass source should prefer runtime-property metadata and project-owned preference accessors over wiring the simulation directly to Mod Settings internals. If Mod Settings disappeared, the intended repair would be to replace this presentation/configuration plumbing without changing the physical model.

The owned runtime may therefore include pinned generic dependencies needed by Mod Settings, while the source-mod ownership prohibition remains unchanged: Dark Future and Project E3 cannot execute RealPass gameplay or presentation policy.

## Diagnostics

Diagnostics remain development-only and opt-in through attended build/session tooling. They must never become a background watcher, service or persistent telemetry system.

Diagnostics may expose exact numerical state because their purpose is verification. The ordinary Mod Settings ledger must not become a disguised diagnostics page.

## Physical outfits are not a settings toggle

The vanilla Outfit/wardrobe convenience is being reinterpreted as a physical equipment-loadout behavior, not retained as cosmetic transmog and not exposed as a switch between realism and transmog.

What V appears to wear must ultimately match the physical equipment RealPass uses for protection/coverage. Configuration must not provide a "keep cosmetic transmog" escape hatch that reintroduces two contradictory equipment realities.

## Acceptance criteria

Configuration work is accepted only when:

1. `Settings > Mods` visibly identifies RealPass as active;
2. the page contains a concise feature ledger rather than patch notes or diagnostics;
3. core body/injury/combat/armor authorities cannot be disabled there;
4. no public Float/Int/numeric balance controls exist;
5. every editable public control is binary and demonstrably presentation/accessibility-only;
6. diagnostics cannot be enabled accidentally from the normal release page;
7. internal authorities can still be isolated through development-only tooling;
8. temporary native health/needs feedback is not removed until replacement feedback is accepted;
9. final release acceptance still removes traditional actor HP presentation where technically safe once replacements are proven;
10. Mod Settings remains generic plumbing rather than the owner of simulation policy.
