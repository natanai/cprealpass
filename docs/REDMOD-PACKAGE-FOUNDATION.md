# Biology REDmod package/dependency foundation

Issue: #28  
Lane: `agent/redmod-foundation`  
Canonical start: `6fab5ba706e2a10387bb8629cccdb0868533bb97`  
Target game: Cyberpunk 2077 2.31

## Purpose

This lane makes official REDmod the package/deployment authority for Biology without pretending every runtime seam should be rewritten as a REDmod whole-file script replacement.

The target is:

1. one recognizable first-party package at `mods/Biology`,
2. official REDmod deployment/enable/load for REDmod-native content,
3. only narrow supplemental runtime/framework files that a concrete Biology feature still proves necessary,
4. exact per-file install/uninstall ownership,
5. no executing Dark Future or Project E3 payload,
6. no dependency retained merely because it existed in the pre-REDmod baseline.

Machine-readable policy lives in:

- `manifest/redmod-package.json`
- `manifest/redmod-install-contract.json`
- `manifest/dependency-graph.json`
- `manifest/redmod-classification.json`

Direct supported-install evidence is recorded in:

- `docs/evidence/REDMOD-2.31-PROBE-2026-09-15.md`

The pre-refactor `manifest/distribution.json`, `manifest/install-contract.json`, `manifest/package.json`, and clean-room builders remain transitional until PKG-06 is satisfied by an integrated candidate. They are not silently redefined underneath the parallel runtime lanes.

## REDmod facts and direct 2.31 evidence

CD PROJEKT RED's public REDmod support/documentation establishes the package model: REDmod-compatible mods live under `<Cyberpunk 2077>\mods`, use `info.json`, and are deployed through REDmod. The official command-line tool is under `tools\redmod\bin`.

The direct read-only probe on the supported local Cyberpunk 2077 2.31 installation confirmed:

- game root `C:\Games\Steam\steamapps\common\Cyberpunk 2077`,
- executable `tools\redmod\bin\redMod.exe`,
- REDmod file version `2.3.1.0`,
- Cyberpunk product version `2.31`,
- a `deploy` module described by REDmod as compiling installed mods together,
- the global `-root` parameter,
- a clean `mods` directory containing only `.stub` at probe time.

The probe also produced a useful negative result: invoking `redMod.exe --help` without an explicit game root made REDmod default to `C:\` and report that root as invalid. Biology tooling therefore **must always pass `-root=<Cyberpunk 2077>` explicitly**. Working-directory/default-root behavior is not part of Biology's deterministic contract.

Sources for upstream semantics:

- https://www.cyberpunk.net/en/modding-support
- https://cdn-l-cyberpunk.cdprojektred.com/REDmod-docs.pdf
- https://github.com/CDPR-Modding-Documentation/Cyberpunk-Modding-Docs/blob/main/for-mod-creators-theory/modding-tools/redmod/README.md
- https://github.com/CDPR-Modding-Documentation/Cyberpunk-Modding-Docs/blob/main/for-mod-creators-theory/modding-tools/redmod/script-modding.md

The direct probe resolves the exact installed CLI/version question. It does **not** by itself prove that Biology is recognized/deployed, that enablement survives relaunch, or that two overlapping REDmods resolve in the documented order. Those remain separate attended/direct-game gates.

## Official package identity

The canonical REDmod identity is:

```text
mods/
└── Biology/
    └── info.json
