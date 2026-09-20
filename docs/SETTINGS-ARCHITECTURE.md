# Biology configuration architecture

Status: **canonical self-contained settings contract; attended persistence/launcher-off acceptance remains parent-owned**  
Last updated: 2026-09-15

## Goal

Biology is one authored physical simulation. Its normal in-game preference surface now contains exactly **one editable Boolean**:

- **E3-inspired HUD + nameplates** — presentation-only. While Biology is active, this controls the Biology-owned red/minimal E3-inspired first-person HUD and NPC-nameplate layer. It does not change body state, injury, combat, armor, pain, treatment, recovery, the Biology-wide actor-healthbar policy, or the modern scanner/quickhack interface.

There is no second persisted **Enable Biology** preference. REDlauncher/REDmod is the public whole-product ON/OFF boundary. Internal development gates may still isolate authorities for compilation/calibration/diagnosis; they are not player preferences.

## REDlauncher is the whole-mod activation boundary

The player release distinguishes three states:

1. **REDlauncher Enable mods ON** -> the Biology REDmod activation marker is present and Biology may run.
2. **REDlauncher Enable mods OFF** -> target Biology-inactive vanilla-play behavior without uninstalling the package.
3. **Uninstall Biology.exe** -> hard removal of safely proven Biology-owned files.

`CRRealpassSettings.IsEnabled(game)` is retained as the provider-neutral runtime accessor, but it now resolves only from `CRRealpassSettings.IsLauncherActivated()`. No save-persistent Boolean can override an absent launcher marker.

Disabling Biology is not permission to erase/refill persistent Biology body state or delete saves.

## Biology-owned persistence and editor

The external settings-provider stack has been removed from production architecture.

`CRRealpassSettings` remains a `ScriptableSystem` and owns one persistent field:

```text
public persistent let e3FirstPersonHudVisuals: Bool = true;
```

That field is stored through Cyberpunk's save lifecycle. Biology does not create a parallel INI/config authority for the preference.

The player edits the Boolean from a small Biology-owned control mounted on the existing Biology/Cyberware body screen (`RipperDocGameController`). Biology does **not** register a row in the pause-menu Mod Settings surface or depend on a third-party settings screen.

This intentionally avoids invasive ownership of Cyberpunk's native settings screen. The existing Biology body screen is already a first-party Biology interaction surface and requires only a narrow Ink control to edit the one remaining preference.

## Dependency exit

Issue #61 removes the former settings stack from Biology production release/build/install architecture:

- Mod Settings — removed; no production source adapter/provider registration remains;
- ArchiveXL — removed; its only Biology role was transitive support for Mod Settings;
- RED4ext — removed; its only Biology role was transitive support for the retired settings stack and Biology owns no RED4ext plugin.

redscript remains for current Biology-owned additive/wrapper runtime, ScriptableSystem persistence, Ink UI, and native hook seams. Its full elimination is a separate future architecture question and is not hidden inside settings work.

## Blank pause-menu gap

The previous blank/inert pause-menu space was associated with a Mod Settings provider surface that remained installed/registered while launcher mods were unavailable or blocked.

The new Biology package contains no Mod Settings runtime, no Biology `ModSettings.runtimeProperty` declarations, no module-existence provider registration, and no Biology pause-menu settings registration. Therefore Biology no longer creates or owns a provider row that can become an empty clickable placeholder when REDlauncher mods are OFF.

Attended launcher-OFF validation remains required to prove that an exact integrated artifact no longer produces the observed gap or framework-security warning on the supported install.

## Current attended evidence

Historical pre-REDmod settings evidence remains in `PRE-REDMOD-LIVE-BASELINE-2026-09-15.md`; it is not the current implementation status.

The previous integrated artifact built from `8cf045664b5e4d8b4b014edfc98bf2f8eb270ba5` established that the E3 preference gated at least part of the presentation path, but it also exposed the now-retired framework/menu residue during launcher-OFF testing. That artifact pre-dates the self-contained settings migration and must not be treated as acceptance of this replacement persistence/UI path.

