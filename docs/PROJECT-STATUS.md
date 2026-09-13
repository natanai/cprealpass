# realpass project status

Last updated: 2026-09-13
Working branch: `chatgpt-continuation`
Canonical product goals: `AGREED-GOALS.md`

## Release target

realpass is intended to become one coherent Cyberpunk 2077 + Phantom Liberty realism mod with a **realpass-owned executing runtime**. Dark Future and Project E3 HUD are reference/inspiration only; an accepted owned-runtime candidate may not require their scripts, assets, state machines, save state or gameplay/UI authority.

The project is explicitly **vanilla-first**: preserve CDPR item/system identities, names, animations, screens and assets wherever practical, and replace underlying behavior only where realism requires it. Do not import another mod's renames. MaxDoc remains MaxDoc; Bounce Back remains Bounce Back; Health Booster remains Health Booster.

The target player experience is: download one release package, copy/extract it into the Cyberpunk 2077 game root (or run one equally simple installer if dependency licensing technically requires that route), then launch normally through Steam. No Vortex knowledge, source-mod stack management or persistent realpass launcher should be required.

The release is a fixed authored experience rather than a player-configurable module collection. Development builds retain internal gates so engineers can isolate body/combat/injury/presentation problems, but a normal release enables the accepted physical model together and keeps diagnostics off.

For the full current product decisions and precedence rules, read `AGREED-GOALS.md` first.

## Overall completion estimate

**50% toward a first credible 1.0 release.**

The owned runtime has now passed the first exact local Cyberpunk 2.31 compile/preflight on the user's installed game. That closes the former compiler/signature gate and justifies restoring some of the readiness credit that was removed when the project abandoned Dark Future/Project E3 runtime ownership. The estimate remains conservative because nothing from this owned candidate has yet been deployed or observed in live gameplay.

| Workstream | Weight | Current completion | Weighted contribution | Notes |
| --- | ---: | ---: | ---: | --- |
| Scope, architecture and authority ownership | 10% | 95% | 9.5% | Product scope, fixed-release philosophy, vanilla-first identity and owned-runtime requirement are explicit. |
| Body / needs / sleep / exertion | 20% | 55% | 11.0% | Original models plus native runtime/hooks now exact-compile in the complete owned candidate; live behavior/calibration is still pending. |
| Combat / injury / blood loss / armor / pain | 25% | 45% | 11.25% | Original causal models and native adapters exact-compile together; physical outcomes, armor, pain/MaxDoc and treatment still need attended gameplay acceptance. |
| Fixed release profile / development gates | 10% | 55% | 5.5% | Architecture treats modularity as development-only; player gameplay/balance settings are retired from the product path. |
| Presentation / Condition UI / scanner / nameplates | 10% | 35% | 3.5% | No-healthbar and owned Cyberware/Condition adapters exact-compile; live rendering/interaction and E3-independent nameplates remain unaccepted. |
| Distribution / one-package installation | 10% | 25% | 2.5% | Owned build/preflight plus a fast flat install/removal path exists; public packaging is still blocked by live acceptance and final dependency audit. |
| Native gameplay, save and quest validation | 10% | 20% | 2.0% | Exact local compile/preflight is now proven; first owned-runtime deployment, save/reload, combat/body/Condition behavior and quest compatibility are still ahead. |
| Documentation / handoff / reproducibility | 5% | 95% | 4.75% | Goals, architecture/status/worklog, native-seam policy and attended acceptance path preserve current intent and reproducible evidence. |
| **Total** | **100%** |  | **50.0%** | |

## Current known-good state

