# How realpass interacts with Cyberpunk 2077

Last updated: 2026-09-14

## Short version

GitHub source does nothing to the installed game by itself. RealPass becomes active only when the exact owned runtime files are installed under the Cyberpunk game root and redscript compiles/loads them.

```text
repository source
  -> cloud/offline contracts
  -> immutable owned candidate
  -> exact compile against installed Cyberpunk 2077 2.31 scripts
  -> flat verified install
  -> normal Steam launch
  -> native game events -> thin RealPass seams -> RealPass model/state -> gameplay/presentation
```

The current owned candidate needs project-original RealPass REDscript plus pinned redscript only.

## Runtime files

### RealPass REDscript

Installed under `r6/scripts/CyberpunkRealism/`.

Model/state examples:

- `BodyModel.reds`, `SleepModel.reds`, `ClockModel.reds` — shared physiology/time;
- `InjuryModel.reds`, `WoundModel.reds`, `BloodLossModel.reds`, `PainModel.reds` — physical injury consequences;
- `BallisticProfiles.reds`, `ImpactModel.reds`, `ArmorWearModel.reds` — impact/protection/wear;
- `ConditionPresentation.reds`, `BiologyPresentation.reds` — qualitative read-only projections.

Explicit patch-sensitive/native seams include:

- `BodyNativeHooks.reds`, `BodyInteractionRuntime.reds`;
- `CombatNativeBridge.reds`, `CombatProfilesNative.reds`, `CombatWoundsNative.reds`;
- `ArmorWearNative.reds`, `BloodLossNative.reds`, `InjuryEffectsNative.reds`, `PainNativeEffects.reds`;
- `FieldCareActionRuntime.reds`, `ProfessionalCareRuntime.reds`;
- `BiologyNativeUI.reds`, `NameplatesNative.reds`, `NoHealthbars.reds`.

`manifest/native-seams.json` is the allowlist for hook-bearing production files. Pure model files may not acquire native hook annotations without an intentional seam-contract change.

### redscript runtime/compiler

The owned profile stages the pinned official Windows redscript package. It is the only generic runtime selected by `m1-base` and `Build-OwnedRuntimeProfile.ps1`.

The current production source does not import RED4ext/ArchiveXL/TweakXL/Codeware/Mod Settings/Input Loader APIs. Those older framework profiles remain development history only and are not selected by the completion candidate.

### No release archive/tweak dependency

The current owned runtime does not require a custom ArchiveXL/TweakXL payload or Project E3 archive. Historical patch recipes/assets under `config/patches`, `patches/`, Git history or ignored local staging do not enter the owned candidate.

## Fail-closed canonical source

`CRBodyRuntimePolicy.Enabled()` and `CRCombatRuntimePolicy.Enabled()` remain false in canonical source. This protects a raw checkout from accidentally becoming an enabled gameplay build merely because `.reds` files were copied somewhere.

`Build-OwnedAcceptance.ps1`:

1. reads the complete production source tree;
2. rejects retired prototypes/source-mod imports/identity leakage;
3. creates immutable staged copies;
4. opens body/combat gates only in those copies;
5. exact-compiles that candidate against the installed 2.31 base script bundle.

`Build-OwnedRuntimeProfile.ps1` then combines that source candidate with pinned redscript and exact-compiles the final deployment manifest again.

## Body path

```text
native lifecycle / game time / consumable completion / player activity / wait-sleep / interactions
  -> body native adapters
  -> one persistent CRBodyRuntime body state
  -> hydration/nutrition/sleep/exertion/digestion/elimination/injury recovery
  -> qualitative Biology + model-owned effects
```

Food/drink from Backpack and Biology converge on Cyberpunk's stock consumable action. `ConsumeAction.CompleteAction` submits the completed stock item record to RealPass once; Biology does not subtract inventory or call body intake directly.

## Combat path

```text
native attack/hit
  -> projectile/weapon profile + hit region/material
  -> armor/structural interception
  -> physical impact
  -> tissue/bone/chrome wound proposal
  -> native authored protection reconciliation
  -> accepted regional injury
  -> blood/pain/impairment/treatment/recovery
```

Target level/max HP is not a causal wound input. The native HP channel remains an engine-compatibility/output boundary and final authored boss/quest/immortality/nonlethal safeguards are respected.

V and supported ordinary human NPCs use the same physical wound reasoning where the game permits it. NPC body/injury state advances with the same shared-time principles rather than an unrelated damage model.

## Presentation path

### Biology

`MenuHubLogicController` receives a dynamic RealPass Biology surface. It reads `CRBiologyPresentation` and `CRConditionPresentation` only; it does not become simulation authority.

Biology exposes qualitative needs/effects/conditions and contextual actions. Exact hidden body values remain inside model/diagnostic layers.

At a ripperdoc, the Cyberware screen remains equipment-focused and a separate Biology professional-care doorway calls the same professional-care runtime/model.

### Scanner/nameplates

The native modern scanner is preserved by not replacing it.

`NameplatesNative.reds` enriches an empty public crowd name only for a scanned ordinary civilian allowed by stock scanner/nameplate policy, then gives control back to the original nameplate renderer.

### Health bars

`NoHealthbars.reds` suppresses actor-health-specific presentation across known native visibility paths while keeping unrelated RAM/buffs/scanner/objective/vehicle state intact.

## Persistent state and saves

Body/injury/pain/NPC state is intentionally persistent. File uninstall does not rewind already-saved script state.

For ordinary development the project owner has chosen not to add another RealPass save-backup chain. Existing external/cloud save protection is considered sufficient. The accepted development recovery model is:

- `Remove-OwnedRuntime.ps1` removes recorded RealPass-installed extra files whose hashes still match;
- Steam **Verify Files** or reinstall repairs stock game files if needed;
- save-state rollback, if ever desired, uses the owner's existing save/cloud workflow rather than an automatic RealPass service.

Do not reintroduce unattended save manipulation, launch automation or background monitoring.

## Build/deployment tools

Current product path:

- `Build-OwnedAcceptance.ps1` — complete project-original source candidate + staged activation + exact compile;
- `Build-OwnedRuntimeProfile.ps1` — adds only pinned redscript, exact-compiles final manifest;
- `Prepare-OwnedSession.ps1` — runs repository checks, build, exact compile and flat install preflight/deploy;
- `Install-OwnedRuntime.ps1` — exact flat owned-file install and hash verification;
- `Remove-OwnedRuntime.ps1` — remove matching recorded RealPass files;
- `Test-ArtifactPolicy.ps1` — reject game/private/source-mod/not-required dependency content;
- `Finalize-PlayerPackage.ps1` — deterministic public-package metadata/hash finalizer after native release gates close.

Legacy integration/upgrade/rollback/source-mod presentation builders remain historical tools only and are not the normal acceptance path.

## Final player experience

After native acceptance and release packaging:

1. download one RealPass package;
2. close the game;
3. extract it into the game root;
4. launch normally through Steam.

The package is one authored experience; core realism systems are not independently switchable. No persistent special launcher, service, watcher or scheduled task is part of RealPass.
