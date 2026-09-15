# RealPass E3-inspired presentation target

Status: canonical visual target / implementation contract
Last updated: 2026-09-14

## Product decision

RealPass intentionally targets the red 2018/E3-style first-person HUD language and NPC nameplates while keeping Cyberpunk 2077's modern scanner/quickhack behavior.

The target is **not** to install or execute the external Project E3 HUD mod as a dependency. RealPass must own the final implementation so the public package remains standalone.

## Desired player-facing result

With **E3 first-person HUD visuals = On** (the default):

- ordinary first-person HUD presentation uses the red E3-inspired visual language;
- NPC nameplates use the E3-inspired presentation;
- the modern scanner and quickhack panels remain the current native Cyberpunk experience rather than reverting to the old E3 scanner;
- RealPass physiology/injury feedback may integrate into that visual language where useful, without turning it into a permanent numeric body-meter wall;
- traditional actor HP presentation is removed only after replacement feedback has passed attended acceptance.

With the setting **Off**:

- the E3-inspired visual skin/nameplate layer is disabled;
- RealPass body, combat, injury, armor, pain, treatment, recovery and other simulation behavior remains identical;
- modern scanner behavior remains unchanged.

## Ownership and provenance boundary

Historical Project E3 material is reference material. The old local integration proved that a modern-scanner + E3-HUD combination is technically possible, but its external archive/scripts are not the standalone RealPass runtime target.

Do not solve the final package by silently reintroducing `basegame_3e_demo_hud.archive`, `r6/scripts/Project E3 - HUD`, its tweak payload, or its Mod Settings class as executing dependencies.

Instead:

1. identify the native Cyberpunk controllers/resources that own each HUD element;
2. identify the visual behavior that makes the E3 presentation recognizable;
3. recreate that behavior in RealPass-owned source/assets, using native shells where practical;
4. keep the modern scanner exclusions explicit;
5. exact-compile and test the resulting seams against Cyberpunk 2077 2.31;
6. keep attribution/provenance records for reference material used during implementation.

## Historical evidence already in repository history

Earlier RealPass development successfully produced a local candidate described as **modern scanner while preserving E3 HUD assets**. Historical integration manifests also identify the original E3 archive and the HUD/nameplate/compass/quest/crosshair script areas that were involved.

Those historical commits are useful research evidence, not permission to make the final player package depend on the original external runtime.

## Implementation order

A practical owned recreation should proceed in small visible slices:

1. Mod Settings presence + single E3 visual toggle;
2. NPC nameplate visual behavior;
3. core first-person red HUD framing/status presentation;
4. compass/navigation presentation where retained;
5. quest/activity/interaction/crosshair elements that materially define the E3 look;
6. final replacement-gated removal of traditional actor HP presentation once RealPass feedback is readable;
7. broad attended testing with the modern scanner, combat, Biology, quests and Phantom Liberty.

Do not recreate old scanner assets or scanner behavior merely for visual fidelity. The modern scanner is an explicit product requirement.

## Current implementation status

As of this document's creation, the repository has the owned settings boundary and an owned scanned-civilian name fallback, but it does **not yet** contain the full red E3-style first-person HUD recreation. Do not describe the presentation as complete until an attended build visibly demonstrates it.
