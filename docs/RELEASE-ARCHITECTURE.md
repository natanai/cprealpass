# Biology release and installation architecture

Status: **canonical target; REDmod migration active**
Last updated: **2026-09-15**
Canonical policy: `../AGREED-GOALS.md`, `docs/BIOLOGY-REDMOD-MIGRATION.md`, `manifest/distribution.json`, `docs/CLEAN-ROOM-TESTING.md`, `docs/PLAYER-DISABLE-UNINSTALL.md`

## Player-facing target

A normal player should be able to:

1. have Cyberpunk 2077 plus the official free REDmod support installed/enabled as required by the supported platform;
2. download one **Biology** release;
3. copy/install one clearly identified Biology package, preferably under `Cyberpunk 2077/mods/Biology`;
4. deploy/enable it through the supported REDmod path as needed;
5. launch Cyberpunk normally through Steam thereafter.

The player should not need Vortex knowledge, a manual source-mod stack, a persistent Biology launcher, or a menu of independent gameplay modules.

## Player disable / uninstall states

Biology deliberately supports three different player states:

1. **Biology ON** — REDlauncher `Enable mods` ON. Biology's REDmod-owned activation marker is present and Biology may run, subject to the existing Biology master preference.
2. **Vanilla-play mode** — REDlauncher `Enable mods` OFF. Biology remains physically installed, but the REDmod activation marker is absent and Biology behavior must fail closed to native Cyberpunk behavior. This does not reset saves, Biology state, or Biology preferences.
3. **Fully removed** — close the game and double-click the packaged `Uninstall Biology.exe`. The uninstaller is manifest/hash-driven, removes only proven Biology-owned files, preserves changed/ambiguous files, preserves generic/shared dependencies and saves, preserves Biology preferences by default, and refreshes official REDmod state without recursively deleting shared roots.

The launcher switch is therefore an everyday behavioral disable, not an uninstall mechanism. Full game reinstall is an exceptional recovery/milestone operation, not the normal Biology removal path. Detailed ownership, dependency, REDmod-refresh, and attended-acceptance rules live in `docs/PLAYER-DISABLE-UNINSTALL.md` and `manifest/redmod-install-contract.json`.

## REDmod-first does not mean REDmod-only

Official REDmod is the preferred package/deployment/runtime route wherever it can own the behavior cleanly.

Use REDmod for:

- package identity/deployment;
- REDmod-native archives/resources;
- tweak source;
- audio/animation paths where Biology actually owns such content;
- script replacement only when whole-file replacement is the robust choice.

Do **not** force a behavior into REDmod merely because the route is official. REDmod `.script` modding replaces a vanilla-path script file and conflicts per file; a narrow Biology-owned wrapper/additive seam may touch far less vanilla implementation and therefore survive patches better.

The route for each runtime feature must be classified under `docs/BIOLOGY-REDMOD-MIGRATION.md` before the migration is considered complete.

## Runtime ownership and dependency ladder

Executing gameplay/presentation behavior is Biology-owned. Dark Future and Project E3 are reference/provenance only and are blocked from finished live/public runtime manifests.

Dependency preference:

```text
vanilla Cyberpunk semantic authority
        |
        v
official REDmod
        |
        v
Biology-owned additive/wrapper script seam (only when narrower/safer)
        |
        v
generic native/framework extension (only when necessary)
```

The current settings-capable runtime may still contain redscript, RED4ext, ArchiveXL and Mod Settings during migration. **Those are transitional, not an entitlement.** Each must be removed unless the migration audit demonstrates a current Biology feature that genuinely requires it.

In particular, Mod Settings is no longer a product requirement. The public settings contract is provider-neutral and intentionally tiny; a Biology-owned preferences surface is preferred if it can remove the Mod Settings/ArchiveXL/RED4ext chain without increasing fragility.

## Product/package identity

Player-facing and new package identity is **Biology**.

During migration:

