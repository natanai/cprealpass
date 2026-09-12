# realpass dependency and redistribution audit

Last evidence review: 2026-09-12

This is an engineering release audit, not legal advice. Its purpose is to keep the one-download goal honest: a dependency is not marked bundleable merely because it is easy to download or because another mod bundles it. `manifest/components.json` remains the pinned technical inventory; `manifest/distribution.json` remains the machine-readable release disposition.

## Decision rule

A framework can move from **conditional** to a final bundled disposition only after all of the following are true for the exact pinned release:

1. the primary license permits the intended binary redistribution;
2. required copyright/license text is identified;
3. bundled third-party notices and their redistribution conditions are preserved;
4. the exact official release archive/file set is inventoried and hash verified;
5. only files actually required by the final realpass runtime are selected, unless selectively extracting files would violate an upstream notice/packaging requirement;
6. the installed paths are represented in the realpass owner/provenance manifest;
7. the combined package passes `tools/Test-ArtifactPolicy.ps1` and the final dependency notice audit.

Until then, `conditional` means “technically promising, not cleared for public realpass bundling yet.”

## Pinned framework evidence

### RED4ext 1.30.0

Pinned source/release: <https://github.com/WopsS/RED4ext/releases/tag/v1.30.0>

Primary license: MIT, exact tagged evidence: <https://github.com/WopsS/RED4ext/blob/v1.30.0/LICENSE.md>

The official release also carries `THIRD_PARTY_LICENSES.md`: <https://github.com/WopsS/RED4ext/blob/v1.30.0/THIRD_PARTY_LICENSES.md>. That file contains several third-party licenses with notice/redistribution conditions, so the public realpass package must preserve the applicable notice material rather than copying only the top-level MIT text.

Engineering disposition: **conditional bundle candidate**. The pinned release archive hash is already recorded in `manifest/components.json`.

### redscript 0.5.31

Pinned source/release: <https://github.com/jac3km4/redscript/releases/tag/v0.5.31>

Primary license: MIT, exact tagged evidence: <https://github.com/jac3km4/redscript/blob/v0.5.31/LICENSE>

The project’s Windows installation model is already game-root-relative, which matches realpass’s desired player experience. The exact official release archive/hash is pinned in `manifest/components.json`.

Engineering disposition: **conditional bundle candidate**, pending exact release-archive notice/file audit.

### ArchiveXL 1.27.3

Pinned source/release: <https://github.com/psiberx/cp2077-archive-xl/releases/tag/v1.27.3>

Primary license: MIT, exact tagged evidence: <https://github.com/psiberx/cp2077-archive-xl/blob/v1.27.3/LICENSE>

Third-party notices: <https://github.com/psiberx/cp2077-archive-xl/blob/v1.27.3/THIRD_PARTY_LICENSES>. The notice set contains multiple licenses/conditions and explicitly includes a TiltedCore notice that says not to remove or modify license notices. Therefore an ArchiveXL bundle must preserve the upstream third-party notice material intact unless a complete component-level legal audit establishes a narrower compliant set.

Engineering disposition: **conditional bundle candidate**, not yet promoted.

### TweakXL 1.11.4

Pinned source/release: <https://github.com/psiberx/cp2077-tweak-xl/releases/tag/v1.11.4>

Primary license: MIT, exact tagged evidence: <https://github.com/psiberx/cp2077-tweak-xl/blob/v1.11.4/LICENSE>

Its runtime depends on RED4ext. The official release’s third-party notice material must be retained/audited before public bundling.

Engineering disposition: **conditional bundle candidate**. If the final realpass runtime no longer requires TweakXL, remove the dependency instead of bundling it by inertia.

### Codeware 1.20.3

Pinned source/release: <https://github.com/psiberx/cp2077-codeware/releases/tag/v1.20.3>

Primary license: MIT, exact tagged evidence: <https://github.com/psiberx/cp2077-codeware/blob/v1.20.3/LICENSE>

Third-party notices: <https://github.com/psiberx/cp2077-codeware/blob/v1.20.3/THIRD_PARTY_LICENSES>. As with ArchiveXL, this includes several separate notice/redistribution conditions. Preserve the official third-party notice file unless a complete audit proves another compliant representation.

Engineering disposition: **conditional bundle candidate**. Remove it if the final realpass settings/UI/runtime no longer needs it.

### Mod Settings 0.2.21

Pinned source/release: <https://github.com/jackhumbert/mod_settings/releases/tag/v0.2.21>

Primary license: MIT, exact tagged evidence: <https://github.com/jackhumbert/mod_settings/blob/v0.2.21/license.md>

The upstream release documentation lists RED4ext, ArchiveXL and redscript requirements. realpass currently plans to use Mod Settings for one public settings surface, but `docs/SETTINGS-ARCHITECTURE.md` deliberately leaves replacement possible if a smaller reliable realpass-owned UI becomes preferable.

Engineering disposition: **conditional bundle candidate**. Its dependency closure matters: bundling Mod Settings can indirectly keep ArchiveXL in the final dependency set even if realpass gameplay itself does not otherwise need ArchiveXL.

### Input Loader 0.2.3

Pinned upstream release: <https://github.com/jackhumbert/cyberpunk2077-input-loader/releases/tag/v0.2.3>

Primary license: MIT, exact tagged evidence: <https://github.com/jackhumbert/cyberpunk2077-input-loader/blob/v0.2.3/license.md>

Upstream documents RED4ext as its requirement and supports per-mod input XMLs. It also has uninstall/cache behavior of its own. realpass must never package a user’s live `inputUserMappings.xml`; if Input Loader remains necessary, package only the official plugin/runtime pieces and realpass-owned input definitions.

Engineering disposition: **conditional bundle candidate**. Remove it if the final realpass controls require no custom input mapping.

## Adapted gameplay/presentation dependencies

### Dark Future 2.0

Current role: needs/UI integration host and source of adapted behavior. The repository records the selected adapted material as CC BY-SA 4.0 and retains the source author/change notices.

This does **not** mean the whole upstream mod should become part of realpass. `manifest/feature-inventory.json` marks unrelated difficulty/economy/travel/random-encounter/addiction/humanity systems for removal. The release path is either:

- retain only the specifically adapted, in-scope material with full attribution/share-alike compliance and any required source/notice availability; or
- replace remaining host/integration pieces with realpass-owned equivalents.

Engineering disposition: **conditional adapt-or-replace**. A full upstream archive is not assumed cleared or desirable.

### Project E3 - HUD

Current role: local/reference presentation source for the selected E3-inspired HUD/nameplate look.

The permission record in this repository requires the original mod for published modifications and prohibits standalone redistribution of its modified assets. That conflicts directly with the one-download standalone realpass target.

Engineering disposition: **blocked from standalone realpass artifact under current recorded terms**. Replace the required presentation behavior with independently distributable realpass implementation/assets or obtain new permission. The artifact scanner and distribution contract fail closed on `project-e3-hud`.

## Dependency minimization before 1.0

A one-download package is easiest to maintain when its dependency graph is as small as possible. Before promoting a framework from conditional to bundled:

- identify which final realpass runtime file/API actually requires it;
- prove that removing the framework breaks an in-scope feature;
- prefer deleting an unused dependency over carrying it for historical reasons;
- avoid bundling broad framework “extras” as realpass features; framework-internal files required for correct operation are different from optional gameplay features;
- preserve upstream authorship and license notices even though the player downloads one realpass package.

The target is “one player download,” not “claim all bundled software is ours.”
