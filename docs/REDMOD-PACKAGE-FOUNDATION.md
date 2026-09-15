# Biology REDmod package/dependency foundation

Issue: #28  
Lane: `agent/redmod-foundation`  
Canonical start: `6fab5ba706e2a10387bb8629cccdb0868533bb97`  
Target game: Cyberpunk 2077 2.31

## Purpose

This lane makes official REDmod the package/deployment authority for Biology without pretending that every runtime seam should be rewritten as a REDmod whole-file script replacement.

The target is:

1. one recognizable first-party package at `mods/Biology`,
2. official REDmod deployment/enable/load for REDmod-native content,
3. only the narrow supplemental runtime/framework files that a concrete Biology feature still proves necessary,
4. exact per-file install/uninstall ownership,
5. no executing Dark Future or Project E3 payload,
6. no dependency retained merely because it existed in the pre-REDmod baseline.

This document is the lane-level evidence/status record. Machine-readable policy lives in:

- `manifest/redmod-package.json`
- `manifest/redmod-install-contract.json`
- `manifest/dependency-graph.json`
- `manifest/redmod-classification.json`

The pre-refactor `manifest/distribution.json`, `manifest/install-contract.json`, `manifest/package.json`, and clean-room builders remain transitional until PKG-06 is satisfied by an integrated candidate. They are not silently redefined underneath the parallel runtime lanes.

## Official REDmod facts used by this foundation

CD PROJEKT RED's current modding-support page states that REDmod-compatible mods are placed under `<Cyberpunk 2077>\mods`, are recognizable by an `info.json`, can be enabled/disabled through REDlauncher (and the supported store integration), and are processed before the game starts. It also identifies the command-line tool at `tools\redmod\bin\redMod.exe`.

The official REDmod technical documentation states that `redmod deploy -root=<path>` stages installed REDmods; archives, scripts, tweaks, and custom sounds are handled from their REDmod package roots. It also documents `-mod=<name,...>` for an explicit REDmod-only order and the game's `-modded` launch flag.

The maintained CDPR-Modding-Documentation REDmod page records the minimal package metadata as `name` and `version`, with `description` optional and `customSounds` required only when audio entries are used. Biology nevertheless declares an empty `customSounds` array to keep the skeleton explicit.

Sources:

- https://www.cyberpunk.net/en/modding-support
- https://cdn-l-cyberpunk.cdprojektred.com/REDmod-docs.pdf
- https://github.com/CDPR-Modding-Documentation/Cyberpunk-Modding-Docs/blob/main/for-mod-creators-theory/modding-tools/redmod/README.md
- https://github.com/CDPR-Modding-Documentation/Cyberpunk-Modding-Docs/blob/main/for-mod-creators-theory/modding-tools/redmod/script-modding.md

These sources establish the public REDmod contract. They do **not** replace the required direct 2.31 probe for the exact executable/version/behavior present in the supported install.

## Official package identity

The canonical REDmod identity is now:

```text
mods/
└── Biology/
    └── info.json
```

`mods/Biology/info.json` uses the product-facing name `Biology`. It intentionally contains no unrelated legacy runtime payload. Future first-party REDmod content may be added only to the official REDmod content roots:

```text
mods/Biology/archives
mods/Biology/scripts
mods/Biology/tweaks
mods/Biology/customSounds
```

A content root is not created just to make the tree look complete. It appears only when Biology actually has valid content for that route.

## Build contract

`tools/Build-RedmodFoundation.ps1` is an offline, release-shaped **foundation** builder. It:

- reads `manifest/redmod-package.json`,
- validates the Biology REDmod identity,
- copies only enumerated first-party REDmod-native files,
- generates installation/uninstallation instructions,
- generates Biology provenance and per-file ownership,
- generates SHA-256 verification data,
- produces a ZIP without reading or modifying the game installation.

The current foundation ZIP is deliberately non-playable. Its purpose is to establish the package/ownership machinery before the parallel runtime lanes contribute the accepted integrated runtime file set.

The builder therefore must not pull the old `r6/scripts`, RED4ext, ArchiveXL, or Mod Settings payload into the foundation merely to make it appear complete.

## Install / enable / load workflow

### Player-facing target

