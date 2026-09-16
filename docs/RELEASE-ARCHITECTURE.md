# Biology release and installation architecture

Status: **canonical release target; attended integration acceptance still in progress**  
Last updated: **2026-09-15**

Canonical policy sources:

- `../AGREED-GOALS.md`
- `BIOLOGY-REDMOD-MIGRATION.md`
- `SETTINGS-ARCHITECTURE.md`
- `CLEAN-ROOM-TESTING.md`
- `LOCAL-OPERATOR-COMMANDS.md`
- root `ROADMAP.md`
- current GitHub issues/PRs

## Player-facing target

A normal player should be able to:

1. have Cyberpunk 2077 + official REDmod support installed;
2. download one **Biology** release;
3. copy/install one clearly identified package;
4. use the normal REDlauncher/Steam mod-enable path;
5. launch normally through Steam;
6. temporarily play without Biology by disabling REDmod once launcher-off behavior is proven across the complete runtime;
7. fully remove Biology with a self-contained `Uninstall Biology.exe` rather than reinstalling Cyberpunk.

The player should not need Vortex knowledge, Git, PowerShell, a source checkout, a persistent Biology launcher, or a menu of independent gameplay modules.

## Three supported player states

### 1. Biology ON

REDlauncher `Enable mods` ON and Biology active.

### 2. Vanilla-play mode

Biology remains installed, REDlauncher `Enable mods` OFF, and Biology behavior is inactive.

This must be **proven**, not assumed. Supplemental redscript paths outside `mods/Biology` must remain inert without the REDmod-owned Biology activation marker.

Vanilla-play mode means Biology behavior is inactive; it does not necessarily mean the retained redscript infrastructure is physically absent.

### 3. Fully removed

The player runs:

`Uninstall Biology.exe`

The uninstaller removes only files whose ownership can be proven safely, preserves saves and save-backed Biology preference/state, and reports ambiguous/changed files instead of guessing.

## REDmod-first does not mean REDmod-only

Official REDmod is preferred where it owns behavior cleanly.

Use REDmod for package identity/deployment and REDmod-native resources/routes. Do not force a behavior into whole-file REDmod script replacement when a smaller Biology-owned additive/wrapper seam is materially safer across game patches.

Runtime route decisions belong in `BIOLOGY-REDMOD-MIGRATION.md` and the relevant manifests/tests.

## Current integrated package foundation

The first integrated REDmod-first milestone already proved:

- package identity under `mods/Biology`;
- release-shaped package construction;
- exact compilation against Cyberpunk 2077 2.31;
- installation into a clean game;
- official REDmod recognition of `Biology`;
- actual five-stage REDmod deployment through the corrected explicit-root helper.

That foundation is no longer hypothetical. Current attended follow-ups are runtime/UI/presentation/release-UX defects tracked in root `ROADMAP.md`.

## Runtime ownership and current dependency set

Executing gameplay/presentation behavior is Biology-owned. Dark Future and Project E3 are reference/provenance only and must not execute in the player package.

Preferred dependency ladder:

```text
vanilla Cyberpunk semantic authority
        |
        v
official REDmod
        |
        v
Biology-owned additive/wrapper seam when narrower/safer
        |
        v
generic framework/native extension only when required
```

The current production generic runtime dependency set is exactly:

- **redscript 0.5.31** — retained for Biology-owned additive/wrapper runtime/UI seams, ScriptableSystem persistence, and native hook integration.

Issue #61 removes these former settings-stack dependencies from the production release path:

- Mod Settings;
- ArchiveXL;
- RED4ext.

They have no current accepted Biology consumer. Historical pinned component/license metadata may remain in the repository as evidence, but canonical acquisition/staging/package tooling must not install them.

Do not retain or reintroduce a dependency simply because a previous build used it. Any future framework addition requires a concrete current consumer and synchronized dependency/package contracts.

## Self-contained settings boundary

REDlauncher/REDmod is the sole public whole-mod activation boundary. Biology does not maintain a second persisted `Enable Biology` setting.

The one normal in-game public preference is:

`presentation.e3-first-person-hud-visuals`

It is:

- presentation-only;
- persisted as a Biology-owned `persistent` field on `CRRealpassSettings` (`ScriptableSystem`) through the Cyberpunk save lifecycle;
- edited from Biology-owned UI on the existing Biology/Cyberware body screen;
- unable to activate Biology when the REDmod launcher marker is absent.

Biology registers no external Mod Settings/pause-menu provider row. The previous blank/inert settings gap observed while launcher mods were OFF belongs to the retired provider architecture and must not be reproduced by the current package.

## Product/package identity

Player-facing identity is **Biology**.

The repository may remain named `cprealpass`, and internal `RealPass`/`CR*` identifiers may remain where renaming would add risk. New player-facing package metadata, labels and documentation should use Biology.

## Preferred final artifact shape

The core target is approximately:

```text
Cyberpunk 2077/
└── mods/
    └── Biology/
        ├── info.json
        ├── scripts/        # only accepted REDmod whole-file script routes
        ├── tweaks/         # accepted Biology tweak source
        ├── archives/       # accepted Biology-owned resources
        └── customSounds/   # only if Biology owns such content
```

The actual current release-shaped artifact also contains narrow supplemental Biology REDscript, redscript's pinned generic runtime files, package metadata/license/checksums, and:

```text
Uninstall Biology.exe
biology/build-manifest.json
biology/provenance.json
```

