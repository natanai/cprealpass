# AUTONOMOUS FINAL PRODUCT COMPLETION — Owner-authorized sole-agent run

Owner directive: this run intentionally **supersedes the normal parent/worker orchestration model**.  
There is one autonomous local agent. Do not create workers. Do not wait for a parent. Do not stop to ask the owner to test. Make engineering decisions yourself from the repository, installed Cyberpunk 2077 2.31 files, private reference mods, current modding tools, exact compiler, and automated/local evidence.

Tracking issue: **#152 — Autonomous product completion — finish Biology end-to-end for public release**  
Dedicated branch: **`autonomous/final-product-completion`**  
Starting canonical main: **`d2a4c8f1c166bbfd0227451cbf32e3793f10ea72`**

This is not a narrow bugfix lane. The goal is to leave **Biology functionally complete, release-shaped, safely installable/uninstallable, merged, and installed on the owner's machine ready to play**.

---

## 1. Product definition

Biology is a self-contained realism/biology overhaul for Cyberpunk 2077 + Phantom Liberty, targeting current supported game version **2.31**.

The finished player experience should be simple:

1. one obvious Biology download/release;
2. no manual dependency hunting;
3. install is as close to **game-root drag-and-drop** as can be made genuinely safe;
4. use the normal Steam/REDlauncher launch path;
5. REDlauncher **Enable mods OFF** cleanly disables Biology behavior and yields native/vanilla behavior without requiring uninstall;
6. REDlauncher **Enable mods ON** restores Biology;
7. a single obvious **`Uninstall Biology.exe`** safely removes Biology-owned payload;
8. uninstall preserves saves and generic/shared modding infrastructure that is not exclusively Biology-owned;
9. reinstall and upgrade work cleanly;
10. the final installed game is left with the newest completed Biology build installed and ready for the owner.

Do not sacrifice collision safety merely to claim “drag-and-drop.” If an unavoidable shared global component makes blind Explorer overwrite unsafe, solve the packaging architecture rather than silently overwriting foreign/newer files. The final UX must still be one download and obvious/simple for a normal player.

The authoritative packaging direction is REDmod-first, centered on:

`Cyberpunk 2077\mods\Biology`

Narrow Biology-owned REDscript/native wrapper seams are allowed where they are more patch-resilient than whole-file replacement.

---

## 2. Sole-agent authority for this run

For this session only, ignore the repository instructions that require parent/worker conversation routing, worker handoffs, parent merge approval, or waiting for attended owner testing.

Those process rules were designed around cloud-chat limitations and no longer fit this local autonomous run.

You are the sole:
- investigator;
- implementer;
- integrator;
- release engineer;
- test engineer;
- packaging engineer;
- documentation maintainer.

Use **one branch**:

`autonomous/final-product-completion`

Use **one main tracking issue**:

`#152`

Open **one final PR** to `main`.

You MAY merge your own final PR after all automated/local completion gates in this document pass and GitHub CI is green.

Do not spawn sub-workers or create a parent hierarchy.

Do not sit idle waiting for human validation. When something would previously have triggered an attended test:
- exhaust direct installed-game evidence;
- inspect private reference implementations;
- exact-compile;
- add bounded automated diagnostics/tests;
- perform safe automated smoke tests where possible;
- make the most evidence-backed implementation decision;
- continue finishing the rest of the product.

Never claim a specific live behavior passed unless you actually observed/proved it. If a genuinely irreducible human-only visual/gameplay uncertainty remains at the end, document it precisely, but do not use it as an excuse to stop work on everything else.

---

## 3. Local machine authority and known paths

Installed Cyberpunk 2077:

`C:\Games\Steam\steamapps\common\Cyberpunk 2077`

Private reference library:

`C:\Games\Cyberpunk-ReferenceMods`

Reusable reference tooling:

`C:\Games\Cyberpunk-ReferenceMods\_tooling`

