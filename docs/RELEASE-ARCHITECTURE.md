# realpass release and installation architecture

Last updated: 2026-09-14
Canonical policy: `AGREED-GOALS.md` and `manifest/distribution.json`

## User-facing target

A normal player should not need to understand REDscript, staging manifests, development gates or the reference-mod history.

Preferred release flow:

1. Download `realpass-x.y.z.zip`.
2. Close Cyberpunk 2077.
3. Extract the archive into the Cyberpunk 2077 game root and merge folders.
4. Launch Cyberpunk normally through Steam.

There is no persistent RealPass launcher and no public menu for enabling/disabling core realism authorities. The shipped version is one authored simulation. RealPass may appear in Mod Settings so the player can confirm it is active, read a concise managed-feature ledger and change explicitly accepted binary presentation/accessibility preferences that do not alter the simulation.

## Current runtime dependency set

The integrated owned candidate uses:

- **project-original RealPass REDscript** for gameplay and presentation policy;
- **redscript 0.5.31** for script loader/compiler plumbing;
- **RED4ext 1.30.0** as generic infrastructure required by the pinned settings dependency chain;
- **ArchiveXL 1.27.3** as a generic dependency of the pinned Mod Settings build;
- **Mod Settings 0.2.21** to host the accepted RealPass settings surface.

`m1-base` remains a useful **redscript-only** source/native-development profile. The deployable `m1-owned-settings` profile is the constrained four-component generic runtime above. TweakXL, Codeware and Input Loader are not required by the current owned candidate.

These generic frameworks do not own RealPass simulation or presentation policy. In particular, Mod Settings only hosts RealPass-owned labels/status text and accepted binary presentation/accessibility preferences. It is not a body, injury, combat, armor, progression or balance authority.

Dark Future and Project E3 are reference/history only and are forbidden from owned/live/public runtime manifests.

The final release should not add a dependency simply because it is already installed on a developer's machine. Any new framework must correspond to a concrete RealPass-owned source requirement and a synchronized distribution/license contract change.

## Repository/build boundary

GitHub source does not affect the game until runtime files are installed. The release boundary is:

`repository source -> verified candidate -> exact compile -> game-root artifact -> install -> normal Steam launch`

Canonical body/combat gates remain fail-closed in repository source. The candidate builder opens them only in immutable staged copies, compiles the exact candidate against the supported game scripts and hashes every source payload.

## Candidate/live-test install

`Prepare-OwnedSession.ps1` is the development operator entry point.

Without `-Deploy`, it runs source contracts, acquires/stages the constrained generic settings profile, builds the complete owned candidate, exact-compiles it against the local Cyberpunk 2077 2.31 base script bundle and produces a flat install plan without changing game files.

With `-Deploy`, it repeats the checks and then uses `Install-OwnedRuntime.ps1` to:

- remove the previous RealPass-owned script namespace and known retired/source-mod residue;
- copy only the exact current manifest payload;
- verify installed hashes;
- write one `owned-current.json` state file;
- verify known retired/source-mod runtime residue is absent;
- stop without launching the game.

`Remove-OwnedRuntime.ps1` removes recorded RealPass-owned files whose hashes still match. If stock game bytes ever need repair, use Steam **Verify Files** or reinstall. Steam verification is not assumed to remove arbitrary extra mod files, which is why the flat RealPass ownership record exists.

No multi-generation rollback chain or additional RealPass-managed save backup is part of the normal development path.

## Final artifact shape

After attended native acceptance and the dependency/license audit, the intended player ZIP is approximately:

```text
realpass-x.y.z.zip
  INSTALL.txt
  UNINSTALL.txt
  REALPASS-VERSION.txt
  SHA256SUMS.txt
  bin/                    # only files from allowed pinned generic dependencies
  engine/                 # pinned redscript runtime files
  r6/
    scripts/
      CyberpunkRealism/
        ... RealPass-owned .reds sources ...
    config/                # only required pinned dependency configuration
  red4ext/                 # only allowed pinned RED4ext/ArchiveXL/Mod Settings payload
  archive/                 # only dependency payload explicitly required by the accepted profile
  LICENSES/
    realpass.txt
    redscript.txt
    red4ext.txt
    archivexl.txt
    mod-settings.txt
    ... required third-party notices ...
  realpass/
    provenance.json
    build-manifest.json
```

