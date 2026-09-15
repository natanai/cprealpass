# Biology — agreed goals ledger

Last updated: 2026-09-14
Status: **canonical product-intent source of truth**

This file records the goals and product decisions explicitly agreed with the project owner. It exists so a new ChatGPT/Codex/local agent can understand the intended product without reconstructing chat history.

**Precedence rule:** if an older design/status document conflicts with this file, follow this file and update the older document. Do not silently reinterpret a locked goal. Calibration values and implementation details may evolve without changing the goal they serve.

**Naming migration note:** the player-facing/product/package name is now **Biology**. Older entries, source files, tests, classes, settings keys and repository paths may still say `realpass`, `RealPass` or `CR*` while the migration is underway. Those names refer to the same project unless the text is specifically describing legacy architecture. Do not perform a risky mass internal rename merely to make naming uniform.

## Status legend

- **LOCKED** — agreed product goal; change only after a new explicit user decision.
- **ACTIVE** — agreed direction currently being implemented.
- **OPEN** — implementation/calibration choice still to be resolved while preserving the locked goal.

---

## Product identity

### G-001 — One coherent Biology overhaul — LOCKED
**Biology** is one authored Cyberpunk 2077 + Phantom Liberty physical/physiological overhaul, not a collection of unrelated difficulty/survival modules and not a repackaged mod stack.

### G-002 — Same Biology version means the same simulation — LOCKED
Internal modularity is for development, calibration, isolation and debugging. With Biology enabled, a normal release is **all-or-nothing**: accepted body, injury, combat, armor, cyberware-physiology and presentation authorities run together. Players do not get a menu for disabling core authorities independently or changing balance values.

A single global **Enable Biology** master switch may disable the entire overhaul and yield to native Cyberpunk behavior if that switch remains technically reliable. That whole-mod switch is not permission to expose body/combat/armor/etc. as separate player-configurable modules.

Diagnostics remain development-only and off in a normal release.

### G-003 — Physical/physiological realism, not difficulty for difficulty's sake — LOCKED
The target is plausible cause/effect. A mechanic belongs only when it supports the physical body, injury, equipment, combat or presentation model. Added friction is not a goal by itself.

### G-004 — Vanilla-first mechanic replacement; preserve game identity — LOCKED
Biology starts from the **vanilla Cyberpunk game** and makes its existing systems behave more plausibly. Preserve CDPR item names, item identities, animations, screens, assets and interaction language whenever they remain useful; replace or reinterpret the underlying mechanics only where realism requires it.

Do **not** import Dark Future/E3 renames or other source-mod nomenclature as Biology features. In particular, do not rename one vanilla medical item into another concept. MaxDoc remains MaxDoc, Bounce Back remains Bounce Back, Health Booster remains Health Booster, and any future Biology role for each is authored against that vanilla identity.

For stability, prefer narrow hooks at semantic native/official boundaries and Biology-owned models behind them over wholesale asset/resource replacement, duplicated vanilla state, or variant-by-variant patches.

### G-005 — “Biology” is the organizing product concept, not a narrow needs menu — LOCKED
The Biology name intentionally covers the complete causal body experience. Food/hydration, sleep/fatigue, elimination, pain, injury, treatment, combat consequences, clothing/armor protection and relevant cyberware all belong when they determine what happens to the body.

This does **not** expand the product into unrelated economy/weather/travel/hardship systems. A feature belongs because it participates in the authored physical body/protection/combat model, not because it can be labeled “realistic.”

---

## Runtime ownership and dependency direction

### G-010 — Executing gameplay/presentation code must be ours — LOCKED
Dark Future, Project E3 HUD and other gameplay/presentation mods are **reference/inspiration only**. The finished Biology runtime must not depend on their scripts, state machines, UI assets, archives, save state or gameplay authority.

Observing how another mod solved a problem is allowed. The accepted behavior must then be re-derived from native Cyberpunk/official REDmod signals and implemented in Biology-owned source/data.

### G-011 — Generic frameworks may be plumbing only — LOCKED
redscript/RED4ext/Codeware/ArchiveXL/TweakXL/Mod Settings or similar frameworks may remain only when they provide generic infrastructure that Biology genuinely needs. A framework may not own Biology gameplay policy, simulation state or authored presentation behavior. Remove framework dependencies that cease to be necessary.

