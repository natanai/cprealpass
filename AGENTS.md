# Biology agent instructions

Last updated: **2026-09-15**

**Biology** is the player-facing product identity for this foundational Cyberpunk 2077 body/physiology overhaul. The repository and some internal identifiers still use `cprealpass`, `RealPass`, and `CR*` during migration; do not perform a risky mass rename merely for cosmetics.

The product is intentionally designed so ordinary game patches should affect a small compatibility boundary rather than force broad rewrites. The current migration direction is **official REDmod-first, self-contained, and dependency-minimal**, while preserving narrower Biology-owned wrapper/native seams when REDmod whole-file replacement would be more brittle.

Read `docs/BIOLOGY-REDMOD-MIGRATION.md` before making packaging/dependency/runtime-routing decisions.

## PARALLEL WORK GATE — proactively split large work when safe

The project owner can often run **2–3 agents concurrently**. Treat that capacity as part of the normal development workflow.

When a task is large and contains independent workstreams, the current agent SHOULD:

1. identify safe parallel lanes;
2. keep one lane in the current thread/branch;
3. tell the user that another agent can usefully work in parallel;
4. provide a copy/paste-ready handoff for the new thread;
5. specify repository, branch, exact base SHA, owned scope, non-goals, canonical reading, deliverables, acceptance criteria and merge dependencies;
6. continue its own lane unless genuinely blocked.

Do **not** parallelize two implementations that must repeatedly edit the same core file/schema or where one lane depends on an unresolved interface from another.

Every parallel lane works on its **own branch**. Do not use `main` as a shared scratchpad. Merge coherent lanes through PRs/CI, then test the selected work together from canonical `main` as one release-shaped build.

For the full workflow, branch/ownership rules, handoff template, merge order and the preferred Biology REDmod migration split, read:

- `docs/PARALLEL-AGENT-WORKFLOW.md`
- `docs/BIOLOGY-REDMOD-MIGRATION.md`

If an agent foresees a large undertaking that can be split, it should explicitly report that fact to the user and provide the handoff rather than silently serializing everything.

## PARENT INTEGRATION GATE — worker lanes report into one integration thread

Parallel feature lanes are coordinated by a long-lived **parent/integration thread**. Read `docs/INTEGRATION-ORCHESTRATOR.md` before acting as that parent or before making cross-lane merge/test decisions.

The parent/integration thread owns:

- merge readiness and merge order across worker PRs;
- short-lived integration branches when combined risk is high;
- exact canonical-`main` awareness;
- clean local-test handoffs after selected lanes are integrated;
- durable attended test records under `docs/test-runs/`;
- routing live findings back to the original lane when appropriate, or creating/recommending a new lane when the finding is substantial, cross-cutting, or the original context is stale.

The parent thread is **not** a fourth broad implementation lane. It should normally return substantive subsystem fixes to their owner. It may handle only small merge glue, integration-only fixes, documentation/test-contract alignment, and deliberate conflict resolution.

Worker agents should make their PRs easy for the parent to integrate: state the exact branch/head, owned scope, CI status, remaining attended acceptance, direct-game probes, overlaps, and merge dependencies.

When attended testing reveals a failure, do not leave it only in chat. The parent should tie it to an exact `main` SHA/artifact, record it in `docs/test-runs/`, and give the receiving worker enough evidence to reproduce/understand the expected vs observed behavior without needing the parent conversation transcript.

## TEST HANDOFF GATE — read before telling the user a build is ready to test

Every user-facing live-test handoff MUST explicitly classify the requested test as one of these two modes:

### 1. ITERATION TEST

Use this for focused feature/UI/gameplay iteration when there has been no game patch, framework/package-layout change, or other structural reason to distrust the existing vanilla baseline.

Rules:

- The local repository/workspace is disposable. **Use a fresh clone/download of current canonical `main` for every user-facing test build.**
- A Cyberpunk reinstall is **not** required for every iteration.
- Reusing the game installation is allowed only when the prior Biology/RealPass test package is accounted for and the game can be returned to the **recorded vanilla baseline** without unexplained extra or modified files.
- Use `docs/CLEAN-ROOM-TESTING.md` and the baseline/reset tooling. If the reset cannot prove the game is back at baseline, stop and escalate to a milestone clean-room test.
- Build/install the same release-shaped package intended for players; do not use an accumulated developer deployment as the normal attended-test path.