Known private references include Project E3 HUD material, Cyberware-EX, Ripperdoc Vendor UI Enhancements, Codeware, and other Ripperdoc/Cyberware examples collected by the owner.

Treat private references as **read-only engineering evidence**.

Never:
- install a reference mod merely to inspect it;
- copy Project E3 or another third-party implementation into Biology;
- commit private third-party source/payload;
- redistribute proprietary Cyberpunk files;
- turn a reference dependency into a Biology runtime dependency without a new independently justified product need.

Derived architecture knowledge, widget/controller names, hashes, resource paths, and Biology-owned seam conclusions may be documented in Git.

---

## 4. Repository startup

Do not assume the current working directory is correct.

If necessary:
1. locate an existing Git checkout whose remote is `natanai/cprealpass`;
2. if none exists, clone it into a safe owner workspace such as `C:\Games\cprealpass-autonomous`;
3. fetch all refs;
4. resolve exact `origin/main`;
5. check out `autonomous/final-product-completion`;
6. reconcile with latest `origin/main` immediately;
7. record exact starting HEAD and main SHA in issue #152.

Read, in this order:

- `AGREED-GOALS.md`
- `README.md`
- `ROADMAP.md`
- `AGENTS.md` — use its technical/evidence/safety guidance, but the owner override in this handoff supersedes its parent/worker routing requirements for this run
- `docs/BIOLOGY-REDMOD-MIGRATION.md`
- `docs/RELEASE-ARCHITECTURE.md`
- `docs/PLAYER-DISABLE-UNINSTALL.md`
- `docs/PATCH-RESILIENCE.md`
- `docs/BIOLOGY-UI.md`
- `docs/E3-PRESENTATION.md`
- `docs/SETTINGS-ARCHITECTURE.md`
- `docs/LOCAL-OPERATOR-COMMANDS.md`
- `manifest/distribution.json`
- `manifest/install-contract.json`
- `manifest/redmod-install-contract.json`
- `manifest/feature-inventory.json`
- `manifest/dependency-graph.json`
- `manifest/runtime-modules.json`
- current open GitHub issues and latest comments.

Do not treat stale dated “current milestone” prose in README/old handoffs as authoritative when current source/evidence contradicts it.

---

## 5. Build a completion matrix before broad implementation

Create a temporary or durable engineering matrix mapping every canonical product goal to:

- implementation owner/source file(s);
- native authority/seam;
- automated test coverage;
- exact-compile coverage;
- packaging/activation impact;
- persistence impact;
- current status: PASS / BROKEN / MISSING / LIVE-ONLY;
- evidence.

Derive this from `AGREED-GOALS.md`, manifests, current source, current issues, and test history.

Do not limit the run to the three latest T007 bugs.

Systematically burn down the whole product until no known source/build/package/install defect remains.

---

## 6. Immediate T007 evidence — fix these first

Exact live-tested source before this autonomous run:

`d2a4c8f1c166bbfd0227451cbf32e3793f10ea72`

T007 evidence:

`Biology-Operator-Evidence-attended-d2a4c8f1c166-20260920-014102-63374e83.zip`

Expected SHA-256:

`E25A441BD4BD61DB31874E91483101E3D021ED72C65471743CB7B3FBC5F964EA`

Locate it locally if available and inspect directly.

T007 proved:
- managed build/install PASS;
- exact 2.31 compile PASS;
- game launched;
- fresh REDscript compile;
- no crash/hang evidence;
- W19 Biology drill-down/Back is live-good;
- W20.2 preference placement is visually good.

### 6.1 Body authority is blocked

Initial Biology diagnostic:

`ticks 0 progressed 0 allowed false dt 0h rate 0x body 0h`

Later after ordinary gameplay:

`ticks 23 progressed 0 allowed false dt 0h rate 0x body 0h`

This proves the tick loop is alive but body progression never becomes allowed.

Current likely seam:

`CRBodyRuntime.NativeStateAllowed(false)`

depends on:

`CRInjuryEffectsBridge.Allowed(player, true)`

which was originally shaped around actor/NPC injury-effect eligibility and rejects on conditions including attachment/scene state.

Do not simply remove the gate.

Use current 2.31 game source/resources to prove which predicate rejects the ordinary local PlayerPuppet and create a semantically correct **player body progression lifecycle gate**.

Body progression should:
- run during ordinary active gameplay;
- suspend where native pause/menu semantics require;
- not progress from duplicate clocks;
- intentionally handle scenes/cinematics rather than accidentally blocking all player time;
- remain fail-closed when player/runtime authority is truly unavailable;
- preserve one persistent CRBodyState.

### 6.2 Combat reaches body-gate rejection

After substantial real native Health loss, T007 showed:

`combat ... commit-body-gate ...`

with tissue burden still zero.

Therefore combat hooks exist and are reaching Biology.

Continue the causal route:

`ProcessOneShotProtection`
→ `CRNativeWoundBridge.Prepare`
→ native resource loss
→ `SendDamageEvents`
→ `CRNativeWoundBridge.Commit`
→ `CRBodyRuntime.RecordInjury`
→ `CRBodyInputs.Drain`
→ persistent body
→ Biology presentation.

Determine whether the player lifecycle/body-gate correction resolves combat as well.

Then find and fix the next first broken boundary if one remains.

Never substitute:
- Health polling;
- synthetic generic wounds;
- a second damage authority;
- a second injury state.

Actual accepted native physical Health loss must remain a prerequisite for physical injury.

### 6.3 E3 preference is visible but does not toggle

The local Biology detail placement is KEEP:

`PRESENTATION`
`E3 HUD + NAMEPLATES    ON`

Do not move it back to fullscreen TopRight.

Diagnose:
- pointer callback firing;
- action name;
- current-target behavior when clicking child widgets;
- `CRBiologyInDetail()`;
- handled-event state;
- missing `CRRealpassSettings` ScriptableSystem;
- UI refresh.

Particularly audit this dangerous current behavior:

If `CRRealpassSettings.Get(game)` is undefined, `SetE3FirstPersonHudVisuals` currently returns success without storing state, while reads default to ON.

A missing settings authority must not masquerade as a successful toggle.

Finished behavior:
- row reliably toggles ON/OFF;
- immediate UI refresh;
- actual E3 presentation follows;
- save-backed authority persists across reopen/save/load;
- launcher OFF always wins over the saved presentation preference.

### 6.4 Scanner/nameplate presentation conflict

T007 showed native blue `BEAT COP` while Biology simultaneously forced red `NC RESIDENT`.

Do not write fallback identity into native scanner/knowledge data.

The remaining fix is presentation ownership:
- identify native scanner/detailed identity state and widgets;
- when scanner/detailed native identity owns the presentation, suppress Biology ambient fallback;
- outside scanner, keep ambient public names where native policy allows;
- preserve hidden-name, alternative-name, quest-target, disabled-nameplate rules;
- preserve modern scanner/quickhack UX.

Do not add guessed screen-space overlays.

---

## 7. Finish the physiology product, not just T007

Audit the entire authoritative body loop.

At minimum prove and repair where needed:

### Time / needs
- awake time progression;
- hydration;
- nutrition/energy;
- bladder;
- activity/exertion;
- sleep;
- WAIT;
- shower/body interactions;
- consumable intake;
- no progression while truly paused/invalid;
- sensible progression through allowed game states.

### Body state and persistence
- exactly one persistent authority;
- schema migration safety;
- menu reopen reads current state;
- save/reload continues state;
- sleep/wait advances same state;
- launcher OFF does not erase saves;
- uninstall does not delete saves;
- reinstall/enable resumes valid Biology state rather than corrupting/resetting it unexpectedly.

### Injury / wounds
- region resolution;
- tissue injury;
- bone injury;
- cyberware injury where intended;
- bleeding;
- wound progression;
- treatment/field care;
- recovery;
- injury effects;
- no wound without causal accepted native damage.