- repository name may remain `cprealpass`;
- internal `RealPass`/`CR*` identifiers may remain temporarily;
- historical manifests/tests may still use `realpass` as a technical identifier;
- do not mass-rename internals merely for cosmetics.

The migration should move package metadata, install paths, labels and new documentation toward Biology first, then internal identifiers gradually where safe.

## Preferred final artifact shape

The target shape is approximately:

```text
Cyberpunk 2077/
├── Uninstall Biology.exe
├── biology/
│   └── build-manifest.json
└── mods/
    └── Biology/
        ├── info.json
        ├── scripts/        # only accepted REDmod whole-file script routes
        ├── tweaks/         # includes the inert launcher-activation marker
        ├── archives/       # only accepted Biology-owned resources
        └── customSounds/   # only if Biology owns custom sound content
```

If an unavoidable generic framework remains, its player-package files may live outside `mods/Biology` only because that framework requires it. Every such file family must be:

- pinned and hash-verified;
- explicitly justified by a current Biology feature;
- accompanied by required notices;
- represented in the package manifest/provenance;
- treated conservatively at uninstall time when another mod may depend on it.

The normal player uninstaller preserves generic/shared framework files rather than attempting unreliable last-consumer detection. The stricter developer iteration reset may remove an exact generic file only when the recorded pristine baseline proves Biology introduced it into that installation.

The final package must not contain:

- repository `tests/`, `tools/`, `staging/`, `reports/`, or `vendor/` state;
- local deployment receipts or machine-specific manifests;
- saves or user data;
- Cyberpunk executables, stock archives, `final.redscripts`, or other proprietary game files;
- Dark Future or Project E3 executing content;
- frameworks merely inherited from an old developer machine;
- unexplained loose legacy payload unrelated to an accepted final route.

## Authoritative overlap and load order

Biology should be authoritative for the physical systems it intentionally owns.

Where REDmod can deterministically express conflict/load-order precedence, the package/deploy process should give Biology the intended precedence for overlapping REDmod-controlled resources. However:

- do not modify unrelated files merely to “win” conflicts;
- do not claim universal dominance over redscript wrappers, RED4ext/CET/native hooks, runtime TweakDB mutation or other mechanisms outside REDmod's per-file model;
- document known overlap/incompatibility classes honestly.

A self-contained mod is not the same thing as a mod that forcibly overrides every other possible runtime mechanism.

## Repository -> package boundary

The repository root is not the player mod. It contains tests, tools, docs and build state that do not belong in the game.

The target boundary is:

```text
canonical source
  -> cloud/offline source contracts
  -> direct/native/REDmod compatibility evidence
  -> exact compile/stage against supported game
  -> official REDmod-shaped Biology artifact
  -> supported REDmod deploy/enable path
  -> normal Steam launch
  -> attended acceptance of that exact package
```

Raw repository source may remain fail-closed where necessary for development. Candidate builders may open accepted development gates only in immutable staged copies.

## Current clean-room builder is transitional

`tools/Build-CleanRoomTestPackage.ps1` remains useful while the migration is underway because it enforces fresh source, exact compile, owned-package provenance and non-deployment. It must **not** be mistaken for the final artifact architecture if it still emits the old game-root-shaped RealPass/framework layout.

The migration should evolve or replace that builder so broad attended testing eventually builds the same `mods/Biology`/REDmod-shaped artifact intended for players.

Do not spend large effort polishing the old root-package shape as though it were final while the REDmod migration remains unresolved.

## Dependency and notice policy

`manifest/distribution.json` remains authoritative for currently allowed/blocked/not-required runtime components during migration, but it must be revised as dependencies are removed.

Every bundled generic dependency must be the exact pinned upstream version, hash-verified from its official release source, and accompanied by required license/third-party notices.

`docs/DEPENDENCY-AUDIT.md` records engineering/license evidence. A technically working dependency is not automatically approved or still necessary.

## Patch compatibility before packaging

