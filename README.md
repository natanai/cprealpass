# realpass

A consolidated Cyberpunk 2077 + Phantom Liberty realism overhaul in development, with sparse E3-inspired presentation and connected needs, sleep, exertion, injury and recovery.

## Current milestone

The current presentation/body candidate combines realpass settings and UI naming, corrected backpack needs placement, a clear toilet action, recoverable exertion fatigue and a restrained E3 HUD integration. NPC nameplates retain the game's authored hiding and scan rules. Regional injury, armor, NPC progression, blood loss and treatment modules are present; combat activation remains deferred until its integration and gameplay checks are ready.

The first native E3 session exposed empty scanned-NPC nameplates and a duplicate Flush caption. The next quiet candidate corrects the visibility/name fallback and gives Use toilet its own localized interaction record. It compiles 115 scripts; 69 presentation staging, 63 nameplate behavior and 31 interaction checks pass. This 226-file candidate passed an exact upgrade/rollback and is installed locally for the next launch; native rendering still needs verification. The body bundle previously passed 429 installation/recovery checks. Those results do not establish native rendering, save behavior, combat or quest compatibility.

Weather control is not a release requirement.

## Source layout

- src/redscript and src/tweaks: physiology, timing, integration, injury and presentation modules plus interaction records.
- config: authored presets, hash-pinned reference inventory and adaptation recipes.
- tools: component acquisition, staging, compilation, packaging and reversible deployment.
- tests: model, integration and file-transaction checks.
- package and LICENSES: package documentation and dependency notices.

See [realism principles](REALISM-SPEC.md), [third-party credits](THIRD_PARTY.md), and the [roadmap](docs/ROADMAP.md).

This is a source repository, not a finished public installation bundle. Builds need the locally acquired dependencies, game installation and generated staging manifests. Runtime reports, machine inventories, save backups, screenshots, downloaded assets and the earlier machine-specific development history are kept outside this public branch.

## E3 reference

The E3 recipe expects the original [Project E3 - HUD by Virtuoso75](https://www.nexusmods.com/cyberpunk2077/mods/8800) under the directory recorded in config/realpass-e3.json. The recipe verifies the supplied original files before applying local presentation changes. Downloaded E3 scripts and assets are not included here. Published adaptations require the original mod; no standalone modified asset redistribution is provided.

Dark Future adaptations retain DarkFortuneTeller's credit and CC BY-SA 4.0 notices. Internal script and saved-state identities remain stable across the realpass display-name change.

## Development policy

Prepare coherent batches and verify the exact build before gameplay testing. Do not launch the game unattended or leave watchers, recorders, services, scheduled jobs or other external helpers running. Temporary diagnostics require explicit player attendance and remain off otherwise.

Back up saves before deployment. File rollback does not migrate a save backward or remove persistent mod state. Keep required script providers and a matching pre-update save backup.
