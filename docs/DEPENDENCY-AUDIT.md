# Biology dependency and redistribution audit

Status: **current engineering audit**  
Last evidence review: **2026-09-15**

This is an engineering release audit, not legal advice. `manifest/components.json` records pinned technical inputs and `manifest/distribution.json` records the current machine-readable release disposition.

A dependency is not entitled to remain because an older RealPass build used it or because another mod bundles it.

## Current integrated dependency picture

The first integrated REDmod-first Biology milestone on Cyberpunk 2077 2.31 retained:

- official REDmod — game-provided package/deployment foundation;
- redscript 0.5.31 — direct retained consumer for Biology-owned narrow additive/wrapper seams;
- Mod Settings 0.2.21 — temporary provider for the small player preference surface;
- ArchiveXL 1.27.3 — temporary transitive dependency of the current Mod Settings route;
- RED4ext 1.30.0 — temporary transitive plumbing for the retained settings/framework chain.

It did **not** require TweakXL, Codeware, Input Loader, Dark Future runtime, or Project E3 runtime.

Issue #44 must additionally audit whether any supplemental path remains behaviorally active when REDlauncher `Enable mods` is OFF. Launcher-off vanilla-play behavior is a product requirement, so a physically installed framework may remain only if Biology-specific behavior is inert or otherwise correctly gated.

## Decision rule

A generic framework can remain in a public Biology release only when all of the following are true for the exact pinned version:

1. a current accepted Biology feature requires it;
2. a smaller vanilla/REDmod/Biology-owned route is not materially safer;
3. license/redistribution terms permit the intended binary distribution;
4. required notices are identified and preserved;
5. exact official release files/hashes are inventoried;
6. only required files are selected unless upstream packaging terms require otherwise;
7. installed files are represented individually in Biology ownership/provenance metadata;
8. the artifact passes `tools/Test-ArtifactPolicy.ps1` and dependency-notice tests;
9. install/disable/uninstall semantics remain safe, including launcher-off behavior where advertised.

## Pinned framework evidence

### RED4ext 1.30.0

Pinned source/release: <https://github.com/WopsS/RED4ext/releases/tag/v1.30.0>

License: MIT plus upstream third-party notices.

Current Biology role: **temporary transitive dependency only**. Biology currently owns no RED4ext plugin. Keep only while the retained settings/framework chain genuinely requires it. Issue #44 must account for its launcher-off behavior and uninstaller ownership semantics.

### redscript 0.5.31

Pinned source/release: <https://github.com/jac3km4/redscript/releases/tag/v0.5.31>

License: MIT.

Current Biology role: **direct retained dependency** for accepted Biology-owned additive/wrapper runtime seams. Its retention is architectural, not merely settings-provider inheritance.

### ArchiveXL 1.27.3

Pinned source/release: <https://github.com/psiberx/cp2077-archive-xl/releases/tag/v1.27.3>

License: MIT plus upstream third-party notices.

Current Biology role: **temporary transitive dependency** of the current Mod Settings adapter. There is no current direct Biology resource consumer in the integrated package. Remove it when the provider chain no longer needs it.

### Mod Settings 0.2.21

Pinned source/release: <https://github.com/jackhumbert/mod_settings/releases/tag/v0.2.21>

License: MIT.

Current Biology role: **temporary provider** for the provider-neutral Biology/E3 preferences. It has no entitlement to remain in the final product. A Biology-owned surface or deliberate launcher/install boundary may replace it if that reduces dependency depth without increasing fragility.

### TweakXL 1.11.4

Pinned upstream evidence remains available in `manifest/components.json` for historical/tooling context.

Current Biology role: **not required**. Do not bundle merely because Project E3 or another historical source used it.

### Codeware 1.20.3

Pinned upstream evidence remains available for historical/tooling context.

Current Biology role: **not required**. The integrated Biology UI/presentation routes do not currently justify it.

### Input Loader 0.2.3

Pinned upstream evidence remains available for historical/tooling context.

Current Biology role: **not required**. Biology currently adds no custom input binding requiring it.

## Historical/reference gameplay and presentation sources

### Dark Future

Dark Future is **research/provenance only for the final runtime**. Historical adapted ideas/source records may remain where licensing/provenance requires them, but no executing Dark Future gameplay content may enter Biology candidates.

Do not describe Dark Future as the current needs/UI host; that was an earlier architecture.

### Project E3 - HUD

Project E3 is **local-only design archaeology/provenance**, not a runtime dependency.

`config/realpass-e3.json` preserves the exact reference inventory/version/hashes. The actual `ReferenceMods/` payload remains gitignored and must not be committed or shipped.

Issue #40 uses that reference to map HUD responsibilities to current Cyberpunk 2.31 native seams and Biology-owned presentation. Project E3 scripts, tweaks and archives remain blocked from Biology player artifacts.

## Dependency minimization before public release

Before retaining any framework:

- identify the exact accepted consumer;
- prove removing it breaks an in-scope feature or accepted provider path;
- prefer deletion over historical inertia;
- preserve required upstream notices;
- keep per-file ownership explicit;
- test hard uninstall conservatively;
- verify launcher-off behavior where Biology advertises vanilla-play mode.

The target is one understandable player download, not a claim that bundled third-party software is Biology-owned.

## Source of truth

When prose and machine-readable state disagree, treat that as a bug to fix rather than choosing whichever is convenient.

Current release disposition: `manifest/distribution.json`  
Pinned versions/hashes: `manifest/components.json`  
Install/uninstall safety contract: `manifest/install-contract.json`  
Current active work: root `ROADMAP.md` + current issues/PRs
