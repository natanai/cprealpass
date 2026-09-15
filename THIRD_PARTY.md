# Biology third-party provenance

Framework authors, pinned versions, upstream source URLs, archive hashes, license/provenance records, and dependency relationships are recorded in `manifest/components.json`, `manifest/dependency-graph.json`, and `manifest/distribution.json`. Captured license notices are under `LICENSES/`. The offline redscript compiler/toolchain is pinned separately in `manifest/toolchain.json`.

This repository does not contain Cyberpunk game archives/executables, compiled stock game caches, or the local-only third-party reference payloads under ignored `ReferenceMods/`.

## Current runtime dependency status

The current integrated Biology candidate is REDmod-first and retains only the generic runtime pieces that still have a concrete consumer:

- **official REDmod** — game-provided package/deploy/enable authority; never bundled by Biology;
- **redscript 0.5.31** — directly required by current Biology-owned additive/wrapper runtime seams whose whole-file REDmod replacement is presently classified as a broader compatibility surface;
- **Mod Settings 0.2.21** — temporary accessible/persistent provider for the small provider-neutral Biology preference surface;
- **ArchiveXL 1.27.3** — temporary transitive dependency of the current Mod Settings provider;
- **RED4ext 1.30.0** — temporary transitive plumbing for that ArchiveXL/Mod Settings chain.

Mod Settings, ArchiveXL, and RED4ext do **not** have permanent architectural entitlement. Issue #44 owns launcher-off/hard-uninstall behavior across supplemental routes, and current dependency contracts require removal when their last accepted consumer disappears.

TweakXL, Codeware, and Input Loader are catalogued for provenance/history but are **not required by the current integrated candidate** and must not drift into a player artifact without a new concrete consumer and routing decision.

No generic framework owns Biology gameplay policy, body state, injury/combat/armor authority, Biology UI semantics, or the authored E3-inspired presentation.

## Reference mods

**Dark Future 2.0 by DarkFortuneTeller** is research/provenance only. Earlier development studied portions of its gameplay/UI behavior, but no Dark Future gameplay script, archive, tweak payload, localization, persistent state, or runtime authority is permitted in Biology.

**Project E3 - HUD by Virtuoso75** is design/controller archaeology only. `config/realpass-e3.json` preserves a durable inventory/version/hash map of the user-supplied local reference package. The actual third-party source/archive/tweak payload remains outside Git under ignored `ReferenceMods/` and is not redistributed by Biology. Issue #40 re-derives the desired presentation against current Cyberpunk/REDmod native controllers in Biology-owned code while preserving the modern scanner.

Historical filenames containing `realpass`, `darkfuture`, or `project-e3` may remain where they are clearly provenance/reference data. Their presence is not runtime authorization.

## Redistribution rule

`manifest/distribution.json` is authoritative for what may enter a Biology player artifact. Every bundled generic dependency must be pinned, attributed, licensed for the intended redistribution, individually represented in the owner manifest, and removable without recursively owning shared framework/game roots.

Downloaded component archives stay in ignored local vendor/reference storage. Public packaging must be assembled from explicit contracts and verified payloads, never by copying whatever happens to be installed on a developer machine.

For foundational capability questions, investigate vanilla Cyberpunk and the installed official CDPR/REDmod toolchain before accepting a community workaround as necessary. If a non-official framework remains, preserve the evidence showing why that route is currently narrower or more robust.
