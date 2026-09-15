# Biology — REDmod-first product and migration plan

Status: **canonical migration direction**
Last updated: **2026-09-15**
Current repository name: `cprealpass` (may remain during migration)
Player-facing product name: **Biology**

> **Active execution:** read `PRE-REDMOD-LIVE-BASELINE-2026-09-15.md` and `ACTIVE-REDMOD-ROADMAP.md` before starting migration work. The active roadmap incorporates attended evidence and supersedes any older generic lane split where they differ.

## Decision

The finished overhaul is **Biology**, not a generic “realism pack.” Biology is one coherent systemic overhaul built around the premise that V and supported actors are physical bodies rather than collections of unrelated RPG meters.

That product boundary intentionally includes systems that may not look biological in isolation when they materially determine what happens to the body:

- metabolism, food, hydration, fatigue, sleep, elimination and hygiene where retained;
- pain, analgesia, injury, bleeding, impairment, treatment and recovery;
- weapons, projectiles, impact regions and physical combat consequences;
- clothing, armor, material protection, coverage and wear;
- cyberware as installed structure inside/alongside the body;
- restrained UI, audio and visual feedback required to perceive those systems;
- physical outfit/loadout behavior where the visible/equipped item must be the same item encountered by protection logic.

This is not permission to expand into unrelated economy, weather, hardship, travel restriction, random encounter or “realism for realism's sake” systems. A feature belongs when it supports the authored body/protection/combat model.

## Product hierarchy

The conceptual product map is:

```text
BIOLOGY
|
+-- Body
|   +-- metabolism / food / hydration
|   +-- fatigue / sleep
|   +-- elimination / hygiene
|   +-- pain / sensation
|
+-- Injury
|   +-- tissue
|   +-- bone
|   +-- bleeding
|   +-- impairment
|   +-- treatment / recovery
|
+-- Combat
|   +-- weapon / projectile
|   +-- impact region
|   +-- material encounter
|   +-- physical injury consequence
|
+-- Protection
|   +-- clothing
|   +-- armor
|   +-- coverage
|   +-- wear / condition
|
+-- Cyberware
    +-- installed equipment
    +-- cybernetic structure
    +-- mechanical damage
    +-- biological interaction
```

The **BIOLOGY** game screen remains the player-facing body home. Cyberware remains accessible as a Biology submode because it is installed equipment within the body, not the parent concept.

## Distribution objective

The preferred finished installation is one recognizable official REDmod package:

```text
Cyberpunk 2077/
└── mods/
    └── Biology/
        ├── info.json
        ├── scripts/       # only where official REDmod script replacement is appropriate
        ├── tweaks/        # REDmod/TweakDB source where appropriate
        ├── archives/      # Biology-owned assets/resources where appropriate
        └── customSounds/  # only if Biology owns custom sound content
```

The exact folder contents are evidence-driven. Do not manufacture a REDmod subfolder merely to fill the shape.

The official REDmod toolchain is the **first routing option** for systems it can own cleanly. A finished Biology release should be as self-contained and self-reliant as practical and should avoid requiring players to assemble a stack of community gameplay mods or framework dependencies.

## Official-path-first development rule

Biology does not merely *package* through REDmod when convenient. The project should learn the game on CDPR's terms whenever the installed official tooling can expose the needed truth.

For each new native/game-internal problem, use this order before copying an established community workaround:

1. inspect the installed official REDmod decompiled script tree under `tools\redmod\scripts` for current class/event/field/controller ownership;
2. inspect or invoke the installed official `tools\redmod\bin\redMod.exe` when its own command surface can answer the packaging/deploy/resource question directly;
3. use official REDmod package/script/tweak/archive mechanisms where they express the required behavior cleanly;
4. only then consider redscript wrappers, RED4ext, ArchiveXL, TweakXL, Codeware, CET, or another community technique — and only with a written reason the official route is insufficient or materially more brittle.

The existence or popularity of a community workaround is **not evidence that it is the best route for Biology**. Historical mods often optimized for the tooling/ecosystem available at the time. Biology should re-evaluate those assumptions against Cyberpunk 2.31's installed REDmod capabilities.

