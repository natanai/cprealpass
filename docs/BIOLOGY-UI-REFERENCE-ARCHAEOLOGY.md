# Biology UI — Cyberware/Ripperdoc reference archaeology

Status: **W17.1 source/resource archaeology complete; implementation repaired for T005**  
Issue: #107  
Parent issue: #39  
Process gate: #105  
Cyberpunk target: 2.31

## Final decision

The selected-detail lifecycle authority is **RipperdocInventoryController**, but the W02.6 layout host was wrong.

Current-2.31 serialized native evidence proves the authored item subtree is:

```text
wrapper
└─ Inventory                         RipperdocInventoryController root
   └─ cyberwareContainer             inkVerticalPanelWidget
      └─ GridAndSlider               inkHorizontalPanelWidget
         └─ grid                     inkCanvasWidget
            └─ scrollRect            inkScrollAreaWidget
               └─ virtualGridContainer
```

Package-copy handles:

```text
wrapper(412)
└─ Inventory(632)
   └─ cyberwareContainer(635)
      └─ GridAndSlider(737)
         └─ grid(740)
            └─ scrollRect(743)
               └─ virtualGridContainer(746)
```

The corresponding library-copy chain is:

```text
wrapper(4)
└─ Inventory(141)
   └─ cyberwareContainer(143)
      └─ GridAndSlider(215)
         └─ grid(217)
            └─ scrollRect(219)
               └─ virtualGridContainer(221)
```

Therefore:

- `Inventory` remains the native detail show/hide/opacity lifecycle root.
- `cyberwareContainer` is the authored selected-content layout container under that root.
- `GridAndSlider -> grid -> scrollRect -> virtualGridContainer` is Cyberware's item-list implementation, not a generic detail-content host.
- W02.6's mount beside `m_virtualGridContainer` was inside an `inkScrollAreaWidget` subtree and is structurally disproven.
- Biology now mounts as a **sibling of `cyberwareContainer` under `Inventory`**, derives its placement from the live `cyberwareContainer`, and never reconstructs the serialized 800/300 placement as a screen-space constant.

This preserves the native detail lifecycle while removing Biology from scroll/mask/virtualization semantics.

## Evidence priority

### 1. Current installed CP2077 2.31 serialized Ripperdoc resource

Authoritative resource:

- `base\gameplay\gui\fullscreen\ripperdoc\ripperdoc.inkwidget`
- archive: `content\basegame_1_engine.archive`
- extracted resource SHA-256 from the W02.4 probe:
  `9E96DF6CECC0F3A0A492B0F7B6ED84C105901504B1508BE9BFA3696B977E1112`
- full serialized target JSON captured through the #105 private-reference workflow:
  SHA-256 `0141525E50EF98289E1D0D8A5AFA835A26476CC2442488AD0A3B39B4398754B3`

Private bundle evidence is not committed. Only the derived hierarchy and implementation contract are retained here.

The current resource establishes:

- `scrollRect` 219/743 is `inkScrollAreaWidget`;
- it is size 906x1010, Fill-aligned, fit-to-content, with authored bottom padding 204;
- `virtualGridContainer` 221/746 is its sole child;
- the scroll area is child-order 0 of `grid`; the other grid children are mask/frame decoration;
- `grid` 217/740 is a 906x1010 `inkCanvasWidget`;
- `GridAndSlider` 215/737 is an `inkHorizontalPanelWidget`;
- `cyberwareContainer` 143/635 is an `inkVerticalPanelWidget` with authored left/top placement 800/300;
- `Inventory` 141/632 carries `RipperdocInventoryController` and is under `wrapper`.

The same resource exposes `paperDollWrapper` as a screen-level anatomy composition node (package copy handle 448, `inkCanvasWidget`, 1300x1800, centered with authored top margin 100).

### 2. Native Ripperdoc controller behavior

The installed 2.31 script tree remains the runtime symbol authority. The readable public CDPR script mirror is useful for behavioral inspection but is not treated as a 2.31 resource substitute.

Native responsibility is split deliberately:

```text
RipperDocGameController
├─ screen/mode/navigation state
├─ body/category minigrids
├─ DollHover / DollSelect anatomy animation
├─ minigrid target + selector transition
├─ DisplayInventory(detail depth)
├─ inventoryViewAnchor
│  └─ RipperdocInventoryController
│     ├─ root opacity/show/hide lifecycle
│     └─ authored cyberwareContainer content subtree
└─ selectorAnchor
   └─ RipperdocSelectorController
```

Native category entry is approximately:

```text
selected area
-> m_filterArea
-> DollHover(area)
-> DollSelect(true)
-> DisplayInventory(true)
-> selected minigrid target transition
-> selector detail navigation
```

Native Back reverses that state through the same shell.

Biology therefore continues to reuse:

- `m_filterArea` / selected-area identity;
- native `DollHover` and `DollSelect`;
- `DisplayInventory(true/false)`;
- native selector events and category cycling;
- native minigrid movement/animation;
- native Back/Cancel depth.

Biology does not create a second drill-down controller.

### 3. Cyberware-EX 1.5.6

Public reference commit inspected:

`psiberx/cp2077-cyberware-ex@855d9a42eecdb635d5c9d15e6949107b9b3b1b00`

Relevant public source:

- `scripts/Overrides/UI/RipperDocGameController.reds`
- `scripts/Overrides/UI/RipperdocMetersArmor.reds`
- `scripts/Overrides/UI/RipperdocMetersCapacity.reds`
- `scripts/Overrides/UI/CyberwareInventoryMiniGrid.reds`

Cyberware-EX preserves the stock Ripperdoc controller and category system rather than cloning the screen.

Its meter wrappers are particularly useful architecture evidence. They obtain the existing screen composition through:

```text
meter root
-> parent
-> parent.GetWidget("wrapper")
-> wrapper.GetWidget("paperDollWrapper")
```

and reparent meters relative to `paperDollWrapper`.

That independently supports two rules:

1. authored named screen composition is a stable seam worth resolving directly;
2. screen-level/body-relative additions should not be attached to the Cyberware virtual-grid subtree merely because it is visible during detail.

Biology deliberately does **not** depend on Cyberware-EX.

### 4. Ripperdoc Vendor UI Enhancements 1.04

The private #105 reference capture establishes that this mod modifies the same native screen through controller seams rather than base-asset replacement:

- wraps `RipperDocGameController.OnMinigridSpawned`;
- obtains native category minigrids with `GetMinigrid(area)`;
- modifies `CyberwareInventoryMiniGrid.m_label` / `m_isNew`;
- wraps `RipperdocSelectorController.SetIndicator`.

This independently confirms that Biology's category/body labels and detail selector should remain controller-driven. No screenshot coordinate system is required for those elements.

The private payload is not committed and is not a runtime dependency.

### 5. Secondary references

The #105 capture also contains Codeware 1.20.4, Specialized Ripperdocs 1.1.1, With Phantom Liberty 1.2, and other Ripperdoc-related material. These are useful corroborating/private archaeology inputs only.

Codeware is not introduced as a Biology dependency by W17.1. Biology can resolve the required direct child using vanilla compound-child traversal and `inkWidget.GetName()`.

## Screen architecture

The useful screen-level model is:

```text
RipperDocGameController
└─ wrapper                                      screen composition
   ├─ paperDollWrapper                          anatomy/body presentation
   │  └─ body visuals / body-relative composition
   ├─ category/minigrid anchors                 overview system nodes
   │  └─ selected minigrid -> MinigridTargetAnchor
   ├─ selectorAnchor
   │  └─ RipperdocSelectorController            detail category navigation
   └─ Inventory                                 selected-detail lifecycle surface
      ├─ cyberwareContainer                     stock selected-content layout
      │  └─ GridAndSlider
      │     └─ grid
      │        └─ scrollRect                     ITEM-SCROLL boundary
      │           └─ virtualGridContainer        ITEM-VIRTUALIZATION boundary
      └─ CRBiologyNativeContent                 Biology sibling replacement surface
```

The distinction is intentional:

- **paperDollWrapper** is the authored body/anatomy composition host.
- **Inventory** is the selected-detail lifecycle authority.
- **cyberwareContainer** is the authored stock content container.
- **scrollRect / virtualGridContainer** are item-list implementation details.
- **CRBiologyNativeContent** is Biology-owned, but it inherits placement from the live authored `cyberwareContainer` and remains under the same Inventory lifecycle.

This is closer to native composition than mounting Biology into `paperDollWrapper`: selected detail still needs `RipperdocInventoryController.ShowArea/Hide` opacity/lifecycle behavior. It is also safer than W02.6 because it avoids scroll clipping, item masking, virtualized sizing, and grid child ordering.

## W17.1 implementation contract

### Enter Biology detail

Biology retains the already-working W02.2+ state path:

```text
commit Biology selected area
-> native DollHover(area)
-> native DollSelect(true)
-> native DisplayInventory(true)
-> resolve Inventory direct child named cyberwareContainer
-> verify it is inkVerticalPanel
-> mount CRBiologyNativeContent under Inventory as its sibling
-> copy live cyberwareContainer anchor/alignment/margin/padding/translation
-> hide cyberwareContainer as one stock content unit
-> show Biology content
```

The serialized 800/300 `cyberwareContainer` placement is evidence, not a hard-coded layout constant. Runtime code reads the live widget.

If the named direct child or expected widget family is missing after a future patch, Biology fails closed with a bounded diagnostic instead of using a guessed fallback.

### Leave Biology detail

```text
restore prior cyberwareContainer visibility
-> DisplayInventory(false)
-> native body/category overview reset
-> Biology overview labels/interactivity restored
```

