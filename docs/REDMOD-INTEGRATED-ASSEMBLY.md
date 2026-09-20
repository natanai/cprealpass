# Biology integrated REDmod-first assembly

Status: **1.0.0 local release: exact build, startup output and install/removal lifecycle passed; native gameplay observations remain separate**
Target game: Cyberpunk 2077 `2.31`  
Canonical builder: `tools/Build-BiologyPackage.ps1`

## Purpose

This document describes the current integrated package architecture and direct evidence already obtained. Biology remains REDmod-first and self-contained, but W13 proved that the post-W11 dependency reduction removed a startup task runner that redscript still needs when RED4ext/CET are absent.

## What has been proven

The **DEPLOYMENT FOUNDATION ACCEPTED** milestone remains established historical
evidence. The current local release extends it with source/build/install/startup
checks while preserving the native observation boundaries below.

The earlier exact integrated candidate built from `8cf045664b5e4d8b4b014edfc98bf2f8eb270ba5` proved exact compilation, installation, official REDmod recognition of `Biology`, and real five-stage REDmod deployment on Cyberpunk 2077 2.31.

W10/W11 then correctly removed Mod Settings, ArchiveXL, and RED4ext from production because Biology no longer has a settings/provider consumer for that stack. A later exact candidate, source revision `68b50ed9e3c629ca252326918dbbb68b9bc35494`, was installed and REDmod-deployed successfully but had no material Biology runtime effect.

W13 read-only installed evidence proved the first broken boundary was not Biology source placement, the activation marker, UI, or gameplay hooks:

- the schema-2 receipt was exact and all 75 payload files hash-verified;
- all 62 current Biology REDscript sources were installed;
- `engine/tools/scc.exe`, `scc_lib.dll`, `scripts.ini`, and `r6/config/cybercmd/scc.toml` were current;
- `scc.toml` configured `InvokeScc` and `r6/cache/modded/final.redscripts`;
- that configured compiled blob was stale from before the candidate install;
- neither `bin/x64/plugins/cybercmd.asi` nor RED4ext existed to execute the configured startup task.

Therefore W13 repairs the missing startup/compiler integration boundary rather than changing downstream Biology runtime behavior.

## Canonical package shape

Biology is REDmod-first, not REDmod-only:

- `mods/Biology` is the official first-party REDmod identity and whole-mod activation marker owner;
- Biology-owned additive/wrapper REDscript remains under `r6/scripts/CyberpunkRealism` where classified `REDSCRIPT-BETTER`;
- `redscript 0.5.31` supplies SCC plus the `r6/config/cybercmd/scc.toml` startup compilation task;
- standalone `cybercmd 0.0.13` is retained only to execute that existing `InvokeScc` task when RED4ext/CET are absent;
- **redscript + cybercmd are the complete retained generic runtime plumbing**;
- Mod Settings, ArchiveXL, and RED4ext remain removed from the production package path;
- every installed file is individually owned/hashed/attributed;
- generic redscript/cybercmd files are `generic-dependency-shared` and preserved by the normal player uninstaller;
- shared roots are never recursively Biology-owned;
- no Dark Future or Project E3 runtime content ships.

The canonical build command remains:

```powershell
pwsh ./tools/Build-BiologyPackage.ps1 `
  -GameRoot 'C:\Games\Steam\steamapps\common\Cyberpunk 2077'