- `main` remains the local-agent baseline through `938c8b9`, including the modern-scanner restoration candidate and earlier presentation fixes.
- `chatgpt-continuation` contains the clarified realism scope, internal modular development architecture, fixed-release direction, vanilla-first identity rule, ownership policy work and extensive original body/combat/injury models.
- `AGREED-GOALS.md` is the canonical user-intent ledger and supersedes conflicting older design text.
- Core realpass source includes original models for body/needs, ballistics/impact, localized injuries, blood loss, armor wear, impairment, field care, professional biological/mechanical care, pain/analgesia, injury provenance and NPC injury progression.
- The body runtime has direct native Cyberpunk lifecycle/consumable/time-skip hooks (`BodyNativeHooks.reds` plus realpass-owned body runtime/state) rather than using Dark Future as the body host.
- The production source tree is guarded by runtime-origin policy: owned gameplay source cannot import/use Dark Future or Project E3 as an executing runtime host.
- The obsolete Health-Booster-as-"Trauma Kit" field-care interceptor, Dark Future-derived localization layer and backpack `FIELD CARE` popup have been removed from production source rather than merely hidden from the candidate. Git history remains available if their old behavior needs to be studied.
- `Build-OwnedAcceptance.ps1` now compiles the complete current production REDscript tree and fails if retired bridge/prototype files reappear. There is no grandfathered production-source exception for those paths.
- `manifest/native-seams.json` plus `Test-NativeSeamPolicy.ps1` make patch-sensitive native-hook files explicit. Core simulation/model examples are forbidden from acquiring `@wrapMethod`/`@replaceMethod`/`@addMethod`/`@addField` hooks without an intentional seam-policy change.
- MaxDoc is mapped by its **vanilla** `FirstAidWhiff` consumable identity at the native `UseHealChargeAction` status-effect boundary. The intended realpass effect is analgesia only; the stock HP-regeneration effect is skipped while the vanilla item identity/use flow is retained. Bounce Back/Health Booster are not aliases for MaxDoc and await their own realistic roles.
- `FieldCareActionRuntime.reds` uses native menu/gameplay state rather than Dark Future services. Dressing and limb support use separate field-supply paths; MaxDoc is not wound-care currency.
- Bounded player injury provenance records explanatory metadata only after an authoritative wound commit; it does not own damage/treatment state.
- `ConditionPresentation.reds` projects regional injury + provenance + qualitative pain into condition descriptors without reading native HP.
- `ConditionNativeUI.reds` contains the first owned native `CYBERWARE | CONDITION` slice on the stock Cyberware/ripperdoc controller, including active-condition listing, stock paper-doll selection/zoom calls, field-care controls and ripperdoc clinical/mechanical controls. It now exact-compiles against the user's installed 2.31 scripts; live rendering/input acceptance is still pending.
- `docs/CONDITION-UI.md` defines the final injury UX: vanilla Cyberware/body shell, `CYBERWARE | CONDITION`, condition entries anchored to anatomy, native paper-doll zoom where possible, cause/protection explanation, field care in ordinary context and professional/mechanical care in ripperdoc context.
- `Build-OwnedRuntimeProfile.ps1` layers only the pinned generic `RED4ext + redscript` base under the owned source candidate, rejects Dark Future/Project E3/Mod Settings/Input Loader payloads, and exact-compiles the final deployment manifest.
- `Prepare-OwnedSession.ps1` now uses `Install-OwnedRuntime.ps1` for the development install path. It exact-compiles first, plans only the current flat payload, directly replaces the current realpass-owned script namespace, removes known retired Dark Future/Project E3 runtime residue, verifies every copied payload hash, records one flat `owned-current.json`, and checks source-mod isolation. It does **not** traverse old rollback chains or create an extra local save backup.
- `Remove-OwnedRuntime.ps1` is the lightweight realpass cleanup path. It removes recorded realpass-installed files whose hashes still match. If stock game bytes ever need repair, use Steam **Verify Files** or reinstall; Steam verification is not expected to remove arbitrary extra mod files on its own.
- On 2026-09-13, owned preflight build `realpass-owned-preflight-20260913-201539-52d9961b` passed all 42 cloud-safe/offline checks and exact-compiled **42 project-original REDscript sources** against the installed Cyberpunk 2.31 scripts. The final deployable owned profile also exact-compiled with **50 files**. The game cache was not modified and nothing was deployed or launched.
- Traditional actor health bars remain outside the authored presentation target; generic objective/vehicle durability indicators are not blanket-suppressed.
- Exact-head cloud CI is required before moving to local acceptance; cloud success remains architecture/model evidence only, not gameplay acceptance.

## Principal release blockers