### G-012 — Thin native adapters, stable Biology core — LOCKED
Patch-sensitive Cyberpunk/REDmod hooks and mappings should be kept in thin boundary adapters. Simulation models and state should remain as game-version-independent as practical behind those adapters.

Preferred direction:

`Cyberpunk/REDmod native API/event -> thin Biology adapter -> Biology model/state -> Biology presentation`

not:

`Cyberpunk -> another gameplay mod -> Biology patch/bridge`.

### G-013 — Official REDmod is the preferred final packaging/runtime route where it is actually robust — LOCKED
The final product should use CDPR's official REDmod path for every surface it can cleanly own: package identity/deployment, archives/resources, tweak sources, audio/animation paths and script replacement **when whole-file replacement is the robust option**.

REDmod-first does not mean blindly forcing every behavior into REDmod. If official `.script` replacement would copy a large/stale vanilla implementation while a narrow Biology-owned additive/wrapper seam touches only the needed method, the narrower seam may be more patch-resilient and is preferred.

### G-014 — Minimize dependency depth; historical dependencies have no entitlement to survive — LOCKED
For every runtime need, prefer this hierarchy:

1. vanilla Cyberpunk semantic authority;
2. official REDmod;
3. Biology-owned additive/wrapper scripting where narrower than REDmod whole-file replacement;
4. generic native/framework extension only when demonstrably necessary;
5. more invasive/version-sensitive techniques only as isolated, justified exceptions.

Do not retain RED4ext, ArchiveXL, Mod Settings, Codeware, TweakXL, CET or any other framework merely because an earlier build used it. Each surviving dependency must have a current feature-specific justification.

### G-015 — Biology is authoritative where it intentionally overlaps, but does not promise universal dominance over every mod mechanism — LOCKED
Where REDmod can deterministically express file/resource precedence, Biology should use that mechanism so Biology wins for the physical systems it explicitly owns. It should not broaden its footprint merely to overpower unrelated mods.

Do not claim universal compatibility or precedence over third-party redscript wrappers, RED4ext/CET/native hooks, runtime TweakDB mutation or other mechanisms outside REDmod's per-file conflict model. Document known overlap/incompatibility honestly.

### G-016 — Final package identity should be self-contained and obvious — LOCKED
The preferred finished identity is one recognizable `mods/Biology` REDmod package plus only those extra generic framework files that remain strictly unavoidable after the dependency audit.

A user should be able to understand what belongs to Biology, how to enable it, and how to remove it without knowing the project's development history. Avoid unexplained loose legacy payload spread across the game tree.

---

## Scope

### G-020 — In-scope authorities — LOCKED
The core product includes:

- body/needs and physiology;
- injury, bleeding, pain, impairment, treatment and recovery;
- realistic combat/ballistics/impact consequences;
- physical armor/clothing coverage and armor wear;
- relevant cyberware physiology/structural injury;
- restrained presentation needed to communicate those systems;
- development diagnostics that are absent/off in normal play.

### G-021 — Explicitly out of scope — LOCKED
Do **not** add or retain systems merely because a source/reference mod had them. Current exclusions include:

- weather overhaul;
- economy overhaul, arbitrary scarcity or broad price rebalance;
- random encounters added for hardship;
- fast-travel/travel restrictions;
- vehicle summon currencies/limits unrelated to physical realism;
- addictions/humanity/cyberpsychosis unless a future separate explicit decision puts a narrowly defined physiological behavior in scope;
- a new outfit/transmog simulation layer;
- generic carry/stamina hardship disconnected from the authored body model.

### G-022 — Clothes are clothes; armor is armor — LOCKED
Appearance and protection are separate concepts. Ordinary clothing does not become meaningful ballistic armor because it occupies an equipment slot. Protective equipment protects according to actual construction, threat resistance, coverage and condition.

### G-023 — Vanilla Outfits become physical equipment loadouts, not cosmetic transmog — LOCKED
Preserve the familiar vanilla Outfit convenience where feasible, but applying an Outfit must equip the actual owned wearable items recorded for that loadout. The item V visibly wears and the item encountered by armor/protection logic must be the same physical equipped object; a parallel cosmetic override must not remain authoritative.

