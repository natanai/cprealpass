# realpass scanned civilian names

Status: project-original native source implemented; fresh exact compile and attended acceptance pending
Last updated: 2026-09-14

## Product intent

realpass keeps Cyberpunk's stock nameplate renderer and visibility policy. The only added behavior is a narrow fallback for an ordinary civilian who has been successfully scanned but whose stock focus-data name is empty even though the public crowd identity is allowed.

The implementation is `src/redscript/CyberpunkRealism/NameplatesNative.reds`. It does not ship a replacement nameplate widget/archive and does not depend on a reference HUD runtime.

## Permission boundary

The fallback requires all of the following:

- target is an attached `NPCPuppet`;
- target has been scanned;
- target is a civilian;
- target is not the current quest target;
- neither `hide_nametag` nor the dynamic `Puppet.HideNameplate` flag hides identity;
- `Character_Record.UiNameplate()` exists, is enabled, and is exactly `UINameplate.CrowdSettings`;
- the puppet persistent state exists and does not advertise an alternative identity;
- the effective scanner visibility preset (including a forced preset) allows the name.

If stock `NPCNextToTheCrosshair.name` is already nonempty, it always wins. The fallback reads only `GameObject.GetDisplayName()` and assigns it to the incoming stock focus/nameplate data before the original `NameplateVisualsLogicController.SetVisualData(...)` runs.

Because the stock renderer still executes, its distance/projection/dialogue/mounting/defeated-state/settings/visibility behavior remains authoritative. realpass does not directly show the name text widget, frame, health bar or attitude decorations.

## What this deliberately does not do

- reveal quest-hidden or custom/alternative identities;
- invent names from archetype, affiliation or other hidden records;
- restore a reference mod's nameplate assets;
- force names globally;
- change NPC attitude/health presentation;
- override the player's stock NPC-name setting;
- create a second scanner/nameplate controller.

## Public native API evidence

The stock 2.31 nameplate controller exposes `SetVisualData(puppet, incomingData, opt isNewNpc)` and renders `incomingData.name`; stock visibility remains a separate decision. This makes enriching an otherwise-empty permitted public name before calling `wrappedMethod` narrower and more patch-resilient than replacing the entire nameplate resource/controller.

The precise installed 2.31 signature still belongs to the exact-compile gate. `NameplatesNative.reds` is registered in `manifest/native-seams.json` so a future game API change fails at the explicit boundary rather than silently altering simulation logic.

## Acceptance

Attend at least these cases with the owned candidate:

1. scan an ordinary unnamed civilian and confirm an allowed public name appears/readably persists through focus changes;
2. ordinary civilian before scan does not gain the fallback merely from proximity;
3. quest target remains governed by stock quest presentation;
4. NPC with an alternative identity retains the alternative/hidden behavior;
5. `hide_nametag` / dynamic HideNameplate still suppress identity;
6. dialogue/scene transitions retain native visibility behavior;
7. friendly/neutral/hostile attitudes still render with stock rules;
8. actor-healthbar suppression does not remove the name/scanner text;
9. look away/back and scanner open/close do not leave stale names.

Previous screenshots from the retired integration demonstrated that readable scanned civilian names are desirable, but they are not acceptance evidence for this new owned implementation.