1. Install Cyberpunk 2077 and the official REDmod support available for the player's store/platform.
2. Close Cyberpunk 2077.
3. Install the Biology release so `mods\Biology\info.json` exists exactly under the Cyberpunk game root.
4. Use the supported REDlauncher/Steam REDmod enable flow and allow the REDmod deployment/progress step to finish.
5. After the supported 2.31 persistence test passes, ordinary Steam launch is the normal-play target. Biology does not own or require a permanent custom launcher.

The final release must not tell players to run a repository helper every time they play.

### Developer/diagnostic route

The official command-line deployment shape is:

```powershell
& '<Cyberpunk 2077>\tools\redmod\bin\redMod.exe' deploy -root='<Cyberpunk 2077>'
```

The official docs also describe the game `-modded` flag. Those commands are documented as upstream behavior, not yet as a locally proven 2.31 contract; the direct probe below closes that evidence gap.

### Enable/disable semantics

REDmod enable/disable is a package activation choice. It is not save deletion, simulation-state reset, uninstall, or permission to delete shared framework directories.

## Install/uninstall ownership

`manifest/redmod-install-contract.json` makes these first-party roots obvious:

- `mods/Biology`
- `biology` release metadata

The package owner manifest is `biology/build-manifest.json`. Every ordinary installed payload file has a path, SHA-256, owner, component, route, and replacement policy. The manifest itself is finalized and then hashed from `SHA256SUMS.txt`, avoiding recursive self-hashing.

Shared roots such as `r6`, `engine`, `red4ext`, `archive`, and `bin` are **never** directory-owned by Biology. If a future integrated release still needs redscript framework files, it owns only the exact pinned files named in the package manifest. Uninstall must never recursively delete a shared root.

If ownership or collision state cannot be proven, iteration reset fails closed and escalates to the milestone clean-room procedure in `docs/CLEAN-ROOM-TESTING.md`.

Because this lane changes package/dependency architecture, broad attended acceptance after integration is a milestone-clean-room event, not just a normal iteration reset.

## REDmod load order / overlap evidence

Official REDmod technical documentation says:

- the normal REDmod deploy path stages installed packages,
- default REDmod ordering is alphabetical,
- when REDmods conflict at the same file, the first mod in REDmod's order wins,
- `redmod deploy ... -mod=modA,modB,modC` supplies an explicit REDmod-only order, with the earlier listed mod taking precedence over later conflicting packages.

Biology therefore must **not** rely on a vague 'loads last' rule. If explicit REDmod ordering is ever needed, Biology's precedence must be expressed and tested in REDmod's own order semantics.

This evidence applies only inside REDmod's own package/deploy domain. It does not establish a universal precedence rule over redscript wrappers, RED4ext plugins, CET, runtime TweakDB mutation, or arbitrary legacy loaders.

### PKG-05 direct evidence gate

Issue #28 requires direct supported-install evidence, not documentation alone. Until a harmless two-REDmod overlap fixture is deployed on the supported 2.31 installation and the resulting deployment/log behavior is recorded, `manifest/redmod-classification.json` intentionally keeps `redmod-conflict-precedence-on-supported-2.31-install` as:

`UNKNOWN — NEEDS DIRECT GAME PROBE`

No release decision may silently convert that status to proven.

## Dependency conclusions

### redscript — retention candidate, not historical entitlement

Current Biology runtime code is project-owned REDscript and its game-facing seams use narrow annotations such as `@wrapMethod`, `@addMethod`, `@replaceMethod`, and `@addField`, enumerated by `manifest/native-seams.json`.

Official REDmod script modding works by placing modified vanilla-path `.script` files under a REDmod's `scripts` tree. For the current narrow wrappers, replacing whole vanilla script files would make Biology own substantially more upstream implementation than the feature needs. That increases patch and mod-conflict surface.

Accordingly, current additive/wrapper seams are classified `REDSCRIPT-BETTER`, not because redscript was already installed, but because it is the narrower boundary for the current implementation. A future seam can be reclassified only with feature-specific evidence that another route is smaller and safer.

### Mod Settings — removal candidate

The current `RealpassSettings.reds` surface contains only the global master preference and the E3-inspired presentation preference. Mod Settings is a provider for those values, not Biology simulation authority.

The presentation/settings lane may preserve those semantics using a Biology-owned/provider-neutral surface. Once it does, Mod Settings has no remaining current Biology consumer and should leave the integrated package.

### ArchiveXL — removal candidate

