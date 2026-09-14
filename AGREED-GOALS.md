# realpass — agreed goals ledger

Last updated: 2026-09-14
Status: **canonical product-intent source of truth**

This file records the goals and product decisions explicitly agreed with the project owner. It exists so a new ChatGPT/Codex/local agent can understand the intended product without reconstructing chat history.

**Precedence rule:** if an older design/status document conflicts with this file, follow this file and update the older document. Do not silently reinterpret a locked goal. Calibration values and implementation details may evolve without changing the goal they serve.

## Status legend

- **LOCKED** — agreed product goal; change only after a new explicit user decision.
- **ACTIVE** — agreed direction currently being implemented.
- **OPEN** — implementation/calibration choice still to be resolved while preserving the locked goal.

---

## Product identity

### G-001 — One coherent realism mod — LOCKED
realpass is one authored Cyberpunk 2077 + Phantom Liberty realism pass, not a collection of unrelated difficulty/survival modules and not a repackaged mod stack.

### G-002 — Same realpass version means the same simulation — LOCKED
Internal modularity is for development, calibration, isolation and debugging. A normal release is **all-or-nothing**: accepted body, injury, combat, armor, cyberware-physiology and presentation authorities run together. Players do not get a menu for disabling core authorities or changing balance values independently.

Diagnostics remain development-only and off in a normal release.

### G-003 — Physical/physiological realism, not difficulty for difficulty's sake — LOCKED
The target is plausible cause/effect. A mechanic belongs only when it supports the physical body, injury, equipment, combat or presentation model. Added friction is not a goal by itself.

### G-004 — Vanilla-first mechanic replacement; preserve game identity — LOCKED
realpass starts from the **vanilla Cyberpunk game** and makes its existing systems behave more plausibly. Preserve CDPR item names, item identities, animations, screens, assets and interaction language whenever they remain useful; replace or reinterpret the underlying mechanics only where realism requires it.

Do **not** import Dark Future/E3 renames or other source-mod nomenclature as realpass features. In particular, do not rename one vanilla medical item into another concept. MaxDoc remains MaxDoc, Bounce Back remains Bounce Back, Health Booster remains Health Booster, and any future realpass role for each is authored against that vanilla identity.

For stability, prefer narrow hooks at semantic native boundaries and realpass-owned models behind them over wholesale asset/resource replacement, duplicated vanilla state, or variant-by-variant patches.

---

## Runtime ownership

### G-010 — Executing gameplay/presentation code must be ours — LOCKED
Dark Future, Project E3 HUD and other gameplay/presentation mods are **reference/inspiration only**. The finished realpass runtime must not depend on their scripts, state machines, UI assets, archives, save state or gameplay authority.

Observing how another mod solved a problem is allowed. The accepted behavior must then be re-derived from native Cyberpunk signals and implemented in realpass-owned source/data.

### G-011 — Generic frameworks may be plumbing only — LOCKED
redscript/RED4ext/Codeware/ArchiveXL/TweakXL or similar frameworks may remain only when they provide generic infrastructure that realpass genuinely needs. A framework may not own realpass gameplay policy, simulation state or authored presentation behavior. Remove framework dependencies that cease to be necessary.

### G-012 — Thin native adapters, stable realpass core — LOCKED
Patch-sensitive Cyberpunk hooks/mappings should be kept in thin boundary adapters. Simulation models and state should remain as game-version-independent as practical behind those adapters.

Preferred direction:

`Cyberpunk native API/event -> thin realpass adapter -> realpass model/state -> realpass presentation`

not:

`Cyberpunk -> another gameplay mod -> realpass patch/bridge`.

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
The authored realpass presentation hides traditional HP bars/HP-number feedback for V, ordinary NPCs, bosses/MaxTac and companions where technically safe. Injury and performance consequences are the intended feedback.

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
The top-level hub destination currently labeled **CYBERWARE** should become **BIOLOGY** while reusing the stock `cyberware_equip` body/anatomy fullscreen as the technical shell.

The player-facing hierarchy is:

`BIOLOGY -> shared body/anatomy shell -> BIOLOGY | CYBERWARE`

Biology is the parent concept because it owns V's embodied state: needs, sensations, injury/conditions, pain/analgesia, elimination, fatigue/rest, recovery, hygiene where retained, and relevant biological/cybernetic body state. **Cyberware is installed equipment within that body**, so it remains fully accessible as an internal mode/subcategory rather than owning the body screen.

Normal hub access should default to Biology. A direct ripperdoc/vendor context may default the internal mode to Cyberware for usability while preserving Biology as the parent screen.

