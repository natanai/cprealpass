# realpass project status

Last updated: 2026-09-14
Canonical product goals: `AGREED-GOALS.md`
Current milestone: complete owned candidate for fresh local compile/deploy/live acceptance

## Milestone status

**Repository-side live-test milestone: complete pending exact-head CI/merge.**

**1.0 release-readiness estimate: 50% (unchanged until live/native gates close).**

Those are intentionally different measures. The implementation, architecture, source ownership, cloud-safe contracts and local operator path needed to produce the next broad candidate are now present in the repository. The remaining high-value evidence can only come from the installed Cyberpunk 2077 2.31 environment: fresh exact compile, deployment, live interaction/rendering, physical gameplay calibration, persistence, quest compatibility and performance.

A source-complete candidate is not a gameplay-accepted release. Do not raise the 1.0 percentage merely because more source was written.

## Product target

realpass is one coherent Cyberpunk 2077 + Phantom Liberty realism overhaul with a **realpass-owned executing gameplay/presentation runtime**.

Core rules:

- vanilla-first: preserve CDPR names, item identities, animations, screens and interaction flows where they can host the physical model;
- one authored release experience, not a player-configurable collection of gameplay modules;
- physical combat and injury are causal, regional and material-aware rather than level/HP-sponge driven;
- body simulation may be numerically deep internally, while the player experiences plausible sensations/consequences rather than arbitrary meters;
- **Backpack = possessions; Biology = embodied state**;
- Cyberware remains equipment-focused; a ripperdoc may expose contextual Biology professional care;
- the modern native scanner/quickhack flow remains authoritative;
- traditional actor HP bars remain hidden while unrelated objective/vehicle/RAM/status information stays usable;
- MaxDoc remains MaxDoc and is modeled as analgesia, not magical tissue/blood/chrome repair;
- normal installation/launch should become one package + ordinary Steam launch, without Vortex knowledge or a persistent custom launcher.

## Current owned runtime

The completion candidate is intentionally minimal:

- project-original `r6/scripts/CyberpunkRealism/*.reds` runtime;
- pinned **redscript** plumbing only.

The owned profile does **not** require RED4ext, ArchiveXL, TweakXL, Codeware, Mod Settings or Input Loader. Dark Future and Project E3 remain historical/reference material only and are forbidden from owned/live/public runtime manifests.

Canonical body/combat activation remains fail-closed in repository source. `Build-OwnedAcceptance.ps1` opens those gates only in immutable staged copies for an exact candidate, and `Build-OwnedRuntimeProfile.ps1` exact-compiles both the owned source candidate and final redscript-only deployment profile before install.

## Implemented authorities

### Body

Project-original shared physiology/time state covers nutrition, hydration, sleep/wake pressure, exertion, digestion/elimination, recovery and restrained hygiene interactions. Native lifecycle, completed consumable, wait/sleep and interaction adapters feed the same body authority.

### Combat / armor / injury

The owned pipeline includes projectile/weapon/ammunition profiles, hit region, protective coverage, penetration/impact, regional tissue/bone/chrome wound routing, blood loss, impairment, armor wear, pain/analgesia, field care, professional biological/mechanical care, recovery, injury provenance and supported NPC progression.

Native authored boss/quest/immortality/nonlethal safeguards remain the final compatibility boundary.

### Biology presentation

`BiologyPresentation.reds` and `BiologyNativeUI.reds` implement the canonical body-state surface.

- qualitative bodily needs/effects rather than raw percentages;
- active conditions only; healthy regions stay quiet;
- condition detail reads authoritative RealPass injury/provenance/pain state;
- `Eat…` / `Drink…` enumerate actual carried stacks;
- food preserves stock `Eat` actions, drinks preserve stock `Drink` actions, and generic `Consume` is only the stock fallback;
- stock item localization/quantities remain authoritative;
- completed stock `ConsumeAction` remains the single intake adapter into the RealPass body;
- dressing/support use the shared timed field-care runtime;
- ripperdoc-only Biology professional care uses the shared professional-care runtime;
- Biology closes/clears its picker when the native hub deactivates, preventing root-level UI leakage into other fullscreen menus.

The superseded `ConditionNativeUI.reds` / `CYBERWARE | CONDITION` implementation has been removed from production source.

### Presentation / scanner / names

- `NoHealthbars.reds` suppresses known actor-health visibility paths without blanket-hiding unrelated HUD state.
- The native modern scanner/quickhack flow is preserved by not replacing it.
- `NameplatesNative.reds` provides a narrow scanned-civilian public-name fallback before the stock renderer runs. It requires stock crowd-nameplate/scanner permission, scan completion, no hidden/alternative/quest identity, and never becomes a second nameplate renderer.

