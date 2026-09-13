# realpass attended acceptance batch

This is the primary player-attended test plan for the first broad realpass candidate. It is intentionally larger than the earlier micro-tests: the goal is to experience body simulation, presentation, combat, localized injury, armor, blood loss, impairment and field care together while still collecting enough structure to identify which authority failed.

The test is **not** permission to promote the source activation gates. `BodyRuntime.reds` and `CombatNativeBridge.reds` stay disabled in canonical source. `tools/Build-AttendedAcceptance.ps1` creates a new immutable local manifest with body and combat enabled, compiles that exact profile, adds the no-traditional-healthbar presentation by default, and stops before live deployment.

## Candidate contract

Default broad attended candidate:

- body simulation: **on**
- combat physical bridge: **on**
- localized injury / blood loss / impairment / armor / treatment: active only through their existing native safety and eligibility gates
- traditional player health/overshield bars and HP numbers: **hidden**
- ordinary NPC health bars and damage-preview bars: **hidden**
- dedicated boss / MaxTac health bar: **hidden**
- dedicated companion/Flathead actor health bar: **hidden**
- generic objective/vehicle durability UI: **not intentionally hidden**; those can communicate mission state rather than an actor's HP
- NPC names / scanner presentation: retained according to authored/native visibility rules
- RAM, buffs and other non-health player biomonitor information: not intentionally hidden by the no-healthbar module
- diagnostics: **off** unless the tester explicitly requests a diagnostic build
- no background logger, watcher, recorder, service or scheduled task

The no-healthbar rule is presentation only. It must not change health, overshield state, damage, one-shot protection, boss logic, quest immunity, wound calculation or treatment state.

## Preferred operator path

`tools/Prepare-AttendedSession.ps1` is the preferred entry point once the PC is available. It is intentionally safe to run before the player is ready to launch the game. The ordinary path no longer requires the player or local agent to invent a build ID or remember a manifest name.

With no source-manifest argument, it reads the verified current deployment pointer and automatically uses `manifest/<current buildId>.deployment.json` as the base. With no build ID, it creates a unique immutable ID containing the mode, UTC timestamp and a random suffix.

First run the one-command compile/preflight:

```powershell
pwsh ./tools/Prepare-AttendedSession.ps1
```

That command does **not** alter the game. It validates the current source manifest and every source hash, requires the full body -> combat -> armor -> wound -> blood loss -> impairment -> field-care chain, generates an immutable candidate, compiles the exact candidate against the installed Cyberpunk 2077 scripts, and runs the real upgrade planner in `-WhatIf` mode.

Only after that preflight passes, while the player is present and the game is stopped, run:

```powershell
pwsh ./tools/Prepare-AttendedSession.ps1 -Deploy
```

This creates a **new** immutable deployment ID automatically, repeats exact build/compile/preflight, establishes a verified save backup, performs the reversible upgrade, verifies the deployment receipt and then stops. It does **not** launch Cyberpunk. A local agent may supply `-BuildId` or `-SourceManifestPath` explicitly when diagnosing/reproducing a particular case, but the normal operator path should not need them.

`-Diagnostics` is an explicit second-pass troubleshooting mode, not the ordinary feel-test default. `-ShowTraditionalHealthBars` exists only as a comparison/debug build; the authored realpass default is health bars hidden.

If auto-discovery reports that the current build manifest is missing, recover/reconstruct that local manifest rather than guessing. If it reports that the current manifest lacks any required broad-runtime file, rebuild a coherent combined base before testing; do not interpret a partial profile as combat balance evidence.

## Before the session

1. Sync `chatgpt-continuation` and verify the current GitHub CI head is green.
2. Confirm Cyberpunk 2077 is fully stopped.
3. Run `pwsh ./tools/Prepare-AttendedSession.ps1` and require the exact compile + upgrade preflight to pass.
4. For the live candidate, run `pwsh ./tools/Prepare-AttendedSession.ps1 -Deploy` so a verified save backup and reversible receipt exist before any game-file changes.
5. Use a save where ordinary open-world combat can be tested without immediately entering a critical quest sequence.
6. Keep diagnostics off for the first feel pass.

