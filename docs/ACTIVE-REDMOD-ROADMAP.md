# Biology — active REDmod follow-up roadmap

Status: **ACTIVE FOLLOW-UP LEDGER**  
Last updated: **2026-09-15**

This file tracks work that is active **after** the first integrated REDmod-first attended run. It is intentionally not a permanent archive of every prior migration lane.

For historical pre-REDmod evidence, use `PRE-REDMOD-LIVE-BASELINE-2026-09-15.md`. For exact integrated attended evidence, use `docs/test-runs/`.

## Read before working

1. `AGENTS.md`
2. `AGREED-GOALS.md`
3. root `ROADMAP.md`
4. this file
5. the focused architecture doc for the subsystem
6. `docs/BIOLOGY-REDMOD-MIGRATION.md`
7. `docs/PARALLEL-AGENT-WORKFLOW.md`
8. `docs/INTEGRATION-ORCHESTRATOR.md`
9. `docs/LOCAL-OPERATOR-COMMANDS.md` before requesting local commands
10. the relevant GitHub issue and all current comments

Do not use merged worker handoffs or dated baseline records to infer a current branch assignment.

---

# 1. Accepted foundation from the first integrated REDmod milestone

The exact candidate built from `8cf045664b5e4d8b4b014edfc98bf2f8eb270ba5` produced:

- exact compile success;
- a release-shaped Biology package;
- official package identity `mods/Biology`;
- successful installation into a clean Cyberpunk 2077 2.31 game;
- successful official REDmod recognition of `Biology`;
- successful five-stage REDmod deployment after explicit-root handling was repaired and made fail-closed.

Artifact:

`biology-integrated-20260915-061136-8cf045664b5e.zip`

SHA-256:

`42BACC73173EB95D84F3278593CD06DDAF665AA714F4C692DB03D553B91557CC`

The original package/dependency/UI/presentation worker branches are merged history. They are not active work lanes.

---

# 2. Active attended follow-ups

## UI-ATTENDED — Issue #39

Branch: `agent/biology-ui-attended-followup`

### Live failures

- Biology overview/detail still behaves like a parallel custom overlay instead of fully reusing the native Cyberware interaction shell.
- Overview labels remain visible during detail zoom.
- `BIOLOGY | CYBERWARE` is too small and easy to miss.
- Biology detail has no normal Back/Cancel route to Biology overview; the user had to close the whole menu.
- Switching directly from Biology detail to Cyberware can leave Biology body/skeleton presentation stuck.
- Native Cyberware already blocks the inverse switch while drilled down, proving the preferred state rule.

### Required design

Overview:

- Biology/Cyberware mode switching allowed.

Detail/drill-down:

- mode switching unavailable;
- native Back/Cancel returns to the current mode overview;
- the mode selector becomes available again only after returning to overview.

Biology detail should reuse the native Cyberware structural grammar where possible:

- selected-region zoom/focus;
- top body-part navigation strip and left/right cycling;
- native content/item area;
- native back-stack/input behavior;
- contextual items/actions routed through authoritative inventory/treatment systems.

Do not create a second inventory or manually mutate item counts.

### Acceptance

- overview → detail → Back → overview works repeatedly;
- overview-only labels are absent from detail;
- switching modes is blocked while either Biology or Cyberware is drilled down;
- no Biology visual state leaks into Cyberware;
- selector is legible/discoverable at attended UI scale;
- stock Cyberware equip/upgrade/vendor/capacity behavior remains intact.

Runtime-authority failure is owned by #41, not #39.

---

## RUNTIME-ATTENDED — Issue #41

Branch: `agent/body-runtime-attended-followup`

### Live failure

The Biology overview visibly reports:

`[ BIOLOGY ERROR ] BODY RUNTIME SYSTEM MISSING`

This is a blocking authority/lifecycle failure, not a cosmetic string problem.

### Questions to resolve

Determine whether the authoritative body runtime is:

- not registered;
- registered but not initialized;
- initialized but inaccessible from the live menu/GameInstance context;
- temporarily unavailable during a lifecycle window;
- disabled by an activation/settings gate;
- absent from the packaged runtime route;
- reached through a stale/incorrect controller path;
- or failing for another evidenced reason.

### Rules

- no fake `STABLE` fallback;
- no UI-owned duplicate body state;
- no second body runtime for menus;
- diagnostics may distinguish failure classes but must not hide missing authority;
- save/reload/time progression must consume the same canonical body state.

### Acceptance

- ordinary valid session exposes the body runtime reliably;
- menu open/close does not lose it;
- save/reload retains/reconstructs expected state;
- wait/sleep/time skip update through one authority;
- live UI reads real state;
- true compatibility failure remains obvious.

---

## PRES-ATTENDED — Issue #40

Branch: `agent/presentation-attended-followup`

### Corrected live evidence

With E3 presentation **ON**:

- ordinary gameplay still looks overwhelmingly like the modern retail HUD;
- the quest/objective tracker remains modern;
- minimap, weapon/ammo, prompts and most framing remain modern;
- looking directly at a random civilian shows no E3 ambient nameplate;
- police/combatants receive only a narrow red strip, not the complete intended identity treatment.

With E3 **OFF**, that police red strip is absent.

The modern scanner/quickhack view remains intact and is a **PASS/preserve requirement**.

### Project E3 reference archaeology

`config/realpass-e3.json` is the durable component inventory for the local-only Project E3 reference. The actual `ReferenceMods/` payload is intentionally gitignored and must not be redistributed.

The inventory demonstrates that the original presentation touched materially more than a biomonitor/nameplate hook, including:

- base HUD controller;
- quest tracker;
- activity log;
- dialogue/interactions;
- minimap/quest mappins;
- compass;
- weapon roster/ammo;
- crosshair/focus;
- D-pad hints;
- health/status presentation;
- NPC nameplate visuals/behavior.

The worker must map those responsibilities to current Cyberpunk 2.31 native seams and Biology-owned implementation, while documenting which areas intentionally remain modern/native.

### Acceptance

Matched attended captures must include:

- ordinary gameplay E3 ON/OFF;
- quest/objective HUD ON/OFF;
- random civilian ordinary focus E3 ON before scanner;
- police/combatant ordinary focus E3 ON;
- same relevant NPC after scan knowledge is acquired where applicable;
- modern scanner/quickhack E3 ON.

E3 ON must be recognizable without reading settings. A tiny red widget, a police strip, or health-bar suppression alone is not acceptance.

---

## RELEASE-UX — Issue #44

Branch: `agent/player-uninstall-vanilla-toggle`  
Draft PR: `#45`

### Product states

1. **Biology ON** — REDlauncher `Enable mods` ON; full Biology behavior.
2. **Vanilla-play mode** — Biology installed, REDlauncher `Enable mods` OFF; Biology behavior inactive.
3. **Fully removed** — self-contained `Uninstall Biology.exe` safely removes manifest-proven Biology-owned files.

### Hard-uninstall safety

The uninstaller must:

- work without PowerShell/Git/Vortex/source checkout;
- verify the installed ownership manifest and file hashes;
- never recursively delete shared roots;
- preserve saves;
- preserve settings by default unless the user explicitly chooses otherwise;
- leave changed/shared/ambiguous files in place and report them;
- refresh REDmod state appropriately after removal;
- report success/partial success clearly.

A full Steam uninstall/reinstall becomes exceptional clean-room recovery, not normal Biology removal.

---

# 3. Integration rules

The active branches above may work in parallel where file ownership allows, but the parent integration thread decides merge order.

Particular overlap risks:

- #39 and #41 both originate near Biology menu/runtime boundaries; #39 owns shell/state-machine presentation, #41 owns runtime authority/lifecycle.
- #40 may touch shared settings/activation gates; coordinate with #44 rather than duplicating whole-mod enable semantics.
- #44 may change package/install/activation contracts; it must not absorb UI/runtime/presentation feature redesign.

Do not ask the user to install each branch separately. Merge compatible work into canonical `main`, then build one release-shaped candidate.

---

# 4. Local evidence policy

Before asking the user to run PowerShell/CMD, read `docs/LOCAL-OPERATOR-COMMANDS.md`.

Rules:

- use repository-owned entrypoints rather than reconstructing their internals in chat;
- do not assume a persistent repo checkout path;
- attended workspaces are disposable;
- the known game path may be used where the catalog allows it;
- long-running commands need durable progress output;
- user-run evidence tools should write a plain-text report file when output is materially useful for an agent, and the user should return that file rather than copy/pasting large console transcripts;
- a fast post-reinstall sanity check is not equivalent to whole-game baseline verification.

---

# 5. Combined next-milestone acceptance

After the parent integrates the selected follow-ups, the next attended candidate should establish at minimum:

- official Biology package recognition/deploy still works;
- body runtime authority is available in live Biology;
- Biology overview/detail/back navigation is stable;
- mode switching is allowed only at the shared overview level;
- stock Cyberware remains functional;
- E3 ON clearly changes the ordinary first-person presentation;
- ambient civilian and police/combatant nameplates behave as intended;
- modern scanner/quickhack remains native/current;
- E3 OFF cleanly removes only E3-specific presentation;
- save/reload/time progression remains correct;
- if #44 is included, launcher OFF yields Biology-inactive vanilla-play behavior and hard uninstall removes Biology without a Steam reinstall.

Live acceptance must be tied to the exact canonical `main` SHA and exact artifact. CI/source contracts cannot substitute for attended behavior.

---

# 6. Historical migration IDs

Older identifiers such as `PKG-*`, `DEP-*`, `NAV-*`, `BIO-*`, `STATE-*`, `PRES-*`, and `SET-*` appear in historical docs/issues/test records. They remain useful when tracing why a feature exists, but they are **not automatically active work merely because their text remains in history**.

Current work is defined by root `ROADMAP.md`, this ledger, and current GitHub issues/PRs.
