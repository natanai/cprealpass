# Biology E3-inspired presentation target

Status: canonical visual target / W18.1 engineering-reference continuation
Last updated: 2026-09-17
Current worker: W18.1 / issue #106 / parent issue #40

## W18.1 verified resource-composition rule

W18.1 directly inspected `Biology-Private-ReferenceBundle-20260919-001914-365937cf.zip`. Its exact pinned Project E3 HUD archive has a WolvenKit-verified inventory of 370 actual resource paths, including authored quest/list, D-pad/input-hint, compass, weapon/ammo, player-health, NPC-nameplate, minimap, scanner/quickhack, activity-log and interaction/dialog resource families.

Therefore Biology's E3 preference must not evolve by stacking more runtime-created red geometry around controller roots. Current native widgets/resources own layout and gameplay semantics. Biology runtime geometry is limited to reversible accent chrome on already-proven semantic hosts. If T005 shows a structural mismatch that native child styling cannot solve, the next step is a Biology-owned REDmod/INK resource authored independently for the current 2.31 seam.

This rule preserves the W03.5/W03.6 live wins and does not reintroduce Project E3 as a dependency.

## W18.1 engineering-reference rule

The exact Project E3 2.31.p2 private reference was traced by the predecessor archaeology and is now owned by the W18.1 continuation as a layered implementation: authored archive/INK resources + redscript controller logic + TweakXL record policy, with Mod Settings only as an optional settings surface.

See `E3-REFERENCE-ARCHAEOLOGY.md` for the durable mapping. W18.1 does **not** change the product boundary to “copy Project E3.” It uses Project E3 to identify the real responsibilities and then chooses the smallest current Cyberpunk 2.31 / Biology-owned seam. In particular, W03.5/W03.6 native content-region binding remains intentional, while Project E3 archive bytes/scripts/tweaks remain forbidden from the player artifact.

## Product decision

Biology targets a coherent red/minimal 2018/E3-inspired ordinary first-person HUD and ambient NPC identity/nameplates while preserving Cyberpunk 2077's modern scanner/quickhack presentation.

Project E3 remains archaeology/reference material only. Biology does not execute or redistribute its archive, scripts, tweaks, old scanner, settings implementation, or gameplay logic. Current Cyberpunk 2077 2.31 native/REDmod controller behavior remains authoritative unless attended evidence proves a narrow presentation lifecycle correction is required.

## W03.3 attended boundary

W13 already proved that the supported live game compiles and executes current Biology REDscript. The later integrated candidate 205578b11d818f474dc74a873e6d6ea5a1e1accd therefore gives a stronger presentation-specific result:

- ordinary gameplay still read substantially as the current/retail HUD;
- minimap, quest/objective stack, weapon/ammo presentation and ordinary prompts showed no convincing E3 transformation;
- ambient civilian and police/combatant nameplates were absent;
- after scanning an NPC, a small strange red rectangle appeared near the lower-right of the reticle;
- the modern scanner itself remained current/native and must stay that way.

This proves that source presence, exact compilation and controller-name matching are not sufficient. W03.3 must fix the live presentation lifecycle and geometry.

## W03.3 root-fitted HUD correction

W03.2 created large fixed-size/translated Biology canvases as children of several native controller roots. Those roots are controller-local layouts, not guaranteed full-screen canvases. A 530x286 or 552x312 child can therefore be clipped, translated outside the useful local bounds, or otherwise fail to produce the intended visible result even though the hook executes.

W03.3 changes persistent HUD treatment to root-fitted Biology-owned shells:

- the owned shell uses inkEAnchor.Fill against the actual native controller root;
- a low-opacity red wash, short local rail/accent and compact label live inside that fitted shell;
- quest, minimap/navigation, weapon/ammo, quick-slot, lower-left Biology presentation and ordinary interaction prompts all use the same layout rule;
- native controller data, visibility, input and update logic run first and remain authoritative;
- E3 OFF hides the Biology-owned shell rather than repainting native roots.

