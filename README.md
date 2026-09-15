# realpass

A Cyberpunk 2077 + Phantom Liberty realism overhaul in development. RealPass starts from the **vanilla game** and replaces selected underlying mechanics with project-original physical/physiological systems while preserving CDPR names, item identities, screens, animations, inventory/equipment authority, and interaction language wherever they remain useful.

RealPass is not a repackaged gameplay-mod stack and not a menu of arbitrary difficulty toggles. The intended release is one authored simulation: connected body/needs, regional injury and recovery, physical projectile/impact behavior, meaningful armor/clothing coverage, relevant cyberware physiology, and restrained presentation that communicates those systems.

## Read this first

Current instructions are intentionally kept small and explicit:

1. [`AGENTS.md`](AGENTS.md) — agent evidence rules, direct local-game inspection, patch resilience, and clean-room testing.
2. [`AGREED-GOALS.md`](AGREED-GOALS.md) — canonical current product intent. Locked goals beat old implementation notes.
3. [`docs/DECISION-HISTORY.md`](docs/DECISION-HISTORY.md) — dated user decisions, reversals, and misunderstandings that agents must not repeat.
4. Read the focused architecture file for the subsystem you are changing.

Superseded handoff packets and old active-status instructions are removed from the current tree rather than left beside canonical instructions. Git history preserves them when historical research is actually needed.

## Core product rules

- Executing RealPass gameplay/presentation behavior must be **RealPass-owned**. Dark Future and Project E3 are research/provenance references only.
- Generic frameworks may remain only as plumbing when genuinely needed; they do not own RealPass simulation policy.
- **Backpack = possessions. Biology = embodied state. Cyberware = installed equipment.**
- Biology is always inspectable, including when V is healthy. The healthy overview is terse (`STABLE`); exact values belong to deliberate drill-down rather than a permanent meter wall.
- Combat is causal and physical: projectile/ammunition -> region -> encountered material/protection -> penetration/impact -> tissue/chrome injury -> physiology -> treatment/recovery.
- Ordinary human wound severity is not meant to be driven by level-based HP-sponge scaling.
- MaxDoc remains MaxDoc and becomes analgesia rather than magical tissue/blood/chrome repair.
- Vanilla Outfits are being reinterpreted as **physical equipment loadouts**: the visible item and the protective equipped object must be the same physical state.
- The modern Cyberpunk scanner/quickhack experience remains authoritative.
- Traditional actor HP bars/numbers are suppressed while RealPass is enabled.
- The visual target remains a **RealPass-owned red E3-inspired first-person HUD and NPC-nameplate language**, without restoring the old E3 scanner or requiring Project E3 as a runtime dependency.

Weather overhaul, economy overhaul, artificial scarcity, hardship encounters, travel restrictions, and unrelated generic difficulty mechanics remain out of scope unless a later explicit product decision changes that.

## Player settings

RealPass currently has exactly two intended public Boolean controls in Mod Settings, both default On:

- **Enable RealPass** — global all-or-nothing master switch;
- **E3 first-person HUD visuals** — presentation-only preference while RealPass is enabled.

There is no feature ledger, patch-note/status panel, diagnostic menu, balance slider, or separate body/combat/injury/armor toggle. Turning the E3 visual preference off does not change the physical simulation or restore actor HP bars.

See [`docs/SETTINGS-ARCHITECTURE.md`](docs/SETTINGS-ARCHITECTURE.md).

## Biology

The player-facing hierarchy is:

```text
BIOLOGY -> shared native body/anatomy shell -> BIOLOGY | CYBERWARE
```

Biology owns bodily needs/sensations, injury/conditions, pain/analgesia, elimination, fatigue/rest, recovery, and relevant biological/cybernetic state. Cyberware remains the ordinary installed-equipment experience inside the shared body screen.

The overview is qualitative and terse. Supported system/region nodes stay available even when normal. Exact hydration/nutrition/blood/bleeding/pain/regional integrity and similar values may appear only after deliberate inspection.