A saved item that is no longer physically available must not be conjured, substituted, or silently represented by appearance only. Remote stash teleport is not assumed. Quest/special-equipment restrictions and scripted outfit states must fail safely or retain native authority rather than being broken by the loadout adapter.

---

## Combat

### G-030 — Causal physical combat pipeline — LOCKED
A ranged hit should be explainable through the chain:

`weapon/projectile -> impact region -> encountered material/clothing -> ballistic protection -> cybernetic structure and/or tissue -> injury -> physiological consequence -> treatment/recovery`

The primary explanation must not be level, rarity, DPS tier or a generic health-sponge pool.

### G-031 — Ordinary humans do not become level-based bullet sponges — LOCKED
For physically equivalent ordinary-human targets, wound severity should be driven by the physical event rather than character level/max-HP inflation. Preserve explicit authored boss, quest, immortality, nonlethal and special encounter protections where required for game integrity.

### G-032 — V and supported human NPCs share the same physical logic — LOCKED
Where the game permits, player and supported human NPC impacts use the same regional/protection/injury reasoning rather than unrelated damage rules.

### G-033 — No traditional actor health bars — LOCKED
The authored Biology presentation hides traditional HP bars/HP-number feedback for V, ordinary NPCs, bosses/MaxTac and companions where technically safe. Injury and performance consequences are the intended feedback.

Do not blanket-hide mission-objective or vehicle durability indicators merely because they are bar-shaped; those can communicate objective state rather than actor HP.

---

## Injury model and player-facing condition system

### G-040 — Regional body injury is authoritative — LOCKED
V's body is modeled at minimum as six regions: head, torso, left/right arm, left/right leg. A region may independently track biological tissue damage, bone damage, cyberware damage, external bleeding, internal bleeding, support/stabilization and clinical-care state. Whole-body blood loss/recovery is tracked separately.

### G-041 — Detailed simulation internally, qualitative diagnosis externally — LOCKED
The model may use exact internal values. Normal gameplay and Biology's unzoomed overview should translate them into understandable condition language rather than expose raw simulation percentages/rates as replacement health meters.

Examples: minor/moderate/severe trauma, external bleeding, suspected internal injury, impaired function, supported fracture, damaged chrome.

A player who **deliberately drills into a body system or selected region** may inspect exact authoritative values as restrained bars/numbers. Those values are inspection depth, not the primary communication layer and not a second state authority.

### G-042 — Physical consequences communicate injury during combat — LOCKED
During a fight the player should mostly learn that something is wrong through believable consequences: movement impairment, stamina loss, degraded weapon handling/reload, pain, bleeding/weakness and similar effects—not through an exact HP readout.

### G-043 — Biology owns the shared body/anatomy screen; Cyberware is a Biology submode — LOCKED
The top-level hub destination currently labeled **CYBERWARE** should become **BIOLOGY** while reusing the stock `cyberware_equip` body/anatomy fullscreen as the technical shell where robust.

The player-facing hierarchy is:

`BIOLOGY -> shared body/anatomy shell -> BIOLOGY | CYBERWARE`

Biology is the parent concept because it owns V's embodied state: needs, sensations, injury/conditions, pain/analgesia, elimination, fatigue/rest, recovery, hygiene where retained, and relevant biological/cybernetic body state. **Cyberware is installed equipment within that body**, so it remains fully accessible as an internal mode/subcategory rather than owning the body screen.

Normal hub access should default to Biology. A direct ripperdoc/vendor context may default the internal mode to Cyberware for usability while preserving Biology as the parent screen.

### G-044 — Conditions are a subsection of Biology, not the screen itself — LOCKED
**Conditions** remains useful language for meaningful injury, illness, impairment, diagnosed/recognized pathology and cyberware/body damage. It is one subsection or mode within Biology rather than the name or total scope of the body screen.

Biology may organize player-facing information into restrained groups such as bodily needs/sensations, active conditions, effects and context-relevant responses. Exact visual grouping is open to native calibration.

### G-045 — Biology overview is qualitative; exact bars belong only to deliberate drill-down — LOCKED
Healthy, irrelevant or currently imperceptible state should remain visually quiet. The unzoomed Biology view should surface terse states such as `STABLE`, `THIRST`, `HUNGER`, `FATIGUE`, `BLEEDING`, `PAIN HIGH` or a recognized active condition when meaningful.

