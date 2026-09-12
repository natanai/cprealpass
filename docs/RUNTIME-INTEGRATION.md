# How realpass interacts with the Cyberpunk 2077 client

## Short version

GitHub does not modify the installed game. The repository contains source, configuration and build/deployment logic. A build becomes active only after its runtime files are placed into the Cyberpunk 2077 installation paths that the game or its mod frameworks load.

Conceptually:

```text
GitHub source
  -> build/stage exact runtime files
  -> verify hashes + supported game version
  -> install/copy into Cyberpunk 2077 game root
  -> launch Cyberpunk normally
  -> framework/game loaders compile/load realpass
  -> realpass hooks receive game events and update realpass state
```

The long-term player package should hide the build/staging/deployment complexity. Development keeps it explicit because exact file ownership, rollback and save safety matter while the systems are changing quickly.

## Runtime file families

### redscript (`r6/scripts/...`)

Most realpass simulation/native integration code is redscript. The pinned redscript framework/compiler loads script source from the game installation and integrates the compiled result when Cyberpunk starts.

Project-original model/runtime examples include:

- `BodyModel.reds`, `SleepModel.reds`, `ClockModel.reds` — body/time simulation;
- `BodyRuntime.reds` — lifecycle/native body adapter (source gate currently off);
- `ImpactModel.reds`, `HitModel.reds`, `BallisticProfiles.reds` — physical impact/ballistics;
- `WoundModel.reds`, `InjuryModel.reds`, `BloodLossModel.reds` — wound/physiology state;
- `CombatNativeBridge.reds`, `CombatWoundsNative.reds` — live combat adapters (source combat gate currently off);
- `ArmorWearNative.reds`, `InjuryEffectsNative.reds`, `FieldCareNative.reds`, `NPCBodyNative.reds` — native integration for those authorities;
- `RuntimePolicyModel.reds` — engine-independent target logic for accepted-build gate + player toggle composition; not yet wired to live adapters.

A `.reds` file merely existing in GitHub has no effect on the game. It must be present in the installed/staged script set and compile successfully in the game’s environment.

### TweakDB/TweakXL data (`r6/tweaks/...`)

Some interactions/localization/tuning are better represented as TweakDB records rather than procedural script. Current source contains project tweak data under `src/tweaks`. If TweakXL remains in the final dependency graph, release staging places only the required realpass tweak payload into the appropriate game-relative path.

### RED4ext plugins (`red4ext/plugins/...` plus loader files)

RED4ext is the native plugin loader used by several framework dependencies. realpass itself is primarily redscript today, but frameworks such as ArchiveXL/TweakXL/Codeware/Mod Settings/Input Loader use the RED4ext ecosystem. A one-download release may bundle exact pinned framework runtime files only after the distribution/license audit promotes them from conditional status.

### Archive resources (`archive/pc/mod/...`)

Cyberpunk loads mod archives placed in its mod archive path. The current local presentation work can build a derived Project E3 HUD archive, but that derived E3 asset is **local integration material only** under the recorded permission model and cannot become part of the standalone realpass ZIP. The final release therefore needs independently distributable realpass presentation assets/code or new permission.

## What happens during play

### Body path

The intended data flow is:

```text
game lifecycle / game clock / consumption / actions
    -> body runtime adapter
    -> one realpass body state
    -> nutrition/hydration/sleep/exertion/digestion/elimination/recovery
    -> physical gameplay effects + contextual presentation
```

The source body gate remains disabled in the normal source tree. `Build-BodyAttended.ps1` creates a separate staged copy that opens only the body gate for controlled testing and explicitly requires combat to stay disabled. This protects normal builds from accidental activation while body timing/save behavior is still being accepted.

### Combat path

The intended data flow is:

```text
native attack/hit
    -> identify weapon/projectile + hit region
    -> resolve actual protective coverage / cybernetic structure
    -> calculate stopped/penetrating/blunt impact
    -> convert the physical result into regional wound state
    -> reconcile authored game protections
    -> commit bleeding / impairment / treatment demand
    -> send only the necessary native damage/effect output back to the game
```

Target max HP/level is not supposed to decide the physical wound. Existing offline tests explicitly check that an otherwise identical impact produces the same wound across different target health pools, while the final native-output adapter may scale/limit the engine-facing HP channel and respect authored boss/quest protections.

The source combat gate remains disabled. Having combat files compile does **not** mean combat is live.

## Persistent state and saves

Several realpass authorities are persistent by design. This is why deployment and save rollback are treated separately:

- replacing/removing files can restore the previous installed bytes;
- that does not automatically rewind persistent script state already written into a save;
- a schema-changing test may therefore require the matching pre-test save backup when reverting;
- feature toggles should suspend their authority without destructively erasing saved state unless an explicit migration says otherwise.

The existing integration installer performs file/version/hash preflight, backs up saves, and uses durable deployment receipts before applying a staged build. Those tools are development safety infrastructure, not the intended final player UX.

## Build and deployment boundary

Current relevant tools:

- `Build-BodyRuntime.ps1` / `Build-BodyAttended.ps1` — stage body source variants;
- `Build-RealpassPresentation.ps1` — local presentation integration, including modern-scanner selection;
- `Build-IntegrationBundle.ps1` — construct a full local integration bundle from already acquired/pinned components;
- `Install-IntegrationBundle.ps1` — verify/back up/deploy or upgrade that local bundle;
- `Deploy.ps1`, `Upgrade.ps1`, `Rollback.ps1`, `Verify-Deployment.ps1` — exact transactional file ownership/recovery;
- `Build-Package.ps1` — cloud-safe project-original **development/source** ZIP, not gameplay activation;
- `Test-ArtifactPolicy.ps1` — fail-closed scan for game/private/blocked content;
- `Finalize-PlayerPackage.ps1` — deterministic ownership/hash metadata finalizer for a future staged player package. It does not decide that the package is release-ready.

## Settings versus installed files

A player setting cannot install or uninstall a dependency. Runtime settings govern already installed realpass authorities. The desired effective rule is:

```text
may run = build/native acceptance gate
          AND player module toggle
          AND safe game/save lifecycle state
```

This lets the eventual public defaults be “realism on” while keeping unsafe development bridges closed until native acceptance promotes them.

A module toggle also must not merely hide UI. If injury is off, injury-owned bleeding/impairment/treatment effects must be suspended; if presentation is off, simulation state must continue independently; if combat is off, realpass stops rewriting combat and native/authored behavior remains authoritative.

## Final player experience

The completed distribution should reduce all of the above to:

1. download one verified realpass release;
2. close Cyberpunk;
3. extract/merge it into the game root (or run one finite bootstrap/install action if dependency licensing/update safety requires that route);
4. launch normally through Steam;
5. optionally change realpass modules in one settings surface.

No permanent special launcher, service, watcher or scheduled task belongs in the final design.
