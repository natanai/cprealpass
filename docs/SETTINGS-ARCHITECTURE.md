# realpass settings architecture

## Goal

Expose one understandable **realpass** settings surface while keeping development safety gates separate from player preference. The final public UI should not expose the original source-mod menu structure or preserve unrelated source-mod features merely because they already have settings.

The machine-readable contract is `manifest/settings.json`; the module ownership contract is `manifest/runtime-modules.json`.

## Why player toggles and acceptance gates are different

During development, a setting such as `combat.enabled = true` describes the intended default experience. It must **not** automatically mean that an unvalidated native combat bridge is allowed to run.

The effective decision is:

```text
module may run = build/native acceptance gate AND player module setting AND valid lifecycle/state
```

These three questions are intentionally separate:

1. Has this implementation been accepted for the current build and game version?
2. Does the player want the module enabled?
3. Is the current game/save/lifecycle state safe for the module to run?

Current source build scripts use hard-coded/staged policy gates for body and combat. They remain in place until the unified settings implementation is integrated and compiled locally. Refactoring those gates without a compile/native test would create risk without helping the player.

## Mod Settings integration target

The pinned dependency set already includes Mod Settings. Its documented redscript API supports `@runtimeProperty` settings and registering a settings class as a listener so runtime values update when players change them. The intended implementation is therefore one realpass-owned `ScriptableSystem` settings class containing only the fields in `manifest/settings.json`.

Reference implementation/API documentation:

- https://github.com/jackhumbert/mod_settings

The implementation should register on attach and unregister on detach. It should use `@if(ModuleExists("ModSettingsModule"))` where practical so compile/runtime failure modes remain explicit. The final release may make Mod Settings a required bundled dependency if that remains the smallest reliable player UI, but dependency removal should remain possible if a simpler realpass-owned UI replaces it.

## Public categories

The intended categories are deliberately small:

- **Body** — needs, sleep/fatigue, exertion, elimination and minimal hygiene.
- **Injury and treatment** — localized wounds, blood loss, impairment, field care and recovery.
- **Combat** — physical ballistics/damage authority.
- **Armor** — physical protection and optional wear.
- **Cyberware physiology** — only structural/physiological consequences.
- **Presentation** — realpass cues/nameplates, never simulation authority.
- **Diagnostics** — development-only and off by default.

The first contract intentionally uses Boolean controls only. Numeric tuning controls should not be exposed merely because coefficients exist internally. A player-facing slider needs a clear conceptual meaning, a safe range and evidence that changing it does not break model relationships. Until then, calibration belongs in authored presets/code rather than a wall of tuning knobs.

## Toggle semantics

A toggle must control an **authority**, not simply hide its UI. For example, turning injury off must suspend realpass-owned bleeding and impairment modifiers and make combat fall back safely; it cannot leave a hidden wound timer running while removing the status display.

Persistent state should normally be retained while a module is disabled so a temporary preference change is not destructive. Re-enabling cannot silently refill needs, erase injuries or manufacture elapsed history. Schema/version migration remains explicit.

Where an engine hook cannot safely detach immediately, the setting must either suspend its effect while leaving the hook inert or be marked `restartRequired`. The settings contract currently marks all planned controls as live-changeable; native implementation must prove that assumption before 1.0. If proof fails for any control, update the contract rather than pretending hot toggling is safe.

## Source-mod settings migration

Upstream settings are treated as implementation inputs, not public product design. The migration rule is:

```text
source setting -> identify represented physical phenomenon -> map to one realpass owner
    -> retain/adapt only if needed -> otherwise remove from final runtime
```

Examples:

- Dark Future hydration/nutrition callbacks can feed/host the realpass body authority during transition.
- Dark Future fast-travel restrictions have no realpass owner and are removed.
- Dark Future generic HP-derived injury is replaced by localized realpass injury ownership.
- E3 scanner replacement is removed because the native modern scanner is preferred.
- E3-style nameplate behavior is a presentation requirement, but the current E3 assets are not a viable standalone distribution dependency; the behavior must be independently implemented or newly permitted.

`manifest/feature-inventory.json` tracks these decisions.

## Integration sequence

The source refactor should occur in this order to minimize save/build risk:

1. Keep `manifest/settings.json` and module contract passing in CI.
2. Add the realpass settings `ScriptableSystem` without changing existing body/combat activation behavior.
3. Compile it against the pinned local framework/game environment.
4. Add a central runtime policy facade that reads player intent but still requires the existing build acceptance gates.
5. Migrate body and presentation gates first; conduct save/reload and toggle tests.
6. Migrate injury/armor/combat gates only when their native pipeline is already ready for attended activation.
7. Remove redundant source-mod public settings from the final package after realpass owns every retained phenomenon.
8. Validate off -> on -> save -> reload and on -> off -> save -> reload for each module before calling the toggle safe.

This ordering deliberately prevents a settings refactor from accidentally activating unaccepted combat or rewriting an existing save merely because the intended public default is `true`.
