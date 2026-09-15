# Biology player disable and uninstall contract

Status: **canonical product target; implementation pending under issue #44**  
Last updated: **2026-09-15**

This document defines how Biology must behave for players who do not normally mod Cyberpunk 2077 and for attended development testing.

The design goal is not to imitate the most common community-mod workflow. The design goal is a predictable player experience:

- install Biology once by copying/extracting the release into the game;
- use the familiar REDlauncher **Enable mods** choice to turn Biology gameplay on or off;
- use a self-contained Biology uninstaller when the player wants the files removed;
- never require a full Cyberpunk reinstall merely to remove a known Biology release.

`docs/RELEASE-ARCHITECTURE.md`, `docs/CLEAN-ROOM-TESTING.md`, the package builder, and the installed ownership manifest must converge on this contract.

## The three supported player states

### 1. Biology ON

Expected player action:

```text
Biology installed
REDlauncher: Enable mods = ON
launch Cyberpunk normally
```

Expected result:

- official REDmod recognizes/deploys the `Biology` package;
- Biology simulation and presentation run according to the Biology master/presentation settings;
- approved supplemental framework files may support Biology where still required;
- the installed ownership manifest records the exact release payload.

### 2. Vanilla-play mode

Expected player action:

```text
Biology remains installed
REDlauncher: Enable mods = OFF
launch Cyberpunk normally
```

Expected result:

- Biology behavior is inactive;
- Biology UI/presentation hooks do not visibly alter ordinary gameplay;
- Biology simulation does not advance or replace vanilla semantics;
- the player can use the installed game as their convenient vanilla comparison/play path without uninstalling Biology.

This state does **not** necessarily mean the game directory is byte-for-byte identical to Steam vanilla. Approved generic framework files may still be physically installed while they remain required by the package architecture.

The hard requirement is behavioral:

> **REDlauncher Enable mods OFF must produce vanilla-play behavior, not a partially active Biology installation.**

Every executing file that can load outside the REDmod package must therefore be audited. An out-of-package Biology-owned script/hook is acceptable only if it becomes inert/fail-open to native behavior whenever Biology's REDmod activation is absent.

Do not use a hidden Biology setting as a substitute for this contract. The launcher switch itself is the intended everyday soft-disable path.

### 3. Fully removed

Expected player action:

```text
double-click Uninstall Biology.exe
```

Expected result:

- Biology-owned files are removed safely;
- REDmod deployment/cache state is refreshed as required;
- saves are untouched;
- user preferences are preserved by default unless the player explicitly chooses to remove them;
- changed/shared/ambiguous files are reported rather than guessed about;
- no source repository, PowerShell, Git, Vortex, or mod manager is required;
- a full Cyberpunk reinstall is not required.

## Player release shape

The exact final package may evolve, but the player-facing release should include a self-contained uninstaller and the ownership metadata it needs. Conceptually:

```text
Cyberpunk 2077/
├── mods/
│   └── Biology/
│       └── ...
├── <only unavoidable approved supplemental runtime files>
└── Biology/
    ├── Uninstall Biology.exe
    ├── build-manifest.json or equivalent immutable ownership receipt
    └── version metadata
```

The existing `biology/build-manifest.json` contract may be reused/evolved. Avoid maintaining two contradictory ownership manifests.

The player uninstaller must not depend on repository `tools/` or on PowerShell 7 being installed.

## Uninstaller safety contract

The uninstaller is an ownership verifier first and a deletion tool second.

Before deleting any ordinary payload file it must prove that the path is part of the installed Biology release and that the current file is safe to remove under the release's ownership rules.

At minimum it must:

1. validate the Cyberpunk game root;
2. refuse to operate while `Cyberpunk2077.exe` is running;
3. load and validate the installed Biology ownership/version metadata;
4. reject unsafe rooted or `..` paths;
5. reject duplicate manifest paths;
6. verify expected file hashes for Biology-owned payload before automatic deletion;
7. understand the difference between `biology-owned` and approved generic dependency ownership;
8. never recursively delete shared roots;
9. remove only now-empty directories reached from files it safely removed;
10. never touch saves;
11. preserve settings/preferences by default;
12. refresh official REDmod deployment state as necessary after removal;
13. produce an explicit final report.

### Changed file rule

If a file recorded as Biology-owned no longer matches the installed release hash:

```text
DO NOT DELETE IT AUTOMATICALLY.
```

Report it as changed and leave it in place by default.

The same principle applies to files that are unexpectedly missing or whose ownership has become ambiguous.

This avoids destroying a later mod/update that reused or modified a path after Biology was installed.

### Shared roots that must never be recursively owned

The uninstaller must never treat these shared directory roots as recursively Biology-owned merely because Biology has files beneath them:

- `archive`
- `bin`
- `engine`
- `r6`
- `red4ext`
- the game-root `mods` directory

`mods/Biology` itself is Biology's package namespace, but removal should still be driven by its ownership/manifest contract rather than an unbounded game-root recursive delete.

## Bundled generic dependencies

