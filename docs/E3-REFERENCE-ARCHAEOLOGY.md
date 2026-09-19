# Project E3 2.31.p2 — engineering-reference archaeology

Status: **W18.1 continuation — durable derived evidence; predecessor W03 archaeology retained**  
Issue: **#106** / parent presentation issue **#40**  
Game target: **Cyberpunk 2077 2.31**

This document records redistribution-safe conclusions from the owner's exact private Project E3 HUD/UI reference. It does **not** reproduce Project E3 source bodies or archive payloads.

The exact private reference matches the long-lived `config/realpass-e3.json` inventory, including the 33,013,760-byte HUD archive with SHA-256 `776556B6913C3B6B2FE1E13DA0964732FA917A130EA9C2A43E34AD4F5FEC03B6`.

## W18.1 evidence reconciliation

The predecessor archaeology established the implementation architecture before this worker-conversation transfer. W18.1 has independently reconciled that evidence against current repository history, T004, issue #40, and the public Project E3 2.31 distribution metadata.

The current Project E3 distribution page for Nexus mod 8800 identifies **redscript** and **TweakXL** as hard requirements and **Mod Settings** as optional customization. It also describes the mod as replacing/reworking a broad HUD family (including quest list, world/minimap mappins, input hints, ammo counters, crosshairs, notifications, dialog/interaction, scanner surfaces and other HUD/menu widgets). This independently supports the private-source mechanism mapping; it is not used as authority for current Cyberpunk 2.31 native controller contracts.

Historical Biology evidence is stronger than a count-only claim for the scanner split. `config/patches/realpass-modern-scanner.json` pins the same archive hash, `expectedResourceCount: 370`, and **all 34 omitted scanner/quickhack/focus/connected-device resource paths with SHA-256**. The directly inspected W18 bundle independently verifies the same exact archive and lists 370 resource paths, so the full archive inventory is no longer an unresolved boundary.

W18.1 directly inspected `Biology-Private-ReferenceBundle-20260919-001914-365937cf.zip`, produced by the #105 workflow from canonical revision `ffc000ffed2b958f70ce446f43a2fd92132a5f7c`. Its manifest includes 36 indexed Project E3 files, 22 REDscript files, 13 TweakXL YAML files, the separately selected Mod Settings reference, and a **verified WolvenKit listing** of `archive\\pc\\mod\\basegame_3e_demo_hud.archive`. The archive identity is exactly 33,013,760 bytes / SHA-256 `776556B6913C3B6B2FE1E13DA0964732FA917A130EA9C2A43E34AD4F5FEC03B6`. The listing contains 370 actual resource paths; four additional lines in the text file are WolvenKit long-path warning footer text, not resources.

## Architectural finding

Project E3's HUD is not a REDscript-drawn skin.

It is a layered implementation:

1. **archive/resource replacement** supplies authored INK widget trees, styles, atlases, textures, animations and HUD resources;
2. **redscript** replaces/wraps/adds native controller logic so those authored resources are populated and animated;
3. **TweakXL** changes TweakDB UI policy/record data for nameplates, mappins, clamping and choice icons;
4. **Mod Settings** is only an optional editor for Project E3's settings object.

That distinction matters for Biology. A script that references an archive-authored child such as an optional quest subtree, a custom compass container, a weapon decorator or a nameplate background does not prove Biology should recreate that hierarchy with runtime rectangles.

Conversely, Project E3's use of stock-resource replacement does not prove Biology should replace the same stock files. Biology's patch-resilience requirement favors the smallest current-2.31 semantic seam when it can express the intended result.

The machine-readable derived record is `docs/reference-mods/project-e3-hud-2.31-p2.json`.

## Resource/archive contribution

Historical Biology work already performed a byte-verified round trip of this exact archive. That evidence established:

- **370** total resources in the exact Project E3 archive;
- **34** scanner / quickhack / connected-device / focus-mode resources could be omitted;
- **336** other Project E3 resources remained byte-identical;
- selected retained working-HUD resources included the NPC nameplate, player healthbar, minimap and interaction dialog resources;
- the Project E3 scanner script was separable from the remaining HUD resource family;
- current Cyberpunk contains native fallbacks for every omitted scanner-family path.

