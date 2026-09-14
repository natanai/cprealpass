# realpass owned attended acceptance

Status: canonical local test plan for the completed repository-side live-test candidate
Last updated: 2026-09-14
Governing goals: `AGREED-GOALS.md`

This plan begins **after** the completion branch has merged to `main`. Repository-side work should already be internally coherent and cloud CI green. The purpose of this session is to obtain evidence that only the installed Cyberpunk 2077 2.31 environment can provide: exact native compile compatibility, layout/input behavior, physical gameplay feel, persistence, quest compatibility and runtime cost.

Do not use legacy source-mod-integrated attended tooling for product acceptance.

## Candidate contract

The candidate being tested should contain only:

- project-original realpass REDscript;
- the pinned redscript runtime/compiler plumbing selected by `m1-base`;
- no Dark Future, Project E3, Codeware, ArchiveXL, TweakXL, Mod Settings, Input Loader or other gameplay/presentation runtime dependency;
- body and combat gates opened only in immutable staged candidate copies;
- diagnostics off unless a concrete second-pass investigation explicitly enables them.

Expected authored behavior includes:

- one shared physiological body;
- physical projectile/protection/injury routing;
- regional injury, blood loss, impairment, pain, armor wear and treatment;
- MaxDoc kept as the vanilla item but acting as analgesia rather than magical wound healing;
- traditional actor HP bars suppressed;
- native modern scanner/quickhack behavior retained;
- owned scanned-civilian name fallback under stock identity/visibility policy;
- **Biology** as the body-state interface, with Backpack remaining possessions and Cyberware remaining equipment.

## Preferred operator path

With Cyberpunk fully stopped and the repository updated to the merged `main`:

```powershell
pwsh ./tools/Prepare-OwnedSession.ps1
```

This preflight must:

1. run the complete cloud-safe/offline repository checks;
2. create a fresh immutable build ID;
3. acquire/stage only pinned redscript plumbing;
4. build the complete project-original source tree;
5. reject forbidden source-mod identities/dependencies;
6. open fail-closed body/combat gates only in staged candidate copies;
7. exact-compile the source candidate against the installed Cyberpunk 2077 2.31 base script bundle;
8. exact-compile the final deployable manifest;
9. plan the flat owned install with `-WhatIf`;
10. write a preflight report and stop without changing game files.

A passing preflight establishes compile/install readiness only. It is not gameplay acceptance.

Then run:

```powershell
pwsh ./tools/Prepare-OwnedSession.ps1 -Deploy
```

The deploy pass recompiles, installs the exact current owned payload, verifies copied hashes, records one flat `owned-current.json`, removes known retired RealPass/source-mod runtime residue, verifies that residue is absent, and stops. It does **not** launch the game, create a background process or make an extra realpass-managed save backup.

If stock game repair is ever needed, use `Remove-OwnedRuntime.ps1` for recorded RealPass-owned extra files and Steam **Verify Files** or reinstall for stock-game repair.

After `READY`, launch Cyberpunk normally through Steam.

## Stop-before-gameplay conditions

Do not proceed to gameplay acceptance if any of these occur:

- cloud/offline repository checks fail;
- exact compilation fails;
- the completed Biology/nameplate/no-healthbar native seams fail to compile;
- final manifest contains an unexpected component beyond RealPass + redscript;
- install hashes do not match;
- retired/source-mod runtime residue remains;
- the game fails to reach the menu/load a save cleanly.

Repair the seam/tooling first. Do not loosen the physical model or reintroduce old dependencies merely to make a candidate boot.

## Session A — boot, vanilla identity and presentation baseline

Before deliberately injuring V:

- Load a normal save and move through ordinary menus.
- Confirm Backpack still behaves as inventory rather than a RealPass body dashboard.
- Confirm Cyberware retains its normal equipment purpose.
- Confirm MaxDoc, Bounce Back and Health Booster retain their CDPR names/identities.
- Confirm the native modern scanner opens/closes and quickhack/device/NPC targeting remains usable.
- Confirm the normal V actor HP bar is not continuously visible.
- If Overclock/overshield is available, exercise those visibility paths and ensure HP does not reappear while RAM/status feedback remains usable.
- Confirm objective/vehicle durability UI remains where the game needs it.
- Scan an ordinary civilian; confirm allowed identity can remain readable without revealing hidden/quest/alternative identity cases.

