# Project E3 2.31.p2 — engineering-reference archaeology

Status: **W03.7 durable derived evidence**  
Issue: **#106** / parent presentation issue **#40**  
Game target: **Cyberpunk 2077 2.31**

This document records redistribution-safe conclusions from the owner's exact private Project E3 HUD/UI reference. It does **not** reproduce Project E3 source bodies or archive payloads.

The exact private reference matches the long-lived `config/realpass-e3.json` inventory, including the 33,013,760-byte HUD archive with SHA-256 `776556B6913C3B6B2FE1E13DA0964732FA917A130EA9C2A43E34AD4F5FEC03B6`.

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

The current private ZIP does not by itself expose a complete decoded 370-resource path/ancestry inventory. #105/W16.1 is the durable private-bundle route for that evidence. Until a safe inventory is attached, W03.7 records the remaining archive-internal detail as opaque rather than inventing it.

## Dependency roles

**redscript** is Project E3's controller-hook mechanism. The reference uses broad `replaceMethod` as well as `wrapMethod` / additive fields and helpers across generic HUD fades, player HUD, activity log, scanner border, interactions/dialogue, minimap/mappins, quest tracker, Tech-Hex crosshair, weapon roster, compass, D-pad and nameplates.

**TweakXL** is materially involved, not incidental. The reference YAMLs alter:
- nameplate display policy records;
- mappin definitions and visibility range;
- world-mappin UI profiles;
- clamping geometry/behavior;
- a large set of dialogue/interaction choice-icon record mappings.

**Archive/resource override** supplies the authored visual/widget layer. Project E3 2.31.p2 no longer needs REDmod merely to load that legacy archive layout; Biology nevertheless remains REDmod-first and can own project-original resources through its official package when that is the smallest robust route.

**Mod Settings** only exposes Project E3 options. Biology intentionally does not retain it as a production dependency.

No Project E3 evidence establishes a need for Biology to add ArchiveXL, Codeware, CET or RED4ext.

## Subsystem reconciliation

### Quest tracker

Project E3 replaces the native tracker update/state logic so it can populate an archive-authored optional-objective hierarchy and alter objective success/failure imagery.

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

W03.7 validation must prove:

- current canonical main is reconciled without discarding W03.6;
- Project E3 remains reference-only in runtime/package policy;
- W03.6 quest/hotkey native-content seams remain present;
- W03.5 weapon binding, W03.4 reticle cleanup and W03.3/W03.4 nameplate lifecycle remain present;
- modern scanner/quickhack hooks/resources remain absent;
- the targeted 2.31 native probe covers every Biology seam retained after archaeology;
- cloud policy/source tests enforce the derived reference record and archive/dependency conclusions;
- parent P02, not this worker, owns T005.
