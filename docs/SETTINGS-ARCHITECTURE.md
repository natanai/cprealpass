# realpass configuration architecture

Status: canonical public-settings contract
Last updated: 2026-09-14

## Goal

RealPass has one authored physical simulation. Its normal player-facing settings page is intentionally tiny: **exactly two editable Boolean settings**.

Those settings are:

- **Enable RealPass** — `On` by default. This is the one global master switch for the complete overhaul. Turning it off makes RealPass gameplay and presentation adapters yield to native Cyberpunk behavior. Because some systems attach, schedule, or initialize at save/session boundaries, reload the current save after changing this setting so every adapter begins from the same state.
- **E3 first-person HUD visuals** — `On` by default. While RealPass is enabled, this controls the RealPass-owned red E3-inspired first-person HUD and NPC-nameplate presentation only. It does not change body state, injury, combat, armor, pain, treatment, recovery, or the modern scanner.

The global switch is deliberately **not** a collection of subsystem toggles. A player may run the authored RealPass experience or disable RealPass as a whole; they may not independently disable body, injury, combat, armor, bleeding, recovery, or other physical authorities.

RealPass appearing under `Settings > Mods` is itself sufficient to show that the mod/settings integration is installed. Do not fill the page with fake one-value status controls, implementation inventory, patch notes, diagnostics, or a feature ledger.

## Release behavior

With **Enable RealPass = On**, a normal RealPass release keeps the accepted simulation authorities together:

```text
body = on
injury = on
combat = on
armor = on
cyberware physiology = on where implemented
presentation authority = on
diagnostics = off
native modern scanner = on
traditional actor HP bars = off
E3-inspired first-person HUD/nameplates = authored visual target
```

With **Enable RealPass = Off**, RealPass-owned adapters should yield to the native game rather than leave a half-enabled mixture. Native Cyberware labeling/behavior, wardrobe behavior, actor-health presentation, consumable behavior, combat routing and other wrapped stock paths should remain available. Persistent RealPass body state may remain saved for later re-enable; disabling the mod is not permission to erase or refill it.

Two players on the same RealPass version with RealPass enabled therefore get the same damage, ballistics, armor, injury, physiology, pain, treatment and recovery rules regardless of the E3-HUD visual preference.

## E3 presentation boundary

The product goal is not to run the external Project E3 HUD mod. The goal is to reproduce the desired visual language inside RealPass:

- red E3-inspired first-person HUD styling;
- E3-inspired NPC nameplates;
- native modern scanner/quickhack behavior retained;
- RealPass-owned source/assets and runtime authority;
- no requirement that players install Project E3 separately.

Historical Project E3 code/assets may be studied as reference/provenance where permitted, but the standalone RealPass runtime must not depend on its scripts, archive, tweak payload, save state, or settings implementation.

## Public settings

### `realpass.enabled`

- type: Boolean;
- default: `true`;
- authority: global master only;
- disables or enables the authored RealPass overhaul as one unit;
- does not expose the internal authority graph as individual settings;
- changing it should be followed by reloading the current save/session so attach-time systems all agree on the same state.

### `presentation.e3-first-person-hud-visuals`

- type: Boolean;
- default: `true`;
- presentation-only;
- meaningful only while the RealPass master switch is on;
- gates the RealPass-owned E3-inspired HUD/nameplate skin;
- does not disable presentation authority as a whole;
- does not restore gameplay/balance configuration;
- does not replace the modern scanner with E3 scanner behavior.

Analgesic-disorientation feedback, pain consequences, injury effects, and other authored body feedback are not separate player settings. They remain part of the fixed RealPass experience while RealPass is enabled unless a later explicit product decision says otherwise.

## What players may never tune

The normal settings page must not expose:

- separate body/injury/combat/armor enable switches;
- damage multipliers;
- hunger/hydration rates;
- bleeding multipliers;
- pain or analgesia scales;
- armor/protection scaling;
- MaxDoc dose/decay thresholds;
- recovery speed;
- cosmetic-transmog authority;
- diagnostics;
- any Float/Int balance control.

Internal development gates may still exist for isolation, exact compilation, and diagnosis. They are not player preferences.

## Mod Settings dependency boundary

Mod Settings is generic UI/persistence plumbing only. RealPass owns both setting labels/defaults and all runtime policy/behavior behind them.

The RealPass settings singleton may register/unregister as a Mod Settings listener so accepted changes are reflected and persisted. RealPass code reads its own `CRRealpassSettings` singleton; it must not use Mod Settings internals as a simulation-policy owner or query provider APIs to define body/combat/injury balance.

If Mod Settings were replaced in the future, the authored RealPass simulation should not change.

## Actor-health presentation

Attended feedback on 2026-09-14 explicitly rejected the restored native red player-health indicator. The ordinary **RealPass-on** presentation therefore hides traditional actor HP bars/HP-number feedback. This remains a presentation-only change: native game health state is not deleted or used as the RealPass injury model.

The global master switch is the native fallback boundary. With **Enable RealPass = Off**, native actor-health presentation is allowed to return. The E3 visual toggle does not independently control health-bar policy: switching only the E3 skin off leaves the RealPass simulation and barless actor-health decision intact.

## Acceptance criteria

Configuration is accepted only when:

1. `Settings > Mods` lists **RealPass**;
2. RealPass contains exactly two editable settings: **Enable RealPass** and **E3 first-person HUD visuals**;
3. both settings are Boolean and default `On`;
4. turning **Enable RealPass** off causes RealPass gameplay/presentation wrappers to yield to native behavior after reload, without exposing per-system tuning;
5. toggling **E3 first-person HUD visuals** changes only the RealPass-owned E3-inspired HUD/nameplate presentation while RealPass remains enabled;
6. the modern scanner/quickhack UI remains native and usable in every setting state;
7. traditional actor HP presentation is suppressed while RealPass is enabled and may return when the global master is off;
8. no subsystem/balance/diagnostic controls appear;
9. no fake read-only feature-ledger controls appear;
10. RealPass does not require the external Project E3 runtime;
11. all simulation authority remains identical with the E3 visual toggle on or off.
