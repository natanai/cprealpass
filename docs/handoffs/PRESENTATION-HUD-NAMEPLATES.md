# Handoff — HUD / NPC nameplates / presentation-settings lane

Use this as the source-of-truth handoff for a new agent thread.

## Goal

Implement the **Biology-owned E3-inspired presentation layer** that the current clean-room build does not visibly deliver: first-person HUD styling, NPC nameplates, and clear ON/OFF presentation semantics, while preserving the modern scanner/quickhack experience and the Biology-wide simulation model.

## Repository / branch

- Repository: `natanai/cprealpass`
- Create branch: `agent/presentation-hud-nameplates`
- Base: current canonical `main` **including** the pre-REDmod live-baseline/roadmap documentation. Record the exact starting SHA in the PR.
- Do not work directly on `main`.

## Read first

1. `AGENTS.md`
2. `AGREED-GOALS.md`
3. `docs/PRE-REDMOD-LIVE-BASELINE-2026-09-15.md`
4. `docs/ACTIVE-REDMOD-ROADMAP.md`
5. `docs/E3-PRESENTATION.md`
6. `docs/BIOLOGY-REDMOD-MIGRATION.md`
7. `docs/SETTINGS-ARCHITECTURE.md`
8. `docs/PARALLEL-AGENT-WORKFLOW.md`
9. current HUD/nameplate/settings source and tests

## Attended evidence you must address

The clean-room pre-refactor build at `ec8ba06451c3cbacabfad24f1479e1537147d0c9` showed:

- ordinary first-person HUD still looked substantially modern/vanilla rather than the intended red 2018/E3-inspired style;
- E3-inspired NPC nameplates were not active;
- the ordinary player health bar was hidden, proving some presentation code was executing;
- turning `E3 first-person HUD visuals` OFF did not restore the health bar;
- Mod Settings rendered `REALPASS`, `Enable RealPass`, and `E3 first-person HUD visuals`.

Important interpretation: the current canonical Biology goal keeps actor-health bars suppressed while Biology is enabled, independent of the optional E3 skin. Therefore the missing health bar is **not proof the E3 layer works**, and E3 OFF is not currently required to restore it. The real failure is that the E3 toggle has no clearly demonstrated visible E3-specific effect because the intended HUD/nameplate styling is absent.

## Owned scope

You own:

- `PRES-01`..`PRES-08`;
- `SET-01`..`SET-05` insofar as they concern presentation/player-facing settings identity;
- Biology-owned E3-inspired first-person HUD styling;
- Biology-owned E3-inspired NPC nameplates;
- explicit exclusion/preservation of modern scanner and quickhack presentation;
- visible/functional E3 preference semantics;
- player-facing removal of obsolete `REALPASS`/Project E3 dependency identity where safe;
- tests/contracts proving presentation ownership and toggle behavior.

## Non-goals / boundaries

Do not own:

- Biology body-menu shell/navigation/body-runtime availability (`agent/biology-ui-runtime`);
- REDmod package/dependency plumbing (`agent/redmod-foundation`);
- simulation equations or combat balance;
- replacement of the modern scanner with an old E3 scanner;
- importing Project E3 runtime scripts/archive as a dependency.

If you discover a required framework/package feature, report the concrete consumer to the REDmod foundation lane rather than adding package dependencies independently.

## Required product semantics

### Biology-wide barless health vs optional E3 styling

Treat these as separate concepts:

- **Biology enabled:** canonical barless actor-health presentation remains in force unless the project owner explicitly changes that goal.
- **E3 visuals ON:** the recognizable Biology-owned E3-inspired HUD/nameplate skin is active.
- **E3 visuals OFF:** E3-specific skin/nameplates yield to the non-E3 Biology/vanilla presentation, but Biology's simulation and barless-health rule remain unchanged.

Do not use health-bar suppression as the only toggle test.

### Modern scanner is locked

Scanner/quickhack panels and interactions remain modern native Cyberpunk. Recreate E3 visual language around ordinary gameplay without reverting the scanner.

### Biology owns the result

Reference Project E3 for visual behavior/provenance, but final executing code/assets must be Biology-owned and redistribution-safe.

## Investigation / implementation priorities

### 1. Produce one unmistakable first-person visual slice

Start with a narrow HUD subset that makes E3 ON/OFF visibly different in attended screenshots. Prefer a stable native shell/resource seam over a sprawling copied implementation.

### 2. Restore E3-inspired NPC nameplates

Identify the native nameplate/focus controllers currently used by 2.31 and implement Biology-owned styling without disturbing identity/permission/scanner authority.

### 3. Audit every current HUD hook

For each hook/resource classify:

- genuine E3 visual consumer;
- Biology-wide barless consumer;
- modern-scanner exclusion;
- dead/transitional code.

Do not conflate these categories.

### 4. Clarify settings surface

Current player-facing labels are obsolete/transitional. The final feature should be Biology-branded and provider-neutral. Coordinate dependency/provider decisions with Lane A.

### 5. Matched screenshot contract

Design ON/OFF behavior so one attended test can capture the same location/NPC with E3 ON and OFF and demonstrate obvious visual difference.

## Deliverables

Before reporting ready to merge, provide:

1. Biology-owned E3-inspired HUD implementation for the agreed visible slice(s);
2. Biology-owned E3-inspired NPC nameplate implementation;
3. tests/contracts separating Biology-wide barless health from optional E3 skin behavior;
4. modern scanner/quickhack exclusion checks;
5. player-facing Biology naming for the presentation setting where safe;
6. dependency requirements/removal opportunities reported to Lane A;
7. no Project E3 executing runtime content;
8. PR against `main` with CI status and explicit attended screenshot checklist.

## Acceptance criteria

Ready-to-merge means:

- E3 ON and OFF have intentionally different visible first-person presentation in source/contracts;
- intended NPC nameplate states have Biology-owned styling;
- modern scanner/quickhack remains native;
- health-bar suppression is not incorrectly used as proof of E3 completion;
- Project E3 does not execute as a dependency;
- player-facing presentation identity no longer implies an installed external E3 mod;
- obsolete RealPass naming is removed from surfaces this lane owns where safe;
- lane tests pass.

Final visual fidelity requires attended screenshots after merge.

## Coordination

Parallel lanes:

- `agent/redmod-foundation` owns package/dependency decisions.
- `agent/biology-ui-runtime` owns Biology body-screen/navigation/runtime availability.

Avoid shared edits to canonical docs unless necessary; report contract changes in the PR if another integration owner should apply them.

## Local evidence

Use `reference/cyberpunk/` and existing source/history first. If a native controller/resource path cannot be established confidently, ask the user for one targeted read-only PowerShell probe and save large results to a file.