### G-044 — Conditions are a subsection of Biology, not the screen itself — LOCKED
**Conditions** remains useful language for meaningful injury, illness, impairment, diagnosed/recognized pathology and cyberware/body damage. It is one subsection or mode within Biology rather than the name or total scope of the body screen.

Biology may organize player-facing information into restrained groups such as bodily needs/sensations, active conditions, effects and context-relevant responses. Exact visual grouping is open to native calibration.

### G-045 — Biology overview is qualitative; exact bars belong only to deliberate drill-down — LOCKED
Healthy, irrelevant or currently imperceptible state should remain visually quiet. The unzoomed Biology view should surface things such as `thirsty`, `very hungry`, `need to urinate`, `exhausted`, `bleeding`, `dizzy`, `impaired` or a recognized active condition when those states are meaningful.

Do **not** replace the removed HP bar with an always-visible hydration/hunger/fatigue/pain/blood/bladder meter wall. Exact values may be displayed after a player intentionally selects/zooms into a relevant body system or region, including as bars useful for testing and deep inspection. Those bars must read the authoritative model directly and disappear again at the overview/gameplay level.

### G-046 — Reuse Cyberpunk's native body nodes/zooms as Biology's interaction language — LOCKED
Biology should reuse the existing Cyberware screen's central body silhouette, anatomical/system anchors, hover highlighting, node interaction and zoom-in/zoom-out language where technically robust.

In Biology mode, stock cyberware slot contents may be hidden while anatomically useful categories become Biology nodes. Existing labels such as Arms, Skeleton, Nervous System, Integumentary System, Circulatory System and Legs are valuable native language. Cyberware-specific categories should be relabeled or omitted only when realpass has an authoritative body concept behind the replacement; do not invent physiology merely to fill every vanilla slot.

Switching to the internal **CYBERWARE** mode must restore the ordinary Cyberpunk cyberware equipment/slot experience without duplicating or rewriting its inventory authority.

### G-047 — Injury detail explains what happened — LOCKED
The zoomed condition view should explain, in restrained player-facing language:

- what kind of condition/injury exists;
- which region is affected;
- approximate severity and functional effect;
- external vs internal bleeding when relevant;
- biological vs cybernetic damage;
- **how/when the condition likely occurred** when realpass has enough evidence;
- what protection was involved/defeated when useful;
- what can be done in the field;
- what requires professional/clinical/mechanical care.

### G-048 — Persist compact injury provenance without replacing regional state — ACTIVE
Add a bounded realpass-owned injury provenance/history record so the UI can explain causes such as projectile family, impact type, region, protection/penetration result and approximate time of injury. The **regional physical state remains authoritative**; history explains how the current state arose and must not become an unbounded status-effect pile.

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
**MaxDoc remains MaxDoc.** realpass keeps the vanilla inhaler item identity/animation/quick-slot behavior but replaces its magical HP-regeneration role with **analgesia only**: it reduces perceived pain.

MaxDoc must not dress bleeding, splint fractures, replace blood, heal tissue/bone, repair chrome or refill native HP. Dressing and limb support require their own appropriate supplies. Health Booster and Bounce Back remain separately named vanilla items and must not be silently treated as MaxDoc or renamed into another mod's concepts.

### G-055 — Pain is a realpass body state/consequence — LOCKED
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
Backpack/inventory is the source of truth for physical items V carries. Realpass hunger, thirst, fatigue, elimination, pain, injury severity and other body-state presentation do **not** live as status bars or a body dashboard in Backpack.

Inventory-specific information that genuinely describes possessions may remain there. Realpass physiology presentation belongs in Biology.

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

### G-071 — E3 is visual inspiration only — LOCKED
Useful E3-era HUD/nameplate ideas may be recreated with realpass-owned code/assets, but Project E3 runtime assets/scripts may not be required by the finished mod.

### G-072 — Presentation serves the simulation — LOCKED
UI should communicate what V could reasonably perceive/diagnose without becoming a dense spreadsheet or permanent RPG meter wall. Exact numerical state may be available in **deliberate Biology drill-down inspection** and development diagnostics, but not as always-visible gameplay/HUD or overview telemetry.

---

## Distribution and ordinary use

### G-080 — One easy player package — LOCKED
The finished experience should be as close as practical to:

1. download one realpass release;
2. extract/copy it into the Cyberpunk 2077 game directory (or use one equally simple installer only if technically/licensing necessary);
3. click **Play** in Steam normally.

The player should not need Vortex knowledge or a manual stack of source/reference mods.

