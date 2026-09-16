# Player disable / uninstall contract

Status: **IMPLEMENTED; W10 settings-stack exit integrated in source — attended acceptance remains parent-owned**  
Issues: #44, #61  
Target game: Cyberpunk 2077 `2.31`

## Product contract

Biology has three distinct player states:

1. **REDlauncher Enable mods ON** — Biology's REDmod-owned activation signal is available and Biology may run.
2. **REDlauncher Enable mods OFF** — Biology behavior is inactive and adapters yield to native Cyberpunk behavior without uninstalling Biology. Saves, Biology state and the E3 presentation preference remain intact.
3. **Hard uninstall** — with the game closed, a normal player double-clicks `Uninstall Biology.exe` from the game root. No PowerShell, Git, Vortex, mod manager, or Cyberpunk reinstall is required.

REDlauncher/REDmod is the sole public whole-mod activation boundary. There is no second persisted Biology master preference. Disable is not uninstall. Uninstall is not save rollback.

## Launcher-OFF runtime audit

The integrated candidate is REDmod-first but not REDmod-only. Biology-owned loose REDscript and redscript infrastructure **may still load** while the Biology REDmod package is disabled, so neither can be activation authority.

| Package/runtime family | Location in current artifact | Can exist/load with REDlauncher mods OFF? | Biology-off implication |
| --- | --- | --- | --- |
| Biology REDmod package | `mods/Biology/**` | REDmod-controlled; this is launcher authority | Owns the activation marker. Marker absent means Biology inactive. |
| Biology supplemental REDscript | `r6/scripts/CyberpunkRealism/*.reds` | **Yes / must be assumed yes.** | Every behavior accessor must fail closed when the REDmod activation marker is absent. |
| redscript | `engine/**`, `r6/config/cybercmd/**` | **Yes / must be assumed yes.** | May still compile/load loose Biology scripts. It is not activation authority. |
| Biology persistent ScriptableSystem/save state | Cyberpunk save/runtime state | May remain across disable/re-enable | State/preferences may remain stored, but Biology behavior cannot activate while the launcher marker is absent. |
| Mod Settings / ArchiveXL / RED4ext | **not bundled by current W10 architecture** | N/A for the new artifact | No production consumer or activation role remains. |
| TweakXL / Codeware / Input Loader | not bundled | N/A | No activation role. |
| Dark Future / Project E3 runtime | blocked from package | N/A | No runtime authority. |

The pre-W10 attended launcher-OFF artifact did still contain ArchiveXL/RED4ext/Mod Settings and produced an ArchiveXL Windows Security warning plus a blank/inert pause-menu settings space. Those observations are evidence against retaining the old stack, not evidence about the new redscript-only candidate.

## Activation mechanism

The official Biology REDmod package owns one inert TweakDB marker:

```text
mods/Biology/tweaks/base/gameplay/static_data/database/items/weapons/parts/biology_activation.tweak
Items.BiologyLauncherActivationMarker.stackable = true
```

`CRRealpassSettings.IsLauncherActivated()` reads that value. `CRRealpassSettings.IsEnabled(game)` now returns only that launcher activation state.

The save-persistent E3 presentation preference remains subordinate to `IsEnabled`; it is not a second activation mechanism. This is deliberately a session/deploy boundary rather than a polling watcher.

P01.1 still owns attended proof that the exact integrated marker disappears/reappears as expected through supported REDlauncher OFF/ON flow.

## Self-contained E3 preference

The only normal in-game public preference is `presentation.e3-first-person-hud-visuals`.

- storage: `public persistent let e3FirstPersonHudVisuals: Bool` in Biology's `CRRealpassSettings` ScriptableSystem;
- scope: current Cyberpunk save;
- editor: a Biology-owned Ink control on the existing Biology/Cyberware body screen;
- semantics: presentation-only;
- external provider: none;
- pause-menu provider registration: none.

The old `ModSettings.runtimeProperty` adapter/module listener has been removed. Biology therefore no longer owns a Mod Settings row that can become an empty/inert pause-menu placeholder.

## Player uninstaller architecture

The release-shaped package contains one player-facing binary at its root:

```text
Uninstall Biology.exe
```

Source/toolchain:

- deterministic planner/executor: `src/uninstaller/BiologyUninstallCore.cs`;
- WinForms front-end/self-relocation: `src/uninstaller/BiologyUninstallerProgram.cs`;
- build helper: `tools/Build-BiologyUninstaller.ps1`;
- output: one EXE, no PowerShell/script/runtime sidecar required for the player workflow.

The installed EXE first verifies that it is the packaged root binary and that the receipt is valid, copies itself to a temporary location so the original can be removed, then presents the uninstall UI from the temporary copy.

## Receipt and deletion planner

`biology/build-manifest.json` is schema 2 and is packaged with the same artifact as the EXE. Every payload file records relative path, SHA-256, owner, component, route, and uninstall/replace policy.

Two policies are allowed:

