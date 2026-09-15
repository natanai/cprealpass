# Biology — REDmod-first product and migration architecture

Status: **canonical architecture direction**  
Last updated: **2026-09-15**  
Repository: `natanai/cprealpass`  
Player-facing product/package identity: **Biology**

This document defines architecture. It intentionally does **not** define current worker branch names. For active work, read root `ROADMAP.md`, `ACTIVE-REDMOD-ROADMAP.md`, and current GitHub issues/PRs.

## Decision

Biology is one coherent systemic overhaul centered on the premise that V and supported actors are physical bodies rather than disconnected RPG meters.

That product boundary can include systems that materially determine what happens to the body:

- metabolism, food, hydration, fatigue, sleep, elimination and hygiene where retained;
- pain, analgesia, injury, bleeding, impairment, treatment and recovery;
- projectiles, impact regions and physical combat consequences;
- clothing, armor, material protection, coverage and wear;
- cyberware as installed structure inside/alongside the body;
- restrained UI/audio/visual feedback needed to perceive those systems;
- physical outfit/loadout behavior where visible/equipped protection must be the same physical state used by simulation.

It does not automatically expand into unrelated economy, weather, generic hardship, travel restrictions, random encounters or difficulty systems.

## Product hierarchy

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
|   +-- tissue / bone / bleeding / impairment
|   +-- treatment / recovery
|
+-- Combat / Protection
|   +-- projectile / impact region
|   +-- material encounter / penetration
|   +-- clothing / armor / coverage / wear
|
+-- Cyberware
    +-- installed equipment
    +-- cybernetic structure / damage
    +-- biological interaction
```

The **BIOLOGY** game screen is the player-facing body home. Cyberware remains an internal mode because it is installed equipment within the shared body experience, not the parent product concept.

## Distribution objective

The preferred release is centered on one recognizable official REDmod package:

```text
Cyberpunk 2077/
└── mods/
    └── Biology/
        ├── info.json
        ├── scripts/       # only when accepted whole-file REDmod script routing is robust
        ├── tweaks/        # accepted Biology tweak sources
        ├── archives/      # Biology-owned resources
        └── customSounds/  # only if Biology owns custom sound content
