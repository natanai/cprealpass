# realpass worklog

This is the durable chronological ledger for repo work. It is intentionally concise enough for a new agent to scan before touching the project, while retaining the decisions that would otherwise be trapped in chat history.

For canonical product intent, read `AGREED-GOALS.md` first. For current percentages and blockers, read `docs/PROJECT-STATUS.md`. For implementation architecture, read `REALISM-SPEC.md`, `docs/MODULAR-ARCHITECTURE.md` and `docs/SETTINGS-ARCHITECTURE.md`.

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

---

## 2026-09-13 — product ownership and release philosophy corrected

Branch: `chatgpt-continuation`
Key commits/files: source changes through `3ade43e`; `docs/MODULAR-ARCHITECTURE.md`, `docs/SETTINGS-ARCHITECTURE.md`, `manifest/runtime-origin-policy.json`, `src/redscript/CyberpunkRealism/BodyRuntime.reds`, `BodyNativeHooks.reds`, `BodyStatusPresentation.reds`

The user clarified two governing requirements that supersede the earlier settings/mod-stack direction:

1. everything executing as realpass gameplay/presentation should be physically realpass-owned code/data; Dark Future and Project E3 are inspiration/reference only, not hidden runtime hosts;
2. final releases are one authored all-or-nothing simulation. Internal modular switches remain useful for development but are not a normal player-facing way to create different versions of realpass.

The configuration architecture was rewritten accordingly and the prior Mod Settings gameplay-preference surface was retired from the intended production path. The body runtime began moving to direct native Cyberpunk lifecycle/consumable/time-skip hooks, and active Dark Future tick/intake/menu/preview bridge files were removed from production source.

Not claimed: owned-runtime separation is not complete. `FieldCareActionRuntime.reds` still imports `DarkFuture.Services.DFGameStateService`, and the owned candidate/build path has not yet been exact-compiled against the user's game.

The previous 50% readiness estimate was therefore no longer defensible under the stricter ownership requirement. The reopened integration/presentation gates are reflected in the 2026-09-13 status refresh.

Next: remove every remaining source-mod runtime dependency and construct an explicit owned-runtime candidate rather than inheriting the legacy integrated deployment.

---

## 2026-09-13 — Cyberware/body Condition interface chosen as canonical injury UX

Branch: `chatgpt-continuation`
Design decision; implementation pending

The user identified the stock Cyberware screen's body visualization and per-system paper-doll zoom as the desired foundation for injury inspection/treatment. The final direction is now:

- normal **Cyberware** mode preserves the screen's vanilla purpose;
- **Condition** mode replaces/dims cyberware-slot content with realpass condition entries associated with the body;
- active conditions, not six always-visible `OK` body-part tiles, are the selectable objects;
- selecting a condition/body region should reuse CDPR's existing anatomical zoom/drill-down language where technically possible;
- the zoomed view explains condition type, severity, functional consequence, biological vs chrome damage, external/internal bleeding, likely cause/how it occurred, protection/penetration context where useful, field treatment and professional-care requirements;
- ordinary context exposes plausible field care; ripperdoc/clinical context exposes professional biological care and mechanical cyberware repair;
- the current backpack Field Care popup becomes a prototype to retire after the Condition interface works.

This requires a new bounded injury-provenance/history record so the UI can explain how a condition arose. The regional injury model remains authoritative; event history is explanatory metadata, not a second injury system.

Evidence: public Cyberpunk scripts confirm the current cyberware/ripperdoc controller already owns anatomical slot anchors and paper-doll selection/zoom behavior, so this direction can target the native UI shell rather than copying another mod's menu.

Not claimed: no native Condition-mode implementation has yet been compiled/rendered. Exact mapping of left/right limb conditions onto the stock combined Arms/Legs zoom remains an implementation detail to test.

Next: document the canonical UI contract, add injury provenance to the realpass model/native wound commit path, then implement the smallest realpass-owned Condition-mode screen adapter that can compile against the installed game.

---

## 2026-09-13 — canonical agreed-goals ledger added; readiness reset to 45%

Branch: `chatgpt-continuation`
Commits: `1b52114`, `c0f18d0`
Files: `AGREED-GOALS.md`, `docs/PROJECT-STATUS.md`, this worklog

Added `AGREED-GOALS.md` at repository root as the canonical user-intent ledger with stable `G-###` identifiers and an explicit precedence rule. It records the fixed authored release, runtime ownership requirement, scope/exclusions, physical combat rules, no-healthbar requirement, Cyberware/Condition injury UI, treatment/recovery philosophy, one-package distribution target, patch-resilience architecture and testing safety rules.