The crosshair is intentionally different: it stays a compact centered frame under the current gameuiCrosshairContainerController. The separate W03.2 CrosshairGameController_Tech_Hex inner frame is removed because it can outlive the generic focus treatment and is a plausible contributor to the attended post-scan artifact.

## W03.3 nameplate diagnosis

The current 2.31 native nameplate flow explains the live failure precisely.

NameplateVisualsLogicController.SetElementVisibility(...) starts by hiding the native name text. For ordinary non-aggressive NPCs it may leave both name text and level presentation absent. Its public IsAnyElementVisible() then returns only whether native name text or level presentation is visible.

NpcNameplateGameController.OnScreenProjectionUpdate(...) subsequently performs the projection/distance/dialog/hide checks and then applies an additional gate: if the candidate nameplate is otherwise visible, m_visualController.IsAnyElementVisible() must also be true before the projected root is shown.

W03.2 acted too late. It attempted to reveal m_displayName after native projection processing, but for an ordinary civilian the entire projected nameplate root could already have been hidden by IsAnyElementVisible() == false. After scanning, native state could make the root visible, which explains why a Biology red child could suddenly appear as the observed small reticle-adjacent rectangle.

## W03.3 ambient nameplate correction

W03.3 keeps native projection authority but fixes that one presentation bottleneck:

1. Native NPCNextToTheCrosshair.name remains first priority.
2. If native name is empty, Biology may use the entity's existing public GameObject.GetDisplayName() for an attached ordinary NPC—civilian, police or combatant—when quest, hidden-name, alternative-identity and explicitly disabled-nameplate policy do not block it.
3. Biology enriches only a local copy before the native visual controller runs.
4. Biology wraps IsAnyElementVisible() so a legitimate E3 ambient identity counts as visible. This allows the native projected root to survive its normal visibility calculation without replacing projection, dialog, mount or hide-name logic.
5. Biology uses the native m_nameTextMain / m_nameFrame as the actual identity surface. The W03.2 oversized custom projected CRBiologyE3NameplateFrame is removed.
6. While E3 is ON, native name text/frame receive the red/minimal treatment; their captured native tint is restored when E3 is OFF.
7. Non-aggressive nameplate range is raised from the current native ordinary 3 / 10 display/max envelope to 10 / 20 while E3 is ON. E3 OFF restores the native SNameplateRangesData values.

This remains a presentation rule, not a scanner knowledge database. Biology does not derive FullDisplayName, archetype, affiliation or scanner-only hidden identity.

## Hook execution evidence

The next integrated attended session needs to answer a question W03.2 could not: which mapped presentation hooks actually execute in live ordinary play?

W03.3 therefore emits narrow [Biology:E3] FTLog trace markers at persistent controller initialization and the first relevant nameplate projection/data events. These markers are diagnostics for the parent-integrated attended run; they do not change release/startup architecture and they do not ask the owner to play a worker branch.

If a visible surface still remains retail while its hook trace is present, the fault is presentation geometry/state inside that proven controller. If its trace is absent, the parent can route the next repair to the actual live controller instead of guessing.

## Modern scanner is a hard preserve

Biology E3 presentation must not hook or replace scanner/quickhack controllers, load Project E3 scanner resources, recreate the 2018 scanner, or recolor the current scanner.

The W03.3 crosshair cleanup is specifically intended to reduce scanner-adjacent residue: one generic current crosshair-container child remains, and native vision ownership decides whether that container is visible. Nameplate presentation continues through native projected-nameplate controllers, not scanner controllers.

## E3 ON/OFF contract

With E3 ON, an ordinary gameplay capture must be unmistakably different from retail through the combined quest, navigation, weapon/ammo, quick-slot, prompt/focus and ambient-nameplate language. A single bar, tiny rectangle or healthbar suppression is not acceptance.

With E3 OFF:

- root-fitted Biology HUD shells are hidden;
- ambient-nameplate range returns to native defaults;
- captured native name/frame tint is restored;
- Biology simulation and Biology-wide healthbar suppression are unchanged;
- modern scanner/quickhack remains unchanged.

## Parent attended acceptance

Parent P01.2 should integrate and test the release-shaped candidate rather than this worker branch directly. Capture the same state/location with E3 ON and OFF, including quest/objective, minimap/navigation, weapon/ammo/hotkeys, one interaction prompt, civilian focus, police/combatant focus, post-scan identity where applicable, and the modern scanner. Also inspect the captured game/functional trace output for the [Biology:E3] markers so missing visuals can be tied to hooks that did or did not execute.

The strange post-scan red rectangle must be absent. If any red artifact remains, identify its owner before accepting #40.


## W03.4 attended visual-completion boundary

T002 tested exact integrated source `3dc049ee99979f924978b671ddbbbda06b472d1b`. It proved two things simultaneously:

- W03.3's ambient ordinary-look identity lifecycle is now real and must be preserved;
- the visible presentation still needs substantial design completion.

The T002 screenshots show ambient names such as `FEDOT VASILYEV` / `NC RESIDENT`, but they also show large full-root red blocks behind the lower-left HUD, weapon/ammo, quest stack and minimap. Those blocks are unmistakably Biology-owned, yet they read as generic tinted panels rather than one restrained E3 system.

### Reticle artifact — concrete owner

The reticle-adjacent red box is no longer ambiguous. The live screenshots show exactly two Biology-red corners: one top-left and one bottom-right around the center reticle. W03.3's `CRBiologyE3FocusFrame` is a centered **112 x 112** canvas that draws exactly those top-left and bottom-right corner pairs.

Therefore W03.4 treats `CRBiologyE3FocusFrame` as the concrete artifact owner and removes that canvas/geometry outright. It does not add a replacement reticle overlay.

Ordinary crosshair treatment moves to the native `gameuiCrosshairBaseGameController` root. Biology only captures/restores the native tint and applies the shared red tint while E3 is enabled. The native controller already hides its root in `OnState_Scanning`, so Biology adds no scanner reticle geometry and does not take over scanner/quickhack controllers.

### HUD language — compact chrome, not full-root red

W03.4 keeps the proven current native controller seams but removes the full-root red wash from quest, navigation, weapon/ammo, hotkeys, lower-left Biology presentation and ordinary interaction prompts.

Those surfaces now share a small Biology-owned chrome language:

- short 2 px top rule;
- short left rule;
- compact accent cell;
- faint label band with a small uppercase system label;
- faint lower-right corner marker;
- no full-root fill.

This preserves the root-fitted lifecycle advantage from W03.3 while eliminating the large red slabs visible in T002.

### Nameplate completion

The ambient-name lifecycle from W03.3 remains untouched: native `NPCNextToTheCrosshair.name` wins, public `GetDisplayName()` may fill an empty ordinary identity when native hidden/quest/alternative/disabled policy permits, and `IsAnyElementVisible()` continues to keep the native projected root alive for legitimate ambient identity.

W03.4 upgrades the visual treatment rather than changing identity knowledge:

- native `m_nameTextMain` remains the actual name text;
- native `m_nameFrame` remains part of the presentation;
- Biology adds a compact 340 x 46 projected identity chrome behind the native text, with segmented top/bottom rails, small vertical caps, a small accent cell and a very low-opacity inner band;
- no actor health meter, health number, affiliation database, archetype derivation or scanner-only identity is added;
- native name/frame tint is captured and restored on E3 OFF;
- the proven 10 / 20 non-aggressive ambient range remains, with native range restored on E3 OFF.

The Project E3 2.31.p2 reference is design archaeology only. Its source confirms that the historical nameplate presentation combined name text, a name frame and optional background/level framing rather than treating a red string alone as the finished design. Biology recreates only the compact framing language in project-original code; it does not ship or execute the reference archive/scripts.