See [`docs/BIOLOGY-UI.md`](docs/BIOLOGY-UI.md).

## Direct official-game evidence and patch resilience

Remote agents cannot directly browse the user's local Cyberpunk installation, but the repository is intentionally connected to it through a read-only local evidence workflow. The tracked, redistribution-safe snapshot lives under `reference/cyberpunk/`; the real installed game remains outside Git.

For foundational questions such as a class/method signature, controller, lifecycle event, TweakDB record, resource path, or native ownership boundary, agents should prefer direct evidence from the supported installed build over old web examples when a small local probe can answer the question.

The proactive compatibility command is:

```powershell
Set-Location 'C:\Games\CyberpunkRealism'
pwsh ./tools/Audit-GameContracts.ps1
```

It is read-only against the game. It refreshes the safe environment snapshot, fingerprints the important official script/database boundaries, inventories RealPass's native-hook surface, validates the native-seam policy, and exact-compiles project-owned REDscript against the installed Cyberpunk base script bundle. This is an early patch-breakage canary, not a substitute for live gameplay/UI/save/quest testing.

For narrower questions, agents should ask for one targeted PowerShell/CMD/WolvenKit probe rather than bulk-extracting the game or guessing from community material.

See [`docs/LOCAL-GAME-REFERENCE.md`](docs/LOCAL-GAME-REFERENCE.md) and [`docs/PATCH-RESILIENCE.md`](docs/PATCH-RESILIENCE.md).

## Testing and distribution

The final player experience should approach one simple game-root-shaped package: copy/extract it into Cyberpunk 2077, then launch normally through Steam. Players should not need Vortex knowledge, a manual source-mod stack, or a persistent custom launcher.

Broad attended acceptance is deliberately **clean-room and release-shaped**:

1. use fresh/canonical source;
2. restore the Cyberpunk game directory to a genuinely vanilla baseline;
3. build the game-root-shaped candidate with `tools/Build-CleanRoomTestPackage.ps1`;
4. merge that artifact into the vanilla game root as a normal player would;
5. launch normally through Steam and test that exact package.

Narrow exact-compile/API investigations may use the existing local environment when installed mod residue cannot affect the result.

See [`docs/CLEAN-ROOM-TESTING.md`](docs/CLEAN-ROOM-TESTING.md) and [`docs/RELEASE-ARCHITECTURE.md`](docs/RELEASE-ARCHITECTURE.md).

## Current implementation status

Project-original source contains the body/needs clock and intake model, sleep/fatigue/exertion, digestion/elimination, ballistic/impact models, regional wounds, blood loss, impairment, armor wear, pain/analgesia, field/professional care, physical Outfit adaptation, Biology presentation/native-shell work, scanner/nameplate integration, and actor-healthbar suppression seams.

The repository has also established explicit native-seam boundaries and exact-compile tooling so future Cyberpunk patches should preferentially fail at a small game-facing adapter rather than silently alter the simulation core.

Several important gates remain live-test work. In particular, the full owned red E3-style first-person HUD recreation is **not yet complete**, and source/compile correctness does not by itself prove native UI rendering, save persistence, quest compatibility, gameplay feel, or runtime performance.

## Repository layout

- `src/redscript` / `src/tweaks` — RealPass simulation, presentation, and thin game-facing adapters.
- `manifest` — runtime, feature, acceptance, dependency, ownership, and native-seam contracts.
- `tests` — cloud-safe models/contracts plus local compatibility checks where appropriate.
- `tools` — dependency acquisition, exact compilation, local game-reference audits, packaging, and development utilities.
- `reference/cyberpunk` — redistribution-safe metadata derived from the user's supported installed game.
- `docs` — current focused architecture, decision history, testing, and release policy.
- `LICENSES` / `THIRD_PARTY.md` — dependency and historical reference provenance/notice material.

Downloaded frameworks, proprietary game assets, local extractions, generated staging, reports, deployment state, and saves stay outside the public repository unless represented only by safe derived metadata.
