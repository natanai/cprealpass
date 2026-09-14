# realpass specification

Last updated: 2026-09-14
Canonical intent: `AGREED-GOALS.md` takes precedence over this implementation specification.

## Product definition

realpass is one coherent realism pass for Cyberpunk 2077 + Phantom Liberty. It is not a curated stack, a compatibility preset, or a reskin of other gameplay/presentation mods. Gameplay and presentation behavior that defines realpass is authored in this repository and owned by realpass. Other mods may be studied as references, but their gameplay scripts, archives, assets and runtime state are not part of the finished product.

The target is plausible cause and effect rather than difficulty for its own sake: bodies need food, water, sleep and recovery; exertion has consequences; bullets interact with clothing, armor, cyberware and tissue; injuries impair and can require treatment; presentation removes unnecessary RPG abstraction while keeping the game usable.

## One authored experience

Development is modular so isolated gates can support calibration, fault-finding and regression testing. **The released mod is not modular from the player's perspective.** A normal release enables the complete accepted realpass experience as one authored balance. There is no public menu for disabling body, combat, injury, armor or other core authorities and no balance-slider matrix that produces materially different simulations.

Diagnostics and internal gates are development controls only. Accessibility options may be considered separately only when they do not create different simulation authority. Traditional actor health bars are intentionally absent from the authored presentation.

## Runtime ownership

Gameplay and presentation runtime code is project-original realpass code. Generic tooling may remain only when it supplies plumbing that the runtime actually uses.

The current owned live-test candidate is deliberately minimal: **project-original realpass REDscript plus pinned redscript**. It has no executing source-mod runtime and no production dependency on RED4ext, ArchiveXL, TweakXL, Codeware, Mod Settings or Input Loader. Historical/reference profiles remain only as development history.

The owned builder fails closed on source-mod imports, source-mod presentation identity and retired prototype files. The exact candidate must compile against the installed Cyberpunk 2077 2.31 script bundle before deployment.

## Vanilla-first replacement

realpass alters the minimum necessary layer of vanilla Cyberpunk. Keep CDPR names, item identities, animations, screens, assets and interaction structures wherever they can cleanly host the realism model. Replace mechanics underneath them rather than constructing a parallel branded ecosystem.

Examples:

- MaxDoc stays MaxDoc. Its vanilla inhaler/use flow is retained while realpass replaces magical HP restoration with analgesia.
- Bounce Back and Health Booster retain their vanilla names and remain separate items; they are never silently aliased to MaxDoc or imported source-mod concepts.
- **Biology** is the realpass body-state surface. Cyberware remains equipment-focused; ripperdoc context may expose a Biology professional-care doorway without turning Cyberware into the body-state owner.
- `Eat…` and `Drink…` in Biology enumerate the actual carried inventory and call Cyberpunk's own consumable action. Backpack and Biology are two routes into the same item transaction, not two inventories.
- The native modern scanner/quickhack flow remains authoritative. realpass only adds narrow owned presentation behavior where explicitly desired.

This is also the patch-resilience strategy: prefer semantic native hooks and small dynamic UI seams feeding stable realpass models over broad resource replacements or duplicated vanilla state.

## Scope

### In scope

- one physiological body: nutrition, hydration, sleep/fatigue, exertion, digestion/elimination, recovery and restrained hygiene where retained;
- regional injury, blood loss, pain, impairment, field care, professional care and recovery;
- physical projectile/ammunition/impact behavior and realistic injury consequences;
- physical armor/clothing coverage and wear;
- cyberware where it changes relevant structure or physiology;
- sparse presentation supporting the simulation: Biology, actor-healthbar removal, readable scanned civilian identity where stock rules permit, and native scanner compatibility;
- attended-development diagnostics that are off in ordinary play.

### Explicitly out of scope

- weather control;
- economy overhaul, arbitrary scarcity or price rebalance;
- added hardship encounters;
- fast-travel/travel restrictions;
- vehicle summon currencies/limits;
- broad addiction/humanity/cyberpsychosis systems absent a new explicit decision;
- a new outfit/transmog simulation layer;
- generic carry/stamina hardship disconnected from the authored body;
- public subsystem toggles or balance-slider matrices;
- features retained merely because a reference mod had them.

## Authority boundaries

1. **Body** owns the shared physiological clock/state, intake, sleep, exertion, digestion/elimination and recovery inputs.
2. **Injury** owns regional tissue/bone/chrome damage, bleeding, impairment, stabilization, treatment and recovery state.
3. **Combat** owns projectile/ammunition profiles, physical impact routing and wound proposals.
4. **Armor** owns protective classification, regional coverage, projectile-dependent protection and wear.
5. **Cyberware physiology** is intentionally narrow: cybernetic hit shapes may produce structural chrome injury and mechanical repair requirements; it is not a generic cyberware rebalance.
6. **Presentation** reads the above authorities but never mutates them as a substitute for gameplay logic.
7. **Diagnostics** expose exact internal values only for attended development/calibration.

