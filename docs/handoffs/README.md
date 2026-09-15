# Active parallel handoffs

These are the current copy/paste-ready work packets for the Biology REDmod refactor.

Use separate branches and merge through PR/CI before attended testing:

1. [`REDMOD-FOUNDATION.md`](REDMOD-FOUNDATION.md) -> `agent/redmod-foundation`
2. [`BIOLOGY-UI-RUNTIME.md`](BIOLOGY-UI-RUNTIME.md) -> `agent/biology-ui-runtime`
3. [`PRESENTATION-HUD-NAMEPLATES.md`](PRESENTATION-HUD-NAMEPLATES.md) -> `agent/presentation-hud-nameplates`

All three lanes should branch from the same canonical `main` revision after the roadmap/baseline documentation is merged. Each PR must record its exact starting SHA.

The project owner normally tests the **combined merged `main`**, not three separately layered branch installs.

See `../../ROADMAP.md`, `../ACTIVE-REDMOD-ROADMAP.md`, and `../PARALLEL-AGENT-WORKFLOW.md`.