### Combat / protection
- actual hit region/material;
- stock clothing/armor protection;
- cyberware/protection;
- armor wear;
- unmapped protection safe policy;
- physical damage path;
- native one-shot/boss/nullified/protected-hit semantics;
- no double damage;
- no duplicate actor HP authority.

### NPC integration
Audit whatever the canonical goals still require for NPC injury/progression. Do not grow scope into unrelated AI overhaul.

---

## 8. Finish Biology UI and Cyberware coexistence

Preserve the live-good native anatomy/Ripperdoc composition.

Audit:
- Biology root entry;
- overview;
- all supported body categories;
- drill-down;
- Back;
- repeated drill-in/out;
- selected body zoom;
- metrics;
- context/treatment surfaces;
- presentation preference;
- Biology ↔ Cyberware switching;
- stock Cyberware restore;
- ordinary equip/upgrade/vendor/capacity/armor behavior;
- no stock-grid flashes;
- no stale Biology widgets in Cyberware;
- no empty or fabricated body values.

Use authored/local/native layout hierarchy. No screenshot-derived global offsets.

Do not reintroduce the old `virtualGridContainer` host error.

---

## 9. Finish E3-inspired presentation

Project E3 is reference evidence only.

Audit the actual integrated current-game presentation against the intended E3-inspired visual language:

- quest/objective region;
- lower-left D-pad/hotkeys;
- lower-right weapon/ammo;
- ambient NPC identity;
- police/combatant identity;
- native scanner preservation;
- reticle cleanup;
- notifications/interactions where already in canonical scope;
- E3 ON/OFF preference;
- E3 OFF clean restore.

Structure should come from native/authored resources or Biology-owned authored resources, not arbitrary rectangles when those drift.

Modern scanner/quickhack remains authoritative.

No Project E3 runtime payload.

---

## 10. REDlauncher OFF must truly disable Biology

This is a release-critical audit.

The REDmod activation marker is the whole-product public activation boundary.

When REDlauncher “Enable mods” is OFF:
- Biology simulation must not advance;
- Biology combat modifications must yield;
- Biology injury effects must yield;
- Biology UI additions must not become authoritative;
- E3 presentation/nameplates must yield;
- health suppression or other presentation modifications must yield;
- Biology interactions must yield;
- native Cyberpunk behavior must remain usable.

Shared redscript/cybercmd infrastructure may still physically exist, but it must be non-authoritative.

Audit **every production hook/wrapper** for this contract.

Add static/regression coverage so new wrappers cannot accidentally ignore launcher activation.

Turning REDmods back ON should restore Biology without reinstall.

Saved Biology state may remain in saves while inactive; launcher OFF is not a save reset.

---

## 11. Dependency minimization / self-containment

Final runtime must remain as minimal as practical.

Current intended direct runtime dependencies:
- redscript 0.5.31;
- standalone cybercmd only as startup compilation plumbing if still genuinely required.

Current forbidden/not-required runtime dependencies:
- Mod Settings;
- ArchiveXL;
- RED4ext;
- Codeware;
- Project E3;
- Dark Future.

Do not keep a dependency merely because an old prototype used it.

Audit current code and package to prove dependency graph matches reality.

If a simpler native/REDmod path can safely eliminate a remaining generic dependency, you may improve the architecture, but do not perform risky broad rewrites solely for aesthetic purity.

Bundle all legally redistributable required dependency payload/licenses in the one player release so users do not hunt for prerequisites.

Never bundle proprietary game files.

---

## 12. Public install architecture

Target experience: one download, obvious installation, no dependency hunting.

Preferred final artifact:

`Biology-<version>-Cyberpunk-2.31.zip`

with a game-root-shaped layout where safe.

The ideal user action is:
- extract/drag the release into the Cyberpunk 2077 root;
- enable mods in REDlauncher;
- play normally.