A future agent operating on the user's PC should perform these setup steps directly rather than asking the player to manually edit files or assemble manifests.

## Session A — presentation and baseline body state

Before firing a weapon, establish that the test build is behaving as one coherent profile.

- Load normally and remain idle for a minute.
- Confirm no traditional player HP bar, HP number or overshield bar is visible, including after drawing a weapon and entering ordinary combat readiness.
- If Overclock is available, activate/deactivate it and confirm the direct Overclock visibility path does not re-show HP while RAM/Overclock information still behaves normally.
- If an overshield effect is available, gain/lose it and confirm the dedicated overshield evaluator does not re-show a continuous bar while the underlying effect still functions.
- Confirm RAM/quickhack information still works when appropriate; hiding HP must not blank the whole biomonitor root.
- Scan an ordinary civilian. Confirm the permitted public/display name behavior still works and no empty nameplate rectangle appears.
- Scan or focus an ordinary hostile. Confirm no NPC HP bar or damage-preview bar appears before or after damage.
- If a reproducible companion/Flathead health HUD is available, confirm the actor HP bar stays hidden without breaking companion/mission behavior.
- Confirm objective/vehicle durability indicators still appear when a mission genuinely uses them; realpass must not remove required non-actor mission feedback merely because it resembles a bar.
- Confirm minimap/compass/interaction presentation has not regressed from the current accepted local candidate.
- Eat/drink once, perform the toilet interaction once, and observe that body state continues without duplicate interactions or labels.
- Sprint or otherwise exert V enough to observe recovery behavior. Exertion should recover; it must not become a permanent generic debuff.

If the HUD root disappears entirely, RAM disappears unexpectedly, names become empty rectangles, objective UI is lost, or the game reports script compilation errors, stop the batch before combat conclusions are drawn.

## Session B — ordinary unarmored combat

Use ordinary non-quest human enemies first. Do not start with bosses, MaxTac, drones or scripted invulnerable actors.

Test both directions of damage.

### V attacks NPC

- Fire a small number of controlled shots at torso, arm, leg and head across separate targets where practical.
- Observe whether hits feel physical rather than level/HP-sponge driven.
- Confirm no traditional enemy HP bar or damage-preview bar appears after the hit.
- Confirm NPC name/affiliation presentation can remain visible independently of HP.
- Watch for regional consequences: movement/function changes should correspond to the struck region rather than generic global slowdown.
- A stopped or non-penetrating impact may cause blunt injury, but must not create an open projectile bleeding tract.
- Mechanical/cyberware-only contact must not manufacture biological bleeding.

### NPC attacks V

- Allow a controlled ordinary enemy to hit V without immediately attempting a lethal stress test.
- Confirm V receives the same physical injury model rather than a separate arcade-only path.
- Confirm V's HP/overshield bars remain hidden throughout damage and recovery.
- Look for physical consequences that can replace a bar as feedback: regional movement/handling impairment, blood-loss effects, contextual injury cues and treatment need.
- Verify the absence of a bar does not make combat state itself malfunction (healing/treatment, death, native protections and save state remain functional).

The desired feel is uncertainty about exact remaining HP, **not** uncertainty about whether V is injured. Injury feedback should come from consequences and contextual cues rather than a continuously exposed numerical reservoir.

## Session C — armor and cyberware

Use clearly different protection cases rather than judging armor from one outfit.

- Hit a region with no mapped protective coverage and compare it to a mapped torso-protective item.
- Confirm torso armor does not magically protect uncovered arms/legs.
- Repeated impacts should be capable of wearing the impacted protection region without duplicating one impact into multiple wear commits.
- Ordinary cosmetic clothing must not silently become ballistic armor.
- Test at least one mapped mechanical/cyberware contact if a reliable target is available. Structural damage may occur; biological bleeding should not be created solely because the struck material is mechanical.
- If a stock item cannot be mapped confidently, the safe behavior is unresolved/fallback—not invented protection.