- `biology-owned` — eligible for automatic deletion only when the current SHA-256 matches **and** the path is in Biology's narrow hard-coded allowlist;
- `generic-dependency-shared` — inventoried for package/update accounting but always preserved by the normal player uninstaller.

The receipt's uninstall policy now states:

```text
savePolicy = never-target
preferencePolicy = stored-in-save-never-target
```

There is no provider path/section metadata because no provider file is used.

## Directories, saves and preferences

There is no recursive directory deletion. The executor removes only now-empty descendants of `mods/Biology`, `r6/scripts/CyberpunkRealism`, and `biology`. It never recursively owns/deletes shared roots including `mods`, `r6`, `engine`, `bin`, `red4ext`, `archive`, or `LICENSES`.

Cyberpunk save locations are never part of the receipt or deletion allowlist. Because the E3 preference is stored in save state, preserving saves automatically preserves that preference. The uninstaller exposes no preference-removal checkbox and contains no Mod Settings INI surgery.

A safety reference to `red4ext` as a shared root is not a runtime dependency claim; it prevents a malformed receipt from authorizing broad deletion on an installation where some other mod owns that root.

## Generic dependency removal policy

Normal player uninstall preserves the one bundled generic dependency, **redscript**, even when its hashes still match Biology's release. The uninstaller cannot reliably prove that another installed mod does not require it, so automatic removal would be unsafe.

Mod Settings, ArchiveXL, and RED4ext are not packaged by the W10 production path, so there is nothing from those components for the new Biology uninstaller to preserve or remove.

## REDmod refresh after hard uninstall

The player front-end performs exact-file removal first, then checks whether Biology-specific namespaces still contain residual content. It invokes the official REDmod tool only when `mods/Biology` is actually gone. If changed, untracked, or otherwise unresolved content keeps `mods/Biology` present, REDmod refresh is deliberately withheld and the result is reported as a partial uninstall requiring manual review.

For a clean removal, the refresh uses the official supported tool with an explicit root:

```text
tools/redmod/bin/redMod.exe deploy -root=<Cyberpunk 2077>
```

The uninstaller never recursively deletes `r6/cache/modded` or another shared REDmod cache root. W09.1 / issue #59 owns post-uninstall REDmod output-cache recovery; W10 does not redesign that mechanism.

## Package changes from W10

`tools/Build-BiologyPackage.ps1` now emits a release-shaped ZIP containing:

- official `mods/Biology/info.json` and activation marker tweak;
- exact-compiled Biology REDscript runtime;
- pinned redscript as the only generic runtime dependency;
- schema-2 ownership receipt/provenance;
- `Uninstall Biology.exe`;
- package instructions/version/checksums;
- redscript license notice.

It fails closed if Mod Settings, ArchiveXL, RED4ext, TweakXL, Codeware, Input Loader, Dark Future, or Project E3 runtime content leaks into the artifact.

## Automated safety tests

`tests/Test-PlayerUninstaller.ps1` compiles/runs `tests/BiologyUninstallCoreTests.cs` on Windows CI. Cases include exact-hash Biology deletion, unchanged/changed generic redscript preservation, unrelated mod/save preservation, changed-file refusal, change-after-planning refusal, unsafe-path and duplicate rejection, malformed policy rejection, forged game-file ownership rejection, save-backed preference-policy validation, bounded empty-directory cleanup, and REDmod refresh result classification.

`tests/Test-SelfContainedSettings.ps1` independently asserts that production settings/uninstaller source contains no Mod Settings provider path/adapter, the public preference surface remains exactly one Boolean, launcher activation remains separate, release staging is redscript-only, and the three retired dependencies remain absent from active distribution/install contracts.

## Attended checks still required

Cloud CI and source contracts do **not** close live acceptance. P01.1 owns attended integration acceptance of the exact merged artifact, including:

1. REDlauncher Enable mods ON: Biology is active.
2. REDlauncher Enable mods OFF + relaunch: Biology UI/gameplay/presentation hooks are inactive/native with only redscript supplemental infrastructure installed.
3. Launcher OFF produces no Biology-owned blank/dead settings row and no warning caused by Biology-packaged ArchiveXL/RED4ext files.
4. E3 preference can be changed from the Biology body shell and persists across save/reload.
5. OFF -> ON + relaunch preserves the E3 preference and Biology state while restoring Biology behavior.
6. Double-click `Uninstall Biology.exe`: exact Biology-owned files are removed, saves/preference remain, redscript is preserved.
7. Changed Biology-owned fixture remains fail-closed/manual-review safe.
8. Another harmless REDmod is preserved/redeployed correctly after clean Biology removal.
9. No stale Biology activation/behavior remains after hard uninstall/official refresh.
10. Normal game launch/save load after hard uninstall remains healthy.

W09.1 remains the owner of issue #59 post-uninstall deploy/output recovery. PKG-05 overlap/precedence and feature-specific body/UI/presentation acceptance remain outside W10.