However, do NOT make blind Explorer overwrite a foreign/newer shared loader simply to satisfy the phrase “drag-and-drop.”

If redscript/cybercmd global-file collision semantics make pure drag/drop unsafe, solve this cleanly. Acceptable final UX may be:
- game-root-shaped extraction plus one obvious `Install Biology.exe`, or
- another single-download collision-safe mechanism,
provided the user never has to manually locate dependencies or copy individual files.

Whichever design you choose:
- document it truthfully;
- keep it simple;
- fail before mutation on incompatible shared global collisions;
- preserve byte-identical already-installed shared dependencies;
- never downgrade a proven newer/incompatible shared loader blindly;
- retain exact ownership receipts.

If you can genuinely make pure drag/drop safe, do so and prove it.

---

## 13. Uninstaller — one button

The release must contain:

`Uninstall Biology.exe`

The player experience should be one obvious action.

The uninstaller must:
- consume the exact Biology ownership receipt;
- validate paths/hashes/namespace;
- remove Biology-owned payload;
- remove Biology REDmod identity;
- refresh/deploy official REDmod state as required;
- preserve saves;
- preserve generic/shared redscript/cybercmd unless explicitly Biology-exclusive and safely owned;
- preserve other REDmods;
- refuse changed/untracked/reparse unsafe content rather than over-delete;
- leave no stale Biology activation;
- allow a clean Biology reinstall afterward.

Keep Windows Application Control lessons from W22:
do not depend on generating/running a new unsigned Temp executable during routine transition/uninstall.

Test uninstaller from the actual final release artifact, not merely source-unit tests.

---

## 14. Upgrade / reinstall contract

Test:
- install final candidate over no Biology;
- reinstall same exact candidate;
- upgrade from currently installed prior Biology receipt;
- uninstall;
- reinstall;
- launcher OFF;
- launcher ON again.

No unexplained residue.

No need for Steam reinstall as a normal Biology lifecycle.

If a collision or changed file is detected, fail closed before mutation and make the user-facing error actionable.

---

## 15. Release artifact integrity

The final player artifact must contain only intended redistributable content.

It must include:
- Biology REDmod identity;
- Biology project-original runtime;
- required redistributable pinned dependencies;
- required licenses/notices;
- exact version/provenance;
- ownership manifest/receipt;
- checksums;
- install instructions;
- `Uninstall Biology.exe`.

It must NOT contain:
- Cyberpunk proprietary archives/scripts/final.redscripts;
- saves;
- user settings;
- private reference mods;
- Project E3 payload;
- Dark Future payload;
- repo staging/reports/vendor/reference bundles;
- development secrets;
- unrelated test artifacts.

Run artifact-policy tests and inspect the ZIP inventory manually/programmatically.

---

## 16. Version and release status

The goal is to finish the product, not merely create another dev candidate.

Do not label a broken build 1.0.

If every release gate that can be automated/localized passes and no known source defect remains, promote the product version consistently to an appropriate release version (prefer **1.0.0** if the canonical product really is feature-complete).

Update all manifests/docs/version files together.

If an irreducible human-only visual acceptance item remains, distinguish that honestly from source/build/install completeness. Do not leave stale documentation claiming old failures are current.

Do not externally publish to Nexus/other public distribution without owner approval.

A local final release artifact and merged GitHub source are enough for this overnight goal.

---

## 17. Static/native evidence strategy

When uncertain about current CP2077 internals:

1. inspect Biology source/tests;
2. inspect installed 2.31 game directly;
3. inspect private working mods that touch the same subsystem;
4. inspect official tool/framework docs;
5. only then rely on broad community/web examples.

Prefer:
working mod → dependency mechanism → native 2.31 authority → Biology-owned minimal seam.

Do not guess from screenshots if the installed resource/controller can answer the question.

Persist redistribution-safe derived findings into repo docs so future maintenance does not require redoing private archaeology.

---

