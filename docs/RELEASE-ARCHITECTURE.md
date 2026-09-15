# RealPass release and installation architecture

Status: current release/package contract
Last updated: **2026-09-14 20:36 CDT (UTC-05:00)**
Canonical policy: `../AGREED-GOALS.md`, `manifest/distribution.json`, `docs/CLEAN-ROOM-TESTING.md`

## Player-facing target

A normal player should be able to:

1. download one RealPass release;
2. close Cyberpunk 2077;
3. extract/copy the package contents into the game root and merge folders;
4. launch Cyberpunk normally through Steam.

The player should not need Vortex knowledge, a manual source-mod stack, a persistent RealPass launcher, or a menu of independent gameplay modules.

## Runtime ownership

Executing gameplay/presentation behavior is RealPass-owned. Dark Future and Project E3 are reference/provenance only and are blocked from owned/live/public runtime manifests.

The current settings-capable runtime may use these pinned generic components as infrastructure:

- redscript;
- RED4ext;
- ArchiveXL;
- Mod Settings.

Those components do not own RealPass body/combat/injury/presentation policy. Mod Settings hosts exactly two RealPass-owned public Boolean controls:

- **Enable RealPass** — global all-or-nothing master switch;
- **E3 first-person HUD visuals** — presentation-only preference.

TweakXL, Codeware and Input Loader are not required by the current owned candidate. Do not add a dependency merely because it already exists on a developer machine.

## Repository -> package boundary

The repository root is not the player mod. It contains tests, tools, docs and build state that do not belong in the game.

The release boundary is:

```text
canonical source
  -> cloud/offline source contracts
  -> exact compile against the supported installed game
  -> verified game-root-shaped artifact
  -> ordinary folder merge into a vanilla game
  -> normal Steam launch
  -> attended acceptance of that exact package
```

Raw repository source remains fail-closed where necessary for development. Candidate builders may open accepted development gates only in immutable staged copies.

## Clean-room package is the broad acceptance authority

Broad attended testing must exercise the same package shape intended for players. The preferred builder is:

```powershell
pwsh ./tools/Build-CleanRoomTestPackage.ps1
```

It builds a game-root-shaped ZIP from fresh/canonical source, exact-compiles against the supported local game, materializes only the owned runtime + allowed pinned infrastructure, applies package policy, and does **not** deploy or launch Cyberpunk.

For broad acceptance, apply that ZIP to a genuinely vanilla Cyberpunk installation by normal folder merge, then launch through Steam. Do not call an accumulated in-place developer install a release-like acceptance pass.

`Prepare-OwnedSession.ps1`, `Install-OwnedRuntime.ps1`, and related flat-install tools may remain useful for narrow developer iteration and diagnosis. They are not the canonical broad product-validation path.

## Final artifact shape

The exact file list comes from the verified package plan, not from copying folders out of a developer installation. A release-shaped package may contain paths such as:

```text
bin/                    # only required allowed framework payload
engine/                 # only required allowed framework payload
r6/
  scripts/CyberpunkRealism/...
  config/               # only required allowed framework configuration
red4ext/                 # only required allowed framework payload
archive/                 # only if an accepted owned/dependency payload genuinely requires it
LICENSES/
INSTALL.txt
UNINSTALL.txt
REALPASS-VERSION.txt
SHA256SUMS.txt
realpass/provenance.json
realpass/build-manifest.json
```

The artifact must not contain:

- repository `tests/`, `tools/`, `staging/`, `reports/`, or `vendor/` state;
- local deployment receipts or machine-specific manifests;
- saves or user data;
- Cyberpunk executables, stock archives, `final.redscripts`, or other proprietary game files;
- Dark Future or Project E3 executing content;
- currently unnecessary frameworks merely inherited from the developer machine.

## Dependency and notice policy

`manifest/distribution.json` is authoritative for allowed/blocked/not-required runtime components. Every bundled generic dependency must be the exact pinned upstream version, hash-verified from its official release source, and accompanied by the required license/third-party notices.

`docs/DEPENDENCY-AUDIT.md` records engineering/license evidence. A technically working dependency is not automatically approved for public redistribution.

## Patch compatibility before packaging

Before broad testing after a Cyberpunk patch or before changing a foundational native seam, run the read-only compatibility audit:

```powershell
Set-Location 'C:\Games\CyberpunkRealism'
pwsh ./tools/Audit-GameContracts.ps1
```

This fingerprints the important official script/database boundaries, inventories the RealPass hook surface and exact-compiles project-owned REDscript against the installed base script bundle. It is an early compatibility check, not gameplay acceptance.

See `docs/PATCH-RESILIENCE.md` and `docs/LOCAL-GAME-REFERENCE.md`.

## CI vs local evidence

Cloud CI can establish source/model/contract/package-policy consistency. It cannot prove:

- native UI rendering;
- actual game event semantics;
- save persistence behavior;
- quest compatibility;
- combat feel/calibration;
- runtime latency/performance.

Those remain attended local gates against the exact release-shaped package.

## Release gate

Do not publish a player release merely because source compiles or the ZIP assembles. A release candidate needs, at minimum:

- cloud/source contracts green;
- local native-contract audit green for the supported game;
- exact package compilation green;
- artifact/provenance/dependency policy green;
- clean-room normal Steam boot;
- attended Biology/settings/scanner/presentation validation;
- attended physical combat/armor/wound/bleeding/pain/treatment validation;
- save/reload/time progression validation;
- representative base-game + Phantom Liberty quest-safety validation;
- acceptable runtime performance;
- required dependency notices/checksums present.

## Recovery philosophy

For development, RealPass does not maintain a multi-generation rollback chain or an extra automatic save-backup system. RealPass-owned extra files may be removed through the tracked ownership tooling; Steam Verify/reinstall remains the authority for stock game repair. Existing user/cloud save protection is considered sufficient unless the user explicitly chooses another workflow.

The public package may eventually include a simple uninstall instruction/manifest, but recovery complexity is not allowed to become a hidden launcher/service requirement.
