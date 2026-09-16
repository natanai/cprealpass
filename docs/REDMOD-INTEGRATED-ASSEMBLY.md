# Biology integrated REDmod-first assembly

Status: **DEPLOYMENT FOUNDATION ACCEPTED; W10 self-contained settings source complete; broader live acceptance ongoing**  
Target game: Cyberpunk 2077 `2.31`  
Canonical builder: `tools/Build-BiologyPackage.ps1`

## Purpose

This document describes the current integrated package architecture and direct evidence already obtained. Historical attended evidence from the earlier multi-framework artifact remains useful, but it must not be confused with the W10 dependency-reduced candidate.

## What has been proven

The earlier exact integrated candidate built from `8cf045664b5e4d8b4b014edfc98bf2f8eb270ba5` proved exact compilation, installation, official REDmod recognition of `Biology`, and real five-stage REDmod deployment on Cyberpunk 2077 2.31.

That artifact also later showed launcher-OFF residue from the then-retained settings stack: an ArchiveXL DLL security warning and a blank/inert Mod Settings pause-menu space. W10 removes that stack from the next production candidate rather than treating the observation as acceptable final behavior.

See `docs/test-runs/2026-09-15-8cf04566-redmod-deploy-preflight.md` plus issue #61 / parent evidence for the launcher-OFF follow-up.

## Canonical package shape

Biology is REDmod-first, not REDmod-only:

- `mods/Biology` is the official first-party REDmod identity and whole-mod activation marker owner;
- Biology-owned additive/wrapper REDscript remains under `r6/scripts/CyberpunkRealism` where classified `REDSCRIPT-BETTER`;
- **redscript is now the only retained generic runtime dependency**;
- Mod Settings, ArchiveXL, and RED4ext are removed from the production package path;
- every installed file is individually owned/hashed/attributed;
- shared roots are never recursively Biology-owned;
- no Dark Future or Project E3 runtime content ships.

The canonical build command remains:

```powershell
pwsh ./tools/Build-BiologyPackage.ps1 `
  -GameRoot 'C:\Games\Steam\steamapps\common\Cyberpunk 2077'
```

For attended preparation, prefer the higher-level canonical operator flow in `LOCAL-OPERATOR-COMMANDS.md`.

## Exact compilation remains a hard artifact gate

`Build-BiologyPackage.ps1` constructs the complete accepted Biology runtime and exact-compiles against the installed supported Cyberpunk 2077 2.31 `final.redscripts` before emitting a playable ZIP.

That proves source/language compatibility. It does not by itself prove UI rendering, ScriptableSystem save lifecycle, E3 preference interaction/persistence, launcher-off Biology inactivity, hard-uninstall runtime cleanliness, or gameplay/quest acceptance.

## Current generic dependencies

| Component | Status | Current reason | Direction |
| --- | --- | --- | --- |
| official REDmod | required platform | package/deploy/enable authority and launcher activation marker | retain; game-provided |
| redscript `0.5.31` | direct required runtime | Biology-owned additive/wrapper runtime/UI/native seams plus save-backed ScriptableSystem preference state | retain while these accepted seams remain |
| Mod Settings `0.2.21` | **removed** | no current consumer; replaced by Biology-owned save persistence/UI | absent from production artifact |
| ArchiveXL `1.27.3` | **removed** | former transitive Mod Settings dependency; no direct Biology consumer | absent from production artifact |
| RED4ext `1.30.0` | **removed** | former transitive settings-stack plumbing; no Biology plugin | absent from production artifact |

Also not required: TweakXL, Codeware, Input Loader, Dark Future runtime, Project E3 runtime.

`tools/Build-OwnedRuntimeProfile.ps1` acquires/stages only redscript. `Build-BiologyPackage.ps1` expects exactly redscript and fails closed if a retired or blocked component enters the artifact.

## Self-contained settings

The remaining public preference is `presentation.e3-first-person-hud-visuals`.

- persistence: `CRRealpassSettings.e3FirstPersonHudVisuals`, a persistent Biology `ScriptableSystem` Bool stored through the Cyberpunk save lifecycle;
- editor: Biology-owned Ink control on the existing Biology/Cyberware body screen;
- whole-mod activation: REDlauncher/REDmod sentinel only;
- external settings provider: none;
- pause-menu provider registration: none.

There is no saved `Enable Biology` Boolean. This prevents a saved preference from competing with launcher OFF and avoids preserving a framework stack solely to host two booleans.

## Ownership and hard uninstall

`biology/build-manifest.json` is the exact installed-file ownership record. Ordinary payload entries include relative path, SHA-256, owner, component, route, and replacement policy.

The uninstaller contract records `savePolicy = never-target` and `preferencePolicy = stored-in-save-never-target`. Because preferences are save-backed, `Uninstall Biology.exe` does not edit any third-party settings file or expose a provider-specific preference-removal checkbox.

The one retained generic dependency, redscript, remains shared/preserved by normal player uninstall. Shared roots such as `bin`, `archive`, `engine`, `mods`, `r6`, and `red4ext` may never be deleted recursively; mentioning `red4ext` here is a deletion-safety boundary, not a Biology dependency.

## Deterministic REDmod deployment

The supported game-provided REDmod tool remains the deployment authority. Use `tools/Deploy-BiologyRedmod.ps1` for deterministic developer/probe deployment rather than reconstructing raw command quoting.

W09.1 / issue #59 owns the separate post-uninstall REDmod output-cache recovery problem. W10 does not modify that deployment-state recovery architecture.

## Current direct-game gates

Already accepted from earlier integrated evidence:

- official REDmod executable/version/module contract;
- Biology REDmod recognition;
- real five-stage Biology deployment.

Still requiring parent/direct acceptance for the new W10 architecture:

- exact compile of the combined integrated candidate against supported 2.31;
- REDlauncher ON/OFF and launcher-OFF Biology-inactive behavior with only redscript supplemental runtime remaining;
- no Biology-owned blank/dead settings row or settings-stack DLL warning;
- E3 preference body-shell interaction and save/reload persistence;
- OFF -> ON preservation of E3 preference/state;
- self-contained hard uninstall and residue verification;
- issue #59 post-uninstall REDmod output recovery through W09.1;
- safe REDmod overlap/precedence fixture;
- live body runtime, Biology shell, E3 presentation, and broader gameplay acceptance.

## Testing mode

Because W10 removes packaged frameworks and changes persistence/UI ownership, the parent should treat integrated attended acceptance as a structural dependency milestone under `CLEAN-ROOM-TESTING.md`. W10 itself does not ask the user to install or play the worker branch.

## Source of current work

Current branch ownership and acceptance criteria live in root `ROADMAP.md`, `ACTIVE-REDMOD-ROADMAP.md`, current GitHub issues/PRs, `THREAD-LEDGER.md`, and the latest relevant `docs/test-runs/` record.