## W03.4 parent acceptance

The next integrated attended run must show:

- E3 ON reads as one coherent HUD rather than multiple red slabs;
- the `CRBiologyE3FocusFrame` reticle corners are absent;
- ordinary crosshair behavior remains native-functional and the modern scanner remains current;
- civilian and police/combatant ambient identity still appears before scanning;
- the nameplate has a visible compact identity frame, not only red text;
- quest, minimap/navigation, weapon/ammo, hotkeys, prompt and activity surfaces visibly share the same compact chrome language;
- E3 OFF removes Biology chrome and restores captured native crosshair/nameplate styling and native ambient range.


## W03.5 — native HUD content regions

T003 tested exact integrated source `67593bfbb12b4a6ebcec7042066d48b4f5fac427`.

T003 preserved the W03.4 reticle/nameplate improvements but exposed a new coordinate-space boundary:

- the old 112 x 112 two-corner reticle artifact is absent — KEEP;
- ambient ordinary-focus names still appear — KEEP;
- the compact segmented nameplate frame is visibly live — KEEP;
- `WEAPON // AMMO` chrome is detached from the actual lower-right weapon/ammo content and floats nearer lower-center — FAIL;
- the right-hand quest/objective stack remains essentially native/current — FAIL.

The failure is not evidence that the W03.4 hooks are dead. It is evidence that a controller root is not necessarily the authored visual content region used by the native widget resource.

### Current 2.31 quest content authority

The current quest tracker script exposes semantic editable regions rather than only the controller root:

- `m_questTrackerContainer : inkWidgetRef` — the native tracker container whose visibility is controlled by `UpdateTrackerData()`;
- `m_QuestTitle : inkTextRef` — the native visible quest title;
- `m_ObjectiveContainer : inkCompoundRef` — the native compound where objective rows are removed, enumerated and spawned.

W03.5 resolves the Biology quest host from `m_questTrackerContainer` only. `m_ObjectiveContainer` remains important structural evidence, but it is deliberately **not** used as a mount fallback because vanilla enumerates that child list and assumes its entries are `QuestTrackerObjectiveLogicController` instances. If the tracker container cannot be resolved as a compound widget, Biology fails closed and records that fact in the bounded trace rather than inserting a foreign child into the objective list. Biology no longer composes quest chrome against `QuestTrackerGameController.GetRootCompoundWidget()`.

The native quest title is tinted through its own `m_QuestTitle` widget while E3 is ON and its captured native tint is restored when E3 is OFF. Journal data, objective spawning/state, visibility, timers and animations remain native.

### Current 2.31 weapon/ammo content authority

The current weapon roster script exposes:

- `m_onFootContainer : inkWidgetRef` — the semantic on-foot weapon roster region;
- `m_weaponAmmoWrapper : inkWidgetRef` — the native ammo subregion;
- `m_weaponName : inkTextRef`;
- `m_weaponCurrentAmmo : inkTextRef`;
- `m_weaponTotalAmmo : inkTextRef`.

The native controller itself applies effects/visibility to `m_onFootContainer` and updates the ammo wrapper/text from weapon state. W03.5 therefore mounts Biology chrome inside `m_onFootContainer`, falling back only to `m_weaponAmmoWrapper` if the broader semantic host cannot be resolved. It no longer mounts weapon chrome at the controller root.

The native weapon name/current-ammo/total-ammo tints are captured, changed to the shared Biology red while E3 is ON, and restored on E3 OFF. Native fold/unfold, weapon data, ammo counts, vehicle state, scanner/focus folding and animation remain authoritative.

### No guessed screen-space compensation

W03.5 does not attempt to repair T003 by adding a screen translation that merely happens to move the label toward the screenshot's lower-right corner.

The presentation child is placed inside the same semantic native content host as the visible data. This means native authored position, visibility, fold/unfold and animation establish the coordinate system.

