# Biology — active REDmod refactor roadmap

Status: **ACTIVE WORK PLAN**

This is the current execution roadmap for the Biology product migration. It converts the attended pre-REDmod evidence in `PRE-REDMOD-LIVE-BASELINE-2026-09-15.md` into concrete work items, ownership lanes, merge order, and acceptance gates.

This file is intentionally more operational than `BIOLOGY-REDMOD-MIGRATION.md`. The migration document explains the architecture and why. This roadmap says **what to do next**.

## Read before working

Every agent on this refactor must read, in this order:

1. `AGENTS.md`
2. `AGREED-GOALS.md`
3. `docs/PRE-REDMOD-LIVE-BASELINE-2026-09-15.md`
4. `docs/BIOLOGY-REDMOD-MIGRATION.md`
5. this file
6. the focused architecture document for the lane (`BIOLOGY-UI.md`, `E3-PRESENTATION.md`, etc.)
7. `docs/PARALLEL-AGENT-WORKFLOW.md`

Do not infer current product intent from historical `RealPass`, Dark Future, or Project E3 implementations before reading those files.

---

# 1. Current milestone state

The tested pre-REDmod candidate at revision `ec8ba06451c3cbacabfad24f1479e1537147d0c9`:

- exact-compiled;
- packaged from a clean clone;
- installed into a freshly baselined Cyberpunk 2.31 directory;
- launched successfully;
- changed the outer hub label to `BIOLOGY`;
- hid the ordinary player health bar;
- exposed the current RealPass Mod Settings page;
- **did not** deliver the intended E3-style HUD;
- **did not** deliver E3-style NPC nameplates;
- **did not** make Biology the true parent body mode;
- **did not** provide live body state to the Biology overlay;
- **did not** consistently rename inner Cyberware navigation to Biology;
- displayed a visually colliding/faint `BIOLOGY | CYBERWARE` selector;
- still exposed obsolete `REALPASS` branding in settings.

Those failures are migration acceptance requirements, not reasons to polish the old overlay architecture indefinitely.

---

# 2. Parallel work lanes

The next phase should use up to three branches in parallel.

## Lane A — REDmod foundation, package shape, dependency audit

Proposed branch: `agent/redmod-foundation`

Owns:

- official `mods/Biology` package skeleton;
- REDmod identity/deploy/enable/load-order proof;
- machine-readable classification of current runtime/package components;
- dependency justification/removal map;
- final install/uninstall ownership model;
- REDmod overlap/precedence evidence;
- migration of clearly REDMOD-NATIVE resources where safe;
- package/build tooling necessary for a release-shaped Biology artifact.

Must not redesign:

- body model equations;
- Biology UI layout/content semantics;
- E3 HUD/nameplate visual design;
- combat/injury calibration.

Primary issue IDs:

- `PKG-01` through `PKG-07`
- `DEP-01` through `DEP-06`
- `SEAM-01` classification coordination

## Lane B — Biology body shell, runtime availability, navigation

Proposed branch: `agent/biology-ui-runtime`

Owns:

- making Biology the real parent mode of the shared body/anatomy fullscreen;
- consistent player-facing `BIOLOGY` navigation identity;
- correct non-overlapping `BIOLOGY | CYBERWARE` mode switch;
- authoritative body-state availability/lifecycle in live game;
- persistent Biology nodes while healthy;
- drill-down exact values/bars;
- terse telemetry wording;
- preservation of stock Cyberware behavior inside Cyberware submode;
- contextual Biology actions only where backed by authoritative transactions.

Must not redesign:

- REDmod package/dependency architecture beyond requirements reported to Lane A;
- E3 HUD/nameplate styling;
- body equations unless a proven lifecycle/API defect requires a narrowly scoped fix.

Primary issue IDs:

- `NAV-01`, `NAV-02`
- `BIO-01` through `BIO-08`
- `STATE-01` through `STATE-04`

## Lane C — first-person HUD, NPC nameplates, presentation settings

Proposed branch: `agent/presentation-hud-nameplates`

Owns:

- Biology-owned E3-inspired first-person HUD recreation;
- Biology-owned E3-inspired NPC nameplates;
- modern scanner/quickhack preservation;
- presentation-toggle semantics and visible proof;
- player-facing settings/product naming for presentation;
- separation of Biology-wide barless-health policy from optional E3 skin behavior;
- removal of Project E3 runtime dependence/identity.

Must not redesign:

- body simulation equations;
- Biology body-menu shell;
- REDmod package architecture except reporting actual dependency needs to Lane A.

Primary issue IDs:

- `PRES-01` through `PRES-08`
- `SET-01` through `SET-05`

---

# 3. Issue ledger

## Packaging / REDmod foundation

### PKG-01 — create the minimal official Biology REDmod identity

Target:

```text
Cyberpunk 2077/
└── mods/
    └── Biology/
        └── info.json
```

Add only REDmod-supported subtrees that actual migrated behavior needs.

Acceptance:

- official tooling recognizes/deploys the mod;
- enable/disable state is testable;
- package can exist with no unrelated legacy payload;
- package identity is `Biology`, not `RealPass`.

### PKG-02 — make the build produce a REDmod-first release-shaped artifact

The canonical attended build path must eventually produce the same install shape intended for players, not an accumulated developer tree.

Acceptance:

- fresh clone can build it;
- game is not modified during build;
- generated package manifest owns every file;
- artifact clearly separates project-original Biology files from unavoidable external framework payload.

### PKG-03 — official deployment / Steam launch workflow

Determine exact supported steps for deploy/enable/launch with current REDmod.

Acceptance:

- no Biology-specific launcher/background helper;
- player can use supported Steam/CDPR flow;
- documented behavior survives reboot/relaunch;
- failure to enable mods is obvious.

### PKG-04 — uninstall/disable cleanliness

Acceptance:

- Biology-owned paths are obvious;
- removing/disabling package does not require historical rollback receipts;
- iteration reset can return the game to recorded vanilla baseline or fail closed with exact residue.

### PKG-05 — overlap/load-order proof

Acceptance:

- test at least one deliberately conflicting REDmod fixture or safe local test package;
- record whether Biology wins/loses based on actual REDmod precedence rather than assumptions;
- do not claim dominance over redscript/CET/native hooks outside REDmod's control.

### PKG-06 — retire superseded root-package tooling only after replacement works

Do not delete the current build path before the REDmod path can compile/package/deploy an integrated candidate.

Acceptance:

- replacement has equivalent or better reproducibility and baseline auditing;
- old path is marked retired and removed from active instructions.

### PKG-07 — preserve clean-room discipline during migration

Acceptance:

- ordinary iteration can reuse a baseline-verified game install;
- milestone structural tests still use clean reinstall when required;
- fresh local repo remains the default for attended builds.

---

# 4. Dependency and seam audit

### DEP-01 — audit Mod Settings

Question: can the tiny settings surface move into Biology and eliminate Mod Settings plus transitive dependencies?

Acceptance:

- retain only with feature-specific justification;
- otherwise remove provider coupling and port controls into Biology-owned UI/config.

### DEP-02 — audit ArchiveXL

Acceptance:

- keep only if an actual final Biology feature requires it;
- being transitively required by a provider that itself can be removed is not sufficient.

### DEP-03 — audit RED4ext

Acceptance:

- keep only if a final native extension/framework consumer remains after REDmod/redscript migration;
- isolate version-sensitive usage.

### DEP-04 — audit redscript

Redscript is not automatically rejected. For each hook, compare narrow wrapper/additive behavior against REDmod whole-file replacement.

Acceptance:

- every retained hook has a written `REDSCRIPT-BETTER` rationale;
- native seam is explicit and validated against 2.31;
- no wrapper remains merely because the old build used one.

### DEP-05 — no source-mod runtime ownership

Acceptance:

- no Dark Future or Project E3 scripts/assets execute as dependencies;
- copied/reference material remains provenance/research only.

### DEP-06 — machine-readable dependency graph

Create/update a manifest listing:

- dependency/component;
- consumer feature(s);
- required/optional/transitional;
- routing layer;
- planned removal/migration status;
- license/provenance notes.

---

# 5. Biology UI and runtime issues

### NAV-01 — consistent Biology destination identity

Current evidence: outer hub says `BIOLOGY`; inner top tab says `CYBERWARE`.

Acceptance:

- outer hub = `BIOLOGY`;
- inner standard navigation = `BIOLOGY`;
- adjacent inventory/menu navigation uses `BIOLOGY` for the same destination;
- Cyberware wording appears as the internal submode, not the parent destination.

### NAV-02 — stable Biology/Cyberware selector

Acceptance:

- no overlap with top navigation;
- no faint duplicated labels;
- keyboard/controller/mouse focus works;
- state is obvious;
- responsive at supported resolution/UI scale.

### BIO-01 — Biology truly owns the shared body shell

Acceptance:

- ordinary hub entry defaults to Biology mode;
- Biology mode replaces/hides cyberware equipment cards with body-system content;
- Cyberware remains accessible and restores stock equipment interactions.

### BIO-02 — persistent Biology nodes

Acceptance:

- modeled nodes remain present even when healthy;
- quiet state never collapses into only `STABLE` text;
- selecting a node uses native hover/zoom language where possible.

### BIO-03 — exact drill-down values

Acceptance:

- exact authoritative numbers/bars appear only after deliberate selection;
- no duplicate state variables;
- useful development metrics are visible for calibration.

### BIO-04 — terse overview telemetry

Acceptance:

- normal overview = `STABLE`;
- abnormal state uses compact tokens;
- no prose such as `Body state is unavailable.` unless a true diagnostics error is being surfaced separately.

### BIO-05 — contextual actions use real inventory/treatment transactions

Acceptance:

- `EAT…`, `DRINK…`, dress/support/care actions use authoritative item/care paths;
- no Biology-owned duplicate inventory.

### BIO-06 — stock Cyberware submode integrity

Acceptance:

- equip/upgrade/capacity/vendor behavior remains correct;
- switching modes cannot duplicate/lose/unequip items.

### BIO-07 — contextual ripperdoc behavior

Acceptance:

- normal hub defaults Biology;
- ripperdoc/vendor context may sensibly default Cyberware if needed;
- parent identity remains Biology.

### BIO-08 — no old overlay architecture remains active after replacement

Acceptance:

- superseded popup/overlay/prototype code removed from production route;
- only one active Biology body UI authority.

---

# 6. Body-state lifecycle issues

### STATE-01 — resolve `Body state is unavailable.`

This is a blocking functional issue for UI acceptance.

Investigate:

- ScriptableSystem availability timing;
- save/session initialization;
- release/acceptance gating;
- global enable setting interaction;
- menu controller game-instance access;
- persistence/load lifecycle;
- forecast/runtime object ownership.

Acceptance:

- ordinary valid save/session exposes body state reliably;
- menu can open/close repeatedly without losing it.

### STATE-02 — save/reload persistence

Acceptance:

- body state exists before save;
- reload reconstructs/retains expected state;
- UI reads the same authoritative state after reload.

### STATE-03 — time progression consistency

Acceptance:

- waiting/sleeping/time skip updates body once through shared authority;
- Biology detail values reflect resulting state;
- no stale view-model cache.

### STATE-04 — fail-obvious compatibility behavior

If a supported-game native seam breaks, do not silently present empty body data.

Acceptance:

- compatibility failure is distinguishable from a healthy body;
- normal player UI stays concise;
- diagnostics/logging identifies the failed seam.

---

# 7. E3-inspired presentation issues

### PRES-01 — full first-person E3 visual language is absent

Current screenshot is substantially modern/vanilla in ordinary gameplay.

Acceptance:

- E3 visuals ON produces a clearly recognizable red E3-inspired presentation in ordinary gameplay;
- result is Biology-owned, not Project E3 runtime content.

### PRES-02 — NPC nameplates are absent

Acceptance:

- intended NPC focus/nameplate states use Biology-owned E3-inspired presentation;
- scanner/quickhack remains modern/native.

