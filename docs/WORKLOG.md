# realpass worklog

This is the durable chronological ledger for repo work. It is intentionally concise enough for a new agent to scan before touching the project, while retaining the decisions that would otherwise be trapped in chat history.

For current percentages and blockers, read `docs/PROJECT-STATUS.md`. For design rules, read `REALISM-SPEC.md` and `docs/MODULAR-ARCHITECTURE.md`.

## Logging convention

Every meaningful work batch should record:

- date and branch;
- commit(s) or identifiable files changed;
- what changed and why;
- tests/evidence actually obtained;
- what was deliberately *not* claimed;
- completion percentage before/after if the change closes or reopens a release gate;
- the clearest next action.

Do not use successful compilation as shorthand for gameplay validation. Do not report a distribution package as release-ready if it contains local-only or redistribution-blocked dependencies.

---

## 2026-09-12 — local-to-GitHub handoff completed

Branch/source: `main`
Commits: `cba7659`, `938c8b9`

The local PC repository was successfully pushed to `natanai/cprealpass`. The remote now contains the local-agent fixes for scanned NPC names/toilet interaction labels and the candidate that restores the modern scanner/quickhack presentation while retaining selected E3 HUD assets.

Evidence: Git remote advanced from `2f0846b` to `938c8b9`; local worktree was clean before push.

Not claimed: the modern-scanner candidate has not thereby been proven in native gameplay. Pushing source does not upload ignored local game assets, staging outputs, dependency archives, deployment state or saves.

Next: continue remote work on a branch separate from `main` and preserve the local state for attended testing.

---

## 2026-09-12 — realism scope tightened

Branch: `chatgpt-continuation`
Commits: `f23eda2`, `e6501a2`, `4b9dbbe`
Files: `REALISM-SPEC.md`, `docs/ROADMAP.md`, `docs/MODULAR-ARCHITECTURE.md`

The project was explicitly reframed as one physical/physiological realism mod rather than a general difficulty/survival collection. Major runtime authorities were defined as body/needs, injury, ballistics/combat, armor/clothing, cyberware physiology, presentation and diagnostics. Weather/economy/scarcity/random encounters/travel restrictions and an added outfit/transmog system were declared out of scope.

Combat target was made causal rather than health-pool driven: projectile/ammunition -> region -> material/protection -> penetration -> tissue/cyberware injury -> physiological consequence -> treatment/recovery. Clothing does not gain arbitrary ballistic protection merely because it occupies an equipment slot.

Not claimed: those module boundaries are not yet a fully wired runtime settings implementation. Existing source still contains hard-coded development gates and upstream integration bridges.

Completion estimate after this scope work: **43% toward 1.0** (formal baseline recorded in `docs/PROJECT-STATUS.md`).

Next: convert the architecture into machine-readable contracts, automated tests and a release/distribution plan.

---

## 2026-09-12 — durable project ledger introduced

Branch: `chatgpt-continuation`
Commit: `90b6ac0`
Files: `docs/PROJECT-STATUS.md`

Added a weighted release-readiness model, current known-good state, blocker list, immediate priority order and future-agent rules. Overall baseline is **43%**. The percentage is deliberately conservative and measures progress toward a usable, validated, redistributable 1.0 rather than source-code volume.

Next: add runtime/distribution contracts and cloud-safe automation, then revise the percentage only if those changes materially close release gates.

---

## 2026-09-12 — contracts, cloud CI and safe artifact policy established

Branch: `chatgpt-continuation`
Key files: `manifest/runtime-modules.json`, `manifest/settings.json`, `manifest/distribution.json`, `manifest/acceptance.json`, `.github/workflows/ci.yml`, `tests/Run-CI.ps1`, package/artifact policy tests

Converted major architecture decisions into machine-readable runtime, settings, distribution and acceptance contracts and added cloud-safe regression checks. CI was separated from local-only tests that require acquired third-party source, generated deployment manifests, the installed game or live deployment state. Safe development-package policy rejects forbidden paths, blocked dependencies and game/user data instead of treating a successful ZIP operation as release readiness.

Evidence: public-source CI repeatedly exercised module/settings/distribution/install contracts plus body, combat, wound, armor, field-care, blood-loss, injury-effects and NPC progression models. A previously failing cloud run exposed local-manifest-only tests in `Run-CI.ps1`; those were correctly moved out of the cloud tier rather than faking the missing manifests. Subsequent exact-head CI passed.

Not claimed: cloud CI cannot prove native redscript compatibility with the user's installed Cyberpunk 2.31 script bundle, E3 integration behavior, save persistence or actual gameplay feel.

Next: build one broad, immutable attended candidate that can exercise the whole physical pipeline together.

---

## 2026-09-12 — broad body/combat attended candidate and operator flow added

Branch: `chatgpt-continuation`
Key commits/files: `tools/Build-AttendedAcceptance.ps1`, `tools/Prepare-AttendedSession.ps1`, `tests/Test-AttendedBuilder.ps1`, `tests/Test-AttendedSessionTool.ps1`, `tests/Test-ActivationGates.ps1`, `docs/ATTENDED-ACCEPTANCE.md`, `docs/COMBAT-CALIBRATION.md`

Added a broad attended builder that refuses partial combat profiles: body runtime, interactions, combat profiles/bridge, wound routing, regional armor wear, injury effects, blood loss, field-care runtime, timed treatment/item handling and field-care UI must all be present before the candidate is accepted for compilation. Canonical source body/combat gates remain closed; only a new immutable generated profile may open them.

