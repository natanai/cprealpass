# Biology configuration architecture

Status: **canonical public-settings contract; provider/launcher-off integration still under #44 acceptance**  
Last updated: 2026-09-15

## Goal

Biology is one authored physical simulation. Its normal player-facing preference surface is intentionally tiny: **at most two editable Boolean settings**.

The semantic controls are:

- **Enable Biology** — the one global master semantic boundary for the complete overhaul when a reliable live switch is retained. It is not permission to expose body/injury/combat/armor/etc. independently.
- **E3-inspired HUD + nameplates** — presentation-only. While Biology is active, this controls the Biology-owned red/minimal E3-inspired first-person HUD and NPC-nameplate layer. It does not change body state, injury, combat, armor, pain, treatment, recovery, the Biology-wide actor-healthbar policy, or the modern scanner/quickhack interface.

Internal development gates may still isolate authorities for compilation/calibration/diagnosis. They are not player preferences.

## REDlauncher disable is the ordinary vanilla-play target

The player release now distinguishes three states:

1. **REDlauncher Enable mods ON** -> Biology package/runtime active.
2. **REDlauncher Enable mods OFF** -> target Biology-inactive vanilla-play behavior without uninstalling the package.
3. **Uninstall Biology.exe** -> hard removal of safely proven Biology-owned files.

Issue #44 owns direct acceptance of the launcher-off and hard-uninstall contract across REDmod plus any supplemental script/framework route.

The launcher-level disable boundary is separate from the in-game/global `Enable Biology` semantic key. If a reliable live master switch remains useful, it may coexist as one whole-mod control. If maintaining it would require disproportionate invasive infrastructure, the product remains all-or-nothing and the official launcher/install boundary may carry whole-mod activation instead. Do **not** replace one global boundary with per-subsystem switches.

Disabling Biology is not permission to erase/refill persistent Biology body state or delete saves.

## Provider is not product architecture

The settings provider is **not locked to Mod Settings**.

Current source still contains a provider-neutral Biology semantic API with a Mod Settings adapter as temporary UI/persistence plumbing. Mod Settings, ArchiveXL, and RED4ext have no permanent entitlement to survive merely because older builds used them.

Preferred dependency direction:

- keep the two semantic controls stable;
- use a Biology-owned surface if it removes the temporary settings stack without increasing fragility;
- or deliberately move whole-mod activation to the official launcher/install boundary where that is more robust;
- remove Mod Settings/ArchiveXL/RED4ext when their last accepted consumer disappears.

Do not preserve a framework stack merely to host two booleans.

## Current attended evidence — integrated REDmod artifact

Historical pre-REDmod settings evidence remains in `PRE-REDMOD-LIVE-BASELINE-2026-09-15.md`. It is not the current implementation status.

The current attended presentation evidence came from the integrated artifact built from:

`8cf045664b5e4d8b4b014edfc98bf2f8eb270ba5`

Artifact:

`biology-integrated-20260915-061136-8cf045664b5e.zip`

SHA-256:

`42BACC73173EB95D84F3278593CD06DDAF665AA714F4C692DB03D553B91557CC`

With **E3-inspired HUD + nameplates ON**:

- ordinary first-person gameplay still read overwhelmingly as the modern retail HUD;
- quest objectives and other ordinary HUD composition had not yet received the intended red/minimal E3-inspired treatment;
- direct look/focus at a random civilian showed no ambient E3-style nameplate;
- police showed only a narrow red strip rather than the complete intended ambient identity treatment;
- the modern scanner/quickhack interface remained intact, which is positive preserve evidence.

With the E3 presentation preference OFF, the narrow police red treatment was absent. This is evidence that the preference gated at least part of the presentation path, but it is **not** acceptance of the full E3 mode.

Issue #40 / PR #46 owns the broader Biology-owned E3 follow-up. Source/CI/exact compile cannot substitute for matched attended E3 ON/OFF screenshots.

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

## Public preference identifiers during migration

Internal/compatibility keys may retain historical names until a safe migration is worthwhile. New player-facing labels use **Biology**.

### `biology.enabled` / legacy compatibility key `realpass.enabled`

- type: Boolean;
- default: `true` when retained as a live runtime preference;
- authority: global master only;
- never exposes internal authorities individually;
- may require a session/save reload when attach-time systems cannot safely change authority in place;
- must not be confused with REDlauncher `Enable mods`, which is the ordinary package-level vanilla-play target.

### `presentation.e3-first-person-hud-visuals`

- type: Boolean;
- default: `true`;
- presentation-only;
- meaningful only while Biology is active;
- gates the Biology-owned E3-inspired HUD/nameplate layer;
- does not alter the Biology-wide healthbar policy;
- does not replace or restyle the modern scanner into Project E3's old scanner.

Pain/disorientation, injury effects, and other authored body feedback are not separate player settings.

## What players may never tune

The normal preference surface must not expose:

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

`config/realpass-e3.json` preserves the local reference inventory/hashes; the actual third-party `ReferenceMods/` payload remains outside Git.

## Acceptance criteria

Configuration is accepted only when:

1. player-facing identity is **Biology**;
2. no more than the whole-mod semantic boundary and E3 presentation preference are exposed as editable public settings;
3. no subsystem/balance/diagnostic/feature-ledger controls appear;
4. the Biology activation boundary remains all-or-nothing;
5. REDlauncher Enable mods OFF is directly proven to yield Biology-inactive vanilla-play behavior before that path is advertised as accepted;
6. E3 ON/OFF changes only Biology's E3-specific HUD/nameplate treatment;
7. ordinary E3 ON gameplay is visibly/recognizably E3-inspired in attended screenshots;
8. civilian/police ambient nameplates work through native identity/visibility authority as designed;
9. the modern scanner/quickhack interface remains native and usable;
10. traditional actor HP presentation stays suppressed while Biology is active regardless of E3 preference;
11. Project E3 runtime remains absent;
12. any surviving settings framework has a current concrete consumer and is removable when that consumer disappears.