1. **First owned-runtime live deployment and smoke test.** Exact compilation is now clean. The next gate is the fast flat `Prepare-OwnedSession.ps1 -Deploy` install followed by a manual launch through Steam and a short smoke test proving the game boots, scripts load and the owned runtime is actually active.
2. **Cyberware/Condition live acceptance.** The agreed Condition mode exact-compiles, but its dynamic Ink layout, `CYBERWARE | CONDITION` toggle, active-condition list, paper-doll zoom behavior and treatment controls must be verified in the stock screen.
3. **First attended combat/injury/pain/treatment acceptance.** Validate physical combat, armor, wounds, bleeding, impairment, pain/MaxDoc, no-healthbar feedback, Condition treatment and persistence together.
4. **Provenance-to-UI acceptance.** Verify persistence, cause wording and left/right regional association in the live Condition interface without exposing raw simulation numbers.
5. **Body native calibration.** Validate real game clock rate, consumption, sleep/wait distinction, exertion, washing/bathroom interactions and save/reload under the owned runtime.
6. **Special combat compatibility.** Validate bosses/MaxTac, authored immunity/quest protections, nonlethal paths, NPC persistence/AI effects and Phantom Liberty critical sequences.
7. **E3-independent presentation.** Recreate only desired nameplate/HUD ideas with realpass-owned implementation; keep the native modern scanner authoritative.
8. **Player release artifact.** After runtime ownership and native behavior stabilize, produce the deterministic game-root-shaped release with hashes/notices/ownership records and a simple install/update/uninstall path.

## Immediate priority order

1. Treat `AGREED-GOALS.md` as the first read for every agent and keep it synchronized when the user makes a new explicit product decision.
2. Keep the cloud-owned-path suite green and use it to reject architecture regressions, including native-hook code leaking out of the explicit seam allowlist.
3. Run the first **fast owned deployment** with `Prepare-OwnedSession.ps1 -Deploy`. It should exact-compile, install only the current 50-file owned profile, clean retired source-mod residue, verify installed bytes and stop at `READY` without walking historical rollback receipts or copying saves.
4. If deployment reports `READY`, launch Cyberpunk normally through Steam and perform a short boot/load/save smoke test before deliberately exercising combat/body/Condition systems.
5. Then run one broad attended combat + injury + pain + Condition treatment session using `docs/ATTENDED-ACCEPTANCE.md` as the checklist.
6. Convert native/runtime failures into narrow adapter/model/acceptance issues; do not solve them by reintroducing source-mod ownership, item renames or generic health-sponge scaling.

## Rules for future agents

- **Read `AGREED-GOALS.md` first.** Then read this file, `docs/WORKLOG.md`, `REALISM-SPEC.md`, `docs/MODULAR-ARCHITECTURE.md`, `docs/COMBAT-CALIBRATION.md` and relevant acceptance docs before changing behavior.
- If an older document conflicts with a locked goal in `AGREED-GOALS.md`, update the older document; do not reinterpret the goal to preserve legacy implementation.
- Update `AGREED-GOALS.md` whenever the user explicitly agrees to a new product goal. Give new decisions stable `G-###` identifiers.
- Preserve vanilla item/system identity unless a new explicit user decision says otherwise. Change mechanics under CDPR identities rather than importing source-mod names.
- Keep patch-sensitive hooks at explicit native seams. Do not move engine-version-specific annotations/types into pure simulation models merely because it is convenient.
- Update completion percentages only when a real release gate closes/reopens and explain the change in `docs/WORKLOG.md`.
- Do not label any candidate “owned-runtime” while Dark Future/Project E3 executing content remains required.
- Do not treat a successful exact compile as gameplay validation; the first owned deployment and attended live session are now the next authority.
- Keep game files, saves, downloaded dependencies, generated staging state and local install-state files out of the public repository.
- Do not reintroduce heavy local rollback/save-backup machinery into the normal development path unless the project owner explicitly asks for it. Flat owned-file tracking plus Steam repair is the accepted recovery model.
- No unattended game launch, background watcher/logger/service or scheduled task may be introduced for testing.
- Prefer coherent reviewable batches over speculative patches.