Stop and repair presentation if the whole biomonitor disappears, scanner/quickhacks break, unrelated mission UI disappears, or identity is leaked in a stock-hidden context.

## Session B — Biology and ordinary body behavior

Open **BIOLOGY** from the hub.

- Confirm the screen is labeled Biology, not Conditions.
- Confirm bodily needs are qualitative and no permanent hydration/nutrition/fatigue/bladder percentages appear.
- When hunger is meaningful, `EAT…` should list only modeled food stacks actually carried by V.
- When thirst is meaningful, `DRINK…` should list only modeled drinks actually carried by V.
- Select an item and confirm stock consumable behavior/animation/inventory transaction occurs exactly once and the same item count changes as it would from inventory.
- Confirm using the same item from Backpack feeds the same RealPass body model.
- Confirm no duplicate Biology inventory exists.
- Observe ordinary digestion/absorption over time rather than instant meter refills.
- Exercise movement enough to test exertion and rest recovery.
- Exercise bathroom/washing interactions when available.
- Wait and sleep separately; confirm time is neither missed nor double-counted.
- Save/reload with nontrivial body state and verify it persists coherently.

Record whether hunger/thirst/fatigue/elimination become perceptible at sensible timescales. Those thresholds are calibration targets, not clinical claims.

## Session C — ordinary physical combat in both directions

Use ordinary non-quest human enemies first.

### V attacks NPC

- Compare controlled head, torso, arm and leg hits.
- Compare uncovered and clearly protected regions.
- Confirm hits feel driven by projectile/region/protection rather than level/max-HP sponge behavior.
- Confirm arm/leg injury can differ functionally from torso/head trauma.
- Confirm stopped/nonpenetrating impacts can create blunt consequences without inventing an open projectile tract.
- Confirm cyberware/metal structural contact does not automatically create biological bleeding.
- Confirm actor HP/damage-preview bars remain absent.

### NPC attacks V

- Allow controlled hits rather than starting with a lethal stress test.
- Confirm V enters the same regional physical model.
- Observe impairment, bleeding/weakness and pain as the primary injury feedback rather than an HP reservoir.
- Confirm no V HP bar appears during ordinary damage.

## Session D — pain and MaxDoc

With meaningful biological injury:

- Compare weapon handling before MaxDoc.
- Use **MaxDoc** through its normal vanilla interaction/quick-slot path.
- Confirm native MaxDoc identity/animation/charge flow remains recognizable.
- Confirm its vanilla HP-regeneration effect is suppressed by RealPass.
- Confirm it does not dress bleeding, splint bone, replace blood, heal tissue or repair chrome.
- Confirm pain-derived instability decreases while structural limb impairment remains.
- Carefully test overlapping doses for diminishing returns.
- Confirm overuse reaches the authored disorientation/native drunk-visual envelope without becoming alcohol gameplay authority.
- Let body time advance; confirm analgesia/disorientation decay while unresolved injury pain can return.
- Confirm Bounce Back and Health Booster did not become aliases for MaxDoc.

If other vanilla medical items still create realism-breaking magical recovery, record the exact item/action/effect as a concrete follow-up rather than guessing from name alone.

## Session E — Biology condition inspection and field care

With a controlled injury, return to Biology.

- Healthy regions should remain visually quiet.
- The actual injured region should appear as an active condition.
- Select it and verify qualitative tissue/bone/bleeding/chrome/function text rather than native HP or raw percentages.
- Confirm likely-cause/protection wording corresponds to the accepted hit when provenance exists.
- Confirm current pain/MaxDoc wording matches actual state.
- For external bleeding, `APPLY DRESSING` appears only when it can help.
- For appropriate limb injury, `SUPPORT LIMB` appears only when it can help.
- Start field care, close the menu, stay still and verify successful completion consumes the mapped supply exactly once.
- Interrupt another attempt by movement/combat/menu reopening and verify no treatment/supply loss commits.
- Confirm field care cannot cure internal bleeding, replace blood, instantly heal tissue/bone or repair chrome.
- Confirm neither dressing nor support consumes MaxDoc.

