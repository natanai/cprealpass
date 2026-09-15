# Player disable / uninstall contract

Status: **IMPLEMENTED IN PLAYER-UNINSTALL LANE — attended acceptance still required**  
Issue: #44  
Draft PR: #45  
Target game: Cyberpunk 2077 `2.31`

## Product contract

Biology has three distinct player states:

1. **REDlauncher Enable mods ON** — Biology's REDmod-owned activation signal is available. Biology may run, subject to the existing Biology master preference.
2. **REDlauncher Enable mods OFF** — Biology behavior is inactive and adapters yield to native Cyberpunk behavior without uninstalling Biology. Saves, Biology state and Biology preferences remain intact.
3. **Hard uninstall** — with the game closed, a normal player double-clicks `Uninstall Biology.exe` from the game root. No PowerShell, Git, Vortex, mod manager, or Cyberpunk reinstall is required.

Disable is not uninstall. Uninstall is not save rollback.

## Launcher-OFF runtime audit

The integrated candidate is REDmod-first but not REDmod-only. Therefore launcher OFF cannot be implemented by assuming every supplemental path disappears.

| Package/runtime family | Location in current artifact | Can exist/load with REDlauncher mods OFF? | Biology-off implication |
| --- | --- | --- | --- |
| Biology REDmod package | `mods/Biology/**` | REDmod-controlled; this is the launcher authority | Owns the activation marker. Marker absent means Biology inactive. |
| Biology supplemental REDscript | `r6/scripts/CyberpunkRealism/*.reds` | **Yes / must be assumed yes.** These files are outside `mods/Biology`. | Every behavior accessor must fail closed when the REDmod activation marker is absent. |
| redscript | `engine/**`, `r6/config/cybercmd/**` | **Yes / must be assumed yes.** | May still compile/load loose Biology scripts. It is not activation authority. |
| RED4ext | `bin/x64/winmm.dll`, `red4ext/**` | **Yes / must be assumed yes.** | Generic loader may remain active. It is not activation authority. |
| ArchiveXL | `red4ext/plugins/ArchiveXL/**`, hints | **Yes / must be assumed yes.** | Generic/transitive settings plumbing only. It is not activation authority. |
| Mod Settings | `red4ext/plugins/mod_settings/**` | **Yes / must be assumed yes.** | A persisted Biology `enabled=true` preference cannot override launcher OFF. |
| Biology persistent ScriptableSystem/save state | Cyberpunk save/runtime state | May remain across disable/re-enable | State may remain stored, but hooks cannot mutate/use it while the launcher marker is absent. |
| TweakXL / Codeware / Input Loader | not bundled by current integrated candidate | N/A for this artifact | No activation role. |
| Dark Future / Project E3 runtime | blocked from package | N/A | No runtime authority. |

The audit therefore rejects the unsafe proposition “REDmod disabled => redscript/RED4ext/ArchiveXL/Mod Settings are disabled.” The contract instead uses one REDmod-owned signal as the necessary condition for all Biology behavior.

## Activation mechanism

The official Biology REDmod package now owns one inert TweakDB marker:

```text
mods/Biology/tweaks/base/gameplay/static_data/database/items/weapons/parts/biology_activation.tweak
Items.BiologyLauncherActivationMarker.stackable = true
```

`CRRealpassSettings.IsLauncherActivated()` reads that value. `CRRealpassSettings.IsEnabled(game)` is now:

```text
launcher marker present/true AND existing Biology master preference enabled
```

If the marker is absent or false, `IsEnabled` returns false before consulting a persisted preference. The existing E3 presentation preference remains subordinate to `IsEnabled`; it is not a second activation mechanism.

This is deliberately a session/deploy boundary rather than a polling watcher. Attended testing must still prove that the exact marker tweak compiles/deploys under REDmod 2.31 and disappears/reappears as expected through the supported launcher OFF/ON flow.

### Narrow overlap with #39 / #40 / #41