Do not use this session to tune final coefficients from one encounter. The immediate gate is causality, coverage and consistency.

## Session D — bleeding, impairment and field care

Once a controlled injury is present:

- Wait long enough to establish whether external/internal bleeding progresses with game time rather than frame rate.
- Verify dressing an external wound changes subsequent external bleeding but does not cure unrelated internal injury.
- Verify limb support improves function without instantly healing bone damage.
- Begin treatment and interrupt it by movement/combat/menu boundary where practical. Interrupted treatment must not consume supplies or apply the completed result.
- Complete treatment normally. Item debit and treatment application should happen exactly once.
- Confirm injury-related movement/weapon penalties clear or improve only when the underlying model says they should, and do not stack endlessly on refresh/weapon swap.
- Save with a nontrivial injury, reload, and verify persistent state is neither duplicated nor silently healed/refilled.

## Session E — time, sleep and broad body integration

After combat, continue the same save rather than immediately resetting it.

- Eat/drink and allow ordinary game time to advance.
- Sleep/wait once and verify the body clock advances coherently rather than double-counting time.
- Observe recovery from exertion and injury across the time transition.
- Confirm severe blood-loss consequences do not replay old accumulated exposure after load/restore.
- Verify bathroom/washing interactions remain usable and do not become combat-owned systems.
- Save/reload again after the time transition.

The point is to catch cross-system failures that isolated fixture tests cannot expose: duplicated clocks, stale listeners, repeated damage delivery, lost persistent state and source-mod systems fighting for the same authority.

## Session F — protected and unusual actors

Only after ordinary combat behaves coherently:

- test a boss or MaxTac actor while confirming the dedicated boss health bar stays hidden;
- test an authored quest-protected or one-shot-protected actor and verify realpass respects final native protection rather than bypassing it;
- test a defeated/nonlethal outcome and confirm injury does not force an unintended kill;
- test a drone/mechanical target and confirm unsupported biological wound routing is rejected;
- test a companion actor if available and confirm healthbar suppression does not interfere with its scripted lifecycle;
- test combat near a quest/dialogue transition and a Phantom Liberty encounter when a safe reproducible point is available.

A boss taking more punishment because of an explicitly authored protection rule is acceptable; a physically identical ordinary human becoming a sponge merely because of level/max-HP inflation is not the intended model.

## What to record

The player should not need to run diagnostics for the first feel pass. Record observations in plain language first:

- weapon / rough target type;
- body region hit;
- obvious armor/cyberware context;
- what happened immediately;
- what changed over the next several seconds/minutes;
- whether the result felt too weak, too strong or physically implausible;
- whether any traditional actor HP/overshield bar appeared and what caused it;
- whether a nameplate, scanner, RAM or other unrelated UI element disappeared;
- whether objective/vehicle mission feedback disappeared unexpectedly;
- whether treatment/reload/save changed the result unexpectedly.

Only if an observation cannot be explained should a second build enable the explicit attended diagnostics switch. Diagnostics are for resolving a concrete discrepancy, not for turning ordinary play into a telemetry session.

## Promotion gates after the batch

Do not call combat accepted just because the game launches. Promotion requires, at minimum:

- exact candidate compiles and deploys/rolls back cleanly;
- player and ordinary NPC physical hit paths work in both directions;
- no traditional actor HP bars appear for V, ordinary NPCs, bosses or dedicated companion HUDs in the default presentation, including Overclock/overshield state changes;
- healthbar suppression does not hide RAM/buffs/names or mutate health/overshield state;
- objective/vehicle mission-state UI remains available where required;
- regional armor coverage and mechanical-vs-biological routing behave coherently;
- bleeding/impairment/treatment operate without duplicates or orphaned modifiers;
- save/reload does not replay, duplicate or erase live injury state;
- native quest/boss/nonlethal protections remain authoritative;
- no severe script errors, runaway callbacks, obvious performance degradation or quest blockers are observed.

Failures should become specific acceptance-ledger entries. Do not compensate for a failed native binding by loosening the physical model or by reintroducing level-scaling/health-sponge behavior.