## 18. Testing strategy — autonomous, no owner waiting

Run tests continuously.

Required categories:

### Unit/model
- body model;
- clock;
- inputs;
- injury;
- wound;
- combat;
- armor/protection;
- persistence;
- settings;
- presentation policy.

### Static/native contracts
- current game signatures;
- widget/controller seams;
- hook method signatures;
- activation gates.

### Exact compile
Exact-compile **all production REDscript sources** against the installed CP2077 2.31 base.

Do this after major changes and again at final reconciled HEAD.

### Packaging
- full `Build-BiologyPackage.ps1`;
- dependency acquisition/pinning;
- artifact policy;
- receipt creation;
- checksums;
- uninstaller build;
- release ZIP inventory.

### Install lifecycle
On the owner machine, after source/build gates pass, you are explicitly authorized to exercise Biology's own supported install lifecycle against:

`C:\Games\Steam\steamapps\common\Cyberpunk 2077`

Use only the receipt-bounded Biology installer/uninstaller/transition tooling.

Before mutation:
- capture relevant Biology ownership/install state;
- make sure failure can preserve current installed candidate;
- never recursively wipe the game.

Test:
- install;
- verify exact receipt;
- REDmod recognition/deploy;
- uninstall;
- verify Biology-owned files removed;
- verify shared dependencies/other mods preserved;
- reinstall final candidate;
- verify final exact receipt.

End state must be **final Biology installed**, not uninstalled.

### Launcher disable/enable
Use the safest available automated mechanism to prove REDmod activation marker absence/presence and startup compilation behavior.

If full REDlauncher GUI interaction can be automated safely, exercise OFF and ON.
If not, prove as much as possible from deployment/activation contracts and leave only the UI click itself as human-live acceptance.

### Game startup smoke
You may launch Cyberpunk unattended for a **startup/main-menu smoke test** if you can do so without loading/modifying the owner's saves.

Observe:
- process start;
- current REDscript output regeneration;
- REDmod logs/deployment;
- no compile/runtime startup error;
- no crash/hang.

Do not load a user save merely to obtain overnight gameplay evidence unless you can guarantee a disposable isolated save/profile and no user-save mutation.

Do not claim gameplay/UI acceptance from a main-menu smoke test.

---

## 19. Current attended diagnostics

Keep the W21.2 attended diagnostic machinery available while solving body authority, but ensure it remains:
- transient/in-memory;
- absent from normal release presentation;
- diagnostics-off in release package.

Once the root cause is proven/fixed, keep only diagnostics that materially improve future maintenance without leaking into ordinary gameplay.

Do not let test telemetry become an authority.

---

## 20. Performance / robustness audit

Before final release:
- inspect recurring DelaySystem callbacks;
- avoid per-frame heavy allocations where not necessary;
- bound arrays/history;
- avoid log spam;
- ensure reference/debug diagnostics are gated off;
- avoid repeated expensive TweakDB/resource scans at runtime;
- ensure menu widgets clean up/reuse correctly;
- verify no obvious runaway callback registration;
- verify no persistent stale widget/controller references after mode changes.

Use profiling/log evidence available without loading user saves.

---

## 21. Save and upgrade safety

Never delete or rewrite the owner's save files.

Audit persistent schemas:
- body state;
- settings;
- NPC state if persisted;
- schema versions/migrations.

Old Biology state in a save should either:
- migrate safely;
- be intentionally compatible;
- or fail visibly without corrupting the save.

Launcher OFF and uninstall do not mean save rollback.

Document this clearly.

---

## 22. Issue/repo cleanup

The repo currently contains stale open issues from old lanes.

Near completion, inspect all open issues, especially:
- #35
- #39
- #40
- #41
- #44
- #78
- #101
- #102
- #148
- #151
- #152

Do not mechanically close them early.

Once the final implementation supersedes/resolves them:
- add concise final evidence comments;
- close superseded/completed issues;
- leave only genuinely unresolved future work open.