Each physical phenomenon has one authority. Presentation does not become a second model and source/reference mods do not remain hidden authorities.

## Body and needs principles

Normal presentation follows:

`hidden biological state -> perceptible/knowable interpretation -> Biology UI and/or embodied gameplay consequences`

Exact quantities may exist internally. They are not permanent player meters merely because they exist.

Guardrails:

- no starvation over a handful of in-world hours;
- no dangerous dehydration after ordinary short activity;
- fluid intake absorbs before it fills the bladder;
- digestion/bowel state is delayed and aggregated rather than one-to-one with each food item;
- sleep pressure reflects time awake, prior rest, exertion and injury rather than an arbitrary energy bar;
- hygiene/elimination remain only while they can be represented without constant busywork;
- food/drink effects enter the shared body through the same completed stock consumable action whether selected from Backpack or Biology.

Numeric coefficients remain game abstractions requiring attended calibration; they are not clinical claims.

## Combat model

Target causal chain:

`weapon/projectile -> impact region -> encountered material/protection -> cybernetic structure and/or tissue -> regional injury -> whole-body consequence -> treatment/recovery`

Required qualities:

- ordinary humans do not become level-based bullet sponges;
- physical equivalence should produce comparable injury for V and supported human NPCs;
- protection applies only where genuinely protective equipment/structure is encountered;
- ordinary clothing is not generic armor;
- armor has projectile-dependent protection and wear;
- cyberware/metal hit shapes can produce structural chrome damage distinct from biological trauma;
- unprotected limbs remain vulnerable and regional injury can impair locomotion/weapon handling;
- authored boss/quest/immortality/nonlethal protections remain respected by the native acceptance boundary;
- native HP is an output/engine-compatibility channel, not the causal wound model.

## Injury, pain and care

- Regional injury remains authoritative for head, torso, left/right arms and left/right legs.
- Whole-body blood deficit/recovery is separate from any one region.
- Pain is derived from physical injury, not native HP.
- MaxDoc is analgesia only; it does not heal tissue/bone, stop bleeding, replace blood or repair chrome.
- Analgesia has diminishing returns and overuse/disorientation consequences.
- Dressing/support are timed field actions using separate supplies and safe-context checks.
- Clinical biological care and mechanical cyberware repair are distinct.
- Professional intervention does not erase time-dependent biological recovery.

## Biology presentation

Biology answers what V can currently perceive, know or reasonably infer about their body.

It contains:

- qualitative bodily needs/sensations;
- meaningful current effects such as pain/analgesia/disorientation;
- active conditions only; healthy regions stay quiet;
- selected-condition explanation and applicable field care;
- `Eat…` / `Drink…` filtered views over actual carried items.

In ripperdoc context, Biology also exposes only model-approved clinical/mechanical professional actions. Cyberware continues to serve its vanilla equipment role.

No normal Biology view exposes raw body percentages, exact bladder volume, exact calorie balance, exact bleed rate, analgesic load or native HP.

## Other presentation

- Keep the modern native scanner/quickhack flow.
- Scanned ordinary civilians may receive a readable name fallback only when the stock nameplate/scanner policy allows it; authored hidden/alternative/quest identities remain protected.
- Hide traditional actor HP feedback while preserving non-health information and objective/vehicle durability where needed.
- Avoid floating-number/RPG clutter when it does not communicate the physical model.
- Use existing native visual/weapon behavior for pain/disorientation where safe rather than inventing permanent custom meters.

## Distribution and development workflow

The development candidate is produced from the repository source tree, not the installed mod stack. Canonical body/combat gates remain fail-closed in source and are opened only in immutable staged copies for an exact candidate.

The normal completion flow is:

1. cloud-safe source/model/contracts CI passes;
2. build the complete owned candidate;
3. exact-compile it against the installed Cyberpunk 2077 2.31 base script bundle;
4. plan/install through the flat owned-file installer;
5. verify the installed hashes and absence of retired/source-mod runtime residue;
6. launch normally through Steam for an attended broad test.

No custom persistent launcher, background watcher/service or redundant save-backup chain is part of realpass.

## Acceptance questions for every mechanic

- What real or internally plausible process is represented?
- Does its timescale remain credible relative to the other systems?
- Does it duplicate another authority?
- Does it create arbitrary punishment without physical rationale?
- Is it in scope or merely inherited from a reference?
- Is the executing implementation owned by realpass?
- Does it preserve vanilla identity/surface where useful?
- Is exact internal state kept out of normal UI unless V could reasonably know it?
- Does it respect authored quest/boss/nonlethal protections?
- Can the full locked experience remain compatible with Phantom Liberty and acceptable script latency?