Every supplemental file family must be pinned/hash-verified, feature-justified, represented in package ownership/provenance, handled conservatively by uninstall logic, and removable when its last current consumer disappears.

## What must not ship

The final player package must not contain:

- repository tests/source-workspace state unrelated to runtime;
- staging/reports/vendor caches;
- machine-specific deployment receipts;
- saves;
- Cyberpunk executables, stock archives or other proprietary game payload;
- Dark Future or Project E3 executing content;
- Mod Settings, ArchiveXL, or RED4ext without a newly accepted concrete consumer;
- frameworks with no current Biology consumer;
- unexplained loose legacy payload;
- local `ReferenceMods/` material.

## Uninstaller safety contract

The self-contained player uninstaller must not depend on repository PowerShell scripts.

It should:

- locate/validate the game root;
- require Cyberpunk to be closed;
- read the installed Biology ownership manifest/version data;
- validate owned files before deletion;
- remove only proven Biology/release-owned paths;
- never recursively delete shared roots such as `archive`, `r6`, `red4ext`, `bin`, `engine`, or the entire `mods` directory;
- remove only now-empty directories reached from owned paths;
- preserve saves and therefore save-backed Biology E3 preference/state;
- leave changed/shared/ambiguous files in place and report them;
- refresh official REDmod deployment/cache state appropriately after removal;
- clearly distinguish full success from partial cleanup.

A mention of `red4ext` in the uninstaller shared-root safety denylist is not a Biology dependency claim; it prevents a malformed receipt from authorizing broad deletion on an installation where another mod owns that root.

W09.1 / issue #59 owns the separate post-uninstall REDmod output/cache recovery defect. W10 does not redesign that recovery path.

## Authoritative overlap and load order

Biology is authoritative for systems it intentionally owns.

Where REDmod can deterministically express precedence for REDmod-controlled resources, use that behavior deliberately. Do not claim universal dominance over redscript/CET/native/runtime TweakDB mechanisms outside REDmod's per-file model.

A self-contained mod is not a mod that forcibly overrides every possible third-party behavior.

## Repository → package boundary

The repository root is not the player mod.

```text
canonical source
  -> cloud/source contracts
  -> direct/native compatibility evidence
  -> exact compile/stage against supported game
  -> release-shaped Biology artifact
  -> official REDmod deploy/enable path
  -> normal Steam launch
  -> attended acceptance of that exact artifact
```

The package builder, not a developer working tree, defines what players receive.

## Local operator path rule

Repository/workspace paths are not stable.

Do not publish active instructions that require a permanent checkout such as `C:\Games\CyberpunkRealism`.

Before asking the user to run local commands, use `LOCAL-OPERATOR-COMMANDS.md`. Tools should derive the active checkout or self-bootstrap according to the canonical operator workflow.

The known game path may be used where the catalog permits it:

```text
C:\Games\Steam\steamapps\common\Cyberpunk 2077
```

## Testing and cleanup

The source checkout is disposable for user-facing attended builds.

The game installation has two test tiers:

- **Iteration** — use current ownership/reset policy when the prior Biology install can be safely accounted for.
- **Milestone clean-room** — Steam uninstall + residual-directory deletion + reinstall for structural/package/framework/game-patch milestones or unexplained residue.

Removing Mod Settings/ArchiveXL/RED4ext is a structural dependency change, so the parent integration acceptance for the combined W10 candidate should use the appropriate milestone-clean-room discipline rather than treating old framework residue as representative of the new package.

A full Steam reinstall is **not** the normal uninstall path for Biology. It remains exceptional clean-room/recovery evidence until the dedicated player uninstaller is fully accepted.

See `CLEAN-ROOM-TESTING.md`.

## CI vs attended evidence

Cloud CI can establish source/model/contract/package-policy consistency. It cannot prove:

- exact REDscript compile against the user's supported installed game bundle unless that local gate is run;
- native UI rendering of the Biology-owned E3 preference control;
- ScriptableSystem save/load persistence of that preference;
- REDmod runtime behavior on the user's supported installation;
- launcher-off native behavior and absence of the former blank provider row/security warning;
- quest compatibility;
- gameplay feel/performance;
- hard-uninstall cleanliness.

Those require direct/attended evidence against an exact release-shaped artifact. P01.1 owns launcher-OFF and E3 persistence acceptance; W10 does not ask the user to install/play the worker branch.

## Release gate

Do not publish a player release merely because source contracts pass or a ZIP assembles.

A release candidate needs, at minimum:

- cloud/source contracts green;
- runtime routes/dependencies justified;
- exact supported-game compile/package checks green;
- official REDmod recognition/deploy proven;
- normal Steam launch;
- attended Biology body/runtime/UI/presentation validation;
- E3 preference edit/save/reload validation;
- launcher ON/OFF semantics verified;
- no Biology-owned dead settings row/framework warning under launcher OFF;
- save/reload/time progression validation;
- representative gameplay/quest safety;
- acceptable runtime performance;
- notices/checksums/ownership metadata present;
- self-contained uninstaller safety/cleanup verified;
- install/disable/remove instructions understandable without development context.

## Recovery philosophy

Biology should not maintain a multi-generation rollback chain or depend on reinstalling an 85+ GiB game as ordinary removal.

Ownership manifests and the self-contained uninstaller are the normal safety mechanism. Full Steam reinstall remains the fallback when state cannot be accounted for or when a deliberate milestone clean-room proof is needed.
