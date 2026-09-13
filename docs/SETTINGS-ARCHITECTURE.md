# realpass settings architecture

## Goal

Expose one understandable **realpass** settings surface while keeping development safety gates separate from player preference. The final public UI should not expose the original source-mod menu structure or preserve unrelated source-mod features merely because they already have settings.

The machine-readable contract is `manifest/settings.json`; the module ownership contract is `manifest/runtime-modules.json`. The current passive runtime adapter is `src/redscript/CyberpunkRealism/RealpassSettings.reds`; the engine-independent decision model is `RuntimePolicyModel.reds`.

## Current implementation state

The first two consolidation steps are now implemented in source:

- `CRRealpassSettings` is one realpass-owned `ScriptableSystem` registered with Mod Settings.
- Twenty player-facing Boolean preferences mirror the non-development categories in `manifest/settings.json`.
- The diagnostics Boolean exists internally but is deliberately not annotated into the ordinary player menu; attended diagnostics remain an explicit build/session choice.
- `IntentSnapshot()` maps those persisted/UI values into `CRRuntimeFeatureFlags`.
- All acceptance flags in `CRRuntimeFeatureFlags` still default to `false`, and the settings class has no method that can assign them.
- The settings class contains no gameplay callbacks, damage/stat-pool mutation, body/combat gate writes or Mod Settings modification listener. It records intent only.
- The broad attended builder refreshes both `RuntimePolicyModel.reds` and `RealpassSettings.reds` into the generated candidate and requires the pinned Mod Settings component before exact local compilation.

Cloud CI can prove those structural constraints, but it cannot prove Mod Settings reflection/registration or game-version compatibility. The next acceptance gate is the exact local Cyberpunk 2.31 compile followed by native menu rendering. Until that passes, the existing body/combat development gates remain authoritative.

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

Current source build scripts use hard-coded/staged policy gates for body and combat. They remain in place while the settings surface is compiled and accepted. Refactoring those gates before the local compile/native test would create risk without helping the player.

## Mod Settings integration

The pinned local integration profile already includes Mod Settings 0.2.21. Its documented redscript API supports `@runtimeProperty` fields and class listeners, so `CRRealpassSettings` uses one direct dependency in attended/local runtime profiles:

```text
OnAttach -> ModSettings.RegisterListenerToClass(this)
OnDetach -> ModSettings.UnregisterListenerToClass(this)
```

Reference API/project:

- https://github.com/jackhumbert/mod_settings

The current approach deliberately does **not** make Mod Settings optional inside the attended profile: the builder checks that the pinned component is present before adding the settings source. That is easier to reason about than relying on unproven module-detection behavior. A future standalone release can revisit whether Mod Settings remains a required bundled dependency or is replaced by a smaller realpass-owned UI, but that is a distribution decision rather than a reason to weaken the current compile contract.

## Player-facing categories

The intended categories are deliberately small:

- **Body** — needs, sleep/fatigue, exertion, elimination and minimal hygiene.
- **Injury and treatment** — localized wounds, blood loss, impairment, field care and recovery.
- **Combat** — physical ballistics/damage authority.
- **Armor** — physical protection and optional wear.
- **Cyberware physiology** — only structural/physiological consequences.
- **Presentation** — realpass cues/nameplates and healthbar preference, never simulation authority.

**Diagnostics is not an ordinary player-facing category.** It is development-only, defaults off and is selected through the attended build/session tooling when a concrete discrepancy needs investigation.

The first contract intentionally uses Boolean controls only. Numeric tuning controls should not be exposed merely because coefficients exist internally. A player-facing slider needs a clear conceptual meaning, a safe range and evidence that changing it does not break model relationships. Until then, calibration belongs in authored presets/code rather than a wall of tuning knobs.

## Toggle semantics

A toggle must control an **authority**, not simply hide its UI. For example, turning injury off must suspend realpass-owned bleeding and impairment modifiers and make combat fall back safely; it cannot leave a hidden wound timer running while removing the status display.

Persistent state should normally be retained while a module is disabled so a temporary preference change is not destructive. Re-enabling cannot silently refill needs, erase injuries or manufacture elapsed history. Schema/version migration remains explicit.

Where an engine hook cannot safely detach immediately, the setting must either suspend its effect while leaving the hook inert or be marked `restartRequired`. The settings contract currently marks all planned controls as live-changeable; native implementation must prove that assumption before 1.0. If proof fails for any control, update the contract rather than pretending hot toggling is safe.

The current settings source is intentionally **not yet wired to runtime authorities**, so toggling it during the first attended compile/menu check is a persistence/UI test, not evidence that the corresponding gameplay module can hot-toggle safely.

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

The source refactor proceeds in this order to minimize save/build risk:

1. **Done:** machine-readable settings/module contracts pass in cloud CI.
2. **Done in source:** add the passive realpass settings `ScriptableSystem` without changing existing body/combat activation behavior.
3. **Next local gate:** compile the policy + settings surface against the pinned Mod Settings/game environment and confirm the realpass menu renders with the expected defaults/dependencies.
4. Add the native runtime policy facade that combines the already-implemented player-intent snapshot with explicit accepted-build flags and lifecycle checks; do not delete legacy gates in the same untested batch.
5. Migrate presentation and body authority reads first; conduct off/on/save/reload and stale-modifier tests.
6. Migrate injury/armor/combat authority reads only after the broad native pipeline has passed attended combat acceptance.
7. Remove redundant source-mod public settings from the final runtime after realpass owns every retained phenomenon.
8. Validate off -> on -> save -> reload and on -> off -> save -> reload for every live-changeable module before calling the toggle safe.

This ordering deliberately prevents a settings refactor from accidentally activating unaccepted combat or rewriting an existing save merely because the intended public default is `true`.