`Prepare-AttendedSession.ps1` now provides the preferred local operator path. It can derive the verified active deployment manifest, build and compile the broad candidate, run the real upgrade planner in `-WhatIf` mode, and stop. Live installation requires an explicit `-Deploy`, a verified save backup, reversible upgrade receipt and post-write verification. It never launches Cyberpunk or installs background monitoring.

The combat calibration guide formalizes the target: physical impact and anatomy/protection drive injury; native HP is an engine-output channel, not the causal wound model. Ordinary-human level/max-HP inflation must not define wound severity, while explicit boss/quest/nonlethal protections remain authoritative.

Evidence: exact branch-head GitHub Actions run `34718888471` completed successfully for commit `378a2b2` after the attended orchestration and acceptance docs were added.

Not claimed: the generated candidate has not yet been compiled or played against the user's local acquired dependency/game bundle. Native combat feel remains an attended gate.

Next: close known actor-healthbar re-show paths, then run exact local compile/preflight as soon as the PC is available.

---

## 2026-09-12 — no-traditional-healthbar coverage hardened

Branch: `chatgpt-continuation`
Commits: `d27cf9e`, `0d046ff`
Files: `src/redscript/CyberpunkRealism/NoHealthbars.reds`, `tests/Test-NoHealthbars.ps1`

Expanded the default no-healthbar presentation from the generic player/NPC/boss paths to the direct native visibility paths that can otherwise re-show player HP during Overclock or overshield changes. Added dedicated companion/Flathead actor-health suppression as well. The implementation continues to hide health-specific children rather than the entire player biomonitor root so RAM/buffs and other non-health information can remain visible.

The scope is intentionally actor health only. Generic objective/vehicle durability UI is not blanket-suppressed because those bars can communicate mission state rather than an actor's remaining HP.

Evidence: hook signatures were cross-checked against public decompiled Cyberpunk script references for `EvaluateHealthBarVisibility(Bool)`, `EvaluateOvershieldBarVisibility()` and `CompanionHealthBarGameController.OnFlatheadStatusChanged(Bool)`. Static contract tests now require all player visibility paths to finish by reapplying the same health-only suppression helper and continue forbidding presentation code from mutating health/damage authority.

Not claimed: these new wrappers have not yet passed the project's exact local 2.31 compilation or native rendering test. They are specifically designed to fail the attended compile/preflight before deployment if the installed signatures differ.

Next: let CI validate the public contract batch, then exact-compile on the user's machine and test Overclock/overshield/companion cases alongside ordinary combat.

---

## 2026-09-12 — release-readiness estimate advanced to 50%

Branch: `chatgpt-continuation`
Commit: `42b6306`
File: `docs/PROJECT-STATUS.md`

Recomputed the weighted release-readiness ledger from the original 43% baseline to **50%**. Credit was added for architecture/contracts, cloud-safe regression coverage, artifact policy, broad immutable attended tooling, no-healthbar integration and durable operator documentation. Native gameplay/save/quest validation intentionally remains at 15%, so this increase does not assume the unplayed candidate works in-game.

Next: the single highest-leverage gate is now local exact compile/preflight followed by one broad attended gameplay session rather than further speculative activation work.

---

## 2026-09-12 — passive unified realpass settings surface implemented

Branch: `chatgpt-continuation`
Key commits/files: `src/redscript/CyberpunkRealism/RealpassSettings.reds`, `src/redscript/CyberpunkRealism/RuntimePolicyModel.reds`, `tests/Test-SettingsRuntimeSurface.ps1`, `tools/Build-BodyRuntime.ps1`, `tools/Build-AttendedAcceptance.ps1`, `docs/SETTINGS-ARCHITECTURE.md`, `manifest/package.json`

Added one realpass-owned Mod Settings `ScriptableSystem` for the twenty player-facing Boolean preferences already defined by the settings contract. Diagnostics remains internal/development-only. The settings source registers only for value persistence/update and has no gameplay callback or modification listener.

`IntentSnapshot()` now translates persisted player choices into the existing engine-independent `CRRuntimeFeatureFlags`. Crucially, the settings class cannot assign any `*Accepted` flag, and those acceptance fields remain false by default. This preserves the distinction between “the player wants combat enabled” and “this exact native bridge has been accepted for this build.” Existing canonical body/combat gates therefore remain unchanged.

The broad attended builder now refreshes both the policy model and settings source even when the player's current known-good deployed base predates them, requires the pinned Mod Settings component, and compiles the exact result before any optional deployment. The runtime prototype builder stages the same two files. Development source package metadata advanced to `0.1.0-dev.19` and records Mod Settings 0.2.21 as the dependency for the settings source only.

Evidence obtained remotely: static contract tests cover all 21 contract keys, 20 public annotations, exact defaults/dependencies, player-intent-to-policy mapping, closed acceptance flags and absence of direct body/combat/damage side effects. The acceptance ledger and settings architecture were updated accordingly.

Not claimed: `CRRealpassSettings` has not yet been compiled against Nat's exact local Cyberpunk 2.31 + pinned Mod Settings bundle or rendered in the live Mod Settings menu. The native modules do not consume these preferences yet; that wiring intentionally waits until local compilation and broad attended acceptance.

Completion estimate remains **50%** rather than taking speculative credit for an uncompiled runtime adapter. A successful exact local compile/menu check will close enough of the settings gate to justify revisiting the weighted percentage.

Next: exact local compile/preflight, confirm the realpass settings menu/default/dependency behavior, then introduce a narrow accepted-build+lifecycle policy facade before migrating any native module to these preferences.