Before broad testing after a Cyberpunk/REDmod patch or before changing a foundational native seam, run the read-only compatibility audit through the canonical operator catalog in `docs/LOCAL-OPERATOR-COMMANDS.md`.

For REDmod-specific questions that the tracked snapshot cannot answer, prefer a targeted direct probe against the user's clean supported game installation over community guesswork.

See `docs/PATCH-RESILIENCE.md`, `docs/LOCAL-GAME-REFERENCE.md`, and `docs/BIOLOGY-REDMOD-MIGRATION.md`.

## Clean-room and iteration testing

The source checkout is disposable for every attended user-facing build: use a fresh clone/download of canonical `main`.

The game installation has two valid tiers:

- **Iteration:** remove/account for the previous package, prove the whole installation matches the recorded vanilla baseline, then install the new release-shaped artifact.
- **Milestone clean-room:** uninstall Cyberpunk, delete residual game directory, reinstall, refresh/capture baseline, then install/deploy the new artifact.

A full game reinstall is deliberately **not** required for every small iteration or normal player removal. It is reserved for structural/package/dependency changes whose prior ownership cannot be proven, unexplained residue/baseline drift, game/framework patch transitions, or deliberate release-confidence milestones.

See `docs/CLEAN-ROOM-TESTING.md` and `docs/PLAYER-DISABLE-UNINSTALL.md`.

## Parallel implementation

The REDmod migration is a large project and should normally be split across 2–3 branches when safe. Follow `docs/PARALLEL-AGENT-WORKFLOW.md`.

Preferred initial lanes:

- official REDmod/package/dependency architecture;
- runtime/script/native seam classification and migration;
- Biology product/UI/settings identity.

Each lane merges only when internally coherent and green. Broad in-game acceptance happens after selected lanes converge into canonical `main`, not by contaminating the game separately for every branch.

## CI vs local evidence

Cloud CI can establish source/model/contract/package-policy consistency. It cannot prove:

- REDmod deployment behavior on the supported local game;
- launcher ON/OFF activation semantics in Cyberpunk 2.31;
- native UI rendering;
- actual game event semantics;
- self-contained hard-uninstall behavior against an installed release-shaped artifact;
- save persistence behavior;
- quest compatibility;
- combat feel/calibration;
- runtime latency/performance;
- third-party overlap behavior.

Those remain attended local gates against the exact release-shaped package.

## Release gate

Do not publish a player release merely because source compiles or a ZIP assembles. A release candidate needs, at minimum:

- cloud/source contracts green;
- every current runtime route classified and justified;
- minimal dependency graph demonstrated;
- local native/REDmod contract evidence green for the supported game;
- exact package compilation/staging green;
- artifact/provenance/dependency policy green;
- official REDmod deploy/enable path proven;
- attended launcher ON -> Biology active, launcher OFF -> Biology inactive/native, OFF -> ON restore;
- attended double-click `Uninstall Biology.exe` hard removal with changed-file refusal and another-REDmod preservation;
- clean-room normal Steam boot;
- attended Biology/settings/scanner/presentation validation;
- attended physical combat/armor/wound/bleeding/pain/treatment validation;
- save/reload/time progression validation;
- representative base-game + Phantom Liberty quest-safety validation;
- acceptable runtime performance;
- required notices/checksums present;
- install/disable/remove instructions understandable without development context.

## Recovery philosophy

Biology does not maintain a multi-generation rollback chain or an extra automatic save-backup system for ordinary development.

The player uninstaller relies on the immutable Biology ownership receipt and exact hashes. Changed or ambiguous files are preserved rather than guessed away. The stricter recorded vanilla baseline remains the developer authority for proving a reused installation is completely clean.

If a prior package cannot be fully accounted for or baseline state cannot be restored, escalate to a milestone uninstall/delete/reinstall. Public removal is simple because package identity and ownership are narrow and explicit, not because Biology runs a persistent cleanup service or recursively owns shared game/mod roots.