Current migration builds may still contain generic dependencies such as redscript, RED4ext, ArchiveXL, and Mod Settings.

These require special care because another mod may later use the same framework.

The uninstaller must not blindly remove a generic dependency solely because Biology originally installed it if doing so could break another subsequently installed mod.

The implementation lane must define and test a conservative policy. Safe options may include, depending on the exact dependency and available evidence:

- remove only exact Biology-bundled dependency files when no evidence of sharing/change exists;
- leave a changed/shared framework installed and report it;
- progressively eliminate bundled framework dependencies so the problem disappears.

The preferred long-term architecture remains the smallest dependency graph that satisfies Biology's actual needs.

## REDlauncher OFF activation audit

Issue #44 must inventory every current runtime path and answer:

```text
Does this file/code path still execute or alter gameplay when REDlauncher Enable mods is OFF?
```

The audit must cover at least:

- `mods/Biology` REDmod content;
- Biology-owned redscript source staged outside REDmod;
- redscript framework/bootstrap behavior;
- Mod Settings listener/config behavior;
- ArchiveXL/RED4ext runtime behavior;
- any loose `archive/pc/mod` Biology content if such a route exists;
- generated/deployed REDmod cache/output state;
- any future native extension.

If Biology-owned additive script code necessarily remains loadable with REDmod disabled, it must have a robust activation signal whose absent state returns native behavior. Compile-time presence alone cannot equal Biology activation.

## Self-contained executable target

The public uninstaller should be a single Windows executable or comparably self-contained player-facing binary.

Implementation choice is not fixed by this document, but acceptance requires:

- no PowerShell prerequisite;
- no Git prerequisite;
- no repository checkout;
- no mod manager;
- usable by double-clicking;
- deterministic logs/reporting;
- automated safety tests around its deletion planner.

A small .NET single-file executable, native executable, or another maintainable single-binary approach may be used. The implementation PR must justify the choice with respect to build reproducibility, dependency footprint, antivirus/signing implications, and patch resilience.

The deletion/ownership planner should be testable independently from the UI/front-end so safety logic is not hidden inside button handlers.

## Developer reset vs player uninstall

`tools/Reset-BiologyIteration.ps1` is currently a conservative developer cleanup implementation. It validates package hashes, removes owned payload, and then performs an exhaustive vanilla-baseline comparison.

It is valuable reference logic, but it is **not** the final player uninstaller because it:

- requires repository tooling and PowerShell;
- assumes the tracked developer vanilla baseline is available;
- performs an expensive whole-game hash pass appropriate to strict iteration proof rather than every ordinary uninstall.

The player uninstaller should reuse the same safety principles without requiring the whole developer environment.

After the player uninstaller exists, the developer command surface should be adjusted so routine iteration can use the same uninstall core/contract where practical instead of maintaining divergent deletion rules.

## Clean-room policy after this feature

A full Steam uninstall + residual directory deletion + reinstall remains a valid **milestone clean-room** tool, but it becomes exceptional.

Use it for situations such as:

- Cyberpunk/REDmod patched and the canonical clean reference needs refresh;
- a structural migration moved paths that the previous ownership receipt cannot safely account for;
- the prior manifest is missing/corrupt;
- unexplained residue remains after safe uninstall;
- package/framework state cannot be proven;
- deliberate release-level from-scratch confidence testing.

Do **not** require it merely because the user wants to remove a normal known Biology build.

Normal development should prefer:

```text
known installed Biology release
-> safe manifest-driven uninstall/reset
-> targeted or strict verification as appropriate
-> next exact candidate
```

## Required attended acceptance

Issue #44 is not complete from source tests alone.

The parent integration flow must eventually test at least:

### Soft-disable comparison

Same installed release and save/environment:

1. REDlauncher Enable mods ON -> Biology visibly/behaviorally active.
2. Quit fully.
3. REDlauncher Enable mods OFF -> Biology behavior inactive and vanilla presentation/gameplay restored as defined by this contract.
4. Quit fully.
5. REDlauncher Enable mods ON -> Biology returns without reinstall/re-extraction.

### Hard uninstall

From an exact release-shaped installed Biology build:

1. close Cyberpunk;
2. run `Uninstall Biology.exe` as a normal player;
3. verify owned paths are removed;
4. verify saves remain;
5. verify REDmod state is coherent;
6. launch Cyberpunk normally with Biology removed;
7. perform targeted or strict baseline/residue verification appropriate to the milestone.

### Tamper/shared-file safety

Automated tests must prove the deletion planner refuses/retains changed or unsafe paths. Direct attended destructive testing of intentionally corrupted shared files is not required when deterministic tests cover the planner safely.

## Failure philosophy

When ownership is uncertain, Biology must fail safe rather than "clean aggressively."

A partial uninstall that clearly says:

```text
Biology removed, but 2 changed files were left in place for safety.
```

is preferable to deleting another mod's file or a game file.

Full reinstall remains the last-resort recovery path for genuinely unprovable state, not the default Biology uninstall mechanism.