Issue #40 remains responsible for the broader E3 presentation implementation. P01.1 remains responsible for attended launcher-OFF and save/reload persistence acceptance of the exact integrated W10 architecture.

## Release behavior

With Biology active, the authored release keeps accepted physical authorities together:

```text
body = on
injury = on
combat = on
armor = on
cyberware physiology = on where implemented
presentation authority = on
diagnostics = off
native modern scanner = on
traditional actor HP bars = off
E3-inspired first-person HUD/nameplates = controlled only by the presentation preference
```

Two players on the same Biology version with Biology active therefore receive the same damage, ballistics, armor, injury, physiology, pain, treatment, and recovery rules regardless of the E3 visual preference.

The E3 preference may only yield Biology's E3-specific visual skin/nameplate treatment. It must not turn off physical simulation or re-enable actor HP bars.

## Public preference identifier

### `presentation.e3-first-person-hud-visuals`

- type: Boolean;
- default: `true`;
- persistence: Biology-owned `ScriptableSystem` field in the Cyberpunk save;
- editor: Biology-owned control on the Biology/Cyberware body screen;
- presentation-only;
- meaningful only while Biology is active;
- gates the Biology-owned E3-inspired HUD/nameplate layer;
- does not alter the Biology-wide healthbar policy;
- does not replace or restyle the modern scanner into Project E3's old scanner.

`biology.enabled` and legacy `realpass.enabled` are not public settings. Whole-mod activation belongs to REDlauncher/REDmod.

Pain/disorientation, injury effects, and other authored body feedback are not separate player settings.

## What players may never tune

The normal preference surface must not expose:

- a second whole-mod in-game enable switch;
- separate body/injury/combat/armor/cyberware-physiology enable switches;
- damage multipliers;
- hunger/hydration rates;
- bleeding multipliers;
- pain/analgesia scales;
- armor/protection scaling;
- MaxDoc dose/decay thresholds;
- recovery speed;
- cosmetic-transmog authority;
- diagnostics;
- a read-only managed feature ledger presented as settings;
- Float/Int balance controls.

## Actor-health presentation

While Biology is active, traditional actor HP bars/HP-number feedback remain suppressed where technically safe. This is independent of the E3 presentation preference.

The native fallback boundary may restore normal actor-health presentation when Biology as a whole is inactive. Turning only E3 visuals OFF must not restore traditional HP bars.

## External Project E3 boundary

Project E3 is design/controller archaeology only. The product target is Biology-owned presentation:

- red/minimal E3-inspired ordinary first-person HUD;
- ambient E3-inspired NPC nameplates;
- scanner-acquired identity may enrich ordinary nameplate information through native knowledge authority;
- native modern scanner/quickhack retained;
- no Project E3 scripts/archive/tweaks/settings/save state required or shipped.

## Acceptance criteria

Configuration is accepted only when:

1. player-facing identity is **Biology**;
2. the only normal in-game public preference is the E3 presentation Boolean;
3. no subsystem/balance/diagnostic/feature-ledger controls appear;
4. REDlauncher/REDmod is the sole whole-mod public activation boundary;
5. the E3 preference is read/written through Biology's save-backed ScriptableSystem rather than a third-party provider;
6. Biology registers no external pause-menu/provider row;
7. REDlauncher Enable mods OFF is directly proven to yield Biology-inactive vanilla-play behavior before that path is advertised as accepted;
8. E3 ON/OFF changes only Biology's E3-specific HUD/nameplate treatment and persists across save/reload;
9. the modern scanner/quickhack interface remains native and usable;
10. traditional actor HP presentation stays suppressed while Biology is active regardless of E3 preference;
11. Project E3 runtime remains absent;
12. Mod Settings, ArchiveXL, and RED4ext remain absent from production package/build/install contracts unless a future independently accepted consumer is documented first.