Update:
- `README.md`;
- `ROADMAP.md`;
- active REDmod roadmap;
- release architecture docs;
- player disable/uninstall docs;
- manifests;
- version files;
- test ledger as appropriate.

Remove stale prose saying known-fixed historical failures are current.

Do not delete valuable historical test records.

---

## 23. Git discipline

Work only on:

`autonomous/final-product-completion`

Commit coherent checkpoints.

Fetch/rebase/merge latest main as needed.

Never force-push shared history.

Before final PR:
- clean working tree;
- latest main reconciled;
- full tests rerun;
- exact compile rerun;
- final artifact rebuilt from the exact final HEAD;
- install lifecycle rerun with that exact artifact.

Open one final PR against `main`.

Wait for GitHub CI.

Fix every failure.

When all completion gates are green, you are owner-authorized for this run to merge your own final PR.

After merge:
- resolve exact new `main`;
- rebuild the release artifact from merged main if merge SHA differs materially from tested commit;
- ensure final installed game receipt matches the merged release source;
- leave final Biology installed.

---

## 24. Completion gates

Do not call the mod “finished” until all of these are true or an item is demonstrably impossible without human visual input and is explicitly marked as such:

- canonical product scope audited;
- no known body-progression source bug;
- authoritative body time advances under correct lifecycle conditions;
- combat no longer statically stops at body gate;
- one-decimal Biology metrics source is exact-compile-safe;
- E3 preference reliably mutates real saved authority;
- scanner/native detailed identity suppresses ambient fallback conflict;
- Biology/Cyberware drill-down/Back remains stable;
- native Cyberware behavior preserved;
- launcher OFF contract audited across all hooks;
- release diagnostics off;
- exact 2.31 compile PASS;
- full local tests PASS;
- GitHub CI PASS;
- package build PASS;
- artifact policy PASS;
- dependency/license audit PASS;
- final install PASS;
- same-version reinstall/upgrade semantics PASS;
- hard uninstall PASS;
- post-uninstall no stale Biology activation;
- reinstall PASS;
- final exact candidate installed;
- ownership receipt matches final source;
- no private/proprietary material in artifact;
- README/install/uninstall docs accurate;
- stale issues/docs reconciled.

Continue working rather than stopping after the first successful fix.

---

## 25. Final deliverables

Create/update:

`docs/handoffs/AUTONOMOUS-FINAL-PRODUCT-COMPLETION.md`

At the end append a final completion report containing:

- exact starting main;
- exact final autonomous branch head;
- exact merged main;
- full list of root causes fixed;
- architecture changes;
- body authority fix;
- combat result;
- preference fix;
- scanner/nameplate fix;
- other whole-product defects found/fixed;
- exact tests run and counts/results;
- exact current-game compile command and PASS evidence;
- tool/framework versions;
- release version;
- release artifact path;
- release artifact SHA-256;
- release artifact inventory summary;
- install result;
- uninstall result;
- reinstall result;
- launcher OFF/ON evidence;
- final installed ownership receipt/source revision;
- GitHub PR number;
- GitHub CI run/result;
- issues closed;
- residual human-only visual checks, if any;
- concise owner morning checklist.

Also update issue #152 with the same high-level completion state.

---

## 26. Owner morning state

The owner should wake up to:

- source merged to `main` if all gates passed;
- one final release artifact in a clearly named local release directory, e.g. `C:\Games\Biology-Releases\`;
- Biology final build installed in Cyberpunk 2077;
- an exact ownership receipt proving what is installed;
- `Uninstall Biology.exe` present and tested;
- no temporary worker/test residue that can be safely cleaned automatically;
- no need to run a chain of repair commands;
- one concise report explaining what was fixed and any genuinely irreducible visual/gameplay checks still worth doing.

Do not leave the owner with an uninstalled game merely because uninstall testing was the last lifecycle step. **Reinstall the final release after uninstall verification.**

Do not wait for the owner during the run.
