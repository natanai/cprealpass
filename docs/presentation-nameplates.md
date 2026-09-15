# Biology NPC nameplates

Status: project-original identity and E3 visual seams implemented; fresh exact compile and attended acceptance pending
Last updated: 2026-09-15

## Product intent

Biology keeps Cyberpunk's native NPC identity, projection and visibility policy while adding two deliberately separate owned behaviors:

1. `src/redscript/CyberpunkRealism/NameplatesNative.reds` provides a narrow data-only fallback for an ordinary civilian who has been successfully scanned but whose stock focus-data name is empty even though the public crowd identity is allowed.
2. `src/redscript/CyberpunkRealism/E3NameplatesNative.reds` adds the optional Biology-owned red E3-inspired frame/rail treatment to the native nameplate controller when the E3 presentation preference is enabled.

Neither implementation requires the Project E3 runtime, its archive, its scanner, or its private nameplate widget fields.

## Identity permission boundary

The public-name fallback requires all of the following:

- target is an attached `NPCPuppet`;
- target has been scanned;
- target is a civilian;
- target is not the current quest target;
- neither `hide_nametag` nor the dynamic `Puppet.HideNameplate` flag hides identity;
- `Character_Record.UiNameplate()` exists, is enabled, and is exactly `UINameplate.CrowdSettings`;
- the puppet persistent state exists and does not advertise an alternative identity;
- the effective scanner visibility preset (including a forced preset) allows the name.

If stock `NPCNextToTheCrosshair.name` is already nonempty, it always wins. The fallback reads only `GameObject.GetDisplayName()` and assigns it to the incoming stock focus/nameplate data before the original `NameplateVisualsLogicController.SetVisualData(...)` runs.

Because the stock renderer still executes, its distance/projection/dialogue/mounting/defeated-state/settings/visibility behavior remains authoritative. The identity seam does not directly show the name text widget, frame, health bar or attitude decorations.

## E3 visual boundary

`E3NameplatesNative.reds` is a separate presentation-only seam. It creates Biology-owned INK widgets on the native `NameplateVisualsLogicController` root: open asymmetric red rails, a small accent/tick treatment, and a restrained `BIO // ID` identifier. The visual layer is shown only when `CRRealpassSettings.UseE3FirstPersonHudVisuals(...)` is true.

The E3 visual seam deliberately does **not**:

- replace the native name string or permission rules;
- read current/max health or reconstruct an NPC health meter;
- reach into the historical Project E3 `m_nameTextMain`, `m_nameFrame`, `m_nameBG` or equivalent private widget fields;
- hook scanner or quickhack controllers;
- load a replacement scanner/nameplate archive;
- control Biology's actor-health suppression policy.

Therefore E3 OFF yields the Biology-specific red frame treatment while the stock/native nameplate renderer remains authoritative. Biology-wide barless health remains independent of this preference.

## What the identity fallback deliberately does not do

- reveal quest-hidden or custom/alternative identities;
- invent names from archetype, affiliation or other hidden records;
- force names globally;
- change NPC attitude/health presentation;
- override the player's stock NPC-name setting;
- create a second scanner/nameplate controller.

## Public native API evidence

The stock 2.31 nameplate controller exposes `SetVisualData(puppet, incomingData, opt isNewNpc)` and renders `incomingData.name`; stock visibility remains a separate decision. This makes enriching an otherwise-empty permitted public name before calling `wrappedMethod` narrower and more patch-resilient than replacing the nameplate identity system.

Both `NameplatesNative.reds` and `E3NameplatesNative.reds` are registered in `manifest/native-seams.json` so a future game API change fails at the explicit 2.31 boundary rather than silently altering simulation logic. Exact installed-game compilation remains the authority for the native signature and INK controller compatibility.

## Acceptance

Attend at least these cases with the owned combined candidate:

1. capture the same focused NPC with E3 ON and E3 OFF; the Biology-owned red frame must be unmistakably present only with E3 ON;
2. scan an ordinary unnamed civilian and confirm an allowed public name appears/readably persists through focus changes;
3. ordinary civilian before scan does not gain the fallback merely from proximity;
4. quest target remains governed by stock quest presentation;
5. NPC with an alternative identity retains the alternative/hidden behavior;
6. `hide_nametag` / dynamic HideNameplate still suppress identity;
7. dialogue/scene transitions retain native visibility behavior;
8. friendly/neutral/hostile attitudes still render with native rules;
9. Biology actor-healthbar suppression does not remove the name/scanner text and does not become dependent on the E3 preference;
10. look away/back and scanner open/close do not leave stale names or stale E3 frame state;
11. open the modern scanner/quickhack interface with E3 ON and confirm it remains the current native scanner rather than an E3 scanner restoration.

Previous screenshots from the retired integration demonstrated that readable scanned civilian names are desirable, but they are not acceptance evidence for this new owned implementation. The new matched ON/OFF screenshots must come from the exact combined release-shaped candidate under review.
