# Attended test — REDmod-first milestone deploy preflight

Date: 2026-09-15  
Cyberpunk version: 2.31  
Test mode: MILESTONE CLEAN-ROOM  
Canonical main SHA under test: `8cf045664b5e4d8b4b014edfc98bf2f8eb270ba5`  
Artifact/package: `biology-integrated-20260915-061136-8cf045664b5e.zip`  
Artifact SHA-256: `42BACC73173EB95D84F3278593CD06DDAF665AA714F4C692DB03D553B91557CC`  
Artifact size: `3202407` bytes  
Build command: `pwsh ./tools/Build-BiologyPackage.ps1 -GameRoot 'C:\Games\Steam\steamapps\common\Cyberpunk 2077'`  
Game-state evidence: fresh Steam uninstall/reinstall; existing tracked baseline strict comparison passed for all 4967 files; fresh full SHA-256 baseline capture then hashed 85.1 GiB / 4967 files and passed.

## Included work

- PR #31 / issue #28 — REDmod foundation
- PR #32 / issue #29 — Biology UI/body runtime
- PR #33 / issue #30 — presentation/HUD/nameplates
- PR #36 / issue #28 follow-up — integrated playable REDmod-first assembly

## Expected acceptance

- [x] supported Cyberpunk 2.31 clean installation is proven before Biology install
- [x] exact integrated source builds and exact-compiles successfully
- [x] release-shaped ZIP installs `mods/Biology/info.json` and exact ownership metadata
- [ ] official REDmod consumes the explicit game root
- [ ] official REDmod recognizes/deploys Biology
- [ ] attended gameplay launch and Lane B/Lane C acceptance

## Observed results

### PASS

- Strict comparison against the tracked vanilla baseline passed: `4967` files exactly matched.
- Fresh baseline capture passed: `4967` files, `85.1 GiB`, Cyberpunk `2.31`.
- Integrated package build passed and exact-compiled the merged runtime.
- Package artifact policy passed with `107` final files.
- Installed package exposed `mods/Biology/info.json`, `biology/build-manifest.json`, and `BIOLOGY-VERSION.txt`.

### FAIL / PARTIAL

- `Deploy-BiologyRedmod.ps1` printed PASS solely because `redMod.exe` returned exit code `0`, but REDmod itself reported:
  - `No root specified, using default root path.`
  - `Invalid root path found: C:\!`
  - `No mods found, no deployment is needed!`
- Therefore the direct REDmod deployment gate did **not** pass and no gameplay launch was attempted.

## Evidence

- Workspace: `C:\Games\Biology-Test-2026-09-15-8cf04566`
- Candidate source remained exact detached SHA `8cf045664b5e4d8b4b014edfc98bf2f8eb270ba5`.
- Artifact path: `C:\Games\Biology-Test-2026-09-15-8cf04566\candidate\staging\biology-packages\biology-integrated-20260915-061136-8cf045664b5e.zip`
- Artifact SHA-256: `42BACC73173EB95D84F3278593CD06DDAF665AA714F4C692DB03D553B91557CC`.
- User stopped before launching Cyberpunk, as required by the parent handoff.

## Findings and routing

| ID | Finding | Expected | Observed | Owner / route | Follow-up issue/branch |
|---|---|---|---|---|---|
| TEST-REDMOD-01 | deploy helper false-positive | explicit game root consumed and real deployment required before PASS | REDmod ignored root, fell back to `C:\`, found no mods, exit 0 was misclassified as success | parent tiny integration/test-tool fix | `integration/redmod-deploy-validation` |
| TEST-REDMOD-02 | Biology REDmod recognition remains unknown | installed `mods/Biology` is recognized/deployed on supported install | current probe cannot distinguish package-recognition failure until root invocation is corrected | original packaging lane if reproduced after corrected root | issue #28 follow-up after targeted probe |

## KEEP / FIX / REMOVE

- KEEP — clean-room baseline and release-shaped build evidence.
- KEEP — installed exact artifact and workspace until targeted deploy probe finishes.
- FIX — deployment helper must fail closed on ignored root, invalid root, or `No mods found` even with exit 0.
- FIX — if corrected-root probe still reports no mods, route package-recognition failure to the REDmod packaging lane.
- REMOVE — prior assumption that REDmod exit code 0 alone proves deployment.

## Milestone disposition

Partially accepted.

Reason: clean install, baseline, build, exact compile, artifact, and install gates passed. Official REDmod deployment/recognition did not pass, so attended gameplay acceptance is blocked.

## Next integration step

- Merge fail-closed deployment tooling.
- Run one targeted deploy probe against the already-installed exact `8cf04566` artifact; do not reinstall or repeat the 85.1 GiB hash pass.
- If root is consumed and Biology deploys, continue the milestone from the same artifact evidence.
- If root is consumed but REDmod reports no mods, route that exact direct-game evidence back to issue #28 / REDmod packaging lane before another attended build.
