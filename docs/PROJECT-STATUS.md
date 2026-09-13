# realpass project status

Last updated: 2026-09-13
Working branch: `chatgpt-continuation`
Canonical product goals: `AGREED-GOALS.md`

## Release target

realpass is intended to become one coherent Cyberpunk 2077 + Phantom Liberty realism mod with a **realpass-owned executing runtime**. Dark Future and Project E3 HUD are reference/inspiration only; an accepted owned-runtime candidate may not require their scripts, assets, state machines, save state or gameplay/UI authority.

The target player experience is: download one release package, copy/extract it into the Cyberpunk 2077 game root (or run one equally simple installer if dependency licensing technically requires that route), then launch normally through Steam. No Vortex knowledge, source-mod stack management or persistent realpass launcher should be required.

The release is a fixed authored experience rather than a player-configurable module collection. Development builds retain internal gates so engineers can isolate body/combat/injury/presentation problems, but a normal release enables the accepted physical model together and keeps diagnostics off.

For the full current product decisions and precedence rules, read `AGREED-GOALS.md` first.

## Overall completion estimate

**45% toward a first credible 1.0 release.**

This estimate was deliberately reduced from the earlier 50% after the ownership requirement was tightened. Work that only functioned through Dark Future/Project E3 integration no longer receives release-completion credit. The source models remain valuable; the reduction reflects reopened integration/presentation gates, not lost simulation work.

| Workstream | Weight | Current completion | Weighted contribution | Notes |
| --- | ---: | ---: | ---: | --- |
| Scope, architecture and authority ownership | 10% | 95% | 9.5% | Product scope, fixed-release philosophy and owned-runtime requirement are explicit. |
| Body / needs / sleep / exertion | 20% | 50% | 10.0% | Substantial original models plus a new native-runtime direction exist; the Dark Future-free native path is not yet compile/game accepted. |
| Combat / injury / blood loss / armor | 25% | 40% | 10.0% | Original causal models are substantial; owned native routing and bounded provenance now exist, but gameplay calibration/acceptance remains incomplete. |
| Fixed release profile / development gates | 10% | 55% | 5.5% | Architecture now correctly treats modularity as development-only; earlier player-facing Mod Settings work is retired from the product path. |
| Presentation / condition UI / scanner / nameplates | 10% | 30% | 3.0% | No-healthbar, modern-scanner and Condition information architecture are defined, but the live Cyberware/Condition adapter and E3-independent nameplates are not yet native accepted. |
| Distribution / one-package installation | 10% | 20% | 2.0% | Safe deployment/rollback/artifact scaffolding exists, but the player artifact cannot be called owned/all-in-one until the new owned candidate path is complete. |
| Native gameplay, save and quest validation | 10% | 5% | 0.5% | Do not test the legacy integrated candidate as the intended product; first produce an owned-runtime compile candidate. |
| Documentation / handoff / reproducibility | 5% | 90% | 4.5% | `AGREED-GOALS.md`, architecture/status/worklog and acceptance docs preserve current product intent and handoff state. |
| **Total** | **100%** |  | **45.0%** | |

## Current known-good state

- `main` remains the local-agent baseline through `938c8b9`, including the modern-scanner restoration candidate and earlier presentation fixes.
- `chatgpt-continuation` contains the clarified realism scope, internal modular architecture, fixed-release configuration direction, ownership policy work and extensive original body/combat/injury models.
- `AGREED-GOALS.md` is the canonical user-intent ledger and supersedes conflicting older design text.
- Core realpass source includes original models for body/needs, ballistics/impact, localized injuries, blood loss, armor wear, impairment, field care and NPC injury progression.
- The body runtime now has direct native Cyberpunk lifecycle/consumable/time-skip hooks (`BodyNativeHooks.reds` plus realpass-owned body runtime/state) rather than using Dark Future as the body host.
- Dark Future preview/menu/intake/tick authority files were removed from the active production source path during the ownership pivot.
- The previously identified Dark Future dependencies in `FieldCareActionRuntime.reds` and `FieldCareItemUse.reds` have now been removed. The runtime-origin policy is part of cloud CI so any remaining production `module/import DarkFuture.*` reference fails closed.
- Bounded player injury provenance now records explanatory metadata only after an authoritative wound commit; it does not own damage/treatment state.
- `ConditionPresentation.reds` projects regional injury + provenance into qualitative condition descriptors without reading native HP.
- `docs/CONDITION-UI.md` defines the final injury UX: vanilla Cyberware/body shell, `CYBERWARE | CONDITION`, condition entries anchored to anatomy, native paper-doll zoom where possible, cause/protection explanation, field care in ordinary context and professional/mechanical care in ripperdoc context.
- The current backpack `FIELD CARE` popup is a prototype slated for retirement after the Condition interface replaces it and is no longer a release-path CI target.
- Traditional actor health bars remain outside the authored presentation target; generic objective/vehicle durability indicators are not blanket-suppressed.

