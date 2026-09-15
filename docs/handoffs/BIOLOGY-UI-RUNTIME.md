# Handoff — Biology UI / body-runtime lane

Use this as the source-of-truth handoff for a new agent thread.

## Goal

Make **Biology** the actual parent body interface in-game, not a label/overlay pasted onto Cyberware. Fix live body-state availability, persistent body-system inspection, navigation identity, and the Biology/Cyberware mode boundary while preserving native Cyberware equipment behavior.

## Repository / branch

- Repository: `natanai/cprealpass`
- Create branch: `agent/biology-ui-runtime`
- Base: current canonical `main` **including** the pre-REDmod live-baseline/roadmap documentation. Record the exact starting SHA in the PR.
- Do not work directly on `main`.

## Read first

1. `AGENTS.md`
2. `AGREED-GOALS.md`
3. `docs/PRE-REDMOD-LIVE-BASELINE-2026-09-15.md`
4. `docs/ACTIVE-REDMOD-ROADMAP.md`
5. `docs/BIOLOGY-UI.md`
6. `docs/BIOLOGY-REDMOD-MIGRATION.md`
7. `docs/PARALLEL-AGENT-WORKFLOW.md`
8. `manifest/native-seams.json`
9. current Biology/body/runtime REDscript and related tests

## Attended evidence you must address

The clean-room pre-refactor build at `ec8ba06451c3cbacabfad24f1479e1537147d0c9` showed:

- outer hub destination says `BIOLOGY`;
- inner top navigation still says `CYBERWARE`;
- faint `BIOLOGY | CYBERWARE` text overlaps the stock top-navigation area;
- entering Biology still displays the stock Cyberware equipment layout rather than a Biology overview;
- bottom body text says `Body state is unavailable.`;
- persistent Biology system nodes/exact drill-down are not visible.

These observations are canonical in `PRE-REDMOD-LIVE-BASELINE-2026-09-15.md`.

## Owned scope

You own:

- `NAV-01`, `NAV-02`;
- `BIO-01`..`BIO-08`;
- `STATE-01`..`STATE-04` from `docs/ACTIVE-REDMOD-ROADMAP.md`;
- player-facing body-screen routing/navigation identity;
- Biology/Cyberware mode switching;
- Biology view-model/controller lifecycle;
- live access to authoritative body runtime;
- persistent supported Biology nodes;
- deliberate exact metrics/bars in drill-down;
- terse status telemetry;
- preservation of stock Cyberware mode interactions;
- contextual Biology actions only through real authoritative transaction paths.

## Non-goals / boundaries

Do not own:

- REDmod package/dependency architecture (`agent/redmod-foundation`);
- E3-inspired first-person HUD/nameplates (`agent/presentation-hud-nameplates`);
- body/combat calibration unless a proven runtime/lifecycle bug requires a narrow change;
- broad internal renaming merely for cosmetics.

Do not add framework/package dependencies yourself. If the UI genuinely requires one, document the concrete requirement and coordinate with the REDmod foundation lane.

## Investigation priorities

### 1. Resolve body-state unavailability before polishing

Treat `Body state is unavailable.` as a functional blocker.

Investigate at minimum:

- `CRBodyRuntime` ScriptableSystem registration/availability timing;
- release/acceptance gates and global enable state;
- menu controller's `GameInstance` access;
- save/load initialization;
- whether the body runtime is present but rejected by presentation policy;
- stale or transitional view-model code paths;
- whether the current menu is opening in a context that lacks the expected system reference.

Do not hide the error with `STABLE` if state is actually unavailable.

### 2. Establish proper ownership hierarchy

Target:

```text
top hub -> BIOLOGY -> native shared body shell -> BIOLOGY | CYBERWARE
```

Normal hub entry should default to Biology. Cyberware is an internal submode. A ripperdoc/vendor entry may default to Cyberware if justified.

### 3. Persistent Biology nodes

Healthy/quiet state must still expose modeled systems. `STABLE` is only overview telemetry.

Reuse native body silhouette/system anchors/hover/zoom where practical. Do not invent physiology to fill unsupported native categories.

### 4. Exact drill-down

Selected systems/regions may expose bars/numbers for authoritative values, especially for development calibration. Overview/gameplay must not become a permanent body-meter dashboard.

### 5. Preserve stock Cyberware integrity

Switching to Cyberware must restore normal equipment slots/interactions and never duplicate/lose/unequip items.

## Deliverables

Before reporting ready to merge, provide:

1. implementation of the corrected hierarchy and runtime access;
2. updated tests for navigation, persistent nodes, drill-down, and state availability contracts;
3. removal/retirement of superseded active overlay/prototype paths where replacement is authoritative;
4. documentation of any native seam discovered/changed;
5. direct-game probe request only where tracked game reference is insufficient;
6. PR against `main` with CI status and explicit package/dependency requirements for Lane A.

## Acceptance criteria

Ready-to-merge means source/contracts establish all of the following:

- outer and inner navigation consistently present Biology as parent destination;
- selector no longer relies on arbitrary overlay placement that collides with top navigation;
- normal hub entry opens Biology mode;
- authoritative body state becomes available in ordinary valid sessions;
- modeled nodes remain visible while healthy;
- overview uses terse telemetry;
- exact numbers/bars appear only in deliberate drill-down;
- Cyberware submode preserves stock equipment behavior;
- save/reload/time progression share one body authority;
- no second duplicate inventory/body state is introduced;
- lane tests pass.

Final visual placement still requires attended testing after merge.

## Coordination

Parallel lanes:

- `agent/redmod-foundation`: package/dependencies. Report requirements; do not duplicate its work.
- `agent/presentation-hud-nameplates`: first-person HUD/nameplates/settings presentation. Do not edit those visual surfaces unless required by a shared API contract, in which case coordinate first.

## Local evidence

Use `reference/cyberpunk/` and current source first. If a native controller/widget/lifecycle fact is uncertain, ask the user for one targeted read-only PowerShell probe and have large output written to a file.