### PRES-03 — health-bar suppression is not an E3 completion metric

Current build hides the health bar even when E3 visuals are toggled off.

Canonical interpretation:

- barless actor-health remains Biology-wide while Biology is enabled;
- E3 toggle controls E3-specific styling/nameplates;
- therefore the toggle must demonstrate other obvious visible changes.

If the project owner later explicitly changes this rule, update `AGREED-GOALS.md` and `E3-PRESENTATION.md` together.

### PRES-04 — visible ON/OFF parity test

Acceptance:

Capture matched screenshots from the same location/state:

- E3 ON;
- E3 OFF.

A reviewer should be able to identify which is which without reading settings.

### PRES-05 — modern scanner/quickhack preservation

Acceptance:

- scanner visuals/interaction remain modern Cyberpunk;
- no old E3 scanner recreation sneaks in with HUD work.

### PRES-06 — quest/navigation/interaction/crosshair treatment

Audit which visible components materially define the desired E3 look and implement only those intentionally owned by Biology.

Acceptance:

- coherent visual language;
- no arbitrary partial recolor that looks broken or inconsistent.

### PRES-07 — presentation feedback remains subordinate to simulation

Biology injury/need cues may use the HUD language, but do not recreate a permanent body-meter wall.

### PRES-08 — remove player-facing Project E3 identity

Use attribution/provenance in docs/licenses as appropriate, but final settings/UI should describe the feature as Biology presentation rather than an installed Project E3 dependency.

---

# 8. Settings and product identity

### SET-01 — replace `REALPASS` player-facing branding

Acceptance:

- shipped settings/product labels say `BIOLOGY` / `Biology`;
- obsolete RealPass name remains only in transitional internals where renaming is risky.

### SET-02 — replace `Enable RealPass`

If the runtime master remains:

- label becomes `Enable Biology`;
- disable semantics are tested explicitly.

If the REDmod enable/disable boundary makes an in-game master redundant, document and remove it rather than preserving a historical toggle.

### SET-03 — clarify E3 preference label

The preference should describe the player-facing outcome without implying an external runtime dependency.

Candidate direction: `E3-inspired HUD` or `2018-style HUD`, subject to final product wording.

### SET-04 — provider-neutral settings ownership

Acceptance:

- settings semantics exist independently from Mod Settings provider;
- provider can be removed/replaced without changing simulation authority.

### SET-05 — master-disable yield-to-vanilla test

If retained, turning Biology off must have documented session/reload semantics and yield wrapped presentation/gameplay surfaces to vanilla as completely as technically safe.

---

# 9. Merge order

The lanes can work concurrently, but integration should normally proceed:

1. **Lane A foundational package/dependency schema/tooling** that other lanes do not need to guess around;
2. **Lane B and Lane C implementation PRs** after rebasing/merging current main as necessary;
3. any final Lane A package assembly changes that consume the now-known runtime output;
4. combined CI on `main`;
5. build one release-shaped candidate from a fresh clone;
6. attended integrated milestone test.

If Lane B/C discovers a hard dependency requirement, report it to Lane A rather than independently adding framework/package plumbing.

---

# 10. Combined milestone acceptance

Do not call the REDmod-first refactor ready for broad testing until the integrated `main` candidate demonstrates:

- official Biology package identity;
- build/deploy from fresh clone;
- known dependency graph;
- `BIOLOGY` outer and inner navigation;
- non-overlapping Biology/Cyberware selector;
- live body state available;
- persistent inspectable Biology nodes;
- exact drill-down metrics;
- Cyberware submode preserved;
- E3-inspired HUD visibly present when enabled;
- E3-inspired NPC nameplates present when enabled;
- modern scanner preserved;
- settings under Biology identity;
- E3 ON/OFF visibly distinguishable;
- save/reload body persistence;
- no Project E3/Dark Future executing runtime;
- baseline-auditable install/remove state.

The next screenshot set should be compared directly against `PRE-REDMOD-LIVE-BASELINE-2026-09-15.md` so the refactor can prove which failures were fixed and which remain.