## Principal release blockers

1. **Prove owned-runtime separation end-to-end.** Source-level Dark Future dependencies found so far have been removed, but the build/deploy path must also assemble from realpass-owned runtime files rather than inheriting the legacy source-mod-integrated deployment. Project E3 must likewise be absent from the owned runtime.
2. **Build an explicit owned-runtime candidate.** The candidate must be assembled from a realpass-owned manifest, machine-reject source-mod payloads/namespaces, exact-compile against the installed game, and exclude the retired backpack prototype once Condition mode is ready.
3. **Cyberware/Condition injury interface.** Implement the agreed body-screen Condition mode using the stock Cyberware/ripperdoc shell/zoom behavior where feasible and realpass-owned condition widgets/state.
4. **Provenance-to-UI acceptance.** The bounded provenance model exists; verify persistence, cause wording and left/right regional association in the live Condition interface without exposing raw simulation numbers.
5. **Exact local compilation.** Compile the owned candidate against the user's installed game/framework scripts before deployment. Fix signature/API issues at the thin adapter boundary.
6. **Broad native gameplay acceptance.** Validate player/NPC physical symmetry, no-healthbar feedback, localized injury, armor, bleeding, impairment, field/professional treatment, body progression, save/reload, bosses/MaxTac/nonlethal/quest protections and Phantom Liberty critical sequences.
7. **E3-independent presentation.** Recreate only the desired nameplate/HUD ideas with realpass-owned implementation; keep the native modern scanner authoritative.
8. **Player release artifact.** After runtime ownership and native behavior stabilize, produce the deterministic game-root-shaped release with hashes/notices/collision rules and simple install/update/rollback behavior.

## Immediate priority order

1. Treat `AGREED-GOALS.md` as the first read for every agent and keep it synchronized when the user makes a new explicit product decision.
2. Finish/verify owned-runtime source cleanup and replace the legacy inherited attended builder with an explicit owned candidate path before asking the user to deploy/test again.
3. Implement the Condition-mode native screen adapter on top of the existing provenance/condition descriptor layer, preserving regional physical state as authority.
4. Exact-compile the owned candidate against the user's Cyberpunk installation; use compilation failures to refine only thin native adapters.
5. Only after the owned-runtime compile is clean, deploy with verified save backup/rollback and run a broad attended session.
6. Convert native failures into narrow adapter/model/acceptance issues; do not solve them by reintroducing source-mod ownership or generic health-sponge scaling.

## Rules for future agents

- **Read `AGREED-GOALS.md` first.** Then read this file, `docs/WORKLOG.md`, `REALISM-SPEC.md`, `docs/MODULAR-ARCHITECTURE.md`, `docs/SETTINGS-ARCHITECTURE.md`, `docs/COMBAT-CALIBRATION.md` and relevant acceptance docs before changing behavior.
- If an older document conflicts with a locked goal in `AGREED-GOALS.md`, update the older document; do not reinterpret the goal to preserve legacy implementation.
- Update `AGREED-GOALS.md` whenever the user explicitly agrees to a new product goal. Give new decisions stable `G-###` identifiers.
- Update completion percentages only when a real release gate closes/reopens and explain the change in `docs/WORKLOG.md`.
- Do not label any candidate “owned-runtime” while Dark Future/Project E3 executing content remains required.
- Do not reactivate/deploy speculative body/combat code merely because offline tests pass; exact native compile/preflight comes first.
- Keep game files, saves, downloaded dependencies, generated staging state and deployment receipts out of the public repository.
- No unattended game launch, background watcher/logger/service or scheduled task may be introduced for testing.
- Prefer coherent reviewable batches over speculative patches.