```

`mods/Biology/info.json` uses the product-facing name `Biology`. Future first-party REDmod content may be added only to valid REDmod content roots when actual content exists:

```text
mods/Biology/archives
mods/Biology/scripts
mods/Biology/tweaks
mods/Biology/customSounds
```

A content root is not created merely to make the tree look complete.

## Build contract

`tools/Build-RedmodFoundation.ps1` is an offline, release-shaped **foundation** builder. It:

- reads `manifest/redmod-package.json`,
- validates the Biology REDmod identity,
- copies only enumerated first-party REDmod-native files,
- generates installation/uninstallation instructions,
- generates Biology provenance and per-file ownership,
- generates SHA-256 verification data,
- produces a ZIP without reading or modifying the game installation.

The current foundation ZIP is deliberately non-playable. It establishes package/ownership machinery before the parallel runtime lanes contribute the accepted integrated runtime file set. The builder therefore must not pull the old `r6/scripts`, RED4ext, ArchiveXL, or Mod Settings payload into the foundation merely to make it appear complete.

## Install / enable / load workflow

### Player-facing target

1. Install Cyberpunk 2077 and official REDmod support for the player's store/platform.
2. Close Cyberpunk 2077.
3. Install the Biology release so `mods\Biology\info.json` exists under the Cyberpunk game root.
4. Use the supported REDmod enable/deploy flow and allow deployment to finish.
5. After direct persistence acceptance passes, ordinary Steam/supported launch is the normal-play target. Biology does not own or require a permanent custom launcher.

The final release must not tell players to run a repository helper every time they play.

### Developer/diagnostic route

The deterministic command shape is:

```powershell
& '<Cyberpunk 2077>\tools\redmod\bin\redMod.exe' deploy -root='<Cyberpunk 2077>'
```

The executable path, `deploy` module, product/file version, and need for an explicit root are now directly evidenced on the supported 2.31 install. Package recognition/deploy success for Biology itself remains unproven until an actual Biology candidate is exercised.

### Enable/disable semantics

REDmod enable/disable is package activation. It is not save deletion, simulation-state reset, uninstall, or permission to delete shared framework directories.

## Install/uninstall ownership

`manifest/redmod-install-contract.json` makes these first-party roots obvious:

- `mods/Biology`
- `biology` release metadata

The package owner manifest is `biology/build-manifest.json`. Every ordinary installed payload file has a path, SHA-256, owner, component, route, and replacement policy. Shared roots such as `r6`, `engine`, `red4ext`, `archive`, and `bin` are never directory-owned by Biology.

If a future integrated release still needs redscript framework files, it owns only exact pinned files named in the package manifest. Uninstall must never recursively delete a shared root.

If ownership or collision state cannot be proven, iteration reset fails closed and escalates to the milestone clean-room procedure in `docs/CLEAN-ROOM-TESTING.md`.

Because this lane changes package/dependency architecture, broad attended acceptance after integration is a milestone-clean-room event, not merely an iteration reset.

## REDmod load order / overlap evidence

Official REDmod documentation describes REDmod ordering and explicit `-mod=` order semantics, but issue #28 requires supported-install evidence before Biology depends on overlap precedence.

Biology therefore must not rely on a vague "loads last" rule. `manifest/redmod-classification.json` intentionally keeps `redmod-conflict-precedence-on-supported-2.31-install` as:

`UNKNOWN — NEEDS DIRECT GAME PROBE`

until a harmless, reversible two-REDmod fixture is deployed and observed. This remaining gate applies only to REDmod's own package/deploy domain; it does not imply a universal order over redscript wrappers, RED4ext plugins, CET, runtime TweakDB mutation, or unrelated loaders.

## Dependency conclusions

### redscript — retention candidate, not historical entitlement

Current Biology runtime code is project-owned REDscript and its game-facing seams use narrow annotations such as `@wrapMethod`, `@addMethod`, `@replaceMethod`, and `@addField`, enumerated by `manifest/native-seams.json`.

For the current narrow wrappers, replacing whole vanilla script files through REDmod would make Biology own substantially more upstream implementation than the feature needs. That increases patch and mod-conflict surface. Current additive/wrapper seams therefore remain classified `REDSCRIPT-BETTER` unless a feature-specific smaller/safer route is proven.

### Mod Settings — removal candidate

The current `RealpassSettings.reds` surface contains only the global master preference and E3-inspired presentation preference. Mod Settings is a provider for those values, not Biology simulation authority. Once the parallel settings/presentation work preserves those semantics without Mod Settings, this dependency should leave the integrated package.

### ArchiveXL — removal candidate

The canonical project has no direct first-party ArchiveXL consumer. Its current need is inherited through Mod Settings. If Mod Settings leaves and no separate Biology feature proves an ArchiveXL requirement, ArchiveXL leaves too.

### RED4ext — removal candidate

The canonical project contains no Biology-owned RED4ext DLL/plugin. Its current role is inherited through the ArchiveXL/Mod Settings chain. If those consumers leave and no concrete final native extension appears, RED4ext leaves too.

### TweakXL, Codeware, Input Loader — not required

No current Biology production source consumes them. They remain excluded unless a future lane proves a concrete feature need and updates the dependency graph with the exact consumer/rationale.

### Dark Future and Project E3 — blocked runtime

They may remain as historical/reference/provenance material where repository policy permits, but no executing runtime content from either belongs in Biology.

## Classification summary

| Current component/family | Classification | Foundation conclusion |
| --- | --- | --- |
| `mods/Biology/info.json` | `REDMOD-NATIVE` | canonical package identity |
| first-party archives/tweaks/audio/resources | `REDMOD-NATIVE` | use when actual content exists |
| current project-owned additive REDscript core | `REDSCRIPT-BETTER` | retain with accepted narrow seams |
| native hook files in `manifest/native-seams.json` | `REDSCRIPT-BETTER` | narrower than whole vanilla-file replacement |
| whole-file REDmod replacement for current wrappers | `REDMOD-POSSIBLE-BUT-BRITTLE` | do not choose merely to eliminate redscript |
| Mod Settings provider | `REMOVE/RETHINK` | migrate tiny semantics, then remove provider |
| ArchiveXL | `REMOVE/RETHINK` | inherited provider dependency only today |
| RED4ext | `REMOVE/RETHINK` | no direct Biology-native plugin today |
| TweakXL / Codeware / Input Loader | `REMOVE/RETHINK` | no current consumer |
| Dark Future / Project E3 runtime | `REMOVE/RETHINK` | prohibited from final runtime |
| installed REDmod CLI/version contract | `REDMOD-NATIVE` | directly probed on supported 2.31 install |
| actual REDmod conflict precedence on 2.31 | `UNKNOWN — NEEDS DIRECT GAME PROBE` | PKG-05 fixture required |
| hypothetical DLL/native hook | `REQUIRES-NATIVE-EXTENSION` | reserved; no current feature proves need |

## Direct-game evidence status

The read-only REDmod inventory/version/help probe is complete and committed as `docs/evidence/REDMOD-2.31-PROBE-2026-09-15.md`.

Remaining probes should be performed only when they can exercise real behavior safely:

- deploy an actual Biology candidate and verify recognition/deployment,
- verify enable/disable and relaunch persistence,
- construct a harmless reversible two-REDmod overlap fixture for PKG-05.

Do not guess at a conflicting stock asset or deploy an unsafe fixture merely to close the checklist.

## Work-item status

| Item | Status in this lane | Evidence / remaining gate |
| --- | --- | --- |
| PKG-01 | PARTIAL | package identity plus exact 2.31 REDmod CLI/path/version now proven; Biology recognition/deploy + enable/disable proof still required |
| PKG-02 | COMPLETE (foundation scope) | `Build-RedmodFoundation.ps1` builds offline release-shaped skeleton with provenance/ownership/checksums; integrated playable payload belongs to later assembly |
| PKG-03 | PARTIAL | exact deploy CLI is locally evidenced; direct enable persistence/reboot/relaunch evidence still required |
| PKG-04 | COMPLETE (contract) | exact owner/uninstall/fail-closed contract plus CI verification; attended reset verification follows integrated candidate |
| PKG-05 | BLOCKED ON OVERLAP PROBE | upstream order semantics documented; actual safe overlap fixture on supported install still required |
| PKG-06 | INTENTIONALLY NOT YET RETIRED | new foundation tooling exists; old builders remain until integrated candidate compiles/packages/deploys at least as reproducibly |
| PKG-07 | COMPLETE (foundation) | no game data copied into package; structural migration explicitly requires milestone clean-room broad acceptance |
| DEP-01 | AUDIT COMPLETE / REMOVAL PENDING SETTINGS LANE | Mod Settings is a removal candidate with only tiny transitional provider consumer |
| DEP-02 | COMPLETE | ArchiveXL removal candidate unless a direct final feature appears |
| DEP-03 | COMPLETE | RED4ext removal candidate absent direct native plugin consumer |
| DEP-04 | COMPLETE FOR CURRENT SEAM CLASSIFICATION | current wrapper/additive hook family is `REDSCRIPT-BETTER`; exact integrated compilation remains normal runtime acceptance |
| DEP-05 | COMPLETE | source-mod runtime blocked from dependency graph/package |
| DEP-06 | COMPLETE | `manifest/dependency-graph.json` records consumer, status, route, plan, rationale, and provenance where applicable |

## Merge rule

This lane is architecturally mergeable only when cloud CI is green. Direct-game items that remain probes must stay visibly open rather than being converted to assumptions.

Merging this foundation does **not** authorize removal of the old pre-REDmod runtime path by itself. PKG-06 closes only after the integrated Biology runtime from the parallel lanes builds, packages, deploys, and passes required clean-room acceptance through the replacement path.