### Bounded live geometry evidence

Quest and weapon adapters now emit `[Biology:E3]` region evidence on initial E3 state and later ON/OFF transitions. The trace records:

- semantic host selected;
- whether host resolution succeeded;
- whether chrome exists;
- E3 enabled state;
- native host size;
- native host translation;
- native host margins;
- Biology chrome size;
- Biology chrome translation;
- Biology chrome margins.

This is diagnostic evidence, not layout authority. It exists so a future attended session can distinguish a bad native-host choice from a hook that never ran or a mounted child that was clipped.

### W03.5 acceptance

Parent-integrated attended evidence must show the `WEAPON // AMMO` treatment traveling with the actual lower-right native weapon region and the quest treatment visibly composed with the right-side native tracker. The prior reticle removal and framed ambient nameplate are regressions if lost. Native modern scanner/quickhack remains a hard preserve.


## W03.6 — quest / hotkey native content-region completion

T004 tested exact integrated source `ffa6f64d6c837146d032aaab565d671c932453a2`.

T004 preserves the W03.5 weapon fix and earlier nameplate/reticle wins, but it proves that quest and hotkey presentation need a second semantic-region pass:

- weapon/ammo no longer floats near lower-center and is back with the lower-right native region — KEEP;
- ambient ordinary-focus framed nameplates remain live — KEEP;
- the old 112 x 112 two-corner reticle artifact remains absent — KEEP;
- quest chrome reaches the right-hand tracker region, but only as a small partial marker while the title/objective stack still reads overwhelmingly current/native — FAIL;
- lower-left Biology chrome visibly overlaps/misaligns with cyan native hotkey/quickslot controls — FAIL.

### Quest completion uses native row content, not a larger guessed overlay

W03.5 correctly moved the quest mount into `m_questTrackerContainer`, but a fixed `OBJECTIVES` label/rail is not enough to transform the whole tracker.

Current 2.31 quest authority exposes the actual visible row components through `QuestTrackerObjectiveLogicController`:

- `m_objectiveTitle : inkTextRef`;
- `m_trackingIcon : inkWidgetRef`;
- `m_trackingFrame : inkWidgetRef`.

W03.6 keeps custom chrome mounted only in `m_questTrackerContainer`, replaces the tiny fixed label treatment with a segmented host-relative frame, and styles the actual native quest title plus each spawned native objective row. The objective list itself remains owned by `m_ObjectiveContainer`; Biology never reparents a foreign child into that list.

The quest controller iterates the native objective children only after native `UpdateTrackerData()` completes and calls a Biology presentation helper on each existing `QuestTrackerObjectiveLogicController`. Native Journal data, objective spawning/removal, tracked-state logic, counters, success/failure transitions and animations remain authoritative.

E3 OFF restores the captured native title, objective-text, tracking-icon and tracking-frame tint.

### Hotkey / quickslot semantic host

Current CP2077 2.31 `HotkeysWidgetController` exposes separate editable regions:

- `m_phoneSlot`;
- `m_carSlot`;
- `m_radioSlot`;
- `m_dpadHintsPanel`.

The controller's ordinary consumable/gadget/cyberware/leeroy/time-bank widgets are spawned directly into `m_dpadHintsPanel`. That panel is therefore the narrow semantic host for the quickslot cluster that T004 showed underneath the misaligned Biology chrome.

W03.6 removes the `GetRootCompoundWidget()` mount from `E3HotkeyHudNative.reds`. The Biology frame now fills only `m_dpadHintsPanel`, using the same segmented region language as the quest completion. Phone/car/radio sibling slots remain native and are not covered by a broad root overlay.

No screenshot-derived X/Y compensation is introduced. The native authored panel position and size define Biology's local coordinate space.

### Bounded evidence

Quest and hotkey adapters continue/extend `[Biology:E3]` region traces. For each semantic host they report mount resolution, E3 state, native host size/translation/margins and Biology chrome geometry. These values are evidence only and are never converted into hard-coded global offsets.