Do **not** replace the removed HP bar with an always-visible hydration/hunger/fatigue/pain/blood/bladder meter wall. Exact values may be displayed after a player intentionally selects/zooms into a relevant body system or region, including as bars useful for testing and deep inspection. Those bars must read the authoritative model directly and disappear again at the overview/gameplay level.

### G-046 — Reuse Cyberpunk's native body nodes/zooms as Biology's interaction language — LOCKED
Biology should reuse the existing Cyberware screen's central body silhouette, anatomical/system anchors, hover highlighting, node interaction and zoom-in/zoom-out language where technically robust.

In Biology mode, stock cyberware slot contents may be hidden while anatomically useful categories become Biology nodes. Existing labels such as Arms, Skeleton, Nervous System, Integumentary System, Circulatory System and Legs are valuable native language. Cyberware-specific categories should be relabeled or omitted only when Biology has an authoritative body concept behind the replacement; do not invent physiology merely to fill every vanilla slot.

Switching to the internal **CYBERWARE** mode must restore the ordinary Cyberpunk cyberware equipment/slot experience without duplicating or rewriting its inventory authority.

### G-047 — Injury detail explains what happened — LOCKED
The zoomed condition view should explain, in restrained player-facing language:

- what kind of condition/injury exists;
- which region is affected;
- approximate severity and functional effect;
- external vs internal bleeding when relevant;
- biological vs cybernetic damage;
- **how/when the condition likely occurred** when Biology has enough evidence;
- what protection was involved/defeated when useful;
- what can be done in the field;
- what requires professional/clinical/mechanical care.

### G-048 — Persist compact injury provenance without replacing regional state — ACTIVE
Add a bounded Biology-owned injury provenance/history record so the UI can explain causes such as projectile family, impact type, region, protection/penetration result and approximate time of injury. The **regional physical state remains authoritative**; history explains how the current state arose and must not become an unbounded status-effect pile.

### G-049 — Biology supports context-appropriate care without becoming a treatment dashboard — LOCKED
Biology may expose plausible field care from the relevant condition. In an appropriate ripperdoc/clinical context, the same Biology condition language may expose professional biological treatment and mechanical cyberware repair as appropriate.

Actions appear because a bodily state makes them relevant; Biology should remain primarily an interface for understanding the body rather than a permanent command center full of treatment buttons.

---

## Treatment, pain and recovery

### G-050 — No magic universal heal — LOCKED
A generic item should not instantly erase the physical injury model. Treatment changes the condition it can plausibly address; recovery continues through the body clock.

### G-051 — Field care is limited — LOCKED
Current intended field-care concepts include:

- dress external bleeding;
- support/splint appropriate limb bone injury;
- require time, appropriate supplies and a safe enough context;
- movement/combat/menu interruptions may cancel timed care.

Field care does **not** magically replace blood, cure internal bleeding, instantly heal fractures/tissue or repair damaged cyberware.

### G-052 — Professional and mechanical care are distinct — LOCKED
Internal bleeding/serious biological care belongs in clinical/ripperdoc-like professional treatment. Structural cyberware damage requires mechanical/ripperdoc repair. Biological and cybernetic injury may coexist in the same region without being treated as the same thing.

### G-053 — Healing is time/body-state dependent — LOCKED
Tissue/bone/blood recovery progresses through the same authored body clock and should interact with relevant rest/resources rather than resolve because a menu was closed.

### G-054 — Vanilla MaxDoc inhaler is analgesia only — LOCKED
**MaxDoc remains MaxDoc.** Biology keeps the vanilla inhaler item identity/animation/quick-slot behavior but replaces its magical HP-regeneration role with **analgesia only**: it reduces perceived pain.

MaxDoc must not dress bleeding, splint fractures, replace blood, heal tissue/bone, repair chrome or refill native HP. Dressing and limb support require their own appropriate supplies. Health Booster and Bounce Back remain separately named vanilla items and must not be silently treated as MaxDoc or renamed into another mod's concepts.

### G-055 — Pain is a Biology body state/consequence — LOCKED
Pain is part of the authored physiology/injury experience. Physical injury generates pain independently of native HP. Pain relief changes perception/functional pain response; it does **not** repair the underlying injury, restore structural function or erase blood loss.

