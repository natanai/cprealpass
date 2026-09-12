# realpass

A consolidated Cyberpunk 2077 + Phantom Liberty realism overhaul in development. realpass is intended to make the physical world and body behave more credibly without turning the game into a collection of arbitrary difficulty systems.

Core scope: connected needs/sleep/exertion, localized injury and recovery, realistic projectile/impact behavior, physical armor/clothing coverage, relevant cyberware physiology, and restrained presentation needed to communicate those systems. Weather control, economy rebalancing, artificial scarcity, added random encounters, travel restrictions and a separate outfit/transmog system are intentionally out of scope.

## Current milestone

The current presentation/body candidate combines realpass settings and UI naming, corrected backpack needs placement, a clear toilet action, recoverable exertion fatigue and restrained E3-inspired presentation. Playtest screenshots confirmed a readable scanned civilian nameplate and distinct Flush / Use toilet labels. The current quiet local candidate restores the modern hold-L1 scanner and quickhack panels while retaining selected E3 HUD presentation; native scanner rendering and the broader body/save acceptance batch remain pending.

Regional injury, armor, NPC progression, blood loss and treatment modules are present. Combat activation remains deliberately gated until the impact -> armor/cyberware -> tissue injury -> blood loss/impairment -> treatment pipeline is ready for coherent native gameplay testing.

The project now also contains a pure `RuntimePolicyModel` that encodes the intended independent module/subtoggle semantics while keeping player intent separate from native acceptance. It is packaged in the redistribution-safe development/source artifact, but the live body/combat adapters are **not yet wired to it**; their existing safety gates remain closed until local compile/native acceptance work is ready.

## Project status

The repository contains a durable progress ledger so work can continue cleanly across agents and long conversations:

- [Project status and completion estimate](docs/PROJECT-STATUS.md)
- [Chronological worklog](docs/WORKLOG.md)
- [Realism specification](REALISM-SPEC.md)
- [Modular runtime architecture](docs/MODULAR-ARCHITECTURE.md)
- [Unified settings architecture](docs/SETTINGS-ARCHITECTURE.md)
- [Combat calibration plan](docs/COMBAT-CALIBRATION.md)
- [Roadmap](docs/ROADMAP.md)
- [Release / one-download architecture](docs/RELEASE-ARCHITECTURE.md)
- Machine-readable acceptance gates: `manifest/acceptance.json`

The status ledger records a conservative percentage toward a gameplay-validated, safely distributable 1.0. Offline code or compilation alone does not count as full completion.

## Distribution goal

The finished player experience should be one download: extract/copy realpass into the Cyberpunk 2077 game root (or use one equally simple bootstrap installer only if licensing/update safety requires it), then launch Cyberpunk normally through Steam. A permanent realpass launcher should not be required.

GitHub source does not modify an installed game by itself. Runtime files must first be assembled into the paths Cyberpunk and its mod frameworks load. `manifest/distribution.json` records the machine-readable packaging policy and release gates. Public playable artifacts remain gated until dependency redistribution, native gameplay acceptance, save/update safety and artifact verification are complete.

A cloud-safe GitHub Actions workflow now runs offline model/contract checks, verifies the exact built ZIP against the artifact deny/block policy, and uploads a clearly labeled redistribution-safe **development source package**. That artifact is not yet the finished drag-and-drop gameplay mod.

## Source layout

- `src/redscript` and `src/tweaks`: physiology, timing, integration, injury, combat and presentation modules plus interaction records.
- `config`: authored presets, hash-pinned reference inventories and adaptation recipes.
- `manifest`: dependency, settings, runtime-module, feature-inventory, acceptance and distribution contracts.
- `tools`: component acquisition, staging, compilation, packaging, artifact policy and reversible deployment.
- `tests`: model, integration, contract, policy and file-transaction checks.
- `package` and `LICENSES`: package documentation and dependency notices.
- `docs`: architecture, calibration, acceptance notes, roadmap, status and worklog.

## Third-party/reference material

Project E3 - HUD by Virtuoso75 is currently a separately acquired reference/integration dependency. The recorded permission model permits credited modifications but requires the original mod and prohibits standalone redistribution of modified assets. Therefore E3 assets are **not** part of the planned standalone realpass ZIP under the current terms; the needed presentation behavior must eventually be replaced by independently distributable realpass implementation or separately permitted.

Dark Future adaptations retain DarkFortuneTeller's credit and CC BY-SA 4.0 notices. Framework authors, pinned versions, hashes and license evidence are recorded in `manifest/components.json` and `THIRD_PARTY.md`. Third-party authorship is preserved even when the end-user experience is one realpass download.

Downloaded components, game assets, generated staging output, local deployment manifests, runtime reports, machine inventories and save backups remain outside the public repository.

## Development policy

Prepare coherent batches and verify the exact build before gameplay testing. Do not launch the game unattended or leave watchers, recorders, services, scheduled jobs or other external helpers running. Temporary diagnostics require explicit player attendance and remain off otherwise.

Back up saves before deployment. File rollback does not migrate a save backward or remove persistent mod state. Keep required script providers and a matching pre-update save backup.
