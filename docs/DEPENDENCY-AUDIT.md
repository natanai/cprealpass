# Biology dependency and redistribution audit

Status: **current engineering audit**  
Last evidence review: **2026-09-15**

This is an engineering release audit, not legal advice. `manifest/components.json` may retain pinned historical/tooling evidence; `manifest/dependency-graph.json`, `manifest/distribution.json`, and the production build profile define the current release dependency disposition.

A dependency is not entitled to remain because an older RealPass/Biology build used it or because another mod bundles it.

## Current production dependency picture

The self-contained settings migration leaves this production runtime dependency set:

- official REDmod — game-provided package/deployment/whole-mod activation foundation;
- redscript 0.5.31 — the **only retained third-party runtime dependency** bundled by Biology.

Removed from Biology production release/build/install architecture by issue #61:

- Mod Settings 0.2.21;
- ArchiveXL 1.27.3;
- RED4ext 1.30.0.

TweakXL, Codeware, Input Loader, Dark Future runtime, and Project E3 runtime also remain not required/blocked.

REDlauncher launcher-OFF acceptance must now evaluate Biology with only redscript supplemental infrastructure remaining outside `mods/Biology`. That is a materially smaller launcher-OFF surface than the previous integrated artifact.

## Why redscript remains

redscript has concrete current consumers independent of the retired settings stack:

- project-owned Biology simulation/runtime classes;
- Biology body UI/runtime and lifecycle hooks;
- Biology-owned HUD/nameplate presentation hooks;
- additive/wrapper native seams listed in `manifest/native-seams.json`;
- `CRRealpassSettings` save-persistent ScriptableSystem state;
- the Biology-owned E3 preference control mounted on the shared Biology/Cyberware body screen.

Biology currently uses narrow additive/wrapper annotations where whole-file REDmod script replacement would copy broader vanilla implementation and increase conflict/patch surface. Full redscript elimination therefore requires a fresh dedicated lane with direct supported-game seam analysis; it is not implied by settings self-containment.

## Removed settings stack

### Mod Settings 0.2.21 — removed

Former role: temporary UI/persistence provider for the small Biology preference surface.

Current role: none. The remaining E3 Boolean is a persistent Biology `ScriptableSystem` field and is edited from Biology-owned Ink UI. No production `ModSettings.runtimeProperty`, provider module listener, package component, pause-menu registration, ownership path, or uninstaller INI surgery remains.

### ArchiveXL 1.27.3 — removed

Former role: transitive dependency of Mod Settings.

Current role: none. The dependency audit found no direct Biology resource consumer requiring ArchiveXL. It is removed with the provider stack.

### RED4ext 1.30.0 — removed

Former role: transitive native loader/plumbing for ArchiveXL/Mod Settings.

Current role: none. Biology owns no RED4ext plugin. It is removed from the production release/build/install dependency set.

A `red4ext` path may still appear in safety allow/deny documentation as a shared root that the uninstaller must never recursively delete. That safety mention does **not** make RED4ext a Biology dependency.

## Other non-required frameworks

### TweakXL 1.11.4

Pinned upstream evidence may remain in `manifest/components.json` for historical/tooling context. Current Biology role: **not required**; do not bundle.

### Codeware 1.20.3

Pinned upstream evidence may remain for historical/tooling context. Current Biology role: **not required**; do not bundle.

### Input Loader 0.2.3

Pinned upstream evidence may remain for historical/tooling context. Current Biology role: **not required**; Biology adds no current custom input binding requiring it.

## Historical/reference gameplay and presentation sources

### Dark Future

Dark Future is research/provenance only for the final runtime. No executing Dark Future gameplay content may enter Biology candidates.

### Project E3 - HUD

Project E3 is local-only design archaeology/provenance, not a runtime dependency. `config/realpass-e3.json` preserves the reference inventory/version/hashes; the actual `ReferenceMods/` payload remains gitignored and must not be committed or shipped.

## Decision rule

A generic framework can remain or be reintroduced in a public Biology release only when all of the following are true for the exact pinned version:

1. a current accepted Biology feature requires it;
2. a smaller vanilla/REDmod/Biology-owned route is not materially safer;
3. license/redistribution terms permit the intended binary distribution;
4. required notices are identified and preserved;
5. exact official release files/hashes are inventoried;
6. only required files are selected unless upstream packaging terms require otherwise;
7. installed files are represented individually in Biology ownership/provenance metadata;
8. the artifact passes source/package policy tests;
9. install/disable/uninstall semantics remain safe, including launcher-off behavior where advertised.

## Production acquisition/package consequence

`tools/Build-OwnedRuntimeProfile.ps1` explicitly acquires only `redscript` and stages the `biology-runtime` profile, which contains only `redscript`. `tools/Build-BiologyPackage.ps1` expects exactly that one retained generic component and fails closed if Mod Settings, ArchiveXL, RED4ext, or another blocked/unrequired runtime component leaks into the package.

Historical component metadata is not production entitlement. A component present in `manifest/components.json` but absent from the production profile is not downloaded/staged by the canonical Biology package path.

## Source of truth

Current release disposition: `manifest/distribution.json`  
Current runtime dependency graph: `manifest/dependency-graph.json`  
Production staging profile: `manifest/profiles.json`  
Pinned historical/tooling versions/hashes: `manifest/components.json`  
Install/uninstall safety contract: `manifest/install-contract.json` and `manifest/redmod-install-contract.json`  
Current active work: root `ROADMAP.md` + current issues/PRs