`docs/PROJECT-STATUS.md` was refreshed so new/local agents are told to read the goal ledger first and no longer treat the earlier source-mod-integrated attended build or player-toggle settings architecture as the immediate target. The official conservative release-readiness estimate is now **45%**: the original models still count, but Dark Future/E3-dependent integration no longer counts as completed release integration.

Not claimed: adding a goal ledger does not implement the Condition UI or complete owned-runtime cleanup. Those remain active engineering work.

Next: keep every newly agreed product decision synchronized into `AGREED-GOALS.md`, then continue owned-runtime cleanup and Condition-mode implementation before the next user deployment/test.

---

## 2026-09-13 — first owned Cyberpunk 2.31 compile/preflight passed; readiness restored to 50%

Branch: `chatgpt-continuation`
Local candidate: `realpass-owned-preflight-20260913-201539-52d9961b`
Remote source immediately before documentation update: `2ccb67fb8f467237ec18a29b755f77e8a0e4253e`

The user ran `Prepare-OwnedSession.ps1` without `-Deploy` against the installed Steam Cyberpunk 2077 2.31 game. All 42 owned-path offline checks passed. The tool verified RED4ext 1.30.0 and redscript 0.5.31, then exact-compiled the complete owned source candidate successfully: **42 project-original REDscript sources** compiled to a temporary `final.redscripts`, and the final deployable owned runtime profile compiled successfully with **50 files**. The game cache was not modified; nothing was deployed or launched.

This local pass came after the compiler had already exposed and driven fixes for real integration mistakes: REDscript persistent initializer rules, project-owned method extension/wrapping boundaries, Ink text wrapping API usage, array helper syntax, provenance pruning, professional-care dispatch and native pain refresh ownership. The resulting source-mod-free candidate now has compiler evidence against the user's actual installed 2.31 scripts rather than only cloud/static confidence.

Not claimed: successful compilation is **not** gameplay validation. The owned runtime has not yet been installed, loaded in the game, rendered in the Cyberware/Condition UI, exercised through MaxDoc/body/combat/treatment flows, or proven across save/reload/quests/Phantom Liberty. No source-mod-residue-free live deployment has yet been verified.

Because a real release gate closed, the weighted readiness estimate moves from **45% to 50%**. The increase credits owned native compile compatibility and reproducible preflight only; it does not credit unobserved gameplay behavior.

Next: run `Prepare-OwnedSession.ps1 -Deploy`. It must establish a verified save backup, hash-verify the transaction and prove Dark Future/Project E3 runtime residue is absent. Only if the tool reports `READY` should the user launch normally through Steam for the first owned-runtime smoke test.

---

## 2026-09-13 — development install/recovery path deliberately simplified

Branch: `chatgpt-continuation`
Key commits/files: `tools/Install-OwnedRuntime.ps1`, `tools/Remove-OwnedRuntime.ps1`, `tools/Prepare-OwnedSession.ps1`, `tests/Test-OwnedSessionTool.ps1`, `AGREED-GOALS.md`, `manifest/acceptance.json`, `docs/PROJECT-STATUS.md`

The user explicitly rejected spending local iteration time on redundant save backups and multi-generation game-file rollback history. Their Cyberpunk saves are already protected externally/cloud-side, and stock-game repair can be delegated to Steam Verify Files or a reinstall if necessary.

The owned development path was therefore replaced with a deliberately flat model. `Prepare-OwnedSession.ps1` still runs the offline contracts and exact local compile before any install, but then plans only the current owned payload. `Install-OwnedRuntime.ps1` clears the project-owned `CyberpunkRealism` script namespace plus known retired Dark Future/Project E3 residue, writes the current compiled payload directly with per-file hash verification, and records one `owned-current.json` manifest. It does not traverse the six-receipt historical rollback chain, does not copy saves, and does not create another generation of game-file backups. `Remove-OwnedRuntime.ps1` removes matching files from that flat ownership record; if stock game bytes ever need repair, Steam Verify Files/reinstall is the recovery authority.

Important limitation recorded explicitly: Steam verification should not be assumed to remove arbitrary extra mod files. That is why the lightweight owned-file manifest/removal tool remains useful even though stock-game recovery is delegated to Steam.

Evidence so far: cloud CI for the first fast-installer policy batch passed; later documentation/acceptance synchronization is being kept under exact-head CI as usual. The prior local exact compile remains valid evidence for the REDscript source itself, but the new installer still needs one local attended run.

Not claimed: the fast installer has not yet been exercised on the user's machine, and the game still has not been launched with the owned runtime. Readiness remains **50%** until live deployment/gameplay evidence closes another gate.