### G-056 — MaxDoc analgesia has diminishing returns and overuse consequences — LOCKED
Repeated MaxDoc inhaler use within a short enough physiological window has diminishing pain-relief benefit. Excess concurrent analgesic load produces an overdose/intoxication state rather than unlimited relief.

For player-facing presentation, reuse Cyberpunk's native dizzy/drunk visual language where technically safe instead of inventing a permanent custom meter. The exact dose curve, decay window and overdose thresholds remain calibration values, not clinical claims.

### G-057 — Pain should be felt through play, not a pain bar — LOCKED
Normal play should communicate significant pain through restrained embodied feedback rather than a permanent numerical pain meter. Intended channels include pain-related weapon/aim instability or sway, contextual visual effects, and appropriately throttled existing V pain/grunt vocalizations where safe native events can be identified.

Structural impairment remains distinct: numbing pain may reduce pain-induced wobble, but it must not make a fractured/damaged limb mechanically healthy.

---

## Body / needs

### G-060 — One shared physiological body — LOCKED
Hydration, energy/nutrition, sleep/fatigue, exertion, digestion/elimination, hygiene where retained, injury, pain/analgesia and recovery belong to one coherent body state/clock rather than independent survival meters that can contradict one another.

### G-061 — Needs should create believable behavior, not chores for their own sake — LOCKED
Needs exist to make V feel embodied and to interact with recovery/performance. Remove mechanics that amount only to repetitive punishment or another mod's survival checklist.

### G-062 — Hidden simulation -> perception -> presentation — LOCKED
The normal player-facing path is:

`hidden biological state -> perceptible/knowable interpretation -> Biology UI and/or gameplay/visual/audio cues`

Exact quantities are allowed and often desirable inside the simulation. They should not automatically become player-visible values. Urgency should increasingly communicate itself through believable consequences and sensations, including outside the menu.

### G-063 — Backpack is possessions; Biology is bodily state — LOCKED
Backpack/inventory is the source of truth for physical items V carries. Biology hunger, thirst, fatigue, elimination, pain, injury severity and other body-state presentation do **not** live as status bars or a body dashboard in Backpack.

Inventory-specific information that genuinely describes possessions may remain there. Physiology presentation belongs in Biology.

### G-064 — Biology actions are contextual gateways into real inventory — LOCKED
When a bodily state suggests an action, Biology may offer a context-sensitive doorway into applicable items V actually carries—for example `Hungry -> Eat…`, `Thirsty -> Drink…`, or an injury -> applicable treatment supplies.

Biology must not maintain a duplicate food/medical inventory. Selecting or consuming an item still uses the actual inventory item and normal item identity/transaction path.

### G-065 — Needs are not continuously entitled to screen space — LOCKED
A need does not need a permanent row merely because the simulation tracks it. If V has no meaningful hunger, thirst, bladder/bowel pressure, fatigue or other perceptible concern, Biology may omit or quiet that state. As a need becomes meaningful, presentation may progress from subtle sensation to explicit qualitative language to gameplay consequences according to the model.

### G-066 — Detailed values are secondary; polling Biology should never be required — LOCKED
The game should communicate important bodily state effectively enough that players do **not** feel compelled to repeatedly open Biology and inspect every detailed bar just to know whether V needs food, water, rest, a bathroom, care or attention to an injury.

Drill-down numbers/bars answer *what exactly is happening?* and help calibration/testing. Gameplay consequences and qualitative presentation should already answer *do I need to care about this now?* If repeated meter polling becomes optimal play, improve the embodied communication rather than promoting the bars to the overview/HUD.

---

## Presentation

### G-070 — Native modern scanner stays authoritative — LOCKED
Keep Cyberpunk's modern scanner/quickhack behavior rather than restoring Project E3's scanner replacement.

### G-071 — Biology owns an E3-inspired first-person HUD and NPC-nameplate visual language — LOCKED
The intended ordinary first-person presentation uses the recognizable **red E3-era HUD visual language and E3-inspired NPC nameplates**. This is an explicit Biology presentation target, not merely optional historical inspiration.

The finished implementation must be Biology-owned and standalone: Project E3 may be studied as reference/provenance, but its scripts, archive, tweak payload, settings class, save state or other executing runtime material must not be required by the finished mod. Preserve G-070: the modern Cyberpunk scanner/quickhack experience stays authoritative rather than restoring the old E3 scanner.

