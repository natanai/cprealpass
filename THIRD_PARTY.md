# Third-party provenance

Framework authors, pinned versions, official source URLs, archive hashes and dependency relationships are recorded in `manifest/components.json`. Captured license notices are under `LICENSES/`. The offline redscript compiler/toolchain is pinned separately in `manifest/toolchain.json`. This source repository contains no framework binaries, Cyberpunk game archives or compiled game cache.

## Current owned-candidate infrastructure

The current deployable owned candidate intentionally uses only the following generic third-party infrastructure:

- **redscript 0.5.31** — script loader/compiler plumbing;
- **RED4ext 1.30.0** — generic infrastructure required by the pinned settings dependency chain;
- **ArchiveXL 1.27.3** — generic dependency of the pinned Mod Settings build;
- **Mod Settings 0.2.21** — host for RealPass presence, its read-only managed-feature ledger and explicitly accepted binary presentation/accessibility preferences.

These dependencies do **not** own RealPass gameplay or presentation policy. Body, injury, combat, armor/protection, physical Outfit behavior, Biology, nameplate behavior, healthbar policy and the meaning/effects of RealPass settings are implemented in project-original RealPass source. TweakXL, Codeware and Input Loader remain catalogued because they were used by older development profiles, but they are not required by the current owned candidate and must not drift into its runtime artifact.

`manifest/distribution.json` is authoritative for which components may enter a future public package. Before release, every allowed pinned dependency must have its exact redistributable payload and all required license/third-party notices re-audited. The repository already retains captured notices for the pinned framework versions, but their presence here is not itself proof that a particular release archive is complete.

## Historical/reference mods

**Dark Future 2.0 by DarkFortuneTeller is reference/provenance only.** Earlier experiments adapted its needs/UI behavior, but no Dark Future gameplay script, archive, tweak payload, localization, persistent state or runtime authority is permitted in the current owned candidate or final RealPass package. Historical recipes and its captured CC BY-SA 4.0 notice may remain in the repository for provenance; they are not current runtime dependencies.

**Project E3 - HUD by Virtuoso75 is reference/provenance only.** Its visual ideas informed some presentation exploration, but the accepted RealPass runtime uses stock Cyberpunk UI behavior plus project-original RealPass code. Original or modified Project E3 scripts/assets are not permitted in the standalone RealPass runtime or package. Historical local recipes may remain for provenance and must not be mistaken for a build dependency.

Downloaded component archives stay in ignored local reference/vendor directories; generated candidates and deployment manifests stay in ignored staging/deployment storage. A local integration bundle is never authorization for public redistribution. Public packaging must be assembled from the explicit allowed-component contract and verified pinned upstream archives, not by copying whatever happens to be installed on a developer machine.