### 2. MILESTONE CLEAN-ROOM TEST

Use this for large milestones, major structural/package changes, Cyberpunk patches, REDmod/dependency changes, unexplained baseline drift, or any test where stale files could plausibly invalidate the result.

Rules:

- uninstall Cyberpunk 2077 in Steam;
- delete any residual `Cyberpunk 2077` game directory after uninstall;
- reinstall through Steam;
- optionally launch vanilla once and exit;
- use the canonical milestone operator flow in `docs/LOCAL-OPERATOR-COMMANDS.md`;
- after a just-completed uninstall + residual-directory deletion + reinstall, the user may decline the additional exhaustive whole-game hash comparison; the fast vanilla sanity probe still runs and the evidence must explicitly say the exhaustive hash check was skipped;
- refresh/publish the tracked vanilla baseline when the clean reference itself needs to change, such as after a supported Cyberpunk patch, rather than blindly re-hashing the entire game twice for every milestone;
- use a fresh clone/download of current canonical `main`;
- build the release-shaped Biology test package and install/deploy it exactly as a player would.

### Mandatory wording in a test handoff

Before saying “ready to test”, “launch it”, or equivalent, the agent must state:

1. **Test mode:** `ITERATION` or `MILESTONE CLEAN-ROOM`.
2. **Source state:** the exact canonical `main` revision being tested.
3. **Game-state evidence:** exactly what was established — for example `verified against recorded vanilla baseline`, or `fresh Steam reinstall + fast sanity; exhaustive hash check skipped`.
4. **Artifact:** the release-shaped package being tested, not an accumulated repo/game state.

Do not casually instruct the user to reinstall Cyberpunk for every small change, do not casually reuse an unknown modded game directory, and do not overstate a skipped hash scan as baseline verification.

See `docs/CLEAN-ROOM-TESTING.md` before giving live-test instructions.

## LOCAL OPERATOR COMMAND GATE — do not invent routine PowerShell in chat

Before asking the user to run PowerShell/CMD against their local repo or Cyberpunk install, read:

- `docs/LOCAL-OPERATOR-COMMANDS.md`

That file is the **canonical user-run command surface**. If a catalogued command covers the operation, use it instead of recreating its internals in a new paste block. Routine milestone preparation, vanilla sanity/hash checks, baseline capture, package build, REDmod deployment, iteration reset, compatibility audit and snapshot publishing are all standardized there.

Rules:

- prefer one repository-owned command over a long hand-written shell sequence;
- agents may substitute the exact main SHA, disposable test-root name and known game path only where the catalog explicitly permits it;
- if a recurring operation is missing or inefficient, improve the tool/catalog/test contract first rather than inventing another private variant;
- one-off shell probes are allowed only for genuinely narrow, preferably read-only evidence questions not covered by the catalog;
- long operations must provide durable console progress; `Write-Progress` alone is not sufficient because some hosts hide it;
- attended milestone workspaces are disposable and should normally be named like `C:\Games\Biology-Test-<YYYY-MM-DD>-<short-main-sha>` rather than assuming a permanent `C:\Games\CyberpunkRealism` checkout;
- never claim a fast sanity check is equivalent to the strict full baseline/hash comparison.

## Read order — do this before changing scope or architecture

1. `AGREED-GOALS.md` — **what the product is now**. Locked goals outrank old implementation notes.
2. `docs/BIOLOGY-REDMOD-MIGRATION.md` — current product/package/dependency migration direction.
3. `docs/DECISION-HISTORY.md` — when decisions changed and which misunderstandings the user already corrected.
4. `docs/PARALLEL-AGENT-WORKFLOW.md` — branch/lane/handoff/merge rules.
5. `docs/INTEGRATION-ORCHESTRATOR.md` — parent-thread merge/test/evidence/routing rules when coordinating multiple lanes.
6. `docs/LOCAL-OPERATOR-COMMANDS.md` before asking the user to run local commands.
7. The focused architecture file relevant to the task, for example:
   - `docs/BIOLOGY-UI.md`
   - `docs/SETTINGS-ARCHITECTURE.md`
   - `docs/E3-PRESENTATION.md`
   - `docs/PATCH-RESILIENCE.md`
   - `docs/RELEASE-ARCHITECTURE.md`
   - `docs/CLEAN-ROOM-TESTING.md`
