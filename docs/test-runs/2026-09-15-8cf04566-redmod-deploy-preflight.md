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
- PR #38 — parent-owned deploy validation fix discovered during this same milestone preflight

## Expected acceptance

- [x] supported Cyberpunk 2.31 clean installation is proven before Biology install
- [x] exact integrated source builds and exact-compiles successfully
- [x] release-shaped ZIP installs `mods/Biology/info.json` and exact ownership metadata
- [x] official REDmod consumes the explicit game root
- [x] official REDmod recognizes/deploys Biology
- [ ] attended gameplay launch and Lane B/Lane C acceptance

## Observed results

### PASS

- Strict comparison against the tracked vanilla baseline passed: `4967` files exactly matched.
- Fresh baseline capture passed: `4967` files, `85.1 GiB`, Cyberpunk `2.31`.
- Integrated package build passed and exact-compiled the merged runtime.
- Package artifact policy passed with `107` final files.
- Installed package exposed `mods/Biology/info.json`, `biology/build-manifest.json`, and `BIOLOGY-VERSION.txt`.
- After the parent-owned deploy helper was repaired in PR #38, the targeted probe consumed the actual game root and REDmod reported:
  - `Found mod "Biology" (v0.1.0) in folder "Biology" (enabled; not deployed; )`
  - `Needs deployment: true`
  - all five `[DEPLOY]` stages ran through Finalize
  - `r6\cache\modded\mods.json` was written under the supported Cyberpunk install
  - `Commandlet deploy has succeeded.`
- The repaired helper returned PASS only after observing non-empty REDmod discovery plus positive deploy completion evidence.

### FAIL / PARTIAL

- Initial deployment attempt was invalid because `redMod.exe` ignored the supplied root, fell back to `C:\`, found no mods, and still exited `0`.
- That false-positive behavior is now fixed in PR #38 and was not accepted as deployment evidence.
- Attended gameplay behavior has not yet been exercised.

## Evidence

- Workspace: `C:\Games\Biology-Test-2026-09-15-8cf04566`
- Candidate source remained exact detached SHA `8cf045664b5e4d8b4b014edfc98bf2f8eb270ba5`.
- Artifact path: `C:\Games\Biology-Test-2026-09-15-8cf04566\candidate\staging\biology-packages\biology-integrated-20260915-061136-8cf045664b5e.zip`
- Artifact SHA-256: `42BACC73173EB95D84F3278593CD06DDAF665AA714F4C692DB03D553B91557CC`.
- Corrected deploy-tool checkout used canonical tooling commit `71eda86d247374e2e270d98c1451f95be3d5cd01`; commits after `8cf04566` changed test/operator/deploy tooling only, not the installed Biology runtime payload under test.
- Direct corrected deployment found Biology v0.1.0, marked it enabled/not deployed, required deployment, completed stages 1–5, and wrote `r6\cache\modded\mods.json`.
- No attended gameplay observations have yet been recorded.

## Findings and routing

| ID | Finding | Expected | Observed | Owner / route | Follow-up issue/branch |
|---|---|---|---|---|---|
| TEST-REDMOD-01 | deploy helper false-positive | explicit game root consumed and real deployment required before PASS | initial helper accepted exit 0 despite ignored root | parent tiny integration/test-tool fix | fixed/merged in PR #38 |
| TEST-REDMOD-02 | Biology REDmod recognition | installed `mods/Biology` is recognized/deployed on supported install | corrected direct probe found Biology v0.1.0 and completed a real five-stage deployment | packaging gate passed | no packaging follow-up required for recognition |
| TEST-GAME-01 | attended gameplay acceptance | merged Biology runtime/UI/presentation behaves correctly in-game | not yet exercised | Lane B / Lane C / parent routing based on evidence | pending attended checklist |

## KEEP / FIX / REMOVE

- KEEP — clean-room baseline and release-shaped build evidence.
- KEEP — installed exact artifact and workspace through attended gameplay acceptance.
- KEEP — fail-closed REDmod deployment validation added in PR #38.
- FIX — route any gameplay/UI/presentation failures from the upcoming attended pass to their original owner lanes.
- REMOVE — prior assumption that REDmod exit code 0 alone proves deployment.

## Milestone disposition

Preflight accepted; attended gameplay pending.

Reason: clean install, baseline, build, exact compile, artifact, install, explicit-root REDmod recognition, and deployment gates now pass. The milestone can proceed to attended in-game validation against the same exact `8cf04566` runtime artifact.

## Next integration step

- Launch Cyberpunk with the already-installed/deployed Biology artifact.
- Run the parent-issued attended checklist covering startup/relaunch persistence, Biology parent UI/runtime state, native Cyberware integrity, E3 presentation ON/OFF, nameplates, scanner/quickhack, save/reload/time progression, and failure diagnostics.
- Preserve screenshots and exact observations; route each failure by evidence rather than reopening broad lanes preemptively.