### G-072 — Presentation serves the simulation — LOCKED
UI should communicate what V could reasonably perceive/diagnose without becoming a dense spreadsheet or permanent RPG meter wall. Exact numerical state may be available in **deliberate Biology drill-down inspection** and development diagnostics, but not as always-visible gameplay/HUD or overview telemetry.

### G-073 — Public settings remain minimal; the provider is not a product dependency — LOCKED
The intended player-facing preference surface contains **at most two editable Boolean settings**, both default On when present:

1. **Enable Biology** — the one global master switch for the complete overhaul, provided a reliable whole-mod runtime switch remains practical.
2. **E3 first-person HUD visuals** — while Biology is enabled, controls only the Biology-owned E3-inspired first-person HUD/nameplate visual layer.

Do not fill settings with a feature ledger, status controls, patch notes, diagnostics, balance values, rate sliders or individual switches for body, injury, combat, armor, bleeding, recovery, cyberware physiology or other core authorities.

**Mod Settings is not itself a locked product requirement.** It may remain during migration only if the dependency audit proves it worthwhile. Prefer a Biology-owned preference surface if that removes unnecessary RED4ext/ArchiveXL/Mod Settings dependencies without creating a more brittle implementation.

### G-074 — Biology-on actor presentation is barless; master-off restores native fallback — LOCKED
While **Enable Biology = On**, traditional actor HP bars/HP-number feedback for V and supported actors should remain suppressed where technically safe. The 2026-09-14 attended session explicitly rejected the restored native red player-health indicator as enabled-overhaul behavior.

Do not replace that bar with a duplicate Biology percentage meter. Continue improving Biology UI, E3-inspired HUD, injury, impairment, pain, bleeding and other embodied cues as the meaningful replacement channels.

Turning the global master **Off** is the native fallback boundary and may restore Cyberpunk's stock actor-health presentation. Turning only the E3 first-person visual preference Off must not re-enable traditional actor HP bars or change the physical simulation.

---

## Distribution and ordinary use

### G-080 — One easy Biology package — LOCKED
The finished experience should be as close as practical to:

1. have Cyberpunk 2077 and the official free REDmod support installed/enabled as required by the supported platform;
2. download one Biology release;
3. copy/install one clearly identified Biology package, preferably `mods/Biology`;
4. deploy/enable through the supported REDmod path as needed;
5. click **Play** in Steam normally thereafter.

The player should not need Vortex knowledge or a manual stack of source/reference mods.

### G-081 — Normal Steam launch; no persistent Biology launcher — LOCKED
Ordinary play must not require a custom Biology launcher/background process. The official REDmod enable/deploy path is acceptable; after required setup, ordinary play should be as close as practical to normal Steam launch. Biology should not intentionally interfere with Steam achievements.

Do not promise REDlauncher skipping until the current supported REDmod/Steam behavior is directly verified.

### G-082 — Reproducible GitHub build/release path — LOCKED
When the runtime is ready, GitHub Actions should be able to build/test/assemble a deterministic player artifact, enforce provenance/forbidden-file rules, produce hashes/notices and publish the release artifact where licensing permits.

The build should increasingly produce the same REDmod-shaped Biology artifact used in attended testing, not a separate developer-only package shape.

### G-083 — Fresh source for every attended build; periodic clean-room game reset with strict baseline evidence — LOCKED
The local repository is disposable for user-facing build tests: use a fresh clone/download of canonical `main` each time.

A full Cyberpunk reinstall is **not** required for every small iteration. Reuse the installed game only when the previous test package is accounted for and the strict recorded vanilla baseline proves there is no unexplained residue. Use uninstall/delete/reinstall + refreshed baseline for milestone/structural/dependency changes, game patches, or any time the baseline cannot be restored/proven.

Development should not maintain multi-generation rollback chains or redundant save backups. Preserve a small auditable ownership/baseline record instead.

---

## Patch resilience and testing

### G-090 — Fail before install when native APIs change — LOCKED
The exact candidate should compile/preflight against the installed game/framework/REDmod environment before deployment. A Cyberpunk patch that changes a hooked signature or required deployment contract should preferably produce a compile/preflight failure rather than silently installing a broken runtime.