This may mean occasionally re-deriving functionality that community mods already solved. That is acceptable when it yields a smaller, more official, more inspectable compatibility boundary.

The project must not blindly force REDmod where it cannot safely express a narrow behavior. “Official-path-first” means **investigate and prefer the official path every time**, not “ignore evidence that a whole-file REDmod replacement would be less stable than a tiny additive seam.” Deviations must be evidence-backed exceptions, not defaults inherited from modding convention.

## Dependency ladder

For every runtime requirement, prefer the highest viable layer:

1. **Vanilla Cyberpunk 2077 semantic authority** — native item/system/state/event/controller behavior when it can carry the intended Biology behavior.
2. **Official REDmod** — packaging, archives, tweak sources, sound/animation paths, and script replacement only where that replacement is genuinely the robust option.
3. **Biology-owned additive/wrapper scripting** — currently redscript where a narrow wrapper/additive seam is materially safer than copying/replacing an entire vanilla script file.
4. **Generic native/framework extension** — RED4ext/ArchiveXL/Codeware/TweakXL/Mod Settings/etc. only when a required Biology behavior cannot be implemented robustly above and the dependency has a clear, isolated benefit.
5. **Anything more invasive/version-sensitive** — exceptional and requires explicit justification, compatibility evidence, and a narrow adapter.

A dependency does **not** survive merely because the current build already uses it. The REDmod migration audit must prove why each dependency remains necessary.

## Why REDmod-first does not mean REDmod-only

Official REDmod script modding uses modified `.script` files at their vanilla paths and resolves conflicts on a per-file basis. That can be appropriate when Biology intentionally owns an entire file/resource, but it can also be brittle across patches because a copied 2.31 vanilla file can become stale after CDPR changes unrelated code in that same file.

A narrow additive/wrapper seam may therefore be **more patch-resilient** than an official whole-file replacement. The project must choose the route that minimizes the actual compatibility surface after the official route has been investigated directly.

The migration question for every current mechanism is therefore:

```text
What can current installed REDmod do here, and does it express this behavior cleanly without copying more vanilla implementation than necessary?
```

If yes, migrate it to REDmod. If not, record the specific limitation/risk and keep the smallest justified Biology-owned fallback.

## Required migration classification

Every current runtime feature/file family must be audited and assigned one of these classifications before the REDmod migration is considered designed:

- `REDMOD-NATIVE` — official REDmod is clearly the preferred final route.
- `REDMOD-POSSIBLE-BUT-BRITTLE` — technically possible through REDmod, but likely increases patch/conflict surface compared with a narrower seam.
- `REDSCRIPT-BETTER` — an additive/wrapper redscript seam is demonstrably narrower/more resilient than REDmod whole-file replacement **after the official REDmod route was directly investigated**.
- `REQUIRES-NATIVE-EXTENSION` — the feature cannot be implemented adequately through vanilla/REDmod/redscript and requires a generic native framework.
- `REMOVE/RETHINK` — the current mechanism exists because of historical architecture and should disappear rather than be migrated.
- `UNKNOWN — NEEDS DIRECT GAME PROBE` — do not guess; use `reference/cyberpunk/`, installed `tools\redmod\scripts`, `redMod.exe`, or request a targeted local inspection before choosing a route.

For every classification below `REDMOD-NATIVE`, preserve the evidence explaining why the higher official layer was rejected.

The audit should cover at minimum:

- body clock/state and persistence;
- food/consumable routing;
- inventory/equipment transactions;
- Biology/Cyberware UI shell and navigation;
- injury/bleeding/pain/impairment hooks;
- combat/projectile/damage interception;
- armor/clothing/outfit authority;
- health-bar/nameplate/HUD presentation;
- E3-inspired visual presentation;
- settings/master-switch persistence;
- professional/field care interactions;
- any archives, tweaks, localization, sounds or animation dependencies;
- build/install/uninstall and load-order behavior.

The active three-lane plan divides this audit by consumer: Lane A owns package/dependency classification, while Lane B and Lane C must classify their own UI/runtime and presentation seams and report concrete dependency requirements back to Lane A.

## Authoritative-overlap policy

Biology is intended to be **authoritative for the systems it explicitly owns**. If another mod alters the same REDmod-controlled file/resource, Biology's deployment/load-order policy should prefer Biology where REDmod can deterministically express that precedence.

