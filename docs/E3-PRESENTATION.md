# Biology E3-inspired presentation target

Status: canonical visual target / implementation contract
Last updated: 2026-09-15

## Product decision

Biology intentionally targets the red 2018/E3-style first-person HUD language and NPC nameplates while keeping Cyberpunk 2077's modern scanner/quickhack behavior.

The target is **not** to install or execute the external Project E3 HUD mod as a dependency. Biology must own the final implementation so the public package remains standalone.

## Desired player-facing result

With **Enable Biology = On** and the E3-inspired presentation preference = On (both defaults while those runtime controls remain part of the product):

- ordinary first-person HUD presentation uses the red E3-inspired visual language;
- NPC nameplates use the E3-inspired presentation;
- the modern scanner and quickhack panels remain the current native Cyberpunk experience rather than reverting to the old E3 scanner;
- Biology physiology/injury feedback may integrate into that visual language where useful, without turning it into a permanent numeric body-meter wall;
- traditional actor HP presentation is hidden. Attended feedback explicitly rejected the restored native red health indicator as ordinary Biology-on behavior.

With the E3-inspired presentation preference = Off while Biology remains enabled:

- the E3-inspired visual skin/nameplate layer is disabled;
- Biology body, combat, injury, armor, pain, treatment, recovery and other simulation behavior remains identical;
- the barless Biology actor-health decision remains in force;
- modern scanner behavior remains unchanged.

With **Enable Biology = Off**, if the final architecture retains an in-game master switch:

- Biology gameplay and presentation adapters yield to native Cyberpunk behavior after the documented session/reload boundary;
- native actor-health presentation may return;
- native Cyberware/wardrobe/other wrapped UI behavior remains authoritative;
- the E3 preference has no effect until Biology is enabled again.

The REDmod migration may conclude that the official mod enable/disable boundary makes a separate in-game master switch unnecessary. Do not preserve the old RealPass toggle merely for historical compatibility.

## 2026-09-15 attended pre-REDmod evidence

The exact clean-room candidate at `ec8ba06451c3cbacabfad24f1479e1537147d0c9` launched successfully, but the attended test showed that the presentation target above was **not implemented yet in that candidate**.

Observed:

- ordinary first-person gameplay still looked substantially like the modern/vanilla HUD rather than the intended red E3-inspired visual language;
- the intended E3-inspired NPC nameplates were not active;
- the ordinary player health bar was hidden, proving that at least some presentation behavior was executing;
- turning `E3 first-person HUD visuals` OFF did not restore the player health bar;
- Mod Settings still used the transitional `REALPASS`, `Enable RealPass`, and `E3 first-person HUD visuals` labels.

Interpretation:

- **do not count health-bar suppression as evidence that the E3 presentation works.** Barless actor-health is a Biology-wide product rule while Biology is enabled.
- The optional E3 preference needs a clearly visible E3-specific effect: ON should visibly activate the Biology-owned E3-inspired HUD/nameplate treatment; OFF should yield those E3-specific treatments while leaving Biology simulation and barless-health policy unchanged.
- The pre-refactor candidate therefore lacked a convincing attended success signal because the full HUD/nameplate treatment was absent.

The full baseline and issue IDs are in:

- `PRE-REDMOD-LIVE-BASELINE-2026-09-15.md`
- `ACTIVE-REDMOD-ROADMAP.md` (`PRES-01`..`PRES-08`, `SET-01`..`SET-05`)

## Ownership and provenance boundary

Historical Project E3 material is reference material. The old local integration proved that a modern-scanner + E3-HUD combination is technically possible, but its external archive/scripts are not the standalone Biology runtime target.

Do not solve the final package by silently reintroducing `basegame_3e_demo_hud.archive`, `r6/scripts/Project E3 - HUD`, its tweak payload, or its Mod Settings class as executing dependencies.

Instead:

1. identify the native Cyberpunk controllers/resources that own each HUD element;
2. identify the visual behavior that makes the E3 presentation recognizable;
3. recreate that behavior in Biology-owned source/assets, using native shells where practical;
4. keep the modern scanner exclusions explicit;
5. exact-compile and test the resulting seams against Cyberpunk 2077 2.31;
6. keep attribution/provenance records for reference material used during implementation.

## Historical evidence already in repository history

Earlier development successfully produced a local candidate described as **modern scanner while preserving E3 HUD assets**. Historical integration manifests also identify the original E3 archive and the HUD/nameplate/compass/quest/crosshair script areas that were involved.

Those historical commits are useful research evidence, not permission to make the final player package depend on the original external runtime.

## Implementation order

A practical owned recreation should proceed in small visible slices:

1. identify/validate the current native HUD and nameplate seams on 2.31;
2. produce one unmistakable first-person E3-inspired visual slice whose ON/OFF states are visibly different;
3. implement Biology-owned E3-inspired NPC nameplates;
4. expand core red HUD framing/status presentation;
5. audit compass/navigation/quest/activity/interaction/crosshair elements and migrate only the pieces that materially define the intended look;
6. integrate restrained Biology bodily/injury cues without rebuilding permanent numeric body meters;
7. move/rename the preference into the final provider-neutral Biology settings surface;
8. broad attended testing with matched E3 ON/OFF screenshots, NPC focus, the modern scanner, combat, Biology menus, quests and Phantom Liberty.

Do not recreate old scanner assets or scanner behavior merely for visual fidelity. The modern scanner is an explicit product requirement.

## Matched screenshot acceptance contract

The presentation lane should be testable with matched captures from the same location/state:

- ordinary gameplay, E3 ON;
- ordinary gameplay, E3 OFF;
- NPC focus/nameplate, E3 ON;
- NPC focus/nameplate, E3 OFF where applicable;
- modern scanner/quickhack while E3 ON.

A reviewer should be able to identify the E3 ON capture without reading the settings screen. If the only visible difference is the player health bar, the implementation has failed the intended presentation target.

## Current implementation status

Issue #30's `agent/presentation-hud-nameplates` lane now contains the first project-original executable presentation slices:

- `E3FirstPersonHud.reds` creates a Biology-owned red asymmetric lower-left first-person rail/frame treatment on the native biomonitor HUD host. It is controlled only by the E3 presentation preference and does not render or read a health value.
- `E3NameplatesNative.reds` creates a matching Biology-owned red rail/frame treatment on the native NPC nameplate controller. Native identity, projection and visibility rules remain authoritative.
- `NameplatesNative.reds` remains the separate data-only scanned-civilian public-name fallback.
- `NoHealthbars.reds` remains the separate Biology-wide actor-health suppression policy and does not consult the E3 presentation preference.
- the player-facing settings surface now says `Biology`, `Enable Biology`, and `E3-inspired HUD + nameplates`, while compatibility identifiers remain internal where renaming them would add unnecessary migration risk;
- cloud regression checks explicitly reject Project E3 runtime dependencies, scanner/quickhack ownership, external E3 UI resources, health-state coupling, and unregistered 2.31 native seams.

These source slices are **implemented, but not yet attended-accepted**. Cloud CI can prove ownership/contract boundaries, not visual placement or exact game-runtime compatibility. Before calling the presentation complete or merge-ready, exact-compile the combined release-shaped candidate against Cyberpunk 2077 2.31 and perform the matched screenshot acceptance above. If the first-person frame is not visually unmistakable enough in the live game, expand the owned framing/status language before acceptance rather than treating hidden health bars as success.

Compass/navigation/quest/activity/interaction/crosshair migration remains optional follow-on presentation work unless attended comparison shows those elements are necessary for the intended recognizable 2018/E3 result.