### G-091 — Broad attended testing beats tiny disconnected tests — LOCKED
Once a coherent owned-runtime candidate exists, prefer broad attended sessions that exercise scanner/presentation, Biology UI, body, combat, armor, injury, bleeding, pain/analgesia, impairment, treatment, save/reload and time progression together. Narrow diagnostic profiles remain available only to isolate failures.

Parallel development branches should normally converge into canonical `main` before the user performs a broad in-game milestone test.

### G-092 — Existing external/cloud save protection is sufficient for local development; no unattended game automation — LOCKED
Do **not** require an additional Biology-managed local save backup during ordinary attended development deployment. The project owner already considers saves adequately protected by existing cloud/external backup mechanisms and does not want deployment time spent duplicating that protection.

This does not relax exact compile/preflight, owned-file tracking, installed-byte verification, vanilla-baseline comparison or source-mod isolation. Do not add unattended game launching, background watchers/loggers/services or scheduled tasks.

### G-093 — Parallel agents are a normal project resource — LOCKED
When a large undertaking has safely separable workstreams, agents should proactively recommend splitting it across 2–3 branches/threads, provide self-contained handoffs, preserve explicit ownership boundaries and merge coherent lanes through PR/CI before combined attended testing.

Do not force parallelism when lanes would repeatedly conflict on the same core implementation. See `docs/PARALLEL-AGENT-WORKFLOW.md`.

---

## Current non-goals / unresolved implementation choices

These are **not** permission to change the locked goals above. They are implementation details still open:

- exact balance/calibration values for projectile/wound/body/pain/analgesia/recovery models;
- exact MaxDoc analgesic-load decay, diminishing-return curve and overdose thresholds;
- exact native pain/grunt VO events and throttling policy after local verification;
- exact realistic Biology mechanics for vanilla Bounce Back and Health Booster; preserve their vanilla names/identity while unresolved;
- exact field-supply item/data implementation for dressings and limb supports;
- exact Biology typography, grouping, colors, widget positions and animation timing;
- exact Biology node-to-model mapping, selective reuse/relabeling of Cyberware categories, and detailed-bar presentation within the shared body/anatomy shell;
- exact qualitative thresholds/cue escalation for hunger, thirst, elimination, fatigue, hygiene and other bodily sensations;
- the REDmod migration classification of each current runtime seam;
- the minimal set (possibly zero beyond redscript/REDmod as technically required) of generic third-party frameworks actually required by the final runtime;
- whether the two public preferences live inside Biology UI or a retained generic settings provider;
- exact official REDmod folder/load-order naming needed to produce the intended precedence without touching unrelated mods;
- exact professional-care cost/time/economy integration, provided it does not become an economy overhaul;
- exact handling for exceptional bosses/quest actors/robots/non-human targets beyond the locked ordinary-human physical model;
- exact Biology-owned implementation details for the red E3-inspired first-person HUD/nameplate layer while keeping the modern scanner native.

---

## Instructions for every future agent

1. Read this file **before** changing scope, architecture, packaging, UI or gameplay behavior.
2. Read `docs/BIOLOGY-REDMOD-MIGRATION.md` before adding/removing a runtime dependency or choosing REDmod vs wrapper/native routing.
3. Read `docs/PARALLEL-AGENT-WORKFLOW.md` before undertaking a large multi-subsystem migration.
4. Treat every `LOCKED` entry as a product requirement, not a suggestion.
5. If code/docs contradict a locked goal, record the contradiction and move the implementation toward the goal; do not redefine the goal to match legacy code.
6. Record newly agreed user goals here with stable `G-###` identifiers and update affected architecture/status docs in the same work batch.
7. Record implementation progress separately in `docs/WORKLOG.md`; do not confuse “goal agreed” with “goal implemented.”
8. Do not mark an owned-runtime milestone complete while Dark Future/Project E3 executing content remains required.
9. Do not present a release as self-contained while the user still has to understand/install a manual dependency stack that could reasonably have been removed.
10. Preserve vanilla item/system identity unless a new explicit product decision says otherwise; prefer realistic Biology mechanics beneath CDPR's existing names/assets/interactions over importing another mod's renames.
11. When safe parallel work exists, proactively offer a branch handoff instead of silently serializing the entire undertaking.