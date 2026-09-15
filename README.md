# Biology

**Biology** is a Cyberpunk 2077 + Phantom Liberty systemic body overhaul in development. It starts from the vanilla game and replaces selected underlying mechanics with project-original physical/physiological systems while preserving CDPR names, item identities, screens, animations, inventory/equipment authority, and interaction language wherever they remain useful.

The repository is still named `cprealpass`, and some internal identifiers remain `RealPass` / `CR*` during migration. Do not perform a risky mass rename merely for cosmetics. Player-facing product/package identity is **Biology**.

Biology is not a repackaged gameplay-mod stack and not a menu of arbitrary difficulty toggles. The intended release is one authored simulation: connected body/needs, regional injury and recovery, physical projectile/impact behavior, meaningful armor/clothing coverage, relevant cyberware physiology, and restrained presentation that communicates those systems.

## READ THIS FIRST — active work

The project is currently beginning a **REDmod-first refactor** after a clean-room attended test of the pre-refactor runtime.

1. [`ROADMAP.md`](ROADMAP.md) — **current active work, next branches, and the failures observed in-game.**
2. [`AGENTS.md`](AGENTS.md) — mandatory agent evidence, parallel-branch, direct game-inspection, and test-handoff rules.
3. [`AGREED-GOALS.md`](AGREED-GOALS.md) — canonical current product intent. Locked goals beat old implementation notes.
4. [`docs/PRE-REDMOD-LIVE-BASELINE-2026-09-15.md`](docs/PRE-REDMOD-LIVE-BASELINE-2026-09-15.md) — exact attended evidence from the current pre-refactor build.
5. [`docs/ACTIVE-REDMOD-ROADMAP.md`](docs/ACTIVE-REDMOD-ROADMAP.md) — detailed issue ledger, sequencing, ownership, and acceptance criteria.
6. [`docs/BIOLOGY-REDMOD-MIGRATION.md`](docs/BIOLOGY-REDMOD-MIGRATION.md) — REDmod-first/self-contained architecture direction and rationale.
7. [`docs/PARALLEL-AGENT-WORKFLOW.md`](docs/PARALLEL-AGENT-WORKFLOW.md) — branch/lane/handoff/merge policy.

Superseded handoff packets and old active-status instructions should be removed from the current tree rather than left beside canonical instructions. Git history preserves them when historical research is actually needed.

## Current parallel work split

The next migration phase is intentionally suitable for **2–3 agents in parallel**:

- `agent/redmod-foundation` — official REDmod package/dependency foundation;
- `agent/biology-ui-runtime` — Biology body shell, body-state lifecycle, navigation and drill-down;
- `agent/presentation-hud-nameplates` — E3-inspired HUD, NPC nameplates, presentation settings.

Copy/paste-ready lane specifications live under [`docs/handoffs/`](docs/handoffs/).

Agents should not serialize all three lanes in one thread when parallel capacity is available, and they should not test separate branches by layering them into the same game install. Merge coherent branches into canonical `main`, then test one combined release-shaped candidate.

## Pre-REDmod attended baseline

The exact clean-room candidate at `ec8ba06451c3cbacabfad24f1479e1537147d0c9` compiled, packaged, installed into a freshly baselined Cyberpunk 2.31 directory, and launched.

It also established that major work remains:

- outer hub shows `BIOLOGY`, but inner navigation still says `CYBERWARE`;
- the current `BIOLOGY | CYBERWARE` selector overlaps/fades into stock navigation;
- Biology does not yet truly own the body shell; the screen is still fundamentally Cyberware;
- live body state reports unavailable;
- persistent inspectable Biology nodes/exact drill-down were not demonstrated;
- the intended E3-style first-person HUD was not visibly present;
- intended E3 NPC nameplates were not active;
- the player health bar was hidden, proving some presentation code runs, but health-bar suppression alone is **not** evidence that the optional E3 presentation is working;
- settings still expose obsolete `REALPASS` / `Enable RealPass` player-facing branding.

