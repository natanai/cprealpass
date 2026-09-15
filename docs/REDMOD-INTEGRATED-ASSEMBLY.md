# Biology integrated REDmod-first assembly

Status: **DEPLOYMENT FOUNDATION ACCEPTED; broader live acceptance ongoing**  
Target game: Cyberpunk 2077 `2.31`  
Canonical builder: `tools/Build-BiologyPackage.ps1`

## Purpose

This document describes the current integrated package architecture and the direct evidence already obtained. It is no longer a pre-deployment handoff for the original three migration lanes.

Historical provenance remains in Git history and the exact attended record under `docs/test-runs/`.

## What has been proven

The exact integrated candidate built from:

`8cf045664b5e4d8b4b014edfc98bf2f8eb270ba5`

produced:

`biology-integrated-20260915-061136-8cf045664b5e.zip`

SHA-256:

`42BACC73173EB95D84F3278593CD06DDAF665AA714F4C692DB03D553B91557CC`

On a clean Cyberpunk 2077 2.31 installation:

- exact compilation passed;
- the release-shaped package installed successfully;
- official REDmod recognized `Biology`;
- REDmod reported `Found mod "Biology"`;
- all five deploy stages executed;
- `r6/cache/modded/mods.json` was written;
- `Commandlet deploy has succeeded` was observed;
- the corrected Biology deploy helper returned PASS only after validating real deployment evidence.

The earlier false-positive deploy attempt is also important evidence: REDmod can return exit code 0 while ignoring the intended root and finding no mods. Therefore raw exit code alone is never accepted as deploy proof.

See `docs/test-runs/2026-09-15-8cf04566-redmod-deploy-preflight.md`.

## Canonical package shape

Biology is **REDmod-first, not REDmod-only**:

- `mods/Biology` is the official first-party REDmod identity;
- current Biology-owned additive/wrapper REDscript remains under `r6/scripts/CyberpunkRealism` because those seams are classified `REDSCRIPT-BETTER`;
- generic framework files outside `mods/Biology` are included only while a current accepted consumer requires them;
- every installed file is individually owned/hashed/attributed;
- shared roots are never recursively Biology-owned;
- no Dark Future or Project E3 runtime content ships.

The canonical build command from an active pristine candidate checkout is:

```powershell
pwsh ./tools/Build-BiologyPackage.ps1 `
  -GameRoot 'C:\Games\Steam\steamapps\common\Cyberpunk 2077'
