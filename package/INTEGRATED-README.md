# realpass — integrated local body candidate

Build: {{BUILD_ID}}

This is a complete local installation bundle for the realpass quiet body/presentation candidate: the original shared-body runtime and UI adapters, the adapted Dark Future integration and its assets, and the seven pinned framework dependencies. It includes the sleep-clamp correction, explicit Use toilet caption and inventory guidance for inspecting needs through the weapon wheel, and top-anchored backpack needs to address header clipping. Exertion fatigue now recovers separately from time awake, preventing ordinary activity from creating permanent morning energy drift. The mod identifies itself as realpass in the body interface and settings/help presentation, with original dependency author credits retained. Current regional-treatment and combat modules are included for integration, but combat and its treatment UI remain disabled. Body authority is enabled; test diagnostics are disabled. No helper, logger, launcher, startup entry or scheduled task is installed.

E3 HUD and NPC focus nameplates are an external local dependency and are not included in this archive. The supplied ReferenceMods copy is being integrated through a separate local manifest. Combat activation still requires its combined acceptance work. This is not a finished overhaul, a new gameplay-validated release, or a public redistribution package. Public release still requires transitive asset/notice review. Framework authorship and Dark Future attribution remain in provenance/components.json and LICENSES; modified upstream scripts retain their author/change notices. Adapted Dark Future material remains subject to CC BY-SA 4.0. The project does not claim authorship of dependency components. Do not upload this bundle as a standalone E3 mod.

## Verify, then install during an agreed test window

Use PowerShell 7 or newer. Extract the whole realpass directory to a new folder outside the game, preserving payload, tools, LICENSES, provenance and manifest. Keep the supplied bundle-index.json. Its hashes detect missing/changed files; they are not a digital signature or a substitute for checking the archive hash against the project's build report.

Run tools/Verify-IntegrationBundle.ps1 to check the extracted files. For a dry run, invoke tools/Install-IntegrationBundle.ps1 with -GameRoot pointing at Cyberpunk 2077, -StateRoot pointing at the durable deployment-state folder, and -WhatIf. The game must be closed. The dry run may create a state directory/lock file but does not change game or save files.

For an upgrade of the existing project installation, reuse its original snapshots/deployment-state directory. Never start a second receipt chain for the same installation. Keep that entire directory across bundle updates. For a first managed install, choose an empty durable state folder outside the extracted bundle. Unknown existing file collisions stop before game writes.

The actual install also requires -SaveRoot pointing at the existing Cyberpunk save directory. It first runs the same collision/version/hash/receipt preflight, then copies and verifies all saves under StateRoot/save-backups, applies the existing reversible deployment/upgrade transaction and verifies installed hashes. This local candidate requires existing saves; a fresh-new-game bootstrap without saves is not supplied yet. No baseline.json containing a personal save path is bundled. The installer does not launch Cyberpunk or enable diagnostics.

The fatigue update adds one persistent field with a zero default. Existing sleep pressure and debt are retained; old accumulated pressure is not silently cleared. Forecasts copy the same field and use the same recovery equations. Thirty-day core simulations pass, but actual game-clock timing, field initialization in native saves, and menu placement remain unverified.

## Recovery and persistence

The installer prints an immutable receipt path. Use tools/Rollback.ps1 -ReceiptPath with that path for file recovery, then tools/Verify-Deployment.ps1 -ReceiptPath with the resulting current receipt. If a transaction was interrupted, inspect and recover that same state chain before retrying. These tools refuse unexpected file drift instead of overwriting it.

File rollback does not migrate a save backward or safely remove a gameplay provider from it. Do not load a candidate save after removing its script types. Keep the pre-install save backup and retain the full Dark Future provider unless its author-prescribed disable/save/exit procedure has been completed. Restoring older code may require restoring a matching pre-test save. Save backups are never automatically restored or deleted.

## Acceptance still required

The full script set compiles offline. File transaction/recovery tests do not prove in-game menus, food/drink effects, sleep/time-skip results, body persistence or NPC behavior. The next attended session should combine needs inspection, consumption, toilet/washing, sleep/wait, save/reload and E3 focus behavior in the separate E3-containing profile. Until then this bundle is prepared for local review and controlled testing, not automatically promoted to the live game.