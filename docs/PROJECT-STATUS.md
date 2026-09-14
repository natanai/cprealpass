# realpass project status

Last updated: 2026-09-14
Canonical product goals: `AGREED-GOALS.md`
Current milestone: complete integrated owned candidate for fresh local compile/deploy/live acceptance

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
- RealPass appears in Mod Settings for presence, a concise managed-feature ledger and narrowly accepted binary presentation/accessibility preferences, never numeric balance controls or core-authority switches;
- physical combat and injury are causal, regional and material-aware rather than level/HP-sponge driven;
- body simulation may be numerically deep internally, while the player experiences plausible sensations/consequences rather than arbitrary meters;
- **Backpack = possessions; Biology = embodied state**;
- Cyberware remains equipment-focused; a ripperdoc may expose contextual Biology professional care;
- vanilla Outfits are convenience **physical equipment loadouts**: applying one equips actual carried items rather than maintaining a second cosmetic/transmog authority;
- the modern native scanner/quickhack flow remains authoritative;
- the final authored target removes traditional actor HP bars, but development keeps native actor-health feedback available until RealPass replacement feedback has passed attended acceptance;
- MaxDoc remains MaxDoc and is modeled as analgesia, not magical tissue/blood/chrome repair;
- normal installation/launch should become one package + ordinary Steam launch, without Vortex knowledge or a persistent custom launcher.

## Current owned runtime

The integrated candidate keeps executing gameplay/presentation policy in project-original `r6/scripts/CyberpunkRealism/*.reds` source. Its generic deployment plumbing is intentionally narrow:

- **redscript** — script loader/compiler plumbing;
- **RED4ext + ArchiveXL + Mod Settings** — generic support required by the pinned Mod Settings release and the accepted RealPass settings surface.

The separate `m1-base` profile remains redscript-only for source/native work. The deployable `m1-owned-settings` profile adds only `red4ext`, `archivexl` and `mod-settings` around that base. TweakXL, Codeware and Input Loader are not required by this candidate. Dark Future and Project E3 remain historical/reference material only and are forbidden from owned/live/public runtime manifests.

Mod Settings does **not** own simulation policy. `RealpassSettings.reds` exposes a managed status/feature ledger and currently one binary presentation-only preference for fullscreen disorientation effects. Core body, injury, combat, armor, bleeding, recovery and cyberware-physiology authorities remain fixed for a given RealPass version.

Canonical body/combat activation remains fail-closed in repository source. `Build-OwnedAcceptance.ps1` opens those gates only in immutable staged copies for an exact candidate, and `Build-OwnedRuntimeProfile.ps1` exact-compiles both the complete owned source candidate and final constrained deployment profile before install.

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

### Physical Outfits / clothing authority

`PhysicalOutfits.reds` wraps the native `EquipmentSystemPlayerData.EquipWardrobeSet(...)` semantic boundary so the vanilla Outfit interaction can remain convenient without remaining cosmetic authority.

- recorded wardrobe visuals are resolved against actual clothing V currently carries;
- all required saved slots are preflighted before any equipment mutation;
- missing or blocked clothing fails closed instead of being conjured, substituted or silently represented by appearance only;
- the adapter does not pull items remotely from stash;
- `UnequipBlocked` and native wardrobe-disable state are respected;
- ordinary equipment transactions equip/unequip the resolved objects and visual overrides are cleared;
- armor/protection code can therefore continue to read the same physically equipped objects the player sees.

This still needs attended validation for duplicate item-record instances, missing/sold saved items, quest/special wardrobe states and interaction with worn armor condition.

### Presentation / scanner / names

- `NoHealthbars.reds` contains the known actor-health suppression seams, but player and NPC replacement-readiness gates currently remain **false**. Native actor HP is therefore intentionally retained during development until replacement cues are accepted in attended play. The final release policy remains barless.
- The native modern scanner/quickhack flow is preserved by not replacing it.
- `NameplatesNative.reds` provides a narrow scanned-civilian public-name fallback before the stock renderer runs. It requires stock crowd-nameplate/scanner permission, scan completion, no hidden/alternative/quest identity, and never becomes a second nameplate renderer.
- `PainNativeEffects.reds` consumes the fullscreen-disorientation preference only at the visual channel; pain-derived physical/weapon consequences remain authored simulation and are not player-toggleable.

## Build / install / recovery path

The normal local acceptance entry point is:

```powershell
pwsh ./tools/Prepare-OwnedSession.ps1
```

It runs cloud-safe repository checks, creates a fresh immutable build ID, acquires/stages the constrained generic profile, builds the complete project-original source tree, exact-compiles against the installed Cyberpunk 2077 2.31 base script bundle, exact-compiles the final deployment manifest, and plans the flat install without changing the game.

If that passes:

```powershell
pwsh ./tools/Prepare-OwnedSession.ps1 -Deploy
```

The deploy path installs only the exact current manifest payload, verifies copied hashes, records `owned-current.json`, removes known retired/source-mod runtime residue, verifies residue absence and stops without launching Cyberpunk.

