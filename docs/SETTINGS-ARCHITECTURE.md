# Biology configuration architecture

Status: canonical public-settings contract during REDmod migration
Last updated: 2026-09-14

## Goal

Biology is one authored physical simulation. Its normal player-facing preference surface is intentionally tiny: **at most two editable Boolean settings**.

Those preferences are:

- **Enable Biology** — `On` by default if a reliable whole-mod runtime switch remains practical. This is the one global master switch for the complete overhaul. Turning it off should make Biology gameplay/presentation adapters yield to native Cyberpunk behavior after the current save/session is reloaded when attach-time state requires it.
- **E3 first-person HUD visuals** — `On` by default. While Biology is enabled, this controls the Biology-owned red E3-inspired first-person HUD and NPC-nameplate presentation only. It does not change body state, injury, combat, armor, pain, treatment, recovery, or the modern scanner.

The global switch is deliberately **not** a collection of subsystem toggles. A player may run the authored Biology experience or disable Biology as a whole; they may not independently disable body, injury, combat, armor, bleeding, recovery, or other physical authorities.

## Provider is not product architecture

The settings **provider is no longer locked to Mod Settings**.

Current code may still use Mod Settings during migration, but it is generic UI/persistence plumbing only and has no entitlement to remain in the finished package. The REDmod/dependency audit must determine whether the two public preferences can live in a Biology-owned surface (for example, a restrained preferences subsection inside Biology) without increasing fragility.

Preferred result:

- remove Mod Settings if it has no other required consumer;
- remove ArchiveXL/RED4ext dependencies that existed only to support Mod Settings when no other accepted feature needs them;
- keep the public preference semantics unchanged regardless of provider.

Do not preserve a framework stack merely to host two booleans.

## Release behavior

With **Enable Biology = On**, a normal release keeps accepted simulation authorities together:

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

With **Enable Biology = Off**, Biology-owned adapters should yield to the native game rather than leave a half-enabled mixture. Native Cyberware labeling/behavior, wardrobe behavior, actor-health presentation, consumable behavior, combat routing and other wrapped stock paths should remain available. Persistent Biology body state may remain saved for later re-enable; disabling the mod is not permission to erase or refill it.

Two players on the same Biology version with Biology enabled therefore get the same damage, ballistics, armor, injury, physiology, pain, treatment and recovery rules regardless of the E3-HUD visual preference.

If the REDmod migration proves a fully reliable live master switch is disproportionately invasive, preserve the all-or-nothing product rule and revisit whether “disable Biology” should instead be an install/deploy boundary. Do not replace one master switch with per-system switches.

## E3 presentation boundary

The product goal is not to run the external Project E3 HUD mod. The goal is to reproduce the desired visual language inside Biology:

- red E3-inspired first-person HUD styling;
- E3-inspired NPC nameplates;
- native modern scanner/quickhack behavior retained;
- Biology-owned source/assets and runtime authority;
- no requirement that players install Project E3 separately.

Historical Project E3 code/assets may be studied as reference/provenance where permitted, but the standalone Biology runtime must not depend on its scripts, archive, tweak payload, save state, or settings implementation.

## Public preference identifiers during migration

Internal keys may remain historically named until safe migration. New player-facing labels use Biology.

Conceptual preferences:

### `biology.enabled` / legacy `realpass.enabled`

- type: Boolean;
- default: `true` if retained as a runtime preference;
- authority: global master only;
- disables or enables the authored Biology overhaul as one unit;
- does not expose the internal authority graph as individual settings;
- changing it may require save/session reload so attach-time systems agree.

### `presentation.e3-first-person-hud-visuals`

- type: Boolean;
- default: `true`;
- presentation-only;
- meaningful only while Biology is enabled;
- gates the Biology-owned E3-inspired HUD/nameplate skin;
- does not disable presentation authority as a whole;
- does not restore gameplay/balance configuration;
- does not replace the modern scanner with E3 scanner behavior.

Analgesic-disorientation feedback, pain consequences, injury effects, and other authored body feedback are not separate player settings. They remain part of the fixed Biology experience while Biology is enabled unless a later explicit product decision says otherwise.

## What players may never tune

The normal preference surface must not expose:

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

## Actor-health presentation

Attended feedback on 2026-09-14 explicitly rejected the restored native red player-health indicator. The ordinary **Biology-on** presentation therefore hides traditional actor HP bars/HP-number feedback. This remains a presentation-only change: native game health state is not deleted or used as the Biology injury model.

The global master switch, if retained, is the native fallback boundary. With **Enable Biology = Off**, native actor-health presentation is allowed to return. The E3 visual preference does not independently control health-bar policy: switching only the E3 skin off leaves the Biology simulation and barless actor-health decision intact.

## REDmod migration requirements

The settings lane must explicitly classify the final provider:

- `BIOLOGY-OWNED` — preferred if it removes framework dependencies cleanly;
- `GENERIC-FRAMEWORK-JUSTIFIED` — allowed only with a current feature-specific reason;
- `INSTALL/DEPLOY-BOUNDARY` — acceptable for the whole-mod enable state if a live runtime master switch would require disproportionate invasive infrastructure.

Whatever provider is chosen must not become a simulation authority.

See `BIOLOGY-REDMOD-MIGRATION.md`.

## Acceptance criteria

Configuration is accepted only when:

1. the player sees **Biology** rather than RealPass as the product identity;
2. no more than two editable public preferences exist: **Enable Biology** (if retained as a live switch) and **E3 first-person HUD visuals**;
3. both are Boolean and default `On` when present;
4. the Biology enable boundary is all-or-nothing rather than per-system tuning;
5. toggling **E3 first-person HUD visuals** changes only the Biology-owned E3-inspired HUD/nameplate presentation while Biology remains enabled;
6. the modern scanner/quickhack UI remains native and usable in every setting state;
7. traditional actor HP presentation is suppressed while Biology is enabled and may return when the whole-mod enable boundary is off;
8. no subsystem/balance/diagnostic controls appear;
9. no fake read-only feature-ledger controls appear;
10. Biology does not require the external Project E3 runtime;
11. all simulation authority remains identical with the E3 visual preference on or off;
12. any surviving settings framework has a documented current necessity and is not retained merely because older RealPass builds used it.