Next: after exact-head CI is green, pull the simplified tooling and run `Prepare-OwnedSession.ps1 -Deploy`. The expected planning/install scope is the current ~50-file owned payload, not hundreds of historical receipt entries. If it reports `READY`, launch normally through Steam for the first owned-runtime smoke test.

---

## 2026-09-14 — completion branch rebuilt around Biology and a minimal owned runtime

Branch: `chatgpt-realpass-completion`
Base: new authoritative `main` at `44393b2`
Key files: `BiologyPresentation.reds`, `BiologyNativeUI.reds`, `NameplatesNative.reds`, `manifest/native-seams.json`, `manifest/runtime-modules.json`, `manifest/feature-inventory.json`, `manifest/acceptance.json`, `manifest/distribution.json`, `manifest/profiles.json`, `Build-OwnedRuntimeProfile.ps1`, updated architecture/acceptance docs and cloud tests

After the user moved the older branch to `main`, a fresh completion branch was created directly from that baseline with an explicit instruction not to merge until repository-side work was complete enough that the next meaningful step would be a real in-game test.

The body UI direction was completed around the newer product decision: **Backpack = possessions; Biology = embodied state.** The old `ConditionNativeUI.reds` / `CYBERWARE | CONDITION` prototype was removed from production. `BiologyPresentation.reds` now composes qualitative needs, pain/analgesia effects and active regional conditions without exposing native HP or hidden body quantities. `BiologyNativeUI.reds` mounts an owned dynamic Biology panel on the stock hub, provides condition detail, routes applicable dressing/support into the shared field-care runtime, and provides a ripperdoc-only Biology professional-care doorway without replacing the vanilla Cyberware equipment screen.

Biology's `Eat…`/`Drink…` path was hardened against public current Cyberpunk script APIs. It enumerates actual carried stacks through `TransactionSystem`, filters them through `CRItemServing`, requires a real stock action, preserves `Eat` and `Drink` actions where present with generic `Consume` only as the stock fallback, uses stock item-name localization/quantity data, and never removes inventory or calls body intake directly. The stock `ConsumeAction.CompleteAction` adapter remains the single intake commit into RealPass. The root-level panel also follows `MenuHubLogicController.SetActive(...)` so it closes/clears when the stock hub deactivates.

Presentation ownership was completed without carrying the old E3 runtime forward. The native modern scanner remains authoritative by absence of a replacement. `NameplatesNative.reds` adds only a scanned-civilian public-name fallback before the stock nameplate renderer runs; it respects stock quest-target state, hide-name flags, exact crowd nameplate policy, alternative identities and `ScannerModulePreset().ShoulShowName()`. A dedicated CI contract now forbids private-field access, unsupported forced-preset APIs, direct widget/health ownership and source-mod presentation dependencies.

The owned deployment profile was reduced from the historical framework stack to **project-original RealPass REDscript + pinned redscript only**. RED4ext, ArchiveXL, TweakXL, Codeware, Mod Settings and Input Loader are marked not required by the candidate; Dark Future/Project E3/game files remain blocked. Artifact policy rejects both blocked and currently unnecessary components so release packaging cannot silently grow back into a mod stack.

Architecture/status documents, runtime/feature/acceptance ledgers and the attended test plan were synchronized to the completed source rather than the earlier Condition/E3 assumptions. Core authorities are now described as source-complete but live-acceptance-pending. The 1.0 readiness estimate deliberately remains **50%** because live/native evidence has not yet closed a release gate; the repository-side live-test milestone is the thing being completed here.

Evidence obtained remotely: repeated GitHub Actions runs passed throughout the migration, including a green run after the Biology native Eat/Drink and lifecycle changes. Public Cyberpunk script references were used to audit the unique native boundaries for hub/ripperdoc controller signatures, Ink widget APIs, inventory enumeration/quantity/localization, item action helpers, nameplate visual-data wrapping, scanner/name visibility, quest state and alternative identity behavior. The final exact-head CI run remains the merge gate after the last documentation/test commit.

Not claimed: the **current** completion head has not yet been exact-compiled against Nat's installed Cyberpunk 2077 2.31 scripts, deployed, rendered or played. The successful 2026-09-13 exact compile predates the final Biology/nameplate source. That is intentionally the next authority after merge, not something remote source review can honestly substitute for.

Next: require green CI for the exact completion head; confirm the branch is strictly ahead of unchanged `main`; merge to `main`; then run `Prepare-OwnedSession.ps1` locally for a fresh exact compile/preflight, followed by `-Deploy` only if clean and then normal Steam launch using `docs/ATTENDED-ACCEPTANCE.md`.
