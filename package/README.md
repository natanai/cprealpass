# Biology development/source artifact 0.1.0-dev.20

This redistribution-safe **development/source artifact** contains a selected set of project-original Biology model/policy sources plus the authored stock-protection recipe. It exists for offline model review, CI packaging, artifact-policy checks, and source handoff.

It is **not the player package** and **does not activate gameplay**. The canonical playable artifact is built by `tools/Build-BiologyPackage.ps1` and is centered on the official `mods/Biology` REDmod identity.

## What this artifact contains

The source artifact intentionally exercises representative project-original model families such as:

- runtime policy;
- body resources/input/clock/sleep/forecast models;
- impact/projectile/injury/wound models;
- stock protection and armor-wear models;
- injury-effect, field-care, blood-loss, and NPC progression models.

It deliberately excludes native gameplay adapters, UI/controller hooks, settings adapters, packaged framework binaries, Cyberpunk game files, Dark Future runtime, and Project E3 runtime material.

The declared `redscript 0.5.31` prerequisite belongs only to this model/source artifact's source context. It is **not** a complete statement of the current playable candidate's dependency graph.

For current runtime dependencies, read:

- `manifest/dependency-graph.json`
- `manifest/distribution.json`
- `manifest/redmod-package.json`
- `docs/REDMOD-INTEGRATED-ASSEMBLY.md`

The current integrated playable candidate directly requires redscript for Biology-owned additive/wrapper seams and temporarily retains Mod Settings plus its ArchiveXL/RED4ext dependency chain while a current accepted preference/activation boundary still needs them. Those temporary dependencies do not own Biology simulation or presentation policy.

## Provenance and safety

Dark Future and Project E3 are reference/provenance sources only. Their scripts, archives, tweak payloads, assets, settings/save state, or other executing runtime content are not permitted in this development artifact or in a Biology player artifact.

The stock-protection recipe uses stock record identifiers plus project-authored coefficients. It contains no Cyberpunk assets or copied upstream implementation bodies. Values remain gameplay/model assumptions requiring attended calibration rather than measured material claims.

This artifact starts no process, installs nothing, deploys nothing, and should never be extracted over the game as though it were a release.

## What this artifact does not prove

Successful source packaging/model tests do not prove:

- Cyberpunk runtime registration or serialization;
- live item/controller availability;
- REDmod recognition/deployment;
- UI rendering;
- mission/save compatibility;
- performance;
- launcher-off behavior;
- hard-uninstall safety;
- attended gameplay acceptance.

Those gates belong to the canonical Biology build/test flow and direct evidence recorded by the parent integration thread.

Version `0.1.0-dev.20` is the development-source recipe version, not the public Biology release version.
