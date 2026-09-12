# realpass release and installation architecture

## User-facing target

A normal player should not need to understand redscript, RED4ext, staging manifests, source-mod patch recipes or deployment receipts.

Preferred final flow:

1. Download `realpass-x.y.z.zip` from the GitHub Release.
2. Open the Cyberpunk 2077 installation folder.
3. Extract/copy the archive contents into that folder and allow folder merging.
4. Start Cyberpunk 2077 normally through Steam.
5. Configure realpass, if desired, through one in-game realpass settings surface.

No realpass launcher should be required for ordinary play after installation. If licensing or dependency update safety makes a bootstrap installer materially safer than a raw ZIP, that installer must still be one obvious action and must leave normal Steam launch intact.

## Why source code on GitHub does not affect the game by itself

The repository is development source. Cyberpunk only loads realpass when runtime files exist in the game directory paths understood by the game and its mod frameworks (for example `r6/scripts`, `r6/tweaks`, `red4ext/plugins` and `archive/pc/mod`, depending on the final implementation). Git does not inject code into a running or installed game.

The release pipeline therefore has a deliberate boundary:

`repository source -> verified build/staging -> release artifact -> copy/install into game root -> normal game launch`

## Release artifact shape

The player ZIP should be game-root-relative. A representative *shape* is:

```text
realpass-x.y.z.zip
  INSTALL.txt
  REALPASS-VERSION.txt
  SHA256SUMS.txt
  archive/                 # only when realpass-owned/redistribution-cleared archives are needed
  bin/                     # only redistribution-cleared framework runtime files if approved
  r6/
    scripts/
      CyberpunkRealism/
    tweaks/
      realpass/
  red4ext/                 # only required redistribution-cleared framework/runtime files
  LICENSES/
  realpass/
    provenance.json
    build-manifest.json
```

The exact directories are determined by the runtime dependency set. The player artifact must not contain repository structure such as `tests/`, `staging/`, `reports/`, `vendor/`, `ReferenceMods/` or source-only patch recipes unless a recipe is specifically required at runtime.

## Dependency rule

The desired product is one mod, not a mod list. That does **not** mean third-party authorship disappears. Dependencies fall into three categories:

### Bundleable runtime dependency

A dependency whose license/notice requirements have been audited and whose necessary runtime files may be redistributed can be placed inside the realpass ZIP with the required notices and provenance. This gives the player one download while retaining authorship and license obligations.

### Bootstrap-only dependency

If a dependency may be downloaded from its official source but should not be redistributed inside realpass, a future one-click bootstrap installer may fetch the exact pinned release from its official URL, verify its cryptographic hash, and install only the required files. The player still performs one realpass setup action.

### Blocked/reference-only dependency

A dependency whose current terms prohibit standalone redistribution of the required modified material cannot be part of the final one-download artifact. Project E3 HUD is currently in this category under the permissions recorded in this repository. The release solution is therefore to replace the required presentation behavior with realpass-owned/independently distributable implementation, or obtain new permission. The release builder must fail closed if blocked material is present.

`manifest/distribution.json` is the machine-readable source of truth for this policy.

## GitHub Actions plan

The cloud pipeline is deliberately staged so CI cannot accidentally publish local/reference material.

### CI workflow (safe now)

Runs on pull requests and pushes to development branches. It should:

- validate JSON/manifest contracts;
- run self-contained model/contract tests that do not need the installed game;
- run source/package consistency checks;
- optionally build a clearly named **development/source artifact** containing only redistribution-safe project files;
- never publish a GitHub Release automatically.

### Candidate artifact workflow

Manual (`workflow_dispatch`) while the project is pre-release. Once enough runtime material is redistributable and cloud-reproducible, it should:

- acquire only explicitly approved pinned dependencies from official URLs;
- verify every downloaded archive against the pinned hash in `manifest/components.json`;
- assemble the game-root-relative candidate;
- run the artifact content deny-list from `manifest/distribution.json`;
- generate a complete file/hash index;
- zip the exact verified directory;
- upload it as a GitHub Actions artifact for attended testing;
- mark the artifact `development` or `candidate`, never `release`, while release gates remain open.

### Public release workflow

Triggered only by an intentional version tag/release after `publicPlayableArtifactReady` is explicitly promoted through review. It should:

- repeat all candidate checks from a clean runner;
- refuse to run if any component is `blocked` or any required component is still `conditional` without an approved release disposition;
- compile/validate the exact shipped scripts against the pinned toolchain;
- build the final game-root package;
- include required licenses and attribution;
- verify no forbidden file/path is present;
- generate `SHA256SUMS.txt` and a build manifest;
- attach the ZIP and checksum to the GitHub Release.

The release workflow must never pull files from a developer's PC, local save folder, ignored staging directory or prior workflow artifact without re-verification.

## Upgrade and rollback UX

Development currently has robust receipt-based install/upgrade/rollback tools. Those safety properties should survive simplification, but ordinary players should not need to manage receipts manually.

Preferred release behavior:

- first install: folder merge or one-click installer;
- update: replace only realpass-owned files and approved dependency files;
- preserve user settings unless a schema migration explicitly changes them;
- before any risky save-affecting migration, display a clear version/migration warning and create or request a backup;
- uninstall: remove only files owned by realpass, never broad mod directories shared with other mods;
- rollback documentation distinguishes file rollback from save-state rollback.

A raw drag-and-drop ZIP is simplest for first installation, but exact uninstall/upgrade ownership may justify an optional helper script. Any helper must be finite, explicit, user-invoked and must not install a background service/watcher/scheduled task.

## INSTALL.txt target content

The finished package should contain a very short installation file approximately equivalent to:

```text
realpass — Cyberpunk 2077 realism pass

Requirements: Cyberpunk 2077 + Phantom Liberty, supported game version listed below.

INSTALL
1. Close Cyberpunk 2077.
2. Open your Cyberpunk 2077 installation folder (the folder containing bin, archive and r6).
3. Extract everything from this ZIP into that folder. Merge folders when Windows asks.
4. Launch Cyberpunk 2077 normally through Steam.

SETTINGS
Use the realpass section in the in-game Mod Settings menu. Major realism systems can be disabled independently.

UPDATE
Close the game and extract the newer realpass ZIP over the same game folder. Read release notes first when a save migration is listed.

UNINSTALL
Follow UNINSTALL.txt for the exact version so only files owned by realpass are removed.

Build: <version / commit>
Supported game: <version>
```

The real file must list any bundled/bootstrapped prerequisites accurately; it must not claim true drag-and-drop installation until the artifact actually contains or safely obtains every required runtime dependency.

## Definition of distribution done

Distribution is not complete merely because a ZIP can be produced. It is complete when all of the following are true:

- a clean PC with the supported game can install realpass without manually assembling a mod stack;
- all shipped files are redistribution-cleared and attributed;
- the exact release is reproducible from the repository and pinned upstream sources;
- CI verifies every shipped file and rejects blocked/private/game files;
- installation does not require a permanent launcher;
- updates and uninstall have explicit file ownership;
- the installed build passes the same body/combat/save/quest acceptance gates documented for the source revision;
- the package contains no extraneous upstream gameplay systems outside the realpass scope.