```

For attended preparation, prefer the higher-level canonical operator flow in `LOCAL-OPERATOR-COMMANDS.md`.

## Exact compilation remains a hard artifact gate

`Build-BiologyPackage.ps1` constructs the complete accepted Biology runtime and exact-compiles the REDscript sources against the installed supported Cyberpunk 2077 2.31 `final.redscripts` before emitting a playable ZIP.

That offline compile proves source/language compatibility. It does **not** prove the installed startup task executed. W13 therefore adds a separate live gate: after installation and supported launch, `r6/cache/modded/final.redscripts` must be regenerated for the exact current payload by the packaged redscript/cybercmd startup path.

## Current generic dependencies

| Component | Status | Current reason | Direction |
| --- | --- | --- | --- |
| official REDmod | required platform | package/deploy/enable authority and launcher activation marker | retain; game-provided |
| redscript `0.5.31` | direct required runtime | Biology-owned additive/wrapper runtime/UI/native seams plus save-backed ScriptableSystem state; supplies SCC and `scc.toml` | retain while these accepted seams remain |
| cybercmd standalone `0.0.13` | direct required startup plumbing | executes redscript's `scc.toml` `InvokeScc` task and regenerates configured `r6/cache/modded/final.redscripts` without RED4ext/CET | retain only while this startup boundary is required |
| Mod Settings `0.2.21` | **removed** | no current consumer; replaced by Biology-owned save persistence/UI | absent from production artifact |
| ArchiveXL `1.27.3` | **removed** | former transitive Mod Settings dependency; no direct Biology consumer | absent from production artifact |
| RED4ext `1.30.0` | **removed** | former settings-stack plumbing; broader than the startup task W13 needs | absent from production artifact |

Also not required: TweakXL, Codeware, Input Loader, Dark Future runtime, Project E3 runtime.

`tools/Build-OwnedRuntimeProfile.ps1` acquires/stages exactly redscript + cybercmd. `Build-BiologyPackage.ps1` expects exactly those two generic components and fails closed if a retired or blocked component enters the artifact. cybercmd is never Biology activation authority or gameplay/presentation policy owner.

## Self-contained settings

The remaining public preference is `presentation.e3-first-person-hud-visuals`.

- persistence: `CRRealpassSettings.e3FirstPersonHudVisuals`, a persistent Biology `ScriptableSystem` Bool stored through the Cyberpunk save lifecycle;
- editor: Biology-owned Ink control on the existing Biology/Cyberware body screen;
- whole-mod activation: REDlauncher/REDmod sentinel only;
- external settings provider: none;
- pause-menu provider registration: none.

There is no saved `Enable Biology` Boolean. redscript/cybercmd may exist or load while launcher mods are OFF, but they cannot activate Biology without the REDmod-owned marker.

## Ownership and hard uninstall

`biology/build-manifest.json` is the exact installed-file ownership record. Ordinary payload entries include relative path, SHA-256, owner, component, route, and replacement policy.

The uninstaller contract records `savePolicy = never-target` and `preferencePolicy = stored-in-save-never-target`. Because preferences are save-backed, `Uninstall Biology.exe` does not edit any third-party settings file or expose a provider-specific preference-removal checkbox.

The two retained generic dependencies, redscript and cybercmd, remain shared/preserved by normal player uninstall. Shared roots such as `bin`, `archive`, `engine`, `mods`, `r6`, and `red4ext` may never be deleted recursively; mentioning `red4ext` here is a deletion-safety boundary, not a Biology dependency.

## Deterministic REDmod deployment

The supported game-provided REDmod tool remains the deployment and activation authority. Use `tools/Deploy-BiologyRedmod.ps1` for deterministic developer/probe deployment rather than reconstructing raw command quoting.

cybercmd does not replace REDmod. Its only role is startup execution of redscript's compiler task. REDmod continues to own Biology package recognition/deployment and the launcher activation marker.

## Current direct-game gates

Already accepted:

- official REDmod executable/version/module contract;
- Biology REDmod recognition;
- real five-stage Biology deployment;
- exact post-install evidence proving the pre-W13 runtime failure was stale configured REDscript output with no task runner, not missing Biology sources.

The #152 local completion run directly passed exact 65-source compilation, current
packaged cybercmd/redscript startup-output regeneration, actual shipped-binary
upgrade/reinstall/removal/clean reinstall and REDmod refresh. The exact evidence
and limits are in `evidence/AUTONOMOUS-COMPLETION-2026-09-20.md`.

The original broader native acceptance scope remains below for traceability;
completed local items must not be mistaken for an outstanding W13 worker task:

- exact compile of the combined integrated candidate against supported 2.31;
- packaged standalone cybercmd loads on supported launch and executes redscript's `InvokeScc` task;
- `r6/cache/modded/final.redscripts` is regenerated at/after the exact installed candidate payload;
- REDlauncher ON/OFF and launcher-OFF Biology-inactive behavior with redscript/cybercmd infrastructure remaining non-authoritative;
- no Biology-owned blank/dead settings row or settings-stack DLL warning;
- E3 preference body-shell interaction and save/reload persistence;
- OFF -> ON preservation of E3 preference/state;
- self-contained hard uninstall and residue verification while preserving shared redscript/cybercmd;
- safe REDmod overlap/precedence fixture;
- live body runtime, Biology shell, E3 presentation, and broader gameplay acceptance.

## Testing mode

The W13 dependency milestone is historical. The #152 owner directive authorizes
receipt-bounded local iteration with the accounted-for installed T007 package.
No new Steam reinstall, worker handoff or owner-run test is required for this run.

## Source of current work

Current branch ownership and acceptance criteria live in root `ROADMAP.md`, `ACTIVE-REDMOD-ROADMAP.md`, current GitHub issues/PRs, `THREAD-LEDGER.md`, and the latest relevant `docs/test-runs/` record.