The private 2.31.p2 scripts independently prove that many Project E3 controllers expect authored child hierarchies that are not created by those scripts themselves. Examples include:

- the quest tracker's optional-objective subtree;
- the weapon roster's nested decorator;
- the hotkey consumable widget's additional phone slot;
- custom nameplate level/background widgets;
- the Ironsight-hosted compass `Pusula` / `Fluff` hierarchy;
- custom world-mappin arrows/name/distance widgets;
- interaction/dialog child hierarchies.

Therefore the archive is **material implementation**, not decorative residue.

The direct W18 bundle closes the archive-inventory gate. Redistribution-safe path evidence now confirms exact authored resources including `quest_tracker.inkwidget`, `dpad_hint.inkwidget`, `compass.inkwidget`, `ammo_counter.inkwidget`, `playerhealthbar.inkwidget`, `npcnameplate.inkwidget`, `minimap.inkwidget`, `scanner_hud.inkwidget`, `scandetails.inkwidget`, `quickhacks.inkwidget`, `activity_log.inkwidget`, `interaction.inkwidget`, `dialog.inkwidget`, and `interactions_root.inkwidget`. W18.1 does **not** copy the private inventory or any Project E3 resource bytes into Git.

## Dependency roles

**redscript** is Project E3's controller-hook mechanism and is identified as a hard requirement by the current Project E3 2.31 distribution metadata. The reference uses broad `replaceMethod` as well as `wrapMethod` / additive fields and helpers across generic HUD fades, player HUD, activity log, scanner border, interactions/dialogue, minimap/mappins, quest tracker, Tech-Hex crosshair, weapon roster, compass, D-pad and nameplates.

**TweakXL** is materially involved, not incidental, and is likewise identified as a hard requirement by the current Project E3 2.31 distribution metadata. The reference YAMLs alter:
- nameplate display policy records;
- mappin definitions and visibility range;
- world-mappin UI profiles;
- clamping geometry/behavior;
- a large set of dialogue/interaction choice-icon record mappings.

**Archive/resource override** supplies the authored visual/widget layer. Project E3 2.31.p2 no longer needs REDmod merely to load that legacy archive layout; Biology nevertheless remains REDmod-first and can own project-original resources through its official package when that is the smallest robust route.

**Mod Settings** only exposes Project E3 options. The current Project E3 distribution explicitly describes it as optional for customization rather than required for the HUD to work. Biology intentionally does not retain it as a production dependency.

No Project E3 evidence establishes a need for Biology to add ArchiveXL, Codeware, CET or RED4ext.

## Published Project E3 surface coverage ledger

The public 2.31.p2 distribution/changelog is a useful completeness check because several visual families are implemented primarily through archive resources and therefore do not appear as dedicated files in `config/realpass-e3.json`. This ledger prevents those surfaces from disappearing from future archaeology simply because no standalone REDscript file exists.

