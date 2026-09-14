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

There is no persistent RealPass launcher and no public menu for enabling/disabling core realism authorities. The shipped version is one authored simulation.

## Current runtime dependency set

The completion candidate has been reduced to:

- **project-original realpass REDscript**;
- **pinned redscript runtime/compiler plumbing**.

The owned source does not currently require RED4ext, ArchiveXL, TweakXL, Codeware, Mod Settings or Input Loader. Those components may remain in the historical component catalog because older development profiles used them, but `m1-base` and `Build-OwnedRuntimeProfile.ps1` deliberately do not stage them.

Dark Future and Project E3 are reference/history only and are forbidden from owned/live/public runtime manifests.

The final release should not add a dependency simply because it is already installed on a developer's machine.

## Repository/build boundary

GitHub source does not affect the game until runtime files are installed. The release boundary is:

`repository source -> verified candidate -> exact compile -> game-root artifact -> install -> normal Steam launch`

Canonical body/combat gates remain fail-closed in repository source. The candidate builder opens them only in immutable staged copies, compiles the exact candidate against the supported game scripts and hashes every source payload.

## Candidate/live-test install

`Prepare-OwnedSession.ps1` is the development operator entry point.

Without `-Deploy`, it runs source contracts, builds the complete owned candidate, exact-compiles it against the local Cyberpunk 2077 2.31 base script bundle and produces a flat install plan without changing game files.

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

After attended native acceptance, the intended player ZIP is approximately:

```text
realpass-x.y.z.zip
  INSTALL.txt
  UNINSTALL.txt
  REALPASS-VERSION.txt
  SHA256SUMS.txt
  r6/
    scripts/
      CyberpunkRealism/
        ... realpass owned .reds sources ...
  engine/                 # pinned redscript runtime files required by its official Windows package
  r6/config/              # only redscript runtime config files required by the pinned package
  LICENSES/
    realpass.txt
    redscript.txt
  realpass/
    provenance.json
    build-manifest.json
```

The exact pinned redscript file list comes from the verified upstream archive, not this illustrative directory tree.

The artifact must not contain repository/developer state such as `tests/`, `staging/`, `reports/`, `vendor/`, `ReferenceMods/`, local manifests, save files, game executables/archives or compiled `final.redscripts` copied from the user's installation.

## Dependency policy

`manifest/distribution.json` is authoritative.

### Allowed runtime components

- `realpass-project-original`
- `redscript`

### Not required / must not drift into the artifact

- RED4ext
- ArchiveXL
- TweakXL
- Codeware
- Mod Settings
- Input Loader

A future change may reintroduce one only after an actual owned-source requirement is documented, the dependency/notice policy is updated and CI is intentionally changed.

### Blocked runtime material

- Dark Future execution/content;
- Project E3 execution/assets;
- proprietary Cyberpunk game files/user data.

The artifact scanner rejects provenance declaring both blocked and currently not-required components so the one-download package cannot silently grow back into a mod stack.

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

- acquires only pinned redscript plumbing;
- builds the complete project-original REDscript tree;
- rejects forbidden source-mod identity/imports;
- opens fail-closed body/combat gates only in staged copies;
- exact-compiles against the installed supported game;
- plans/installs only the current manifest payload.

### Public release

After live acceptance, a clean release workflow should:

- acquire the exact pinned redscript archive from its official source;
- verify its SHA-256;
- assemble only allowed components;
- include required MIT/RealPass notices;
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
This release is one authored realism experience. Core gameplay systems are not separately toggleable.

UPDATE
Close the game and follow the release notes. Extract the new package over the game root only when the release notes say the versions are directly upgrade-compatible.

UNINSTALL
Follow UNINSTALL.txt so only files owned by this RealPass release are removed. Use Steam Verify Files/reinstall only if stock-game repair is needed.
```

## Distribution done

Public distribution is complete only when:

- a clean supported installation needs one RealPass download rather than a manually assembled dependency stack;
- the exact shipped candidate has passed body/combat/presentation/save/quest/performance attended acceptance;
- all shipped files are owned or redistribution-cleared and correctly noticed;
- the release is reproducible from repository source + pinned upstream redscript;
- CI rejects game/user/source-mod/unneeded-framework content;
- no persistent special launcher/background process is required;
- update/uninstall ownership is explicit;
- the package contains no out-of-scope gameplay from historical dependencies.
