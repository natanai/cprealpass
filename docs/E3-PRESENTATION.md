# Biology E3-inspired presentation target

Status: canonical visual target; current attended follow-up #40 / PR #46 pending integration and live acceptance  
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

## Historical pre-REDmod evidence

The exact clean-room candidate at `ec8ba06451c3cbacabfad24f1479e1537147d0c9` launched successfully, but the attended test showed that the presentation target above was **not implemented yet in that candidate**.

Observed:

- ordinary first-person gameplay still looked substantially like the modern/vanilla HUD rather than the intended red E3-inspired visual language;
- the intended E3-inspired NPC nameplates were not active;
- the ordinary player health bar was hidden, proving that at least some presentation behavior was executing;
- turning `E3 first-person HUD visuals` OFF did not restore the player health bar;
- Mod Settings still used the transitional `REALPASS`, `Enable RealPass`, and `E3 first-person HUD visuals` labels.

Interpretation:

- **do not count health-bar suppression as evidence that the E3 presentation works.** Barless actor-health is a Biology-wide product rule while Biology is enabled;
- the optional E3 preference needs a clearly visible E3-specific effect: ON should visibly activate the Biology-owned E3-inspired HUD/nameplate treatment; OFF should yield those E3-specific treatments while leaving Biology simulation and barless-health policy unchanged;
- the pre-refactor candidate therefore lacked a convincing attended success signal because the full HUD/nameplate treatment was absent.

Historical details remain in `PRE-REDMOD-LIVE-BASELINE-2026-09-15.md`.

## Integrated REDmod attended evidence

The first integrated REDmod-first artifact was built from:

`8cf045664b5e4d8b4b014edfc98bf2f8eb270ba5`

Artifact:

`biology-integrated-20260915-061136-8cf045664b5e.zip`

SHA-256:

`42BACC73173EB95D84F3278593CD06DDAF665AA714F4C692DB03D553B91557CC`

On Cyberpunk 2077 2.31, the attended presentation findings were:

- ordinary quest/objective/minimap/weapon/prompt presentation still read overwhelmingly modern/retail with E3 ON;
- an ordinary civilian look/focus did not show the intended ambient E3 nameplate;
- police showed only a narrow red strip rather than a complete identity treatment;
- the modern scanner/quickhack UI remained intact and must stay native/current.

Those failures are routed to issue #40 / PR #46. Source/compile success in that worker does not upgrade the live gate to passed.

## Ownership and provenance boundary

Historical Project E3 material is reference material. The old local integration proved that a modern-scanner + E3-HUD combination is technically possible, but its external archive/scripts are not the standalone Biology runtime target.

Do not solve the final package by silently reintroducing `basegame_3e_demo_hud.archive`, `r6/scripts/Project E3 - HUD`, its tweak payload, or its Mod Settings class as executing dependencies.

Instead:

1. identify the current native Cyberpunk controllers/resources that own each accepted HUD/nameplate element;
2. use installed official REDmod scripts/tooling as first-choice readable evidence for current controller/event/field ownership;
3. recreate the accepted visual behavior in Biology-owned source/assets, using native shells where practical;
4. keep modern scanner/quickhack exclusions explicit;
5. exact-compile and test the resulting seams against Cyberpunk 2077 2.31;
6. keep attribution/provenance records for reference material used during implementation.

A tiny additive Biology wrapper may still be preferable to copying a whole vanilla `.script` file when direct investigation shows it is the smaller compatibility surface. REDmod-first does not mean blindly REDmod-only.

## Current accepted presentation scope

The current neutral persistent first-person target includes:

- quest/objective tracker presentation;
- minimap/navigation framing;
- weapon/ammo presentation;
- applicable ordinary crosshair/focus treatment;
- quick-slot/D-pad presentation;
- existing lower-left non-health presentation;
- ambient NPC identity/nameplates;
- police/combatant nameplate completion where native authority permits it;
- scan-acquired identity enrichment through native-authority nameplates where appropriate.

Explicitly outside this follow-up scope:

- dialogue UI redesign;
- interaction-menu redesign;
- activity-log replacement;
- phone-call UI redesign;
- Project E3's old scanner/quickhack/focus composition;
- broad import of Project E3 runtime/archive/tweak content.

The top-right quest tracker is part of the neutral HUD target. The modern scanner/quickhack experience is a hard preserve.

## Current implementation status

Issue #40 / PR #46 (`agent/presentation-attended-followup`) is the current implementation owner.

At its latest reviewed worker head `ff08ac0661180ad09afedba920e3962c4117c928`, the worker reported and directly audited:

- exact compile against installed Cyberpunk 2077 2.31 `final.redscripts`: PASS;
- current native presentation symbol/signature probe: PASS;
- `MinimapContainerController` confirmed as the current persistent minimap presentation host;
- `IronsightGameController` confirmed as a separate weapon/ironsight path rather than the minimap host;
- current native nameplate controller/name/frame/display-name fields confirmed;
- Biology-owned adapters added for current quest, minimap/navigation, weapon, Tech-Hex crosshair and hotkey controllers;
- ambient civilian-name fallback broadened only where native public-name/scanner rules permit identity;
- native name text/frame styled rather than creating a second floating-label identity system;
- scanner/quickhack ownership, health-bar ownership, damage preview, level and rarity remain outside the E3 skin;
- Project E3 executing content remains absent.

This is **native-compile ready, not attended accepted**. Parent integration still has to combine it with the other current workers and record live behavior from one release-shaped canonical-main candidate.

## Matched screenshot acceptance contract

The presentation lane is accepted only from matched attended captures/observations from the integrated candidate, including:

- ordinary gameplay, E3 ON;
- ordinary gameplay, E3 OFF;
- quest/objective/minimap/weapon areas in comparable states;
- random civilian focus/nameplate, E3 ON;
- police/combatant nameplate, E3 ON;
- post-scan identity enrichment where applicable;
- modern scanner/quickhack while E3 ON;
- ordinary navigation/combat transitions without stale red widgets or overlap.

A reviewer should be able to identify the E3 ON capture without reading the settings screen. If the only visible difference is the player health bar, the implementation has failed the intended presentation target.

## Acceptance boundary

Do not call this presentation complete merely because:

- source tests are green;
- native symbols were found;
- exact compilation succeeds;
- one red widget renders;
- actor health bars are hidden.

The current live gate is visual and behavioral: the ordinary persistent HUD must read recognizably E3-inspired with the preference ON, must yield that skin with the preference OFF, ambient NPC identity treatment must work through native authority, and the modern scanner/quickhack UI must remain intact.
