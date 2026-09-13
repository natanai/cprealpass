# realpass project status

Last updated: 2026-09-13
Working branch: `chatgpt-continuation`
Canonical product goals: `AGREED-GOALS.md`

## Release target

realpass is intended to become one coherent Cyberpunk 2077 + Phantom Liberty realism mod with a **realpass-owned executing runtime**. Dark Future and Project E3 HUD are reference/inspiration only; an accepted owned-runtime candidate may not require their scripts, assets, state machines, save state or gameplay/UI authority.

The project is now explicitly **vanilla-first**: preserve CDPR item/system identities, names, animations, screens and assets wherever practical, and replace the underlying behavior only where realism requires it. Do not import another mod's renames. MaxDoc remains MaxDoc; Bounce Back remains Bounce Back; Health Booster remains Health Booster.

The target player experience is: download one release package, copy/extract it into the Cyberpunk 2077 game root (or run one equally simple installer if dependency licensing technically requires that route), then launch normally through Steam. No Vortex knowledge, source-mod stack management or persistent realpass launcher should be required.

The release is a fixed authored experience rather than a player-configurable module collection. Development builds retain internal gates so engineers can isolate body/combat/injury/presentation problems, but a normal release enables the accepted physical model together and keeps diagnostics off.

For the full current product decisions and precedence rules, read `AGREED-GOALS.md` first.

## Overall completion estimate

**45% toward a first credible 1.0 release.**

This estimate remains conservative until the new owned runtime exact-compiles and runs on the user's installed game. The model/test work and deployment tooling are materially stronger, but local native acceptance—not additional scaffolding—is the next release gate that changes this percentage.

| Workstream | Weight | Current completion | Weighted contribution | Notes |
| --- | ---: | ---: | ---: | --- |
| Scope, architecture and authority ownership | 10% | 95% | 9.5% | Product scope, fixed-release philosophy, vanilla-first identity and owned-runtime requirement are explicit. |
| Body / needs / sleep / exertion | 20% | 50% | 10.0% | Substantial original models plus native runtime/hooks exist; the owned native path is not yet local compile/game accepted. |
| Combat / injury / blood loss / armor / pain | 25% | 40% | 10.0% | Original causal models, regional injury, pain/MaxDoc, treatment and native adapters are substantial; native calibration/acceptance remains incomplete. |
| Fixed release profile / development gates | 10% | 55% | 5.5% | Architecture treats modularity as development-only; player gameplay/balance settings are retired from the product path. |
| Presentation / Condition UI / scanner / nameplates | 10% | 30% | 3.0% | No-healthbar, modern-scanner and first owned Cyberware/Condition adapter exist in source; live rendering/interaction and E3-independent nameplates are not native accepted. |
| Distribution / one-package installation | 10% | 20% | 2.0% | Owned development profile + safe deployment/rollback path exist, but the public player artifact is still blocked by native acceptance, presentation ownership and final dependency audit. |
| Native gameplay, save and quest validation | 10% | 5% | 0.5% | The next meaningful evidence is exact local compile/preflight, then attended owned-runtime gameplay—not the legacy integrated candidate. |
| Documentation / handoff / reproducibility | 5% | 90% | 4.5% | `AGREED-GOALS.md`, architecture/status/worklog and acceptance docs preserve current product intent and handoff state. |
| **Total** | **100%** |  | **45.0%** | |

## Current known-good state

- `main` remains the local-agent baseline through `938c8b9`, including the modern-scanner restoration candidate and earlier presentation fixes.
- `chatgpt-continuation` contains the clarified realism scope, internal modular development architecture, fixed-release direction, vanilla-first identity rule, ownership policy work and extensive original body/combat/injury models.
- `AGREED-GOALS.md` is the canonical user-intent ledger and supersedes conflicting older design text.
- Core realpass source includes original models for body/needs, ballistics/impact, localized injuries, blood loss, armor wear, impairment, field care, professional biological/mechanical care, pain/analgesia, injury provenance and NPC injury progression.
- The body runtime has direct native Cyberpunk lifecycle/consumable/time-skip hooks (`BodyNativeHooks.reds` plus realpass-owned body runtime/state) rather than using Dark Future as the body host.
- The production source tree is guarded by runtime-origin policy: owned gameplay source cannot import/use Dark Future or Project E3 as an executing runtime host.
- The obsolete Health-Booster-as-"Trauma Kit" field-care interceptor has been removed. It is not part of the owned source tree.
- MaxDoc is now mapped by its **vanilla** `FirstAidWhiff` consumable identity at the native `UseHealChargeAction` status-effect boundary. The intended realpass effect is analgesia only; the stock HP-regeneration effect is skipped while the vanilla item identity/use flow is retained. Bounce Back/Health Booster are not aliases for MaxDoc and await their own realistic roles.
- `FieldCareActionRuntime.reds` uses native menu/gameplay state rather than Dark Future services. Dressing and limb support use separate field-supply paths; MaxDoc is not wound-care currency.
- Bounded player injury provenance records explanatory metadata only after an authoritative wound commit; it does not own damage/treatment state.
- `ConditionPresentation.reds` projects regional injury + provenance + qualitative pain into condition descriptors without reading native HP.
- `ConditionNativeUI.reds` contains the first owned native `CYBERWARE | CONDITION` slice on the stock Cyberware/ripperdoc controller, including active-condition listing, stock paper-doll selection/zoom calls, field-care controls and ripperdoc clinical/mechanical controls. Exact live rendering/input acceptance is still pending.
- `docs/CONDITION-UI.md` defines the final injury UX: vanilla Cyberware/body shell, `CYBERWARE | CONDITION`, condition entries anchored to anatomy, native paper-doll zoom where possible, cause/protection explanation, field care in ordinary context and professional/mechanical care in ripperdoc context.
- The current backpack `FIELD CARE` popup is historical prototype evidence. `Build-OwnedAcceptance.ps1` excludes it from the intended owned acceptance runtime.
- `Build-OwnedAcceptance.ps1` creates an immutable source-only owned candidate, opens body/combat gates only in staged copies, reruns origin policy, and exact-compiles against the installed game without deploying.
- `Build-OwnedRuntimeProfile.ps1` layers only the pinned generic `RED4ext + redscript` base under that owned source candidate, rejects Dark Future/Project E3/Mod Settings/Input Loader payloads, and exact-compiles the final deployment manifest.
- `Prepare-OwnedSession.ps1` provides the safe local path: compile + transaction preflight by default; `-Deploy` additionally requires a verified save backup, performs hash-verified deploy/upgrade, checks for source-mod runtime residue, and rolls back if post-deploy isolation fails. It never launches Cyberpunk.
- Traditional actor health bars remain outside the authored presentation target; generic objective/vehicle durability indicators are not blanket-suppressed.