8. Machine-readable manifests/tests for the implementation contract.

Do **not** reconstruct current intent from old commits, closed branch workplans, historical prototypes, or old `RealPass` naming before reading the files above.

## Current product identity and ownership rules

- Player-facing product/package identity is **Biology**.
- Biology is one authored simulation, not a menu of unrelated realism modules.
- Biology includes body/needs, injury, combat consequences, physical clothing/armor protection, relevant cyberware/body interaction and the presentation required to communicate them.
- Executing gameplay/presentation behavior must be Biology-owned. Dark Future, Project E3 and other gameplay/presentation mods are reference only.
- Backpack = possessions; Biology = embodied state; Cyberware = installed equipment inside the shared body experience.
- Biology stays inspectable while healthy; quiet/`STABLE` overview does not mean hidden nodes or no drill-down.
- Exact numerical body values belong behind deliberate drill-down/testing, not on the ordinary HUD/overview.
- Traditional actor HP bars/numbers remain suppressed while Biology is enabled where technically safe.
- The modern scanner/quickhack experience remains native.
- E3 visual language remains an authored target, but no Project E3 runtime dependency is allowed.
- Vanilla item names/identities should be preserved unless an explicit new decision changes them.

## REDmod-first dependency/routing rule

For every runtime need, prefer in this order:

1. vanilla Cyberpunk semantic authority;
2. official REDmod where it expresses the behavior cleanly;
3. Biology-owned additive/wrapper scripting when narrower/more patch-resilient than REDmod whole-file replacement;
4. generic framework/native extension only when demonstrably necessary;
5. more invasive/version-sensitive mechanisms only as explicit isolated exceptions.

Do not keep a dependency because the old build already has it. The finished package should be as close as practical to one `mods/Biology` REDmod identity with any unavoidable extra framework payload explicitly justified.

Do not claim Biology can universally overpower every possible third-party mod. Biology should be authoritative for the systems it owns, use deterministic REDmod precedence where applicable, and leave unrelated systems alone.

## Evidence hierarchy for Cyberpunk internals

For questions about what the supported game build actually contains, exposes, names, calls, stores, or does, use this order:

1. repository-owned code/tests and `reference/cyberpunk/`;
2. targeted direct inspection of the user's installed Cyberpunk build;
3. official CDPR/REDmod/framework/tool documentation and release notes;
4. web/community examples as secondary evidence.

**Do not use internet search as a substitute for a small direct game-file inspection when the installed build can answer the question more authoritatively.**

If correctness depends on a vanilla class, method, event, record, resource path, controller, callback, state-machine path, widget ownership rule, REDmod deployment result or other game-internal fact and the tracked snapshot is insufficient, ask the user for a targeted local probe instead of guessing.

## Local game access available through the user

Known stable Windows path:

- Cyberpunk 2077: `C:\Games\Steam\steamapps\common\Cyberpunk 2077`

Repository/workspace paths are **not stable**. For attended milestones, prefer a disposable workspace such as:

```text
C:\Games\Biology-Test-<YYYY-MM-DD>-<short-main-sha>\
    operator\
    candidate\
```

Within whichever checkout is active:

