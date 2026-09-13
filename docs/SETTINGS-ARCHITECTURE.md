# realpass configuration architecture

## Goal

realpass has one authored gameplay experience. Configuration exists to support development, diagnostics, accessibility where it does not change the simulation, and future migration—not to turn the release into a menu of independently optional mechanics.

The release contract is recorded in `manifest/runtime-origin-policy.json`. Internal module ownership remains in `manifest/runtime-modules.json`. `RuntimePolicyModel.reds` is retained as an engine-independent development/build gate model. The previous Mod Settings-based gameplay preference surface is retired from the production path.

## Release behavior

A normal release locks the accepted authorities together:

```text
body = on
injury = on
combat = on
armor = on
cyberware physiology = on where implemented
presentation = on
diagnostics = off
traditional actor health bars = off
```

There is no player-facing switch for disabling a core authority and no balance slider matrix. Version-to-version changes are authored realpass balance changes and therefore reproducible for every player on that version.

## Development configuration

Internal gates still matter. During development an engineer may need a body-only build, a combat-without-presentation comparison, diagnostics, or another narrow profile. These controls are allowed only in build/test tooling and are never evidence that the final product should expose the same choice.

The decision model is therefore:

```text
development candidate may run authority = build acceptance gate AND development profile gate AND valid native lifecycle/state
```

For a release candidate, the development-profile side is fixed to the one accepted product configuration.

## Why the earlier Mod Settings surface was retired

The repository briefly implemented a passive realpass Mod Settings surface to separate player intent from native acceptance. That architecture was safe, but it represented the wrong product goal: two players could disable different pieces of the physical model and still both call the result realpass.

The product requirement is now explicit: modularity is for us while developing, not for the player after release. `RealpassSettings.reds` therefore becomes historical/transitional source and is removed from active package/build manifests. Mod Settings should not remain a realpass dependency merely because that prototype existed.

If a future accessibility control is justified, it must meet all of these conditions:

- it does not disable or rebalance a simulation authority;
- it does not expose exact hidden state that the authored presentation intentionally withholds;
- it has a clear accessibility purpose rather than being a difficulty/balance switch;
- it does not introduce another framework dependency unless that dependency is independently justified.

## Diagnostics

Diagnostics are development-only and opt-in through attended build/session tooling. They remain off in normal play and must never become a background watcher, service or persistent telemetry system.

Diagnostics may expose exact numerical state because their purpose is verification. Release presentation should communicate injury/body state through consequences and restrained status surfaces instead.

## Ownership and reference mods

There is no source-mod settings migration in the final architecture. Dark Future and Project E3 HUD are references, not runtime hosts. We may use historical configuration to understand which edge cases existed, but the final implementation is re-derived from native game signals and realpass-owned state.

The rule is:

```text
reference observation -> identify the underlying problem -> implement a realpass-native solution
```

not:

```text
source setting -> rename it -> expose it as realpass
```

## Build profiles

Development tooling may define immutable profiles such as:

- model/offline validation;
- owned-runtime compile candidate;
- owned-runtime attended candidate;
- temporary diagnostics candidate;
- release candidate.

An **owned-runtime** profile has an additional hard rule: it contains no Dark Future or Project E3 runtime scripts/assets/state. `manifest/runtime-origin-policy.json` is the machine-readable authority for that check.

The release profile may not inherit the currently installed legacy integration manifest. It must be constructed from an explicit realpass-owned runtime manifest so a source-mod dependency cannot be accidentally laundered into a “clean” build.

## Runtime policy model

`RuntimePolicyModel.reds` remains useful, but its booleans are development/build gates rather than player preferences. Before 1.0 it should be simplified to distinguish:

- authority accepted for this game/build;
- authority enabled in this development profile;
- lifecycle/state safe right now.

The release builder supplies the fixed accepted profile. Normal players never edit it.

## Acceptance criteria

Before configuration work is considered complete:

1. the active package/build path has no Mod Settings dependency unless a non-gameplay accessibility feature proves it necessary;
2. the owned-runtime audit rejects Dark Future/E3 payloads and namespace dependencies;
3. a release candidate cannot disable body, injury, combat, armor or presentation independently;
4. diagnostics are impossible to enable accidentally in the release artifact;
5. healthbar suppression is part of the authored presentation rather than a normal player preference;
6. all runtime authorities can still be isolated through development-only tooling for diagnosis and calibration.