The stock content container's prior visibility is captured and restored exactly.

### Cyberware mode

Biology mode never mutates the stock content children individually as a layout technique. Ordinary Cyberware mode continues to own its native:

- inventory grid;
- scrollbar;
- filter labels;
- item displays;
- vendor/equip/upgrade behavior;
- capacity/armor presentation.

Biology's overview/category hiding remains limited to Biology mode and stock categories are restored on mode exit.

## What W02.6 still contributes

W02.6 remains valuable evidence:

- the native inventory controller must stay the show/hide authority;
- detail content must fail closed when its intended native seam is unavailable;
- runtime-backed Biology data was already reaching presentation;
- post-mount visibility/size/order diagnostics are useful until live acceptance;
- an ordinary Biology vertical panel should size from its real children, not inherit virtual-grid extent semantics.

W02.6's specific **host assumption** is retired:

```text
scrollRect
├─ virtualGridContainer
└─ Biology
```

is not an acceptable long-term composition.

## T005 acceptance boundary

### Already source/resource-proven before T005

T005 does **not** need to rediscover:

- the current installed Ripperdoc resource identity;
- the exact `wrapper -> Inventory -> cyberwareContainer -> GridAndSlider -> grid -> scrollRect -> virtualGridContainer` chain;
- that 219/743 is an `inkScrollAreaWidget`;
- that W02.6 mounted Biology inside the item-scroll subtree;
- that `RipperdocInventoryController` is the detail lifecycle authority;
- that `cyberwareContainer` is the direct authored stock content container;
- that `paperDollWrapper` is a separate screen-level anatomy host;
- that native category labels/selector can be controlled through native controllers;
- that no screenshot-derived offsets are necessary.

### T005 must validate live behavior only

Parent P02's attended T005 should establish:

1. Biology detail title/summary/metrics are visibly composed in the intended selected-content region.
2. The panel is not top-left, clipped by the old scroll rectangle, hidden by a mask, or constrained by virtual-grid sizing.
3. LEGS and at least one additional supported system show authoritative runtime-backed detail.
4. Native anatomy focus/zoom and selector/category cycling remain correct.
5. Back returns Biology detail -> Biology overview without leaving the whole menu.
6. Repeated overview -> detail -> Back -> another detail cycles do not accumulate stale state.
7. Switching Biology <-> Cyberware at overview remains stable.
8. Ordinary Cyberware detail restores its stock content, filters, scrollbar, item grid, equip/upgrade/vendor behavior, and capacity/armor presentation.
9. Existing W02.6 diagnostics can be removed only after this new authored-host path is visually accepted.

No further local resource probe is required for this hierarchy unless T005 exposes a genuinely new native boundary rather than a visual/runtime implementation defect.


## W20.2 — Biology E3 preference placement contract

T006 live evidence proved that the previous E3 preference editor was not a usable
part of the Biology interface. It created a free-floating `inkText`, reparented it
directly to the fullscreen `RipperDocGameController` root, anchored it
`TopRight`, and relied on fixed top/right margins. On the actual Cyberpunk 2.31
Biology screen this was clipped at the extreme right edge.

The corrected placement reuses W17.1's already-proven authored detail seam instead of
introducing another screen coordinate system:

```text
wrapper
└─ Inventory                         RipperdocInventoryController lifecycle root
   ├─ cyberwareContainer             authored stock selected-content container
   └─ CRBiologyNativeContent         Biology sibling with copied authored placement
      ├─ selected-system title / summary / metrics
      ├─ PRESENTATION
      │  └─ E3 HUD + NAMEPLATES   ON|OFF
      └─ contextual Biology actions
```

The preference row is progressive-disclosure UI at deliberate detail depth. This keeps
it readily reachable from Biology while preventing permanent chrome from competing with
level/street cred, top tabs, currency, anatomy, category nodes, or ordinary Cyberware.

Implementation rules:

- `CRRealpassSettings` remains the sole save-backed preference authority.
- The preference panel is a child of `CRBiologyNativeContent`; it is not a child of
  the fullscreen root and has no screen-space anchor.
- The local row owns a 680x48 interactive hit target aligned with Biology's existing
  680-wide metric/detail composition.
- The parent `CRBiologyNativeContent` remains visible only when Biology owns detail
  depth and the authored `Inventory -> cyberwareContainer` host contract resolves.
- Teardown clears the preference widget references with the shared Ripperdoc lifecycle.
- No Mod Settings, ArchiveXL, RED4ext, Codeware, or Project E3 runtime dependency is
  introduced.

T007 must visually/interactively prove that the complete label and current ON/OFF value
are legible inside the selected-content region, that mouse/controller activation toggles
the saved E3 state, and that repeated detail -> Back plus Biology <-> Cyberware switching
does not leak or strand the preference.
