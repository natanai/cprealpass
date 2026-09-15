# Handoff — Player disable/uninstall and vanilla-play mode

Issue: **#44**  
Branch: **`agent/player-uninstall-vanilla-toggle`**  
Base: **`23eab90a3d28e428f3679911d971106eb5413a9b`**

## Mission

Implement the canonical contract in `docs/PLAYER-DISABLE-UNINSTALL.md`:

- REDlauncher `Enable mods` ON -> Biology active;
- REDlauncher `Enable mods` OFF -> Biology behavior inactive / vanilla-play mode;
- `Uninstall Biology.exe` -> safe hard removal without reinstalling Cyberpunk.

This work is aimed at players who may never have used a Cyberpunk mod manager. The intended UX is drag/drop install, familiar launcher switch for everyday enable/disable, and a double-click uninstaller for removal.

Do not optimize for expert-modder conventions at the expense of that goal.

## Read first

- `AGENTS.md`
- `AGREED-GOALS.md`
- `ROADMAP.md`
- `docs/RELEASE-ARCHITECTURE.md`
- `docs/BIOLOGY-REDMOD-MIGRATION.md`
- `docs/CLEAN-ROOM-TESTING.md`
- `docs/LOCAL-OPERATOR-COMMANDS.md`
- `docs/PLAYER-DISABLE-UNINSTALL.md`
- `docs/INTEGRATION-ORCHESTRATOR.md`
- `docs/PARALLEL-AGENT-WORKFLOW.md`
- `manifest/distribution.json`
- `manifest/install-contract.json`
- `manifest/package.json`
- current `tools/Build-BiologyPackage.ps1`
- current `tools/Reset-BiologyIteration.ps1`
- current `tools/Deploy-BiologyRedmod.ps1`
- current runtime/settings activation gates
- issue #44 and all comments

Also review open attended follow-ups #39, #40 and #41 before changing any feature-owned files.

## Scope boundary

You own release/package/activation/uninstall work necessary for #44.

Do not absorb:

- Biology shell redesign (#39);
- E3 HUD/nameplate redesign (#40);
- body runtime authority repair (#41);
- unrelated gameplay/calibration work.

If launcher-OFF behavior requires a narrow activation-gate change in a shared runtime file, document the overlap explicitly in the PR and minimize it.

## Phase 1 — audit launcher-OFF behavior

Before implementing the uninstaller, determine exactly what the current installed candidate does when REDlauncher `Enable mods` is OFF.

Inventory every current package family and classify it:

```text
path/component
-> load mechanism
-> controlled by REDmod enablement? yes/no/partial
-> can still execute with launcher mods OFF?
-> if yes, what Biology behavior remains?
-> required remediation
```

At minimum cover:

- `mods/Biology`;
- REDmod-deployed/generated state;
- Biology-owned scripts staged under `r6/scripts`;
- redscript framework/bootstrap;
- RED4ext;
- ArchiveXL;
- Mod Settings;
- loose archive routes if any;
- Biology config/state files;
- any current generic dependency outside the REDmod package.

Do not assume `Enable mods OFF` disables redscript/RED4ext content just because Biology's package is a REDmod.

The accepted product result is behavioral vanilla-play mode. If an out-of-package Biology hook still loads, it must fail open to native behavior when the Biology REDmod activation signal is absent.

Do not solve this by requiring the player to also toggle an internal Biology setting.

## Phase 2 — establish a robust activation signal

If current additive scripts can load when REDmod is OFF, design the narrowest stable way for them to know whether Biology is actually activated.

Requirements:

- absent/false activation -> native behavior;
- activation survives normal launcher ON/relaunch;
- launcher OFF cannot accidentally reuse stale cached Biology-active state;
- save data must not itself force Biology active when launcher mods are OFF;
- do not couple activation to E3 presentation preference;
- avoid brittle polling or dependence on UI opening;
- prefer official/native REDmod/package state evidence where available.

If direct Cyberpunk 2.31 evidence is required, use `docs/LOCAL-OPERATOR-COMMANDS.md`. Add/refine a reusable probe before asking the user to run routine shell commands.

## Phase 3 — self-contained player uninstaller

Build a player-facing Windows executable, conceptually named:

`Uninstall Biology.exe`

The final release must not require PowerShell, Git, repository source, Vortex, or another mod manager.

### Implementation architecture

Separate the **deletion planner/ownership verifier** from the front-end.

The planner should be deterministic and unit-testable from synthetic filesystem/manifest fixtures without touching a real Cyberpunk install.

The front-end can be minimal, but must be understandable to a non-modder.

A suitable flow is:

```text
Biology Uninstaller

Cyberpunk 2077 installation:
C:\...\Cyberpunk 2077

Biology version: <version>

[ ] Also remove Biology preferences   (default unchecked)

[Uninstall Biology] [Cancel]
```

After completion:

```text
Biology removed successfully.
Cyberpunk saves were not touched.

0 changed/shared files were left behind.
```

Or, on conservative partial removal:

```text
Biology-owned files were removed, but 2 changed files were left in place for safety.
See details.
```

Do not require a complex installer wizard.

### Required filesystem safety

The planner must reject:

- rooted manifest paths;
- `..` traversal;
- duplicate manifest paths;
- game-root deletion;
- recursive ownership of shared roots;
- unsupported/malformed manifest versions;
- unexpected product identity;
- ambiguous changed payload.

Shared roots never recursively owned:

- `archive`
- `bin`
- `engine`
- `r6`
- `red4ext`
- top-level `mods`

Delete only exact safely-owned files, then remove now-empty reached directories.

### Hash policy

For Biology-owned ordinary payload:

- current hash == installed manifest hash -> eligible for removal;
- current hash differs -> leave it and report it;
- missing -> report it, do not fabricate success for that path.

Do not delete a changed file merely because its path used to belong to Biology.

### Generic dependencies

Current package may install generic framework files.

A dependency file that Biology originally installed may later be used/updated by another mod.

Design a conservative policy rather than blindly deleting framework roots.

Document exactly how each retained generic dependency is treated. If reliable sharing detection is impossible, prefer leaving an ambiguous/changed framework file and reporting it over breaking another mod.

This work may strengthen the case for removing transitional framework dependencies later, but do not silently redesign unrelated settings functionality without parent coordination.

## Phase 4 — REDmod state after uninstall

Removing `mods/Biology` alone is not sufficient if generated/deployed REDmod state can keep stale entries.

Determine the supported way to refresh deployment after hard uninstall.

The uninstaller should perform or guide the minimum deterministic action required so the next ordinary launch does not retain stale Biology deployment state.

Do not report success merely because a process returned exit code 0; follow the fail-closed lessons already encoded in `Deploy-BiologyRedmod.ps1`.

## Phase 5 — package builder integration

Evolve `Build-BiologyPackage.ps1` so a release-shaped artifact contains:

- the self-contained uninstaller;
- immutable version/ownership metadata required by it;
- no development-only repository state;
- reproducible provenance for the uninstaller binary.

The package's uninstall metadata must correspond to the exact payload in that same artifact.

Do not ship an uninstaller built against a different manifest/version than the package beside it.

## Phase 6 — developer command convergence

Do not maintain two contradictory cleanup algorithms indefinitely.

Where practical, make developer iteration reset and player uninstall share the same ownership-planning model or fixtures.

`Reset-BiologyIteration.ps1` can remain stricter by performing a post-removal full baseline verification, but its deletion semantics should not drift from the player uninstaller's safe ownership rules.

Update `docs/LOCAL-OPERATOR-COMMANDS.md` with a canonical hard-uninstall/verification command for development once the implementation exists.

Do not make routine user testing depend on manually composing deletion commands.

## Tests

Automated coverage must include at least:

- valid exact Biology manifest removal plan;
- changed Biology-owned file retained;
- missing file reported;
- traversal/rooted-path rejection;
- duplicate path rejection;
- malformed/wrong-product manifest rejection;
- shared-root recursive delete impossible;
- empty-directory cleanup bounded to reached owned paths;
- saves outside game-root ownership never touched;
- preferences preserved by default;
- generic dependency changed/shared policy;
- stale REDmod cleanup/deploy contract where testable;
- package builder embeds matching uninstaller + manifest/version metadata;
- no Project E3/Dark Future runtime introduced.

If using .NET/another binary toolchain, CI must compile/test it on a supported runner and ideally produce a Windows binary artifact for inspection.

## Direct attended acceptance still required

Source/CI cannot close #44.

The parent will eventually run a release-shaped attended test:

### Soft toggle

```text
launcher mods ON -> Biology active
quit
launcher mods OFF -> Biology behavior inactive / vanilla-play mode
quit
launcher mods ON -> Biology active again
```

No reinstall between those states.

### Hard uninstall

```text
exact Biology release installed
-> double-click Uninstall Biology.exe
-> package removed safely
-> REDmod state coherent
-> saves untouched
-> normal vanilla launch
-> residue verification
```

The user should not need PowerShell for the player-facing hard-uninstall test.

## Clean-room escalation

After #44 is accepted, full Steam uninstall + residual folder deletion + reinstall remains reserved for:

- unexplained residue;
- missing/corrupt ownership metadata;
- Cyberpunk/REDmod/framework patch transitions;
- structural migration whose previous paths cannot be safely proven;
- deliberate milestone/release confidence from scratch.

It is no longer the normal way to remove Biology.

## Deliverable

Open a PR from:

`agent/player-uninstall-vanilla-toggle`

to `main`.

Report:

- exact head SHA;
- PR number;
- launcher-OFF runtime audit;
- activation mechanism chosen;
- player uninstaller implementation/toolchain;
- package layout changes;
- ownership/dependency deletion policy;
- REDmod refresh behavior;
- automated safety tests;
- binary build/provenance method;
- CI result;
- any overlap with #39/#40/#41;
- exact attended checks still required.

Do not ask the user to install/test this worker branch independently. The parent integration thread will combine compatible changes into the next attended candidate.
