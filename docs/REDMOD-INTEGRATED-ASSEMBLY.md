# Biology integrated REDmod-first assembly

Status: **PLAYABLE CANDIDATE ASSEMBLY — live acceptance pending**  
Issue: #28  
Branch: `agent/redmod-integrated-assembly`  
Integrated source base: `bfd6f7469139c64f0b9185724619a37e4ced5eca`  
Target game: Cyberpunk 2077 `2.31`

## Purpose

This is the successor to the non-playable foundation skeleton documented in `REDMOD-PACKAGE-FOUNDATION.md`.

PRs #31, #32 and #33 are now integrated on canonical main. The packaging lane can therefore assemble the actual Biology runtime rather than guessing what the UI/body/presentation lanes will need.

The integrated candidate is **REDmod-first, not REDmod-only**:

- `mods/Biology` is the official first-party REDmod package identity and deployment authority;
- the complete merged Biology-owned REDscript runtime remains outside `mods/Biology` because the accepted hooks are narrow additive/wrapper seams and are classified `REDSCRIPT-BETTER`;
- generic framework files outside `mods/Biology` are included only when the current merged candidate has a concrete consumer;
- every installed file is individually owned, hashed and attributed;
- shared roots such as `r6`, `engine`, `red4ext` and `bin` are never recursively Biology-owned;
- no Dark Future or Project E3 runtime content is included.

## Canonical build route

The canonical integrated candidate builder is:

```powershell
pwsh ./tools/Build-BiologyPackage.ps1
```

The optional explicit game-root form is:

```powershell
pwsh ./tools/Build-BiologyPackage.ps1 `
  -GameRoot 'C:\Games\Steam\steamapps\common\Cyberpunk 2077'
```

The builder does **not** deploy or launch the game. It reads the supported installed game only for version validation and exact REDscript compilation.

Artifact naming:

```text
biology-integrated-<UTC timestamp>-<12-char source SHA>.zip
```

The ZIP contents are already game-root-shaped. The official first-party identity inside it is always:

```text
mods/
└── Biology/
    └── info.json