### G-081 — Normal Steam launch; no persistent realpass launcher — LOCKED
Ordinary play must not require a custom realpass launcher/background process. Skipping REDlauncher is desirable where supported, while still launching through Steam. realpass should not intentionally interfere with Steam achievements.

### G-082 — Reproducible GitHub build/release path — LOCKED
When the runtime is ready, GitHub Actions should be able to build/test/assemble a deterministic player artifact, enforce provenance/forbidden-file rules, produce hashes/notices and publish the release artifact where licensing permits.

### G-083 — Keep development installation lightweight; use external game repair — LOCKED
Local development iteration should **not** spend significant time maintaining multi-generation rollback chains, repeated game-file backups or local save snapshots that duplicate recovery already provided elsewhere.

The owned development installer should stay small and fast: exact-compile before install, keep a flat manifest of files realpass wrote, replace the current realpass-owned payload directly, remove known retired realpass/Dark Future/Project E3 runtime residue, and hash-check the bytes it actually installs.

If a development install damages the stock game, the accepted recovery path is: remove recorded realpass-owned extra files first, then use **Steam Verify Files** or reinstall Cyberpunk as needed. Steam verification is not assumed to remove arbitrary extra mod files, which is why a small realpass ownership/removal record remains useful. Public release tooling may provide a similarly simple uninstall path, but preserving a historical rollback chain is not a product requirement.

---

## Patch resilience and testing

### G-090 — Fail before install when native APIs change — LOCKED
The exact candidate should compile/preflight against the installed game/framework environment before deployment. A Cyberpunk patch that changes a hooked signature should preferably produce a compile/preflight failure rather than silently installing a broken runtime.

### G-091 — Broad attended testing beats tiny disconnected tests — LOCKED
Once a coherent owned-runtime candidate exists, prefer broad attended sessions that exercise scanner/presentation, body, combat, armor, injury, bleeding, pain/analgesia, impairment, treatment, save/reload and time progression together. Narrow diagnostic profiles remain available only to isolate failures.

### G-092 — Existing external/cloud save protection is sufficient for local development; no unattended game automation — LOCKED
Do **not** require an additional realpass-managed local save backup during ordinary attended development deployment. The project owner already considers their saves adequately protected by existing cloud/external backup mechanisms and does not want deployment time spent duplicating that protection.

This does not relax exact compile/preflight, owned-file tracking, installed-byte verification or source-mod isolation. Do not add unattended game launching, background watchers/loggers/services or scheduled tasks.

---

## Current non-goals / unresolved implementation choices

These are **not** permission to change the locked goals above. They are implementation details still open:

- exact balance/calibration values for projectile/wound/body/pain/analgesia/recovery models;
- exact MaxDoc analgesic-load decay, diminishing-return curve and overdose thresholds;
- exact native pain/grunt VO events and throttling policy after local verification;
- exact realistic realpass mechanics for vanilla Bounce Back and Health Booster; preserve their vanilla names/identity while these remain unresolved;
- exact field-supply item/data implementation for dressings and limb supports;
- exact Biology typography, grouping, colors, widget positions and animation timing;
- exact Biology node-to-model mapping, selective reuse/relabeling of Cyberware categories, and detailed-bar presentation within the shared body/anatomy shell;
- exact qualitative thresholds/cue escalation for hunger, thirst, elimination, fatigue, hygiene and other bodily sensations;
- the minimal set of generic frameworks actually required by the final owned runtime;
- exact professional-care cost/time/economy integration, provided it does not become an economy overhaul;
- exact handling for exceptional bosses/quest actors/robots/non-human targets beyond the locked ordinary-human physical model;
- final implementation of realpass-owned E3-inspired nameplate/HUD aesthetics.

---

## Instructions for every future agent

1. Read this file **before** changing scope, architecture, packaging, UI or gameplay behavior.
2. Treat every `LOCKED` entry as a product requirement, not a suggestion.
3. If code/docs contradict a locked goal, record the contradiction and move the implementation toward the goal; do not redefine the goal to match legacy code.
4. Record any newly agreed user goal here with a stable `G-###` identifier and update affected architecture/status docs in the same work batch.
5. Record implementation progress separately in `docs/WORKLOG.md`; do not confuse “goal agreed” with “goal implemented.”
6. Do not mark an owned-runtime milestone complete while Dark Future/Project E3 executing content remains required.
7. Do not present a release as all-in-one while the user still has to understand/install a manual dependency stack.
8. Preserve vanilla item/system identity unless a new explicit product decision says otherwise; prefer swapping realistic realpass mechanics beneath CDPR's existing names/assets/interactions over importing another mod's renames.