## Session F — ripperdoc Biology professional care

At an actual ripperdoc context:

- Cyberware should still look/behave as an equipment screen.
- Confirm a **BIOLOGY** professional-care doorway appears only in the ripperdoc screen.
- Select active conditions using the same qualitative regional language.
- Clinical care appears only for biological states it can help.
- Mechanical repair appears only for chrome structural damage it can help.
- Clinical care can control appropriate biological bleeding/aftercare but must not instantly erase tissue/bone trauma or replace already lost blood.
- Mechanical repair must reduce chrome damage only and not heal biology.
- Reopen ordinary Biology afterward and confirm the condition state matches the authoritative body model.

## Session G — armor, recovery and persistence

Continue the same save.

- Compare clearly protected torso coverage with uncovered limbs.
- Confirm protection does not magically cover an unrelated region.
- Repeat impacts enough to observe regional armor wear without duplicate wear commits.
- Let bleeding/recovery/body time advance and verify it is game-time-driven rather than frame-rate-driven.
- Sleep/wait around injury and analgesia; verify no duplicate progression.
- Save/reload with meaningful injury/pain/armor/body state and confirm state is neither duplicated nor silently reset/healed.

## Session H — special/protected actors and Phantom Liberty

Only after ordinary cases are coherent:

- test bosses/MaxTac with actor HP bars still suppressed;
- verify authored immunity/quest/one-shot/native safeguards remain authoritative;
- test nonlethal defeat where reproducible;
- test drones/mechanical targets and reject unsupported biological routing;
- test companions and their HUD lifecycle if available;
- test combat around dialogue/cinematics/quest transitions;
- test representative base-game and Phantom Liberty critical paths.

A protected special actor may legitimately survive more. A physically ordinary human should not become a sponge merely because their level/max HP is high.

## Session I — runtime/performance sanity

During the broad session, observe rather than run a background profiler:

- obvious frame/input hitching associated with body/NPC ticks;
- script/log errors after repeated combat/menu transitions;
- runaway repeated notifications or callbacks;
- Biology open/close leaks or duplicate widgets;
- NPC persistence growth over a longer session;
- save/load time regressions.

If a concrete performance problem appears, use a deliberate second diagnostic build to investigate that failure only.

## What to report

For each discrepancy, capture the smallest useful description:

- action/weapon/item;
- target/body region;
- visible protection;
- immediate result;
- what changed with game time;
- what Biology displayed;
- what inventory item/supply changed;
- whether any HP bar/unrelated UI appeared/disappeared;
- whether the result survived save/reload;
- why it felt physically or functionally implausible.

Screenshots/video/log excerpts are useful when they show a concrete mismatch. Exact hidden numbers are not required for the first pass.

## Promotion criteria

A live-test candidate is accepted for release-calibration work only when:

- exact compile + install verification succeeds;
- the game boots/loads normally with source-mod residue absent;
- Biology, actual-inventory Eat/Drink and field/pro care work;
- body/time/save progression is coherent;
- ordinary V/NPC physical hit paths work in both directions;
- armor, biological/chrome routing, bleeding and impairment are causal;
- MaxDoc is analgesia-only without magical wound repair;
- actor HP bars stay hidden without breaking unrelated UI;
- native scanner and owned scanned-name fallback coexist correctly;
- boss/quest/nonlethal protections remain intact;
- save/reload does not duplicate/erase body/injury/pain state;
- no severe script errors, runaway callbacks, obvious performance degradation or quest blockers appear.

Live failures become narrow native-seam/model/calibration work. They are not permission to restore the old dependency stack or abandon the locked product goals.
