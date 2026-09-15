# realpass configuration architecture

Status: canonical public-settings contract
Last updated: 2026-09-14

## Goal

RealPass has one authored physical simulation. Its normal player-facing settings page is intentionally tiny: **exactly one editable setting**.

That setting is:

- **E3 first-person HUD visuals** — `On` by default. It enables the RealPass-owned red E3-inspired first-person HUD and NPC-nameplate presentation. Turning it off changes presentation only. It does not change body state, injury, combat, armor, pain, treatment, recovery, the modern scanner, or any other simulation authority.

RealPass appearing under `Settings > Mods` is itself sufficient to show that the mod/settings integration is active. Do not fill the page with fake one-value status controls, implementation inventory, patch notes, diagnostics, or a feature ledger.

## Release behavior

A normal RealPass release keeps the accepted simulation authorities together:

```text
body = on
injury = on
combat = on
armor = on
cyberware physiology = on where implemented
presentation authority = on
diagnostics = off
native modern scanner = on
E3-inspired first-person HUD/nameplates = authored visual target
```

Two players on the same RealPass version therefore get the same damage, ballistics, armor, injury, physiology, pain, treatment and recovery rules regardless of the HUD-visual preference.

## E3 presentation boundary

The product goal is not to run the external Project E3 HUD mod. The goal is to reproduce the desired visual language inside RealPass:

- red E3-inspired first-person HUD styling;
- E3-inspired NPC nameplates;
- native modern scanner/quickhack behavior retained;
- RealPass-owned source/assets and runtime authority;
- no requirement that players install Project E3 separately.

Historical Project E3 code/assets may be studied as reference/provenance where permitted, but the standalone RealPass runtime must not depend on its scripts, archive, tweak payload, save state, or settings implementation.

## The sole public setting

`presentation.e3-first-person-hud-visuals`

- type: Boolean;
- default: `true`;
- presentation-only;
- gates the RealPass-owned E3-inspired HUD/nameplate skin;
- does not disable presentation authority as a whole;
- does not restore traditional balance/gameplay configuration;
- does not replace the modern scanner with E3 scanner behavior.

Analgesic-disorientation feedback, pain consequences, injury effects, and other authored body feedback are not separate player settings. They remain part of the fixed RealPass experience unless a later explicit product decision says otherwise.

## What players may never tune

The normal settings page must not expose:

- body/injury/combat/armor enable switches;
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

Mod Settings is generic UI/persistence plumbing only. RealPass owns the setting label, default, policy, and visual behavior.

The RealPass settings singleton may register/unregister as a Mod Settings listener so an accepted change is reflected live and persisted. It must not use Mod Settings as a simulation-policy owner or query it to define body/combat/injury balance.

If Mod Settings were replaced in the future, the physical simulation should not change.

## Transitional health feedback

Traditional actor-health suppression remains replacement-gated during development. The final target is still no traditional actor HP bars, but a useful native indicator may remain temporarily until the RealPass-owned HUD/Biology feedback has passed attended testing.

This is independent of the E3 visual toggle: turning the E3-inspired skin off does not change the underlying acceptance gate or physical simulation.

## Acceptance criteria

Configuration is accepted only when:

1. `Settings > Mods` lists **RealPass**;
2. RealPass contains exactly one editable setting: **E3 first-person HUD visuals**;
3. that setting is Boolean and defaults `On`;
4. toggling it changes only the RealPass-owned E3-inspired HUD/nameplate presentation;
5. the modern scanner/quickhack UI remains native and usable in either setting state;
6. no gameplay/balance/diagnostic controls appear;
7. no fake read-only feature-ledger controls appear;
8. RealPass does not require the external Project E3 runtime;
9. all simulation authority remains identical with the toggle on or off.
