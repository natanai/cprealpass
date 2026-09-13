# realpass owned attended acceptance batch

Status: canonical local test plan for the first broad owned-runtime candidate
Last updated: 2026-09-13
Governing goals: `AGREED-GOALS.md`

This is the primary player-attended test plan for the first broad **owned** realpass candidate. The goal is to experience the vanilla game with realpass mechanics substituted underneath it: body simulation, physical combat, localized injury, armor, blood loss, impairment, pain/MaxDoc, Condition inspection, field treatment and professional repair should behave as one causal system.

This document supersedes the earlier Dark Future/E3-based attended workflow. Do not use the legacy `Prepare-AttendedSession.ps1` path for product acceptance.

## Candidate contract

The ordinary broad owned candidate should have:

- realpass body simulation enabled;
- realpass combat/ballistics/wound routing enabled;
- localized injury, blood loss, impairment, armor wear, pain and treatment enabled through their native safety/eligibility gates;
- traditional V/NPC/boss/companion actor health bars hidden;
- generic objective/vehicle durability UI left intact where it communicates mission state;
- native modern scanner/quickhack behavior authoritative;
- vanilla item identities preserved;
- MaxDoc still presented/used as MaxDoc, with realpass replacing its HP-regeneration effect with analgesia only;
- Bounce Back and Health Booster kept distinct from MaxDoc and not silently renamed;
- `CYBERWARE | CONDITION` mounted onto the stock Cyberware/ripperdoc body screen;
- no Dark Future or Project E3 executing content;
- diagnostics off unless explicitly requested for a second-pass investigation;
- no background logger, watcher, recorder, service, launcher or scheduled task.

Canonical source gates remain fail-closed. The owned builder opens body/combat only in immutable staged copies for this exact candidate.

## Preferred operator path

The only normal acceptance entry point is:

```powershell
pwsh ./tools/Prepare-OwnedSession.ps1
```

Run that **first** with Cyberpunk fully stopped. It:

1. creates a fresh immutable owned build ID;
2. builds from the project-original realpass source tree rather than the currently installed gameplay-mod stack;
3. rejects forbidden source-mod runtime dependencies;
4. layers only the audited generic runtime base required by the owned profile;
5. exact-compiles the candidate against the installed Cyberpunk 2077 environment;
6. runs the real deployment/upgrade planner in `-WhatIf` mode;
7. writes an attended preflight report and stops without changing game files.

A successful first run must end with the equivalent of:

`PASS: owned candidate ... exact-compiled and deployment preflight passed ... Nothing was deployed.`

Do **not** infer gameplay success from this. It only establishes that the exact candidate can compile and can be transacted safely.

Only after that preflight is clean should the attended deployment be run:

```powershell
pwsh ./tools/Prepare-OwnedSession.ps1 -Deploy
```

The deploy path creates another immutable build, redoes exact compilation/preflight, establishes a verified save backup, deploys/replaces the runtime, hash-verifies the receipt, checks that Dark Future/Project E3 executing residue is absent, and rolls back automatically if owned-runtime isolation fails. It does not launch Cyberpunk.

The successful deploy marker is:

`READY: owned runtime ... is deployed, hash-verified, source-mod-residue-free, and protected by a verified save backup.`

After that, launch Cyberpunk normally through Steam.

## Stop-before-gameplay conditions

Do not launch the candidate for acceptance if any of these occur:

- redscript/native compilation error;
- unresolved deployment collision;
- source-mod residue remains after deployment;
- save backup cannot be verified;
- candidate manifest is incomplete;
- exact MaxDoc/`UseHealChargeAction` hook does not compile;
- Condition/Cyberware controller hook does not compile;
- no-healthbar controller hook does not compile.

Fix the adapter/profile first. Do not loosen the physical model or reintroduce Dark Future/E3 to make compilation pass.

## Session A — vanilla identity and baseline presentation

Before combat, establish that realpass feels like modified vanilla Cyberpunk rather than a parallel mod UI stack.

