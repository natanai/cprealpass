# realpass — agreed goals ledger

Last updated: 2026-09-13
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
The model may use exact internal values. Normal player presentation should translate them into understandable condition language rather than expose raw simulation percentages/rates as a replacement health meter.

Examples: minor/moderate/severe trauma, external bleeding, suspected internal injury, impaired function, supported fracture, damaged chrome.

### G-042 — Physical consequences communicate injury during combat — LOCKED
During a fight the player should mostly learn that something is wrong through believable consequences: movement impairment, stamina loss, degraded weapon handling/reload, pain, bleeding/weakness and similar effects—not through an exact HP readout.

### G-043 — Cyberware/body screen becomes the canonical condition interface — LOCKED
The final injury UI belongs in the game's existing **Cyberware/body screen**, using CDPR's body visualization as the shell. The current backpack Field Care popup is a development prototype and should be retired once the Condition interface replaces it.

### G-044 — Cyberware / Condition modes — LOCKED
The body screen should provide a clear `CYBERWARE | CONDITION` mode concept.

- **Cyberware mode:** retain the normal vanilla cyberware purpose/behavior as much as practical.
- **Condition mode:** cyberware mod-slot presentation is replaced/dimmed by realpass condition entries anchored around the same body.

The goal is to feel native to Cyberpunk rather than like a separate mod configuration screen.

### G-045 — Conditions are the selectable objects — LOCKED
Condition mode should show meaningful active conditions rather than six permanent `BODY PART: OK` tiles. Healthy regions can remain visually quiet. Injuries/damage become selectable entries associated with the relevant anatomy.

Examples: left-arm gunshot wound, torso blunt trauma, head concussive trauma, right-leg cyberware actuator damage.

### G-046 — Reuse the game's anatomical zoom/drill-down behavior — LOCKED
Selecting a condition/body area should use the existing Cyberware/ripperdoc paper-doll zoom language wherever technically possible. Do not recreate a parallel full-screen medical UI if the vanilla screen can supply the navigation/zoom shell.

If vanilla only provides a combined Arms/Legs zoom, realpass may use that regional camera and then distinguish left/right conditions within the zoomed view rather than inventing fragile camera assets.

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

### G-049 — Same condition screen supports field and professional care — LOCKED
When opened normally, the Condition view exposes only plausible field care. In an appropriate ripperdoc/clinical context, the same body/condition language should expose professional biological treatment and mechanical cyberware repair as appropriate.

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

### G-054 — Trauma kits are analgesia only — LOCKED
The item realpass presents as a **Trauma Kit** is not a wound-healing item and must not dress bleeding, splint fractures, replace blood, heal tissue/bone, repair chrome or refill native HP. Its authored physiological purpose is to **numb/reduce perceived pain only**.

Dressing and limb support therefore require their own appropriate field supplies rather than consuming Trauma Kits.

### G-055 — Pain is a realpass body state/consequence — LOCKED
Pain is part of the authored physiology/injury experience. Physical injury generates pain independently of native HP. Pain relief changes perception/functional pain response; it does **not** repair the underlying injury, restore structural function or erase blood loss.

### G-056 — Analgesia has diminishing returns and overuse consequences — LOCKED
Repeated Trauma Kit use within a short enough physiological window has diminishing pain-relief benefit. Excess concurrent analgesic load produces an overdose/intoxication state rather than unlimited relief.

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

---

## Presentation

### G-070 — Native modern scanner stays authoritative — LOCKED
Keep Cyberpunk's modern scanner/quickhack behavior rather than restoring Project E3's scanner replacement.

### G-071 — E3 is visual inspiration only — LOCKED
Useful E3-era HUD/nameplate ideas may be recreated with realpass-owned code/assets, but Project E3 runtime assets/scripts may not be required by the finished mod.

### G-072 — Presentation serves the simulation — LOCKED
UI should communicate what V could reasonably perceive/diagnose without becoming a dense spreadsheet or permanent RPG meter wall. Detailed exact numerical state belongs in development diagnostics, not normal play.

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

### G-083 — Safe upgrades and rollback underneath simple UX — LOCKED
Even if installation is simple, development/release tooling should preserve collision checks, ownership manifests, verified save backup where appropriate, rollback data and fail-closed verification.

---

## Patch resilience and testing

### G-090 — Fail before install when native APIs change — LOCKED
The exact candidate should compile/preflight against the installed game/framework environment before deployment. A Cyberpunk patch that changes a hooked signature should preferably produce a compile/preflight failure rather than silently installing a broken runtime.

### G-091 — Broad attended testing beats tiny disconnected tests — LOCKED
Once a coherent owned-runtime candidate exists, prefer broad attended sessions that exercise scanner/presentation, body, combat, armor, injury, bleeding, pain/analgesia, impairment, treatment, save/reload and time progression together. Narrow diagnostic profiles remain available only to isolate failures.

### G-092 — Save safety; no unattended game automation — LOCKED
Before live development deployment, maintain verified save backup/rollback practices. Do not add unattended game launching, background watchers/loggers/services or scheduled tasks.

---

## Current non-goals / unresolved implementation choices

These are **not** permission to change the locked goals above. They are implementation details still open:

- exact balance/calibration values for projectile/wound/body/pain/analgesia/recovery models;
- exact Trauma Kit analgesic load decay, diminishing-return curve and overdose thresholds;
- exact native pain/grunt VO events and throttling policy after local verification;
- exact field-supply item/data implementation for dressings and limb supports now that Trauma Kits are analgesia-only;
- exact Condition-mode typography, colors, widget positions and animation timing;
- whether all condition UI can be mounted dynamically without shipping a custom `.inkwidget` asset;
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