```

Do not manufacture REDmod subtrees simply to match a diagram. The package shape follows actual accepted routes.

The first integrated milestone has already proven that official REDmod can recognize and deploy the Biology package on Cyberpunk 2077 2.31. Future work must preserve that proof while fixing runtime/UI/presentation behavior.

## Dependency ladder

For each runtime requirement, prefer:

1. **Vanilla Cyberpunk semantic authority** — native item/system/state/event/controller behavior when it can carry the intended semantics.
2. **Official REDmod** — package identity, archives/resources, tweaks, sound/animation paths, and whole-file script replacement only when genuinely robust.
3. **Biology-owned additive/wrapper scripting** — currently redscript where a narrow wrapper/additive seam is materially safer than replacing an entire vanilla script file.
4. **Generic framework/native extension** — only when a current Biology feature demonstrably requires it.
5. **More invasive/version-sensitive mechanisms** — isolated exceptions with direct compatibility evidence and a narrow adapter.

A dependency does not survive because an older build happened to use it.

## Why REDmod-first does not mean REDmod-only

Official REDmod whole-file script routing can increase patch/conflict surface when it requires copying a larger vanilla implementation than Biology actually needs.

Therefore the engineering question is:

```text
Does official REDmod express this behavior cleanly without increasing the compatibility surface compared with a narrower Biology-owned seam?
```

If yes, use REDmod. If not, keep the smallest evidenced Biology-owned fallback.

## Runtime-route classifications

Use these classifications when auditing a feature/file family:

- `REDMOD-NATIVE`
- `REDMOD-POSSIBLE-BUT-BRITTLE`
- `REDSCRIPT-BETTER`
- `REQUIRES-NATIVE-EXTENSION`
- `REMOVE/RETHINK`
- `UNKNOWN — NEEDS DIRECT GAME PROBE`

The audit should cover at minimum:

- body clock/state/persistence;
- consumable routing;
- inventory/equipment transactions;
- Biology/Cyberware UI shell and navigation;
- injury/bleeding/pain/impairment hooks;
- combat/projectile/damage interception;
- armor/clothing/outfit authority;
- health-bar/nameplate/HUD presentation;
- settings/activation persistence;
- care interactions;
- archives/tweaks/localization/sounds/animation;
- build/install/disable/uninstall and load-order behavior.

## Authoritative overlap policy

Biology should be authoritative for systems it explicitly owns, while minimizing changes outside those systems.

Where REDmod can deterministically express precedence for overlapping REDmod-controlled resources, package/deploy policy may use that precedence. Do not claim universal dominance over redscript/CET/RED4ext/native hooks or other mechanisms outside REDmod's per-file model.

A self-contained mod is not a mod that forcibly overrides everything.

## Self-contained identity and uninstallability

The target release should make ownership obvious:

- one `mods/Biology` identity;
- one product/version/provenance identity;
- no Dark Future or Project E3 executing content;
- no unexplained loose legacy payload;
- any unavoidable framework payload explicitly justified and represented in ownership metadata;
- safe disable/removal without historical rollback chains.

The release UX now has three intended states:

1. REDlauncher mods enabled → Biology active.
2. REDlauncher mods disabled → Biology behavior inactive / convenient vanilla-play mode, once the activation audit proves this across supplemental routes.
3. self-contained `Uninstall Biology.exe` → hard removal of manifest-proven Biology-owned files without requiring a full Steam reinstall.

Issue #44 owns implementation of that contract. A full game reinstall is an exceptional clean-room/recovery operation, not normal Biology uninstall.

## Settings direction

Biology remains one authored simulation, not a set of independently toggled modules.

The public preference surface should remain small. The provider is not product architecture. Mod Settings may remain only while a current feature justifies it; do not preserve a framework stack merely to host a small number of booleans.

The launcher-level Biology activation contract and the optional E3-inspired presentation preference must remain semantically distinct.

## REDmod launch/deployment UX target

Target player experience:

1. install official REDmod support if the game install does not already contain it;
2. copy/install one Biology release;
3. use the normal REDlauncher/Steam mod-enable path;
4. launch normally through Steam;
5. use the launcher mod toggle for convenient Biology-on / Biology-inactive play once proven;
6. use the Biology uninstaller for full removal.

No Biology-specific persistent launcher/background service is desired.

## Current architecture milestone

Already demonstrated in the first integrated REDmod milestone:

- `mods/Biology` package identity;
- release-shaped builder;
- exact compilation against the supported 2.31 script bundle;
- installation into a clean game;
- official REDmod recognition;
- real REDmod deploy stages through an explicit-root, fail-closed helper.

Still active after attended testing:

- Biology native-shell/detail/back behavior (#39);
- authoritative body-runtime lifecycle/availability (#41);
- complete E3-inspired ordinary HUD and ambient nameplates (#40);
- player disable/hard-uninstall contract (#44);
- later dependency reduction where current consumers can be eliminated safely.

For exact live evidence and current branch assignments, use `ROADMAP.md`, `ACTIVE-REDMOD-ROADMAP.md`, and `docs/test-runs/`.

## Patch resilience

For every version-sensitive seam:

- use direct supported-build evidence when practical;
- isolate the seam from the simulation core;
- register/audit native boundaries where appropriate;
- exact-compile/package against the supported game before attended tests;
- fail obvious/closed rather than silently presenting incorrect state.

See `PATCH-RESILIENCE.md` and `manifest/native-seams.json`.

## Project E3 / external references

Project E3 and Dark Future may be studied as design/provenance references. They do not execute or ship as Biology runtime dependencies.

For Project E3 specifically, `config/realpass-e3.json` preserves a durable inventory of the local-only reference package. The actual `ReferenceMods/` payload is intentionally gitignored and must not be copied into the public Biology repository simply to make remote agents convenient.

Derived design/controller mappings are appropriate repository material; third-party payload is not.

## Acceptance criteria for the architecture

The REDmod-first architecture is successful when:

1. player-facing/package identity is Biology;
2. the release is centered on `mods/Biology` with only justified supplemental payload;
3. official REDmod owns every surface it can own robustly;
4. every retained non-REDmod dependency has a current feature-specific justification;
5. no source gameplay/presentation mod executes at runtime;
6. Biology touches only systems it intends to own;
7. native seams are narrow and auditable;
8. package build/deploy is reproducible from fresh canonical source;
9. body authority is available and persistent in live sessions;
10. Biology is the body parent with Cyberware as an internal mode;
11. E3 presentation has an obvious attended effect while the modern scanner stays native;
12. users can install, temporarily disable and fully remove Biology without needing development knowledge or a routine Steam reinstall.

## Parallelization policy

Do not hard-code live branch names in this architecture document. Large work should still be split when ownership boundaries are safe, using `PARALLEL-AGENT-WORKFLOW.md`.

Current lanes and exact branches belong in root `ROADMAP.md`, the active follow-up ledger, and GitHub issues/PRs so architecture does not become stale every time a worker merges.