- Open the normal menus, scanner and Cyberware screen. Confirm the game still presents CDPR's ordinary item/system identities.
- Confirm MaxDoc is still named/presented as MaxDoc; Bounce Back and Health Booster retain their own vanilla identities.
- Confirm the native modern scanner/quickhack flow opens, targets and closes normally.
- Confirm no traditional V HP/HP-number/overshield bar is continuously visible.
- If Overclock or an overshield is available, exercise it and verify those direct visibility paths do not resurrect the HP bar while RAM/status feedback remains usable.
- Scan/focus ordinary civilians and hostiles. Names/identity information may remain, but ordinary actor HP/damage-preview bars should not appear.
- Confirm mission/objective or vehicle durability UI still appears where genuinely required.
- Eat/drink once and verify body intake does not duplicate or rename stock consumables.
- Exercise V enough to observe that exertion can recover instead of becoming a permanent generic penalty.

Stop before combat conclusions if the whole biomonitor disappears, the scanner breaks, vanilla item names are unexpectedly rewritten, or unrelated mission UI vanishes.

## Session B — ordinary physical combat, both directions

Start with ordinary non-quest human enemies, not bosses/MaxTac/drones/scripted invulnerables.

### V attacks NPC

- Use controlled torso, arm, leg and head shots across separate ordinary targets where practical.
- Judge whether hits behave physically rather than as level/DPS-versus-HP arithmetic.
- Confirm actor HP/damage-preview bars remain absent.
- Compare regional consequences: arm/leg injury should not look identical to torso/head injury.
- Verify stopped/nonpenetrating impacts can produce blunt consequences without inventing an open projectile tract.
- Verify mechanical/cyberware-only contact does not manufacture biological bleeding.

### NPC attacks V

- Allow controlled ordinary hits rather than beginning with a lethal stress test.
- Confirm V enters the same regional injury/protection logic.
- Confirm no traditional V HP bar appears.
- Observe embodied feedback: movement, stamina, handling, bleeding/weakness and pain should make injury legible without showing an exact HP reservoir.

The desired uncertainty is about exact remaining reserve, not about whether V has been hurt.

## Session C — pain and vanilla MaxDoc

Once V has a meaningful biological injury:

- Aim/handle a weapon before taking MaxDoc and judge the pain-driven instability separately from obvious structural limb impairment.
- Use **MaxDoc** through its normal vanilla interaction/quick-slot path.
- Confirm the MaxDoc animation/use/charge behavior remains recognizably vanilla.
- Confirm MaxDoc does **not** visibly heal the underlying wound, stop bleeding, stabilize bone, replace blood or repair chrome.
- Confirm perceived-pain/aim instability is reduced while structural impairment remains.
- Use overlapping MaxDoc doses carefully to test diminishing relief. Later overlapping uses should help less than the first.
- At the authored overuse threshold, confirm disorientation/dizzy-drunk presentation appears without alcohol-specific gameplay behavior becoming the treatment model.
- Allow game/body time to pass and verify analgesia/disorientation clears while unresolved injury pain can return.
- Confirm Health Booster and Bounce Back did not become aliases for the MaxDoc analgesia path.

The initial dose/decay/overuse values are calibration targets, not clinical claims. Record whether the effect is too weak/strong/long/short rather than treating the first numbers as final.

## Session D — Cyberware / Condition injury inspection

With a controlled injury present, open the normal Cyberware/body screen.

- Confirm **Cyberware** mode still performs its normal vanilla purpose.
- Enter **Condition** mode and confirm healthy regions do not create a wall of `OK` entries.
- Confirm the actual injured region appears as an active condition.
- Select it and verify the stock paper-doll anatomical focus/zoom is reused where available.
- For arms/legs, verify left/right condition identity remains clear even if vanilla supplies only a combined Arms/Legs camera framing.
- Confirm the detail view qualitatively describes tissue/bone/bleeding/chrome/function state rather than native HP or raw simulation percentages.
- Confirm likely-cause/protection text is plausible and tied to the actual accepted hit when provenance exists.
- Confirm qualitative pain/MaxDoc text reflects the current body state.
- Enter/exit Condition mode repeatedly and verify vanilla Cyberware screen state is not corrupted.

## Session E — field treatment

Use Condition mode to treat only what is physically field-treatable.