- safe selective extraction area: `game-reference\extracted`;
- local generated indexes: `game-reference\index`;
- GitHub-safe derived snapshot: `reference\cyberpunk\`;
- GitHub-safe vanilla baseline: `reference\cyberpunk\vanilla-baseline\`.

If a checkout contains `game-reference\live`, it points at the real game installation. Treat it as **read-only** during investigation. Never ask the user to edit/delete/rename/repack through that junction merely to inspect something.

The tracked vanilla baseline contains only derived metadata (paths, sizes, hashes, versions/timestamps), never proprietary game content.

## Preferred proactive compatibility audit

After a Cyberpunk patch, major REDmod/framework/install change, or before basing foundational code on native seams, prefer the repository-owned read-only compatibility audit from the active checkout:

```powershell
pwsh ./tools/Audit-GameContracts.ps1 -GamePath 'C:\Games\Steam\steamapps\common\Cyberpunk 2077'
```

A successful audit is not runtime acceptance, but it should catch signature/type/linkage changes and refresh durable evidence.

For a narrow implementation question, prefer a smaller targeted probe rather than repeatedly running a broad audit or unpacking large archives.

## How to ask the user for local evidence

When a local probe would materially improve the work:

1. check `docs/LOCAL-OPERATOR-COMMANDS.md` first and use the catalogued command whenever one exists;
2. give one copy/paste-ready command/block only when needed;
3. use known absolute paths when possible;
4. make it read-only whenever possible;
5. explain exactly what uncertainty it resolves;
6. filter large output locally or write it to a file before asking the user to return it;
7. prefer paths, hashes, symbol names, record IDs, metadata and narrow tool output over proprietary file contents;
8. record durable conclusions in tracked code/docs/tests so another agent does not rediscover them.

## Patch-resilience design rules

Prefer:

- semantic game systems and named APIs over implementation accidents;
- official/native lifecycle/state ownership over duplicated shadow state;
- named classes/events/records/stats over magic indexes/offsets;
- thin game-facing adapters around stable Biology models;
- runtime discovery + validation when deterministic enough;
- exact compilation/deployment checks and explicit compatibility probes;
- fail-obvious/fail-closed behavior over silent incorrect simulation.

Avoid unless unavoidable:

- hard-coded memory offsets/addresses;
- copied/decompiled vanilla implementation bodies;
- wholesale REDmod `.script` replacement when a narrower additive/wrapper seam is safer;
- exact line numbers/file ordering;
- brittle widget-child positions when semantic ownership exists;
- fixed delays standing in for lifecycle events;
- patch-specific assumptions scattered through the simulation core;
- another gameplay/presentation mod as an intermediary when native/official contracts exist.

If a version-sensitive seam is unavoidable, isolate it in the smallest adapter, document the evidence, and add a validation/probe where practical.

See `docs/PATCH-RESILIENCE.md`, `docs/BIOLOGY-REDMOD-MIGRATION.md`, and `manifest/native-seams.json`.

## Native-first investigation principle

Before creating a parallel Biology mechanism, investigate whether Cyberpunk/REDmod already exposes an appropriate native authority or lifecycle: inventory/equipment behavior, player state, stat, status effect, TweakDB record, event, controller, animation/state machine, interaction, consumable action, cyberware hook, UI shell, archive/tweak/deploy route, etc.

Preferred shape:

```text
stable Biology simulation core
        |
        v
small semantic compatibility adapter
        |
        v
native Cyberpunk / official REDmod contract
```

not:

```text
Cyberpunk -> third-party gameplay mod -> Biology patch/bridge
```

## Settings principle during migration

The public settings contract remains tiny: one whole-mod master switch (renamed **Enable Biology**) plus the **E3 first-person HUD visuals** preference if those controls remain practical.

The provider is not sacred. Mod Settings may remain only while justified; prefer a Biology-owned preference surface if that safely removes RED4ext/ArchiveXL/Mod Settings dependencies. Do not expose body/combat/armor/needs/etc. as separate player-configurable modules or balance sliders.

## Instruction hygiene

When the user changes/corrects a requirement:

- update `AGREED-GOALS.md` if current product intent changed;
- append the correction to `docs/DECISION-HISTORY.md`;
- update the focused architecture doc and relevant contract/test;
- remove obsolete active workplans/instructions instead of leaving competing current directions;
- preserve history through Git.

When large work can be parallelized, also update/provide the branch handoffs described in `docs/PARALLEL-AGENT-WORKFLOW.md`.

When attended testing produces actionable evidence, the parent/integration thread should record and route it under `docs/INTEGRATION-ORCHESTRATOR.md` rather than leaving it only in conversation history.

Current tracked game baseline is Cyberpunk 2077 `2.31`; refresh/audit after later patches or whenever compatibility depends on a newer local state.