## Principal release blockers

1. **Exact local owned-runtime compilation.** The source-only and deployable owned builders are ready for local preflight, but only the user's installed Cyberpunk 2.31 script bundle can prove the current native hook signatures/types compile together. The newly corrected MaxDoc `UseHealChargeAction.ProcessStatusEffects` hook is specifically part of this gate.
2. **Cyberware/Condition live acceptance.** The agreed Condition mode now exists in source, but its dynamic Ink layout, `CYBERWARE | CONDITION` toggle, active-condition list, paper-doll zoom behavior and treatment controls must be verified in the stock screen.
3. **First attended combat/injury/pain/treatment acceptance.** Once exact local compile is clean, deploy the owned candidate through the save-backed session path and validate physical combat, armor, wounds, bleeding, impairment, pain/MaxDoc, no-healthbar feedback, Condition treatment and persistence together.
4. **Provenance-to-UI acceptance.** Verify persistence, cause wording and left/right regional association in the live Condition interface without exposing raw simulation numbers.
5. **Body native calibration.** Validate real game clock rate, consumption, sleep/wait distinction, exertion, washing/bathroom interactions and save/reload under the owned runtime.
6. **Special combat compatibility.** Validate bosses/MaxTac, authored immunity/quest protections, nonlethal paths, NPC persistence/AI effects and Phantom Liberty critical sequences.
7. **E3-independent presentation.** Recreate only desired nameplate/HUD ideas with realpass-owned implementation; keep the native modern scanner authoritative.
8. **Player release artifact.** After runtime ownership and native behavior stabilize, produce the deterministic game-root-shaped release with hashes/notices/collision rules and simple install/update/rollback behavior.

## Immediate priority order

1. Treat `AGREED-GOALS.md` as the first read for every agent and keep it synchronized when the user makes a new explicit product decision.
2. Keep the cloud-owned-path suite green and use it to reject architecture regressions, while recognizing it cannot prove Cyberpunk native compatibility.
3. Run one **compile/preflight-only owned session on the user's PC**. Do not deploy on the first attempt. Fix exact native compile/signature problems until preflight is clean.
4. If the Condition adapter compiles, use the same local preflight to verify there are no hidden Dark Future/E3 runtime requirements and no stale item-rename path.
5. Once owned preflight is clean, deploy with verified save backup/rollback and run one broad combat + injury + pain + Condition treatment attended session.
6. Convert native failures into narrow adapter/model/acceptance issues; do not solve them by reintroducing source-mod ownership, item renames or generic health-sponge scaling.

## Rules for future agents

- **Read `AGREED-GOALS.md` first.** Then read this file, `docs/WORKLOG.md`, `REALISM-SPEC.md`, `docs/MODULAR-ARCHITECTURE.md`, `docs/COMBAT-CALIBRATION.md` and relevant acceptance docs before changing behavior.
- If an older document conflicts with a locked goal in `AGREED-GOALS.md`, update the older document; do not reinterpret the goal to preserve legacy implementation.
- Update `AGREED-GOALS.md` whenever the user explicitly agrees to a new product goal. Give new decisions stable `G-###` identifiers.
- Preserve vanilla item/system identity unless a new explicit user decision says otherwise. Change mechanics under CDPR identities rather than importing source-mod names.
- Update completion percentages only when a real release gate closes/reopens and explain the change in `docs/WORKLOG.md`.
- Do not label any candidate “owned-runtime” while Dark Future/Project E3 executing content remains required.
- Do not deploy speculative body/combat code merely because cloud/offline tests pass; exact local native compile/preflight comes first.
- Keep game files, saves, downloaded dependencies, generated staging state and deployment receipts out of the public repository.
- No unattended game launch, background watcher/logger/service or scheduled task may be introduced for testing.
- Prefer coherent reviewable batches over speculative patches.