The installed-source probe now requires the exact 2.31 quest objective-row fields and the hotkey hierarchy including `m_dpadHintsPanel` plus the native `SpawnFromLocal(inkCompoundRef.Get(m_dpadHintsPanel), ...)` usage.

### W03.6 acceptance

Parent-integrated attended evidence must show:

- the right-hand tracker reads as one E3-composed unit because native title/objective rows visibly participate, not because a larger arbitrary box was added;
- lower-left segmented chrome follows the actual `m_dpadHintsPanel` quickslot cluster without overlapping phone/car siblings;
- W03.5 lower-right weapon binding remains correct;
- framed ambient names remain live;
- the old reticle artifact stays absent;
- E3 OFF restores native quest/hotkey styling;
- the modern scanner/quickhack presentation remains current/native.


## W18.1 T005 acceptance boundary

Parent P02 owns T005 on an integrated canonical candidate. W18.1 requires T005 to verify, without rediscovering architecture:

- quest title/objective rows remain composed in the right-hand native tracker and the existing W03.6 treatment is visually coherent;
- quickslot/D-pad treatment follows `m_dpadHintsPanel` without the T004 overlap;
- weapon/ammo remains bound to the lower-right native region;
- ambient framed names remain live, including the already-recorded police/combat scan-enrichment follow-up;
- the old two-corner reticle artifact remains absent;
- scanner and quickhack remain the current native 2.31 presentation;
- E3 OFF yields reversible accent styling while Biology-wide health suppression remains independent;
- any remaining **structural** HUD mismatch is routed to a Biology-owned authored-resource follow-up rather than another screen-space/runtime-rectangle iteration.


## W20.1 — T005 authored nameplate and one-way identity authority

T005 tested exact integrated source `a5818db6596e335824d75f596fc8204cc419de4f` on Cyberpunk 2077 2.31. The broader E3 presentation and modern scanner remain KEEP, but two nameplate assumptions are superseded.

### Structural authority

The fixed 340 x 46 `CRBiologyE3IdentityChrome` canvas is removed. T005 showed that controller-root runtime geometry can sit visibly apart from the actual authored name. Biology now treats native `m_nameTextMain` and `m_nameFrame` as one authored structural unit and limits itself to reversible style changes on those widgets.

This follows W18.1's direct Project E3 archaeology: authored resource hierarchy owns structure; runtime rectangles are at most accent chrome. W20.1 does not copy Project E3 resources and does not add a Project E3 runtime dependency.

### Identity authority

Biology no longer writes its public `GetDisplayName()` fallback into a local `NPCNextToTheCrosshair` copy before calling native `SetVisualData`.

The required flow is:

`native discovered identity -> native nameplate/scanner authority -> ambient E3 presentation`.

The forbidden flow is:

`Biology generic ambient fallback -> native SetVisualData / scanner knowledge`.

The fallback remains presentation-only. After native visibility/data handling, Biology may render `GetDisplayName()` only when native incoming identity is still empty and existing hidden/quest/alternative/disabled-nameplate policy permits it.

### T006 boundary

Parent P02 must verify on the integrated canonical candidate:

- ordinary civilians retain ambient identity before scanner;
- police/combatants can start generic if native data is generic, but scanner-discovered specific identity remains authoritative on later focus/recheck;
- the name text and frame are visually composed together with no detached Biology canvas;
- modern scanner/quickhack remains current/native;
- E3 OFF restores captured native name/frame styling and native range.


## W20.3 — restore real E3 ON/OFF authority after rejected autonomous release

The autonomous 1.0.0 / PR #153 release is **not** an accepted presentation baseline.
Owner live testing found that its Biology preference could change state while meaningful
E3 presentation was absent both ON and OFF. PR #155 restored the complete pre-autonomous
tree; W20.3 repairs the presentation contract from that recovered source.