This lane changes only the shared provider-neutral activation accessor in `RealpassSettings.reds`. It does **not** redesign Biology UI (#39), E3 HUD/nameplates (#40), or body runtime authority (#41). Existing body/runtime and presentation adapters already consume `CRRealpassSettings.IsEnabled(...)` / `UseE3FirstPersonHudVisuals(...)`, so no #39/#40/#41 feature implementation is taken over here.

## Player uninstaller architecture

The release-shaped package now contains exactly one player-facing binary at its root:

```text
Uninstall Biology.exe
```

Source/toolchain:

- deterministic planner/executor: `src/uninstaller/BiologyUninstallCore.cs`;
- WinForms front-end/self-relocation: `src/uninstaller/BiologyUninstallerProgram.cs`;
- build helper: `tools/Build-BiologyUninstaller.ps1`;
- compiler: Windows .NET Framework `csc.exe` already present on the supported Windows build/runtime environment;
- output: one EXE, no PowerShell/script/runtime sidecar required for the player workflow.

The installed EXE first verifies that it is the packaged root binary and that the receipt is valid, copies itself to a temporary location so the original can be removed, then presents the uninstall UI from the temporary copy.

## Receipt and deletion planner

`biology/build-manifest.json` is schema 2 and is packaged with the same artifact as the EXE. Every payload file records relative path, SHA-256, owner, component, route, and uninstall/replace policy.

Two policies are allowed:

- `biology-owned` — eligible for automatic deletion only when the current SHA-256 matches **and** the path is in Biology's narrow hard-coded allowlist;
- `generic-dependency-shared` — inventoried for package/update accounting but always preserved by the normal player uninstaller.

The executable separately constrains Biology-owned deletion to `mods/Biology/**`, `r6/scripts/CyberpunkRealism/**`, `biology/**` metadata, and exact package root files `INSTALL.txt`, `UNINSTALL.txt`, `BIOLOGY-VERSION.txt`, `SHA256SUMS.txt`, `Uninstall Biology.exe`.

A receipt therefore cannot authorize automatic deletion of `Cyberpunk2077.exe`, a save, a generic framework file, or an arbitrary shared path merely by labeling it “Biology.”

The planner rejects empty, rooted, UNC, traversal, alternate-data-stream/colon and case-insensitive duplicate paths. At execution time every candidate is re-hashed immediately before deletion, closing the plan/execute race. Changed Biology files are preserved and reported. If changed/failed Biology-owned files remain, the ownership receipt itself is preserved for manual review.

## Directories, saves and preferences

There is no recursive directory deletion. The executor removes only now-empty descendants of `mods/Biology`, `r6/scripts/CyberpunkRealism`, and `biology`. It never recursively owns/deletes shared roots including `mods`, `r6`, `engine`, `bin`, `red4ext`, `archive`, or `LICENSES`.

Cyberpunk save locations are never part of the receipt or deletion allowlist.

Biology preferences are **preserved by default**. The uninstaller exposes one unchecked opt-in: remove only the `[CyberpunkRealism.Settings.CRRealpassSettings]` section from `red4ext/plugins/mod_settings/user.ini`. Other Mod Settings sections are retained. This matches the current upstream Mod Settings persistence path and remains temporary plumbing while the presentation/settings-provider blocker exists.

## Generic dependency removal policy

Normal player uninstall preserves all bundled generic dependencies (`redscript`, RED4ext, ArchiveXL, Mod Settings and their packaged license snapshots), even when their hashes still match Biology's release. The uninstaller cannot reliably prove that another installed mod does not require them, so automatic removal would be unsafe.

This is intentionally more conservative than the developer clean-room reset. `Reset-BiologyIteration.ps1` has a whole-game pre-install vanilla baseline and may delete an exact generic file only when that baseline proves the file did not exist before the Biology iteration. A generic path that pre-existed is preserved; the subsequent full baseline comparison remains the authority.

## REDmod refresh after hard uninstall

After Biology-owned payload removal, the uninstaller invokes the official supported tool with an explicit root:

```text
tools/redmod/bin/redMod.exe deploy -root=<Cyberpunk 2077>
```

Refresh outcomes are fail-closed:

- if other `mods/*/info.json` REDmods remain, success requires REDmod to report a completed deploy stage;
- if no other REDmods remain, the official `No mods found, no deployment is needed` outcome is accepted;
- nonzero exit, wrong-root evidence, missing official executable, or ambiguous success is reported as a refresh failure/manual-review condition.

The uninstaller never recursively deletes `r6/cache/modded` or any other shared REDmod cache root. Attended hard-uninstall acceptance must prove that no stale Biology marker/behavior survives the official refresh.

## Package changes

`tools/Build-BiologyPackage.ps1` now emits one exact release-shaped ZIP containing official `mods/Biology/info.json`, the REDmod activation marker tweak, exact-compiled Biology REDscript runtime, currently retained generic dependencies, schema-2 ownership receipt/provenance, `Uninstall Biology.exe`, and package instructions/version/checksums/licenses.

The binary is compiled directly into the staging root **before** its SHA-256 is recorded. `SHA256SUMS.txt` hashes finalized pre-receipt payload; the owner receipt then inventories/hash-pins every removable/preserved payload file. The receipt cannot self-hash, so the executable independently enforces schema/product/policy/path constraints and re-hashes the receipt during execution.

## Automated safety tests

`tests/Test-PlayerUninstaller.ps1` compiles/runs `tests/BiologyUninstallCoreTests.cs` on Windows CI. Cases include happy exact-hash Biology deletion, generic/shared dependency preservation, unrelated mod and save preservation, changed-file refusal, change-after-planning refusal, missing-file reporting, unsafe-path and case-insensitive duplicate rejection, non-Biology receipt rejection, forged game-executable ownership rejection, generic dependency owner validation, surgical preference removal, and REDmod refresh success/failure classification.

`tests/Test-PlayerDisableContract.ps1` separately asserts launcher marker/accessor/package coupling and that the package builder includes both the marker and uninstaller.

## Attended checks still required

CI, C# planner tests and exact REDscript compilation do **not** close live acceptance. Parent integration must test the exact merged artifact in MILESTONE CLEAN-ROOM mode and record:

1. REDmod 2.31 compiles/deploys the activation tweak.
2. REDlauncher Enable mods ON: Biology is active.
3. REDlauncher Enable mods OFF + relaunch: Biology UI/gameplay/presentation hooks are inactive/native even though supplemental REDscript/framework files remain installed.
4. OFF -> ON + relaunch: Biology returns and preserved Biology preference/state behaves as intended.
5. Double-click `Uninstall Biology.exe`: no shell/dev tooling required; exact Biology-owned files are removed, saves remain, preferences remain by default, generic/shared dependencies remain.
6. Repeat with opt-in preference removal: only Biology's Mod Settings section is removed.
7. Changed Biology-owned fixture: uninstaller refuses that file and preserves the receipt/manual-review evidence.
8. Another harmless REDmod installed: uninstall refresh redeploys it and does not remove/disable it.
9. No other REDmods installed: official no-mod refresh outcome leaves no stale Biology activation/behavior without recursive cache deletion.
10. Normal game launch/save load after hard uninstall remains healthy.

PKG-05 overlap/precedence and the feature-specific acceptance owned by #39/#40/#41 remain outside this lane.