| Published Project E3 surface | W18.1 disposition before private archive inventory |
| --- | --- |
| Compass | **Mapped** — custom Project E3 compass is archive/script-backed; Biology currently preserves native persistent minimap/navigation instead of resurrecting it. |
| Nameplates | **Mapped** — archive + redscript + TweakXL; Biology keeps narrower native identity/projection authority. |
| Health / RAM / stamina | **Partially mapped** — Project E3 health/RAM archive/script behavior is understood; Biology owns lower-left body presentation and no-healthbar policy. Stamina-specific archive contribution awaits #105 inventory and is not guessed. |
| Holocall / waveform | **Mapped at controller level** — Biology keeps native phone/waveform behavior. Archive-only presentation details await #105. |
| Quest list | **Mapped** — authored optional subtree + replaced tracker logic; Biology preserves W03.6 native title/objective-row seam. |
| World mappin widget / minimap mappins | **Mapped at script/TweakXL level** — Biology keeps current native mappin authority; archive widget ancestry awaits #105. |
| Input hints / D-pad | **Mapped for current Biology seam** — W03.6 `m_dpadHintsPanel`; any other authored input-icon resources await #105. |
| Action buttons | **Authored-resource follow-up** — the verified archive inventory proves Project E3 resource ownership, but Biology has no current product/native-seam reason to take this surface over before T005. |
| Wanted stars | **Authored-resource follow-up** — Project E3 resource participation is established; retain native/current behavior unless a later product requirement justifies a Biology-owned seam. |
| Minimap | **Mapped** — native `MinimapContainerController` remains authority; Project E3 archive/style contribution is material but not copied. |
| On-foot ammo counter | **Mapped** — preserve W03.5 lower-right native weapon binding. |
| Vehicle ammo counter | **Authored-resource follow-up** — Project E3 archive participation is established, but do not infer that Biology's proven on-foot weapon seam automatically owns vehicle ammo presentation. |
| Pistol / shotgun / smart crosshairs | **Partially mapped** — current generic/crosshair-state lifecycle is preserved and old Biology artifact removed; Project E3 weapon-specific archive resources await #105. |
| Quest / area / message / contact / item / level-up / warning / vehicle / radio notifications | **Authored-resource follow-up** — archive participation is established; activity log is separately mapped, and these notification families must not be silently treated as the same surface. |
| Dialog / interaction widgets | **Mapped at controller/TweakXL level** — native behavior remains authority; authored child ancestry awaits #105. |
| Scanner HUD / scan details | **Hard preserve: native/current** — exact 34 Project E3 scanner-family overrides are known and intentionally absent from Biology. |
| Phone / vehicle / radio / radial / metro menus | **Authored-resource follow-up / native preserve** — Project E3 resource participation is established, but these remain outside the accepted ordinary-HUD redesign unless future product scope says otherwise. |
| Hacking minigame | **Native preserve** — no Biology presentation ownership is justified by #40. Archive resource identity still belongs in the #105 inventory for completeness. |
| Speedometer | **Native preserve / authored-resource follow-up** — Project E3 2.31.p2 advertises an E3 speedometer and the archive inventory confirms broad authored HUD ownership, but Biology has no justified seam yet. |
| Warning/progress/damage/loot/boss-health presentation and HUD decorators | **Authored-resource follow-up** — Project E3 2.31.p2 advertises these as new/remade content; Biology must not accidentally import boss HP or old damage/scanner semantics contrary to its own product rules. |

An **authored-resource follow-up** is not a promise to reproduce that Project E3 surface. The verified #105 inventory establishes that Project E3 used authored resource composition there; Biology still chooses between an evidence-backed current-2.31 seam, a future Biology-owned resource, or an explicit native-preserve decision based on product scope rather than copying the reference.

## Direct private-bundle cross-check

The private source and archive inventory correlate at the architecture level:

- **Quest:** `quest_tracker.reds` replaces native tracker logic and hard-targets `inkVerticalPanelWidget2/OptionalTracker`, `Fluff/OptionalList`, and `Fluff/Title/OptionalName`; the exact archive contains `base\\gameplay\\gui\\widgets\\quests\\quest_tracker.inkwidget`, `quest_list.inkwidget`, tracker animations/styles/atlases, and objective textures.
- **D-pad:** `dpad_hint.reds` expects `mainCanvas/newPhoneSlot`; the archive contains `dpad_hint.inkwidget`, `dpad_hint_consumables.inkwidget`, D-pad animations/styles/atlases and related input resources.
- **Weapon/ammo:** `weaponRoster.reds` expects `weapon_on_foot/ammo_counter/weapon_wrapper/weapon_holder/decorator` and replaces ammo update/formatting; the archive contains `ammo_counter.inkwidget`, its style/animations and atlas resources.
- **Compass:** the scripts hard-target `Pusula/mappinContainer` and multiple `Fluff/...` children and spawn quest/POI widgets; the archive contains `compass.inkwidget`, `quest_mappin.inkwidget`, `poi_mappin.inkwidget` and compass animations.
- **Nameplates:** Project E3 adds/finds `levelValue`, `levelFrame`, `nameBG`, `levelBG` and `level_wrapper`, replaces nameplate behavior/ranges, and its TweakXL record enables/forces broad nameplate display; the archive contains `npcnameplate.inkwidget` and `nameplatecolors.inkstyle`.
- **Minimap/mappins:** REDscript replaces/wraps minimap mappin behavior while TweakXL changes mappin definitions, runtime profiles and clamping; the archive contains the minimap widget/style/animation family and minimap mappin resources.
- **Interactions/dialogue:** Project E3 replaces interaction/dialog controller methods and points at authored dialog resources; the archive contains interaction/dialog/root widgets, animations, styles and atlases while TweakXL remaps choice icons.
- **Activity log:** Project E3 replaces entry initialization and the archive contains `activity_log.inkwidget`.
- **Player health:** Project E3 wraps/replaces player-health controller behavior and the archive contains `playerhealthbar.inkwidget`, styles/animations, stamina and buff resources.
- **Scanner/quickhack:** Project E3 ships scanner/quickhack/focus resources and replaces scanner-border behavior. Biology deliberately excludes this entire reference family and preserves current 2.31 native scanner/quickhack.

