# Third-party provenance

Framework authors, pinned versions, official source URLs, archive hashes and dependencies are recorded in manifest/components.json. Captured license notices are under LICENSES.

RED4ext, redscript, ArchiveXL, TweakXL, Codeware, Mod Settings and Input Loader are external dependencies. Their inspected licenses and required bundled notices must be retained. The offline redscript compiler is pinned separately in manifest/toolchain.json. This source repository contains no framework binaries, game archives or compiled game cache.

Dark Future 2.0 by DarkFortuneTeller is the current needs/UI integration base. Its source adaptations and the selected English localization overrides are subject to CC BY-SA 4.0. Patch recipes preserve author, source and change notices; the license is captured in LICENSES/darkfuture-2.0.txt. Original realpass modules and adapted third-party material must not be conflated when packaging.

Project E3 - HUD by Virtuoso75 is a separately acquired original dependency. The local inventory and presentation recipe are recorded in config/realpass-e3.json and tools/Build-RealpassPresentation.ps1. The author permits credited modifications, requires published changes to depend on the original mod, and prohibits standalone redistribution of modified assets. This repository supplies adaptation recipes, not original E3 scripts or assets.

Downloaded components stay in ignored local reference/vendor directories; adapted runtime files and generated manifests stay in ignored staging/deployment storage. A local integration bundle is not authorization for public redistribution. Complete transitive asset/notice review and satisfy each dependency's terms before publishing a gameplay package.
