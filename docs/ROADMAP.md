# realpass roadmap

Last updated: 2026-09-14

The product is one locked authored realism experience. Internal module gates exist only for development/diagnosis; they are **not** player-facing feature toggles.

## Current milestone — complete owned live-test candidate

The repository-side target is complete when all remotely verifiable work is finished and the next meaningful action requires the installed Cyberpunk 2077 2.31 game.

Before merge to `main`, the completion branch must have:

1. **Owned runtime only.** All executing gameplay/presentation source is realpass-owned. Dark Future and Project E3 remain reference/history only.
2. **Minimal runtime plumbing.** The owned profile contains project-original realpass REDscript plus pinned redscript only; historical framework stacks are not carried into the live candidate without an actual dependency.
3. **One body authority.** Intake, sleep, exertion, digestion/elimination, injury, pain and recovery share the authored body clock/state.
4. **Biology presentation.** Biology is the canonical body-state interface; Backpack remains possessions; Cyberware remains equipment. Eat/Drink use the actual carried inventory and stock consumable transaction.
5. **Physical combat pipeline.** Projectile/region/protection/chrome-or-tissue injury routing, regional wounds, blood loss, impairment, field/professional care and armor wear are connected behind fail-closed canonical gates that the immutable candidate builder opens.
6. **Restrained presentation.** Traditional actor HP bars are suppressed, the modern native scanner remains authoritative, and scanned-civilian name fallback is realpass-owned.
7. **Safe build/deploy tooling.** Cloud CI is green; the exact candidate builder compiles against the installed game before install; the flat installer verifies hashes and removes known retired/source-mod residue; no unattended game launch/background service/save-backup chain exists.
8. **Synchronized contracts/docs.** `AGREED-GOALS.md`, runtime/feature/acceptance manifests and the attended-test checklist describe the current architecture rather than obsolete prototypes.

## Next milestone — attended native acceptance

After the completion branch merges, the user pulls `main` and runs the owned session tool locally. The candidate must then pass:

- exact Cyberpunk 2077 2.31 compilation;
- flat install and installed-byte verification;
- confirmation that retired/source-mod runtime residue is absent;
- normal Steam launch;
- Biology layout/input and Eat/Drink transaction behavior;
- body clock, food/drink absorption, exertion, wait/sleep, bathroom/washing and save/reload;
- physical combat/armor/wound/bleed/impairment/pain/MaxDoc/treatment behavior;
- V/NPC symmetry, bosses/MaxTac, authored immunity and nonlethal cases;
- actor-healthbar suppression without breaking RAM/buffs/scanner/objective/vehicle UI;
- scanned-civilian naming without leaking hidden/quest/alternate identities;
- critical base-game and Phantom Liberty quest flows;
- acceptable script/runtime latency.

Live findings should drive calibration or native-seam repairs. Do not reinterpret a failed live test as permission to weaken the locked realism goals.

## Release milestone

Only after attended native acceptance should the project finalize public-release calibration, notices/checksums, one-download package assembly and release-version metadata. Public release is deliberately a later gate than “ready to live test.”

## Scope exclusions

Do not spend release work on weather control, economy rebalance, arbitrary scarcity, added hardship encounters, travel restrictions, summon currencies/limits, a new outfit/transmog system, or generic difficulty penalties disconnected from the physical model. Source/reference-mod features outside the locked scope are omitted rather than retained behind toggles.