The bundle does not serialize the Project E3 INK resources to JSON, so W18.1 does not claim private widget properties that are not present in the evidence. Another owner probe is unnecessary: the hard-coded Project E3 widget paths plus the exact WolvenKit resource inventory already answer the architectural question—these surfaces materially depend on authored resource hierarchy rather than REDscript-created geometry alone.

## W18.1 implementation consequence before T005

The verified archive evidence changes the **architecture rule**, not the accepted live seam.

Project E3's quest, D-pad, weapon/ammo, minimap, nameplate, activity-log, interaction/dialog and related presentation was materially authored in archive/INK resources. Biology must therefore not treat more runtime-created red rectangles as the route to deeper fidelity.

No W18 runtime source rewrite is warranted before T005 because the existing W03.5/W03.6 fixes already moved Biology onto current 2.31 authored/native content regions and were live-proven to correct specific placement failures:

- quest text/rows remain native `m_QuestTitle` / `QuestTrackerObjectiveLogicController` content inside `m_questTrackerContainer`;
- quickslots remain under native `m_dpadHintsPanel`;
- weapon/ammo remains in native `m_onFootContainer` / `m_weaponAmmoWrapper`;
- nameplates remain in the native projected-nameplate lifecycle;
- scanner/quickhack remains wholly current/native.

The existing Biology-created frames are therefore **accent chrome only**. They must not become a parallel layout authority. If T005 shows that a surface still needs structural composition beyond what the native authored hierarchy can express cleanly, the next implementation step is a **Biology-owned REDmod archive/INK resource authored from scratch against the current 2.31 resource seam**, not another guessed screen-space overlay and not a copied Project E3 resource.

## Subsystem reconciliation

### Quest tracker

Project E3 replaces the native tracker update/state logic so it can populate its archive-authored `OptionalTracker` optional-objective hierarchy and alter objective success/failure imagery.

Biology intentionally keeps current 2.31 `QuestTrackerGameController` and `QuestTrackerObjectiveLogicController` lifecycle authority. W03.6 mounts only inside `m_questTrackerContainer` and styles native `m_QuestTitle`, `m_objectiveTitle`, `m_trackingIcon`, and `m_trackingFrame`. It never injects a foreign child into `m_ObjectiveContainer`.

**Decision:** preserve W03.6. Project E3 proves that richer fidelity came from an authored resource tree, but its whole tracker replacement is a larger compatibility surface than Biology needs.

### Weapon / ammo

Project E3 expects a custom nested decorator in the weapon resource and replaces weapon roster data formatting/visibility methods.

Biology already has the stronger current-native seam: `m_onFootContainer`, `m_weaponAmmoWrapper`, and the native weapon/ammo text fields. T004 proved the old detached lower-center Biology chrome is gone.

**Decision:** preserve W03.5 binding. Do not copy the Project E3 decorator hierarchy or weapon data replacements.

### D-pad / hotkeys

Project E3's hotkey code relies on an authored additional phone slot inside the consumable widget and re-injects phone content. Current native 2.31 separately exposes `m_dpadHintsPanel` as the parent where ordinary consumable/gadget/cyberware children are spawned.

**Decision:** preserve W03.6 `m_dpadHintsPanel` ownership. It is narrower than the Project E3 custom resource hierarchy and avoids the controller-root collision seen in T004.

### Ambient nameplates

Project E3 combines:
- archive-authored name/level/background presentation;
- broad redscript replacement of naming/color/visibility/health presentation;
- TweakXL records that make Crowd/Quest/Combat/MpPlayer nameplates `Always` and even enable the Disabled record;
- longer display ranges.

Biology deliberately diverges. It keeps native hidden/alternative/quest/record permission gates, does not reintroduce actor levels/health bars, and uses the current native projected-nameplate lifecycle plus compact Biology framing.

