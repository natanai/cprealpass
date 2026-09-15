# Biology NPC nameplates

Status: attended follow-up implementation; exact compile and live acceptance pending  
Last updated: 2026-09-15

## Product intent

Biology's E3 presentation includes an **ambient identity/nameplate treatment during ordinary first-person focus**. Scanner mode is not required just to get the baseline nameplate.

The implementation is deliberately split:

1. `NameplatesNative.reds` resolves the identity string while preserving native knowledge/permission authority.
2. `E3NameplatesNative.reds` owns the red/minimal visual presentation and the narrow native projection lifecycle needed to make the identity surface actually visible.
3. `NoHealthbars.reds` separately suppresses actor HP presentation while Biology is enabled. It is not part of the E3 nameplate success criterion.

No Project E3 runtime script/archive/tweak executes in Biology.

## Identity precedence

Biology does not keep a second identity database.

1. Native `NPCNextToTheCrosshair.name` always wins when populated.
2. If native focus identity is empty, an ordinary public civilian may use `GameObject.GetDisplayName()` only when:
   - the NPC is attached and a civilian;
   - it is not being handled as a quest target by the generic fallback;
   - neither `hide_nametag` nor dynamic `Puppet.HideNameplate` hides identity;
   - `Character_Record.UiNameplate()` exists, is enabled, and is `UINameplate.CrowdSettings`;
   - persistent state does not advertise an alternative identity;
   - the native `ScannerModulePreset().ShoulShowName()` permission says the public name is showable.
3. When scanning later causes native focus/nameplate data to contain a richer identity, step 1 automatically supersedes the fallback. Biology therefore gets scanner enrichment without storing learned identities itself.

`ScannerModulePreset()` is used here as native **permission authority**, not as a requirement that scanner mode has already been entered.

## Ambient visibility seam

The previous implementation only decorated `NameplateVisualsLogicController.SetVisualData(...)`, which attended testing showed was insufficient: a random civilian with E3 ON had no visible nameplate, while cops only showed a narrow red strip.

The follow-up also uses the current `NpcNameplateGameController.OnScreenProjectionUpdate(...) -> Void` lifecycle, evidenced directly by the preserved Project E3 2.31.p2 reference source. After native projection logic runs, Biology may make the existing native `m_displayName` surface visible only when:

- E3 presentation is enabled;
- native `GetNameplateVisible()` is true;
- the native buffered character nameplate record exists and is enabled;
- the visual controller confirms a legitimate native-rendered/public-fallback name is available.

Biology does not create a second floating-name projection system and does not replace native distance, mounting, dialogue, scene or projection authority.

## Visual treatment

`E3NameplatesNative.reds` styles the native identity text/frame with the Biology-owned red/minimal language and adds an open asymmetric Biology-owned bracket. It does not render health, level, rarity, damage preview or a scanner panel.

The native 2.31 `m_nameTextMain` and `m_nameFrame` refs are used because the supplied Project E3 2.31.p2 source demonstrates those fields belong to `NameplateVisualsLogicController`; they are not Project E3-added fields.

## E3 OFF

With Biology still enabled and E3 presentation off:

- Biology E3 nameplate styling/ambient force-show behavior yields;
- Biology-wide actor-health suppression remains unchanged;
- identity/scanner systems remain native;
- modern scanner/quickhack remains unchanged.

## Acceptance

The parent-integrated attended candidate must verify:

1. random civilian ordinary direct look/focus with E3 ON, before scanner — baseline identity/nameplate visible where native public-name policy permits;
2. same relevant civilian after scanner information is acquired — richer native identity/context appears if the game supplies it;
3. police/combatant ordinary focus with E3 ON — full identity/nameplate treatment, not only a narrow red strip;
4. E3 OFF removes Biology's E3 nameplate treatment;
5. hidden/alternative/quest-sensitive identities are not revealed by the generic fallback;
6. look-away/back, scanner open/close, dialogue and combat transitions do not leave stale Biology nameplate widgets;
7. modern scanner/quickhack remains the current native Cyberpunk interface.

Previous screenshots from the retired integration are not acceptance evidence for this implementation.