```

For normal milestone preparation, prefer the higher-level canonical operator flow in `LOCAL-OPERATOR-COMMANDS.md` rather than manually chaining build/install/deploy steps.

Artifact naming:

```text
biology-integrated-<UTC timestamp>-<12-char source SHA>.zip
```

Important package metadata includes:

```text
mods/Biology/info.json
biology/build-manifest.json
biology/provenance.json
BIOLOGY-VERSION.txt
SHA256SUMS.txt
INSTALL.txt
UNINSTALL.txt
LICENSES/<retained dependency>.txt
```

## Exact compilation remains a hard artifact gate

`Build-BiologyPackage.ps1` constructs the complete accepted Biology runtime, stages current activation gates in build-owned copies, and exact-compiles against the installed supported Cyberpunk 2077 2.31 `final.redscripts` before emitting a playable ZIP.

That proves source/language compatibility with the supported bundle. It does not by itself prove:

- body runtime lifecycle;
- UI rendering/navigation;
- save/reload behavior;
- E3 presentation;
- launcher-off Biology inactivity;
- uninstaller safety;
- quest/gameplay acceptance.

Those remain direct/attended gates.

## Current generic dependencies

The integrated candidate currently retains:

| Component | Status | Current reason | Direction |
| --- | --- | --- | --- |
| official REDmod | required platform | package/deploy/enable authority | retain; game-provided |
| redscript `0.5.31` | direct required runtime | Biology-owned additive/wrapper seams | retain while this remains the narrower robust route |
| Mod Settings `0.2.21` | temporary | current accessible/persistent provider for provider-neutral Biology/E3 preferences | remove/rethink when an accepted smaller provider/boundary replaces it |
| ArchiveXL `1.27.3` | temporary transitive | dependency of current Mod Settings adapter | remove with Mod Settings unless another direct consumer appears |
| RED4ext `1.30.0` | temporary transitive | plumbing for ArchiveXL/Mod Settings | remove with that chain unless another direct consumer appears |

Not required by the current candidate:

- TweakXL;
- Codeware;
- Input Loader;
- Dark Future runtime;
- Project E3 runtime.

Issue #44 additionally owns proving that supplemental files outside the REDmod package do not keep Biology behavior active when REDlauncher `Enable mods` is OFF.

## Project E3 reference boundary

Project E3 remains a local-only presentation reference. `config/realpass-e3.json` preserves the reference inventory/version/hashes; actual third-party `ReferenceMods/` payload is gitignored and never shipped.

Issue #40 uses the reference for design/controller archaeology while implementing Biology-owned presentation.

## Ownership and hard uninstall target

`biology/build-manifest.json` is the exact installed-file ownership record. Ordinary payload entries include:

- relative path;
- SHA-256;
- owner;
- component;
- route;
- replacement policy.

First-party directory roots are narrow. Shared roots such as `bin`, `archive`, `engine`, `mods`, `r6`, and `red4ext` may never be deleted recursively.

The target player release now includes a self-contained `Uninstall Biology.exe` that consumes the ownership/version contract, preserves saves, preserves settings by default, refuses changed/ambiguous file deletion, removes only now-empty owned directories, and refreshes REDmod state. Issue #44 owns implementation/acceptance.

A full Steam reinstall is not the normal Biology uninstall path.

## Deterministic REDmod deployment

The supported tool is:

```text
tools/redmod/bin/redMod.exe
file version 2.3.1.0
product version 2.31
```

Do **not** reconstruct raw REDmod command quoting from this document or old chat history.

For deterministic developer/probe deployment, use:

```powershell
pwsh ./tools/Deploy-BiologyRedmod.ps1 `
  -GameRoot 'C:\Games\Steam\steamapps\common\Cyberpunk 2077'
```

The helper owns argument construction and fails closed if REDmod reports root fallback, invalid root, or an empty mod set even when the process exits 0.

Normal players use the supported REDlauncher/Steam mod-enable path.

## Current direct-game gates

Already accepted:

- official REDmod executable/version/module contract;
- Biology REDmod recognition;
- real five-stage Biology deployment.

Still open:

- launcher enable/disable and launcher-OFF Biology-inactive behavior;
- normal relaunch persistence;
- self-contained hard uninstall and residue verification;
- safe REDmod overlap/precedence fixture;
- live body runtime authority (#41);
- Biology native shell/drill-down/back behavior (#39);
- E3 ordinary HUD/ambient nameplate behavior (#40);
- broader combat/body/save/quest/performance acceptance.

## Legacy builders

`Build-BiologyPackage.ps1` is the canonical player-candidate route and has now met the old foundation's exact-build/install/deploy proof threshold.

Older RealPass-era model/clean-room builders may remain temporarily only when a current test/recovery consumer still requires them. They must be clearly labeled legacy/development and must not appear in active player/operator instructions as equivalent canonical routes.

A later cleanup may remove them once no active test/recovery contract depends on them; do not keep them indefinitely merely because they were once the working path.

## Testing mode

The **first** REDmod structural milestone already used milestone clean-room preparation. Future test mode follows `CLEAN-ROOM-TESTING.md` based on the change being tested:

- use iteration when the previous Biology install can be safely accounted for under current ownership/reset policy;
- use milestone clean-room for structural/package/framework/game-patch changes, unexplained residue, or deliberate release-level confidence.

Do not force a Steam reinstall merely because this document historically described the first structural migration.

## Source of current work

Current branch ownership and acceptance criteria live in:

- root `ROADMAP.md`;
- `ACTIVE-REDMOD-ROADMAP.md`;
- current GitHub issues/PRs;
- the latest relevant `docs/test-runs/` record.

Do not revive the original migration lane names from this document's Git history.