However, do **not** claim universal dominance over every possible Cyberpunk mod. Another mod may use redscript wrappers, RED4ext/CET/native hooks, runtime TweakDB mutation, or another mechanism outside REDmod's per-file conflict model.

The compatibility promise is therefore:

> Biology owns the physical systems it changes, minimizes edits outside those systems, and uses explicit deterministic precedence where the official loader can provide it. Unrelated mods should remain untouched; overlapping mods may be incompatible unless their behavior composes cleanly.

Do not broaden Biology's file footprint merely to “win” conflicts.

## Self-contained identity and uninstallability

The final package should make it obvious which files belong to Biology.

Preferred end state:

- one `mods/Biology` REDmod identity;
- one product/version/provenance identity;
- no Dark Future or Project E3 executing content;
- no unexplained loose files scattered through legacy mod locations;
- any unavoidable external framework payload explicitly listed and justified;
- simple uninstall/removal instructions based on owned paths, not historical rollback chains;
- disabling/removing Biology should yield the affected systems back to native Cyberpunk as cleanly as technically possible.

The repository name and internal class/file prefixes may remain `cprealpass`, `RealPass`, or `CR*` temporarily during migration. **Do not perform a risky mass rename merely for cosmetic consistency.** Player-facing product identity, package identity and new documentation should use **Biology** now; internal identifiers can migrate incrementally when doing so is low-risk.

## Settings direction

Biology remains one authored simulation, not a collection of independently toggled modules.

The public preference contract remains intentionally tiny:

- one global **Enable Biology** master switch, if a reliable whole-mod runtime switch remains practical;
- one E3-inspired first-person HUD presentation preference.

The **provider is no longer a product requirement**. Mod Settings may remain during migration only if the dependency audit proves it worthwhile. Prefer a Biology-owned settings surface (for example, a restrained preferences subsection inside Biology) if that can remove RED4ext/ArchiveXL/Mod Settings dependencies without making the implementation more brittle.

Do not preserve a framework stack merely to host two booleans.

## REDmod launch/deployment UX target

Official REDmod requires deployment and modded launch behavior. The migration must determine the cleanest supported Steam experience and document it before release.

Target user experience:

1. install/enable the free official REDmod DLC/tooling if the game installation does not already contain it;
2. copy/install the single Biology package;
3. enable mods through the supported Cyberpunk/Steam/REDlauncher path once as needed;
4. thereafter launch normally through Steam without a Biology-specific launcher or background process.

Do not promise launcher skipping until verified against the current supported game/REDmod behavior.

## Migration phases

### Phase 0 — preserve the attended baseline and freeze the old packaging direction

The pre-refactor live evidence is recorded in `PRE-REDMOD-LIVE-BASELINE-2026-09-15.md`. During migration:

- do not add new third-party runtime dependencies;
- do not add new loose legacy-package paths unless required for an urgent correctness fix;
- do not spend large effort polishing the old RealPass root-package architecture as though it were final;
- keep current code compiling so useful simulation work is not lost;
- do not lose the attended failures by declaring source-level tests equivalent to live acceptance.

### Phase 1 — inventory and classify

Create a machine-readable/runtime inventory mapping each current file/feature to the classification list above. Record:

- current mechanism;
- intended final mechanism;
- touched vanilla authority/file/resource;
- patch-risk rationale;
- conflict/load-order implications;
- required dependency;
- official REDmod capability investigated;
- evidence/probe needed;
- migration owner/branch.

### Phase 2 — establish minimal official REDmod skeleton

Build the smallest `mods/Biology` package that:

- has valid REDmod identity/metadata;
- can be deployed by official REDmod tooling;
- can be enabled/disabled without unrelated payload;
- contains no gameplay behavior merely for demonstration;
- is verified against the recorded vanilla baseline.

### Phase 3 — migrate low-risk REDmod-native systems

Move assets/tweaks/resources and other clearly REDmod-native content first. Remove superseded legacy paths as each migration becomes authoritative.

### Phase 4 — decide script seams individually

For each script-based behavior, first inspect current installed REDmod source/tool capability, then compare:

- REDmod whole-file `.script` replacement;
- Biology-owned redscript wrapper/addition;
- native/plugin alternative;
- removal/re-design.

Choose the smallest stable seam. Add compatibility probes for every version-sensitive fallback and document why REDmod itself was not selected when it loses.

### Phase 5 — dependency reduction

After behavior is migrated, remove any framework that no longer has a proven runtime consumer. Rebuild the dependency graph from actual need rather than historical inheritance.

Special scrutiny:

- Mod Settings;
- ArchiveXL if retained only because of Mod Settings;
- RED4ext if no remaining native plugin requires it;
- any framework present only because an earlier source mod used it.

### Phase 6 — authoritative overlap/load-order acceptance

Test Biology alone, then representative overlapping mods where practical. Establish exactly what REDmod precedence can guarantee and document known incompatibility classes without pretending to solve every third-party hook collision.

### Phase 7 — clean-room milestone

Only after the new packaging path is coherent and the active UI/presentation lanes are integrated:

- start from a recorded clean vanilla installation;
- fresh-clone canonical `main`;
- build the release-shaped Biology/REDmod artifact;
- install it exactly as a player would;
- deploy/enable it through the official path;
- launch through Steam;
- test Biology UI, body, needs, combat, armor/clothing, cyberware, HUD, treatment, save/reload and time progression together;
- capture the matched screenshot set required by `ACTIVE-REDMOD-ROADMAP.md`;
- snapshot the resulting installed game state so residue is auditable.

## Acceptance criteria for the migration

The REDmod migration is not complete until all are true:

1. player-facing/product/package identity is **Biology**;
2. the package is as close as practical to a single `mods/Biology` installation;
3. official REDmod has been directly investigated for every runtime surface, and owns every surface it can own without increasing patch fragility;
4. each non-REDmod runtime dependency or redscript fallback has a written, current, feature-specific justification tied to a demonstrated REDmod limitation/risk;
5. no source gameplay/presentation mod executes at runtime;
6. no framework remains solely because it happened to exist in an older development stack;
7. Biology's touched systems have documented precedence/conflict behavior;
8. unrelated systems are not modified merely to force compatibility/load-order dominance;
9. a clean-room install is auditable against the recorded vanilla baseline;
10. the exact candidate passes compile/preflight, official REDmod deployment, Steam launch, save/reload and broad attended gameplay acceptance;
11. Biology body state is available and inspectable in the live UI;
12. Biology is the parent body mode with Cyberware as submode;
13. the E3-inspired HUD/nameplate option has an obvious visible attended effect while preserving the modern scanner;
14. a user can understand install/disable/remove without knowing the project's development history.

## Parallelization — current active split

This migration is intentionally large enough to split across agents. Follow `docs/PARALLEL-AGENT-WORKFLOW.md` and the active issue ledger in `ACTIVE-REDMOD-ROADMAP.md`.

The current attended-evidence-informed split is:

### Lane A — `agent/redmod-foundation`

Official REDmod/package/dependency architecture:

- `mods/Biology` skeleton and official deploy/load proof;
- package/install/uninstall shape;
- dependency graph and removal candidates;
- REDmod overlap/load-order evidence;
- package/dependency classification and tooling.

Handoff: `handoffs/REDMOD-FOUNDATION.md`

### Lane B — `agent/biology-ui-runtime`

Biology body shell/runtime availability:

- Biology parent / Cyberware submode hierarchy;
- outer/inner navigation identity;
- selector placement/behavior;
- `Body state is unavailable` root cause;
- persistent nodes, drill-down metrics, save/reload lifecycle.

Handoff: `handoffs/BIOLOGY-UI-RUNTIME.md`

### Lane C — `agent/presentation-hud-nameplates`

HUD/nameplates/settings presentation:

- Biology-owned E3-inspired first-person HUD;
- Biology-owned E3-inspired NPC nameplates;
- modern scanner preservation;
- E3 ON/OFF semantics and matched screenshot acceptance;
- player-facing presentation/settings identity.

Handoff: `handoffs/PRESENTATION-HUD-NAMEPLATES.md`

These lanes should work on separate branches and merge only after their owned contracts are individually green. The combined `main` candidate is then tested once as a whole.