```

The artifact also contains the exact supplemental runtime files described below plus:

```text
biology/build-manifest.json
biology/provenance.json
BIOLOGY-VERSION.txt
SHA256SUMS.txt
INSTALL.txt
UNINSTALL.txt
LICENSES/<retained dependency>.txt
```

## Exact compile is a hard artifact gate

`Build-BiologyPackage.ps1` calls `Build-OwnedRuntimeProfile.ps1`, which:

1. constructs the complete merged Biology-owned source candidate from the current `src/redscript/CyberpunkRealism/*.reds` tree;
2. opens release activation gates only in immutable staged copies;
3. combines that source with exactly the retained generic runtime plumbing;
4. calls `Compile-Profile.ps1` against the installed Cyberpunk 2077 2.31 `r6/cache/final.redscripts`;
5. requires compiler exit code `0`, zero diagnostic errors and a non-empty output bundle;
6. records the exact compile result before the player ZIP can be emitted.

This is exact language/type compilation against the supported game bundle. It is **not** native runtime, UI, save, REDmod recognition or attended gameplay acceptance.

If exact compilation fails in a Lane B-owned Biology shell/body/lifecycle source, route the defect back to the Biology UI/runtime lane. If it fails in Lane C-owned HUD/nameplate/settings source, route it back to presentation/settings. The packaging lane should not redesign those subsystems to make compilation pass.

## Integrated package shape

### REDmod-native identity

- `mods/Biology/info.json`

No empty archives/tweaks/scripts/audio folders are manufactured. Add those only when Biology actually owns a REDmod-native payload for the route.

### Biology-owned supplemental REDscript

The complete accepted merged source is installed under:

```text
r6/scripts/CyberpunkRealism/
```

These files are Biology-owned and classified `REDSCRIPT-BETTER`. They remain outside `mods/Biology` because REDmod `.script` modding would require whole vanilla-path file replacement for hooks currently expressed as narrow additions/wrappers.

### Generic runtime files

The integrated candidate currently retains exactly four generic components:

| Component | Current status | Why it remains in this candidate | Final direction |
| --- | --- | --- | --- |
| official REDmod | required platform | package/deployment authority | retain; game-provided, never bundled |
| redscript `0.5.31` | required current runtime | direct consumer: merged Biology additive/wrapper runtime, body UI hooks, HUD/nameplate hooks and native seams | retain while those seams remain narrower than whole-file REDmod replacement |
| Mod Settings `0.2.21` | temporary retained blocker | current accessible/persistent adapter for the two Biology-owned Boolean preferences | remove when Lane C provides/accepts replacement provider or deliberately moves the master boundary to install/deploy |
| ArchiveXL `1.27.3` | temporary transitive | dependency of current Mod Settings adapter; no direct Biology consumer | remove with Mod Settings unless a new direct consumer is proven |
| RED4ext `1.30.0` | temporary transitive | plumbing for ArchiveXL/Mod Settings; no Biology-owned DLL/plugin | remove with that chain unless a new direct native consumer is proven |

The table lists official REDmod separately because it is a required game/platform component rather than bundled third-party payload.

### Dependencies removed from the integrated candidate

These have no current merged Biology consumer and are not bundled:

- TweakXL;
- Codeware;
- Input Loader;
- Dark Future runtime;
- Project E3 runtime.

No dependency survives because an older RealPass package happened to use it.

## Exact Lane C settings-provider blocker

PR #33 completed the important semantic decoupling: Biology owns the meaning and accessors for:

- **Enable Biology**;
- **E3-inspired HUD + nameplates**.

`CRRealpassSettings.IsEnabled(...)` and `UseE3FirstPersonHudVisuals(...)` are provider-neutral consumers. The Mod Settings listener is guarded by module availability.

However, provider-neutral semantics are not themselves a player-accessible persistent settings provider. The merged source does **not** yet contain another accepted UI/persistence surface for those two booleans.

Therefore removing Mod Settings now would leave the default values available internally but would remove the current attended-test path for:

- master Biology disable/yield-to-vanilla;
- E3 presentation ON/OFF comparison;
- persistence of those choices through the documented session boundary.

This is a **presentation/settings lane blocker**, not a request for the packaging lane to invent a Biology settings UI. The follow-up requirement for Lane C is narrowly defined:

> Provide and accept a player-accessible persistent provider for the existing two provider-neutral Boolean semantics, or deliberately decide that the whole-mod master becomes an install/deploy boundary. Do not add new settings semantics. Once that replacement is merged, re-run the dependency audit and remove Mod Settings + ArchiveXL + RED4ext if no other consumer appears.

## Ownership and uninstall

`biology/build-manifest.json` is the exact installed-file ownership record. Every ordinary payload file records:

- relative path;
- SHA-256;
- owner;
- component;
- routing classification;
- replacement policy.

The first-party roots owned as directories are only:

- `mods/Biology`;
- `biology` package metadata.

Supplemental files under shared roots are owned **per file**. Uninstall/reset must never recursively delete:

- `bin`;
- `archive`;
- `engine`;
- `r6`;
- `red4ext`.

`SHA256SUMS.txt` covers the finalized owner manifest and every other final artifact file except itself. The owner manifest does not recursively hash itself.

## Deterministic REDmod deployment

The supported 2.31 probe established:

```text
tools/redmod/bin/redMod.exe
file version 2.3.1.0
product version 2.31
```

It also established that relying on REDmod's default-root heuristic can resolve the wrong root. Biology therefore always passes the game root explicitly.

Developer/direct-probe helper:

```powershell
pwsh ./tools/Deploy-BiologyRedmod.ps1 `
  -GameRoot 'C:\Games\Steam\steamapps\common\Cyberpunk 2077'
```

Equivalent official command shape:

```powershell
& '<Cyberpunk 2077>\tools\redmod\bin\redMod.exe' deploy `
  '-root=<Cyberpunk 2077>'
```

Deployment success is not the same thing as launcher enablement, relaunch persistence or in-game acceptance.

## PKG status after integrated assembly

| Item | Integrated assembly status | Remaining gate |
| --- | --- | --- |
| PKG-01 | PLAYABLE PACKAGE PREPARED | actual supported-install Biology recognition/deploy and enable/disable evidence |
| PKG-02 | COMPLETE FOR INTEGRATED ASSEMBLY | fresh committed source can construct release-shaped candidate; successful local run must exact-compile first |
| PKG-03 | DETERMINISTIC DEPLOY PATH PREPARED | enable state and ordinary Steam relaunch persistence remain direct-game evidence |
| PKG-04 | CONTRACT/ARTIFACT OWNERSHIP COMPLETE | milestone clean uninstall/reset must be observed against recorded vanilla baseline |
| PKG-05 | OPEN | harmless reversible REDmod overlap/precedence fixture still required |
| PKG-06 | OPEN UNTIL DIRECT REPLACEMENT PROOF | new route is canonical for the integrated candidate, but the old known-working clean-room route remains present until exact build + deploy demonstrates equivalent/better reproducibility/functionality |
| PKG-07 | READY FOR PARENT MILESTONE HANDOFF AFTER BUILD/CI | first attended integrated test must be MILESTONE CLEAN-ROOM because package/dependency architecture changed structurally |

## DEP status after merged Lane B + Lane C audit

| Item | Status |
| --- | --- |
| DEP-01 Mod Settings | retained temporarily with exact Lane C provider blocker; still `REMOVE/RETHINK` final direction |
| DEP-02 ArchiveXL | retained only transitively with Mod Settings; no direct Biology consumer |
| DEP-03 RED4ext | retained only transitively with settings chain; no Biology-owned native plugin |
| DEP-04 redscript | retained, `REDSCRIPT-BETTER`, direct merged runtime consumer |
| DEP-05 source-mod runtime | complete: no Dark Future / Project E3 runtime allowed |
| DEP-06 dependency graph | updated to integrated current consumers/status/ownership |

## Remaining direct-game gates

The parent integration thread must coordinate these after this follow-up is merged:

1. actual Biology REDmod recognition/deployment;
2. REDmod enable/disable behavior;
3. normal Steam relaunch persistence;
4. clean uninstall/reset against the refreshed recorded vanilla baseline;
5. PKG-05 harmless overlap/precedence fixture;
6. the combined Lane B/Lane C attended acceptance checklist already recorded by their merged PRs/roadmap.

Do not close any of these from CI, exact compilation, documentation or upstream REDmod behavior alone.

## Milestone test mode

This integration is a structural package/dependency migration. The first user-facing integrated acceptance after merge must therefore be:

**MILESTONE CLEAN-ROOM**

The parent thread, not this worker lane, issues the attended handoff. It must use a fresh canonical `main`, a freshly baselined/reinstalled supported game as required by `CLEAN-ROOM-TESTING.md`, and the exact game-root-shaped ZIP produced by the canonical builder.

## PKG-06 transition rule

`Build-BiologyPackage.ps1` is the obvious canonical route for this integrated REDmod-first candidate.

The old RealPass-era clean-room/package tools remain in the repository temporarily as rollback/reference until the new route:

- exact-compiles the integrated source;
- produces its owned release artifact reproducibly;
- successfully deploys through official REDmod;
- reaches or exceeds the old route's functional/reproducibility baseline.

Only then may a later cleanup mark/remove the superseded active instructions/tooling. This follow-up must not delete a working fallback merely because the new architecture is preferable on paper.