- For external bleeding, verify `APPLY DRESSING` appears only when it can help and consumes the mapped dressing supply exactly once on successful completion.
- For a supported limb injury, verify `SUPPORT LIMB` appears only when applicable and improves function without instantly healing bone damage.
- Start a timed treatment and interrupt it by movement/combat/menu context where practical. It must not consume supplies or apply the result if cancelled.
- Confirm dressing does not cure internal bleeding or unrelated injuries.
- Confirm neither dressing nor limb support consumes MaxDoc.

The rigid support-supply mapping is still provisional. The acceptance target here is causal treatment, transaction correctness and separation from MaxDoc—not final inventory art/economy polish.

## Session F — ripperdoc professional care

At a context where the stock screen identifies a ripperdoc:

- Open the same Condition view rather than a separate medical UI.
- Verify clinical care appears only for biological conditions it can help.
- Verify mechanical repair appears only when chrome damage exists.
- Clinical care may control bleeding and establish aftercare but must not instantly erase tissue/bone injury or replace lost blood.
- Mechanical repair must affect chrome only and not heal biological trauma.
- Recheck the region afterward and confirm the UI describes the new state accurately.

Professional price/time integration is not yet the acceptance authority; do not infer final economy design from this first slice.

## Session G — armor, time, recovery and persistence

Continue the same save rather than resetting immediately.

- Compare an uncovered region with clearly mapped protective coverage.
- Confirm torso protection does not protect uncovered limbs.
- Repeat impacts enough to establish that armor wear is regional and not duplicated per hit.
- Let bleeding/body time advance and verify consequences are driven by game/body time rather than frame rate.
- Sleep/wait once and confirm body/injury/analgesia recovery does not double-count the time transition.
- Save with nontrivial injury and/or active analgesia, reload, and verify state is neither duplicated nor silently reset/healed.
- Verify bathroom/washing/body interactions continue to function independently of combat.

## Session H — unusual/protected actors and Phantom Liberty

Only after ordinary cases are coherent:

- test boss/MaxTac while the dedicated actor health bar stays hidden;
- test authored quest/one-shot protection and ensure realpass does not bypass final native safeguards;
- test nonlethal defeat where reproducible;
- test a drone/mechanical target and reject unsupported biological wound routing;
- test companion HUD/lifecycle if available;
- test combat around dialogue/quest transitions;
- test reproducible Phantom Liberty critical sequences.

An explicitly protected boss may legitimately take more punishment. A physically ordinary human should not become a sponge merely because level/max-HP is high.

## What the player should report

Plain-language observations are more useful than diagnostics on the first pass. Record weapon/target, body region, obvious protection, what happened immediately, what changed over time, whether the result felt implausible, any HP bar that appeared, any unrelated UI that vanished, how MaxDoc changed pain/handling, what Condition mode showed, and what treatment actually changed.

Only after a concrete discrepancy exists should a second build enable `-Diagnostics`. Diagnostics are for explaining a specific failure, not for turning normal play into telemetry.

## Promotion gates

Do not call the owned combat/body candidate accepted merely because it launches. Promotion requires at minimum:

- exact owned candidate compiles and preflights cleanly;
- live deployment is save-backed, hash-verified and source-mod-residue-free;
- vanilla item/screen identity remains coherent;
- ordinary player/NPC physical hit paths work in both directions;
- actor HP bars remain hidden without breaking unrelated HUD/mission state;
- regional armor, biological/chrome routing, bleeding and impairment behave causally;
- MaxDoc retains its vanilla identity while producing analgesia only, with believable diminishing returns/overuse and no magical wound healing;
- Cyberware/Condition mode works, reuses safe stock body/zoom behavior, and explains the actual regional condition;
- field and professional treatment remain distinct and transactionally correct;
- save/reload/time progression do not duplicate, erase or replay injury/analgesia state;
- native boss/quest/nonlethal protections remain authoritative;
- no severe script errors, runaway callbacks, obvious performance degradation or quest blockers are observed.

Failures become specific acceptance-ledger items. Do not solve them by restoring source-mod ownership, renaming vanilla items, or reintroducing generic health-sponge scaling.