### Why the presentation disappeared

The failure is source-explainable rather than a request for another coordinate guess.

PR #153 combined three risky changes:

1. `UseE3FirstPersonHudVisuals` changed from default-ON while
   `CRRealpassSettings` is not yet attached to requiring the settings system to exist.
2. Multiple HUD adapters stopped creating their native-hosted Biology frame unless that
   early read was already ON.
3. The attempted UISystem refresh callbacks used the Event-suffixed method name instead
   of REDengine's `FooEvent -> OnFoo` callback convention.

That makes controller initialization order capable of permanently producing a
presentation-less session. W20.3 restores the pre-autonomous default-ON startup
semantics, keeps meaningful frames created independently of preference value, and
reconciles live controllers through a stateless
`CRBiologyE3PreferenceChangedEvent -> OnCRBiologyE3PreferenceChanged` event when the
single saved authority attaches, restores or changes.

The event is notification only. It carries no Boolean and creates no second authority.
Every controller reads `CRRealpassSettings.UseE3FirstPersonHudVisuals`.

### ON contract

E3 ON must visibly exercise the established Biology-owned/current-native seams together:

- lower-left compact Biology chrome;
- segmented D-pad/quickslot chrome inside native `m_dpadHintsPanel`;
- quest tracker frame plus native quest/objective-row tint treatment;
- lower-right weapon/ammo frame plus native weapon/ammo tint treatment;
- current interaction/activity accent treatment;
- ordinary native crosshair tint without custom reticle geometry;
- ambient authored native name/frame treatment where native nameplate policy permits.

A changing ON label without these meaningful paths is a regression.

### OFF contract

E3 OFF must restore current/native presentation in the same session:

- Biology E3 frames hidden;
- quest/objective, weapon/ammo, activity and crosshair tints restored from the current
  native state and their capture flags released for future cycles;
- no uncaptured activity/nameplate letter-case or font-style mutation;
- name/frame tint, frame opacity/visibility and ambient range restored;
- native nameplate data is re-applied when preference ownership changes;
- Biology-wide simulation/no-healthbar policy remains independent.

### Scanner / nameplate contract

Modern scanner and quickhack remain native/current. W20.3 introduces no scanner
controller or scanner resource hook.

The nameplate controller's existing `m_isScanning` state is used solely to stop the
ambient projected nameplate from competing with native scanner identity. During scan,
Biology's ambient fallback is disallowed and the projected `m_displayName` is hidden;
native detailed scanner identity remains untouched. On scan exit, native nameplate data
is re-applied and ordinary ambient policy is re-evaluated.

This resolves T007's simultaneous `BEAT COP` / `NC RESIDENT` presentation without
teaching Biology anything new about the NPC and without writing fallback text into
native identity data.

### Biology preference control

W20.2's local detail placement is retained exactly in principle:
`PRESENTATION -> E3 HUD + NAMEPLATES -> ON/OFF`.

T007 proved that placement is visually usable but its click callback could reject the
event. W20.3 makes the row the only interactive child, removes the brittle current-target
comparison, writes the single saved setting, refreshes the row immediately and then
notifies the live HUD.

### Next attended acceptance

The next P02 clean-room milestone should compare the same ordinary-play state ON and OFF
and verify:

- quest/objective, D-pad/hotkeys and lower-right weapon/ammo are materially E3-styled ON;
- OFF visibly returns those regions to native/current presentation without stale red
  tint/frame state;
- the local Biology preference changes ON <-> OFF on click and remains correct after
  menu close/reopen and save/reload;
- ordinary ambient civilian/police names work outside scanner when native policy permits;
- during scanner, native detailed identity is the only identity treatment (no concurrent
  generic Biology name);
- scanner/quickhack remains the current 2.31 interface;
- the old two-corner reticle artifact remains absent;
- Biology detail/Back, Biology <-> Cyberware and ordinary Cyberware remain unchanged.
