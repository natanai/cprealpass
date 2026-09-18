# Biology E3-inspired presentation target

Status: canonical visual target / W03.4 visual-completion contract
Last updated: 2026-09-17
Current worker: W03.4 / issue #40

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