## Build / install / recovery path

The normal local acceptance entry point is:

```powershell
pwsh ./tools/Prepare-OwnedSession.ps1
```

It runs cloud-safe repository checks, creates a fresh immutable build ID, acquires/stages pinned redscript only, builds the complete project-original source tree, exact-compiles against the installed Cyberpunk 2077 2.31 base script bundle, exact-compiles the final deployment manifest, and plans the flat install without changing the game.

If that passes:

```powershell
pwsh ./tools/Prepare-OwnedSession.ps1 -Deploy
```

The deploy path installs only the exact current manifest payload, verifies copied hashes, records `owned-current.json`, removes known retired/source-mod runtime residue, verifies residue absence and stops without launching Cyberpunk.

`Remove-OwnedRuntime.ps1` removes matching RealPass-owned extra files. Steam **Verify Files** or reinstall remains the stock-game repair authority. The accepted development path does not maintain a redundant RealPass save-backup/rollback chain and does not start background services/watchers/loggers.

## Evidence already obtained

- Pure-model/property/architecture tests cover body, sleep, clock, combat, ballistics, wound routing, injury, blood loss, armor wear, field care, professional care, pain, injury effects, NPC progression, runtime ownership, settings/release policy, artifact policy and no-healthbar behavior.
- A previous owned source candidate exact-compiled successfully against Nat's installed Cyberpunk 2077 2.31 environment on 2026-09-13. That compile predates the final Biology/nameplate completion and therefore remains evidence for the broader owned architecture, **not** compile proof for the current head.
- The completion branch has repeatedly passed cloud CI during the migration; the final merge gate requires a green run for the exact final branch head.
- Public current/decompiled Cyberpunk script references were used to audit the new native boundaries, including `MenuHubLogicController`, `RipperDocGameController`, `TransactionSystem.GetItemList/GetItemQuantity`, `ItemActionsHelper` Eat/Drink/Consume paths, item-name localization, Ink text/widget APIs, `NameplateVisualsLogicController.SetVisualData`, quest-target access, hide-name flags, alternative identities and stock scanner visibility policy.

## Remaining gates — deliberately local/live

The repository should not invent more speculative architecture to substitute for these checks:

1. **Fresh exact current-head compile.** The new Biology and owned nameplate seams must compile against Nat's installed 2.31 scripts.
2. **Flat deployment + boot.** Verify exact installed hashes, no retired/source-mod runtime residue, normal Steam startup and save load.
3. **Biology acceptance.** Layout/input, hub lifecycle, actual-inventory Eat/Drink, qualitative needs/conditions, field care and ripperdoc professional care.
4. **Body calibration.** Consumption/absorption, game-time progression, exertion/recovery, wait vs sleep, bathroom/washing and save/reload.
5. **Combat/injury/pain acceptance.** Physical hit routing, armor coverage/wear, regional impairment, bleeding, MaxDoc analgesia/overuse, treatment and persistence in both V and ordinary human NPC directions.
6. **Presentation acceptance.** Actor-health suppression, native scanner/quickhacks, scanned-civilian naming and no hidden/quest/alternative identity leakage.
7. **Special compatibility.** Bosses/MaxTac, authored protections, nonlethal paths, drones/mechanical targets, companions, base-game and Phantom Liberty critical sequences.
8. **Performance.** No severe script errors, runaway callbacks/widgets, obvious latency regression or quest blockers over an attended session.
9. **Release packaging.** Only after native acceptance: final calibration, notices/checksums and deterministic one-download player artifact.

`docs/ATTENDED-ACCEPTANCE.md` is the canonical broad live-test checklist.

## Rules for future agents

- Read `AGREED-GOALS.md` first. Explicit newer user decisions supersede stale implementation text.
- Do not restore Dark Future/Project E3 executing ownership or obsolete framework dependencies to solve a local native failure.
- Preserve vanilla identities and interactions when changing the underlying mechanic is sufficient.
- Keep patch-sensitive engine hooks in `manifest/native-seams.json`; stable models remain engine-independent.
- Do not interpret cloud CI or compilation as gameplay acceptance.
- Do not expose internal body/injury numbers merely because the simulation tracks them.
- Do not reintroduce public core-system toggles, generic health-sponge scaling, redundant save-backup machinery, unattended launch automation or background monitoring.
- Live failures should become narrow native-seam/model/calibration issues and be fixed against concrete evidence.