`Remove-OwnedRuntime.ps1` removes matching RealPass-owned extra files. Steam **Verify Files** or reinstall remains the stock-game repair authority. The accepted development path does not maintain a redundant RealPass save-backup/rollback chain and does not start background services/watchers/loggers.

## Evidence already obtained

- Pure-model/property/architecture tests cover body, sleep, clock, combat, ballistics, wound routing, injury, blood loss, armor wear, field care, professional care, pain, injury effects, NPC progression, runtime ownership, settings/release policy, artifact policy, replacement-gated healthbar behavior and physical Outfit authority.
- The non-Biology implementation passed branch cloud CI before integration with the latest Biology `main`.
- The branch was then merged forward onto current `main` without overwriting Biology: the post-integration diff contains only the intended non-Biology/settings/HUD/Outfit/build-policy files and is zero commits behind `main`.
- A previous owned source candidate exact-compiled successfully against Nat's installed Cyberpunk 2077 2.31 environment on 2026-09-13. That compile predates the final Biology/nameplate/settings/physical-Outfit completion and therefore remains evidence for the broader owned architecture, **not** compile proof for the current head.
- Public current/decompiled Cyberpunk script references were used to audit the native boundaries, including `MenuHubLogicController`, `RipperDocGameController`, `TransactionSystem.GetItemList/GetItemQuantity`, `ItemActionsHelper` Eat/Drink/Consume paths, item-name localization, Ink text/widget APIs, `NameplateVisualsLogicController.SetVisualData`, quest-target access, hide-name flags, alternative identities, stock scanner visibility policy and `EquipmentSystemPlayerData.EquipWardrobeSet`.

## Remaining gates — deliberately local/live

The repository should not invent more speculative architecture to substitute for these checks:

1. **Fresh exact current-head compile.** The Biology, owned nameplate, Mod Settings, healthbar and physical-Outfit seams must compile together against Nat's installed 2.31 scripts.
2. **Flat deployment + boot.** Verify exact installed hashes, required generic plumbing, no retired/source-mod runtime residue, normal Steam startup and save load.
3. **Settings acceptance.** Confirm RealPass appears in Mod Settings, the managed feature ledger is readable, no numeric/core simulation controls exist, and the fullscreen-disorientation preference affects only that presentation channel.
4. **Biology acceptance.** Layout/input, hub lifecycle, actual-inventory Eat/Drink, qualitative needs/conditions, field care and ripperdoc professional care.
5. **Physical Outfit acceptance.** Applying a saved Outfit equips actual carried objects, armor/protection sees the same objects, missing/sold items are not conjured, and quest/special wardrobe states remain safe.
6. **Transitional HUD / presentation acceptance.** Native player/NPC actor health remains usable while replacement cues are unaccepted; once replacement evidence is sufficient, suppression can be enabled without hiding objective/vehicle/RAM/status information. Also verify native scanner/quickhacks and scanned-civilian naming without hidden/quest/alternative identity leakage.
7. **Body calibration.** Consumption/absorption, game-time progression, exertion/recovery, wait vs sleep, bathroom/washing and save/reload.
8. **Combat/injury/pain acceptance.** Physical hit routing, armor coverage/wear, regional impairment, bleeding, MaxDoc analgesia/overuse, treatment and persistence in both V and ordinary human NPC directions.
9. **Special compatibility.** Bosses/MaxTac, authored protections, nonlethal paths, drones/mechanical targets, companions, base-game and Phantom Liberty critical sequences.
10. **Performance.** No severe script errors, runaway callbacks/widgets, obvious latency regression or quest blockers over an attended session.
11. **Release packaging.** Only after native acceptance: final calibration, notices/checksums and deterministic one-download player artifact.

`docs/ATTENDED-ACCEPTANCE.md` is the canonical broad live-test checklist; the immediate non-Biology attended pass should additionally follow `docs/NONBIOLOGY-WORKPLAN.md` for settings, transitional HUD and physical-Outfit checks.

## Rules for future agents

- Read `AGREED-GOALS.md` first. Explicit newer user decisions supersede stale implementation text.
- Do not restore Dark Future/Project E3 executing ownership or obsolete framework dependencies to solve a local native failure.
- Generic framework plumbing may remain only when it is actually required by an accepted RealPass surface; it never owns gameplay policy.
- Preserve vanilla identities and interactions when changing the underlying mechanic is sufficient.
- Keep patch-sensitive engine hooks in `manifest/native-seams.json`; stable models remain engine-independent.
- Do not interpret cloud CI or compilation as gameplay acceptance.
- Do not expose internal body/injury numbers merely because the simulation tracks them.
- Do not reintroduce public core-system toggles, numeric balance controls, generic health-sponge scaling, redundant save-backup machinery, unattended launch automation or background monitoring.
- Do not re-enable cosmetic transmog as protection authority; physical equipped items must remain the armor/protection source of truth.
- Live failures should become narrow native-seam/model/calibration issues and be fixed against concrete evidence.