These are migration acceptance requirements, not invitations to cosmetically polish an overlay architecture that is being replaced. See the baseline and active roadmap docs above.

## Core product rules

- Executing Biology gameplay/presentation behavior must be **Biology-owned**. Dark Future and Project E3 are research/provenance references only.
- Generic frameworks may remain only as plumbing when genuinely needed; they do not own Biology simulation policy.
- **Backpack = possessions. Biology = embodied state. Cyberware = installed equipment.**
- Biology is always inspectable, including when V is healthy. The healthy overview is terse (`STABLE`); exact values belong to deliberate drill-down rather than a permanent meter wall.
- Combat is causal and physical: projectile/ammunition -> region -> encountered material/protection -> penetration/impact -> tissue/chrome injury -> physiology -> treatment/recovery.
- Ordinary human wound severity is not meant to be driven by level-based HP-sponge scaling.
- MaxDoc remains MaxDoc and becomes analgesia rather than magical tissue/blood/chrome repair.
- Vanilla Outfits are being reinterpreted as **physical equipment loadouts**: the visible item and the protective equipped object must be the same physical state.
- The modern Cyberpunk scanner/quickhack experience remains authoritative.
- Traditional actor HP bars/numbers are suppressed while Biology is enabled under the current locked product goal.
- The visual target remains a **Biology-owned red E3-inspired first-person HUD and NPC-nameplate language**, without restoring the old E3 scanner or requiring Project E3 as a runtime dependency.

Weather overhaul, economy overhaul, artificial scarcity, hardship encounters, travel restrictions, and unrelated generic difficulty mechanics remain out of scope unless a later explicit product decision changes that.

## REDmod-first direction

The finished release should be as close as practical to one official package:

```text
Cyberpunk 2077/
└── mods/
    └── Biology/
        ├── info.json
        └── ...only the REDmod-supported content Biology actually needs
```

Routing preference:

1. vanilla Cyberpunk semantic authority;
2. official REDmod where it expresses the feature cleanly;
3. narrow Biology-owned additive/wrapper scripting when safer than whole-file REDmod script replacement;
4. generic framework/native extension only when demonstrably necessary.

REDmod-first does **not** mean blindly copying whole vanilla scripts merely to avoid a community framework. Patch resilience and conflict surface matter more than branding the route as official.

See [`docs/BIOLOGY-REDMOD-MIGRATION.md`](docs/BIOLOGY-REDMOD-MIGRATION.md).

## Player settings

Biology remains one authored simulation, not a collection of gameplay-module toggles.

The old pre-refactor Mod Settings page currently exposes two booleans (`Enable RealPass` and `E3 first-person HUD visuals`). That provider and wording are **transitional, not final product requirements**.

The REDmod/dependency audit must decide whether:

- a whole-mod runtime master switch remains useful in addition to official mod enable/disable;
- the E3-inspired presentation preference remains as a small Biology-owned setting;
- those preferences can move into Biology and eliminate Mod Settings/ArchiveXL/RED4ext dependency depth.

Under the current product goal, turning the E3-specific visual preference off does not alter simulation and does not by itself restore actor HP bars while Biology remains enabled. The attended baseline showed that the current E3 preference has no clearly demonstrated visual success signal yet because the intended HUD/nameplate treatment is absent.

See [`docs/SETTINGS-ARCHITECTURE.md`](docs/SETTINGS-ARCHITECTURE.md) and [`docs/E3-PRESENTATION.md`](docs/E3-PRESENTATION.md).

## Biology screen

The player-facing hierarchy is:

```text
BIOLOGY -> shared native body/anatomy shell -> BIOLOGY | CYBERWARE
```

Biology owns bodily needs/sensations, injury/conditions, pain/analgesia, elimination, fatigue/rest, recovery, and relevant biological/cybernetic state. Cyberware remains the ordinary installed-equipment experience inside the shared body screen.

The overview is qualitative and terse. Supported system/region nodes stay available even when normal. Exact hydration/nutrition/blood/bleeding/pain/regional integrity and similar values may appear only after deliberate inspection.