The current canonical project contains no first-party ArchiveXL resource consumer. ArchiveXL is present because the transitional Mod Settings package depends on it. If Mod Settings leaves and no separate Biology feature proves a direct ArchiveXL need, ArchiveXL leaves too.

### RED4ext — removal candidate

The current canonical project contains no Biology-owned RED4ext DLL/plugin. Its current package role is the inherited ArchiveXL/Mod Settings chain. If those consumers leave and no concrete final native extension appears, RED4ext leaves too.

### TweakXL, Codeware, Input Loader — not required

No current Biology production source consumes them. They remain excluded unless a future lane proves a concrete feature need and updates the dependency graph with the exact consumer/rationale.

### Dark Future and Project E3 — blocked runtime

They may remain as historical/reference/provenance material where repository policy permits, but no executing runtime content from either belongs in Biology.

## Classification summary

The complete machine-readable classification is `manifest/redmod-classification.json`. The architectural result is:

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
| installed REDmod CLI/version behavior | `UNKNOWN — NEEDS DIRECT GAME PROBE` | direct 2.31 evidence required |
| actual REDmod conflict precedence on 2.31 | `UNKNOWN — NEEDS DIRECT GAME PROBE` | PKG-05 fixture required |
| hypothetical DLL/native hook | `REQUIRES-NATIVE-EXTENSION` | reserved; no current feature proves need |

## Targeted direct-game probe

The first direct probe should be read-only and record the exact REDmod tool inventory, executable metadata/help, and current `mods` directory from the supported install. The requested output target is:

`game-reference/index/redmod-foundation-probe.txt`

The command supplied to the project owner is intentionally read-only with respect to Cyberpunk: it only enumerates files, reads executable metadata/help output, and writes the report into the local project evidence area.

After that evidence is available, a separate PKG-05 overlap fixture may be constructed only if its target is harmless and reversible. Do not guess at a conflicting stock asset or deploy an unsafe fixture just to close the checklist.

## Work-item status

| Item | Status in this lane | Evidence / remaining gate |
| --- | --- | --- |
| PKG-01 | PARTIAL | `mods/Biology/info.json` exists and is structurally validated; direct 2.31 recognition/deploy + enable/disable proof still required |
| PKG-02 | COMPLETE (foundation scope) | `Build-RedmodFoundation.ps1` builds offline release-shaped skeleton with provenance/ownership/checksums; integrated playable payload belongs to later assembly |
| PKG-03 | PARTIAL | official workflow documented; direct 2.31 enable persistence/reboot/relaunch evidence still required |
| PKG-04 | COMPLETE (contract) | exact owner/uninstall/fail-closed contract plus CI verification; attended reset verification follows integrated candidate |
| PKG-05 | BLOCKED ON DIRECT PROBE | official order documented; actual safe overlap fixture on supported install still required |
| PKG-06 | INTENTIONALLY NOT YET RETIRED | new foundation tooling exists; old builders remain until integrated candidate compiles/packages/deploys at least as reproducibly |
| PKG-07 | COMPLETE (foundation) | no game data copied into package; structural migration explicitly requires milestone clean-room broad acceptance |
| DEP-01 | AUDIT COMPLETE / REMOVAL PENDING SETTINGS LANE | Mod Settings is a removal candidate with only tiny transitional provider consumer |
| DEP-02 | COMPLETE | ArchiveXL removal candidate unless a direct final feature appears |
| DEP-03 | COMPLETE | RED4ext removal candidate absent direct native plugin consumer |
| DEP-04 | COMPLETE FOR CURRENT SEAM CLASSIFICATION | current wrapper/additive hook family is `REDSCRIPT-BETTER`; exact integrated compilation remains normal runtime acceptance |
| DEP-05 | COMPLETE | source-mod runtime blocked from dependency graph/package |
| DEP-06 | COMPLETE | `manifest/dependency-graph.json` records consumer, status, route, plan, rationale, and provenance where applicable |

## Merge rule

This lane is architecturally mergeable only when its cloud CI is green. Direct-game items that are intentionally classified as probes must remain visibly open rather than being converted to assumptions.

The merge of this foundation does **not** authorize removal of the old pre-REDmod runtime path by itself. PKG-06 is closed only after the integrated Biology runtime from the parallel lanes builds, packages, deploys, and passes the required clean-room acceptance through the replacement path.