**Decision:** preserve Biology's narrower policy. The still-observed police/combat scanner-name enrichment discrepancy remains a bounded #40 follow-up; it is not a reason to import Project E3's archetype/affiliation derivation or blanket Always policy.

### Minimap / world mappins / compass

Project E3 has two distinct systems:
- minimap/world mappins: redscript replacement plus TweakXL profile/clamping/definition changes;
- a separate top compass: substantial custom logic mounted through `IronsightGameController`, driven by archive-authored compass containers and external compass mappin resources.

Current Cyberpunk 2.31 persistent minimap authority is `MinimapContainerController`.

**Decision:** keep Biology on the current persistent minimap/navigation path. Do not resurrect Project E3's custom top compass or import mappin/clamping TweakDB behavior merely for fidelity. A future explicit product decision could separately justify a Biology-owned top compass.

### Crosshair

Project E3 modifies the Tech-Hex crosshair's own widgets/spread/charge/ADS behavior. Biology's earlier custom centered frame produced the attended two-corner artifact.

**Decision:** preserve W03.4 cleanup. Biology only uses reversible native crosshair styling, and native Scanning state owns scanner transition/visibility.

### Interaction / dialogue

Project E3's interaction and dialogue work is tightly coupled to authored child hierarchy plus extensive controller method replacement. Choice-icon TweakDB mappings are part of the presentation.

**Decision:** Biology retains only ordinary interaction presentation and leaves native choice/input/dialogue behavior authoritative. Dialogue redesign remains outside the accepted #40 scope.

### Activity log

Project E3 replaces the entry initialization and constructs its animation behavior in script.

**Decision:** Biology's native-entry reversible styling is narrower and remains preferable. Do not take over queue/timing/animation semantics.

### Player health / lower-left

Project E3 combines archive-authored player HUD resources with script behavior such as health percentage presentation and RAM-related fluff visibility.

**Decision:** Biology owns its own product-specific lower-left presentation and independent healthbar policy. Do not inherit Project E3 health/RAM behavior.

### Generic HUD fade and phone waveform

Project E3 replaces generic `inkHUDGameController` context-change animation and phone waveform logic.

**Decision:** neither is required for Biology's accepted ordinary-HUD target. Keep native.

## What Biology should learn from the archive without copying it

The major engineering lesson is **authored content regions matter**.

W03.3-W03.6 live failures repeatedly came from adding runtime geometry to a controller root whose authored visible content lived deeper in an INK resource. Project E3 avoids many of those failures by owning the resource hierarchy itself and then having controller code address named children.

Biology should apply that lesson in this order:

1. use the current native semantic child/resource when it already exposes the required content region;
2. style that native content through narrow additive/wrapper code when possible;
3. if static layout fidelity cannot be expressed safely through native children, prefer a **Biology-owned REDmod archive resource** over increasingly elaborate runtime screen-space compensation;
4. only replace a stock authored resource when direct evidence shows the narrower native-content approach cannot express the design without greater fragility;
5. never copy Project E3 resource bytes or make Project E3 a runtime dependency.

This is why W03.5/W03.6 content-region work remains valid even though Project E3 itself uses an archive: those fixes moved Biology *toward* authored/native content ownership rather than toward arbitrary screen coordinates.

## Scanner hard boundary

Project E3's archive includes a substantial scanner/quickhack/focus family. Biology's historical filtered-archive experiment proved those resources can be separated from the rest of the E3 HUD.

Biology now takes the stronger approach: **no Project E3 runtime archive at all** and no scanner controller/resource override. The current native scanner and quickhack presentation remain authoritative.

## Validation contract

W18.1 validation must prove:

- current canonical main is reconciled without discarding W03.6;
- Project E3 remains reference-only in runtime/package policy;
- W03.6 quest/hotkey native-content seams remain present;
- W03.5 weapon binding, W03.4 reticle cleanup and W03.3/W03.4 nameplate lifecycle remain present;
- modern scanner/quickhack hooks/resources remain absent;
- the targeted 2.31 native probe covers every Biology seam retained after archaeology;
- cloud policy/source tests enforce the derived reference record, verified archive-family conclusions, and dependency conclusions;
- parent P02, not this worker, owns T005.