The attended pre-refactor build did **not** yet achieve this hierarchy: it still showed stock Cyberware as the effective parent and reported body state unavailable. See [`docs/BIOLOGY-UI.md`](docs/BIOLOGY-UI.md).

## Direct official-game evidence and patch resilience

Remote agents cannot directly browse the user's local Cyberpunk installation, but the repository is intentionally connected to it through a read-only local evidence workflow. The tracked, redistribution-safe snapshot lives under `reference/cyberpunk/`; the real installed game remains outside Git.

For foundational questions such as a class/method signature, controller, lifecycle event, TweakDB record, resource path, or native ownership boundary, agents should prefer direct evidence from the supported installed build over old web examples when a small local probe can answer the question.

The proactive compatibility command is:

```powershell
Set-Location 'C:\Games\CyberpunkRealism'
pwsh ./tools/Audit-GameContracts.ps1
```

It is read-only against the game. It refreshes the safe environment snapshot, fingerprints important official script/database boundaries, inventories Biology's native-hook surface, validates the native-seam policy, and exact-compiles project-owned REDscript against the installed Cyberpunk base script bundle. This is an early patch-breakage canary, not a substitute for live gameplay/UI/save/quest testing.

For narrower questions, agents should ask for one targeted PowerShell/CMD/WolvenKit probe rather than bulk-extracting the game or guessing from community material.

See [`docs/LOCAL-GAME-REFERENCE.md`](docs/LOCAL-GAME-REFERENCE.md) and [`docs/PATCH-RESILIENCE.md`](docs/PATCH-RESILIENCE.md).

## Testing and distribution

Attended testing uses two tiers. A full Cyberpunk reinstall is **not** required for every iteration.

- **Iteration test:** fresh canonical source + reset/verify the existing game directory against the recorded vanilla baseline.
- **Milestone clean-room:** reinstall/delete residual game directory/rebaseline when structural package/dependency changes or unexplained residue make that necessary.

Broad user-facing tests should install the same release-shaped artifact intended for players, not an accumulated developer deployment.

See [`docs/CLEAN-ROOM-TESTING.md`](docs/CLEAN-ROOM-TESTING.md) and [`docs/RELEASE-ARCHITECTURE.md`](docs/RELEASE-ARCHITECTURE.md).

## Current implementation status

Project-original source contains the body/needs clock and intake model, sleep/fatigue/exertion, digestion/elimination, ballistic/impact models, regional wounds, blood loss, impairment, armor wear, pain/analgesia, field/professional care, physical Outfit adaptation, Biology presentation/native-shell work, scanner/nameplate integration, and actor-healthbar suppression seams.

The repository has also established explicit native-seam boundaries and exact-compile tooling so future Cyberpunk patches should preferentially fail at a small game-facing adapter rather than silently alter the simulation core.

Source/compile correctness does not prove native UI rendering, save persistence, quest compatibility, gameplay feel, runtime performance, REDmod deployment behavior, or visual fidelity. The attended baseline intentionally records where those claims are still unproven or failed.

## Repository layout

- `src/redscript` / `src/tweaks` — Biology simulation, presentation, and thin game-facing adapters (some transitional paths still use old naming).
- `manifest` — runtime, feature, acceptance, dependency, ownership, and native-seam contracts.
- `tests` — cloud-safe models/contracts plus local compatibility checks where appropriate.
- `tools` — dependency acquisition, exact compilation, local game-reference audits, packaging, and development utilities.
- `reference/cyberpunk` — redistribution-safe metadata derived from the supported installed game.
- `docs` — current focused architecture, baseline evidence, roadmap, testing, release policy, and lane handoffs.
- `LICENSES` / `THIRD_PARTY.md` — dependency and historical reference provenance/notice material.

Downloaded frameworks, proprietary game assets, local extractions, generated staging, reports, deployment state, and saves stay outside the public repository unless represented only by safe derived metadata.
