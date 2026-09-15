# Biology — CURRENT ROADMAP

**This file is intentionally at repository root so active work is hard to miss.**

The current project is migrating from the transitional pre-REDmod RealPass runtime into the standalone **Biology** overhaul.

Before doing new implementation work, read:

1. `AGENTS.md`
2. `AGREED-GOALS.md`
3. `docs/PRE-REDMOD-LIVE-BASELINE-2026-09-15.md` — what the current build actually did in-game
4. `docs/ACTIVE-REDMOD-ROADMAP.md` — detailed issue ledger, sequencing, acceptance gates
5. `docs/BIOLOGY-REDMOD-MIGRATION.md` — architectural direction and rationale
6. `docs/PARALLEL-AGENT-WORKFLOW.md` — worker-lane branch/coordination rules
7. `docs/INTEGRATION-ORCHESTRATOR.md` — parent-thread merge, local-test, evidence, and redistribution policy

## Parent integration/orchestration thread

Parallel worker lanes are coordinated by one long-lived **parent integration thread**.

That parent thread is responsible for:

- reviewing/ordering merges and keeping canonical `main` coherent;
- deciding when multiple lane heads need a temporary integration branch before main;
- coordinating the user's clean local test against one exact combined `main` candidate;
- recording attended screenshots/logs/results under `docs/test-runs/`;
- routing each live-test finding back to the original lane when appropriate, or creating/recommending a new follow-up lane when that is cleaner;
- preventing the user from having to manually synchronize multiple agent threads.

The parent thread is **not** a fourth broad feature lane. Substantive subsystem fixes normally return to the appropriate worker branch/agent. Read `docs/INTEGRATION-ORCHESTRATOR.md` for the canonical routing rules.

Copy/paste-ready parent-thread startup/replacement packet:

- `docs/handoffs/PARENT-INTEGRATION.md`

## Current worker branches

The current refactor is intentionally split across up to three implementation agents:

- `agent/redmod-foundation` — official REDmod package/dependency foundation
- `agent/biology-ui-runtime` — Biology body shell, body-state lifecycle, navigation/drill-down
- `agent/presentation-hud-nameplates` — E3-inspired first-person HUD, NPC nameplates, presentation settings

Copy/paste-ready lane specifications live in:

- `docs/handoffs/REDMOD-FOUNDATION.md`
- `docs/handoffs/BIOLOGY-UI-RUNTIME.md`
- `docs/handoffs/PRESENTATION-HUD-NAMEPLATES.md`

## Current integration cycle

The intended cycle is:

```text
worker branches -> PR/CI -> parent merge/integration review -> canonical main
       -> one release-shaped local test -> docs/test-runs record
       -> findings routed back to original/new worker lanes -> repeat
```

Do not install three separate worker branches into the game merely because three agents are active. The user normally tests selected work only after it is integrated into a coherent canonical candidate.

## Most important attended findings driving this work

The exact pre-refactor candidate `ec8ba06451c3cbacabfad24f1479e1537147d0c9` launched, but:

- outer hub said `BIOLOGY` while inner navigation still said `CYBERWARE`;
- the `BIOLOGY | CYBERWARE` selector overlapped/faded into stock top navigation;
- the screen remained fundamentally Cyberware rather than Biology owning the shared body shell;
- live body state reported unavailable;
- persistent inspectable Biology nodes/drill-down were absent;
- the intended E3-style first-person HUD was not visibly present;
- intended E3 NPC nameplates were not active;
- the player health bar was hidden, but that alone does not prove the optional E3 presentation is working;
- turning E3 visuals off did not restore that bar because the current canonical barless-health rule is Biology-wide, exposing that the E3 toggle presently has no clear visible success signal;
- settings still exposed `REALPASS` / `Enable RealPass` transitional branding.

Do not patch these only cosmetically in the old architecture if the fix would be discarded by the REDmod migration. Treat them as acceptance requirements for the final Biology architecture.