This is illustrative, not a license to copy arbitrary folders from a developer installation. The exact file list must come from the verified upstream archives and the accepted deployment plan for the pinned versions.

The artifact must not contain repository/developer state such as `tests/`, `staging/`, `reports/`, `vendor/`, `ReferenceMods/`, local manifests, save files, game executables/archives or compiled `final.redscripts` copied from the user's installation.

## Dependency policy

`manifest/distribution.json` is authoritative.

### Allowed runtime components

- `realpass-project-original`
- `redscript`
- `red4ext`
- `archivexl`
- `mod-settings`

The four generic dependencies are infrastructure only. The final package may include their pinned runtime files only after license/notice and live-acceptance gates pass.

### Not required / must not drift into the artifact

- TweakXL
- Codeware
- Input Loader

A future change may add one only after an actual owned-source requirement is documented, the dependency/notice policy is updated and CI is intentionally changed.

### Blocked runtime material

- Dark Future execution/content;
- Project E3 execution/assets;
- proprietary Cyberpunk game files/user data.

The artifact scanner rejects provenance declaring blocked or currently not-required components so the one-download package cannot silently grow back into a broad mod stack.

## CI and release pipeline

### Normal CI

Push/PR CI must:

- validate manifests/docs/source contracts;
- run deterministic model/property tests;
- validate native-seam placement;
- enforce runtime-origin rules;
- enforce artifact/package policies;
- never launch Cyberpunk or publish a release automatically.

Cloud CI is source evidence only. It cannot replace exact local compile/native acceptance.

### Candidate build

The local attended candidate:

- acquires only the pinned redscript/RED4ext/ArchiveXL/Mod Settings plumbing required by `m1-owned-settings`;
- builds the complete project-original REDscript tree;
- rejects forbidden source-mod identity/imports;
- opens fail-closed body/combat gates only in staged copies;
- exact-compiles against the installed supported game;
- exact-compiles the final constrained deployment profile;
- plans/installs only the current manifest payload.

### Public release

After live acceptance, a clean release workflow should:

- acquire the exact pinned allowed dependency archives from their official sources;
- verify each SHA-256;
- assemble only allowed components and only the files required by the accepted profile;
- include all required MIT/third-party/RealPass notices;
- run the artifact deny/disallowed-component policy;
- generate a complete file/hash index;
- produce deterministic version/build metadata and `SHA256SUMS.txt`;
- attach the verified game-root ZIP/checksum to the intentional GitHub release/tag.

No developer-PC save, game file, ignored staging output or previously generated local candidate may enter the release artifact.

## INSTALL.txt target

The final package installation copy should remain short:

```text
realpass — Cyberpunk 2077 realism pass

Supported game: <version>
Build: <version / commit>

INSTALL
1. Close Cyberpunk 2077.
2. Open the Cyberpunk 2077 folder containing bin, archive and r6.
3. Extract this ZIP into that folder and merge folders.
4. Launch Cyberpunk 2077 normally through Steam.

REALPASS
This release is one authored realism experience. Core gameplay systems are not separately toggleable. Mod Settings, when present, exposes only RealPass status/feature information and explicitly accepted presentation/accessibility preferences.

UPDATE
Close the game and follow the release notes. Extract the new package over the game root only when the release notes say the versions are directly upgrade-compatible.

UNINSTALL
Follow UNINSTALL.txt so only files owned by this RealPass release are removed. Use Steam Verify Files/reinstall only if stock-game repair is needed.
```

## Distribution done

Public distribution is complete only when:

- a clean supported installation needs one RealPass download rather than a manually assembled dependency stack;
- the exact shipped candidate has passed settings/Biology/Outfit/HUD/body/combat/presentation/save/quest/performance attended acceptance;
- all shipped files are owned or redistribution-cleared and correctly noticed;
- the release is reproducible from repository source + pinned allowed upstream generic dependencies;
- CI rejects game/user/source-mod/unneeded-framework content;
- no persistent special launcher/background process is required;
- update/uninstall ownership is explicit;
- the package contains no out-of-scope gameplay from historical dependencies.
